import {useState} from 'react';
import {useQuery} from '@tanstack/react-query';
import {Link} from 'react-router-dom';
import {api} from './api';
import {ErrorBox,Loading} from './components';
import ClubCrest from './ClubCrest';
import type {CompetitionLeaders} from './types';
const categories=[['attack','Ataque'],['defense','Defensa'],['kicking','Juego al pie'],['setPieces','Formaciones'],['discipline','Disciplina'],['participation','Participación']];
export default function CompetitionStatistics({id}:{id:string}){
 const [category,setCategory]=useState('attack');
 const q=useQuery({queryKey:['competition-statistics',id],queryFn:()=>api<CompetitionLeaders>(`/competitions/${id}/statistics`),refetchInterval:15000});
 if(q.isLoading)return <Loading/>;if(q.error)return <ErrorBox error={q.error}/>;
 const data=q.data!;
 return <><div className="toolbar competition-statistics-toolbar"><label>Estadísticas<select aria-label="Categoría de estadísticas" value={category} onChange={e=>setCategory(e.target.value)}>{categories.map(([key,label])=><option key={key} value={key}>{label}</option>)}</select></label><span>Top 10 · Totales de {data.season} · Incluye fases finales</span></div>{data.partialRecords>0&&<p className="notice">Algunos partidos antiguos tienen registros parciales. Solo se suman los datos disponibles.</p>}{!data.players?<section className="card"><p className="empty">Las estadísticas aparecerán al terminar los primeros partidos de esta competición.</p></section>:<div className="competition-leaderboards">{data.metrics.filter(m=>m.category===category).map(m=><section key={m.id} className="card competition-leaderboard"><div className="card-top"><h3>{m.label}</h3><span className="tiny-tag">TOP 10</span></div>{m.leaders.length?<table className="player-list-table"><thead><tr><th>#</th><th>Jugador</th><th title="Partidos jugados">PJ</th><th>Total</th></tr></thead><tbody>{m.leaders.map(p=><tr key={p.playerId}><td>{p.rank}</td><td><Link className="player-name" to={`/jugadores/${p.playerId}?club=${p.clubId}`}>{p.name}</Link><small className="leaderboard-club"><ClubCrest clubId={p.clubId} name={p.clubName}/>{p.clubName}</small></td><td>{p.appearances}</td><td><b>{Math.round(p.value).toLocaleString('es-ES')}</b></td></tr>)}</tbody></table>:<p className="empty">Todavía no hay registros para esta estadística.</p>}</section>)}</div>}</>;
}
