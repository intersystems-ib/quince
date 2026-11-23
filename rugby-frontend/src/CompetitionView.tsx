import { localize, tr, useLocale } from "./i18n";
import CupView from './CupView';
import CompetitionCalendar from './CompetitionCalendar';
import CompetitionStatistics from './CompetitionStatistics';
import { EmptyTie, FixtureCard } from './CompetitionFixtures';
import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Trophy } from 'lucide-react';
import { api } from './api';
import { ErrorBox, Heading, Loading } from './components';
import ClubCrest from './ClubCrest';
import type { Club, Competition, Page } from './types';
export default function CompetitionView({ club }: {
    club: Club;
}) {
    useLocale();
    const leagues = useQuery({ queryKey: ['competitions'], queryFn: () => api<Page<Competition>>('/competitions?limit=100') });
    const [choice, setChoice] = useState(''), [panel, setPanel] = useState('standings');
    if (leagues.isLoading)
        return <Loading />;
    if (leagues.error)
        return <ErrorBox error={leagues.error}/>;
    const items = [...leagues.data!.items].sort((a, b) => b.year - a.year || a.divisionId - b.divisionId);
    const selected = items.find(c => c.id === choice) ?? items.find(c => c.divisionId === club.competitionId) ?? items[0];
    const id = selected?.id, seasonItems = items.filter(c => c.year === selected?.year);
    const seasons = [...new Map(items.map(c => [c.year, c.season])).entries()];
    const changeSeason = (year: number) => {
        const available = items.filter(c => c.year === year);
        const next = available.find(c => (c.type === 'cup') === (selected?.type === 'cup') && (c.type === 'cup' || c.divisionId === selected?.divisionId)) ?? available.find(c => c.divisionId === club.competitionId) ?? available[0];
        setChoice(next?.id ?? '');
    };
    return <><Heading eyebrow={"TEMPORADA DE RUGBY"} title={"Competición"}/><div className="competition-toolbar"><label>{tr("Competici\u00F3n")}<select aria-label={tr("Competición")} value={id ?? ''} onChange={e => setChoice(e.target.value)} disabled={!items.length}>{localize(seasonItems.map(c => <option key={c.id} value={c.id}>{c.name}</option>))}</select></label><label>{tr("Temporada")}<select aria-label={tr("Temporada")} value={selected?.year ?? ''} onChange={e => changeSeason(Number(e.target.value))} disabled={!items.length}>{localize(seasons.map(([year, season]) => <option key={year} value={year}>{localize(season)}</option>))}</select></label><span className="pill">{localize(selected?.type === 'cup' ? '20 EQUIPOS · COPA DEL REY' : `${selected?.teamIds.length ?? 10} ${tr('equipos')} · ${((selected?.teamIds.length ?? 10) - 1) * 2} ${tr('jornadas')}`)}</span></div><div className="competition-tabs competition-main-tabs" role="tablist" aria-label={tr("Vista de competición")}>{localize([['standings', 'Clasificación'], ['calendar', 'Calendario'], ['statistics', 'Estadísticas']].map(([value, label]) => <button key={value} id={`competition-${value}-tab`} role="tab" aria-selected={panel === value} aria-controls="competition-content" onClick={() => setPanel(value)}>{localize(label)}</button>))}</div><div role="tabpanel" id="competition-content" aria-labelledby={`competition-${panel}-tab`}>{localize(id ? panel === 'statistics' ? <CompetitionStatistics key={id} id={id}/> : panel === 'calendar' ? <CompetitionCalendar key={id} id={id} club={club}/> : selected?.type === 'cup' ? <CupView key={id} id={id} club={club}/> : <League key={id} id={id} club={club}/> : <p className="empty">{tr("No hay una temporada disponible.")}</p>)}</div></>;
}
function League({ id, club }: {
    id: string;
    club: Club;
}) {
    useLocale();
    const q = useQuery({ queryKey: ['competition', id], queryFn: () => api<Competition>(`/competitions/${id}`), refetchInterval: 15000 });
    const [tab, setTab] = useState('regular');
    if (q.isLoading)
        return <Loading />;
    if (q.error)
        return <ErrorBox error={q.error}/>;
    const c = q.data!, names = Object.fromEntries(c.standings.map(r => [r.clubId, r.shortName || r.name]));
    return <>
 <div className="competition-tabs" role="tablist" aria-label={tr("Fases de competición")}><button id="regular-tab" role="tab" aria-selected={tab === 'regular'} aria-controls="regular-panel" onClick={() => setTab('regular')}>{tr("Liga regular")}</button><button id="playoffs-tab" role="tab" aria-selected={tab === 'playoffs'} aria-controls="playoffs-panel" onClick={() => setTab('playoffs')}>{tr("Fase final")}</button></div>
 {localize(tab === 'regular' ? <section role="tabpanel" id="regular-panel" aria-labelledby="regular-tab"><div className="card table-wrap competition-table"><table aria-label={tr(`Clasificación de ${c.name}`)}><thead><tr><th>{tr("#")}</th><th>{tr("Equipo")}</th><th title={tr("Partidos jugados")}>{tr("PJ")}</th><th title={tr("Ganados")}>{tr("G")}</th><th title={tr("Empatados")}>{tr("E")}</th><th title={tr("Perdidos")}>{tr("P")}</th><th title={tr("Tantos del marcador a favor")}>{tr("PF")}</th><th title={tr("Puntos en contra")}>{tr("PC")}</th><th title={tr("Diferencia de puntos")}>{tr("DIF")}</th><th title={tr("Bonus ofensivo: ganar con al menos tres ensayos más que el rival")}>{tr("BO")}</th><th title={tr(c.defensiveBonusMargin === 5 ? "Bonus defensivo: perder por cinco puntos o menos" : "Bonus defensivo: perder por siete puntos o menos")}>{tr("BD")}</th><th title={tr("Puntos de clasificación: 4 por victoria, 2 por empate, más BO y BD")}>{tr("PTS")}</th></tr></thead><tbody>{localize(c.standings.map(r => <tr key={r.clubId} className={`${r.rank <= (c.playoffTeams ?? 4) ? 'playoff-place' : ''} ${(c.divisionId === 416 || c.divisionId === 1401) && r.rank === c.teamIds.length ? 'relegation-place' : ''} ${c.divisionId === 1401 && r.rank === 13 ? 'access-place' : ''} ${r.clubId === club.id ? 'managed-club' : ''}`}><td title={tr((c.divisionId === 416 || c.divisionId === 1401) && r.rank === c.teamIds.length ? (c.divisionId === 1401 ? 'Plaza de descenso a Pro D2' : 'Plaza de descenso a División Élite') : c.divisionId === 1401 && r.rank === 13 ? 'Access Match' : undefined)}>{localize(r.rank)}</td><td><div className="standing-club"><ClubCrest clubId={r.clubId} name={r.name}/><span title={tr(r.name)}>{localize(r.shortName || r.name)}</span>{localize(r.clubId === club.id && <span className="tiny-tag">{tr("TU CLUB")}</span>)}</div></td><td>{localize(r.played)}</td><td>{localize(r.wins)}</td><td>{localize(r.draws)}</td><td>{localize(r.losses)}</td><td>{localize(r.pointsFor)}</td><td>{localize(r.pointsAgainst)}</td><td>{localize(r.difference > 0 ? '+' : '')}{localize(r.difference)}</td><td>{localize(r.bonusOffensive)}</td><td>{localize(r.bonusDefensive)}</td><td><b>{localize(r.points)}</b></td></tr>))}</tbody></table></div>
        </section> : <section role="tabpanel" id="playoffs-panel" aria-labelledby="playoffs-tab">
 {localize(c.championId && <div className="competition-champion"><Trophy size={26}/><ClubCrest clubId={c.championId} name={names[c.championId]}/><div><small>{tr("CAMPE\u00D3N")}{localize(c.divisionId === 417 ? ' · ASCENSO A HONOR' : '')}{tr(" \u00B7 ")}{localize(c.season)}</small><h3>{localize(names[c.championId])}</h3></div></div>)}
 <div className={`playoff-bracket ${c.directSemifinals === 2 ? 'playoff-bracket-six' : ''}`}>
 {c.directSemifinals === 2 && <section><h3>{tr('Eliminatoria previa')}</h3>{[1,2].map(slot => {const f=c.quarterfinals?.find(f=>f.slot===slot);return <div key={slot} className="playoff-slot"><span className="tiny-tag">{slot===1?'3.º — 6.º':'4.º — 5.º'}</span>{f?<FixtureCard f={f} club={club} names={names}/>:<EmptyTie date={c.quarterfinalDate ?? c.semifinalDates[0]}/>}</div>;})}</section>}
 <section><h3>{tr("Semifinales")}</h3>{localize([1, 2].map(slot => { const f = c.semifinals.find(f => f.slot === slot); return <div key={slot} className="playoff-slot"><span className="tiny-tag">{tr("SEMIFINAL ")}{localize(slot)}{tr(" \u00B7 ")}{localize(c.directSemifinals === 2 ? (slot === 1 ? '1.º — Ganador 4.º/5.º' : '2.º — Ganador 3.º/6.º') : slot === 1 ? '1.º — 4.º' : '2.º — 3.º')}</span>{localize(f ? <FixtureCard f={f} club={club} names={names}/> : <EmptyTie date={c.semifinalDates[slot - 1]}/>)}</div>; }))}</section><section className="playoff-final"><h3>{tr("Final")}</h3>{localize(c.final ? <FixtureCard f={c.final} club={club} names={names}/> : <EmptyTie date={c.finalDate}/>)}</section></div>
 {c.accessEnabled && <section className="competition-access"><h3>{tr('Access Match')}</h3><p className="muted">{tr('Subcampeón de Pro D2 — 13.º del Top 14')}</p>{c.accessMatch ? <FixtureCard f={c.accessMatch} club={club} names={names}/> : <EmptyTie date={c.accessDate ?? c.finalDate}/>}</section>}
 </section>)}</>;
}
