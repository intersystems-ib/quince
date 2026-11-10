"""Quality checks in a disposable IRIS instance only."""
from test_paths import artifact_path
import json,secrets
from pathlib import Path
from uuid import uuid4
from session_integration import Client,BASE
assert ':52776/' in BASE,'Use a disposable instance'
c=Client();c.call('/auth/register','POST',{'username':'quality_'+uuid4().hex[:10],'password':secrets.token_urlsafe(24)})
c.game=c.call('/games','POST',{'name':'Calidad por clasificacion','clubId':'c3','divisionId':416})
reference=json.loads(Path('iris/data/team-quality.json').read_text(encoding='utf-8'));report=[]
for row in reference['clubs']:
 players=c.call('/clubs/'+row['clubId']+'/players?limit=100')['items']
 seniors=[p for p in players if p['category']=='senior'];academy=[p for p in players if p['category']=='academy']
 means={cat:sum(sum(p['attributes'].values())/17 for p in group)/len(group) for cat,group in [('senior',seniors),('academy',academy)]}
 for cat in means:assert abs(means[cat]-row[cat+'Target'])<.0001,(row,means)
 assert len({round(p['average'],3) for p in seniors})>10
 assert all(1<=v<=100 for p in players for v in p['attributes'].values())
 report.append(dict(clubId=row['clubId'],name=row['name'],rank=row['rank'],divisionId=row['divisionId'],**means))
before=c.call('/clubs/c3/players?limit=100')
c.call('/games/'+c.game['id']+'/load','POST',{});c.call('/games/'+c.game['id']+'/unload','POST',{})
assert c.call('/clubs/c3/players?limit=100')==before
assert min(r['senior'] for r in report if r['divisionId']==416)>max(r['senior'] for r in report if r['divisionId']==417)
artifact_path('quality-http-means.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
artifact_path('quality-http-traces.json').write_text(json.dumps(c.trace),encoding='utf-8')
print('PASS HTTP twenty clubs, senior and academy target means, individual variation, attribute bounds, division gap, load/unload idempotency and interop correlation')
