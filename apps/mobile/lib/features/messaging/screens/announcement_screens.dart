import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/announcement_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/skeleton_placeholder.dart';
import '../../../core/widgets/status_chip.dart';

/// Domain 8 / Stage 6 Convergence: Announcements List Screen
///
/// Implements Official Federation Bulletins & Circulars:
/// - Real federation broadcasts from GET /communication/announcements.
/// - Unbundled announcement card with pinned status, date badge, and Space Grotesk typography.
/// - Eradication of nested `GlassCard` inside `ListView` in compliance with Audit Rule Item 2.2.
/// - Full `RepaintBoundary` raster isolation for smooth 60fps scrolling.
class AnnouncementsListScreen extends ConsumerWidget {
  const AnnouncementsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardSurface,
        elevation: 0,
        title: const Text(
          'Federation Bulletins',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: announcementsAsync.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(AppTheme.space16),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(height: AppTheme.space12),
          itemBuilder: (_, __) => const SkeletonPlaceholder(
            height: 120,
            borderRadius: AppTheme.radiusMedium,
          ),
        ),
        error: (error, _) => AppEmptyState(
          icon: Icons.error_outline,
          title: 'Could not load bulletins',
          subtitle: error.toString(),
          ctaLabel: 'Retry',
          onCtaTap: () => ref.invalidate(announcementsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              icon: Icons.campaign_outlined,
              title: 'No active bulletins',
              subtitle:
                  'Official executive circulars, rule changes, and federation schedules will appear here once published.',
            );
          }
          return RefreshIndicator(
            color: AppTheme.goldPrimary,
            backgroundColor: AppTheme.cardSurface,
            onRefresh: () async {
              await ref.read(announcementsProvider.notifier).refresh();
            },
            child: ListView.separated(
              key: const PageStorageKey<String>('announcements_list_view'),
              padding: const EdgeInsets.all(AppTheme.space16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppTheme.space12),
              itemBuilder: (context, index) {
                final item = items[index];
                final dateRaw = item['publishedAt']?.toString() ??
                    item['createdAt']?.toString() ??
                    '';
                final dateFormatted = dateRaw.contains('T')
                    ? dateRaw.split('T').first
                    : dateRaw;
                final isPinned = item['isPinned'] == true;

                return RepaintBoundary(
                  child: ElevatedActionCard(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    borderColor: isPinned
                        ? AppTheme.goldPrimary.withValues(alpha: 0.6)
                        : AppTheme.border,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (isPinned)
                              const StatusChip(
                                label: 'PINNED BULLETIN',
                                type: StatusType.warning,
                              )
                            else
                              const StatusChip(
                                label: 'OFFICIAL NOTICE',
                                type: StatusType.neutral,
                              ),
                            if (dateFormatted.isNotEmpty)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 12,
                                    color: AppTheme.textMuted,
                                  ),
                                  const SizedBox(width: 4),
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
                        const SizedBox(height: AppTheme.space12),
                        Text(
                          item['title']?.toString() ?? '',
                          style: const TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space8),
                        Text(
                          item['content']?.toString() ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: AppTheme.textSecondary,
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
