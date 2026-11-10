"""Availability cleanup checks on a disposable instance, using fresh accounts only."""
from test_paths import artifact_path
from session_integration import Client,BASE
from uuid import uuid4
import json,secrets,sys

assert ':52776/' in BASE,'Use disposable instance'
c=Client();path=artifact_path('availability-ui.json')
if len(sys.argv)==1:
    username='availability_'+uuid4().hex[:10];password=secrets.token_urlsafe(24)
    c.call('/auth/register','POST',{'username':username,'password':password})
    c.game=c.call('/games','POST',{'name':'Situación y no disponibles','clubId':'c1','divisionId':416})
    lineup=c.call('/clubs/c1/lineups')['items'][0]
    path.write_text(json.dumps({'username':username,'password':password,'game':c.game,'lineup':lineup,'starterId':lineup['slots'][0]['playerId'],'benchId':lineup['bench'][0],'otherId':lineup['bench'][1]},ensure_ascii=False),encoding='utf-8')
    print('PASS disposable availability scenario created')
else:
    qa=json.loads(path.read_text(encoding='utf-8'))
    c.call('/auth/login','POST',{'username':qa['username'],'password':qa['password']});c.game=qa['game']
    lineup=c.call('/clubs/c1/lineups')['items'][0]
    assert qa['benchId'] not in lineup['bench'] and qa['otherId'] not in lineup['bench']
    assert len(lineup['bench'])==6 and lineup['slots'][0]['playerId']==qa['starterId']
    c.call('/lineups/'+lineup['id'],'PUT',lineup,status=422)
    incoming=lineup['bench'][0]
    stale=qa['lineup'];stale['version']=lineup['version'];stale['slots'][0]['playerId']=incoming
    stale['bench']=[qa['starterId'] if pid==incoming else pid for pid in stale['bench']]
    saved=c.call('/lineups/'+lineup['id'],'PUT',stale)
    assert len(saved['bench'])==5
    assert not set(saved['bench'])&{qa['starterId'],qa['benchId'],qa['otherId']}
    assert c.call('/lineups/'+saved['id']+'/validate','POST',{})['valid']
    reloaded=c.call('/clubs/c1/lineups')['items'][0]
    assert reloaded['bench']==saved['bench'] and reloaded['captainId']==saved['captainId'] and reloaded['version']==saved['version']
    assert [(s['position'],s['playerId']) for s in reloaded['slots']]==[(s['position'],s['playerId']) for s in saved['slots']]
    players=c.call('/clubs/c1/players')['items'];by_id={p['id']:p for p in players}
    assert all(not by_id[pid]['available'] for pid in (qa['starterId'],qa['benchId'],qa['otherId']))
    assert by_id[qa['starterId']]['injury'] and by_id[qa['benchId']]['injury'] and not by_id[qa['otherId']].get('injury')
    artifact_path('availability-http-traces.json').write_text(json.dumps(c.trace),encoding='utf-8')
    print('PASS unavailable substitutes removed automatically, unavailable starter blocked until replaced, stale bench safely normalized on save, generic unavailability preserved, native interop correlation')
