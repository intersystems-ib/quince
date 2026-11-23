import { useState } from 'react';
import { getLocale, tr, useLocale } from './i18n';
import type { FinancialView } from './types';

export const financeMoney = (value: number) => new Intl.NumberFormat(getLocale(), { style: 'currency', currency: 'EUR', minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(value / 100);
const labels: Record<string, string> = { sponsorship: 'Patrocinios', grant: 'Patrocinios institucionales', memberships: 'Abonados', tickets: 'Taquilla', socialMembers: 'Socios', otherIncome: 'Otros ingresos', communityCosts: 'Escuelas y otras categorías', barConcession: 'Concesión de bar', bar: 'Bar anterior', barCosts: 'Costes de bar anteriores', financeWages: 'Financiero', registration: 'Fichas y participación', travel: 'Desplazamientos', training: 'Entrenamientos', wages: 'Plantilla', staffWages: 'Cuerpo técnico', transfer: 'Traspasos', match: 'Partidos anteriores' };

function forecast(f: FinancialView) {
    const income = f.financialPlan?.projectedIncome ?? f.fundingReference;
    const costs = f.salaryBudget ? f.salaryBudget.currentAnnualPlayers + f.salaryBudget.otherAnnualCosts : f.financialPlan?.projectedCosts ?? f.payroll.annualProjectedCosts;
    const reserved = f.salaryBudget?.additionalAnnual ?? 0;
    return { income, costs, reserved, margin: income - costs - reserved };
}

export function FinanceOverview({ finance: f, kind }: { finance: FinancialView; kind: 'income' | 'expenses' }) {
    useLocale();
    const income = kind === 'income', p = f.financialPlan, community = p?.community, totals = forecast(f);
    const start = `${f.season.year}-09-01`, end = `${f.season.year + 1}-09-01`;
    const actual = new Map<string, number>();
    for (const m of f.movements) {
        if (m.date < start || m.date >= end || (income ? m.amount <= 0 : m.amount >= 0)) continue;
        actual.set(m.type, (actual.get(m.type) ?? 0) + Math.abs(m.amount));
    }
    // The ledger groups school fees and activities in one receipt; retain its exact total.
    const youthShare = community && community.annualOtherIncome > 0 ? community.annualYouthFees / community.annualOtherIncome : 0;
    const plannedYouth = community ? Math.round(community.plannedOtherIncome * youthShare) : undefined;
    if (income && community) {
        const other = actual.get('otherIncome') ?? 0, youth = Math.round(other * youthShare);
        actual.delete('otherIncome');
        actual.set('youthFees', youth);
        actual.set('clubActivities', other - youth);
    }
    const communityLabels: Record<string, string> = {
        youthFees: 'Cuotas de categorías inferiores y escuelas', clubActivities: 'Actividades, eventos y colaboraciones',
        baseCoaching: 'Entrenadores y coordinación de base', baseTravel: 'Fichas y desplazamientos de base', baseFacilities: 'Instalaciones, material y administración',
    };
    const communityExpenses: Record<string, number | undefined> = {};
    if (!income && community) {
        const paid = actual.get('communityCosts') ?? 0;
        let plannedRemaining = community.plannedCosts, paidRemaining = paid;
        const costs = [['baseCoaching', community.annualCoachingCosts], ['baseTravel', community.annualFederationTravelCosts], ['baseFacilities', community.annualFacilitiesCosts]] as const;
        costs.forEach(([type, annual], index) => {
            const share = community.annualCosts > 0 ? annual / community.annualCosts : 0;
            const projected = index === costs.length - 1 ? plannedRemaining : Math.round(community.plannedCosts * share);
            const spent = index === costs.length - 1 ? paidRemaining : Math.round(paid * share);
            communityExpenses[type] = projected;
            actual.set(type, spent);
            plannedRemaining -= projected;
            paidRemaining -= spent;
        });
        actual.delete('communityCosts');
    }
    const concept = (type: string) => type === 'socialMembers' && community
        ? `${tr('Socios')} · ${community.memberCount.toLocaleString(getLocale())} × ${financeMoney(community.memberFee)} ${tr('por temporada')}`
        : tr(communityLabels[type] ?? labels[type] ?? type);
    const rows: Record<string, number | undefined> = income ? {
        sponsorship: p?.privateSponsors, grant: p?.publicGrants, memberships: p?.memberships,
        socialMembers: p?.community?.plannedMembersIncome, tickets: p?.tickets,
        barConcession: p?.barConcession, ...(community ? { youthFees: plannedYouth, clubActivities: community.plannedOtherIncome - (plannedYouth ?? 0) } : { otherIncome: undefined }),
    } : {
        wages: f.payroll.annualPlayers, staffWages: f.payroll.annualStaff, financeWages: f.payroll.annualDirector,
        registration: f.payroll.annualRegistrations, travel: f.payroll.annualTravelReserve,
        ...(community ? communityExpenses : { communityCosts: undefined }),
    };
    if (!income && actual.has('transfer')) rows.transfer = actual.get('transfer');
    for (const type of actual.keys()) if (!(type in rows)) rows[type] = undefined;
    return <section className="card table-wrap finance-overview"><div className="card-top"><h3>{tr(income ? 'Ingresos de la temporada' : 'Gastos de la temporada')}</h3></div>
        <table aria-label={tr(income ? 'Resumen de ingresos' : 'Resumen de gastos')}><thead><tr><th>{tr('Concepto')}</th><th className="right">{tr(income ? 'Cobrado' : 'Pagado')}</th><th className="right">{tr('Previsión total')}</th></tr></thead>
            <tbody>{Object.entries(rows).map(([type, projected]) => <tr key={type}><td>{concept(type)}</td><td className="right">{financeMoney(actual.get(type) ?? 0)}</td><td className="right">{projected === undefined ? '—' : financeMoney(projected)}</td></tr>)}</tbody>
            <tfoot><tr><th scope="row">{tr('Total')}</th><td className="right">{financeMoney(income ? f.income : f.expenses)}</td><td className="right">{financeMoney(income ? totals.income : totals.costs)}</td></tr></tfoot>
        </table>
    </section>;
}

export function FinanceMovements({ finance: f, kind }: { finance: FinancialView; kind: 'income' | 'expenses' }) {
    useLocale();
    const [page, setPage] = useState(0);
    const movements = f.movements.filter(m => kind === 'income' ? m.amount > 0 : m.amount < 0).sort((a, b) => b.day - a.day || b.id.localeCompare(a.id));
    const pages = Math.max(1, Math.ceil(movements.length / 20)), current = Math.min(page, pages - 1);
    return <details className="card finance-history"><summary>{tr(kind === 'income' ? 'Histórico de ingresos' : 'Histórico de gastos')} <span>({movements.length})</span></summary>
        <div className="table-wrap"><table aria-label={tr(kind === 'income' ? 'Movimientos de ingresos' : 'Movimientos de gastos')}><thead><tr><th>{tr('Fecha')}</th><th>{tr('Concepto')}</th><th>{tr('Tipo')}</th><th className="right">{tr('Importe')}</th></tr></thead><tbody>{movements.slice(current * 20, current * 20 + 20).map(m => <tr key={m.id}><td>{new Date(`${m.date}T12:00:00`).toLocaleDateString(getLocale())}</td><td>{tr(m.concept)}</td><td>{tr(labels[m.type] ?? m.type)}</td><td className={`right ${kind === 'income' ? 'positive' : ''}`}>{financeMoney(m.amount)}</td></tr>)}</tbody></table></div>
        {!movements.length && <p className="empty">{tr('Todavía no hay movimientos.')}</p>}
        {pages > 1 && <div className="toolbar"><button className="button secondary" disabled={!current} onClick={() => setPage(current - 1)}>{tr('Anterior')}</button><span>{current + 1} / {pages}</span><button className="button secondary" disabled={current >= pages - 1} onClick={() => setPage(current + 1)}>{tr('Siguiente')}</button></div>}
    </details>;
}

export function FinanceBalance({ finance: f }: { finance: FinancialView }) {
    useLocale();
    const totals = forecast(f), months = Object.entries(f.monthly).sort(([a], [b]) => a.localeCompare(b));
    return <div className="finance-balance-layout"><section className="card table-wrap finance-monthly"><div className="card-top"><h3>{tr('Balance mensual')}</h3><span className="tiny-tag">{f.season.season}</span></div>
        <table aria-label={tr('Balance mensual de la temporada')}><thead><tr><th>{tr('Mes')}</th><th className="right">{tr('Ingresos')}</th><th className="right">{tr('Gastos')}</th><th className="right">{tr('Resultado')}</th></tr></thead>
            <tbody>{months.length ? months.map(([month, row]) => <tr key={month}><th scope="row">{new Date(`${month}-01T12:00:00`).toLocaleDateString(getLocale(), { month: 'short', year: 'numeric' })}</th><td className="right">{financeMoney(row.income)}</td><td className="right">{financeMoney(row.expenses)}</td><td className={`right ${row.income < row.expenses ? 'negative' : 'positive'}`}>{financeMoney(row.income - row.expenses)}</td></tr>) : <tr><td colSpan={4}>{tr('Todavía no hay movimientos esta temporada.')}</td></tr>}</tbody>
            <tfoot><tr><th scope="row">{tr('Acumulado')}</th><td className="right">{financeMoney(f.income)}</td><td className="right">{financeMoney(f.expenses)}</td><td className={`right ${f.income < f.expenses ? 'negative' : 'positive'}`}>{financeMoney(f.income - f.expenses)}</td></tr></tfoot>
        </table>
    </section><section className="card finance-season-forecast finance-balance-forecast" aria-label={tr('Previsión económica de temporada')}><div className="card-top"><h3>{tr('Previsión de temporada')}</h3>{f.financialPlan?.provisional && <span className="tiny-tag">{tr('PROVISIONAL')}</span>}</div>
        <dl><div><dt>{tr('Ingresos previstos')}</dt><dd>{financeMoney(totals.income)}</dd></div><div><dt>{tr('Gastos previstos')}</dt><dd>{financeMoney(totals.costs)}</dd></div>{totals.reserved > 0 && <div><dt>{tr('Ampliación reservada')}</dt><dd>−{financeMoney(totals.reserved)}</dd></div>}<div className={`finance-forecast-result ${totals.margin < 0 ? 'negative' : 'positive'}`}><dt>{tr(totals.margin < 0 ? 'Déficit previsto' : totals.reserved > 0 ? 'Resultado tras reservar ampliación' : 'Resultado previsto')}</dt><dd>{totals.margin > 0 ? '+' : ''}{financeMoney(totals.margin)}</dd></div></dl>
        <small>{tr('Previsión del conjunto de la temporada, incluidos los importes ya cobrados y pagados.')}</small>
    </section></div>;
}
