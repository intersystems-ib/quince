import { localize, tr, useLocale } from "./i18n";
import { useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { ArrowRight } from 'lucide-react';
import { api, getClubId } from './api';
import { Action } from './components';
import type { Club, Fixture, Lineup, Match, Page } from './types';
export default function Prepare({ fixture, club }: {
    fixture: Fixture;
    club: Club;
}) {
    useLocale();
    const nav = useNavigate(), lineups = useQuery({ queryKey: ['lineups'], queryFn: () => api<Page<Lineup>>('/my-club/lineups') }), [selected, setSelected] = useState(fixture.preparationLineupId ?? `${getClubId()}-default`);
    useEffect(() => { if (fixture.preparationLineupId)
        setSelected(fixture.preparationLineupId); }, [fixture.preparationLineupId]);
    if (fixture.matchId)
        return <Link className="button dark full" to={`/partido/${fixture.matchId}`}>{localize(fixture.status === 'finished' ? 'Ver resumen' : 'Ir al partido')} <ArrowRight size={16}/></Link>;
    return <div className="prepare">{localize((lineups.data?.items.length ?? 0) > 1 && <label>{tr("Alineaci\u00F3n")}<select aria-label={tr("Alineación del encuentro")} value={selected} onChange={e => setSelected(e.target.value)}>{localize(lineups.data?.items.map(l => <option key={l.id} value={l.id}>{localize(l.name)}</option>))}</select></label>)}<Action path="/matches" body={{ fixtureId: fixture.id, lineupId: selected }} disabled={fixture.day > club.day} onSuccess={d => nav(`/partido/${(d as Match).id}`)} className="dark full">{tr("Ir al partido ")}<ArrowRight size={16}/></Action></div>;
}
