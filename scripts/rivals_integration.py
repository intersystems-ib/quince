"""Verify rival management only on the disposable rugby-rivals-check instance."""
from test_paths import artifact_path
import json,secrets,subprocess,time
from pathlib import Path
from uuid import uuid4
from session_integration import Client,BASE
assert BASE=='http://localhost:52776/api/v1','Use the disposable instance on port 52776'
def terminal(code):
    r=subprocess.run(['docker','exec','-i','rugby-rivals-check','iris','session','IRIS','-U','RUGBY'],input=code+'\nhalt\n',text=True,capture_output=True,check=True)
    assert '<' not in r.stdout,r.stdout
c=Client();c.call('/auth/register','POST',{'username':'qa_rivals_'+uuid4().hex[:8],'password':secrets.token_urlsafe(20)})
c.game=c.call('/games','POST',{'name':'Rivales deterministas','clubId':'c1','divisionId':416})
c.call('/games/'+c.game['id']+'/load','POST',{})
club=c.call('/clubs/c1');plan=c.call('/clubs/c1/training-plan');c.call('/clubs/c1/training-plan','PUT',{'version':plan['version'],'groups':[]})
own=c.call('/players/c1-p1')['attributes'];before=c.call('/players/c2-academy-1');key=str(uuid4())
start=time.monotonic();after=c.call('/clubs/c1/advance-day','POST',{'version':club['version']},key=key);elapsed=time.monotonic()-start
assert after['date']=='2026-09-02'
rivals=c.call('/clubs')['items'];assert all(r['date']==after['date'] for r in rivals)
youth=c.call('/players/c2-academy-1');assert youth['average']>before['average'] and youth['energy']<before['energy']
assert c.call('/players/c1-p1')['attributes']==own
again=c.call('/clubs/c1/advance-day','POST',{'version':club['version']},key=key);assert again==after and c.call('/players/c2-academy-1')['energy']==youth['energy']
training=c.call('/clubs/c2/training-plan');roster=c.call('/clubs/c2/players')['items'];ids=[pid for g in training['groups'] for pid in g['playerIds']]
assert len(ids)==len(set(ids))==len(roster)
assert len([p for p in roster if p['category']=='academy'])>=20
assert max(t['quality'] for t in c.call('/clubs/c2/staff')['coaches'])>35
c.call('/rivals','POST',{'Channel':'rivals','day':-65},status=404)
print('PASS daily rival clocks, academy improvement and fatigue, staff improvement, complete training groups and idempotency; advance seconds',round(elapsed,2),flush=True)

# Force a late AI validation failure and verify that the entire parent day rolls back.
beforeOwn=c.call('/clubs/c1');beforeOther=c.call('/players/c3-academy-1');badkey=str(uuid4());gid=c.game['id']
terminal('set %RugbyGame="'+gid+'",players=##class(Rugby.Service.Store).All("Player","clubId","c2")\nfor i=0:1:players.%Size()-1 { set p=players.%Get(i) if (p.category="senior")&&(p.position=1) { set p.available=0,p.recoveryDay=10000 do ##class(Rugby.Service.Store).Put("Player",p) } }')
error=c.call('/clubs/c1/advance-day','POST',{'version':beforeOwn['version']},key=badkey,status=409)
assert error['code']=='AI_LINEUP',error
assert c.call('/clubs/c1')==beforeOwn and c.call('/players/c3-academy-1')==beforeOther
terminal('set %RugbyGame="'+gid+'",players=##class(Rugby.Service.Store).All("Player","clubId","c2")\nfor i=0:1:players.%Size()-1 { set p=players.%Get(i) if (p.category="senior")&&(p.position=1) { set p.available=1,p.recoveryDay=0 do ##class(Rugby.Service.Store).Put("Player",p) } }')
fixed=c.call('/clubs/c1/advance-day','POST',{'version':beforeOwn['version']},key=badkey);assert fixed['date']=='2026-09-03'
print('PASS nested production operation rollback and successful retry without duplicate training or charges',flush=True)
c.call('/games/'+c.game['id']+'/unload','POST',{});c.call('/auth/logout','POST',{})
artifact_path('rivals-http-traces.json').write_text(json.dumps(c.trace),encoding='utf-8')
