import type {Lineup,Player} from './types';

export type LineupTarget={kind:'starter'|'bench';index:number};

export function availableBench(lineup:Lineup,players:Player[]):Lineup{
 const byId=new Map(players.map(p=>[p.id,p]));
 const bench=lineup.bench.filter(id=>!byId.has(id)||byId.get(id)!.available);
 const removedCaptain=lineup.bench.includes(lineup.captainId)&&!bench.includes(lineup.captainId);
 const captainId=removedCaptain?(lineup.slots.map(s=>s.playerId).find(id=>byId.get(id)?.available)??bench.find(id=>byId.get(id)?.available)??''):lineup.captainId;
 return bench.length===lineup.bench.length&&captainId===lineup.captainId?lineup:{...lineup,bench,captainId};
}

export function selectLineupPlayer(lineup:Lineup,players:Player[],target:LineupTarget,playerId:string):Lineup{
 const byId=new Map(players.map(p=>[p.id,p])),incoming=byId.get(playerId);
 if(!incoming?.available)return lineup;
 const current=target.kind==='starter'?lineup.slots[target.index].playerId:lineup.bench[target.index];
 const otherSlot=lineup.slots.findIndex(s=>s.playerId===playerId),otherBench=lineup.bench.indexOf(playerId);
 if(otherSlot>=0&&playerId!==current&&!byId.get(current)?.available)return lineup;
 const next={...lineup,slots:lineup.slots.map(s=>({...s})),bench:[...lineup.bench]};
 if(otherSlot>=0)next.slots[otherSlot].playerId=current;
 if(otherBench>=0)next.bench[otherBench]=current;
 if(target.kind==='starter')next.slots[target.index].playerId=playerId;else next.bench[target.index]=playerId;
 if(current===next.captainId&&!byId.get(current)?.available)next.captainId=playerId;
 return availableBench(next,players);
}

export type LineupSelection=LineupTarget|{kind:'unselected';playerId:string};
export function selectedPlayerId(l:Lineup,pick:LineupSelection):string{
 if(pick.kind==='unselected')return pick.playerId;
 return pick.kind==='starter'?l.slots[pick.index]?.playerId??'':l.bench[pick.index]??'';
}
export function positionPenalty(p:Player,position:number):number{
 return p.position===position?0:p.secondary.includes(position)?3:(p.position<=8)===(position<=8)?8:15;
}
export function lineupMorale(p:Player,position?:number):number{
 return Math.max(0,Math.min(100,p.morale-(position===undefined?0:positionPenalty(p,position))));
}
export function swapLineupPlayers(l:Lineup,players:Player[],first:LineupSelection,second:LineupSelection):Lineup{
 const a=selectedPlayerId(l,first),b=selectedPlayerId(l,second),byId=new Map(players.map(p=>[p.id,p]));
 if(a===b||(first.kind==='unselected'&&second.kind==='unselected'))return l;
 let next:Lineup;
 if(first.kind==='unselected')next=selectLineupPlayer(l,players,second as LineupTarget,a);
 else if(second.kind==='unselected')next=selectLineupPlayer(l,players,first,b);
 else if(!byId.get(b)?.available)next=selectLineupPlayer(l,players,second,a);
 else next=selectLineupPlayer(l,players,first,b);
 if(next===l)return l;
 const called=new Set([...next.slots.map(s=>s.playerId),...next.bench]);
 if(!called.has(next.captainId)){
  const oldSlot=l.slots.findIndex(s=>s.playerId===l.captainId);
  next.captainId=(oldSlot>=0?next.slots[oldSlot]?.playerId:undefined)??next.slots.find(s=>byId.get(s.playerId)?.available)?.playerId??'';
 }
 return next;
}
