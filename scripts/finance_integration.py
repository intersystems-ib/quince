"""Disposable-account checks for the financial module."""
from test_paths import artifact_path
import json,secrets,time
from pathlib import Path
from uuid import uuid4
from session_integration import Client,BASE
assert ':52776/' in BASE,'Use disposable instance'
c=Client();password=secrets.token_urlsafe(24);username='finance_'+uuid4().hex[:10]
c.call('/auth/register','POST',{'username':username,'password':password});c.game=c.call('/games','POST',{'name':'Economía de septiembre','clubId':'c3','divisionId':416})
f=c.call('/clubs/c3/finances');assert not f['office']['director'].get('id');assert f['balance']==25000000
candidate=f['office']['candidates'][2];key=str(uuid4());body={'candidateId':candidate['id'],'version':f['office']['version']}
first=c.call('/clubs/c3/financial-director','POST',body,key=key);assert c.call('/clubs/c3/financial-director','POST',body,key=key)==first
c.call('/clubs/c2/financial-director','POST',body,status=403)
for day in range(20):
 club=c.call('/clubs/c3');c.call('/clubs/c3/advance-day','POST',{'version':club['version']})
 if day in [5,12,19]:print('Reached',day+2,'September',flush=True)
f=c.call('/clubs/c3/finances');assert len(f['agreements'])==6 and len(f['season']['offers'])==12 and len(f['season']['grants'])==2 and f['season']['members']>0
assert f['income']==sum(m['amount'] for m in f['movements'] if m['amount']>0)
assert f['expenses']==-sum(m['amount'] for m in f['movements'] if m['amount']<0)
assert f['balance']==25000000+sum(m['amount'] for m in f['movements'])
assert all(m['type'] in f['breakdown'] for m in f['movements'])
rival=c.call('/clubs/c2/finances');assert rival['season']['campaignComplete'] and rival['agreements']
club=c.call('/clubs/c3');options=c.call('/clubs/c3/friendly-options?date='+club['date'])['items'];fixture=c.call('/clubs/c3/friendlies','POST',{'date':club['date'],'opponentId':options[0]['id'],'venue':'home','version':club['version']})
m=c.call('/matches','POST',{'fixtureId':fixture['id']},status=201)
c.call('/matches/'+m['id']+'/ticketing','PUT',{'version':m['version'],'ticketPrice':5001},status=422)
price_key=str(uuid4());m=c.call('/matches/'+m['id']+'/ticketing','PUT',{'version':m['version'],'ticketPrice':1250},key=price_key);assert c.call('/matches/'+m['id']+'/ticketing','PUT',{},key=price_key)==m
preview=c.call('/matches/'+m['id']+'/ticketing');assert preview['editable'] and preview['forecast']['ticketPrice']==1250
artifact_path('finance-ui.json').write_text(json.dumps({'username':username,'password':password,'game':c.game,'matchId':m['id'],'fixtureId':fixture['id']}),encoding='utf-8')
artifact_path('finance-http-traces.json').write_text(json.dumps(c.trace),encoding='utf-8')
artifact_path('finance-http-summary.json').write_text(json.dumps({'season':f['season'],'agreements':f['agreements'],'balance':f['balance'],'rivalMembers':rival['season']['members'],'ticketing':preview},ensure_ascii=False,indent=2),encoding='utf-8')
print('PASS HTTP director hire and retry, ownership, full September automation, rival finances, exact ledger, ticket validation and saved cents; match remains scheduled',flush=True)
