"""Verify new development endpoints; restore plan and staff without advancing game time."""
import json
from urllib.request import Request,urlopen
from urllib.error import HTTPError
from uuid import uuid4

base='http://127.0.0.1:5175/api/v1'
def api(path,method='GET',body=None,key=None,status=200):
    req=Request(base+path,method=method,data=None if body is None else json.dumps(body,ensure_ascii=False).encode('utf-8'),headers={'Content-Type':'application/json; charset=utf-8','Idempotency-Key':key or str(uuid4())})
    try:
        with urlopen(req,timeout=15) as response:actual=response.status;data=json.load(response)
    except HTTPError as error:actual=error.code;data=json.load(error)
    assert actual==status,(path,actual,data)
    return data

original_plan=api('/clubs/c1/training-plan')
original_staff=api('/clubs/c1/staff')
balance=api('/clubs/c1')['balance']
old_coach=next(c for c in original_staff['coaches'] if c['role']=='fitness')
plan_changed=staff_changed=False
try:
    catalog=api('/training-types')['items']
    players=api('/clubs/c1/players')['items']
    assert len(catalog)==18
    for player in players:
        assert all(1<=player['attributes'][t['id']]<=100 for t in catalog if t['id']!='recovery')
    groups=[{'id':'http-scrum','name':'Melé · jóvenes','focus':'scrum','intensity':'normal','playerIds':['c1-p1']},{'id':'http-passing','name':'Pase y recepción','focus':'passing','intensity':'normal','playerIds':['c1-p16']}]
    saved=api('/clubs/c1/training-plan','PUT',{'version':original_plan['version'],'groups':groups})
    plan_changed=True
    assert saved['groups']==groups and saved['dailyCost']==0
    assert api('/clubs/c1/training-plan')['groups']==groups
    assert api('/clubs/c1/training-plan','PUT',{'version':original_plan['version'],'groups':groups},status=409)['code']=='VERSION_CONFLICT'
    duplicate=json.loads(json.dumps(groups));duplicate[1]['playerIds']=['c1-p1']
    assert api('/clubs/c1/training-plan','PUT',{'version':saved['version'],'groups':duplicate},status=422)['code']=='TRAINING_DUPLICATE'
    foreign=json.loads(json.dumps(groups));foreign[1]['playerIds']=['c2-p1']
    assert api('/clubs/c1/training-plan','PUT',{'version':saved['version'],'groups':foreign},status=422)['code']=='PLAYER_CLUB'
    print('PASS groups, UTF-8, membership, duplicates, versions and cost',flush=True)
    staff=api('/clubs/c1/staff')
    candidate=max((c for c in api('/staff-market')['items'] if c['role']=='fitness'),key=lambda c:c['quality'])
    key=str(uuid4());hired=api('/clubs/c1/staff','POST',{'version':staff['version'],'coachId':candidate['id']},key)
    staff_changed=True
    again=api('/clubs/c1/staff','POST',{'version':staff['version'],'coachId':candidate['id']},key)
    assert hired['version']==again['version'] and len(hired['coaches'])==8
    assert next(c for c in hired['coaches'] if c['role']=='fitness')['id']==candidate['id']
    assert hired['weeklyWage']==sum(c['weeklyWage'] for c in hired['coaches'])
    assert api('/clubs/c1/staff','POST',{'version':hired['version'],'coachId':candidate['id']},status=409)['code']=='COACH_UNAVAILABLE'
    print('PASS hiring, replacement, idempotency, availability and salary total',flush=True)
finally:
    if plan_changed:
        current=api('/clubs/c1/training-plan')
        api('/clubs/c1/training-plan','PUT',{'version':current['version'],'groups':original_plan['groups']})
    if staff_changed:
        current=api('/clubs/c1/staff')
        api('/clubs/c1/staff','POST',{'version':current['version'],'coachId':old_coach['id']})
assert api('/clubs/c1')['balance']==balance
assert api('/clubs/c1/training-plan')['groups']==original_plan['groups']
print('PASS original plan, staff and balance restored; no game day advanced',flush=True)
