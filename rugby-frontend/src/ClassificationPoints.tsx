import { localize, tr, useLocale } from "./i18n";
import type { Classification, LeaguePoints } from './types';
function Breakdown({ points }: {
    points: LeaguePoints;
}) { useLocale(); return <><b>{localize(points.total)}{tr(" puntos")}</b><small>{localize(points.basePoints)}{tr(" por resultado")}{localize(points.bonusOffensive ? ' + 1 BO' : '')}{localize(points.bonusDefensive ? ' + 1 BD' : '')}</small></>; }
export default function ClassificationPoints({ value, home, away }: {
    value?: Classification;
    home: string;
    away: string;
}) {
    useLocale();
    if (!value?.eligible || !value.home || !value.away)
        return null;
    return <div className="classification-points" aria-label={tr("Puntos de clasificación del partido")}><span>{tr("Puntos de clasificaci\u00F3n")}</span><div><strong>{localize(home)}</strong><Breakdown points={value.home}/></div><div><strong>{localize(away)}</strong><Breakdown points={value.away}/></div></div>;
}
