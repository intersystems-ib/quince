"""Read-only checks for automatic training suggestions against the running app."""
import json
from urllib.request import urlopen
from urllib.error import HTTPError

BASE = 'http://127.0.0.1:5175/api/v1'

def get(path):
    with urlopen(BASE + path, timeout=15) as response:
        return json.load(response)

plan = get('/clubs/c1/training-plan')
club = get('/clubs/c1')
players = {p['id']: p for p in get('/clubs/c1/players')['items']}
previous = None
for variant in range(9):
    proposal = get(f'/clubs/c1/training-suggestion?variant={variant}')
    assert proposal['variant'] == variant and type(proposal['variant']) is int
    assignments = {}
    cost = recovering = 0
    for group in proposal['groups']:
        for player_id in group['playerIds']:
            assert player_id not in assignments
            player = players[player_id]
            focus = group['focus']
            assignments[player_id] = focus
            if player['energy'] < 60 or not player['available']:
                assert focus == 'recovery'
            else:
                assert focus != 'recovery'
                assert group['intensity'] == ('low' if player['energy'] < 75 else 'normal')
                if previous:
                    assert previous[player_id] != focus
            if focus == 'recovery':
                recovering += 1
            else:
                cost += 1000 * {'low': 1, 'normal': 2}[group['intensity']]
    assert set(assignments) == set(players)
    assert proposal['playerCount'] == len(players)
    assert proposal['recoveryCount'] == recovering and proposal['dailyCost'] == 0
    previous = assignments
for invalid in ['-1', '1.5', 'abc', '1000001']:
    try:
        get('/clubs/c1/training-suggestion?variant=' + invalid)
        raise AssertionError('Invalid variant accepted')
    except HTTPError as error:
        assert error.code == 400
assert get('/clubs/c1/training-plan') == plan
assert get('/clubs/c1') == club
print('AUTOMATIC TRAINING HTTP CHECKS PASSED: coverage, alternatives, recovery, cost, validation, no saved changes')
