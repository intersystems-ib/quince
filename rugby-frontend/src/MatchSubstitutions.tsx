import {useEffect,useRef,useState} from 'react';
import {ArrowLeftRight,Cross,LoaderCircle} from 'lucide-react';
import {ErrorBox,attrLabels,positions} from './components';
import {useMutation,useQueryClient} from '@tanstack/react-query';
import {api} from './api';
import {requestId} from './requestId';
import type {Command,Snapshot} from './types';

const canLeave=(p:Snapshot)=>p.status==='field'||(p.status==='injured'&&!p.substituted);
const canEnter=(p:Snapshot)=>p.status==='bench'&&!p.injury;
const average=(p:Snapshot)=>{const values=Object.keys(attrLabels).map(k=>p.attributes[k]).filter(Number.isFinite);return values.length?Math.round(values.reduce((sum,v)=>sum+v,0)/values.length):0;};

export default function MatchSubstitutions({id,players,used,commands}:{id:string;players:Snapshot[];used:number;commands:Command[]}){
 const [outId,setOut]=useState(''),[inId,setIn]=useState(''),[sent,setSent]=useState<Command>(),[rejected,setRejected]=useState('');
 const qc=useQueryClient(),requestKey=useRef(requestId());
 const submit=useMutation({mutationFn:()=>api<Command>(`/matches/${id}/commands`,'POST',{type:'substitution',outId,inId},requestKey.current),onSuccess:command=>{setSent(command);setRejected('');void qc.invalidateQueries({queryKey:['commands',id]});void qc.invalidateQueries({queryKey:['match',id]});}});
 useEffect(()=>{requestKey.current=requestId();submit.reset();},[outId,inId,submit.reset]);
 const current=commands.find(c=>c.id===sent?.id)??sent;
 const waiting=submit.isPending||current?.status==='pending'||commands.some(c=>c.type==='substitution'&&c.status==='pending');
 useEffect(()=>{if(current?.status==='applied'){setOut('');setIn('');setSent(undefined);}else if(current?.status==='rejected'){setRejected(current.reason||'No se han podido aplicar los cambios. Revisa la selección.');setSent(undefined);}},[current?.id,current?.status,current?.reason]);
 const field=players.filter(p=>['field','sinBin','sentOff'].includes(p.status)||(p.status==='injured'&&!p.substituted)).sort((a,b)=>a.position-b.position);
 const bench=players.filter(p=>p.status==='bench'),remaining=Math.max(0,8-used),selected=players.find(p=>p.playerId===outId);
 const valid=remaining>0&&players.some(p=>p.playerId===outId&&canLeave(p))&&players.some(p=>p.playerId===inId&&canEnter(p));
 function choose(p:Snapshot,side:'field'|'bench'){
  if(waiting)return;
  if(side==='field'){setOut(outId===p.playerId?'':p.playerId);setIn('');}else{setIn(inId===p.playerId?'':p.playerId);}
  setRejected('');
 }
 return <section className="match-substitutions" aria-label="Selección de sustitución">
  <p className="substitution-hint" role="status">{waiting?'Cambio enviado. Se aplicará en la siguiente interrupción.':remaining===0?'Has utilizado las ocho sustituciones.':selected?(inId?'Confirma el cambio con Solicitar sustitución.':`Sale ${selected.name}. Selecciona un suplente.`):'Selecciona un jugador en campo y después un suplente.'}</p>
  <div className="substitution-squads">{(['field','bench'] as const).map(side=><div key={side}><div className="substitution-columns"><strong>{side==='field'?'En campo':'Banquillo'}</strong><span>Media</span><span>Energía</span></div><div className="substitution-player-list" role="group" aria-label={side==='field'?'Jugadores en campo':'Jugadores en el banquillo'}>{(side==='field'?field:bench).map(p=>{
   const active=side==='field'?outId===p.playerId:inId===p.playerId;
   const unavailable=side==='field'?!canLeave(p):!canEnter(p),disabled=waiting||unavailable||remaining===0||(side==='bench'&&!outId);
   const status=p.status==='injured'?' · Lesionado':p.status==='sinBin'?' · Excluido':p.status==='sentOff'?' · Expulsado':'';
   return <button key={p.playerId} type="button" className={`substitution-player ${active?'selected':''}`} aria-label={`${side==='field'?'Sale':'Entra'} ${p.name}`} aria-pressed={active} disabled={disabled} title={`${p.name} · ${positions[side==='field'?p.position:p.naturalPosition]}${status}`} onClick={()=>choose(p,side)}><span className="substitution-player-heading"><span className={`substitution-position ${p.status==='injured'?'injured':''}`}>{p.status==='injured'?<Cross size={12}/>:side==='field'?p.position:p.naturalPosition}</span><span className="substitution-position-name">{positions[side==='field'?p.position:p.naturalPosition]}</span><strong>{p.name}</strong></span><b className="substitution-average">{average(p)}</b><span className="substitution-energy">{Number.isFinite(p.energy)?Math.round(Math.min(100,Math.max(0,p.energy))):0}%</span></button>;
  })}{side==='bench'&&!bench.length&&<p className="empty">Sin suplentes.</p>}</div></div>)}</div>
  {rejected&&<ErrorBox error={new Error(rejected)} onDismiss={()=>setRejected('')}/>}
  {!!outId&&!!inId&&!valid&&!waiting&&<p className="substitution-warning" role="alert">La disponibilidad ha cambiado. Revisa la selección.</p>}
  {submit.error&&<ErrorBox error={submit.error} onDismiss={()=>submit.reset()}/>}
  <button type="button" className="button dark full" disabled={!valid||waiting} onClick={()=>submit.mutate()}>{submit.isPending?<LoaderCircle className="spin" size={16}/>:null}Solicitar sustitución <ArrowLeftRight size={16}/></button>
 </section>;
}
