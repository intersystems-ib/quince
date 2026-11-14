import {useQuery} from '@tanstack/react-query';
import {api} from './api';
import type {Club,Page} from './types';

export function useClubName(){
 const clubs=useQuery({queryKey:['clubs'],queryFn:()=>api<Page<Club>>('/clubs?limit=100'),staleTime:60000});
 const names=new Map(clubs.data?.items.map(c=>[c.id,c.shortName?.trim()||c.name]));
 return (id:string,fallback='')=>names.get(id)??fallback;
}
