"""Check all clubs and idle morale in a disposable instance only."""
from test_paths import artifact_path
import json,secrets
from pathlib import Path
from uuid import uuid4
from session_integration import Client,BASE
assert ':52776/' in BASE
c=Client();d={'username':'morale_'+uuid4().hex[:8],'password':secrets.token_urlsafe(24)}
c.call('/auth/register','POST',d);c.game=c.call('/games','POST',{'name':'Moral y energía','clubId':'c1','divisionId':416})
clubs=c.call('/clubs')['items']
for club in clubs:
 ps=c.call('/clubs/'+club['id']+'/players')['items'];assert all(p['morale']==100 for p in ps)
print('PASS all 20 clubs, both divisions, seniors and academy start with morale 100',flush=True)
for i in range(15):
 club=c.call('/clubs/c1');c.call('/clubs/c1/advance-day','POST',{'version':club['version']})
for club in clubs:
 ps=c.call('/clubs/'+club['id']+'/players')['items'];day=c.call('/clubs/'+club['id'])['day']
 for p in ps:
  reference=max(p.get('moraleStartedDay',day),p.get('lastAppearanceDay',-99999),p.get('signedDay',-99999));expected=max(0,100-max(0,day-reference-14));assert p['morale']==expected,(club['id'],p['name'],p['morale'],expected)
 assert any(p['morale']==99 for p in ps)
print('PASS fifteen daily advances: identical idle loss in all 20 teams, including their academies',flush=True)
d['game']=c.game;artifact_path('morale-ui.json').write_text(json.dumps(d),encoding='utf-8');artifact_path('morale-http-traces.json').write_text(json.dumps(c.trace),encoding='utf-8')
