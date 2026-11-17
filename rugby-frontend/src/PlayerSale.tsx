import { localize, tr, useLocale } from "./i18n";
import { useState } from 'react';
import { Action, money } from './components';
import { monthlySalary } from './salary';
import type { Player } from './types';
export default function PlayerSale({ player: p }: {
    player: Player;
}) {
    useLocale();
    const [price, setPrice] = useState(String(Math.round((p.transferListed ? p.transferFee ?? 0 : (p.monthlyWage ?? monthlySalary(p.weeklyWage)) * 3) / 100)));
    return <div className="player-sale-controls">{localize(p.transferListed ? <><span className="pill">{tr("En venta \u00B7 ")}{localize(money(p.transferFee ?? 0))}</span><Action key={`unlist-${p.version}`} path={`/players/${p.id}/sale`} body={{ version: p.version, listed: false }} className="secondary">{tr("Retirar del mercado")}</Action></> : <><label>{tr("Precio de venta (\u20AC)")}<input aria-label={tr(`Precio de venta de ${p.name}`)} type="number" min="0" max="1000000" step="1" value={price} onChange={e => setPrice(e.target.value)}/></label><Action key={`list-${p.version}`} path={`/players/${p.id}/sale`} body={{ version: p.version, listed: true, transferFee: Number(price) * 100 }} disabled={!!p.retirementAnnounced || !price || !Number.isInteger(Number(price)) || Number(price) < 0 || Number(price) > 1000000} className="secondary">{tr("Poner a la venta")}</Action></>)}</div>;
}
