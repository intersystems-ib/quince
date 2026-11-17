import { localize, tr, useLocale } from "./i18n";
import { useState } from 'react';
import { Shuffle } from 'lucide-react';
import { drillOptions, weeklyProposal } from './weeklyPlanning';
import type { TrainingTheme, TrainingType, WeeklyDay } from './types';
const days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
const approaches = [['balanced', 'Equilibrado'], ['attack', 'Ofensivo'], ['defense', 'Defensivo'], ['physical', 'Físico'], ['technique', 'Destrezas técnicas'], ['setPieces', 'Formaciones y reinicios'], ['tactics', 'Táctica y disciplina']];
export default function WeeklyPlanner({ week, themes, catalog, category, onChange, readOnly = false }: {
    week: WeeklyDay[];
    themes: TrainingTheme[];
    catalog: TrainingType[];
    category: 'senior' | 'academy';
    onChange: (week: WeeklyDay[]) => void;
    readOnly?: boolean;
}) {
    useLocale();
    const [approach, setApproach] = useState('balanced'), [selected, setSelected] = useState(1);
    const labels = Object.fromEntries(catalog.map(t => [t.id, t.name]));
    const entry = week.find(d => d.day === selected)!, theme = themes.find(t => t.id === entry.theme)!;
    const focus = (d: WeeklyDay, line: 'forwards' | 'backs') => d[line] ?? themes.find(t => t.id === d.theme)![line].split(',')[d.day - 1];
    function patch(change: Partial<WeeklyDay>) { onChange(week.map(d => d.day === selected ? { ...d, ...change } : d)); }
    function propose() {
        const proposed = weeklyProposal(week, themes);
        if (approach !== 'balanced') {
            const main = themes.find(t => t.id === approach)!;
            const trainingDays = proposed.filter(d => d.theme !== 'rest');
            for (const d of trainingDays.slice(0, 3))
                Object.assign(d, { theme: main.id, forwards: pick(drillOptions(main, 'forwards')), backs: pick(drillOptions(main, 'backs')) });
        }
        onChange(proposed);
    }
    return <>
 {localize(!readOnly && <div className="weekly-approach"><label>{tr("Enfoque de la semana")}<select value={approach} onChange={e => setApproach(e.target.value)}>{localize(approaches.map(([id, name]) => <option key={id} value={id}>{localize(name)}</option>))}</select></label><button className="button secondary" onClick={propose}><Shuffle size={15}/>{tr("Solicitar planificaci\u00F3n")}</button></div>)}
 {localize(!readOnly && <p className="muted small">{tr("Genera una propuesta y selecciona un d\u00EDa para ajustarlo. El plan se repite cada semana.")}</p>)}
 <div className="weekly-day-cards" role="group" aria-label={tr(`Días del plan de ${category === 'senior' ? 'primer equipo' : 'cantera'}`)}>{localize(week.map(d => { const t = themes.find(t => t.id === d.theme)!; return <button type="button" className={`weekly-day-card${d.theme === 'rest' ? ' rest' : ''}`} key={d.day} aria-pressed={selected === d.day} aria-controls={`weekly-day-editor-${category}`} onClick={() => setSelected(d.day)}><strong>{localize(days[d.day - 1])}</strong><span>{localize(t.name)}</span>{localize(d.theme !== 'rest' && <><small>{tr("Delanteros: ")}{localize(labels[focus(d, 'forwards')] ?? focus(d, 'forwards'))}</small><small>{tr("Tres cuartos: ")}{localize(labels[focus(d, 'backs')] ?? focus(d, 'backs'))}</small></>)}</button>; }))}</div>
 <div className="weekly-day-editor" id={`weekly-day-editor-${category}`} role="group" aria-label={tr(`Editar ${days[selected - 1]}`)}><div className="weekly-edit-heading"><h4>{localize(days[selected - 1])}</h4><span className="muted small">{localize(readOnly ? 'Sesión automática' : 'Ajuste del día')}</span></div>{localize(readOnly ? <div className="weekly-auto-details"><p><strong>{tr("Sesi\u00F3n:")}</strong> {localize(theme.name)}</p>{localize((['forwards', 'backs'] as const).map(line => <p key={line}><strong>{localize(line === 'forwards' ? 'Delanteros' : 'Tres cuartos')}{tr(":")}</strong> {localize(labels[focus(entry, line)] ?? focus(entry, line))}</p>))}</div> : <div className="weekly-edit-fields"><label>{tr("Sesi\u00F3n")}<select aria-label={tr(`${days[selected - 1]} · ${category === 'senior' ? 'Primer equipo' : 'Cantera'}`)} value={entry.theme} onChange={e => patch({ theme: e.target.value, forwards: undefined, backs: undefined })}>{localize(themes.map(t => <option key={t.id} value={t.id}>{localize(t.name)}</option>))}</select></label>{localize((['forwards', 'backs'] as const).map(line => <label key={line}>{localize(line === 'forwards' ? 'Delanteros' : 'Tres cuartos')}<select aria-label={tr(`${days[selected - 1]} · ${line === 'forwards' ? 'Delanteros' : 'Tres cuartos'} · ${category === 'senior' ? 'Primer equipo' : 'Cantera'}`)} value={focus(entry, line)} disabled={entry.theme === 'rest'} onChange={e => patch({ [line]: e.target.value })}>{localize(drillOptions(theme, line).map(id => <option key={id} value={id}>{localize(labels[id] ?? id)}</option>))}</select></label>))}</div>)}{localize(entry.theme === 'rest' && <p className="muted small">{tr("Recuperaci\u00F3n para ambos grupos.")}</p>)}</div>
 </>;
}
function pick<T>(items: T[]): T { return items[Math.floor(Math.random() * items.length)]; }
