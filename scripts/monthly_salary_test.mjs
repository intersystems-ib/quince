import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {createRequire} from 'node:module';
const require=createRequire(new URL('../rugby-frontend/package.json',import.meta.url));
const ts=require('typescript');
const source=await readFile(new URL('../rugby-frontend/src/salary.ts',import.meta.url),'utf8');
const js=ts.transpileModule(source,{compilerOptions:{module:ts.ModuleKind.ESNext,target:ts.ScriptTarget.ES2022}}).outputText;
const {monthlySalary,weeklySalary}=await import(`data:text/javascript;base64,${Buffer.from(js).toString('base64')}`);
assert.equal(weeklySalary(200000),46154);
assert.equal(Math.round(monthlySalary(weeklySalary(80000))/100),800);
assert.equal(Math.round(monthlySalary(weeklySalary(200000))/100),2000);
for(let monthly=80000;monthly<=200000;monthly+=100){assert.ok(Math.abs(monthlySalary(weeklySalary(monthly))-monthly)<=3);}
for(let weekly=100;weekly<=60000;weekly+=37){assert.equal(weeklySalary(monthlySalary(weekly)),weekly);}
assert.equal(monthlySalary(0),0);assert.equal(monthlySalary(-12000),-52000);
console.log('PASS monthly offer conversion, displayed salary, cent rounding, weekly round trips, zero and negative available margin');
