import {useEffect,useRef,useState} from 'react';
import {ArrowLeftRight,Cross,X,LoaderCircle} from 'lucide-react';
import {Energy,ErrorBox,attrLabels,positions} from './components';
import {useMutation,useQueryClient} from '@tanstack/react-query';
import {api} from './api';
import {requestId} from './requestId';
import type {Command,Snapshot} from './types';

type Pair={outId:string;inId:string};
const canLeave=(p:Snapshot)=>p.status==='field'||(p.status==='injured'&&!p.substituted);
const canEnter=(p:Snapshot)=>p.status==='bench'&&!p.injury;
const average=(p:Snapshot)=>{const values=Object.keys(attrLabels).map(k=>p.attributes[k]).filter(Number.isFinite);return values.length?Math.round(values.reduce((sum,v)=>sum+v,0)/values.length):0;};

export default function MatchSubstitutions({id,players,used,commands}:{id:string;players:Snapshot[];used:number;commands:Command[]}){
 const [pairs,setPairs]=useState<Pair[]>([]),[outId,setOut]=useState(''),[sent,setSent]=useState<Command>(),[rejected,setRejected]=useState('');
 const qc=useQueryClient(),requestKey=useRef(requestId());
 const submit=useMutation({mutationFn:(changes:Pair[])=>api<Command>(`/matches/${id}/commands`,'POST',{type:'substitution',changes},requestKey.current),onSuccess:command=>{setSent(command);setOut('');setRejected('');void qc.invalidateQueries({queryKey:['commands',id]});void qc.invalidateQueries({queryKey:['match',id]});}});
 useEffect(()=>{requestKey.current=requestId();submit.reset();},[pairs,submit.reset]);
 const current=commands.find(c=>c.id===sent?.id)??sent;
 const waiting=submit.isPending||current?.status==='pending'||commands.some(c=>c.type==='substitution'&&c.status==='pending');
 useEffect(()=>{if(current?.status==='applied'){setPairs([]);setOut('');setSent(undefined);}else if(current?.status==='rejected'){setRejected(current.reason||'No se han podido aplicar los cambios. Revisa la selección.');setSent(undefined);}},[current?.id,current?.status,current?.reason]);
 const field=players.filter(p=>['field','sinBin','sentOff'].includes(p.status)||(p.status==='injured'&&!p.substituted)).sort((a,b)=>a.position-b.position);
 const bench=players.filter(p=>p.status==='bench'),remaining=Math.max(0,8-used),selected=players.find(p=>p.playerId===outId);
 const valid=pairs.length>0&&pairs.length<=remaining&&pairs.every(pair=>players.some(p=>p.playerId===pair.outId&&canLeave(p))&&players.some(p=>p.playerId===pair.inId&&canEnter(p)));
 function remove(pair:Pair){setPairs(old=>old.filter(p=>p!==pair));setRejected('');}
 function choose(p:Snapshot,side:'field'|'bench'){
  if(waiting)return;
  const pair=pairs.find(pair=>side==='field'?pair.outId===p.playerId:pair.inId===p.playerId);
  if(pair){remove(pair);setOut(pair.outId);return;}
  if(side==='field'){setOut(outId===p.playerId?'':p.playerId);return;}
  if(!outId||pairs.length>=remaining)return;
  setPairs(old=>[...old,{outId,inId:p.playerId}]);setOut('');setRejected('');
 }
 return <section className="match-substitutions" aria-label="Sustituciones"><div className="card-top"><h4>Sustituciones</h4><span className="tiny-tag">{used}/8 UTILIZADAS</span></div>
  <p className="substitution-hint" role="status">{waiting?'Cambios enviados. Se aplicarán en la siguiente interrupción.':remaining===0?'Has utilizado las ocho sustituciones.':selected?`Sale ${selected.name}. Selecciona un suplente.`:'Selecciona un jugador en campo y después un suplente.'}</p>
  <div className="substitution-squads">{(['field','bench'] as const).map(side=><div key={side}><h4>{side==='field'?'En campo':'Banquillo'}</h4><div className="substitution-player-list" role="group" aria-label={side==='field'?'Jugadores en campo':'Jugadores en el banquillo'}>{(side==='field'?field:bench).map(p=>{
   const index=pairs.findIndex(pair=>side==='field'?pair.outId===p.playerId:pair.inId===p.playerId),planned=index>=0,active=side==='field'&&outId===p.playerId;
   const unavailable=side==='field'?!canLeave(p):!canEnter(p),disabled=waiting||unavailable||(!planned&&(side==='field'?pairs.length>=remaining:!outId||pairs.length>=remaining));
   return <button key={p.playerId} type="button" className={`substitution-player ${planned?'planned':''} ${active?'selected':''}`} aria-label={`${side==='field'?'Sale':'Entra'} ${p.name}`} aria-pressed={planned||active} disabled={disabled} title={`${p.name} · ${positions[side==='field'?p.position:p.naturalPosition]}`} onClick={()=>choose(p,side)}><span className="substitution-player-heading"><span className={`substitution-position ${p.status==='injured'?'injured':''}`}>{p.status==='injured'?<Cross size={13}/>:side==='field'?p.position:positions[p.naturalPosition]?.slice(0,1)}</span><strong>{p.name}</strong>{planned&&<b className="substitution-pair-number">{index+1}</b>}</span><small className="substitution-player-position">{positions[side==='field'?p.position:p.naturalPosition]}{p.status==='injured'?' · Lesionado':p.status==='sinBin'?' · Excluido':p.status==='sentOff'?' · Expulsado':''}</small><span className="substitution-player-metrics"><span>Media <b>{average(p)}</b></span><Energy value={p.energy}/></span></button>;
  })}{side==='bench'&&!bench.length&&<p className="empty">Sin suplentes.</p>}</div></div>)}</div>
  {pairs.length>0&&<div className="substitution-draft"><h4>{pairs.length} {pairs.length===1?'cambio preparado':'cambios preparados'} · {remaining} disponibles</h4><ol>{pairs.map((pair,i)=><li key={pair.outId}><b>{i+1}</b><div><span>{players.find(p=>p.playerId===pair.outId)?.name}</span><span><ArrowLeftRight size={11}/>{players.find(p=>p.playerId===pair.inId)?.name}</span></div><button type="button" className="icon-button" aria-label={`Quitar cambio ${i+1}`} disabled={waiting} onClick={()=>remove(pair)}><X size={14}/></button></li>)}</ol></div>}
  {rejected&&<ErrorBox error={new Error(rejected)} onDismiss={()=>setRejected('')}/>}
  {!!pairs.length&&!valid&&!waiting&&<p className="substitution-warning" role="alert">La disponibilidad ha cambiado. Revisa los cambios preparados.</p>}
  {submit.error&&<ErrorBox error={submit.error} onDismiss={()=>submit.reset()}/>}
  <button type="button" className="button dark full" disabled={!valid||waiting} onClick={()=>submit.mutate(pairs.map(pair=>({...pair})))}>{submit.isPending?<LoaderCircle className="spin" size={16}/>:null}Solicitar sustitución <ArrowLeftRight size={16}/></button>
 </section>;
}
