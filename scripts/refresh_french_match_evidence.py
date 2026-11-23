"""Refresh compact LNR squad evidence without replacing identities or downloading images."""
from lnr_countries import normalize_player
from concurrent.futures import ThreadPoolExecutor
from datetime import date
import argparse
import hashlib
import json
from pathlib import Path
import re
from import_french_leagues import document, prop, match, player_id, SEASON
from update_lnr_names import display_name

ROOT = Path(__file__).resolve().parents[1]


def official_squad(club):
    url = club['sourceUrl'].rstrip('/') + '/effectif-staff'
    page = document(url)
    result = []
    for card in page.find(lambda n: n.tag == 'a' and n.has('player-block')):
        pid = player_id(card.attrs.get('href', ''))
        title = card.find(lambda n: n.has('player-block__name'))
        role = card.find(lambda n: n.has('player-block__position'))
        country = card.find(lambda n: n.has('player-block__country'))
        if pid and title:
            result.append({'lnrId': pid, 'rawName': title[0].text(), 'name': display_name(title[0].text()), 'sourceUrl': card.attrs['href'], 'rosterUrl': url, 'sourceRole': role[0].text() if role else '', 'nationality': country[0].attrs.get('alt', '') if country else '', 'squadListed': True})
    assert len(result) >= 23, club['id']
    return club, result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--incremental', action='store_true')
    incremental = parser.parse_args().incremental
    path = ROOT / 'iris/data/french-leagues.json'
    catalog = json.loads(path.read_text(encoding='utf-8'))
    validation_path = ROOT / 'iris/data/french-match-validation.json'
    previous = json.loads(validation_path.read_text(encoding='utf-8'))
    urls = {m['sourceUrl'].removesuffix('/statistiques-du-match') for m in previous['matches']}
    for host in ['top14', 'prod2']:
        base = f'https://{host}.lnr.fr'
        ranking = document(base + '/classement')
        current = prop(ranking, 'filters-fixtures', ':current-week')['number']
        for week in range(1, current + 2):
            page = document(base + f'/calendrier-et-resultats/{SEASON}/j{week}')
            for a in page.find(lambda n: n.tag == 'a' and f'/feuille-de-match/{SEASON}/' in n.attrs.get('href', '')):
                found = re.match(r'https://[^/]+/feuille-de-match/[^/]+/[^/]+/[^/]+', a.attrs['href'])
                if found: urls.add(found.group())
        print(host, 'through round', current, flush=True)
    if incremental:
        urls -= {m['sourceUrl'].removesuffix('/statistiques-du-match') for m in previous['matches']}
    clubs = {c['sourceUrl'].rstrip('/'): c for c in catalog['clubs']}
    players = {p['lnrId']: (c, p) for c in catalog['clubs'] for p in c['players']}
    for p in [p for c in catalog['clubs'] for p in c['players']]: p['squadListed'] = False
    with ThreadPoolExecutor(max_workers=4) as pool:
        for club, squad in pool.map(official_squad, catalog['clubs']):
            for row in squad:
                existing = players.get(row['lnrId'])
                if existing:
                    existing[1].update(row)
                else:
                    row['pointsValidated'] = all(p.get('pointsValidated', True) for p in club['players'])
                    club['players'].append(row)
                    players[row['lnrId']] = club, row
    print('Verified official rosters:', len(players), 'unique identities', flush=True)
    for c in catalog['clubs']:
        if not incremental: c['referenceMatches'] = 0
        for p in c['players']:
            for key in ['appearances', 'minutes', 'points', 'tries', 'tackles', 'breaks', 'turnovers', 'offloads', 'selections', 'starts', 'benchSelections']:
                if not incremental: p[key] = 0
                else: p.setdefault(key, 0)
            if not incremental:
                p['positionCounts'], p['lastReferenceMatchDate'] = {}, ''
                p.pop('lastStartDate', None)
                p.pop('lastStartPosition', None)
            else:
                p.setdefault('positionCounts', {})
                p.setdefault('lastReferenceMatchDate', '')
    references = []
    with ThreadPoolExecutor(max_workers=4) as pool:
        for index, result in enumerate(pool.map(match, sorted(urls)), 1):
            if not result: continue
            references.append(result)
            for side in result['sides']:
                club = clubs[side['clubUrl'].rstrip('/')]
                club['referenceMatches'] += 1
                for row in side['players']:
                    pid = row['lnrId']
                    if pid not in players:
                        p = {k: v for k, v in row.items() if k not in ['stats', 'selected', 'shirtNumber']}
                        p.update({k: 0 for k in ['appearances', 'minutes', 'points', 'tries', 'tackles', 'breaks', 'turnovers', 'offloads', 'selections', 'starts', 'benchSelections']})
                        p.update(positionCounts={}, lastReferenceMatchDate='')
                        club['players'].append(p)
                        players[pid] = club, p
                    owner, p = players[pid]
                    if owner['id'] != club['id']: continue
                    stats = row['stats']
                    p['appearances'] += stats['tempsJeu'] > 0
                    p['selections'] += bool(row['selected'])
                    number = row['shirtNumber'] or 0
                    p['starts'] += 1 <= number <= 15
                    p['benchSelections'] += number > 15
                    if 1 <= number <= 15:
                        p['positionCounts'][str(number)] = p['positionCounts'].get(str(number), 0) + 1
                        if result['date'] >= p.get('lastStartDate', ''):
                            p['lastStartDate'], p['lastStartPosition'] = result['date'], number
                    p['lastReferenceMatchDate'] = max(p['lastReferenceMatchDate'], result['date'])
                    for key, source in [('minutes', 'tempsJeu'), ('points', 'nbPoints'), ('tries', 'nbEssais'), ('tackles', 'totalSuccessfulTackles'), ('breaks', 'lineBreak'), ('turnovers', 'breakdownSteals'), ('offloads', 'offload')]:
                        p[key] += stats[source]
            if index % 20 == 0: print(index, '/', len(urls), 'matches', flush=True)
    for c in catalog['clubs']:
        for p in c['players']:
            votes = p['positionCounts']
            if votes:
                p['position'] = int(max(votes, key=lambda n: (votes[n], int(n) == p.get('lastStartPosition'))))
                p['secondary'] = [int(n) for n in votes if int(n) != p['position']]
            if not p.get('position'):
                role, pid = p.get('sourceRole', '').lower(), int(p['lnrId'])
                p['position'] = (1 + pid % 3) if role.startswith('1') else (4 + pid % 2) if role.startswith('2') else (6 + pid % 3) if role.startswith('3') else 9 if 'mêlée' in role else 10 if 'ouverture' in role else (12 + pid % 2) if 'centre' in role else (11 if pid % 2 else 14) if 'ailier' in role else 15
            p['positionEvidence'] = 'LNR-starter-vote' if votes else 'LNR-role-estimate'
            p['matchEligible'] = bool(p['selections'] or p['appearances'])
            p['referenceGames'] = c['referenceMatches']
    # Compare production per 80 minutes inside each division and positional family.
    groups = {}
    for c in catalog['clubs']:
        for p in c['players']:
            pos = p.get('position') or 0
            family = 'front' if pos <= 3 else 'lock' if pos <= 5 else 'backrow' if pos <= 8 else 'half' if pos <= 10 else 'centre' if pos in [12, 13] else 'backthree'
            confidence = p['minutes'] / (p['minutes'] + 160)
            production = (p['tackles'] * .15 + p['turnovers'] * 1.5 + p['breaks'] + p['offloads'] * .3 + p['tries'] * 2 + (p['points'] * .08 if p.get('pointsValidated', True) else 0)) * 80 / max(80, p['minutes'])
            groups.setdefault((c['competitionId'], family), []).append((p, production, confidence))
    for entries in groups.values():
        rates = sorted(v for _, v, _ in entries)
        for p, rate, confidence in entries:
            percentile = (sum(v < rate for v in rates) + sum(v == rate for v in rates) / 2) / len(rates)
            games = max(1, p['referenceGames'])
            involvement = min(1, .6 * p['minutes'] / (games * 80) + .25 * p['starts'] / games + .15 * p['selections'] / games)
            p['ratingOffset'] = round((involvement - .4) * 8 + (percentile - .5) * 5 * confidence, 6)
            p['selectionScore'] = round(involvement * 75 + percentile * 25 * confidence, 6)
    for c in catalog['clubs']:
        for p in c['players']: normalize_player(p)
    catalog['identityVersion'] = 'lnr-squads-' + hashlib.sha256(json.dumps({p['lnrId']: p['name'] for c in catalog['clubs'] for p in c['players']}, sort_keys=True).encode()).hexdigest()[:12]
    catalog['identityVerifiedOn'] = date.today().isoformat()
    catalog['evidenceVerifiedOn'] = date.today().isoformat()
    summary = previous['matches'] if incremental else []
    for ref in references:
        teams = []
        for index, side in enumerate(ref['sides']):
            club = clubs[side['clubUrl'].rstrip('/')]; points = sum(p['stats']['nbPoints'] for p in side['players']); residual = ref['score'][index] - points
            teams.append({'clubId': club['id'], 'players': len(side['players']), 'officialScore': ref['score'][index], 'points': points, 'tries': sum(p['stats']['nbEssais'] for p in side['players']), 'unassignedPoints': residual, 'scoringValidation': 'exact' if residual == 0 else 'unassigned-team-points' if residual > 0 else 'inconsistent-source'})
        summary.append({'sourceUrl': ref['url'], 'date': ref['date'], 'teams': teams})
    catalog['evidenceMatchCount'] = len(summary)
    validation_path.write_text(json.dumps({'verifiedOn': date.today().isoformat(), 'matches': summary}, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    catalog['evidenceVersion'] = 'lnr-matches-' + hashlib.sha256(json.dumps([(p['lnrId'], p['minutes'], p['starts'], p['selections'], p['ratingOffset'], p.get('position'), p.get('squadListed', False)) for c in catalog['clubs'] for p in c['players']], sort_keys=True).encode()).hexdigest()[:12]
    path.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print('Verified', catalog['evidenceMatchCount'], 'matches;', sum(p['matchEligible'] for c in catalog['clubs'] for p in c['players']), 'eligible identities.', flush=True)


if __name__ == '__main__': main()
