import { localize, tr, useLocale } from "./i18n";
import { automaticLineup } from './automaticLineup';
import { useDayAdvanceBlock } from './DayAdvanceControl';
import { InjuryMark, injuryText } from './InjuryStatus';
import { availableBench, lineupForSave, selectedPlayerId, swapLineupPlayers, lineupMorale, positionPenalty } from './lineupAvailability';
import type { LineupSelection } from './lineupAvailability';
import { useEffect, useState } from 'react';
import { ArrowRight, X } from 'lucide-react';
import { Action, Energy, ErrorBox, Heading, Pitch, TacticFields, positions } from './components';
import type { Lineup, Player } from './types';
export default function LineupEditor({ initial, players }: {
    initial: Lineup;
    players: Player[];
}) {
    useLocale();
    const [l, setL] = useState(() => availableBench(initial, players)), [active, setActive] = useState(1), [hovered, setHovered] = useState<string>(), [selected, setSelected] = useState<LineupSelection | null>(null), [error, setError] = useState<string | null>(null);
    const dirty = JSON.stringify(l) !== JSON.stringify(availableBench(initial, players));
    useDayAdvanceBlock(dirty ? 'Guarda la alineación antes de avanzar.' : null);
    useEffect(() => { setL(old => availableBench(old, players)); setSelected(null); }, [players]);
    useEffect(() => {
        if (!selected)
            return;
        const cancel = (e: KeyboardEvent) => {
            if (e.key === 'Escape') {
                setSelected(null);
                setError(null);
            }
        };
        window.addEventListener('keydown', cancel);
        return () => window.removeEventListener('keydown', cancel);
    }, [selected]);
    const byId = new Map(players.map(p => [p.id, p]));
    const preview = byId.get(hovered ?? l.slots.find(s => s.position === active)?.playerId ?? '');
    const chosen = selected ? byId.get(selectedPlayerId(l, selected)) : undefined;
    const called = new Set([...l.slots.map(s => s.playerId), ...l.bench]);
    const unselected = players.filter(p => p.available && !called.has(p.id));
    const unavailable = players.filter(p => !p.available && !l.slots.some(s => s.playerId === p.id));
    const same = (a: LineupSelection | null, b: LineupSelection) => !!a && a.kind === b.kind && (a.kind === 'unselected' && b.kind === 'unselected' ? a.playerId === b.playerId : a.kind !== 'unselected' && b.kind !== 'unselected' && a.index === b.index);
    function pick(target: LineupSelection) {
        setError(null);
        const id = selectedPlayerId(l, target);
        setHovered(id);
        if (target.kind === 'starter')
            setActive(l.slots[target.index].position);
        if (!selected) {
            setSelected(target);
            return;
        }
        if (same(selected, target)) {
            setSelected(null);
            return;
        }
        const next = swapLineupPlayers(l, players, selected, target);
        if (next === l) {
            setError(selected.kind === 'unselected' && target.kind === 'unselected' ? 'Elige un titular o un suplente para el intercambio.' : 'Ese intercambio dejaría un puesto vacío o alinearía a un jugador no disponible.');
            return;
        }
        setL(next);
        setSelected(null);
        setHovered(undefined);
    }
    function hover(p: Player | undefined, position?: number) {
        setHovered(p?.id);
        if (position)
            setActive(position);
    }
    function identity(p: Player | undefined) { return p ? <span title={tr(p.secondary.length ? `También: ${p.secondary.map(n => positions[n]).join(', ')}` : undefined)}><strong title={p.name}>{p.name}</strong><small>{localize(positions[p.position])}</small></span> : <span><strong>{tr("Sin jugador")}</strong></span>; }
    function row(p: Player | undefined, badge: string, target: LineupSelection, position?: number) {
        const penalty = p && position !== undefined ? positionPenalty(p, position) : 0;
        return <button type="button" className={`lineup-player-row ${!p ? 'empty-slot' : ''} ${same(selected, target) ? 'selected' : ''}`} aria-pressed={same(selected, target)} aria-label={tr(`Seleccionar ${target.kind === 'starter' ? `titular ${position}` : target.kind === 'bench' ? `suplente ${target.index + 1}` : 'no convocado'}: ${p?.name ?? 'puesto vacío'}`)} onClick={() => pick(target)} onMouseEnter={() => hover(p, position)} onFocus={() => hover(p, position)} title={tr(p?.injury ? injuryText(p.injury) : p && !p.available ? p.unavailableReason ?? 'No disponible' : undefined)}><span className="lineup-row-identity"><span className={target.kind === 'starter' ? 'number' : 'bench-index'}>{localize(p?.injury ? <InjuryMark player={p}/> : badge)}</span>{localize(identity(p))}</span><b>{localize(p ? Math.round(p.average) : '—')}</b><span title={tr(penalty ? `Fuera de posición: −${penalty} de moral. Moral habitual: ${Math.round(p!.morale)}%.` : undefined)}>{localize(p ? <Energy value={lineupMorale(p, position)}/> : '—')}</span><span>{localize(p ? <Energy value={p.energy}/> : '—')}</span></button>;
    }
    const headers = <div className="lineup-list-head"><span>{tr("Jugador y posici\u00F3n natural")}</span><span>{tr("Media")}</span><span>{tr("Moral")}</span><span>{tr("Energ\u00EDa")}</span></div>;
    return <><Heading eyebrow={"PREPARACIÓN"} title={"Tu manera de jugar."} description={"Pulsa dos jugadores para intercambiar sus puestos."}/>{localize(selected && <div className="lineup-swap-status" role="status"><span>{localize(chosen?.name ?? 'Puesto vacío')}{tr(" seleccionado")}</span><button className="text-button" onClick={() => { setSelected(null); setError(null); }}><X size={13}/>{tr("Cancelar selecci\u00F3n")}</button></div>)}{localize(error && <ErrorBox error={new Error(error)}/>)}
 <div className="lineup-workspace lineup-compact"><div className="lineup-roster-columns"><section className="card lineup-selection"><div className="card-top"><h3>{tr("El XV inicial")}</h3><button type="button" className="button secondary" title={tr("Elige la mayor media por posición y un banquillo equilibrado con cobertura de puestos. Energía y moral desempatan. Guarda para confirmar.")} onClick={() => { try { setL(automaticLineup(l, players)); setSelected(null); setHovered(undefined); setError(null); } catch (cause) { setError(cause instanceof Error ? cause.message : String(cause)); } }}>{tr("Alineación automática")}</button></div><label>{tr("Nombre de la alineaci\u00F3n")}<input value={l.name} onChange={e => setL({ ...l, name: e.target.value })}/></label>{localize(headers)}{localize(l.slots.map((slot, index) => <div key={slot.position}>{localize(row(byId.get(slot.playerId), String(slot.position), { kind: 'starter', index }, slot.position))}</div>))}<label className="lineup-captain">{tr("Capit\u00E1n")}<select value={l.captainId} onChange={e => setL({ ...l, captainId: e.target.value })}><option value="">{tr("Selecciona un capit\u00E1n")}</option>{localize(players.filter(p => called.has(p.id)).map(p => <option key={p.id} value={p.id}>{p.name}</option>))}</select></label></section>
 <div className="lineup-reserves"><section className="card lineup-selection"><div className="card-top"><h3>{tr("El banquillo")}</h3><span className="pill">{localize(l.bench.filter(Boolean).length)}{tr("/8")}</span></div>{localize(headers)}{localize(l.bench.map((id, index) => <div key={index}>{localize(row(byId.get(id), `S${index + 1}`, { kind: 'bench', index }))}</div>))}</section>
    </div></div>
 <aside className="lineup-side"><section className="card lineup-preparation" aria-label={tr("Campo y táctica")}><div className="formation-preview lineup-field"><h3>{tr("Tu equipo en el campo")}</h3><Pitch compact activePosition={active} naturalPosition={preview?.position} onPositionSelect={position => pick({ kind: 'starter', index: l.slots.findIndex(s => s.position === position) })}/><div className="formation-legend"><span><i className="selected-key"/>{tr("Puesto seleccionado")}</span><span><i className="natural-key"/>{tr("Posici\u00F3n natural")}</span></div><div className="formation-caption"><strong>{localize(active)}{tr(". ")}{localize(positions[active])}</strong>{localize(preview && <span>{localize(preview.name)}{tr(" \u00B7 ")}{localize(positions[preview.position])}</span>)}</div></div><div className="lineup-tactics"><h3>{tr("La idea de juego")}</h3><TacticFields value={l.tactic} onChange={tactic => setL({ ...l, tactic })}/><Action path={`/lineups/${l.id}`} method="PUT" body={lineupForSave(l)} className="dark full">{tr("Guardar alineaci\u00F3n ")}<ArrowRight size={16}/></Action></div></section> <section className="card lineup-selection lineup-unselected" aria-labelledby="lineup-unselected-title"><div className="card-top"><h3 id="lineup-unselected-title">{tr("No convocados")}</h3><span className="pill">{localize(unselected.length)}</span></div>{localize(headers)}<div role="list">{localize(unselected.map(p => <div role="listitem" key={p.id}>{localize(row(p, '—', { kind: 'unselected', playerId: p.id }))}</div>))}</div>{localize(!unselected.length && <p className="empty">{tr("Todos los jugadores disponibles est\u00E1n convocados.")}</p>)}</section>
 <section className="card lineup-selection lineup-unavailable" aria-labelledby="lineup-unavailable-title"><div className="card-top"><h3 id="lineup-unavailable-title">{tr("No disponibles")}</h3><span className="pill">{localize(unavailable.length)}</span></div>{localize(headers)}<div role="list">{localize(unavailable.map(p => <div className="lineup-player-row lineup-unavailable-row" role="listitem" key={p.id} title={tr(p.injury ? injuryText(p.injury) : p.unavailableReason ?? 'No disponible')}><span className="lineup-row-identity"><span className="bench-index">{localize(p.injury ? <InjuryMark player={p}/> : '—')}</span>{localize(identity(p))}</span><b>{localize(Math.round(p.average))}</b><span><Energy value={lineupMorale(p)}/></span><span><Energy value={p.energy}/></span></div>))}</div>{localize(!unavailable.length && <p className="empty">{tr("No hay jugadores no disponibles fuera del XV.")}</p>)}</section></aside></div></>;
}
