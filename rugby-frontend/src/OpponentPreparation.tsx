import {useEffect,useState} from 'react';
import {useMutation,useQuery,useQueryClient} from '@tanstack/react-query';
import {Link,useParams} from 'react-router-dom';
import {CalendarClock,ArrowRight,RefreshCw,Check} from 'lucide-react';
import {api} from './api';
import {requestId} from './requestId';
import {Energy,ErrorBox,Heading,Loading,TacticFields,penaltyPriorityLabels} from './components';
import ClubCrest from './ClubCrest';
import type {Club,Lineup,Page,PreparationMeeting,PreparationReport,Tactic} from './types';
export const tacticText=(t:Tactic)=>`${{hands:'A la mano',balanced:'Equilibrado',kicking:'Al pie'}[t.style]} · Ritmo ${{slow:'pausado',normal:'normal',fast:'alto'}[t.tempo]} · Presión ${{low:'baja',normal:'normal',high:'alta'}[t.defense]} · Golpes: ${penaltyPriorityLabels[t.penaltyPriority??'auto']}`;
export function PreparationNotice({club}:{club:Club}){
 const q=useQuery({queryKey:['preparations',club.id,club.date],queryFn:()=>api<{items:PreparationMeeting[]}>('/my-club/preparations')});
 const due=q.data?.items.filter(m=>m.available)??[];
 if(!due.length)return null;
 return <section className="card preparation-notice" aria-label="Reuniones de preparación">{due.map(m=><div key={m.fixtureId}><CalendarClock size={23}/><span><strong>{m.applied?'Preparación del rival disponible':'Reunión con el cuerpo técnico'}</strong><small>{m.opponentName} · Partido del {new Date(m.matchDate+'T12:00:00').toLocaleDateString('es-ES')}</small></span><Link className="button dark" to={`/preparacion/${m.fixtureId}`}>{m.applied?'Consultar informe':'Preparar al rival'}<ArrowRight size={16}/></Link></div>)}</section>;
}
export function PreparationMatchNote({fixtureId}:{fixtureId:string}){
 const q=useQuery({queryKey:['preparation-preview',fixtureId],queryFn:()=>api<PreparationReport>(`/preparations/${fixtureId}`),retry:false});
 const r=q.data;
 if(!r)return null;
 return <section className="notice preparation-match-note"><CalendarClock size={20}/><div><strong>Preparación del rival</strong><p>{r.lastApplied?`${r.lastApplied.outdated?'Informe actualizado desde la reunión. ':''}${r.lastApplied.tacticChanged?'La táctica se ha modificado. ':''}Plan aplicado: ${tacticText(r.lastApplied.tactic)}`:'El cuerpo técnico tiene una propuesta para este encuentro.'}</p></div><Link className="button secondary" to={`/preparacion/${fixtureId}`}>Consultar informe</Link></section>;
}
export default function OpponentPreparation(){
 const {id}=useParams(),[lineupId,setLineupId]=useState('');
 const q=useQuery({queryKey:['preparation',id,lineupId],queryFn:()=>api<PreparationReport>(`/preparations/${id}${lineupId?`?lineupId=${encodeURIComponent(lineupId)}`:''}`)});
 const lineups=useQuery({queryKey:['lineups'],queryFn:()=>api<Page<Lineup>>('/my-club/lineups')});
 if(q.isLoading)return <Loading/>;
 if(q.error)return <><Link className="back-link" to="/calendario">← Volver al calendario</Link><ErrorBox error={q.error}/></>;
 const r=q.data!;
 return <><Link className="back-link" to="/calendario">← Volver al calendario</Link><Heading eyebrow="REUNIÓN CON EL CUERPO TÉCNICO" title="Prepara al rival." description={`${r.ownName} frente a ${r.opponentName} · ${new Date(r.meeting.matchDate+'T12:00:00').toLocaleDateString('es-ES')}`} action={<button className="button secondary" disabled={q.isFetching} onClick={()=>void q.refetch()}><RefreshCw size={16}/>Actualizar informe</button>}/>
 <section className="card preparation-header"><div><ClubCrest clubId={r.clubId} name={r.ownName}/><strong>{r.ownName}</strong><span>frente a</span><ClubCrest clubId={r.opponentId} name={r.opponentName}/><strong>{r.opponentName}</strong></div><label>Alineación analizada<select aria-label="Alineación analizada" disabled={r.lineupLocked} value={lineupId||r.lineupId} onChange={e=>setLineupId(e.target.value)}>{lineups.data?.items.map(l=><option key={l.id} value={l.id}>{l.name}</option>)}</select></label><p>Rival: XV probable · Precisión {r.confidence.label.toLocaleLowerCase()} del cuerpo técnico ({Math.round(r.confidence.quality)}/100).</p></section>
 {r.lastApplied&&(r.lastApplied.outdated||r.lastApplied.tacticChanged)&&<p className="notice" role="status">{r.lastApplied.outdated?'El equipo o el informe han cambiado desde la última preparación.':'Has modificado la táctica desde la reunión.'} Revisa la propuesta antes del partido.</p>}
 <section className="card preparation-comparison" aria-label="Análisis del rival"><div className="card-top"><h3>Comparación del rendimiento previsto</h3><span className="tiny-tag">ENERGÍA Y MORAL INCLUIDAS</span></div><div className="preparation-analysis-layout"><div className="preparation-analysis-main"><div className="table-wrap"><table aria-label="Comparación de aspectos del juego"><thead><tr><th>Aspecto</th><th>{r.ownName}</th><th>Rival estimado</th></tr></thead><tbody>{r.aspects.map(a=><tr key={a.id}><th scope="row">{a.name}<small>{a.group==='forwards'?'Delanteros':a.group==='backs'?'Tres cuartos':'XV completo'}</small></th><td className={a.delta>2?'positive':''}><strong>{Math.round(a.own)}</strong></td><td className={a.delta< -2?'preparation-rival-edge':''}><strong>{Math.round(a.opponent)}</strong><small>±{a.uncertainty}</small></td></tr>)}</tbody></table></div><div className="preparation-units">{(['forwards','backs'] as const).map(g=><div key={g}><h4>{g==='forwards'?'Delanteros':'Tres cuartos'}</h4><p>{r.groups.own[g].count} jugadores · Media {Math.round(r.groups.own[g].average)}</p><label>Energía<Energy value={r.groups.own[g].energy}/></label><label>Moral<Energy value={r.groups.own[g].morale}/></label></div>)}</div><p className="muted">Las cifras del rival son estimaciones. Su alineación y su táctica pueden cambiar antes del encuentro.</p></div>
 <aside className="preparation-findings"><section><h3>Nuestras ventajas</h3>{r.advantages.length?<ul>{r.advantages.map(t=><li key={t}>{t}</li>)}</ul>:<p className="muted">No se detectan ventajas claras.</p>}</section><section><h3>Riesgos a vigilar</h3>{r.risks.length?<ul>{r.risks.map(t=><li key={t}>{t}</li>)}</ul>:<p className="muted">No se detectan desventajas claras.</p>}</section></aside></div></section>
 {!r.ready&&<div className="notice" role="alert"><strong>Revisa las alineaciones antes de aplicar una propuesta.</strong>{r.validationErrors.length>0&&<ul>{r.validationErrors.map(e=><li key={e}>{e}</li>)}</ul>}<Link to="/alineacion">Editar mi alineación →</Link></div>}
 <PreparationDecision key={`${r.fixtureId}-${r.lineupId}-${r.reportToken}-${r.lineupVersion}`} report={r}/>
 </>;
}
function PreparationDecision({report:r}:{report:PreparationReport}){
 const qc=useQueryClient(),[choice,setChoice]=useState<'main'|'alternative'|'custom'>('main'),[custom,setCustom]=useState<Tactic>(r.currentTactic),[key,setKey]=useState(requestId),[success,setSuccess]=useState(false);
 const proposal=choice==='alternative'?r.alternative:r.recommendation,tactic=choice==='custom'?custom:proposal.tactic;
 const mutation=useMutation({mutationFn:()=>api<PreparationReport>(`/preparations/${r.fixtureId}/apply`,'POST',{lineupId:r.lineupId,lineupVersion:r.lineupVersion,reportToken:r.reportToken,choice,...(choice==='custom'?{tactic}: {})},key),onSuccess:()=>{setKey(requestId());setSuccess(true);void qc.invalidateQueries();}});
 useEffect(()=>{setSuccess(false);},[choice,custom]);
 return <section className="card preparation-decision"><div className="card-top"><h3>Propuesta del cuerpo técnico</h3><Link to="/alineacion">Editar alineación</Link></div><div className="competition-tabs" role="tablist" aria-label="Propuesta táctica">{([['main','Recomendada'],['alternative','Alternativa'],['custom','Personalizar']] as const).map(([v,label])=><button key={v} role="tab" aria-selected={choice===v} disabled={mutation.isPending} onClick={()=>{setChoice(v);mutation.reset();setKey(requestId());}}>{label}</button>)}</div>{choice==='custom'?<TacticFields value={custom} onChange={value=>{setCustom(value);mutation.reset();setKey(requestId());}}/>:<><strong className="preparation-tactic">{tacticText(tactic)}</strong><p>{proposal.reason}</p><p className="muted">{proposal.risk}</p></>}{mutation.error&&<ErrorBox error={mutation.error}/>}<div className="preparation-actions"><button className="button dark" disabled={!r.ready||mutation.isPending} onClick={()=>mutation.mutate()}>{mutation.isPending?'Aplicando…':'Aplicar a mi alineación'}<Check size={16}/></button><Link className="button secondary" to="/calendario">Mantener mi táctica</Link></div>{success&&<p className="success" role="status">Táctica guardada en {r.lineupName}.</p>}{r.lastApplied&&!r.lastApplied.outdated&&!r.lastApplied.tacticChanged&&<p className="positive" role="status">Plan vigente: {tacticText(r.lastApplied.tactic)}</p>}</section>;
}
