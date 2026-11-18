import { useRef } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { LoaderCircle } from 'lucide-react';
import { api } from './api';
import { ErrorBox } from './components';
import { requestId } from './requestId';
import { tr, useLocale } from './i18n';
import type { Match } from './types';

export default function MatchResultControl({ match: m, onBusy }: { match: Match; onBusy: (busy: boolean) => void }) {
    useLocale();
    const qc = useQueryClient(), key = useRef(requestId());
    const target = m.status === 'halftime' || m.period === 2 ? 'fulltime' : 'halftime';
    const advance = useMutation({
        mutationFn: () => api<Match>(`/matches/${m.id}/advance-result`, 'POST', { target }, key.current),
        onMutate: () => onBusy(true),
        onSuccess: match => { key.current = requestId(); qc.setQueryData(['match', m.id], match); void qc.invalidateQueries(); },
        onSettled: () => onBusy(false),
    });
    return <div className="speed-control result-control"><span>{tr('Resultado')}</span><div className="action-wrap">
        <button className="button dark" disabled={advance.isPending} onClick={() => advance.mutate()}>
            {advance.isPending && <LoaderCircle className="spin" size={15} />}
            {tr(advance.isPending ? (target === 'halftime' ? 'Simulando hasta el descanso…' : 'Simulando hasta el final…') : target === 'halftime' ? 'Ir a descanso' : 'Ir al final')}
        </button>
        {advance.error && <ErrorBox error={advance.error} onDismiss={() => advance.reset()} />}
    </div></div>;
}
