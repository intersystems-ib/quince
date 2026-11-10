"""Additional production checks against the explicitly named disposable IRIS instance."""
from test_paths import artifact_path
import json
import os
import subprocess
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import urlopen
from session_integration import Client, BASE

assert BASE=='http://localhost:52776/api/v1','Run only against rugby-interop-check'
qa=json.loads(artifact_path('session-qa.json').read_text(encoding='utf-8'))
c=Client();c.call('/auth/login','POST',{'username':qa['username'],'password':qa['password']})
c.game=c.call('/games','POST',{'name':'Interoperabilidad · prueba','divisionId':416,'clubId':'c1'})
c.call('/games/'+c.game['id']+'/load','POST',{})
club=c.call('/clubs/c1');plan=c.call('/clubs/c1/training-plan')
saved=c.call('/clubs/c1/training-plan','PUT',{'version':plan['version'],'groups':[{'id':'interop-strength','name':'Fuerza · jóvenes','focus':'strength','intensity':'normal','playerIds':['c1-p1']}]})
assert saved['groups'][0]['name']=='Fuerza · jóvenes'
staff=c.call('/clubs/c1/staff');market=c.call('/staff-market')['items'];candidate=max((t for t in market if t['role']=='academy'),key=lambda t:t['quality'])
hired=c.call('/clubs/c1/staff','POST',{'version':staff['version'],'coachId':candidate['id']})
assert any(t['id']==candidate['id'] for t in hired['coaches'])
after=c.call('/clubs/c1/advance-day','POST',{'version':club['version']});assert after['date']=='2026-09-02'
c.call('/clubs/c1/advance-day','POST',{'version':club['version']},status=409)
assert c.call('/clubs/c1')['date']==after['date']
for resource in ('bootstrap','simulation'):
    c.call('/'+resource,'POST',{'Channel':'system'},status=404)
print('PASS training, UTF-8, staff, day progress, version conflicts and internal-channel isolation',flush=True)

# A stopped production must reject requests; the HTTP class must never run business logic directly.
def terminal(code):
    r=subprocess.run(['docker','exec','-i','rugby-interop-check','iris','session','IRIS','-U','RUGBY'],input=code+'\nhalt\n',text=True,capture_output=True,check=True)
    assert '<' not in r.stdout,r.stdout
terminal('set sc=##class(Ens.Director).StopProduction(30)\nwrite $system.Status.GetErrorText(sc),!')
try:
    with urlopen(BASE+'/health',timeout=10):raise AssertionError('Stopped engine accepted a request')
except HTTPError as e:
    assert e.code==503 and json.load(e)['code']=='INTEROP_UNAVAILABLE'
terminal('do ##class(Rugby.Interop.Runtime).Start()')
restored=c.call('/clubs/c1');assert restored['date']==after['date'] and restored['balance']==after['balance']
print('PASS production stop/restart, no bypass and preservation of save state',flush=True)
c.call('/games/'+c.game['id']+'/unload','POST',{});c.call('/auth/logout','POST',{})
artifact_path('interop-extended-traces.json').write_text(json.dumps(c.trace),encoding='utf-8')
