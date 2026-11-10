"""Exercise contracts and lifecycle against the disposable instance."""
from test_paths import artifact_path
import argparse
import json
import secrets
from pathlib import Path
from uuid import uuid4
from session_integration import Client, BASE

assert ':52776/' in BASE, 'Never target the live game'
path = artifact_path('seasons-ui.json')
parser = argparse.ArgumentParser()
parser.add_argument('mode', choices=['setup', 'close'])
args = parser.parse_args()
c = Client()
if args.mode == 'setup':
    d = {'username': 'seasons_' + uuid4().hex[:8], 'password': secrets.token_urlsafe(24)}
    c.call('/auth/register', 'POST', d)
    c.game = c.call('/games', 'POST', {'name': 'Temporadas y contratos', 'clubId': 'c1', 'divisionId': 416})
    roster = c.call('/clubs/c1/players')['items']
    p1 = next(p for p in roster if p['id'] == 'c1-p1')
    n = c.call('/players/c1-p1/renew', 'POST', {'version': p1['version']})
    assert n['kind'] == 'renewal' and n['signingFee'] == 0
    n = c.call('/negotiations/' + n['id'] + '/offer', 'POST', {'version': n['version'], 'weeklyWage': n['askingWeeklyWage']})
    key, body = str(uuid4()), {'version': n['version']}
    n = c.call('/negotiations/' + n['id'] + '/sign', 'POST', body, key=key)
    assert c.call('/negotiations/' + n['id'] + '/sign', 'POST', body, key=key) == n
    kept = c.call('/players/c1-p1')
    assert kept['contractEndDate'] > p1['contractEndDate'] and kept['attributes'] == p1['attributes'] and kept['energy'] == p1['energy']
    youth = next(p for p in roster if p['id'] == 'c1-p24')
    n = c.call('/players/c1-p24/renew', 'POST', {'version': youth['version']})
    assert n['askingWeeklyWage'] == youth['weeklyWage']
    n = c.call('/negotiations/' + n['id'] + '/offer', 'POST', {'version': n['version'], 'weeklyWage': n['askingWeeklyWage']})
    c.call('/negotiations/' + n['id'] + '/sign', 'POST', {'version': n['version']})
    assert c.call('/players/c1-p24')['category'] == 'academy'
    c.call('/players/c2-p1/renew', 'POST', {'version': 1}, status=403)
    d.update(game=c.game, youthName=youth['name'], retiringName=next(p['name'] for p in roster if p['id'] == 'c1-p4'), renewName=next(p['name'] for p in roster if p['id'] == 'c1-p3'))
    path.write_text(json.dumps(d), encoding='utf-8')
    fixture = f'''set %RugbyGame="{c.game['id']}",%RugbyManagedClub="c1"
lock +^RugbyWrite:15
tstart
set year=##class(Rugby.Service.Seasons).Year(),final=##class(Rugby.Service.Seasons).FinalDay(year),day=final+6,clubs=##class(Rugby.Service.Store).All("Club"),p=##class(Rugby.Service.Store).Get("Player","c1-p4"),p.birthDay=final-(40*365)
do ##class(Rugby.Service.Seasons).Contract(p,year+2),##class(Rugby.Service.Store).Put("Player",p)
set announcements=##class(Rugby.Service.Seasons).Announce(##class(Rugby.Service.Seasons).NoticeDay(year))
for i=0:1:clubs.%Size()-1 {{ set club=clubs.%Get(i),club.day=day,club.date=$zdate(day+$zdateh("2026-11-07",3),3),club.aiLastDay=day do ##class(Rugby.Service.Store).Put("Club",club) if club.id'="c1" set renewed=##class(Rugby.Service.Seasons).RenewRival(club,final-1) }}
do ##class(Rugby.Test.Seasons).Complete(year)
tcommit
lock -^RugbyWrite
halt
'''
    artifact_path('seasons-fixture.script').write_text(fixture, encoding='utf-8')
    print('PASS HTTP salary renewal, extension, retries, preserved attributes/energy, academy category and club authorization', flush=True)
else:
    d = json.loads(path.read_text(encoding='utf-8'))
    c.call('/auth/login', 'POST', {k: d[k] for k in ['username', 'password']})
    c.game = d['game']
    old = c.call('/competitions/league-416-2026')
    assert any(p['playerId'] == 'c1-p4' for p in old['retiringPlayers'])
    retiring = c.call('/players/c1-p4')
    c.call('/players/c1-p4/renew', 'POST', {'version': retiring['version']}, status=409)
    club = c.call('/clubs/c1')
    key, body = str(uuid4()), {'version': club['version']}
    new = c.call('/clubs/c1/advance-day', 'POST', body, key=key)
    assert c.call('/clubs/c1/advance-day', 'POST', body, key=key) == new
    assert new['seasonYear'] == 2027 and new['seasonStartDate'] == '2027-09-01' and new['date'] == '2027-06-13'
    assert len(c.call('/competitions')['items']) == 4
    for division in [416, 417]:
        league = c.call(f'/competitions/league-{division}-2027')
        assert len(league['regularFixtures']) == 90 and all(f['status'] == 'scheduled' for f in league['regularFixtures'])
        assert not league['semifinals'] and league['final'] == '' and league['seasonStartDate'] == '2027-09-01'
    prior = c.call('/competitions/league-416-2026')
    assert prior['closedDate'] == '2027-06-13' and prior['championId'] == old['championId'] and prior['regularFixtures'] == old['regularFixtures']
    free, gone, kept = [c.call('/players/' + pid) for pid in ['c1-p2', 'c1-p4', 'c1-p1']]
    assert free['clubId'] == '' and free['contractStatus'] == 'expired' and gone['retired'] and not gone['available'] and kept['clubId'] == 'c1'
    market = c.call('/transfer-market?limit=500')['items']
    assert any(p['id'] == free['id'] for p in market) and not any(p['id'] == gone['id'] for p in market)
    print('PASS HTTP advance-day closes season once, September start, both draws, history, expiry to market and permanent retirement', flush=True)
artifact_path('seasons-http-traces-' + args.mode + '.json').write_text(json.dumps(c.trace), encoding='utf-8')
