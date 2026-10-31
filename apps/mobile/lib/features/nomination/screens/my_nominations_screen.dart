import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/nomination_provider.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/crystal_stage_scaffold.dart';
import '../../../core/widgets/crystal_glass_nav_controls.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/theme/app_theme.dart';

StatusType _resolveNominationStatusType(String status) {
  switch (status.toUpperCase()) {
    case 'APPROVED':
      return StatusType.success;
    case 'REJECTED':
      return StatusType.error;
    case 'PENDING':
    default:
      return StatusType.warning;
  }
}

class MyNominationsScreen extends ConsumerWidget {
  const MyNominationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nominationsAsync = ref.watch(nominationListProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: const CrystalBackButton(),
        title: const Text('My Nominations'),
        actions: [
          IconButton(
            tooltip: 'Nominate Talent',
            icon: const Icon(Icons.star_outline),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push('/nominate');
            },
          ),
          const CrystalHomeButton(),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CrystalStageBackdrop(domain: ArmSphereStageDomain.rankings),
          RefreshIndicator(
            onRefresh: () async => ref.invalidate(nominationListProvider),
            child: nominationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => AppErrorView(
            error: e,
            title: 'Could not load nominations',
            onRetry: () {
              HapticFeedback.lightImpact();
              ref.invalidate(nominationListProvider);
            },
            secondaryActionLabel: 'Return to Home',
            onSecondaryAction: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
          data: (nominations) {
            if (nominations.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  AppEmptyState(
                    icon: Icons.how_to_vote_outlined,
                    title: 'No active nominations',
                    subtitle: 'Nominate an athlete or referee and track its federation review progress here.',
                    ctaLabel: 'Submit a Nomination',
                    onCtaTap: () {
                      HapticFeedback.lightImpact();
                      context.push('/nominate');
                    },
                    secondaryCtaLabel: 'Return to Home',
                    onSecondaryCtaTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppTheme.space16),
              itemCount: nominations.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppTheme.space12),
              itemBuilder: (context, index) {
                final n = nominations[index];
                final title = n['nomineeName']?.toString() ?? 'Nomination Candidate';
                final status = (n['status']?.toString() ?? 'PENDING').toUpperCase();
                final created = n['createdAt']?.toString() ?? '';
                final reason = n['reason']?.toString() ?? '';

                return RepaintBoundary(
                  child: ElevatedActionCard(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppTheme.space8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.goldPrimary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                    border: Border.all(
                                      color: AppTheme.goldPrimary.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Icon(Icons.how_to_vote, size: 18, color: AppTheme.goldPrimary),
                                ),
                                const SizedBox(width: AppTheme.space10),
                                const Text(
                                  'TALENT NOMINATION',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.goldPrimary,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                            StatusChip(
                              label: status,
                              type: _resolveNominationStatusType(status),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.space14),
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (reason.isNotEmpty) ...[
                          const SizedBox(height: AppTheme.space6),
                          Text(
                            reason,
                            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.35),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: AppTheme.space14),
                        const Divider(color: AppTheme.cardBorder, height: 1),
                        const SizedBox(height: AppTheme.space10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'FEDERATION REVIEW',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                            ),
                            Text(
                              created.length >= 10 ? created.substring(0, 10) : created,
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
                );
              },
            );
          },
        ),
      ),
        ],
      ),
    );
  }
}
