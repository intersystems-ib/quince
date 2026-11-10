"""Read-only validation of league schedules, results and saved-game preservation."""
from test_paths import artifact_path
import json
from collections import Counter, defaultdict
from datetime import date
from pathlib import Path
from urllib.request import urlopen

BASE = 'http://127.0.0.1:5175/api/v1'

def get(path):
    with urlopen(BASE + path, timeout=20) as response:
        return json.load(response)

club = get('/clubs/c1')
leagues = get('/competitions')['items']
assert {c['divisionId'] for c in leagues} == {416, 417}
for league in leagues:
    c = get('/competitions/' + league['id'])
    fixtures = c['regularFixtures']
    assert len(fixtures) == 90 and len(c['standings']) == 10
    pairings = Counter((f['homeId'], f['awayId']) for f in fixtures)
    assert len(pairings) == 90 and set(pairings.values()) == {1}
    venues = defaultdict(dict)
    rounds = defaultdict(set)
    for f in fixtures:
        assert date.fromisoformat(f['date']).weekday() in (5, 6)
        assert c['startDate'] <= f['date'] < min(c['semifinalDates']) < c['finalDate']
        for key, venue in [('homeId', 'H'), ('awayId', 'A')]:
            assert f[key] not in rounds[f['round']]
            rounds[f['round']].add(f[key])
            venues[f[key]][f['round']] = venue
    assert len(rounds) == 18 and all(len(ids) == 10 for ids in rounds.values())
    for team, sequence in venues.items():
        text = ''.join(sequence[r] for r in range(1, 19))
        assert text.count('H') == text.count('A') == 9
        assert 'HHH' not in text and 'AAA' not in text
    assert c['regularFinished'] == sum(f['status'] == 'finished' for f in fixtures)
    if c['regularFinished'] < 90:
        assert c['semifinals'] == [] and c['final'] == ''
    for row in c['standings']:
        completed = [f for f in fixtures if f['status'] == 'finished' and row['clubId'] in (f['homeId'], f['awayId'])]
        assert row['played'] == len(completed)
        assert row['points'] == row['wins'] * 4 + row['draws'] * 2 + row['bonusOffensive'] + row['bonusDefensive']
        assert row['difference'] == row['pointsFor'] - row['pointsAgainst']
    print('PASS league', c['divisionId'], 'draw, weekends, 9/9 venues, table and empty bracket')
fixtures = get('/clubs/c1/fixtures')['items']
assert len([f for f in fixtures if f.get('stage') == 'regular']) == 18
assert all('c1' in (f['homeId'], f['awayId']) for f in fixtures)
assert get('/players/c1-p1')['potentialDate'] == next(c['endDate'] for c in leagues if c['divisionId'] == 416)
baseline = artifact_path('competition-before.json')
if baseline.exists():
    old = json.loads(baseline.read_text(encoding='utf-8'))
    player = get('/players/c1-p1')
    assert club == old['club'], 'Migration changed the managed club'
    for field in ['attributes', 'energy', 'age', 'morale', 'version']:
        assert player[field] == old['player'][field], field
    assert get('/clubs/c1/financial-movements') == old['movements']
    print('PASS migration preserves day, balance, ledger and player attributes')
print('ALL COMPETITION HTTP CHECKS PASSED')
