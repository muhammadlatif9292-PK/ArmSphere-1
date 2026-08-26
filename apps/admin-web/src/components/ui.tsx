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
      <Loader2 className="h-8 w-8 animate-spin text-brand-accent" />
      <p className="text-sm text-slate-400">{label}</p>
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
      <div className="w-12 h-12 rounded-full bg-red-500/10 flex items-center justify-center">
        <AlertTriangle className="w-6 h-6 text-red-400" />
      </div>
      <p className="text-base font-semibold text-slate-200">{title}</p>
      {message && <p className="text-xs text-slate-500 max-w-sm">{message}</p>}
      {onRetry && (
        <button
          onClick={onRetry}
          className="mt-1 inline-flex items-center gap-2 px-4 py-2 rounded-md bg-red-500/10 border border-red-500/30 text-red-300 text-xs font-semibold hover:bg-red-500/20 transition-colors"
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
      <p className="text-sm font-medium text-slate-400">{title}</p>
      {subtitle && <p className="text-xs text-slate-500 max-w-sm">{subtitle}</p>}
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
    <div className="flex items-center justify-between gap-3 p-4 rounded-xl border border-red-500/30 bg-red-500/5 text-sm text-red-300">
      <span className="min-w-0 break-words">{message}</span>
      {onRetry && (
        <button
          onClick={onRetry}
          className="shrink-0 inline-flex items-center gap-1.5 px-3 py-1.5 rounded-md border border-red-500/40 text-xs font-semibold hover:bg-red-500/10 transition-colors"
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
    <p className="text-xs text-red-400 bg-red-500/10 p-2.5 rounded border border-red-500/20">
      {message}
    </p>
  );
}
