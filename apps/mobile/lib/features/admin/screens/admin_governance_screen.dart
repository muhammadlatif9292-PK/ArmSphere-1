// lib/features/admin/screens/admin_governance_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/admin_provider.dart';
import '../../../core/security/admin_permissions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/crystal_glass_nav_controls.dart';
import '../../../core/widgets/crystal_stage_scaffold.dart';
import '../../../core/widgets/crystal_slash_painter.dart';
import '../../../core/widgets/crystal_toast.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/main_shell_screen.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/admin_crystal_widgets.dart';

/// Tab 4 (`Governance` — `/community/feed` in Admin Mode):
/// Arbitration Rulings, Community Video Moderation, Partner Gym Certification,
/// and Member Support Helpdesk with 4 segments:
/// 0. `Disputes` (Arbitration Rulings: Uphold/Overturn + Official Docket Closure)
/// 1. `Moderation` (Community Video Submissions: Approve & Publish / Reject & Remove)
/// 2. `Partner Gyms` (Official Training Venue Verification with Provincial Jurisdiction Lock)
/// 3. `Helpdesk` (Member Support Ticket Queue, Agent Assignment, Internal Notes & Resolution)
class AdminGovernanceScreen extends ConsumerStatefulWidget {
  const AdminGovernanceScreen({super.key});

  @override
  ConsumerState<AdminGovernanceScreen> createState() =>
      _AdminGovernanceScreenState();
}

class _AdminGovernanceScreenState extends ConsumerState<AdminGovernanceScreen> {
  final TextEditingController _disputeSearchCtrl = TextEditingController();
  final TextEditingController _venueSearchCtrl = TextEditingController();

  String _disputeSearch = '';
  String _disputeStatusFilter = '';
  String _venueSearch = '';
  String _venueVerifyFilter = ''; // '' | 'PENDING' | 'VERIFIED'
  String _supportStatusFilter = 'ALL';
  String _supportCategoryFilter = 'ALL';
  bool _myTicketsOnly = false;

  @override
  void dispose() {
    _disputeSearchCtrl.dispose();
    _venueSearchCtrl.dispose();
    super.dispose();
  }

  void _refreshSegment(int segment, AdminSupportFilter supportFilter) {
    if (segment == 0) {
      ref.invalidate(adminDisputesProvider);
    } else if (segment == 1) {
      ref.invalidate(adminPendingCommunityLinksProvider);
    } else if (segment == 2) {
      ref.invalidate(adminVenuesProvider);
    } else {
      ref.invalidate(adminSupportTicketsProvider(supportFilter));
    }
  }

  // ===========================================================================
  // DISPUTE ARBITRATION RULING BOTTOM SHEET
  // ===========================================================================
  Future<void> _openDisputeRulingSheet({
    required Map<String, dynamic> dispute,
    required bool canResolve,
  }) async {
    final String disputeId = dispute['id']?.toString() ?? '';
    final String matchId = dispute['matchId']?.toString() ?? 'Bout Docket';
    final String reason =
        dispute['reason']?.toString() ?? 'Official foul / call protest';
    final String status =
        (dispute['status'] ?? 'OPEN').toString().toUpperCase();
    final String evidenceUrl = dispute['evidenceUrl']?.toString() ?? '';

    final notesCtrl = TextEditingController(
      text: dispute['resolutionNotes']?.toString() ?? '',
    );
    String selectedRuling = 'RESOLVED_UPHELD';
    bool isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return CrystalModalSheet(
              title: 'DISPUTE ARBITRATION RULING',
              subtitle: 'Case #$disputeId • Match: $matchId • $status',
              headerIcon: Icons.gavel_rounded,
              primaryActionLabel: canResolve
                  ? (selectedRuling == 'RESOLVED_UPHELD'
                      ? 'Uphold Referee Call'
                      : 'Overturn Result & Recalc ELO')
                  : null,
              primaryActionIcon: Icons.verified_rounded,
              isPrimaryLoading: isSubmitting,
              secondaryActionLabel: 'Close',
              onPrimaryAction: !canResolve
                  ? null
                  : () async {
                      if (notesCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          CrystalSnackBar(
                            content: const Text(
                              'Arbitration resolution notes are mandatory.',
                            ),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                        return;
                      }
                      setSheetState(() => isSubmitting = true);
                      try {
                        await ref
                            .read(adminRepositoryProvider)
                            .resolveDispute(
                              disputeId: disputeId,
                              status: selectedRuling,
                              resolutionNotes: notesCtrl.text.trim(),
                            );
                        ref.invalidate(adminDisputesProvider);
                        ref.invalidate(adminDashboardStatsProvider);
                        await AdminCrossAppSync.syncDisputeMutations(ref);
                        if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            CrystalSnackBar(
                              content: Text(
                                'Dispute resolved: $selectedRuling',
                              ),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        }
                      } catch (e) {
                        setSheetState(() => isSubmitting = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            CrystalSnackBar(
                              content: Text('Ruling failed: $e'),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                        }
                      }
                    },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedActionCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PROTEST STATEMENT & EVIDENCE',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.goldPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          reason,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPure,
                            height: 1.4,
                          ),
                        ),
                        if (evidenceUrl.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          CrystalHeaderActionPill(
                            label: 'OPEN VIDEO EVIDENCE',
                            icon: Icons.play_circle_fill_rounded,
                            accentColor: AppTheme.info,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                CrystalSnackBar(
                                  content: Text(
                                    'Evidence URL: $evidenceUrl',
                                  ),
                                  backgroundColor: AppTheme.info,
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (canResolve) ...[
                    Row(
                      children: [
                        Expanded(
                          child: CrystalActionButton(
                            label: 'UPHOLD CALL',
                            icon: Icons.gavel_rounded,
                            isPrimary: selectedRuling == 'RESOLVED_UPHELD',
                            accentColor: AppTheme.success,
                            onTap: () => setSheetState(
                              () => selectedRuling = 'RESOLVED_UPHELD',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CrystalActionButton(
                            label: 'OVERTURN',
                            icon: Icons.swap_calls_rounded,
                            isPrimary: selectedRuling == 'RESOLVED_OVERTURNED',
                            accentColor: AppTheme.crimson,
                            onTap: () => setSheetState(
                              () => selectedRuling = 'RESOLVED_OVERTURNED',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 3,
                      style: const TextStyle(
                        color: AppTheme.textPure,
                        fontSize: 13.5,
                      ),
                      decoration: CrystalModalSheet.inputDecoration(
                        labelText: 'Official Arbitration Ruling Notes',
                        hintText:
                            'Document frame-by-frame evidence and WAF rule citation...',
                      ),
                    ),
                    if (status.startsWith('RESOLVED')) ...[
                      const SizedBox(height: 14),
                      CrystalActionButton(
                        label: 'CLOSE & ARCHIVE DISPUTE DOCKET',
                        icon: Icons.lock_outline_rounded,
                        fullWidth: true,
                        accentColor: AppTheme.info,
                        isLoading: isSubmitting,
                        onTap: () async {
                          setSheetState(() => isSubmitting = true);
                          try {
                            await ref
                                .read(adminRepositoryProvider)
                                .closeDispute(disputeId);
                            ref.invalidate(adminDisputesProvider);
                            await AdminCrossAppSync.syncDisputeMutations(ref);
                            if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                CrystalSnackBar(
                                  content: const Text(
                                    'Dispute docket closed and archived.',
                                  ),
                                  backgroundColor: AppTheme.success,
                                ),
                              );
                            }
                          } catch (e) {
                            setSheetState(() => isSubmitting = false);
                          }
                        },
                      ),
                    ],
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // SUPPORT HELPDESK TICKET CONVERSATION & RESOLUTION SHEET
  // ===========================================================================
  Future<void> _openSupportTicketSheet({
    required Map<String, dynamic> ticketSummary,
    required String? currentUserId,
    required AdminSupportFilter currentFilter,
  }) async {
    final String ticketId = ticketSummary['id']?.toString() ?? '';
    final String subject =
        ticketSummary['subject']?.toString() ?? 'Member Support Request';
    final replyCtrl = TextEditingController();
    final resolutionCtrl = TextEditingController();
    bool isInternalNote = false;
    bool isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Consumer(
          builder: (ctx, sheetRef, _) {
            final detailAsync =
                sheetRef.watch(adminSupportTicketDetailProvider(ticketId));
            final detail = detailAsync.valueOrNull ?? ticketSummary;
            final String status =
                (detail['status'] ?? 'OPEN').toString().toUpperCase();
            final String? assignedId = detail['assignedAgentId']?.toString();
            final messages = (detail['messages'] is List)
                ? (detail['messages'] as List)
                    .whereType<Map>()
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList()
                : const <Map<String, dynamic>>[];

            return StatefulBuilder(
              builder: (sCtx, setSheetState) {
                Future<void> performTicketAction(
                  Future<void> Function() action,
                  String toastMsg,
                ) async {
                  setSheetState(() => isSubmitting = true);
                  try {
                    await action();
                    ref.invalidate(adminSupportTicketDetailProvider(ticketId));
                    ref.invalidate(adminSupportTicketsProvider(currentFilter));
                    await AdminCrossAppSync.syncSupportMutations(ref);
                    setSheetState(() => isSubmitting = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        CrystalSnackBar(
                          content: Text(toastMsg),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                    }
                  } catch (e) {
                    setSheetState(() => isSubmitting = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        CrystalSnackBar(
                          content: Text('Ticket update failed: $e'),
                          backgroundColor: AppTheme.error,
                        ),
                      );
                    }
                  }
                }

                return CrystalModalSheet(
                  title: 'SUPPORT TICKET CONSOLE',
                  subtitle: '$subject • Status: $status',
                  headerIcon: Icons.support_agent_rounded,
                  primaryActionLabel: isInternalNote
                      ? 'Save Internal Staff Note'
                      : 'Send Official Reply',
                  primaryActionIcon: isInternalNote
                      ? Icons.lock_rounded
                      : Icons.send_rounded,
                  isPrimaryLoading: isSubmitting,
                  secondaryActionLabel: 'Close',
                  onPrimaryAction: () async {
                    if (replyCtrl.text.trim().isEmpty) return;
                    final text = replyCtrl.text.trim();
                    replyCtrl.clear();
                    await performTicketAction(
                      () => ref
                          .read(adminRepositoryProvider)
                          .addSupportTicketMessage(
                            ticketId: ticketId,
                            message: text,
                            isInternal: isInternalNote,
                          ),
                      isInternalNote
                          ? 'Internal staff note recorded'
                          : 'Reply sent to member',
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Quick Assignment & Lifecycle Controls
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (currentUserId != null &&
                              assignedId != currentUserId)
                            CrystalHeaderActionPill(
                              label: 'ASSIGN TO ME',
                              icon: Icons.person_add_alt_1_rounded,
                              accentColor: AppTheme.goldPrimary,
                              onTap: () => performTicketAction(
                                () => ref
                                    .read(adminRepositoryProvider)
                                    .assignSupportTicket(
                                      ticketId: ticketId,
                                      agentId: currentUserId,
                                    ),
                                'Assigned ticket to you',
                              ),
                            ),
                          if (assignedId != null && assignedId.isNotEmpty)
                            CrystalHeaderActionPill(
                              label: 'UNASSIGN',
                              icon: Icons.person_remove_rounded,
                              accentColor: AppTheme.warning,
                              onTap: () => performTicketAction(
                                () => ref
                                    .read(adminRepositoryProvider)
                                    .assignSupportTicket(
                                      ticketId: ticketId,
                                      agentId: null,
                                    ),
                                'Unassigned ticket',
                              ),
                            ),
                          if (status != 'RESOLVED')
                            CrystalHeaderActionPill(
                              label: 'MARK RESOLVED',
                              icon: Icons.check_circle_rounded,
                              accentColor: AppTheme.success,
                              onTap: () => performTicketAction(
                                () => ref
                                    .read(adminRepositoryProvider)
                                    .updateSupportTicketStatus(
                                      ticketId: ticketId,
                                      status: 'RESOLVED',
                                      resolutionNotes:
                                          resolutionCtrl.text.trim().isEmpty
                                              ? 'Resolved by Federation Support'
                                              : resolutionCtrl.text.trim(),
                                    ),
                                'Ticket marked RESOLVED',
                              ),
                            ),
                          if (status != 'CLOSED')
                            CrystalHeaderActionPill(
                              label: 'CLOSE TICKET',
                              icon: Icons.archive_rounded,
                              accentColor: AppTheme.crimson,
                              onTap: () => performTicketAction(
                                () => ref
                                    .read(adminRepositoryProvider)
                                    .updateSupportTicketStatus(
                                      ticketId: ticketId,
                                      status: 'CLOSED',
                                    ),
                                'Ticket closed',
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Thread Messages
                      const Text(
                        'CONVERSATION & INTERNAL AUDIT THREAD',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppTheme.goldPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (messages.isEmpty)
                        ElevatedActionCard(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            detail['description']?.toString() ??
                                'No messages posted yet.',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        )
                      else
                        ...messages.map((m) {
                          final internal = m['isInternal'] == true;
                          final body = m['message']?.toString() ??
                              m['content']?.toString() ??
                              '';
                          final sender = m['senderName']?.toString() ??
                              (internal ? 'Staff Internal Note' : 'Member');
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ElevatedActionCard(
                              padding: const EdgeInsets.all(12),
                              borderColor: internal
                                  ? AppTheme.goldPrimary.withValues(alpha: 0.5)
                                  : null,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        sender,
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: internal
                                              ? AppTheme.goldPrimary
                                              : AppTheme.textPure,
                                        ),
                                      ),
                                      if (internal)
                                        const StatusChip.warning(
                                          label: 'INTERNAL NOTE',
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    body,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      const SizedBox(height: 12),

                      // Reply Mode Toggle (Public vs Internal Staff Note)
                      Row(
                        children: [
                          Expanded(
                            child: CrystalActionButton(
                              label: 'PUBLIC REPLY',
                              icon: Icons.reply_rounded,
                              isPrimary: !isInternalNote,
                              accentColor: AppTheme.info,
                              onTap: () =>
                                  setSheetState(() => isInternalNote = false),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CrystalActionButton(
                              label: 'INTERNAL STAFF NOTE',
                              icon: Icons.lock_rounded,
                              isPrimary: isInternalNote,
                              accentColor: AppTheme.goldPrimary,
                              onTap: () =>
                                  setSheetState(() => isInternalNote = true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: replyCtrl,
                        maxLines: 3,
                        style: const TextStyle(
                          color: AppTheme.textPure,
                          fontSize: 13.5,
                        ),
                        decoration: CrystalModalSheet.inputDecoration(
                          labelText: isInternalNote
                              ? 'Internal Staff Note (Hidden from Member)'
                              : 'Official Support Response',
                          hintText: 'Write message...',
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final activeRole = (authState.activeRole ??
            authState.userProfile?['role']?.toString() ??
            'SYSTEM_ADMIN')
        .toUpperCase();
    final jurisdiction =
        AdminPermissions.resolveJurisdiction(authState.userProfile);
    final currentUserId = authState.userProfile?['id']?.toString();

    final selectedSegment = ref.watch(adminGovernanceSegmentProvider);

    final supportFilter = AdminSupportFilter(
      status: _supportStatusFilter,
      category: _supportCategoryFilter,
      myTicketsOnly: _myTicketsOnly,
      currentUserId: currentUserId,
    );

    final disputesAsync = ref.watch(adminDisputesProvider);
    final pendingLinksAsync = ref.watch(adminPendingCommunityLinksProvider);
    final venuesAsync = ref.watch(adminVenuesProvider);
    final ticketsAsync = ref.watch(adminSupportTicketsProvider(supportFilter));

    final bool insideRootShell = MainShellScope.isInsideShell(context);
    final double bottomDockGap = insideRootShell
        ? (kFloatingDockTotalHeight + MediaQuery.paddingOf(context).bottom + 10.0)
        : 12.0;

    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: CrystalStageBackdrop(domain: ArmSphereStageDomain.governance),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AdminAuthorityHeader(
                    title: 'Federation Governance',
                    subtitle:
                        'Arbitration dockets, video moderation, partner gyms, and member helpdesk',
                    activeRole: activeRole,
                    jurisdiction: jurisdiction,
                    onRefresh: () =>
                        _refreshSegment(selectedSegment, supportFilter),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: CrystalVaporDissolve(
                    bottomMargin: bottomDockGap,
                    child: RefreshIndicator(
                      color: AppTheme.goldPrimary,
                      backgroundColor: AppTheme.cardSurface,
                      onRefresh: () async =>
                          _refreshSegment(selectedSegment, supportFilter),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          12,
                          16,
                          28,
                        ),
                        children: [
                          AdminSegmentedDeck(
                            selectedIndex: selectedSegment,
                            onChanged: (idx) => ref
                                .read(adminGovernanceSegmentProvider.notifier)
                                .state = idx,
                            segments: [
                              AdminSegmentItem(
                                label: 'Disputes',
                                icon: Icons.gavel_rounded,
                                count: disputesAsync.valueOrNull?.length,
                              ),
                              AdminSegmentItem(
                                label: 'Moderation',
                                icon: Icons.ondemand_video_rounded,
                                count: pendingLinksAsync.valueOrNull?.length,
                              ),
                              AdminSegmentItem(
                                label: 'Gyms',
                                icon: Icons.fitness_center_rounded,
                                count: venuesAsync.valueOrNull?.length,
                              ),
                              AdminSegmentItem(
                                label: 'Helpdesk',
                                icon: Icons.support_agent_rounded,
                                count: ticketsAsync.valueOrNull?.length,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          if (selectedSegment == 0)
                            _buildDisputesSegment(
                              disputesAsync: disputesAsync,
                              activeRole: activeRole,
                            )
                          else if (selectedSegment == 1)
                            _buildModerationSegment(
                              pendingLinksAsync: pendingLinksAsync,
                              activeRole: activeRole,
                            )
                          else if (selectedSegment == 2)
                            _buildPartnerGymsSegment(
                              venuesAsync: venuesAsync,
                              activeRole: activeRole,
                              jurisdiction: jurisdiction,
                            )
                          else
                            _buildHelpdeskSegment(
                              ticketsAsync: ticketsAsync,
                              currentUserId: currentUserId,
                              supportFilter: supportFilter,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisputesSegment({
    required AsyncValue<List<Map<String, dynamic>>> disputesAsync,
    required String activeRole,
  }) {
    final allDisputes =
        disputesAsync.valueOrNull ?? const <Map<String, dynamic>>[];
    final filtered = allDisputes.where((d) {
      final reason = (d['reason'] ?? '').toString().toLowerCase();
      final status = (d['status'] ?? 'OPEN').toString().toUpperCase();
      final matchesSearch =
          _disputeSearch.isEmpty || reason.contains(_disputeSearch.toLowerCase());
      final matchesStatus =
          _disputeStatusFilter.isEmpty || status == _disputeStatusFilter;
      return matchesSearch && matchesStatus;
    }).toList();

    final canResolve = AdminPermissions.canPerform(
      activeRole,
      AdminAction.resolveDispute,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminCrystalSearchBar(
          controller: _disputeSearchCtrl,
          hintText: 'Search arbitration dockets by protest reason...',
          onChanged: (v) => setState(() => _disputeSearch = v),
          onClear: () {
            _disputeSearchCtrl.clear();
            setState(() => _disputeSearch = '');
          },
          filterOptions: const [
            '',
            'OPEN',
            'UNDER_REVIEW',
            'RESOLVED_UPHELD',
            'RESOLVED_OVERTURNED',
            'CLOSED',
          ],
          selectedFilter: _disputeStatusFilter,
          onFilterSelected: (f) => setState(() => _disputeStatusFilter = f),
        ),
        const SizedBox(height: 14),
        if (filtered.isEmpty)
          const AppEmptyState(
            icon: Icons.gavel_rounded,
            title: 'No Match Disputes in Docket',
            description:
                'Official bout protests and video challenges appear here for arbitration rulings.',
          )
        else
          ...filtered.map((dispute) {
            final id = dispute['id']?.toString() ?? '';
            final reason =
                dispute['reason']?.toString() ?? 'Bout protest submitted';
            final status =
                (dispute['status'] ?? 'OPEN').toString().toUpperCase();

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ElevatedActionCard(
                onTap: () => _openDisputeRulingSheet(
                  dispute: dispute,
                  canResolve: canResolve,
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'CASE #${id.length > 8 ? id.substring(0, 8) : id}',
                          style: const TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.goldPrimary,
                          ),
                        ),
                        status == 'OPEN'
                            ? const StatusChip.warning(label: 'OPEN')
                            : StatusChip.info(label: status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      reason,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPure,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildModerationSegment({
    required AsyncValue<List<Map<String, dynamic>>> pendingLinksAsync,
    required String activeRole,
  }) {
    final links =
        pendingLinksAsync.valueOrNull ?? const <Map<String, dynamic>>[];
    final canModerate = AdminPermissions.canPerform(
      activeRole,
      AdminAction.moderateCommunity,
    );

    if (links.isEmpty) {
      return const AppEmptyState(
        icon: Icons.verified_rounded,
        title: 'Community Video Queue Clear',
        description:
            'All athlete external video clips (YouTube, Instagram, TikTok) have been reviewed.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...links.map((post) {
          final postId = post['id']?.toString() ?? '';
          final author = post['authorName']?.toString() ??
              (post['author'] is Map
                  ? post['author']['displayName']?.toString()
                  : null) ??
              'Community Athlete';
          final caption = post['content']?.toString() ??
              post['caption']?.toString() ??
              'Submitted training / match clip';
          final videoUrl = post['externalVideoUrl']?.toString() ??
              post['videoUrl']?.toString() ??
              '';
          final platform =
              (post['videoPlatform'] ?? 'VIDEO').toString().toUpperCase();

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ElevatedActionCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        author,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPure,
                        ),
                      ),
                      StatusChip.info(label: platform),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    caption,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (videoUrl.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      videoUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.info,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (videoUrl.isNotEmpty)
                        CrystalHeaderActionPill(
                          label: 'OPEN SOURCE CLIP',
                          icon: Icons.open_in_new_rounded,
                          accentColor: AppTheme.info,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              CrystalSnackBar(
                                content: Text(
                                  'Source clip URL: $videoUrl',
                                ),
                                backgroundColor: AppTheme.info,
                              ),
                            );
                          },
                        ),
                      if (canModerate && postId.isNotEmpty) ...[
                        CrystalHeaderActionPill(
                          label: 'APPROVE & PUBLISH',
                          icon: Icons.check_circle_rounded,
                          accentColor: AppTheme.success,
                          onTap: () async {
                            await ref
                                .read(adminRepositoryProvider)
                                .moderateCommunityLink(
                                  postId: postId,
                                  decision: 'APPROVED',
                                );
                            ref.invalidate(adminPendingCommunityLinksProvider);
                            await AdminCrossAppSync.syncCommunityMutations(ref);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                CrystalSnackBar(
                                  content: const Text(
                                    'Video clip approved and published to Community Feed.',
                                  ),
                                  backgroundColor: AppTheme.success,
                                ),
                              );
                            }
                          },
                        ),
                        CrystalHeaderActionPill(
                          label: 'REJECT',
                          icon: Icons.cancel_rounded,
                          accentColor: AppTheme.crimson,
                          onTap: () async {
                            await ref
                                .read(adminRepositoryProvider)
                                .moderateCommunityLink(
                                  postId: postId,
                                  decision: 'REJECTED',
                                );
                            ref.invalidate(adminPendingCommunityLinksProvider);
                            await AdminCrossAppSync.syncCommunityMutations(ref);
                          },
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPartnerGymsSegment({
    required AsyncValue<List<Map<String, dynamic>>> venuesAsync,
    required String activeRole,
    required String? jurisdiction,
  }) {
    final allVenues = venuesAsync.valueOrNull ?? const <Map<String, dynamic>>[];
    final filtered = allVenues.where((v) {
      final name = (v['name'] ?? '').toString().toLowerCase();
      final city = (v['city'] ?? v['province'] ?? '').toString().toLowerCase();
      final isVerified = v['isVerified'] == true;
      final matchesSearch = _venueSearch.isEmpty ||
          name.contains(_venueSearch.toLowerCase()) ||
          city.contains(_venueSearch.toLowerCase());
      final matchesFilter = _venueVerifyFilter.isEmpty ||
          (_venueVerifyFilter == 'VERIFIED' && isVerified) ||
          (_venueVerifyFilter == 'PENDING' && !isVerified);
      return matchesSearch && matchesFilter;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminCrystalSearchBar(
          controller: _venueSearchCtrl,
          hintText: 'Search partner gyms & arm-wrestling clubs...',
          onChanged: (v) => setState(() => _venueSearch = v),
          onClear: () {
            _venueSearchCtrl.clear();
            setState(() => _venueSearch = '');
          },
          filterOptions: const ['', 'PENDING', 'VERIFIED'],
          selectedFilter: _venueVerifyFilter,
          onFilterSelected: (f) => setState(() => _venueVerifyFilter = f),
        ),
        const SizedBox(height: 14),
        if (filtered.isEmpty)
          const AppEmptyState(
            icon: Icons.fitness_center_rounded,
            title: 'No Partner Gyms Match Filter',
            description:
                'Submitted training gyms and clubs appear here for official federation verification.',
          )
        else
          ...filtered.map((venue) {
            final venueId = venue['id']?.toString() ?? '';
            final name = venue['name']?.toString() ?? 'Partner Gym';
            final city = venue['city']?.toString() ?? '';
            final province = venue['province']?.toString() ?? '';
            final tablesCount =
                venue['tableCount'] ?? venue['tablesCount'] ?? 1;
            final isVerified = venue['isVerified'] == true;

            final canVerify = AdminPermissions.canPerform(
              activeRole,
              AdminAction.verifyVenue,
              jurisdiction: jurisdiction,
              targetProvince: province,
            );

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ElevatedActionCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPure,
                            ),
                          ),
                        ),
                        isVerified
                            ? const StatusChip.success(label: 'OFFICIAL GYM')
                            : const StatusChip.warning(label: 'UNVERIFIED'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$city${province.isNotEmpty ? ", $province" : ""} • $tablesCount Pro Tables',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (!isVerified && canVerify && venueId.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      CrystalHeaderActionPill(
                        label: 'APPROVE OFFICIAL PARTNER GYM',
                        icon: Icons.verified_rounded,
                        accentColor: AppTheme.goldPrimary,
                        onTap: () async {
                          await ref
                              .read(adminRepositoryProvider)
                              .verifyVenue(venueId);
                          ref.invalidate(adminVenuesProvider);
                          await AdminCrossAppSync.syncVenueMutations(ref);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              CrystalSnackBar(
                                content: Text('Verified partner gym "$name"'),
                                backgroundColor: AppTheme.success,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildHelpdeskSegment({
    required AsyncValue<List<Map<String, dynamic>>> ticketsAsync,
    required String? currentUserId,
    required AdminSupportFilter supportFilter,
  }) {
    final tickets =
        ticketsAsync.valueOrNull ?? const <Map<String, dynamic>>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final st in const [
                'ALL',
                'OPEN',
                'IN_PROGRESS',
                'RESOLVED',
                'CLOSED',
              ]) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CrystalHeaderActionPill(
                    label: st.replaceAll('_', ' '),
                    accentColor: _supportStatusFilter == st
                        ? AppTheme.goldPrimary
                        : AppTheme.textMuted,
                    onTap: () => setState(() => _supportStatusFilter = st),
                  ),
                ),
              ],
              CrystalHeaderActionPill(
                label: _myTicketsOnly ? 'MY ASSIGNED ONLY ✓' : 'MY ASSIGNED',
                icon: Icons.person_pin_rounded,
                accentColor:
                    _myTicketsOnly ? AppTheme.crimson : AppTheme.info,
                onTap: () => setState(() => _myTicketsOnly = !_myTicketsOnly),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (tickets.isEmpty)
          const AppEmptyState(
            icon: Icons.support_agent_rounded,
            title: 'No Support Tickets in Queue',
            description:
                'Member inquiries, account recovery requests, and event support tickets appear here.',
          )
        else
          ...tickets.map((t) {
            final subject =
                t['subject']?.toString() ?? 'Member Support Ticket';
            final category = t['category']?.toString() ?? 'GENERAL';
            final status = (t['status'] ?? 'OPEN').toString().toUpperCase();
            final priority =
                (t['priority'] ?? 'NORMAL').toString().toUpperCase();

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ElevatedActionCard(
                onTap: () => _openSupportTicketSheet(
                  ticketSummary: t,
                  currentUserId: currentUserId,
                  currentFilter: supportFilter,
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$category • $priority PRIORITY',
                          style: const TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.goldPrimary,
                          ),
                        ),
                        status == 'RESOLVED' || status == 'CLOSED'
                            ? StatusChip.success(label: status)
                            : StatusChip.warning(label: status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subject,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPure,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
