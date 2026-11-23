import { getLocale, localize, tr, useLocale } from "./i18n";
import VenueInfo from './VenueInfo';
import ClubCrest from './ClubCrest';
import { useClubName } from './clubNames';
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
    const clubName = useClubName(), homeName = clubName(f.homeId, names[f.homeId] ?? f.homeId), awayName = clubName(f.awayId, names[f.awayId] ?? f.awayId);
    const own = f.homeId === club.id || f.awayId === club.id;
    return <article className={`card competition-fixture ${own ? 'own-fixture' : ''}`}><div className="fixture-heading"><time dateTime={f.date}>{localize(dateLabel(f.date))}</time><span className="pill">{localize(statusLabels[f.status] ?? f.status)}</span></div><VenueInfo venue={f.venue}/><div className="competition-score-row"><ClubCrest clubId={f.homeId} name={homeName}/><strong>{localize(homeName)}</strong><b>{localize(f.status === 'finished' ? f.homeScore : '—')}</b></div><div className="competition-score-row"><ClubCrest clubId={f.awayId} name={awayName}/><strong>{localize(awayName)}</strong><b>{localize(f.status === 'finished' ? f.awayScore : '—')}</b></div><ClassificationPoints value={f.classification} home={homeName} away={awayName}/>{localize(f.homeShootout !== undefined && <p className="shootout-result">{tr("Desempate a palos: ")}{localize(f.homeShootout)}{tr("\u2013")}{localize(f.awayShootout)}</p>)}{localize(own && <Prepare fixture={f} club={club}/>)}</article>;
}
