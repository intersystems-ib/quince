"""Disposable-instance checks for rating scale and incoming friendly invitations."""
from session_integration import Client, BASE
from test_paths import artifact_path
from uuid import uuid4
from datetime import date
import json,secrets

assert ':52776/' in BASE, 'Use the disposable instance.'
c=Client();password=secrets.token_urlsafe(24);username='friendly_'+uuid4().hex[:10]
c.call('/auth/register','POST',{'username':username,'password':password})
c.game=c.call('/games','POST',{'name':'Invitaciones de rivales','clubId':'c1','divisionId':416})
c.call('/games/'+c.game['id']+'/load','POST',{})
clubs=c.call('/clubs')['items'];means={}
for club in clubs:
 players=c.call('/clubs/'+club['id']+'/players?limit=500')['items']
 assert all(p['talentScaleFactor']==.75 for p in players)
 seniors=[p for p in players if p['category']=='senior']
 means[club['id']]=sum(p['average'] for p in seniors)/len(seniors)
 assert abs(means[club['id']]-club['qualitySeniorTarget'])<.00001,(club['id'],means[club['id']],club['qualitySeniorTarget'],len(seniors))
honor=[means[x['id']] for x in clubs if x['competitionId']==416];elite=[means[x['id']] for x in clubs if x['competitionId']==417]
assert min(honor)>max(elite) and max(honor)<61
market=c.call('/transfer-market')['items'];assert len(market)<=20 and all(p['talentScaleFactor']==.75 for p in market)
items=c.call('/clubs/c1/friendly-invitations')['items'];assert len(items)==1
v=items[0];assert date.fromisoformat(v['date']).weekday()>=5 and v['opponentId']!='c1'
assert not any(f.get('invitationId')==v['id'] for f in c.call('/clubs/c1/fixtures?limit=500')['items'])
b={'invitationId':v['id'],'version':v['version'],'decision':'accept'};key=str(uuid4());before=c.call('/clubs/c1')['balance']
accepted=c.call('/clubs/c1/friendly-invitations','POST',b,key=key)
assert accepted==c.call('/clubs/c1/friendly-invitations','POST',b,key=key)
fixtures=c.call('/clubs/c1/fixtures?limit=500')['items'];f=next(f for f in fixtures if f['id']==accepted['fixtureId'])
assert f['stage']=='friendly' and f['date']==v['date'] and c.call('/clubs/c1')['balance']==before
assert not c.call('/clubs/c1/friendly-invitations')['items']
c.call('/clubs/c2/friendly-invitations',status=403)
# Leave a second save with a pending invitation for visual review.
c.game=c.call('/games','POST',{'name':'Propuesta de amistoso','clubId':'c3','divisionId':416});c.call('/games/'+c.game['id']+'/load','POST',{})
v=c.call('/clubs/c3/friendly-invitations')['items'][0]
artifact_path('friendly-ui.json').write_text(json.dumps({'username':username,'password':password,'game':c.game}),encoding='utf-8')
artifact_path('friendly-http-traces.json').write_text(json.dumps(c.trace),encoding='utf-8')
artifact_path('friendly-summary.json').write_text(json.dumps({'means':means,'accepted':accepted,'fixture':f,'pending':v},indent=2),encoding='utf-8')
print('PASS scaled ratings for 20 clubs and free agents; Honor exceeds Elite; weekend invitation, explicit consent, retry, calendar, ownership and unchanged balance',flush=True)
