import {useEffect,useLayoutEffect,useRef,useSyncExternalStore} from 'react';
import type {Match} from './types';

type Point={x:number;y:number};
type Frame={at:number;points:Map<string,Point>};
type Motion={id?:string;period?:number;speed:number;running:boolean;frames:Frame[];shown:Map<string,Point>;nodes:Map<string,SVGElement>;raf?:number;playhead:number;cadence:number;started:number;from:Map<string,Point>;velocities:Map<string,Point>;lastFrame:number};
const reducedMotion=()=>window.matchMedia('(prefers-reduced-motion: reduce)').matches;
function subscribe(callback:()=>void){const media=window.matchMedia('(prefers-reduced-motion: reduce)');media.addEventListener('change',callback);return()=>media.removeEventListener('change',callback);}

// Only SVG transforms change per frame; the scoreboard and React tree keep their normal refresh rate.
export function usePitchMotion(match?:Match){
 const ref=useRef<HTMLDivElement>(null),reduced=useSyncExternalStore(subscribe,reducedMotion,()=>true);
 const motion=useRef<Motion>({speed:0,running:false,frames:[],shown:new Map(),nodes:new Map(),playhead:0,cadence:1000,started:0,from:new Map(),velocities:new Map(),lastFrame:0});
 function draw(points:Map<string,Point>){
  const state=motion.current;
  for(const [id,point] of points){
   const previous=state.shown.get(id);
   if(!previous||Math.abs(previous.x-point.x)>.0001||Math.abs(previous.y-point.y)>.0001)state.nodes.get(id)?.style.setProperty('transform',`translate(${point.x}px,${point.y}px)`);
  }
  state.shown=points;
 }
 function between(from:Map<string,Point>,to:Map<string,Point>,amount:number){
  const points=new Map<string,Point>();
  for(const [id,target] of to){const start=from.get(id)??target;points.set(id,{x:start.x+(target.x-start.x)*amount,y:start.y+(target.y-start.y)*amount});}
  return points;
 }
 function follow(targets:Map<string,Point>,now:number){
  const state=motion.current,elapsed=Math.min(.05,Math.max(0,(now-state.lastFrame)/1000)),points=new Map<string,Point>();
  state.lastFrame=now;
  for(const [id,target] of targets){
   const current=state.shown.get(id)??target,velocity=state.velocities.get(id)??{x:0,y:0},next={x:0,y:0},nextVelocity={x:0,y:0};
   // Critically damped motion preserves velocity when a new action changes direction.
   const omega=id==='ball'?24:18,decay=Math.exp(-omega*elapsed);
   for(const axis of ['x','y'] as const){
    const distance=current[axis]-target[axis],change=(velocity[axis]+omega*distance)*elapsed;
    next[axis]=target[axis]+(distance+change)*decay;
    nextVelocity[axis]=(velocity[axis]-omega*change)*decay;
   }
   points.set(id,next);state.velocities.set(id,nextVelocity);
  }
  draw(points);
 }
 function animate(now:number){
  const state=motion.current;state.raf=undefined;
  if(!state.running||!state.frames.length)return;
  if(state.speed<10){
   const duration=Math.max(1000,20000/state.speed)*1.05;
   follow(between(state.from,state.frames[state.frames.length-1].points,Math.min(1,(now-state.started)/duration)),now);
  }else{
   // Render slightly behind the newest state so uneven polling still yields a continuous path.
   const delay=Math.min(2500,Math.max(1250,state.cadence*1.35));
   state.playhead=Math.max(state.playhead,Math.min(now-delay,state.frames[state.frames.length-1].at));
   while(state.frames.length>2&&state.frames[1].at<=state.playhead)state.frames.shift();
   const first=state.frames[0],last=state.frames[1]??first;
   const amount=last.at>first.at?Math.min(1,Math.max(0,(state.playhead-first.at)/(last.at-first.at))):1;
   follow(between(first.points,last.points,amount),now);
  }
  state.raf=requestAnimationFrame(animate);
 }
 useLayoutEffect(()=>{
  const state=motion.current,now=performance.now(),points=new Map<string,Point>();
  state.nodes=new Map(Array.from(ref.current?.querySelectorAll<SVGElement>('[data-motion-id]')??[]).map(node=>{
   const id=node.dataset.motionId!,x=Number(node.dataset.x),y=Number(node.dataset.y);
   if(Number.isFinite(x)&&Number.isFinite(y))points.set(id,{x,y});
   return [id,node];
  }));
  const running=!!match&&match.speed>0&&match.status!=='scheduled'&&match.status!=='halftime'&&match.status!=='finished'&&!reduced;
  const reset=state.id!==match?.id||state.period!==match?.period||state.speed!==(match?.speed??0)||state.running!==running;
  state.id=match?.id;state.period=match?.period;state.speed=match?.speed??0;state.running=running;
  if(!running||reset){
   if(state.raf!==undefined)cancelAnimationFrame(state.raf);
   state.raf=undefined;state.frames=[{at:now,points}];state.from=points;state.started=now;state.playhead=now;state.cadence=1000;state.velocities=new Map();state.lastFrame=now;
   // New nodes must also receive an initial transform even if their coordinates match the old state.
   state.shown=new Map();draw(points);
  }else{
   const last=state.frames[state.frames.length-1];
   const changed=!last||last.points.size!==points.size||[...points].some(([id,p])=>{const previous=last.points.get(id);return !previous||previous.x!==p.x||previous.y!==p.y;});
   if(changed){
    if(last)state.cadence=Math.max(500,Math.min(2000,state.cadence*.7+(now-last.at)*.3));
    state.from=state.shown;state.started=now;state.frames.push({at:now,points});
    if(state.frames.length>32)state.frames.shift();
   }
   // A replacement player appears at its actual location rather than flying in from another slot.
   for(const [id,p] of points)if(!state.shown.has(id))state.nodes.get(id)?.style.setProperty('transform',`translate(${p.x}px,${p.y}px)`);
  }
  if(running&&state.raf===undefined)state.raf=requestAnimationFrame(animate);
 },[match?.id,match?.clock,match?.sequence,match?.speed,match?.status,match?.period,reduced]);
 useEffect(()=>()=>{const state=motion.current;if(state.raf!==undefined)cancelAnimationFrame(state.raf);state.running=false;},[]);
 return ref;
}
