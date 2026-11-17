import { localize, tr, useLocale } from "./i18n";
import { Fragment } from 'react';
import { matchSeconds } from './matchClock';
import type { Match, MatchEvent } from './types';
export default function MatchScorers({ match, events, loading }: {
    match: Match;
    events: MatchEvent[];
    loading: boolean;
}) {
    useLocale();
    if (!loading && !events.some(e => e.points > 0))
        return null;
    return <div className="match-scorers" aria-label={tr("Resumen de anotadores")}>
  {localize((['home', 'away'] as const).map(side => {
            const players = match[`${side}Players`];
            return <section key={side} aria-label={tr(`Anotadores de ${match[`${side}Name`]}`)}>
    <h3>{localize(match[`${side}Name`])}</h3>
    {localize(loading ? <p className="scorers-empty">{tr("Cargando anotadores\u2026")}</p> : ([['try', 'Ensayos'], ['conversion', 'Transformaciones'], ['threePoints', 'Penalties']] as const).map(([type, label]) => {
                    const scorers = new Map<string, {
                        name: string;
                        minutes: string[];
                    }>();
                    events.filter(e => e.side === side && (type === 'threePoints' ? e.points === 3 : e.type === type && e.points > 0)).sort((a, b) => a.sequence - b.sequence).forEach(e => {
                        const key = e.playerId || e.id;
                        const scorer = scorers.get(key) ?? { name: players.find(p => p.playerId === e.playerId || p.id === e.playerId)?.name ?? 'Autor no registrado', minutes: [] };
                        scorer.minutes.push(`${Math.max(1, Math.ceil(matchSeconds(match, e.clock, e.period) / 60))}′`);
                        scorers.set(key, scorer);
                    });
                    if (!scorers.size)
                        return null;
                    return <div className="scorers-category" key={type}><h4>{localize(label)}</h4><p className="scorers-list">{localize([...scorers.entries()].map(([id, scorer], index) => <Fragment key={id}>{localize(index > 0 ? ', ' : '')}{localize(scorer.name)} <strong>{tr("(")}{localize(scorer.minutes.join(', '))}{tr(")")}</strong></Fragment>))}</p></div>;
                }))}
   </section>;
        }))}
 </div>;
}
