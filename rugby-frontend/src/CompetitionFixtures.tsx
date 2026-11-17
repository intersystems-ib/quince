import { getLocale, localize, tr, useLocale } from "./i18n";
import VenueInfo from './VenueInfo';
import ClubCrest from './ClubCrest';
import Prepare from './MatchPreparation';
import ClassificationPoints from './ClassificationPoints';
import { statusLabels } from './components';
import type { Club, Fixture } from './types';
const dateLabel = (date?: string) => date ? new Date(`${date}T12:00:00`).toLocaleDateString(getLocale(), { weekday: 'short', day: 'numeric', month: 'short', year: 'numeric' }) : '';
export function EmptyTie({ date }: {
    date: string;
}) { useLocale(); return <article className="card empty-tie"><span>{localize(dateLabel(date))}</span><div><span className="empty-crest"/><b>{tr("Por determinar")}</b></div><small>{tr("vs")}</small><div><span className="empty-crest"/><b>{tr("Por determinar")}</b></div></article>; }
export function FixtureCard({ f, club, names }: {
    f: Fixture;
    club: Club;
    names: Record<string, string>;
}) {
    useLocale();
    const own = f.homeId === club.id || f.awayId === club.id;
    return <article className={`card competition-fixture ${own ? 'own-fixture' : ''}`}><div className="fixture-heading"><time dateTime={f.date}>{localize(dateLabel(f.date))}</time><span className="pill">{localize(statusLabels[f.status] ?? f.status)}</span></div><VenueInfo venue={f.venue}/><div className="competition-score-row"><ClubCrest clubId={f.homeId} name={names[f.homeId]}/><strong>{localize(names[f.homeId])}</strong><b>{localize(f.status === 'finished' ? f.homeScore : '—')}</b></div><div className="competition-score-row"><ClubCrest clubId={f.awayId} name={names[f.awayId]}/><strong>{localize(names[f.awayId])}</strong><b>{localize(f.status === 'finished' ? f.awayScore : '—')}</b></div><ClassificationPoints value={f.classification} home={names[f.homeId]} away={names[f.awayId]}/>{localize(f.homeShootout !== undefined && <p className="shootout-result">{tr("Desempate a palos: ")}{localize(f.homeShootout)}{tr("\u2013")}{localize(f.awayShootout)}</p>)}{localize(own && <Prepare fixture={f} club={club}/>)}</article>;
}
