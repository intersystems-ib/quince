import {useState} from 'react';
import {Shuffle} from 'lucide-react';
import {drillOptions,weeklyProposal} from './weeklyPlanning';
import type {TrainingTheme,TrainingType,WeeklyDay} from './types';

const days=['Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo'];
const approaches=[['balanced','Equilibrado'],['attack','Ofensivo'],['defense','Defensivo'],['physical','Físico'],['technique','Destrezas técnicas'],['setPieces','Formaciones y reinicios'],['tactics','Táctica y disciplina']];
export default function WeeklyPlanner({week,themes,catalog,category,onChange,readOnly=false}:{week:WeeklyDay[];themes:TrainingTheme[];catalog:TrainingType[];category:'senior'|'academy';onChange:(week:WeeklyDay[])=>void;readOnly?:boolean}){
 const [approach,setApproach]=useState('balanced'),[selected,setSelected]=useState(1);
 const labels=Object.fromEntries(catalog.map(t=>[t.id,t.name]));
 const entry=week.find(d=>d.day===selected)!,theme=themes.find(t=>t.id===entry.theme)!;
 const focus=(d:WeeklyDay,line:'forwards'|'backs')=>d[line]??themes.find(t=>t.id===d.theme)![line].split(',')[d.day-1];
 function patch(change:Partial<WeeklyDay>){onChange(week.map(d=>d.day===selected?{...d,...change}:d));}
 function propose(){
  const proposed=weeklyProposal(week,themes);
  if(approach!=='balanced'){
   const main=themes.find(t=>t.id===approach)!;
   const trainingDays=proposed.filter(d=>d.theme!=='rest');
   for(const d of trainingDays.slice(0,3))Object.assign(d,{theme:main.id,forwards:pick(drillOptions(main,'forwards')),backs:pick(drillOptions(main,'backs'))});
  }
  onChange(proposed);
 }
 return <>
 {!readOnly&&<div className="weekly-approach"><label>Enfoque de la semana<select value={approach} onChange={e=>setApproach(e.target.value)}>{approaches.map(([id,name])=><option key={id} value={id}>{name}</option>)}</select></label><button className="button secondary" onClick={propose}><Shuffle size={15}/>Solicitar planificación</button></div>}
 {!readOnly&&<p className="muted small">Genera una propuesta y selecciona un día para ajustarlo. El plan se repite cada semana.</p>}
 <div className="weekly-day-cards" role="group" aria-label={`Días del plan de ${category==='senior'?'primer equipo':'cantera'}`}>{week.map(d=>{const t=themes.find(t=>t.id===d.theme)!;return <button type="button" className={`weekly-day-card${d.theme==='rest'?' rest':''}`} key={d.day} aria-pressed={selected===d.day} aria-controls={`weekly-day-editor-${category}`} onClick={()=>setSelected(d.day)}><strong>{days[d.day-1]}</strong><span>{t.name}</span>{d.theme!=='rest'&&<><small>Delanteros: {labels[focus(d,'forwards')]??focus(d,'forwards')}</small><small>Tres cuartos: {labels[focus(d,'backs')]??focus(d,'backs')}</small></>}</button>;})}</div>
 <div className="weekly-day-editor" id={`weekly-day-editor-${category}`} role="group" aria-label={`Editar ${days[selected-1]}`}><div className="weekly-edit-heading"><h4>{days[selected-1]}</h4><span className="muted small">{readOnly?'Sesión automática':'Ajuste del día'}</span></div>{readOnly?<div className="weekly-auto-details"><p><strong>Sesión:</strong> {theme.name}</p>{(['forwards','backs'] as const).map(line=><p key={line}><strong>{line==='forwards'?'Delanteros':'Tres cuartos'}:</strong> {labels[focus(entry,line)]??focus(entry,line)}</p>)}</div>:<div className="weekly-edit-fields"><label>Sesión<select aria-label={`${days[selected-1]} · ${category==='senior'?'Primer equipo':'Cantera'}`} value={entry.theme} onChange={e=>patch({theme:e.target.value,forwards:undefined,backs:undefined})}>{themes.map(t=><option key={t.id} value={t.id}>{t.name}</option>)}</select></label>{(['forwards','backs'] as const).map(line=><label key={line}>{line==='forwards'?'Delanteros':'Tres cuartos'}<select aria-label={`${days[selected-1]} · ${line==='forwards'?'Delanteros':'Tres cuartos'} · ${category==='senior'?'Primer equipo':'Cantera'}`} value={focus(entry,line)} disabled={entry.theme==='rest'} onChange={e=>patch({[line]:e.target.value})}>{drillOptions(theme,line).map(id=><option key={id} value={id}>{labels[id]??id}</option>)}</select></label>)}</div>}{entry.theme==='rest'&&<p className="muted small">Recuperación para ambos grupos.</p>}</div>
 </>;
}
function pick<T,>(items:T[]):T{return items[Math.floor(Math.random()*items.length)];}
