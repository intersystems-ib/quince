import type {Classification,LeaguePoints} from './types';

function Breakdown({points}:{points:LeaguePoints}){return <><b>{points.total} puntos</b><small>{points.basePoints} por resultado{points.bonusOffensive?' + 1 BO':''}{points.bonusDefensive?' + 1 BD':''}</small></>}
export default function ClassificationPoints({value,home,away}:{value?:Classification;home:string;away:string}){
 if(!value?.eligible||!value.home||!value.away)return null;
 return <div className="classification-points" aria-label="Puntos de clasificación del partido"><span>Puntos de clasificación</span><div><strong>{home}</strong><Breakdown points={value.home}/></div><div><strong>{away}</strong><Breakdown points={value.away}/></div></div>;
}
