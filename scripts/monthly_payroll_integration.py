"""Check salary bands and monthly negotiations on a disposable instance only."""
from test_paths import artifact_path
from session_integration import Client,BASE
from uuid import uuid4
import json,secrets

assert ':52776/' in BASE,'Use disposable instance'
c=Client();username='monthly_'+uuid4().hex[:10];password=secrets.token_urlsafe(24)
c.call('/auth/register','POST',{'username':username,'password':password})
c.game=c.call('/games','POST',{'name':'Salarios mensuales','clubId':'c7','divisionId':416})
clubs=c.call('/clubs')['items'];report=[];roster=[]
for club in clubs:
    players=c.call('/clubs/'+club['id']+'/players')['items']
    rank=club.get('qualityReferenceRank',5)
    lo,hi=((85000,240000) if rank<=3 else (80000,200000) if rank<=7 else (45000,140000)) if club['competitionId']==416 else (30000,110000)
    seniors=[p for p in players if p['category']=='senior'];youth=[p for p in players if p['category']=='academy']
    assert all(lo<=p['monthlyWage']<=hi for p in seniors)
    assert all(3000<=p['monthlyWage']<=10000 for p in youth)
    assert all(abs(p['monthlyWage']-round(p['weeklyWage']*52/12))<=1 for p in players)
    assert len({p['monthlyWage'] for p in seniors})>1
    finance=c.call('/clubs/'+club['id']+'/finances');p=finance['payroll']
    assert p['budget']==p['budgetReference'] and p['annualMargin']>=p['annualSafetyReserve']
    assert finance['balance']==finance['initialBalance']+sum(m['amount'] for m in finance['movements'])
    report.append({'clubId':club['id'],'club':club['name'],'rank':rank,'budget':p['budgetReference'],'monthlyMin':min(p['monthlyWage'] for p in seniors),'monthlyMax':max(p['monthlyWage'] for p in seniors),'annualCosts':p['annualProjectedCosts'],'annualMargin':p['annualMargin'],'fundingReference':finance['fundingReference'],'securedIncome':finance['securedAnnualIncome']})
    if club['id']=='c7':roster=seniors;own_finance=finance
p=max((p for p in roster if not p.get('retirementAnnounced')),key=lambda p:p['weeklyWage'])
n=c.call('/players/'+p['id']+'/renew','POST',{'version':p['version']})
c.call('/negotiations/'+n['id']+'/offer','POST',{'version':n['version'],'weeklyWage':10000,'monthlyWage':200000},status=422)
c.call('/negotiations/'+n['id']+'/offer','POST',{'version':n['version'],'monthlyWage':'200000'},status=422)
key=str(uuid4());body={'version':n['version'],'monthlyWage':200000}
n=c.call('/negotiations/'+n['id']+'/offer','POST',body,key=key)
assert n==c.call('/negotiations/'+n['id']+'/offer','POST',body,key=key)
assert n['status']=='agreed' and n['agreedWeeklyWage']==46154
allowed=own_finance['payroll']['weeklyAvailable']+p['weeklyWage']>=46154
if allowed:
    balance=c.call('/clubs/c7')['balance'];key=str(uuid4());body={'version':n['version']}
    signed=c.call('/negotiations/'+n['id']+'/sign','POST',body,key=key)
    assert signed==c.call('/negotiations/'+n['id']+'/sign','POST',body,key=key)
    player=c.call('/players/'+p['id']);assert abs(player['monthlyWage']-200000)<=3
    assert c.call('/clubs/c7')['balance']==balance
else:
    c.call('/negotiations/'+n['id']+'/sign','POST',{'version':n['version']},status=409)
artifact_path('monthly-ui.json').write_text(json.dumps({'username':username,'password':password,'game':c.game},ensure_ascii=False),encoding='utf-8')
artifact_path('monthly-http-summary.json').write_text(json.dumps({'clubs':report,'monthlyOfferWeeklyCents':n['agreedWeeklyWage'],'renewalWithinBudget':allowed},ensure_ascii=False,indent=2),encoding='utf-8')
artifact_path('monthly-http-traces.json').write_text(json.dumps(c.trace),encoding='utf-8')
print('PASS all 20 club bands, academy wages, varied monthly salaries, nominal budget reserve, exact ledger, monthly offer conversion and retries; renewal allowed:',allowed)
