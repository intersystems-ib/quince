import { getLocale, localize, tr, useLocale } from "./i18n";
import { useClubName } from './clubNames';
import { isAddedTime, matchSeconds } from './matchClock';
import MatchScorers from './MatchScorers';
import MatchSubstitutions from './MatchSubstitutions';
import MatchTimeline from './MatchTimeline';
import CardBadge from './CardBadge';
import { MatchStatistics } from './PlayerMatchHistory';
import { fixtureLabel } from './competitionLabels';
import VenueInfo from './VenueInfo';
import { injuryPauseMessage } from './matchInjuries';
import { kitBackground } from './kitAppearance';
import { useEffect, useRef, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { ArrowRight, CheckCircle2, Radio, Trophy, WifiOff } from 'lucide-react';
import { api, getClubId } from './api';
import ClubCrest from './ClubCrest';
import MatchPreview from './MatchPreview';
import ClassificationPoints from './ClassificationPoints';
import { Action, ErrorBox, Heading, Loading, Pitch, TacticFields, clock, positions, statusLabels } from './components';
import type { Command, Match, MatchEvent, Page, Snapshot, Tactic } from './types';
const statLabels: Record<string, string> = { tries: 'Ensayos', conversions: 'Transformaciones', penaltyGoals: 'Golpes a palos', drops: 'Drops', metres: 'Metros ganados', tackles: 'Placajes', turnovers: 'Recuperaciones', passes: 'Pases', kicks: 'Patadas', scrums: 'Melés', lineouts: 'Touches', penalties: 'Golpes de castigo', yellowCards: 'Tarjetas amarillas', redCards: 'Tarjetas rojas' };
export default function MatchView() {
    useLocale();
    const clubName = useClubName(), qc = useQueryClient(), syncedMatch = useRef<string | undefined>(undefined);
    const { id } = useParams(), [events, setEvents] = useState<MatchEvent[]>([]), seq = useRef(0);
    const state = useQuery({ queryKey: ['match', id], queryFn: () => api<Match>(`/matches/${id}`), refetchInterval: q => q.state.data?.status === 'finished' ? false : 1000 });
    const commandQuery = useQuery({ queryKey: ['commands', id], queryFn: () => api<Page<Command>>(`/matches/${id}/commands?limit=500`), refetchInterval: state.data?.status === 'finished' ? false : 1500 });
    const feed = useQuery({ queryKey: ['events', id], queryFn: async () => {
            const d = await api<{
                items: MatchEvent[];
                lastSequence: number;
                hasMore: boolean;
            }>(`/matches/${id}/events?afterSequence=${seq.current}&limit=500`);
            if (d.items.length) {
                seq.current = d.items[d.items.length - 1].sequence;
                setEvents(old => Array.from(new Map([...old, ...d.items].map(e => [e.sequence, e])).values()).sort((a, b) => a.sequence - b.sequence));
            }
            return d;
        }, refetchInterval: () => state.data?.status === 'finished' && seq.current >= state.data.sequence ? false : 1000 });
    useEffect(() => { seq.current = 0; setEvents([]); }, [id]);
    useEffect(() => {
        if (state.data?.status === 'finished' && syncedMatch.current !== state.data.id) {
            syncedMatch.current = state.data.id;
            void qc.invalidateQueries();
        }
    }, [qc, state.data?.id, state.data?.status]);
    const m = state.data ? { ...state.data, homeName: clubName(state.data.homeId, state.data.homeName), awayName: clubName(state.data.awayId, state.data.awayName) } : undefined;
    if (state.isLoading)
        return <Loading />;
    if (state.error && !m)
        return <ErrorBox error={state.error}/>;
    if (!m)
        return null;
    const side = m.homeId === getClubId() ? 'home' : 'away', own = m[`${side}Players`], finished = m.status === 'finished';
    if (m.status === 'scheduled')
        return <MatchPreview match={m}/>;
    return <><Heading eyebrow={finished ? 'RESUMEN DEL ENCUENTRO' : 'DÍA DE PARTIDO'} title={finished ? 'El partido ya es historia.' : 'Ochenta minutos. Todo por jugar.'} description={finished ? 'Resultado y estadísticas del encuentro.' : 'Tu equipo en el campo. Tus decisiones desde la banda.'} action={<Link className="button secondary" to="/competicion">{tr("Volver a Competici\u00F3n ")}<ArrowRight size={16}/></Link>}/>{localize((state.isError || feed.isError || commandQuery.isError) && <div className="error" role="alert"><WifiOff size={18}/>{tr("Conexi\u00F3n interrumpida. Conservamos el \u00FAltimo estado y seguimos intentando reconectar.")}</div>)}<section className={`scoreboard ${finished ? 'final' : ''}`}><div className="scoreboard-top"><span>{localize(finished ? <Trophy size={15}/> : <Radio size={15}/>)} {localize(finished ? 'RESULTADO FINAL' : 'EN DIRECTO')}</span><span>{localize(fixtureLabel(m).toLocaleUpperCase())}</span></div><div className="score-main"><div className="score-team"><ClubCrest clubId={m.homeId} name={m.homeName} className="score-crest"/><h2 title={state.data?.homeName}>{m.homeName}</h2><small>{tr("LOCAL \u00B7 ")}{localize(m.homeKit?.id === 'secondary' ? '2.ª' : '1.ª')}{tr(" EQUIPACI\u00D3N")}</small><TeamDiscipline players={m.homePlayers} stats={m.homeStats}/></div><div className="score-center"><div className="score"><div className="score-side"><span className="score-team-color" role="img" aria-label={tr(`Color en campo de ${m.homeName}`)} title={m.homeName} style={{ background: kitBackground(m.homeKit, m.homeColor) }}/><b>{localize(m.homeScore)}</b></div><span>{tr(":")}</span><div className="score-side"><b>{localize(m.awayScore)}</b><span className="score-team-color" role="img" aria-label={tr(`Color en campo de ${m.awayName}`)} title={m.awayName} style={{ background: kitBackground(m.awayKit, m.awayColor) }}/></div></div><span className="match-clock"><span className={`match-time ${isAddedTime(m) ? 'expired' : ''}`} title={tr(isAddedTime(m) ? 'Tiempo cumplido' : undefined)}>{localize(clock(matchSeconds(m)))}</span> <i /> {localize(m.speed === 0 && !finished ? `Pausa · ${statusLabels[m.status]}` : statusLabels[m.status])}</span></div><div className="score-team"><ClubCrest clubId={m.awayId} name={m.awayName} className="score-crest"/><h2 title={state.data?.awayName}>{m.awayName}</h2><small>{tr("VISITANTE \u00B7 ")}{localize(m.awayKit?.id === 'secondary' ? '2.ª' : '1.ª')}{tr(" EQUIPACI\u00D3N")}</small><TeamDiscipline players={m.awayPlayers} stats={m.awayStats}/></div></div><div className="score-bottom"><VenueInfo venue={m.venue}/>{localize(finished && m.economy && <span className="match-attendance">{tr("Asistentes ")}<strong>{localize(m.economy.attendance.toLocaleString(getLocale()))}</strong></span>)}{localize(m.homeShootout !== undefined && <span>{tr("Desempate a palos ")}<strong>{localize(m.homeShootout)}{tr("\u2013")}{localize(m.awayShootout)}</strong></span>)}<span className="match-possession">{tr("Posesi\u00F3n ")}<strong title={tr(m.possession === 'home' ? m.homeName : m.awayName)}>{localize(m.possession === 'home' ? m.homeName : m.awayName)}</strong></span>{localize(!finished && <div className="speed-control"><span>{tr("Velocidad")}</span>{localize([0, 1, 5, 20, 60].map(speed => <Action key={speed} path={`/matches/${id}/commands`} body={{ type: 'speed', speed }} className={m.speed === speed ? 'selected' : ''}>{localize(speed === 0 ? 'Pausa' : `x${speed}`)}</Action>))}</div>)}</div><MatchScorers match={m} events={events} loading={finished ? seq.current < m.sequence : feed.isLoading && events.length === 0}/></section>{localize(!finished && m.speed === 0 && <div className="notice match-pause" role="alert"><strong>{localize(m.pauseReason === 'injury' ? 'Pausa por lesión' : m.pauseReason === 'halftime' ? 'Descanso' : 'Partido en pausa')}</strong><p>{localize(m.pauseReason === 'injury' ? injuryPauseMessage(m) : m.pauseMessage || 'Selecciona una velocidad para continuar.')}</p></div>)}{localize(finished && <div className="success" role="status"><CheckCircle2 size={19}/>{localize(m.settled ? 'Resultado guardado.' : 'Confirmando resultado…')}</div>)}{localize(finished && <ClassificationPoints value={m.classification} home={m.homeName} away={m.awayName}/>)}<div className={`live-layout ${finished ? 'match-finished' : ''}`}><div className="match-main">{localize(!finished && <section className="card field-card"><div className="card-top"><h3>{tr("Desde la banda")}</h3><span className="tiny-tag">{localize(({ restart: 'Reinicio', open: 'Juego abierto', ruck: 'Ruck', scrum: 'Melé', lineout: 'Touche', penalty: 'Golpe de castigo', conversion: 'Transformación', stoppage: 'Balón muerto' })[m.phase] ?? m.phase)}</span></div><Pitch match={m}/><Exclusions m={m}/><MatchInjuries m={m}/><div className="pitch-legend"><span><i style={{ background: kitBackground(m.homeKit, m.homeColor) }}/>{m.homeName}</span><span><i style={{ background: kitBackground(m.awayKit, m.awayColor) }}/>{m.awayName}</span><small>{localize(finished ? 'Posiciones finales' : m.speed === 0 ? 'Partido en pausa' : 'Balón y jugadores en movimiento')}</small></div></section>)}<MatchTimeline match={m} events={events} decisions={commandQuery.data?.items ?? []}/></div>{localize(!finished && <div className="match-right"><MatchControls key={id} id={id!} own={own} tactic={m[`${side}Tactic`]} subs={m[`${side}Subs`]} commands={(commandQuery.data?.items ?? []).filter(c => c.side === side)}/></div>)}</div><MatchStatistics key={m.id} match={m} summary={<Stats m={m}/>}/></>;
}
function Stats({ m }: {
    m: Match;
}) { useLocale(); return <div className="stats-list"><div className="stats-names"><b>{m.homeName}</b><b>{m.awayName}</b></div>{localize(Object.entries(statLabels).map(([key, label]) => { const home = m.homeStats[key] ?? 0, away = m.awayStats[key] ?? 0; return <div className="match-stat" key={key}><div><b>{localize(Math.round(home))}</b><span>{localize(label)}</span><b>{localize(Math.round(away))}</b></div><div className="stat-bars"><i style={{ width: `${home + away ? home / (home + away) * 100 : 50}%`, background: kitBackground(m.homeKit, m.homeColor) }}/><i style={{ flex: 1, background: kitBackground(m.awayKit, m.awayColor) }}/></div></div>; }))}</div>; }
function MatchControls({ id, own, tactic, subs, commands }: {
    id: string;
    own: Snapshot[];
    tactic: Tactic;
    subs: number;
    commands: Command[];
}) { useLocale(); const [t, setT] = useState(tactic); return <section className="card match-decisions" aria-label={tr("Sustituciones y tácticas")}><div className="card-top"><h3>{tr("Sustituciones y t\u00E1cticas")}</h3><span className="tiny-tag">{localize(subs)}{tr("/8 UTILIZADAS")}</span></div><MatchSubstitutions id={id} players={own} used={subs} commands={commands}/><section className="match-tactics" aria-label={tr("Indicaciones tácticas")}><TacticFields value={t} onChange={setT}/><Action path={`/matches/${id}/commands`} body={{ type: 'tactic', tactic: t }} className="secondary full">{tr("Enviar cambio t\u00E1ctico ")}<ArrowRight size={16}/></Action></section></section>; }
function TeamDiscipline({ players, stats }: {
    players: Snapshot[];
    stats: Record<string, number>;
}) { useLocale(); return <div className="team-discipline"><span>{localize(players.filter(p => p.status === 'field').length)}{tr(" en campo")}</span><CardBadge color="yellow" count={stats.yellowCards ?? 0}/><CardBadge color="red" count={stats.redCards ?? 0}/></div>; }
function exclusionLabel(p: Snapshot, m: Match) { return p.status === 'sentOff' ? (p.redCardReason === 'secondYellow' ? 'Expulsado por doble amarilla' : 'Expulsado') : m.status === 'finished' ? 'Excluido al finalizar' : `Exclusión · vuelve en ${clock(Math.max(0, (p.sinBinUntil ?? 0) - m.clock))}`; }
function Exclusions({ m }: {
    m: Match;
}) { useLocale(); const players = [...m.homePlayers.map(p => ({ ...p, team: m.homeName })), ...m.awayPlayers.map(p => ({ ...p, team: m.awayName }))].filter(p => p.status === 'sinBin' || p.status === 'sentOff'); return players.length ? <div className="match-exclusions" aria-label={tr("Exclusiones del partido")}><h4>{tr("Exclusiones")}</h4>{localize(players.map(p => <div className={`exclusion-row ${p.status}`} key={p.id}><CardBadge color={p.status === 'sentOff' ? 'red' : 'yellow'}/><div><strong>{p.name}</strong><small>{localize(p.team)}{tr(" \u00B7 ")}{localize(p.position)}{tr(". ")}{localize(positions[p.position])}</small></div><b>{localize(exclusionLabel(p, m))}</b></div>))}</div> : null; }
function MatchInjuries({ m }: {
    m: Match;
}) { useLocale(); const players = [...m.homePlayers, ...m.awayPlayers].filter(p => p.status === 'injured' && p.injury); return players.length ? <div className="match-injuries" aria-label={tr("Lesiones del partido")}><h4>{tr("Lesiones")}</h4>{localize(players.map(p => <p key={p.id}><strong>{p.name}</strong><small>{tr("Lesionado")}{localize(p.substituted ? ' · Sustituido' : m.status === 'finished' ? '' : ' · Pendiente de sustitución')}</small></p>))}</div> : null; }
