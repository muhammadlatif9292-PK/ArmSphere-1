import React, { useState, useMemo } from 'react';
import { 
  Users, 
  Search, 
  CheckCircle, 
  AlertOctagon, 
  ShieldAlert, 
  Edit, 
  RefreshCw, 
  UserMinus, 
  UserCheck, 
  UserX,
  Check,
  X,
  Loader2,
  Info,
  MapPin,
  Award
} from 'lucide-react';
import { 
  useAthletes, 
  useReviewProfile, 
  useSuspendAthlete, 
  useBlacklistAthlete, 
  useRecoverAthlete, 
  useCorrectAthlete,
  useRefereeCertifications,
  useIssueRefereeCertification,
  useRevokeRefereeCertification
} from '../lib/athletesApi';
import { useAuth } from '../context/AuthContext';
import { UserRole, AthleteAdminView } from '../types';
import { LoadingCard, ErrorPanel, EmptyState } from '../components/ui';

export default function AthletesPage() {
  const { user } = useAuth();
  
  // Filter & Search states
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [provinceFilter, setProvinceFilter] = useState('');
  
  // Local state for pagination (Client-side view pagination ONLY, with explicit ledger note)
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 10;

  // Query hook using the supported backend filters (search, status, province)
  const { 
    data: athletes = [], 
    isLoading, 
    isError, 
    error, 
    refetch 
  } = useAthletes({
    search: searchQuery || undefined,
    status: statusFilter || undefined,
    province: provinceFilter || undefined
  });

  // Mutations
  const reviewMutation = useReviewProfile();
  const suspendMutation = useSuspendAthlete();
  const blacklistMutation = useBlacklistAthlete();
  const recoverMutation = useRecoverAthlete();
  const correctMutation = useCorrectAthlete();

  // Modal active targets
  const [activeReviewAthlete, setActiveReviewAthlete] = useState<AthleteAdminView | null>(null);
  const [activeSuspendAthlete, setActiveSuspendAthlete] = useState<AthleteAdminView | null>(null);
  const [activeBlacklistAthlete, setActiveBlacklistAthlete] = useState<AthleteAdminView | null>(null);
  const [activeCorrectAthlete, setActiveCorrectAthlete] = useState<AthleteAdminView | null>(null);
  const [activeCertificationsAthlete, setActiveCertificationsAthlete] = useState<AthleteAdminView | null>(null);

  // Form states
  const [reviewForm, setReviewForm] = useState<{ status: 'VERIFIED' | 'REJECTED'; reason: string }>({
    status: 'VERIFIED',
    reason: ''
  });
  const [suspendForm, setSuspendForm] = useState({
    reason: '',
    durationDays: 30
  });
  const [blacklistForm, setBlacklistForm] = useState({
    reason: ''
  });
  const [correctForm, setCorrectForm] = useState({
    displayName: '',
    weightClass: '',
    leftArmElo: 1000,
    rightArmElo: 1000,
    province: '',
    city: ''
  });

  // Local feedback messages
  const [actionError, setActionError] = useState<string | null>(null);

  // Gating calculations based on requireRole in adminRouter:
  const isSysAdminOrNational = user?.role === UserRole.SYSTEM_ADMIN || user?.role === UserRole.NATIONAL_DIRECTOR;
  
  const canReview = isSysAdminOrNational || 
                    user?.role === UserRole.PROVINCIAL_DIRECTOR || 
                    user?.role === UserRole.COMPLIANCE_OFFICER;

  const canSuspend = isSysAdminOrNational || 
                     user?.role === UserRole.PROVINCIAL_DIRECTOR;

  const canBlacklist = isSysAdminOrNational;
  const canRecover = isSysAdminOrNational;
  const canCorrect = isSysAdminOrNational;
  const canManageCertifications = isSysAdminOrNational || user?.role === UserRole.PROVINCIAL_DIRECTOR;

  // Extract distinct provinces dynamically from data for filter dropdown
  const provincesList = useMemo(() => {
    const list = athletes.map(a => a.province).filter(Boolean);
    return Array.from(new Set(list)).sort();
  }, [athletes]);

  // Client-side pagination slice
  const paginatedAthletes = useMemo(() => {
    const startIndex = (currentPage - 1) * itemsPerPage;
    return athletes.slice(startIndex, startIndex + itemsPerPage);
  }, [athletes, currentPage]);

  const totalPages = Math.ceil(athletes.length / itemsPerPage);

  const handleSearchChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setSearchQuery(e.target.value);
    setCurrentPage(1);
  };

  const handleStatusFilterChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    setStatusFilter(e.target.value);
    setCurrentPage(1);
  };

  const handleProvinceFilterChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    setProvinceFilter(e.target.value);
    setCurrentPage(1);
  };

  // Row action initializers
  const openReviewModal = (athlete: AthleteAdminView) => {
    setActiveReviewAthlete(athlete);
    setReviewForm({ status: 'VERIFIED', reason: '' });
    setActionError(null);
  };

  const openSuspendModal = (athlete: AthleteAdminView) => {
    setActiveSuspendAthlete(athlete);
    setSuspendForm({ reason: '', durationDays: 30 });
    setActionError(null);
  };

  const openBlacklistModal = (athlete: AthleteAdminView) => {
    setActiveBlacklistAthlete(athlete);
    setBlacklistForm({ reason: '' });
    setActionError(null);
  };

  const openCorrectModal = (athlete: AthleteAdminView) => {
    setActiveCorrectAthlete(athlete);
    setCorrectForm({
      displayName: athlete.displayName || '',
      weightClass: athlete.weightClass || '',
      leftArmElo: athlete.leftArmElo ?? 1000,
      rightArmElo: athlete.rightArmElo ?? 1000,
      province: athlete.province || '',
      city: athlete.city || ''
    });
    setActionError(null);
  };

  // Submit Handlers
  const handleReviewSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!activeReviewAthlete) return;
    try {
      setActionError(null);
      await reviewMutation.mutateAsync({
        id: activeReviewAthlete.id,
        payload: {
          status: reviewForm.status,
          reason: reviewForm.reason || undefined
        }
      });
      setActiveReviewAthlete(null);
    } catch (err: any) {
      setActionError(err?.message || 'Failed to submit profile review.');
    }
  };

  const handleSuspendSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!activeSuspendAthlete) return;
    if (suspendForm.reason.trim().length < 5) {
      setActionError('Suspension reason must be at least 5 characters.');
      return;
    }
    try {
      setActionError(null);
      await suspendMutation.mutateAsync({
        id: activeSuspendAthlete.id,
        payload: {
          reason: suspendForm.reason,
          durationDays: Number(suspendForm.durationDays) || undefined
        }
      });
      setActiveSuspendAthlete(null);
    } catch (err: any) {
      setActionError(err?.message || 'Failed to suspend athlete.');
    }
  };

  const handleBlacklistSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!activeBlacklistAthlete) return;
    if (blacklistForm.reason.trim().length < 5) {
      setActionError('Blacklist reason must be at least 5 characters.');
      return;
    }
    try {
      setActionError(null);
      await blacklistMutation.mutateAsync({
        id: activeBlacklistAthlete.id,
        payload: {
          reason: blacklistForm.reason
        }
      });
      setActiveBlacklistAthlete(null);
    } catch (err: any) {
      setActionError(err?.message || 'Failed to blacklist athlete.');
    }
  };

  const handleRecoverClick = async (athlete: AthleteAdminView) => {
    if (!window.confirm(`Are you sure you want to reinstate and recover user account for ${athlete.displayName}?`)) {
      return;
    }
    try {
      setActionError(null);
      await recoverMutation.mutateAsync(athlete.id);
    } catch (err: any) {
      alert(err?.message || 'Failed to recover athlete.');
    }
  };

  const handleCorrectSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!activeCorrectAthlete) return;
    try {
      setActionError(null);
      await correctMutation.mutateAsync({
        id: activeCorrectAthlete.id,
        payload: {
          displayName: correctForm.displayName || undefined,
          weightClass: correctForm.weightClass || undefined,
          leftArmElo: Number(correctForm.leftArmElo),
          rightArmElo: Number(correctForm.rightArmElo),
          province: correctForm.province || undefined,
          city: correctForm.city || undefined
        }
      });
      setActiveCorrectAthlete(null);
    } catch (err: any) {
      setActionError(err?.message || 'Failed to update athlete information.');
    }
  };

  const getStatusBadgeClass = (status: string, isActive: boolean) => {
    if (!isActive) return 'bg-red-500/15 text-red-400 border-red-500/20';
    
    switch (status?.toUpperCase()) {
      case 'VERIFIED':
        return 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20';
      case 'PENDING':
        return 'bg-amber-500/10 text-amber-500 border-amber-500/20';
      case 'REJECTED':
        return 'bg-red-500/10 text-red-400 border-red-500/20';
      case 'SUSPENDED':
        return 'bg-orange-500/10 text-orange-400 border-orange-500/20';
      case 'BLACKLISTED':
        return 'bg-rose-500/10 text-rose-400 border-rose-500/20';
      default:
        return 'bg-slate-500/10 text-slate-400 border-slate-500/20';
    }
  };

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 border-b border-slate-800 pb-6">
        <div>
          <h1 className="text-2xl md:text-3xl font-display font-bold text-slate-100 tracking-tight">Athletes Directory</h1>
          <p className="text-slate-400 text-sm mt-1">Review active athlete profile listings, handle sanctions, and calibrate Elo ratings.</p>
        </div>
        
        <button 
          onClick={() => refetch()}
          className="p-2.5 bg-slate-800 hover:bg-slate-700 border border-slate-700 text-slate-300 rounded-lg transition-colors flex items-center justify-center gap-2 text-xs font-medium"
          title="Refresh Registry"
        >
          <RefreshCw className="w-4 h-4" />
          Sync Registry
        </button>
      </div>

      {/* Compliance Warning regarding API-level parameters */}
      <div className="bg-slate-900/40 border border-slate-800 rounded-lg p-4 flex items-start gap-3">
        <Info className="w-5 h-5 text-amber-500 flex-shrink-0 mt-0.5" />
        <div className="text-xs text-slate-400 leading-relaxed">
          <p className="font-semibold text-slate-200">Compliance Ledger Note</p>
          <p className="mt-0.5">
            The core administrative <code className="text-amber-500">GET /admin/athletes</code> endpoint supports native server-side parameters for <code className="text-slate-300">search</code>, <code className="text-slate-300">status</code>, and <code className="text-slate-300">province</code>, which are dynamically passed to the database. It does not support cursor or offset pagination parameters; thus, all retrieved rows are synchronized instantly, and visual page segmentation is handled locally in the client layer.
          </p>
        </div>
      </div>

      {/* Filter / Search Controls */}
      <div className="bg-[#1E293B] border border-slate-800 rounded-xl p-5 shadow-lg flex flex-col md:flex-row items-center gap-4">
        <div className="relative w-full md:flex-1">
          <span className="absolute inset-y-0 left-0 flex items-center pl-3 text-slate-500">
            <Search className="w-4 h-4" />
          </span>
          <input
            type="text"
            value={searchQuery}
            onChange={handleSearchChange}
            placeholder="Search athletes by display name, city, or province..."
            className="w-full bg-slate-900 border border-slate-800 rounded-lg pl-10 pr-4 py-2.5 text-sm text-slate-200 focus:outline-none focus:border-amber-500 placeholder-slate-500"
          />
        </div>

        <div className="flex items-center gap-3 w-full md:w-auto">
          <div className="flex-1 md:flex-none">
            <select
              value={statusFilter}
              onChange={handleStatusFilterChange}
              className="w-full bg-slate-900 border border-slate-800 rounded-lg px-3 py-2.5 text-xs text-slate-300 focus:outline-none focus:border-amber-500"
            >
              <option value="">All Statuses</option>
              <option value="VERIFIED">Verified</option>
              <option value="PENDING">Pending Review</option>
              <option value="UNVERIFIED">Unverified</option>
              <option value="REJECTED">Rejected</option>
              <option value="SUSPENDED">Suspended</option>
              <option value="BLACKLISTED">Blacklisted</option>
            </select>
          </div>

          <div className="flex-1 md:flex-none">
            <select
              value={provinceFilter}
              onChange={handleProvinceFilterChange}
              className="w-full bg-slate-900 border border-slate-800 rounded-lg px-3 py-2.5 text-xs text-slate-300 focus:outline-none focus:border-amber-500"
            >
              <option value="">All Provinces</option>
              {provincesList.map(prov => (
                <option key={prov} value={prov}>{prov}</option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {/* Main Table */}
      <div className="bg-[#1E293B] border border-slate-800 rounded-xl shadow-xl overflow-hidden">
        {isLoading ? (
          <LoadingCard label="Loading federated athletes list..." />
        ) : isError ? (
          <ErrorPanel
            title="Failed to Retrieve Athletes"
            message={(error as any)?.message || 'An unexpected error occurred during client-side ledger queries.'}
            onRetry={() => refetch()}
            retryLabel="Retry Fetch"
          />
        ) : athletes.length === 0 ? (
          <EmptyState
            icon={Users}
            title="No Athletes Found"
            subtitle="Try adjusting your query inputs or synchronization filters to capture valid registered armwrestlers."
          />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="border-b border-slate-800 bg-slate-900/25">
                  <th className="p-4 text-xs font-semibold text-slate-400 uppercase tracking-wider">Athlete Profile</th>
                  <th className="p-4 text-xs font-semibold text-slate-400 uppercase tracking-wider">Location</th>
                  <th className="p-4 text-xs font-semibold text-slate-400 uppercase tracking-wider">Division</th>
                  <th className="p-4 text-xs font-semibold text-slate-400 uppercase tracking-wider">Elo Ratings</th>
                  <th className="p-4 text-xs font-semibold text-slate-400 uppercase tracking-wider">Account status</th>
                  <th className="p-4 text-xs font-semibold text-slate-400 uppercase tracking-wider text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800">
                {paginatedAthletes.map((athlete) => (
                  <tr key={athlete.id} className="hover:bg-slate-800/10 transition-colors">
                    <td className="p-4">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 bg-slate-800 rounded-full flex items-center justify-center border border-slate-700 font-bold text-amber-500">
                          {athlete.displayName?.substring(0, 2).toUpperCase() || 'AT'}
                        </div>
                        <div>
                          <p className="font-semibold text-slate-200 text-sm">{athlete.displayName}</p>
                          <p className="text-[10px] text-slate-500 font-mono">UID: {athlete.userId.substring(0, 8)}...</p>
                        </div>
                      </div>
                    </td>
                    
                    <td className="p-4">
                      <div className="flex items-center gap-1.5 text-xs text-slate-300">
                        <MapPin className="w-3.5 h-3.5 text-slate-500 flex-shrink-0" />
                        <span>{athlete.city}, {athlete.province}</span>
                      </div>
                    </td>

                    <td className="p-4 text-xs text-slate-300">
                      <p>{athlete.weightClass}</p>
                      <p className="text-[10px] text-slate-500 font-mono mt-0.5">
                        Dominant: {athlete.dominantArm} • {athlete.handedness}
                      </p>
                    </td>

                    <td className="p-4 font-mono text-xs">
                      <div className="flex flex-col gap-0.5">
                        <span className="text-slate-200">Left: <strong className="text-amber-500 font-medium">{athlete.leftArmElo}</strong></span>
                        <span className="text-slate-200">Right: <strong className="text-amber-500 font-medium">{athlete.rightArmElo}</strong></span>
                      </div>
                    </td>

                    <td className="p-4">
                      <div className="flex flex-col gap-1 items-start">
                        <span className={`inline-flex items-center px-2 py-0.5 rounded text-[10px] font-bold border ${getStatusBadgeClass(athlete.verificationStatus, athlete.isActive)}`}>
                          {athlete.isActive ? athlete.verificationStatus : 'DEACTIVATED'}
                        </span>
                        {athlete.verificationStatus === 'REJECTED' && athlete.rejectionReason && (
                          <span className="text-[9px] text-red-400 line-clamp-1 max-w-[150px]" title={athlete.rejectionReason}>
                            Reason: {athlete.rejectionReason}
                          </span>
                        )}
                      </div>
                    </td>

                    <td className="p-4 text-right">
                      <div className="flex items-center justify-end gap-1.5">
                        {/* Review Profile Action */}
                        {canReview && athlete.verificationStatus === 'PENDING' && (
                          <button
                            onClick={() => openReviewModal(athlete)}
                            className="p-1.5 bg-amber-500/10 hover:bg-amber-500/20 text-amber-400 border border-amber-500/20 rounded-md transition-colors"
                            title="Review athlete profile verification"
                          >
                            <CheckCircle className="w-3.5 h-3.5" />
                          </button>
                        )}

                        {/* Suspend Action */}
                        {canSuspend && athlete.isActive && athlete.verificationStatus !== 'SUSPENDED' && athlete.verificationStatus !== 'BLACKLISTED' && (
                          <button
                            onClick={() => openSuspendModal(athlete)}
                            className="p-1.5 bg-orange-500/10 hover:bg-orange-500/20 text-orange-400 border border-orange-500/20 rounded-md transition-colors"
                            title="Suspend athlete profile"
                          >
                            <UserMinus className="w-3.5 h-3.5" />
                          </button>
                        )}

                        {/* Blacklist Action */}
                        {canBlacklist && athlete.isActive && athlete.verificationStatus !== 'BLACKLISTED' && (
                          <button
                            onClick={() => openBlacklistModal(athlete)}
                            className="p-1.5 bg-rose-500/10 hover:bg-rose-500/20 text-rose-400 border border-rose-500/20 rounded-md transition-colors"
                            title="Blacklist and deactivate athlete"
                          >
                            <UserX className="w-3.5 h-3.5" />
                          </button>
                        )}

                        {/* Recover / Reinstate Action */}
                        {canRecover && (!athlete.isActive || athlete.verificationStatus === 'SUSPENDED' || athlete.verificationStatus === 'BLACKLISTED') && (
                          <button
                            onClick={() => handleRecoverClick(athlete)}
                            className="p-1.5 bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-400 border border-emerald-500/20 rounded-md transition-colors"
                            title="Recover and reinstate athlete"
                          >
                            <UserCheck className="w-3.5 h-3.5" />
                          </button>
                        )}

                        {/* Correct Profile Action */}
                        {canCorrect && (
                          <button
                            onClick={() => openCorrectModal(athlete)}
                            className="p-1.5 bg-blue-500/10 hover:bg-blue-500/20 text-blue-400 border border-blue-500/20 rounded-md transition-colors"
                            title="Apply manual profile/Elo correction"
                          >
                            <Edit className="w-3.5 h-3.5" />
                          </button>
                        )}

                        {/* Manage Referee Certifications */}
                        {canManageCertifications && (
                          <button
                            id={`manage-cert-btn-${athlete.id}`}
                            onClick={() => {
                              setActiveCertificationsAthlete(athlete);
                              setActionError(null);
                            }}
                            className="p-1.5 bg-amber-500/10 hover:bg-amber-500/20 text-amber-500 border border-amber-500/20 rounded-md transition-colors"
                            title="Manage referee certifications"
                          >
                            <Award className="w-3.5 h-3.5" />
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* Client Pagination Controls */}
        {totalPages > 1 && (
          <div className="p-4 border-t border-slate-800 bg-slate-900/15 flex items-center justify-between">
            <span className="text-xs text-slate-400">
              Showing page <strong>{currentPage}</strong> of <strong>{totalPages}</strong> ({athletes.length} total athletes)
            </span>
            <div className="flex items-center gap-2">
              <button
                disabled={currentPage === 1}
                onClick={() => setCurrentPage(prev => Math.max(1, prev - 1))}
                className="px-3 py-1.5 bg-slate-800 hover:bg-slate-700 disabled:opacity-50 text-xs text-slate-300 border border-slate-700 rounded-lg transition-colors"
              >
                Previous
              </button>
              <button
                disabled={currentPage === totalPages}
                onClick={() => setCurrentPage(prev => Math.min(totalPages, prev + 1))}
                className="px-3 py-1.5 bg-slate-800 hover:bg-slate-700 disabled:opacity-50 text-xs text-slate-300 border border-slate-700 rounded-lg transition-colors"
              >
                Next
              </button>
            </div>
          </div>
        )}
      </div>

      {/* 1. Profile Review Modal */}
      {activeReviewAthlete && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-[#1E293B] border border-slate-800 rounded-xl p-6 max-w-md w-full shadow-2xl space-y-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-amber-500/10 text-amber-500 rounded-lg border border-amber-500/20">
                <CheckCircle className="w-6 h-6" />
              </div>
              <div>
                <h3 className="text-lg font-bold text-slate-100">Review Athlete Profile</h3>
                <p className="text-xs text-slate-400">UID: {activeReviewAthlete.userId}</p>
              </div>
            </div>

            <p className="text-xs text-slate-300">
              Approve or reject the pending identity/profile details for <strong>{activeReviewAthlete.displayName}</strong>.
            </p>

            <form onSubmit={handleReviewSubmit} className="space-y-4">
              <div className="grid grid-cols-2 gap-3">
                <button
                  type="button"
                  onClick={() => setReviewForm(prev => ({ ...prev, status: 'VERIFIED' }))}
                  className={`p-3 border rounded-lg font-semibold text-xs transition-all flex items-center justify-center gap-1.5 ${
                    reviewForm.status === 'VERIFIED'
                      ? 'bg-emerald-500/10 border-emerald-500/50 text-emerald-400 shadow-md'
                      : 'bg-slate-900 border-slate-800 text-slate-400 hover:bg-slate-800/40'
                  }`}
                >
                  <Check className="w-4 h-4" />
                  VERIFY
                </button>

                <button
                  type="button"
                  onClick={() => setReviewForm(prev => ({ ...prev, status: 'REJECTED' }))}
                  className={`p-3 border rounded-lg font-semibold text-xs transition-all flex items-center justify-center gap-1.5 ${
                    reviewForm.status === 'REJECTED'
                      ? 'bg-red-500/10 border-red-500/50 text-red-400 shadow-md'
                      : 'bg-slate-900 border-slate-800 text-slate-400 hover:bg-slate-800/40'
                  }`}
                >
                  <X className="w-4 h-4" />
                  REJECT
                </button>
              </div>

              <div className="space-y-2">
                <label className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
                  Reasoning {reviewForm.status === 'REJECTED' ? '(Required)' : '(Optional)'}
                </label>
                <textarea
                  value={reviewForm.reason}
                  onChange={(e) => setReviewForm(prev => ({ ...prev, reason: e.target.value }))}
                  placeholder={reviewForm.status === 'REJECTED' ? "Provide reason for rejection..." : "Add standard profile approval remarks..."}
                  rows={3}
                  required={reviewForm.status === 'REJECTED'}
                  className="w-full bg-slate-900 border border-slate-800 rounded-lg p-2.5 text-xs text-slate-200 focus:outline-none focus:border-amber-500 leading-relaxed placeholder-slate-600"
                />
              </div>

              {actionError && (
                <p className="text-xs text-red-400 bg-red-500/10 p-2.5 rounded border border-red-500/20">
                  {actionError}
                </p>
              )}

              <div className="flex justify-end gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => setActiveReviewAthlete(null)}
                  className="px-4 py-2 bg-slate-800 hover:bg-slate-700 border border-slate-700 text-slate-300 text-xs font-medium rounded-lg transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={reviewMutation.isPending}
                  className="px-4 py-2 bg-amber-500 hover:bg-amber-400 text-slate-950 text-xs font-semibold rounded-lg transition-colors flex items-center gap-2"
                >
                  {reviewMutation.isPending && <Loader2 className="w-3.5 h-3.5 animate-spin" />}
                  Submit Decision
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* 2. Suspend Profile Modal */}
      {activeSuspendAthlete && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-[#1E293B] border border-slate-800 rounded-xl p-6 max-w-md w-full shadow-2xl space-y-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-orange-500/10 text-orange-500 rounded-lg border border-orange-500/20">
                <ShieldAlert className="w-6 h-6" />
              </div>
              <div>
                <h3 className="text-lg font-bold text-slate-100">Suspend Athlete Profile</h3>
                <p className="text-xs text-orange-400">Regulatory profile restriction action</p>
              </div>
            </div>

            <form onSubmit={handleSuspendSubmit} className="space-y-4">
              <div className="space-y-2">
                <label className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Suspension Reason (Required)</label>
                <textarea
                  value={suspendForm.reason}
                  onChange={(e) => setSuspendForm(prev => ({ ...prev, reason: e.target.value }))}
                  placeholder="Provide precise regulatory, policy, or disciplinary reasoning (minimum 5 characters)..."
                  rows={3}
                  required
                  className="w-full bg-slate-900 border border-slate-800 rounded-lg p-2.5 text-xs text-slate-200 focus:outline-none focus:border-amber-500 leading-relaxed placeholder-slate-600"
                />
              </div>

              <div className="space-y-2">
                <label className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Duration (Days)</label>
                <input
                  type="number"
                  value={suspendForm.durationDays}
                  onChange={(e) => setSuspendForm(prev => ({ ...prev, durationDays: Number(e.target.value) }))}
                  min={1}
                  required
                  className="w-full bg-slate-900 border border-slate-800 rounded-lg p-2.5 text-xs text-slate-200 focus:outline-none focus:border-amber-500"
                />
              </div>

              {actionError && (
                <p className="text-xs text-red-400 bg-red-500/10 p-2.5 rounded border border-red-500/20">
                  {actionError}
                </p>
              )}

              <div className="flex justify-end gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => setActiveSuspendAthlete(null)}
                  className="px-4 py-2 bg-slate-800 hover:bg-slate-700 border border-slate-700 text-slate-300 text-xs font-medium rounded-lg transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={suspendMutation.isPending}
                  className="px-4 py-2 bg-orange-600 hover:bg-orange-500 text-white text-xs font-semibold rounded-lg transition-colors flex items-center gap-2 shadow-lg shadow-orange-950/20"
                >
                  {suspendMutation.isPending && <Loader2 className="w-3.5 h-3.5 animate-spin" />}
                  Confirm Suspension
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* 3. Blacklist Athlete Modal */}
      {activeBlacklistAthlete && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-[#1E293B] border border-slate-800 rounded-xl p-6 max-w-md w-full shadow-2xl space-y-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-rose-500/10 text-rose-500 rounded-lg border border-rose-500/20">
                <AlertOctagon className="w-6 h-6" />
              </div>
              <div>
                <h3 className="text-lg font-bold text-slate-100">Permanent Blacklist Ban</h3>
                <p className="text-xs text-rose-400 font-semibold uppercase tracking-wide">Critical Security / Integrity Action</p>
              </div>
            </div>

            <div className="bg-red-500/10 border border-red-500/20 p-3.5 rounded-lg text-xs text-red-400 leading-relaxed">
              <strong>Warning:</strong> This immediately deactivates the user account (restricting system ingress), voids current registry presence, and marks the profile as permanently blacklisted.
            </div>

            <form onSubmit={handleBlacklistSubmit} className="space-y-4">
              <div className="space-y-2">
                <label className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Blacklisting Reason (Required)</label>
                <textarea
                  value={blacklistForm.reason}
                  onChange={(e) => setBlacklistForm(prev => ({ ...prev, reason: e.target.value }))}
                  placeholder="Mandatory justification for permanent ban (minimum 5 characters)..."
                  rows={3}
                  required
                  className="w-full bg-slate-900 border border-slate-800 rounded-lg p-2.5 text-xs text-slate-200 focus:outline-none focus:border-amber-500 leading-relaxed placeholder-slate-600"
                />
              </div>

              {actionError && (
                <p className="text-xs text-red-400 bg-red-500/10 p-2.5 rounded border border-red-500/20">
                  {actionError}
                </p>
              )}

              <div className="flex justify-end gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => setActiveBlacklistAthlete(null)}
                  className="px-4 py-2 bg-slate-800 hover:bg-slate-700 border border-slate-700 text-slate-300 text-xs font-medium rounded-lg transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={blacklistMutation.isPending}
                  className="px-4 py-2 bg-rose-600 hover:bg-rose-500 text-white text-xs font-semibold rounded-lg transition-colors flex items-center gap-2 shadow-lg shadow-rose-950/20"
                >
                  {blacklistMutation.isPending && <Loader2 className="w-3.5 h-3.5 animate-spin" />}
                  Blacklist Competitor
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* 4. Manual Profile/Elo Correction Modal */}
      {activeCorrectAthlete && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-[#1E293B] border border-slate-800 rounded-xl p-6 max-w-lg w-full shadow-2xl space-y-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-500/10 text-blue-500 rounded-lg border border-blue-500/20">
                <Edit className="w-6 h-6" />
              </div>
              <div>
                <h3 className="text-lg font-bold text-slate-100">Manual profile & Elo Correction</h3>
                <p className="text-xs text-blue-400 font-semibold">Calibrate athlete information with administrative override</p>
              </div>
            </div>

            <form onSubmit={handleCorrectSubmit} className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <label className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Display Name</label>
                  <input
                    type="text"
                    value={correctForm.displayName}
                    onChange={(e) => setCorrectForm(prev => ({ ...prev, displayName: e.target.value }))}
                    className="w-full bg-slate-900 border border-slate-800 rounded-lg p-2.5 text-xs text-slate-200 focus:outline-none focus:border-amber-500"
                  />
                </div>

                <div className="space-y-2">
                  <label className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Weight division Class</label>
                  <input
                    type="text"
                    value={correctForm.weightClass}
                    onChange={(e) => setCorrectForm(prev => ({ ...prev, weightClass: e.target.value }))}
                    placeholder="e.g. FEATHERWEIGHT, LIGHTWEIGHT"
                    className="w-full bg-slate-900 border border-slate-800 rounded-lg p-2.5 text-xs text-slate-200 focus:outline-none focus:border-amber-500"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <label className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Left Arm Elo rating</label>
                  <input
                    type="number"
                    value={correctForm.leftArmElo}
                    onChange={(e) => setCorrectForm(prev => ({ ...prev, leftArmElo: Number(e.target.value) }))}
                    className="w-full bg-slate-900 border border-slate-800 rounded-lg p-2.5 text-xs text-slate-200 focus:outline-none focus:border-amber-500 font-mono"
                  />
                </div>

                <div className="space-y-2">
                  <label className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Right Arm Elo rating</label>
                  <input
                    type="number"
                    value={correctForm.rightArmElo}
                    onChange={(e) => setCorrectForm(prev => ({ ...prev, rightArmElo: Number(e.target.value) }))}
                    className="w-full bg-slate-900 border border-slate-800 rounded-lg p-2.5 text-xs text-slate-200 focus:outline-none focus:border-amber-500 font-mono"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <label className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Province</label>
                  <input
                    type="text"
                    value={correctForm.province}
                    onChange={(e) => setCorrectForm(prev => ({ ...prev, province: e.target.value }))}
                    className="w-full bg-slate-900 border border-slate-800 rounded-lg p-2.5 text-xs text-slate-200 focus:outline-none focus:border-amber-500"
                  />
                </div>

                <div className="space-y-2">
                  <label className="text-xs font-semibold text-slate-400 uppercase tracking-wider">City</label>
                  <input
                    type="text"
                    value={correctForm.city}
                    onChange={(e) => setCorrectForm(prev => ({ ...prev, city: e.target.value }))}
                    className="w-full bg-slate-900 border border-slate-800 rounded-lg p-2.5 text-xs text-slate-200 focus:outline-none focus:border-amber-500"
                  />
                </div>
              </div>

              {actionError && (
                <p className="text-xs text-red-400 bg-red-500/10 p-2.5 rounded border border-red-500/20">
                  {actionError}
                </p>
              )}

              <div className="flex justify-end gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => setActiveCorrectAthlete(null)}
                  className="px-4 py-2 bg-slate-800 hover:bg-slate-700 border border-slate-700 text-slate-300 text-xs font-medium rounded-lg transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={correctMutation.isPending}
                  className="px-5 py-2 bg-blue-600 hover:bg-blue-500 text-white text-xs font-semibold rounded-lg transition-colors flex items-center gap-2 shadow-lg shadow-blue-950/20"
                >
                  {correctMutation.isPending && <Loader2 className="w-3.5 h-3.5 animate-spin" />}
                  Apply Calibration
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* 5. Manage Referee Certifications Modal */}
      {activeCertificationsAthlete && (
        <RefereeCertificationsModal 
          athlete={activeCertificationsAthlete}
          onClose={() => {
            setActiveCertificationsAthlete(null);
            setActionError(null);
          }}
          actionError={actionError}
          setActionError={setActionError}
        />
      )}

    </div>
  );
}

function RefereeCertificationsModal({ 
  athlete, 
  onClose,
  actionError,
  setActionError
}: { 
  athlete: AthleteAdminView; 
  onClose: () => void;
  actionError: string | null;
  setActionError: (err: string | null) => void;
}) {
  const { data: certifications = [], isLoading, isError, error } = useRefereeCertifications(athlete.userId);
  const issueMutation = useIssueRefereeCertification();
  const revokeMutation = useRevokeRefereeCertification();

  const [form, setForm] = useState({
    certificationLevel: 'PRO_LEVEL_1',
    issuingBody: 'WAF_OFFICIAL',
    issuedAt: new Date().toISOString().substring(0, 10),
    expiresAt: new Date(Date.now() + 86400000 * 365).toISOString().substring(0, 10)
  });

  const handleIssueSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      setActionError(null);
      await issueMutation.mutateAsync({
        userId: athlete.userId,
        payload: {
          certificationLevel: form.certificationLevel,
          issuingBody: form.issuingBody,
          issuedAt: new Date(form.issuedAt).toISOString(),
          expiresAt: form.expiresAt ? new Date(form.expiresAt).toISOString() : undefined
        }
      });
      // reset dates
      setForm(prev => ({
        ...prev,
        issuedAt: new Date().toISOString().substring(0, 10),
        expiresAt: new Date(Date.now() + 86400000 * 365).toISOString().substring(0, 10)
      }));
    } catch (err: any) {
      setActionError(err?.message || 'Failed to issue certification.');
    }
  };

  const handleRevoke = async (certId: string) => {
    if (!window.confirm('Are you sure you want to revoke this referee certification? This action is irreversible.')) {
      return;
    }
    try {
      setActionError(null);
      await revokeMutation.mutateAsync({ id: certId, userId: athlete.userId });
    } catch (err: any) {
      setActionError(err?.message || 'Failed to revoke certification.');
    }
  };

  return (
    <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4 z-50">
      <div className="bg-[#1E293B] border border-slate-800 rounded-xl p-6 max-w-2xl w-full shadow-2xl space-y-6 max-h-[90vh] overflow-y-auto text-left">
        <div className="flex items-center justify-between border-b border-slate-800 pb-4">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-amber-500/10 text-amber-500 rounded-lg border border-amber-500/20">
              <Award className="w-6 h-6" />
            </div>
            <div>
              <h3 className="text-lg font-bold text-slate-100">Referee Certifications</h3>
              <p className="text-xs text-slate-400">Manage credentials for <strong>{athlete.displayName}</strong></p>
            </div>
          </div>
          <button onClick={onClose} className="p-1 text-slate-400 hover:text-slate-200 hover:bg-slate-800 rounded-lg transition-colors">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Existing Certifications */}
        <div className="space-y-3">
          <h4 className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Certification History</h4>
          {isLoading ? (
            <div className="flex items-center gap-2 text-xs text-slate-400 py-4 justify-center">
              <Loader2 className="w-4 h-4 animate-spin text-amber-500" />
              <span>Fetching history...</span>
            </div>
          ) : isError ? (
            <p className="text-xs text-red-400 bg-red-500/10 p-2.5 rounded border border-red-500/20">
              {(error as any)?.message || 'Failed to load certifications.'}
            </p>
          ) : certifications.length === 0 ? (
            <p className="text-xs text-slate-500 italic py-3 text-center border border-dashed border-slate-800 rounded-lg">
              No certifications on record for this referee.
            </p>
          ) : (
            <div className="space-y-2 max-h-[180px] overflow-y-auto pr-1">
              {certifications.map((cert) => (
                <div key={cert.id} className="bg-slate-900/60 border border-slate-800/80 rounded-lg p-3 flex justify-between items-center text-xs">
                  <div className="space-y-1">
                    <div className="flex items-center gap-2">
                      <span className="font-mono font-semibold text-amber-400">{cert.certificationLevel}</span>
                      <span className={`px-1.5 py-0.2 rounded text-[9px] font-bold border ${
                        cert.status === 'ACTIVE' 
                          ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20' 
                          : cert.status === 'REVOKED'
                          ? 'bg-red-500/10 text-red-400 border-red-500/20'
                          : 'bg-slate-500/10 text-slate-400 border-slate-500/20'
                      }`}>
                        {cert.status}
                      </span>
                    </div>
                    <p className="text-[10px] text-slate-400">
                      Issued by <span className="text-slate-300 font-medium">{cert.issuingBody}</span> on {new Date(cert.issuedAt).toLocaleDateString()}
                    </p>
                    {cert.expiresAt && (
                      <p className="text-[9px] text-slate-500">
                        Expires: {new Date(cert.expiresAt).toLocaleDateString()}
                      </p>
                    )}
                  </div>
                  {cert.status === 'ACTIVE' && (
                    <button
                      type="button"
                      onClick={() => handleRevoke(cert.id)}
                      disabled={revokeMutation.isPending}
                      className="px-2.5 py-1 bg-red-500/10 hover:bg-red-500/20 text-red-400 border border-red-500/20 rounded text-[10px] font-semibold transition-all"
                    >
                      {revokeMutation.isPending ? 'Revoking...' : 'Revoke'}
                    </button>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Issue New Certification Form */}
        <div className="border-t border-slate-800/80 pt-4 space-y-3">
          <h4 className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Issue New Certification</h4>
          <form onSubmit={handleIssueSubmit} className="space-y-3">
            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-1">
                <label className="text-[10px] text-slate-400 font-semibold uppercase">Level</label>
                <select
                  value={form.certificationLevel}
                  onChange={(e) => setForm(p => ({ ...p, certificationLevel: e.target.value }))}
                  className="w-full bg-slate-900 border border-slate-800 rounded-lg p-2 text-xs text-slate-200 focus:outline-none focus:border-amber-500"
                >
                  <option value="PRO_LEVEL_1">PRO_LEVEL_1</option>
                  <option value="PRO_LEVEL_2">PRO_LEVEL_2</option>
                  <option value="PRO_LEVEL_3">PRO_LEVEL_3</option>
                  <option value="PROVINCIAL">PROVINCIAL</option>
                  <option value="NATIONAL">NATIONAL</option>
                  <option value="INTERNATIONAL">INTERNATIONAL</option>
                </select>
              </div>

              <div className="space-y-1">
                <label className="text-[10px] text-slate-400 font-semibold uppercase">Issuing Body</label>
                <input
                  type="text"
                  value={form.issuingBody}
                  onChange={(e) => setForm(p => ({ ...p, issuingBody: e.target.value }))}
                  required
                  placeholder="e.g. WAF_OFFICIAL"
                  className="w-full bg-slate-900 border border-slate-800 rounded-lg p-2 text-xs text-slate-200 focus:outline-none focus:border-amber-500"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-1">
                <label className="text-[10px] text-slate-400 font-semibold uppercase">Issued At</label>
                <input
                  type="date"
                  value={form.issuedAt}
                  onChange={(e) => setForm(p => ({ ...p, issuedAt: e.target.value }))}
                  required
                  className="w-full bg-slate-900 border border-slate-800 rounded-lg p-2 text-xs text-slate-200 focus:outline-none focus:border-amber-500 font-mono"
                />
              </div>

              <div className="space-y-1">
                <label className="text-[10px] text-slate-400 font-semibold uppercase">Expires At</label>
                <input
                  type="date"
                  value={form.expiresAt}
                  onChange={(e) => setForm(p => ({ ...p, expiresAt: e.target.value }))}
                  className="w-full bg-slate-900 border border-slate-800 rounded-lg p-2 text-xs text-slate-200 focus:outline-none focus:border-amber-500 font-mono"
                />
              </div>
            </div>

            {actionError && (
              <p className="text-xs text-red-400 bg-red-500/10 p-2.5 rounded border border-red-500/20">
                {actionError}
              </p>
            )}

            <div className="flex justify-end gap-3 pt-2">
              <button
                type="button"
                onClick={onClose}
                className="px-3.5 py-2 bg-slate-800 hover:bg-slate-700 border border-slate-700 text-slate-300 text-xs font-medium rounded-lg transition-colors"
              >
                Close
              </button>
              <button
                type="submit"
                disabled={issueMutation.isPending}
                className="px-4 py-2 bg-amber-500 hover:bg-amber-400 text-slate-950 text-xs font-semibold rounded-lg transition-colors flex items-center gap-1.5 shadow-lg shadow-amber-950/20"
              >
                {issueMutation.isPending && <Loader2 className="w-3.5 h-3.5 animate-spin" />}
                Issue Certification
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}
