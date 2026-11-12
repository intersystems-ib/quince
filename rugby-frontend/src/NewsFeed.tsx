import {useState} from 'react';
import {useQuery} from '@tanstack/react-query';
import {Link} from 'react-router-dom';
import {Activity,Briefcase,UserPlus,Flag} from 'lucide-react';
import {api} from './api';
import {ErrorBox,Loading} from './components';
import ClubCrest from './ClubCrest';
import type {Page} from './types';

type News={id:string;type:'injury'|'playerSigning'|'staffSigning'|'retirement';date:string;clubId:string;clubName:string;personName:string;playerId:string;title:string;text:string;category?:string;role?:string};
const labels={injury:'Lesión',playerSigning:'Fichaje',staffSigning:'Empleado',retirement:'Retirada'};
export default function NewsFeed({date}:{date:string}){
 const [page,setPage]=useState(0);
 const q=useQuery({queryKey:['news',date,page],queryFn:()=>api<Page<News>&{fromDate:string;toDate:string}>(`/news?offset=${page*10}&limit=10`)});
 return <section className="card club-news"><div className="card-top"><h3>Últimas noticias</h3><span className="tiny-tag">ÚLTIMOS 7 DÍAS</span></div>{q.isLoading?<Loading/>:q.error?<ErrorBox error={q.error}/>:q.data&&<>{!q.data.total?<p className="empty">No hay noticias en los últimos siete días.</p>:<ul className="club-news-list">{q.data.items.map(n=><li key={n.id}><ClubCrest clubId={n.clubId} name={n.clubName}/><div><div className={`news-meta news-${n.type}`}>{n.type==='retirement'?<Flag size={13}/>:n.type==='injury'?<Activity size={13}/>:n.type==='playerSigning'?<UserPlus size={13}/>:<Briefcase size={13}/>}<span>{labels[n.type]}{n.category==='academy'?' · Cantera':''}</span><time dateTime={n.date}>{new Date(n.date+'T12:00:00').toLocaleDateString('es-ES',{day:'numeric',month:'short'})}</time></div><h4>{n.playerId?<Link to={`/jugadores/${n.playerId}`}>{n.title}</Link>:n.title}</h4><p>{n.clubName} · {n.text}</p></div></li>)}</ul>}{q.data.total>10&&<div className="toolbar news-pagination"><button className="button secondary" disabled={!page} onClick={()=>setPage(page-1)}>Anterior</button><span>Página {page+1} de {Math.ceil(q.data.total/10)}</span><button className="button secondary" disabled={(page+1)*10>=q.data.total} onClick={()=>setPage(page+1)}>Siguiente</button></div>}</>}</section>;
}
