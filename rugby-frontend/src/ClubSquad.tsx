import { getLocale, localize, tr, useLocale } from "./i18n";
import { useState } from 'react';
import { Link, useParams, useSearchParams } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { api } from './api';
import { Energy, ErrorBox, Heading, Loading } from './components';
import ClubCrest from './ClubCrest';
import { InjuryMark } from './InjuryStatus';
import VenueInfo from './VenueInfo';
import type { Club, Page, Player } from './types';
export default function ClubSquad({ day }: {
    day: number;
}) {
    useLocale();
    const { clubId } = useParams(), [params, setParams] = useSearchParams(), academy = params.get('categoria') === 'cantera';
    const [search, setSearch] = useState(''), [position, setPosition] = useState('all');
    const club = useQuery({ queryKey: ['directory-club', clubId, day], queryFn: () => api<Club>(`/clubs/${encodeURIComponent(clubId!)}`) });
    const roster = useQuery({ queryKey: ['directory-roster', clubId, day], queryFn: () => api<Page<Player>>(`/clubs/${encodeURIComponent(clubId!)}/players?limit=500`) });
    if (club.isLoading || roster.isLoading)
        return <Loading />;
    if (club.error || roster.error)
        return <ErrorBox error={club.error || roster.error}/>;
    const c = club.data!, all = roster.data!.items;
    const players = all.filter(p => p.category === (academy ? 'academy' : 'senior') && p.name.toLocaleLowerCase().includes(search.toLocaleLowerCase()) && (position === 'all' || p.positionGroup === position)).sort((a, b) => a.position - b.position || b.average - a.average || a.name.localeCompare(b.name, 'es'));
    function changeCategory(next: boolean) { setSearch(''); setPosition('all'); setParams(next ? { categoria: 'cantera' } : {}); }
    return <><Link className="back-link" to="/clubes">{tr("\u2190 Volver a clubes y divisiones")}</Link><Heading eyebrow={"PLANTILLA ACTUAL"} title={c.shortName || c.name} description={`${c.competition} · ${new Date(`${c.date}T12:00:00`).toLocaleDateString(getLocale())}`}/>
 <div className="club-squad-identity"><ClubCrest clubId={c.id} name={c.name} className="directory-crest"/><div><strong>{c.city}</strong><VenueInfo venue={c.stadium}/></div></div>
 <div className="competition-tabs" role="tablist" aria-label={tr("Categoría de la plantilla del club")}>{localize((['senior', 'academy'] as const).map(category => <button key={category} role="tab" id={`club-squad-${category}`} aria-selected={academy === (category === 'academy')} aria-controls="club-squad-panel" onClick={() => changeCategory(category === 'academy')}>{localize(category === 'senior' ? 'Primer equipo' : 'Cantera')}{tr(" \u00B7 ")}{localize(all.filter(p => p.category === category).length)}</button>))}</div>
 <div role="tabpanel" id="club-squad-panel" aria-labelledby={`club-squad-${academy ? 'academy' : 'senior'}`}><div className="toolbar"><input aria-label={tr("Buscar jugador")} placeholder={tr("Buscar por nombre…")} value={search} onChange={e => setSearch(e.target.value)}/><select aria-label={tr("Filtrar por posición")} value={position} onChange={e => setPosition(e.target.value)}><option value="all">{tr("Todas las posiciones")}</option><option value="forwards">{tr("Delanteros")}</option><option value="backs">{tr("Tres cuartos")}</option></select><span>{localize(players.length)}{tr(" jugadores")}</span></div>
 <div className="card table-wrap"><table className="player-list-table roster-player-table" aria-label={tr(academy ? 'Cantera del club' : 'Primer equipo del club')}><thead><tr><th>{tr("Jugador")}</th><th>{tr("Situaci\u00F3n")}</th><th>{tr("Posici\u00F3n")}</th><th>{tr("Edad")}</th><th>{tr("Media")}</th><th>{tr("Energ\u00EDa")}</th><th>{tr("Moral")}</th><th>{tr("Nacionalidad")}</th></tr></thead><tbody>{localize(players.map(p => <tr key={p.id}><td><Link className="player-name" title={p.name} to={`/jugadores/${encodeURIComponent(p.id)}?club=${encodeURIComponent(c.id)}`}>{p.name}</Link></td><td className="situation-cell"><InjuryMark player={p}/></td><td>{localize(p.positionName)}</td><td>{localize(p.age)}</td><td>{localize(Math.round(p.average))}</td><td><Energy value={p.energy}/></td><td><Energy value={p.morale}/></td><td>{localize(p.nationality ?? 'España')}</td></tr>))}</tbody></table>{localize(!players.length && <p className="empty">{tr("No hay jugadores con estos filtros.")}</p>)}</div></div>
 </>;
}
