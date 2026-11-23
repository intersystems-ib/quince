import {test,expect} from '@playwright/test';
import {automaticLineup,positionScore} from '../src/automaticLineup';
import type {Lineup,Player} from '../src/types';
const make=(position:number,id=`p${position}`,average=60):Player=>({id,clubId:'c1',name:id,category:'senior',position,secondary:[],average,available:true,energy:100,morale:100,attributes:Object.fromEntries('speed strength stamina agility passing handling tackling kicking scrum lineout discipline decisions leadership ruck maul attacking defensiveReading'.split(' ').map(key=>[key,average]))} as Player);
const lineup={id:'c1-default',clubId:'c1',version:4,name:'Mi XV',slots:[],bench:[],captainId:'p9',tactic:{style:'hands',tempo:'slow',defense:'low'}} as unknown as Lineup;
const squad=()=>Array.from({length:15},(_,i)=>make(i+1));

test('selects the best available specialist and keeps tactics until explicitly saved',()=>{
 const players=[...squad(),make(9,'better9',85),make(10,'injured',99),{...make(10,'academy',99),category:'academy'} as Player,{...make(10,'otherClub',99),clubId:'c2'}];players.find(p=>p.id==='injured')!.available=false;
 const original=JSON.stringify(lineup),result=automaticLineup(lineup,players);
 expect(result.slots[8].playerId).toBe('better9');expect(result.slots.map(s=>s.position)).toEqual(Array.from({length:15},(_,i)=>i+1));expect(new Set(result.slots.map(s=>s.playerId)).size).toBe(15);expect(result.version).toBe(4);expect(result.tactic).toEqual(lineup.tactic);expect(JSON.stringify(lineup)).toBe(original);
});

test('always prioritizes the higher average over individual skills, fitness and morale',()=>{
 const players=squad(),higher={...make(10,'higher',80),energy:1,morale:1,attributes:{...make(10).attributes,kicking:1,passing:1}},lower={...make(10,'lower',79),attributes:{...make(10).attributes,kicking:100,passing:100,decisions:100}};
 players.push(higher,lower);
 expect(automaticLineup(lineup,players).slots[9].playerId).toBe('higher');
 expect(positionScore(higher,10)).toBeGreaterThan(positionScore(lower,10));
 const tied={...higher,id:'tie',energy:100,morale:100};
 expect(automaticLineup(lineup,[...players,tied]).slots[9].playerId).toBe('tie');
});

test('chooses the highest average in every natural position for a complete squad',()=>{
 const players=[...squad(),...Array.from({length:15},(_,i)=>({...make(i+1,`star${i+1}`,90-i/10),energy:15,morale:20}))];
 const result=automaticLineup(lineup,players);
 for(const slot of result.slots)expect(slot.playerId).toBe(`star${slot.position}`);
});

test('resolves versatile cover globally and completes the reserve front row',()=>{
 const players=squad(),versatile={...make(1,'versatile',75),secondary:[2]},hooker=make(2,'hooker',70),prop=make(1,'reserve1',65),tight=make(3,'reserve3',65);
 players.push(versatile,hooker,prop,tight,...[4,8,9,10,15].map(p=>make(p,`reserve${p}`,55)));
 const result=automaticLineup(lineup,players),called=[...result.slots.map(s=>s.playerId),...result.bench.filter(Boolean)];
 expect(result.bench.filter(Boolean)).toHaveLength(8);expect(new Set(called).size).toBe(called.length);
 expect(result.bench.slice(0,3).map(id=>players.find(p=>p.id===id)!)).toEqual(expect.arrayContaining([expect.objectContaining({position:3})]));
});

test('leaves empty bench slots and rejects an incomplete XV without changing the draft',()=>{
 expect(automaticLineup(lineup,squad()).bench).toEqual(Array(8).fill(''));
 expect(()=>automaticLineup(lineup,squad().slice(1))).toThrow('suficientes');
 expect(()=>automaticLineup(lineup,squad().map(p=>({...p,position:1})))).toThrow('delanteros');
});


test('balances a strong forward pool with three backs and covers the main positions',()=>{
 const starters=Array.from({length:15},(_,i)=>make(i+1,`starter${i+1}`,100));
 const reserves=[make(1,'loose',89),make(2,'hooker',88),make(3,'tight',87),make(4,'lock',86),make(8,'backrow',85),make(9,'scrumhalf',75),make(10,'flyhalf',74),make(15,'outside',73),make(1,'extraProp',84),make(6,'extraFlanker',83),make(5,'extraLock',82),make(14,'lowerOutside',65),make(9,'lower9',60)];
 const players=[...starters,...reserves],result=automaticLineup(lineup,players),bench=result.bench.filter(Boolean).map(id=>players.find(p=>p.id===id)!);
 expect(bench).toHaveLength(8);expect(bench.filter(p=>p.position<=8)).toHaveLength(5);expect(bench.filter(p=>p.position>8)).toHaveLength(3);
 expect(new Set(result.bench)).toEqual(new Set(['loose','hooker','tight','lock','backrow','scrumhalf','flyhalf','outside']));
});

test('balances a strong backs pool and uses secondary positions for reserve cover',()=>{
 const starters=Array.from({length:15},(_,i)=>make(i+1,`starter${i+1}`,100));
 const versatile={...make(12,'versatile',90),secondary:[10]},reserves=[make(1,'loose',70),make(2,'hooker',69),make(3,'tight',68),make(5,'lock',67),make(7,'backrow',66),make(9,'nine',91),versatile,make(14,'wing',89),make(10,'lower10',65),make(13,'extraCentre',88),make(15,'extra15',87)];
 const players=[...starters,...reserves],bench=automaticLineup(lineup,players).bench.filter(Boolean).map(id=>players.find(p=>p.id===id)!);
 expect(bench.filter(p=>p.position<=8)).toHaveLength(5);expect(bench.filter(p=>p.position>8)).toHaveLength(3);expect(bench.map(p=>p.id)).toContain('versatile');expect(bench.map(p=>p.id)).not.toContain('lower10');
});

test('fills the available bench when positional cover is scarce without selecting injured players',()=>{
 const starters=Array.from({length:15},(_,i)=>make(i+1,`starter${i+1}`,100)),injured={...make(2,'injured',99),available:false};
 const reserves=[make(1,'one',80),make(4,'four',79),make(6,'six',78),make(8,'eight',77),make(9,'nine',76),make(10,'ten',75),make(15,'fifteen',74),injured];
 const players=[...starters,...reserves],bench=automaticLineup(lineup,players).bench.filter(Boolean);
 expect(bench).toHaveLength(7);expect(bench).not.toContain('injured');expect(new Set(bench).size).toBe(7);
 expect(automaticLineup(lineup,[...starters,...reserves.slice(0,3)]).bench.filter(Boolean)).toHaveLength(3);
});
