import { localize, tr, useLocale } from "./i18n";
import type { ReactNode } from 'react';
export default function Metric({ icon, label, value, note, tag, children, className = '' }: {
    icon: ReactNode;
    label: string;
    value: ReactNode;
    note: ReactNode;
    tag: string;
    children?: ReactNode;
    className?: string;
}) {
    useLocale();
    return <section className={`metric ${className}`} aria-label={tr(label)}><div className="metric-top"><span>{localize(icon)}</span><small>{localize(tag)}</small></div><p>{localize(label)}</p><strong>{localize(value)}</strong><div className="metric-note"><span className="small-dot"/><span className="metric-note-content">{localize(note)}</span></div>{localize(children)}</section>;
}
