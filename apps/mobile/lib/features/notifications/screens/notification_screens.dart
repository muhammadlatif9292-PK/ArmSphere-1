import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/skeleton_placeholder.dart';

/// Notifications — real list from GET /communication/notifications with
/// mark-as-read and mark-all-as-read actions.
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
    try {
      await ref.read(notificationProvider.notifier).markAsRead(n['id'].toString());
    } catch (_) {
      // markAsRead enqueues offline; do not block the user on failure.
    }
  }

  Future<void> _markAllRead() async {
    if (_markingAll) return;
    setState(() => _markingAll = true);
    try {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.markAllAsRead();
      ref.invalidate(notificationProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Could not mark all as read: $e'),
              backgroundColor: Colors.red),
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
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: _markingAll ? null : _markAllRead,
            child: _markingAll
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Mark all read'),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, __) => const SkeletonPlaceholder(height: 84),
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
              subtitle: 'Match results and federation updates will appear here.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final n = items[index];
                final unread = n['status']?.toString().toUpperCase() == 'UNREAD';
                final priority = _priorityColor(n['priority']?.toString());
                final dateRaw = n['createdAt']?.toString() ?? '';

                return Opacity(
                  opacity: unread ? 1.0 : 0.55,
                  child: GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: ListTile(
                      onTap: unread ? () => _openNotification(n) : null,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: priority.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_categoryIcon(n['category']?.toString()),
                            color: priority, size: 20),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              n['title']?.toString() ?? '',
                              style: TextStyle(
                                fontWeight: unread
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (unread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text(n['content']?.toString() ?? '',
                              style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(dateRaw.split('T').first,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant)),
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
