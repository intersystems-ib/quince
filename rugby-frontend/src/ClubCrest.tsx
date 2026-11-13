import {createContext,useContext,useState} from 'react';
import type {ReactNode} from 'react';
import {useQuery} from '@tanstack/react-query';
import {api} from './api';
const Crests=createContext<Record<string,string>>({});
export function CrestProvider({path,children}:{path:string;children:ReactNode}){
 const q=useQuery({queryKey:['crest-catalog',path],queryFn:()=>api<{items:{id:string;crestUrl?:string}[]}>(path)});
 return <Crests.Provider value={Object.fromEntries(q.data?.items.filter(c=>c.crestUrl).map(c=>[c.id,c.crestUrl!])??[])}>{children}</Crests.Provider>;
}
export default function ClubCrest({clubId,name='',className=''}:{clubId:string;name?:string;className?:string}){
 const custom=useContext(Crests)[clubId],src=custom??`/crests/${clubId}.jpg`,[failed,setFailed]=useState<string|null>(null);
 const available=(!!custom||/^c([1-9]|1\d|20)$/.test(clubId))&&failed!==src;
 return <span className={`club-crest ${className}`}>
  {available?<img src={src} alt={`Escudo de ${name||clubId}`} width="64" height="64" decoding="async" onError={()=>setFailed(src)}/>:<span className="crest-fallback" role="img" aria-label={`Escudo no disponible de ${name||clubId}`}>{name.slice(0,2).toUpperCase()||'RC'}</span>}
 </span>;
}
