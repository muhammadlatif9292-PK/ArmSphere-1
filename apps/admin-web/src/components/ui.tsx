import React from 'react';
import { Loader2, AlertTriangle, RefreshCw } from 'lucide-react';

/**
 * Shared presentation primitives for the admin console.
 * These encode the dominant dark-theme recipes used across pages so that
 * loading / error / empty states stay visually unified.
 */

export function LoadingCard({ label = 'Loading...' }: { label?: string }) {
  return (
    <div className="py-12 flex flex-col items-center justify-center gap-3">
      <Loader2 className="h-8 w-8 animate-spin text-[#D4AF37]" />
      <p className="text-sm font-mono text-slate-400">{label}</p>
    </div>
  );
}

interface ErrorPanelProps {
  title: string;
  message?: string;
  onRetry?: () => void;
  retryLabel?: string;
}

export function ErrorPanel({ title, message, onRetry, retryLabel = 'Try Again' }: ErrorPanelProps) {
  return (
    <div className="py-12 flex flex-col items-center justify-center gap-3 text-center">
      <div className="w-12 h-12 rounded-full bg-[#E23B3B]/10 border border-[#E23B3B]/25 flex items-center justify-center shadow-[0_0_16px_rgba(226,59,59,0.2)]">
        <AlertTriangle className="w-6 h-6 text-[#E23B3B]" />
      </div>
      <p className="text-base font-display font-bold text-slate-100">{title}</p>
      {message && <p className="text-xs text-slate-400 max-w-sm font-mono">{message}</p>}
      {onRetry && (
        <button
          onClick={onRetry}
          className="mt-1 inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-[#E23B3B]/10 border border-[#E23B3B]/30 text-red-300 text-xs font-mono font-bold hover:bg-[#E23B3B]/20 transition-colors"
        >
          <RefreshCw className="w-3.5 h-3.5" />
          {retryLabel}
        </button>
      )}
    </div>
  );
}

interface EmptyStateProps {
  icon: React.ComponentType<{ className?: string }>;
  title: string;
  subtitle?: string;
}

export function EmptyState({ icon: Icon, title, subtitle }: EmptyStateProps) {
  return (
    <div className="py-16 flex flex-col items-center justify-center gap-3 text-center">
      <Icon className="w-12 h-12 text-slate-600" />
      <p className="text-sm font-display font-semibold text-slate-300">{title}</p>
      {subtitle && <p className="text-xs text-slate-500 max-w-sm font-mono">{subtitle}</p>}
    </div>
  );
}

interface ErrorBannerProps {
  message: string;
  onRetry?: () => void;
}

export function ErrorBanner({ message, onRetry }: ErrorBannerProps) {
  if (!message) return null;
  return (
    <div className="flex items-center justify-between gap-3 p-4 rounded-xl border border-[#E23B3B]/30 bg-[#E23B3B]/10 text-sm text-red-200">
      <span className="min-w-0 break-words font-mono text-xs">{message}</span>
      {onRetry && (
        <button
          onClick={onRetry}
          className="shrink-0 inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-[#E23B3B]/40 text-xs font-mono font-bold hover:bg-[#E23B3B]/20 text-red-300 transition-colors"
        >
          <RefreshCw className="w-3 h-3" />
          Retry
        </button>
      )}
    </div>
  );
}

interface FormErrorProps {
  message?: string | null;
}

export function FormError({ message }: FormErrorProps) {
  if (!message) return null;
  return (
    <p className="text-xs text-[#E23B3B] bg-[#E23B3B]/10 p-2.5 rounded-lg border border-[#E23B3B]/20 font-mono">
      {message}
    </p>
  );
}
