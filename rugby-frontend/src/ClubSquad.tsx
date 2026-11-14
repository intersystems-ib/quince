import {useState} from 'react';
import {Link,useParams,useSearchParams} from 'react-router-dom';
import {useQuery} from '@tanstack/react-query';
import {api} from './api';
import {Energy,ErrorBox,Heading,Loading} from './components';
import ClubCrest from './ClubCrest';
import {InjuryMark} from './InjuryStatus';
import VenueInfo from './VenueInfo';
import type {Club,Page,Player} from './types';

export default function ClubSquad({day}:{day:number}){
 const {clubId}=useParams(),[params,setParams]=useSearchParams(),academy=params.get('categoria')==='cantera';
 const [search,setSearch]=useState(''),[position,setPosition]=useState('all');
 const club=useQuery({queryKey:['directory-club',clubId,day],queryFn:()=>api<Club>(`/clubs/${encodeURIComponent(clubId!)}`)});
 const roster=useQuery({queryKey:['directory-roster',clubId,day],queryFn:()=>api<Page<Player>>(`/clubs/${encodeURIComponent(clubId!)}/players?limit=500`)});
 if(club.isLoading||roster.isLoading)return <Loading/>;
 if(club.error||roster.error)return <ErrorBox error={club.error||roster.error}/>;
 const c=club.data!,all=roster.data!.items;
 const players=all.filter(p=>p.category===(academy?'academy':'senior')&&p.name.toLocaleLowerCase().includes(search.toLocaleLowerCase())&&(position==='all'||p.positionGroup===position)).sort((a,b)=>a.position-b.position||b.average-a.average||a.name.localeCompare(b.name,'es'));
 function changeCategory(next:boolean){setSearch('');setPosition('all');setParams(next?{categoria:'cantera'}:{});}
 return <><Link className="back-link" to="/clubes">← Volver a clubes y divisiones</Link><Heading eyebrow="PLANTILLA ACTUAL" title={c.shortName||c.name} description={`${c.competition} · ${new Date(`${c.date}T12:00:00`).toLocaleDateString('es-ES')}`}/>
 <div className="club-squad-identity"><ClubCrest clubId={c.id} name={c.name} className="directory-crest"/><div><strong>{c.city}</strong><VenueInfo venue={c.stadium}/></div></div>
 <div className="competition-tabs" role="tablist" aria-label="Categoría de la plantilla del club">{(['senior','academy'] as const).map(category=><button key={category} role="tab" id={`club-squad-${category}`} aria-selected={academy===(category==='academy')} aria-controls="club-squad-panel" onClick={()=>changeCategory(category==='academy')}>{category==='senior'?'Primer equipo':'Cantera'} · {all.filter(p=>p.category===category).length}</button>)}</div>
 <div role="tabpanel" id="club-squad-panel" aria-labelledby={`club-squad-${academy?'academy':'senior'}`}><div className="toolbar"><input aria-label="Buscar jugador" placeholder="Buscar por nombre…" value={search} onChange={e=>setSearch(e.target.value)}/><select aria-label="Filtrar por posición" value={position} onChange={e=>setPosition(e.target.value)}><option value="all">Todas las posiciones</option><option value="forwards">Delanteros</option><option value="backs">Tres cuartos</option></select><span>{players.length} jugadores</span></div>
 <div className="card table-wrap"><table className="player-list-table roster-player-table" aria-label={academy?'Cantera del club':'Primer equipo del club'}><thead><tr><th>Jugador</th><th>Situación</th><th>Posición</th><th>Edad</th><th>Media</th><th>Energía</th><th>Moral</th><th>Nacionalidad</th></tr></thead><tbody>{players.map(p=><tr key={p.id}><td><Link className="player-name" title={p.name} to={`/jugadores/${encodeURIComponent(p.id)}?club=${encodeURIComponent(c.id)}`}>{p.name}</Link></td><td className="situation-cell"><InjuryMark player={p}/></td><td>{p.positionName}</td><td>{p.age}</td><td>{Math.round(p.average)}</td><td><Energy value={p.energy}/></td><td><Energy value={p.morale}/></td><td>{p.nationality??'España'}</td></tr>)}</tbody></table>{!players.length&&<p className="empty">No hay jugadores con estos filtros.</p>}</div></div>
 </>;
}
