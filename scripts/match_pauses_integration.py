"""Pauses over the audited API, with controlled injuries on a disposable instance."""
from session_integration import Client, BASE
from test_paths import artifact_path
from uuid import uuid4
import json
import secrets
import subprocess
import time

assert ':52776/' in BASE, 'Use the disposable instance'
c = Client()
creds = {'username': 'pauses_' + uuid4().hex[:10], 'password': secrets.token_urlsafe(24)}
c.call('/auth/register', 'POST', creds)
c.game = c.call('/games', 'POST', {'name': 'Pausas del partido', 'clubId': 'c1', 'divisionId': 416})
c.call('/games/' + c.game['id'] + '/load', 'POST', {})
club = c.call('/clubs/c1')
opponent = c.call('/clubs/c1/friendly-options?date=' + club['date'])['items'][0]
f = c.call('/clubs/c1/friendlies', 'POST', {'version': club['version'], 'date': club['date'], 'opponentId': opponent['id'], 'venue': 'away'})
m = c.call('/matches', 'POST', {'fixtureId': f['id']}, status=201)
prefix = '/matches/' + m['id']
c.call(prefix + '/start', 'POST', {})

def wait(predicate):
    for _ in range(80):
        state = c.call(prefix)
        if predicate(state):
            return state
        time.sleep(.1)
    raise AssertionError(state)

def inject(code):
    c.call('/games/' + c.game['id'] + '/unload', 'POST', {})
    script = f'''set %RugbyGame="{c.game['id']}",%RugbyManagedClub="c1"
lock +^RugbyWrite:10
tstart
set m=##class(Rugby.Service.Store).Get("Match","{m['id']}")
{code}
do ##class(Rugby.Service.Store).Put("Match",m)
tcommit
lock -^RugbyWrite
write "INJECTION_OK",!
halt
'''
    result = subprocess.run(['docker', 'exec', '-i', 'rugby-pauses-check', 'iris', 'session', 'IRIS', '-U', 'RUGBY'], input=script, text=True, capture_output=True, check=True)
    assert 'INJECTION_OK' in result.stdout and '<' not in result.stdout, result.stdout
    c.call('/games/' + c.game['id'] + '/load', 'POST', {})

key = str(uuid4())
cmd = c.call(prefix + '/commands', 'POST', {'type': 'speed', 'speed': 0}, key=key)
assert cmd == c.call(prefix + '/commands', 'POST', {'type': 'speed', 'speed': 0}, key=key)
paused = wait(lambda s: s['speed'] == 0)
time.sleep(.7)
assert c.call(prefix)['clock'] == paused['clock']
c.call(prefix + '/commands', 'POST', {'type': 'speed', 'speed': 60})
wait(lambda s: s['clock'] > paused['clock'])
c.call(prefix + '/commands', 'POST', {'type': 'speed', 'speed': 0})
wait(lambda s: s['speed'] == 0)
inject('set hit=##class(Rugby.Service.Injuries).Hit(m,"away",m.awayPlayers.%Get(0))')
injured = wait(lambda s: s.get('pauseReason') == 'injury')
assert injured['speed'] == 0 and injured['pausedPlayerId'] == injured['awayPlayers'][0]['playerId']
out = injured['awayPlayers'][0]
incoming = next(p for p in injured['awayPlayers'] if p['status'] == 'bench')
c.call(prefix + '/commands', 'POST', {'type': 'substitution', 'outId': out['playerId'], 'inId': incoming['playerId']})
changed = wait(lambda s: s['awaySubs'] == 1)
assert changed['clock'] == injured['clock'] and changed['speed'] == 0
inject('set m.speed=60,m.clock=2380,m.phase="stoppage",m.x=50,m.y=35\ndo ##class(Rugby.Simulation.Engine).Step(m)')
half = wait(lambda s: s['status'] == 'halftime')
assert half['speed'] == 0 and half['clock'] == 2400 and half['pauseReason'] == 'halftime'
c.call(prefix + '/commands', 'POST', {'type': 'speed', 'speed': 20})
wait(lambda s: s['status'] == 'second')
c.call(prefix + '/commands', 'POST', {'type': 'speed', 'speed': 0})
wait(lambda s: s['speed'] == 0)
inject('set hit=##class(Rugby.Service.Injuries).Hit(m,"away",m.awayPlayers.%Get(1))')
wait(lambda s: s['speed'] == 0 and s.get('pauseReason') == 'injury')
artifact_path('pauses-ui.json').write_text(json.dumps({**creds, 'game': c.game, 'matchId': m['id']}), encoding='utf-8')
artifact_path('pauses-http-traces.json').write_text(json.dumps(c.trace), encoding='utf-8')
print('PASS manual pause/resume, frozen clock, away injury pause, substitution while paused, halftime pause, explicit second half and interop correlation')
