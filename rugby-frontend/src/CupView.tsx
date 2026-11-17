import { localize, tr, useLocale } from "./i18n";
import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Trophy } from 'lucide-react';
import { api } from './api';
import { ErrorBox, Loading } from './components';
import ClubCrest from './ClubCrest';
import { EmptyTie, FixtureCard } from './CompetitionFixtures';
import type { Club, CupCompetition, Fixture } from './types';
export default function CupView({ id, club }: {
    id: string;
    club: Club;
}) {
    useLocale();
    const q = useQuery({ queryKey: ['competition', id], queryFn: () => api<CupCompetition>(`/competitions/${id}`), refetchInterval: 15000 });
    const [tab, setTab] = useState('groups');
    if (q.isLoading)
        return <Loading />;
    if (q.error)
        return <ErrorBox error={q.error}/>;
    const c = q.data!, names = Object.fromEntries(c.standings.map(r => [r.clubId, r.shortName || r.name]));
    const tie = (fixtures: Fixture[], slots: number, date: string) => Array.from({ length: slots }, (_, i) => { const f = fixtures.find(x => x.slot === i + 1); return <div key={i} className="playoff-slot">{localize(f ? <FixtureCard f={f} club={club} names={names}/> : <EmptyTie date={date}/>)}</div>; });
    return <><div className="competition-summary"><span>{localize(c.season)}</span><b>{localize(c.regularFinished)}{tr("/18 partidos de grupos")}</b><span className="pill">{localize(({ groups: 'FASE DE GRUPOS', quarterfinal: 'CUARTOS', semifinal: 'SEMIFINALES', final: 'FINAL', finished: 'COPA FINALIZADA' } as Record<string, string>)[c.phase])}</span></div>
 <section className="card cup-exempt"><h3>{tr("Clasificados directamente a cuartos")}</h3><div>{localize(c.exemptTeamIds.map(cid => <span key={cid}><ClubCrest clubId={cid} name={names[cid]}/><strong>{localize(names[cid])}</strong></span>))}</div></section>
 <div className="competition-tabs" role="tablist" aria-label={tr("Fases de Copa")}><button role="tab" aria-selected={tab === 'groups'} onClick={() => setTab('groups')}>{tr("Fase de grupos")}</button><button role="tab" aria-selected={tab === 'knockout'} onClick={() => setTab('knockout')}>{tr("Eliminatorias")}</button></div>
 {localize(tab === 'groups' ? <div className="cup-groups">{localize(c.groups.map(g => <section className="card" key={g.id}><h3>{tr("Grupo ")}{localize(g.id)}</h3><div className="table-wrap"><table aria-label={tr(`Clasificación del grupo ${g.id}`)}><thead><tr><th>{tr("Equipo")}</th><th>{tr("PJ")}</th><th>{tr("G")}</th><th>{tr("E")}</th><th>{tr("P")}</th><th>{tr("DIF")}</th><th>{tr("BO")}</th><th>{tr("BD")}</th><th>{tr("PTS")}</th></tr></thead><tbody>{localize(g.standings.map(r => <tr key={r.clubId} className={r.clubId === club.id ? 'managed-club' : ''}><td><div className="standing-club"><ClubCrest clubId={r.clubId} name={r.name}/><span title={tr(r.name)}>{localize(r.shortName || r.name)}</span>{localize(c.qualifiedTeamIds.includes(r.clubId) && <span className="tiny-tag">{tr("CLASIFICADO")}</span>)}</div></td><td>{localize(r.played)}</td><td>{localize(r.wins)}</td><td>{localize(r.draws)}</td><td>{localize(r.losses)}</td><td>{localize(r.difference)}</td><td>{localize(r.bonusOffensive)}</td><td>{localize(r.bonusDefensive)}</td><td><b>{localize(r.points)}</b></td></tr>))}</tbody></table></div></section>))}</div> : <>
 {localize(c.championId && <div className="competition-champion"><Trophy size={26}/><ClubCrest clubId={c.championId} name={names[c.championId]}/><div><small>{tr("CAMPE\u00D3N DE COPA \u00B7 ")}{localize(c.season)}</small><h3>{localize(names[c.championId])}</h3></div></div>)}
 <div className="cup-bracket"><section><h3>{tr("Cuartos de final")}</h3>{localize(tie(c.quarterfinals, 4, c.quarterfinalDate))}</section><section><h3>{tr("Semifinales")}</h3>{localize(tie(c.semifinals, 2, c.semifinalDates[0]))}</section><section><h3>{tr("Final")}</h3>{localize(c.final ? <FixtureCard f={c.final} club={club} names={names}/> : <EmptyTie date={c.finalDate}/>)}</section></div></>)}
 </>;
}
