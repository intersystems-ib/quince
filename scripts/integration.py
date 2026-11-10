"""Real HTTP integration against the IRIS MVP. Consumes one demo friendly.

Usage: python scripts/integration.py [--restart-backend] [--base http://localhost:5175/api/v1]
"""
import argparse
import json
import subprocess
import time
import uuid
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError

parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--base',default='http://127.0.0.1:5175/api/v1')
parser.add_argument('--restart-backend',action='store_true')
args=parser.parse_args()

def api(path,method='GET',body=None,key=None,expected=200):
 data=None if body is None else json.dumps(body).encode()
 req=Request(args.base+path,data=data,method=method,headers={'Content-Type':'application/json','Idempotency-Key':key or str(uuid.uuid4())})
 try:
  with urlopen(req,timeout=15) as r:
   status=r.status;result=json.load(r)
 except HTTPError as error:
  status=error.code;result=json.load(error)
 assert status==expected,(method,path,status,result)
 return result

def log(message): print(message,flush=True)
def wait_api(timeout=100):
 end=time.monotonic()+timeout
 while time.monotonic()<end:
  try:return api('/health')
  except (OSError,URLError,AssertionError):time.sleep(.5)
 raise AssertionError('API did not become ready')

wait_api()
clubs=api('/clubs')['items']
assert len(clubs)==20
assert sum(c['competitionId']==416 for c in clubs)==10
assert sum(c['competitionId']==417 for c in clubs)==10
assert len({c['officialTeamId'] for c in clubs})==20
log('PASS: 20 equipos oficiales, 10 por división, IDs únicos')
players=api('/clubs/c1/players')['items'];count=len(players)
juvenile=next((p for p in players if p['category']=='academy'),None)
if juvenile:
 path=f"/clubs/c1/academy/{juvenile['id']}/promote"
 negotiation=api(path,'POST',{'version':juvenile['version']},'integration-promote-'+juvenile['id'])
 agreed=api('/negotiations/'+negotiation['id']+'/offer','POST',{'version':negotiation['version'],'weeklyWage':negotiation['askingWeeklyWage']})
 first=api('/negotiations/'+agreed['id']+'/sign','POST',{'version':agreed['version']},'integration-promotion-sign-'+juvenile['id'])
 second=api('/negotiations/'+agreed['id']+'/sign','POST',{'version':agreed['version']},'integration-promotion-sign-'+juvenile['id'])
 assert first['id']==second['id'] and api('/players/'+juvenile['id'])['category']=='senior'
 assert api('/clubs/c1/players')['total']==count
log('PASS: promoción persistente sin duplicados')
l=api('/clubs/c1/lineups')['items'][0]
bad=json.loads(json.dumps(l));bad['slots'][1]['playerId']=bad['slots'][0]['playerId']
assert api('/lineups/'+l['id'],'PUT',bad,expected=422)['code']=='INVALID_LINEUP'
saved=api('/lineups/'+l['id'],'PUT',l)
assert saved['version']>l['version']
api('/lineups/'+l['id'],'PUT',l,expected=409)
log('PASS: alineación inválida rechazada y edición concurrente protegida')
plan=api('/clubs/c1/training-plan')
plan['groups']=[{'id':'integration-recovery','name':'Recuperación','focus':'recovery','intensity':'low','playerIds':[p['id'] for p in players]}]
api('/clubs/c1/training-plan','PUT',plan)
fixtures=api('/clubs/c1/fixtures')['items']
fixture=next(f for f in fixtures if f['status']!='finished')
club=api('/clubs/c1')
while club['day']<fixture['day']:
 key='integration-day-'+str(uuid.uuid4());before=club['day']
 club=api('/clubs/c1/advance-day','POST',{'version':club['version']},key)
 retry=api('/clubs/c1/advance-day','POST',{'version':0},key)
 assert retry['day']==club['day']==before+1
log('PASS: entrenamiento, recuperación y avance de día idempotente')
key=str(uuid.uuid4())
match=api('/matches','POST',{'fixtureId':fixture['id'],'lineupId':l['id'],'seed':593},key,expected=201)
assert api('/matches','POST',{'fixtureId':fixture['id']},key,expected=201)['id']==match['id']
mid=match['id'];prefix='/matches/'+mid
match=api(prefix+'/start','POST',{},'integration-start')
assert api(prefix+'/start','POST',{},'integration-start')['seed']==593
api('/clubs/c1/advance-day','POST',{'version':club['version']},expected=409)
speed=api(prefix+'/commands','POST',{'type':'speed','speed':60},'integration-speed')
assert api(prefix+'/commands','POST',{'type':'speed','speed':60},'integration-speed')['id']==speed['id']
api(prefix+'/commands','POST',{'type':'speed','speed':2},expected=422)
api(prefix+'/commands','POST',{'type':'substitution','outId':'c1-p1','inId':'c1-p21'},expected=422)
sub=api(prefix+'/commands','POST',{'type':'substitution','outId':'c1-p1','inId':'c1-p16'},'integration-sub')
api(prefix+'/commands','POST',{'type':'tactic','tactic':{'style':'hands','tempo':'normal','defense':'normal'}},'integration-tactic')
log('PASS: inicio, reintentos y comandos HTTP; partido '+mid)

time.sleep(2)
before=api(prefix)
real_start=time.monotonic()
time.sleep(2)
after=api(prefix)
real_elapsed=time.monotonic()-real_start
game_elapsed=after['clock']-before['clock']
assert 40<=game_elapsed<=((real_elapsed*60)+45),(real_elapsed,game_elapsed)
log(f'PASS: x60 medido en tiempo real ({game_elapsed}s de juego en {real_elapsed:.2f}s reales)')
if args.restart_backend:
 before=after
 subprocess.run(['docker','compose','restart','iris'],check=True,stdout=subprocess.DEVNULL)
 wait_api()
 after=api(prefix)
 assert after['clock']>=before['clock']
 assert after['clock']-before['clock']<=180,'Restart must not simulate the offline time'
 assert after['seed']==before['seed'] and after['id']==before['id']
 log('PASS: reinicio real de IRIS conserva estado y no recupera tiempo apagado')

end=time.monotonic()+115
while time.monotonic()<end:
 match=api(prefix)
 if match['status']=='finished':break
 time.sleep(1)
assert match['status']=='finished' and match['clock']==4800 and match['settled']
commands=api(prefix+'/commands?limit=500')['items']
assert next(c for c in commands if c['id']==sub['id'])['status']=='applied'
assert len([c for c in commands if c['id']==speed['id']])==1
seq=0;events=[]
while True:
 page=api(prefix+f'/events?afterSequence={seq}&limit=30')
 events+=page['items']
 if page['items']:seq=page['items'][-1]['sequence']
 if not page['hasMore']:break
assert [e['sequence'] for e in events]==list(range(1,match['sequence']+1))
assert sum(e['points'] for e in events if e['side']=='home')==match['homeScore']
assert sum(e['points'] for e in events if e['side']=='away')==match['awayScore']
finances=api('/clubs/c1/finances');movements=finances['movements']
assert finances['balance']==finances['initialBalance']+sum(m['amount'] for m in movements)
assert len([m for m in movements if m['source'].startswith('economy-'+match['fixtureId']+'-')])==3
assert api(prefix+'/start','POST',{},'integration-restart-final')['status']=='finished'
assert api('/clubs/c1/finances')['balance']==finances['balance']
log(f"PASS: final {match['homeScore']}–{match['awayScore']}, {len(events)} eventos, sustitución, saldo y liquidación única")
log('ALL HTTP INTEGRATION TESTS PASSED')
