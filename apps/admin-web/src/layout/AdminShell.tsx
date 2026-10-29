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
  ScrollText,
  Award,
  ChevronDown,
  MapPin,
  Headphones,
} from 'lucide-react';
import {
  getAuthorizedNavLinks,
  getEffectiveRole,
  getUserJurisdiction,
  RoutePermission,
} from '../lib/authorizationPolicy';
import { UserRole } from '../types';

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
            ? 'bg-[#D4AF37]/10 text-[#D4AF37] border border-[#D4AF37]/30 shadow-sm font-bold shadow-[0_0_12px_rgba(212,175,55,0.15)]'
            : 'text-slate-400 hover:text-slate-100 hover:bg-[#1A2330]'
        }`
      }
    >
      <span className="shrink-0">{icon}</span>
      <span className="truncate">{label}</span>
    </NavLink>
  );
}

const ROUTE_ICONS: Record<string, React.ReactNode> = {
  '/': <LayoutDashboard className="w-4 h-4 text-[#D4AF37]" />,
  '/athletes': <Users className="w-4 h-4 text-[#38BDF8]" />,
  '/referees': <Award className="w-4 h-4 text-[#10B981]" />,
  '/championships': <Trophy className="w-4 h-4 text-[#D4AF37]" />,
  '/nominations': <BadgeCheck className="w-4 h-4 text-[#10B981]" />,
  '/analytics': <BarChart3 className="w-4 h-4 text-purple-400" />,
  '/governance': <FileCheck className="w-4 h-4 text-[#E23B3B]" />,
  '/moderation': <Video className="w-4 h-4 text-indigo-400" />,
  '/venues': <Building2 className="w-4 h-4 text-teal-400" />,
  '/audit': <ScrollText className="w-4 h-4 text-[#10B981]" />,
  '/support': <Headphones className="w-4 h-4 text-[#38BDF8]" />,
};

interface AdminShellProps {
  children: React.ReactNode;
}

export default function AdminShell({ children }: AdminShellProps) {
  const { user, activeRole, jurisdiction, logout, switchActiveRole } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [roleSwitcherOpen, setRoleSwitcherOpen] = useState(false);

  // Close mobile drawer on route change
  useEffect(() => {
    setMobileMenuOpen(false);
    setRoleSwitcherOpen(false);
  }, [location.pathname]);

  const handleLogout = async () => {
    await logout();
    navigate('/login');
  };

  const effectiveRole = activeRole || getEffectiveRole(user);
  const effectiveJurisdiction = jurisdiction || getUserJurisdiction(user);
  const authorizedLinks = getAuthorizedNavLinks(user);

  const availableRoles = (user?.verifiedRoles || []) as UserRole[];
  const hasMultipleRoles = availableRoles.length > 1;

  const getRoleBadgeStyle = (role?: string | null) => {
    switch (role) {
      case UserRole.SYSTEM_ADMIN:
        return 'text-purple-400 border-purple-500/30 bg-purple-500/10';
      case UserRole.NATIONAL_DIRECTOR:
        return 'text-[#D4AF37] border-[#D4AF37]/30 bg-[#D4AF37]/10';
      case UserRole.PROVINCIAL_DIRECTOR:
        return 'text-[#38BDF8] border-[#38BDF8]/30 bg-[#38BDF8]/10';
      case UserRole.COMPLIANCE_OFFICER:
        return 'text-[#10B981] border-[#10B981]/30 bg-[#10B981]/10';
      case UserRole.TOURNAMENT_OPERATOR:
        return 'text-blue-400 border-blue-500/30 bg-blue-500/10';
      default:
        return 'text-slate-400 border-[rgba(214,220,227,0.12)] bg-[#151B24]';
    }
  };

  const categories: Array<'Overview' | 'Competition' | 'Governance' | 'Platform'> = [
    'Overview',
    'Competition',
    'Governance',
    'Platform',
  ];

  const renderNavSections = (onLinkClick?: () => void) => {
    return categories.map((category) => {
      const links = authorizedLinks.filter((l) => l.category === category);
      if (links.length === 0) return null;

      return (
        <div key={category}>
          <p className="px-3 py-1 text-[10px] font-mono font-bold uppercase tracking-widest text-slate-500">
            {category}
          </p>
          <nav className="mt-1 space-y-0.5">
            {links.map((link: RoutePermission) => (
              <SidebarLink
                key={link.path}
                to={link.path}
                icon={ROUTE_ICONS[link.path] || <LayoutDashboard className="w-4 h-4 text-slate-400" />}
                label={link.label}
                onClick={onLinkClick}
              />
            ))}
          </nav>
        </div>
      );
    });
  };

  return (
    <div className="flex h-screen bg-brand-canvas text-slate-100 overflow-hidden font-sans">
      {/* DESKTOP SIDEBAR */}
      <aside className="hidden lg:flex w-64 bg-[#0B0F19] border-r border-[rgba(214,220,227,0.12)] flex-col justify-between shrink-0 z-30 shadow-[4px_0_24px_rgba(0,0,0,0.5)]">
        <div className="flex-1 overflow-y-auto scrollbar-thin scrollbar-thumb-slate-800">
          {/* Header Branding */}
          <div className="p-4 border-b border-[rgba(214,220,227,0.12)] flex items-center gap-3 bg-[#070A11]/60">
            <div className="p-2 bg-gradient-to-br from-[#D4AF37]/20 to-[#D4AF37]/5 rounded-lg text-[#D4AF37] border border-[#D4AF37]/30 shadow-[0_0_14px_rgba(212,175,55,0.2)]">
              <Shield className="w-5 h-5" />
            </div>
            <div>
              <h1 className="font-display font-black text-sm tracking-tight text-slate-100 uppercase">
                ArmSphere
              </h1>
              <p className="text-[10px] text-[#D4AF37] font-mono tracking-wider uppercase font-semibold">
                Admin Console
              </p>
            </div>
          </div>

          {/* Navigation Links — Strictly Authorized */}
          <div className="p-3 space-y-4">{renderNavSections()}</div>
        </div>

        {/* Footer User Card & Active Role Switcher */}
        <div className="p-4 border-t border-[rgba(214,220,227,0.12)] bg-[#070A11]/60 space-y-3">
          <div className="p-3 bg-[#151B24] border border-[rgba(214,220,227,0.14)] rounded-xl space-y-2 shadow-sm">
            <div className="flex items-center gap-2.5">
              <UserCircle className="w-7 h-7 text-[#D4AF37] shrink-0" />
              <div className="min-w-0 flex-1">
                <p className="text-xs font-bold text-slate-200 truncate">
                  {user?.fullName || user?.email || 'Signed-in admin'}
                </p>
                <div className="flex flex-wrap items-center gap-1.5 mt-0.5">
                  <span
                    className={`inline-block px-1.5 py-0.2 rounded text-[9px] font-mono font-semibold uppercase tracking-wider border ${getRoleBadgeStyle(
                      effectiveRole
                    )}`}
                  >
                    {effectiveRole?.replace(/_/g, ' ') || 'UNASSIGNED'}
                  </span>
                </div>
              </div>
            </div>

            {/* Jurisdiction Badge */}
            {effectiveJurisdiction && (
              <div className="flex items-center gap-1.5 text-[10px] font-mono text-emerald-400 bg-emerald-500/10 px-2 py-0.5 rounded border border-emerald-500/20">
                <MapPin className="w-3 h-3 shrink-0" />
                <span className="truncate uppercase font-bold">{effectiveJurisdiction} Jurisdiction</span>
              </div>
            )}

            {/* Active Role Switcher (Multi-Role Support) */}
            {hasMultipleRoles && (
              <div className="pt-1.5 border-t border-[rgba(214,220,227,0.10)]">
                <button
                  onClick={() => setRoleSwitcherOpen(!roleSwitcherOpen)}
                  className="w-full flex items-center justify-between text-[10px] font-mono text-slate-400 hover:text-[#D4AF37] transition-colors"
                >
                  <span>Switch Active Role</span>
                  <ChevronDown className={`w-3 h-3 transition-transform ${roleSwitcherOpen ? 'rotate-180' : ''}`} />
                </button>

                {roleSwitcherOpen && (
                  <div className="mt-2 space-y-1">
                    {availableRoles.map((role) => (
                      <button
                        key={role}
                        onClick={() => {
                          switchActiveRole(role);
                          setRoleSwitcherOpen(false);
                        }}
                        className={`w-full text-left px-2 py-1 rounded text-[10px] font-mono transition-colors flex items-center justify-between ${
                          role === effectiveRole
                            ? 'bg-[#D4AF37]/20 text-[#D4AF37] font-bold border border-[#D4AF37]/30'
                            : 'hover:bg-[#1A2330] text-slate-400 hover:text-slate-200'
                        }`}
                      >
                        <span>{role.replace(/_/g, ' ')}</span>
                        {role === effectiveRole && <span className="text-[9px] text-[#D4AF37]">● Active</span>}
                      </button>
                    ))}
                  </div>
                )}
              </div>
            )}
          </div>

          <button
            onClick={handleLogout}
            className="w-full flex items-center justify-center gap-2 px-3 py-2 rounded-lg border border-[rgba(214,220,227,0.12)] hover:border-red-500/40 hover:bg-red-500/10 hover:text-red-300 text-slate-400 text-xs font-semibold transition-colors"
          >
            <LogOut className="w-3.5 h-3.5" />
            <span>Sign Out</span>
          </button>
        </div>
      </aside>

      {/* MOBILE DRAWER OVERLAY */}
      {mobileMenuOpen && (
        <div className="lg:hidden fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex">
          <div className="w-72 bg-[#0B0F19] h-full border-r border-[rgba(214,220,227,0.12)] shadow-[4px_0_24px_rgba(0,0,0,0.5)] flex flex-col justify-between p-4 overflow-y-auto">
            <div>
              <div className="flex items-center justify-between pb-4 border-b border-[rgba(214,220,227,0.12)] mb-4">
                <div className="flex items-center gap-2">
                  <Shield className="w-5 h-5 text-[#D4AF37]" />
                  <span className="font-display font-bold text-sm tracking-tight text-slate-100 uppercase">
                    ArmSphere Admin
                  </span>
                </div>
                <button
                  onClick={() => setMobileMenuOpen(false)}
                  className="p-1 text-slate-400 hover:text-slate-100"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              {/* Navigation Links — Strictly Authorized */}
              <div className="space-y-4">{renderNavSections(() => setMobileMenuOpen(false))}</div>
            </div>

            <div className="pt-4 border-t border-[rgba(214,220,227,0.12)] mt-4 space-y-3">
              <div className="p-3 bg-[#151B24] border border-[rgba(214,220,227,0.14)] rounded-xl space-y-1.5">
                <p className="text-xs font-bold text-slate-200 truncate">
                  {user?.fullName || user?.email || 'Signed-in admin'}
                </p>
                <div className="flex flex-wrap items-center gap-1.5">
                  <span
                    className={`inline-block px-1.5 py-0.2 rounded text-[9px] font-mono font-semibold uppercase tracking-wider border ${getRoleBadgeStyle(
                      effectiveRole
                    )}`}
                  >
                    {effectiveRole?.replace(/_/g, ' ') || 'UNASSIGNED'}
                  </span>
                </div>
                {effectiveJurisdiction && (
                  <div className="flex items-center gap-1.5 text-[10px] font-mono text-emerald-400 bg-emerald-500/10 px-2 py-0.5 rounded border border-emerald-500/20">
                    <MapPin className="w-3 h-3 shrink-0" />
                    <span className="truncate uppercase font-bold">{effectiveJurisdiction} Jurisdiction</span>
                  </div>
                )}
                {hasMultipleRoles && (
                  <div className="pt-1.5 border-t border-[rgba(214,220,227,0.10)]">
                    <p className="text-[10px] font-mono text-slate-500 uppercase mb-1">Switch Role:</p>
                    <div className="flex flex-wrap gap-1">
                      {availableRoles.map((role) => (
                        <button
                          key={role}
                          onClick={() => {
                            switchActiveRole(role);
                            setMobileMenuOpen(false);
                          }}
                          className={`px-2 py-1 rounded text-[10px] font-mono ${
                            role === effectiveRole
                              ? 'bg-[#D4AF37]/20 text-[#D4AF37] font-bold border border-[#D4AF37]/30'
                              : 'bg-[#1A2330] text-slate-300 border border-transparent'
                          }`}
                        >
                          {role.replace(/_/g, ' ')}
                        </button>
                      ))}
                    </div>
                  </div>
                )}
              </div>
              <button
                onClick={handleLogout}
                className="w-full flex items-center justify-center gap-2 px-3 py-2 rounded-lg border border-[rgba(214,220,227,0.12)] text-slate-400 text-xs font-semibold hover:border-red-500/40 hover:bg-red-500/10 hover:text-red-300 transition-colors"
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
        <header className="lg:hidden flex items-center justify-between p-4 bg-[#0B0F19]/90 backdrop-blur-md border-b border-[rgba(214,220,227,0.12)]">
          <div className="flex items-center gap-3">
            <button
              onClick={() => setMobileMenuOpen(true)}
              className="p-1.5 bg-[#151B24] border border-[rgba(214,220,227,0.14)] rounded-lg text-slate-300 hover:text-white"
            >
              <Menu className="w-5 h-5" />
            </button>
            <div className="flex items-center gap-2">
              <Shield className="w-5 h-5 text-[#D4AF37]" />
              <span className="font-display font-bold text-sm text-slate-100 uppercase">ArmSphere Admin</span>
            </div>
          </div>
        </header>

        {/* PAGE CONTENT CONTAINER */}
        <main className="flex-1 overflow-y-auto bg-brand-canvas">
          <div className="max-w-7xl mx-auto p-4 sm:p-6 md:p-8">{children}</div>
        </main>
      </div>
    </div>
  );
}
