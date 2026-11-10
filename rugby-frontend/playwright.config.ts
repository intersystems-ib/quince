import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {defineConfig} from '@playwright/test';
export default defineConfig({outputDir:process.env.RUGBY_TEST_ARTIFACTS||join(tmpdir(),'rugby-test-results','playwright'),testDir:'./e2e',fullyParallel:false,workers:1,timeout:180000,use:{baseURL:process.env.E2E_BASE_URL||'http://localhost:5175',trace:'retain-on-failure'},reporter:'list'});
