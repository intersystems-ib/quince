import { getLocale, localize, tr, useLocale } from "./i18n";
import { useEffect, useState } from 'react';
import { Action } from './components';
import { monthlySalary } from './salary';
import type { FinancialView } from './types';
const money = (value: number) => new Intl.NumberFormat(getLocale(), { style: 'currency', currency: 'EUR', minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(value / 100);
export default function FinanceSalary({ finance: f }: {
    finance: FinancialView;
}) {
    useLocale();
    const b = f.salaryBudget, [percent, setPercent] = useState(b?.percent ?? 0), [saved, setSaved] = useState(false);
    useEffect(() => { setPercent(b?.percent ?? 0); }, [b?.percent, b?.year]);
    const extra = b ? Math.floor(b.surplusAtBaseLimit * percent / 100) : 0, dirty = !!b && percent !== b.percent;
    const p = f.payroll, rows = [['Primer equipo', p.annualSenior], ['Cantera', p.annualAcademy], ['Cuerpo técnico', p.annualStaff], ['Financiero', p.annualDirector]] as const;
    const annual = rows.reduce((sum, [, value]) => sum + value, 0), players = p.monthlyPlayers ?? p.annualPlayers / 12, limit = b ? (b.baseAnnualLimit + extra) / 12 : players + (p.monthlyAvailable ?? monthlySalary(p.weeklyAvailable)), available = limit - players;
    const used = limit > 0 ? Math.min(100, Math.max(0, players / limit * 100)) : players > 0 ? 100 : 0;

    return <div className="finance-columns finance-salary"><section className="card finance-detail-card"><div className="card-top"><h3>{tr("Presupuesto salarial")}</h3><span className="pill">{tr("N\u00D3MINAS MENSUALES")}</span></div>
  <div className="finance-payroll-breakdown"><div className="finance-payroll-total"><small>{tr("N\u00F3mina total del club")}</small><strong>{localize(money(annual / 12))} <span>{tr("/ mes")}</span></strong></div>
   <table aria-label={tr("Desglose de salarios")}><thead><tr><th>{tr("Personal")}</th><th>{tr("Al mes")}</th><th>{tr("Al a\u00F1o")}</th></tr></thead><tbody>{localize(rows.map(([name, value]) => <tr key={name}><td>{localize(name)}</td><td>{localize(money(value / 12))}</td><td>{localize(money(value))}</td></tr>))}</tbody><tfoot><tr><th>{tr("Total")}</th><td>{localize(money(annual / 12))}</td><td>{localize(money(annual))}</td></tr></tfoot></table>
   <p className="finance-payroll-note">{tr("Pago al final de cada mes, con prorrateo por d\u00EDas en las incorporaciones.")}</p>

  </div></section><section className={`card finance-detail-card finance-player-budget ${available < 0 ? 'over-budget' : ''}`} aria-label={tr("Presupuesto de jugadores")}><div className="card-top"><h3>{localize(available < 0 ? 'Exceso sobre el límite de jugadores' : 'Disponible para salarios de jugadores')}</h3><span className="pill">{tr("N\u00D3MINAS MENSUALES")}</span></div><strong>{localize(money(Math.abs(available)))} <span>{tr("/ mes")}</span></strong><div className="finance-budget-bar" role="progressbar" aria-label={tr("Presupuesto salarial de jugadores comprometido")} aria-valuemin={0} aria-valuemax={100} aria-valuenow={Math.round(used)} aria-valuetext={`${money(players)} de ${money(limit)} mensuales`}><i style={{ width: `${used}%` }}/></div><div className="finance-budget-amounts"><span>{tr("Comprometido ")}<b>{localize(money(players))}</b></span><span>{tr("L\u00EDmite mensual ")}<b>{localize(money(limit))}</b></span></div>
   {localize(b && <div className="finance-salary-flex" role="group" aria-label={tr("Ampliación del límite salarial")}><div className="card-top"><h4>{tr("Reinvertir super\u00E1vit en fichajes")}</h4><strong>{localize(percent)}{tr("%")}</strong></div><label htmlFor="salary-reinvest">{tr("Super\u00E1vit adicional destinado a salarios")}<input id="salary-reinvest" type="range" min={0} max={b.maxPercent} step={1} value={percent} aria-valuetext={`${percent}% · ${money(extra / 12)} adicionales al mes`} disabled={b.surplusAtBaseLimit <= 0 && b.percent === 0} onChange={e => { setPercent(Number(e.target.value)); setSaved(false); }}/></label><div className="finance-slider-scale"><span>{tr("0% \u00B7 Conservar margen")}</span><span>{localize(b.maxPercent)}{tr("% \u00B7 M\u00E1s fichajes")}</span></div><dl><div><dt>{tr("Ampliaci\u00F3n mensual")}</dt><dd>{tr("+")}{localize(money(extra / 12))}</dd></div>{localize(b.surplusAtBaseLimit > 0 && <div className="positive"><dt>{tr("Super\u00E1vit usando todo el l\u00EDmite")}</dt><dd>{localize(money(b.projectedIncome - b.otherAnnualCosts - b.baseAnnualLimit - extra))}</dd></div>)}</dl>{localize(b.surplusAtBaseLimit <= 0 && <p className="muted">{tr("El l\u00EDmite actual ya cubre el margen disponible. No hay super\u00E1vit adicional para ampliarlo.")}</p>)}<Action path="/my-club/salary-budget" method="PUT" body={{ version: b.version, percent }} disabled={!dirty} className="dark" errorResetKey={`${b.version}-${percent}`} onSuccess={() => setSaved(true)}>{tr("Guardar l\u00EDmite salarial")}</Action>{localize(dirty && <small role="status">{tr("Vista previa \u00B7 pendiente de guardar")}</small>)}{localize(saved && !dirty && <small className="positive" role="status">{tr("L\u00EDmite salarial guardado.")}</small>)}</div>)}</section>

 </div>;
}
