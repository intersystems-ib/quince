"""Build deterministic offsets against the original simulated seed, not played saves."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
keys='speed strength stamina agility passing handling tackling kicking scrum lineout discipline decisions leadership ruck maul attacking defensiveReading'.split()
positions=list(range(1,16))+[1,2,3,4,6,9,10,15,11,12,5,8,13,14]
orders={416:['c3','c10','c2','c8','c7','c4','c6','c1','c5','c9'],417:['c20','c12','c15','c16','c17','c18','c14','c13','c19','c11']}
points={416:[18,17,17,15,11,11,11,8,6,1],417:[21,17,16,13,13,13,9,6,4,2]}
clubs=json.loads((ROOT/'iris/data/clubs.json').read_text(encoding='utf-8'))['clubs']
def original(c,n):
 pos=positions[n-1];a={}
 for k,key in enumerate(keys[:13],1):
  a[key]=44+((n*17+c*11+k*7)%29)+(9 if (pos<=8 and k in [2,9,10]) or (pos>=9 and k in [1,5,8]) else 0)
 a.update(ruck=(a['strength']+a['tackling']+a['decisions'])/3,maul=(a['strength']+a['scrum']+a['handling'])/3,attacking=(a['passing']+a['decisions']+a['speed'])/3,defensiveReading=(a['tackling']+a['decisions']+a['discipline'])/3)
 return [round(a[k],6) for k in keys]
def academy(c):
 rows=[original(c,n) for n in range(24,30)];covered=set(positions[23:]);serial=0
 for pos in [p for p in range(1,16) if p not in covered]+list(range(10,15)):
  serial+=1
  rows.append([30+((serial*19+c*7+k*11)%32)+(8 if (pos<=8 and key in ['strength','scrum','lineout','ruck','maul']) or (pos>8 and key in ['speed','agility','passing','kicking']) else 0) for k,key in enumerate(keys)])
 assert len(rows)==20
 return rows
def offset(rows,target):
 vals=sum(rows,[]);low,high=-100,100
 for _ in range(60):
  mid=(low+high)/2
  if sum(max(1,min(100,v+mid)) for v in vals)/len(vals)<target:low=mid
  else:high=mid
 return round((low+high)/2,9)
# Final placement includes the playoffs; semifinalists use their regular ranking as tie-break.
history_honor=['c2','c3','c7','c6','c1','c5','c10','c8','c4','c12','c18']
history_url='https://es.wikipedia.org/wiki/Divisi%C3%B3n_de_Honor_de_rugby_2025-26'
entries=[]
for division,order in orders.items():
 for rank,cid in enumerate(order,1):
  club=next(c for c in clubs if c['id']==cid);c=int(cid[1:]);current=(80 if division==416 else 64)-(rank-1)*12/9
  historical_rank=history_honor.index(cid)+1 if cid in history_honor else None
  weight=.65 if historical_rank is not None else 0
  # Current Honor's promoted club has no prior Honor finish: retain its current reference.
  # Relegated Honor clubs lead the historical reference for their new Elite division.
  historical=(80-(historical_rank-1)*12/9 if division==416 else 64-(historical_rank-10)*12/9) if historical_rank is not None else current
  target=current*(1-weight)+historical*weight
  entries.append(dict(clubId=cid,name=club['name'],divisionId=division,rank=rank,historicalRank=historical_rank,historicalSeason="2025/2026",historicalWeight=weight,currentWeight=1-weight,currentTarget=round(current,6),historicalTarget=round(historical,6),points=points[division][rank-1],played=4 if cid in ['c13','c19'] else 5,seniorTarget=round(target,6),academyTarget=round(target-18,6),seniorOffset=offset([original(c,n) for n in range(1,24)],target),academyOffset=offset(academy(c),target-18)))
entries.sort(key=lambda row:(row['divisionId'],-row['seniorTarget']))
for division in orders:
 for blended_rank,row in enumerate((r for r in entries if r['divisionId']==division),1):row['blendedRank']=blended_rank
reference=dict(version='standings-2026-11-10-v2-history',consultedOn='2026-11-10',description='Simulated ratings calibrated to the standings available at consultation, not official player ratings.',historicalWeight=.65,currentWeight=.35,historicalPlacementMethod='Champion, finalist, semifinalists ordered by regular phase, then quarterfinalists ordered by regular phase, then remaining regular places. No historical record: current reference only.',sources=[history_url]+[f'https://resultadosrugby.isquad.es/clasificacion.php?seleccion=0&id={tid}&id_ambito=1&id_territorial=9999&id_superficie=1&iframe=0&id_categoria=0&id_competicion={division}' for division,tid in [(416,1296),(417,1297)]],clubs=entries)
(ROOT/'iris/data/team-quality.json').write_text(json.dumps(reference,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('20 clubs; 65 percent previous final season / 35 percent current standings where historical data exists; no invented history')
