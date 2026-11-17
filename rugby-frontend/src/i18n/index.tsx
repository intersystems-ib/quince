import {useSyncExternalStore} from 'react';
import translations from './translations.json' with {type:'json'};
import errorTranslations from './errors.json' with {type:'json'};
export type Language='es'|'en'|'fr';
const locales:Record<Language,string>={es:'es-ES',en:'en-GB',fr:'fr-FR'};
const listeners=new Set<()=>void>();
let language:Language='es';
try{const saved=localStorage.getItem('quince-language');if(saved==='es'||saved==='en'||saved==='fr')language=saved;}catch{/* Preferences may be unavailable in private browsing. */}
export const getLanguage=()=>language;
export const getLocale=()=>locales[language];
function syncDocument(){if(typeof document!=='undefined'){document.documentElement.lang=language;document.title=language==='fr'?'Quince · Manager de club de rugby':'Quince · Rugby Club Manager';}}
syncDocument();
export function setLanguage(value:Language){if(value===language)return;language=value;try{localStorage.setItem('quince-language',value);}catch{/* The choice still applies to this session. */}syncDocument();[...listeners].forEach(listener=>listener());}
const subscribe=(listener:()=>void)=>{listeners.add(listener);return()=>{listeners.delete(listener);};};
export function useLocale(){return useSyncExternalStore(subscribe,getLanguage,()=> 'es' as Language);}
type Entry=[string,string];
const catalog=translations as unknown as Record<string,Entry>;
const normalize=(s:string)=>s.normalize('NFC').replace(/\s+/g,' ').trim();
const folded=new Map(Object.keys(catalog).filter(key=>!key.includes('{')).map(key=>[normalize(key).toLocaleLowerCase('es'),key]));
const patterns=Object.entries(catalog).filter(([key])=>key.includes('{')).sort((a,b)=>b[0].replace(/\{\d+\}/g,'').length-a[0].replace(/\{\d+\}/g,'').length).map(([key,value])=>{const slots:number[]=[];let pattern='',end=0;for(const match of normalize(key).matchAll(/\{(\d+)\}/g)){pattern+=normalize(key).slice(end,match.index).replace(/[.*+?^${}()|[\]\\]/g,'\\$&')+'(.*?)';slots.push(Number(match[1]));end=match.index!+match[0].length;}pattern+=normalize(key).slice(end).replace(/[.*+?^${}()|[\]\\]/g,'\\$&');return {regex:new RegExp('^'+pattern+'$','u'),slots,value,key};});
const translatedSlots:Record<string,number[]>={
 'Entrenamiento · {0}':[0],
 '{0} Partido en pausa: revisa la sustitución y selecciona una velocidad para continuar.':[0],
 'Balón en {0}, {1}. Ataca {2} hacia la {3}. {4} defiende la mitad {5} y {6} la {7}. Posiciones simuladas de los jugadores, numeradas por puesto.':[3,5,7],
 'Fin de temporada · {0} · {1}':[1],
 'Lesionado: {0}. {1}':[0,1],
 'Lesión: {0} · regreso previsto {1}':[0],
 '{0} de {1} {2} en la temporada{3}':[0,2],
 '{0} {1} {2}por {3} mensuales durante {4} {5}. {6}':[0,2,5,6],
 '{0} · Grado {1} · {2} sem. · Alta {3}':[0],
 '{0} · Ritmo {1} · Presión {2} · Golpes: {3}':[0,1,2,3],
 '{0} · {1} años · {2} · {3}':[0,2,3],
 '{0} · {1} · Media {2}':[0,1],
 '{0}Conviene reservar {1} ({2}) para descanso y recuperación{3}.':[0,2,3],
 '{0} (grado {1}). Baja de {2} {3}.':[0,3],
 '{0} ganada por el equipo que introduce.':[0],
 '{0} robada por el rival.':[0]
};
const cache=new Map<string,string>();
function translate(source:string,depth=0):string{
 if(language==='es'||!source.trim()||depth>3)return source;
 const token=language+'|'+source,cached=cache.get(token);if(cached!==undefined)return cached;
 const key=normalize(source),index=language==='en'?0:1;
 const exact=catalog[key]??catalog[folded.get(key.toLocaleLowerCase('es'))??''];
 let translated=exact?.[index];
 if(translated&&key===key.toLocaleUpperCase('es')&&/[A-ZÁÉÍÓÚÑ]/.test(key))translated=translated.toLocaleUpperCase(getLocale());
 if(!translated){for(const pattern of patterns){const match=pattern.regex.exec(key);if(!match)continue;const args:Record<number,string>={};pattern.slots.forEach((slot,i)=>{args[slot]=translatedSlots[pattern.key]?.includes(slot)?translate(match[i+1],depth+1):match[i+1];});translated=pattern.value[index].replace(/\{(\d+)\}/g,(_,slot)=>args[Number(slot)]??'');break;}}
 if(!translated&&depth<3){
  const sentences=source.split(/(?<=\.)\s+(?=[A-ZÁÉÍÓÚÑ¡¿])/u);
  if(sentences.length>1){const parts=sentences.map(part=>translate(part,depth+1));if(parts.some((part,i)=>part!==sentences[i]))translated=parts.join(' ');}
  if(!translated&&key.endsWith('.')){const stem=translate(key.slice(0,-1),depth+1);if(stem!==key.slice(0,-1))translated=stem+'.';}
 }
 if(!translated){if(cache.size>5000)cache.clear();cache.set(token,source);return source;}
 const result=(source.match(/^\s*/)?.[0]??'')+translated+(source.match(/\s*$/)?.[0]??'');
 if(cache.size>5000)cache.clear();cache.set(token,result);return result;
}
export function tr<T>(value:T):T{return (typeof value==='string'?translate(value):value) as T;}
export function localize<T>(value:T):T{return (typeof value==='string'?translate(value):Array.isArray(value)?value.map(item=>localize(item)):value) as T;}
export function LanguageSelector(){const current=useLocale();return <select className="language-selector" title="Español · English · Français" aria-label={current==='en'?'Language':current==='fr'?'Langue':'Idioma'} value={current} onChange={event=>setLanguage(event.target.value as Language)}><option value="es" lang="es" aria-label="Español">ES</option><option value="en" lang="en" aria-label="English">EN</option><option value="fr" lang="fr" aria-label="Français">FR</option></select>;}

export function localizedError(error:unknown):string{
 const details=error as {code?:string;message?:string;name?:string}|null;
 const message=error instanceof Error?error.message:details?.message??'No se han podido cargar los datos.';
 if(language==='es')return message;
 const translated=translate(message);if(translated!==message)return translated;
 const entry=(errorTranslations as Record<string,string[]>)[details?.code??''];
 if(entry)return entry[language==='en'?0:1];
 if(details?.name==='AbortError')return language==='en'?'The request timed out. Please try again.':'Le délai de la requête a expiré. Réessayez.';
 return message;
}
