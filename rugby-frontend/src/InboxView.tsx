import { useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { Bell, Check, ClipboardList, HeartPulse, Mail, MailOpen, Handshake } from 'lucide-react';
import { api } from './api';
import { ErrorBox, Heading, Loading, money } from './components';
import { getLocale, tr, useLocale } from './i18n';
import type { Club } from './types';

export type ClubNotice = {
    id: string; type: 'injury' | 'sale' | 'contract' | 'staff'; date: string;
    title: string; path: string; personName: string; playerId: string; read: boolean;
    contractEndDate?: string; category?: string; retiring?: boolean; role?: string;
    buyerName?: string; fee?: number;
};
type Inbox = { items: ClubNotice[]; total: number; unread: number; date: string };
export function useInbox(club?: Club, enabled = true) {
    return useQuery({ queryKey: ['inbox', club?.id, club?.date], queryFn: () => api<Inbox>('/my-club/inbox'), enabled: !!club && enabled, staleTime: 15000 });
}
export function InboxBadge({ count }: { count: number }) {
    return count > 0 ? <span className="inbox-count">{count > 99 ? '99+' : count}</span> : null;
}
const labels = { injury: 'Lesión', sale: 'Venta', contract: 'Contrato', staff: 'Personal' };
const icons = { injury: HeartPulse, sale: Handshake, contract: ClipboardList, staff: Bell };
const formatDate = (date: string) => new Date(`${date}T12:00:00`).toLocaleDateString(getLocale());

export default function InboxView({ club }: { club: Club }) {
    useLocale();
    const q = useInbox(club), qc = useQueryClient(), [filter, setFilter] = useState('all'), [page, setPage] = useState(0);
    const mark = useMutation({ mutationFn: async ({ ids, read }: { ids: string[]; read: boolean }) => {
        for (let i = 0; i < ids.length; i += 500) await api('/my-club/inbox', 'POST', { ids: ids.slice(i, i + 500), read });
    }, onSuccess: () => { void qc.invalidateQueries({ queryKey: ['inbox'] }); } });
    if (q.isLoading) return <Loading />;
    if (q.error) return <ErrorBox error={q.error} />;
    if (!q.data) return null;
    const items = q.data.items.filter(item => filter === 'all' || !item.read).sort((a, b) => Number(a.read) - Number(b.read) || b.date.localeCompare(a.date) || a.id.localeCompare(b.id));
    const current = Math.min(page, Math.max(0, Math.ceil(items.length / 20) - 1));
    return <><Heading eyebrow="GESTIÓN DEL CLUB" title="Buzón de avisos" />
        <div className="inbox-toolbar"><div className="competition-tabs" role="tablist" aria-label={tr('Filtrar avisos')}>
            <button role="tab" aria-selected={filter === 'all'} onClick={() => { setFilter('all'); setPage(0); }}>{tr('Todos')} ({q.data.total})</button>
            <button role="tab" aria-selected={filter === 'unread'} onClick={() => { setFilter('unread'); setPage(0); }}>{tr('Sin leer')} ({q.data.unread})</button>
        </div><button className="button secondary" disabled={mark.isPending || !q.data.unread} onClick={() => mark.mutate({ ids: q.data!.items.filter(item => !item.read).map(item => item.id), read: true })}>{tr('Marcar todos como leídos')}</button></div>
        {mark.error && <ErrorBox error={mark.error} onDismiss={() => mark.reset()} />}
        <section className="card inbox-list" aria-label={tr('Avisos del club')}>
            {!items.length ? <p className="empty">{tr(filter === 'unread' ? 'No tienes avisos sin leer.' : 'No hay avisos pendientes.')}</p> : <ul>{items.slice(current * 20, current * 20 + 20).map(item => {
                const Icon = icons[item.type];
                return <li key={item.id} className={`inbox-item ${item.read ? 'is-read' : 'is-unread'}`}>
                    <span className={`inbox-icon inbox-${item.type}`}><Icon size={21} /></span>
                    <div className="inbox-content"><div className="inbox-meta"><span>{tr(labels[item.type])}{!item.read && <span className="inbox-unread-dot" aria-label={tr('Sin leer')} />}</span><time dateTime={item.date}>{formatDate(item.date)}</time></div>
                        <h3>{tr(item.title)}</h3>
                        {item.personName && <p className="inbox-person">{item.personName}</p>}
                        {item.type === 'injury' && <p>{tr('Revisa la alineación y sustituye al jugador lesionado.')}</p>}
                        {item.type === 'contract' && <p>{tr(item.category === 'academy' ? 'Cantera' : 'Primer equipo')} · {tr('Contrato hasta')} {formatDate(item.contractEndDate!)}{item.retiring ? ` · ${tr('Retirada anunciada')}` : ''}</p>}
                        {item.type === 'sale' && <p>{item.buyerName} · {money(item.fee ?? 0)}</p>}
                        {item.type === 'staff' && <p>{tr(item.role ?? '')}</p>}
                        <div className="inbox-actions"><Link className="button secondary" to={item.path}>{tr(item.type === 'injury' ? 'Revisar alineación' : item.type === 'staff' ? 'Contratar' : 'Ver jugador')}</Link>
                            <button className="button secondary" disabled={mark.isPending} onClick={() => mark.mutate({ ids: [item.id], read: !item.read })}>{item.read ? <Mail size={15} /> : <Check size={15} />}{tr(item.read ? 'Marcar como no leído' : 'Marcar como leído')}</button>
                        </div>
                    </div>
                </li>;
            })}</ul>}
        </section>
        {items.length > 20 && <div className="toolbar news-pagination"><button className="button secondary" disabled={!current} onClick={() => setPage(current - 1)}>{tr('Anterior')}</button><span>{current + 1} / {Math.ceil(items.length / 20)}</span><button className="button secondary" disabled={(current + 1) * 20 >= items.length} onClick={() => setPage(current + 1)}>{tr('Siguiente')}</button></div>}
        <p className="muted inbox-note"><MailOpen size={16} />{tr('Los avisos de lesiones, contratos y puestos vacantes desaparecen cuando se resuelven. Las ventas permanecen en el buzón.')}</p>
    </>;
}
