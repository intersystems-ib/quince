export type DayVersion={day:number;version:number};

export async function advanceWithRefresh<T extends DayVersion>(current:DayVersion,advance:(version:number)=>Promise<T>,refresh:()=>Promise<T>):Promise<T>{
 try{return await advance(current.version);}
 catch(error){
  if(!error||typeof error!=='object'||!('status' in error)||error.status!==409||!('code' in error)||error.code!=='VERSION_CONFLICT')throw error;
  const fresh=await refresh();
  // A concurrent advance already fulfilled the click; never advance another day.
  if(fresh.day>current.day)return fresh;
  if(fresh.day<current.day)throw error;
  return advance(fresh.version);
 }
}
