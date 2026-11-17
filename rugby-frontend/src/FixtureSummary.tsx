import { localize, tr, useLocale } from "./i18n";
import { useClubName } from './clubNames';
import ClubCrest from './ClubCrest';
import { statusLabels } from './components';
import { fixtureLabel } from './competitionLabels';
import { fixtureOutcome } from './calendarResults';
import type { Fixture } from './types';
export default function FixtureSummary({ fixture: f, names, clubId }: {
    fixture: Fixture;
    names: Record<string, string>;
    clubId: string;
}) {
    useLocale();
    const clubName = useClubName();
    return <><div className="fixture-heading"><span className="pill">{localize(fixtureLabel(f))}</span></div><div className="calendar-teams"><ClubCrest clubId={f.homeId} name={names[f.homeId]}/><strong title={tr(names[f.homeId])}>{localize(clubName(f.homeId, names[f.homeId]))}</strong><b className={`calendar-result ${fixtureOutcome(f, clubId)}`}>{localize(f.status === 'finished' ? `${f.homeScore} – ${f.awayScore}` : 'vs')}</b><strong title={tr(names[f.awayId])}>{localize(clubName(f.awayId, names[f.awayId]))}</strong><ClubCrest clubId={f.awayId} name={names[f.awayId]}/></div><p className="calendar-fixture-status">{localize(statusLabels[f.status] ?? f.status)}</p></>;
}
