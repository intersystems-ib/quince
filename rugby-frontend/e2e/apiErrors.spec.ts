import {test, expect} from '@playwright/test';
import {createElement} from 'react';
import {renderToStaticMarkup} from 'react-dom/server';
import {api, ApiError} from '../src/api';
import {ErrorBox} from '../src/components';

test('server failures retain the request identifier and show it with the error', async () => {
 const originalFetch = globalThis.fetch;
 const requestId = '73F86782-E764-11F1-AE81-0242AC170002';
 globalThis.fetch = async () => new Response(JSON.stringify({code:'INTERNAL_ERROR',message:'Error del servidor. Consulta los registros con el identificador de solicitud.',requestId}), {status:500});
 try {
  let failure: unknown;
  try { await api('/competitions/league-1402-2026'); } catch (error) { failure=error; }
  expect(failure).toBeInstanceOf(ApiError);
  expect((failure as ApiError).requestId).toBe(requestId);
  expect(renderToStaticMarkup(createElement(ErrorBox,{error:failure}))).toContain(requestId);
 } finally { globalThis.fetch=originalFetch; }
});

test('errors without a request identifier keep their existing display', () => {
 const html=renderToStaticMarkup(createElement(ErrorBox,{error:new ApiError(409,'CONFLICT','Datos modificados.')}));
 expect(html).not.toContain('ID:');
});
