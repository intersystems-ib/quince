import { getLocale, localize, tr, useLocale } from "./i18n";
import type { ReactNode } from 'react';
import CardBadge from './CardBadge';
import { Fragment, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { api } from './api';
import { ErrorBox, Loading } from './components';
import type { Match, Page, PlayerMatchStats, Snapshot } from './types';
export const performanceLabels: Record<string, string> = { metres: 'Metros ganados', carries: 'Carreras con balón', tackles: 'Placajes', turnovers: 'Recuperaciones', passes: 'Pases', kicks: 'Patadas', knockOns: 'Avants', tries: 'Ensayos', conversions: 'Transformaciones', conversionAttempts: 'Transformaciones intentadas', penaltyGoals: 'Golpes a palos', penaltyAttempts: 'Golpes a palos intentados', drops: 'Drops', dropAttempts: 'Drops intentados', points: 'Puntos', scrums: 'Melés disputadas', lineouts: 'Touches disputadas', infringements: 'Infracciones', yellowCards: 'Amarillas', redCards: 'Rojas' };
const main = ['metres', 'tackles', 'tries', 'conversions', 'points'];
const columnLabels: Record<string, string> = { metres: 'Metros', tackles: 'Placajes', tries: 'Ensayos', conversions: 'Transf.', points: 'Puntos' };
const value = (n: number | undefined) => n === undefined ? '—' : Math.round(n).toLocaleString(getLocale());
function Details({ stats }: {
    stats: Record<string, number>;
}) { useLocale(); return <dl className="performance-details">{localize(Object.entries(performanceLabels).map(([key, label]) => <div key={key}><dt>{localize(label)}</dt><dd>{localize(value(stats[key]))}</dd></div>))}</dl>; }
export default function PlayerMatchHistory({ playerId }: {
    playerId: string;
}) {
    useLocale();
    const [page, setPage] = useState(0), [expanded, setExpanded] = useState<string | null>(null);
    const q = useQuery({ queryKey: ['player-match-stats', playerId, page], queryFn: () => api<Page<PlayerMatchStats> & {
            summary: {
                appearances: number;
                playedSeconds: number;
                stats: Record<string, number>;
                partialMatches: number;
            };
        }>(`/players/${playerId}/match-stats?offset=${page * 20}&limit=20`) });
    return <section className="card player-match-history"><div className="card-top"><h3>{tr("Rendimiento en partidos")}</h3>{localize(q.data && <span className="pill">{localize(q.data.summary.appearances)}{tr(" PARTIDOS JUGADOS")}</span>)}</div>{localize(q.isLoading ? <Loading /> : q.error ? <ErrorBox error={q.error}/> : q.data && <>{localize(!q.data.total ? <p className="empty">{tr("Todav\u00EDa no hay estad\u00EDsticas de partidos para este jugador.")}</p> : <><div className="performance-summary">{localize([['playedSeconds', 'Minutos'], ['metres', 'Metros ganados'], ['tackles', 'Placajes'], ['tries', 'Ensayos'], ['conversions', 'Transformaciones'], ['points', 'Puntos']].map(([key, label]) => <div key={key}><small>{localize(label)}</small><strong>{localize(value(key === 'playedSeconds' ? q.data.summary.playedSeconds / 60 : q.data.summary.stats[key]))}</strong></div>))}</div><div className="table-wrap"><table className="player-list-table performance-table"><thead><tr><th>{tr("Fecha / competici\u00F3n")}</th><th>{tr("Rival / resultado")}</th><th>{tr("Min.")}</th>{localize(main.map(key => <th key={key} title={tr(performanceLabels[key])}>{localize(columnLabels[key])}</th>))}<th /></tr></thead><tbody>{localize(q.data.items.map(r => <Fragment key={r.id}><tr><td>{localize(new Date(r.date + 'T12:00:00').toLocaleDateString(getLocale()))}<small>{localize(r.season)}{tr(" \u00B7 ")}{localize(r.stage === 'friendly' ? 'Amistoso' : r.competitionType === 'cup' ? 'Copa del Rey' : 'Liga')}</small></td><td><strong>{r.opponentName}</strong><small>{localize(r.side === 'home' ? 'Local' : 'Visitante')}{tr(" \u00B7 ")}{localize(r.matchId ? <Link to={`/partido/${r.matchId}`}>{localize(r.homeScore)}{tr("\u2013")}{localize(r.awayScore)}</Link> : `${r.homeScore}–${r.awayScore}`)}{tr(" \u00B7 ")}{r.clubName}</small></td><td>{localize(value(r.playedSeconds / 60))}</td>{localize(main.map(key => <td key={key}>{localize(value(r.stats[key]))}</td>))}<td><button className="button secondary" aria-expanded={expanded === r.id} onClick={() => setExpanded(expanded === r.id ? null : r.id)}>{localize(expanded === r.id ? 'Ocultar' : 'Ver detalle')}</button></td></tr>{localize(expanded === r.id && <tr><td colSpan={9}><Details stats={r.stats}/>{localize(!r.complete && <p className="muted small">{tr("Registro parcial: \u2014 indica una estad\u00EDstica que no se registraba.")}</p>)}</td></tr>)}</Fragment>))}</tbody></table></div>{localize(q.data.summary.partialMatches > 0 && <p className="muted small">{tr("Los totales incluyen s\u00F3lo los datos disponibles; algunos encuentros antiguos tienen registros parciales.")}</p>)}{localize(q.data.total > 20 && <div className="toolbar"><button className="button secondary" disabled={!page} onClick={() => setPage(page - 1)}>{tr("Anterior")}</button><span>{tr("P\u00E1gina ")}{localize(page + 1)}{tr(" de ")}{localize(Math.ceil(q.data.total / 20))}</span><button className="button secondary" disabled={(page + 1) * 20 >= q.data.total} onClick={() => setPage(page + 1)}>{tr("Siguiente")}</button></div>)}</>)}</>)}</section>;
}
function TeamPlayers({ players, name }: {
    players: Snapshot[];
    name: string;
}) { useLocale(); const [expanded, setExpanded] = useState<string | null>(null); return <section className="individual-team"><h4>{localize(name)}</h4><div className="table-wrap"><table className="player-list-table performance-table"><thead><tr><th>{tr("Jugador")}</th><th>{tr("Min.")}</th>{localize(main.map(key => <th key={key} title={tr(performanceLabels[key])}>{localize(columnLabels[key])}</th>))}<th>{tr("Detalle")}</th></tr></thead><tbody>{localize(players.map(p => <Fragment key={p.id}><tr><td><span className="performance-player-identity"><Link className="player-name" to={`/jugadores/${p.playerId}`}>{p.name}</Link><CardBadge color="yellow" count={p.yellowCards ?? p.stats.yellowCards ?? 0}/><CardBadge color="red" count={p.redCards ?? p.stats.redCards ?? 0}/></span></td><td>{localize(value(p.playedSeconds === undefined ? undefined : p.playedSeconds / 60))}</td>{localize(main.map(key => <td key={key}>{localize(value(p.stats[key]))}</td>))}<td><button className="button secondary" aria-expanded={expanded === p.id} onClick={() => setExpanded(expanded === p.id ? null : p.id)}>{localize(expanded === p.id ? 'Ocultar' : 'Ver detalle')}</button></td></tr>{localize(expanded === p.id && <tr><td colSpan={8}><Details stats={{ ...p.stats, yellowCards: p.yellowCards ?? 0, redCards: p.redCards ?? 0, infringements: p.infringements ?? 0 }}/></td></tr>)}</Fragment>))}</tbody></table></div></section>; }
export function MatchStatistics({ match, summary }: {
    match: Match;
    summary: ReactNode;
}) {
    useLocale();
    const [tab, setTab] = useState<'match' | 'home' | 'away'>('match');
    const panel = `statistics-${match.id}-panel`;
    return <section className="card individual-statistics"><div className="card-top"><h3>{tr("Estad\u00EDsticas")}</h3><span className="tiny-tag">{localize(match.status === 'finished' ? 'RESULTADO FINAL' : 'EN DIRECTO')}</span></div><div className="competition-tabs" role="tablist" aria-label={tr("Estadísticas del partido")}><button id={`statistics-${match.id}-match-tab`} role="tab" aria-selected={tab === 'match'} aria-controls={panel} onClick={() => setTab('match')}>{tr("Partido")}</button>{localize((['home', 'away'] as const).map(team => <button key={team} id={`statistics-${match.id}-${team}-tab`} role="tab" aria-selected={tab === team} aria-controls={panel} onClick={() => setTab(team)}>{localize(match[`${team}Name`])}</button>))}</div><div role="tabpanel" id={panel} aria-labelledby={`statistics-${match.id}-${tab}-tab`}>{localize(tab === 'match' ? summary : <TeamPlayers key={tab} players={match[`${tab}Players`]} name={match[`${tab}Name`]}/>)}</div></section>;
}
