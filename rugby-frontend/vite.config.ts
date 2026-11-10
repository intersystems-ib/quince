import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
export default defineConfig({ plugins: [react()], server: { port: 5176, proxy: { '/api/v1': { target: process.env.VITE_API_TARGET || 'http://localhost:8085', changeOrigin: false } } } });
