import type {Match} from './types';

type MatchTime=Pick<Match,'clock'|'period'|'firstHalfAddedSeconds'>;
export function matchSeconds(match:MatchTime,seconds=match.clock,period=match.period){
 return Math.max(0,seconds-(period===2?(match.firstHalfAddedSeconds??0):0));
}
export function isAddedTime(match:MatchTime){return matchSeconds(match)>(match.period===1?2400:4800);}
