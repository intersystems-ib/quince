"""Build compact FER references from public match sheets; never invent missing statistics."""
from concurrent.futures import ThreadPoolExecutor
from datetime import date
from http.cookiejar import CookieJar
from io import BytesIO
from pathlib import Path
from urllib.parse import urlencode
from urllib.request import Request, build_opener, HTTPCookieProcessor
import hashlib
import json
import re
import tempfile
import unicodedata
import pdfplumber

ROOT = Path(__file__).resolve().parents[1]
BASE = 'https://resultadosrugby.isquad.es/maqueta/'
HEADERS = {'User-Agent': 'Mozilla/5.0'}
KEYS = 'speed strength stamina agility passing handling tackling kicking scrum lineout discipline decisions leadership ruck maul attacking defensiveReading'.split()


def repair_text(value):
    # Reverse UTF-8 decoded as Latin-1/Windows-1252; leave valid text unchanged.
    def repair_run(match):
        text = match.group()
        for _ in range(3):
            try:
                content = bytes(ord(char) if ord(char) < 256 else char.encode('cp1252')[0] for char in text)
                candidate = content.decode('utf-8')
            except (UnicodeError, ValueError): break
            if candidate == text: break
            text = candidate
        return text
    return re.sub(r'[^\x00-\x7f]+', repair_run, value)


def normalized(value):
    return re.sub(r'[^a-z0-9]', '', unicodedata.normalize('NFKD', repair_text(value)).encode('ascii', 'ignore').decode().lower())


class FER:
    def __init__(self):
        self.opener = build_opener(HTTPCookieProcessor(CookieJar()))
        html = self.opener.open(Request(BASE, headers=HEADERS), timeout=40).read().decode('utf-8')
        self.token = re.search(r'name="client-token" content="([^"]+)', html).group(1)

    def api(self, kind, identity):
        request = Request(BASE + 'json/beta.php', data=urlencode({'tipo': kind, 'id': identity}).encode(), headers=HEADERS | {'Content-Type': 'application/x-www-form-urlencoded', 'X-Client-Token': self.token, 'Referer': BASE})
        with self.opener.open(request, timeout=45) as response:
            result = json.load(response)
        return result.get('data', result)


def substitutions(content):
    result = [[], []]
    with pdfplumber.open(BytesIO(content)) as pdf:
        for page in pdf.pages[1:]:
            # Crop each team before table detection: the two sides have different row heights.
            for side, (left, right) in enumerate([(8, 296), (300, 585)]):
                for table in page.crop((left, 150, right, page.height - 35)).extract_tables():
                    for row in table:
                        cells = [str(cell).strip() for cell in row if cell is not None and str(cell).strip()]
                        if len(cells) < 3: continue
                        out = re.match(r'^(\d{1,2})\s*-', cells[0])
                        into = re.match(r'^(\d{1,2})\s*-', cells[1])
                        if not out or not into: continue
                        minute = re.fullmatch(r'\d{1,3}', cells[2])
                        if not minute: raise ValueError('Unrecognised substitution minute')
                        item = (int(cells[0].split('-')[0]), int(cells[1].split('-')[0]), min(80, int(cells[2])))
                        if item not in result[side]: result[side].append(item)
    return result


def minutes_played(numbers, changes, cards):
    active = {number: 0 for number in numbers if 1 <= number <= 15}
    intervals = {number: [] for number in numbers}
    uncertain, appeared = set(), set(active)
    for out, into, minute in sorted(changes, key=lambda item: item[2]):
        if out == into or out not in active or into in active or into not in intervals:
            uncertain.update([out, into]); continue
        intervals[out].append((active.pop(out), minute))
        active[into] = minute
        appeared.add(into)
    for number, start in active.items(): intervals[number].append((start, 80))
    result = {}
    for number, spans in intervals.items():
        total = 0
        for start, end in spans:
            removed = set()
            for minute, length in cards.get(number, []):
                removed.update(range(max(start, minute), min(end, minute + length)))
            total += max(0, end - start) - len(removed)
        result[number] = None if number in uncertain else max(0, total)
    return result, appeared


def match(client, fixture):
    data = client.api('acta', fixture['id'])
    if not data or not data.get('partido') or not data.get('alineaciones'):
        raise ValueError('No public lineup')
    changes, qualifications, pdf_ok, error = [[], []], [{}, {}], True, ''
    try:
        content = client.opener.open(Request(fixture['acta'], headers=HEADERS), timeout=50).read()
        if not content.startswith(b'%PDF-'): raise ValueError('No public PDF')
        changes = substitutions(content)
        with pdfplumber.open(BytesIO(content)) as pdf:
            page = pdf.pages[0]
            for side, (left, right) in enumerate([(8, 296), (300, 585)]):
                for table in page.crop((left, 150, right, page.height - 35)).extract_tables():
                    for cells in table:
                        values = [str(cell).strip() for cell in cells if cell is not None and str(cell).strip()]
                        if len(values) < 2: continue
                        number = re.fullmatch(r'(\d{1,2})(?: C)?', values[0])
                        if number and re.fullmatch(r'(?:PI|T|PD)(?:,(?:PI|T|PD))*', values[1]):
                            qualifications[side][int(number.group(1))] = [{'PI': 1, 'T': 2, 'PD': 3}[v] for v in values[1].split(',')]

    except Exception as ex:
        pdf_ok, error = False, type(ex).__name__ + ': ' + str(ex)
    teams = []
    for side, key in enumerate(['l', 'v']):
        team = fixture[key]['id']
        rows = [row for row in data['alineaciones'] if row['id_equipo'] == team and not row.get('es_tecnico') and not row.get('rol') and 1 <= int(row.get('dorsal') or 0) <= 23]
        by_id = {row['id_jugador']: int(row['dorsal']) for row in rows}
        cards = {}
        for event in data.get('eventos', []):
            if event.get('id_equipo') != team or event.get('id_jugador') not in by_id: continue
            label = normalized(event.get('tipo_evento', ''))
            if 'expulsion' in label:
                minute = min(80, int(str(event['minuto']).split(':')[0]))
                length = 10 if event.get('sancion') == 1 else 80
                cards.setdefault(by_id[event['id_jugador']], []).append((minute, length))
        times, appeared = minutes_played([row['dorsal'] for row in rows], changes[side], cards)
        events = data.get('eventos', [])
        total = sum(int(event.get('tantos') or 0) for event in events if event.get('id_equipo') == team)
        official = int(fixture['gl' if side == 0 else 'gv'])
        inferred = {n: n for n in range(1, 16)}
        for out, into, minute in sorted(changes[side], key=lambda item: item[2]):
            if out != into and out in inferred: inferred[into] = inferred[out]
        for row in rows:
            row['frontRowQualifications'] = qualifications[side].get(row['dorsal'], [])
            row['inferredPosition'] = inferred.get(row['dorsal'])
            row['minutes'] = times[row['dorsal']] if pdf_ok else None
            row['appeared'] = row['dorsal'] in appeared
            mine = [event for event in events if event.get('id_equipo') == team and event.get('id_jugador') == row['id_jugador']]
            row['tries'] = sum(normalized(event.get('tipo_evento', '')) == 'ensayo' for event in mine)
            row['conversions'] = sum('conversion' in normalized(event.get('tipo_evento', '')) and int(event.get('tantos') or 0) == 2 for event in mine)
            row['penalties'] = sum('castigoapalos' in normalized(event.get('tipo_evento', '')) and int(event.get('tantos') or 0) == 3 for event in mine)
            row['drops'] = sum('drop' in normalized(event.get('tipo_evento', '')) and int(event.get('tantos') or 0) == 3 for event in mine)
            row['yellowCards'] = sum(event.get('sancion') == 1 for event in mine)
            row['redCards'] = sum(event.get('sancion') == 2 for event in mine)
            row['points'] = sum(int(event.get('tantos') or 0) for event in mine)
        teams.append({'officialTeamId': team, 'players': rows, 'score': official, 'eventPoints': total, 'scoringValidated': total == official})
    return {'id': str(fixture['id']), 'date': fixture['fecha'], 'round': fixture['j'], 'competitionId': fixture['comp'], 'sourceUrl': fixture['acta'], 'pdfAvailable': pdf_ok, 'pdfError': error, 'teams': teams}


def main():
    client = FER()
    clubs = json.loads((ROOT / 'iris/data/clubs.json').read_text(encoding='utf-8'))['clubs']
    catalog = json.loads((ROOT / 'iris/data/real-rosters.json').read_text(encoding='utf-8'))
    by_team = {club['officialTeamId']: club for club in clubs}
    rows, names, source_ids = {}, {}, {}
    for team in catalog['teams']:
        club = next(club for club in clubs if club['id'] == team['clubId'])
        for player in team['players']:
            key = (club['officialTeamId'], normalized(player['name']))
            names[key] = player['id']
            rows[player['id']] = {'playerId': player['id'], 'clubId': club['id'], 'competitionId': club['competitionId'], 'ferId': None, 'name': player['name'], 'selections': 0, 'starts': 0, 'benchSelections': 0, 'appearances': 0, 'minutes': 0, 'minutesMatches': 0, 'tries': 0, 'conversions': 0, 'penalties': 0, 'drops': 0, 'points': 0, 'yellowCards': 0, 'redCards': 0, 'positionCounts': {}, 'sourceUrl': '', 'scoringMatches': 0, 'replacementPositionCounts': {}, 'lastReferenceMatchDate': '', 'frontRowQualifications': [], 'initialPosition': player['position']}
    fixtures = []
    for identity in [1296, 1297]:
        competition = client.api('torneo', identity)
        fixtures.extend(f for f in competition['partidos'] if f['estado'] == 'Finalizado' and f['fecha'] <= date.today().isoformat())
    fixtures.sort(key=lambda f: (f['fecha'], f['id']))
    club_games = {club['id']: 0 for club in clubs}
    summaries = []
    progress = Path(tempfile.gettempdir()) / 'rugby-fer-import-progress.jsonl'
    cached = {}
    if progress.exists():
        for line in progress.read_text(encoding='utf-8').splitlines():
            item = json.loads(line)
            cached[item['id']] = item
    def fetch(fixture):
        if str(fixture['id']) in cached: return cached[str(fixture['id'])]
        return match(client, fixture)
    with ThreadPoolExecutor(max_workers=2) as pool:
        for index, result in enumerate(pool.map(fetch, fixtures), 1):
            if result['id'] not in cached:
                with progress.open('a', encoding='utf-8') as stream: stream.write(json.dumps(result, ensure_ascii=False) + '\n')
            summary = {key: value for key, value in result.items() if key != 'teams'}
            summary['teams'] = []
            for team in result['teams']:
                club = by_team[team['officialTeamId']]
                club_games[club['id']] += 1
                matched = 0
                for player in team['players']:
                    identity = names.get((team['officialTeamId'], normalized(player['nombre_jugador'])))
                    source_key = (team['officialTeamId'], str(player['id_jugador']))
                    identity = source_ids.get(source_key, identity)
                    if identity is None:
                        identity = club['id'] + '-fer-' + str(player['id_jugador'])
                        given = repair_text(player['nombre_jugador']).strip()
                        if '?' in given or not given: raise ValueError('Unverified name: ' + given)
                        words = given.title().split()
                        name = ' '.join(word.lower() if n and word.lower() in {'de','del','la','las','los','van','von','di','du','i'} else word for n,word in enumerate(words))
                        rows[identity] = {'playerId': identity, 'clubId': club['id'], 'competitionId': club['competitionId'], 'ferId': None, 'name': name, 'selections': 0, 'starts': 0, 'benchSelections': 0, 'appearances': 0, 'minutes': 0, 'minutesMatches': 0, 'tries': 0, 'conversions': 0, 'penalties': 0, 'drops': 0, 'points': 0, 'yellowCards': 0, 'redCards': 0, 'positionCounts': {}, 'sourceUrl': '', 'scoringMatches': 0, 'replacementPositionCounts': {}, 'lastReferenceMatchDate': '', 'frontRowQualifications': [], 'initialPosition': None}
                    source_ids[source_key] = identity
                    names[(team['officialTeamId'], normalized(player['nombre_jugador']))] = identity
                    matched += 1
                    row = rows[identity]
                    if row['ferId'] not in [None, str(player['id_jugador'])]: raise ValueError('Ambiguous real identity: ' + identity)
                    row['ferId'] = str(player['id_jugador'])
                    row['lastReferenceMatchDate'] = result['date']
                    inferred = player.get('inferredPosition')
                    if player['dorsal'] > 15 and inferred:
                        role = str(inferred)
                        row['replacementPositionCounts'][role] = row['replacementPositionCounts'].get(role, 0) + 1
                    row['frontRowQualifications'] = sorted(set(row['frontRowQualifications'] + player.get('frontRowQualifications', [])))
                    if row['initialPosition'] is None:
                        row['initialPosition'] = player.get('inferredPosition') or (row['frontRowQualifications'][0] if row['frontRowQualifications'] else {16:2,17:1,18:3,19:4,20:8,21:9,22:10,23:15}[player['dorsal']])
                    row['selections'] += 1
                    row['starts'] += player['dorsal'] <= 15
                    row['benchSelections'] += player['dorsal'] > 15
                    row['appearances'] += player['appeared']
                    if player['minutes'] is not None:
                        row['minutes'] += player['minutes']
                        row['minutesMatches'] += 1
                    if player['dorsal'] <= 15:
                        pos = str(player['dorsal'])
                        row['positionCounts'][pos] = row['positionCounts'].get(pos, 0) + 1
                    row['sourceUrl'] = result['sourceUrl']
                    for field in ['tries', 'conversions', 'penalties', 'drops', 'points', 'yellowCards', 'redCards']:
                        if team['scoringValidated'] or field.endswith('Cards'): row[field] += player[field]
                    row['scoringMatches'] += team['scoringValidated']
                summary['teams'].append({key: value for key, value in team.items() if key != 'players'} | {'matchedPlayers': matched, 'selectedPlayers': len(team['players'])})
            summaries.append(summary)
            print(index, '/', len(fixtures), 'actas; PDF', result['pdfAvailable'], result['pdfError'], flush=True)
    # One identity per real FER player, including moves between clubs.
    owners = {}
    for identity, row in rows.items():
        previous = owners.get(row['ferId'])
        if previous is None or (row['lastReferenceMatchDate'], row['selections']) > (rows[previous]['lastReferenceMatchDate'], rows[previous]['selections']): owners[row['ferId']] = identity
    rows = {identity: row for identity, row in rows.items() if owners[row['ferId']] == identity}
    positional = {}
    original = {p['id']: p for team in catalog['teams'] for p in team['players']}
    for identity, row in rows.items():
        row['referenceGames'] = club_games[row['clubId']]
        votes = row['positionCounts']
        inferred = row['replacementPositionCounts']
        pos = int(max(votes, key=votes.get)) if votes else row['frontRowQualifications'][0] if row['frontRowQualifications'] else int(max(inferred, key=inferred.get)) if inferred else row['initialPosition']
        row['position'] = pos
        row['secondary'] = sorted({int(p) for p in votes if int(p) != pos} | {p for p in row['frontRowQualifications'] if p != pos})
        row['positionEvidence'] = 'FER-starter-vote' if votes else 'FER-replacement-inference' if inferred or row['frontRowQualifications'] else 'FER-simulation-estimate'
        row['minutesComplete'] = row['minutesMatches'] == row['selections']
        family = 'front' if pos <= 3 else 'lock' if pos <= 5 else 'backrow' if pos <= 8 else 'half' if pos <= 10 else 'centre' if pos in [12, 13] else 'backthree'
        games = max(1, row['referenceGames'])
        minutes_ratio = row['minutes'] / (max(1, row['minutesMatches']) * 80)
        row['participationScore'] = (.5 * row['starts'] / games + .25 * row['selections'] / games + .25 * minutes_ratio) if row['minutesMatches'] else (.7 * row['starts'] / games + .3 * row['selections'] / games)
        confidence = row['selections'] / (row['selections'] + 2)
        # Actual scoring per selection complements participation; no invented tackles or metres.
        production = (row['tries'] * 2 + (row['conversions'] + row['penalties'] + row['drops']) * .25) / max(1, row['selections'])
        positional.setdefault((row['competitionId'], family), []).append((row, production, confidence))
    for entries in positional.values():
        rates = [rate for _, rate, _ in entries]
        for row, production, confidence in entries:
            percentile = (sum(rate < production for rate in rates) + sum(rate == production for rate in rates) / 2) / len(rates)
            offset = (row['participationScore'] - .45) * 7 + (percentile - .5) * 4 * confidence
            row['ratingOffset'] = offset
            kicking = min(4, (row['conversions'] + row['penalties'] + row['drops']) / max(1, row['selections']) * 1.5) * confidence
            attack = min(2, row['tries'] / max(1, row['selections']) * 2) * confidence
            discipline = -min(2, (row['yellowCards'] * .4 + row['redCards']) / max(1, row['selections']))
            row['attributeOffsets'] = {key: offset + (kicking if key == 'kicking' else attack if key == 'attacking' else discipline if key == 'discipline' else 0) for key in KEYS}
    # Keep each club's calibrated level while differentiating its players.
    for club in clubs:
        squad = [row for row in rows.values() if row['clubId'] == club['id']]
        center = sum(row['ratingOffset'] for row in squad) / len(squad)
        centers = {key: sum(row['attributeOffsets'][key] for row in squad) / len(squad) for key in KEYS}
        for row in squad:
            row['ratingOffset'] = round(row['ratingOffset'] - center, 6)
            row['attributeOffsets'] = {key: round(value - centers[key], 6) for key, value in row['attributeOffsets'].items()}
    payload = {'season': '2026/2027', 'verifiedOn': date.today().isoformat(), 'matchCount': len(summaries), 'notice': 'FER match references. Minutes reconstructed from PDF substitutions and cards; ambiguous minutes are excluded. No tackles or metres available. Ratings are simulated. All selected players across the reference rounds. Initial IDs and club mean levels are retained.', 'players': list(rows.values()), 'matches': summaries}
    payload['version'] = 'fer-matches-' + hashlib.sha256(json.dumps(payload['players'], sort_keys=True).encode()).hexdigest()[:12]
    assert all(row['selections'] and row['ferId'] for row in rows.values()), [p['name'] for p in rows.values() if not p['selections']]
    (ROOT / 'iris/data/spanish-match-evidence.json').write_text(json.dumps(payload, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    progress.unlink(missing_ok=True)
    print('Verified', len(summaries), 'matches;', len(rows), 'players across all match sheets;', sum(r['minutesComplete'] for r in rows.values()), 'complete minute records.', flush=True)


if __name__ == '__main__': main()
