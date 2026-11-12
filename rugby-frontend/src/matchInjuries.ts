import type {Match} from './types';

export function injuryEventMessage(match:Match,playerId?:string){
 const player=[...match.homePlayers,...match.awayPlayers].find(p=>p.playerId===playerId);
 return `${player?.name||'Un jugador'} se ha lesionado y abandona el campo.`;
}

export function injuryPauseMessage(match:Match){
 return `${injuryEventMessage(match,match.pausedPlayerId)} Partido en pausa: revisa la sustitución y selecciona una velocidad para continuar.`;
}
