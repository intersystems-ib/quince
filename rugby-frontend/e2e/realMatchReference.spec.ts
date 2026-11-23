import {test,expect} from '@playwright/test';
import {createElement} from 'react';
import {renderToStaticMarkup} from 'react-dom/server';
import RealMatchReference from '../src/RealMatchReference';
import {setLanguage} from '../src/i18n';
import type {Player} from '../src/types';

const fer={sourceUrl:'https://rugby.isquad.es/rugby_acta_completa_pdf.php?id_partido=17644',selections:6,starts:4,benchSelections:2,appearances:5,minutes:241,minutesMatches:5,minutesComplete:false,points:21,tries:3,conversions:0,penalties:1,drops:1,referenceGames:6};
const view=(data:Partial<Player>)=>renderToStaticMarkup(createElement(RealMatchReference,{player:{identitySeason:'2026/2027',...data} as Player}));
test.afterEach(()=>setLanguage('es'));

test('shows Spanish source participation separately and flags partial minute records',()=>{
 const html=view({ferReference:fer});
 expect(html).toContain('Referencia FER');expect(html).toContain('Minutos reconstruidos');expect(html).toContain('241');expect(html).toContain('cambios ambiguos');expect(html).not.toContain('Placajes');
 expect(view({ferReference:{...fer,minutesComplete:true,minutesMatches:6}})).not.toContain('cambios ambiguos');
});

test('retains French references and honours unvalidated points',()=>{
 const html=view({lnrReference:{sourceUrl:'https://top14.lnr.fr',appearances:6,minutes:320,points:12,tries:2,tackles:40,breaks:1,turnovers:1,pointsValidated:false}});
 expect(html).toContain('Referencia LNR');expect(html).toContain('Placajes');expect(html).not.toContain('Puntos');expect(view({})).toBe('');
});

test('translates the shared reference card into English and French',()=>{
 setLanguage('en');expect(view({ferReference:fer})).toContain('Reconstructed minutes');
 setLanguage('fr');expect(view({ferReference:fer})).toContain('Minutes reconstituées');expect(view({ferReference:fer})).toContain('Référence FER');
});


test('identifies official squad players without match evidence as estimates',()=>{
 const html=view({lnrReference:{sourceUrl:'https://top14.lnr.fr',appearances:0,minutes:0,points:0,tries:0,tackles:0,breaks:0,turnovers:0,matchEligible:false,squadListed:true}});
 expect(html).toContain('Plantilla oficial LNR');expect(html).toContain('características estimadas');
});
