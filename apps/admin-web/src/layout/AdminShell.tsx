import React, { useState, useEffect } from 'react';
import { NavLink, useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import {
  Shield,
  LayoutDashboard,
  BarChart3,
  Trophy,
  FileCheck,
  Users,
  LogOut,
  UserCircle,
  Video,
  Building2,
  Menu,
  X,
  BadgeCheck,
  ScrollText
} from 'lucide-react';

interface SidebarLinkProps {
  to: string;
  icon: React.ReactNode;
  label: string;
  onClick?: () => void;
}

function SidebarLink({ to, icon, label, onClick }: SidebarLinkProps) {
  return (
    <NavLink
      to={to}
      onClick={onClick}
      className={({ isActive }) =>
        `flex items-center gap-2.5 px-3 py-2 rounded-lg text-xs font-semibold tracking-wide transition-all ${
          isActive
            ? 'bg-amber-500/10 text-amber-400 border border-amber-500/20 shadow-sm font-bold'
            : 'text-slate-400 hover:text-slate-100 hover:bg-[#161F30]'
        }`
      }
    >
      <span className="shrink-0">{icon}</span>
      <span className="truncate">{label}</span>
    </NavLink>
  );
}

interface AdminShellProps {
  children: React.ReactNode;
}

export default function AdminShell({ children }: AdminShellProps) {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  // Close mobile drawer on route change
  useEffect(() => {
    setMobileMenuOpen(false);
  }, [location.pathname]);

  const handleLogout = async () => {
    await logout();
    navigate('/login');
  };

  const getRoleLabel = (role?: string) => {
    return role ? role.replace(/_/g, ' ') : 'Unauthenticated';
  };

  return (
    <div className="flex h-screen bg-[#070A11] text-slate-100 overflow-hidden font-sans">
      {/* DESKTOP SIDEBAR */}
      <aside className="hidden lg:flex w-64 bg-[#0F172A] border-r border-slate-800/90 flex-col justify-between shrink-0 z-30">
        <div className="flex-1 overflow-y-auto scrollbar-thin scrollbar-thumb-slate-800">
          {/* Header Branding */}
          <div className="p-4 border-b border-slate-800/90 flex items-center gap-3 bg-[#0B0F19]">
            <div className="p-2 bg-gradient-to-br from-amber-500/20 to-amber-600/10 rounded-lg text-amber-400 border border-amber-500/30">
              <Shield className="w-5 h-5" />
            </div>
            <div>
              <h1 className="font-display font-bold text-sm tracking-tight text-slate-100 uppercase">ArmSphere</h1>
              <p className="text-[10px] text-amber-400 font-mono tracking-wider uppercase font-semibold">Admin Console</p>
            </div>
          </div>

          {/* Navigation Links */}
          <div className="p-3 space-y-4">
            {/* OVERVIEW */}
            <div>
              <p className="px-3 py-1 text-[10px] font-mono font-bold uppercase tracking-widest text-slate-500">
                Overview
              </p>
              <nav className="mt-1 space-y-0.5">
                <SidebarLink to="/" icon={<LayoutDashboard className="w-4 h-4 text-amber-400" />} label="Operations Center" />
              </nav>
            </div>

            {/* COMPETITION */}
            <div>
              <p className="px-3 py-1 text-[10px] font-mono font-bold uppercase tracking-widest text-slate-500">
                Competition
              </p>
              <nav className="mt-1 space-y-0.5">
                <SidebarLink to="/athletes" icon={<Users className="w-4 h-4 text-blue-400" />} label="Athletes" />
                <SidebarLink to="/championships" icon={<Trophy className="w-4 h-4 text-amber-400" />} label="Championship Titles" />
                <SidebarLink to="/nominations" icon={<BadgeCheck className="w-4 h-4 text-emerald-400" />} label="Nominations" />
                <SidebarLink to="/analytics" icon={<BarChart3 className="w-4 h-4 text-purple-400" />} label="Analytics" />
              </nav>
            </div>

            {/* GOVERNANCE */}
            <div>
              <p className="px-3 py-1 text-[10px] font-mono font-bold uppercase tracking-widest text-slate-500">
                Governance
              </p>
              <nav className="mt-1 space-y-0.5">
                <SidebarLink to="/governance" icon={<FileCheck className="w-4 h-4 text-red-400" />} label="Dispute Review" />
                <SidebarLink to="/moderation" icon={<Video className="w-4 h-4 text-indigo-400" />} label="Community Moderation" />
                <SidebarLink to="/venues" icon={<Building2 className="w-4 h-4 text-teal-400" />} label="Venues" />
              </nav>
            </div>

            {/* PLATFORM */}
            <div>
              <p className="px-3 py-1 text-[10px] font-mono font-bold uppercase tracking-widest text-slate-500">
                Platform
              </p>
              <nav className="mt-1 space-y-0.5">
                <SidebarLink to="/audit" icon={<ScrollText className="w-4 h-4 text-emerald-400" />} label="Audit Ledger" />
              </nav>
            </div>
          </div>
        </div>

        {/* Footer User Card */}
        <div className="p-4 border-t border-slate-800 bg-[#0B0F19] space-y-3">
          <div className="flex items-center gap-2.5 p-2 bg-[#161F30] border border-slate-800/80 rounded-lg">
            <UserCircle className="w-7 h-7 text-amber-400 shrink-0" />
            <div className="min-w-0 flex-1">
              <p className="text-xs font-bold text-slate-200 truncate">
                {user?.fullName || user?.email || 'Signed-in admin'}
              </p>
              <span className="inline-block text-[9px] font-mono font-semibold uppercase tracking-wider text-amber-400 truncate">
                {getRoleLabel(user?.role)}
              </span>
            </div>
          </div>

          <button
            onClick={handleLogout}
            className="w-full flex items-center justify-center gap-2 px-3 py-2 rounded-lg border border-slate-800 hover:border-red-500/40 hover:bg-red-500/10 hover:text-red-300 text-slate-400 text-xs font-semibold transition-colors"
          >
            <LogOut className="w-3.5 h-3.5" />
            <span>Sign Out</span>
          </button>
        </div>
      </aside>

      {/* MOBILE DRAWER OVERLAY */}
      {mobileMenuOpen && (
        <div className="lg:hidden fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex">
          <div className="w-72 bg-[#0F172A] h-full border-r border-slate-800 flex flex-col justify-between p-4 overflow-y-auto">
            <div>
              <div className="flex items-center justify-between pb-4 border-b border-slate-800 mb-4">
                <div className="flex items-center gap-2">
                  <Shield className="w-5 h-5 text-amber-400" />
                  <span className="font-display font-bold text-sm tracking-tight text-slate-100 uppercase">ArmSphere Admin</span>
                </div>
                <button
                  onClick={() => setMobileMenuOpen(false)}
                  className="p-1 text-slate-400 hover:text-slate-100"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              <div className="space-y-4">
                <div>
                  <p className="text-[10px] font-mono font-bold uppercase tracking-widest text-slate-500 mb-1">Overview</p>
                  <SidebarLink to="/" icon={<LayoutDashboard className="w-4 h-4 text-amber-400" />} label="Operations Center" onClick={() => setMobileMenuOpen(false)} />
                </div>
                <div>
                  <p className="text-[10px] font-mono font-bold uppercase tracking-widest text-slate-500 mb-1">Competition</p>
                  <div className="space-y-0.5">
                    <SidebarLink to="/athletes" icon={<Users className="w-4 h-4 text-blue-400" />} label="Athletes" onClick={() => setMobileMenuOpen(false)} />
                    <SidebarLink to="/championships" icon={<Trophy className="w-4 h-4 text-amber-400" />} label="Championship Titles" onClick={() => setMobileMenuOpen(false)} />
                    <SidebarLink to="/nominations" icon={<BadgeCheck className="w-4 h-4 text-emerald-400" />} label="Nominations" onClick={() => setMobileMenuOpen(false)} />
                    <SidebarLink to="/analytics" icon={<BarChart3 className="w-4 h-4 text-purple-400" />} label="Analytics" onClick={() => setMobileMenuOpen(false)} />
                  </div>
                </div>
                <div>
                  <p className="text-[10px] font-mono font-bold uppercase tracking-widest text-slate-500 mb-1">Governance</p>
                  <div className="space-y-0.5">
                    <SidebarLink to="/governance" icon={<FileCheck className="w-4 h-4 text-red-400" />} label="Dispute Review" onClick={() => setMobileMenuOpen(false)} />
                    <SidebarLink to="/moderation" icon={<Video className="w-4 h-4 text-indigo-400" />} label="Community Moderation" onClick={() => setMobileMenuOpen(false)} />
                    <SidebarLink to="/venues" icon={<Building2 className="w-4 h-4 text-teal-400" />} label="Venues" onClick={() => setMobileMenuOpen(false)} />
                  </div>
                </div>
                <div>
                  <p className="text-[10px] font-mono font-bold uppercase tracking-widest text-slate-500 mb-1">Platform</p>
                  <div className="space-y-0.5">
                    <SidebarLink to="/audit" icon={<ScrollText className="w-4 h-4 text-emerald-400" />} label="Audit Ledger" onClick={() => setMobileMenuOpen(false)} />
                  </div>
                </div>
              </div>
            </div>

            <div className="pt-4 border-t border-slate-800 mt-4 space-y-3">
              <div className="p-2 bg-[#161F30] rounded-lg">
                <p className="text-xs font-bold text-slate-200 truncate">{user?.fullName || user?.email || 'Signed-in admin'}</p>
                <p className="text-[10px] font-mono text-amber-400">{getRoleLabel(user?.role)}</p>
              </div>
              <button
                onClick={handleLogout}
                className="w-full flex items-center justify-center gap-2 px-3 py-2 rounded-lg border border-slate-800 text-slate-400 text-xs font-semibold hover:border-red-500/40 hover:bg-red-500/10 hover:text-red-300 transition-colors"
              >
                <LogOut className="w-3.5 h-3.5" />
                <span>Sign Out</span>
              </button>
            </div>
          </div>
        </div>
      )}

      {/* MAIN CONTENT AREA */}
      <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
        {/* MOBILE TOP BAR */}
        <header className="lg:hidden flex items-center justify-between p-4 bg-[#0B0F19] border-b border-slate-800">
          <div className="flex items-center gap-3">
            <button
              onClick={() => setMobileMenuOpen(true)}
              className="p-1.5 bg-[#0F172A] border border-slate-800 rounded-lg text-slate-300 hover:text-white"
            >
              <Menu className="w-5 h-5" />
            </button>
            <div className="flex items-center gap-2">
              <Shield className="w-5 h-5 text-amber-400" />
              <span className="font-display font-bold text-sm text-slate-100 uppercase">ArmSphere Admin</span>
            </div>
          </div>
        </header>

        {/* PAGE CONTENT CONTAINER */}
        <main className="flex-1 overflow-y-auto bg-[#070A11]">
          <div className="max-w-7xl mx-auto p-4 sm:p-6 md:p-8">
            {children}
          </div>
        </main>
      </div>
    </div>
  );
}
