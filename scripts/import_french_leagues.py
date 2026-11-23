"""Import compact public LNR identities and match references (stdlib only)."""
from lnr_countries import normalize_player
from concurrent.futures import ThreadPoolExecutor
from datetime import date
from html.parser import HTMLParser
import json
from pathlib import Path
import re
import time
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[1]
SEASON = '2026-2027'


class Node:
    def __init__(self, tag='', attrs=()):
        self.tag, self.attrs, self.children = tag, dict(attrs), []

    def find(self, predicate):
        result = [self] if predicate(self) else []
        for child in self.children:
            if isinstance(child, Node):
                result.extend(child.find(predicate))
        return result

    def text(self):
        return ' '.join(' '.join(c.text() if isinstance(c, Node) else c for c in self.children).split())

    def has(self, name):
        return name in self.attrs.get('class', '').split()


class Document(HTMLParser):
    def __init__(self, html):
        super().__init__()
        self.root = Node()
        self.stack = [self.root]
        self.feed(html)

    def handle_starttag(self, tag, attrs):
        node = Node(tag, attrs)
        self.stack[-1].children.append(node)
        if tag not in ['area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input', 'link', 'meta', 'param', 'source', 'track', 'wbr']:
            self.stack.append(node)

    def handle_endtag(self, tag):
        for i in range(len(self.stack) - 1, 0, -1):
            if self.stack[i].tag == tag:
                del self.stack[i:]
                break

    def handle_data(self, data):
        self.stack[-1].children.append(data)


def fetch(url):
    for attempt in range(3):
        try:
            with urlopen(Request(url, headers={'User-Agent': 'Quince-reference-import/1.0'}), timeout=40) as response:
                return response.read()
        except Exception:
            if attempt == 2:
                raise
            time.sleep(2 + attempt)


def document(url):
    return Document(fetch(url).decode('utf-8')).root


def prop(node, tag, key):
    items = node.find(lambda n: n.tag == tag and key in n.attrs)
    return json.loads(items[0].attrs[key]) if items else None


def player_id(url):
    found = re.search(r'/joueur/(\d+)', url or '')
    return found.group(1) if found else None


def match(url):
    stats = document(url + '/statistiques-du-match')
    rankings = stats.find(lambda n: n.tag == 'players-ranking')
    if len(rankings) != 2:
        return None
    header_text = stats.find(lambda n: n.has('match-header'))[0].text()
    day, month, year = re.search(r'(\d{2})/(\d{2})/(\d{4})', header_text).groups()
    match_date = f'{year}-{month}-{day}'
    score_match = re.search(r'(\d+)\s+-\s+(\d+)\s+', header_text)
    if match_date > date.today().isoformat() or not score_match: return None
    score = [int(v) for v in score_match.groups()]
    composition = document(url + '/compositions')
    header = composition.find(lambda n: n.tag == 'score-sticky-header')[0]
    clubs = [json.loads(header.attrs[key]) for key in [':hosting-club', ':visiting-club']]
    pitch = composition.find(lambda n: n.tag == 'line-up-pitch')[0]
    pitch_teams = pitch.find(lambda n: n.has('line-up__pitch-team'))
    positions = {}
    for team in pitch_teams:
        for link in team.find(lambda n: n.tag == 'a' and n.has('player-pitch')):
            number = link.find(lambda n: n.has('player-pitch__number'))
            if number:
                positions[player_id(link.attrs['href'])] = int(number[0].text())
    countries, numbers = {}, {}
    for link in composition.find(lambda n: n.tag == 'a' and n.has('player-block--lineup')):
        country = link.find(lambda n: n.has('player-block__country'))
        position = link.find(lambda n: n.has('player-block__position'))
        number = link.find(lambda n: n.has('player-block__number'))
        if number:
            numbers[player_id(link.attrs['href'])] = int(number[0].text())
        if country:
            countries[player_id(link.attrs['href'])] = (country[0].attrs.get('alt', ''), position[0].text() if position else '')
    sides = []
    for club, ranking in zip(clubs, rankings):
        players = []
        for row in json.loads(ranking.attrs[':ranking']):
            identity = row['player']
            pid = player_id(identity['url'])
            if not pid:
                continue
            values = {key: float(row.get(key) or 0) for key in ['tempsJeu', 'nbPoints', 'nbEssais', 'offload', 'lineBreak', 'breakdownSteals', 'totalSuccessfulTackles', 'nbCartonsJaunes', 'nbCartonsOranges', 'nbCartonsRouges']}
            country, role = countries.get(pid, ('', ''))
            players.append({'lnrId': pid, 'name': identity['name'], 'sourceUrl': identity['url'], 'position': positions.get(pid), 'shirtNumber': numbers.get(pid), 'selected': pid in numbers, 'nationality': country, 'sourceRole': role or row.get('position', ''), 'stats': values})
        sides.append({'clubUrl': club['url'], 'players': players})
    return {'url': url + '/statistiques-du-match', 'date': match_date, 'score': score, 'sides': sides}


def main():
    leagues, all_clubs, match_urls = [], [], []
    for host, division, name, count in [('top14', 1401, 'Top 14', 14), ('prod2', 1402, 'Pro D2', 16)]:
        base = f'https://{host}.lnr.fr'
        ranking = document(base + '/classement')
        catalog = prop(ranking, 'footer-clubs', ':competitions')
        club_catalog = {c['url'].rstrip('/'): c for league in catalog for c in league['clubs']}
        fixed = ranking.find(lambda n: n.has('ranking__fixed-block'))[0]
        urls = [base + '/club/' + re.search(r'/club/([^/]+)/', n.attrs['src']).group(1) for n in fixed.find(lambda n: n.tag == 'img' and '/club/' in n.attrs.get('src', ''))]
        urls = list(dict.fromkeys(urls))
        assert len(urls) == count, (name, urls)
        current = prop(ranking, 'filters-fixtures', ':current-week')['number']
        leagues.append({'id': division, 'name': name, 'country': 'FR', 'teams': count, 'rounds': (count - 1) * 2, 'sourceUrl': base + '/classement', 'referenceRound': current})
        for rank, url in enumerate(urls, 1):
            club = club_catalog[url]
            slug = url.rsplit('/', 1)[1]
            all_clubs.append({'id': 'fr-' + slug, 'name': club['name'], 'shortName': club['name'], 'slug': slug, 'competitionId': division, 'competition': name, 'countryCode': 'FR', 'sourceUrl': url, 'rank': rank, 'crestSourceUrl': club['logo']['thumbnail-2x'], 'players': {}})
        for round_number in range(1, current + 1):
            page = document(base + f'/calendrier-et-resultats/{SEASON}/j{round_number}')
            links = page.find(lambda n: n.tag == 'a' and f'/feuille-de-match/{SEASON}/j{round_number}/' in n.attrs.get('href', ''))
            for link in links:
                url = re.match(r'https://[^/]+/feuille-de-match/[^/]+/[^/]+/[^/]+', link.attrs['href']).group(0)
                if url not in match_urls:
                    match_urls.append(url)
        print(name, count, 'clubs;', current, 'reference rounds', flush=True)
    by_url = {c['sourceUrl']: c for c in all_clubs}
    references = []
    with ThreadPoolExecutor(max_workers=4) as pool:
        for index, result in enumerate(pool.map(match, match_urls), 1):
            if result:
                references.append(result)
                for side in result['sides']:
                    club = by_url[side['clubUrl'].rstrip('/')]
                    for item in side['players']:
                        pid = item['lnrId']
                        if pid not in club['players']:
                            club['players'][pid] = {k: v for k, v in item.items() if k != 'stats'} | {'appearances': 0, 'minutes': 0, 'points': 0, 'tries': 0, 'tackles': 0, 'breaks': 0, 'turnovers': 0}
                        p = club['players'][pid]
                        p['lastReferenceMatchDate'] = max(p.get('lastReferenceMatchDate', ''), result['date'])
                        if not p['position'] and item['position']:
                            p['position'] = item['position']
                        if item['stats']['tempsJeu'] > 0:
                            p['appearances'] += 1
                        for key, source in [('minutes', 'tempsJeu'), ('points', 'nbPoints'), ('tries', 'nbEssais'), ('tackles', 'totalSuccessfulTackles'), ('breaks', 'lineBreak'), ('turnovers', 'breakdownSteals')]:
                            p[key] += item['stats'][source]
                if index % 15 == 0:
                    print(index, '/', len(match_urls), 'match references', flush=True)
    # A player may appear for two clubs during a loan/transfer: retain the latest club only.
    owners = {}
    for club in all_clubs:
        for pid, player in club['players'].items():
            previous = owners.get(pid)
            if previous is None or player['lastReferenceMatchDate'] > previous[0]:
                owners[pid] = (player['lastReferenceMatchDate'], club['id'])
    for club in all_clubs:
        club['players'] = {pid: p for pid, p in club['players'].items() if owners[pid][1] == club['id']}
        club['players'] = list(club['players'].values())
        assert len(club['players']) >= 23, (club['name'], len(club['players']))
        assert set(range(1, 16)).issubset({p['position'] for p in club['players']}), club['name']
        crest = ROOT / 'rugby-frontend/public/crests' / (club['id'] + '.webp')
        crest.write_bytes(fetch(club['crestSourceUrl']))
        club['crestUrl'] = '/crests/' + crest.name
    out = {'version': '1.0.0', 'season': '2026/2027', 'verifiedOn': date.today().isoformat(), 'leagues': leagues, 'clubs': all_clubs,
           'notice': 'Identities and reference statistics: LNR. Ratings, budgets marked estimated, salaries and game results are simulated. Reference statistics do not count as saved-game results.'}
    (ROOT / 'iris/data/french-leagues.json').write_text(json.dumps(out, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    summary = [{'sourceUrl': r['url'], 'date': r['date'], 'teams': [{'clubId': by_url[s['clubUrl'].rstrip('/')]['id'], 'players': len(s['players']), 'officialScore': r['score'][i], 'points': sum(p['stats']['nbPoints'] for p in s['players']), 'tries': sum(p['stats']['nbEssais'] for p in s['players'])} for i, s in enumerate(r['sides'])]} for r in references]
    inconsistent_clubs = set()
    for ref in summary:
        for team in ref['teams']:
            residual = team['officialScore'] - team['points']
            team['unassignedPoints'] = residual
            team['scoringValidation'] = 'exact' if residual == 0 else 'unassigned-team-points' if residual >= 0 else 'inconsistent-source'
            if residual < 0:
                inconsistent_clubs.add(team['clubId'])
    for club in all_clubs:
        for player in club['players']:
            player['pointsValidated'] = club['id'] not in inconsistent_clubs
            normalize_player(player)
    (ROOT / 'iris/data/french-leagues.json').write_text(json.dumps(out, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    (ROOT / 'iris/data/french-match-validation.json').write_text(json.dumps({'verifiedOn': date.today().isoformat(), 'matches': summary}, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print('Imported', len(all_clubs), 'clubs,', sum(len(c['players']) for c in all_clubs), 'players and', len(references), 'matches.', flush=True)


if __name__ == '__main__':
    main()
