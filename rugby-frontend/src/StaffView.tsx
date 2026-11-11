import {monthlySalary} from './salary';
import {useEffect,useState} from 'react';
import {useSearchParams} from 'react-router-dom';
import {useQuery} from '@tanstack/react-query';
import {BriefcaseBusiness,Coins,TrendingUp,UserCheck} from 'lucide-react';
import {api} from './api';
import {Action,ErrorBox,Heading,Loading,money} from './components';
import type {Coach,Page,Staff} from './types';

export default function StaffView(){
 const [params]=useSearchParams();
 const [roleId,setRoleId]=useState(params.get('role')||'head'),[page,setPage]=useState(0);
 const staff=useQuery({queryKey:['staff'],queryFn:()=>api<Staff>('/my-club/staff')});
 const market=useQuery({queryKey:['staff-market',roleId,page],queryFn:()=>api<Page<Coach>>(`/staff-market?role=${encodeURIComponent(roleId)}&offset=${page*12}&limit=12`)});
 useEffect(()=>{if(market.data&&page*12>=market.data.total&&page>0)setPage(Math.max(0,Math.ceil(market.data.total/12)-1));},[market.data?.total,page]);
 if(staff.isLoading||market.isLoading)return <Loading/>;
 if(staff.error||market.error)return <ErrorBox error={staff.error||market.error}/>;
 const data=staff.data!,role=data.roles.find(r=>r.id===roleId)??data.roles[0],current=data.coaches.find(c=>c.role===roleId);
 const candidates=[...market.data!.items].filter(c=>c.role===roleId).sort((a,b)=>b.quality-a.quality);
 return <><Heading eyebrow="LAS PERSONAS QUE HACEN CRECER AL EQUIPO" title="Un equipo detrás del equipo." description="Contrata especialistas y construye el cuerpo técnico que necesita tu club."/>
 <div className="staff-overview"><span><UserCheck size={19}/><strong>{data.coaches.length}</strong> especialistas contratados</span><span><Coins size={19}/>Salarios mensuales <strong>{money(data.monthlyWage??monthlySalary(data.weeklyWage))}</strong></span><span><TrendingUp size={19}/>La calidad acelera el desarrollo dentro del límite anual</span></div>
 <section className="card"><div className="card-top"><h3>Tu cuerpo técnico</h3><span className="pill">{data.roles.length} ESPECIALIDADES</span></div><div className="staff-role-grid">{data.roles.map(r=>{const coach=data.coaches.find(c=>c.role===r.id);return <button key={r.id} aria-pressed={roleId===r.id} className={`staff-role ${roleId===r.id?'active':''}`} onClick={()=>{setRoleId(r.id);setPage(0);}}><BriefcaseBusiness size={19}/><strong>{r.name}</strong><span>{coach?.name??'Sin contratar'}</span><b>Calidad {coach?.quality??25}/100</b><small>{coach?`${money((coach.monthlyWage??monthlySalary(coach.weeklyWage)))} / mes`:'Apoyo básico del club'}</small></button>})}</div></section>
 <Heading eyebrow="CONTRATACIÓN" title={role.name} description={`${role.englishName} · ${role.description}`}/>
 <div className="notice">Actual: <strong>{current?.name??'Sin especialista'}</strong>{current&&<> · Calidad {current.quality}/100 · {money((current.monthlyWage??monthlySalary(current.weeklyWage)))} por mes</>}. Una persona por especialidad. Nóminas al cierre de cada mes, con la parte proporcional de las incorporaciones.</div>
 <p className="muted">{market.data!.total} candidatos para esta especialidad</p>
 <div className="staff-candidates">{candidates.map(c=><article className="card candidate-card" key={c.id}><span className="pill">DISPONIBLE</span><h3>{c.name}</h3><p>{role.name}</p><div className="candidate-quality"><b>{c.quality}</b><span>/100<small>Calidad técnica</small></span></div><div className="candidate-details"><span>Eficacia formativa <strong>{Math.round(c.effectiveness*100)}%</strong></span><span>Salario mensual <strong>{money((c.monthlyWage??monthlySalary(c.weeklyWage)))}</strong></span><span>Variación del gasto <strong>{(c.monthlyWage??monthlySalary(c.weeklyWage))-(current?.monthlyWage??monthlySalary(current?.weeklyWage??0))>0?'+':''}{money((c.monthlyWage??monthlySalary(c.weeklyWage))-(current?.monthlyWage??monthlySalary(current?.weeklyWage??0)))} / mes</strong></span></div><Action path="/my-club/staff" body={{coachId:c.id,version:data.version}} className="dark full">{current?'Contratar y sustituir':'Contratar entrenador'}</Action></article>)}</div>
 {!candidates.length&&<p className="empty">No hay candidatos disponibles para esta especialidad.</p>}
 {market.data!.total>12&&<div className="toolbar"><button className="button secondary" disabled={!page} onClick={()=>setPage(page-1)}>Anterior</button><span>Página {page+1} de {Math.ceil(market.data!.total/12)}</span><button className="button secondary" disabled={(page+1)*12>=market.data!.total} onClick={()=>setPage(page+1)}>Siguiente</button></div>}
 </>;
}
