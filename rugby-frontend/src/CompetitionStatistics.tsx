import { getLocale, localize, tr, useLocale } from "./i18n";
import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { api } from './api';
import { ErrorBox, Loading } from './components';
import ClubCrest from './ClubCrest';
import type { CompetitionLeaders } from './types';
const categories = [['attack', 'Ataque'], ['defense', 'Defensa'], ['kicking', 'Juego al pie'], ['setPieces', 'Formaciones'], ['discipline', 'Disciplina'], ['participation', 'Participación']];
export default function CompetitionStatistics({ id }: {
    id: string;
}) {
    useLocale();
    const [category, setCategory] = useState('attack');
    const q = useQuery({ queryKey: ['competition-statistics', id], queryFn: () => api<CompetitionLeaders>(`/competitions/${id}/statistics`), refetchInterval: 15000 });
    if (q.isLoading)
        return <Loading />;
    if (q.error)
        return <ErrorBox error={q.error}/>;
    const data = q.data!;
    return <><div className="toolbar competition-statistics-toolbar"><label>{tr("Estad\u00EDsticas")}<select aria-label={tr("Categoría de estadísticas")} value={category} onChange={e => setCategory(e.target.value)}>{localize(categories.map(([key, label]) => <option key={key} value={key}>{localize(label)}</option>))}</select></label><span>{tr("Top 10 \u00B7 Totales de ")}{localize(data.season)}{tr(" \u00B7 Incluye fases finales")}</span></div>{localize(data.partialRecords > 0 && <p className="notice">{tr("Algunos partidos antiguos tienen registros parciales. Solo se suman los datos disponibles.")}</p>)}{localize(!data.players ? <section className="card"><p className="empty">{tr("Las estad\u00EDsticas aparecer\u00E1n al terminar los primeros partidos de esta competici\u00F3n.")}</p></section> : <div className="competition-leaderboards">{localize(data.metrics.filter(m => m.category === category).map(m => <section key={m.id} className="card competition-leaderboard"><div className="card-top"><h3>{localize(m.label)}</h3><span className="tiny-tag">{tr("TOP 10")}</span></div>{localize(m.leaders.length ? <table className="player-list-table"><thead><tr><th>{tr("#")}</th><th>{tr("Jugador")}</th><th title={tr("Partidos jugados")}>{tr("PJ")}</th><th>{tr("Total")}</th></tr></thead><tbody>{localize(m.leaders.map(p => <tr key={p.playerId}><td>{localize(p.rank)}</td><td><Link className="player-name" to={`/jugadores/${p.playerId}?club=${p.clubId}`}>{p.name}</Link><small className="leaderboard-club"><ClubCrest clubId={p.clubId} name={p.clubName}/>{p.clubName}</small></td><td>{localize(p.appearances)}</td><td><b>{localize(Math.round(p.value).toLocaleString(getLocale()))}</b></td></tr>))}</tbody></table> : <p className="empty">{tr("Todav\u00EDa no hay registros para esta estad\u00EDstica.")}</p>)}</section>))}</div>)}</>;
}
