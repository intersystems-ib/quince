import { getLocale, localize, tr, useLocale } from "./i18n";
import { useClubName } from './clubNames';
import FixtureSummary from './FixtureSummary';
import VenueInfo from './VenueInfo';
import { useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { CalendarClock, ChevronRight, RefreshCw, Check } from 'lucide-react';
import { api } from './api';
import { requestId } from './requestId';
import { Energy, ErrorBox, Loading, penaltyPriorityLabels } from './components';
import type { Club, Fixture, Page, PreparationMeeting, PreparationReport, Tactic } from './types';
export const preparationPath = (fixtureId?: string) => `/staff?tab=preparacion${fixtureId ? `&fixture=${encodeURIComponent(fixtureId)}` : ''}`;
const dateLabel = (date: string) => new Date(date + 'T12:00:00').toLocaleDateString(getLocale(), { day: 'numeric', month: 'long' });
const styleLabels = { hands: 'A la mano', balanced: 'Equilibrado', kicking: 'Al pie' };
const tempoLabels = { slow: 'Pausado', normal: 'Normal', fast: 'Alto' };
const defenseLabels = { low: 'Baja', normal: 'Normal', high: 'Alta' };
export const tacticText = (t: Tactic) => `${styleLabels[t.style]} · Ritmo ${tempoLabels[t.tempo]} · Presión ${defenseLabels[t.defense]} · Golpes: ${penaltyPriorityLabels[t.penaltyPriority ?? 'auto']}`;
function useMeetings(club: Club) {
    return useQuery({ queryKey: ['preparations', club.id, club.date], queryFn: () => api<{
            items: PreparationMeeting[];
        }>('/my-club/preparations') });
}
function upcoming(items: PreparationMeeting[], day: number) { return items.filter(m => !m.closed && m.matchDay >= day).sort((a, b) => a.day - b.day || a.fixtureId.localeCompare(b.fixtureId))[0]; }
export function PreparationTask({ club }: {
    club: Club;
}) {
    useLocale();
    const clubName = useClubName(), q = useMeetings(club), meeting = upcoming(q.data?.items ?? [], club.day);
    return <Link to={preparationPath(meeting?.fixtureId)}><span className="task-icon purple"><CalendarClock size={20}/></span><div><strong>{tr("Reuni\u00F3n con el cuerpo t\u00E9cnico")}</strong><p>{localize(meeting ? `${clubName(meeting.opponentId, meeting.opponentName)} · ${meeting.available ? 'Informe disponible' : meeting.preparing ? 'Informe en preparación' : dateLabel(meeting.date)}` : 'Preparación del próximo rival.')}</p></div><ChevronRight size={18}/></Link>;
}
export default function PreparationPanel({ club, fixtureId }: {
    club: Club;
    fixtureId?: string;
}) {
    useLocale();
    const clubName = useClubName(), q = useMeetings(club);
    if (q.isLoading)
        return <Loading />;
    if (q.error)
        return <ErrorBox error={q.error}/>;
    const requested = fixtureId ? q.data?.items.find(m => m.fixtureId === fixtureId) : undefined;
    const meeting = requested && (!requested.closed || requested.matchDay > club.day) ? requested : upcoming(q.data?.items ?? [], club.day) ?? requested;
    if (!meeting)
        return <section className="card preparation-waiting"><CalendarClock size={26}/><h3>{tr("No hay una reuni\u00F3n pendiente")}</h3><p className="muted">{tr("Las reuniones se programan dos d\u00EDas antes de los partidos oficiales.")}</p></section>;
    if (!meeting.available)
        return <section className="card preparation-waiting"><CalendarClock size={26}/><h3>{tr("Preparaci\u00F3n frente a ")}{localize(clubName(meeting.opponentId, meeting.opponentName))}</h3><p>{localize(meeting.closed ? 'La reunión de preparación ha finalizado.' : meeting.preparing ? 'El cuerpo técnico está trabajando en la elaboración del informe.' : `La preparación del informe comenzará después del partido anterior${meeting.preparationStartDate ? `, a partir del ${dateLabel(meeting.preparationStartDate)}` : ''}.`)}</p><p className="muted">{tr("Reuni\u00F3n: ")}{localize(dateLabel(meeting.date))}{tr(" \u00B7 Partido: ")}{localize(dateLabel(meeting.matchDate))}</p><Link className="button secondary" to="/calendario">{tr("Ver calendario")}</Link></section>;
    return <OpponentPreparation key={`${meeting.fixtureId}-${club.date}`} fixtureId={meeting.fixtureId}/>;
}
function OpponentPreparation({ fixtureId }: {
    fixtureId: string;
}) {
    useLocale();
    const clubName = useClubName(), q = useQuery({ queryKey: ['preparation', fixtureId], queryFn: () => api<PreparationReport>(`/preparations/${fixtureId}`), retry: false });
    if (q.isLoading)
        return <Loading />;
    if (q.error)
        return <ErrorBox error={q.error}/>;
    const r = { ...q.data!, ownName: clubName(q.data!.clubId, q.data!.ownName), opponentName: clubName(q.data!.opponentId, q.data!.opponentName) };
    return <><div className="preparation-report-heading"><div><div className="eyebrow">{tr("REUNI\u00D3N CON EL CUERPO T\u00C9CNICO")}</div><h2>{tr("Preparaci\u00F3n del rival")}</h2><p>{tr("Partido del ")}{localize(dateLabel(r.meeting.matchDate))}</p></div><button className="button secondary" disabled={q.isFetching} onClick={() => void q.refetch()}><RefreshCw size={16}/>{tr("Actualizar informe")}</button></div>
 <PreparationFixture report={r}/>
 {localize(r.lastApplied && (r.lastApplied.outdated || r.lastApplied.tacticChanged) && <p className="notice" role="status">{tr("La convocatoria o la t\u00E1ctica han cambiado. Actualiza el informe antes de aplicar la recomendaci\u00F3n.")}</p>)}
 <section className="card preparation-comparison" aria-label={tr("Análisis del rival")}><div className="card-top"><h3>{tr("An\u00E1lisis del rival")}</h3><span className="tiny-tag">{tr("ENERG\u00CDA Y MORAL INCLUIDAS")}</span></div><div className="preparation-analysis-layout"><div className="preparation-analysis-main"><div className="table-wrap"><table aria-label={tr("Comparación de aspectos del juego")}><thead><tr><th>{tr("Aspecto")}</th><th>{r.ownName}</th><th>{tr("Rival estimado")}</th></tr></thead><tbody>{localize(r.aspects.map(a => <tr key={a.id}><th scope="row">{localize(a.name)}<small>{localize(a.group === 'forwards' ? 'Delanteros' : a.group === 'backs' ? 'Tres cuartos' : 'XV completo')}</small></th><td className={a.delta > 2 ? 'positive' : ''}><strong>{localize(Math.round(a.own))}</strong></td><td className={a.delta < -2 ? 'preparation-rival-edge' : ''}><strong>{localize(Math.round(a.opponent))}</strong></td></tr>))}</tbody></table></div><div className="preparation-units">{localize((['forwards', 'backs'] as const).map(g => <div key={g}><h4>{localize(g === 'forwards' ? 'Delanteros' : 'Tres cuartos')}</h4><p>{localize(r.groups.own[g].count)}{tr(" jugadores \u00B7 Media ")}{localize(Math.round(r.groups.own[g].average))}</p><label>{tr("Energ\u00EDa")}<Energy value={r.groups.own[g].energy}/></label><label>{tr("Moral")}<Energy value={r.groups.own[g].morale}/></label></div>))}</div><p className="muted">{tr("Las cifras del rival son estimaciones. Su alineaci\u00F3n y su t\u00E1ctica pueden cambiar antes del encuentro.")}</p></div>
 <aside className="preparation-findings"><section><h3>{tr("Nuestras ventajas")}</h3>{localize(r.advantages.length ? <ul>{localize(r.advantages.map(t => <li key={t}>{localize(t)}</li>))}</ul> : <p className="muted">{tr("No se detectan ventajas claras.")}</p>)}</section><section><h3>{tr("Riesgos a vigilar")}</h3>{localize(r.risks.length ? <ul>{localize(r.risks.map(t => <li key={t}>{localize(t)}</li>))}</ul> : <p className="muted">{tr("No se detectan desventajas claras.")}</p>)}</section><PreparationDecision key={`${r.fixtureId}-${r.reportToken}-${r.lineupVersion}`} report={r}/></aside></div></section>
 </>;
}
function PreparationFixture({ report: r }: {
    report: PreparationReport;
}) {
    useLocale();
    const fixtures = useQuery({ queryKey: ['fixtures'], queryFn: () => api<Page<Fixture>>('/my-club/fixtures?limit=500') });
    const fixture = fixtures.data?.items.find(f => f.id === r.fixtureId);
    return <section className="card calendar-fixture preparation-fixture" aria-label={tr("Partido analizado")}>{localize(fixtures.isLoading ? <Loading /> : fixtures.error ? <ErrorBox error={fixtures.error}/> : fixture ? <><FixtureSummary fixture={fixture} clubId={r.clubId} names={{ [r.clubId]: r.ownName, [r.opponentId]: r.opponentName }}/><VenueInfo venue={fixture.venue}/></> : <p className="muted">{tr("El partido ya no est\u00E1 disponible en el calendario.")}</p>)}</section>;
}
function PreparationDecision({ report: r }: {
    report: PreparationReport;
}) {
    useLocale();
    const qc = useQueryClient(), [key, setKey] = useState(requestId), tactic = r.recommendation.tactic;
    const mutation = useMutation({ mutationFn: () => api<PreparationReport>(`/preparations/${r.fixtureId}/apply`, 'POST', { lineupId: r.lineupId, lineupVersion: r.lineupVersion, reportToken: r.reportToken, choice: 'main' }, key), onSuccess: () => { setKey(requestId()); void qc.invalidateQueries(); } });
    const applied = r.lastApplied && !r.lastApplied.outdated && !r.lastApplied.tacticChanged;
    return <section className="preparation-recommendation"><h3>{tr("Propuesta t\u00E9cnica")}</h3><ul className="preparation-tactic-list">{localize([['Construcción de juego', styleLabels[tactic.style]], ['Ritmo', tempoLabels[tactic.tempo]], ['Presión defensiva', defenseLabels[tactic.defense]], ['Prioridad en golpes', penaltyPriorityLabels[tactic.penaltyPriority ?? 'auto']]].map(([label, value]) => <li key={label}><strong>{localize(label)}{tr(":")}</strong> {localize(value)}{tr(".")}</li>))}</ul>
 {localize(!r.ready && <div className="notice" role="alert"><p>{tr("Revisa la convocatoria antes de aplicar la recomendaci\u00F3n.")}</p>{localize(r.validationErrors.length > 0 && <ul>{localize(r.validationErrors.map(e => <li key={e}>{localize(e)}</li>))}</ul>)}<Link to="/alineacion">{tr("Editar alineaci\u00F3n \u2192")}</Link></div>)}
 {localize(mutation.error && <ErrorBox error={mutation.error} onDismiss={() => mutation.reset()}/>)}
 <p className="preparation-reason">{localize(r.recommendation.reason)}</p>
 <button className="button dark full" disabled={!r.ready || mutation.isPending || !!applied} onClick={() => mutation.mutate()}>{localize(mutation.isPending ? 'Aplicando…' : 'Aplicar recomendación')}<Check size={16}/></button>
 {localize(applied && <p className="positive preparation-applied" role="status">{tr("Recomendaci\u00F3n aplicada.")}</p>)}</section>;
}
