import {useState} from 'react';

/** Local original artwork. A monogram keeps the layout usable if an asset cannot load. */
export default function ClubCrest({clubId,name='',className=''}:{clubId:string;name?:string;className?:string}){
 const [failedId,setFailedId]=useState<string|null>(null);
 const available=/^c([1-9]|1\d|20)$/.test(clubId)&&failedId!==clubId;
 return <span className={`club-crest ${className}`}>
  {available?<img src={`/crests/${clubId}.jpg`} alt={`Escudo de ${name||clubId}`} width="64" height="64" decoding="async" onError={()=>setFailedId(clubId)}/>:<span className="crest-fallback" role="img" aria-label={`Escudo no disponible de ${name||clubId}`}>{name.slice(0,2).toUpperCase()||'RC'}</span>}
 </span>;
}
