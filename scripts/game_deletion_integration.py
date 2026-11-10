"""Delete only freshly created saves on the disposable verification instance."""
from test_paths import artifact_path
from session_integration import Client,BASE
from uuid import uuid4
import json,secrets

assert ':52776/' in BASE,'Use disposable instance'
a,b=Client(),Client();suffix=uuid4().hex[:10];password=secrets.token_urlsafe(24)
a.call('/auth/register','POST',{'username':'deletion_'+suffix,'password':password})
create_key=str(uuid4());body={'name':'Eliminar prueba','clubId':'c1','divisionId':416}
first=a.call('/games','POST',body,key=create_key);a.game=first
first_player=a.call('/players/c1-p1')
sibling=a.call('/games','POST',{'name':'Conservar prueba','clubId':'c2','divisionId':416});a.game=sibling
player=a.call('/players/c1-p1');club=a.call('/clubs/c2')
b.call('/auth/register','POST',{'username':'other_'+suffix,'password':secrets.token_urlsafe(24)})
foreign=b.call('/games','POST',{'name':'Otra cuenta','clubId':'c11','divisionId':417});b.game=foreign
foreign_club=b.call('/clubs/c11')
b.call('/games/'+first['id'],'DELETE',{'confirm':True},status=404)
a.call('/games/'+foreign['id'],'DELETE',{'confirm':True},status=404)
a.call('/games/'+first['id'],'DELETE',{},status=422)
assert len(a.call('/games')['items'])==2
key=str(uuid4());deleted=a.call('/games/'+first['id'],'DELETE',{'confirm':True},key=key)
assert deleted['deleted'] and deleted['gameId']==first['id'] and deleted['recordsDeleted']>1000
assert a.call('/games/'+first['id'],'DELETE',{'confirm':True},key=key)==deleted
assert a.call('/games/'+first['id'],'DELETE',{'confirm':True})==deleted
assert [g['id'] for g in a.call('/games')['items']]==[sibling['id']]
assert a.call('/players/c1-p1')==player and a.call('/clubs/c2')==club
assert b.call('/clubs/c11')==foreign_club
b.call('/games/'+first['id'],'DELETE',{'confirm':True},status=404)
a.call('/games/'+first['id']+'/load','POST',{},status=404)
a.game=first;a.call('/players/c1-p1',status=404)
a.call('/games','POST',body,key=create_key,status=410)
a.game=sibling;assert a.call('/players/c1-p1')==player
artifact_path('deletion-http-traces.json').write_text(json.dumps(a.trace+b.trace),encoding='utf-8')
artifact_path('deletion-http-summary.json').write_text(json.dumps(deleted,ensure_ascii=False,indent=2),encoding='utf-8')
artifact_path('deletion-ui.json').write_text(json.dumps({'username':'deletion_'+suffix,'password':password,'game':sibling},ensure_ascii=False),encoding='utf-8')
print('PASS owner-only confirmed deletion, removed save inaccessible, retries stable, stale creation blocked, sibling and other account unchanged, native interop correlation')
