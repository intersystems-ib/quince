import {useState} from 'react';
import {Action,money} from './components';
import {monthlySalary} from './salary';
import type {Player} from './types';
export default function PlayerSale({player:p}:{player:Player}){
 const [price,setPrice]=useState(String(Math.round((p.transferListed?p.transferFee??0:(p.monthlyWage??monthlySalary(p.weeklyWage))*3)/100)));
 return <div className="player-sale-controls">{p.transferListed?<><span className="pill">En venta · {money(p.transferFee??0)}</span><Action key={`unlist-${p.version}`} path={`/players/${p.id}/sale`} body={{version:p.version,listed:false}} className="secondary">Retirar del mercado</Action></>:<><label>Precio de venta (€)<input aria-label={`Precio de venta de ${p.name}`} type="number" min="0" max="1000000" step="1" value={price} onChange={e=>setPrice(e.target.value)}/></label><Action key={`list-${p.version}`} path={`/players/${p.id}/sale`} body={{version:p.version,listed:true,transferFee:Number(price)*100}} disabled={!!p.retirementAnnounced||!price||!Number.isInteger(Number(price))||Number(price)<0||Number(price)>1000000} className="secondary">Poner a la venta</Action></>}</div>;
}
