import { getLocale, tr, useLocale } from './i18n';
import { money } from './components';
import type { CommunityPlan } from './types';

export default function ClubRevenueCard({ plan: p }: { plan: CommunityPlan }) {
    useLocale();
    return <section className="card club-revenue-card"><div className="card-top"><h3>{tr('Socios y actividad del club')}</h3><span className="tiny-tag">{tr('SEPTIEMBRE — JUNIO')}</span></div>
        <div className="club-revenue-columns"><div><h4>{tr('Socios')}</h4><p><strong>{p.memberCount.toLocaleString(getLocale())}</strong> · {money(p.memberFee)} {tr('por temporada')}</p><small>{tr('Cuota social independiente del abono de partidos.')}</small>
            <dl><div><dt>{tr('Cuotas sociales anuales')}</dt><dd>{money(p.annualMembersIncome)}</dd></div></dl>
            <h4>{tr('Otros ingresos')}</h4><dl><div><dt>{tr('Cuotas de categorías inferiores y escuelas')}</dt><dd>{money(p.annualYouthFees)}</dd></div><div><dt>{tr('Actividades, eventos y colaboraciones')}</dt><dd>{money(p.annualActivitiesIncome)}</dd></div></dl>
        </div><div><h4>{tr('Gastos asociados')}</h4><small>{tr('Escuelas y otras categorías fuera de la plantilla gestionada.')}</small><dl><div><dt>{tr('Entrenadores y coordinación de base')}</dt><dd>{money(p.annualCoachingCosts)}</dd></div><div><dt>{tr('Fichas y desplazamientos de base')}</dt><dd>{money(p.annualFederationTravelCosts)}</dd></div><div><dt>{tr('Instalaciones, material y administración')}</dt><dd>{money(p.annualFacilitiesCosts)}</dd></div></dl></div></div>
        <div className="club-revenue-summary"><h4>{tr('Previsión de esta temporada')}</h4><dl><div><dt>{tr('Socios')}</dt><dd>{money(p.plannedMembersIncome)}</dd></div><div><dt>{tr('Otros ingresos')}</dt><dd>{money(p.plannedOtherIncome)}</dd></div><div><dt>{tr('Gastos asociados')}</dt><dd>{money(p.plannedCosts)}</dd></div><div className="club-revenue-net"><dt>{tr('Aportación neta al club')}</dt><dd>{money(p.plannedMembersIncome + p.plannedOtherIncome - p.plannedCosts)}</dd></div></dl></div>
        <small>{tr('Cobros y gastos mensuales el día 21, de septiembre a junio.')}{p.firstInstalment > 0 && <> {tr('Previsión parcial desde')} {new Date(`${p.introducedOn}T12:00:00`).toLocaleDateString(getLocale())}.</>}</small>
    </section>;
}
