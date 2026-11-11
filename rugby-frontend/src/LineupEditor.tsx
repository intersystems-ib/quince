import {useDayAdvanceBlock} from './DayAdvanceControl';
import {InjuryMark,injuryText} from './InjuryStatus';
import {availableBench,selectedPlayerId,swapLineupPlayers,lineupMorale,positionPenalty} from './lineupAvailability';
import type {LineupSelection} from './lineupAvailability';
import {useEffect,useState} from 'react';
import {ArrowRight,X} from 'lucide-react';
import {Action,Energy,ErrorBox,Heading,Pitch,TacticFields,positions} from './components';
import type {Lineup,Player} from './types';

export default function LineupEditor({initial,players}:{initial:Lineup;players:Player[]}){
 const [l,setL]=useState(()=>availableBench(initial,players)),[active,setActive]=useState(1),[hovered,setHovered]=useState<string>(),[selected,setSelected]=useState<LineupSelection|null>(null),[error,setError]=useState<string|null>(null);
 const dirty=JSON.stringify(l)!==JSON.stringify(availableBench(initial,players));
 useDayAdvanceBlock(dirty?'Guarda la alineación antes de avanzar.':null);
 useEffect(()=>{setL(old=>availableBench(old,players));setSelected(null);},[players]);
 useEffect(()=>{if(!selected)return;const cancel=(e:KeyboardEvent)=>{if(e.key==='Escape'){setSelected(null);setError(null);}};window.addEventListener('keydown',cancel);return()=>window.removeEventListener('keydown',cancel);},[selected]);
 const byId=new Map(players.map(p=>[p.id,p]));
 const preview=byId.get(hovered??l.slots.find(s=>s.position===active)?.playerId??'');
 const chosen=selected?byId.get(selectedPlayerId(l,selected)):undefined;
 const called=new Set([...l.slots.map(s=>s.playerId),...l.bench]);
 const unselected=players.filter(p=>p.available&&!called.has(p.id));
 const unavailable=players.filter(p=>!p.available&&!l.slots.some(s=>s.playerId===p.id));
 const same=(a:LineupSelection|null,b:LineupSelection)=>!!a&&a.kind===b.kind&&(a.kind==='unselected'&&b.kind==='unselected'?a.playerId===b.playerId:a.kind!=='unselected'&&b.kind!=='unselected'&&a.index===b.index);
 function pick(target:LineupSelection){
  setError(null);const id=selectedPlayerId(l,target);setHovered(id);
  if(target.kind==='starter')setActive(l.slots[target.index].position);
  if(!selected){setSelected(target);return;}
  if(same(selected,target)){setSelected(null);return;}
  const next=swapLineupPlayers(l,players,selected,target);
  if(next===l){setError(selected.kind==='unselected'&&target.kind==='unselected'?'Elige un titular o un suplente para el intercambio.':'Ese intercambio dejaría un puesto vacío o alinearía a un jugador no disponible.');return;}
  setL(next);setSelected(null);setHovered(undefined);
 }
 function hover(p:Player|undefined,position?:number){setHovered(p?.id);if(position)setActive(position);}
 function identity(p:Player|undefined){return p?<span title={p.secondary.length?`También: ${p.secondary.map(n=>positions[n]).join(', ')}`:undefined}><strong>{p.name}</strong><small>{positions[p.position]}</small></span>:<span><strong>Sin jugador</strong></span>;}
 function row(p:Player|undefined,badge:string,target:LineupSelection,position?:number){
  const penalty=p&&position!==undefined?positionPenalty(p,position):0;
  return <button type="button" className={`lineup-player-row ${same(selected,target)?'selected':''}`} aria-pressed={same(selected,target)} aria-label={`Seleccionar ${target.kind==='starter'?`titular ${position}`:target.kind==='bench'?`suplente ${target.index+1}`:'no convocado'}: ${p?.name??'puesto vacío'}`} onClick={()=>pick(target)} onMouseEnter={()=>hover(p,position)} onFocus={()=>hover(p,position)} title={p?.injury?injuryText(p.injury):p&&!p.available?p.unavailableReason??'No disponible':undefined}><span className="lineup-row-identity"><span className={target.kind==='starter'?'number':'bench-index'}>{p?.injury?<InjuryMark player={p}/>:badge}</span>{identity(p)}</span><b>{p?Math.round(p.average):'—'}</b><span title={penalty?`Fuera de posición: −${penalty} de moral. Moral habitual: ${Math.round(p!.morale)}%.`:undefined}>{p?<Energy value={lineupMorale(p,position)}/>: '—'}</span><span>{p?<Energy value={p.energy}/>: '—'}</span></button>;
 }
 const headers=<div className="lineup-list-head"><span>Jugador y posición natural</span><span>Promedio</span><span>Moral</span><span>Energía</span></div>;
 return <><Heading eyebrow="PREPARACIÓN" title="Tu manera de jugar." description="Pulsa dos jugadores para intercambiar sus puestos."/>{selected&&<div className="lineup-swap-status" role="status"><span>{chosen?.name??'Puesto vacío'} seleccionado</span><button className="text-button" onClick={()=>{setSelected(null);setError(null);}}><X size={13}/>Cancelar selección</button></div>}{error&&<ErrorBox error={new Error(error)}/>}
 <div className="lineup-workspace lineup-compact"><div className="lineup-roster-columns"><section className="card lineup-selection"><div className="card-top"><h3>El XV inicial</h3><span className="pill">15 TITULARES</span></div><label>Nombre de la alineación<input value={l.name} onChange={e=>setL({...l,name:e.target.value})}/></label>{headers}{l.slots.map((slot,index)=><div key={slot.position}>{row(byId.get(slot.playerId),String(slot.position),{kind:'starter',index},slot.position)}</div>)}<label className="lineup-captain">Capitán<select value={l.captainId} onChange={e=>setL({...l,captainId:e.target.value})}><option value="">Selecciona un capitán</option>{players.filter(p=>called.has(p.id)).map(p=><option key={p.id} value={p.id}>{p.name}</option>)}</select></label></section>
 <div className="lineup-reserves"><section className="card lineup-selection"><div className="card-top"><h3>El banquillo</h3><span className="pill">{l.bench.length}/8</span></div>{headers}{l.bench.map((id,index)=><div key={index}>{row(byId.get(id),`S${index+1}`,{kind:'bench',index})}</div>)}{l.bench.length<8&&<button className="button secondary" onClick={()=>{setL({...l,bench:[...l.bench,'']});setSelected({kind:'bench',index:l.bench.length});}}>Añadir suplente</button>}</section>
 <section className="card lineup-selection lineup-unselected" aria-labelledby="lineup-unselected-title"><div className="card-top"><h3 id="lineup-unselected-title">No convocados</h3><span className="pill">{unselected.length}</span></div>{headers}<div role="list">{unselected.map(p=><div role="listitem" key={p.id}>{row(p,'—',{kind:'unselected',playerId:p.id})}</div>)}</div>{!unselected.length&&<p className="empty">Todos los jugadores disponibles están convocados.</p>}</section>
 <section className="card lineup-selection lineup-unavailable" aria-labelledby="lineup-unavailable-title"><div className="card-top"><h3 id="lineup-unavailable-title">No disponibles</h3><span className="pill">{unavailable.length}</span></div>{headers}<div role="list">{unavailable.map(p=><div className="lineup-player-row lineup-unavailable-row" role="listitem" key={p.id} title={p.injury?injuryText(p.injury):p.unavailableReason??'No disponible'}><span className="lineup-row-identity"><span className="bench-index">{p.injury?<InjuryMark player={p}/>: '—'}</span>{identity(p)}</span><b>{Math.round(p.average)}</b><span><Energy value={lineupMorale(p)}/></span><span><Energy value={p.energy}/></span></div>)}</div>{!unavailable.length&&<p className="empty">No hay jugadores no disponibles fuera del XV.</p>}</section></div></div>
 <aside className="lineup-side"><section className="card lineup-preparation" aria-label="Campo y táctica"><div className="formation-preview lineup-field"><h3>Tu equipo en el campo</h3><Pitch compact activePosition={active} naturalPosition={preview?.position} onPositionSelect={position=>pick({kind:'starter',index:l.slots.findIndex(s=>s.position===position)})}/><div className="formation-legend"><span><i className="selected-key"/>Puesto seleccionado</span><span><i className="natural-key"/>Posición natural</span></div><div className="formation-caption"><strong>{active}. {positions[active]}</strong>{preview&&<span>{preview.name} · {positions[preview.position]}</span>}</div></div><div className="lineup-tactics"><h3>La idea de juego</h3><TacticFields value={l.tactic} onChange={tactic=>setL({...l,tactic})}/><Action path={`/lineups/${l.id}`} method="PUT" body={l} className="dark full">Guardar alineación <ArrowRight size={16}/></Action></div></section></aside></div></>;
}
