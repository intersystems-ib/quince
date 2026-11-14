import {preparationPath} from './OpponentPreparation';
import {createContext,useCallback,useContext,useEffect,useId,useRef,useState} from 'react';
import type {ReactNode} from 'react';
import {Link,useLocation,useNavigate} from 'react-router-dom';
import {useQuery,useQueryClient} from '@tanstack/react-query';
import {ArrowRight,FastForward,LoaderCircle,Play,Square,X} from 'lucide-react';
import {Action,ErrorBox} from './components';
import {api,getGameId} from './api';
import {requestId} from './requestId';
import {advanceUntilEvent} from './advanceUntilEvent';
import {advanceWithRefresh} from './advanceDay';
import {pendingFixture} from './matchDay';
import type {Club,Fixture,Match,Page,PreparationMeeting,SeasonEvent} from './types';

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
 const navigate=useNavigate(),qc=useQueryClient(),[running,setRunning]=useState(false),[manualPending,setManualPending]=useState(false),[stopping,setStopping]=useState(false),[autoError,setAutoError]=useState<unknown>(),[message,setMessage]=useState(''),active=useRef(false),mounted=useRef(true),reasonRef=useRef(reason);
 reasonRef.current=reason;
 useEffect(()=>{mounted.current=true;return()=>{mounted.current=false;active.current=false;};},[]);
 async function nextEvent(){
  if(active.current||running||manualPending||reason)return;
  const gameId=getGameId();active.current=true;setRunning(true);setStopping(false);setAutoError(undefined);setMessage('');
  try{
   const result=await advanceUntilEvent(club,{
    cancelled:()=>!active.current||!mounted.current||getGameId()!==gameId||!!reasonRef.current,
    readSchedule:async()=>{const [f,m,s]=await Promise.all([api<Page<Fixture>>('/my-club/fixtures?limit=500'),api<{items:PreparationMeeting[]}>('/my-club/preparations'),api<{items:SeasonEvent[]}>('/my-club/season-events')]);return {fixtures:f.items,meetings:m.items,seasonEvents:s.items};},
    advance:current=>{const key=requestId();return advanceWithRefresh(current,version=>api<Club>('/my-club/advance-day','POST',{version,day:current.day},key),()=>api<Club>('/my-club'));},
    onDay:next=>{if(mounted.current&&getGameId()===gameId){qc.setQueryData(['club'],next);void qc.invalidateQueries({refetchType:'none'});}},
   });
   if(mounted.current&&getGameId()===gameId){
    const messages={season:result.seasonEvent?.title??'Cambio de temporada.',meeting:'',match:'Día de partido.',cancelled:reasonRef.current??'Avance detenido.',empty:'No hay más eventos programados.',limit:'Avance detenido tras 365 días.'};
    setMessage(messages[result.reason]);
    if(result.reason==='season')navigate('/calendario');
    if(result.reason==='meeting'&&result.fixtureId)navigate(preparationPath(result.fixtureId));
   }
  }catch(e){if(mounted.current&&getGameId()===gameId)setAutoError(e);}
  finally{active.current=false;if(mounted.current){setRunning(false);setStopping(false);}if(getGameId()===gameId)void qc.invalidateQueries();}
 }

 useEffect(()=>{setAutoError(undefined);},[club.id,club.version,location.key]);
 async function singleDay(){
  if(running||manualPending||reason)return;
  const gameId=getGameId(),key=requestId();setManualPending(true);setAutoError(undefined);setMessage('');
  try{const next=await advanceWithRefresh(club,version=>api<Club>('/my-club/advance-day','POST',{version,day:club.day},key),()=>api<Club>('/my-club'));if(mounted.current&&getGameId()===gameId){qc.setQueryData(['club'],next);void qc.invalidateQueries();}}
  catch(e){if(mounted.current&&getGameId()===gameId)setAutoError(e);}
  finally{if(mounted.current)setManualPending(false);}
 }
 const fixtures=useQuery({queryKey:['match-day-fixtures',club.id,club.day],queryFn:()=>api<Page<Fixture>>('/my-club/fixtures?limit=500'),refetchInterval:q=>pendingFixture(q.state.data?.items??[],club.day)?3000:false});
 const pending=pendingFixture(fixtures.data?.items??[],club.day);
 return <div className="topbar-calendar" aria-label="Calendario de la partida"><Link className="date calendar-link" to="/calendario" title="Abrir calendario"><time dateTime={club.date}>{new Date(`${club.date}T12:00:00`).toLocaleDateString('es-ES',{day:'numeric',month:'short',year:'numeric'})}</time></Link>{running?<button className="button dark" disabled={stopping} onClick={()=>{active.current=false;setStopping(true);}}><Square size={14}/>{stopping?'Deteniendo…':'Detener avance'}</button>:pending?(pending.matchId?<Link className="button dark" to={`/partido/${pending.matchId}`}>Ir al partido <ArrowRight size={15}/></Link>:<Action key={pending.id} path="/matches" body={{fixtureId:pending.id,lineupId:pending.preparationLineupId??`${club.id}-default`}} onSuccess={result=>navigate(`/partido/${(result as Match).id}`)} className="dark">Ir al partido <ArrowRight size={15}/></Action>):<div className="action-wrap" title={reason??'Avanzar un día'}><button className="button dark day-advance-icon" aria-label="Avanzar día" aria-busy={manualPending} title={reason??(manualPending?'Avanzando…':'Avanzar día')} disabled={running||manualPending||!!reason||fixtures.isLoading||fixtures.isError} onClick={()=>void singleDay()}>{manualPending?<LoaderCircle size={18} className="spin" aria-hidden="true"/>:<Play size={18} aria-hidden="true"/>}</button><button className="button secondary auto-advance-button day-advance-icon" aria-label="Próximo evento" disabled={running||manualPending||!!reason||fixtures.isLoading||fixtures.isError} onClick={()=>void nextEvent()} title={reason??'Próximo evento'}><FastForward size={18} aria-hidden="true"/></button>{fixtures.error&&<ErrorBox error={fixtures.error}/>}</div>}{!!autoError&&<div className="auto-advance-feedback"><ErrorBox error={autoError} onDismiss={()=>setAutoError(undefined)}/></div>}{message&&<div className="auto-advance-feedback" role="status"><span>{message}</span><button className="icon-button" aria-label="Cerrar aviso de avance" onClick={()=>setMessage('')}><X size={14}/></button></div>}</div>;
}
