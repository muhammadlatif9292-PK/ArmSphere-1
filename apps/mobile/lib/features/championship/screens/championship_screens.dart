import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/championship_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/skeleton_placeholder.dart';
import '../../../core/widgets/status_chip.dart';

/// Domain 10 / Stage 6 Convergence: Championships List Screen
///
/// Implements Canonical Federation Championship Titles & Belt Catalog:
/// - Displays sanctioned national and regional title belts (GET /championship/titles).
/// - Unbundled championship belt cards with arm, division, and weight class tags.
/// - Eradication of nested `GlassCard` inside `ListView` in compliance with Audit Rule Item 2.2.
/// - Full `RepaintBoundary` raster isolation for smooth 60fps scrolling.
class ChampionshipsListScreen extends ConsumerWidget {
  const ChampionshipsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final championshipsAsync = ref.watch(championshipProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardSurface,
        elevation: 0,
        title: const Text(
          'Championship Titles',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.goldPrimary,
        backgroundColor: AppTheme.cardSurface,
        onRefresh: () async => ref.invalidate(championshipProvider),
        child: championshipsAsync.when(
          loading: () => ListView.separated(
            padding: const EdgeInsets.all(AppTheme.space16),
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(height: AppTheme.space12),
            itemBuilder: (_, __) => const SkeletonPlaceholder(
              height: 100,
              borderRadius: AppTheme.radiusMedium,
            ),
          ),
          error: (e, _) => AppEmptyState(
            icon: Icons.error_outline,
            title: 'Could not load championship titles',
            subtitle: e.toString(),
            ctaLabel: 'Retry',
            onCtaTap: () => ref.invalidate(championshipProvider),
          ),
          data: (championships) {
            if (championships.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  AppEmptyState(
                    icon: Icons.emoji_events_outlined,
                    title: 'No active championship titles',
                    subtitle:
                        'Official federation title belts will appear here once sanctioned.',
                  ),
                ],
              );
            }

            return ListView.separated(
              key: const PageStorageKey<String>('championships_list_view'),
              padding: const EdgeInsets.all(AppTheme.space16),
              itemCount: championships.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppTheme.space12),
              itemBuilder: (context, index) {
                final c = championships[index];
                final id = c['id']?.toString() ?? '';
                final name = c['name']?.toString() ?? 'Championship Title';
                final arm = (c['arm']?.toString() ?? 'RIGHT').toUpperCase();
                final weightClass = c['weightClass']?.toString() ?? '';
                final ageGroup = c['ageGroup']?.toString() ?? '';

                return RepaintBoundary(
                  child: ElevatedActionCard(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    onTap: id.isEmpty ? null : () => context.push('/championship/$id'),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Championship Medallion Emblem
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.elevatedSurface,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            border: Border.all(color: AppTheme.goldPrimary, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.goldPrimary.withValues(alpha: 0.15),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.military_tech,
                              color: AppTheme.goldPrimary,
                              size: 26,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.space12),
                        // Title Info & Tags
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppTheme.space8),
                              Wrap(
                                spacing: AppTheme.space6,
                                runSpacing: AppTheme.space6,
                                children: [
                                  StatusChip(
                                    label: arm.contains('RIGHT') ? 'RIGHT ARM' : 'LEFT ARM',
                                    type: StatusType.warning,
                                  ),
                                  if (weightClass.isNotEmpty)
                                    StatusChip(
                                      label: weightClass,
                                      type: StatusType.info,
                                    ),
                                  if (ageGroup.isNotEmpty)
                                    StatusChip(
                                      label: ageGroup,
                                      type: StatusType.neutral,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
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

/// Championship Detail Screen — real championship data from GET /championship/titles/:id
/// and historical reign lineage from GET /championship/titles/:id/lineage.
class ChampionshipDetailScreen extends ConsumerWidget {
  final String championshipId;

  const ChampionshipDetailScreen({super.key, required this.championshipId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titlesAsync = ref.watch(championshipProvider);
    final lineageAsync = ref.watch(beltLineageProvider(championshipId));

    final title = titlesAsync.value
        ?.where((t) => t['id']?.toString() == championshipId)
        .cast<Map<String, dynamic>?>()
        .firstWhere((t) => t != null, orElse: () => null);

    final titleName = title?['name']?.toString() ?? 'Championship Title';
    final arm = (title?['arm']?.toString() ?? 'RIGHT').toUpperCase();
    final weightClass = title?['weightClass']?.toString() ?? '';
    final ageGroup = title?['ageGroup']?.toString() ?? '';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardSurface,
        elevation: 0,
        title: const Text(
          'Title Lineage Ledger',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.goldPrimary,
        backgroundColor: AppTheme.cardSurface,
        onRefresh: () async =>
            ref.invalidate(beltLineageProvider(championshipId)),
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.space16),
          children: [
            // 1. Title Belt Dossier Card
            ElevatedActionCard(
              padding: const EdgeInsets.all(AppTheme.space16),
              borderColor: AppTheme.goldPrimary.withValues(alpha: 0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.elevatedSurface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.goldPrimary),
                        ),
                        child: const Icon(Icons.military_tech, color: AppTheme.goldPrimary, size: 24),
                      ),
                      const SizedBox(width: AppTheme.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SANCTIONED BELT',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                                color: AppTheme.goldLight,
                              ),
                            ),
                            Text(
                              titleName,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space12),
                  const Divider(height: 1, color: AppTheme.border),
                  const SizedBox(height: AppTheme.space12),
                  Wrap(
                    spacing: AppTheme.space8,
                    runSpacing: AppTheme.space6,
                    children: [
                      StatusChip(
                        label: arm.contains('RIGHT') ? 'RIGHT ARM' : 'LEFT ARM',
                        type: StatusType.warning,
                      ),
                      if (weightClass.isNotEmpty)
                        StatusChip(
                          label: weightClass,
                          type: StatusType.info,
                        ),
                      if (ageGroup.isNotEmpty)
                        StatusChip(
                          label: ageGroup,
                          type: StatusType.neutral,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space20),

            // 2. Lineage Section Header
            Row(
              children: [
                const Icon(Icons.history_edu, size: 16, color: AppTheme.goldPrimary),
                const SizedBox(width: 8),
                const Text(
                  'BELT LINEAGE & HISTORIC REIGNS',
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

            // 3. Lineage List
            lineageAsync.when(
              loading: () => Column(
                children: const [
                  SkeletonPlaceholder(height: 80, borderRadius: AppTheme.radiusMedium),
                  SizedBox(height: AppTheme.space8),
                  SkeletonPlaceholder(height: 80, borderRadius: AppTheme.radiusMedium),
                ],
              ),
              error: (e, _) => AppEmptyState(
                icon: Icons.error_outline,
                title: 'Could not load lineage',
                subtitle: e.toString(),
                ctaLabel: 'Retry',
                onCtaTap: () => ref.invalidate(beltLineageProvider(championshipId)),
              ),
              data: (lineage) {
                if (lineage.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(AppTheme.space24),
                    decoration: BoxDecoration(
                      color: AppTheme.cardSurface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(Icons.hourglass_empty, size: 32, color: AppTheme.textMuted),
                          SizedBox(height: 8),
                          Text(
                            'No reigns recorded yet',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'The lineage ledger begins once the inaugural champion is crowned.',
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    for (int i = 0; i < lineage.length; i++)
                      _ReignCard(reign: lineage[i], isCurrent: i == 0),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ReignCard extends StatelessWidget {
  final Map<String, dynamic> reign;
  final bool isCurrent;

  const _ReignCard({required this.reign, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    final defenses = reign['defensesCount'] ?? 0;
    final days = (reign['reignDays'] ?? 0).toString();
    final reason = reign['reason']?.toString() ?? '';
    final athleteId = reign['athleteId']?.toString() ?? '—';
    final shortAthleteId = athleteId.length >= 8 ? athleteId.substring(0, 8).toUpperCase() : athleteId;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space8),
      child: RepaintBoundary(
        child: ElevatedActionCard(
          padding: const EdgeInsets.all(AppTheme.space14),
          borderColor: isCurrent ? AppTheme.goldPrimary : AppTheme.border,
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isCurrent ? AppTheme.goldPrimary.withValues(alpha: 0.15) : AppTheme.elevatedSurface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCurrent ? AppTheme.goldPrimary : AppTheme.border,
                    width: 1.0,
                  ),
                ),
                child: Center(
                  child: Icon(
                    isCurrent ? Icons.emoji_events : Icons.military_tech_outlined,
                    color: isCurrent ? AppTheme.goldPrimary : AppTheme.textMuted,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Champion #$shortAthleteId',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isCurrent ? AppTheme.goldLight : AppTheme.textPrimary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        if (isCurrent)
                          const StatusChip(
                            label: 'REIGNING CHAMPION',
                            type: StatusType.warning,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '$defenses Defense(s)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const Text(' • ', style: TextStyle(color: AppTheme.textMuted)),
                        Text(
                          '$days Day(s) Reign',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        if (reason.isNotEmpty) ...[
                          const Text(' • ', style: TextStyle(color: AppTheme.textMuted)),
                          Expanded(
                            child: Text(
                              reason,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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
  }
}
