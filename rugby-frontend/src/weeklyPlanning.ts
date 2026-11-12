import type {Player,TrainingExecution,TrainingTheme,WeeklyDay} from './types';

export function drillOptions(theme:TrainingTheme,line:'forwards'|'backs'):string[] {
  return [...new Set(theme[line].split(','))];
}
export function weeklyProposal(current:WeeklyDay[],themes:TrainingTheme[],random= Math.random):WeeklyDay[] {
  const pick=<T,>(items:T[]):T=>items[Math.floor(random()*items.length)];
  const active=themes.filter(t=>t.id!=='rest');
  const main=pick(active),restDay=1+Math.floor(random()*6);
  const result=current.map(d=>{
    const theme=d.day===restDay||d.day===7?themes.find(t=>t.id==='rest')!:random()<.5?main:pick(active);
    return {day:d.day,theme:theme.id,forwards:pick(drillOptions(theme,'forwards')),backs:pick(drillOptions(theme,'backs'))};
  });
  if(JSON.stringify(result)===JSON.stringify(current)) {
    const day=result.find(d=>d.theme!=='rest')!;
    const theme=active[(active.findIndex(t=>t.id===day.theme)+1)%active.length];
    Object.assign(day,{theme:theme.id,forwards:pick(drillOptions(theme,'forwards')),backs:pick(drillOptions(theme,'backs'))});
  }
  return result;
}
export function trainingImprovements(executions:TrainingExecution[],players:Player[],day:number) {
  const byId=new Map(players.map(p=>[p.id,p]));
  const improved=new Map<string,Set<string>>();
  for(const execution of executions){
    if(execution.day<day-6||execution.day>day)continue;
    for(const result of execution.results){
      if(!byId.has(result.playerId))continue;
      for(const change of result.changes??[]){
        if(!(change.after-change.before>1e-8))continue;
        if(!improved.has(result.playerId))improved.set(result.playerId,new Set());
        improved.get(result.playerId)!.add(change.attribute);
      }
    }
  }
  return [...improved].map(([id,attributes])=>({player:byId.get(id)!,attributes:[...attributes]}))
    .sort((a,b)=>a.player.name.localeCompare(b.player.name,'es'));
}
