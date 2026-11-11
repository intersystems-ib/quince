import VenueInfo from './VenueInfo';
import ClubCrest from './ClubCrest';
import Prepare from './MatchPreparation';
import ClassificationPoints from './ClassificationPoints';
import {statusLabels} from './components';
import type {Club,Fixture} from './types';
const dateLabel=(date?:string)=>date?new Date(`${date}T12:00:00`).toLocaleDateString('es-ES',{weekday:'short',day:'numeric',month:'short',year:'numeric'}):'';
export function EmptyTie({date}:{date:string}){return <article className="card empty-tie"><span>{dateLabel(date)}</span><div><span className="empty-crest"/><b>Por determinar</b></div><small>vs</small><div><span className="empty-crest"/><b>Por determinar</b></div></article>}
export function FixtureCard({f,club,names}:{f:Fixture;club:Club;names:Record<string,string>}){
 const own=f.homeId===club.id||f.awayId===club.id;
 return <article className={`card competition-fixture ${own?'own-fixture':''}`}><div className="fixture-heading"><time dateTime={f.date}>{dateLabel(f.date)}</time><span className="pill">{statusLabels[f.status]??f.status}</span></div><VenueInfo venue={f.venue}/><div className="competition-score-row"><ClubCrest clubId={f.homeId} name={names[f.homeId]}/><strong>{names[f.homeId]}</strong><b>{f.status==='finished'?f.homeScore:'—'}</b></div><div className="competition-score-row"><ClubCrest clubId={f.awayId} name={names[f.awayId]}/><strong>{names[f.awayId]}</strong><b>{f.status==='finished'?f.awayScore:'—'}</b></div><ClassificationPoints value={f.classification} home={names[f.homeId]} away={names[f.awayId]}/>{f.homeShootout!==undefined&&<p className="shootout-result">Desempate a palos: {f.homeShootout}–{f.awayShootout}</p>}{own&&<Prepare fixture={f} club={club}/>}</article>;
}
