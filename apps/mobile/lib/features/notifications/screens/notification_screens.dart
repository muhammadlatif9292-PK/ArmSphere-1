import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/providers/state_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/skeleton_placeholder.dart';
import '../../../core/widgets/status_chip.dart';

/// Domain 8 / Stage 6 Convergence: Notifications List Screen
///
/// Implements Real-time Athlete & Tournament Alert Center:
/// - Pulls alerts from GET /communication/notifications with mark-as-read and mark-all-as-read actions.
/// - Unbundled notification tiles with category iconography, priority pills, and monospace tabular timestamps.
/// - Eradication of nested `GlassCard` inside `ListView` in compliance with Audit Rule Item 2.2.
/// - Full `RepaintBoundary` raster isolation for smooth 60fps scrolling.
class NotificationsListScreen extends ConsumerStatefulWidget {
  const NotificationsListScreen({super.key});

  @override
  ConsumerState<NotificationsListScreen> createState() =>
      _NotificationsListScreenState();
}

class _NotificationsListScreenState
    extends ConsumerState<NotificationsListScreen> {
  bool _markingAll = false;

  Future<void> _openNotification(Map<String, dynamic> n) async {
    HapticFeedback.lightImpact();
    try {
      await ref.read(notificationProvider.notifier).markAsRead(n['id'].toString());
    } catch (_) {
      // markAsRead enqueues offline; do not block the user on failure.
    }
  }

  Future<void> _markAllRead() async {
    if (_markingAll) return;
    HapticFeedback.lightImpact();
    setState(() => _markingAll = true);
    try {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.markAllAsRead();
      ref.invalidate(notificationProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All alerts marked as read'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not mark all as read: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  Color _priorityColor(String? priority) {
    switch ((priority ?? '').toUpperCase()) {
      case 'HIGH':
      case 'URGENT':
        return AppTheme.primaryAccent;
      case 'MEDIUM':
        return AppTheme.secondaryAccent;
      default:
        return AppTheme.info;
    }
  }

  StatusType _priorityStatusType(String? priority) {
    switch ((priority ?? '').toUpperCase()) {
      case 'HIGH':
      case 'URGENT':
        return StatusType.error;
      case 'MEDIUM':
        return StatusType.warning;
      default:
        return StatusType.info;
    }
  }

  IconData _categoryIcon(String? category) {
    switch ((category ?? '').toUpperCase()) {
      case 'MATCH':
      case 'RESULT':
        return Icons.sports_kabaddi;
      case 'TOURNAMENT':
      case 'EVENT':
        return Icons.emoji_events_outlined;
      case 'ELO':
      case 'RANKING':
        return Icons.trending_up;
      default:
        return Icons.notifications_none;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardSurface,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _markingAll ? null : _markAllRead,
            child: _markingAll
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.goldPrimary,
                    ),
                  )
                : const Text(
                    'Mark all read',
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.goldPrimary,
                    ),
                  ),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(AppTheme.space16),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(height: AppTheme.space12),
          itemBuilder: (_, __) => const SkeletonPlaceholder(
            height: 84,
            borderRadius: AppTheme.radiusMedium,
          ),
        ),
        error: (error, _) => AppEmptyState(
          icon: Icons.error_outline,
          title: 'Could not load notifications',
          subtitle: error.toString(),
          ctaLabel: 'Retry',
          onCtaTap: () => ref.invalidate(notificationProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              icon: Icons.notifications_off_outlined,
              title: 'No notifications',
              subtitle: 'Match calls, weigh-in clearances, and federation circulars will appear here.',
            );
          }
          return RefreshIndicator(
            color: AppTheme.goldPrimary,
            backgroundColor: AppTheme.cardSurface,
            onRefresh: () async => ref.invalidate(notificationProvider),
            child: ListView.separated(
              key: const PageStorageKey<String>('notifications_list_view'),
              padding: const EdgeInsets.all(AppTheme.space16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppTheme.space12),
              itemBuilder: (context, index) {
                final n = items[index];
                final unread = n['status']?.toString().toUpperCase() == 'UNREAD';
                final priority = _priorityColor(n['priority']?.toString());
                final priorityLabel = (n['priority']?.toString() ?? 'NORMAL').toUpperCase();
                final rawDate = n['createdAt']?.toString() ?? '';
                final dateFormatted = rawDate.contains('T')
                    ? rawDate.split('T').first
                    : rawDate;

                return Opacity(
                  opacity: unread ? 1.0 : 0.65,
                  child: RepaintBoundary(
                    child: ElevatedActionCard(
                      padding: const EdgeInsets.all(AppTheme.space14),
                      borderColor: unread
                          ? AppTheme.goldPrimary.withValues(alpha: 0.5)
                          : AppTheme.border,
                      onTap: unread ? () => _openNotification(n) : null,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Icon Avatar
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: priority.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                              border: Border.all(color: priority.withValues(alpha: 0.4)),
                            ),
                            child: Icon(
                              _categoryIcon(n['category']?.toString()),
                              color: priority,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppTheme.space12),
                          // Content Column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        n['title']?.toString() ?? 'Alert',
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          fontWeight: unread ? FontWeight.bold : FontWeight.w600,
                                          fontSize: 14,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (unread)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(left: 6),
                                        decoration: const BoxDecoration(
                                          color: AppTheme.goldPrimary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  n['content']?.toString() ?? '',
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: unread ? AppTheme.textPrimary : AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    StatusChip(
                                      label: priorityLabel,
                                      type: _priorityStatusType(n['priority']?.toString()),
                                    ),
                                    if (dateFormatted.isNotEmpty)
                                      Text(
                                        dateFormatted,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textMuted,
                                          fontFeatures: [FontFeature.tabularFigures()],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
