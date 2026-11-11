import {clock} from './components';
import type {Command,Match,MatchEvent} from './types';

type Entry={id:string;clock:number;sequence:number;event?:MatchEvent;command?:Command};
const commands:Record<string,string>={speed:'Velocidad',substitution:'Sustitución',tactic:'Cambio táctico'};
const statuses:Record<string,string>={pending:'Pendiente',applied:'Aplicada',rejected:'Rechazada'};
export default function MatchTimeline({match,events,decisions}:{match:Match;events:MatchEvent[];decisions:Command[]}){
 const latestDecisions=[...decisions].sort((a,b)=>b.sequence-a.sequence).slice(0,10);
 const entries:Entry[]=[
  ...events.slice(-100).filter(event=>event.type!=='command'||!latestDecisions.some(c=>c.status==='applied'&&c.appliedClock===event.clock&&(!c.side||c.side===event.side))).map(event=>({id:`event-${event.id}`,clock:event.clock,sequence:event.sequence,event})),
  ...latestDecisions.map(command=>({id:`command-${command.id}`,clock:command.status==='applied'?command.appliedClock:command.receivedClock??command.appliedClock,sequence:command.sequence,command})),
 ];
 entries.sort((a,b)=>b.clock-a.clock||Number(!!b.command)-Number(!!a.command)||b.sequence-a.sequence);
 return <section className="card feed-card match-timeline"><div className="card-top"><h3>El minuto a minuto</h3><span className="tiny-tag">{match.status==='finished'?'FINAL':'EN DIRECTO'}</span></div><div className="event-feed" aria-label="Narración y decisiones del partido" aria-live="off">{entries.map(entry=>{
  if(entry.command){const c=entry.command;return <div className={`event decision ${c.status}`} key={entry.id}><span className="event-clock">{clock(entry.clock)}</span><i className="decision-marker"/><div><div className="decision-heading"><strong>{commands[c.type]??'Decisión'}{c.type==='speed'&&typeof c.parameters.speed==='number'?` · ${c.parameters.speed===0?'Pausa':`x${c.parameters.speed}`}`:''}</strong><span className={`command-status ${c.status}`}>{statuses[c.status]??c.status}</span></div><p>{c.reason||(c.status==='applied'?'Decisión confirmada.':'Esperando el siguiente punto permitido.')}</p><small className="decision-source">{c.source==='ai'?'Decisión del rival':'Decisión desde la banda'}</small></div></div>}
  const e=entry.event!;return <div key={entry.id} className={`event ${e.points?'scoring':''} ${['yellowCard','redCard','sinBinReturn','injury'].includes(e.type)?e.type:''}`}><span className="event-clock">{clock(e.clock)}</span><i style={{background:e.side==='home'?match.homeColor:e.side==='away'?match.awayColor:'#909b96'}}/><div><p>{e.text}</p>{e.points>0&&<small>+{e.points} PUNTOS · {e.homeScore} — {e.awayScore}</small>}</div></div>;
 })}{!entries.length&&<p className="empty">Esperando las primeras jugadas…</p>}</div></section>;
}
