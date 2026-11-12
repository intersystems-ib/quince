import type {Fixture,Training} from './types';

export function calendarTraining(date:string,plan:Training|undefined,fixtures:Fixture[]){
 if(fixtures.some(f=>f.date===date))return;
 if(!plan?.weeklyConfigured||!plan.weekly)return;
 const day=new Date(`${date}T12:00:00`),weekday=(day.getDay()+6)%7+1;
 const entry=plan.weekly.senior.find(d=>d.day===weekday);
 if(!entry)return;
 const tomorrow=new Date(day);tomorrow.setDate(day.getDate()+1);
 const nextDate=`${tomorrow.getFullYear()}-${String(tomorrow.getMonth()+1).padStart(2,'0')}-${String(tomorrow.getDate()).padStart(2,'0')}`;
 if(entry.theme==='rest'||fixtures.some(f=>f.date===nextDate))return {rest:true,label:entry.theme==='rest'?'Descanso y recuperación':'Recuperación previa al partido'};
 const theme=plan.themes?.find(t=>t.id===entry.theme);
 return {rest:false,label:`Entrenamiento · ${theme?.name??'Plan semanal'}`,forwards:entry.forwards??theme?.forwards.split(',')[weekday-1],backs:entry.backs??theme?.backs.split(',')[weekday-1]};
}
