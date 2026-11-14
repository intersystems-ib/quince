import {useState} from 'react';
import {useQuery} from '@tanstack/react-query';
import {api} from './api';
import {Action,ErrorBox,Loading} from './components';
import type {Match,MatchEconomy} from './types';
const money=(value:number)=>new Intl.NumberFormat('es-ES',{style:'currency',currency:'EUR',minimumFractionDigits:2,maximumFractionDigits:2}).format(value/100);
export default function MatchTicketing({match:m}:{match:Match}){
 const q=useQuery({queryKey:['ticketing',m.id,m.version],queryFn:()=>api<{forecast:MatchEconomy;editable:boolean}>(`/matches/${m.id}/ticketing`)});
 if(q.isLoading)return <Loading/>;if(q.error)return <ErrorBox error={q.error}/>;return <TicketDetails key={q.data!.forecast.ticketPrice} match={m} data={q.data!}/>;
}
function TicketDetails({match:m,data}:{match:Match;data:{forecast:MatchEconomy;editable:boolean}}){
 const f=data.forecast,[price,setPrice]=useState(String(f.ticketPrice/100)),cents=Math.round(Number(price)*100),valid=price.trim()!==''&&Number.isFinite(cents)&&cents>=0&&cents<=5000;
 return <div className="match-ticketing">{f.pricing&&<div className="ticket-recommendation"><div><small>PRECIO RECOMENDADO</small><strong>{money(f.pricing.price)}</strong><span className="pill">Interés {f.pricing.interest.toLocaleLowerCase()}</span></div><p>{f.pricing.reasons.join(' · ')}</p></div>}{data.editable?<div className="ticketing-controls"><label>Precio de entrada (€)<input type="number" min="0" max="50" step="0.01" value={price} onChange={e=>setPrice(e.target.value)}/></label><Action method="PUT" path={`/matches/${m.id}/ticketing`} body={{version:m.version,ticketPrice:cents}} disabled={!valid||cents===f.ticketPrice} className="secondary">Guardar precio</Action></div>:<p>Precio fijado por el club local: <strong>{money(f.ticketPrice)}</strong></p>}<p>Previsión: <strong>{f.attendance.toLocaleString('es-ES')} asistentes</strong> · Taquilla {money(f.ticketRevenue)}</p>{m.stage==='friendly'&&<small>La taquilla se reparte al 50 % entre ambos clubes.</small>}</div>;
}
