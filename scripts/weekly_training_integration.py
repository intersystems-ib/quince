"""Recurring weekly coaching checks on a disposable instance only."""
from session_integration import Client,BASE
from test_paths import artifact_path
from uuid import uuid4
from datetime import date
import json,secrets,time

assert ':52776/' in BASE,'Use the disposable instance'
c=Client();username='weekly_'+uuid4().hex[:10];password=secrets.token_urlsafe(24)
c.call('/auth/register','POST',{'username':username,'password':password})
c.game=c.call('/games','POST',{'name':'Plan semanal del club','clubId':'c1','divisionId':416})
c.call('/games/'+c.game['id']+'/load','POST',{})
p=c.call('/clubs/c1/training-plan');assert p['weeklyConfigured'] and p['mode']=='weekly'
assert len(p['weekly']['senior'])==len(p['weekly']['academy'])==7
original=json.loads(json.dumps(p['weekly']))
for days in [[],[{'day':1,'theme':'attack'}]*7]:
 bad={'senior':days,'academy':original['academy']}
 c.call('/clubs/c1/training-plan','PUT',{'version':p['version'],'mode':'weekly','weekly':bad},status=422)
week={'senior':[{'day':i+1,'theme':t} for i,t in enumerate(['rest','physical','attack','defense','setPieces','technique','rest'])],'academy':[{'day':i+1,'theme':t} for i,t in enumerate(['technique','rest','defense','attack','physical','setPieces','rest'])]}
body={'version':p['version'],'mode':'weekly','weekly':week};key=str(uuid4());saved=c.call('/clubs/c1/training-plan','PUT',body,key=key)
assert saved==c.call('/clubs/c1/training-plan','PUT',body,key=key)
c.call('/clubs/c1/training-plan','PUT',body,status=409)
c.call('/clubs/c2/training-plan','PUT',{'version':1,'mode':'weekly','weekly':week},status=403)
players=c.call('/clubs/c1/players')['items'];ids={x['id']:x for x in players}
assert {i for g in saved['nextGroups'] for i in g['playerIds']}==set(ids)
themes={t['id']:t for t in saved['themes']};seen=[]
for n in range(14):
 club=c.call('/clubs/c1');key=str(uuid4());body={'version':club['version']};updated=c.call('/clubs/c1/advance-day','POST',body,key=key)
 assert updated==c.call('/clubs/c1/advance-day','POST',body,key=key)
 execution=c.call('/clubs/c1/training-executions?limit=1')['items'][0]
 assert execution['mode']=='weekly' and execution['weekly']==week and execution['trainingCost']==0
 assert len(execution['results'])==len(ids) and len({r['playerId'] for r in execution['results']})==len(ids)
 weekday=date.fromisoformat(updated['date']).weekday()
 for g in execution['groups']:
  cat=g['category'];theme=week[cat][weekday]['theme'];assert g['theme']==theme
  expected=themes[theme][g['positionGroup']].split(',')[weekday]
  assert g['focus'] in [expected,'recovery']
 seen.append({'date':updated['date'],'themes':[week[k][weekday]['theme'] for k in ['senior','academy']],'groups':len(execution['groups'])})
 assert c.call('/clubs/c1/training-plan')['weekly']==week
print('PASS fourteen daily advances: recurring weeks, distinct position drills and academy schedule, recovery, complete squads, exact retries, no training fees',flush=True)
artifact_path('weekly-ui.json').write_text(json.dumps({'username':username,'password':password,'game':c.game}),encoding='utf-8')
artifact_path('weekly-http-traces.json').write_text(json.dumps(c.trace),encoding='utf-8')
artifact_path('weekly-http-summary.json').write_text(json.dumps({'weekly':week,'days':seen,'saved':saved},indent=2),encoding='utf-8')
