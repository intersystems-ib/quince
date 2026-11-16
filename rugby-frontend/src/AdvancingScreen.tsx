import {useEffect,useRef} from 'react';
import type {ReactNode} from 'react';
import {useQuery} from '@tanstack/react-query';
import {getGameId} from './api';
import ClubCrest from './ClubCrest';
import type {Club,Fixture} from './types';
import {fixtureLabel} from './competitionLabels';
type RecentResults={items:(Fixture&{competitionName:string})[];clubs:{id:string;name:string}[]};

export function AdvanceBackground({running,children}:{running:boolean;children:ReactNode}){
 const previous=useRef(children);
 if(!running)previous.current=children;
 return previous.current;
}
type Scorer={playerId:string;name:string;tries:number;conversions:number;penalties:number};
function ScoringList({players}:{players:Scorer[]}){
 return <>{([['tries','Ensayos'],['conversions','Transformaciones'],['penalties','Penalties']] as const).map(([field,label])=>{
  const scorers=players.filter(p=>p[field]>0);
  return scorers.length?<div className="scorers-category" key={field}><h4>{label}</h4><p>{scorers.map(p=>`${p.name}${p[field]>1?` ×${p[field]}`:''}`).join(', ')}</p></div>:null;
 })}</>;
}
export default function AdvancingScreen({club}:{club:Club}){
 const screen=useRef<HTMLDivElement>(null),startDay=useRef(club.day);
 useEffect(()=>{screen.current?.focus();},[]);
 const results=useQuery({queryKey:['advancing-results',getGameId()],queryFn:async():Promise<RecentResults>=>({items:[],clubs:[]}),enabled:false,staleTime:Infinity});
 const finished=results.data?.items??[],index=finished.length?Math.max(0,club.day-startDay.current)%finished.length:0,selected=finished[index];
 const scorers=selected?.scorers;
 const names=Object.fromEntries(results.data?.clubs.map(c=>[c.id,c.name])??[]);
 return <div ref={screen} className="advancing-overlay" role="dialog" aria-modal="true" aria-label="Avance de la partida" tabIndex={-1}><section className="advancing-screen">
  <div className="advancing-date-panel"><time dateTime={club.date} aria-live="polite" aria-atomic="true">{new Date(`${club.date}T12:00:00`).toLocaleDateString('es-ES',{weekday:'long',day:'numeric',month:'long',year:'numeric'})}</time><span className="advancing-progress" aria-hidden="true"><i/></span></div>
  <section className="card advancing-results"><div className="card-top"><div><span className="eyebrow">{selected?.competitionName??'TODAS LAS COMPETICIONES'}</span><h2>{selected?fixtureLabel(selected):'Últimos partidos'}</h2></div></div>
   {selected?<article className="advancing-match" aria-label={`Resultado de ${names[selected.homeId]} contra ${names[selected.awayId]}`}>
    <div className="advancing-match-meta"><span>Partido {index+1} de {finished.length}</span>{selected.date&&<time dateTime={selected.date}>{new Date(`${selected.date}T12:00:00`).toLocaleDateString('es-ES',{day:'numeric',month:'short'})}</time>}</div>
    <div className="advancing-match-score"><div><ClubCrest clubId={selected.homeId} name={names[selected.homeId]}/><strong>{names[selected.homeId]}</strong></div><div className="advancing-match-total"><b>{selected.homeScore} – {selected.awayScore}</b>{selected.homeTries!==undefined&&selected.awayTries!==undefined&&<small>Ensayos {selected.homeTries} – {selected.awayTries}</small>}</div><div><ClubCrest clubId={selected.awayId} name={names[selected.awayId]}/><strong>{names[selected.awayId]}</strong></div></div>
    {scorers&&(scorers.home.length>0||scorers.away.length>0)&&<div className="advancing-match-scorers" aria-label="Anotadores del partido">{(['home','away'] as const).map(side=><section key={side} aria-label={`Anotadores de ${names[selected[`${side}Id`]]}`}><h3>{names[selected[`${side}Id`]]}</h3><ScoringList players={scorers[side]}/></section>)}</div>}
   </article>:<p className="empty">{results.isError?'Los resultados no están disponibles en este momento.':!results.data?'Consultando los resultados…':'Todavía no hay partidos disputados.'}</p>}
  </section>
 </section></div>;
}
