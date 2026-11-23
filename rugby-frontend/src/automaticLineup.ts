import type {Lineup,Player} from './types';

// Position compatibility comes first, then average; fitness and morale only break ties.
function abilityScore(player:Player):number{
 return player.average*10000+player.energy/100+player.morale/10000;
}
export function positionScore(player:Player,position:number):number{
 if((player.position<=8)!==(position<=8))return -1e6;
 const fit=player.position===position?1e9:player.secondary.includes(position)?1e8:0;
 return fit+abilityScore(player);
}
// Maximum-weight assignment avoids consuming a versatile player needed in another position.
function assign(scores:number[][]):number[]{
 const n=scores.length,m=scores[0].length,u=Array(n+1).fill(0),v=Array(m+1).fill(0),p=Array(m+1).fill(0),way=Array(m+1).fill(0);
 for(let i=1;i<=n;i++){
  p[0]=i;let j0=0;const min=Array(m+1).fill(Infinity),used=Array(m+1).fill(false);
  do{
   used[j0]=true;const i0=p[j0];let delta=Infinity,j1=0;
   for(let j=1;j<=m;j++)if(!used[j]){const current=-scores[i0-1][j-1]-u[i0]-v[j];if(current<min[j]){min[j]=current;way[j]=j0;}if(min[j]<delta){delta=min[j];j1=j;}}
   for(let j=0;j<=m;j++){if(used[j]){u[p[j]]+=delta;v[j]-=delta;}else min[j]-=delta;}
   j0=j1;
  }while(p[j0]!==0);
  do{const j1=way[j0];p[j0]=p[j1];j0=j1;}while(j0!==0);
 }
 const result=Array(n).fill(-1);for(let j=1;j<=m;j++)if(p[j])result[p[j]-1]=j-1;return result;
}
export function automaticLineup(lineup:Lineup,players:Player[]):Lineup{
 const available=players.filter(p=>p.clubId===lineup.clubId&&p.category==='senior'&&p.available&&!p.retired).sort((a,b)=>a.id.localeCompare(b.id,'en'));
 if(available.length<15)throw new Error('No hay suficientes jugadores disponibles para completar el XV.');
 const scores=Array.from({length:15},(_,index)=>available.map(p=>positionScore(p,index+1))),chosen=assign(scores);
 if(chosen.some((column,row)=>column<0||scores[row][column]<0))throw new Error('No hay suficientes delanteros o tres cuartos disponibles para completar el XV.');
 const slots=chosen.map((column,index)=>({position:index+1,playerId:available[column].id})),used=new Set(slots.map(s=>s.playerId)),bench:string[]=[];
 const remaining=available.filter(p=>!used.has(p.id));
 const covers=(player:Player,positions:number[])=>positions.includes(player.position)||player.secondary.some(position=>positions.includes(position));
 let fullFront=false;
 if(remaining.length>=3){
  const frontScores=[1,2,3].map(position=>remaining.map(player=>covers(player,[position])?abilityScore(player):-1e6)),front=assign(frontScores);
  fullFront=front.every((column,row)=>frontScores[row][column]>=0);
 }
 // Five forwards / three backs; with a seven-player bench, four forwards / three backs.
 const roles=fullFront?[[1],[2],[3],[4,5],[6,7,8],[9],[10],[11,12,13,14,15]]:[[1],[2],[3],[4,5,6,7,8],[9],[10],[11,12,13,14,15]];
 const benchScores=roles.map((positions,index)=>[
  ...remaining.map(player=>{
   const sameGroup=(player.position<=8)===(positions[0]<=8);
   const coverage=sameGroup&&covers(player,positions)?(index<3?1e10:1e9):sameGroup?1e7:0;
   return coverage+abilityScore(player);
  }),
  ...roles.map(()=>0)
 ]);
 for(const column of assign(benchScores))if(column<remaining.length){used.add(remaining[column].id);bench.push(remaining[column].id);}
 const captainId=used.has(lineup.captainId)?lineup.captainId:chosen.map(column=>available[column]).sort((a,b)=>(b.attributes.leadership??b.average)-(a.attributes.leadership??a.average)||a.id.localeCompare(b.id,'en'))[0].id;
 return {...lineup,slots,bench:Array.from({length:8},(_,i)=>bench[i]??''),captainId};
}
