import type {KitAppearance} from './types';
export function kitBackground(kit:KitAppearance|undefined,fallback:string){
 const base=kit?.color??fallback,accent=kit?.accentColor;if(!accent||!kit?.pattern||kit.pattern==='solid')return base;
 if(kit.pattern==='trim')return `linear-gradient(135deg,${base} 0 78%,${accent} 78% 100%)`;
 const angle=kit.pattern==='hoops'?'180deg':'90deg';
 if(kit.thirdColor)return `linear-gradient(${angle},${base} 0 40%,${accent} 40% 60%,${kit.thirdColor} 60% 100%)`;
 if(kit.pattern==='halves')return `linear-gradient(${angle},${base} 0 50%,${accent} 50% 100%)`;
 return `repeating-linear-gradient(${angle},${base} 0 3px,${accent} 3px 6px)`;
}
