import {useMutation,useQuery,useQueryClient} from '@tanstack/react-query';
import {api} from './api';
import {ErrorBox} from './components';
import ClubCrest from './ClubCrest';
import type {Page} from './types';
type Invitation={id:string;opponentId:string;date:string;venue:'home'|'away';expiresOn:string;version:number};
export default function FriendlyInvitations({names}:{names:Record<string,string>}){
 const qc=useQueryClient();
 const invitations=useQuery({queryKey:['friendly-invitations'],queryFn:()=>api<Page<Invitation>>('/my-club/friendly-invitations')});
 const respond=useMutation({mutationFn:({v,decision}:{v:Invitation;decision:'accept'|'reject'})=>api('/my-club/friendly-invitations','POST',{invitationId:v.id,version:v.version,decision}),onSuccess:()=>{void qc.invalidateQueries();}});
 if(invitations.error)return <ErrorBox error={invitations.error}/>;
 if(!invitations.data?.items.length)return null;
 const date=(value:string)=>new Date(value+'T12:00:00').toLocaleDateString('es-ES',{weekday:'long',day:'numeric',month:'long'});
 return <section className="card friendly-invitations" aria-label="Invitaciones a amistosos"><h3>Te proponen un amistoso</h3>{invitations.data.items.map(v=><article key={v.id}><div className="invitation-opponent"><ClubCrest clubId={v.opponentId} name={names[v.opponentId]}/><div><strong>{names[v.opponentId]??v.opponentId}</strong><p>{date(v.date)} · {v.venue==='home'?'En casa':'Fuera de casa'}</p><small>Responder hasta el {date(v.expiresOn)}</small></div></div><div className="confirm-buttons"><button className="button secondary" disabled={respond.isPending} onClick={()=>respond.mutate({v,decision:'reject'})}>Rechazar</button><button className="button dark" disabled={respond.isPending} onClick={()=>respond.mutate({v,decision:'accept'})}>Aceptar amistoso</button></div></article>)}{respond.error&&<ErrorBox error={respond.error}/>}</section>;
}
