import type {Stadium} from './types';

export function stadiumImage(capacity?:number){
 if(!capacity||capacity<=0)return undefined;
 return capacity<=1000?'small':capacity<=2500?'club':capacity<=5000?'regional':capacity<=10000?'city':'large';
}
export default function StadiumImage({venue}:{venue?:Stadium}){
 const image=stadiumImage(venue?.capacity);
 return <figure className="stadium-illustration">{image?<img src={`/stadiums/${image}.jpg`} alt={`Ilustración de un campo de rugby de aforo similar a ${venue?.name??'este campo'}`} width={1672} height={941}/>:<div className="stadium-image-unavailable">Imagen no disponible: aforo sin confirmar.</div>}<figcaption><div><span>EL ESCENARIO</span><h3>{venue?.name||'Campo no disponible'}</h3><p>Aforo {venue?.capacity?`${venue.capacity.toLocaleString('es-ES')} personas`:'no disponible'}</p></div><small>Ilustración orientativa según aforo</small></figcaption></figure>;
}
