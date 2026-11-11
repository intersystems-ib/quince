export default function CardBadge({color,count=1}:{color:'yellow'|'red';count?:number}){
 const label=`${count} ${color==='yellow'?(count===1?'tarjeta amarilla':'tarjetas amarillas'):(count===1?'tarjeta roja':'tarjetas rojas')}`;
 return count>0?<span className={`card-badge card-${color}`} role="img" title={label} aria-label={label}><i aria-hidden="true"/>{count>1&&<b>{count}</b>}</span>:null;
}
