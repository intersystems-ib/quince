import React from 'react';
import ReactDOM from 'react-dom/client';
import {BrowserRouter} from 'react-router-dom';
import {QueryClient,QueryClientProvider} from '@tanstack/react-query';
import SessionGate from './SessionGate';
import './style.css';
const client=new QueryClient({defaultOptions:{queries:{retry:1,refetchOnWindowFocus:true},mutations:{retry:false}}});
ReactDOM.createRoot(document.getElementById('root')!).render(<React.StrictMode><QueryClientProvider client={client}><BrowserRouter><SessionGate/></BrowserRouter></QueryClientProvider></React.StrictMode>);
