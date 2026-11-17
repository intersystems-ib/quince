import { localize, tr, useLocale } from "./i18n";
import StadiumImage from './StadiumImage';
import MatchTicketing from './MatchTicketing';
import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { ArrowRight } from 'lucide-react';
import { api } from './api';
import ClubCrest from './ClubCrest';
import { Action, Energy, ErrorBox, Heading, Loading } from './components';
import type { Match, MatchComparison, ComparisonGroup } from './types';
export default function MatchPreview({ match: m }: {
    match: Match;
}) {
    useLocale();
    const [group, setGroup] = useState<ComparisonGroup | 'ticketing'>('all');
    const q = useQuery({ queryKey: ['match-comparison', m.id], queryFn: () => api<MatchComparison>(`/matches/${m.id}/comparison`) });
    const comparison = q.data, home = group === 'ticketing' ? undefined : comparison?.home.groups[group], away = group === 'ticketing' ? undefined : comparison?.away.groups[group];
    return <><Heading eyebrow={"PREVIA DEL PARTIDO"} title={"Comparativa de equipos."} description={`${m.homeName} frente a ${m.awayName}`} action={<Action path={`/matches/${m.id}/start`} className="orange" disabled={!comparison?.ready || q.isFetching}>{tr("Iniciar partido ")}<ArrowRight size={16}/></Action>}/>
 <div className="competition-tabs prematch-tabs" role="tablist" aria-label={tr("Previa del partido")}>{localize(([['all', 'XV titular'], ['forwards', 'Delanteros'], ['backs', 'Tres cuartos'], ['ticketing', 'Campo y entradas']] as const).map(([id, label]) => <button id={`comparison-${id}`} key={id} role="tab" aria-selected={group === id} aria-controls="comparison-panel" onClick={() => setGroup(id)}>{localize(label)}</button>))}</div>
 {localize(group === 'ticketing' ? <section className="card prematch-ticketing" id="comparison-panel" role="tabpanel" aria-labelledby="comparison-ticketing"><StadiumImage venue={m.venue}/><div className="stadium-ticket-details"><h3>{tr("Entradas")}</h3><MatchTicketing key={`${m.id}-${m.ticketPrice}`} match={m}/></div></section> : q.isLoading ? <Loading /> : q.error ? <ErrorBox error={q.error}/> : comparison && home && away ? <>
 <div id="comparison-panel" role="tabpanel" aria-labelledby={`comparison-${group}`}>
 <div className="prematch-lineups comparison-teams">{localize([{ team: comparison.home, summary: home, venue: 'Local' }, { team: comparison.away, summary: away, venue: 'Visitante' }].map(({ team, summary, venue }) => <section className="card prematch-team comparison-team" key={team.clubId}><header><ClubCrest clubId={team.clubId} name={team.name} className="prematch-crest"/><div><span className="eyebrow">{localize(venue)}</span><h2 title={tr(team.name)}>{localize(team.clubId === m.homeId ? m.homeName : m.awayName)}</h2><small>{localize(summary.count)} {localize(group === 'all' ? 'titulares' : group === 'forwards' ? 'delanteros' : 'tres cuartos')}</small></div></header><div className="comparison-team-stats"><div><small>{tr("Media")}</small><strong>{localize(Math.round(summary.average))}</strong></div><div><small>{tr("Energ\u00EDa")}</small><Energy value={summary.energy}/></div><div><small>{tr("Moral")}</small><Energy value={summary.morale}/></div></div></section>))}</div>
 <section className="card table-wrap comparison-card"><table aria-label={tr("Medias de características por equipo")}><thead><tr><th>{m.homeName}</th><th>{tr("Caracter\u00EDstica")}</th><th>{m.awayName}</th></tr></thead><tbody>{localize(comparison.attributes.map(attr => { const h = home.attributes[attr.id] ?? 0, a = away.attributes[attr.id] ?? 0, higher = Math.round(h) > Math.round(a), lower = Math.round(a) > Math.round(h); return <tr key={attr.id}><td><div className="comparison-value home"><strong className={higher ? 'comparison-leading' : ''}>{localize(Math.round(h))}</strong><span className="comparison-track"><i style={{ width: `${Math.max(0, Math.min(100, h))}%` }}/></span></div></td><th scope="row">{localize(attr.name)}</th><td><div className="comparison-value away"><span className="comparison-track"><i style={{ width: `${Math.max(0, Math.min(100, a))}%` }}/></span><strong className={lower ? 'comparison-leading' : ''}>{localize(Math.round(a))}</strong></div></td></tr>; }))}</tbody></table></section>
 </div>
 </> : null)}
 {localize(comparison && !comparison.ready && <p role="alert" className="notice">{tr("Revisa las alineaciones antes de iniciar el partido.")}</p>)}
 {localize(group === 'ticketing' && q.error && <ErrorBox error={q.error}/>)}
 </>;
}
