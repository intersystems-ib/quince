import {Action} from './components';
import type {Player} from './types';

export default function PlayerRelease({player,onSuccess}:{player:Player;onSuccess?:()=>void}){
 return <Action path={`/players/${player.id}/release`} body={{version:player.version}} className="danger" onSuccess={onSuccess} confirmMessage={`¿Rescindir el contrato de ${player.name}?\n\nSaldrá ${player.category==='academy'?'de la cantera':'del primer equipo'} y de sus grupos de entrenamiento. Si está en una alineación, tendrás que revisarla.\n\nQuedará libre, sin indemnización. Se conservará su historial.`}>Rescindir contrato</Action>;
}
