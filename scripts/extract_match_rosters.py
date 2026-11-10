"""Extract first-round FER squads from user-supplied match sheets, without guessing identity data."""
import argparse
import hashlib
import itertools
import json
import re
from pathlib import Path
import pdfplumber

MATCHES={17643:('c2','c5'),17644:('c7','c1'),17645:('c9','c3'),17646:('c6','c10'),17647:('c4','c8'),17733:('c18','c19'),17734:('c15','c17'),17735:('c20','c12'),17736:('c16','c11'),17737:('c13','c14')}
FRONT={'PI':1,'T':2,'PD':3}
PARTICLES={'de','del','la','las','los','i','van','du','di','lo'}
def display_name(raw):
    surname,given=raw.split(',',1)
    words=(given.strip()+' '+surname.strip()).title().split()
    return ' '.join(w.lower() if i and w.lower() in PARTICLES else w for i,w in enumerate(words))

def extract(folder,output):
    clubs=json.loads(Path('iris/data/clubs.json').read_text(encoding='utf-8'))['clubs'];byid={c['id']:c for c in clubs};teams=[];sources=[]
    pattern=re.compile(r'^(\d{1,2})(?:\s+(C))?\s+(?:(PI(?:,T)?(?:,PD)?|T(?:,PD)?|PD)\s+)?(.+?,.+?)\s+(DHM|DHBM|DHE|M23|M20)\s+(.*?)\s*([ABC])$')
    for num,ids in MATCHES.items():
        file=folder/f'acta_rugby_{num}.pdf'
        with pdfplumber.open(file) as pdf:
            page=pdf.pages[0];text=page.extract_text();date=re.search(r'FECHA El (\d{2})/(\d{2})/(\d{4})',text);assert date
            match_date='-'.join(reversed(date.groups()));code=re.search(r'\bDHE?_\d{3}\b',text).group()
            table=page.find_tables()[-1]
            for side,clubid in enumerate(ids):
                left=8.5 if side==0 else 296;right=296 if side==0 else 584
                top=page.search('JUGADORES')[0]['bottom']+1;bottom=page.search('STAFF')[0]['top']-1
                lines=page.crop((left,top,right,bottom)).extract_text(x_tolerance=1,y_tolerance=2).splitlines();players=[];in_players=True
                for line in lines:
                    if line=='JUGADORES':in_players=True;continue
                    if 'STAFF' in line:break
                    if not in_players:continue
                    m=pattern.match(line)
                    if not m:
                        if 'SUPLENTES'.startswith(line.strip()) or 'SUPLENTES'.endswith(line.strip()) or 'APELLIDOS' in line:continue
                        if line.strip() and players:
                            assert not re.match(r'^\d',line),(num,clubid,line)
                            players[-1]['rawName']+=' '+line.strip()
                        continue
                    number,captain,front,raw,category,middle,registration=m.groups();number=int(number)
                    players.append({'sourceNumber':number,'rawName':re.sub(r'\s+,',',',raw.strip()),'frontRow':front.split(',') if front else [],'sourceCategory':category,'registrationClass':registration,'captain':bool(captain),'replaces':int(middle.split()[0]) if middle.split() else None})
                assert [p['sourceNumber'] for p in players]==list(range(1,24)),(num,clubid,len(players),players[-1:])
                for p in players:
                    n=p['sourceNumber'];front=[FRONT[v] for v in p['frontRow']];replacement=p['replaces'];p['name']=display_name(p['rawName'])
                    if n<=15:pos=n;basis='starting-position'
                    elif front:pos=replacement if replacement in front else front[0];basis='front-row-qualification'
                    elif replacement and 4<=replacement<=15:pos=replacement;basis='replacement-inference'
                    else:pos={16:6,17:4,18:8,19:6,20:8,21:9,22:10,23:15}[n];basis='simulation-estimate'
                    p.update({'id':f'{clubid}-p{n}','position':pos,'secondary':[v for v in front if v!=pos],'positionBasis':basis})
                    assert '\ufffd' not in p['name'] and len(p['name'])>4
                # Follow replacement chains (e.g. a reserve replacing another reserve), never invent front-row qualifications.
                for p in players:
                    if p['positionBasis']!='simulation-estimate':continue
                    target=p['replaces'];seen={p['sourceNumber']}
                    while target and 1<=target<=23 and target not in seen:
                        seen.add(target);other=players[target-1]
                        if other['positionBasis']!='simulation-estimate' and other['position']>3:
                            p['position']=other['position'];p['positionBasis']='replacement-chain-inference';break
                        target=other['replaces']
                # Select compatible primary positions for multiposition front-row reserves.
                options=[[p for p in players[15:] if role in [FRONT[v] for v in p['frontRow']]] for role in (1,2,3)]
                for cover in itertools.product(*options):
                    if len({p['id'] for p in cover})!=3:continue
                    for role,p in enumerate(cover,1):p['position']=role;p['secondary']=[FRONT[v] for v in p['frontRow'] if FRONT[v]!=role]
                    break
                teams.append({'clubId':clubid,'clubName':byid[clubid]['name'],'competitionId':byid[clubid]['competitionId'],'sourceFile':file.name,'sourceId':str(num),'matchCode':code,'matchDate':match_date,'sourcePage':1,'players':players})
            sources.append({'id':str(num),'file':file.name,'sha256':hashlib.sha256(file.read_bytes()).hexdigest(),'pages':len(pdf.pages)})
    assert len(teams)==20 and len({t['clubId'] for t in teams})==20
    names=[p['rawName'] for t in teams for p in t['players']];assert len(names)==len(set(names))==460
    data={'version':'fer-j1-2026-v1','season':'2026/2027','round':1,'notice':'Identidades y convocatorias extraídas de actas FER facilitadas por el usuario. Edades, nacionalidades, salarios y atributos no acreditados por las actas. Posiciones de suplentes inferidas cuando no constan expresamente.','sources':sources,'teams':sorted(teams,key=lambda t:int(t['clubId'][1:]))}
    output.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(f'PASS {len(teams)} clubes; {len(names)} jugadores; diez actas; nombres únicos')
    for t in data['teams']:
        uncertain=[p['name'] for p in t['players'] if p['positionBasis']=='simulation-estimate']
        print(t['clubId'],t['clubName'],len(t['players']),'estimados:',', '.join(uncertain) or 'ninguno')

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--source-dir',type=Path,required=True);parser.add_argument('--output',type=Path,default=Path('iris/data/real-rosters.json'));args=parser.parse_args();extract(args.source_dir,args.output)
