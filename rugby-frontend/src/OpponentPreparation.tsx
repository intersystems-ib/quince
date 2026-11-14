import FixtureSummary from './FixtureSummary';
import VenueInfo from './VenueInfo';
import {useState} from 'react';
import {useMutation,useQuery,useQueryClient} from '@tanstack/react-query';
import {Link} from 'react-router-dom';
import {CalendarClock,ChevronRight,RefreshCw,Check} from 'lucide-react';
import {api} from './api';
import {requestId} from './requestId';
import {Energy,ErrorBox,Loading,penaltyPriorityLabels} from './components';
import type {Club,Fixture,Page,PreparationMeeting,PreparationReport,Tactic} from './types';
export const preparationPath=(fixtureId?:string)=>`/staff?tab=preparacion${fixtureId?`&fixture=${encodeURIComponent(fixtureId)}`:''}`;
const dateLabel=(date:string)=>new Date(date+'T12:00:00').toLocaleDateString('es-ES',{day:'numeric',month:'long'});
const styleLabels={hands:'A la mano',balanced:'Equilibrado',kicking:'Al pie'};
const tempoLabels={slow:'Pausado',normal:'Normal',fast:'Alto'};
const defenseLabels={low:'Baja',normal:'Normal',high:'Alta'};
export const tacticText=(t:Tactic)=>`${styleLabels[t.style]} · Ritmo ${tempoLabels[t.tempo]} · Presión ${defenseLabels[t.defense]} · Golpes: ${penaltyPriorityLabels[t.penaltyPriority??'auto']}`;
function useMeetings(club:Club){return useQuery({queryKey:['preparations',club.id,club.date],queryFn:()=>api<{items:PreparationMeeting[]}>('/my-club/preparations')});}
function upcoming(items:PreparationMeeting[],day:number){return items.filter(m=>!m.closed&&m.matchDay>=day).sort((a,b)=>a.day-b.day||a.fixtureId.localeCompare(b.fixtureId))[0];}
export function PreparationTask({club}:{club:Club}){
 const q=useMeetings(club),meeting=upcoming(q.data?.items??[],club.day);
 return <Link to={preparationPath(meeting?.fixtureId)}><span className="task-icon purple"><CalendarClock size={20}/></span><div><strong>Reunión con el cuerpo técnico</strong><p>{meeting?`${meeting.opponentName} · ${meeting.available?'Informe disponible':meeting.preparing?'Informe en preparación':dateLabel(meeting.date)}`:'Preparación del próximo rival.'}</p></div><ChevronRight size={18}/></Link>;
}
export default function PreparationPanel({club,fixtureId}:{club:Club;fixtureId?:string}){
 const q=useMeetings(club);
 if(q.isLoading)return <Loading/>;
 if(q.error)return <ErrorBox error={q.error}/>;
 const requested=fixtureId?q.data?.items.find(m=>m.fixtureId===fixtureId):undefined;
 const meeting=requested&&(!requested.closed||requested.matchDay>club.day)?requested:upcoming(q.data?.items??[],club.day)??requested;
 if(!meeting)return <section className="card preparation-waiting"><CalendarClock size={26}/><h3>No hay una reunión pendiente</h3><p className="muted">Las reuniones se programan dos días antes de los partidos oficiales.</p></section>;
 if(!meeting.available)return <section className="card preparation-waiting"><CalendarClock size={26}/><h3>Preparación frente a {meeting.opponentName}</h3><p>{meeting.closed?'La reunión de preparación ha finalizado.':meeting.preparing?'El cuerpo técnico está trabajando en la elaboración del informe.':`La preparación del informe comenzará después del partido anterior${meeting.preparationStartDate?`, a partir del ${dateLabel(meeting.preparationStartDate)}`:''}.`}</p><p className="muted">Reunión: {dateLabel(meeting.date)} · Partido: {dateLabel(meeting.matchDate)}</p><Link className="button secondary" to="/calendario">Ver calendario</Link></section>;
 return <OpponentPreparation key={`${meeting.fixtureId}-${club.date}`} fixtureId={meeting.fixtureId}/>;
}
function OpponentPreparation({fixtureId}:{fixtureId:string}){
 const q=useQuery({queryKey:['preparation',fixtureId],queryFn:()=>api<PreparationReport>(`/preparations/${fixtureId}`),retry:false});
 if(q.isLoading)return <Loading/>;
 if(q.error)return <ErrorBox error={q.error}/>;
 const r=q.data!;
 return <><div className="preparation-report-heading"><div><div className="eyebrow">REUNIÓN CON EL CUERPO TÉCNICO</div><h2>Preparación del rival</h2><p>Partido del {dateLabel(r.meeting.matchDate)}</p></div><button className="button secondary" disabled={q.isFetching} onClick={()=>void q.refetch()}><RefreshCw size={16}/>Actualizar informe</button></div>
 <PreparationFixture report={r}/>
 {r.lastApplied&&(r.lastApplied.outdated||r.lastApplied.tacticChanged)&&<p className="notice" role="status">La convocatoria o la táctica han cambiado. Actualiza el informe antes de aplicar la recomendación.</p>}
 <section className="card preparation-comparison" aria-label="Análisis del rival"><div className="card-top"><h3>Análisis del rival</h3><span className="tiny-tag">ENERGÍA Y MORAL INCLUIDAS</span></div><div className="preparation-analysis-layout"><div className="preparation-analysis-main"><div className="table-wrap"><table aria-label="Comparación de aspectos del juego"><thead><tr><th>Aspecto</th><th>{r.ownName}</th><th>Rival estimado</th></tr></thead><tbody>{r.aspects.map(a=><tr key={a.id}><th scope="row">{a.name}<small>{a.group==='forwards'?'Delanteros':a.group==='backs'?'Tres cuartos':'XV completo'}</small></th><td className={a.delta>2?'positive':''}><strong>{Math.round(a.own)}</strong></td><td className={a.delta< -2?'preparation-rival-edge':''}><strong>{Math.round(a.opponent)}</strong></td></tr>)}</tbody></table></div><div className="preparation-units">{(['forwards','backs'] as const).map(g=><div key={g}><h4>{g==='forwards'?'Delanteros':'Tres cuartos'}</h4><p>{r.groups.own[g].count} jugadores · Media {Math.round(r.groups.own[g].average)}</p><label>Energía<Energy value={r.groups.own[g].energy}/></label><label>Moral<Energy value={r.groups.own[g].morale}/></label></div>)}</div><p className="muted">Las cifras del rival son estimaciones. Su alineación y su táctica pueden cambiar antes del encuentro.</p></div>
 <aside className="preparation-findings"><section><h3>Nuestras ventajas</h3>{r.advantages.length?<ul>{r.advantages.map(t=><li key={t}>{t}</li>)}</ul>:<p className="muted">No se detectan ventajas claras.</p>}</section><section><h3>Riesgos a vigilar</h3>{r.risks.length?<ul>{r.risks.map(t=><li key={t}>{t}</li>)}</ul>:<p className="muted">No se detectan desventajas claras.</p>}</section><PreparationDecision key={`${r.fixtureId}-${r.reportToken}-${r.lineupVersion}`} report={r}/></aside></div></section>
 </>;
}
function PreparationFixture({report:r}:{report:PreparationReport}){
 const fixtures=useQuery({queryKey:['fixtures'],queryFn:()=>api<Page<Fixture>>('/my-club/fixtures?limit=500')});
 const fixture=fixtures.data?.items.find(f=>f.id===r.fixtureId);
 return <section className="card calendar-fixture preparation-fixture" aria-label="Partido analizado">{fixtures.isLoading?<Loading/>:fixtures.error?<ErrorBox error={fixtures.error}/>:fixture?<><FixtureSummary fixture={fixture} clubId={r.clubId} names={{[r.clubId]:r.ownName,[r.opponentId]:r.opponentName}}/><VenueInfo venue={fixture.venue}/></>:<p className="muted">El partido ya no está disponible en el calendario.</p>}</section>;
}
function PreparationDecision({report:r}:{report:PreparationReport}){
 const qc=useQueryClient(),[key,setKey]=useState(requestId),tactic=r.recommendation.tactic;
 const mutation=useMutation({mutationFn:()=>api<PreparationReport>(`/preparations/${r.fixtureId}/apply`,'POST',{lineupId:r.lineupId,lineupVersion:r.lineupVersion,reportToken:r.reportToken,choice:'main'},key),onSuccess:()=>{setKey(requestId());void qc.invalidateQueries();}});
 const applied=r.lastApplied&&!r.lastApplied.outdated&&!r.lastApplied.tacticChanged;
 return <section className="preparation-recommendation"><h3>Propuesta técnica</h3><ul className="preparation-tactic-list">{[['Construcción de juego',styleLabels[tactic.style]],['Ritmo',tempoLabels[tactic.tempo]],['Presión defensiva',defenseLabels[tactic.defense]],['Prioridad en golpes',penaltyPriorityLabels[tactic.penaltyPriority??'auto']]].map(([label,value])=><li key={label}><strong>{label}:</strong> {value}.</li>)}</ul>
 {!r.ready&&<div className="notice" role="alert"><p>Revisa la convocatoria antes de aplicar la recomendación.</p>{r.validationErrors.length>0&&<ul>{r.validationErrors.map(e=><li key={e}>{e}</li>)}</ul>}<Link to="/alineacion">Editar alineación →</Link></div>}
 {mutation.error&&<ErrorBox error={mutation.error} onDismiss={()=>mutation.reset()}/>}
 <p className="preparation-reason">{r.recommendation.reason}</p>
 <button className="button dark full" disabled={!r.ready||mutation.isPending||!!applied} onClick={()=>mutation.mutate()}>{mutation.isPending?'Aplicando…':'Aplicar recomendación'}<Check size={16}/></button>
 {applied&&<p className="positive preparation-applied" role="status">Recomendación aplicada.</p>}</section>;
}
