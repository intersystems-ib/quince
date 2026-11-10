"""Verify real squads in disposable saves; refuses the live application."""
from test_paths import artifact_path
import json
import secrets
from pathlib import Path
from uuid import uuid4
from session_integration import Client,BASE

def run():
    assert ':52776/' in BASE,'Use the disposable IRIS instance.'
    c=Client();creds={'username':'rosters_'+uuid4().hex[:10],'password':secrets.token_urlsafe(20)}
    c.call('/auth/register','POST',creds)
    artifact_path('real-rosters-ui.json').write_text(json.dumps(creds),encoding='utf-8')
    catalog=json.loads(Path('iris/data/real-rosters.json').read_text(encoding='utf-8'))
    first=None
    for own,division in [('c1',416),('c18',417)]:
        c.game=c.call('/games','POST',{'name':f'Plantillas reales {division}','clubId':own,'divisionId':division})
        c.call('/games/'+c.game['id']+'/load','POST',{})
        if first is None:first=c.game
        count=0
        for team in catalog['teams']:
            rows=c.call('/clubs/'+team['clubId']+'/players')['items'];players={p['id']:p for p in rows}
            for source in team['players']:
                p=players[source['id']];count+=1
                assert p['name']==source['name'] and p['realIdentity'] is True
                assert p['identitySourceFile']==team['sourceFile'] and p['identitySourcePage']==1
                assert p['nationalityCode']=='' and p['nationality']=='No verificada'
                assert p['position']==source['position'] and 'number' not in p
            assert sum(p['category']=='academy' for p in rows)>=20
        assert count==460
        source=next(t for t in catalog['teams'] if t['clubId']==own)['players'][0]
        detail=c.call('/players/'+source['id']);assert detail['name']==source['name'] and detail['average']>0
        lineups=c.call('/clubs/'+own+'/lineups')['items'];assert c.call('/lineups/'+lineups[0]['id']+'/validate','POST',{})['valid']
        options=c.call('/clubs/'+own+'/friendly-options?date=2026-09-01')['items'];club=c.call('/clubs/'+own)
        fixture=c.call('/clubs/'+own+'/friendlies','POST',{'version':club['version'],'date':club['date'],'opponentId':options[0]['id'],'venue':'home'})
        match=c.call('/matches','POST',{'fixtureId':fixture['id']},status=201)
        match=c.call('/matches/'+match['id']+'/start','POST',{})
        assert match['homePlayers'][0]['name']==source['name']
        assert len({p['playerId'] for p in match['homePlayers']})==len(match['homePlayers'])
        c.call('/games/'+c.game['id']+'/unload','POST',{})
        print('PASS',division,'460 identities, academy intact, own roster, provenance, legal lineup and match names',flush=True)
    artifact_path('real-rosters-ui.json').write_text(json.dumps({**creds,'gameId':first['id']}),encoding='utf-8')
    artifact_path('real-rosters-http-traces.json').write_text(json.dumps(c.trace),encoding='utf-8')

if __name__=='__main__':run()
