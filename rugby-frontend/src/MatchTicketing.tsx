import { getLocale, localize, tr, useLocale } from "./i18n";
import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { api } from './api';
import { Action, ErrorBox, Loading } from './components';
import type { Match, MatchEconomy } from './types';
const money = (value: number) => new Intl.NumberFormat(getLocale(), { style: 'currency', currency: 'EUR', minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(value / 100);
export default function MatchTicketing({ match: m }: {
    match: Match;
}) {
    useLocale();
    const q = useQuery({ queryKey: ['ticketing', m.id, m.version], queryFn: () => api<{
            forecast: MatchEconomy;
            editable: boolean;
        }>(`/matches/${m.id}/ticketing`) });
    if (q.isLoading)
        return <Loading />;
    if (q.error)
        return <ErrorBox error={q.error}/>;
    return <TicketDetails key={q.data!.forecast.ticketPrice} match={m} data={q.data!}/>;
}
function TicketDetails({ match: m, data }: {
    match: Match;
    data: {
        forecast: MatchEconomy;
        editable: boolean;
    };
}) {
    useLocale();
    const f = data.forecast, [price, setPrice] = useState(String(f.ticketPrice / 100)), cents = Math.round(Number(price) * 100), valid = price.trim() !== '' && Number.isFinite(cents) && cents >= 0 && cents <= 5000;
    return <div className="match-ticketing">{localize(f.pricing && <div className="ticket-recommendation"><div><small>{tr("PRECIO RECOMENDADO")}</small><strong>{localize(money(f.pricing.price))}</strong><span className="pill">{tr("Inter\u00E9s ")}{localize(f.pricing.interest.toLocaleLowerCase())}</span></div><p>{localize(f.pricing.reasons.join(' · '))}</p></div>)}{localize(data.editable ? <div className="ticketing-controls"><label>{tr("Precio de entrada (\u20AC)")}<input type="number" min="0" max="50" step="0.01" value={price} onChange={e => setPrice(e.target.value)}/></label><Action method="PUT" path={`/matches/${m.id}/ticketing`} body={{ version: m.version, ticketPrice: cents }} disabled={!valid || cents === f.ticketPrice} className="secondary">{tr("Guardar precio")}</Action></div> : <p>{tr("Precio fijado por el club local: ")}<strong>{localize(money(f.ticketPrice))}</strong></p>)}<p>{tr("Previsi\u00F3n: ")}<strong>{localize(f.attendance.toLocaleString(getLocale()))}{tr(" asistentes")}</strong>{tr(" \u00B7 Taquilla ")}{localize(money(f.ticketRevenue))}</p>{localize(m.stage === 'friendly' && <small>{tr("La taquilla se reparte al 50 % entre ambos clubes.")}</small>)}</div>;
}
