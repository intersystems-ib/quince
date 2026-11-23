"""Refresh LNR identities from official squad lists without changing player IDs or ratings."""
from concurrent.futures import ThreadPoolExecutor
from datetime import date
import json
import hashlib
from pathlib import Path
import re
from import_french_leagues import document, player_id

ROOT = Path(__file__).resolve().parents[1]


def display_name(raw):
    # Preserve complete given names, accents, hyphens and apostrophes; remove all-caps styling.
    name = re.sub(r"[^\W\d_]+", lambda m: m.group().capitalize() if m.group().isupper() or m.group().islower() else m.group(), raw, flags=re.UNICODE)
    name = re.sub(r'\bMc([a-z])', lambda m: 'Mc' + m.group(1).upper(), name)
    return re.sub(r',\s*', ' ', name)


def squad(club):
    url = club['sourceUrl'].rstrip('/') + '/effectif-staff'
    root = document(url)
    names = {}
    for node in root.find(lambda n: n.tag == 'a' and 'player-block' in n.attrs.get('class', '').split()):
        pid = player_id(node.attrs.get('href', ''))
        title = node.find(lambda n: n.has('player-block__name'))
        if pid and title:
            names[pid] = {'rawName': title[0].text(), 'name': display_name(title[0].text()), 'sourceUrl': node.attrs['href'], 'rosterUrl': url}
    assert len(names) >= 23, (club['id'], len(names))
    return club['id'], names


def main():
    path = ROOT / 'iris/data/french-leagues.json'
    catalog = json.loads(path.read_text(encoding='utf-8'))
    with ThreadPoolExecutor(max_workers=4) as pool:
        rosters = dict(pool.map(squad, catalog['clubs']))
    by_id = {}
    for names in rosters.values():
        by_id.update(names)
    matched = fallback = 0
    for club in catalog['clubs']:
        for player in club['players']:
            identity = rosters[club['id']].get(player['lnrId']) or by_id.get(player['lnrId'])
            if identity:
                player.update(identity)
                matched += 1
            else:
                player['rawName'] = player.get('rawName', player['name'])
                player['name'] = display_name(player['rawName'])
                fallback += 1
            if re.search(r'\b[A-Z]\.\s', player['name']):
                profile = document(player['sourceUrl'])
                heading = profile.find(lambda n: n.tag == 'h1')
                assert heading, player['sourceUrl']
                player['rawName'] = heading[0].text()
                player['name'] = display_name(player['rawName'])
                assert not re.search(r'\b[A-Z]\.\s', player['name']), player['sourceUrl']
    identities = {p['lnrId']: p['name'] for c in catalog['clubs'] for p in c['players']}
    catalog['identityVersion'] = 'lnr-squads-' + hashlib.sha256(json.dumps(identities, sort_keys=True).encode()).hexdigest()[:12]
    catalog['identityVerifiedOn'] = date.today().isoformat()
    path.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f'Updated {matched} verified identities; {fallback} historical identities retained and formatted.')


if __name__ == '__main__':
    main()
