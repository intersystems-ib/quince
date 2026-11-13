import {requestId} from './requestId';
export class ApiError extends Error { constructor(public status:number, public code:string, message:string) { super(message); } }
let game:{id:string;clubId:string}|null=null;
export const getGameId=()=>game?.id??null;
export const getClubId=()=>game?.clubId??'c1';
export const setGame=(value:{id:string;clubId:string}|null)=>{game=value;};
export async function api<T>(path:string, method='GET', body?:unknown, key?:string):Promise<T> {
  const controller = new AbortController();
  const timeout = setTimeout(()=>controller.abort(),path==='/games'?120000:30000);
  try {
    const resolved=path.replace(/^\/my-club(?=\/|\?|$)/,`/clubs/${getClubId()}`);
    const response = await fetch(`/api/v1${resolved}`, {method,credentials:'same-origin',signal:controller.signal,headers:{'Content-Type':'application/json',...(game?{'X-Game-Id':game.id}:{}),...(method!=='GET'?{'Idempotency-Key':key||requestId()}: {})},body:body===undefined?undefined:JSON.stringify(body)});
    const text=await response.text();
    let data; try {data=JSON.parse(text);} catch {throw new Error('El servidor no ha devuelto JSON. Comprueba que IRIS y la pasarela están disponibles.');}
    if (!response.ok) {if(response.status===401&&!path.startsWith('/auth/'))window.dispatchEvent(new Event('session-expired'));throw new ApiError(response.status,data.code,data.message);}
    return data as T;
  } finally {clearTimeout(timeout);}
}
