import {getLanguage,tr} from './i18n';
type CompetitionMatch={stage?:string;round?:number;groupId?:string;competitionType?:string;competitionKey?:string};
export function fixtureLabel(f:CompetitionMatch){
 const cup=f.competitionType==='cup'||f.competitionKey?.startsWith('cup-');
 const stage=f.stage==='quarterfinal'?'Cuartos de final':f.stage==='semifinal'?'Semifinal':f.stage==='final'?'Final':f.stage==='cup-group'?`Grupo ${f.groupId??''} · Jornada ${f.round}`:`Jornada ${f.round}`;
 return f.stage==='friendly'?tr('Amistoso'):`${tr(cup?'Copa del Rey':'Liga')} · ${tr(stage)}`;
}
export function fixtureShortLabel(f:CompetitionMatch){
 if(f.stage==='friendly')return tr('Amistoso');
 if(f.stage==='cup-group')return `${tr('Copa')} · ${f.groupId}`;
 return `${f.competitionType==='cup'||f.competitionKey?.startsWith('cup-')?tr('Copa')+' · ':''}${f.stage==='quarterfinal'?tr('Cuartos'):f.stage==='semifinal'?tr('Semi'):f.stage==='final'?tr('Final'):`${getLanguage()==='en'?'R':'J'}${f.round}`}`;
}
