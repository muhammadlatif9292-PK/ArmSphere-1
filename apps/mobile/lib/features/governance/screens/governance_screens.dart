import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/dispute_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/glass_card.dart';

/// Governance dashboard — real disputes from GET /governance/disputes.
class GovernanceDashboardScreen extends ConsumerWidget {
  const GovernanceDashboardScreen({super.key});

  Color _statusColor(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'OPEN':
        return AppTheme.warning;
      case 'ESCALATED':
      case 'AWAITING_EVIDENCE':
        return AppTheme.primaryAccent;
      case 'RESOLVED':
        return AppTheme.success;
      case 'REJECTED':
        return AppTheme.error;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _statusLabel(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'AWAITING_EVIDENCE':
        return 'Awaiting Evidence';
      default:
        final raw = (status ?? '').replaceAll('_', ' ').toLowerCase();
        return raw.isEmpty
            ? 'Unknown'
            : raw[0].toUpperCase() + raw.substring(1);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disputesAsync = ref.watch(disputeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Arbitration & Disputes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_moderator_outlined),
            tooltip: 'File dispute / complaint',
            onPressed: () => context.push('/governance/submit-complaint'),
          ),
        ],
      ),
      body: disputesAsync.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, __) => const GlassCard(
            padding: EdgeInsets.all(16),
            child: SizedBox(height: 56),
          ),
        ),
        error: (error, _) => AppEmptyState(
          icon: Icons.error_outline,
          title: 'Could not load disputes',
          subtitle: error.toString(),
          ctaLabel: 'Retry',
          onCtaTap: () => ref.invalidate(disputeProvider),
        ),
        data: (disputes) {
          if (disputes.isEmpty) {
            return AppEmptyState(
              icon: Icons.balance_outlined,
              title: 'No disputes filed',
              subtitle:
                  'Open arbitration cases will appear here once submitted.',
              ctaLabel: 'File a complaint',
              onCtaTap: () => context.push('/governance/submit-complaint'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(disputeProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: disputes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final d = disputes[index];
                final status = d['status']?.toString();
                final color = _statusColor(status);

                return GestureDetector(
                  onTap: () =>
                      context.push('/governance/dispute/${d['id']}'),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d['title']?.toString() ?? 'Untitled dispute',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                d['createdAt']
                                        ?.toString()
                                        .split('T')
                                        .first ??
                                    '',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _statusLabel(status),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: color),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Dispute Detail Screen — real dispute lookup from the disputes list,
/// with honest escalate / appeal / evidence actions matching backend
/// authorization and validation rules.
class DisputeDetailScreen extends ConsumerStatefulWidget {
  final String disputeId;

  const DisputeDetailScreen({super.key, required this.disputeId});

  @override
  ConsumerState<DisputeDetailScreen> createState() =>
      _DisputeDetailScreenState();
}

class _DisputeDetailScreenState extends ConsumerState<DisputeDetailScreen> {
  bool _busy = false;

  Map<String, dynamic>? _findDispute(List<Map<String, dynamic>> disputes) {
    for (final d in disputes) {
      if (d['id']?.toString() == widget.disputeId) return d;
    }
    return null;
  }

  Future<void> _run(Future<Map<String, dynamic>?> Function() action,
      {String? successMessage}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await action();
      if (!mounted) return;
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(successMessage ?? 'Updated'),
              backgroundColor: AppTheme.success),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Action failed'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _promptText(
    String title,
    String hint,
    Future<Map<String, dynamic>?> Function(String) submit,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.length < 5) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please provide at least 5 characters'),
                      backgroundColor: Colors.red),
                );
                return;
              }
              Navigator.of(dialogContext).pop();
              await _run(() => submit(text));
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _addEvidence() {
    final urlController = TextEditingController();
    String fileType = 'VIDEO';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Submit evidence',
                    style: Theme.of(sheetContext)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: fileType,
                  decoration: const InputDecoration(labelText: 'File type'),
                  items: const ['VIDEO', 'IMAGE', 'DOCUMENT']
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) =>
                      setSheetState(() => fileType = v ?? 'VIDEO'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlController,
                  autofocus: true,
                  keyboardType: TextInputType.url,
                  decoration:
                      const InputDecoration(labelText: 'Evidence URL'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final url = urlController.text.trim();
                    final uri = Uri.tryParse(url);
                    if (uri == null ||
                        !uri.hasScheme ||
                        !(uri.scheme == 'http' || uri.scheme == 'https')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please provide a valid URL'),
                            backgroundColor: Colors.red),
                      );
                      return;
                    }
                    Navigator.of(sheetContext).pop();
                    setState(() => _busy = true);
                    try {
                      final ok = await ref
                          .read(disputeProvider.notifier)
                          .submitEvidence(widget.disputeId, fileType, url);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok
                              ? 'Evidence submitted'
                              : 'Could not submit evidence'),
                          backgroundColor:
                              ok ? AppTheme.success : Colors.red,
                        ),
                      );
                    } finally {
                      if (mounted) setState(() => _busy = false);
                    }
                  },
                  child: const Text('Submit Evidence'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final disputesAsync = ref.watch(disputeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dispute Details')),
      body: disputesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppEmptyState(
          icon: Icons.error_outline,
          title: 'Could not load dispute',
          subtitle: error.toString(),
          ctaLabel: 'Retry',
          onCtaTap: () => ref.invalidate(disputeProvider),
        ),
        data: (disputes) {
          final d = _findDispute(disputes);
          if (d == null) {
            return AppEmptyState(
              icon: Icons.search_off,
              title: 'Dispute not found',
              subtitle:
                  'This dispute does not exist or you cannot view it.',
              ctaLabel: 'Back to disputes',
              onCtaTap: () => context.go('/governance'),
            );
          }

          final status = d['status']?.toString().toUpperCase() ?? 'OPEN';
          final isTerminal = status == 'RESOLVED' || status == 'REJECTED';

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(disputeProvider),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d['title']?.toString() ?? 'Untitled dispute',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Chip(
                            avatar: Icon(Icons.circle,
                                size: 10,
                                color: status == 'OPEN'
                                    ? AppTheme.warning
                                    : status == 'RESOLVED'
                                        ? AppTheme.success
                                        : status == 'REJECTED'
                                            ? AppTheme.error
                                            : AppTheme.primaryAccent),
                            label: Text(
                                status.replaceAll('_', ' '),
                                style: const TextStyle(fontSize: 11)),
                            visualDensity: VisualDensity.compact,
                          ),
                          if (d['createdAt'] != null)
                            Chip(
                              avatar: const Icon(Icons.calendar_today,
                                  size: 12),
                              label: Text(
                                  d['createdAt']
                                      .toString()
                                      .split('T')
                                      .first,
                                  style: const TextStyle(fontSize: 11)),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                      const Divider(height: 24),
                      Text(
                        d['description']?.toString() ?? '',
                        style: const TextStyle(height: 1.5, fontSize: 13),
                      ),
                      if ((d['resolutionDetails'] as String?)
                              ?.isNotEmpty ==
                          true) ...[
                        const Divider(height: 24),
                        Text(
                          'Resolution / Review Notes',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          d['resolutionDetails'].toString(),
                          style:
                              const TextStyle(height: 1.5, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _promptText(
                            'Escalate dispute',
                            'Explain why this case needs higher review...',
                            (reason) => ref
                                .read(disputeProvider.notifier)
                                .escalateDispute(
                                    widget.disputeId, reason),
                          ),
                  icon: const Icon(Icons.trending_up),
                  label: const Text('Escalate'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _addEvidence,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Add Evidence Link'),
                ),
                const SizedBox(height: 8),
                if (isTerminal)
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _promptText(
                              'Appeal resolution',
                              'Explain why you contest this outcome...',
                              (reason) => ref
                                  .read(disputeProvider.notifier)
                                  .appealDispute(
                                      widget.disputeId, reason),
                            ),
                    icon: const Icon(Icons.replay),
                    label: const Text('Appeal Resolution'),
                  )
                else ...[
                  Text(
                    'Appeals become available once a dispute has been resolved or rejected.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
