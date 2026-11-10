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
