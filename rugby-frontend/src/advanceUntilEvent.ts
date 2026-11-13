import {pendingFixture} from './matchDay';
import type {Club,Fixture,PreparationMeeting,SeasonEvent} from './types';
export type AdvanceSchedule={fixtures:Fixture[];meetings:PreparationMeeting[];seasonEvents?:SeasonEvent[]};
export type AutoAdvanceResult={club:Club;reason:'meeting'|'match'|'cancelled'|'empty'|'limit'|'season';fixtureId?:string;seasonEvent?:SeasonEvent};
export async function advanceUntilEvent(start:Club,io:{cancelled:()=>boolean;readSchedule:()=>Promise<AdvanceSchedule>;advance:(club:Club)=>Promise<Club>;onDay:(club:Club)=>void},maximumDays=365):Promise<AutoAdvanceResult>{
 let current=start;
 for(let steps=0;steps<=maximumDays;steps++){
  if(io.cancelled())return {club:current,reason:'cancelled'};
  const schedule=await io.readSchedule();
  if(io.cancelled())return {club:current,reason:'cancelled'};
  const pending=pendingFixture(schedule.fixtures,current.day);
  if(pending)return {club:current,reason:'match',fixtureId:pending.id};
  const meeting=schedule.meetings.filter(m=>!m.closed&&m.day>start.day&&m.day<=current.day&&m.matchDay>=current.day).sort((a,b)=>a.day-b.day||a.fixtureId.localeCompare(b.fixtureId))[0];
  const seasonEvent=schedule.seasonEvents?.filter(e=>e.day>start.day&&e.day<=current.day).sort((a,b)=>a.day-b.day)[0];
  if(seasonEvent)return {club:current,reason:'season',seasonEvent};
  if(meeting)return {club:current,reason:'meeting',fixtureId:meeting.fixtureId};
  if(!schedule.fixtures.some(f=>f.status!=='finished'&&f.day>current.day)&&!schedule.meetings.some(m=>!m.closed&&m.day>current.day)&&!schedule.seasonEvents?.some(e=>e.day>current.day))return {club:current,reason:'empty'};
  if(steps===maximumDays)return {club:current,reason:'limit'};
  if(io.cancelled())return {club:current,reason:'cancelled'};
  current=await io.advance(current);
  io.onDay(current);
 }
 return {club:current,reason:'limit'};
}
