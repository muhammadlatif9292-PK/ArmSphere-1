import { useState, useMemo } from 'react';
import {
  Award,
  Search,
  CheckCircle2,
  ShieldAlert,
  MapPin,
  RefreshCw,
  Edit,
  UserX,
  X,
  Loader2,
  Activity,
} from 'lucide-react';
import {
  useReferees,
  useAssignRefereeRegion,
  useUpdateRefereeLicense,
  useSuspendReferee,
} from '../lib/refereesApi';
import { useAuth } from '../context/AuthContext';
import { UserRole, RefereeAdminView } from '../types';
import { LoadingCard, ErrorPanel, EmptyState } from '../components/ui';

const PAKISTAN_REGIONS = [
  'Punjab',
  'Sindh',
  'Khyber Pakhtunkhwa',
  'Balochistan',
  'Islamabad Capital Territory',
  'Gilgit-Baltistan',
  'Azad Jammu and Kashmir',
];

const CERTIFICATION_LEVELS = [
  'APPRENTICE',
  'PROVINCIAL',
  'NATIONAL',
  'SENIOR',
  'MASTER',
];

export default function RefereesPage() {
  const { user } = useAuth();
  const { data: referees = [], isLoading, isError, error, refetch } = useReferees();

  // Filter & Search states
  const [searchQuery, setSearchQuery] = useState('');
  const [regionFilter, setRegionFilter] = useState('');
  const [statusFilter, setStatusFilter] = useState('');

  // Modals state
  const [activeLicenseReferee, setActiveLicenseReferee] = useState<RefereeAdminView | null>(null);
  const [activeRegionReferee, setActiveRegionReferee] = useState<RefereeAdminView | null>(null);
  const [activeSuspendReferee, setActiveSuspendReferee] = useState<RefereeAdminView | null>(null);

  // Form states
  const [licenseForm, setLicenseForm] = useState({
    certification: 'NATIONAL',
    status: 'ACTIVE' as 'ACTIVE' | 'EXPIRED' | 'REVOKED',
  });
  const [selectedRegion, setSelectedRegion] = useState('Punjab');
  const [suspensionReason, setSuspensionReason] = useState('');

  // Mutations
  const updateLicenseMutation = useUpdateRefereeLicense();
  const assignRegionMutation = useAssignRefereeRegion();
  const suspendMutation = useSuspendReferee();

  // Permissions check: System Admin and National Director have full licensing authority;
  // Provincial Director can assign region.
  const isSuperAdmin =
    user?.role === UserRole.SYSTEM_ADMIN || user?.role === UserRole.NATIONAL_DIRECTOR;
  const canAssignRegion =
    isSuperAdmin || user?.role === UserRole.PROVINCIAL_DIRECTOR;

  // Filtered referees
  const filteredReferees = useMemo(() => {
    return referees.filter((referee) => {
      const matchesSearch =
        !searchQuery ||
        referee.fullName.toLowerCase().includes(searchQuery.toLowerCase()) ||
        referee.email.toLowerCase().includes(searchQuery.toLowerCase());

      const matchesRegion =
        !regionFilter || referee.region === regionFilter;

      const matchesStatus =
        !statusFilter ||
        (statusFilter === 'ACTIVE' && referee.isActive) ||
        (statusFilter === 'SUSPENDED' && !referee.isActive) ||
        (statusFilter === 'CERTIFIED' && referee.certificationStatus === 'ACTIVE');

      return matchesSearch && matchesRegion && matchesStatus;
    });
  }, [referees, searchQuery, regionFilter, statusFilter]);

  // Aggregate stats
  const stats = useMemo(() => {
    const total = referees.length;
    const active = referees.filter((r) => r.isActive).length;
    const certified = referees.filter((r) => r.certificationStatus === 'ACTIVE').length;
    const totalMatches = referees.reduce((sum, r) => sum + (r.performance?.totalMatches || 0), 0);
    const uniqueRegions = new Set(referees.map((r) => r.region).filter(Boolean)).size;
    return { total, active, certified, totalMatches, uniqueRegions };
  }, [referees]);

  const handleOpenLicenseModal = (ref: RefereeAdminView) => {
    setActiveLicenseReferee(ref);
    setLicenseForm({
      certification: ref.licenseClass || 'NATIONAL',
      status: (ref.certificationStatus as any) || 'ACTIVE',
    });
  };

  const handleOpenRegionModal = (ref: RefereeAdminView) => {
    setActiveRegionReferee(ref);
    setSelectedRegion(ref.region || 'Punjab');
  };

  const handleOpenSuspendModal = (ref: RefereeAdminView) => {
    setActiveSuspendReferee(ref);
    setSuspensionReason('');
  };

  const handleSaveLicense = async () => {
    if (!activeLicenseReferee) return;
    await updateLicenseMutation.mutateAsync({
      id: activeLicenseReferee.id,
      payload: licenseForm,
    });
    setActiveLicenseReferee(null);
  };

  const handleSaveRegion = async () => {
    if (!activeRegionReferee) return;
    await assignRegionMutation.mutateAsync({
      id: activeRegionReferee.id,
      payload: { region: selectedRegion },
    });
    setActiveRegionReferee(null);
  };

  const handleConfirmSuspend = async () => {
    if (!activeSuspendReferee || !suspensionReason.trim()) return;
    await suspendMutation.mutateAsync({
      id: activeSuspendReferee.id,
      payload: { reason: suspensionReason.trim() },
    });
    setActiveSuspendReferee(null);
  };

  return (
    <div className="p-6 max-w-7xl mx-auto space-y-6">
      {/* PAGE HEADER */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 border-b border-slate-800 pb-5">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-2xl font-bold font-display text-slate-100">
              Referee Administration
            </h1>
            <span className="px-2 py-0.5 text-[10px] font-mono font-semibold rounded bg-amber-500/10 text-amber-400 border border-amber-500/20 uppercase tracking-wider">
              Federation Roster
            </span>
          </div>
          <p className="text-xs text-slate-400 mt-1">
            Manage certified federation officials, licensing levels, regional jurisdictions, and match accountability.
          </p>
        </div>

        <button
          onClick={() => refetch()}
          className="flex items-center gap-1.5 px-3 py-1.5 bg-brand-raised hover:bg-slate-800 border border-slate-700/80 rounded-lg text-xs font-semibold text-slate-300 transition-colors"
        >
          <RefreshCw className="w-3.5 h-3.5" />
          <span>Refresh Roster</span>
        </button>
      </div>

      {/* METRICS CARDS */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="p-4 bg-brand-panel border border-slate-800 rounded-xl space-y-1">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-xs font-medium">Total Referees</span>
            <Award className="w-4 h-4 text-blue-400" />
          </div>
          <p className="text-2xl font-bold font-display text-slate-100">{stats.total}</p>
          <p className="text-[10px] text-slate-500 font-mono">Registered officials</p>
        </div>

        <div className="p-4 bg-brand-panel border border-slate-800 rounded-xl space-y-1">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-xs font-medium">Active Certified</span>
            <CheckCircle2 className="w-4 h-4 text-emerald-400" />
          </div>
          <p className="text-2xl font-bold font-display text-emerald-400">{stats.certified}</p>
          <p className="text-[10px] text-slate-500 font-mono">{stats.active} accounts active</p>
        </div>

        <div className="p-4 bg-brand-panel border border-slate-800 rounded-xl space-y-1">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-xs font-medium">Matches Officiated</span>
            <Activity className="w-4 h-4 text-purple-400" />
          </div>
          <p className="text-2xl font-bold font-display text-slate-100">{stats.totalMatches}</p>
          <p className="text-[10px] text-slate-500 font-mono">Standard & tournament matches</p>
        </div>

        <div className="p-4 bg-brand-panel border border-slate-800 rounded-xl space-y-1">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-xs font-medium">Regions Covered</span>
            <MapPin className="w-4 h-4 text-amber-400" />
          </div>
          <p className="text-2xl font-bold font-display text-amber-400">{stats.uniqueRegions}</p>
          <p className="text-[10px] text-slate-500 font-mono">Jurisdictions with active staff</p>
        </div>
      </div>

      {/* FILTERS & SEARCH */}
      <div className="flex flex-col sm:flex-row gap-3 p-4 bg-brand-panel border border-slate-800 rounded-xl">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-2.5 w-4 h-4 text-slate-400" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search by official name or email..."
            className="w-full pl-9 pr-3 py-2 bg-brand-raised border border-slate-700/80 rounded-lg text-xs text-slate-200 placeholder-slate-500 focus:outline-none focus:border-amber-500 transition-colors"
          />
        </div>

        <select
          value={regionFilter}
          onChange={(e) => setRegionFilter(e.target.value)}
          className="px-3 py-2 bg-brand-raised border border-slate-700/80 rounded-lg text-xs text-slate-200 focus:outline-none focus:border-amber-500"
        >
          <option value="">All Regions</option>
          {PAKISTAN_REGIONS.map((r) => (
            <option key={r} value={r}>
              {r}
            </option>
          ))}
        </select>

        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="px-3 py-2 bg-brand-raised border border-slate-700/80 rounded-lg text-xs text-slate-200 focus:outline-none focus:border-amber-500"
        >
          <option value="">All Statuses</option>
          <option value="ACTIVE">Account Active</option>
          <option value="SUSPENDED">Account Suspended</option>
          <option value="CERTIFIED">License Certified</option>
        </select>
      </div>

      {/* CONTENT AREA */}
      {isLoading ? (
        <LoadingCard label="Loading referee roster..." />
      ) : isError ? (
        <ErrorPanel
          title="Failed to load referees"
          message={(error as Error)?.message || 'Could not fetch referee directory.'}
          onRetry={() => refetch()}
        />
      ) : filteredReferees.length === 0 ? (
        <EmptyState
          icon={Award}
          title="No referees found"
          subtitle={
            searchQuery || regionFilter || statusFilter
              ? 'No officials matched your current filter criteria.'
              : 'No referees currently registered in the federation database.'
          }
        />
      ) : (
        <div className="bg-brand-panel border border-slate-800 rounded-xl overflow-hidden shadow-sm">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs border-collapse">
              <thead>
                <tr className="border-b border-slate-800 bg-brand-bg text-slate-400 font-mono text-[11px] uppercase tracking-wider">
                  <th className="p-3.5 pl-4">Official</th>
                  <th className="p-3.5">Region</th>
                  <th className="p-3.5">License Class</th>
                  <th className="p-3.5 text-center">Matches Officiated</th>
                  <th className="p-3.5 text-center">Account Status</th>
                  <th className="p-3.5 pr-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800/60 text-slate-300">
                {filteredReferees.map((ref) => {
                  const hasCert = !!ref.licenseClass;
                  const isCertActive = ref.certificationStatus === 'ACTIVE';

                  return (
                    <tr key={ref.id} className="hover:bg-brand-raised/50 transition-colors">
                      {/* OFFICIAL INFO */}
                      <td className="p-3.5 pl-4">
                        <div className="font-semibold text-slate-100">{ref.fullName}</div>
                        <div className="text-[11px] text-slate-500 font-mono">{ref.email}</div>
                      </td>

                      {/* REGION */}
                      <td className="p-3.5">
                        {ref.region ? (
                          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-semibold bg-blue-500/10 text-blue-400 border border-blue-500/20">
                            <MapPin className="w-3 h-3" />
                            {ref.region}
                          </span>
                        ) : (
                          <span className="text-slate-500 text-[11px] italic">Unassigned</span>
                        )}
                      </td>

                      {/* LICENSE CLASS */}
                      <td className="p-3.5">
                        {hasCert ? (
                          <div className="flex items-center gap-1.5">
                            <span className="font-mono text-[11px] font-bold text-amber-400">
                              {ref.licenseClass}
                            </span>
                            <span
                              className={`px-1.5 py-0.5 text-[9px] font-mono font-bold rounded ${
                                isCertActive
                                  ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20'
                                  : 'bg-red-500/10 text-red-400 border border-red-500/20'
                              }`}
                            >
                              {ref.certificationStatus}
                            </span>
                          </div>
                        ) : (
                          <span className="text-slate-500 text-[11px] italic">No active license</span>
                        )}
                      </td>

                      {/* MATCHES */}
                      <td className="p-3.5 text-center font-mono font-semibold text-slate-200">
                        {ref.performance?.totalMatches ?? 0}
                      </td>

                      {/* ACCOUNT STATUS */}
                      <td className="p-3.5 text-center">
                        <span
                          className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-semibold ${
                            ref.isActive
                              ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20'
                              : 'bg-red-500/10 text-red-400 border border-red-500/20'
                          }`}
                        >
                          {ref.isActive ? (
                            <>
                              <CheckCircle2 className="w-3 h-3" /> Active
                            </>
                          ) : (
                            <>
                              <ShieldAlert className="w-3 h-3" /> Suspended
                            </>
                          )}
                        </span>
                      </td>

                      {/* ACTIONS */}
                      <td className="p-3.5 pr-4 text-right">
                        <div className="flex items-center justify-end gap-1.5">
                          {canAssignRegion && (
                            <button
                              onClick={() => handleOpenRegionModal(ref)}
                              title="Assign Regional Coverage"
                              className="p-1.5 rounded-lg bg-brand-raised hover:bg-slate-700 text-slate-300 hover:text-blue-400 border border-slate-700/80 transition-colors"
                            >
                              <MapPin className="w-3.5 h-3.5" />
                            </button>
                          )}

                          {isSuperAdmin && (
                            <>
                              <button
                                onClick={() => handleOpenLicenseModal(ref)}
                                title="Update License Level"
                                className="p-1.5 rounded-lg bg-brand-raised hover:bg-slate-700 text-slate-300 hover:text-amber-400 border border-slate-700/80 transition-colors"
                              >
                                <Edit className="w-3.5 h-3.5" />
                              </button>

                              {ref.isActive && (
                                <button
                                  onClick={() => handleOpenSuspendModal(ref)}
                                  title="Suspend Official License"
                                  className="p-1.5 rounded-lg bg-red-500/10 hover:bg-red-500/20 text-red-400 border border-red-500/30 transition-colors"
                                >
                                  <UserX className="w-3.5 h-3.5" />
                                </button>
                              )}
                            </>
                          )}
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* UPDATE LICENSE MODAL */}
      {activeLicenseReferee && (
        <div className="fixed inset-0 z-50 bg-black/75 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="w-full max-w-md bg-brand-panel border border-slate-800 rounded-xl p-6 space-y-4 shadow-2xl">
            <div className="flex items-center justify-between pb-3 border-b border-slate-800">
              <div className="flex items-center gap-2">
                <Award className="w-5 h-5 text-amber-400" />
                <h3 className="text-sm font-bold text-slate-100 font-display">
                  Update Official License
                </h3>
              </div>
              <button
                onClick={() => setActiveLicenseReferee(null)}
                className="text-slate-400 hover:text-slate-200"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="text-xs text-slate-300 space-y-3">
              <div>
                <p className="font-semibold text-slate-200">{activeLicenseReferee.fullName}</p>
                <p className="text-[11px] text-slate-500 font-mono">{activeLicenseReferee.email}</p>
              </div>

              <div className="space-y-1">
                <label className="text-[11px] font-mono text-slate-400">Certification Level</label>
                <select
                  value={licenseForm.certification}
                  onChange={(e) =>
                    setLicenseForm((prev) => ({ ...prev, certification: e.target.value }))
                  }
                  className="w-full px-3 py-2 bg-brand-raised border border-slate-700 rounded-lg text-xs text-slate-200 focus:outline-none focus:border-amber-500"
                >
                  {CERTIFICATION_LEVELS.map((lvl) => (
                    <option key={lvl} value={lvl}>
                      {lvl}
                    </option>
                  ))}
                </select>
              </div>

              <div className="space-y-1">
                <label className="text-[11px] font-mono text-slate-400">License Status</label>
                <select
                  value={licenseForm.status}
                  onChange={(e) =>
                    setLicenseForm((prev) => ({
                      ...prev,
                      status: e.target.value as 'ACTIVE' | 'EXPIRED' | 'REVOKED',
                    }))
                  }
                  className="w-full px-3 py-2 bg-brand-raised border border-slate-700 rounded-lg text-xs text-slate-200 focus:outline-none focus:border-amber-500"
                >
                  <option value="ACTIVE">ACTIVE</option>
                  <option value="EXPIRED">EXPIRED</option>
                  <option value="REVOKED">REVOKED</option>
                </select>
              </div>
            </div>

            <div className="flex items-center justify-end gap-2 pt-3 border-t border-slate-800">
              <button
                onClick={() => setActiveLicenseReferee(null)}
                className="px-3 py-1.5 text-xs text-slate-400 hover:text-slate-200"
              >
                Cancel
              </button>
              <button
                onClick={handleSaveLicense}
                disabled={updateLicenseMutation.isPending}
                className="flex items-center gap-1.5 px-4 py-2 bg-amber-500 hover:bg-amber-400 text-slate-950 font-bold text-xs rounded-lg transition-colors disabled:opacity-50"
              >
                {updateLicenseMutation.isPending && <Loader2 className="w-3.5 h-3.5 animate-spin" />}
                Save License
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ASSIGN REGION MODAL */}
      {activeRegionReferee && (
        <div className="fixed inset-0 z-50 bg-black/75 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="w-full max-w-md bg-brand-panel border border-slate-800 rounded-xl p-6 space-y-4 shadow-2xl">
            <div className="flex items-center justify-between pb-3 border-b border-slate-800">
              <div className="flex items-center gap-2">
                <MapPin className="w-5 h-5 text-blue-400" />
                <h3 className="text-sm font-bold text-slate-100 font-display">
                  Assign Regional Coverage
                </h3>
              </div>
              <button
                onClick={() => setActiveRegionReferee(null)}
                className="text-slate-400 hover:text-slate-200"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="text-xs text-slate-300 space-y-3">
              <div>
                <p className="font-semibold text-slate-200">{activeRegionReferee.fullName}</p>
                <p className="text-[11px] text-slate-500 font-mono">{activeRegionReferee.email}</p>
              </div>

              <div className="space-y-1">
                <label className="text-[11px] font-mono text-slate-400">Jurisdiction Region</label>
                <select
                  value={selectedRegion}
                  onChange={(e) => setSelectedRegion(e.target.value)}
                  className="w-full px-3 py-2 bg-brand-raised border border-slate-700 rounded-lg text-xs text-slate-200 focus:outline-none focus:border-blue-500"
                >
                  {PAKISTAN_REGIONS.map((r) => (
                    <option key={r} value={r}>
                      {r}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div className="flex items-center justify-end gap-2 pt-3 border-t border-slate-800">
              <button
                onClick={() => setActiveRegionReferee(null)}
                className="px-3 py-1.5 text-xs text-slate-400 hover:text-slate-200"
              >
                Cancel
              </button>
              <button
                onClick={handleSaveRegion}
                disabled={assignRegionMutation.isPending}
                className="flex items-center gap-1.5 px-4 py-2 bg-blue-600 hover:bg-blue-500 text-white font-bold text-xs rounded-lg transition-colors disabled:opacity-50"
              >
                {assignRegionMutation.isPending && <Loader2 className="w-3.5 h-3.5 animate-spin" />}
                Assign Jurisdiction
              </button>
            </div>
          </div>
        </div>
      )}

      {/* SUSPEND MODAL */}
      {activeSuspendReferee && (
        <div className="fixed inset-0 z-50 bg-black/75 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="w-full max-w-md bg-brand-panel border border-red-500/30 rounded-xl p-6 space-y-4 shadow-2xl">
            <div className="flex items-center justify-between pb-3 border-b border-slate-800">
              <div className="flex items-center gap-2 text-red-400">
                <ShieldAlert className="w-5 h-5" />
                <h3 className="text-sm font-bold font-display">Suspend Official</h3>
              </div>
              <button
                onClick={() => setActiveSuspendReferee(null)}
                className="text-slate-400 hover:text-slate-200"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="text-xs text-slate-300 space-y-3">
              <p className="text-slate-300">
                Are you sure you want to suspend{' '}
                <strong className="text-white">{activeSuspendReferee.fullName}</strong>? This action
                will immediately deactivate their referee access and issue a formal license
                revocation sanction.
              </p>

              <div className="space-y-1">
                <label className="text-[11px] font-mono text-slate-400">Reason for Suspension</label>
                <textarea
                  value={suspensionReason}
                  onChange={(e) => setSuspensionReason(e.target.value)}
                  placeholder="State the formal disciplinary or compliance reason..."
                  rows={3}
                  className="w-full px-3 py-2 bg-brand-raised border border-slate-700 rounded-lg text-xs text-slate-200 focus:outline-none focus:border-red-500"
                />
              </div>
            </div>

            <div className="flex items-center justify-end gap-2 pt-3 border-t border-slate-800">
              <button
                onClick={() => setActiveSuspendReferee(null)}
                className="px-3 py-1.5 text-xs text-slate-400 hover:text-slate-200"
              >
                Cancel
              </button>
              <button
                onClick={handleConfirmSuspend}
                disabled={suspendMutation.isPending || !suspensionReason.trim()}
                className="flex items-center gap-1.5 px-4 py-2 bg-red-600 hover:bg-red-500 text-white font-bold text-xs rounded-lg transition-colors disabled:opacity-50"
              >
                {suspendMutation.isPending && <Loader2 className="w-3.5 h-3.5 animate-spin" />}
                Confirm Suspension
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
