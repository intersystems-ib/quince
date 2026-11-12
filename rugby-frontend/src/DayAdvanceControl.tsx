import {createContext,useCallback,useContext,useEffect,useId,useState} from 'react';
import type {ReactNode} from 'react';
import {Link,useLocation,useNavigate} from 'react-router-dom';
import {useQuery} from '@tanstack/react-query';
import {ArrowRight,CalendarDays} from 'lucide-react';
import {Action,ErrorBox} from './components';
import {api} from './api';
import {pendingFixture} from './matchDay';
import type {Club,Fixture,Match,Page} from './types';

type AdvanceState={blocks:Record<string,string>;setBlock:(id:string,reason:string|null)=>void};
const AdvanceContext=createContext<AdvanceState>({blocks:{},setBlock:()=>{}});
export function DayAdvanceProvider({children}:{children:ReactNode}){
 const [blocks,setBlocks]=useState<Record<string,string>>({});
 const setBlock=useCallback((id:string,reason:string|null)=>setBlocks(old=>{
  if(old[id]===(reason??undefined))return old;
  const next={...old};if(reason)next[id]=reason;else delete next[id];return next;
 }),[]);
 return <AdvanceContext.Provider value={{blocks,setBlock}}>{children}</AdvanceContext.Provider>;
}
export function useDayAdvanceBlock(reason:string|null){
 const id=useId(),{setBlock}=useContext(AdvanceContext);
 useEffect(()=>{setBlock(id,reason);return()=>setBlock(id,null);},[id,reason,setBlock]);
}
export default function DayAdvanceControl({club}:{club:Club}){
 const {blocks}=useContext(AdvanceContext),reason=Object.values(blocks)[0],location=useLocation();
 const navigate=useNavigate();
 const fixtures=useQuery({queryKey:['match-day-fixtures',club.id,club.day],queryFn:()=>api<Page<Fixture>>('/my-club/fixtures?limit=500'),refetchInterval:q=>pendingFixture(q.state.data?.items??[],club.day)?3000:false});
 const pending=pendingFixture(fixtures.data?.items??[],club.day);
 return <div className="topbar-calendar" aria-label="Calendario de la partida"><Link className="date calendar-link" to="/calendario" title="Abrir calendario"><CalendarDays size={16}/><time dateTime={club.date}>{new Date(`${club.date}T12:00:00`).toLocaleDateString('es-ES',{day:'numeric',month:'short',year:'numeric'})}</time></Link>{pending?(pending.matchId?<Link className="button dark" to={`/partido/${pending.matchId}`}>Ir al partido <ArrowRight size={15}/></Link>:<Action key={pending.id} path="/matches" body={{fixtureId:pending.id,lineupId:`${club.id}-default`}} onSuccess={result=>navigate(`/partido/${(result as Match).id}`)} className="dark">Ir al partido <ArrowRight size={15}/></Action>):<div className="action-wrap" title={reason??'Avanzar un día'}><Action errorResetKey={`${club.id}:${club.version}:${location.key}`} path="/my-club/advance-day" body={{version:club.version,day:club.day}} disabled={!!reason||fixtures.isLoading||fixtures.isError} className="dark">Avanzar día <ArrowRight size={15}/></Action>{fixtures.error&&<ErrorBox error={fixtures.error}/>}</div>}</div>;
}
