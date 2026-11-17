import { getLocale, localize, tr, useLocale } from "./i18n";
import type { Stadium } from './types';
export function stadiumImage(capacity?: number) {
    if (!capacity || capacity <= 0)
        return undefined;
    return capacity <= 1000 ? 'small' : capacity <= 2500 ? 'club' : capacity <= 5000 ? 'regional' : capacity <= 10000 ? 'city' : 'large';
}
export default function StadiumImage({ venue }: {
    venue?: Stadium;
}) {
    useLocale();
    const image = stadiumImage(venue?.capacity);
    return <figure className="stadium-illustration">{localize(image ? <img src={`/stadiums/${image}.jpg`} alt={tr(`Ilustración de un campo de rugby de aforo similar a ${venue?.name ?? 'este campo'}`)} width={1672} height={941}/> : <div className="stadium-image-unavailable">{tr("Imagen no disponible: aforo sin confirmar.")}</div>)}<figcaption><div><span>{tr("EL ESCENARIO")}</span><h3>{localize(venue?.name || 'Campo no disponible')}</h3><p>{tr("Aforo ")}{localize(venue?.capacity ? `${venue.capacity.toLocaleString(getLocale())} personas` : 'no disponible')}</p></div><small>{tr("Ilustraci\u00F3n orientativa seg\u00FAn aforo")}</small></figcaption></figure>;
}
