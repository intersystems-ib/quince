import {monthlySalary} from './salary';
import type {FinancialView} from './types';

const money=(value:number)=>new Intl.NumberFormat('es-ES',{style:'currency',currency:'EUR',minimumFractionDigits:2,maximumFractionDigits:2}).format(value/100);

export default function FinanceSalary({finance:f}:{finance:FinancialView}){
 const p=f.payroll,rows=[['Primer equipo',p.annualSenior],['Cantera',p.annualAcademy],['Cuerpo técnico',p.annualStaff],['Financiero',p.annualDirector]] as const;
 const annual=rows.reduce((sum,[,value])=>sum+value,0),players=p.monthlyPlayers??p.annualPlayers/12,available=p.monthlyAvailable??monthlySalary(p.weeklyAvailable),limit=players+available;
 const used=limit>0?Math.min(100,Math.max(0,players/limit*100)):players>0?100:0;
 const income=f.financialPlan?.projectedIncome??f.fundingReference,costs=f.financialPlan?.projectedCosts??p.annualProjectedCosts,margin=income-costs;
 return <section className="card finance-salary"><div className="card-top"><h3>Presupuesto salarial</h3><span className="tiny-tag">NÓMINAS MENSUALES</span></div>
  <div className="finance-payroll-layout"><div className="finance-payroll-breakdown"><div className="finance-payroll-total"><small>Nómina total del club</small><strong>{money(annual/12)} <span>/ mes</span></strong></div>
   <table aria-label="Desglose de salarios"><thead><tr><th>Personal</th><th>Al mes</th><th>Al año</th></tr></thead><tbody>{rows.map(([name,value])=><tr key={name}><td>{name}</td><td>{money(value/12)}</td><td>{money(value)}</td></tr>)}</tbody><tfoot><tr><th>Total</th><td>{money(annual/12)}</td><td>{money(annual)}</td></tr></tfoot></table>
   <p className="finance-payroll-note">Pago al final de cada mes, con prorrateo por días en las incorporaciones.</p>
  </div><div className="finance-payroll-context"><section className={`finance-player-budget ${available<0?'over-budget':''}`} aria-label="Presupuesto de jugadores"><h4>{available<0?'Exceso sobre el límite de jugadores':'Disponible para salarios de jugadores'}</h4><strong>{money(Math.abs(available))} <span>/ mes</span></strong><div className="finance-budget-bar" role="progressbar" aria-label="Presupuesto salarial de jugadores comprometido" aria-valuemin={0} aria-valuemax={100} aria-valuenow={Math.round(used)} aria-valuetext={`${money(players)} de ${money(limit)} mensuales`}><i style={{width:`${used}%`}}/></div><div className="finance-budget-amounts"><span>Comprometido <b>{money(players)}</b></span><span>Límite mensual <b>{money(limit)}</b></span></div><small>El límite se aplica sólo a jugadores.</small></section>
   <section className="finance-season-forecast" aria-label="Previsión económica de temporada"><div className="card-top"><h4>Previsión de temporada</h4>{f.financialPlan?.provisional&&<span className="tiny-tag">PROVISIONAL</span>}</div><dl><div><dt>Ingresos previstos</dt><dd>{money(income)}</dd></div><div><dt>Gastos previstos</dt><dd>{money(costs)}</dd></div><div className={`finance-forecast-result ${margin<0?'negative':'positive'}`}><dt>{margin<0?'Déficit previsto':'Resultado previsto'}</dt><dd>{margin>0?'+':''}{money(margin)}</dd></div></dl><small>Gastos de todo el club: salarios, fichas y desplazamientos.</small></section>
  </div></div>
 </section>;
}
