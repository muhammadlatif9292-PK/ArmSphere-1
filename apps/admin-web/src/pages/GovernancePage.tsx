import React, { useState, useEffect } from 'react';
import { 
  Scale, 
  AlertTriangle, 
  CheckCircle, 
  XCircle, 
  Clock, 
  RefreshCw, 
  ShieldCheck, 
  FileText, 
  Video, 
  User, 
  Layers,
  Loader2
} from 'lucide-react';
import { useDisputes, useResolveDispute } from '../lib/governanceApi';
import { useAuth } from '../context/AuthContext';
import { UserRole, Dispute } from '../types';

export default function GovernancePage() {
  const { user } = useAuth();
  const { 
    data: disputes, 
    isLoading, 
    isError, 
    error, 
    refetch 
  } = useDisputes();

  const resolveMutation = useResolveDispute();

  const [selectedDispute, setSelectedDispute] = useState<Dispute | null>(null);
  
  // Resolution form state
  const [resolutionDetails, setResolutionDetails] = useState('');
  const [decision, setDecision] = useState<'RESOLVED' | 'REJECTED'>('RESOLVED');
  const [submitError, setSubmitError] = useState<string | null>(null);

  // Gating check: requireRole(UserRole.SYSTEM_ADMIN, UserRole.NATIONAL_DIRECTOR, UserRole.COMPLIANCE_OFFICER)
  const canResolve = user?.role === UserRole.SYSTEM_ADMIN || 
                      user?.role === UserRole.NATIONAL_DIRECTOR || 
                      user?.role === UserRole.COMPLIANCE_OFFICER;

  const handleSelectDispute = (dispute: Dispute) => {
    setSelectedDispute(dispute);
    setResolutionDetails(dispute.resolutionDetails || '');
    setSubmitError(null);
  };

  const handleResolveSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedDispute) return;
    if (resolutionDetails.trim().length < 5) {
      setSubmitError('Resolution details must be at least 5 characters.');
      return;
    }

    try {
      setSubmitError(null);
      await resolveMutation.mutateAsync({
        id: selectedDispute.id,
        resolutionDetails,
        decision
      });
      
      // Update local selection to reflect resolved state
      const updatedDispute = {
        ...selectedDispute,
        status: decision === 'RESOLVED' ? 'RESOLVED' : 'CLOSED',
        resolutionDetails
      };
      setSelectedDispute(updatedDispute);
      refetch();
    } catch (err: any) {
      setSubmitError(err?.message || 'Failed to resolve dispute.');
    }
  };

  const getStatusColor = (status: string) => {
    switch (status.toUpperCase()) {
      case 'RESOLVED':
        return 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20';
      case 'REJECTED':
      case 'CLOSED':
        return 'bg-slate-500/10 text-slate-400 border-slate-500/20';
      case 'OPEN':
        return 'bg-blue-500/10 text-blue-400 border-blue-500/20';
      case 'UNDER_REVIEW':
        return 'bg-amber-500/10 text-amber-500 border-amber-500/20';
      default:
        return 'bg-purple-500/10 text-purple-400 border-purple-500/20';
    }
  };

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
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div className="lg:col-span-1 bg-[#1E293B] border border-slate-800 rounded-xl h-96" />
          <div className="lg:col-span-2 bg-[#1E293B] border border-slate-800 rounded-xl h-96" />
        </div>
      </div>
    );
  }

  if (isError) {
    return (
      <div className="space-y-8">
        <div className="border-b border-slate-800 pb-6">
          <h1 className="text-2xl md:text-3xl font-display font-bold text-slate-100 tracking-tight">Governance Portal</h1>
          <p className="text-slate-400 text-sm mt-1">Dispute reports, regulatory appeals, and compliance workflows.</p>
        </div>

        <div className="bg-red-500/10 border border-red-500/20 rounded-xl p-8 max-w-2xl mx-auto text-center space-y-4">
          <div className="inline-flex items-center justify-center w-14 h-14 rounded-full bg-red-500/10 text-red-400 border border-red-500/20">
            <AlertTriangle className="w-7 h-7" />
          </div>
          <h3 className="text-lg font-semibold text-slate-200">Failed to Connect to Governance Service</h3>
          <p className="text-slate-400 text-sm max-w-md mx-auto leading-relaxed">
            {(error as any)?.message || 'Unable to retrieve disputes timeline from administrative endpoints.'}
          </p>
          <button
            onClick={() => refetch()}
            className="inline-flex items-center gap-2 px-5 py-2.5 bg-slate-800 hover:bg-slate-700 border border-slate-700 text-slate-200 text-sm font-medium rounded-lg transition-colors"
          >
            <RefreshCw className="w-4 h-4" />
            Retry Governance Connection
          </button>
        </div>
      </div>
    );
  }

  // Auto-select first dispute once data arrives (effect, not render-phase side effect)
  useEffect(() => {
    if (disputes && disputes.length > 0 && !selectedDispute) {
      handleSelectDispute(disputes[0]);
    }
  }, [disputes, selectedDispute, handleSelectDispute]);

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 border-b border-slate-800 pb-6">
        <div>
          <h1 className="text-2xl md:text-3xl font-display font-bold text-slate-100 tracking-tight">Governance Portal</h1>
          <p className="text-slate-400 text-sm mt-1">Review federation rules, resolve dispute reports, and monitor incident reports.</p>
        </div>
        
        <button 
          onClick={() => refetch()}
          className="p-2 bg-slate-800 hover:bg-slate-700 border border-slate-700 text-slate-300 rounded-lg transition-colors flex items-center justify-center"
          title="Refresh disputes"
        >
          <RefreshCw className="w-4 h-4" />
        </button>
      </div>

      {/* Main Split Pane Layout */}
      {disputes && disputes.length > 0 ? (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 items-start">
          
          {/* Left Column: Disputes List */}
          <div className="lg:col-span-1 bg-[#1E293B] border border-slate-800 rounded-xl overflow-hidden shadow-xl flex flex-col max-h-[750px]">
            <div className="p-4 border-b border-slate-800 bg-slate-900/40">
              <h3 className="text-sm font-bold text-slate-200">Disputes Index</h3>
              <p className="text-[11px] text-slate-400 mt-0.5">Timeline feed of filed complaints.</p>
            </div>
            
            <div className="overflow-y-auto divide-y divide-slate-800/80">
              {disputes.map((dispute) => {
                const isSelected = selectedDispute?.id === dispute.id;
                return (
                  <button
                    key={dispute.id}
                    onClick={() => handleSelectDispute(dispute)}
                    className={`w-full text-left p-4 transition-colors flex flex-col gap-2.5 ${
                      isSelected ? 'bg-amber-500/5 border-l-2 border-amber-500' : 'hover:bg-slate-800/30'
                    }`}
                  >
                    <div className="flex justify-between items-start gap-4">
                      <span className="font-semibold text-slate-200 text-xs truncate max-w-[150px] md:max-w-full">
                        {dispute.title}
                      </span>
                      <span className={`inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-semibold border ${getStatusColor(dispute.status)}`}>
                        {dispute.status}
                      </span>
                    </div>
                    
                    <p className="text-[11px] text-slate-400 line-clamp-2 leading-relaxed">
                      {dispute.description}
                    </p>

                    <div className="flex items-center justify-between text-[10px] text-slate-500 font-mono mt-1">
                      <span>Bout: {dispute.matchId ? dispute.matchId.substring(0, 8) : 'N/A'}</span>
                      <span>{new Date(dispute.createdAt).toLocaleDateString()}</span>
                    </div>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Right Column: Dispute Details Panel */}
          <div className="lg:col-span-2 bg-[#1E293B] border border-slate-800 rounded-xl shadow-xl overflow-hidden flex flex-col">
            {selectedDispute ? (
              <div className="p-6 space-y-6">
                
                {/* Panel Header */}
                <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 border-b border-slate-800 pb-5">
                  <div className="space-y-1">
                    <div className="flex items-center gap-2">
                      <Scale className="w-5 h-5 text-amber-500" />
                      <h3 className="text-xl font-bold text-slate-200">{selectedDispute.title}</h3>
                    </div>
                    <p className="text-[10px] text-slate-500 font-mono uppercase tracking-wider">
                      Dispute Case ID: {selectedDispute.id}
                    </p>
                  </div>
                  
                  <span className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold border ${getStatusColor(selectedDispute.status)}`}>
                    <Clock className="w-3.5 h-3.5" />
                    {selectedDispute.status}
                  </span>
                </div>

                {/* Case Description */}
                <div className="space-y-2">
                  <h4 className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Incident Log Description</h4>
                  <p className="text-sm text-slate-300 bg-slate-900/50 p-4 border border-slate-800 rounded-lg leading-relaxed whitespace-pre-wrap">
                    {selectedDispute.description}
                  </p>
                </div>

                {/* Match Metadata Panel */}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="p-4 bg-slate-900/30 border border-slate-800 rounded-lg space-y-1">
                    <span className="text-[10px] font-semibold text-slate-500 uppercase tracking-wider flex items-center gap-1">
                      <Layers className="w-3.5 h-3.5 text-blue-400" /> Matches Association
                    </span>
                    <p className="text-xs font-mono font-bold text-slate-300">
                      {selectedDispute.matchId ? `Bout ID: ${selectedDispute.matchId}` : 'Direct Non-Match Protest / Appeal'}
                    </p>
                  </div>
                  
                  <div className="p-4 bg-slate-900/30 border border-slate-800 rounded-lg space-y-1">
                    <span className="text-[10px] font-semibold text-slate-500 uppercase tracking-wider flex items-center gap-1">
                      <User className="w-3.5 h-3.5 text-blue-400" /> Case Submitter
                    </span>
                    <p className="text-xs font-mono font-bold text-slate-300">
                      Reporter User ID: {selectedDispute.creatorId}
                    </p>
                  </div>
                </div>

                {/* Conceptual Evidence Slot - Mirroring Mobile Client design contract */}
                <div className="space-y-3">
                  <h4 className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Case Evidence Artifacts</h4>
                  
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div className="p-4 border border-dashed border-slate-800 hover:border-slate-700 bg-slate-900/20 rounded-lg flex items-center gap-3.5 transition-colors">
                      <div className="p-2.5 bg-amber-500/10 text-amber-500 border border-amber-500/20 rounded-lg">
                        <Video className="w-5 h-5" />
                      </div>
                      <div>
                        <p className="text-xs font-semibold text-slate-300">Incident_Video_Clip_01.mp4</p>
                        <p className="text-[10px] text-slate-500 font-mono">15.2 MB • Virus Scan Cleaned</p>
                      </div>
                    </div>

                    <div className="p-4 border border-dashed border-slate-800 hover:border-slate-700 bg-slate-900/20 rounded-lg flex items-center gap-3.5 transition-colors">
                      <div className="p-2.5 bg-amber-500/10 text-amber-500 border border-amber-500/20 rounded-lg">
                        <FileText className="w-5 h-5" />
                      </div>
                      <div>
                        <p className="text-xs font-semibold text-slate-300">Referee_Statement_Signed.pdf</p>
                        <p className="text-[10px] text-slate-500 font-mono">342 KB • Virus Scan Cleaned</p>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Resolution History if Resolved */}
                {(selectedDispute.status === 'RESOLVED' || selectedDispute.status === 'CLOSED') && selectedDispute.resolutionDetails && (
                  <div className="p-4 bg-emerald-500/5 border border-emerald-500/20 rounded-lg space-y-2">
                    <h4 className="text-xs font-semibold text-emerald-400 uppercase tracking-wider flex items-center gap-1">
                      <ShieldCheck className="w-4 h-4" /> Official Resolution Decided
                    </h4>
                    <p className="text-sm text-slate-300 leading-relaxed">
                      {selectedDispute.resolutionDetails}
                    </p>
                  </div>
                )}

                {/* Official Compliance Resolution Form (Gated) */}
                {selectedDispute.status !== 'RESOLVED' && selectedDispute.status !== 'CLOSED' && (
                  <div className="border-t border-slate-800 pt-6 space-y-4">
                    <div className="flex items-center gap-2">
                      <ShieldCheck className="w-5 h-5 text-amber-500" />
                      <h4 className="text-sm font-bold text-slate-200">Official Adjudication Resolution</h4>
                    </div>

                    {canResolve ? (
                      <form onSubmit={handleResolveSubmit} className="space-y-4">
                        <div className="grid grid-cols-2 gap-4">
                          <button
                            type="button"
                            onClick={() => setDecision('RESOLVED')}
                            className={`p-3 border rounded-lg font-semibold text-xs transition-all flex items-center justify-center gap-2 ${
                              decision === 'RESOLVED' 
                                ? 'bg-emerald-500/10 border-emerald-500/50 text-emerald-400 shadow-md' 
                                : 'bg-slate-900 border-slate-800 text-slate-400 hover:bg-slate-800/40'
                            }`}
                          >
                            <CheckCircle className="w-4 h-4" />
                            RESOLVED (Uphold protest/remedy)
                          </button>
                          
                          <button
                            type="button"
                            onClick={() => setDecision('REJECTED')}
                            className={`p-3 border rounded-lg font-semibold text-xs transition-all flex items-center justify-center gap-2 ${
                              decision === 'REJECTED' 
                                ? 'bg-red-500/10 border-red-500/50 text-red-400 shadow-md' 
                                : 'bg-slate-900 border-slate-800 text-slate-400 hover:bg-slate-800/40'
                            }`}
                          >
                            <XCircle className="w-4 h-4" />
                            REJECTED (Dismiss complaint)
                          </button>
                        </div>

                        <div className="space-y-2">
                          <label className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Official Statement Details</label>
                          <textarea
                            value={resolutionDetails}
                            onChange={(e) => setResolutionDetails(e.target.value)}
                            placeholder="Enter detailed summary justifying the regulatory decision, specific rule references, and sequential remedy directives..."
                            rows={4}
                            className="w-full bg-slate-900 border border-slate-800 rounded-lg p-3 text-sm text-slate-200 focus:outline-none focus:border-amber-500 leading-relaxed placeholder-slate-600"
                          />
                        </div>

                        {submitError && (
                          <p className="text-xs text-red-400 bg-red-500/10 p-2.5 rounded border border-red-500/20">
                            {submitError}
                          </p>
                        )}

                        <div className="flex justify-end pt-1">
                          <button
                            type="submit"
                            disabled={resolveMutation.isPending}
                            className="inline-flex items-center gap-2 px-5 py-2.5 bg-amber-500 hover:bg-amber-400 text-slate-950 text-sm font-semibold rounded-lg transition-colors shadow-lg disabled:opacity-50"
                          >
                            {resolveMutation.isPending ? (
                              <Loader2 className="w-4 h-4 animate-spin" />
                            ) : (
                              <Scale className="w-4 h-4" />
                            )}
                            Adjudicate Case
                          </button>
                        </div>
                      </form>
                    ) : (
                      <div className="p-4 bg-slate-900 border border-slate-800 rounded-lg flex items-start gap-3">
                        <AlertTriangle className="w-5 h-5 text-amber-500 flex-shrink-0 mt-0.5" />
                        <div>
                          <p className="text-xs font-semibold text-slate-300">Resolution Access Restricted</p>
                          <p className="text-[11px] text-slate-500 mt-1">
                            Your logged-in role ({user?.role}) does not have administrative clearance to resolve disputes. Only Compliance Officers, National Directors, and System Admins may decide dispute resolutions.
                          </p>
                        </div>
                      </div>
                    )}
                  </div>
                )}

              </div>
            ) : (
              <div className="text-center p-24">
                <Scale className="w-12 h-12 text-slate-600 mx-auto mb-4" />
                <h4 className="text-base font-semibold text-slate-400">No dispute selected</h4>
                <p className="text-xs text-slate-500 max-w-xs mx-auto mt-1">
                  Select an active dispute index from the left feed to examine submitted logs and official evidence.
                </p>
              </div>
            )}
          </div>

        </div>
      ) : (
        <div className="text-center p-24 bg-[#1E293B] border border-slate-800 rounded-xl shadow-xl">
          <Scale className="w-14 h-14 text-slate-600 mx-auto mb-4" />
          <h3 className="text-lg font-bold text-slate-200">Disputes Queue Clear</h3>
          <p className="text-xs text-slate-500 max-w-md mx-auto mt-2 leading-relaxed">
            There are currently no registered dispute reports in the ecosystem timeline. Brand-new incident tickets will dynamically populate this timeline feed.
          </p>
        </div>
      )}
    </div>
  );
}
