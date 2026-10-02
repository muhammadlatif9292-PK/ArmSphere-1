import React, { useState } from 'react';
import {
  Headphones,
  RefreshCw,
  Loader2,
  UserCheck,
  UserX,
  CheckCircle2,
  Send,
  Lock,
  MessageSquare,
  Tag,
} from 'lucide-react';
import {
  useSupportTickets,
  useSupportTicket,
  useAssignTicket,
  useUpdateTicketStatus,
  useAddTicketMessage,
} from '../lib/supportApi';
import { useAuth } from '../context/AuthContext';
import { SupportTicketStatus } from '../types';
import { LoadingCard, ErrorPanel, EmptyState } from '../components/ui';

function formatDateTime(value?: string | null): string {
  if (!value) return '--';
  try {
    return new Date(value).toLocaleString();
  } catch {
    return value;
  }
}

export default function SupportPage() {
  const { user } = useAuth();
  const [selectedStatus, setSelectedStatus] = useState<string>('ALL');
  const [selectedCategory, setSelectedCategory] = useState<string>('ALL');
  const [myAssignedOnly, setMyAssignedOnly] = useState<boolean>(false);
  const [activeTicketId, setActiveTicketId] = useState<string | null>(null);

  // Resolution modal state
  const [isResolveModalOpen, setIsResolveModalOpen] = useState(false);
  const [targetStatus, setTargetStatus] = useState<SupportTicketStatus>('RESOLVED');
  const [resolutionNotes, setResolutionNotes] = useState('');

  // Message composer state
  const [replyMessage, setReplyMessage] = useState('');
  const [isInternalNote, setIsInternalNote] = useState(false);

  const {
    data: tickets = [],
    isLoading,
    isError,
    error,
    refetch,
    isRefetching,
  } = useSupportTickets({
    status: selectedStatus,
    category: selectedCategory,
    myTicketsOnly: myAssignedOnly,
  });

  const {
    data: activeTicket,
    isLoading: isLoadingDetail,
  } = useSupportTicket(activeTicketId);

  const assignMutation = useAssignTicket();
  const statusMutation = useUpdateTicketStatus();
  const messageMutation = useAddTicketMessage();

  const handleAssignToMe = () => {
    if (!activeTicketId || !user) return;
    assignMutation.mutate({ ticketId: activeTicketId, agentId: user.id });
  };

  const handleUnassign = () => {
    if (!activeTicketId) return;
    assignMutation.mutate({ ticketId: activeTicketId, agentId: null });
  };

  const handleOpenResolveModal = (status: SupportTicketStatus) => {
    setTargetStatus(status);
    setResolutionNotes('');
    setIsResolveModalOpen(true);
  };

  const handleConfirmStatusUpdate = () => {
    if (!activeTicketId) return;
    statusMutation.mutate(
      {
        ticketId: activeTicketId,
        status: targetStatus,
        resolutionNotes: resolutionNotes.trim() ? resolutionNotes.trim() : undefined,
      },
      {
        onSuccess: () => {
          setIsResolveModalOpen(false);
        },
      }
    );
  };

  const handleSendMessage = (e: React.FormEvent) => {
    e.preventDefault();
    if (!activeTicketId || !replyMessage.trim()) return;

    messageMutation.mutate(
      {
        ticketId: activeTicketId,
        message: replyMessage.trim(),
        isInternal: isInternalNote,
      },
      {
        onSuccess: () => {
          setReplyMessage('');
          setIsInternalNote(false);
        },
      }
    );
  };

  const getStatusBadge = (status: SupportTicketStatus) => {
    switch (status) {
      case 'OPEN':
        return <span className="px-2 py-0.5 text-[11px] font-bold rounded bg-amber-500/10 text-amber-400 border border-amber-500/30">OPEN</span>;
      case 'IN_PROGRESS':
        return <span className="px-2 py-0.5 text-[11px] font-bold rounded bg-blue-500/10 text-blue-400 border border-blue-500/30">IN PROGRESS</span>;
      case 'RESOLVED':
        return <span className="px-2 py-0.5 text-[11px] font-bold rounded bg-emerald-500/10 text-emerald-400 border border-emerald-500/30">RESOLVED</span>;
      case 'CLOSED':
        return <span className="px-2 py-0.5 text-[11px] font-bold rounded bg-slate-500/10 text-slate-400 border border-slate-700">CLOSED</span>;
      default:
        return <span className="px-2 py-0.5 text-[11px] font-bold rounded bg-slate-800 text-slate-400">{status}</span>;
    }
  };

  const getPriorityBadge = (priority: string) => {
    switch (priority) {
      case 'URGENT':
      case 'HIGH':
        return <span className="px-1.5 py-0.5 text-[10px] font-extrabold rounded bg-red-500/20 text-red-400 border border-red-500/40">{priority}</span>;
      case 'LOW':
        return <span className="px-1.5 py-0.5 text-[10px] font-medium rounded bg-slate-800 text-slate-400">{priority}</span>;
      default:
        return <span className="px-1.5 py-0.5 text-[10px] font-medium rounded bg-slate-800 text-slate-300">NORMAL</span>;
    }
  };

  return (
    <div className="space-y-6" id="support-page-container">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl md:text-3xl font-display font-bold text-slate-100 tracking-tight flex items-center gap-2">
            <Headphones className="w-6 h-6 text-cyan-400" />
            Support Helpdesk
          </h1>
          <p className="text-sm text-slate-400 mt-1">
            Incoming customer support queries, athlete help requests, and technical tickets.
          </p>
        </div>
        <div className="flex items-center gap-3">
          <button
            onClick={() => refetch()}
            disabled={isRefetching}
            className="inline-flex items-center gap-2 px-3 py-2 text-xs font-medium text-slate-300 bg-slate-800/60 hover:bg-slate-800 border border-slate-700 rounded-lg transition-colors disabled:opacity-50"
          >
            {isRefetching ? <Loader2 className="w-4 h-4 animate-spin" /> : <RefreshCw className="w-4 h-4" />}
            Refresh
          </button>
        </div>
      </div>

      {/* Filter Toolbar */}
      <div className="p-4 bg-[#0F172A] border border-slate-800 rounded-xl flex flex-wrap items-center justify-between gap-4">
        {/* Status Pills */}
        <div className="flex flex-wrap items-center gap-1.5">
          {['ALL', 'OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'].map((st) => (
            <button
              key={st}
              onClick={() => setSelectedStatus(st)}
              className={`px-3 py-1.5 text-xs font-semibold rounded-lg transition-colors ${
                selectedStatus === st
                  ? 'bg-amber-500 text-slate-950 shadow-sm'
                  : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800'
              }`}
            >
              {st.replace('_', ' ')}
            </button>
          ))}
        </div>

        {/* Category & Assigned Filters */}
        <div className="flex flex-wrap items-center gap-3">
          <div className="flex items-center gap-2 text-xs text-slate-400">
            <Tag className="w-3.5 h-3.5 text-slate-500" />
            <select
              value={selectedCategory}
              onChange={(e) => setSelectedCategory(e.target.value)}
              className="bg-slate-900 border border-slate-700 rounded-lg px-2.5 py-1.5 text-xs text-slate-200 focus:outline-none focus:border-amber-500"
            >
              <option value="ALL">All Categories</option>
              <option value="GENERAL">General</option>
              <option value="EVENT">Tournament & Events</option>
              <option value="TECHNICAL">Technical / App</option>
              <option value="ACCOUNT">Account & Profile</option>
              <option value="DISPUTE">Dispute Question</option>
            </select>
          </div>

          <label className="flex items-center gap-2 text-xs text-slate-300 cursor-pointer select-none">
            <input
              type="checkbox"
              checked={myAssignedOnly}
              onChange={(e) => setMyAssignedOnly(e.target.checked)}
              className="rounded border-slate-700 text-amber-500 focus:ring-amber-500 bg-slate-900"
            />
            My Assigned Only
          </label>
        </div>
      </div>

      {/* Main Content Layout: Queue List + Detail Drawer */}
      {isLoading ? (
        <LoadingCard label="Loading support tickets queue..." />
      ) : isError ? (
        <ErrorPanel
          title="Failed to load support tickets"
          message={(error as Error)?.message || 'An error occurred while contacting the server.'}
          onRetry={() => refetch()}
        />
      ) : tickets.length === 0 ? (
        <EmptyState
          icon={Headphones}
          title="No support tickets found"
          subtitle="There are no tickets matching your current filter criteria."
        />
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
          {/* Ticket Queue List (5 columns on desktop) */}
          <div className="lg:col-span-5 space-y-3">
            <div className="text-xs font-semibold text-slate-400 uppercase tracking-wider px-1">
              Active Queue ({tickets.length})
            </div>
            <div className="space-y-2.5 max-h-[750px] overflow-y-auto pr-1">
              {tickets.map((ticket) => {
                const isSelected = activeTicketId === ticket.id;
                return (
                  <div
                    key={ticket.id}
                    onClick={() => setActiveTicketId(ticket.id)}
                    className={`p-4 rounded-xl border transition-all cursor-pointer ${
                      isSelected
                        ? 'bg-slate-900/90 border-amber-500/50 shadow-md ring-1 ring-amber-500/20'
                        : 'bg-[#0F172A]/70 border-slate-800 hover:border-slate-700 hover:bg-[#0F172A]'
                    }`}
                  >
                    <div className="flex items-start justify-between gap-2 mb-2">
                      <div className="flex items-center gap-2">
                        {getStatusBadge(ticket.status)}
                        {getPriorityBadge(ticket.priority)}
                      </div>
                      <span className="text-[11px] text-slate-500 font-mono">
                        {formatDateTime(ticket.createdAt)}
                      </span>
                    </div>

                    <h3 className="text-sm font-semibold text-slate-200 line-clamp-1 mb-1">
                      {ticket.subject}
                    </h3>
                    <p className="text-xs text-slate-400 line-clamp-2 mb-3">
                      {ticket.description}
                    </p>

                    <div className="flex items-center justify-between text-[11px] text-slate-400 pt-2 border-t border-slate-800/80">
                      <span className="font-medium text-slate-300 truncate max-w-[160px]">
                        {ticket.requester?.fullName || ticket.requester?.username || 'Requester'}
                      </span>
                      <span className="font-mono text-xs">
                        {ticket.assignedAgent ? (
                          <span className="text-blue-400 flex items-center gap-1">
                            <UserCheck className="w-3 h-3" />
                            {ticket.assignedAgent.fullName.split(' ')[0]}
                          </span>
                        ) : (
                          <span className="text-slate-500">Unassigned</span>
                        )}
                      </span>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Ticket Detail Panel (7 columns on desktop) */}
          <div className="lg:col-span-7">
            {!activeTicketId ? (
              <div className="h-full min-h-[400px] flex flex-col items-center justify-center p-8 bg-[#0F172A]/40 border border-slate-800 rounded-xl text-center">
                <MessageSquare className="w-12 h-12 text-slate-700 mb-3" />
                <p className="text-sm font-semibold text-slate-300">Select a Ticket</p>
                <p className="text-xs text-slate-500 max-w-sm mt-1">
                  Choose a support ticket from the active queue to view the conversation history, assign staff, or provide a resolution.
                </p>
              </div>
            ) : isLoadingDetail ? (
              <LoadingCard label="Loading ticket conversation..." />
            ) : !activeTicket ? (
              <ErrorPanel title="Ticket Details Unavailable" message="Could not find the requested ticket." />
            ) : (
              <div className="bg-[#0F172A] border border-slate-800 rounded-xl p-6 space-y-6">
                {/* Detail Header */}
                <div className="space-y-3 pb-4 border-b border-slate-800">
                  <div className="flex flex-wrap items-center justify-between gap-3">
                    <div className="flex items-center gap-2">
                      {getStatusBadge(activeTicket.status)}
                      {getPriorityBadge(activeTicket.priority)}
                      <span className="text-xs font-mono text-slate-500 uppercase tracking-wider">
                        {activeTicket.category}
                      </span>
                    </div>

                    {/* Action buttons */}
                    <div className="flex items-center gap-2">
                      {activeTicket.assignedAgentId === user?.id ? (
                        <button
                          onClick={handleUnassign}
                          disabled={assignMutation.isPending}
                          className="px-2.5 py-1 text-xs font-medium text-slate-300 hover:text-slate-100 bg-slate-800 rounded border border-slate-700 flex items-center gap-1.5 transition-colors"
                        >
                          <UserX className="w-3.5 h-3.5" />
                          Unassign
                        </button>
                      ) : (
                        <button
                          onClick={handleAssignToMe}
                          disabled={assignMutation.isPending}
                          className="px-2.5 py-1 text-xs font-bold text-slate-950 bg-amber-500 hover:bg-amber-400 rounded flex items-center gap-1.5 transition-colors"
                        >
                          <UserCheck className="w-3.5 h-3.5" />
                          Assign to Me
                        </button>
                      )}

                      {activeTicket.status !== 'RESOLVED' && activeTicket.status !== 'CLOSED' && (
                        <button
                          onClick={() => handleOpenResolveModal('RESOLVED')}
                          className="px-2.5 py-1 text-xs font-bold text-slate-950 bg-emerald-500 hover:bg-emerald-400 rounded flex items-center gap-1.5 transition-colors"
                        >
                          <CheckCircle2 className="w-3.5 h-3.5" />
                          Resolve
                        </button>
                      )}

                      {activeTicket.status === 'RESOLVED' && (
                        <button
                          onClick={() => handleOpenResolveModal('CLOSED')}
                          className="px-2.5 py-1 text-xs font-medium text-slate-300 bg-slate-800 hover:bg-slate-700 rounded border border-slate-700 transition-colors"
                        >
                          Close Ticket
                        </button>
                      )}
                    </div>
                  </div>

                  <h2 className="text-lg font-bold text-slate-100 leading-snug">
                    {activeTicket.subject}
                  </h2>

                  {/* Requester & Meta context card */}
                  <div className="p-3 bg-slate-900/70 border border-slate-800 rounded-lg flex flex-wrap items-center justify-between text-xs text-slate-400 gap-3">
                    <div>
                      <span className="text-slate-500">Requester: </span>
                      <span className="text-slate-200 font-semibold">
                        {activeTicket.requester?.fullName}
                      </span>{' '}
                      ({activeTicket.requester?.email})
                    </div>
                    <div>
                      <span className="text-slate-500">Assigned: </span>
                      <span className="text-blue-400 font-medium">
                        {activeTicket.assignedAgent?.fullName || 'None'}
                      </span>
                    </div>
                  </div>

                  {/* Original Description */}
                  <div className="p-3.5 bg-slate-950/60 border border-slate-800/80 rounded-lg text-xs text-slate-300 leading-relaxed font-sans">
                    <span className="text-[11px] font-semibold text-slate-500 uppercase block mb-1">
                      Initial Request Details:
                    </span>
                    {activeTicket.description}
                  </div>

                  {/* Resolution Notes Banner (if present) */}
                  {activeTicket.resolutionNotes && (
                    <div className="p-3.5 bg-emerald-500/10 border border-emerald-500/30 rounded-lg text-xs text-emerald-300 space-y-1">
                      <div className="flex items-center gap-1.5 font-bold">
                        <CheckCircle2 className="w-4 h-4 text-emerald-400" />
                        Resolution Notes
                      </div>
                      <p className="leading-relaxed">{activeTicket.resolutionNotes}</p>
                      <p className="text-[10px] text-emerald-400/70 font-mono pt-1">
                        Resolved by {activeTicket.resolver?.fullName || 'Staff'} on{' '}
                        {formatDateTime(activeTicket.resolvedAt)}
                      </p>
                    </div>
                  )}
                </div>

                {/* Conversation History */}
                <div className="space-y-3">
                  <div className="text-xs font-semibold text-slate-400 uppercase tracking-wider flex items-center gap-2">
                    <MessageSquare className="w-3.5 h-3.5 text-cyan-400" />
                    Conversation Thread ({(activeTicket.messages || []).length})
                  </div>

                  <div className="space-y-3 max-h-[360px] overflow-y-auto pr-1">
                    {(activeTicket.messages || []).length === 0 ? (
                      <div className="p-4 text-center text-xs text-slate-500 italic">
                        No responses yet. Write the first response below.
                      </div>
                    ) : (
                      activeTicket.messages?.map((msg) => (
                        <div
                          key={msg.id}
                          className={`p-3 rounded-xl border text-xs ${
                            msg.isInternal
                              ? 'bg-amber-500/10 border-amber-500/30 text-amber-200'
                              : 'bg-slate-900/60 border-slate-800 text-slate-200'
                          }`}
                        >
                          <div className="flex items-center justify-between text-[11px] mb-1.5">
                            <span className="font-semibold flex items-center gap-1.5">
                              {msg.isInternal && (
                                <span className="inline-flex items-center gap-1 px-1.5 py-0.2 rounded bg-amber-500/20 text-amber-400 font-extrabold text-[9px] uppercase tracking-wider">
                                  <Lock className="w-2.5 h-2.5" /> Staff Internal
                                </span>
                              )}
                              <span className={msg.isInternal ? 'text-amber-300' : 'text-slate-300'}>
                                {msg.sender?.fullName || msg.sender?.username || 'User'}
                              </span>
                              <span className="text-[10px] text-slate-500 font-mono">
                                ({msg.sender?.role || 'PARTICIPANT'})
                              </span>
                            </span>
                            <span className="text-slate-500 font-mono text-[10px]">
                              {formatDateTime(msg.createdAt)}
                            </span>
                          </div>
                          <p className="leading-relaxed whitespace-pre-wrap">{msg.message}</p>
                        </div>
                      ))
                    )}
                  </div>
                </div>

                {/* Message Reply Composer */}
                <form onSubmit={handleSendMessage} className="pt-2 border-t border-slate-800 space-y-3">
                  <div className="space-y-1.5">
                    <textarea
                      rows={3}
                      value={replyMessage}
                      onChange={(e) => setReplyMessage(e.target.value)}
                      placeholder="Write your response or internal note..."
                      className="w-full bg-slate-900 border border-slate-700 rounded-lg p-3 text-xs text-slate-100 placeholder-slate-500 focus:outline-none focus:border-amber-500"
                    />
                  </div>

                  <div className="flex items-center justify-between">
                    <label className="flex items-center gap-2 text-xs text-amber-400/90 cursor-pointer select-none">
                      <input
                        type="checkbox"
                        checked={isInternalNote}
                        onChange={(e) => setIsInternalNote(e.target.checked)}
                        className="rounded border-amber-600/50 text-amber-500 focus:ring-amber-500 bg-slate-900"
                      />
                      <span className="flex items-center gap-1 font-medium">
                        <Lock className="w-3 h-3" /> Internal staff note only (hidden from athlete)
                      </span>
                    </label>

                    <button
                      type="submit"
                      disabled={messageMutation.isPending || !replyMessage.trim()}
                      className="px-4 py-2 text-xs font-bold text-slate-950 bg-amber-500 hover:bg-amber-400 rounded-lg transition-colors flex items-center gap-1.5 disabled:opacity-50"
                    >
                      {messageMutation.isPending ? (
                        <Loader2 className="w-3.5 h-3.5 animate-spin" />
                      ) : (
                        <Send className="w-3.5 h-3.5" />
                      )}
                      Send Response
                    </button>
                  </div>
                </form>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Resolution Modal */}
      {isResolveModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/70 flex items-center justify-center p-4">
          <div className="bg-[#0F172A] border border-slate-800 rounded-2xl max-w-md w-full p-6 space-y-4 shadow-2xl">
            <h3 className="text-base font-bold text-slate-100 flex items-center gap-2">
              <CheckCircle2 className="w-5 h-5 text-emerald-400" />
              {targetStatus === 'RESOLVED' ? 'Resolve Support Ticket' : 'Close Support Ticket'}
            </h3>
            <p className="text-xs text-slate-400">
              Provide closure rationale for the requester. This will be visible to the athlete and recorded in the audit trail.
            </p>

            <div className="space-y-1.5">
              <label className="text-xs font-semibold text-slate-300">Resolution Summary / Notes</label>
              <textarea
                rows={4}
                value={resolutionNotes}
                onChange={(e) => setResolutionNotes(e.target.value)}
                placeholder="Explain the resolution or outcome of this ticket..."
                className="w-full bg-slate-900 border border-slate-700 rounded-lg p-3 text-xs text-slate-100 placeholder-slate-500 focus:outline-none focus:border-emerald-500"
              />
            </div>

            <div className="flex items-center justify-end gap-3 pt-2">
              <button
                type="button"
                onClick={() => setIsResolveModalOpen(false)}
                className="px-3 py-2 text-xs font-medium text-slate-300 hover:text-slate-100 bg-slate-800 rounded-lg"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={handleConfirmStatusUpdate}
                disabled={statusMutation.isPending}
                className="px-4 py-2 text-xs font-bold text-slate-950 bg-emerald-500 hover:bg-emerald-400 rounded-lg transition-colors flex items-center gap-1.5"
              >
                {statusMutation.isPending && <Loader2 className="w-3.5 h-3.5 animate-spin" />}
                Confirm {targetStatus}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
