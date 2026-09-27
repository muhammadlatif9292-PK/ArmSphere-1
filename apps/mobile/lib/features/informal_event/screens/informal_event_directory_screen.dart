import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/informal_event_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/skeleton_placeholder.dart';
import '../../../core/widgets/status_chip.dart';

/// Domain 9 / Stage 6 Convergence: Informal Event Directory Screen
///
/// Implements Grassroots Sparring & Practice Meetups Discovery:
/// - Fetches local practice sessions from GET /informal-events.
/// - Unbundled meetup card with scheduled date/time, city badge, and attendee tallies.
/// - Eradication of nested `GlassCard` inside `ListView` in compliance with Audit Rule Item 2.2.
/// - Full `RepaintBoundary` raster isolation for smooth 60fps scrolling.
class InformalEventDirectoryScreen extends ConsumerWidget {
  const InformalEventDirectoryScreen({super.key});

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${months[dt.month - 1]}, $h:${dt.minute.toString().padLeft(2, '0')} $amPm';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(informalEventListProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardSurface,
        elevation: 0,
        title: const Text(
          'Practice Meetups',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppTheme.goldPrimary),
            tooltip: 'Host practice meetup',
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push('/informal-events/create');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.goldPrimary,
        backgroundColor: AppTheme.cardSurface,
        onRefresh: () async => ref.invalidate(informalEventListProvider),
        child: eventsAsync.when(
          loading: () => ListView.separated(
            padding: const EdgeInsets.all(AppTheme.space16),
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(height: AppTheme.space12),
            itemBuilder: (_, __) => const SkeletonPlaceholder(
              height: 104,
              borderRadius: AppTheme.radiusMedium,
            ),
          ),
          error: (e, _) => AppEmptyState(
            icon: Icons.error_outline,
            title: 'Could not load practice meetups',
            subtitle: e.toString(),
            ctaLabel: 'Retry',
            onCtaTap: () => ref.invalidate(informalEventListProvider),
          ),
          data: (events) {
            if (events.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  AppEmptyState(
                    icon: Icons.sports_martial_arts_outlined,
                    title: 'No upcoming practice meetups',
                    subtitle:
                        'Local sparring sessions near you will appear here. Host one to get pullers to your table.',
                    ctaLabel: 'Host a Meetup',
                    onCtaTap: () {
                      HapticFeedback.lightImpact();
                      context.push('/informal-events/create');
                    },
                  ),
                ],
              );
            }

            return ListView.separated(
              key: const PageStorageKey<String>('informal_event_directory_list_view'),
              padding: const EdgeInsets.all(AppTheme.space16),
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppTheme.space12),
              itemBuilder: (context, index) {
                final e = events[index];
                final id = e['id']?.toString() ?? '';
                final title = e['title']?.toString() ?? 'Meetup';
                final city = e['city']?.toString() ?? '';
                final date = _formatDate(e['scheduledAt']?.toString() ?? '');
                final participantCount =
                    (e['participantCount'] as num?)?.toInt() ?? 0;
                final maxParticipants = e['maxParticipants'] as num?;
                final isFull = maxParticipants != null &&
                    participantCount >= maxParticipants.toInt();

                return RepaintBoundary(
                  child: ElevatedActionCard(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    onTap: () => context.push('/informal-events/$id'),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sparring Emblem
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.elevatedSurface,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            border: Border.all(color: AppTheme.goldPrimary.withValues(alpha: 0.6)),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.sports_martial_arts,
                              color: AppTheme.goldPrimary,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.space12),
                        // Meetup Meta
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppTheme.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.schedule, size: 13, color: AppTheme.textMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    date,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                      fontFeatures: [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                  if (city.isNotEmpty) ...[
                                    const Text(' • ', style: TextStyle(color: AppTheme.textMuted)),
                                    Text(
                                      city,
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: AppTheme.space8),
                              Wrap(
                                spacing: AppTheme.space6,
                                children: [
                                  StatusChip(
                                    label: isFull
                                        ? 'TABLE FULL ($participantCount)'
                                        : '$participantCount PULLERS JOINED',
                                    type: isFull ? StatusType.error : StatusType.success,
                                  ),
                                  if (city.isNotEmpty)
                                    StatusChip(
                                      label: city.toUpperCase(),
                                      type: StatusType.neutral,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: AppTheme.goldPrimary,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
