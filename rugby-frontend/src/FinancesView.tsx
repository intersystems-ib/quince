import { useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { getLocale, localize, tr, useLocale } from './i18n';
import { api } from './api';
import { Action, ErrorBox, Heading, Loading } from './components';
import { monthlySalary } from './salary';
import FinanceSalary from './FinanceSalary';
import { FinanceOverview, FinanceMovements, FinanceBalance, financeMoney as money } from './FinanceBreakdown';
import type { FinancialView } from './types';

export default function FinancesView() {
    useLocale();
    const q = useQuery({ queryKey: ['finances'], queryFn: () => api<FinancialView>('/my-club/finances') });
    const [params, setParams] = useSearchParams(), requested = params.get('tab');
    const tab = requested === 'expenses' || requested === 'balance' ? requested : 'income';
    const [directorOpen, setDirectorOpen] = useState(requested === 'director');
    useEffect(() => { if (requested === 'director') setDirectorOpen(true); }, [requested]);
    if (q.isLoading) return <Loading />;
    if (q.error) return <ErrorBox error={q.error} />;
    const f = q.data!, s = f.season;
    return <><Heading eyebrow={`ECONOMÍA · ${s.season}`} title="Las cuentas del club." action={<button className="button secondary" aria-expanded={directorOpen} aria-controls="finance-director" onClick={() => setDirectorOpen(!directorOpen)}>{tr('Financiero')}</button>} />
        <div className="stat-grid finance-stats">{([['Tesorería', f.balance], ['Presupuesto anual de referencia', f.financialPlan?.community?.referenceBudget ?? f.office.budgetReference], ['Ingresos anuales acordados', f.securedAnnualIncome]] as const).map(([label, value]) => <section className="card finance-metric" key={label}><small>{tr(label)}</small><strong>{money(value)}</strong></section>)}</div>
        {f.balance < 0 && <p className="error">{tr('La tesorería es negativa.')}</p>}
        {directorOpen && <section id="finance-director" className="finance-director-panel" aria-label={tr('Gestión del financiero')}><FinanceDirector finance={f} /></section>}
        <div className="competition-tabs finance-tabs" role="tablist" aria-label={tr('Gestión financiera')}>{([['income', 'Ingresos'], ['expenses', 'Gastos'], ['balance', 'Balance']] as const).map(([id, label]) => <button id={`finance-tab-${id}`} key={id} role="tab" aria-selected={tab === id} aria-controls={`finance-panel-${id}`} onClick={() => setParams({ tab: id })}>{tr(label)}</button>)}</div>
        <div id={`finance-panel-${tab}`} role="tabpanel" aria-labelledby={`finance-tab-${tab}`}>
            {tab === 'income' && <><FinanceOverview finance={f} kind="income" /><FinanceIncomeDetails finance={f} /><FinanceMovements finance={f} kind="income" /></>}
            {tab === 'expenses' && <><FinanceOverview finance={f} kind="expenses" /><FinanceSalary key={f.salaryBudget?.year} finance={f} /><FinanceMovements finance={f} kind="expenses" /></>}
            {tab === 'balance' && <FinanceBalance finance={f} />}
        </div>
    </>;
}

function FinanceIncomeDetails({ finance: f }: { finance: FinancialView }) {
    useLocale();
    const s = f.season, d = f.office.director;
    return <div className="finance-columns"><div className="finance-funding"><section className="card finance-detail-card finance-sponsors"><div className="card-top"><h3>{tr("Patrocinadores")}</h3><span className="pill">{tr("SEPTIEMBRE \u00B7 D\u00CDA 7")}</span></div><div className="finance-sponsor-list" role="region" aria-label={tr("Lista de patrocinadores y ofertas")} tabIndex={0}>{localize(f.agreements.length ? f.agreements.map(a => <div className="finance-deal" key={a.id}><strong>{localize(a.name)}</strong><span className="tiny-tag">{localize(a.category === 'principal' ? 'PATROCINADOR PRINCIPAL' : 'PATROCINADOR SECUNDARIO')}</span><b>{localize(money(a.annualAmount))}{tr(" / temporada")}</b><small>{localize(a.startYear)}{tr("/")}{localize(a.startYear + 1)}{tr(" \u2014 ")}{localize(a.endYear)}{tr("/")}{localize(a.endYear + 1)}{tr(" \u00B7 ")}{localize(a.years)} {localize(a.years === 1 ? 'año' : 'años')}</small></div>) : <p className="muted">{localize(d.id ? 'El financiero buscará acuerdos en septiembre.' : 'Contrata un financiero para conseguir patrocinadores.')}</p>)}{localize(!!s.offers.filter(a => a.kind !== 'barConcession').length && <details><summary>{tr("Ofertas estudiadas (")}{localize(s.offers.filter(a => a.kind !== 'barConcession').length)}{tr(")")}</summary>{localize(s.offers.filter(a => a.kind !== 'barConcession').map((a, i) => <div className="finance-deal" key={`${a.id}-${i}`}><strong>{localize(a.name)}</strong><span>{localize(money(a.annualAmount))}{tr(" / temporada \u00B7 ")}{localize(a.years)}{tr(" a\u00F1os")}</span><small>{localize(a.status === 'signed' ? 'Firmada automáticamente' : 'Descartada')}</small></div>))}</details>)}</div></section>
 <section className="card finance-detail-card finance-grants"><div className="card-top"><h3>{tr("Subvenciones")}</h3><span className="pill">{tr("SEPTIEMBRE \u00B7 D\u00CDA 14")}</span></div>{localize(s.grants.length ? s.grants.map(g => <div className="finance-deal" key={g.id}><strong>{g.name}</strong><b>{localize(money(g.amount))}</b><small>{localize(g.status === 'paid' ? 'Cobrada' : g.status === 'instalments' ? 'Cobro en mensualidades' : 'Concedida')}</small></div>) : <p className="muted">{tr("Pendientes de la gesti\u00F3n de septiembre.")}</p>)}</section></div>
 <section className="card finance-detail-card"><div className="card-top"><h3>{tr("Concesi\u00F3n del bar")}</h3><span className="pill">{tr("SEPTIEMBRE \u00B7 D\u00CDA 28")}</span></div>{localize(f.barConcession?.id ? <div className="finance-deal"><strong>{localize(f.barConcession.name)}</strong><b>{localize(money(f.barConcession.annualAmount))}{tr(" / temporada")}</b><small>{localize(f.barConcession.startYear)}{tr("/")}{localize(f.barConcession.startYear + 1)}{tr(" \u2014 ")}{localize(f.barConcession.endYear)}{tr("/")}{localize(f.barConcession.endYear + 1)}{tr(" \u00B7 ")}{localize(f.barConcession.years)} {localize(f.barConcession.years === 1 ? 'año' : 'años')}</small></div> : <p className="muted">{tr("El financiero negociar\u00E1 la concesi\u00F3n durante septiembre.")}</p>)}<small>{tr("Canon para el club. El concesionario asume las ventas y los costes del bar.")}</small></section>
 <section className="card finance-detail-card"><div className="card-top"><h3>{tr("Campa\u00F1a de abonados")}</h3><span className="pill">{tr("SEPTIEMBRE \u00B7 D\u00CDA 21")}</span></div><div className="finance-metric"><strong>{localize(s.members.toLocaleString(getLocale()))}</strong><small>{tr("abonados \u00B7 ")}{localize(money(s.seasonTicketPrice))}{tr(" por temporada")}</small></div><p>{tr("Recaudaci\u00F3n: ")}<strong>{localize(money(s.campaignIncome))}</strong></p><small>{localize(s.campaignComplete ? 'Campaña cerrada' : 'Pendiente de la campaña de septiembre')}</small></section>
    </div>;
}

function FinanceDirector({ finance: f }: { finance: FinancialView }) {
    useLocale();
    const o = f.office, d = o.director;
    return <><section className="card"><h3>{localize(d.name ?? 'Sin financiero contratado')}</h3>{localize(d.id ? <p>{tr("Capacidad ")}{localize(d.quality)}{tr("/100 \u00B7 ")}{localize(money(d.monthlyWage ?? monthlySalary(d.weeklyWage ?? 0)))}{tr(" por mes")}</p> : <p>{tr("El financiero gestiona autom\u00E1ticamente patrocinios, subvenciones, abonados y la concesi\u00F3n del bar durante septiembre.")}</p>)}</section><div className="staff-candidates">{localize(o.candidates.map(c => <article className="card candidate-card" key={c.id}><span className="pill">{tr("FINANCIERO")}</span><h3>{c.name}</h3><div className="candidate-quality"><b>{localize(c.quality)}</b><span>{tr("/100")}<small>{tr("Capacidad de negociaci\u00F3n")}</small></span></div><p>{localize(money(c.monthlyWage ?? monthlySalary(c.weeklyWage)))}{tr(" / mes")}</p><Action path="/my-club/financial-director" body={{ candidateId: c.id, version: o.version }} disabled={d.id === c.id} className="dark full">{localize(d.id === c.id ? 'Contratado' : d.id ? 'Contratar y sustituir' : 'Contratar financiero')}</Action></article>))}</div></>;
}
