type CompetitionMatch={stage?:string;round?:number;groupId?:string;competitionType?:string;competitionKey?:string};
export function fixtureLabel(f:CompetitionMatch){
 const cup=f.competitionType==='cup'||f.competitionKey?.startsWith('cup-');
 const stage=f.stage==='quarterfinal'?'Cuartos de final':f.stage==='semifinal'?'Semifinal':f.stage==='final'?'Final':f.stage==='cup-group'?`Grupo ${f.groupId??''} · Jornada ${f.round}`:`Jornada ${f.round}`;
 return f.stage==='friendly'?'Amistoso':`${cup?'Copa del Rey':'Liga'} · ${stage}`;
}
export function fixtureShortLabel(f:CompetitionMatch){
 if(f.stage==='friendly')return 'Amistoso';
 if(f.stage==='cup-group')return `Copa · ${f.groupId}`;
 return `${f.competitionType==='cup'||f.competitionKey?.startsWith('cup-')?'Copa · ':''}${f.stage==='quarterfinal'?'Cuartos':f.stage==='semifinal'?'Semi':f.stage==='final'?'Final':`J${f.round}`}`;
}
