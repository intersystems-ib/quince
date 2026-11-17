import {test,expect} from '@playwright/test';
import {getLanguage,getLocale,localize,localizedError,setLanguage,tr} from '../src/i18n';
import {fixtureLabel,fixtureShortLabel} from '../src/competitionLabels';
import catalog from '../src/i18n/translations.json' with {type:'json'};
import errors from '../src/i18n/errors.json' with {type:'json'};
test.afterEach(()=>setLanguage('es'));
test('all messages and error codes have English and French translations',()=>{
 for(const [key,values]of Object.entries({...catalog,...errors})){
  expect(values.length,key).toBe(2);for(const value of values)expect(value.trim(),key).not.toBe('');
  const slots=(key.match(/\{\d+\}/g)??[]).sort();
  for(const value of values)expect((value.match(/\{\d+\}/g)??[]).sort(),key).toEqual(slots);
 }
});
test('switches language without changing data or the Spanish source',()=>{
 const player={name:'François Martín',energy:82,clubId:'c1'};
 setLanguage('en');expect(getLanguage()).toBe('en');expect(getLocale()).toBe('en-GB');expect(tr('Plantilla')).toBe('Squad');expect(tr('Medio melé')).toBe('Scrum-half');expect(localize(player)).toBe(player);
 setLanguage('fr');expect(getLocale()).toBe('fr-FR');expect(tr('Plantilla')).toBe('Effectif');expect(tr('Pilar izquierdo')).toBe('Pilier gauche');expect(tr('Entrenamiento')).toBe('Entraînement');
 setLanguage('es');expect(tr('Plantilla')).toBe('Plantilla');expect(tr('  Cuerpo técnico  ')).toBe('  Cuerpo técnico  ');
});
test('interpolates commentary without translating player and saved-game names',()=>{
 setLanguage('en');expect(tr('Partida «Mi temporada» eliminada.')).toBe('Game “Mi temporada” deleted.');
 expect(tr('¡Ensayo de Diego García! Apoya el balón en la zona de marca.')).toBe('Try for Diego García! Grounds the ball in the in-goal.');
 expect(tr('Diego García enlaza un pase y gana 12 metros.')).toBe('Diego García links up with a pass and gains 12 metres.');
 expect(tr('El rival ajusta su táctica. El ritmo alto aumenta el desgaste.')).toBe('The opposition adjust their tactics. A high tempo increases fatigue.');
 setLanguage('fr');expect(tr('Escudo de VRAC')).toBe('Écusson de VRAC');expect(tr('Lesión: Contusión · regreso previsto 2026-11-20')).toBe('Blessure : Contusion · retour prévu le 2026-11-20');
});
test('localizes API failures and keeps their actionable meaning',()=>{
 setLanguage('en');expect(localizedError({code:'LOGIN_FAILED',message:'Usuario o contraseña incorrectos.'})).toBe('Incorrect username or password.');
 setLanguage('fr');expect(localizedError({code:'MATCH_PENDING',message:'Hay un partido pendiente por disputar.'})).toContain('Disputez le match');
 expect(localizedError({code:'PAYROLL_LIMIT',message:'El salario supera el margen mensual disponible de 250 €. Reduce la oferta o libera masa salarial.'})).toContain('250 €');
});

test('composes translated competition labels without changing match identifiers',()=>{
 setLanguage('en');expect(fixtureLabel({stage:'regular',round:4})).toBe('League · Round 4');expect(fixtureShortLabel({stage:'regular',round:4})).toBe('R4');
 setLanguage('fr');expect(fixtureLabel({stage:'cup-group',groupId:'A',round:2,competitionType:'cup'})).toBe('Copa del Rey · Poule A · Journée 2');expect(fixtureLabel({stage:'final',competitionType:'cup'})).toBe('Copa del Rey · Finale');
});
