import type {Fixture} from './types';

export function pendingFixture(fixtures:Fixture[],day:number):Fixture|undefined {
 return fixtures.filter(f=>f.status!=='finished'&&f.day<=day)
  .sort((a,b)=>a.day-b.day||a.id.localeCompare(b.id))[0];
}
