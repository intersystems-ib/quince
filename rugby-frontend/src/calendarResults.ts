import type {Fixture} from './types';
export function fixtureOutcome(f:Fixture,clubId:string):'win'|'loss'|'draw'|''{
 if(f.status!=='finished'||typeof f.homeScore!=='number'||typeof f.awayScore!=='number')return '';
 if(f.winnerId)return f.winnerId===clubId?'win':'loss';
 const own=f.homeId===clubId?f.homeScore:f.awayScore,other=f.homeId===clubId?f.awayScore:f.homeScore;
 return own>other?'win':own<other?'loss':'draw';
}
export const outcomeLabels={win:'Victoria',loss:'Derrota',draw:'Empate','':''};
