import { useAnalyticsOverview, useEloDistribution } from '../lib/analyticsApi';
import { 
  BarChart3, 
  Users, 
  Trophy, 
  AlertTriangle, 
  TrendingUp, 
  Calendar, 
  RefreshCw,
  Clock
} from 'lucide-react';
import {
  ResponsiveContainer,
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  BarChart,
  Bar,
  Legend
} from 'recharts';

interface CustomTooltipProps {
  active?: boolean;
  payload?: any[];
  label?: string;
}

const CustomTooltip = ({ active, payload, label }: CustomTooltipProps) => {
  if (active && payload && payload.length) {
    return (
      <div className="bg-[#1E293B] border border-slate-700 p-3 rounded-lg shadow-xl font-sans text-xs">
        <p className="font-semibold text-slate-300 mb-1.5">{label}</p>
        <div className="space-y-1">
          {payload.map((p: any, idx: number) => (
            <p key={idx} className="flex justify-between items-center gap-6">
              <span className="flex items-center gap-1.5 text-slate-400">
                <span className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor: p.color || p.fill }}></span>
                {p.name}:
              </span>
              <span className="font-mono font-bold text-slate-100">{p.value}</span>
            </p>
          ))}
        </div>
      </div>
    );
  }
  return null;
};

export default function AnalyticsPage() {
  const { 
    data: overview, 
    isLoading: isOverviewLoading, 
    isError: isOverviewError, 
    error: overviewError,
    refetch: refetchOverview 
  } = useAnalyticsOverview();

  const { 
    data: distribution, 
    isLoading: isDistributionLoading, 
    isError: isDistributionError, 
    error: distributionError,
    refetch: refetchDistribution 
  } = useEloDistribution();

  const handleRetry = () => {
    refetchOverview();
    refetchDistribution();
  };

  const isLoading = isOverviewLoading || isDistributionLoading;
  const isError = isOverviewError || isDistributionError;
  const errorMessage = (overviewError as any)?.message || (distributionError as any)?.message || "Failed to load telemetry data.";

  const formattedDate = new Date().toLocaleDateString('en-US', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  });

  // Skeletal loaders for KPI summary cards
  if (isLoading) {
    return (
      <div className="space-y-8 animate-pulse">
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 border-b border-slate-800 pb-6">
          <div className="space-y-2">
            <div className="h-8 w-64 bg-slate-800 rounded-md"></div>
            <div className="h-4 w-96 bg-slate-800 rounded-md"></div>
          </div>
          <div className="h-10 w-44 bg-slate-800 rounded-lg"></div>
        </div>

        {/* KPI Skeleton Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {[1, 2, 3, 4].map((i) => (
            <div key={i} className="bg-[#1E293B] border border-slate-800 rounded-xl p-6 h-32 flex flex-col justify-between">
              <div className="flex justify-between">
                <div className="h-4 w-24 bg-slate-800 rounded"></div>
                <div className="h-8 w-8 bg-slate-800 rounded-full"></div>
              </div>
              <div className="h-8 w-16 bg-slate-800 rounded mt-4"></div>
            </div>
          ))}
        </div>

        {/* Charts Skeleton Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          <div className="bg-[#1E293B] border border-slate-800 rounded-xl p-6 h-96 flex flex-col justify-between">
            <div className="h-5 w-48 bg-slate-800 rounded"></div>
            <div className="h-64 w-full bg-slate-800 rounded-lg mt-4"></div>
          </div>
          <div className="bg-[#1E293B] border border-slate-800 rounded-xl p-6 h-96 flex flex-col justify-between">
            <div className="h-5 w-48 bg-slate-800 rounded"></div>
            <div className="h-64 w-full bg-slate-800 rounded-lg mt-4"></div>
          </div>
        </div>
      </div>
    );
  }

  // Error state display
  if (isError) {
    return (
      <div className="space-y-8">
        <div className="border-b border-slate-800 pb-6">
          <h2 className="text-3xl font-display font-bold text-slate-100">Analytics Hub</h2>
          <p className="text-slate-400 text-sm mt-1">Ecosystem intelligence feeds and ELO distributions.</p>
        </div>

        <div className="bg-red-500/10 border border-red-500/20 rounded-xl p-8 max-w-2xl mx-auto text-center space-y-4">
          <div className="inline-flex items-center justify-center w-14 h-14 rounded-full bg-red-500/10 text-red-400 border border-red-500/20">
            <AlertTriangle className="w-7 h-7" />
          </div>
          <h3 className="text-lg font-semibold text-slate-200">Telemetry Connection Failure</h3>
          <p className="text-slate-400 text-sm max-w-md mx-auto leading-relaxed">
            {errorMessage}
          </p>
          <button
            onClick={handleRetry}
            className="inline-flex items-center gap-2 px-5 py-2.5 bg-slate-800 hover:bg-slate-700 border border-slate-700 hover:border-slate-600 text-slate-200 text-sm font-medium rounded-lg transition-colors"
          >
            <RefreshCw className="w-4 h-4" />
            Retry Telemetry Fetch
          </button>
        </div>
      </div>
    );
  }

  const hasNoVolumeData = !overview || !overview.matchVolumeOverTime || overview.matchVolumeOverTime.length === 0;
  const hasNoDistributionData = !distribution || distribution.length === 0;

  // Render dashboard overview when data loaded successfully
  return (
    <div className="space-y-8">
      {/* Upper header summary bar */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 border-b border-slate-800 pb-6">
        <div>
          <h2 className="text-3xl font-display font-bold text-slate-100">Analytics Hub</h2>
          <p className="text-slate-400 text-sm mt-1">Federation ecosystem insights, match metrics, and competitor rating analytics.</p>
        </div>
        
        <div className="flex items-center gap-4">
          <button 
            onClick={handleRetry}
            className="p-2 bg-slate-800 hover:bg-slate-700 border border-slate-700 text-slate-300 rounded-lg transition-colors flex items-center justify-center"
            title="Refresh statistics"
          >
            <RefreshCw className="w-4 h-4" />
          </button>
          <div className="flex items-center gap-2 px-4 py-2 bg-[#1E293B] border border-slate-800 rounded-lg text-sm text-slate-300">
            <Calendar className="w-4 h-4 text-amber-500" />
            <span>{formattedDate}</span>
          </div>
        </div>
      </div>

      {/* KPI Performance Metrics Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        
        {/* Card 1: Active Athletes */}
        <div className="bg-[#1E293B] border border-slate-800 rounded-xl p-6 shadow-lg relative overflow-hidden group">
          <div className="absolute top-0 right-0 w-24 h-24 bg-amber-500/5 rounded-full blur-2xl group-hover:bg-amber-500/10 transition-colors"></div>
          <div className="flex justify-between items-start">
            <div>
              <p className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Registered Athletes</p>
              <h3 className="text-3xl font-mono font-bold text-slate-100 mt-2">{overview?.activeAthleteCount}</h3>
            </div>
            <div className="p-2 bg-amber-500/10 text-amber-500 border border-amber-500/20 rounded-lg">
              <Users className="w-5 h-5" />
            </div>
          </div>
          <div className="flex items-center gap-1.5 mt-4 text-xs text-slate-500">
            <span className="text-amber-500 font-semibold flex items-center gap-0.5">
              <TrendingUp className="w-3.5 h-3.5" />
              Active
            </span>
            <span>identity verified profiles</span>
          </div>
        </div>

        {/* Card 2: Total Matches */}
        <div className="bg-[#1E293B] border border-slate-800 rounded-xl p-6 shadow-lg relative overflow-hidden group">
          <div className="absolute top-0 right-0 w-24 h-24 bg-amber-500/5 rounded-full blur-2xl group-hover:bg-amber-500/10 transition-colors"></div>
          <div className="flex justify-between items-start">
            <div>
              <p className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Matches Executed</p>
              <h3 className="text-3xl font-mono font-bold text-slate-100 mt-2">{overview?.totalMatches}</h3>
            </div>
            <div className="p-2 bg-amber-500/10 text-amber-500 border border-amber-500/20 rounded-lg">
              <Trophy className="w-5 h-5" />
            </div>
          </div>
          <div className="flex items-center gap-1.5 mt-4 text-xs text-slate-500">
            <span>Aggregated history of official bouts</span>
          </div>
        </div>

        {/* Card 3: Dispute Rate */}
        <div className="bg-[#1E293B] border border-slate-800 rounded-xl p-6 shadow-lg relative overflow-hidden group">
          <div className="absolute top-0 right-0 w-24 h-24 bg-amber-500/5 rounded-full blur-2xl group-hover:bg-amber-500/10 transition-colors"></div>
          <div className="flex justify-between items-start">
            <div>
              <p className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Dispute Frequency</p>
              <h3 className="text-3xl font-mono font-bold text-slate-100 mt-2">
                {overview?.disputeRatePercentage}%
              </h3>
            </div>
            <div className={`p-2 rounded-lg border ${
              (overview?.disputeRatePercentage || 0) > 5 
                ? 'bg-red-500/10 text-red-400 border-red-500/20' 
                : 'bg-green-500/10 text-green-400 border-green-500/20'
            }`}>
              <AlertTriangle className="w-5 h-5" />
            </div>
          </div>
          <div className="flex items-center gap-1.5 mt-4 text-xs">
            <span className={`font-semibold ${
              (overview?.disputeRatePercentage || 0) > 5 ? 'text-red-400' : 'text-green-400'
            }`}>
              {(overview?.disputeRatePercentage || 0) > 5 ? 'Over-SLA Limit' : 'Nominal Safety SLA'}
            </span>
            <span className="text-slate-500">of all matched events</span>
          </div>
        </div>

        {/* Card 4: Unresolved / Total Disputes */}
        <div className="bg-[#1E293B] border border-slate-800 rounded-xl p-6 shadow-lg relative overflow-hidden group">
          <div className="absolute top-0 right-0 w-24 h-24 bg-amber-500/5 rounded-full blur-2xl group-hover:bg-amber-500/10 transition-colors"></div>
          <div className="flex justify-between items-start">
            <div>
              <p className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Disputes Filed</p>
              <h3 className="text-3xl font-mono font-bold text-slate-100 mt-2">{overview?.totalDisputes}</h3>
            </div>
            <div className="p-2 bg-amber-500/10 text-amber-500 border border-amber-500/20 rounded-lg">
              <Clock className="w-5 h-5" />
            </div>
          </div>
          <div className="flex items-center gap-1.5 mt-4 text-xs text-slate-500">
            <span>Requires compliance review and resolution</span>
          </div>
        </div>
      </div>

      {/* Main Analytical Chart Modules */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        
        {/* Module 1: Match Volume Over Time Line Chart */}
        <div className="bg-[#1E293B] border border-slate-800 rounded-xl p-6 shadow-xl flex flex-col justify-between">
          <div>
            <h3 className="text-lg font-display font-bold text-slate-200">Match Volume Trend</h3>
            <p className="text-xs text-slate-400 mt-1">Daily aggregation of matches finalized on the platform.</p>
          </div>

          <div className="h-72 w-full mt-6">
            {hasNoVolumeData ? (
              <div className="h-full flex flex-col items-center justify-center text-center p-6 border border-dashed border-slate-800 rounded-lg">
                <BarChart3 className="w-10 h-10 text-slate-600 mb-2" />
                <p className="text-sm font-semibold text-slate-400">No match records found</p>
                <p className="text-xs text-slate-500 max-w-xs mt-1">Daily match telemetry streams will populate this timeline as bouts occur.</p>
              </div>
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={overview?.matchVolumeOverTime} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#1E293B" />
                  <XAxis 
                    dataKey="date" 
                    stroke="#64748B" 
                    fontSize={11} 
                    fontFamily="monospace"
                    tickLine={false}
                  />
                  <YAxis 
                    stroke="#64748B" 
                    fontSize={11} 
                    fontFamily="monospace"
                    tickLine={false}
                    allowDecimals={false}
                  />
                  <Tooltip content={<CustomTooltip />} />
                  <Line 
                    type="monotone" 
                    dataKey="count" 
                    name="Matches" 
                    stroke="#f59e0b" 
                    strokeWidth={2.5} 
                    dot={{ r: 3, fill: '#f59e0b', strokeWidth: 1 }}
                    activeDot={{ r: 6 }} 
                  />
                </LineChart>
              </ResponsiveContainer>
            )}
          </div>
        </div>

        {/* Module 2: ELO Rating Distribution Histogram */}
        <div className="bg-[#1E293B] border border-slate-800 rounded-xl p-6 shadow-xl flex flex-col justify-between">
          <div>
            <h3 className="text-lg font-display font-bold text-slate-200">Competitor ELO Distribution</h3>
            <p className="text-xs text-slate-400 mt-1">Histogram of active athlete rankings comparing Left and Right arm classes.</p>
          </div>

          <div className="h-72 w-full mt-6">
            {hasNoDistributionData ? (
              <div className="h-full flex flex-col items-center justify-center text-center p-6 border border-dashed border-slate-800 rounded-lg">
                <BarChart3 className="w-10 h-10 text-slate-600 mb-2" />
                <p className="text-sm font-semibold text-slate-400">No competitor ratings available</p>
                <p className="text-xs text-slate-500 max-w-xs mt-1">Rankings distribution will compute dynamically when registered competitor profiles exist.</p>
              </div>
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={distribution} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#1E293B" />
                  <XAxis 
                    dataKey="range" 
                    stroke="#64748B" 
                    fontSize={11} 
                    fontFamily="monospace"
                    tickLine={false}
                  />
                  <YAxis 
                    stroke="#64748B" 
                    fontSize={11} 
                    fontFamily="monospace"
                    tickLine={false}
                    allowDecimals={false}
                  />
                  <Tooltip content={<CustomTooltip />} />
                  <Legend 
                    verticalAlign="top" 
                    height={36} 
                    iconType="circle"
                    iconSize={8}
                    wrapperStyle={{ fontSize: 11, fontFamily: 'sans-serif', color: '#94A3B8' }}
                  />
                  <Bar 
                    dataKey="leftArmCount" 
                    name="Left Arm" 
                    fill="#f59e0b" 
                    radius={[4, 4, 0, 0]} 
                  />
                  <Bar 
                    dataKey="rightArmCount" 
                    name="Right Arm" 
                    fill="#ea580c" 
                    radius={[4, 4, 0, 0]} 
                  />
                </BarChart>
              </ResponsiveContainer>
            )}
          </div>
        </div>

      </div>
    </div>
  );
}
