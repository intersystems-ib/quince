"""Check salaries and kits in a disposable account; refuses the live application."""
from test_paths import artifact_path
import argparse
import json
import secrets
from pathlib import Path
from uuid import uuid4
from session_integration import Client,BASE

def run(mode):
    assert ':52776/' in BASE,'Use the disposable test instance.'
    path=artifact_path('kits-promotion-ui.json');c=Client()
    if mode=='setup':
        creds={'username':'kits_promo_'+uuid4().hex[:8],'password':secrets.token_urlsafe(20)}
        c.call('/auth/register','POST',creds);c.game=c.call('/games','POST',{'name':'Equipaciones y promociones','clubId':'c1','divisionId':416})
        clubs=c.call('/clubs')['items'];assert len(clubs)==20 and all(x['kits']['primary']['color']!=x['kits']['secondary']['color'] for x in clubs)
        rows=c.call('/clubs/c1/players')['items'];p=next(x for x in rows if x['category']=='academy');before=c.call('/clubs/c1')
        route='/clubs/c1/academy/'+p['id']+'/promote';key=str(uuid4());body={'version':p['version']}
        c.call(route,'POST',{},status=409)
        n=c.call(route,'POST',body,key=key);assert n['kind']=='promotion' and n['status']=='open' and n['signingFee']==0
        assert c.call(route,'POST',body,key=key)['id']==n['id']
        assert c.call('/players/'+p['id'])['category']=='academy'
        c.call('/negotiations/'+n['id']+'/sign','POST',{'version':n['version']},status=409)
        n=c.call('/negotiations/'+n['id']+'/offer','POST',{'version':n['version'],'weeklyWage':100});assert n['status']=='counteroffer'
        n=c.call('/negotiations/'+n['id']+'/offer','POST',{'version':n['version'],'weeklyWage':n['counterWeeklyWage']});assert n['status']=='agreed'
        assert c.call('/players/'+p['id'])['weeklyWage']==p['weeklyWage']
        key=str(uuid4());body={'version':n['version']};signed=c.call('/negotiations/'+n['id']+'/sign','POST',body,key=key)
        assert c.call('/negotiations/'+n['id']+'/sign','POST',body,key=key)==signed
        current=c.call('/players/'+p['id']);assert current['category']=='senior' and current['weeklyWage']==n['agreedWeeklyWage']
        assert current['attributes']==p['attributes'] and current['energy']==p['energy'] and c.call('/clubs/c1/players')['total']==len(rows)
        assert c.call('/clubs/c1')['balance']==before['balance'] and c.call('/clubs/c1')['date']==before['date']
        c.call('/clubs/c2/academy/c2-p24/promote','POST',{'version':1},status=403)
        path.write_text(json.dumps({**creds,'game':c.game}),encoding='utf-8')
        script=f'''set %RugbyGame="{c.game['id']}",%RugbyManagedClub="c1"
lock +^RugbyWrite:10
tstart
set club=##class(Rugby.Service.Store).Get("Club","c1"),f={{"id":"qa-kits-fixture","clubId":"c1","homeId":"c1","awayId":"c2","day":(club.day),"date":(club.date),"stage":"friendly","status":"scheduled","matchId":""}}
do ##class(Rugby.Service.Store).Put("Fixture",f)
tcommit
lock -^RugbyWrite
halt
'''
        artifact_path('kits-promotion-fixture.script').write_text(script,encoding='utf-8')
        print('PASS promotion negotiates before changing category, counteroffer, confirmation, salary, retries, no fees, preserved progress and club authorization',flush=True)
    else:
        data=json.loads(path.read_text(encoding='utf-8'));c.call('/auth/login','POST',{k:data[k] for k in ['username','password']});c.game=data['game']
        match=c.call('/matches','POST',{'fixtureId':'qa-kits-fixture'},status=201)
        assert match['homeKit']['id']=='primary' and match['awayKit']['id']=='secondary' and match['kitClashResolved'] is True
        assert match['homeColor']!=match['awayColor'] and match['homeKit']['numberColor'] in ['#000000','#ffffff']
        again=c.call('/matches/'+match['id']);assert again['homeKit']==match['homeKit'] and again['awayKit']==match['awayKit']
        data['matchId']=match['id'];path.write_text(json.dumps(data),encoding='utf-8')
        print('PASS match selects the visitor second shirt for similar blues and persists readable number colors',flush=True)
    artifact_path('kits-promotion-http-traces-'+mode+'.json').write_text(json.dumps(c.trace),encoding='utf-8')

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('mode',choices=['setup','match']);run(p.parse_args().mode)
