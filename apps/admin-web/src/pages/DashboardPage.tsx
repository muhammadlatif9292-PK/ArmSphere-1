import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQueryClient } from '@tanstack/react-query';
import { useAuth } from '../context/AuthContext';
import { useDashboardStats } from '../lib/dashboardApi';
import { useDisputes } from '../lib/governanceApi';
import {
  Users,
  BadgeCheck,
  Trophy,
  Swords,
  FileCheck,
  RefreshCw,
  AlertTriangle,
  ShieldAlert,
  TrendingUp,
  Server,
  ArrowUpRight,
  Gavel
} from 'lucide-react';

const ACTIVE_DISPUTE_STATUSES = ['OPEN', 'UNDER_REVIEW', 'AWAITING_EVIDENCE', 'ESCALATED'];

export default function DashboardPage() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [isSyncing, setIsSyncing] = useState(false);

  // Real backend queries — every number rendered below comes from these payloads only.
  const {
    data: stats,
    isLoading: isLoadingStats,
    isError: isErrorStats,
    refetch: refetchStats,
    isFetching: isFetchingStats
  } = useDashboardStats();

  const {
    data: disputes,
    isLoading: isLoadingDisputes,
    isError: isErrorDisputes,
    error: disputesError
  } = useDisputes();

  const handleRefresh = async () => {
    setIsSyncing(true);
    await queryClient.invalidateQueries({ queryKey: ['admin'] });
    await refetchStats();
    setIsSyncing(false);
  };

  const getRoleLabel = (role?: string) => {
    if (!role) return 'Unknown Role';
    return role.replace(/_/g, ' ');
  };

  // Sync state text
  const syncState = isErrorStats
    ? 'Unavailable'
    : (isFetchingStats || isSyncing)
    ? 'Synchronizing'
    : 'Connected';

  const openDisputes = (disputes ?? [])
    .filter((d) => ACTIVE_DISPUTE_STATUSES.includes(d.status))
    .sort((a, b) => new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime())
    .slice(0, 4);

  const kpiTiles = stats
    ? [
        { label: 'Registered Athletes', value: stats.kpis.totalAthletes, route: '/athletes', icon: Users, tone: 'text-blue-400' },
        { label: 'Certified Officials', value: stats.kpis.totalReferees, route: '/nominations', icon: BadgeCheck, tone: 'text-emerald-400' },
        { label: 'Sanctioned Events', value: stats.kpis.totalEvents, route: '/championships', icon: Trophy, tone: 'text-amber-400' },
        { label: 'Total Matches', value: stats.kpis.totalMatches, route: '/governance', icon: Swords, tone: 'text-slate-100' },
        { label: 'Active Championships', value: stats.kpis.activeChampionships, route: '/championships', icon: Trophy, tone: 'text-purple-400' },
        { label: 'Verification Backlog', value: stats.verificationBacklog, route: '/athletes', icon: FileCheck, tone: 'text-red-400' }
      ]
    : [];

  return (
    <div className="space-y-6">
      {/* EXECUTIVE HEADER */}
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
            <span>Federation Control Plane</span>
            <span className="text-slate-700">•</span>
            <span className="font-mono text-amber-400/90 font-semibold">Live Platform Metrics</span>
          </p>
        </div>

        <div className="flex items-center gap-3 shrink-0">
          {/* Connection Indicator */}
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
            <span className="text-slate-400">API:</span>
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

      {/* ERROR BAR — failures are surfaced, never masked with placeholder data */}
      {isErrorStats && (
        <div className="bg-red-500/10 border border-red-500/30 rounded-xl p-4 text-slate-200 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div className="flex items-start gap-3">
            <AlertTriangle className="w-5 h-5 text-red-400 shrink-0 mt-0.5" />
            <div>
              <h3 className="text-sm font-bold text-red-200">OPERATIONS DATA UNAVAILABLE</h3>
              <p className="text-xs text-slate-400 font-mono mt-0.5">
                Dashboard metrics could not be loaded from the API. No figures are displayed until the connection is restored.
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

      {/* LOADING SKELETON */}
      {isLoadingStats && !isErrorStats && (
        <div className="space-y-6 animate-pulse">
          <div className="grid grid-cols-2 lg:grid-cols-6 gap-3">
            {[1, 2, 3, 4, 5, 6].map((i) => (
              <div key={i} className="h-20 bg-[#0F172A] border border-slate-800 rounded-xl" />
            ))}
          </div>
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <div className="h-56 bg-[#0F172A] border border-slate-800 rounded-xl" />
            <div className="h-56 bg-[#0F172A] border border-slate-800 rounded-xl" />
          </div>
        </div>
      )}

      {/* MAIN CONTENT — renders only when real stats are in hand */}
      {!isLoadingStats && stats && (
        <>
          {/* KPI STRIP — driven exclusively by stats payload fields */}
          <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3">
            {kpiTiles.map((tile) => (
              <button
                key={tile.label}
                onClick={() => navigate(tile.route)}
                className="group p-3.5 bg-[#0F172A] border border-slate-800/90 hover:border-slate-700 rounded-xl flex flex-col justify-between text-left transition-colors"
              >
                <div className="flex items-center justify-between">
                  <span className="text-[10px] text-slate-400 font-bold uppercase tracking-wider font-mono">{tile.label}</span>
                  <tile.icon className={`w-3.5 h-3.5 ${tile.tone} opacity-70`} />
                </div>
                <div className="mt-2 flex items-baseline justify-between">
                  <span className="text-2xl font-bold text-slate-100 font-display">{tile.value.toLocaleString()}</span>
                  <ArrowUpRight className="w-3 h-3 text-slate-600 group-hover:text-amber-400 transition-colors" />
                </div>
              </button>
            ))}
          </div>

          {/* TWO-COLUMN OPERATIONS GRID */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">

            {/* MATCH OPERATIONS — matchStats */}
            <div className="bg-[#0F172A] border border-slate-800 rounded-xl p-5 flex flex-col justify-between">
              <div>
                <div className="flex items-center justify-between pb-3 border-b border-slate-800">
                  <div className="flex items-center gap-2.5">
                    <Swords className="w-4 h-4 text-amber-400" />
                    <h3 className="text-sm font-display font-bold text-slate-100 uppercase tracking-wide">MATCH OPERATIONS</h3>
                  </div>
                  <button onClick={() => navigate('/governance')} className="text-xs font-mono text-amber-400 font-bold hover:underline">
                    GOVERNANCE →
                  </button>
                </div>

                <div className="mt-4 grid grid-cols-2 gap-2 text-center font-mono text-xs">
                  <div className="p-2.5 bg-[#070A11] border border-slate-800 rounded-lg">
                    <span className="text-[10px] text-slate-500 uppercase">Completed</span>
                    <p className="text-base font-bold text-emerald-400 mt-0.5">{stats.matchStats.completed}</p>
                  </div>
                  <div className="p-2.5 bg-[#070A11] border border-slate-800 rounded-lg">
                    <span className="text-[10px] text-slate-500 uppercase">Pending Results</span>
                    <p className="text-base font-bold text-amber-400 mt-0.5">{stats.matchStats.pending}</p>
                  </div>
                  <div className="p-2.5 bg-[#070A11] border border-slate-800 rounded-lg">
                    <span className="text-[10px] text-slate-500 uppercase">Disputed</span>
                    <p className="text-base font-bold text-red-400 mt-0.5">{stats.matchStats.disputed}</p>
                  </div>
                  <div className="p-2.5 bg-[#070A11] border border-slate-800 rounded-lg">
                    <span className="text-[10px] text-slate-500 uppercase">Total Recorded</span>
                    <p className="text-base font-bold text-slate-100 mt-0.5">{stats.matchStats.total}</p>
                  </div>
                </div>
              </div>

              <div className="mt-4 pt-3 border-t border-slate-800/80 font-mono text-[11px] flex items-center justify-between text-slate-400">
                <span>Total matches registered platform-wide:</span>
                <strong className="text-slate-200">{stats.kpis.totalMatches.toLocaleString()}</strong>
              </div>
            </div>

            {/* DISPUTE CONTROL — disputeStats + live open queue preview */}
            <div className="bg-[#0F172A] border border-slate-800 rounded-xl p-5">
              <div className="flex items-center justify-between pb-3 border-b border-slate-800">
                <div className="flex items-center gap-2.5">
                  <ShieldAlert className="w-4 h-4 text-red-400" />
                  <h3 className="text-sm font-display font-bold text-slate-100 uppercase tracking-wide">DISPUTE CONTROL</h3>
                </div>
                <span className="px-2 py-0.5 bg-red-500/10 text-red-400 border border-red-500/20 rounded text-[10px] font-mono font-bold uppercase">
                  {stats.disputeStats.open} Open
                </span>
              </div>

              <div className="mt-4 grid grid-cols-2 sm:grid-cols-4 gap-2 text-center font-mono text-xs mb-4">
                <div className="p-2.5 bg-[#070A11] border border-slate-800 rounded-lg">
                  <span className="text-[10px] text-slate-500 uppercase">Resolved</span>
                  <p className="text-base font-bold text-emerald-400 mt-0.5">{stats.disputeStats.resolved}</p>
                </div>
                <div className="p-2.5 bg-[#070A11] border border-slate-800 rounded-lg">
                  <span className="text-[10px] text-slate-500 uppercase">Escalated</span>
                  <p className="text-base font-bold text-amber-400 mt-0.5">{stats.disputeStats.escalated}</p>
                </div>
                <div className="p-2.5 bg-[#070A11] border border-slate-800 rounded-lg">
                  <span className="text-[10px] text-slate-500 uppercase">Appealed</span>
                  <p className="text-base font-bold text-purple-400 mt-0.5">{stats.disputeStats.appealed}</p>
                </div>
                <div className="p-2.5 bg-[#070A11] border border-slate-800 rounded-lg">
                  <span className="text-[10px] text-slate-500 uppercase">Lifetime Total</span>
                  <p className="text-base font-bold text-slate-100 mt-0.5">{stats.disputeStats.total}</p>
                </div>
              </div>

              {/* Open dispute queue preview — real records from GET /admin/disputes */}
              <div className="space-y-2">
                <h4 className="text-[10px] font-mono font-bold text-slate-400 uppercase tracking-widest">
                  Active Queue Preview
                </h4>
                {isLoadingDisputes && (
                  <div className="p-3 bg-[#070A11] border border-slate-800 rounded-lg text-xs font-mono text-slate-500 animate-pulse">
                    Loading dispute queue…
                  </div>
                )}
                {isErrorDisputes && (
                  <div className="p-3 bg-red-500/10 border border-red-500/30 rounded-lg text-xs font-mono text-red-300">
                    Dispute queue unavailable: {disputesError instanceof Error ? disputesError.message : 'request failed.'}
                  </div>
                )}
                {!isLoadingDisputes && !isErrorDisputes && openDisputes.length === 0 && (
                  <div className="p-3 bg-[#070A11] border border-slate-800 rounded-lg text-xs font-mono text-slate-500">
                    No active disputes awaiting review.
                  </div>
                )}
                {openDisputes.map((dispute) => (
                  <button
                    key={dispute.id}
                    onClick={() => navigate('/governance')}
                    className="w-full p-3 bg-[#070A11] border border-slate-800 hover:border-slate-700 rounded-lg flex items-center justify-between gap-3 text-left transition-colors group"
                  >
                    <div className="min-w-0">
                      <p className="text-xs font-semibold text-slate-200 truncate">{dispute.title}</p>
                      <p className="text-[10px] text-slate-500 font-mono mt-0.5 truncate">
                        #{dispute.id.slice(0, 8)} • Updated {new Date(dispute.updatedAt).toLocaleDateString()}
                      </p>
                    </div>
                    <div className="flex items-center gap-2 shrink-0">
                      <span className="px-2 py-0.5 bg-amber-500/10 text-amber-400 border border-amber-500/20 rounded text-[9px] font-mono font-bold uppercase">
                        {dispute.status.replace(/_/g, ' ')}
                      </span>
                      <ArrowUpRight className="w-3.5 h-3.5 text-slate-600 group-hover:text-amber-400 transition-colors" />
                    </div>
                  </button>
                ))}
                <button
                  onClick={() => navigate('/governance')}
                  className="w-full py-2 bg-[#161F30] hover:bg-slate-800 text-slate-200 border border-slate-700 rounded-lg text-xs font-mono font-bold transition-colors"
                >
                  Open Dispute Review Console
                </button>
              </div>
            </div>

            {/* ELO HEALTH — eloHealth */}
            <div className="bg-[#0F172A] border border-slate-800 rounded-xl p-5 flex flex-col justify-between">
              <div>
                <div className="flex items-center justify-between pb-3 border-b border-slate-800">
                  <div className="flex items-center gap-2">
                    <TrendingUp className="w-4 h-4 text-emerald-400" />
                    <h3 className="text-sm font-display font-bold text-slate-100 uppercase tracking-wide">ELO RATING HEALTH</h3>
                  </div>
                  <button onClick={() => navigate('/analytics')} className="text-xs font-mono text-emerald-400 font-bold hover:underline">
                    ANALYTICS →
                  </button>
                </div>

                <div className="mt-4 grid grid-cols-3 gap-2 text-center font-mono text-xs">
                  <div className="p-2.5 bg-[#070A11] border border-slate-800 rounded-lg">
                    <span className="text-[10px] text-slate-500 uppercase">Average</span>
                    <p className="text-base font-bold text-emerald-400 mt-0.5">{Math.round(stats.eloHealth.average)}</p>
                  </div>
                  <div className="p-2.5 bg-[#070A11] border border-slate-800 rounded-lg">
                    <span className="text-[10px] text-slate-500 uppercase">Minimum</span>
                    <p className="text-base font-bold text-amber-400 mt-0.5">{Math.round(stats.eloHealth.min)}</p>
                  </div>
                  <div className="p-2.5 bg-[#070A11] border border-slate-800 rounded-lg">
                    <span className="text-[10px] text-slate-500 uppercase">Maximum</span>
                    <p className="text-base font-bold text-slate-100 mt-0.5">{Math.round(stats.eloHealth.max)}</p>
                  </div>
                </div>
              </div>

              <p className="mt-4 pt-3 border-t border-slate-800/80 font-mono text-[11px] text-slate-400">
                Distribution across all nationally rated athletes.
              </p>
            </div>

            {/* SYSTEM STATUS — systemStatus as returned by the API, linked to audit ledger */}
            <div className="bg-[#0F172A] border border-slate-800 rounded-xl p-5 flex flex-col justify-between">
              <div>
                <div className="flex items-center justify-between pb-3 border-b border-slate-800">
                  <div className="flex items-center gap-2">
                    <Server className="w-4 h-4 text-blue-400" />
                    <h3 className="text-sm font-display font-bold text-slate-100 uppercase tracking-wide">SYSTEM STATUS</h3>
                  </div>
                  <span className="px-2 py-0.5 bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 rounded text-[10px] font-mono font-bold">
                    {stats.systemStatus.latencyMs}ms LATENCY
                  </span>
                </div>

                <div className="mt-4 space-y-2 font-mono text-xs">
                  <div className="p-3 bg-[#070A11] border border-slate-800 rounded-lg flex items-center justify-between">
                    <span className="text-slate-500 uppercase text-[10px]">Database</span>
                    <span className="font-bold text-slate-200 uppercase">{stats.systemStatus.database}</span>
                  </div>
                  <div className="p-3 bg-[#070A11] border border-slate-800 rounded-lg flex items-center justify-between">
                    <span className="text-slate-500 uppercase text-[10px]">Scheduled Jobs</span>
                    <span className="font-bold text-slate-200 uppercase">{stats.systemStatus.scheduledJobs}</span>
                  </div>
                </div>
              </div>

              <button
                onClick={() => navigate('/audit')}
                className="w-full mt-4 py-2 bg-[#161F30] hover:bg-slate-800 text-slate-200 border border-slate-700 rounded-lg text-xs font-mono font-bold transition-colors flex items-center justify-center gap-2"
              >
                <Gavel className="w-3.5 h-3.5 text-amber-400" />
                Inspect Immutable Audit Ledger
              </button>
            </div>

          </div>

          {/* VERIFICATION BACKLOG CALLOUT — real backlog figure with direct action */}
          {stats.verificationBacklog > 0 && (
            <button
              onClick={() => navigate('/athletes')}
              className="w-full bg-amber-500/10 border border-amber-500/30 hover:border-amber-500/50 rounded-xl p-4 flex flex-col sm:flex-row sm:items-center justify-between gap-3 transition-colors text-left group"
            >
              <div className="flex items-start gap-3">
                <FileCheck className="w-5 h-5 text-amber-400 shrink-0 mt-0.5" />
                <div>
                  <h3 className="text-sm font-bold text-amber-200">
                    {stats.verificationBacklog} athlete profile{stats.verificationBacklog > 1 ? 's' : ''} awaiting verification review
                  </h3>
                  <p className="text-xs text-slate-400 font-mono mt-0.5">
                    Pending national identity checks block competition eligibility until resolved.
                  </p>
                </div>
              </div>
              <span className="px-4 py-2 bg-amber-500 hover:bg-amber-400 text-slate-950 font-bold text-xs rounded-lg font-mono shrink-0 flex items-center justify-center gap-2">
                Review Queue
                <ArrowUpRight className="w-3.5 h-3.5" />
              </span>
            </button>
          )}

          {/* QUICK ACTIONS — pure navigation, no implied side effects */}
          <div className="bg-[#0F172A] border border-slate-800 rounded-xl p-5">
            <h3 className="text-xs font-mono font-bold text-slate-400 uppercase tracking-widest mb-3">
              QUICK NAVIGATION
            </h3>
            <div className="grid grid-cols-2 sm:grid-cols-5 gap-3 font-mono text-xs">
              <button
                onClick={() => navigate('/athletes')}
                className="p-3 bg-[#070A11] hover:bg-[#161F30] border border-slate-800 rounded-lg flex items-center justify-center gap-2 text-slate-200 font-bold transition-colors"
              >
                <Users className="w-4 h-4 text-blue-400" />
                <span>Athlete Registry</span>
              </button>

              <button
                onClick={() => navigate('/championships')}
                className="p-3 bg-[#070A11] hover:bg-[#161F30] border border-slate-800 rounded-lg flex items-center justify-center gap-2 text-slate-200 font-bold transition-colors"
              >
                <Trophy className="w-4 h-4 text-amber-400" />
                <span>Championship Titles</span>
              </button>

              <button
                onClick={() => navigate('/governance')}
                className="p-3 bg-[#070A11] hover:bg-[#161F30] border border-slate-800 rounded-lg flex items-center justify-center gap-2 text-slate-200 font-bold transition-colors"
              >
                <ShieldAlert className="w-4 h-4 text-red-400" />
                <span>Dispute Review</span>
              </button>

              <button
                onClick={() => navigate('/moderation')}
                className="p-3 bg-[#070A11] hover:bg-[#161F30] border border-slate-800 rounded-lg flex items-center justify-center gap-2 text-slate-200 font-bold transition-colors"
              >
                <FileCheck className="w-4 h-4 text-purple-400" />
                <span>Community Moderation</span>
              </button>

              <button
                onClick={() => navigate('/audit')}
                className="p-3 bg-[#070A11] hover:bg-[#161F30] border border-slate-800 rounded-lg flex items-center justify-center gap-2 text-slate-200 font-bold transition-colors"
              >
                <Gavel className="w-4 h-4 text-emerald-400" />
                <span>Audit Ledger</span>
              </button>
            </div>
          </div>
        </>
      )}
    </div>
  );
}
