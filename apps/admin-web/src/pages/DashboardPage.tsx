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
      <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 border-b border-[rgba(214,220,227,0.12)] pb-6">
        <div>
          <div className="flex items-center gap-3">
            <h1 className="text-2xl md:text-3xl font-display font-black text-slate-100 tracking-tight uppercase">
              ARMSPHERE OPERATIONS CENTER
            </h1>
            <span className="px-2.5 py-0.5 rounded text-[11px] font-mono font-bold bg-[#D4AF37]/10 text-[#D4AF37] border border-[#D4AF37]/30 uppercase tracking-wider shadow-[0_0_10px_rgba(212,175,55,0.15)]">
              {getRoleLabel(user?.role)}
            </span>
          </div>
          <p className="text-slate-400 text-xs md:text-sm mt-1 flex items-center gap-2 font-sans">
            <span>Federation Control Plane</span>
            <span className="text-slate-700">•</span>
            <span className="font-mono text-[#D4AF37] font-semibold">Live Platform Telemetry</span>
          </p>
        </div>

        <div className="flex items-center gap-3 shrink-0">
          {/* Connection Indicator */}
          <div className="flex items-center gap-2 px-3 py-1.5 bg-[#151B24] border border-[rgba(214,220,227,0.14)] rounded-lg text-xs font-mono shadow-sm">
            <span
              className={`w-2 h-2 rounded-full ${
                syncState === 'Connected'
                  ? 'bg-emerald-500 animate-pulse'
                  : syncState === 'Synchronizing'
                  ? 'bg-[#D4AF37] animate-ping'
                  : 'bg-red-500'
              }`}
            />
            <span className="text-slate-400">API:</span>
            <span className={syncState === 'Connected' ? 'text-emerald-400 font-bold' : syncState === 'Synchronizing' ? 'text-[#D4AF37] font-bold' : 'text-red-400 font-bold'}>
              {syncState}
            </span>
          </div>

          {/* Refresh Action */}
          <button
            onClick={handleRefresh}
            disabled={isFetchingStats || isSyncing}
            className="flex items-center gap-2 px-3.5 py-1.5 bg-[#151B24] hover:bg-[#1A2330] border border-[rgba(214,220,227,0.16)] rounded-lg text-xs text-slate-200 font-mono font-semibold transition-colors disabled:opacity-50"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${isFetchingStats || isSyncing ? 'animate-spin text-[#D4AF37]' : 'text-slate-400'}`} />
            <span>SYNC DATA</span>
          </button>
        </div>
      </div>

      {/* ERROR BAR — failures are surfaced, never masked with placeholder data */}
      {isErrorStats && (
        <div className="bg-[#E23B3B]/10 border border-[#E23B3B]/30 rounded-xl p-4 text-slate-200 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div className="flex items-start gap-3">
            <AlertTriangle className="w-5 h-5 text-[#E23B3B] shrink-0 mt-0.5" />
            <div>
              <h3 className="text-sm font-display font-bold text-red-200">OPERATIONS DATA UNAVAILABLE</h3>
              <p className="text-xs text-slate-400 font-mono mt-0.5">
                Dashboard metrics could not be loaded from the API. No figures are displayed until the connection is restored.
              </p>
            </div>
          </div>
          <button
            onClick={() => refetchStats()}
            className="px-4 py-2 bg-[#E23B3B]/20 hover:bg-[#E23B3B]/30 text-red-200 border border-[#E23B3B]/40 rounded-lg text-xs font-mono font-bold transition-colors shrink-0"
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
              <div key={i} className="h-20 bg-[#151B24] border border-[rgba(214,220,227,0.10)] rounded-xl" />
            ))}
          </div>
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <div className="h-56 bg-[#151B24] border border-[rgba(214,220,227,0.10)] rounded-xl" />
            <div className="h-56 bg-[#151B24] border border-[rgba(214,220,227,0.10)] rounded-xl" />
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
                className="group p-3.5 titanium-card rounded-xl border border-[rgba(214,220,227,0.12)] hover:border-[rgba(214,220,227,0.25)] flex flex-col justify-between text-left transition-all"
              >
                <div className="flex items-center justify-between">
                  <span className="text-[10px] text-slate-400 font-bold uppercase tracking-wider font-mono">{tile.label}</span>
                  <tile.icon className={`w-3.5 h-3.5 ${tile.tone} opacity-80`} />
                </div>
                <div className="mt-2 flex items-baseline justify-between">
                  <span className="text-2xl font-bold text-slate-100 font-display">{tile.value.toLocaleString()}</span>
                  <ArrowUpRight className="w-3 h-3 text-slate-600 group-hover:text-[#D4AF37] transition-colors" />
                </div>
              </button>
            ))}
          </div>

          {/* TWO-COLUMN OPERATIONS GRID */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">

            {/* MATCH OPERATIONS — matchStats */}
            <div className="titanium-panel rounded-xl p-5 flex flex-col justify-between">
              <div>
                <div className="flex items-center justify-between pb-3 border-b border-[rgba(214,220,227,0.10)]">
                  <div className="flex items-center gap-2.5">
                    <Swords className="w-4 h-4 text-[#D4AF37]" />
                    <h3 className="text-sm font-display font-bold text-slate-100 uppercase tracking-wide">MATCH OPERATIONS</h3>
                  </div>
                  <button onClick={() => navigate('/governance')} className="text-xs font-mono text-[#D4AF37] font-bold hover:underline">
                    GOVERNANCE →
                  </button>
                </div>

                <div className="mt-4 grid grid-cols-2 gap-2 text-center font-mono text-xs">
                  <div className="p-2.5 recessed-graphite rounded-lg">
                    <span className="text-[10px] text-slate-500 uppercase">Completed</span>
                    <p className="text-base font-bold text-emerald-400 mt-0.5">{stats.matchStats.completed}</p>
                  </div>
                  <div className="p-2.5 recessed-graphite rounded-lg">
                    <span className="text-[10px] text-slate-500 uppercase">Pending Results</span>
                    <p className="text-base font-bold text-[#D4AF37] mt-0.5">{stats.matchStats.pending}</p>
                  </div>
                  <div className="p-2.5 recessed-graphite rounded-lg">
                    <span className="text-[10px] text-slate-500 uppercase">Disputed</span>
                    <p className="text-base font-bold text-[#E23B3B] mt-0.5">{stats.matchStats.disputed}</p>
                  </div>
                  <div className="p-2.5 recessed-graphite rounded-lg">
                    <span className="text-[10px] text-slate-500 uppercase">Total Recorded</span>
                    <p className="text-base font-bold text-slate-100 mt-0.5">{stats.matchStats.total}</p>
                  </div>
                </div>
              </div>

              <div className="mt-4 pt-3 border-t border-[rgba(214,220,227,0.10)] font-mono text-[11px] flex items-center justify-between text-slate-400">
                <span>Total matches registered platform-wide:</span>
                <strong className="text-slate-200">{stats.kpis.totalMatches.toLocaleString()}</strong>
              </div>
            </div>

            {/* DISPUTE CONTROL — disputeStats + live open queue preview */}
            <div className="titanium-panel rounded-xl p-5">
              <div className="flex items-center justify-between pb-3 border-b border-[rgba(214,220,227,0.10)]">
                <div className="flex items-center gap-2.5">
                  <ShieldAlert className="w-4 h-4 text-[#E23B3B]" />
                  <h3 className="text-sm font-display font-bold text-slate-100 uppercase tracking-wide">DISPUTE CONTROL</h3>
                </div>
                <span className="px-2 py-0.5 bg-[#E23B3B]/10 text-[#E23B3B] border border-[#E23B3B]/20 rounded text-[10px] font-mono font-bold uppercase shadow-[0_0_8px_rgba(226,59,59,0.15)]">
                  {stats.disputeStats.open} Open
                </span>
              </div>

              <div className="mt-4 grid grid-cols-2 sm:grid-cols-4 gap-2 text-center font-mono text-xs mb-4">
                <div className="p-2.5 recessed-graphite rounded-lg">
                  <span className="text-[10px] text-slate-500 uppercase">Resolved</span>
                  <p className="text-base font-bold text-emerald-400 mt-0.5">{stats.disputeStats.resolved}</p>
                </div>
                <div className="p-2.5 recessed-graphite rounded-lg">
                  <span className="text-[10px] text-slate-500 uppercase">Escalated</span>
                  <p className="text-base font-bold text-[#D4AF37] mt-0.5">{stats.disputeStats.escalated}</p>
                </div>
                <div className="p-2.5 recessed-graphite rounded-lg">
                  <span className="text-[10px] text-slate-500 uppercase">Appealed</span>
                  <p className="text-base font-bold text-purple-400 mt-0.5">{stats.disputeStats.appealed}</p>
                </div>
                <div className="p-2.5 recessed-graphite rounded-lg">
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
                  <div className="p-3 recessed-graphite rounded-lg text-xs font-mono text-slate-500 animate-pulse">
                    Loading dispute queue…
                  </div>
                )}
                {isErrorDisputes && (
                  <div className="p-3 bg-[#E23B3B]/10 border border-[#E23B3B]/30 rounded-lg text-xs font-mono text-red-300">
                    Dispute queue unavailable: {disputesError instanceof Error ? disputesError.message : 'request failed.'}
                  </div>
                )}
                {!isLoadingDisputes && !isErrorDisputes && openDisputes.length === 0 && (
                  <div className="p-3 recessed-graphite rounded-lg text-xs font-mono text-slate-500">
                    No active disputes awaiting review.
                  </div>
                )}
                {openDisputes.map((dispute) => (
                  <button
                    key={dispute.id}
                    onClick={() => navigate('/governance')}
                    className="w-full p-3 recessed-graphite hover:border-[rgba(214,220,227,0.25)] rounded-lg flex items-center justify-between gap-3 text-left transition-colors group"
                  >
                    <div className="min-w-0">
                      <p className="text-xs font-semibold text-slate-200 truncate">{dispute.title}</p>
                      <p className="text-[10px] text-slate-500 font-mono mt-0.5 truncate">
                        #{dispute.id.slice(0, 8)} • Updated {new Date(dispute.updatedAt).toLocaleDateString()}
                      </p>
                    </div>
                    <div className="flex items-center gap-2 shrink-0">
                      <span className="px-2 py-0.5 bg-[#D4AF37]/10 text-[#D4AF37] border border-[#D4AF37]/20 rounded text-[9px] font-mono font-bold uppercase">
                        {dispute.status.replace(/_/g, ' ')}
                      </span>
                      <ArrowUpRight className="w-3.5 h-3.5 text-slate-600 group-hover:text-[#D4AF37] transition-colors" />
                    </div>
                  </button>
                ))}
                <button
                  onClick={() => navigate('/governance')}
                  className="w-full py-2 bg-[#1A2330] hover:bg-[#202832] text-slate-200 border border-[rgba(214,220,227,0.12)] rounded-lg text-xs font-mono font-bold transition-colors"
                >
                  Open Dispute Review Console
                </button>
              </div>
            </div>

            {/* ELO HEALTH — eloHealth */}
            <div className="titanium-panel rounded-xl p-5 flex flex-col justify-between">
              <div>
                <div className="flex items-center justify-between pb-3 border-b border-[rgba(214,220,227,0.10)]">
                  <div className="flex items-center gap-2">
                    <TrendingUp className="w-4 h-4 text-emerald-400" />
                    <h3 className="text-sm font-display font-bold text-slate-100 uppercase tracking-wide">ELO RATING HEALTH</h3>
                  </div>
                  <button onClick={() => navigate('/analytics')} className="text-xs font-mono text-emerald-400 font-bold hover:underline">
                    ANALYTICS →
                  </button>
                </div>

                <div className="mt-4 grid grid-cols-3 gap-2 text-center font-mono text-xs">
                  <div className="p-2.5 recessed-graphite rounded-lg">
                    <span className="text-[10px] text-slate-500 uppercase">Average</span>
                    <p className="text-base font-bold text-emerald-400 mt-0.5">{Math.round(stats.eloHealth.average)}</p>
                  </div>
                  <div className="p-2.5 recessed-graphite rounded-lg">
                    <span className="text-[10px] text-slate-500 uppercase">Minimum</span>
                    <p className="text-base font-bold text-[#D4AF37] mt-0.5">{Math.round(stats.eloHealth.min)}</p>
                  </div>
                  <div className="p-2.5 recessed-graphite rounded-lg">
                    <span className="text-[10px] text-slate-500 uppercase">Maximum</span>
                    <p className="text-base font-bold text-slate-100 mt-0.5">{Math.round(stats.eloHealth.max)}</p>
                  </div>
                </div>
              </div>

              <p className="mt-4 pt-3 border-t border-[rgba(214,220,227,0.10)] font-mono text-[11px] text-slate-400">
                Distribution across all nationally rated athletes.
              </p>
            </div>

            {/* SYSTEM STATUS — systemStatus as returned by the API, linked to audit ledger */}
            <div className="titanium-panel rounded-xl p-5 flex flex-col justify-between">
              <div>
                <div className="flex items-center justify-between pb-3 border-b border-[rgba(214,220,227,0.10)]">
                  <div className="flex items-center gap-2">
                    <Server className="w-4 h-4 text-[#38BDF8]" />
                    <h3 className="text-sm font-display font-bold text-slate-100 uppercase tracking-wide">SYSTEM STATUS</h3>
                  </div>
                  <span className="px-2 py-0.5 bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 rounded text-[10px] font-mono font-bold">
                    {stats.systemStatus.latencyMs}ms LATENCY
                  </span>
                </div>

                <div className="mt-4 space-y-2 font-mono text-xs">
                  <div className="p-3 recessed-graphite rounded-lg flex items-center justify-between">
                    <span className="text-slate-500 uppercase text-[10px]">Database</span>
                    <span className="font-bold text-slate-200 uppercase">{stats.systemStatus.database}</span>
                  </div>
                  <div className="p-3 recessed-graphite rounded-lg flex items-center justify-between">
                    <span className="text-slate-500 uppercase text-[10px]">Scheduled Jobs</span>
                    <span className="font-bold text-slate-200 uppercase">{stats.systemStatus.scheduledJobs}</span>
                  </div>
                </div>
              </div>

              <button
                onClick={() => navigate('/audit')}
                className="w-full mt-4 py-2 bg-[#1A2330] hover:bg-[#202832] text-slate-200 border border-[rgba(214,220,227,0.12)] rounded-lg text-xs font-mono font-bold transition-colors flex items-center justify-center gap-2"
              >
                <Gavel className="w-3.5 h-3.5 text-[#D4AF37]" />
                Inspect Immutable Audit Ledger
              </button>
            </div>

          </div>

          {/* VERIFICATION BACKLOG CALLOUT — real backlog figure with direct action */}
          {stats.verificationBacklog > 0 && (
            <button
              onClick={() => navigate('/athletes')}
              className="w-full bg-[#D4AF37]/10 border border-[#D4AF37]/30 hover:border-[#D4AF37]/50 rounded-xl p-4 flex flex-col sm:flex-row sm:items-center justify-between gap-3 transition-colors text-left group shadow-[0_0_16px_rgba(212,175,55,0.1)]"
            >
              <div className="flex items-start gap-3">
                <FileCheck className="w-5 h-5 text-[#D4AF37] shrink-0 mt-0.5" />
                <div>
                  <h3 className="text-sm font-bold text-amber-200">
                    {stats.verificationBacklog} athlete profile{stats.verificationBacklog > 1 ? 's' : ''} awaiting verification review
                  </h3>
                  <p className="text-xs text-slate-400 font-mono mt-0.5">
                    Pending national identity checks block competition eligibility until resolved.
                  </p>
                </div>
              </div>
              <span className="px-4 py-2 bg-[#D4AF37] hover:bg-[#e6c148] text-slate-950 font-bold text-xs rounded-lg font-mono shrink-0 flex items-center justify-center gap-2">
                Review Queue
                <ArrowUpRight className="w-3.5 h-3.5" />
              </span>
            </button>
          )}

          {/* QUICK ACTIONS — pure navigation, no implied side effects */}
          <div className="titanium-panel rounded-xl p-5">
            <h3 className="text-xs font-mono font-bold text-slate-400 uppercase tracking-widest mb-3">
              QUICK NAVIGATION
            </h3>
            <div className="grid grid-cols-2 sm:grid-cols-5 gap-3 font-mono text-xs">
              <button
                onClick={() => navigate('/athletes')}
                className="p-3 recessed-graphite hover:bg-[#1A2330] rounded-lg flex items-center justify-center gap-2 text-slate-200 font-bold transition-colors"
              >
                <Users className="w-4 h-4 text-[#38BDF8]" />
                <span>Athlete Registry</span>
              </button>

              <button
                onClick={() => navigate('/championships')}
                className="p-3 recessed-graphite hover:bg-[#1A2330] rounded-lg flex items-center justify-center gap-2 text-slate-200 font-bold transition-colors"
              >
                <Trophy className="w-4 h-4 text-[#D4AF37]" />
                <span>Championship Titles</span>
              </button>

              <button
                onClick={() => navigate('/governance')}
                className="p-3 recessed-graphite hover:bg-[#1A2330] rounded-lg flex items-center justify-center gap-2 text-slate-200 font-bold transition-colors"
              >
                <ShieldAlert className="w-4 h-4 text-[#E23B3B]" />
                <span>Dispute Review</span>
              </button>

              <button
                onClick={() => navigate('/moderation')}
                className="p-3 recessed-graphite hover:bg-[#1A2330] rounded-lg flex items-center justify-center gap-2 text-slate-200 font-bold transition-colors"
              >
                <FileCheck className="w-4 h-4 text-purple-400" />
                <span>Community Moderation</span>
              </button>

              <button
                onClick={() => navigate('/audit')}
                className="p-3 recessed-graphite hover:bg-[#1A2330] rounded-lg flex items-center justify-center gap-2 text-slate-200 font-bold transition-colors"
              >
                <Gavel className="w-4 h-4 text-[#10B981]" />
                <span>Audit Ledger</span>
              </button>
            </div>
          </div>
        </>
      )}
    </div>
  );
}
