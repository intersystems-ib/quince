import VenueInfo from './VenueInfo';
import MatchTicketing from './MatchTicketing';
import {useState} from 'react';
import {useQuery} from '@tanstack/react-query';
import {Link} from 'react-router-dom';
import {ArrowRight} from 'lucide-react';
import {api,getClubId} from './api';
import ClubCrest from './ClubCrest';
import {Action,Energy,ErrorBox,Heading,Loading} from './components';
import type {Match,MatchComparison,ComparisonGroup} from './types';

export default function MatchPreview({match:m}:{match:Match}){
 const [group,setGroup]=useState<ComparisonGroup>('all');
 const q=useQuery({queryKey:['match-comparison',m.id],queryFn:()=>api<MatchComparison>(`/matches/${m.id}/comparison`)});
 const comparison=q.data,home=comparison?.home.groups[group],away=comparison?.away.groups[group];
 return <><Heading eyebrow="PREVIA DEL PARTIDO" title="Comparativa de equipos." description={`${m.homeName} frente a ${m.awayName}`} action={<Link className="button secondary" to="/competicion">Volver a Competición</Link>}/>
 <VenueInfo venue={m.venue}/><section className="card prematch-actions">{(!m.lineupId||m.lineupId===`${getClubId()}-default`)&&<Link className="button secondary" to="/alineacion">Editar mi alineación</Link>}<Action path={`/matches/${m.id}/start`} className="orange" disabled={!comparison?.ready||q.isFetching}>Iniciar partido <ArrowRight size={16}/></Action></section>
 <MatchTicketing key={`${m.id}-${m.ticketPrice}`} match={m}/>
 {q.isLoading?<Loading/>:q.error?<ErrorBox error={q.error}/>:comparison&&home&&away?<>
 <div className="competition-tabs" role="tablist" aria-label="Jugadores de la comparativa">{([['all','XV titular'],['forwards','Delanteros'],['backs','Tres cuartos']] as const).map(([id,label])=><button id={`comparison-${id}`} key={id} role="tab" aria-selected={group===id} aria-controls="comparison-panel" onClick={()=>setGroup(id)}>{label}</button>)}</div>
 <div id="comparison-panel" role="tabpanel" aria-labelledby={`comparison-${group}`}>
 <div className="prematch-lineups comparison-teams">{[{team:comparison.home,summary:home,venue:'Local'},{team:comparison.away,summary:away,venue:'Visitante'}].map(({team,summary,venue})=><section className="card prematch-team comparison-team" key={team.clubId}><header><ClubCrest clubId={team.clubId} name={team.name} className="prematch-crest"/><div><span className="eyebrow">{venue}</span><h2>{team.name}</h2><small>{summary.count} {group==='all'?'titulares':group==='forwards'?'delanteros':'tres cuartos'}</small></div></header><div className="comparison-team-stats"><div><small>Promedio</small><strong>{Math.round(summary.average)}</strong></div><div><small>Energía</small><Energy value={summary.energy}/></div><div><small>Moral</small><Energy value={summary.morale}/></div></div></section>)}</div>
 <section className="card table-wrap comparison-card"><table aria-label="Medias de características por equipo"><thead><tr><th>{m.homeName}</th><th>Característica</th><th>{m.awayName}</th></tr></thead><tbody>{comparison.attributes.map(attr=>{const h=home.attributes[attr.id]??0,a=away.attributes[attr.id]??0,higher=Math.round(h)>Math.round(a),lower=Math.round(a)>Math.round(h);return <tr key={attr.id}><td><div className="comparison-value home"><strong className={higher?'comparison-leading':''}>{Math.round(h)}</strong><span className="comparison-track"><i style={{width:`${Math.max(0,Math.min(100,h))}%`}}/></span></div></td><th scope="row">{attr.name}</th><td><div className="comparison-value away"><span className="comparison-track"><i style={{width:`${Math.max(0,Math.min(100,a))}%`}}/></span><strong className={lower?'comparison-leading':''}>{Math.round(a)}</strong></div></td></tr>})}</tbody></table></section>
 </div>{!comparison.ready&&<p role="alert" className="notice">Revisa las alineaciones antes de iniciar el partido.</p>}
 </>:null}
 </>;
}
