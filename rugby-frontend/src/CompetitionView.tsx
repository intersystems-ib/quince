import CupView from './CupView';
import {EmptyTie,FixtureCard} from './CompetitionFixtures';
import {useState} from 'react';
import {useQuery} from '@tanstack/react-query';
import {Trophy} from 'lucide-react';
import {api} from './api';
import {ErrorBox,Heading,Loading} from './components';
import ClubCrest from './ClubCrest';
import type {Club,Competition,Fixture,Page} from './types';

const dateLabel=(date?:string)=>date?new Date(`${date}T12:00:00`).toLocaleDateString('es-ES',{weekday:'short',day:'numeric',month:'short',year:'numeric'}):'';
export default function CompetitionView({club}:{club:Club}){
 const leagues=useQuery({queryKey:['competitions'],queryFn:()=>api<Page<Competition>>('/competitions?limit=100')});
 const [choice,setChoice]=useState('');
 if(leagues.isLoading)return <Loading/>;
 if(leagues.error)return <ErrorBox error={leagues.error}/>;
 const items=[...leagues.data!.items].sort((a,b)=>b.year-a.year||a.divisionId-b.divisionId),id=choice||items.find(c=>c.divisionId===club.competitionId)?.id||items[0]?.id;
 return <><Heading eyebrow="TEMPORADA DE RUGBY" title="Competición"/><div className="competition-toolbar"><label>Competición y temporada<select aria-label="Competición y temporada" value={id??''} onChange={e=>setChoice(e.target.value)}>{items.map(c=><option key={c.id} value={c.id}>{c.name} · {c.season}</option>)}</select></label><span className="pill">{items.find(c=>c.id===id)?.type==='cup'?'20 EQUIPOS · COPA DEL REY':'10 EQUIPOS · 18 JORNADAS'}</span></div>{id?items.find(c=>c.id===id)?.type==='cup'?<CupView key={id} id={id} club={club}/>:<League key={id} id={id} club={club}/>:<p className="empty">No hay una temporada disponible.</p>}</>;
}
function League({id,club}:{id:string;club:Club}){
 const q=useQuery({queryKey:['competition',id],queryFn:()=>api<Competition>(`/competitions/${id}`),refetchInterval:15000});
 const [tab,setTab]=useState('regular'),[round,setRound]=useState<number|null>(null),[ownOnly,setOwnOnly]=useState(false);
 if(q.isLoading)return <Loading/>;
 if(q.error)return <ErrorBox error={q.error}/>;
 const c=q.data!,names=Object.fromEntries(c.standings.map(r=>[r.clubId,r.name]));
 const currentRound=round??c.regularFixtures.find(f=>f.status!=='finished'&&(f.homeId===club.id||f.awayId===club.id))?.round??c.regularFixtures.find(f=>f.status!=='finished')?.round??18;
 const matches=c.regularFixtures.filter(f=>f.round===currentRound&&(!ownOnly||f.homeId===club.id||f.awayId===club.id));
 return <><div className="competition-summary"><span>{dateLabel(c.startDate)} — {dateLabel(c.endDate)}</span><b>{c.regularFinished}/90 partidos de liga</b><span className="pill">{({regular:'LIGA REGULAR',playoffs:'FASE FINAL',finished:'TEMPORADA FINALIZADA'} as Record<string,string>)[c.phase]}</span></div>
 {c.seasonStartDate&&<p className="notice">Inicio de temporada: {dateLabel(c.seasonStartDate)}{c.closedDate?` · Cerrada: ${dateLabel(c.closedDate)}`:''}</p>}

 <div className="competition-tabs" role="tablist" aria-label="Fases de competición"><button id="regular-tab" role="tab" aria-selected={tab==='regular'} aria-controls="regular-panel" onClick={()=>setTab('regular')}>Liga regular</button><button id="playoffs-tab" role="tab" aria-selected={tab==='playoffs'} aria-controls="playoffs-panel" onClick={()=>setTab('playoffs')}>Fase final</button></div>
 {tab==='regular'?<section role="tabpanel" id="regular-panel" aria-labelledby="regular-tab"><div className="card table-wrap competition-table"><table aria-label={`Clasificación de ${c.name}`}><thead><tr><th>#</th><th>Equipo</th><th title="Partidos jugados">PJ</th><th title="Ganados">G</th><th title="Empatados">E</th><th title="Perdidos">P</th><th title="Tantos del marcador a favor">PF</th><th title="Puntos en contra">PC</th><th title="Diferencia de puntos">DIF</th><th title="Bonus ofensivo: ganar con al menos tres ensayos más que el rival">BO</th><th title="Bonus defensivo: perder por siete puntos o menos">BD</th><th title="Puntos de clasificación: 4 por victoria, 2 por empate, más BO y BD">PTS</th></tr></thead><tbody>{c.standings.map(r=><tr key={r.clubId} className={`${r.rank<=4?'playoff-place':''} ${c.divisionId===416&&r.rank===10?'relegation-place':''} ${r.clubId===club.id?'managed-club':''}`}><td title={c.divisionId===416&&r.rank===10?'Plaza de descenso a División Élite':undefined}>{r.rank}</td><td><div className="standing-club"><ClubCrest clubId={r.clubId} name={r.name}/><span>{r.name}</span>{r.clubId===club.id&&<span className="tiny-tag">TU CLUB</span>}</div></td><td>{r.played}</td><td>{r.wins}</td><td>{r.draws}</td><td>{r.losses}</td><td>{r.pointsFor}</td><td>{r.pointsAgainst}</td><td>{r.difference>0?'+':''}{r.difference}</td><td>{r.bonusOffensive}</td><td>{r.bonusDefensive}</td><td><b>{r.points}</b></td></tr>)}</tbody></table></div>
 <section className="card competition-round"><div className="card-top"><h3>Partidos de liga</h3><select aria-label="Jornada de liga" value={currentRound} onChange={e=>setRound(Number(e.target.value))}>{Array.from({length:18},(_,i)=><option key={i} value={i+1}>Jornada {i+1}</option>)}</select></div><label className="competition-own-filter"><input type="checkbox" checked={ownOnly} onChange={e=>setOwnOnly(e.target.checked)}/>Solo mi club</label><div className="competition-fixtures">{matches.map(f=><FixtureCard key={f.id} f={f} club={club} names={names}/>)}{!matches.length&&<p className="empty">Tu club no participa en esta jornada de esta división.</p>}</div></section></section>:<section role="tabpanel" id="playoffs-panel" aria-labelledby="playoffs-tab">
 {c.championId&&<div className="competition-champion"><Trophy size={26}/><ClubCrest clubId={c.championId} name={names[c.championId]}/><div><small>CAMPEÓN{c.divisionId===417?' · ASCENSO A HONOR':''} · {c.season}</small><h3>{names[c.championId]}</h3></div></div>}
 <div className="playoff-bracket"><section><h3>Semifinales</h3>{[1,2].map(slot=>{const f=c.semifinals.find(f=>f.slot===slot);return <div key={slot} className="playoff-slot"><span className="tiny-tag">SEMIFINAL {slot} · {slot===1?'1.º — 4.º':'2.º — 3.º'}</span>{f?<FixtureCard f={f} club={club} names={names}/>:<EmptyTie date={c.semifinalDates[slot-1]}/>}</div>})}</section><section className="playoff-final"><h3>Final</h3>{c.final?<FixtureCard f={c.final} club={club} names={names}/>:<EmptyTie date={c.finalDate}/>}</section></div>
 </section>}</>;
}
