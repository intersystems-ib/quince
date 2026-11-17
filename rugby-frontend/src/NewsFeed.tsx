import { getLocale, localize, tr, useLocale } from "./i18n";
import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { Activity, Briefcase, UserPlus, Flag } from 'lucide-react';
import { api } from './api';
import { ErrorBox, Loading } from './components';
import ClubCrest from './ClubCrest';
import type { Page } from './types';
type News = {
    id: string;
    type: 'injury' | 'playerSigning' | 'staffSigning' | 'retirement';
    date: string;
    clubId: string;
    clubName: string;
    personName: string;
    playerId: string;
    title: string;
    text: string;
    category?: string;
    role?: string;
};
const labels = { injury: 'Lesión', playerSigning: 'Fichaje', staffSigning: 'Empleado', retirement: 'Retirada' };
export default function NewsFeed({ date }: {
    date: string;
}) {
    useLocale();
    const [page, setPage] = useState(0);
    const q = useQuery({ queryKey: ['news', date, page], queryFn: () => api<Page<News> & {
            fromDate: string;
            toDate: string;
        }>(`/news?offset=${page * 10}&limit=10`) });
    return <section className="card club-news"><div className="card-top"><h3>{tr("\u00DAltimas noticias")}</h3><span className="tiny-tag">{tr("\u00DALTIMOS 7 D\u00CDAS")}</span></div>{localize(q.isLoading ? <Loading /> : q.error ? <ErrorBox error={q.error}/> : q.data && <>{localize(!q.data.total ? <p className="empty">{tr("No hay noticias en los \u00FAltimos siete d\u00EDas.")}</p> : <ul className="club-news-list">{localize(q.data.items.map(n => <li key={n.id}><ClubCrest clubId={n.clubId} name={n.clubName}/><div><div className={`news-meta news-${n.type}`}>{localize(n.type === 'retirement' ? <Flag size={13}/> : n.type === 'injury' ? <Activity size={13}/> : n.type === 'playerSigning' ? <UserPlus size={13}/> : <Briefcase size={13}/>)}<span>{localize(labels[n.type])}{localize(n.category === 'academy' ? ' · Cantera' : '')}</span><time dateTime={n.date}>{localize(new Date(n.date + 'T12:00:00').toLocaleDateString(getLocale(), { day: 'numeric', month: 'short' }))}</time></div><h4>{localize(n.playerId ? <Link to={`/jugadores/${n.playerId}`}>{localize(n.title)}</Link> : n.title)}</h4><p>{n.clubName}{tr(" \u00B7 ")}{localize(n.text)}</p></div></li>))}</ul>)}{localize(q.data.total > 10 && <div className="toolbar news-pagination"><button className="button secondary" disabled={!page} onClick={() => setPage(page - 1)}>{tr("Anterior")}</button><span>{tr("P\u00E1gina ")}{localize(page + 1)}{tr(" de ")}{localize(Math.ceil(q.data.total / 10))}</span><button className="button secondary" disabled={(page + 1) * 10 >= q.data.total} onClick={() => setPage(page + 1)}>{tr("Siguiente")}</button></div>)}</>)}</section>;
}
