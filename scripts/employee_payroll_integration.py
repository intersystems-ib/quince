"""Monthly employee contracts and no weekly wage debits; disposable instance only."""
from session_integration import Client, BASE
from test_paths import artifact_path
from uuid import uuid4
import json
import secrets

assert ':52776/' in BASE, 'Use the disposable instance'
c = Client()
c.call('/auth/register', 'POST', {'username': 'employees_' + uuid4().hex[:10], 'password': secrets.token_urlsafe(24)})
c.game = c.call('/games', 'POST', {'name': 'Nóminas de empleados', 'clubId': 'c7', 'divisionId': 416})
staff = c.call('/clubs/c7/staff')
market = c.call('/staff-market?role=head')['items']
candidate = min((p for p in market if p['affordable']), key=lambda p: p['monthlyWage'])
balance = c.call('/clubs/c7')['balance']
key = str(uuid4())
body = {'coachId': candidate['id'], 'version': staff['version']}
hired = c.call('/clubs/c7/staff', 'POST', body, key=key)
assert hired == c.call('/clubs/c7/staff', 'POST', body, key=key)
coach = next(p for p in hired['coaches'] if p['id'] == candidate['id'])
assert coach['monthlyWage'] == candidate['monthlyWage']
assert hired['monthlyWage'] == sum(p['monthlyWage'] for p in hired['coaches'])
assert c.call('/clubs/c7')['balance'] == balance
finance = c.call('/clubs/c7/finances')
candidate = min(finance['office']['candidates'], key=lambda p: p['monthlyWage'])
key = str(uuid4())
body = {'candidateId': candidate['id'], 'version': finance['office']['version']}
hired = c.call('/clubs/c7/financial-director', 'POST', body, key=key)
assert hired == c.call('/clubs/c7/financial-director', 'POST', body, key=key)
director = hired['office']['director']
assert director['monthlyWage'] == candidate['monthlyWage']
assert hired['annualWages'] == 12 * (hired['payroll']['monthlyPlayers'] + hired['payroll']['monthlyStaff'] + hired['payroll']['monthlyDirector'])
assert hired['payroll']['payPeriod'] == 'monthly' and hired['payroll']['paymentsPerYear'] == 12
for _ in range(8):
    club = c.call('/clubs/c7')
    c.call('/clubs/c7/advance-day', 'POST', {'version': club['version']})
finance = c.call('/clubs/c7/finances')
assert not [m for m in finance['movements'] if m['type'] in ('wages', 'staffWages', 'financeWages', 'training')]
assert finance['balance'] == finance['initialBalance'] + sum(m['amount'] for m in finance['movements'])
artifact_path('employee-http-summary.json').write_text(json.dumps({'coachMonthlyWage': coach['monthlyWage'], 'directorMonthlyWage': director['monthlyWage'], 'date': c.call('/clubs/c7')['date'], 'payroll': finance['payroll'], 'interopRequests': len(c.trace)}, ensure_ascii=False, indent=2), encoding='utf-8')
artifact_path('employee-http-traces.json').write_text(json.dumps(c.trace), encoding='utf-8')
print('PASS monthly employee quotes, hiring, retries, budget, twelve-month forecasts, eight days without weekly debits and exact ledger')
