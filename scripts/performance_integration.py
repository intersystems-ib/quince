"""Read/write checks only against the disposable match-engine instance."""
from test_paths import artifact_path
import json,secrets
from pathlib import Path
from uuid import uuid4
from session_integration import Client,BASE
assert ':52776/' in BASE,'Use the disposable instance'
c=Client();c.call('/auth/register','POST',{'username':'units_'+uuid4().hex[:10],'password':secrets.token_urlsafe(24)})
c.game=c.call('/games','POST',{'name':'Unidades y moral','clubId':'c1','divisionId':416})
lineup=c.call('/clubs/c1/lineups')['items'][0]
lineup['slots'][3]['playerId'],lineup['slots'][11]['playerId']=lineup['slots'][11]['playerId'],lineup['slots'][3]['playerId']
lineup=c.call('/lineups/'+lineup['id'],'PUT',lineup)
original={p['id']:p for p in c.call('/clubs/c1/players')['items']}
club=c.call('/clubs/c1');opponent=c.call('/clubs/c1/friendly-options?date='+club['date'])['items'][0]
f=c.call('/clubs/c1/friendlies','POST',{'version':club['version'],'date':club['date'],'opponentId':opponent['id'],'venue':'home'})
m=c.call('/matches','POST',{'fixtureId':f['id'],'lineupId':lineup['id']},status=201)
m=c.call('/matches/'+m['id']+'/start','POST',{})
assert m['engineVersion']=='1.1.0'
for p in m['homePlayers']:
 old=original[p['playerId']]
 assert p['attributes']==old['attributes']
 expected=0 if p['position']==old['position'] else 3 if p['position'] in old['secondary'] else 8 if (p['position']<=8)==(old['position']<=8) else 15
 if p['status']!='field':expected=0
 assert p['morale']==max(0,old['morale']-expected),(p['name'],p['morale'],expected)
 assert p.get('positionMoralePenalty',0)==expected
c.call('/games/'+c.game['id']+'/unload','POST',{})
artifact_path('performance-http-traces.json').write_text(json.dumps(c.trace),encoding='utf-8')
print('PASS HTTP lineup swap: players keep all attributes; morale loss follows occupied position, secondary roles and bench status; engine 1.1.0; native interop traces')
