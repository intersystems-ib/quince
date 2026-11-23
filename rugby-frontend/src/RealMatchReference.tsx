import {tr} from './i18n';
import type {Player} from './types';

export default function RealMatchReference({player}:{player:Player}) {
 const fer=player.ferReference, reference=fer??player.lnrReference;
 if(!reference)return null;
 return <section className="card"><div className="card-top"><h3>{tr(fer?'Referencia FER':'Referencia LNR')} · {player.identitySeason}</h3><a href={reference.sourceUrl||player.identitySourceUrl} target="_blank" rel="noreferrer">{tr('Fuente oficial ')}</a></div><div className="training-summary">
  <span>{tr('Partidos')} <b>{reference.appearances}</b></span>
  <span>{tr('Titularidades')} <b>{reference.starts??0}</b></span>
  <span>{tr('Convocatorias como suplente')} <b>{reference.benchSelections??0}</b></span>
  {(!fer||fer.minutesMatches>0)&&<span>{tr(fer?'Minutos reconstruidos':'Minutos')} <b>{Math.round(reference.minutes)}</b></span>}
  {(fer||player.lnrReference?.pointsValidated!==false)&&<span>{tr('Puntos')} <b>{reference.points}</b></span>}
  <span>{tr('Ensayos')} <b>{reference.tries}</b></span>
  {fer?<><span>{tr('Transformaciones')} <b>{fer.conversions}</b></span><span>{tr('Penalties')} <b>{fer.penalties+fer.drops}</b></span></>:<span>{tr('Placajes')} <b>{player.lnrReference?.tackles}</b></span>}
 </div>{player.lnrReference?.matchEligible===false&&<p className="muted">{tr("Plantilla oficial LNR. Sin participación en las actas consultadas; características estimadas.")}</p>}{fer&&!fer.minutesComplete&&<p className="muted">{tr('Los minutos excluyen las actas con cambios ambiguos o no disponibles.')}</p>}</section>;
}
