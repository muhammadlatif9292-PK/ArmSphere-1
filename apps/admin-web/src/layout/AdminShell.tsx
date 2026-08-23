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
  Lock,
  ChevronRight,
  Menu,
  X,
  Search,
  Bell,
  Globe2,
  Award,
  FileText,
  Activity,
  Server,
  BadgeCheck,
  ClipboardList
} from 'lucide-react';

interface SidebarLinkProps {
  to: string;
  icon: React.ReactNode;
  label: string;
  badge?: string | number;
  badgeColor?: string;
  onClick?: () => void;
}

function SidebarLink({ to, icon, label, badge, badgeColor = 'bg-amber-500/10 text-amber-400 border-amber-500/20', onClick }: SidebarLinkProps) {
  return (
    <NavLink
      to={to}
      onClick={onClick}
      className={({ isActive }) => 
        `flex items-center justify-between px-3 py-2 rounded-lg text-xs font-semibold tracking-wide transition-all ${
          isActive 
            ? 'bg-amber-500/10 text-amber-400 border border-amber-500/20 shadow-sm font-bold' 
            : 'text-slate-400 hover:text-slate-100 hover:bg-[#161F30]'
        }`
      }
    >
      <div className="flex items-center gap-2.5 min-w-0">
        <span className="shrink-0">{icon}</span>
        <span className="truncate">{label}</span>
      </div>
      {badge !== undefined && (
        <span className={`px-1.5 py-0.5 rounded text-[10px] font-mono font-bold border ${badgeColor}`}>
          {badge}
        </span>
      )}
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
  const [searchModalOpen, setSearchModalOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [notificationsOpen, setNotificationsOpen] = useState(false);

  // Keyboard shortcut for search
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault();
        setSearchModalOpen(prev => !prev);
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);

  // Close mobile drawer on route change
  useEffect(() => {
    setMobileMenuOpen(false);
  }, [location.pathname]);

  const handleLogout = async () => {
    await logout();
    navigate('/login');
  };

  const getRoleLabel = (role: string) => {
    return role ? role.replace(/_/g, ' ') : 'SYSTEM_ADMIN';
  };

  // Mock global search data entities
  const mockSearchEntities = [
    { type: 'ATHLETE', title: 'Muhammad Ali', subtitle: 'Islamabad • Senior Heavyweight (105+kg)', id: 'ATH-1092', link: '/athletes' },
    { type: 'ATHLETE', title: 'Zainab Bibi', subtitle: 'Lahore • Female Open (65kg)', id: 'ATH-1044', link: '/athletes' },
    { type: 'TOURNAMENT', title: 'Pakistan National Championship 2026', subtitle: 'Islamabad Sports Complex • Active Stage: Round of 16', id: 'TRN-2026-01', link: '/championships' },
    { type: 'TOURNAMENT', title: 'Punjab Provincial Cup 2026', subtitle: 'Lahore Gymnasium • Registration Open', id: 'TRN-2026-02', link: '/championships' },
    { type: 'MATCH', title: 'Match #M-1048: Heavyweight Semi-Final', subtitle: 'Ali vs. Khan • Referee Certified', id: 'M-1048', link: '/analytics' },
    { type: 'REGISTRATION', title: 'Reg #REG-8820: Usman Tariq', subtitle: 'CNIC Verified • Fee Paid', id: 'REG-8820', link: '/athletes' },
    { type: 'RESULT', title: 'Official Result Ruling #R-401', subtitle: 'Left Arm Senior 90kg • Certified', id: 'R-401', link: '/governance' },
    { type: 'CERTIFICATE', title: 'Cert #CERT-2026-00182', subtitle: 'Issued to Tariq Ahmed • Verification Valid', id: 'CERT-00182', link: '/governance' },
    { type: 'RANKING', title: 'National ELO Ranking Ledger', subtitle: 'Updated Today 18:30 PKT', id: 'RNK-2026', link: '/analytics' }
  ];

  const filteredSearchEntities = searchQuery.trim() === ''
    ? mockSearchEntities.slice(0, 5)
    : mockSearchEntities.filter(item => 
        item.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
        item.subtitle.toLowerCase().includes(searchQuery.toLowerCase()) ||
        item.id.toLowerCase().includes(searchQuery.toLowerCase()) ||
        item.type.toLowerCase().includes(searchQuery.toLowerCase())
      );

  return (
    <div className="flex h-screen bg-[#070A11] text-slate-100 overflow-hidden font-sans">
      {/* DESKTOP COMMAND RAIL */}
      <aside className="hidden lg:flex w-64 bg-[#0F172A] border-r border-slate-800/90 flex-col justify-between shrink-0 z-30">
        <div className="flex-1 overflow-y-auto scrollbar-thin scrollbar-thumb-slate-800">
          {/* Header Branding */}
          <div className="p-4 border-b border-slate-800/90 flex items-center justify-between bg-[#0B0F19]">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-gradient-to-br from-amber-500/20 to-amber-600/10 rounded-lg text-amber-400 border border-amber-500/30">
                <Shield className="w-5 h-5" />
              </div>
              <div>
                <h1 className="font-display font-bold text-sm tracking-tight text-slate-100 uppercase">ArmSphere</h1>
                <p className="text-[10px] text-amber-400 font-mono tracking-wider uppercase font-semibold">Federation Command</p>
              </div>
            </div>
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" title="System Operational" />
          </div>

          {/* Navigation Links Grouped by Spec */}
          <div className="p-3 space-y-4">
            {/* OVERVIEW */}
            <div>
              <p className="px-3 py-1 text-[10px] font-mono font-bold uppercase tracking-widest text-slate-500">
                OVERVIEW
              </p>
              <nav className="mt-1 space-y-0.5">
                <SidebarLink to="/" icon={<LayoutDashboard className="w-4 h-4 text-amber-400" />} label="Operations Center" />
              </nav>
            </div>

            {/* COMPETITION */}
            <div>
              <p className="px-3 py-1 text-[10px] font-mono font-bold uppercase tracking-widest text-slate-500">
                COMPETITION
              </p>
              <nav className="mt-1 space-y-0.5">
                <SidebarLink to="/athletes" icon={<Users className="w-4 h-4 text-blue-400" />} label="Athletes" badge="1,420" />
                <SidebarLink to="/championships" icon={<Trophy className="w-4 h-4 text-amber-400" />} label="Tournaments" badge="3 Active" />
                <SidebarLink to="/registrations" icon={<ClipboardList className="w-4 h-4 text-cyan-400" />} label="Registrations" />
                <SidebarLink to="/analytics" icon={<BarChart3 className="w-4 h-4 text-purple-400" />} label="Brackets & Matches" />
                <SidebarLink to="/nominations" icon={<BadgeCheck className="w-4 h-4 text-emerald-400" />} label="Officials" />
              </nav>
            </div>

            {/* RESULTS & GOVERNANCE */}
            <div>
              <p className="px-3 py-1 text-[10px] font-mono font-bold uppercase tracking-widest text-slate-500">
                RESULTS & GOVERNANCE
              </p>
              <nav className="mt-1 space-y-0.5">
                <SidebarLink to="/governance" icon={<FileCheck className="w-4 h-4 text-red-400" />} label="Results Review" badge="2" badgeColor="bg-red-500/10 text-red-400 border-red-500/20" />
                <SidebarLink to="/moderation" icon={<Video className="w-4 h-4 text-indigo-400" />} label="Certifications" />
                <SidebarLink to="/venues" icon={<Building2 className="w-4 h-4 text-teal-400" />} label="Rankings" />
                <SidebarLink to="/records" icon={<FileText className="w-4 h-4 text-slate-400" />} label="Federation Records" />
                <SidebarLink to="/verification" icon={<Award className="w-4 h-4 text-amber-400" />} label="Verification" badge="12" />
              </nav>
            </div>

            {/* PLATFORM */}
            <div>
              <p className="px-3 py-1 text-[10px] font-mono font-bold uppercase tracking-widest text-slate-500">
                PLATFORM
              </p>
              <nav className="mt-1 space-y-0.5">
                <SidebarLink to="/audit" icon={<Activity className="w-4 h-4 text-emerald-400" />} label="Audit Log" />
                <SidebarLink to="/platform-health" icon={<Server className="w-4 h-4 text-blue-400" />} label="Platform Health" badge="100%" badgeColor="bg-emerald-500/10 text-emerald-400 border-emerald-500/20" />
              </nav>
            </div>
          </div>
        </div>

        {/* Footer User & Security Context */}
        <div className="p-4 border-t border-slate-800 bg-[#0B0F19] space-y-3">
          {/* Security & Context Indicator */}
          <div className="space-y-1">
            <div className="flex items-center justify-between text-[10px] font-mono text-slate-400">
              <span className="flex items-center gap-1 text-emerald-400">
                <Lock className="w-3 h-3" /> Encrypted Session
              </span>
              <span>TLS 1.3</span>
            </div>
            <p className="text-[10px] font-mono text-slate-500 truncate">
              Context: <span className="text-slate-300 font-bold">Pakistan Armwrestling Fed.</span>
            </p>
          </div>

          {/* User Profile Card */}
          <div className="flex items-center gap-2.5 p-2 bg-[#161F30] border border-slate-800/80 rounded-lg">
            <UserCircle className="w-7 h-7 text-amber-400 shrink-0" />
            <div className="min-w-0 flex-1">
              <p className="text-xs font-bold text-slate-200 truncate">
                {user?.fullName || 'Administrator'}
              </p>
              <span className="inline-block text-[9px] font-mono font-semibold uppercase tracking-wider text-amber-400 truncate">
                {getRoleLabel(user?.role || 'SYSTEM_ADMIN')}
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
                    <SidebarLink to="/championships" icon={<Trophy className="w-4 h-4 text-amber-400" />} label="Tournaments" onClick={() => setMobileMenuOpen(false)} />
                    <SidebarLink to="/registrations" icon={<ClipboardList className="w-4 h-4 text-cyan-400" />} label="Registrations" onClick={() => setMobileMenuOpen(false)} />
                    <SidebarLink to="/analytics" icon={<BarChart3 className="w-4 h-4 text-purple-400" />} label="Brackets & Matches" onClick={() => setMobileMenuOpen(false)} />
                    <SidebarLink to="/nominations" icon={<BadgeCheck className="w-4 h-4 text-emerald-400" />} label="Officials" onClick={() => setMobileMenuOpen(false)} />
                  </div>
                </div>
                <div>
                  <p className="text-[10px] font-mono font-bold uppercase tracking-widest text-slate-500 mb-1">Results & Governance</p>
                  <div className="space-y-0.5">
                    <SidebarLink to="/governance" icon={<FileCheck className="w-4 h-4 text-red-400" />} label="Results Review" onClick={() => setMobileMenuOpen(false)} />
                    <SidebarLink to="/moderation" icon={<Video className="w-4 h-4 text-indigo-400" />} label="Certifications" onClick={() => setMobileMenuOpen(false)} />
                    <SidebarLink to="/venues" icon={<Building2 className="w-4 h-4 text-teal-400" />} label="Rankings" onClick={() => setMobileMenuOpen(false)} />
                    <SidebarLink to="/records" icon={<FileText className="w-4 h-4 text-slate-400" />} label="Federation Records" onClick={() => setMobileMenuOpen(false)} />
                    <SidebarLink to="/verification" icon={<Award className="w-4 h-4 text-amber-400" />} label="Verification" onClick={() => setMobileMenuOpen(false)} />
                  </div>
                </div>
                <div>
                  <p className="text-[10px] font-mono font-bold uppercase tracking-widest text-slate-500 mb-1">Platform</p>
                  <div className="space-y-0.5">
                    <SidebarLink to="/audit" icon={<Activity className="w-4 h-4 text-emerald-400" />} label="Audit Log" onClick={() => setMobileMenuOpen(false)} />
                    <SidebarLink to="/platform-health" icon={<Server className="w-4 h-4 text-blue-400" />} label="Platform Health" onClick={() => setMobileMenuOpen(false)} />
                  </div>
                </div>
              </div>
            </div>

            <div className="pt-4 border-t border-slate-800 mt-4 space-y-3">
              <div className="p-2 bg-[#161F30] rounded-lg">
                <p className="text-xs font-bold text-slate-200">{user?.fullName || 'Administrator'}</p>
                <p className="text-[10px] font-mono text-amber-400">{getRoleLabel(user?.role || 'SYSTEM_ADMIN')}</p>
              </div>
              <button
                onClick={handleLogout}
                className="w-full flex items-center justify-center gap-2 px-3 py-2 rounded-lg border border-slate-800 text-slate-400 text-xs font-semibold"
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
          <div className="flex items-center gap-2">
            <button
              onClick={() => setSearchModalOpen(true)}
              className="p-2 bg-[#0F172A] border border-slate-800 rounded-lg text-slate-300 hover:text-white"
            >
              <Search className="w-4 h-4" />
            </button>
          </div>
        </header>

        {/* TOP COMMAND STRIP FOR DESKTOP */}
        <header className="hidden lg:flex items-center justify-between px-8 py-3 bg-[#0B0F19]/90 border-b border-slate-800/80 backdrop-blur-md">
          <div className="flex items-center gap-4 text-xs font-mono text-slate-400">
            <span className="flex items-center gap-1.5 text-slate-200 font-bold">
              <Globe2 className="w-4 h-4 text-amber-400" /> PAKISTAN FEDERATION CONTEXT
            </span>
            <span className="text-slate-700">•</span>
            <span>2026 Competitive Season</span>
            <span className="text-slate-700">•</span>
            <span className="flex items-center gap-1 text-emerald-400">
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" /> Live Telemetry Online
            </span>
          </div>

          <div className="flex items-center gap-3">
            {/* Quick Search Input Trigger */}
            <button
              onClick={() => setSearchModalOpen(true)}
              className="flex items-center gap-3 px-3 py-1.5 bg-[#0F172A] hover:bg-slate-800 border border-slate-800 rounded-lg text-xs font-mono text-slate-400 transition-colors w-64 justify-between"
            >
              <span className="flex items-center gap-2">
                <Search className="w-3.5 h-3.5 text-slate-500" />
                <span>Search official entities...</span>
              </span>
              <kbd className="px-1.5 py-0.5 bg-[#070A11] border border-slate-700 rounded text-[10px] text-slate-400 font-sans">
                ⌘K
              </kbd>
            </button>

            {/* Notifications / Attention Center Trigger */}
            <div className="relative">
              <button
                onClick={() => setNotificationsOpen(prev => !prev)}
                className="p-2 bg-[#0F172A] hover:bg-slate-800 border border-slate-800 rounded-lg text-slate-300 transition-colors relative"
              >
                <Bell className="w-4 h-4 text-slate-300" />
                <span className="absolute -top-1 -right-1 w-4 h-4 bg-amber-500 text-slate-950 font-mono font-bold text-[9px] rounded-full flex items-center justify-center shadow">
                  3
                </span>
              </button>

              {/* Notifications Popover */}
              {notificationsOpen && (
                <div className="absolute right-0 mt-2 w-80 bg-[#0F172A] border border-slate-800 rounded-xl shadow-2xl p-4 z-50 text-xs">
                  <div className="flex items-center justify-between pb-3 border-b border-slate-800">
                    <span className="font-mono font-bold text-slate-200 uppercase tracking-wider">Operational Attention</span>
                    <span className="px-2 py-0.5 bg-amber-500/10 text-amber-400 border border-amber-500/20 rounded text-[10px] font-mono font-bold">
                      3 Pending
                    </span>
                  </div>
                  <div className="mt-3 space-y-2 font-mono">
                    <div className="p-2.5 bg-[#070A11] border border-slate-800 rounded-lg hover:border-amber-500/40 cursor-pointer" onClick={() => { setNotificationsOpen(false); navigate('/governance'); }}>
                      <p className="font-bold text-amber-400">Match #M-1048 Protest</p>
                      <p className="text-slate-400 text-[11px] mt-0.5">Referee certification pending review</p>
                    </div>
                    <div className="p-2.5 bg-[#070A11] border border-slate-800 rounded-lg hover:border-blue-500/40 cursor-pointer" onClick={() => { setNotificationsOpen(false); navigate('/athletes'); }}>
                      <p className="font-bold text-blue-400">Athlete Verification</p>
                      <p className="text-slate-400 text-[11px] mt-0.5">National CNIC review required</p>
                    </div>
                    <div className="p-2.5 bg-[#070A11] border border-slate-800 rounded-lg hover:border-purple-500/40 cursor-pointer" onClick={() => { setNotificationsOpen(false); navigate('/championships'); }}>
                      <p className="font-bold text-purple-400">Sanctioning Request</p>
                      <p className="text-slate-400 text-[11px] mt-0.5">Heavyweight Title challenge awaiting approval</p>
                    </div>
                  </div>
                </div>
              )}
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

      {/* GLOBAL SEARCH MODAL (PART 16) */}
      {searchModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-md flex items-start justify-center pt-20 p-4">
          <div className="w-full max-w-2xl bg-[#0F172A] border border-slate-800 rounded-2xl shadow-2xl overflow-hidden">
            {/* Search Input Bar */}
            <div className="p-4 border-b border-slate-800 flex items-center gap-3 bg-[#0B0F19]">
              <Search className="w-5 h-5 text-amber-400 shrink-0" />
              <input
                type="text"
                autoFocus
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search athletes, tournaments, matches, registrations, results, certificates..."
                className="w-full bg-transparent text-slate-100 placeholder-slate-500 text-sm focus:outline-none font-sans"
              />
              <button
                onClick={() => setSearchModalOpen(false)}
                className="p-1 text-slate-400 hover:text-white"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Results List */}
            <div className="p-4 max-h-96 overflow-y-auto space-y-2">
              <p className="text-[10px] font-mono font-bold uppercase tracking-widest text-slate-500 px-2 mb-2">
                Official Entity Registry Results
              </p>

              {filteredSearchEntities.length > 0 ? (
                filteredSearchEntities.map((entity, idx) => (
                  <div
                    key={idx}
                    onClick={() => {
                      setSearchModalOpen(false);
                      navigate(entity.link);
                    }}
                    className="p-3 bg-[#070A11] hover:bg-[#161F30] border border-slate-800 hover:border-amber-500/40 rounded-xl flex items-center justify-between cursor-pointer transition-colors group"
                  >
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="px-2 py-0.5 rounded text-[9px] font-mono font-bold uppercase bg-amber-500/10 text-amber-400 border border-amber-500/20">
                          {entity.type}
                        </span>
                        <span className="text-xs font-mono text-slate-500">{entity.id}</span>
                      </div>
                      <p className="text-sm font-bold text-slate-100 mt-1">{entity.title}</p>
                      <p className="text-xs text-slate-400 font-mono mt-0.5">{entity.subtitle}</p>
                    </div>
                    <ChevronRight className="w-4 h-4 text-slate-600 group-hover:text-amber-400 transition-colors shrink-0" />
                  </div>
                ))
              ) : (
                <div className="p-6 text-center text-slate-500 text-xs font-mono">
                  No official records matched "{searchQuery}"
                </div>
              )}
            </div>

            {/* Modal Footer */}
            <div className="p-3 border-t border-slate-800 bg-[#0B0F19] flex items-center justify-between text-[11px] font-mono text-slate-500">
              <span>Navigate with arrow keys • Select entity to open module</span>
              <kbd className="px-2 py-0.5 bg-[#070A11] border border-slate-700 rounded text-slate-400">ESC to close</kbd>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
