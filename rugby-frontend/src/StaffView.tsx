import { localize, tr, useLocale } from "./i18n";
import PreparationPanel from './OpponentPreparation';
import { monthlySalary } from './salary';
import { useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { BriefcaseBusiness, Coins, TrendingUp, UserCheck } from 'lucide-react';
import { api } from './api';
import { Action, ErrorBox, Heading, Loading, money } from './components';
import type { Club, Coach, Page, Staff } from './types';
export default function StaffView({ club }: {
    club: Club;
}) {
    useLocale();
    const [params, setParams] = useSearchParams(), preparation = params.get('tab') === 'preparacion';
    const tab = (value: boolean) => {
        const next = new URLSearchParams(params);
        if (value)
            next.set('tab', 'preparacion');
        else {
            next.delete('tab');
            next.delete('fixture');
        }
        setParams(next);
    };
    return <><Heading eyebrow={"LAS PERSONAS QUE HACEN CRECER AL EQUIPO"} title={"Cuerpo técnico"}/><div className="competition-tabs staff-tabs" role="tablist" aria-label={tr("Gestión del cuerpo técnico")}><button id="staff-coaches-tab" role="tab" aria-selected={!preparation} aria-controls="staff-content" onClick={() => tab(false)}>{tr("Cuerpo t\u00E9cnico")}</button><button id="staff-preparation-tab" role="tab" aria-selected={preparation} aria-controls="staff-content" onClick={() => tab(true)}>{tr("Preparaci\u00F3n del rival")}</button></div><div id="staff-content" role="tabpanel" aria-labelledby={preparation ? 'staff-preparation-tab' : 'staff-coaches-tab'}>{localize(preparation ? <PreparationPanel club={club} fixtureId={params.get('fixture') ?? undefined}/> : <StaffRoster />)}</div></>;
}
function StaffRoster() {
    useLocale();
    const [params] = useSearchParams();
    const [roleId, setRoleId] = useState(params.get('role') || 'head'), [page, setPage] = useState(0);
    const staff = useQuery({ queryKey: ['staff'], queryFn: () => api<Staff>('/my-club/staff') });
    const market = useQuery({ queryKey: ['staff-market', roleId, page], queryFn: () => api<Page<Coach>>(`/staff-market?role=${encodeURIComponent(roleId)}&offset=${page * 12}&limit=12`) });
    useEffect(() => {
        if (market.data && page * 12 >= market.data.total && page > 0)
            setPage(Math.max(0, Math.ceil(market.data.total / 12) - 1));
    }, [market.data?.total, page]);
    if (staff.isLoading || market.isLoading)
        return <Loading />;
    if (staff.error || market.error)
        return <ErrorBox error={staff.error || market.error}/>;
    const data = staff.data!, role = data.roles.find(r => r.id === roleId) ?? data.roles[0], current = data.coaches.find(c => c.role === roleId);
    const candidates = [...market.data!.items].filter(c => c.role === roleId).sort((a, b) => b.quality - a.quality);
    return <>
 <div className="staff-overview"><span><UserCheck size={19}/><strong>{localize(data.coaches.length)}</strong>{tr(" especialistas contratados")}</span><span><Coins size={19}/>{tr("Salarios mensuales ")}<strong>{localize(money(data.monthlyWage ?? monthlySalary(data.weeklyWage)))}</strong></span><span><TrendingUp size={19}/>{tr("La calidad acelera el desarrollo dentro del l\u00EDmite anual")}</span></div>
 <section className="card"><div className="card-top"><h3>{tr("Tu cuerpo t\u00E9cnico")}</h3><span className="pill">{localize(data.roles.length)}{tr(" ESPECIALIDADES")}</span></div><div className="staff-role-grid">{localize(data.roles.map(r => { const coach = data.coaches.find(c => c.role === r.id); return <button key={r.id} aria-pressed={roleId === r.id} className={`staff-role ${roleId === r.id ? 'active' : ''}`} onClick={() => { setRoleId(r.id); setPage(0); }}><BriefcaseBusiness size={19}/><strong>{localize(r.name)}</strong><span>{localize(coach?.name ?? 'Sin contratar')}</span><b>{tr("Calidad ")}{localize(coach?.quality ?? 25)}{tr("/100")}</b>{localize(coach && <span>{tr("Eficacia formativa ")}<strong>{localize(Math.round(coach.effectiveness * 100))}{tr("%")}</strong></span>)}<small>{localize(coach ? `${money((coach.monthlyWage ?? monthlySalary(coach.weeklyWage)))} / mes` : 'Apoyo básico del club')}</small></button>; }))}</div></section>
 <Heading eyebrow={"CONTRATACIÓN"} title={role.name} description={`${role.englishName} · ${role.description}`}/>

 <p className="muted"><span className="pill">{tr(data.marketCountry === 'FR' ? 'Francia' : 'España')}</span> {localize(market.data!.total)}{tr(" candidatos para esta especialidad")}</p>
 <div className="staff-candidates">{localize(candidates.map(c => <article className="card candidate-card" key={c.id}><span className="pill">{tr("DISPONIBLE")}</span><h3>{c.name}</h3><p>{localize(role.name)}</p><div className="candidate-quality"><b>{localize(c.quality)}</b><span>{tr("/100")}<small>{tr("Calidad t\u00E9cnica")}</small></span></div><div className="candidate-details"><span>{tr("Eficacia formativa ")}<strong>{localize(Math.round(c.effectiveness * 100))}{tr("%")}</strong></span><span>{tr("Salario mensual ")}<strong>{localize(money((c.monthlyWage ?? monthlySalary(c.weeklyWage))))}</strong></span><span>{tr("Variaci\u00F3n del gasto ")}<strong>{localize((c.monthlyWage ?? monthlySalary(c.weeklyWage)) - (current?.monthlyWage ?? monthlySalary(current?.weeklyWage ?? 0)) > 0 ? '+' : '')}{localize(money((c.monthlyWage ?? monthlySalary(c.weeklyWage)) - (current?.monthlyWage ?? monthlySalary(current?.weeklyWage ?? 0))))}{tr(" / mes")}</strong></span></div><Action path="/my-club/staff" body={{ coachId: c.id, version: data.version }} className="dark full">{localize(current ? 'Contratar y sustituir' : 'Contratar entrenador')}</Action></article>))}</div>
 {localize(!candidates.length && <p className="empty">{tr("No hay candidatos disponibles para esta especialidad.")}</p>)}
 {localize(market.data!.total > 12 && <div className="toolbar"><button className="button secondary" disabled={!page} onClick={() => setPage(page - 1)}>{tr("Anterior")}</button><span>{tr("P\u00E1gina ")}{localize(page + 1)}{tr(" de ")}{localize(Math.ceil(market.data!.total / 12))}</span><button className="button secondary" disabled={(page + 1) * 12 >= market.data!.total} onClick={() => setPage(page + 1)}>{tr("Siguiente")}</button></div>)}
 </>;
}
