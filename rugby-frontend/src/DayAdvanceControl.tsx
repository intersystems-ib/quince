import {createContext,useCallback,useContext,useEffect,useId,useState} from 'react';
import type {ReactNode} from 'react';
import {Link,useLocation} from 'react-router-dom';
import {ArrowRight,CalendarDays} from 'lucide-react';
import {Action} from './components';
import type {Club} from './types';

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
 return <div className="topbar-calendar" aria-label="Calendario de la partida"><Link className="date calendar-link" to="/calendario" title="Abrir calendario"><CalendarDays size={16}/><time dateTime={club.date}>{new Date(`${club.date}T12:00:00`).toLocaleDateString('es-ES',{day:'numeric',month:'short',year:'numeric'})}</time></Link><div title={reason??'Avanzar un día'}><Action errorResetKey={`${club.id}:${club.version}:${location.key}`} path="/my-club/advance-day" body={{version:club.version,day:club.day}} disabled={!!reason} className="dark">Avanzar día <ArrowRight size={15}/></Action></div></div>;
}
