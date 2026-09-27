import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/venue_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/skeleton_placeholder.dart';
import '../../../core/widgets/status_chip.dart';

/// Domain 9 / Stage 6 Convergence: Venue Directory Screen
///
/// Implements Canonical Armwrestling Training Gym & Table Directory:
/// - Fetches verified training spaces from GET /venues.
/// - Unbundled venue card with table hardware indicators, city pills, and official verification badges.
/// - Eradication of nested `GlassCard` inside `ListView` in compliance with Audit Rule Item 2.2.
/// - Full `RepaintBoundary` raster isolation for smooth 60fps scrolling.
class VenueDirectoryScreen extends ConsumerWidget {
  const VenueDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venuesAsync = ref.watch(venueListProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardSurface,
        elevation: 0,
        title: const Text(
          'Armwrestling Venues',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt_outlined, color: AppTheme.goldPrimary),
            tooltip: 'Submit training venue',
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push('/venues/submit');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.goldPrimary,
        backgroundColor: AppTheme.cardSurface,
        onRefresh: () async => ref.invalidate(venueListProvider),
        child: venuesAsync.when(
          loading: () => ListView.separated(
            padding: const EdgeInsets.all(AppTheme.space16),
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(height: AppTheme.space12),
            itemBuilder: (_, __) => const SkeletonPlaceholder(
              height: 96,
              borderRadius: AppTheme.radiusMedium,
            ),
          ),
          error: (e, _) => AppEmptyState(
            icon: Icons.error_outline,
            title: 'Could not load venues',
            subtitle: e.toString(),
            ctaLabel: 'Retry',
            onCtaTap: () => ref.invalidate(venueListProvider),
          ),
          data: (venues) {
            if (venues.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  AppEmptyState(
                    icon: Icons.location_on_outlined,
                    title: 'No venues listed yet',
                    subtitle:
                        'Know a training gym with official armwrestling tables? Submit it for federation certification.',
                    ctaLabel: 'Submit a Venue',
                    onCtaTap: () {
                      HapticFeedback.lightImpact();
                      context.push('/venues/submit');
                    },
                  ),
                ],
              );
            }

            return ListView.separated(
              key: const PageStorageKey<String>('venue_directory_list_view'),
              padding: const EdgeInsets.all(AppTheme.space16),
              itemCount: venues.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppTheme.space12),
              itemBuilder: (context, index) {
                final v = venues[index];
                final id = v['id']?.toString() ?? '';
                final name = v['name']?.toString() ?? 'Venue';
                final city = v['city']?.toString() ?? '';
                final addressLine = [
                  v['address']?.toString(),
                  city,
                  v['province']?.toString(),
                ].where((part) => part != null && part.isNotEmpty).join(', ');
                final verificationStatus =
                    (v['verificationStatus']?.toString() ?? 'VERIFIED').toUpperCase();
                final isVerified = verificationStatus == 'VERIFIED';

                return RepaintBoundary(
                  child: ElevatedActionCard(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    onTap: id.isEmpty ? null : () => context.push('/venues/$id'),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Venue Table Icon Badge
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.elevatedSurface,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            border: Border.all(
                              color: isVerified ? AppTheme.goldPrimary : AppTheme.border,
                              width: 1.0,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.fitness_center_outlined,
                              color: isVerified ? AppTheme.goldPrimary : AppTheme.textSecondary,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.space12),
                        // Venue Meta
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppTheme.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (addressLine.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.place_outlined,
                                      size: 13,
                                      color: AppTheme.textMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        addressLine,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: AppTheme.space8),
                              Wrap(
                                spacing: AppTheme.space6,
                                children: [
                                  if (isVerified)
                                    const StatusChip(
                                      label: 'CERTIFIED TABLES',
                                      type: StatusType.success,
                                    )
                                  else
                                    const StatusChip(
                                      label: 'PENDING VERIFICATION',
                                      type: StatusType.warning,
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
