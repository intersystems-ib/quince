import {useQuery} from '@tanstack/react-query';
import {api} from './api';
import type {Injury,InjuryType,Player} from './types';

const date=(value:string)=>new Date(`${value}T12:00:00`).toLocaleDateString('es-ES');
export const injuryText=(injury:Injury)=>`${injury.name} · Grado ${injury.grade} · ${injury.remainingWeeks??injury.weeks} sem. · Alta ${date(injury.expectedReturn)}`;
export function InjuryMark({player}:{player:Pick<Player,'name'|'injury'>|undefined}){
 if(!player?.injury)return null;
 const label=`Lesionado: ${player.name}. ${injuryText(player.injury)}`;
 return <span className="injury-mark" role="img" aria-label={label} title={label}><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M8 2h8v6h6v8h-6v6H8v-6H2V8h6Z" fill="currentColor"/></svg></span>;
}

export default function InjuryStatus({player}:{player:Player}){
 if(player.retired)return <span className="pill">Retirado</span>;
 if(player.injury)return <span className={`injury-status severity-${player.injury.severity}`}><strong>{player.injury.name}</strong><small>Grado {player.injury.grade} · {player.injury.remainingWeeks??player.injury.weeks} sem. restantes</small><small>Alta {date(player.injury.expectedReturn)}</small></span>;
 return <span className={`pill ${player.available?'available':'unavailable'}`}>{player.available?'Disponible':'En recuperación'}</span>;
}

export function InjuryPanel({player}:{player:Player}){
 const injury=player.injury,history=player.injuryHistory??[];
 return <section className="card injury-panel"><h3>Estado físico y lesiones</h3>{injury?<><p className="injury-alert">{injuryText(injury)}</p><p>{injury.severity[0].toUpperCase()+injury.severity.slice(1)} · Baja inicial: {injury.weeks} {injury.weeks===1?'semana':'semanas'} · Desde {date(injury.startedOn)} · {injury.source==='match'?'Partido':'Entrenamiento'}</p><p>{injury.remainingDays??injury.weeks*7} días de baja pendientes.</p></>:<InjuryStatus player={player}/>} {history.length>0&&<details><summary>Historial de lesiones · {history.length}</summary><ul>{[...history].reverse().map(i=><li key={i.id}>{i.name} · Grado {i.grade} · {i.weeks} semanas · {date(i.startedOn)} — {date(i.recoveredOn??i.expectedReturn)}</li>)}</ul></details>}</section>;
}

export function InjuryCatalog(){
 const query=useQuery({queryKey:['injury-types'],queryFn:()=>api<{items:InjuryType[]}>('/injury-types')});
 return <details className="card injury-catalog"><summary>Lesiones y semanas de recuperación</summary>{query.isLoading?<p>Cargando lesiones…</p>:query.error?<p>No se ha podido cargar la lista de lesiones.</p>:<div className="table-wrap"><table><thead><tr><th>Lesión</th><th>Grado</th><th>Gravedad</th><th>Semanas</th></tr></thead><tbody>{query.data?.items.map(i=><tr key={i.id}><td>{i.name}</td><td>{i.grade}</td><td>{i.severity}</td><td>{i.minWeeks===i.maxWeeks?i.minWeeks:`${i.minWeeks}–${i.maxWeeks}`}</td></tr>)}</tbody></table></div>}</details>;
}
