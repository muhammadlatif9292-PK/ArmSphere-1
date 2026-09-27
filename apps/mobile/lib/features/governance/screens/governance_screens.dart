import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/dispute_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/skeleton_placeholder.dart';

/// Domain 6 / Stage 6 Convergence: Governance Dashboard Screen
///
/// Implements Canonical Table Dispute & Arbitration Architecture:
/// - Real disputes loaded from GET /governance/disputes via Riverpod.
/// - Tactical status filters (ALL, OPEN, ESCALATED, RESOLVED).
/// - Unbundled case docket with monospace tabular case numbers (`FontFeature.tabularFigures()`).
/// - Standardized 15-degree shimmer skeleton loading state (`SkeletonPlaceholder`).
/// - Full `RepaintBoundary` raster isolation for smooth 60fps scrolling.
/// - Eradication of `GlassCard` list items in compliance with Audit Rule Item 2.2.
class GovernanceDashboardScreen extends ConsumerStatefulWidget {
  const GovernanceDashboardScreen({super.key});

  @override
  ConsumerState<GovernanceDashboardScreen> createState() =>
      _GovernanceDashboardScreenState();
}

class _GovernanceDashboardScreenState
    extends ConsumerState<GovernanceDashboardScreen> {
  String _selectedFilter = 'ALL';

  StatusType _statusType(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'OPEN':
        return StatusType.warning;
      case 'ESCALATED':
      case 'AWAITING_EVIDENCE':
        return StatusType.error;
      case 'RESOLVED':
        return StatusType.success;
      case 'REJECTED':
        return StatusType.neutral;
      default:
        return StatusType.neutral;
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

  List<Map<String, dynamic>> _filterDisputes(
      List<Map<String, dynamic>> disputes) {
    if (_selectedFilter == 'ALL') return disputes;
    return disputes.where((d) {
      final status = (d['status']?.toString() ?? '').toUpperCase();
      if (_selectedFilter == 'OPEN') return status == 'OPEN';
      if (_selectedFilter == 'ESCALATED') {
        return status == 'ESCALATED' || status == 'AWAITING_EVIDENCE';
      }
      if (_selectedFilter == 'RESOLVED') {
        return status == 'RESOLVED' || status == 'REJECTED';
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final disputesAsync = ref.watch(disputeProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardSurface,
        elevation: 0,
        title: const Text(
          'Arbitration & Disputes',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_moderator_outlined,
                color: AppTheme.goldPrimary),
            tooltip: 'File dispute / complaint',
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push('/governance/submit-complaint');
            },
          ),
        ],
      ),
      body: disputesAsync.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(AppTheme.space16),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(height: AppTheme.space12),
          itemBuilder: (_, __) => const SkeletonPlaceholder(
            height: 96,
            borderRadius: AppTheme.radiusMedium,
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
              onCtaTap: () {
                HapticFeedback.lightImpact();
                context.push('/governance/submit-complaint');
              },
            );
          }

          final openCount = disputes
              .where((d) => (d['status']?.toString().toUpperCase()) == 'OPEN')
              .length;
          final escalatedCount = disputes
              .where((d) =>
                  (d['status']?.toString().toUpperCase()) == 'ESCALATED' ||
                  (d['status']?.toString().toUpperCase()) ==
                      'AWAITING_EVIDENCE')
              .length;
          final resolvedCount = disputes
              .where((d) =>
                  (d['status']?.toString().toUpperCase()) == 'RESOLVED' ||
                  (d['status']?.toString().toUpperCase()) == 'REJECTED')
              .length;

          final filtered = _filterDisputes(disputes);

          return RefreshIndicator(
            color: AppTheme.goldPrimary,
            backgroundColor: AppTheme.cardSurface,
            onRefresh: () async => ref.invalidate(disputeProvider),
            child: ListView(
              key: const PageStorageKey<String>('governance_disputes_list_view'),
              padding: const EdgeInsets.all(AppTheme.space16),
              children: [
                // Top Operational Metrics Ribbon
                Container(
                  padding: const EdgeInsets.all(AppTheme.space12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardSurface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(color: AppTheme.border, width: 1.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _MetricItem(
                        label: 'TOTAL',
                        count: disputes.length,
                        color: AppTheme.textPrimary,
                      ),
                      Container(
                          width: 1, height: 28, color: AppTheme.border),
                      _MetricItem(
                        label: 'OPEN',
                        count: openCount,
                        color: AppTheme.secondaryAccent,
                      ),
                      Container(
                          width: 1, height: 28, color: AppTheme.border),
                      _MetricItem(
                        label: 'ESCALATED',
                        count: escalatedCount,
                        color: AppTheme.primaryAccent,
                      ),
                      Container(
                          width: 1, height: 28, color: AppTheme.border),
                      _MetricItem(
                        label: 'RESOLVED',
                        count: resolvedCount,
                        color: AppTheme.success,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space16),

                // Tactical Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterTab(
                        label: 'ALL',
                        count: disputes.length,
                        isSelected: _selectedFilter == 'ALL',
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedFilter = 'ALL');
                        },
                      ),
                      const SizedBox(width: AppTheme.space8),
                      _FilterTab(
                        label: 'OPEN',
                        count: openCount,
                        isSelected: _selectedFilter == 'OPEN',
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedFilter = 'OPEN');
                        },
                      ),
                      const SizedBox(width: AppTheme.space8),
                      _FilterTab(
                        label: 'ESCALATED',
                        count: escalatedCount,
                        isSelected: _selectedFilter == 'ESCALATED',
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedFilter = 'ESCALATED');
                        },
                      ),
                      const SizedBox(width: AppTheme.space8),
                      _FilterTab(
                        label: 'RESOLVED',
                        count: resolvedCount,
                        isSelected: _selectedFilter == 'RESOLVED',
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedFilter = 'RESOLVED');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space16),

                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'No cases in this status category.',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                else
                  ...filtered.map((d) {
                    final status = d['status']?.toString();
                    final idStr = d['id']?.toString() ?? '';
                    final shortId = idStr.length >= 8
                        ? idStr.substring(0, 8).toUpperCase()
                        : idStr.toUpperCase();
                    final rawDate = d['createdAt']?.toString() ?? '';
                    final dateFormatted = rawDate.contains('T')
                        ? rawDate.split('T').first
                        : rawDate;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.space12),
                      child: RepaintBoundary(
                        child: ElevatedActionCard(
                          padding: const EdgeInsets.all(AppTheme.space16),
                          onTap: () =>
                              context.push('/governance/dispute/${d['id']}'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.elevatedSurface,
                                      borderRadius: BorderRadius.circular(
                                          AppTheme.radiusSmall),
                                      border: Border.all(
                                          color: AppTheme.border, width: 1.0),
                                    ),
                                    child: Text(
                                      '#DISP-$shortId',
                                      style: const TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                        color: AppTheme.goldLight,
                                        fontFeatures: [
                                          FontFeature.tabularFigures()
                                        ],
                                      ),
                                    ),
                                  ),
                                  StatusChip(
                                    label: _statusLabel(status),
                                    type: _statusType(status),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.space12),
                              Text(
                                d['title']?.toString() ?? 'Untitled dispute',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: AppTheme.space12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 13,
                                        color: AppTheme.textMuted,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        dateFormatted,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textMuted,
                                          fontFeatures: [
                                            FontFeature.tabularFigures()
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Row(
                                    children: [
                                      Text(
                                        'VIEW DOSSIER',
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.8,
                                          color: AppTheme.goldPrimary,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 11,
                                        color: AppTheme.goldPrimary,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _MetricItem({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.goldPrimary.withValues(alpha: 0.15)
              : AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(
            color: isSelected ? AppTheme.goldPrimary : AppTheme.border,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
                color: isSelected
                    ? AppTheme.goldLight
                    : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.goldPrimary
                    : AppTheme.elevatedSurface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppTheme.voidBackground : AppTheme.textMuted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
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

  StatusType _statusType(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return StatusType.warning;
      case 'ESCALATED':
      case 'AWAITING_EVIDENCE':
        return StatusType.error;
      case 'RESOLVED':
        return StatusType.success;
      case 'REJECTED':
        return StatusType.neutral;
      default:
        return StatusType.neutral;
    }
  }

  Future<void> _run(Future<Map<String, dynamic>?> Function() action,
      {String? successMessage}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await action();
      if (!mounted) return;
      if (result != null) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage ?? 'Dossier updated successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Action failed. Please try again.'),
            backgroundColor: AppTheme.error,
          ),
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
        backgroundColor: AppTheme.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          side: const BorderSide(color: AppTheme.border, width: 1.0),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppTheme.textMuted),
            filled: true,
            fillColor: AppTheme.elevatedSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              borderSide: const BorderSide(color: AppTheme.goldPrimary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.goldPrimary,
              foregroundColor: AppTheme.voidBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
            ),
            onPressed: () async {
              final text = controller.text.trim();
              if (text.length < 5) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide at least 5 characters'),
                    backgroundColor: AppTheme.error,
                  ),
                );
                return;
              }
              Navigator.of(dialogContext).pop();
              await _run(() => submit(text));
            },
            child: const Text('Submit',
                style: TextStyle(fontWeight: FontWeight.bold)),
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
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusLarge)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: AppTheme.space20,
              right: AppTheme.space20,
              top: AppTheme.space16,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom +
                  AppTheme.space20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textMuted.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.space16),
                const Text(
                  'SUBMIT EVIDENCE RECORD',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Link high-definition table video, photo evidence, or official scorepad scans for arbitration review.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: AppTheme.space16),
                DropdownButtonFormField<String>(
                  initialValue: fileType,
                  dropdownColor: AppTheme.elevatedSurface,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Evidence Type',
                    labelStyle: const TextStyle(color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.elevatedSurface,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusSmall),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                  ),
                  items: const ['VIDEO', 'IMAGE', 'DOCUMENT']
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Row(
                              children: [
                                Icon(
                                  t == 'VIDEO'
                                      ? Icons.videocam_outlined
                                      : t == 'IMAGE'
                                          ? Icons.image_outlined
                                          : Icons.description_outlined,
                                  size: 16,
                                  color: AppTheme.goldPrimary,
                                ),
                                const SizedBox(width: 8),
                                Text(t),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setSheetState(() => fileType = v ?? 'VIDEO'),
                ),
                const SizedBox(height: AppTheme.space12),
                TextField(
                  controller: urlController,
                  autofocus: true,
                  keyboardType: TextInputType.url,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Evidence URL (HTTP/HTTPS)',
                    labelStyle: const TextStyle(color: AppTheme.textSecondary),
                    hintText: 'https://...',
                    hintStyle: const TextStyle(color: AppTheme.textMuted),
                    filled: true,
                    fillColor: AppTheme.elevatedSurface,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusSmall),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusSmall),
                      borderSide:
                          const BorderSide(color: AppTheme.goldPrimary),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.space20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.goldPrimary,
                    foregroundColor: AppTheme.voidBackground,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                  onPressed: () async {
                    final url = urlController.text.trim();
                    final uri = Uri.tryParse(url);
                    if (uri == null ||
                        !uri.hasScheme ||
                        !(uri.scheme == 'http' || uri.scheme == 'https')) {
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please provide a valid HTTP/HTTPS URL'),
                          backgroundColor: AppTheme.error,
                        ),
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
                      HapticFeedback.mediumImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok
                              ? 'Evidence record attached to dossier'
                              : 'Could not submit evidence'),
                          backgroundColor:
                              ok ? AppTheme.success : AppTheme.error,
                        ),
                      );
                    } finally {
                      if (mounted) setState(() => _busy = false);
                    }
                  },
                  child: const Text(
                    'ATTACH EVIDENCE RECORD',
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardSurface,
        elevation: 0,
        title: const Text(
          'Dispute Dossier',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: disputesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.goldPrimary),
        ),
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
                  'This dispute does not exist or you lack authorization to inspect it.',
              ctaLabel: 'Back to disputes',
              onCtaTap: () => context.go('/governance'),
            );
          }

          final status = d['status']?.toString().toUpperCase() ?? 'OPEN';
          final isTerminal = status == 'RESOLVED' || status == 'REJECTED';
          final idStr = d['id']?.toString() ?? '';
          final shortId = idStr.length >= 8
              ? idStr.substring(0, 8).toUpperCase()
              : idStr.toUpperCase();
          final rawDate = d['createdAt']?.toString() ?? '';
          final dateFormatted = rawDate.contains('T')
              ? rawDate.split('T').first
              : rawDate;

          return RefreshIndicator(
            color: AppTheme.goldPrimary,
            backgroundColor: AppTheme.cardSurface,
            onRefresh: () async => ref.invalidate(disputeProvider),
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.space16),
              children: [
                // 1. Case Dossier Header Card
                ElevatedActionCard(
                  padding: const EdgeInsets.all(AppTheme.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.elevatedSurface,
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radiusSmall),
                              border: Border.all(
                                  color: AppTheme.border, width: 1.0),
                            ),
                            child: Text(
                              '#DISP-$shortId',
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: AppTheme.goldLight,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                          StatusChip(
                            label: status.replaceAll('_', ' '),
                            type: _statusType(status),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space16),
                      Text(
                        d['title']?.toString() ?? 'Untitled dispute',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space12),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 13,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Filed on $dateFormatted',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space16),

                // 2. Statement of Complaint
                ElevatedActionCard(
                  padding: const EdgeInsets.all(AppTheme.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.gavel_outlined,
                            size: 16,
                            color: AppTheme.goldPrimary,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'STATEMENT OF COMPLAINT',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: AppTheme.goldLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space12),
                      const Divider(height: 1, color: AppTheme.border),
                      const SizedBox(height: AppTheme.space12),
                      Text(
                        d['description']?.toString() ?? 'No description provided.',
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Arbitration Panel Ruling (if available)
                if ((d['resolutionDetails'] as String?)?.isNotEmpty == true) ...[
                  const SizedBox(height: AppTheme.space16),
                  ElevatedActionCard(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    borderColor: AppTheme.goldPrimary.withValues(alpha: 0.5),
                    backgroundColor:
                        AppTheme.goldPrimary.withValues(alpha: 0.05),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.verified_outlined,
                              size: 16,
                              color: AppTheme.goldPrimary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'ARBITRATION PANEL RULING',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                                color: AppTheme.goldLight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.space12),
                        const Divider(height: 1, color: AppTheme.border),
                        const SizedBox(height: AppTheme.space12),
                        Text(
                          d['resolutionDetails'].toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppTheme.space24),

                // 4. Action Console
                ElevatedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _promptText(
                            'Escalate dispute to Executive Panel',
                            'Provide explicit grounds why table officiating requires higher federation review...',
                            (reason) => ref
                                .read(disputeProvider.notifier)
                                .escalateDispute(
                                    widget.disputeId, reason),
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryAccent,
                    foregroundColor: AppTheme.voidBackground,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                  icon: const Icon(Icons.trending_up, size: 18),
                  label: const Text(
                    'ESCALATE DISPUTE',
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.space12),

                OutlinedButton.icon(
                  onPressed: _busy ? null : _addEvidence,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: AppTheme.border, width: 1.0),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                  icon: const Icon(Icons.attach_file,
                      size: 18, color: AppTheme.goldPrimary),
                  label: const Text(
                    'ATTACH EVIDENCE LINK',
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.space12),

                if (isTerminal)
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _promptText(
                              'Appeal Arbitration Resolution',
                              'Contest the verdict with new or unaddressed referee table evidence...',
                              (reason) => ref
                                  .read(disputeProvider.notifier)
                                  .appealDispute(
                                      widget.disputeId, reason),
                            ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryAccent,
                      side: const BorderSide(
                          color: AppTheme.primaryAccent, width: 1.0),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                    ),
                    icon: const Icon(Icons.replay, size: 18),
                    label: const Text(
                      'CONTEST / APPEAL VERDICT',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space16, vertical: AppTheme.space8),
                    child: Text(
                      'Appeals become eligible once an arbitration verdict has been formally recorded.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
