import { useNavigate, useLocation } from 'react-router-dom';
import { ShieldAlert, ArrowLeft, ShieldCheck, RefreshCw } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { UserRole } from '../types';

interface ForbiddenPageProps {
  attemptedPath?: string;
  requiredRoles?: UserRole[];
  currentRole?: UserRole | null;
  message?: string;
}

export default function ForbiddenPage({
  attemptedPath,
  requiredRoles,
  currentRole,
  message,
}: ForbiddenPageProps) {
  const navigate = useNavigate();
  const location = useLocation();
  const { user, activeRole, jurisdiction, switchActiveRole } = useAuth();

  const effectiveRole = currentRole || activeRole;
  const availableRoles = (user?.verifiedRoles || []) as UserRole[];
  const canSwitchToEligibleRole = availableRoles.some(
    (r) => requiredRoles && requiredRoles.includes(r) && r !== effectiveRole
  );

  return (
    <div className="min-h-[70vh] flex items-center justify-center p-4">
      <div className="max-w-lg w-full bg-brand-panel border border-slate-800 rounded-2xl p-6 sm:p-8 text-center space-y-6 shadow-2xl">
        {/* Shield Icon */}
        <div className="w-16 h-16 bg-red-500/10 text-red-400 border border-red-500/20 rounded-2xl flex items-center justify-center mx-auto shadow-inner">
          <ShieldAlert className="w-8 h-8" />
        </div>

        {/* Header */}
        <div className="space-y-2">
          <span className="inline-block px-2.5 py-1 bg-red-500/10 border border-red-500/20 rounded text-[10px] font-mono font-bold uppercase tracking-widest text-red-400">
            HTTP 403 Forbidden
          </span>
          <h2 className="text-xl sm:text-2xl font-display font-bold text-slate-100 uppercase tracking-tight">
            Restricted Operational Area
          </h2>
          <p className="text-xs text-slate-400 font-mono leading-relaxed">
            {message ||
              'Access to this federation administrative domain is restricted by governance policy. Your verified active role does not meet the authoritative privilege requirement.'}
          </p>
        </div>

        {/* Security Diagnostics Box */}
        <div className="p-4 bg-brand-bg border border-slate-800/90 rounded-xl text-left space-y-2.5 font-mono text-[11px]">
          <div className="flex items-center justify-between pb-2 border-b border-slate-800/80">
            <span className="text-slate-500 uppercase">Attempted Route</span>
            <span className="text-slate-300 font-bold truncate max-w-[220px]">
              {attemptedPath || location.pathname}
            </span>
          </div>
          <div className="flex items-center justify-between pb-2 border-b border-slate-800/80">
            <span className="text-slate-500 uppercase">Active Role</span>
            <span className="text-amber-400 font-bold">
              {effectiveRole?.replace(/_/g, ' ') || 'NONE'}
            </span>
          </div>
          {jurisdiction && (
            <div className="flex items-center justify-between pb-2 border-b border-slate-800/80">
              <span className="text-slate-500 uppercase">Jurisdiction</span>
              <span className="text-emerald-400 font-bold">{jurisdiction}</span>
            </div>
          )}
          {requiredRoles && requiredRoles.length > 0 && (
            <div className="pt-1">
              <span className="text-slate-500 uppercase block mb-1.5">Authorized Roles</span>
              <div className="flex flex-wrap gap-1.5">
                {requiredRoles.map((r) => (
                  <span
                    key={r}
                    className="px-2 py-0.5 bg-slate-800/80 border border-slate-700/80 rounded text-[10px] text-slate-300"
                  >
                    {r.replace(/_/g, ' ')}
                  </span>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Role Switcher if multi-role user has eligible role */}
        {canSwitchToEligibleRole && (
          <div className="p-3 bg-amber-500/10 border border-amber-500/20 rounded-xl space-y-2 text-left">
            <div className="flex items-center gap-2 text-amber-400 text-xs font-bold font-mono">
              <RefreshCw className="w-3.5 h-3.5" />
              <span>Switch to Authorized Role</span>
            </div>
            <p className="text-[11px] text-slate-400 font-mono">
              Your account holds verified roles capable of accessing this sector:
            </p>
            <div className="flex flex-wrap gap-2 pt-1">
              {availableRoles
                .filter((r) => requiredRoles?.includes(r) && r !== effectiveRole)
                .map((r) => (
                  <button
                    key={r}
                    onClick={() => switchActiveRole(r)}
                    className="px-3 py-1.5 bg-amber-500 hover:bg-amber-400 text-slate-950 font-bold text-xs rounded-lg transition-colors font-mono uppercase flex items-center gap-1.5"
                  >
                    <ShieldCheck className="w-3.5 h-3.5" />
                    <span>Switch to {r.replace(/_/g, ' ')}</span>
                  </button>
                ))}
            </div>
          </div>
        )}

        {/* Navigation Action */}
        <div className="pt-2 flex flex-col sm:flex-row gap-3">
          <button
            onClick={() => navigate('/')}
            className="flex-1 py-2.5 px-4 bg-brand-raised hover:bg-slate-800 border border-slate-700 text-slate-200 text-xs font-bold rounded-lg transition-colors font-mono uppercase flex items-center justify-center gap-2"
          >
            <ArrowLeft className="w-4 h-4" />
            <span>Return to Operations Center</span>
          </button>
        </div>
      </div>
    </div>
  );
}
