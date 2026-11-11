import type {ReactNode} from 'react';

export default function Metric({icon,label,value,note,tag,children,className=''}:{icon:ReactNode;label:string;value:ReactNode;note:ReactNode;tag:string;children?:ReactNode;className?:string}){
 return <section className={`metric ${className}`} aria-label={label}><div className="metric-top"><span>{icon}</span><small>{tag}</small></div><p>{label}</p><strong>{value}</strong><div className="metric-note"><span className="small-dot"/><span className="metric-note-content">{note}</span></div>{children}</section>;
}
