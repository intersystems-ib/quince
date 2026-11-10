"""Free-agent contracts against a disposable IRIS instance; never use a live save."""
from test_paths import artifact_path
import json
import secrets
from pathlib import Path
from uuid import uuid4
from session_integration import Client, BASE

def run():
    assert ':52776/' in BASE, 'This check requires the disposable test instance.'
    a=Client();password=secrets.token_urlsafe(20);username='transfer_'+uuid4().hex[:10]
    a.call('/auth/register','POST',{'username':username,'password':password})
    a.game=a.call('/games','POST',{'name':'Prueba fichajes','clubId':'c1','divisionId':416})
    a.call('/games/'+a.game['id']+'/load','POST',{})
    artifact_path('transfers-ui.json').write_text(json.dumps({'username':username,'password':password}),encoding='utf-8')
    market=a.call('/transfer-market?limit=500')['items'];assert any(p['nationalityCode']=='ES' for p in market) and any(p['nationalityCode']!='ES' for p in market)
    p=next(p for p in market if p['nationalityCode']!='ES');before=a.call('/clubs/c1');count=a.call('/clubs/c1/players')['total']
    key=str(uuid4());n=a.call('/players/'+p['id']+'/negotiate','POST',{'version':p['version']},key=key)
    assert n==a.call('/players/'+p['id']+'/negotiate','POST',{'version':p['version']},key=key)
    assert 'reservationWage' not in n and 'reservationWage' not in json.dumps(a.call('/negotiations'))
    assert a.call('/negotiations/'+n['id']+'/sign','POST',{'version':n['version']},status=409)['code']=='NEGOTIATION_STATE'
    for invalid in [-1,12345,5000100,'1200']:
        a.call('/negotiations/'+n['id']+'/offer','POST',{'version':n['version'],'weeklyWage':invalid},status=422)
    old=n['version'];key=str(uuid4());body={'version':old,'weeklyWage':100}
    n=a.call('/negotiations/'+n['id']+'/offer','POST',body,key=key);assert n['status']=='counteroffer'
    assert n==a.call('/negotiations/'+n['id']+'/offer','POST',body,key=key)
    assert a.call('/clubs/c1')['balance']==before['balance'] and a.call('/clubs/c1/players')['total']==count
    assert a.call('/negotiations/'+n['id']+'/offer','POST',{'version':old,'weeklyWage':p['askingWeeklyWage']},status=409)['code']=='VERSION_CONFLICT'
    n=a.call('/negotiations/'+n['id']+'/offer','POST',{'version':n['version'],'weeklyWage':n['counterWeeklyWage']});assert n['status']=='agreed'
    agreed=n['agreedWeeklyWage'];key=str(uuid4());body={'version':n['version']}
    signed=a.call('/negotiations/'+n['id']+'/sign','POST',body,key=key);assert signed['status']=='signed'
    assert signed==a.call('/negotiations/'+n['id']+'/sign','POST',body,key=key)
    after=a.call('/clubs/c1');assert after['balance']==before['balance']-n['signingFee'] and after['date']==before['date']
    player=a.call('/players/'+p['id']);assert player['clubId']=='c1' and player['weeklyWage']==agreed and player['attributes']==p['attributes'] and player['energy']==p['energy']
    assert a.call('/clubs/c1/players')['total']==count+1
    assert p['id'] not in [x['id'] for x in a.call('/transfer-market?limit=500')['items']]
    movements=a.call('/clubs/c1/financial-movements')['items'];assert sum(m['source']=='sign-'+n['id'] for m in movements)==1
    a.call('/players/'+p['id']+'/negotiate','POST',{'version':player['version']},status=409)
    q=next(p for p in market if p['nationalityCode']=='ES');n=a.call('/players/'+q['id']+'/negotiate','POST',{'version':q['version']})
    for _ in range(5): n=a.call('/negotiations/'+n['id']+'/offer','POST',{'version':n['version'],'weeklyWage':100})
    assert n['status']=='rejected'
    assert a.call('/players/'+q['id']+'/negotiate','POST',{'version':q['version']},status=409)['code']=='NEGOTIATION_COOLDOWN'
    q=next(x for x in market if x['id'] not in [p['id'],q['id']]);n=a.call('/players/'+q['id']+'/negotiate','POST',{'version':q['version']})
    assert a.call('/negotiations/'+n['id']+'/withdraw','POST',{'version':n['version']})['status']=='withdrawn'
    b=Client();b.call('/auth/register','POST',{'username':'other_'+uuid4().hex[:10],'password':password});b.game=a.game;b.call('/negotiations/'+n['id'],status=404)
    other=a.call('/games','POST',{'name':'Otra partida','clubId':'c2','divisionId':416});saved=a.game;a.game=other
    a.call('/negotiations/'+n['id'],status=404);assert a.call('/players/'+p['id'])['clubId']==''
    a.game=saved
    artifact_path('transfers-http-traces.json').write_text(json.dumps(a.trace+b.trace),encoding='utf-8')
    print('PASS mixed nationalities, offers, counters, salary agreement, explicit signature, ledger, retries, validation, rejection, withdrawal and save/account isolation',flush=True)

if __name__=='__main__':run()

