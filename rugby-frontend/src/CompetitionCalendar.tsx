import {useState} from 'react';
import {useQuery} from '@tanstack/react-query';
import {api} from './api';
import {ErrorBox,Loading} from './components';
import {FixtureCard} from './CompetitionFixtures';
import type {Club,Competition,CupCompetition,Fixture} from './types';
const stageNames:Record<string,string>={regular:'Liga regular','cup-group':'Fase de grupos',quarterfinal:'Cuartos de final',semifinal:'Semifinales',final:'Final'};
export default function CompetitionCalendar({id,club}:{id:string;club:Club}){
 const q=useQuery({queryKey:['competition',id],queryFn:()=>api<Competition|CupCompetition>(`/competitions/${id}`),refetchInterval:15000});
 const [selected,setSelected]=useState(''),[ownOnly,setOwnOnly]=useState(false);
 if(q.isLoading)return <Loading/>;if(q.error)return <ErrorBox error={q.error}/>;
 const c=q.data!,fixtures=[...c.regularFixtures,...('quarterfinals' in c?c.quarterfinals:[]),...c.semifinals,...(c.final?[c.final]:[])].sort((a,b)=>a.day-b.day||a.id.localeCompare(b.id));
 const names=Object.fromEntries(c.standings.map(r=>[r.clubId,r.shortName||r.name]));
 const key=(f:Fixture)=>`${f.stage}-${f.round??0}`;
 const groups=[...new Map(fixtures.map(f=>[key(f),`${stageNames[f.stage??'regular']??f.stage}${['regular','cup-group'].includes(f.stage??'regular')?` · Jornada ${f.round}`:''}`])).entries()];
 const upcoming=fixtures.find(f=>f.status!=='finished'&&(f.homeId===club.id||f.awayId===club.id))??fixtures.find(f=>f.status!=='finished')??fixtures.at(-1);
 const current=selected||(upcoming?key(upcoming):'all'),matches=fixtures.filter(f=>(current==='all'||key(f)===current)&&(!ownOnly||f.homeId===club.id||f.awayId===club.id));
 const dates=[...new Set(matches.map(f=>f.date))];
 return <section className="card competition-round"><div className="card-top"><h3>Calendario de partidos</h3><label>Fase / jornada<select aria-label="Fase o jornada" value={current} onChange={e=>setSelected(e.target.value)}><option value="all">Todos los partidos</option>{groups.map(([value,label])=><option key={value} value={value}>{label}</option>)}</select></label></div><label className="competition-own-filter"><input type="checkbox" checked={ownOnly} onChange={e=>setOwnOnly(e.target.checked)}/>Solo mi club</label>{dates.map(date=><section key={date} className="competition-calendar-day"><h4>{new Date(`${date}T12:00:00`).toLocaleDateString('es-ES',{weekday:'long',day:'numeric',month:'long',year:'numeric'})}</h4><div className="competition-fixtures">{matches.filter(f=>f.date===date).map(f=><div key={f.id}>{current==='all'&&<small className="tiny-tag">{stageNames[f.stage??'regular']}{f.round&&['regular','cup-group'].includes(f.stage??'regular')?` · Jornada ${f.round}`:''}</small>}<FixtureCard f={f} club={club} names={names}/></div>)}</div></section>)}{!matches.length&&<p className="empty">No hay partidos con estos filtros. Los cruces pendientes aparecerán cuando se clasifiquen los equipos.</p>}</section>;
}
