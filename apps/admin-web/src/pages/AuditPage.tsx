import React, { useState } from 'react';
import {
  ScrollText,
  ShieldCheck,
  ShieldAlert,
  RefreshCw,
  Loader2,
  AlertTriangle,
  Fingerprint,
} from 'lucide-react';
import { useAuditEvents, useVerifyLedger } from '../lib/auditApi';
import { useAuth } from '../context/AuthContext';
import { UserRole } from '../types';
import { ErrorBanner } from '../components/ui';

function formatDateTime(value?: string): string {
  if (!value) return '--';
  try {
    return new Date(value).toLocaleString();
  } catch {
    return value;
  }
}

export default function AuditPage() {
  const { user } = useAuth();
  const { data: events, isLoading, isError, error, refetch, isRefetching } = useAuditEvents();
  const { data: verification, isLoading: isVerifying, refetch: refetchVerification, isRefetching: isVerifyRefreshing } = useVerifyLedger();
  const [expandedId, setExpandedId] = useState<string | null>(null);

  // Ledger integrity verification is a SYSTEM_ADMIN / COMPLIANCE_OFFICER capability
  // enforced by the backend; the UI mirrors that gate honestly.
  const canVerify = user?.role === UserRole.SYSTEM_ADMIN || user?.role === UserRole.COMPLIANCE_OFFICER;

  return (
    <div className="space-y-6" id="audit-page-container">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl md:text-3xl font-display font-bold text-slate-100 tracking-tight flex items-center gap-2">
            <ScrollText className="w-6 h-6 text-amber-400" />
            Immutable Audit Ledger
          </h1>
          <p className="text-sm text-slate-400 mt-1">
            SHA-256 chained record of every privileged operation. Entries are append-only and cryptographically linked.
          </p>
        </div>
        <div className="flex items-center gap-3">
          <button
            onClick={() => refetch()}
            disabled={isRefetching}
            className="inline-flex items-center gap-2 px-3 py-2 text-xs font-medium text-slate-300 bg-slate-800/60 hover:bg-slate-800 border border-slate-700 rounded-lg transition-colors disabled:opacity-50"
          >
            {isRefetching ? <Loader2 className="w-4 h-4 animate-spin" /> : <RefreshCw className="w-4 h-4" />}
            Refresh
          </button>
          <button
            onClick={() => refetchVerification()}
            disabled={!canVerify || isVerifying || isVerifyRefreshing}
            title={canVerify ? 'Recompute the full hash chain' : 'Requires System Admin or Compliance Officer role'}
            className="inline-flex items-center gap-2 px-3 py-2 text-xs font-bold text-slate-950 bg-amber-500 hover:bg-amber-400 rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {(isVerifying || isVerifyRefreshing) ? <Loader2 className="w-4 h-4 animate-spin" /> : <Fingerprint className="w-4 h-4" />}
            Verify Chain Integrity
          </button>
        </div>
      </div>

      {!canVerify && (
        <div className="flex items-start gap-3 p-4 border border-slate-800 bg-slate-900/40 rounded-xl text-xs text-slate-400">
          <AlertTriangle className="w-4 h-4 mt-0.5 shrink-0 text-slate-500" />
          Your role ({user?.role || 'UNKNOWN'}) can read the ledger below. Running a full chain verification requires the
          System Admin or Compliance Officer role — the button stays disabled rather than pretending to verify.
        </div>
      )}

      {/* Verification result */}
      {canVerify && verification && (
        <div
          className={`p-5 rounded-xl border ${
            verification.isValid
              ? 'border-green-500/30 bg-green-500/5'
              : 'border-red-500/40 bg-red-500/10'
          }`}
          role="status"
        >
          <div className="flex items-start gap-3">
            {verification.isValid ? (
              <ShieldCheck className="w-6 h-6 text-green-400 shrink-0" />
            ) : (
              <ShieldAlert className="w-6 h-6 text-red-400 shrink-0" />
            )}
            <div className="space-y-1">
              <p className={`font-semibold ${verification.isValid ? 'text-green-300' : 'text-red-300'}`}>
                {verification.isValid ? 'Ledger integrity verified.' : 'LEDGER TAMPERING DETECTED'}
              </p>
              <p className="text-xs text-slate-400 font-mono">
                {verification.isValid
                  ? `${verification.totalEventsVerified} events recomputed against their stored SHA-256 hashes — full chain intact.`
                  : `Chain broke at event index ${verification.totalEventsVerified}. Reason: ${verification.reason || 'unknown'}`}
              </p>
              {verification.tamperedEventId && (
                <p className="text-xs text-red-300 font-mono break-all">Offending event ID: {verification.tamperedEventId}</p>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Error state */}
      {isError && (
        <ErrorBanner
          message={`Failed to load audit ledger. ${(error as any)?.message || 'Unknown server error.'}`}
          onRetry={() => refetch()}
        />
      )}

      {/* Loading state */}
      {isLoading && (
        <div className="space-y-3">
          {[...Array(6)].map((_, i) => (
            <div key={i} className="h-16 bg-slate-900/60 border border-slate-800 rounded-xl animate-pulse" />
          ))}
        </div>
      )}

      {/* Ledger table */}
      {!isLoading && !isError && (
        <div className="bg-brand-panel border border-slate-800 rounded-xl overflow-hidden">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-slate-800">
              <thead className="bg-slate-900/60">
                <tr>
                  <th className="px-4 py-3 text-left text-[11px] font-mono uppercase tracking-wider text-slate-500">Event ID</th>
                  <th className="px-4 py-3 text-left text-[11px] font-mono uppercase tracking-wider text-slate-500">Action</th>
                  <th className="px-4 py-3 text-left text-[11px] font-mono uppercase tracking-wider text-slate-500">Entity</th>
                  <th className="px-4 py-3 text-left text-[11px] font-mono uppercase tracking-wider text-slate-500">Actor</th>
                  <th className="px-4 py-3 text-left text-[11px] font-mono uppercase tracking-wider text-slate-500">Timestamp</th>
                  <th className="px-4 py-3" />
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800/60">
                {(events || []).length === 0 && (
                  <tr>
                    <td colSpan={6} className="px-4 py-12 text-center text-sm text-slate-500">
                      No audit events recorded yet.
                    </td>
                  </tr>
                )}
                {(events || []).map((event) => (
                  <React.Fragment key={event.id}>
                    <tr className="hover:bg-slate-900/40 transition-colors cursor-pointer" onClick={() => setExpandedId(expandedId === event.id ? null : event.id)}>
                      <td className="px-4 py-3 text-xs font-mono text-slate-300">{event.eventId}</td>
                      <td className="px-4 py-3">
                        <span className="inline-flex px-2 py-0.5 text-[11px] font-medium rounded-md bg-amber-500/10 text-amber-300 border border-amber-500/20">
                          {event.action}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-xs text-slate-400 font-mono">
                        {event.entityType}:{String(event.entityId).slice(0, 8)}…
                      </td>
                      <td className="px-4 py-3 text-xs text-slate-400 font-mono">{event.actorId || 'SYSTEM'}</td>
                      <td className="px-4 py-3 text-xs text-slate-400">{formatDateTime(event.createdAt)}</td>
                      <td className="px-4 py-3 text-right text-[11px] text-slate-500">{expandedId === event.id ? 'Hide' : 'Details'}</td>
                    </tr>
                    {expandedId === event.id && (
                      <tr className="bg-brand-canvas">
                        <td colSpan={6} className="px-4 py-4 space-y-3">
                          <div>
                            <p className="text-[11px] font-mono uppercase tracking-wider text-slate-500 mb-1">Payload</p>
                            <pre className="text-[11px] font-mono text-slate-300 bg-slate-900 border border-slate-800 rounded-lg p-3 overflow-x-auto">
                              {event.payload ? JSON.stringify(event.payload, null, 2) : '(no payload)'}
                            </pre>
                          </div>
                          <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                            <div>
                              <p className="text-[11px] font-mono uppercase tracking-wider text-slate-500 mb-1">Parent Hash</p>
                              <p className="text-[11px] font-mono text-slate-400 break-all">{event.parentHash}</p>
                            </div>
                            <div>
                              <p className="text-[11px] font-mono uppercase tracking-wider text-slate-500 mb-1">Event Hash (SHA-256)</p>
                              <p className="text-[11px] font-mono text-emerald-300/80 break-all">{event.eventHash}</p>
                            </div>
                          </div>
                        </td>
                      </tr>
                    )}
                  </React.Fragment>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}
