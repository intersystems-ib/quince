"""Exercise disposable accounts/saves. Does not touch any existing user's saves."""
from test_paths import artifact_path
import base64
import json
import os
import secrets
import time
from http.cookiejar import CookieJar
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import HTTPCookieProcessor, Request, build_opener
from uuid import uuid4

BASE=os.environ.get('RUGBY_API_BASE','http://localhost:5175/api/v1')
class Client:
    def __init__(self):
        self.cookies=CookieJar();self.opener=build_opener(HTTPCookieProcessor(self.cookies));self.game=None;self.trace=[]
    def call(self,path,method='GET',body=None,status=200,key=None,extra=None):
        headers={'Content-Type':'application/json','Idempotency-Key':key or str(uuid4())}
        if self.game:headers['X-Game-Id']=self.game['id']
        headers.update(extra or {})
        request=Request(BASE+path,method=method,data=None if body is None else json.dumps(body).encode(),headers=headers)
        try:
            with self.opener.open(request,timeout=120) as r:actual=r.status;result=json.load(r);session=r.headers.get("X-Interop-Session-Id");correlation=r.headers.get("X-Request-Id")
        except HTTPError as e:actual=e.code;result=json.load(e);session=e.headers.get("X-Interop-Session-Id");correlation=e.headers.get("X-Request-Id")
        assert actual==status,(path,actual,result)
        if os.environ.get("RUGBY_REQUIRE_INTEROP"):
            assert session and correlation,(path,"missing native interop correlation")
            self.trace.append({"path":path,"status":actual,"sessionId":session,"requestId":correlation})
        return result

def run():
    a,b=Client(),Client();suffix=uuid4().hex[:10];password=secrets.token_urlsafe(20)
    a.call('/clubs',status=401)
    user=a.call('/auth/register','POST',{'username':'qa_'+suffix,'password':password})['user']
    artifact_path('session-qa.json').write_text(json.dumps({'username':user['username'],'password':password,'users':[user['id']],'games':[]}),encoding='utf-8')
    cookie=next(c for c in a.cookies if c.name=='rugby_session');token=cookie.value
    assert 'HttpOnly' in cookie._rest and cookie._rest.get('SameSite')=='Strict'
    claims=json.loads(base64.urlsafe_b64decode(token.split('.')[1]+'==='));assert claims['sub']==user['id'] and claims['exp']>time.time()
    assert a.call('/auth/me')['id']==user['id']
    a.call('/clubs',status=404)  # a save is mandatory
    a.call('/auth/me',status=401,extra={'Authorization':'Bearer '+token[:-3]+'!!!'})
    a.call('/auth/logout','POST',{})
    a.call('/auth/me',status=401,extra={'Authorization':'Bearer '+token})
    a.call('/auth/login','POST',{'username':user['username'],'password':password+'x'},status=401)
    a.call('/auth/login','POST',{'username':user['username'],'password':password})
    print('PASS registration, login, HttpOnly JWT, signature, logout revocation and required game',flush=True)
    game_key=str(uuid4());g1=a.call('/games','POST',{'name':'Prueba El Salvador B','clubId':'c11','divisionId':417},key=game_key)
    assert a.call('/games','POST',{'name':'Prueba El Salvador B','clubId':'c11','divisionId':417},key=game_key)['id']==g1['id']
    a.game=g1;a.call('/games/'+g1['id']+'/load','POST',{})
    club=a.call('/clubs/c11');assert club['date']=='2026-09-01'
    assert a.call('/clubs/c11/lineups')['items'][0]['clubId']=='c11'
    a.call('/clubs/c1/advance-day','POST',{'version':1},status=403)
    options=a.call('/clubs/c11/friendly-options?date=2026-09-01')['items'];assert len(options)==len({c['id'] for c in options})==3 and len({c['competitionId'] for c in options})==2
    assert a.call('/clubs/c11/friendly-options?date=2026-09-01')['items']==options
    a.call('/clubs/c11/friendly-options?date=2026-08-31',status=422)
    payload={'date':'2026-09-01','opponentId':options[0]['id'],'venue':'away','version':club['version']};key=str(uuid4())
    friendly=a.call('/clubs/c11/friendlies','POST',payload,key=key)
    assert a.call('/clubs/c11/friendlies','POST',payload,key=key)['id']==friendly['id']
    assert friendly['awayId']=='c11' and any(f['id']==friendly['id'] for f in a.call('/clubs/c11/fixtures')['items'])
    a.call('/clubs/c11/friendlies','POST',payload,status=409)
    assert a.call('/clubs/c11/advance-day','POST',{'version':club['version']},status=409)['code']=='MATCH_PENDING'
    assert next(f for f in a.call('/clubs/c11/fixtures')['items'] if f['id']==friendly['id'])['date']=='2026-09-01'
    m=a.call('/matches','POST',{'fixtureId':friendly['id']},status=201);a.call('/matches/'+m['id']+'/start','POST',{})
    a.call('/matches/'+m['id']+'/commands','POST',{'type':'speed','speed':60})
    for _ in range(20):
        time.sleep(.3);state=a.call('/matches/'+m['id'])
        if state['clock']>0:break
    assert state['clock']>0
    a.call('/games/'+g1['id']+'/unload','POST',{});clock=a.call('/matches/'+m['id'])['clock'];time.sleep(.8);assert a.call('/matches/'+m['id'])['clock']==clock
    print('PASS chosen Elite club, mixed opponents, away friendly, calendar conflicts, dates and paused match worker',flush=True)
    g2=a.call('/games','POST',{'name':'Prueba Honor','clubId':'c2','divisionId':416});a.game=g2;a.call('/games/'+g2['id']+'/load','POST',{})
    assert a.call('/clubs/c2')['date']=='2026-09-01'
    assert a.call('/clubs/c11')['date']=='2026-09-01'
    options2=a.call('/clubs/c2/friendly-options?date=2026-09-01')['items'];c2=a.call('/clubs/c2')
    f2=a.call('/clubs/c2/friendlies','POST',{'date':'2026-09-01','opponentId':options2[0]['id'],'venue':'home','version':c2['version']})
    m2=a.call('/matches','POST',{'fixtureId':f2['id']},status=201);started=a.call('/matches/'+m2['id']+'/start','POST',{})
    assert started['id']==m['id'] and started['homeId']=='c2'
    assert len(a.call('/games')['items'])==2
    other=b.call('/auth/register','POST',{'username':'qb_'+suffix,'password':secrets.token_urlsafe(20)})['user'];b.game=g1
    b.call('/games/'+g1['id']+'/load','POST',{},status=404);b.call('/clubs/c11',status=404);assert b.call('/games')['items']==[]
    a.game=g1;a.call('/games/'+g1['id']+'/load','POST',{});assert a.call('/clubs/c11')['date']=='2026-09-01'
    a.call('/games/'+g1['id']+'/unload','POST',{});a.call('/auth/logout','POST',{});b.call('/auth/logout','POST',{})
    print('PASS independent saves, duplicate match IDs, loading and cross-account isolation',flush=True)
    artifact_path('session-qa.json').write_text(json.dumps({'username':user['username'],'password':password,'users':[user['id'],other['id']],'games':[g1['id'],g2['id']]}),encoding='utf-8')
    artifact_path('interop-http-traces.json').write_text(json.dumps(a.trace+b.trace),encoding='utf-8')

if __name__=='__main__':run()
