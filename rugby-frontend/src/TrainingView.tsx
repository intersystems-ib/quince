import {useDayAdvanceBlock} from './DayAdvanceControl';
import InjuryStatus,{InjuryMark} from './InjuryStatus';
import {useState} from 'react';
import {Link} from 'react-router-dom';
import {useQuery} from '@tanstack/react-query';
import {ArrowRight,Check,RotateCcw,CalendarDays} from 'lucide-react';
import {api} from './api';
import {Action,Energy,ErrorBox,Heading,Loading,TrendArrow} from './components';
import type {Club,Page,Player,Staff,Training,TrainingExecution,TrainingType,TrainingWeek} from './types';

const dayNames=['Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo'];
export default function TrainingView({club}:{club:Club}){
 const [category,setCategory]=useState<Player['category']>('senior');
 const plan=useQuery({queryKey:['training'],queryFn:()=>api<Training>('/my-club/training-plan')});
 const players=useQuery({queryKey:['players'],queryFn:()=>api<Page<Player>>('/my-club/players')});
 const catalog=useQuery({queryKey:['training-types'],queryFn:()=>api<{items:TrainingType[]}>('/training-types')});
 const staff=useQuery({queryKey:['staff'],queryFn:()=>api<Staff>('/my-club/staff')});
 const history=useQuery({queryKey:['training-history'],queryFn:()=>api<Page<TrainingExecution>>('/my-club/training-executions?limit=5')});
 if(plan.isLoading||players.isLoading||catalog.isLoading||staff.isLoading)return <Loading/>;
 if(plan.error||players.error||catalog.error||staff.error)return <ErrorBox error={plan.error||players.error||catalog.error||staff.error}/>;
 return <WeeklyEditor key={plan.data!.version} initial={plan.data!} players={players.data!.items} catalog={catalog.data!.items} staff={staff.data!} club={club} history={history.data?.items??[]} category={category} onCategoryChange={setCategory}/>;
}
function WeeklyEditor({initial,players,catalog,staff,club,history,category,onCategoryChange}:{initial:Training;players:Player[];catalog:TrainingType[];staff:Staff;club:Club;history:TrainingExecution[];category:Player['category'];onCategoryChange:(c:Player['category'])=>void}){
 const [weekly,setWeekly]=useState<TrainingWeek>(()=>structuredClone(initial.weekly!));
 const [filter,setFilter]=useState('all'),[search,setSearch]=useState('');
 const dirty=!initial.weeklyConfigured||JSON.stringify(weekly)!==JSON.stringify(initial.weekly);
 useDayAdvanceBlock(dirty?'Guarda la planificación de entrenamiento antes de avanzar.':null);
 const labels=Object.fromEntries(catalog.map(t=>[t.id,t.name]));
 const themes=initial.themes??[];
 const next=initial.nextGroups??initial.groups;
 const assignments=new Map(next.flatMap(g=>g.playerIds.map(id=>[id,g] as const)));
 const members=players.filter(p=>p.category===category);
 const shown=[...members].sort((a,b)=>a.position-b.position||a.name.localeCompare(b.name)).filter(p=>(filter==='all'||p.positionGroup===filter)&&p.name.toLocaleLowerCase().includes(search.toLocaleLowerCase()));
 const academyCoach=staff.coaches.find(c=>c.role==='academy');
 const last=history[0];
 const lastDate=new Date(club.date+'T12:00:00');
 if(last)lastDate.setDate(lastDate.getDate()+last.day-club.day);
 const ids=new Set(members.map(p=>p.id));
 function changeDay(day:number,theme:string){setWeekly({...weekly,[category]:weekly[category].map(d=>d.day===day?{...d,theme}:d)});}
 return <><Heading eyebrow="DESARROLLO DE LA PLANTILLA" title="Cada jugador, su camino."/>
 <div className="competition-tabs" role="tablist" aria-label="Plantilla de entrenamiento">{(['senior','academy'] as const).map(c=><button key={c} id={`training-${c}-tab`} role="tab" aria-selected={category===c} aria-controls="training-panel" onClick={()=>{onCategoryChange(c);setSearch('');setFilter('all');}}>{c==='senior'?'Primer equipo':'Cantera'} · {players.filter(p=>p.category===c).length}</button>)}</div>
 <div role="tabpanel" id="training-panel" aria-labelledby={`training-${category}-tab`}>
 <div className="training-summary"><span><CalendarDays size={18}/>Semana recurrente · lunes a domingo</span><Link to="/staff">Cuerpo técnico <ArrowRight size={15}/></Link></div>
 <section className="card weekly-planner"><div className="card-top"><h3>Planifica la semana</h3><span className="tiny-tag">{dirty?'BORRADOR':'PLAN GUARDADO'}</span></div>
 <div className="weekly-days" role="group" aria-label={`Plan semanal de ${category==='senior'?'primer equipo':'cantera'}`}><div className="weekly-header"><span>Día</span><span>Enfoque</span><span>Delanteros</span><span>Tres cuartos</span></div>{weekly[category].map(d=>{const t=themes.find(t=>t.id===d.theme);return <div className={`weekly-day ${d.theme==='rest'?'rest':''}`} key={d.day}><strong>{dayNames[d.day-1]}</strong><select aria-label={`${dayNames[d.day-1]} · ${category==='senior'?'Primer equipo':'Cantera'}`} value={d.theme} onChange={e=>changeDay(d.day,e.target.value)}>{themes.map(t=><option value={t.id} key={t.id}>{t.name}</option>)}</select><span><small>Delanteros</small>{labels[t?.forwards.split(',')[d.day-1]??'recovery']}</span><span><small>Tres cuartos</small>{labels[t?.backs.split(',')[d.day-1]??'recovery']}</span></div>;})}</div>
 <p className="muted small">Se repite cada semana. El cuerpo técnico adapta la intensidad y prioriza la recuperación por cansancio, baja o partido cercano.</p>
 <div className="weekly-save"><span className="muted small">{category==='academy'?`Responsable: ${academyCoach?.name??'Entrenador de cantera'} · Calidad ${academyCoach?.quality??25}/100`:'Responsables: especialistas del primer equipo'}{!initial.weeklyConfigured&&' · Guarda para activar el plan semanal.'}</span><div>{dirty&&initial.weeklyConfigured&&<button className="button secondary" onClick={()=>setWeekly(structuredClone(initial.weekly!))}><RotateCcw size={15}/>Descartar cambios</button>}<Action path="/my-club/training-plan" method="PUT" body={{version:initial.version,mode:'weekly',weekly}} disabled={!dirty} className="dark">Guardar planificación <Check size={16}/></Action></div></div>
 </section>
 <section className="card training-selection"><div className="card-top"><h3>Próxima sesión · {initial.nextDate&&new Date(initial.nextDate+'T12:00:00').toLocaleDateString('es-ES',{weekday:'long',day:'numeric',month:'long'})}</h3><span className="pill">{members.length} JUGADORES</span></div>{dirty&&<p className="muted small">Las sesiones y el potencial reflejan el plan guardado.</p>}
 <div className="training-filters"><input aria-label="Buscar jugador para entrenar" placeholder="Buscar jugador…" value={search} onChange={e=>setSearch(e.target.value)}/><select aria-label="Filtrar jugadores para entrenar" value={filter} onChange={e=>setFilter(e.target.value)}><option value="all">Todos en esta pestaña</option><option value="forwards">Delanteros</option><option value="backs">Tres cuartos</option></select></div>
 <div className="training-player-list weekly-player-list"><div className="training-player-header"><span>Jugador</span><span>Situación</span><span>Energía</span><span>Promedio</span><span>Potencial</span></div>{shown.map(p=>{const g=assignments.get(p.id);return <div className="weekly-player" key={p.id}><div><Link to={`/jugadores/${p.id}`}><strong>{p.name}</strong></Link><small>{p.age} años · {p.positionName}</small>{p.injury&&<InjuryStatus player={p}/>}<span className="training-assignment">{g?`${labels[g.focus]} · ${g.intensity==='low'?'Suave':g.intensity==='high'?'Alta':'Normal'}`:'Descanso y recuperación'}</span></div><span className="training-situation"><InjuryMark player={p}/></span><Energy value={p.energy}/><span className="training-rating" aria-label={`Promedio de ${p.name}`}>{Math.round(p.average)}</span><span className="training-rating" title={`Previsión al ${p.potentialDate} con el plan guardado`}>{Math.round(p.potential)} <TrendArrow trend={p.potentialTrend}/></span></div>;})}{!shown.length&&<p className="empty">No hay jugadores con estos filtros.</p>}</div></section>
 {last&&<section className="card"><div className="card-top"><h3>Última sesión · {lastDate.toLocaleDateString('es-ES',{day:'numeric',month:'long'})}</h3><span className="pill">APLICADA UNA VEZ</span></div><div className="session-results">{last.results.filter(r=>ids.has(r.playerId)).map(r=><div key={r.playerId}><strong>{players.find(p=>p.id===r.playerId)?.name??r.playerId}</strong><span>{labels[r.focus??'recovery']} · {r.attributeGain>0?'Progreso acumulado':r.focus==='recovery'?'Recuperación':(r.changes??[]).some(c=>c.reason==='age')?'Ajuste por edad':'Sesión completada'}</span></div>)}</div></section>}
 </div></>;
}
