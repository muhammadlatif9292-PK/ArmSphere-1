import { useState, useEffect } from 'react';
import { 
  Video, 
  AlertTriangle, 
  CheckCircle, 
  Clock, 
  RefreshCw, 
  User, 
  ExternalLink, 
  ShieldAlert,
  Check,
  X,
  Loader2,
  Layers
} from 'lucide-react';
import { usePendingSubmissions, useModerateSubmission } from '../lib/communityApi';
import { useAuth } from '../context/AuthContext';
import { UserRole, PendingCommunityPost } from '../types';
import { getEmbedUrl } from '../utils/embedUrlBuilder';

export default function ModerationQueuePage() {
  const { user } = useAuth();
  const { 
    data: submissions, 
    isLoading, 
    isError, 
    error, 
    refetch 
  } = usePendingSubmissions();

  const moderateMutation = useModerateSubmission();

  const [selectedSubmission, setSelectedSubmission] = useState<PendingCommunityPost | null>(null);
  const [submitError, setSubmitError] = useState<string | null>(null);

  // Role Gate check matching the backend perfectly
  const canModerate = user?.role === UserRole.SYSTEM_ADMIN || 
                      user?.role === UserRole.NATIONAL_DIRECTOR || 
                      user?.role === UserRole.PROVINCIAL_DIRECTOR;

  const handleSelectSubmission = (post: PendingCommunityPost) => {
    setSelectedSubmission(post);
    setSubmitError(null);
  };

  const handleModerate = async (decision: 'APPROVED' | 'REJECTED') => {
    if (!selectedSubmission) return;

    try {
      setSubmitError(null);
      await moderateMutation.mutateAsync({
        id: selectedSubmission.id,
        decision
      });
      
      // Select another pending submission if available
      const remaining = submissions?.filter(s => s.id !== selectedSubmission.id) || [];
      if (remaining.length > 0) {
        setSelectedSubmission(remaining[0]);
      } else {
        setSelectedSubmission(null);
      }
    } catch (err: any) {
      setSubmitError(err?.message || `Failed to ${decision.toLowerCase()} submission.`);
    }
  };

  const getPlatformBadgeStyles = (platform: string) => {
    switch (platform.toUpperCase()) {
      case 'YOUTUBE':
        return 'bg-red-500/10 text-red-400 border-red-500/20';
      case 'TIKTOK':
        return 'bg-teal-500/10 text-teal-400 border-teal-500/20';
      case 'FACEBOOK':
        return 'bg-blue-500/10 text-blue-400 border-blue-500/20';
      default:
        return 'bg-slate-500/10 text-slate-400 border-slate-500/20';
    }
  };

  const getCategoryLabelColor = (category: string) => {
    switch (category.toUpperCase()) {
      case 'HIGHLIGHTS':
        return 'text-amber-400 bg-amber-500/10 border-amber-500/20';
      case 'TUTORIALS':
        return 'text-indigo-400 bg-indigo-500/10 border-indigo-500/20';
      case 'GYM':
        return 'text-emerald-400 bg-emerald-500/10 border-emerald-500/20';
      default:
        return 'text-slate-400 bg-slate-500/10 border-slate-500/20';
    }
  };

  // 1. Loading State (Shimmer Effect)
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

  // 2. Access Gating Guard check
  if (!canModerate) {
    return (
      <div className="space-y-8">
        <div className="border-b border-slate-800 pb-6">
          <h1 className="text-2xl md:text-3xl font-display font-bold text-slate-100 tracking-tight">Video Moderation Queue</h1>
          <p className="text-slate-400 text-sm mt-1">Review training video and tutorial submissions from the athletic community.</p>
        </div>

        <div className="bg-[#1E293B] border border-slate-800 rounded-xl p-8 max-w-2xl mx-auto text-center space-y-4">
          <div className="inline-flex items-center justify-center w-14 h-14 rounded-full bg-red-500/10 text-red-400 border border-red-500/20">
            <ShieldAlert className="w-7 h-7" />
          </div>
          <h3 className="text-lg font-semibold text-slate-200">Moderation Access Restricted</h3>
          <p className="text-slate-400 text-sm max-w-md mx-auto leading-relaxed">
            Your current account role (<span className="text-amber-500 font-mono font-bold uppercase">{user?.role}</span>) does not have authorization to moderate community posts. Only System Admins, National Directors, and Provincial Directors are allowed here.
          </p>
        </div>
      </div>
    );
  }

  // 3. Error State
  if (isError) {
    return (
      <div className="space-y-8">
        <div className="border-b border-slate-800 pb-6">
          <h1 className="text-2xl md:text-3xl font-display font-bold text-slate-100 tracking-tight">Video Moderation Queue</h1>
          <p className="text-slate-400 text-sm mt-1">Review training video and tutorial submissions from the athletic community.</p>
        </div>

        <div className="bg-red-500/10 border border-red-500/20 rounded-xl p-8 max-w-2xl mx-auto text-center space-y-4">
          <div className="inline-flex items-center justify-center w-14 h-14 rounded-full bg-red-500/10 text-red-400 border border-red-500/20">
            <AlertTriangle className="w-7 h-7" />
          </div>
          <h3 className="text-lg font-semibold text-slate-200">Connection to Moderation Service Failed</h3>
          <p className="text-slate-400 text-sm max-w-md mx-auto leading-relaxed">
            {error instanceof Error ? error.message : 'Unable to connect to community API to fetch submissions.'}
          </p>
          <button
            onClick={() => refetch()}
            className="inline-flex items-center gap-2 px-5 py-2.5 bg-slate-800 hover:bg-slate-700 border border-slate-700 text-slate-200 text-sm font-medium rounded-lg transition-colors"
          >
            <RefreshCw className="w-4 h-4" />
            Retry Connection
          </button>
        </div>
      </div>
    );
  }

  // Auto-select first submission once data arrives (effect, not render-phase side effect)
  useEffect(() => {
    if (submissions && submissions.length > 0 && !selectedSubmission) {
      setSelectedSubmission(submissions[0]);
    }
  }, [submissions, selectedSubmission]);

  const embedUrl = selectedSubmission ? getEmbedUrl(selectedSubmission.externalUrl, selectedSubmission.platform) : null;

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 border-b border-slate-800 pb-6">
        <div>
          <h1 className="text-2xl md:text-3xl font-display font-bold text-slate-100 tracking-tight">Video Moderation Queue</h1>
          <p className="text-slate-400 text-sm mt-1">Approve or reject video link submissions from athletes to manage the main community feed.</p>
        </div>
        
        <button 
          onClick={() => refetch()}
          className="p-2.5 bg-slate-800 hover:bg-slate-700 border border-slate-700 text-slate-300 rounded-lg transition-colors flex items-center justify-center"
          title="Refresh Moderation Queue"
        >
          <RefreshCw className="w-4 h-4" />
        </button>
      </div>

      {submissions && submissions.length > 0 ? (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 items-start">
          
          {/* Left Column: List of Pending Submissions */}
          <div className="lg:col-span-1 bg-[#1E293B] border border-slate-800 rounded-xl overflow-hidden shadow-xl flex flex-col max-h-[750px]">
            <div className="p-4 border-b border-slate-800 bg-slate-900/40 flex justify-between items-center">
              <div>
                <h3 className="text-sm font-bold text-slate-200">Pending Index</h3>
                <p className="text-[11px] text-slate-400 mt-0.5">Awaiting editorial review.</p>
              </div>
              <span className="px-2.5 py-1 rounded-full text-xs font-semibold bg-amber-500/10 text-amber-500 border border-amber-500/20">
                {submissions.length} pending
              </span>
            </div>
            
            <div className="overflow-y-auto divide-y divide-slate-800/80">
              {submissions.map((post) => {
                const isSelected = selectedSubmission?.id === post.id;
                return (
                  <button
                    key={post.id}
                    onClick={() => handleSelectSubmission(post)}
                    className={`w-full text-left p-4 transition-colors flex flex-col gap-2.5 ${
                      isSelected ? 'bg-amber-500/5 border-l-2 border-amber-500' : 'hover:bg-slate-800/30'
                    }`}
                  >
                    <div className="flex justify-between items-start gap-4">
                      <span className="font-semibold text-slate-200 text-xs truncate max-w-[130px] md:max-w-full">
                        {post.athlete?.displayName || 'Anonymous'}
                      </span>
                      <span className={`inline-flex items-center px-1.5 py-0.5 rounded text-[9px] font-bold border uppercase tracking-wider ${getPlatformBadgeStyles(post.platform)}`}>
                        {post.platform}
                      </span>
                    </div>
                    
                    <p className="text-[11px] text-slate-400 line-clamp-2 leading-relaxed">
                      {post.caption || 'No description provided by creator.'}
                    </p>

                    <div className="flex items-center justify-between text-[10px] text-slate-500 font-mono mt-1">
                      <span className={`px-1.5 py-0.5 rounded text-[8px] font-bold border ${getCategoryLabelColor(post.category)}`}>
                        {post.category}
                      </span>
                      <span>{new Date(post.createdAt).toLocaleDateString()}</span>
                    </div>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Right Column: Submission Details & Live Player Previews */}
          <div className="lg:col-span-2 bg-[#1E293B] border border-slate-800 rounded-xl shadow-xl overflow-hidden flex flex-col">
            {selectedSubmission ? (
              <div className="p-6 space-y-6">
                
                {/* Header */}
                <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 border-b border-slate-800 pb-5">
                  <div className="space-y-1">
                    <div className="flex items-center gap-2">
                      <Video className="w-5 h-5 text-amber-500" />
                      <h3 className="text-xl font-bold text-slate-200">Video Link Review</h3>
                    </div>
                    <p className="text-[10px] text-slate-500 font-mono uppercase tracking-wider">
                      Submission UUID: {selectedSubmission.id}
                    </p>
                  </div>
                  
                  <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold border bg-amber-500/10 text-amber-500 border-amber-500/20">
                    <Clock className="w-3.5 h-3.5 animate-pulse" />
                    Pending Verification
                  </span>
                </div>

                {/* Video Player Frame */}
                <div className="space-y-2">
                  <div className="flex justify-between items-center">
                    <h4 className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Live Frame Video Preview</h4>
                    <a 
                      href={selectedSubmission.externalUrl} 
                      target="_blank" 
                      rel="noopener noreferrer"
                      className="text-xs text-amber-500 hover:text-amber-400 font-medium flex items-center gap-1 transition-colors"
                    >
                      <span>Open on platform</span>
                      <ExternalLink className="w-3.5 h-3.5" />
                    </a>
                  </div>
                  
                  <div className="bg-black border border-slate-800 rounded-lg overflow-hidden aspect-video">
                    {embedUrl ? (
                      <iframe
                        src={embedUrl}
                        title="Community video player preview"
                        className="w-full h-full border-0"
                        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
                        allowFullScreen
                      />
                    ) : (
                      <div className="w-full h-full flex flex-col justify-center items-center p-8 bg-slate-900/60 text-center space-y-3">
                        <AlertTriangle className="w-10 h-10 text-amber-500" />
                        <div>
                          <p className="text-sm font-semibold text-slate-200">Embedding Restricted or Unsupported URL format</p>
                          <p className="text-xs text-slate-500 mt-1 max-w-sm">
                            We couldn't build a safe interactive iframe for: <span className="text-red-400 font-mono break-all">{selectedSubmission.externalUrl}</span>.
                            Please open the video link externally to verify the clip before making a decision.
                          </p>
                        </div>
                      </div>
                    )}
                  </div>
                </div>

                {/* Submitter Info and Caption */}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="p-4 bg-slate-900/30 border border-slate-800 rounded-lg space-y-1">
                    <span className="text-[10px] font-semibold text-slate-500 uppercase tracking-wider flex items-center gap-1">
                      <User className="w-3.5 h-3.5 text-blue-400" /> Creator Profile
                    </span>
                    <p className="text-sm font-semibold text-slate-200">
                      {selectedSubmission.athlete?.displayName || 'Anonymous'}
                    </p>
                    <p className="text-[10px] text-slate-500 font-mono">
                      Athlete ID: {selectedSubmission.athleteId}
                    </p>
                  </div>
                  
                  <div className="p-4 bg-slate-900/30 border border-slate-800 rounded-lg space-y-1">
                    <span className="text-[10px] font-semibold text-slate-500 uppercase tracking-wider flex items-center gap-1">
                      <Layers className="w-3.5 h-3.5 text-blue-400" /> Metadata Association
                    </span>
                    <div className="flex items-center gap-2 mt-0.5">
                      <span className={`px-1.5 py-0.5 rounded text-[10px] font-bold border uppercase tracking-wider ${getPlatformBadgeStyles(selectedSubmission.platform)}`}>
                        {selectedSubmission.platform}
                      </span>
                      <span className={`px-1.5 py-0.5 rounded text-[10px] font-bold border uppercase tracking-wider ${getCategoryLabelColor(selectedSubmission.category)}`}>
                        {selectedSubmission.category}
                      </span>
                    </div>
                    {selectedSubmission.matchId && (
                      <p className="text-[10px] text-slate-400 font-mono mt-1">
                        Bout Link: {selectedSubmission.matchId}
                      </p>
                    )}
                  </div>
                </div>

                {/* Caption / Description text */}
                <div className="space-y-2">
                  <h4 className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Creator's Caption</h4>
                  <p className="text-sm text-slate-300 bg-slate-900/50 p-4 border border-slate-800 rounded-lg leading-relaxed whitespace-pre-wrap">
                    {selectedSubmission.caption || 'No accompanying notes or captions submitted.'}
                  </p>
                </div>

                {/* Action Form */}
                <div className="border-t border-slate-800 pt-6 space-y-4">
                  <div className="flex items-center gap-2">
                    <CheckCircle className="w-5 h-5 text-amber-500" />
                    <h4 className="text-sm font-bold text-slate-200">Editorial Decision Actions</h4>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <button
                      type="button"
                      disabled={moderateMutation.isPending}
                      onClick={() => handleModerate('APPROVED')}
                      className="p-3.5 bg-emerald-500 hover:bg-emerald-400 disabled:bg-slate-800 disabled:text-slate-600 text-slate-950 font-bold rounded-lg text-sm transition-colors flex items-center justify-center gap-2 shadow-md"
                    >
                      {moderateMutation.isPending ? (
                        <Loader2 className="w-4 h-4 animate-spin" />
                      ) : (
                        <Check className="w-4 h-4" />
                      )}
                      Approve Link & Publish
                    </button>
                    
                    <button
                      type="button"
                      disabled={moderateMutation.isPending}
                      onClick={() => handleModerate('REJECTED')}
                      className="p-3.5 bg-red-500/15 hover:bg-red-500/25 disabled:bg-slate-800 disabled:text-slate-600 border border-red-500/30 hover:border-red-500/50 text-red-400 font-bold rounded-lg text-sm transition-colors flex items-center justify-center gap-2 shadow-md"
                    >
                      {moderateMutation.isPending ? (
                        <Loader2 className="w-4 h-4 animate-spin" />
                      ) : (
                        <X className="w-4 h-4" />
                      )}
                      Reject & Remove Link
                    </button>
                  </div>

                  {submitError && (
                    <p className="text-xs text-red-400 bg-red-500/10 p-2.5 rounded border border-red-500/20 mt-4">
                      {submitError}
                    </p>
                  )}
                </div>

              </div>
            ) : (
              <div className="text-center p-24">
                <Video className="w-12 h-12 text-slate-600 mx-auto mb-4" />
                <h4 className="text-base font-semibold text-slate-400">No submission selected</h4>
                <p className="text-xs text-slate-500 max-w-xs mx-auto mt-1">
                  Select a video submission from the left queue feed to load the interactive platform embed preview.
                </p>
              </div>
            )}
          </div>

        </div>
      ) : (
        <div className="text-center p-24 bg-[#1E293B] border border-slate-800 rounded-xl shadow-xl">
          <CheckCircle className="w-14 h-14 text-emerald-500 mx-auto mb-4" />
          <h3 className="text-lg font-bold text-slate-200">Verification Queue Clear</h3>
          <p className="text-xs text-slate-500 max-w-md mx-auto mt-2 leading-relaxed">
            There are currently no training highlights or video links awaiting verification. Beautiful job! All uploaded video materials are successfully moderated.
          </p>
        </div>
      )}
    </div>
  );
}
