import { getLocale, localize, tr, useLocale } from "./i18n";
import { HeartPulse } from 'lucide-react';
import Metric from './Metric';
import { useQuery } from '@tanstack/react-query';
import { api } from './api';
import type { Injury, InjuryType, Player } from './types';
const date = (value: string) => new Date(`${value}T12:00:00`).toLocaleDateString(getLocale());
export const injuryText = (injury: Injury) => `${injury.name} · Grado ${injury.grade} · ${injury.remainingWeeks ?? injury.weeks} sem. · Alta ${date(injury.expectedReturn)}`;
export function InjuryMark({ player }: {
    player: Pick<Player, 'name' | 'injury'> | undefined;
}) {
    useLocale();
    if (!player?.injury)
        return null;
    const label = `Lesionado: ${player.name}. ${injuryText(player.injury)}`;
    return <span className="injury-mark" role="img" aria-label={tr(label)} title={tr(label)}><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M8 2h8v6h6v8h-6v6H8v-6H2V8h6Z" fill="currentColor"/></svg></span>;
}
export default function InjuryStatus({ player }: {
    player: Player;
}) {
    useLocale();
    if (player.retired)
        return <span className="pill">{tr("Retirado")}</span>;
    if (player.injury)
        return <span className={`injury-status severity-${player.injury.severity}`}><strong>{player.injury.name}</strong><small>{tr("Grado ")}{localize(player.injury.grade)}{tr(" \u00B7 ")}{localize(player.injury.remainingWeeks ?? player.injury.weeks)}{tr(" sem. restantes")}</small><small>{tr("Alta ")}{localize(date(player.injury.expectedReturn))}</small></span>;
    return <span className={`pill ${player.available ? 'available' : 'unavailable'}`}>{localize(player.available ? 'Disponible' : 'En recuperación')}</span>;
}
export function InjuryPanel({ player }: {
    player: Player;
}) {
    useLocale();
    const injury = player.injury, history = player.injuryHistory ?? [];
    return <Metric icon={injury ? <InjuryMark player={player}/> : <HeartPulse />} label={"Estado físico y lesiones"} value={player.retired ? 'Retirado' : injury ? injury.name : player.available ? 'Disponible' : 'No disponible'} note={injury ? <><span>{tr("Grado ")}{localize(injury.grade)}{tr(" \u00B7 ")}{localize(injury.severity)}{tr(" \u00B7 ")}{localize(injury.remainingWeeks ?? injury.weeks)}{tr(" sem. restantes")}</span><span>{tr("Alta prevista: ")}{localize(date(injury.expectedReturn))}</span></> : player.retired ? 'Fuera de competición' : player.available ? 'Sin lesión activa' : player.unavailableReason ?? 'En recuperación'} tag="SALUD" className="player-info-metric injury-metric">{localize(injury && <details className="metric-details"><summary>{tr("Detalle de la lesi\u00F3n")}</summary><p>{tr("Baja inicial: ")}{localize(injury.weeks)} {localize(injury.weeks === 1 ? 'semana' : 'semanas')}{tr(" \u00B7 Desde ")}{localize(date(injury.startedOn))}{tr(" \u00B7 ")}{localize(injury.source === 'match' ? 'Partido' : 'Entrenamiento')}</p><p>{localize(injury.remainingDays ?? injury.weeks * 7)}{tr(" d\u00EDas de baja pendientes.")}</p></details>)}{localize(history.length > 0 && <details className="metric-details"><summary>{tr("Historial de lesiones \u00B7 ")}{localize(history.length)}</summary><ul>{localize([...history].reverse().map(i => <li key={i.id}>{localize(i.name)}{tr(" \u00B7 Grado ")}{localize(i.grade)}{tr(" \u00B7 ")}{localize(i.weeks)}{tr(" semanas \u00B7 ")}{localize(date(i.startedOn))}{tr(" \u2014 ")}{localize(date(i.recoveredOn ?? i.expectedReturn))}</li>))}</ul></details>)}</Metric>;
}
export function InjuryCatalog() {
    useLocale();
    const query = useQuery({ queryKey: ['injury-types'], queryFn: () => api<{
            items: InjuryType[];
        }>('/injury-types') });
    return <details className="card injury-catalog"><summary>{tr("Lesiones y semanas de recuperaci\u00F3n")}</summary>{localize(query.isLoading ? <p>{tr("Cargando lesiones\u2026")}</p> : query.error ? <p>{tr("No se ha podido cargar la lista de lesiones.")}</p> : <div className="table-wrap"><table><thead><tr><th>{tr("Lesi\u00F3n")}</th><th>{tr("Grado")}</th><th>{tr("Gravedad")}</th><th>{tr("Semanas")}</th></tr></thead><tbody>{localize(query.data?.items.map(i => <tr key={i.id}><td>{localize(i.name)}</td><td>{localize(i.grade)}</td><td>{localize(i.severity)}</td><td>{localize(i.minWeeks === i.maxWeeks ? i.minWeeks : `${i.minWeeks}–${i.maxWeeks}`)}</td></tr>))}</tbody></table></div>)}</details>;
}
