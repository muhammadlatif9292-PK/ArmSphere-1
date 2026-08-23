import React, { useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { Shield, KeyRound, Mail, AlertTriangle, Lock, Cpu, Globe2, ShieldCheck } from 'lucide-react';

export default function LoginPage() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Redirect back to original path if specified, otherwise dashboard
  const from = (location.state as any)?.from?.pathname || '/';

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password) {
      setError('Please fill in all corporate authorization fields.');
      return;
    }

    setError(null);
    setIsSubmitting(true);

    try {
      await login(email, password);
      navigate(from, { replace: true });
    } catch (err: any) {
      setError(err.response?.data?.detail || err.response?.data?.message || err.message || 'Invalid administrator credentials or unauthorized access request.');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#070A11] text-slate-100 flex flex-col justify-between relative overflow-hidden font-sans">
      {/* Background Graphic & Competition Table Silhouette Grid */}
      <div className="absolute inset-0 pointer-events-none overflow-hidden">
        {/* Championship Ambient Glow Field */}
        <div className="absolute -top-40 -left-40 w-[600px] h-[600px] bg-amber-500/5 rounded-full blur-[140px]" />
        <div className="absolute top-1/2 right-0 w-[500px] h-[500px] bg-blue-600/5 rounded-full blur-[160px]" />

        {/* Tactical Grid Overlay */}
        <div 
          className="absolute inset-0 opacity-[0.03]"
          style={{
            backgroundImage: `radial-gradient(circle at 1px 1px, rgba(255,255,255,0.4) 1px, transparent 0)`,
            backgroundSize: '32px 32px'
          }}
        />

        {/* Abstract Championship Line Geometry */}
        <svg className="absolute w-full h-full stroke-slate-800/40 fill-none" xmlns="http://www.w3.org/2000/svg">
          <line x1="0" y1="20%" x2="100%" y2="80%" strokeDasharray="4 8" strokeWidth="1" />
          <line x1="10%" y1="0" x2="90%" y2="100%" strokeDasharray="6 12" strokeWidth="1" />
          <circle cx="50%" cy="50%" r="350" strokeWidth="1" strokeDasharray="3 9" />
          <path d="M 0,300 Q 400,100 800,300 T 1600,300" strokeWidth="1" strokeDasharray="2 6" opacity="0.4" />
        </svg>
      </div>

      {/* Top Header Bar */}
      <header className="relative z-10 p-6 border-b border-slate-800/80 bg-[#0B0F19]/60 backdrop-blur-md flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="p-2 bg-gradient-to-br from-amber-500/20 to-amber-600/10 rounded-lg text-amber-400 border border-amber-500/30 shadow-lg shadow-amber-500/5">
            <Shield className="w-5 h-5" />
          </div>
          <div>
            <span className="font-display font-bold text-base text-slate-100 tracking-tight">ARMSPHERE</span>
            <span className="ml-2 text-xs font-mono font-semibold text-amber-400 uppercase tracking-widest px-2 py-0.5 rounded bg-amber-500/10 border border-amber-500/20">
              Federation Control
            </span>
          </div>
        </div>

        <div className="hidden sm:flex items-center gap-4 text-xs font-mono text-slate-400">
          <span className="flex items-center gap-1.5">
            <Globe2 className="w-3.5 h-3.5 text-slate-500" /> Official Governance Portal
          </span>
          <span className="text-slate-700">•</span>
          <span className="flex items-center gap-1.5 text-emerald-400">
            <ShieldCheck className="w-3.5 h-3.5" /> TLS 1.3 Encrypted
          </span>
        </div>
      </header>

      {/* Main Split Content */}
      <main className="relative z-10 flex-1 max-w-7xl w-full mx-auto px-6 py-12 flex flex-col lg:flex-row items-center justify-between gap-12">
        {/* Left Side: Brand Narrative & Federation Authority */}
        <div className="flex-1 space-y-6 text-left">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-slate-900 border border-slate-800 text-xs font-mono text-amber-400">
            <Cpu className="w-3.5 h-3.5" />
            <span>F1 RACE-CONTROL INFORMATION DENSITY</span>
          </div>

          <h1 className="text-4xl sm:text-5xl font-display font-extrabold text-slate-100 tracking-tight leading-tight">
            ArmSphere Executive & Governance Operations
          </h1>

          <p className="text-slate-400 text-base max-w-xl leading-relaxed">
            Centralized competition intelligence, dispute resolution, referee score verification, and championship title registry for official national arm wrestling operations.
          </p>

          <div className="grid grid-cols-2 sm:grid-cols-3 gap-4 pt-4 border-t border-slate-800/80 max-w-lg">
            <div className="p-3 bg-[#0F172A]/80 border border-slate-800 rounded-lg">
              <p className="text-xs font-mono text-slate-400 uppercase">Authority</p>
              <p className="text-sm font-bold text-slate-200 mt-0.5">National Council</p>
            </div>
            <div className="p-3 bg-[#0F172A]/80 border border-slate-800 rounded-lg">
              <p className="text-xs font-mono text-slate-400 uppercase">Audit Trail</p>
              <p className="text-sm font-bold text-emerald-400 mt-0.5">Immutable Log</p>
            </div>
            <div className="p-3 bg-[#0F172A]/80 border border-slate-800 rounded-lg">
              <p className="text-xs font-mono text-slate-400 uppercase">Security</p>
              <p className="text-sm font-bold text-amber-400 mt-0.5">Role Enforcement</p>
            </div>
          </div>
        </div>

        {/* Right Side: Compact Premium Authentication Panel */}
        <div className="w-full max-w-md bg-[#0F172A]/90 border border-slate-800 rounded-2xl p-8 shadow-2xl backdrop-blur-xl relative">
          {/* Restrained Championship Accent Line */}
          <div className="absolute top-0 left-8 right-8 h-[2px] bg-gradient-to-r from-transparent via-amber-500/60 to-transparent" />

          <div className="mb-6 text-left">
            <div className="flex items-center gap-2 text-xs font-mono text-amber-400 uppercase tracking-widest mb-1">
              <Lock className="w-3.5 h-3.5" /> Secure Authentication
            </div>
            <h2 className="text-2xl font-display font-bold text-slate-100">Administrator Access</h2>
            <p className="text-xs text-slate-400 mt-1">Authenticate with authorized federation credentials</p>
          </div>

          {error && (
            <div className="flex items-start gap-3 bg-red-500/10 border border-red-500/20 text-red-200 p-3.5 rounded-lg mb-6 text-xs leading-relaxed">
              <AlertTriangle className="w-4 h-4 text-red-400 shrink-0 mt-0.5" />
              <div>
                <p className="font-bold text-red-300">Access Denied</p>
                <p className="text-red-400/90 mt-0.5">{error}</p>
              </div>
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-5">
            <div>
              <label className="block text-xs font-mono font-semibold uppercase tracking-wider text-slate-400 mb-2">
                Corporate Email Address
              </label>
              <div className="relative">
                <span className="absolute inset-y-0 left-0 flex items-center pl-3.5 text-slate-500">
                  <Mail className="w-4 h-4" />
                </span>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="executive@armsphere.org"
                  className="w-full bg-[#070A11] border border-slate-700/80 rounded-lg pl-10 pr-4 py-2.5 text-sm text-slate-100 placeholder-slate-500 focus:outline-none focus:border-amber-500 focus:ring-1 focus:ring-amber-500/50 transition-colors font-sans"
                  disabled={isSubmitting}
                  required
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-mono font-semibold uppercase tracking-wider text-slate-400 mb-2">
                Administrator Password
              </label>
              <div className="relative">
                <span className="absolute inset-y-0 left-0 flex items-center pl-3.5 text-slate-500">
                  <KeyRound className="w-4 h-4" />
                </span>
                <input
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••••••"
                  className="w-full bg-[#070A11] border border-slate-700/80 rounded-lg pl-10 pr-4 py-2.5 text-sm text-slate-100 placeholder-slate-500 focus:outline-none focus:border-amber-500 focus:ring-1 focus:ring-amber-500/50 transition-colors font-sans"
                  disabled={isSubmitting}
                  required
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={isSubmitting}
              className="w-full bg-amber-500 hover:bg-amber-400 text-slate-950 font-bold text-sm py-3 rounded-lg transition-all focus:outline-none focus:ring-2 focus:ring-amber-500/50 shadow-lg shadow-amber-500/10 disabled:opacity-50 disabled:cursor-not-allowed flex justify-center items-center gap-2 mt-2"
            >
              {isSubmitting ? (
                <>
                  <div className="w-4 h-4 border-2 border-slate-950 border-t-transparent rounded-full animate-spin" />
                  Verifying Authorization...
                </>
              ) : (
                'Authenticate Console Access'
              )}
            </button>
          </form>
        </div>
      </main>

      {/* Footer */}
      <footer className="relative z-10 p-6 border-t border-slate-800/80 bg-[#0B0F19]/60 backdrop-blur-md text-center text-xs text-slate-500 font-mono">
        ArmSphere Competitive Arm Wrestling Federation • Executive Operations Console v1.0
      </footer>
    </div>
  );
}
