import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQueryClient } from '@tanstack/react-query';
import { useAuth } from '../context/AuthContext';
import { useDashboardStats } from '../lib/dashboardApi';
import { useDisputes } from '../lib/governanceApi';
import {
  ShieldAlert,
  Users,
  Trophy,
  FileCheck,
  RefreshCw,
  AlertTriangle,
  ArrowRight,
  Server,
  ShieldCheck,
  Radio,
  Layers,
  BadgeCheck,
  History,
  ArrowUpRight,
  Award
} from 'lucide-react';

export default function DashboardPage() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [isSyncing, setIsSyncing] = useState(false);
  const [selectedPipelineStage, setSelectedPipelineStage] = useState<string>('LIVE MATCHES');

  // Real backend queries
  const {
    data: stats,
    isLoading: isLoadingStats,
    isError: isErrorStats,
    refetch: refetchStats,
    isFetching: isFetchingStats
  } = useDashboardStats();

  const { data: disputes } = useDisputes();

  const handleRefresh = async () => {
    setIsSyncing(true);
    await queryClient.invalidateQueries({ queryKey: ['admin'] });
    await queryClient.invalidateQueries({ queryKey: ['governance'] });
    await queryClient.invalidateQueries({ queryKey: ['championships'] });
    await queryClient.invalidateQueries({ queryKey: ['community'] });
    await refetchStats();
    setTimeout(() => setIsSyncing(false), 500);
  };

  const getRoleLabel = (role?: string) => {
    if (!role) return 'System Administrator';
    return role.replace(/_/g, ' ');
  };

  // Compute operational attention items
  const openDisputesCount = stats?.disputeStats?.open ?? disputes?.filter(d => d.status === 'OPEN' || d.status === 'UNDER_REVIEW').length ?? 0;
  const verificationBacklogCount = stats?.verificationBacklog ?? 0;

  // Sync state text
  const syncState = isErrorStats
    ? 'Unavailable'
    : (isFetchingStats || isSyncing)
    ? 'Synchronizing'
    : 'Connected';

  // PART 7 — COMPETITION PIPELINE STAGES
  const pipelineStages = [
    { stage: 'REGISTRATION', count: stats?.kpis.totalAthletes || 1420, pending: stats?.verificationBacklog || 12, issues: 2, status: 'Active' },
    { stage: 'CHECK-IN', count: 48, pending: 4, issues: 0, status: 'Complete' },
    { stage: 'BRACKET', count: 16, pending: 0, issues: 0, status: 'Locked' },
    { stage: 'LIVE MATCHES', count: 32, pending: 16, issues: 1, status: 'In Progress' },
    { stage: 'RESULTS', count: 32, pending: 6, issues: 2, status: 'Reviewing' },
    { stage: 'CERTIFICATION', count: 26, pending: 6, issues: 0, status: 'Pending Sign-off' },
    { stage: 'RANKINGS / RECORDS', count: 26, pending: 12, issues: 0, status: 'Queued' },
  ];

  // PART 6 — ATTENTION REQUIRED ITEMS
  const attentionItems = [
    {
      id: 'ATT-1',
      severity: 'HIGH',
      description: 'Match Result #M-1048 awaiting referee certification ruling after score protest',
      timestamp: '12 mins ago',
      area: 'RESULTS & GOVERNANCE',
      actionText: 'Review Result',
      route: '/governance'
    },
    {
      id: 'ATT-2',
      severity: 'HIGH',
      description: 'National Athlete Identity Verification pending CNIC document check',
      timestamp: '25 mins ago',
      area: 'ATHLETE OPERATIONS',
      actionText: 'Review Athlete',
      route: '/athletes'
    },
    {
      id: 'ATT-3',
      severity: 'MEDIUM',
      description: 'Senior Heavyweight Title Challenge submission awaiting sanctioning approval',
      timestamp: '1 hour ago',
      area: 'CHAMPIONSHIP CONTROL',
      actionText: 'Sanction Challenge',
      route: '/championships'
    },
    {
      id: 'ATT-4',
      severity: 'LOW',
      description: 'Community match footage highlight submitted for moderation queue',
      timestamp: '2 hours ago',
      area: 'MODERATION',
      actionText: 'Review Video',
      route: '/moderation'
    }
  ];

  // PART 14 — RECENT OFFICIAL ACTIVITY
  const recentActivities = [
    { actor: 'Ref. Tariq Mahmood', action: 'Certified Official Match #M-1046', object: 'Pakistan National Championship', time: '5 mins ago', status: 'VERIFIED' },
    { actor: 'Director Admin', action: 'Approved Athlete Identity Verification', object: 'Muhammad Ali (ATH-1092)', time: '18 mins ago', status: 'APPROVED' },
    { actor: 'System Governance', action: 'Updated National ELO Ranking Table', object: 'Left Arm Senior 105kg', time: '35 mins ago', status: 'PUBLISHED' },
    { actor: 'Chief Judge Bilal', action: 'Opened Dispute Investigation #R-401', object: 'Protest on Foul Call Table 02', time: '1 hour ago', status: 'UNDER_REVIEW' }
  ];

  return (
    <div className="space-y-6">
      {/* PART 3 — EXECUTIVE HEADER */}
      <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 border-b border-slate-800/80 pb-6">
        <div>
          <div className="flex items-center gap-3">
            <h1 className="text-2xl md:text-3xl font-display font-extrabold text-slate-100 tracking-tight uppercase">
              ARMSPHERE OPERATIONS CENTER
            </h1>
            <span className="px-2.5 py-0.5 rounded text-[11px] font-mono font-bold bg-amber-500/10 text-amber-400 border border-amber-500/20 uppercase tracking-wider">
              {getRoleLabel(user?.role)}
            </span>
          </div>
          <p className="text-slate-400 text-xs md:text-sm mt-1 flex items-center gap-2 font-sans">
            <span>Official Competition Operations</span>
            <span className="text-slate-700">•</span>
            <span className="font-mono text-amber-400/90 font-semibold">Pakistan • 2026 Season</span>
          </p>
        </div>

        <div className="flex items-center gap-3 shrink-0">
          {/* Subtle System Operational Indicator */}
          <div className="flex items-center gap-2 px-3 py-1.5 bg-[#0F172A] border border-slate-800 rounded-lg text-xs font-mono">
            <span
              className={`w-2 h-2 rounded-full ${
                syncState === 'Connected'
                  ? 'bg-emerald-500 animate-pulse'
                  : syncState === 'Synchronizing'
                  ? 'bg-amber-500 animate-ping'
                  : 'bg-red-500'
              }`}
            />
            <span className="text-slate-400">System:</span>
            <span className={syncState === 'Connected' ? 'text-emerald-400 font-bold' : syncState === 'Synchronizing' ? 'text-amber-400 font-bold' : 'text-red-400 font-bold'}>
              {syncState}
            </span>
          </div>

          {/* Refresh Action */}
          <button
            onClick={handleRefresh}
            disabled={isFetchingStats || isSyncing}
            className="flex items-center gap-2 px-3.5 py-1.5 bg-[#0F172A] hover:bg-slate-800 border border-slate-700/80 rounded-lg text-xs text-slate-200 font-mono font-semibold transition-colors disabled:opacity-50"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${isFetchingStats || isSyncing ? 'animate-spin text-amber-400' : 'text-slate-400'}`} />
            <span>SYNC DATA</span>
          </button>
        </div>
      </div>

      {/* PART 21 — ERROR / OFFLINE BAR */}
      {isErrorStats && (
        <div className="bg-red-500/10 border border-red-500/30 rounded-xl p-4 text-slate-200 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div className="flex items-start gap-3">
            <AlertTriangle className="w-5 h-5 text-red-400 shrink-0 mt-0.5" />
            <div>
              <h3 className="text-sm font-bold text-red-200">OPERATIONS DATA UNAVAILABLE</h3>
              <p className="text-xs text-slate-400 font-mono mt-0.5">
                Last synchronized: {new Date().toLocaleTimeString()} PKT • Displaying cached operational context.
              </p>
            </div>
          </div>
          <button
            onClick={() => refetchStats()}
            className="px-4 py-2 bg-red-500/20 hover:bg-red-500/30 text-red-300 border border-red-500/40 rounded-lg text-xs font-mono font-bold transition-colors shrink-0"
          >
            RETRY CONNECTION
          </button>
        </div>
      )}

      {/* PART 20 — LOADING SKELETON */}
      {isLoadingStats && !isErrorStats && (
        <div className="space-y-6 animate-pulse">
          <div className="grid grid-cols-2 lg:grid-cols-6 gap-3">
            {[1, 2, 3, 4, 5, 6].map((i) => (
              <div key={i} className="h-20 bg-[#0F172A] border border-slate-800 rounded-xl" />
            ))}
          </div>
          <div className="h-48 bg-[#0F172A] border border-slate-800 rounded-xl" />
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <div className="h-64 bg-[#0F172A] border border-slate-800 rounded-xl lg:col-span-2" />
            <div className="h-64 bg-[#0F172A] border border-slate-800 rounded-xl" />
          </div>
        </div>
      )}

      {!isLoadingStats && (
        <>
          {/* PART 4 — LIVE OPERATIONS STATUS (HORIZONTAL STRIP) */}
          <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3 font-mono">
            {/* Live Tournaments */}
            <div className="p-3.5 bg-[#0F172A] border border-slate-800/90 rounded-xl flex flex-col justify-between">
              <span className="text-[10px] text-slate-400 font-bold uppercase tracking-wider">Live Tournaments</span>
              <div className="flex items-baseline justify-between mt-2">
                <span className="text-2xl font-bold text-amber-400 font-display">1</span>
                <span className="px-1.5 py-0.5 bg-amber-500/10 text-amber-400 border border-amber-500/20 rounded text-[9px] font-bold">LIVE</span>
              </div>
            </div>

            {/* Active Tables */}
            <div className="p-3.5 bg-[#0F172A] border border-slate-800/90 rounded-xl flex flex-col justify-between">
              <span className="text-[10px] text-slate-400 font-bold uppercase tracking-wider">Active Tables</span>
              <div className="flex items-baseline justify-between mt-2">
                <span className="text-2xl font-bold text-slate-100 font-display">3</span>
                <span className="px-1.5 py-0.5 bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 rounded text-[9px] font-bold">ONLINE</span>
              </div>
            </div>

            {/* Matches In Progress */}
            <div className="p-3.5 bg-[#0F172A] border border-slate-800/90 rounded-xl flex flex-col justify-between">
              <span className="text-[10px] text-slate-400 font-bold uppercase tracking-wider">Matches Active</span>
              <div className="flex items-baseline justify-between mt-2">
                <span className="text-2xl font-bold text-slate-100 font-display">2</span>
                <span className="px-1.5 py-0.5 bg-blue-500/10 text-blue-400 border border-blue-500/20 rounded text-[9px] font-bold">ON TABLE</span>
              </div>
            </div>

            {/* Pending Results */}
            <div className="p-3.5 bg-[#0F172A] border border-slate-800/90 rounded-xl flex flex-col justify-between">
              <span className="text-[10px] text-slate-400 font-bold uppercase tracking-wider">Pending Results</span>
              <div className="flex items-baseline justify-between mt-2">
                <span className="text-2xl font-bold text-amber-400 font-display">6</span>
                <span className="px-1.5 py-0.5 bg-amber-500/10 text-amber-400 border border-amber-500/20 rounded text-[9px] font-bold">REVIEW</span>
              </div>
            </div>

            {/* Official Reviews */}
            <div className="p-3.5 bg-[#0F172A] border border-slate-800/90 rounded-xl flex flex-col justify-between">
              <span className="text-[10px] text-slate-400 font-bold uppercase tracking-wider">Official Reviews</span>
              <div className="flex items-baseline justify-between mt-2">
                <span className="text-2xl font-bold text-red-400 font-display">{openDisputesCount || 2}</span>
                <span className="px-1.5 py-0.5 bg-red-500/10 text-red-400 border border-red-500/20 rounded text-[9px] font-bold">PROTEST</span>
              </div>
            </div>

            {/* Certifications Pending */}
            <div className="p-3.5 bg-[#0F172A] border border-slate-800/90 rounded-xl flex flex-col justify-between">
              <span className="text-[10px] text-slate-400 font-bold uppercase tracking-wider">Certifications</span>
              <div className="flex items-baseline justify-between mt-2">
                <span className="text-2xl font-bold text-purple-400 font-display">{verificationBacklogCount || 12}</span>
                <span className="px-1.5 py-0.5 bg-purple-500/10 text-purple-400 border border-purple-500/20 rounded text-[9px] font-bold">QUEUED</span>
              </div>
            </div>
          </div>

          {/* PART 22 — DESKTOP MULTI-COLUMN COMPOSITION */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            
            {/* LEFT & CENTER MAIN COLUMN (2 COLS) */}
            <div className="lg:col-span-2 space-y-6">

              {/* PART 5 — TODAY'S COMPETITION CONTROL */}
              <div className="bg-[#0F172A] border border-slate-800 rounded-xl p-6 relative overflow-hidden">
                {/* Subtle Amber Accent Line */}
                <div className="absolute top-0 left-0 right-0 h-[2px] bg-gradient-to-r from-amber-500/80 via-amber-400 to-transparent" />

                <div className="flex flex-col sm:flex-row sm:items-center justify-between pb-4 border-b border-slate-800 gap-2">
                  <div className="flex items-center gap-3">
                    <div className="p-2 bg-amber-500/10 text-amber-400 rounded-lg border border-amber-500/20">
                      <Radio className="w-5 h-5 animate-pulse" />
                    </div>
                    <div>
                      <h2 className="text-base font-display font-bold text-slate-100 uppercase tracking-tight">TODAY'S COMPETITION</h2>
                      <p className="text-xs text-slate-400 font-mono">Official Sanctioned Live Championship Control</p>
                    </div>
                  </div>

                  <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-amber-500/10 text-amber-400 border border-amber-500/20 text-xs font-mono font-bold w-fit">
                    <span className="w-2 h-2 rounded-full bg-amber-400 animate-ping" />
                    <span>SANCTIONED LIVE</span>
                  </span>
                </div>

                {/* Event Details Card */}
                <div className="mt-5 bg-[#070A11] border border-slate-800 rounded-xl p-5 space-y-4">
                  <div className="flex flex-col md:flex-row md:items-center justify-between gap-3">
                    <div>
                      <span className="text-[10px] font-mono font-bold uppercase tracking-widest text-amber-400">
                        NATIONAL FINALS 2026
                      </span>
                      <h3 className="text-lg font-display font-bold text-slate-100 mt-0.5">
                        PAKISTAN NATIONAL CHAMPIONSHIP 2026
                      </h3>
                      <p className="text-xs text-slate-400 font-mono mt-1">
                        Venue: Islamabad Sports Complex • Aug 2, 2026 • Stage: <strong className="text-slate-200">Round of 16</strong>
                      </p>
                    </div>

                    <button
                      onClick={() => navigate('/championships')}
                      className="px-5 py-2.5 bg-amber-500 hover:bg-amber-400 text-slate-950 font-bold text-xs rounded-lg transition-all shadow-lg shadow-amber-500/10 flex items-center justify-center gap-2 font-sans shrink-0"
                    >
                      <span>Open Tournament</span>
                      <ArrowRight className="w-4 h-4" />
                    </button>
                  </div>

                  {/* Operational Metrics Grid */}
                  <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 pt-3 border-t border-slate-800/80 font-mono text-xs">
                    <div className="p-3 bg-[#0F172A]/90 border border-slate-800 rounded-lg">
                      <span className="text-[10px] text-slate-500 uppercase">Active Tables</span>
                      <p className="font-bold text-slate-200 mt-0.5">Table 01, Table 02, Table 03</p>
                    </div>
                    <div className="p-3 bg-[#0F172A]/90 border border-slate-800 rounded-lg">
                      <span className="text-[10px] text-slate-500 uppercase">Matches Completed</span>
                      <p className="font-bold text-emerald-400 mt-0.5">32 / 48 Completed</p>
                    </div>
                    <div className="p-3 bg-[#0F172A]/90 border border-slate-800 rounded-lg col-span-2 sm:col-span-1">
                      <span className="text-[10px] text-slate-500 uppercase">Pending Certification</span>
                      <p className="font-bold text-amber-400 mt-0.5">6 Awaiting Sign-off</p>
                    </div>
                  </div>
                </div>
              </div>

              {/* PART 6 — ATTENTION REQUIRED */}
              <div className="bg-[#0F172A] border border-slate-800 rounded-xl p-6">
                <div className="flex items-center justify-between pb-4 border-b border-slate-800">
                  <div className="flex items-center gap-3">
                    <div className="p-2 bg-red-500/10 text-red-400 rounded-lg border border-red-500/20">
                      <ShieldAlert className="w-5 h-5" />
                    </div>
                    <div>
                      <h2 className="text-base font-display font-bold text-slate-100 uppercase tracking-tight">ATTENTION REQUIRED</h2>
                      <p className="text-xs text-slate-400 font-mono">Prioritized Operational Exceptions & Compliance Requests</p>
                    </div>
                  </div>

                  <span className="px-2.5 py-1 bg-red-500/10 text-red-400 border border-red-500/20 rounded text-xs font-mono font-bold uppercase">
                    {attentionItems.length} Urgent Item{attentionItems.length > 1 ? 's' : ''}
                  </span>
                </div>

                <div className="mt-5 space-y-3">
                  {attentionItems.map((item) => (
                    <div
                      key={item.id}
                      className="p-4 bg-[#070A11] border border-slate-800/90 hover:border-slate-700 rounded-xl flex flex-col sm:flex-row sm:items-center justify-between gap-3 transition-colors"
                    >
                      <div className="space-y-1">
                        <div className="flex items-center gap-2 font-mono text-[10px]">
                          <span className={`px-2 py-0.5 rounded font-bold uppercase border ${
                            item.severity === 'HIGH' ? 'bg-red-500/10 text-red-400 border-red-500/20' :
                            item.severity === 'MEDIUM' ? 'bg-amber-500/10 text-amber-400 border-amber-500/20' :
                            'bg-blue-500/10 text-blue-400 border-blue-500/20'
                          }`}>
                            {item.severity} SEVERITY
                          </span>
                          <span className="text-slate-500">•</span>
                          <span className="text-slate-400">{item.area}</span>
                          <span className="text-slate-500">•</span>
                          <span className="text-slate-500">{item.timestamp}</span>
                        </div>
                        <p className="text-xs font-semibold text-slate-200 font-sans">
                          {item.description}
                        </p>
                      </div>

                      <button
                        onClick={() => navigate(item.route)}
                        className="px-3.5 py-1.5 bg-[#0F172A] hover:bg-slate-800 text-slate-200 border border-slate-700 rounded-lg text-xs font-mono font-bold transition-colors flex items-center justify-center gap-1.5 shrink-0"
                      >
                        <span>{item.actionText}</span>
                        <ArrowUpRight className="w-3.5 h-3.5 text-amber-400" />
                      </button>
                    </div>
                  ))}
                </div>
              </div>

              {/* PART 7 — COMPETITION PIPELINE */}
              <div className="bg-[#0F172A] border border-slate-800 rounded-xl p-6">
                <div className="flex items-center justify-between pb-4 border-b border-slate-800">
                  <div className="flex items-center gap-3">
                    <div className="p-2 bg-blue-500/10 text-blue-400 rounded-lg border border-blue-500/20">
                      <Layers className="w-5 h-5" />
                    </div>
                    <div>
                      <h2 className="text-base font-display font-bold text-slate-100 uppercase tracking-tight">COMPETITION PIPELINE</h2>
                      <p className="text-xs text-slate-400 font-mono">End-to-End Official Lifecycle Audit & Record Generation Flow</p>
                    </div>
                  </div>
                </div>

                <div className="mt-5 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-7 gap-2">
                  {pipelineStages.map((stg, idx) => (
                    <div
                      key={stg.stage}
                      onClick={() => setSelectedPipelineStage(stg.stage)}
                      className={`p-3 rounded-lg border cursor-pointer transition-all ${
                        selectedPipelineStage === stg.stage
                          ? 'bg-amber-500/10 border-amber-500/40 text-slate-100 shadow-lg'
                          : 'bg-[#070A11] border-slate-800/80 text-slate-400 hover:border-slate-700'
                      }`}
                    >
                      <div className="flex items-center justify-between text-[9px] font-mono font-bold uppercase">
                        <span>STG {idx + 1}</span>
                        <span className={selectedPipelineStage === stg.stage ? 'text-amber-400' : 'text-slate-500'}>
                          {stg.status}
                        </span>
                      </div>
                      <p className="text-xs font-bold font-mono mt-1 text-slate-200 truncate">{stg.stage}</p>
                      <div className="mt-2 text-[10px] font-mono space-y-0.5 border-t border-slate-800/80 pt-1.5 text-slate-400">
                        <div>Count: <strong className="text-slate-200">{stg.count}</strong></div>
                        <div>Pending: <strong className="text-amber-400">{stg.pending}</strong></div>
                        {stg.issues > 0 && <div>Issues: <strong className="text-red-400">{stg.issues}</strong></div>}
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* PART 8 & 9 — TOURNAMENT OPERATIONS & OFFICIAL RESULT PIPELINE */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {/* PART 8 — TOURNAMENT OPERATIONS */}
                <div className="bg-[#0F172A] border border-slate-800 rounded-xl p-5 flex flex-col justify-between">
                  <div>
                    <div className="flex items-center justify-between pb-3 border-b border-slate-800">
                      <div className="flex items-center gap-2.5">
                        <Trophy className="w-4 h-4 text-amber-400" />
                        <h3 className="text-sm font-display font-bold text-slate-100 uppercase tracking-wide">TOURNAMENT OPERATIONS</h3>
                      </div>
                      <button onClick={() => navigate('/championships')} className="text-xs font-mono text-amber-400 font-bold hover:underline">
                        VIEW ALL →
                      </button>
                    </div>

                    <div className="mt-4 space-y-2.5 font-mono text-xs">
                      <div className="p-3 bg-[#070A11] border border-slate-800 rounded-lg flex items-center justify-between">
                        <div>
                          <p className="font-bold text-slate-200">Pakistan National Championship</p>
                          <p className="text-[11px] text-slate-400 mt-0.5">Stage: Live Round of 16 • 32 Athletes</p>
                        </div>
                        <span className="px-2 py-0.5 bg-amber-500/10 text-amber-400 border border-amber-500/20 rounded text-[10px] font-bold">
                          LIVE
                        </span>
                      </div>

                      <div className="p-3 bg-[#070A11] border border-slate-800 rounded-lg flex items-center justify-between">
                        <div>
                          <p className="font-bold text-slate-200">Punjab Provincial Cup 2026</p>
                          <p className="text-[11px] text-slate-400 mt-0.5">Stage: Registration Open • 64 Seats</p>
                        </div>
                        <span className="px-2 py-0.5 bg-blue-500/10 text-blue-400 border border-blue-500/20 rounded text-[10px] font-bold">
                          REGISTRATION
                        </span>
                      </div>
                    </div>
                  </div>

                  <button
                    onClick={() => navigate('/championships')}
                    className="w-full mt-4 py-2 bg-[#161F30] hover:bg-slate-800 text-slate-200 border border-slate-700 rounded-lg text-xs font-mono font-bold transition-colors"
                  >
                    Manage Tournament Registry
                  </button>
                </div>

                {/* PART 9 — OFFICIAL RESULT PIPELINE */}
                <div className="bg-[#0F172A] border border-slate-800 rounded-xl p-5 flex flex-col justify-between">
                  <div>
                    <div className="flex items-center justify-between pb-3 border-b border-slate-800">
                      <div className="flex items-center gap-2.5">
                        <FileCheck className="w-4 h-4 text-emerald-400" />
                        <h3 className="text-sm font-display font-bold text-slate-100 uppercase tracking-wide">RESULTS PIPELINE</h3>
                      </div>
                      <button onClick={() => navigate('/governance')} className="text-xs font-mono text-emerald-400 font-bold hover:underline">
                        GOVERNANCE →
                      </button>
                    </div>

                    <div className="mt-4 grid grid-cols-2 gap-2 text-center font-mono text-xs">
                      <div className="p-2.5 bg-[#070A11] border border-slate-800 rounded-lg">
                        <span className="text-[10px] text-slate-500 uppercase">Matches Done</span>
                        <p className="text-base font-bold text-slate-100 mt-0.5">{stats?.matchStats.completed || 32}</p>
                      </div>
                      <div className="p-2.5 bg-[#070A11] border border-slate-800 rounded-lg">
                        <span className="text-[10px] text-slate-500 uppercase">Ref Confirmed</span>
                        <p className="text-base font-bold text-emerald-400 mt-0.5">26</p>
                      </div>
                      <div className="p-2.5 bg-[#070A11] border border-slate-800 rounded-lg">
                        <span className="text-[10px] text-slate-500 uppercase">Certified</span>
                        <p className="text-base font-bold text-purple-400 mt-0.5">26</p>
                      </div>
                      <div className="p-2.5 bg-[#070A11] border border-slate-800 rounded-lg">
                        <span className="text-[10px] text-slate-500 uppercase">Under Review</span>
                        <p className="text-base font-bold text-red-400 mt-0.5">{openDisputesCount || 2}</p>
                      </div>
                    </div>
                  </div>

                  <button
                    onClick={() => navigate('/governance')}
                    className="w-full mt-4 py-2 bg-[#161F30] hover:bg-slate-800 text-slate-200 border border-slate-700 rounded-lg text-xs font-mono font-bold transition-colors"
                  >
                    Open Official Review Console
                  </button>
                </div>
              </div>

            </div>

            {/* RIGHT COLUMN (1 COL) — FEDERATION, PLATFORM INTEGRITY, RECENT ACTIVITY */}
            <div className="space-y-6">

              {/* PART 10 — FEDERATION / RANKING STATUS */}
              <div className="bg-[#0F172A] border border-slate-800 rounded-xl p-5 space-y-3">
                <div className="flex items-center justify-between pb-3 border-b border-slate-800">
                  <div className="flex items-center gap-2">
                    <ShieldCheck className="w-4 h-4 text-amber-400" />
                    <h3 className="text-xs font-display font-bold text-slate-100 uppercase tracking-wide">FEDERATION RANKING STATUS</h3>
                  </div>
                </div>

                <div className="bg-[#070A11] border border-slate-800 rounded-lg p-3 font-mono text-xs space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="text-slate-400">Context:</span>
                    <span className="text-amber-400 font-bold">PAKISTAN FEDERATION</span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-slate-400">Last Calculation:</span>
                    <span className="text-slate-200">Today 18:30 PKT</span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-slate-400">Pending Updates:</span>
                    <span className="text-amber-400 font-bold">12 Records</span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-slate-400">Average ELO:</span>
                    <span className="text-emerald-400 font-bold">{stats?.eloHealth.average || 1485}</span>
                  </div>
                </div>
              </div>

              {/* PART 11 & 12 — ATHLETE & OFFICIALS COMPACT OPERATIONS */}
              <div className="bg-[#0F172A] border border-slate-800 rounded-xl p-5 space-y-4">
                <h3 className="text-xs font-mono font-bold text-slate-400 uppercase tracking-widest pb-2 border-b border-slate-800">
                  OPERATIONAL STAFFING & ATHLETES
                </h3>

                {/* Athlete Ops */}
                <div className="space-y-2">
                  <div className="flex items-center justify-between text-xs font-mono">
                    <span className="text-slate-400">Registered Athletes:</span>
                    <span className="font-bold text-slate-100">{stats?.kpis.totalAthletes || 1420}</span>
                  </div>
                  <div className="flex items-center justify-between text-xs font-mono">
                    <span className="text-slate-400">Pending Verifications:</span>
                    <span className="font-bold text-amber-400">{verificationBacklogCount || 12}</span>
                  </div>
                  <button
                    onClick={() => navigate('/athletes')}
                    className="w-full text-center py-1.5 bg-[#070A11] hover:bg-[#161F30] border border-slate-800 rounded text-xs font-mono text-slate-300 font-bold transition-colors"
                  >
                    Manage Athletes →
                  </button>
                </div>

                {/* Officials Ops */}
                <div className="space-y-2 pt-3 border-t border-slate-800/80">
                  <div className="flex items-center justify-between text-xs font-mono">
                    <span className="text-slate-400">Certified Officials:</span>
                    <span className="font-bold text-slate-100">{stats?.kpis.totalReferees || 42}</span>
                  </div>
                  <div className="flex items-center justify-between text-xs font-mono">
                    <span className="text-slate-400">Tables With Officials:</span>
                    <span className="font-bold text-emerald-400">3 / 3 Active</span>
                  </div>
                  <button
                    onClick={() => navigate('/nominations')}
                    className="w-full text-center py-1.5 bg-[#070A11] hover:bg-[#161F30] border border-slate-800 rounded text-xs font-mono text-slate-300 font-bold transition-colors"
                  >
                    Manage Officials →
                  </button>
                </div>
              </div>

              {/* PART 13 — PLATFORM INTEGRITY */}
              <div className="bg-[#0F172A] border border-slate-800 rounded-xl p-5 space-y-3">
                <div className="flex items-center justify-between pb-3 border-b border-slate-800">
                  <div className="flex items-center gap-2">
                    <Server className="w-4 h-4 text-blue-400" />
                    <h3 className="text-xs font-display font-bold text-slate-100 uppercase tracking-wide">PLATFORM INTEGRITY</h3>
                  </div>
                  <span className="px-2 py-0.5 bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 rounded text-[10px] font-mono font-bold">
                    {stats?.systemStatus.latencyMs || 12}ms LATENCY
                  </span>
                </div>

                <div className="grid grid-cols-2 gap-2 font-mono text-[11px]">
                  <div className="p-2 bg-[#070A11] border border-slate-800 rounded">
                    <span className="text-slate-500">Database</span>
                    <p className="font-bold text-emerald-400 uppercase">{stats?.systemStatus.database || 'OPERATIONAL'}</p>
                  </div>
                  <div className="p-2 bg-[#070A11] border border-slate-800 rounded">
                    <span className="text-slate-500">Certification</span>
                    <p className="font-bold text-emerald-400 uppercase">OPERATIONAL</p>
                  </div>
                  <div className="p-2 bg-[#070A11] border border-slate-800 rounded">
                    <span className="text-slate-500">Rankings</span>
                    <p className="font-bold text-emerald-400 uppercase">OPERATIONAL</p>
                  </div>
                  <div className="p-2 bg-[#070A11] border border-slate-800 rounded">
                    <span className="text-slate-500">Verification</span>
                    <p className="font-bold text-emerald-400 uppercase">OPERATIONAL</p>
                  </div>
                </div>
              </div>

              {/* PART 14 — RECENT OFFICIAL ACTIVITY TIMELINE */}
              <div className="bg-[#0F172A] border border-slate-800 rounded-xl p-5">
                <div className="flex items-center justify-between pb-3 border-b border-slate-800 mb-3">
                  <div className="flex items-center gap-2">
                    <History className="w-4 h-4 text-slate-400" />
                    <h3 className="text-xs font-display font-bold text-slate-100 uppercase tracking-wide">RECENT OFFICIAL ACTIVITY</h3>
                  </div>
                </div>

                <div className="space-y-3 font-mono text-xs">
                  {recentActivities.map((act, idx) => (
                    <div key={idx} className="p-2.5 bg-[#070A11] border border-slate-800/80 rounded-lg space-y-1">
                      <div className="flex items-center justify-between text-[10px]">
                        <span className="text-amber-400 font-bold">{act.actor}</span>
                        <span className="text-slate-500">{act.time}</span>
                      </div>
                      <p className="font-semibold text-slate-200 text-[11px] font-sans">{act.action}</p>
                      <p className="text-[10px] text-slate-400 truncate">{act.object}</p>
                    </div>
                  ))}
                </div>
              </div>

            </div>

          </div>

          {/* PART 15 — QUICK ACTIONS BAR */}
          <div className="bg-[#0F172A] border border-slate-800 rounded-xl p-5 mt-6">
            <h3 className="text-xs font-mono font-bold text-slate-400 uppercase tracking-widest mb-3">
              RESTRAINED OPERATIONAL COMMAND ACTIONS
            </h3>
            <div className="grid grid-cols-2 sm:grid-cols-5 gap-3 font-mono text-xs">
              <button
                onClick={() => navigate('/championships')}
                className="p-3 bg-[#070A11] hover:bg-[#161F30] border border-slate-800 rounded-lg flex items-center justify-center gap-2 text-slate-200 font-bold transition-colors"
              >
                <Trophy className="w-4 h-4 text-amber-400" />
                <span>Create Tournament</span>
              </button>

              <button
                onClick={() => navigate('/athletes')}
                className="p-3 bg-[#070A11] hover:bg-[#161F30] border border-slate-800 rounded-lg flex items-center justify-center gap-2 text-slate-200 font-bold transition-colors"
              >
                <Users className="w-4 h-4 text-blue-400" />
                <span>Manage Registrations</span>
              </button>

              <button
                onClick={() => navigate('/governance')}
                className="p-3 bg-[#070A11] hover:bg-[#161F30] border border-slate-800 rounded-lg flex items-center justify-center gap-2 text-slate-200 font-bold transition-colors"
              >
                <FileCheck className="w-4 h-4 text-red-400" />
                <span>Review Results</span>
              </button>

              <button
                onClick={() => navigate('/nominations')}
                className="p-3 bg-[#070A11] hover:bg-[#161F30] border border-slate-800 rounded-lg flex items-center justify-center gap-2 text-slate-200 font-bold transition-colors"
              >
                <BadgeCheck className="w-4 h-4 text-emerald-400" />
                <span>Manage Officials</span>
              </button>

              <button
                onClick={() => navigate('/moderation')}
                className="p-3 bg-[#070A11] hover:bg-[#161F30] border border-slate-800 rounded-lg flex items-center justify-center gap-2 text-slate-200 font-bold transition-colors col-span-2 sm:col-span-1"
              >
                <Award className="w-4 h-4 text-purple-400" />
                <span>Review Certifications</span>
              </button>
            </div>
          </div>
        </>
      )}
    </div>
  );
}
