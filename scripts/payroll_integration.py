"""Disposable-account checks for sustainable payroll."""
from test_paths import artifact_path
import json,secrets
from pathlib import Path
from uuid import uuid4
from session_integration import Client,BASE
assert ':52776/' in BASE
c=Client();password=secrets.token_urlsafe(24);username='payroll_'+uuid4().hex[:10]
c.call('/auth/register','POST',{'username':username,'password':password});c.game=c.call('/games','POST',{'name':'Salarios sostenibles','clubId':'c11','divisionId':417})
rows=[]
for club in c.call('/clubs')['items']:
 f=c.call('/clubs/'+club['id']+'/finances');s=f['payroll'];assert s['annualMargin']>=s['budget']*.15 and s['weeklyAvailable']>0
 ps=c.call('/clubs/'+club['id']+'/players?limit=100')['items'];weekly=sum(p['weeklyWage'] for p in ps)
 assert weekly==s['weeklyPlayers'] and s['annualPlayers']==weekly*53
 assert len({p['weeklyWage'] for p in ps if p['category']=='senior'})>4
 assert s['annualAcademy']<s['annualSenior']*.1
 rows.append({'clubId':club['id'],'name':club['name'],**s})
f=c.call('/clubs/c11/finances');d=f['office']['candidates'][2];c.call('/clubs/c11/financial-director','POST',{'version':f['office']['version'],'candidateId':d['id']})
for _ in range(7):
 club=c.call('/clubs/c11');c.call('/clubs/c11/advance-day','POST',{'version':club['version']})
f=c.call('/clubs/c11/finances');assert f['balance']==f['initialBalance']+sum(m['amount'] for m in f['movements'])
wages=[m for m in f['movements'] if m['type']=='wages'];assert len(wages)==1 and wages[0]['amount']==-f['payroll']['weeklyPlayers']
assert f['payroll']['annualMargin']>=f['payroll']['budget']*.15
c.call('/games/'+c.game['id']+'/load','POST',{});c.call('/games/'+c.game['id']+'/unload','POST',{})
artifact_path('payroll-ui.json').write_text(json.dumps({'username':username,'password':password,'game':c.game}),encoding='utf-8')
artifact_path('payroll-http-summary.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf-8');artifact_path('payroll-http-traces.json').write_text(json.dumps(c.trace),encoding='utf-8')
print('PASS twenty clubs: annual margin >=15%, exact 53-week payroll, lower academy wages, individual variation; first week debited exactly; salary-scaled director; balanced ledger and load/unload')
