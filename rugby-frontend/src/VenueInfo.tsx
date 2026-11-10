import {MapPin} from 'lucide-react';
import type {Stadium} from './types';

export default function VenueInfo({venue}:{venue?:Stadium}){
 return <p className="venue-info"><MapPin size={15} aria-hidden="true"/><span title={venue?.name?`${venue.name} · Aforo ${venue.capacity?.toLocaleString('es-ES')??'no disponible'}${venue.capacity?' personas':''}`:undefined}><strong>{venue?.name||'Campo no disponible'}</strong> · Aforo {venue?.capacity?`${venue.capacity.toLocaleString('es-ES')} personas`:'no disponible'}</span></p>;
}
