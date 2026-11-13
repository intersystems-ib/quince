import {Fragment} from 'react';
import {matchSeconds} from './matchClock';
import type {Match,MatchEvent} from './types';

export default function MatchScorers({match,events,loading}:{match:Match;events:MatchEvent[];loading:boolean}){
 return <div className="match-scorers" aria-label="Resumen de anotadores">
  {(['home','away'] as const).map(side=>{
   const players=match[`${side}Players`];
   return <section key={side} aria-label={`Anotadores de ${match[`${side}Name`]}`}>
    <h3>{match[`${side}Name`]}</h3>
    {loading?<p className="scorers-empty">Cargando anotadores…</p>:([['try','Ensayos'],['conversion','Transformaciones'],['threePoints','Anotaciones de 3 puntos']] as const).map(([type,label])=>{
     const scorers=new Map<string,{name:string;minutes:string[]}>();
     events.filter(e=>e.side===side&&(type==='threePoints'?e.points===3:e.type===type&&e.points>0)).sort((a,b)=>a.sequence-b.sequence).forEach(e=>{
      const key=e.playerId||e.id;
      const scorer=scorers.get(key)??{name:players.find(p=>p.playerId===e.playerId||p.id===e.playerId)?.name??'Autor no registrado',minutes:[]};
      scorer.minutes.push(`${Math.max(1,Math.ceil(matchSeconds(match,e.clock,e.period)/60))}′`);
      scorers.set(key,scorer);
     });
     return <div className="scorers-category" key={type}><h4>{label}</h4>{scorers.size?<p className="scorers-list">{[...scorers.entries()].map(([id,scorer],index)=><Fragment key={id}>{index>0?', ':''}{scorer.name} <strong>({scorer.minutes.join(', ')})</strong></Fragment>)}</p>:<p className="scorers-empty">Sin {label.toLocaleLowerCase()}</p>}</div>;
    })}
   </section>;
  })}
 </div>;
}
