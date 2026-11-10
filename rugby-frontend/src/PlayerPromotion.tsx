import {useEffect,useRef,useState} from 'react';
import {createPortal} from 'react-dom';
import {useMutation,useQuery} from '@tanstack/react-query';
import {ArrowUpRight} from 'lucide-react';
import {api} from './api';
import {ErrorBox,Loading} from './components';
import {NegotiationPanel} from './TransfersView';
import type {Club,Negotiation,Page,Player} from './types';

export default function PlayerPromotion({player,renewal=false}:{player:Player;renewal?:boolean}){
 const [open,setOpen]=useState(false),[initial,setInitial]=useState<Negotiation>(),dialog=useRef<HTMLDialogElement>(null),key=useRef(crypto.randomUUID());
 const start=useMutation({mutationFn:()=>api<Negotiation>(renewal?`/players/${player.id}/renew`:`/my-club/academy/${player.id}/promote`,'POST',{version:player.version},key.current),onSuccess:n=>{key.current=crypto.randomUUID();setInitial(n);setOpen(true);}});
 useEffect(()=>{if(open)dialog.current?.showModal();else dialog.current?.close();},[open]);
 const current=useQuery({queryKey:['negotiation',initial?.id],queryFn:()=>api<Negotiation>(`/negotiations/${initial!.id}`),enabled:open&&!!initial,refetchInterval:open?15000:false});
 const club=useQuery({queryKey:['club'],queryFn:()=>api<Club>('/my-club'),enabled:open});
 const roster=useQuery({queryKey:['players'],queryFn:()=>api<Page<Player>>('/my-club/players'),enabled:open});
 const n=current.data??initial,weekly=roster.data?.items.reduce((sum,p)=>sum+p.weeklyWage,0)??0;
 return <div className="action-wrap"><button className="button secondary" disabled={start.isPending||!!player.retirementAnnounced} onClick={()=>start.mutate()}>{player.retirementAnnounced?'Retirada anunciada':start.isPending?'Contactando…':renewal?'Renovar':'Promocionar'}<ArrowUpRight size={15}/></button>{start.error&&<ErrorBox error={start.error}/>}{createPortal(<dialog ref={dialog} className="promotion-dialog" aria-label={`${renewal?"Negociar renovación de":"Negociar promoción de"} ${player.name}`} onCancel={e=>{e.preventDefault();setOpen(false);}}>{current.error&&<ErrorBox error={current.error}/>} {club.error&&<ErrorBox error={club.error}/>} {n&&club.data?<NegotiationPanel key={n.id} negotiation={n} club={club.data} weekly={weekly} onClose={()=>setOpen(false)}/>:<Loading/>}</dialog>,document.body)}</div>;
}
