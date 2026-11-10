import InjuryStatus,{InjuryMark} from './InjuryStatus';
import {useRef,useState} from 'react';
import {Link} from 'react-router-dom';
import {useQuery} from '@tanstack/react-query';
import {ArrowRight,Check,Plus,RotateCcw,Shuffle,Trash2,Users} from 'lucide-react';
import {api} from './api';
import {Action,Energy,ErrorBox,Heading,Loading,TrendArrow} from './components';
import type {Club,Page,Player,Staff,Training,TrainingExecution,TrainingGroup,TrainingSuggestion,TrainingType} from './types';

export default function TrainingView({club}:{club:Club}){
 const [category,setCategory]=useState<Player['category']>('senior');
 const plan=useQuery({queryKey:['training'],queryFn:()=>api<Training>('/my-club/training-plan')});
 const players=useQuery({queryKey:['players'],queryFn:()=>api<Page<Player>>('/my-club/players')});
 const catalog=useQuery({queryKey:['training-types'],queryFn:()=>api<{items:TrainingType[]}>('/training-types')});
 const staff=useQuery({queryKey:['staff'],queryFn:()=>api<Staff>('/my-club/staff')});
 const history=useQuery({queryKey:['training-history'],queryFn:()=>api<Page<TrainingExecution>>('/my-club/training-executions?limit=5')});
 if(plan.isLoading||players.isLoading||catalog.isLoading||staff.isLoading)return <Loading/>;
 if(plan.error||players.error||catalog.error||staff.error)return <ErrorBox error={plan.error||players.error||catalog.error||staff.error}/>;
 return <TrainingEditor category={category} onCategoryChange={setCategory} key={plan.data!.version} initial={plan.data!} players={players.data!.items} catalog={catalog.data!.items} staff={staff.data!} club={club} history={history.data?.items??[]}/>;
}
function TrainingEditor({initial,players,catalog,staff,club,history,category,onCategoryChange}:{category:Player['category'];onCategoryChange:(c:Player['category'])=>void;initial:Training;players:Player[];catalog:TrainingType[];staff:Staff;club:Club;history:TrainingExecution[]}){
 const [groups,setGroups]=useState(initial.groups),[selected,setSelected]=useState<string[]>([]),[focus,setFocus]=useState('handling'),[intensity,setIntensity]=useState<TrainingGroup['intensity']>('normal'),[name,setName]=useState(''),[filter,setFilter]=useState('all'),[search,setSearch]=useState(''),[editing,setEditing]=useState<string|null>(null);
 const categoryIds=new Set(players.filter(p=>p.category===category).map(p=>p.id));
 const visibleGroups=groups.map(g=>({...g,playerIds:g.playerIds.filter(id=>categoryIds.has(id))})).filter(g=>g.playerIds.length);
 function changeCategory(c:Player['category']){onCategoryChange(c);setSelected([]);setEditing(null);setName('');setSearch('');setFilter('all');setSuggestion(null);}
 const dirty=JSON.stringify(groups)!==JSON.stringify(initial.groups);
 const editorRef=useRef<HTMLElement>(null);
 const nextVariant=useRef(0);
 const [suggestion,setSuggestion]=useState<TrainingSuggestion|null>(null),[suggesting,setSuggesting]=useState(false),[suggestionError,setSuggestionError]=useState<unknown>(null);
 async function automatic(){
  setSuggesting(true);setSuggestionError(null);
  try {
   const proposal=await api<TrainingSuggestion>(`/my-club/training-suggestion?variant=${nextVariant.current}`);
   nextVariant.current=(nextVariant.current+1)%1000001;
   const other=groups.map(g=>({...g,playerIds:g.playerIds.filter(id=>!categoryIds.has(id))})).filter(g=>g.playerIds.length);
   const own=proposal.groups.map(g=>({...g,id:`${category}-${g.id}`,playerIds:g.playerIds.filter(id=>categoryIds.has(id))})).filter(g=>g.playerIds.length);
   setGroups([...other,...own]);setSuggestion({...proposal,playerCount:own.reduce((n,g)=>n+g.playerIds.length,0),recoveryCount:own.filter(g=>g.focus==='recovery').reduce((n,g)=>n+g.playerIds.length,0)});setSelected([]);setEditing(null);setName('');
  } catch(error){setSuggestionError(error);} finally {setSuggesting(false);}
 }
 const labels=Object.fromEntries(catalog.map(t=>[t.id,t.name]));
 const assignments=new Map(groups.flatMap(g=>g.playerIds.map(id=>[id,g] as const)));
 const displayed=[...players].sort((a,b)=>a.position-b.position||a.name.localeCompare(b.name)).filter(p=>p.category===category&&(filter==='all'||(filter==='unassigned'?!assignments.has(p.id):filter==='academy'?p.category==='academy':p.positionGroup===filter))&&p.name.toLocaleLowerCase().includes(search.toLocaleLowerCase()));
 const selectedAcademy=players.filter(p=>selected.includes(p.id)&&p.category==='academy').length,academyOnly=selected.length>0&&selectedAcademy===selected.length;
 const trainingType=catalog.find(t=>t.id===focus),responsible=category==='academy'?'academy':trainingType?.coachRole,coach=staff.coaches.find(c=>c.role===responsible),role=staff.roles.find(r=>r.id===responsible),academyCoach=staff.coaches.find(c=>c.role==='academy');
 function assign(){
  if(!selected.length)return;
  const remaining=groups.map(g=>({...g,playerIds:g.playerIds.filter(pid=>!selected.includes(pid)&&(g.id!==editing||!categoryIds.has(pid)))})).filter(g=>g.playerIds.length);
  const id=editing&&!remaining.some(g=>g.id===editing)?editing:crypto.randomUUID();
  setGroups([...remaining,{id,name:name.trim()||labels[focus],focus,intensity,playerIds:[...selected]}]);
  setSelected([]);setEditing(null);setName('');setSuggestion(null);
 }
 function edit(g:TrainingGroup){setEditing(g.id);setSelected(g.playerIds);setFocus(g.focus);setIntensity(g.intensity);setName(g.name);editorRef.current?.scrollIntoView({block:'start'});}
 const last=history[0];
 return <><Heading eyebrow="DESARROLLO DE LA PLANTILLA" title="Cada jugador, su camino." action={<Action path="/my-club/advance-day" body={{version:club.version}} disabled={dirty||selected.length>0||suggesting} className="dark">Avanzar día <ArrowRight size={16}/></Action>}/>
 <div className="competition-tabs" role="tablist" aria-label="Plantilla de entrenamiento"><button id="training-senior-tab" role="tab" aria-selected={category==='senior'} aria-controls="training-panel" onClick={()=>changeCategory('senior')}>Primer equipo · {players.filter(p=>p.category==='senior').length}</button><button id="training-academy-tab" role="tab" aria-selected={category==='academy'} aria-controls="training-panel" onClick={()=>changeCategory('academy')}>Cantera · {players.filter(p=>p.category==='academy').length}</button></div>
 <div role="tabpanel" id="training-panel" aria-labelledby={category==='senior'?'training-senior-tab':'training-academy-tab'}>
 <div className="training-summary"><span><Users size={18}/><b>{[...assignments.keys()].filter(id=>categoryIds.has(id)).length}</b> jugadores asignados</span><span><b>{visibleGroups.length}</b> grupos</span><Link to="/staff">Cuerpo técnico <ArrowRight size={15}/></Link></div>
 <div className="group-training-layout"><section className="card training-selection"><div className="card-top"><h3>1. Selecciona jugadores</h3><span className="pill">{selected.length} SELECCIONADOS</span></div>
  <div className="training-filters"><input aria-label="Buscar jugador para entrenar" placeholder="Buscar jugador…" value={search} onChange={e=>setSearch(e.target.value)}/><select aria-label="Filtrar jugadores para entrenar" value={filter} onChange={e=>setFilter(e.target.value)}><option value="all">Todos en esta pestaña</option><option value="unassigned">Sin entrenamiento</option><option value="forwards">Delanteros</option><option value="backs">Tres cuartos</option></select></div>
  <div className="selection-actions"><button onClick={()=>setSelected(Array.from(new Set([...selected,...displayed.map(p=>p.id)])))}>Seleccionar visibles</button><button onClick={()=>setSelected([])}>Limpiar selección</button></div>
  <div className="training-player-list"><div className="training-player-header"><span/><span>Jugador</span><span>Situación</span><span>Energía</span><span>Promedio</span><span>Potencial</span></div>{displayed.map(p=>{const g=assignments.get(p.id);return <label key={p.id} className={selected.includes(p.id)?'selected':''}><input type="checkbox" aria-label={`Entrenar a ${p.name}`} checked={selected.includes(p.id)} onChange={e=>setSelected(e.target.checked?[...selected,p.id]:selected.filter(id=>id!==p.id))}/><div><strong>{p.name}</strong><small>{p.age} años · {p.positionName}</small>{p.injury&&<InjuryStatus player={p}/>}<span className="training-assignment">{g?`${g.name} · ${labels[g.focus]}`:'Recuperación · Sin grupo'}</span></div><span className="training-situation"><InjuryMark player={p}/></span><Energy value={p.energy}/><span className="training-rating" aria-label={`Promedio de ${p.name}`}>{Math.round(p.average)}</span><span className="training-rating" aria-label={`Potencial de ${p.name} al ${p.potentialDate}`} title={`Previsión al ${p.potentialDate} con el plan guardado`}>{Math.round(p.potential)} <TrendArrow trend={p.potentialTrend}/></span></label>})}{!displayed.length&&<p className="empty">No hay jugadores con estos filtros.</p>}</div>
 </section><div><section ref={editorRef} className="card training-assignment-card"><h3>2. Asigna el entrenamiento</h3><label>Nombre del grupo<input value={name} maxLength={60} onChange={e=>setName(e.target.value)} placeholder="Ej. Melé del primer equipo"/></label><label>Tipo de entrenamiento<select aria-label="Tipo de entrenamiento del grupo" value={focus} onChange={e=>setFocus(e.target.value)}>{catalog.map(t=><option key={t.id} value={t.id}>{t.name}</option>)}</select></label><label>Intensidad<select value={intensity} onChange={e=>setIntensity(e.target.value as TrainingGroup['intensity'])}><option value="low">Suave</option><option value="normal">Normal</option><option value="high">Alta</option></select></label>
  <div className="training-coach"><span>Especialista responsable</span><strong>{coach?.name??'Apoyo del club'}</strong><small>{role?.name} · Calidad {coach?.quality??25}/100</small>{selectedAcademy>0&&!academyOnly&&<small>Cantera: {academyCoach?.name} · Calidad {academyCoach?.quality??25}/100</small>}</div>
  
  <button className="button orange full" disabled={!selected.length||suggesting} onClick={assign}><Plus size={16}/>{editing?'Actualizar grupo':'Asignar al grupo'} · {selected.length} jugadores</button>
  {editing&&<button className="text-button" onClick={()=>{setEditing(null);setSelected([]);setName('');}}>Cancelar edición del grupo</button>}
 </section><section className="card"><h3>3. Guarda tu planificación</h3><p className="muted small">{dirty?'Cambios sin guardar.':'Plan guardado.'}</p><div className="training-planning-actions"><button className="button secondary" disabled={suggesting} onClick={automatic} title={`Generar otra propuesta para ${category==='academy'?'la cantera':'el primer equipo'}`}><Shuffle size={16}/>{suggesting?'Preparando…':'Automático'}</button><Action path="/my-club/training-plan" method="PUT" body={{version:initial.version,groups}} disabled={!dirty||suggesting} className="dark full">Guardar planificación <Check size={16}/></Action></div>  {suggestion&&<p className="notice" role="status">Propuesta {suggestion.variant+1}: {suggestion.playerCount} jugadores, {suggestion.recoveryCount} en recuperación. Pendiente de guardar.</p>}{!!suggestionError&&<ErrorBox error={suggestionError}/>}{dirty&&<button className="text-button" onClick={()=>{setGroups(initial.groups);setSelected([]);setEditing(null);setSuggestion(null);}}><RotateCcw size={13}/> Descartar cambios</button>}</section></div></div>
 <section className="card"><div className="card-top"><h3>Grupos de trabajo</h3><span className="tiny-tag">{dirty?'BORRADOR':'PLAN GUARDADO'}</span></div><div className="training-groups">{visibleGroups.map(g=><article key={g.id}><div><h4>{g.name}</h4><p>{labels[g.focus]} · {({low:'Suave',normal:'Normal',high:'Alta'})[g.intensity]}</p><span>{g.playerIds.length} jugadores</span></div><div className="group-members">{g.playerIds.map(id=>players.find(p=>p.id===id)?.name??id).join(' · ')}</div><div className="group-actions"><button className="button secondary" onClick={()=>edit(g)}>Editar grupo</button><button className="icon-button" aria-label={`Eliminar grupo ${g.name}`} onClick={()=>{setGroups(groups.map(x=>x.id===g.id?{...x,playerIds:x.playerIds.filter(id=>!categoryIds.has(id))}:x).filter(x=>x.playerIds.length));setSuggestion(null);}}><Trash2 size={17}/></button></div></article>)}{!visibleGroups.length&&<p className="empty">No hay grupos. Selecciona jugadores y asigna su entrenamiento.</p>}</div></section>
 {last&&<section className="card"><div className="card-top"><h3>Última sesión · Día {last.day}</h3><span className="pill">APLICADA UNA VEZ</span></div><p className="muted small">{last.results.filter(r=>categoryIds.has(r.playerId)&&r.attributeGain>0).length} jugadores acumularon progreso. {last.results.filter(r=>categoryIds.has(r.playerId)&&(r.changes??[]).some(c=>c.reason==='age')).length} registraron ajustes por edad.</p><div className="session-results">{last.results.filter(r=>categoryIds.has(r.playerId)&&(r.attributeGain>0||(r.changes??[]).length)).map(r=><div key={r.playerId}><strong>{players.find(p=>p.id===r.playerId)?.name??r.playerId}</strong><span>{labels[r.focus??'']??'Desarrollo'} · {r.averageBefore!==undefined&&r.averageAfter!==undefined?`Promedio ${Math.round(r.averageBefore)} → ${Math.round(r.averageAfter)}`:r.attributeGain>0?'Progreso acumulado':'Ajuste por edad'}</span></div>)}</div></section>}
 </div></>;
}
