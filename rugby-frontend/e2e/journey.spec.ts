import {test,expect} from '@playwright/test';
import {requestId} from '../src/requestId';

test('gestión, partido real, sustitución, recarga y resultado',async({page,request})=>{
  const health=await request.get('/api/v1/health');
  expect(health.ok()).toBeTruthy();
  await page.goto('/clubes');
  await expect(page.getByRole('heading',{name:'Veinte clubes. La misma pasión.'})).toBeVisible();
  await page.getByLabel('Filtrar competición').selectOption('417');
  await expect(page.getByText('10 clubes',{exact:true})).toBeVisible();
  const club=await (await request.get('/api/v1/clubs/c1')).json();
  const fixtures=await (await request.get('/api/v1/clubs/c1/fixtures')).json();
  const next=fixtures.items.find((f:{status:string})=>f.status!=='finished');
  expect(next,'Queda al menos un amistoso disponible').toBeTruthy();
  let current=club;
  while(current.day<next.day){
    const response=await request.post('/api/v1/clubs/c1/advance-day',{headers:{'Idempotency-Key':requestId()},data:{version:current.version}});
    expect(response.ok()).toBeTruthy();current=await response.json();
  }
  await page.goto('/');
  await expect(page.getByRole('heading',{name:'El siguiente capítulo empieza aquí.'})).toBeVisible();
  const existing=page.getByRole('link',{name:'Entrar al encuentro',exact:true});
  if(await existing.count()===0){await page.getByRole('button',{name:'Preparar encuentro',exact:true}).click();}
  await page.getByRole('link',{name:'Entrar al encuentro',exact:true}).click();
  const start=page.getByRole('button',{name:'Iniciar encuentro',exact:true});
  if(await start.count())await start.click();
  await expect(page.getByRole('button',{name:'x60',exact:true})).toBeVisible();
  await page.getByRole('button',{name:'x60',exact:true}).click();
  await page.getByLabel('Jugador que sale',{exact:true}).selectOption('c1-p1');
  await page.getByLabel('Jugador que entra',{exact:true}).selectOption('c1-p16');
  await page.getByRole('button',{name:'Solicitar sustitución',exact:true}).click();
  await expect(page.getByText('Aplicada',{exact:true}).first()).toBeVisible({timeout:15000});
  const matchUrl=page.url();
  await page.reload();
  await expect(page.getByRole('heading',{name:'Desde la banda',exact:true})).toBeVisible();
  expect(page.url()).toBe(matchUrl);
  await expect(page.getByRole('heading',{name:'El partido ya es historia.'})).toBeVisible({timeout:120000});
  await expect(page.getByText('Resultado guardado e ingresos de partido aplicados una sola vez.')).toBeVisible();
  await page.getByRole('button',{name:'Estadísticas',exact:true}).click();
  await expect(page.getByText('Ensayos',{exact:true})).toBeVisible();
  await page.getByRole('link',{name:'Consultar presupuesto',exact:true}).click();
  await expect(page.getByRole('heading',{name:'Movimientos económicos',exact:true})).toBeVisible();
});
