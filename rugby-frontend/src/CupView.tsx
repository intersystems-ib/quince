import {useState} from 'react';
import {useQuery} from '@tanstack/react-query';
import {Trophy} from 'lucide-react';
import {api} from './api';
import {ErrorBox,Loading} from './components';
import ClubCrest from './ClubCrest';
import {EmptyTie,FixtureCard} from './CompetitionFixtures';
import type {Club,CupCompetition,Fixture} from './types';

export default function CupView({id,club}:{id:string;club:Club}){
 const q=useQuery({queryKey:['competition',id],queryFn:()=>api<CupCompetition>(`/competitions/${id}`),refetchInterval:15000});
 const [tab,setTab]=useState('groups');
 if(q.isLoading)return <Loading/>;
 if(q.error)return <ErrorBox error={q.error}/>;
 const c=q.data!,names=Object.fromEntries(c.standings.map(r=>[r.clubId,r.name]));
 const tie=(fixtures:Fixture[],slots:number,date:string)=>Array.from({length:slots},(_,i)=>{const f=fixtures.find(x=>x.slot===i+1);return <div key={i} className="playoff-slot">{f?<FixtureCard f={f} club={club} names={names}/>:<EmptyTie date={date}/>}</div>});
 return <><div className="competition-summary"><span>{c.season}</span><b>{c.regularFinished}/18 partidos de grupos</b><span className="pill">{({groups:'FASE DE GRUPOS',quarterfinal:'CUARTOS',semifinal:'SEMIFINALES',final:'FINAL',finished:'COPA FINALIZADA'} as Record<string,string>)[c.phase]}</span></div>
 <section className="card cup-exempt"><h3>Clasificados directamente a cuartos</h3><div>{c.exemptTeamIds.map(cid=><span key={cid}><ClubCrest clubId={cid} name={names[cid]}/><strong>{names[cid]}</strong></span>)}</div></section>
 <div className="competition-tabs" role="tablist" aria-label="Fases de Copa"><button role="tab" aria-selected={tab==='groups'} onClick={()=>setTab('groups')}>Fase de grupos</button><button role="tab" aria-selected={tab==='knockout'} onClick={()=>setTab('knockout')}>Eliminatorias</button></div>
 {tab==='groups'?<div className="cup-groups">{c.groups.map(g=><section className="card" key={g.id}><h3>Grupo {g.id}</h3><div className="table-wrap"><table aria-label={`Clasificación del grupo ${g.id}`}><thead><tr><th>Equipo</th><th>PJ</th><th>G</th><th>E</th><th>P</th><th>DIF</th><th>BO</th><th>BD</th><th>PTS</th></tr></thead><tbody>{g.standings.map(r=><tr key={r.clubId} className={r.clubId===club.id?'managed-club':''}><td><div className="standing-club"><ClubCrest clubId={r.clubId} name={r.name}/><span>{r.name}</span>{c.qualifiedTeamIds.includes(r.clubId)&&<span className="tiny-tag">CLASIFICADO</span>}</div></td><td>{r.played}</td><td>{r.wins}</td><td>{r.draws}</td><td>{r.losses}</td><td>{r.difference}</td><td>{r.bonusOffensive}</td><td>{r.bonusDefensive}</td><td><b>{r.points}</b></td></tr>)}</tbody></table></div><div className="cup-group-fixtures">{c.regularFixtures.filter(f=>f.groupId===g.id).sort((a,b)=>(a.round??0)-(b.round??0)).map(f=><div key={f.id}><span className="tiny-tag">JORNADA {f.round}</span><FixtureCard f={f} club={club} names={names}/></div>)}</div></section>)}</div>:<>
 {c.championId&&<div className="competition-champion"><Trophy size={26}/><ClubCrest clubId={c.championId} name={names[c.championId]}/><div><small>CAMPEÓN DE COPA · {c.season}</small><h3>{names[c.championId]}</h3></div></div>}
 <div className="cup-bracket"><section><h3>Cuartos de final</h3>{tie(c.quarterfinals,4,c.quarterfinalDate)}</section><section><h3>Semifinales</h3>{tie(c.semifinals,2,c.semifinalDates[0])}</section><section><h3>Final</h3>{c.final?<FixtureCard f={c.final} club={club} names={names}/>:<EmptyTie date={c.finalDate}/>}</section></div></>}
 </>;
}
