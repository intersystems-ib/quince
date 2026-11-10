"""Medical availability and flexible selection, using a disposable IRIS instance only."""
from test_paths import artifact_path
from session_integration import Client,BASE
import json,secrets,sys
from datetime import date
from uuid import uuid4

assert ':52776/' in BASE,'Use disposable instance'
path=artifact_path('injuries-ui.json')
c=Client()
if len(sys.argv)==1:
    username='injuries_'+uuid4().hex[:10];password=secrets.token_urlsafe(24)
    c.call('/auth/register','POST',{'username':username,'password':password})
    c.game=c.call('/games','POST',{'name':'Lesiones y puestos flexibles','clubId':'c1','divisionId':416})
    types=c.call('/injury-types')['items'];assert len(types)==20
    lineup=c.call('/clubs/c1/lineups')['items'][0]
    lineup['slots'][0]['playerId'],lineup['slots'][1]['playerId']=lineup['slots'][1]['playerId'],lineup['slots'][0]['playerId']
    lineup=c.call('/lineups/'+lineup['id'],'PUT',lineup)
    assert c.call('/lineups/'+lineup['id']+'/validate','POST',{})['valid']
    players=c.call('/clubs/c1/players')['items'];academy=next(p for p in players if p['category']=='academy')
    path.write_text(json.dumps({'username':username,'password':password,'game':c.game,'injuredId':lineup['slots'][0]['playerId'],'academyId':academy['id']},ensure_ascii=False),encoding='utf-8')
    print('PASS injury catalog, login, save and validate exchanged first-row positions')
else:
    qa=json.loads(path.read_text(encoding='utf-8'))
    c.call('/auth/login','POST',{'username':qa['username'],'password':qa['password']});c.game=qa['game']
    injured=c.call('/players/'+qa['injuredId']);youth=c.call('/players/'+qa['academyId'])
    for p in (injured,youth):
        assert not p['available'] and p['injury']['grade']==1 and p['injury']['weeks']==1
        assert (date.fromisoformat(p['injury']['expectedReturn'])-date.fromisoformat(p['injury']['startedOn'])).days==7
        assert p['injury']['remainingWeeks']==1 and p['injury']['remainingDays']==7
    lineup=c.call('/clubs/c1/lineups')['items'][0]
    c.call('/lineups/'+lineup['id'],'PUT',lineup,status=422)
    players=c.call('/clubs/c1/players')['items'];by_id={p['id']:p for p in players}
    replacement=next(pid for pid in lineup['bench'] if by_id[pid]['position']<=8)
    lineup['slots'][0]['playerId']=replacement;lineup['bench'].remove(replacement)
    lineup=c.call('/lineups/'+lineup['id'],'PUT',lineup)
    assert c.call('/lineups/'+lineup['id']+'/validate','POST',{})['valid']
    plan=c.call('/clubs/c1/training-plan')
    plan['groups']=[{'id':'medical-test','name':'Fuerza','focus':'strength','intensity':'normal','playerIds':[injured['id'],youth['id']]}]
    c.call('/clubs/c1/training-plan','PUT',plan)
    club=c.call('/clubs/c1');key=str(uuid4());body={'version':club['version']}
    advanced=c.call('/clubs/c1/advance-day','POST',body,key=key)
    assert c.call('/clubs/c1/advance-day','POST',body,key=key)==advanced
    for original in (injured,youth):
        p=c.call('/players/'+original['id'])
        assert not p['available'] and p['injury']['remainingDays']==6
        assert p['injury']['expectedReturn']==original['injury']['expectedReturn'] and p['attributes']==original['attributes']
    artifact_path('injuries-http-traces.json').write_text(json.dumps(c.trace),encoding='utf-8')
    print('PASS injured seniors and academy excluded, alternative forward selected, no training gains, exact remaining days, forecast read-only and day retry idempotent')
