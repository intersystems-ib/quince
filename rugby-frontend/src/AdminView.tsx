import { LanguageSelector, getLocale, localize, tr, useLocale } from "./i18n";
import { useRef, useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { LogOut, Plus, Save, Shield, Users } from 'lucide-react';
import { api } from './api';
import { requestId } from './requestId';
import { attrLabels, ErrorBox, Loading, positions } from './components';
import ClubCrest from './ClubCrest';
type RecordData = {
    id: string;
    version: number;
    name: string;
    [key: string]: any;
};
type Section = 'clubs' | 'players';
const freshPlayer = (): RecordData => ({ id: '', version: 0, name: '', clubId: 'c1', age: 20, category: 'senior', position: 1, secondary: [], nationality: 'España', nationalityCode: 'ES', monthlyWage: 100000, energy: 100, morale: 100, attributes: Object.fromEntries(Object.keys(attrLabels).map(k => [k, 50])) });
async function imageData(file: File): Promise<string> {
    if (!['image/png', 'image/jpeg', 'image/webp'].includes(file.type))
        throw new Error('Utiliza una imagen PNG, JPEG o WebP.');
    if (file.size > 5 * 1024 * 1024)
        throw new Error('El archivo no puede superar 5 MB.');
    const bitmap = await createImageBitmap(file);
    try {
        const scale = Math.min(1, 128 / Math.max(bitmap.width, bitmap.height)), canvas = document.createElement('canvas');
        canvas.width = Math.max(1, Math.round(bitmap.width * scale));
        canvas.height = Math.max(1, Math.round(bitmap.height * scale));
        canvas.getContext('2d')!.drawImage(bitmap, 0, 0, canvas.width, canvas.height);
        return canvas.toDataURL('image/png');
    }
    finally {
        bitmap.close();
    }
}
export default function AdminView({ username, onLogout }: {
    username: string;
    onLogout: () => Promise<void>;
}) {
    useLocale();
    const qc = useQueryClient(), [section, setSection] = useState<Section>('clubs'), [search, setSearch] = useState(''), [clubFilter, setClubFilter] = useState(''), [selected, setSelected] = useState<RecordData | null>(null), [draft, setDraft] = useState<RecordData | null>(null), [pending, setPending] = useState(false), [error, setError] = useState<unknown>(), [message, setMessage] = useState(''), [advanced, setAdvanced] = useState(''), [showAdvanced, setShowAdvanced] = useState(false), key = useRef(requestId());
    const clubs = useQuery({ queryKey: ['admin-clubs'], queryFn: () => api<{
            items: RecordData[];
        }>('/admin/clubs') }), players = useQuery({ queryKey: ['admin-players'], queryFn: () => api<{
            items: RecordData[];
        }>('/admin/players'), enabled: section === 'players' });
    const dirty = !!draft && JSON.stringify(draft) !== JSON.stringify(selected), source = section === 'clubs' ? clubs : players;
    const items = (source.data?.items ?? []).filter(x => x.name.toLocaleLowerCase().includes(search.toLocaleLowerCase()) && (!clubFilter || section === 'clubs' || x.clubId === clubFilter)).sort((a, b) => a.name.localeCompare(b.name, getLocale()));
    function canLeave() { return !dirty || window.confirm(tr('Hay cambios sin guardar. ¿Deseas descartarlos?')); }
    function choose(item: RecordData) {
        if (!canLeave())
            return;
        setSelected(item);
        setDraft(structuredClone(item));
        setError(undefined);
        setMessage('');
        setShowAdvanced(false);
        key.current = requestId();
    }
    function changeSection(next: Section) {
        if (pending || !canLeave())
            return;
        setSection(next);
        setSearch('');
        setClubFilter('');
        setSelected(null);
        setDraft(null);
        setError(undefined);
        setMessage('');
    }
    function update(field: string, value: unknown) { setDraft(old => old ? { ...old, [field]: value } : old); key.current = requestId(); setMessage(''); }
    function text(field: string, label: string, type = 'text', min?: number, max?: number) { return <label key={field}>{localize(label)}<input type={type} value={draft?.[field] ?? ''} min={min} max={max} step={type === 'number' ? 'any' : undefined} required onChange={e => update(field, type === 'number' ? Number(e.target.value) : e.target.value)}/></label>; }
    async function save(e: React.FormEvent) {
        e.preventDefault();
        if (!draft)
            return;
        setPending(true);
        setError(undefined);
        setMessage('');
        try {
            const result = await api<RecordData>(`/admin/${section}${draft.id ? `/${draft.id}` : ''}`, draft.id ? 'PUT' : 'POST', { version: selected?.version ?? 0, data: draft }, key.current);
            setSelected(result);
            setDraft(structuredClone(result));
            setShowAdvanced(false);
            key.current = requestId();
            await Promise.all([qc.invalidateQueries({ queryKey: [`admin-${section}`] }), qc.invalidateQueries({ queryKey: ['crest-catalog'] })]);
            setMessage('Datos iniciales guardados. Se utilizarán en las nuevas partidas.');
        }
        catch (e) {
            setError(e);
        }
        finally {
            setPending(false);
        }
    }
    async function refresh() {
        if (!canLeave())
            return;
        setPending(true);
        try {
            const result = await api<RecordData>(`/admin/${section}/${draft!.id}`);
            setSelected(result);
            setDraft(structuredClone(result));
            setShowAdvanced(false);
            setError(undefined);
            key.current = requestId();
        }
        catch (e) {
            setError(e);
        }
        finally {
            setPending(false);
        }
    }
    function applyAdvanced() {
        try {
            const next = JSON.parse(advanced);
            if (!next || Array.isArray(next) || typeof next !== 'object')
                throw new Error('Los datos deben ser un objeto JSON.');
            setDraft({ ...next, id: draft!.id, version: draft!.version });
            setShowAdvanced(false);
            setError(undefined);
            key.current = requestId();
        }
        catch (e) {
            setError(e);
        }
    }
    return <div className="admin-shell"><header className="lobby-header"><LanguageSelector /><div className="brand"><img className="brand-icon" src="/app-icon.png" alt={tr("")}/><span>{tr("quince")}<small>{tr("ADMINISTRACI\u00D3N")}</small></span></div><div className="admin-account"><span>{username}{tr(" \u00B7 IRIS")}</span><button className="button secondary" disabled={pending} onClick={() => {
            if (canLeave())
                void onLogout();
        }}><LogOut size={16}/>{tr("Cerrar sesi\u00F3n")}</button></div></header><div className="page-heading"><div><div className="eyebrow">{tr("DATOS DE INICIO")}</div><h1>{tr("Administraci\u00F3n.")}</h1><p>{tr("Los cambios se aplican a nuevas partidas.")}</p></div>{localize(section === 'players' && <button className="button dark" disabled={pending} onClick={() => choose(freshPlayer())}><Plus size={17}/>{tr("A\u00F1adir jugador")}</button>)}</div><nav className="competition-tabs" aria-label={tr("Administración")}><button aria-pressed={section === 'clubs'} onClick={() => changeSection('clubs')}><Shield size={17}/>{tr("Clubes")}</button><button aria-pressed={section === 'players'} onClick={() => changeSection('players')}><Users size={17}/>{tr("Jugadores")}</button></nav><div className="admin-layout"><section className="card admin-directory"><div className="admin-filters"><input aria-label={tr("Buscar por nombre")} placeholder={tr("Buscar por nombre…")} value={search} onChange={e => setSearch(e.target.value)}/>{localize(section === 'players' && <select aria-label={tr("Filtrar club")} value={clubFilter} onChange={e => setClubFilter(e.target.value)}><option value="">{tr("Todos los clubes")}</option>{localize(clubs.data?.items.map(c => <option key={c.id} value={c.id}>{c.name}</option>))}</select>)}<small>{localize(items.length)} {localize(section === 'clubs' ? 'clubes' : 'jugadores')}</small></div>{localize(source.isLoading ? <Loading /> : source.error ? <ErrorBox error={source.error}/> : <div className="admin-records">{localize(items.map(item => <button key={item.id} disabled={pending} className={draft?.id === item.id ? 'selected' : ''} onClick={() => choose(item)}>{localize(section === 'clubs' && <ClubCrest clubId={item.id} name={item.name}/>)}<span><strong>{localize(item.name)}</strong><small>{localize(section === 'clubs' ? item.city : `${clubs.data?.items.find(c => c.id === item.clubId)?.shortName ?? 'Agente libre'} · ${positions[item.position]} · Media ${Math.round(item.average)}`)}</small></span></button>))}{localize(!items.length && <p className="empty">{tr("No hay resultados.")}</p>)}</div>)}</section><section className="card admin-editor">{localize(draft ? <form onSubmit={save}><div className="card-top"><h2>{localize(draft.id ? draft.name : 'Nuevo jugador')}</h2>{localize(dirty && <span className="pill">{tr("Sin guardar")}</span>)}</div><fieldset disabled={pending}><div className="admin-fields">{localize(text('name', 'Nombre'))}{localize(section === 'clubs' ? <>{localize(text('shortName', 'Nombre corto'))}{localize(text('officialName', 'Nombre oficial'))}{localize(text('city', 'Localidad'))}{localize(text('color', 'Color principal', 'color'))}<label>{tr("Campo")}<input required maxLength={160} value={draft.stadium?.name ?? ''} onChange={e => update('stadium', { ...draft.stadium, name: e.target.value })}/></label><label>{tr("Aforo")}<input type="number" min={0} max={200000} required value={draft.stadium?.capacity ?? 0} onChange={e => update('stadium', { ...draft.stadium, capacity: Number(e.target.value) })}/></label><div className="admin-crest"><img src={draft.crestUrl || `/crests/${draft.id}.jpg`} alt={tr(`Escudo de ${draft.name}`)}/><label>{tr("Sustituir escudo")}<input type="file" accept="image/png,image/jpeg,image/webp" onChange={async (e) => {
                    const file = e.target.files?.[0];
                    if (!file)
                        return;
                    setPending(true);
                    try {
                        setError(undefined);
                        update('crestUrl', await imageData(file));
                    }
                    catch (e) {
                        setError(e);
                    }
                    finally {
                        e.target.value = '';
                        setPending(false);
                    }
                }}/><small>{tr("PNG, JPEG o WebP \u00B7 Hasta 5 MB")}</small></label><button type="button" className="button secondary" onClick={() => update('crestUrl', '')}>{tr("Escudo original")}</button></div></> : <><label>{tr("Club")}<select required={!draft.id} value={draft.clubId} onChange={e => update('clubId', e.target.value)}><option value="" disabled={!draft.id}>{localize(draft.id ? 'Agente libre' : 'Selecciona club')}</option>{localize(clubs.data?.items.map(c => <option key={c.id} value={c.id}>{c.name}</option>))}</select></label><label>{tr("Categor\u00EDa")}<select value={draft.category} onChange={e => update('category', e.target.value)}><option value="senior">{tr("Primer equipo")}</option><option value="academy">{tr("Cantera")}</option></select></label>{localize(text('age', 'Edad', 'number', 15, 60))}<label>{tr("Posici\u00F3n")}<select value={draft.position} onChange={e => update('position', Number(e.target.value))}>{localize(Object.entries(positions).map(([id, name]) => <option key={id} value={id}>{localize(name)}</option>))}</select></label>{localize(text('nationality', 'Nacionalidad'))}<label>{tr("C\u00F3digo de pa\u00EDs")}<input maxLength={3} value={draft.nationalityCode ?? ''} onChange={e => update('nationalityCode', e.target.value)}/></label><label>{tr("Salario mensual (\u20AC)")}<input type="number" min={0} max={100000} step="0.01" required value={draft.monthlyWage / 100} onChange={e => update('monthlyWage', Math.round(Number(e.target.value) * 100))}/></label>{localize(text('morale', 'Moral (%)', 'number', 0, 100))}{localize(text('energy', 'Energía (%)', 'number', 0, 100))}<label className="admin-span">{tr("Posiciones secundarias")}<select multiple value={(draft.secondary ?? []).map(String)} onChange={e => update('secondary', Array.from(e.target.selectedOptions, o => Number(o.value)))}>{localize(Object.entries(positions).map(([id, name]) => <option key={id} value={id}>{localize(name)}</option>))}</select></label></>)}</div>{localize(section === 'players' && <><h3>{tr("Caracter\u00EDsticas")}</h3><div className="admin-attributes">{localize(Object.entries(attrLabels).map(([key, label]) => <label key={key}>{localize(label)}<input type="number" min={1} max={100} step="any" required value={draft.attributes?.[key] ?? 50} onChange={e => update('attributes', { ...draft.attributes, [key]: Number(e.target.value) })}/></label>))}</div></>)}<div className="admin-advanced"><button type="button" className="button secondary" onClick={() => { setAdvanced(JSON.stringify(draft, null, 2)); setShowAdvanced(!showAdvanced); }}>{tr("Otros datos")}</button>{localize(showAdvanced && <><p className="muted">{tr("Edita los dem\u00E1s campos del registro. El identificador y la estructura de la competici\u00F3n se conservan.")}</p><textarea aria-label={tr("Otros datos del registro")} spellCheck={false} value={advanced} onChange={e => setAdvanced(e.target.value)}/><button type="button" className="button secondary" onClick={applyAdvanced}>{tr("Aplicar al formulario")}</button></>)}</div></fieldset>{localize(!!error && <ErrorBox error={error}/>)} {localize(!!message && <p className="success" role="status">{localize(message)}</p>)}<div className="admin-actions"><button className="button dark" disabled={pending || showAdvanced}><Save size={17}/>{localize(pending ? 'Guardando…' : 'Guardar datos iniciales')}</button>{localize(draft.id && <button type="button" className="button secondary" disabled={pending} onClick={() => void refresh()}>{tr("Recargar registro")}</button>)}</div></form> : <p className="empty">{tr("Selecciona un ")}{localize(section === 'clubs' ? 'club' : 'jugador')}{tr(" para editar sus datos.")}</p>)}</section></div></div>;
}
