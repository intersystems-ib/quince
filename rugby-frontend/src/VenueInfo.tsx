import { getLocale, localize, tr, useLocale } from "./i18n";
import { MapPin } from 'lucide-react';
import type { Stadium } from './types';
export default function VenueInfo({ venue }: {
    venue?: Stadium;
}) {
    useLocale();
    return <p className="venue-info"><MapPin size={15} aria-hidden="true"/><span title={tr(venue?.name ? `${venue.name} · Aforo ${venue.capacity?.toLocaleString(getLocale()) ?? 'no disponible'}${venue.capacity ? ' personas' : ''}` : undefined)}><strong>{localize(venue?.name || 'Campo no disponible')}</strong>{tr(" \u00B7 Aforo ")}{localize(venue?.capacity ? `${venue.capacity.toLocaleString(getLocale())} personas` : 'no disponible')}</span></p>;
}
