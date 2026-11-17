import { getLocale, localize, tr, useLocale } from "./i18n";
import { useEffect, useRef } from 'react';
import type { ReactNode } from 'react';
import { useQuery } from '@tanstack/react-query';
import { getGameId } from './api';
import ClubCrest from './ClubCrest';
import type { Club, Fixture } from './types';
import { fixtureLabel } from './competitionLabels';
type RecentResults = {
    items: (Fixture & {
        competitionName: string;
    })[];
    clubs: {
        id: string;
        name: string;
    }[];
};
export function AdvanceBackground({ running, children }: {
    running: boolean;
    children: ReactNode;
}) {
    useLocale();
    const previous = useRef(children);
    if (!running)
        previous.current = children;
    return previous.current;
}
type Scorer = {
    playerId: string;
    name: string;
    tries: number;
    conversions: number;
    penalties: number;
};
function ScoringList({ players }: {
    players: Scorer[];
}) {
    useLocale();
    return <>{localize(([['tries', 'Ensayos'], ['conversions', 'Transformaciones'], ['penalties', 'Penalties']] as const).map(([field, label]) => {
            const scorers = players.filter(p => p[field] > 0);
            return scorers.length ? <div className="scorers-category" key={field}><h4>{localize(label)}</h4><p>{localize(scorers.map(p => `${p.name}${p[field] > 1 ? ` ×${p[field]}` : ''}`).join(', '))}</p></div> : null;
        }))}</>;
}
export default function AdvancingScreen({ club }: {
    club: Club;
}) {
    useLocale();
    const screen = useRef<HTMLDivElement>(null), startDay = useRef(club.day);
    useEffect(() => { screen.current?.focus(); }, []);
    const results = useQuery({ queryKey: ['advancing-results', getGameId()], queryFn: async (): Promise<RecentResults> => ({ items: [], clubs: [] }), enabled: false, staleTime: Infinity });
    const finished = results.data?.items ?? [], index = finished.length ? Math.max(0, club.day - startDay.current) % finished.length : 0, selected = finished[index];
    const scorers = selected?.scorers;
    const names = Object.fromEntries(results.data?.clubs.map(c => [c.id, c.name]) ?? []);
    return <div ref={screen} className="advancing-overlay" role="dialog" aria-modal="true" aria-label={tr("Avance de la partida")} tabIndex={-1}><section className="advancing-screen">
  <div className="advancing-date-panel"><time dateTime={club.date} aria-live="polite" aria-atomic="true">{localize(new Date(`${club.date}T12:00:00`).toLocaleDateString(getLocale(), { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' }))}</time><span className="advancing-progress" aria-hidden="true"><i /></span></div>
  <section className="card advancing-results"><div className="card-top"><div><span className="eyebrow">{localize(selected?.competitionName ?? 'TODAS LAS COMPETICIONES')}</span><h2>{localize(selected ? fixtureLabel(selected) : 'Últimos partidos')}</h2></div></div>
   {localize(selected ? <article className="advancing-match" aria-label={tr(`Resultado de ${names[selected.homeId]} contra ${names[selected.awayId]}`)}>
    <div className="advancing-match-meta"><span>{tr("Partido ")}{localize(index + 1)}{tr(" de ")}{localize(finished.length)}</span>{localize(selected.date && <time dateTime={selected.date}>{localize(new Date(`${selected.date}T12:00:00`).toLocaleDateString(getLocale(), { day: 'numeric', month: 'short' }))}</time>)}</div>
    <div className="advancing-match-score"><div><ClubCrest clubId={selected.homeId} name={names[selected.homeId]}/><strong>{localize(names[selected.homeId])}</strong></div><div className="advancing-match-total"><b>{localize(selected.homeScore)}{tr(" \u2013 ")}{localize(selected.awayScore)}</b>{localize(selected.homeTries !== undefined && selected.awayTries !== undefined && <small>{tr("Ensayos ")}{localize(selected.homeTries)}{tr(" \u2013 ")}{localize(selected.awayTries)}</small>)}</div><div><ClubCrest clubId={selected.awayId} name={names[selected.awayId]}/><strong>{localize(names[selected.awayId])}</strong></div></div>
    {localize(scorers && (scorers.home.length > 0 || scorers.away.length > 0) && <div className="advancing-match-scorers" aria-label={tr("Anotadores del partido")}>{localize((['home', 'away'] as const).map(side => <section key={side} aria-label={tr(`Anotadores de ${names[selected[`${side}Id`]]}`)}><h3>{localize(names[selected[`${side}Id`]])}</h3><ScoringList players={scorers[side]}/></section>))}</div>)}
   </article> : <p className="empty">{localize(results.isError ? 'Los resultados no están disponibles en este momento.' : !results.data ? 'Consultando los resultados…' : 'Todavía no hay partidos disputados.')}</p>)}
  </section>
 </section></div>;
}
