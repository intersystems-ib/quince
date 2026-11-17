import { getLocale, localize, tr, useLocale } from "./i18n";
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { api } from './api';
import { ErrorBox } from './components';
import ClubCrest from './ClubCrest';
import type { Page } from './types';
type Invitation = {
    id: string;
    opponentId: string;
    date: string;
    venue: 'home' | 'away';
    expiresOn: string;
    version: number;
};
export default function FriendlyInvitations({ names }: {
    names: Record<string, string>;
}) {
    useLocale();
    const qc = useQueryClient();
    const invitations = useQuery({ queryKey: ['friendly-invitations'], queryFn: () => api<Page<Invitation>>('/my-club/friendly-invitations') });
    const respond = useMutation({ mutationFn: ({ v, decision }: {
            v: Invitation;
            decision: 'accept' | 'reject';
        }) => api('/my-club/friendly-invitations', 'POST', { invitationId: v.id, version: v.version, decision }), onSuccess: () => { void qc.invalidateQueries(); } });
    if (invitations.error)
        return <ErrorBox error={invitations.error}/>;
    if (!invitations.data?.items.length)
        return null;
    const date = (value: string) => new Date(value + 'T12:00:00').toLocaleDateString(getLocale(), { weekday: 'long', day: 'numeric', month: 'long' });
    return <section className="card friendly-invitations" aria-label={tr("Invitaciones a amistosos")}><h3>{tr("Te proponen un amistoso")}</h3>{localize(invitations.data.items.map(v => <article key={v.id}><div className="invitation-opponent"><ClubCrest clubId={v.opponentId} name={names[v.opponentId]}/><div><strong>{localize(names[v.opponentId] ?? v.opponentId)}</strong><p>{localize(date(v.date))}{tr(" \u00B7 ")}{localize(v.venue === 'home' ? 'En casa' : 'Fuera de casa')}</p><small>{tr("Responder hasta el ")}{localize(date(v.expiresOn))}</small></div></div><div className="confirm-buttons"><button className="button secondary" disabled={respond.isPending} onClick={() => respond.mutate({ v, decision: 'reject' })}>{tr("Rechazar")}</button><button className="button dark" disabled={respond.isPending} onClick={() => respond.mutate({ v, decision: 'accept' })}>{tr("Aceptar amistoso")}</button></div></article>))}{localize(respond.error && <ErrorBox error={respond.error}/>)}</section>;
}
