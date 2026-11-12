import {useDayAdvanceBlock} from './DayAdvanceControl';
import {drillOptions,trainingImprovements,weeklyProposal} from './weeklyPlanning';
import {useState} from 'react';
import {Link} from 'react-router-dom';
import {useQuery} from '@tanstack/react-query';
import {ArrowRight,Check,RotateCcw,CalendarDays,Shuffle} from 'lucide-react';
import {api} from './api';
import {Action,ErrorBox,Heading,Loading} from './components';
import type {Club,Page,Player,Staff,Training,TrainingExecution,TrainingType,TrainingWeek,WeeklyDay} from './types';

const dayNames=['Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo'];
export default function TrainingView({club}:{club:Club}){
 const [category,setCategory]=useState<Player['category']>('senior');
 const plan=useQuery({queryKey:['training'],queryFn:()=>api<Training>('/my-club/training-plan')});
 const players=useQuery({queryKey:['players'],queryFn:()=>api<Page<Player>>('/my-club/players')});
 const catalog=useQuery({queryKey:['training-types'],queryFn:()=>api<{items:TrainingType[]}>('/training-types')});
 const staff=useQuery({queryKey:['staff'],queryFn:()=>api<Staff>('/my-club/staff')});
 const history=useQuery({queryKey:['training-history',club.id,club.day],queryFn:()=>api<Page<TrainingExecution>>('/my-club/training-executions?limit=7')});
 if(plan.isLoading||players.isLoading||catalog.isLoading||staff.isLoading||history.isLoading)return <Loading/>;
 if(plan.error||players.error||catalog.error||staff.error||history.error)return <ErrorBox error={plan.error||players.error||catalog.error||staff.error||history.error}/>;
 return <WeeklyEditor key={plan.data!.version} initial={plan.data!} players={players.data!.items} catalog={catalog.data!.items} staff={staff.data!} club={club} history={history.data?.items??[]} category={category} onCategoryChange={setCategory}/>;
}
function WeeklyEditor({initial,players,catalog,staff,club,history,category,onCategoryChange}:{initial:Training;players:Player[];catalog:TrainingType[];staff:Staff;club:Club;history:TrainingExecution[];category:Player['category'];onCategoryChange:(c:Player['category'])=>void}){
 const [weekly,setWeekly]=useState<TrainingWeek>(()=>structuredClone(initial.weekly!));
 const [filter,setFilter]=useState('all'),[search,setSearch]=useState('');
 const dirty=!initial.weeklyConfigured||JSON.stringify(weekly)!==JSON.stringify(initial.weekly);
 useDayAdvanceBlock(dirty?'Guarda la planificación de entrenamiento antes de avanzar.':null);
 const labels=Object.fromEntries(catalog.map(t=>[t.id,t.name]));
 const themes=initial.themes??[];
 const members=players.filter(p=>p.category===category);
 const academyCoach=staff.coaches.find(c=>c.role==='academy');
 const recent=history.filter(e=>e.day>=club.day-6&&e.day<=club.day);
 const fromDate=new Date(club.date+'T12:00:00');fromDate.setDate(fromDate.getDate()-6);
 const period=`${fromDate.toLocaleDateString('es-ES')} – ${new Date(club.date+'T12:00:00').toLocaleDateString('es-ES')}`;
 const improved=trainingImprovements(history,members,club.day);
 const shown=improved.filter(({player:p})=>(filter==='all'||p.positionGroup===filter)&&p.name.toLocaleLowerCase().includes(search.toLocaleLowerCase()));
 function changeDay(day:number,patch:Partial<WeeklyDay>){setWeekly({...weekly,[category]:weekly[category].map(d=>d.day===day?{...d,...patch}:d)});}
 function propose(){setWeekly({...weekly,[category]:weeklyProposal(weekly[category],themes)});}
 return <><Heading eyebrow="DESARROLLO DE LA PLANTILLA" title="Cada jugador, su camino."/>
 <div className="competition-tabs" role="tablist" aria-label="Plantilla de entrenamiento">{(['senior','academy'] as const).map(c=><button key={c} id={`training-${c}-tab`} role="tab" aria-selected={category===c} aria-controls="training-panel" onClick={()=>{onCategoryChange(c);setSearch('');setFilter('all');}}>{c==='senior'?'Primer equipo':'Cantera'} · {players.filter(p=>p.category===c).length}</button>)}</div>
 <div role="tabpanel" id="training-panel" aria-labelledby={`training-${category}-tab`}>
 <div className="training-summary"><span><CalendarDays size={18}/>Semana recurrente · lunes a domingo</span><Link to="/staff">Cuerpo técnico <ArrowRight size={15}/></Link></div>
 <section className="card weekly-planner"><div className="card-top"><h3>Planifica la semana</h3><span className="tiny-tag">{dirty?'BORRADOR':'PLAN GUARDADO'}</span></div>
 <div className="weekly-days" role="group" aria-label={`Plan semanal de ${category==='senior'?'primer equipo':'cantera'}`}><div className="weekly-header"><span>Día</span><span>Enfoque</span><span>Delanteros</span><span>Tres cuartos</span></div>{weekly[category].map(d=>{const t=themes.find(t=>t.id===d.theme)!;return <div className={`weekly-day ${d.theme==='rest'?'rest':''}`} key={d.day}><strong>{dayNames[d.day-1]}</strong><select aria-label={`${dayNames[d.day-1]} · ${category==='senior'?'Primer equipo':'Cantera'}`} value={d.theme} onChange={e=>changeDay(d.day,{theme:e.target.value,forwards:undefined,backs:undefined})}>{themes.map(t=><option value={t.id} key={t.id}>{t.name}</option>)}</select>{(['forwards','backs'] as const).map(line=><label className="weekly-drill" key={line}><small>{line==='forwards'?'Delanteros':'Tres cuartos'}</small><select aria-label={`${dayNames[d.day-1]} · ${line==='forwards'?'Delanteros':'Tres cuartos'} · ${category==='senior'?'Primer equipo':'Cantera'}`} value={d[line]??t[line].split(',')[d.day-1]} onChange={e=>changeDay(d.day,{[line]:e.target.value})} disabled={d.theme==='rest'}>{drillOptions(t,line).map(id=><option key={id} value={id}>{labels[id]??id}</option>)}</select></label>)}</div>;})}</div>
 <p className="muted small">Se repite cada semana. El cuerpo técnico adapta la intensidad y prioriza la recuperación por cansancio, baja o partido cercano.</p>
 <div className="weekly-save"><span className="muted small">{category==='academy'?`Responsable: ${academyCoach?.name??'Entrenador de cantera'} · Calidad ${academyCoach?.quality??25}/100`:'Responsables: especialistas del primer equipo'}{!initial.weeklyConfigured&&' · Guarda para activar el plan semanal.'}</span><div><button className="button secondary" onClick={propose}><Shuffle size={15}/>Solicitar planificación</button>{dirty&&initial.weeklyConfigured&&<button className="button secondary" onClick={()=>setWeekly(structuredClone(initial.weekly!))}><RotateCcw size={15}/>Descartar cambios</button>}<Action path="/my-club/training-plan" method="PUT" body={{version:initial.version,mode:'weekly',weekly}} disabled={!dirty} className="dark">Guardar planificación <Check size={16}/></Action></div></div>
 </section>
 <section className="card training-selection"><div className="card-top"><h3 title={period}>Mejoras de los últimos 7 días</h3><span className="pill">{improved.length} JUGADORES</span></div>
 {!recent.length?<p className="empty">No se han realizado entrenamientos en los últimos siete días.</p>:!improved.length?<p className="empty">No hubo mejoras de características en esta categoría durante los últimos siete días.</p>:<><div className="training-filters"><input aria-label="Buscar jugador con mejoras" placeholder="Buscar jugador…" value={search} onChange={e=>setSearch(e.target.value)}/><select aria-label="Filtrar jugadores con mejoras" value={filter} onChange={e=>setFilter(e.target.value)}><option value="all">Todos en esta pestaña</option><option value="forwards">Delanteros</option><option value="backs">Tres cuartos</option></select></div>
 <div className="table-wrap"><table className="player-list-table training-improvements"><thead><tr><th>Jugador</th><th>Posición</th><th>Características mejoradas</th></tr></thead><tbody>{shown.map(({player:p,attributes})=><tr key={p.id}><td><Link className="player-name" title={p.name} to={`/jugadores/${p.id}`}>{p.name}</Link></td><td>{p.positionName}</td><td className="training-improved-attributes">{attributes.map(id=>labels[id]??id).join(' · ')}</td></tr>)}</tbody></table></div>{!shown.length&&<p className="empty">No hay jugadores con estos filtros.</p>}</>}
 </section>
 </div></>;
}
