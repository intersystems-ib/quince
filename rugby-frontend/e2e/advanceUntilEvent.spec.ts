import {test,expect} from '@playwright/test';
import {advanceUntilEvent} from '../src/advanceUntilEvent';
import type {Club,Fixture,PreparationMeeting} from '../src/types';
const club=(day:number)=>({id:'c1',day,version:day+1,date:`2026-09-${String(day+1).padStart(2,'0')}`} as Club);
const fixture=(day:number)=>({id:'f1',day,status:'scheduled',homeId:'c1',awayId:'c2',clubId:'c1',matchId:''} as Fixture);
const meeting=(day:number)=>({fixtureId:'f1',day,matchDay:day+2,closed:false} as PreparationMeeting);
test('stops on the meeting without advancing to the match',async()=>{
 let count=0;const result=await advanceUntilEvent(club(0),{cancelled:()=>false,readSchedule:async()=>({fixtures:[fixture(4)],meetings:[meeting(2)]}),advance:async c=>{count++;return club(c.day+1);},onDay:()=>{}});
 expect(result.reason).toBe('meeting');expect(result.club.day).toBe(2);expect(count).toBe(2);
});
test('a new request on meeting day continues to the match',async()=>{
 let count=0;const result=await advanceUntilEvent(club(2),{cancelled:()=>false,readSchedule:async()=>({fixtures:[fixture(4)],meetings:[meeting(2)]}),advance:async c=>{count++;return club(c.day+1);},onDay:()=>{}});
 expect(result.reason).toBe('match');expect(result.club.day).toBe(4);expect(count).toBe(2);
});
test('never skips an overdue or current match',async()=>{
 let count=0;const result=await advanceUntilEvent(club(4),{cancelled:()=>false,readSchedule:async()=>({fixtures:[fixture(3)],meetings:[]}),advance:async c=>{count++;return club(c.day+1);},onDay:()=>{}});
 expect(result.reason).toBe('match');expect(count).toBe(0);
});
test('refreshes the schedule so a newly assigned event stops the run',async()=>{
 let day=0;const result=await advanceUntilEvent(club(0),{cancelled:()=>false,readSchedule:async()=>({fixtures:[fixture(5)],meetings:day>=1?[meeting(2)]:[]}),advance:async c=>{day=c.day+1;return club(day);},onDay:()=>{}});
 expect(result.reason).toBe('meeting');expect(result.club.day).toBe(2);
});
test('stopping an in-flight advance still publishes that day and sends no more',async()=>{
 let cancelled=false,count=0,published=-1;const result=await advanceUntilEvent(club(0),{cancelled:()=>cancelled,readSchedule:async()=>({fixtures:[fixture(5)],meetings:[]}),advance:async c=>{count++;cancelled=true;return club(c.day+1);},onDay:c=>{published=c.day;}});
 expect(result.reason).toBe('cancelled');expect(count).toBe(1);expect(published).toBe(1);
});
test('does not advance when no future events are scheduled',async()=>{
 let count=0;const result=await advanceUntilEvent(club(0),{cancelled:()=>false,readSchedule:async()=>({fixtures:[],meetings:[]}),advance:async c=>{count++;return club(c.day+1);},onDay:()=>{}});
 expect(result.reason).toBe('empty');expect(count).toBe(0);
});
test('a failed daily operation stops the run',async()=>{
 let count=0;await expect(advanceUntilEvent(club(0),{cancelled:()=>false,readSchedule:async()=>({fixtures:[fixture(5)],meetings:[]}),advance:async()=>{count++;throw new Error('offline');},onDay:()=>{}})).rejects.toThrow('offline');expect(count).toBe(1);
});
test('bounds the number of daily requests',async()=>{
 const result=await advanceUntilEvent(club(0),{cancelled:()=>false,readSchedule:async()=>({fixtures:[fixture(50)],meetings:[]}),advance:async c=>club(c.day+1),onDay:()=>{}},3);
 expect(result.reason).toBe('limit');expect(result.club.day).toBe(3);
});

test('stops at season closure even when no matches remain',async()=>{
 const event={id:'closure-2026',type:'closure' as const,seasonYear:2026,date:'2027-06-30',day:2,title:'Cierre de temporada',completed:false};
 let advances=0;
 const result=await advanceUntilEvent(club(0),{cancelled:()=>false,readSchedule:async()=>({fixtures:[],meetings:[],seasonEvents:[event]}),advance:async c=>{advances++;return club(c.day+1)},onDay:()=>{}});
 expect(result.reason).toBe('season');expect(result.seasonEvent?.type).toBe('closure');expect(advances).toBe(2);
});
test('stops at opening after the backend skips July and August',async()=>{
 const closure={id:'closure-2026',type:'closure' as const,seasonYear:2026,date:'2027-06-30',day:2,title:'Cierre de temporada',completed:true};
 const opening={id:'opening-2027',type:'opening' as const,seasonYear:2027,date:'2027-09-01',day:65,title:'Apertura de temporada',completed:false};
 let advances=0;
 const result=await advanceUntilEvent(club(2),{cancelled:()=>false,readSchedule:async()=>({fixtures:[],meetings:[],seasonEvents:[closure,opening]}),advance:async()=>{advances++;return club(65)},onDay:()=>{}});
 expect(result.reason).toBe('season');expect(result.seasonEvent?.type).toBe('opening');expect(advances).toBe(1);expect(result.club.day).toBe(65);
});
