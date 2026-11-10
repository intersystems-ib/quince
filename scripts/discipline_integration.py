"""Set up and inspect disciplinary scenarios in a disposable instance only."""
from test_paths import artifact_path
import argparse
import json
import secrets
from pathlib import Path
from uuid import uuid4
from session_integration import Client,BASE

def run(mode):
    assert ':52776/' in BASE,'Use the disposable discipline instance.'
    c=Client();path=artifact_path('discipline-ui.json')
    if mode=='setup':
        creds={'username':'cards_'+uuid4().hex[:10],'password':secrets.token_urlsafe(20)}
        c.call('/auth/register','POST',creds)
        c.game=c.call('/games','POST',{'name':'Prueba de tarjetas','clubId':'c1','divisionId':416})
        c.call('/games/'+c.game['id']+'/load','POST',{})
        club=c.call('/clubs/c1');opponent=c.call('/clubs/c1/friendly-options?date='+club['date'])['items'][0]
        f=c.call('/clubs/c1/friendlies','POST',{'version':club['version'],'date':club['date'],'opponentId':opponent['id'],'venue':'home'})
        m=c.call('/matches','POST',{'fixtureId':f['id']},status=201);c.call('/matches/'+m['id']+'/start','POST',{})
        c.call('/games/'+c.game['id']+'/unload','POST',{})
        path.write_text(json.dumps({**creds,'game':c.game,'matchId':m['id']}),encoding='utf-8')
        script=f'''set %RugbyGame="{c.game['id']}",%RugbyManagedClub="c1"
lock +^RugbyWrite:10
tstart
set m=##class(Rugby.Service.Store).Get("Match","{m['id']}"),m.clock=1200,m.speed=1,m.credit=0,p=m.homePlayers.%Get(5),q=m.awayPlayers.%Get(6)
set ok=##class(Rugby.Simulation.Discipline).Card(m,"home",p.playerId,"yellow"),ok=##class(Rugby.Simulation.Discipline).Card(m,"away",q.playerId,"red")
for side="home","away" {{ set players=m.%Get(side_"Players") for i=0:1:players.%Size()-1 {{ do ##class(Rugby.Service.Store).Put("MatchPlayer",players.%Get(i)) }} }}
do ##class(Rugby.Service.Store).Put("Match",m)
tcommit
lock -^RugbyWrite
write "PASS test yellow and red scenario persisted",!
halt
'''
        artifact_path('discipline-inject.script').write_text(script,encoding='utf-8')
        print('PASS disposable match prepared',flush=True)
    else:
        creds=json.loads(path.read_text(encoding='utf-8'));c.call('/auth/login','POST',{k:creds[k] for k in ['username','password']});c.game=creds['game']
        m=c.call('/matches/'+creds['matchId']);p=m['homePlayers'][5];q=m['awayPlayers'][6]
        assert p['status']=='sinBin' and p['sinBinUntil']==1800 and q['status']=='sentOff'
        assert sum(p['status']=='field' for p in m['homePlayers'])==14 and sum(p['status']=='field' for p in m['awayPlayers'])==14
        assert m['homeStats']['yellowCards']==1 and m['awayStats']['redCards']==1
        c.call('/matches/'+m['id']+'/commands','POST',{'type':'substitution','outId':p['playerId'],'inId':m['homePlayers'][15]['playerId']},status=422)
        events=c.call('/matches/'+m['id']+'/events?limit=500')['items'];assert {'yellowCard','redCard'}<={e['type'] for e in events}
        artifact_path('discipline-http-traces.json').write_text(json.dumps(c.trace),encoding='utf-8')
        print('PASS API suspension, expiry, permanent dismissal, 14 vs 14, card statistics, substitution rejection and narrated card events',flush=True)

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('mode',choices=['setup','check']);run(parser.parse_args().mode)
