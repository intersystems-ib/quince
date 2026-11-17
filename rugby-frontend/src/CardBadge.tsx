import { localize, tr, useLocale } from "./i18n";
export default function CardBadge({ color, count = 1 }: {
    color: 'yellow' | 'red';
    count?: number;
}) {
    useLocale();
    const label = `${count} ${color === 'yellow' ? (count === 1 ? 'tarjeta amarilla' : 'tarjetas amarillas') : (count === 1 ? 'tarjeta roja' : 'tarjetas rojas')}`;
    return count > 0 ? <span className={`card-badge card-${color}`} role="img" title={tr(label)} aria-label={tr(label)}><i aria-hidden="true"/>{localize(count > 1 && <b>{localize(count)}</b>)}</span> : null;
}
