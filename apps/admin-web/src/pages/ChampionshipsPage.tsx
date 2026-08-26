import React, { useState } from 'react';
import { 
  Trophy, 
  ShieldAlert, 
  Trash2, 
  Check, 
  X, 
  RefreshCw, 
  AlertTriangle, 
  Loader2,
  Award,
  Plus
} from 'lucide-react';
import { 
  useActiveTitles, 
  usePendingChallenges, 
  useAcceptChallenge, 
  useDeclineChallenge, 
  useVacateTitle,
  useCreateTitle
} from '../lib/championshipApi';
import { useAuth } from '../context/AuthContext';
import { UserRole, CreateTitlePayload } from '../types';

export default function ChampionshipsPage() {
  const { user } = useAuth();
  const { 
    data: titles, 
    isLoading: isTitlesLoading, 
    isError: isTitlesError, 
    error: titlesError,
    refetch: refetchTitles 
  } = useActiveTitles();

  const { 
    data: challenges, 
    isLoading: isChallengesLoading, 
    isError: isChallengesError, 
    error: challengesError,
    refetch: refetchChallenges 
  } = usePendingChallenges();

  // Mutations
  const acceptMutation = useAcceptChallenge();
  const declineMutation = useDeclineChallenge();
  const vacateMutation = useVacateTitle();
  const createMutation = useCreateTitle();

  // State for vacate confirmation modal
  const [vacateTargetId, setVacateTargetId] = useState<string | null>(null);
  const [vacateReason, setVacateReason] = useState<'VACATED' | 'STRIPPED'>('VACATED');
  const [vacateError, setVacateError] = useState<string | null>(null);

  // State for Create Title modal
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  const [createForm, setCreateForm] = useState<CreateTitlePayload>({
    name: '',
    arm: 'RIGHT',
    division: 'SENIOR',
    weightClass: ''
  });
  const [createError, setCreateError] = useState<string | null>(null);

  // Verification of role accessibility based on backend routes:
  // - Vacate: POST /championships/vacate requires requireRole(UserRole.NATIONAL_DIRECTOR, UserRole.SYSTEM_ADMIN)
  // - Accept: POST /championships/challenges/:id/accept requires only authenticate (accessible to logged-in admins)
  // - Decline: POST /championships/challenges/:id/decline requires only authenticate (accessible to logged-in admins)
  const canVacate = user?.role === UserRole.SYSTEM_ADMIN || user?.role === UserRole.NATIONAL_DIRECTOR;
  const canCreateTitle = user?.role === UserRole.SYSTEM_ADMIN || user?.role === UserRole.NATIONAL_DIRECTOR;
  const canManageChallenges = true; // No requireRole constraints exist on challenges endpoints

  const handleRetry = () => {
    refetchTitles();
    refetchChallenges();
  };

  const handleCreateSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (createForm.name.trim().length < 5) {
      setCreateError('Title name must be at least 5 characters.');
      return;
    }
    if (createForm.weightClass.trim().length < 2) {
      setCreateError('Weight class must be at least 2 characters.');
      return;
    }
    try {
      setCreateError(null);
      await createMutation.mutateAsync(createForm);
      setIsCreateModalOpen(false);
    } catch (err: any) {
      setCreateError(err?.message || 'Failed to create championship title.');
    }
  };

  const handleVacateConfirm = async () => {
    if (!vacateTargetId) return;
    try {
      setVacateError(null);
      await vacateMutation.mutateAsync({ 
        titleId: vacateTargetId, 
        reason: vacateReason 
      });
      setVacateTargetId(null);
    } catch (err: any) {
      setVacateError(err?.message || 'Failed to vacate title.');
    }
  };

  const isLoading = isTitlesLoading || isChallengesLoading;
  const isError = isTitlesError || isChallengesError;
  const errorMsg = (titlesError as any)?.message || (challengesError as any)?.message || 'Failed to fetch championship registry';

  if (isLoading) {
    return (
      <div className="space-y-8 animate-pulse">
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 border-b border-slate-800 pb-6">
          <div className="space-y-2">
            <div className="h-8 w-64 bg-slate-800 rounded-md" />
            <div className="h-4 w-96 bg-slate-800 rounded-md" />
          </div>
          <div className="h-10 w-24 bg-slate-800 rounded-lg" />
        </div>
        <div className="bg-[#1E293B] border border-slate-800 rounded-xl p-6 h-64" />
        <div className="bg-[#1E293B] border border-slate-800 rounded-xl p-6 h-64" />
      </div>
    );
  }

  if (isError) {
    return (
      <div className="space-y-8">
        <div className="border-b border-slate-800 pb-6">
          <h1 className="text-2xl md:text-3xl font-display font-bold text-slate-100 tracking-tight">Championships Registry</h1>
          <p className="text-slate-400 text-sm mt-1">Federation titles, active weight divisions, and pending challenges.</p>
        </div>

        <div className="bg-red-500/10 border border-red-500/20 rounded-xl p-8 max-w-2xl mx-auto text-center space-y-4">
          <div className="inline-flex items-center justify-center w-14 h-14 rounded-full bg-red-500/10 text-red-400 border border-red-500/20">
            <AlertTriangle className="w-7 h-7" />
          </div>
          <h3 className="text-lg font-semibold text-slate-200">Failed to Connect to Registry</h3>
          <p className="text-slate-400 text-sm max-w-md mx-auto leading-relaxed">
            {errorMsg}
          </p>
          <button
            onClick={handleRetry}
            className="inline-flex items-center gap-2 px-5 py-2.5 bg-slate-800 hover:bg-slate-700 border border-slate-700 text-slate-200 text-sm font-medium rounded-lg transition-colors"
          >
            <RefreshCw className="w-4 h-4" />
            Retry Core Connection
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-8">
      {/* Header Summary */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 border-b border-slate-800 pb-6">
        <div>
          <h1 className="text-2xl md:text-3xl font-display font-bold text-slate-100 tracking-tight">Championships Registry</h1>
          <p className="text-slate-400 text-sm mt-1">Federation titles, active weight divisions, and pending title challenges.</p>
        </div>
        
        <div className="flex items-center gap-3">
          {canCreateTitle && (
            <button
              onClick={() => {
                setCreateForm({
                  name: '',
                  arm: 'RIGHT',
                  division: 'SENIOR',
                  weightClass: ''
                });
                setCreateError(null);
                setIsCreateModalOpen(true);
              }}
              className="inline-flex items-center gap-2 px-4 py-2 bg-amber-500 hover:bg-amber-400 text-slate-950 text-xs font-semibold rounded-lg transition-colors shadow-lg"
            >
              <Plus className="w-4 h-4" />
              Create Title
            </button>
          )}

          <button 
            onClick={handleRetry}
            className="p-2 bg-slate-800 hover:bg-slate-700 border border-slate-700 text-slate-300 rounded-lg transition-colors flex items-center justify-center"
            title="Refresh Registry"
          >
            <RefreshCw className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* Active Champion Titles Table */}
      <div className="bg-[#1E293B] border border-slate-800 rounded-xl shadow-xl overflow-hidden">
        <div className="p-6 border-b border-slate-800 flex justify-between items-center bg-slate-900/40">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-amber-500/10 text-amber-500 border border-amber-500/20 rounded-lg">
              <Trophy className="w-5 h-5" />
            </div>
            <div>
              <h3 className="text-lg font-bold text-slate-200">Active Champion Titles</h3>
              <p className="text-xs text-slate-400 mt-0.5">Currently held belt titles across all valid weight classes & arms.</p>
            </div>
          </div>
        </div>

        <div className="overflow-x-auto">
          {titles && titles.length > 0 ? (
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="border-b border-slate-800 bg-slate-900/25">
                  <th className="p-4 text-xs font-semibold text-slate-400 uppercase tracking-wider">Title / division</th>
                  <th className="p-4 text-xs font-semibold text-slate-400 uppercase tracking-wider">Arm Class</th>
                  <th className="p-4 text-xs font-semibold text-slate-400 uppercase tracking-wider">Weight division</th>
                  <th className="p-4 text-xs font-semibold text-slate-400 uppercase tracking-wider">Current Holder</th>
                  <th className="p-4 text-xs font-semibold text-slate-400 uppercase tracking-wider text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800">
                {titles.map((title) => (
                  <tr key={title.id} className="hover:bg-slate-800/25 transition-colors">
                    <td className="p-4">
                      <div className="flex items-center gap-2.5">
                        <Award className="w-4 h-4 text-amber-500 flex-shrink-0" />
                        <span className="font-semibold text-slate-200 text-sm">{title.name}</span>
                      </div>
                    </td>
                    <td className="p-4">
                      <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-bold ${
                        title.arm === 'RIGHT' ? 'bg-orange-500/10 text-orange-400' : 'bg-blue-500/10 text-blue-400'
                      }`}>
                        {title.arm}
                      </span>
                    </td>
                    <td className="p-4">
                      <span className="text-slate-300 font-mono text-xs">{title.division} • {title.weightClass}</span>
                    </td>
                    <td className="p-4">
                      {title.activeChampion ? (
                        <div>
                          <p className="font-semibold text-slate-200 text-sm">{title.activeChampion.displayName}</p>
                          <p className="text-[10px] text-slate-500 font-mono">{title.activeChampion.city}, {title.activeChampion.province}</p>
                        </div>
                      ) : (
                        <span className="text-slate-500 italic text-sm">Vacant</span>
                      )}
                    </td>
                    <td className="p-4 text-right">
                      {canVacate ? (
                        <button
                          onClick={() => setVacateTargetId(title.id)}
                          className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-red-500/10 hover:bg-red-500/20 border border-red-500/20 hover:border-red-500/30 text-red-400 text-xs font-medium rounded-lg transition-colors"
                          title="Vacate and strip title belt"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                          Vacate Title
                        </button>
                      ) : (
                        <button
                          disabled
                          className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-slate-800 text-slate-500 border border-slate-700/50 text-xs font-medium rounded-lg opacity-50 cursor-not-allowed"
                          title="Requires Director or Admin role"
                        >
                          Gated (National/SysAdmin)
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          ) : (
            <div className="text-center p-12 border-t border-slate-800">
              <Trophy className="w-10 h-10 text-slate-600 mx-auto mb-3" />
              <p className="text-sm font-semibold text-slate-400">No active titles registered</p>
              <p className="text-xs text-slate-500 max-w-sm mx-auto mt-1">Titles containing an active champion holder will be shown here.</p>
            </div>
          )}
        </div>
      </div>

      {/* Pending Challenges Table */}
      <div className="bg-[#1E293B] border border-slate-800 rounded-xl shadow-xl overflow-hidden">
        <div className="p-6 border-b border-slate-800 flex justify-between items-center bg-slate-900/40">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-amber-500/10 text-amber-500 border border-amber-500/20 rounded-lg">
              <ShieldAlert className="w-5 h-5" />
            </div>
            <div>
              <h3 className="text-lg font-bold text-slate-200">Pending Title Challenges</h3>
              <p className="text-xs text-slate-400 mt-0.5">Submitted challenges currently awaiting administrative approval or denial.</p>
            </div>
          </div>
        </div>

        <div className="overflow-x-auto">
          {challenges && challenges.length > 0 ? (
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="border-b border-slate-800 bg-slate-900/25">
                  <th className="p-4 text-xs font-semibold text-slate-400 uppercase tracking-wider">Challenger athlete</th>
                  <th className="p-4 text-xs font-semibold text-slate-400 uppercase tracking-wider">Target Title</th>
                  <th className="p-4 text-xs font-semibold text-slate-400 uppercase tracking-wider">Submitted Date</th>
                  <th className="p-4 text-xs font-semibold text-slate-400 uppercase tracking-wider">Current Status</th>
                  <th className="p-4 text-xs font-semibold text-slate-400 uppercase tracking-wider text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800">
                {challenges.map((challenge) => (
                  <tr key={challenge.id} className="hover:bg-slate-800/25 transition-colors">
                    <td className="p-4">
                      {challenge.challenger ? (
                        <div>
                          <p className="font-semibold text-slate-200 text-sm">{challenge.challenger.displayName}</p>
                          <p className="text-[10px] text-slate-500 font-mono">{challenge.challenger.city}, {challenge.challenger.province}</p>
                        </div>
                      ) : (
                        <span className="text-slate-500 italic text-sm">Unknown Athlete</span>
                      )}
                    </td>
                    <td className="p-4">
                      {challenge.title ? (
                        <div>
                          <p className="font-semibold text-slate-200 text-sm">{challenge.title.name}</p>
                          <p className="text-[10px] text-slate-500 font-mono">{challenge.title.arm} • {challenge.title.division}</p>
                        </div>
                      ) : (
                        <span className="text-slate-500 italic text-sm">Unknown Title</span>
                      )}
                    </td>
                    <td className="p-4 text-slate-300 text-xs font-mono">
                      {challenge.createdAt ? new Date(challenge.createdAt).toLocaleDateString() : 'N/A'}
                    </td>
                    <td className="p-4">
                      <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-semibold bg-amber-500/10 text-amber-500 border border-amber-500/25">
                        {challenge.status}
                      </span>
                    </td>
                    <td className="p-4 text-right">
                      {canManageChallenges ? (
                        <div className="flex items-center justify-end gap-2">
                          <button
                            onClick={() => acceptMutation.mutate(challenge.id)}
                            disabled={acceptMutation.isPending || declineMutation.isPending}
                            className="inline-flex items-center gap-1 px-2.5 py-1.5 bg-green-500/10 hover:bg-green-500/20 border border-green-500/20 hover:border-green-500/30 text-green-400 text-xs font-medium rounded-lg transition-colors disabled:opacity-50"
                            title="Accept and validate title challenge"
                          >
                            {acceptMutation.isPending ? (
                              <Loader2 className="w-3.5 h-3.5 animate-spin" />
                            ) : (
                              <Check className="w-3.5 h-3.5" />
                            )}
                            Accept
                          </button>
                          <button
                            onClick={() => declineMutation.mutate(challenge.id)}
                            disabled={acceptMutation.isPending || declineMutation.isPending}
                            className="inline-flex items-center gap-1 px-2.5 py-1.5 bg-red-500/10 hover:bg-red-500/20 border border-red-500/20 hover:border-red-500/30 text-red-400 text-xs font-medium rounded-lg transition-colors disabled:opacity-50"
                            title="Decline and drop challenge request"
                          >
                            {declineMutation.isPending ? (
                              <Loader2 className="w-3.5 h-3.5 animate-spin" />
                            ) : (
                              <X className="w-3.5 h-3.5" />
                            )}
                            Decline
                          </button>
                        </div>
                      ) : (
                        <button
                          disabled
                          className="px-3 py-1.5 bg-slate-800 text-slate-500 border border-slate-700/50 text-xs font-medium rounded-lg opacity-50 cursor-not-allowed"
                        >
                          Gated
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          ) : (
            <div className="text-center p-12 border-t border-slate-800">
              <ShieldAlert className="w-10 h-10 text-slate-600 mx-auto mb-3" />
              <p className="text-sm font-semibold text-slate-400">No pending challenges registered</p>
              <p className="text-xs text-slate-500 max-w-sm mx-auto mt-1">Pending title requests will show up in this panel for review.</p>
            </div>
          )}
        </div>
      </div>

      {/* Vacate / Strip Belt Destructive Action Dialog */}
      {vacateTargetId && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-[#1E293B] border border-slate-800 rounded-xl p-6 max-w-md w-full shadow-2xl space-y-4">
            <div className="flex items-center gap-3 text-red-500">
              <div className="p-2 bg-red-500/10 rounded-lg border border-red-500/20">
                <AlertTriangle className="w-6 h-6" />
              </div>
              <div>
                <h3 className="text-lg font-bold text-slate-100">Strip Championship Title</h3>
                <p className="text-xs text-red-400">Destructive, non-reversible action</p>
              </div>
            </div>

            <p className="text-sm text-slate-300 leading-relaxed">
              Are you absolutely sure you want to strip this athlete's title belt? This action immediately marks the championship belt as vacant, archives the current holder's active streak, and logs a strict regulatory audit trail event.
            </p>

            {vacateError && (
              <p className="text-xs text-red-400 bg-red-500/10 p-2.5 rounded border border-red-500/20">
                {vacateError}
              </p>
            )}

            <div className="space-y-2">
              <label className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Strip reason category</label>
              <select 
                value={vacateReason}
                onChange={(e) => setVacateReason(e.target.value as any)}
                className="w-full bg-slate-900 border border-slate-800 rounded-lg p-2 text-sm text-slate-200 focus:outline-none focus:border-amber-500"
              >
                <option value="VACATED">Vacated (Voluntary resignation or Retirement)</option>
                <option value="STRIPPED">Stripped (Regulatory violation or Disciplinary Action)</option>
              </select>
            </div>

            <div className="flex justify-end items-center gap-3 pt-2">
              <button
                onClick={() => {
                  setVacateTargetId(null);
                  setVacateError(null);
                }}
                disabled={vacateMutation.isPending}
                className="px-4 py-2 bg-slate-800 hover:bg-slate-700 border border-slate-700 text-slate-300 text-sm font-medium rounded-lg transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleVacateConfirm}
                disabled={vacateMutation.isPending}
                className="inline-flex items-center gap-1.5 px-4 py-2 bg-red-600 hover:bg-red-500 text-white text-sm font-medium rounded-lg transition-colors shadow-lg disabled:opacity-50"
              >
                {vacateMutation.isPending ? (
                  <Loader2 className="w-4 h-4 animate-spin" />
                ) : (
                  <Trash2 className="w-4 h-4" />
                )}
                Confirm Strip Title
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Create Title Modal */}
      {isCreateModalOpen && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-[#1E293B] border border-slate-800 rounded-xl p-6 max-w-md w-full shadow-2xl space-y-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-amber-500/10 text-amber-500 rounded-lg border border-amber-500/20">
                <Trophy className="w-6 h-6" />
              </div>
              <div>
                <h3 className="text-lg font-bold text-slate-100">Create Champion Title</h3>
                <p className="text-xs text-slate-400">Establish a new federation championship belt</p>
              </div>
            </div>

            <form onSubmit={handleCreateSubmit} className="space-y-4">
              <div className="space-y-2">
                <label className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Title Name (Required)</label>
                <input
                  type="text"
                  value={createForm.name}
                  onChange={(e) => setCreateForm(prev => ({ ...prev, name: e.target.value }))}
                  placeholder="e.g. National Heavyweight Championship"
                  required
                  className="w-full bg-slate-900 border border-slate-800 rounded-lg p-2.5 text-xs text-slate-200 focus:outline-none focus:border-amber-500 placeholder-slate-600"
                />
                <p className="text-[10px] text-slate-500">Minimum 5 characters. Must be descriptive.</p>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <label className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Arm Class</label>
                  <select
                    value={createForm.arm}
                    onChange={(e) => setCreateForm(prev => ({ ...prev, arm: e.target.value as 'LEFT' | 'RIGHT' }))}
                    className="w-full bg-slate-900 border border-slate-800 rounded-lg p-2.5 text-xs text-slate-200 focus:outline-none focus:border-amber-500"
                  >
                    <option value="RIGHT">Right Arm</option>
                    <option value="LEFT">Left Arm</option>
                  </select>
                </div>

                <div className="space-y-2">
                  <label className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Division</label>
                  <select
                    value={createForm.division}
                    onChange={(e) => setCreateForm(prev => ({ ...prev, division: e.target.value as any }))}
                    className="w-full bg-slate-900 border border-slate-800 rounded-lg p-2.5 text-xs text-slate-200 focus:outline-none focus:border-amber-500"
                  >
                    <option value="SENIOR">Senior</option>
                    <option value="JUNIOR">Junior</option>
                    <option value="FEMALE">Female</option>
                  </select>
                </div>
              </div>

              <div className="space-y-2">
                <label className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Weight Class (Required)</label>
                <input
                  type="text"
                  value={createForm.weightClass}
                  onChange={(e) => setCreateForm(prev => ({ ...prev, weightClass: e.target.value }))}
                  placeholder="e.g. 95kg+, Open Weight, Featherweight"
                  required
                  className="w-full bg-slate-900 border border-slate-800 rounded-lg p-2.5 text-xs text-slate-200 focus:outline-none focus:border-amber-500 placeholder-slate-600"
                />
                <p className="text-[10px] text-slate-500">Specify the weight threshold or division name.</p>
              </div>

              {createError && (
                <p className="text-xs text-red-400 bg-red-500/10 p-2.5 rounded border border-red-500/20 leading-relaxed">
                  {createError}
                </p>
              )}

              <div className="flex justify-end gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => setIsCreateModalOpen(false)}
                  disabled={createMutation.isPending}
                  className="px-4 py-2 bg-slate-800 hover:bg-slate-700 border border-slate-700 text-slate-300 text-xs font-medium rounded-lg transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={createMutation.isPending}
                  className="px-4 py-2 bg-amber-500 hover:bg-amber-400 text-slate-950 text-xs font-semibold rounded-lg transition-colors flex items-center gap-1.5 shadow-lg shadow-amber-950/25"
                >
                  {createMutation.isPending ? (
                    <Loader2 className="w-3.5 h-3.5 animate-spin" />
                  ) : (
                    <Check className="w-3.5 h-3.5" />
                  )}
                  Create Title
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
