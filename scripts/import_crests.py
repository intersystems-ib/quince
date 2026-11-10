"""Import original federation image assets exported by the browser, preserving provenance."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
from urllib.parse import urlparse,parse_qs
from PIL import Image

parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('bundle',type=Path)
args=parser.parse_args()
root=Path(__file__).resolve().parents[1]
export=json.loads(args.bundle.read_text(encoding='utf-8-sig'))
clubs=json.loads((root/'iris/data/clubs.json').read_text(encoding='utf-8-sig'))['clubs']
by_team={int(parse_qs(urlparse(row['team']).query)['id_equipo'][0]):row['src'] for row in export['mappings']}
by_url={asset['url']:asset for bundle in export['bundles'] for asset in bundle['assets']}
out=root/'rugby-frontend/public/crests'
out.mkdir(parents=True,exist_ok=True)
manifest=[]
for club in clubs:
    source=by_team[club['officialTeamId']]
    asset=by_url[source]
    original=Path(asset['path'])
    with Image.open(original) as image:
        image.verify()
    with Image.open(original) as image:
        dimensions=list(image.size)
        assert image.format=='JPEG' and min(image.size)>=24,(club['id'],image.format,image.size)
    target=out/(club['id']+'.jpg')
    shutil.copyfile(original,target)
    page=f"https://resultadosrugby.isquad.es/competicion.php?id_superficie=1&seleccion=0&id_competicion={club['competitionId']}&id_temp=2627&id_ambito=1&id_territorial=9999"
    manifest.append({'clubId':club['id'],'officialTeamId':club['officialTeamId'],'name':club['name'],'file':'/crests/'+target.name,'sourceUrl':source,'sourcePage':page,'retrievedOn':'2026-11-07','dimensions':dimensions,'sha256':hashlib.sha256(target.read_bytes()).hexdigest()})
(out/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
assert len(manifest)==20 and len({m['clubId'] for m in manifest})==20
print(f"Imported {len(manifest)} original crests ({sum((out/(m['clubId']+'.jpg')).stat().st_size for m in manifest)} bytes)")
for item in manifest:print(item['clubId'],item['dimensions'],item['name'])
