import { LanguageSelector, getLocale, localize, tr, useLocale } from "./i18n";
import { requestId } from './requestId';
import { useEffect, useRef, useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import { ArrowRight, FolderOpen, Plus, LogOut, Trash2 } from 'lucide-react';
import { api, setGame } from './api';
import { ErrorBox, Loading } from './components';
import ClubCrest from './ClubCrest';
import App from './App';
import AdminView from './AdminView';
import { CrestProvider } from './ClubCrest';
import type { Club } from './types';
type User = {
    id: string;
    username: string;
    role?: 'manager' | 'admin';
};
type Game = {
    id: string;
    name: string;
    clubId: string;
    clubName: string;
    divisionId: number;
    division: string;
    date: string;
};
export default function SessionGate() {
    useLocale();
    const [user, setUser] = useState<User | null | undefined>(undefined), [active, setActive] = useState<Game | null>(null), [error, setError] = useState<unknown>(), qc = useQueryClient(), nav = useNavigate();
    useEffect(() => {
        api<User>('/auth/me').then(async (u) => {
            const saved = sessionStorage.getItem('quince-game');
            if (u.role === 'admin') {
                sessionStorage.removeItem('quince-game');
                setGame(null);
            }
            if (saved && u.role !== 'admin') {
                try {
                    const game = await api<Game>(`/games/${saved}/load`, 'POST', {});
                    setGame(game);
                    setActive(game);
                }
                catch {
                    sessionStorage.removeItem('quince-game');
                }
            }
            setUser(u);
        }).catch(() => { sessionStorage.removeItem('quince-game'); setUser(null); });
        const expired = () => { sessionStorage.removeItem('quince-game'); setGame(null); setActive(null); setUser(null); qc.clear(); };
        window.addEventListener('session-expired', expired);
        return () => window.removeEventListener('session-expired', expired);
    }, [qc]);
    async function load(game: Game) { await api(`/games/${game.id}/load`, 'POST', {}); qc.clear(); setGame(game); sessionStorage.setItem('quince-game', game.id); setActive(game); nav('/'); }
    async function leave() {
        try {
            if (active)
                await api(`/games/${active.id}/unload`, 'POST', {});
            sessionStorage.removeItem('quince-game');
            setGame(null);
            qc.clear();
            setActive(null);
            setError(undefined);
            nav('/');
        }
        catch (e) {
            setError(e);
        }
    }
    async function logout() { await api('/auth/logout', 'POST', {}); sessionStorage.removeItem('quince-game'); setGame(null); setActive(null); setUser(null); qc.clear(); }
    if (user === undefined)
        return <div className="session-page"><Loading /></div>;
    if (!user)
        return <Access onAccess={setUser}/>;
    if (user.role === 'admin')
        return <CrestProvider path="/admin/clubs"><AdminView username={user.username} onLogout={logout}/></CrestProvider>;
    if (active)
        return <>{localize(!!error && <ErrorBox error={error}/>)}<CrestProvider path="/clubs"><App username={user.username} onLeave={() => void leave()}/></CrestProvider></>;
    return <CrestProvider path="/game-catalog"><Lobby user={user} onLoad={load} onLogout={logout}/></CrestProvider>;
}
function Access({ onAccess }: {
    onAccess: (u: User) => void;
}) {
    useLocale();
    const [mode, setMode] = useState<'login' | 'register'>('login'), register = mode === 'register', [username, setUsername] = useState(''), [password, setPassword] = useState(''), [pending, setPending] = useState(false), [error, setError] = useState<unknown>();
    async function submit(e: React.FormEvent) {
        e.preventDefault();
        setPending(true);
        setError(undefined);
        try {
            const r = await api<{
                user: User;
            }>(`/auth/${mode}`, 'POST', { username, password });
            onAccess(r.user);
        }
        catch (e) {
            setError(e);
        }
        finally {
            setPending(false);
        }
    }
    return <div className="session-page"><div className="access-story"><div className="brand"><img className="brand-icon" src="/app-icon.png" alt={tr("")}/><span>{tr("quince")}<small>{tr("RUGBY CLUB MANAGER")}</small></span></div><span className="eyebrow">{tr("TU CLUB. TU HISTORIA.")}</span><h1>{tr("El rugby empieza")}<br />{tr("con una decisi\u00F3n.")}</h1><p>{tr("Elige tus colores. Construye tu equipo.")}<br />{tr("Lleva a tu club hasta la cima.")}</p><div className="access-pitch">{tr("15")}<span>{tr("JUGADORES. UN SOLO PROP\u00D3SITO.")}</span></div></div><section className="card access-card"><div className="access-language"><LanguageSelector /></div><span className="eyebrow">{tr("BIENVENIDO AL VESTUARIO")}</span><h2>{localize(register ? 'Crea tu cuenta' : 'Vuelve al juego')}</h2><div className="access-tabs"><button className={mode === 'login' ? 'selected' : ''} onClick={() => { setMode('login'); setError(undefined); }}>{tr("Iniciar sesi\u00F3n")}</button><button className={register ? 'selected' : ''} onClick={() => { setMode('register'); setError(undefined); }}>{tr("Crear cuenta")}</button></div><form onSubmit={submit}><label>{tr("Usuario")}<input autoComplete="username" value={username} onChange={e => setUsername(e.target.value)} minLength={register ? 3 : undefined} maxLength={register ? 40 : 128} pattern={register ? "[A-Za-z0-9_.\-]+" : undefined} required/></label><label>{tr("Contrase\u00F1a")}<input type="password" autoComplete={register ? 'new-password' : 'current-password'} value={password} onChange={e => setPassword(e.target.value)} minLength={register ? 10 : undefined} maxLength={register ? 128 : 255} required/></label>{localize(register && <small className="muted">{tr("Utiliza al menos 10 caracteres.")}</small>)}{localize(!!error && <ErrorBox error={error}/>)}<button className="button dark full" disabled={pending}>{localize(pending ? 'Accediendo…' : register ? 'Crear cuenta' : 'Entrar')}<ArrowRight size={17}/></button></form></section></div>;
}
function Lobby({ user, onLoad, onLogout }: {
    user: User;
    onLoad: (g: Game) => Promise<void>;
    onLogout: () => Promise<void>;
}) {
    useLocale();
    const games = useQuery({ queryKey: ['saved-games'], queryFn: () => api<{
            items: Game[];
        }>('/games') }), catalog = useQuery({ queryKey: ['game-catalog'], queryFn: () => api<{
            items: Club[];
        }>('/game-catalog') });
    const qc = useQueryClient(), [deleted, setDeleted] = useState(''), [deleting, setDeleting] = useState<Game | null>(null), deleteDialog = useRef<HTMLDialogElement>(null), [deleteError, setDeleteError] = useState<unknown>();
    useEffect(() => {
        if (deleting)
            deleteDialog.current?.showModal();
        else
            deleteDialog.current?.close();
    }, [deleting]);
    const [create, setCreate] = useState(false), [division, setDivision] = useState(416), [clubId, setClubId] = useState(''), [name, setName] = useState(() => tr('Mi temporada')), [pending, setPending] = useState(false), [error, setError] = useState<unknown>(), key = useRef(requestId());
    async function start(g?: Game) {
        setPending(true);
        setError(undefined);
        try {
            const game = g ?? await api<Game>('/games', 'POST', { name, clubId, divisionId: division }, key.current);
            key.current = requestId();
            await onLoad(game);
        }
        catch (e) {
            setError(e);
        }
        finally {
            setPending(false);
        }
    }
    async function remove(g: Game) {
        setPending(true);
        setDeleteError(undefined);
        setDeleted('');
        try {
            await api(`/games/${g.id}`, 'DELETE', { confirm: true });
            qc.setQueryData<{
                items: Game[];
            }>(['saved-games'], old => old ? { items: old.items.filter(item => item.id !== g.id) } : old);
            if (sessionStorage.getItem('quince-game') === g.id) {
                sessionStorage.removeItem('quince-game');
                setGame(null);
            }
            setDeleted(`Partida «${g.name}» eliminada.`);
            setDeleting(null);
        }
        catch (e) {
            setDeleteError(e);
        }
        finally {
            setPending(false);
        }
    }
    return <div className="lobby"><header className="lobby-header"><LanguageSelector /><div className="brand"><img className="brand-icon" src="/app-icon.png" alt={tr("")}/><span>{tr("quince")}<small>{tr("RUGBY CLUB MANAGER")}</small></span></div><button className="button secondary" onClick={() => void onLogout()}><LogOut size={16}/>{tr("Cerrar sesi\u00F3n")}</button></header><div className="page-heading"><div><div className="eyebrow">{tr("EL VESTUARIO DE ")}{user.username}</div><h1>{localize(create ? 'Una nueva historia.' : 'Tus partidas.')}</h1></div><button className="button dark" disabled={pending} onClick={() => { setCreate(!create); setError(undefined); setDeleted(''); }}>{localize(create ? <FolderOpen size={18}/> : <Plus size={18}/>)} {localize(create ? 'Ver partidas' : 'Nueva partida')}</button></div>{localize(!!error && <ErrorBox error={error}/>)} {localize(!!deleted && <p className="success" role="status">{localize(deleted)}</p>)}<main>{localize(create ? <><section className="card new-game-controls"><label>{tr("Nombre de la partida")}<input value={name} onChange={e => setName(e.target.value)} maxLength={60}/></label><label>{tr("Divisi\u00F3n")}<select value={division} onChange={e => { setDivision(Number(e.target.value)); setClubId(''); }}><option value={416}>{tr("Divisi\u00F3n de Honor")}</option><option value={417}>{tr("Divisi\u00F3n \u00C9lite")}</option></select></label><span className="pill">{tr("INICIO \u00B7 1 SEPTIEMBRE 2026")}</span></section><h3>{tr("Elige tu club")}</h3>{localize(catalog.isLoading ? <Loading /> : catalog.error ? <ErrorBox error={catalog.error}/> : <div className="club-choice-grid">{localize(catalog.data?.items.filter(c => c.competitionId === division).map(c => <button key={c.id} aria-pressed={clubId === c.id} className={`card club-choice ${clubId === c.id ? 'selected' : ''}`} onClick={() => setClubId(c.id)}><ClubCrest clubId={c.id} name={c.name}/><strong>{c.name}</strong><span>{c.city}</span></button>))}</div>)}<div className="new-game-start"><button className="button dark" disabled={!clubId || !name.trim() || pending} onClick={() => void start()}>{localize(pending ? 'Preparando temporada…' : 'Comenzar temporada')}<ArrowRight size={18}/></button></div></> : <>{localize(games.isLoading ? <Loading /> : games.error ? <ErrorBox error={games.error}/> : games.data?.items.length ? <div className="saved-game-grid">{localize(games.data.items.map(g => <article key={g.id} className="card saved-game"><ClubCrest clubId={g.clubId} name={g.clubName}/><div><span className="eyebrow">{localize(g.division)}</span><h3>{g.name}</h3><strong>{g.clubName}</strong><p>{localize(new Date(g.date + 'T12:00:00').toLocaleDateString(getLocale(), { day: 'numeric', month: 'long', year: 'numeric' }))}</p></div><div className="saved-game-actions"><button className="button dark" disabled={pending} onClick={() => void start(g)}>{tr("Cargar partida ")}<ArrowRight size={16}/></button><button className="button danger" disabled={pending} aria-label={tr(`Eliminar partida ${g.name}`)} onClick={() => { setDeleting(g); setDeleteError(undefined); }}><Trash2 size={16}/>{tr("Eliminar partida")}</button></div></article>))}</div> : <section className="card empty"><FolderOpen size={32}/><h3>{tr("Tu historia est\u00E1 por empezar.")}</h3><p>{tr("Crea una partida y elige el club que quieres dirigir.")}</p><button className="button dark" onClick={() => setCreate(true)}>{tr("Nueva partida ")}<Plus size={16}/></button></section>)}</>)}</main><dialog ref={deleteDialog} className="delete-game-dialog" aria-labelledby="delete-game-title" onCancel={e => {
            e.preventDefault();
            if (!pending)
                setDeleting(null);
        }}><h2 id="delete-game-title">{tr("Eliminar partida")}</h2>{localize(deleting && <><p><strong>{localize(deleting.name)}</strong><br />{deleting.clubName}{tr(" \u00B7 ")}{localize(new Date(deleting.date + 'T12:00:00').toLocaleDateString(getLocale()))}</p><p>{tr("Se eliminar\u00E1n todos sus datos y su progreso. No se podr\u00E1 recuperar.")}</p>{localize(!!deleteError && <ErrorBox error={deleteError}/>)}<div className="delete-game-buttons"><button className="button secondary" disabled={pending} onClick={() => setDeleting(null)}>{tr("Cancelar")}</button><button className="button danger" disabled={pending} onClick={() => void remove(deleting)}>{localize(pending ? 'Eliminando…' : 'Eliminar definitivamente')}</button></div></>)}</dialog><footer>{tr("QUINCE \u00B7 Tu progreso se guarda autom\u00E1ticamente.")}</footer></div>;
}
