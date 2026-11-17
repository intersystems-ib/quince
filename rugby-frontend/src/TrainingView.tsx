import { localize, tr, useLocale } from "./i18n";
import { useDayAdvanceBlock } from './DayAdvanceControl';
import WeeklyPlanner from './WeeklyPlanner';
import { useState } from 'react';
import TrainingReadiness from './TrainingReadiness';
import { useQuery } from '@tanstack/react-query';
import { Check, RotateCcw } from 'lucide-react';
import { api } from './api';
import { Action, ErrorBox, Heading, Loading } from './components';
import type { Club, Page, Player, Staff, Training, TrainingType, TrainingWeek, WeeklyDay } from './types';
export default function TrainingView({ club }: {
    club: Club;
}) {
    useLocale();
    const [category, setCategory] = useState<Player['category']>('senior');
    const plan = useQuery({ queryKey: ['training'], queryFn: () => api<Training>('/my-club/training-plan') });
    const players = useQuery({ queryKey: ['players'], queryFn: () => api<Page<Player>>('/my-club/players') });
    const catalog = useQuery({ queryKey: ['training-types'], queryFn: () => api<{
            items: TrainingType[];
        }>('/training-types') });
    const staff = useQuery({ queryKey: ['staff'], queryFn: () => api<Staff>('/my-club/staff') });
    if (plan.isLoading || players.isLoading || catalog.isLoading || staff.isLoading)
        return <Loading />;
    if (plan.error || players.error || catalog.error || staff.error)
        return <ErrorBox error={plan.error || players.error || catalog.error || staff.error}/>;
    return <WeeklyEditor key={plan.data!.version} initial={plan.data!} players={players.data!.items} catalog={catalog.data!.items} staff={staff.data!} club={club} category={category} onCategoryChange={setCategory}/>;
}
function WeeklyEditor({ initial, players, catalog, staff, club, category, onCategoryChange }: {
    initial: Training;
    players: Player[];
    catalog: TrainingType[];
    staff: Staff;
    club: Club;
    category: Player['category'];
    onCategoryChange: (c: Player['category']) => void;
}) {
    useLocale();
    const [weekly, setWeekly] = useState<TrainingWeek>(() => structuredClone(initial.weekly!));
    const dirty = !initial.weeklyConfigured || JSON.stringify(weekly) !== JSON.stringify(initial.weekly);
    useDayAdvanceBlock(dirty ? 'Guarda la planificación de entrenamiento antes de avanzar.' : null);
    const themes = initial.themes ?? [];
    const members = players.filter(p => p.category === category);
    const academyCoach = staff.coaches.find(c => c.role === 'academy');
    function changeDay(day: number, patch: Partial<WeeklyDay>) { setWeekly({ ...weekly, [category]: weekly[category].map(d => d.day === day ? { ...d, ...patch } : d) }); }
    return <><Heading eyebrow={"DESARROLLO DE LA PLANTILLA"} title={"Cada jugador, su camino."}/>
 <div className="competition-tabs" role="tablist" aria-label={tr("Plantilla de entrenamiento")}>{localize((['senior', 'academy'] as const).map(c => <button key={c} id={`training-${c}-tab`} role="tab" aria-selected={category === c} aria-controls="training-panel" onClick={() => { onCategoryChange(c); }}>{localize(c === 'senior' ? 'Primer equipo' : 'Cantera')}{tr(" \u00B7 ")}{localize(players.filter(p => p.category === c).length)}</button>))}</div>
 <div role="tabpanel" id="training-panel" aria-labelledby={`training-${category}-tab`}>
 <section className="card weekly-planner"><div className="card-top"><h3>{localize(category === 'academy' ? 'Plan automático de cantera' : 'Planifica la semana')}</h3><span className="tiny-tag">{localize(category === 'academy' ? 'AUTOMÁTICO' : dirty ? 'BORRADOR' : 'PLAN GUARDADO')}</span></div>
 {localize(category === 'academy' && <p className="muted small">{localize(academyCoach?.name ?? 'El entrenador de cantera')}{tr(" organiza las sesiones de los j\u00F3venes. La mejora depende de su calidad (")}{localize(academyCoach?.quality ?? 25)}{tr("/100); los jugadores cansados o no disponibles pasan a recuperaci\u00F3n autom\u00E1ticamente.")}</p>)}
 <WeeklyPlanner readOnly={category === 'academy'} key={category} week={weekly[category]} themes={themes} catalog={catalog} category={category} onChange={week => setWeekly({ ...weekly, [category]: week })}/>
 {localize(category === 'senior' && <><p className="muted small">{tr("Se repite cada semana. El cuerpo t\u00E9cnico adapta la intensidad y prioriza la recuperaci\u00F3n por cansancio, baja o partido cercano.")}</p>
 <div className="weekly-save"><span className="muted small">{tr("Responsables: especialistas del primer equipo")}{localize(!initial.weeklyConfigured && ' · Guarda para activar el plan semanal.')}</span><div>{localize(dirty && initial.weeklyConfigured && <button className="button secondary" onClick={() => setWeekly(structuredClone(initial.weekly!))}><RotateCcw size={15}/>{tr("Descartar cambios")}</button>)}<Action path="/my-club/training-plan" method="PUT" body={{ version: initial.version, mode: 'weekly', weekly }} disabled={!dirty} className="dark">{tr("Guardar planificaci\u00F3n ")}<Check size={16}/></Action></div></div></>)}
 </section>
 <TrainingReadiness club={club} players={members} week={weekly[category]} category={category} onRecover={day => changeDay(day, { theme: 'rest', forwards: undefined, backs: undefined })}/>

 </div></>;
}
