import ClubCrest from './ClubCrest';
import {statusLabels} from './components';
import {fixtureLabel} from './competitionLabels';
import {fixtureOutcome} from './calendarResults';
import type {Fixture} from './types';

export default function FixtureSummary({fixture:f,names,clubId}:{fixture:Fixture;names:Record<string,string>;clubId:string}){
 return <><div className="fixture-heading"><span className="pill">{fixtureLabel(f)}</span></div><div className="calendar-teams"><ClubCrest clubId={f.homeId} name={names[f.homeId]}/><strong>{names[f.homeId]}</strong><b className={`calendar-result ${fixtureOutcome(f,clubId)}`}>{f.status==='finished'?`${f.homeScore} – ${f.awayScore}`:'vs'}</b><strong>{names[f.awayId]}</strong><ClubCrest clubId={f.awayId} name={names[f.awayId]}/></div><p className="calendar-fixture-status">{statusLabels[f.status]??f.status}</p></>;
}
