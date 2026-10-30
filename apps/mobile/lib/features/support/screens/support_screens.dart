import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/providers/support_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/error_formatter.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/skeleton_placeholder.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/sticky_form_scaffold.dart';
import '../../auth/providers/auth_provider.dart';

bool _isSupportStaff(AuthState authState) {
  final activeRole = authState.activeRole?.toUpperCase();
  final profileRole = authState.userProfile?['role']?.toString().toUpperCase();
  final roles = <String>{
    ...authState.verifiedRoles.map((r) => r.toUpperCase()),
    if (activeRole != null) activeRole,
    if (profileRole != null) profileRole,
  };
  return roles.contains('SUPPORT_AGENT') || roles.contains('SYSTEM_ADMIN');
}

StatusType _ticketStatusType(String status) {
  switch (status.toUpperCase()) {
    case 'RESOLVED':
      return StatusType.success;
    case 'IN_PROGRESS':
    case 'OPEN':
      return StatusType.warning;
    case 'WAITING_ON_USER':
      return StatusType.info;
    case 'CLOSED':
    default:
      return StatusType.neutral;
  }
}

/// Support Tickets List Screen — serves both Athletes (own tickets) and Support Agents (full helpdesk queue).
class SupportTicketsScreen extends ConsumerStatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  ConsumerState<SupportTicketsScreen> createState() =>
      _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends ConsumerState<SupportTicketsScreen> {
  String? _statusFilter;

  static const _filters = <Map<String, String?>>[
    {'label': 'ALL', 'value': null},
    {'label': 'OPEN', 'value': 'OPEN'},
    {'label': 'IN PROGRESS', 'value': 'IN_PROGRESS'},
    {'label': 'RESOLVED', 'value': 'RESOLVED'},
    {'label': 'CLOSED', 'value': 'CLOSED'},
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isStaff = _isSupportStaff(authState);
    final ticketsAsync = ref.watch(supportTicketsProvider(_statusFilter));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardSurface,
        elevation: 0,
        title: Text(
          isStaff ? 'Helpdesk Triage Queue' : 'Support & Helpdesk',
          style: const TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: InkWell(
                key: const ValueKey('support_new_ticket_button'),
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/support/create');
                },
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.goldPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(color: AppTheme.goldPrimary, width: 1.0),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_comment_outlined,
                          size: 14, color: AppTheme.goldPrimary),
                      SizedBox(width: 4),
                      Text(
                        'NEW TICKET',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.goldPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status filter bar
          Container(
            height: 48,
            color: AppTheme.cardSurface,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = _filters[index];
                final selected = _statusFilter == item['value'];
                return Center(
                  child: ChoiceChip(
                    label: Text(
                      item['label']!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: selected
                            ? AppTheme.voidBackground
                            : AppTheme.textSecondary,
                      ),
                    ),
                    selected: selected,
                    selectedColor: AppTheme.goldPrimary,
                    backgroundColor: AppTheme.elevatedSurface,
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      setState(() => _statusFilter = item['value']);
                    },
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),
          Expanded(
            child: ticketsAsync.when(
              loading: () => ListView.separated(
                padding: const EdgeInsets.all(AppTheme.space16),
                itemCount: 3,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppTheme.space12),
                itemBuilder: (_, __) => const SkeletonPlaceholder(
                  height: 96,
                  borderRadius: AppTheme.radiusMedium,
                ),
              ),
              error: (error, _) => AppErrorView(
                error: error,
                title: 'Could not load support tickets',
                onRetry: () =>
                    ref.invalidate(supportTicketsProvider(_statusFilter)),
              ),
              data: (tickets) {
                if (tickets.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.support_agent_outlined,
                    title: isStaff
                        ? 'No tickets in queue'
                        : 'No support requests yet',
                    subtitle: isStaff
                        ? 'There are no support tickets matching the current status filter.'
                        : 'Need help with a tournament registration, match verification, or account issue? Open a ticket with the ArmSphere Helpdesk.',
                    ctaLabel: 'Open Support Ticket',
                    onCtaTap: () => context.push('/support/create'),
                  );
                }

                return RefreshIndicator(
                  color: AppTheme.goldPrimary,
                  backgroundColor: AppTheme.cardSurface,
                  onRefresh: () async =>
                      ref.invalidate(supportTicketsProvider(_statusFilter)),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    itemCount: tickets.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppTheme.space12),
                    itemBuilder: (context, index) {
                      final ticket = tickets[index];
                      final status =
                          (ticket['status']?.toString() ?? 'OPEN').toUpperCase();
                      final category =
                          (ticket['category']?.toString() ?? 'GENERAL')
                              .toUpperCase();
                      final priority =
                          (ticket['priority']?.toString() ?? 'MEDIUM')
                              .toUpperCase();
                      final assignedAgentId =
                          ticket['assignedAgentId']?.toString();

                      return ElevatedActionCard(
                        padding: const EdgeInsets.all(AppTheme.space16),
                        onTap: () => context.push('/support/${ticket['id']}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    ticket['subject']?.toString() ??
                                        'Support Request',
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppTheme.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                StatusChip(
                                  label: status,
                                  type: _ticketStatusType(status),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              ticket['description']?.toString() ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.elevatedSurface,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppTheme.border),
                                  ),
                                  child: Text(
                                    category,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.goldLight,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Priority: $priority',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                                const Spacer(),
                                if (isStaff)
                                  Text(
                                    assignedAgentId != null
                                        ? 'Assigned'
                                        : 'Unassigned',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: assignedAgentId != null
                                          ? AppTheme.goldPrimary
                                          : AppTheme.warning,
                                    ),
                                  ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: AppTheme.textMuted,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Create Support Ticket Screen — submits POST /support/tickets.
class CreateSupportTicketScreen extends ConsumerStatefulWidget {
  const CreateSupportTicketScreen({super.key});

  @override
  ConsumerState<CreateSupportTicketScreen> createState() =>
      _CreateSupportTicketScreenState();
}

class _CreateSupportTicketScreenState
    extends ConsumerState<CreateSupportTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _category = 'GENERAL';
  String _priority = 'MEDIUM';
  bool _isSubmitting = false;

  static const _categories = <String>[
    'GENERAL',
    'ACCOUNT',
    'MATCH',
    'DISPUTE',
    'EVENT',
    'BILLING',
    'TECHNICAL',
  ];

  static const _priorities = <String>[
    'LOW',
    'MEDIUM',
    'HIGH',
    'URGENT',
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final created = await ref
          .read(supportTicketsProvider(null).notifier)
          .createTicket(
            subject: _subjectController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _category,
            priority: _priority,
          );
      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Support ticket submitted to ArmSphere Helpdesk'),
            backgroundColor: AppTheme.success,
          ),
        );
        context.replace('/support/${created['id']}');
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppErrorFormatter.format(e)),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StickyFormScaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardSurface,
        elevation: 0,
        title: const Text(
          'Open Support Ticket',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      primaryActionLabel: 'SUBMIT SUPPORT REQUEST',
      primaryActionIcon: Icons.send_outlined,
      isLoading: _isSubmitting,
      onPrimaryAction: _isSubmitting ? null : _submit,
      formKey: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedActionCard(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  dropdownColor: AppTheme.elevatedSurface,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Category',
                    filled: true,
                    fillColor: AppTheme.elevatedSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _category = val);
                  },
                ),
                const SizedBox(height: AppTheme.space16),
                DropdownButtonFormField<String>(
                  initialValue: _priority,
                  dropdownColor: AppTheme.elevatedSurface,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Priority',
                    filled: true,
                    fillColor: AppTheme.elevatedSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                  items: _priorities
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _priority = val);
                  },
                ),
                const SizedBox(height: AppTheme.space16),
                TextFormField(
                  key: const ValueKey('support_subject_input'),
                  controller: _subjectController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Subject',
                    hintText: 'Brief summary of your issue',
                    filled: true,
                    fillColor: AppTheme.elevatedSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().length < 3) {
                      return 'Subject must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.space16),
                TextFormField(
                  key: const ValueKey('support_description_input'),
                  controller: _descriptionController,
                  maxLines: 5,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText:
                        'Provide relevant details, match IDs, or event names...',
                    filled: true,
                    fillColor: AppTheme.elevatedSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().length < 5) {
                      return 'Please describe your issue in at least 5 characters';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Support Ticket Detail & Thread Screen — supports both Requester and Support Agent workflows.
class SupportTicketDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;

  const SupportTicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<SupportTicketDetailScreen> createState() =>
      _SupportTicketDetailScreenState();
}

class _SupportTicketDetailScreenState
    extends ConsumerState<SupportTicketDetailScreen> {
  final _replyController = TextEditingController();
  bool _isInternalNote = false;
  bool _busy = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action,
      {String? successMessage}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted && successMessage != null) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.detail), backgroundColor: AppTheme.error),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppErrorFormatter.format(e)),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _busy) return;
    await _run(
      () async {
        await ref
            .read(supportTicketDetailProvider(widget.ticketId).notifier)
            .addMessage(text, isInternal: _isInternalNote);
        _replyController.clear();
        setState(() => _isInternalNote = false);
      },
      successMessage:
          _isInternalNote ? 'Internal note recorded' : 'Reply posted',
    );
  }

  Future<void> _promptResolveTicket() async {
    final notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        title: const Text(
          'Resolve Support Ticket',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        content: TextField(
          controller: notesController,
          maxLines: 3,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Resolution Notes',
            hintText: 'Summarize how this issue was resolved...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.goldPrimary,
              foregroundColor: AppTheme.voidBackground,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Mark Resolved'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(
      () => ref
          .read(supportTicketDetailProvider(widget.ticketId).notifier)
          .updateStatus('RESOLVED',
              resolutionNotes: notesController.text.trim()),
      successMessage: 'Ticket marked as RESOLVED',
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isStaff = _isSupportStaff(authState);
    final currentUserId = authState.userProfile?['id']?.toString();
    final detailAsync = ref.watch(supportTicketDetailProvider(widget.ticketId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardSurface,
        elevation: 0,
        title: const Text(
          'Support Ticket',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: detailAsync.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(AppTheme.space16),
          children: const [
            SkeletonPlaceholder(height: 140, borderRadius: AppTheme.radiusMedium),
            SizedBox(height: AppTheme.space16),
            SkeletonPlaceholder(height: 80, borderRadius: AppTheme.radiusMedium),
          ],
        ),
        error: (error, _) => AppErrorView(
          error: error,
          title: 'Could not load support ticket',
          onRetry: () =>
              ref.invalidate(supportTicketDetailProvider(widget.ticketId)),
        ),
        data: (ticket) {
          final status =
              (ticket['status']?.toString() ?? 'OPEN').toUpperCase();
          final category =
              (ticket['category']?.toString() ?? 'GENERAL').toUpperCase();
          final priority =
              (ticket['priority']?.toString() ?? 'MEDIUM').toUpperCase();
          final resolutionNotes = ticket['resolutionNotes']?.toString();
          final messages = (ticket['messages'] as List?) ?? const [];

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  color: AppTheme.goldPrimary,
                  backgroundColor: AppTheme.cardSurface,
                  onRefresh: () async => ref.invalidate(
                      supportTicketDetailProvider(widget.ticketId)),
                  child: ListView(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    children: [
                      // Ticket Summary Card
                      ElevatedActionCard(
                        padding: const EdgeInsets.all(AppTheme.space16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    ticket['subject']?.toString() ??
                                        'Support Request',
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                StatusChip(
                                  label: status,
                                  type: _ticketStatusType(status),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.space8),
                            Text(
                              ticket['description']?.toString() ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: AppTheme.space12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                StatusChip(
                                    label: category, type: StatusType.neutral),
                                StatusChip(
                                  label: 'PRIORITY: $priority',
                                  type: priority == 'URGENT' ||
                                          priority == 'HIGH'
                                      ? StatusType.warning
                                      : StatusType.neutral,
                                ),
                              ],
                            ),
                            if (resolutionNotes != null &&
                                resolutionNotes.isNotEmpty) ...[
                              const SizedBox(height: AppTheme.space12),
                              Container(
                                padding: const EdgeInsets.all(AppTheme.space12),
                                decoration: BoxDecoration(
                                  color: AppTheme.elevatedSurface,
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusSmall),
                                  border: Border.all(
                                      color: AppTheme.goldPrimary
                                          .withValues(alpha: 0.5)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'OFFICIAL RESOLUTION NOTES',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.goldPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      resolutionNotes,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Staff Triage Actions OR Requester Close Action
                            const SizedBox(height: AppTheme.space12),
                            const Divider(height: 1, color: AppTheme.border),
                            const SizedBox(height: AppTheme.space8),
                            if (isStaff)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (currentUserId != null &&
                                      ticket['assignedAgentId']?.toString() !=
                                          currentUserId)
                                    OutlinedButton.icon(
                                      key: const ValueKey(
                                          'support_assign_self_button'),
                                      onPressed: _busy
                                          ? null
                                          : () => _run(
                                                () => ref
                                                    .read(
                                                        supportTicketDetailProvider(
                                                                widget.ticketId)
                                                            .notifier)
                                                    .assignTicket(currentUserId),
                                                successMessage:
                                                    'Ticket assigned to you',
                                              ),
                                      icon: const Icon(
                                          Icons.assignment_ind_outlined,
                                          size: 16),
                                      label: const Text('Assign to Me'),
                                    ),
                                  if (status != 'RESOLVED')
                                    ElevatedButton.icon(
                                      key: const ValueKey(
                                          'support_resolve_button'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.goldPrimary,
                                        foregroundColor:
                                            AppTheme.voidBackground,
                                      ),
                                      onPressed:
                                          _busy ? null : _promptResolveTicket,
                                      icon: const Icon(
                                          Icons.check_circle_outline,
                                          size: 16),
                                      label: const Text('Resolve Ticket'),
                                    ),
                                  if (status != 'CLOSED')
                                    TextButton(
                                      onPressed: _busy
                                          ? null
                                          : () => _run(
                                                () => ref
                                                    .read(
                                                        supportTicketDetailProvider(
                                                                widget.ticketId)
                                                            .notifier)
                                                    .updateStatus('CLOSED'),
                                                successMessage: 'Ticket closed',
                                              ),
                                      child: const Text('Close Ticket'),
                                    ),
                                ],
                              )
                            else if (status != 'CLOSED')
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  key: const ValueKey(
                                      'support_requester_close_button'),
                                  onPressed: _busy
                                      ? null
                                      : () => _run(
                                            () => ref
                                                .read(
                                                    supportTicketDetailProvider(
                                                            widget.ticketId)
                                                        .notifier)
                                                .updateStatus('CLOSED'),
                                            successMessage:
                                                'Support ticket closed',
                                          ),
                                  icon: const Icon(Icons.check, size: 16),
                                  label: const Text('Mark Issue Closed'),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.space16),
                      const Text(
                        'CONVERSATION THREAD',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: AppTheme.goldLight,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space8),
                      if (messages.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(AppTheme.space16),
                          decoration: BoxDecoration(
                            color: AppTheme.cardSurface,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: const Text(
                            'No replies yet. Add a message below to update the thread.',
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        )
                      else
                        ...messages.map((m) {
                          if (m is! Map) return const SizedBox.shrink();
                          final msg = Map<String, dynamic>.from(m);
                          final isInternal = msg['isInternal'] == true;
                          final isMine =
                              msg['senderId']?.toString() == currentUserId;

                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppTheme.space8),
                            child: ElevatedActionCard(
                              padding: const EdgeInsets.all(AppTheme.space12),
                              borderColor: isInternal
                                  ? AppTheme.warning
                                  : (isMine
                                      ? AppTheme.goldPrimary
                                      : AppTheme.border),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        isMine ? 'You' : 'Helpdesk / Participant',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.goldLight,
                                        ),
                                      ),
                                      if (isInternal)
                                        const StatusChip(
                                          label: 'INTERNAL STAFF NOTE',
                                          type: StatusType.warning,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    (msg['message'] ?? msg['content'])?.toString() ?? '',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textPrimary,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),

              // Reply Composer
              if (status != 'CLOSED')
                Container(
                  padding: EdgeInsets.fromLTRB(
                    AppTheme.space16,
                    AppTheme.space12,
                    AppTheme.space16,
                    MediaQuery.of(context).padding.bottom + AppTheme.space12,
                  ),
                  decoration: const BoxDecoration(
                    color: AppTheme.cardSurface,
                    border: Border(top: BorderSide(color: AppTheme.border)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isStaff)
                        Row(
                          children: [
                            Checkbox(
                              key: const ValueKey('support_internal_note_checkbox'),
                              value: _isInternalNote,
                              activeColor: AppTheme.warning,
                              onChanged: (val) => setState(
                                  () => _isInternalNote = val ?? false),
                            ),
                            const Text(
                              'Post as Internal Staff Note (hidden from requester)',
                              style: TextStyle(
                                  fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              key: const ValueKey('support_reply_input'),
                              controller: _replyController,
                              style:
                                  const TextStyle(color: AppTheme.textPrimary),
                              decoration: InputDecoration(
                                hintText: _isInternalNote
                                    ? 'Write internal staff note...'
                                    : 'Write a reply...',
                                filled: true,
                                fillColor: AppTheme.elevatedSurface,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusSmall),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            key: const ValueKey('support_send_reply_button'),
                            onPressed: _busy ? null : _sendReply,
                            icon: const Icon(Icons.send,
                                color: AppTheme.goldPrimary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
