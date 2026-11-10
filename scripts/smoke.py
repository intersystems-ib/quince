"""Read-only smoke checks plus a deliberately rejected invalid lineup edit."""
import json
from urllib.request import Request,urlopen
from urllib.error import HTTPError

base='http://127.0.0.1:5175/api/v1'
def get(path):
    with urlopen(base+path,timeout=10) as response:return json.load(response)
lineup=get('/clubs/c1/lineups')['items'][0]
lineup['slots'][1]['playerId']=lineup['slots'][0]['playerId']
request=Request(base+'/lineups/'+lineup['id'],data=json.dumps(lineup).encode(),method='PUT',headers={'Content-Type':'application/json'})
try:
    urlopen(request,timeout=10)
    raise AssertionError('Invalid lineup must be rejected')
except HTTPError as error:
    result=json.load(error)
    assert error.code==422 and result['code']=='INVALID_LINEUP'
    assert result['details']['errors'] and result['requestId']
print('PASS final HTTP error schema')
clubs=get('/clubs')['items']
assert len(clubs)==20
assert next(c for c in clubs if c['id']=='c18')['name']=='Barça Rugbi'
assert all(isinstance(c['generatedRoster'],bool) for c in clubs)
print('PASS final official catalog and UTF-8')
assert not get('/health')['workerError']
fixtures=get('/clubs/c1/fixtures')['items']
existing=next((f for f in fixtures if f['matchId']),None)
if existing:
    assert isinstance(get('/matches/'+existing['matchId'])['settled'],bool)
print('PASS worker health and JSON flags')
