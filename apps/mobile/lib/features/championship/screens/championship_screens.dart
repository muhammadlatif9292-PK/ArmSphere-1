import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/championship_provider.dart';
import '../../../core/providers/state_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/crystal_toast.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/crystal_stage_scaffold.dart';
import '../../../core/widgets/crystal_glass_nav_controls.dart';
import '../../../core/widgets/main_shell_screen.dart';
import '../../../core/widgets/skeleton_placeholder.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/providers/auth_provider.dart';

/// Domain 10 / Stage-First Living Screen Architecture: Championships List Screen
///
/// - Stage Backdrop: `ArmSphereAssets.stageChampionshipBelts` (`m1_stage_championship_belts_9x16.webp`).
/// - `165px` open top 24k Gold Belt Shrine Showcase (`y: 8%–35%`).
/// - Division filter chips (`70 KG`, `78 KG`, `86 KG`, `95 KG`, `OPEN`) and reigning champion /
///   title belt cards anchored in the lower obsidian zone (`y: 36%–90%`) with `120px` bottom clearance.
class ChampionshipsListScreen extends ConsumerStatefulWidget {
  const ChampionshipsListScreen({super.key});

  @override
  ConsumerState<ChampionshipsListScreen> createState() =>
      _ChampionshipsListScreenState();
}

class _ChampionshipsListScreenState
    extends ConsumerState<ChampionshipsListScreen> {
  static const List<String> _divisions = [
    'ALL',
    '70 KG',
    '78 KG',
    '86 KG',
    '95 KG',
    'OPEN',
  ];

  String _selectedDivision = 'ALL';

  bool _matchesDivision(Map<String, dynamic> c) {
    if (_selectedDivision == 'ALL') return true;
    final wc = (c['weightClass']?.toString() ?? '').toUpperCase();
    final name = (c['name']?.toString() ?? '').toUpperCase();
    final needle = _selectedDivision.replaceAll(' ', '');
    return wc.replaceAll(' ', '').contains(needle) ||
        name.replaceAll(' ', '').contains(needle);
  }

  @override
  Widget build(BuildContext context) {
    final championshipsAsync = ref.watch(championshipProvider);

    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: const CrystalHeaderStageBar(
          domain: ArmSphereStageDomain.championships,
        ),
        elevation: 0,
        leading: const CrystalBackButton(),
        title: const Text(
          'Championship Titles',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: const [CrystalHomeButton()],
      ),
      body: Stack(
        children: [
          const CrystalStageBackdrop(domain: ArmSphereStageDomain.championships),
          RefreshIndicator(
            color: AppTheme.goldPrimary,
            backgroundColor: AppTheme.cardSurface,
            onRefresh: () async => ref.invalidate(championshipProvider),
            child: championshipsAsync.when(
              loading: () => ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  AppTheme.space16,
                  165,
                  AppTheme.space16,
                  MainShellScope.bottomClearance(context, additionalPadding: 44),
                ),
                itemCount: 4,
                separatorBuilder: (_, __) => const SizedBox(height: AppTheme.space12),
                itemBuilder: (_, __) => const SkeletonPlaceholder(
                  height: 100,
                  borderRadius: AppTheme.radiusMedium,
                ),
              ),
              error: (e, _) => AppErrorView(
                error: e,
                title: 'Could not load championship titles',
                onRetry: () => ref.invalidate(championshipProvider),
                onSecondaryAction: () => context.go('/'),
                secondaryActionLabel: 'Return to Home',
              ),
              data: (allChampionships) {
                final championships =
                    allChampionships.where(_matchesDivision).toList();

                return ListView(
                  key: const ValueKey<String>('championships_list_view'),
                  padding: EdgeInsets.fromLTRB(
                    AppTheme.space16,
                    165,
                    AppTheme.space16,
                    MainShellScope.bottomClearance(context, additionalPadding: 44),
                  ),
                  children: [
                    // Division Filter Chips (70 KG, 78 KG, 86 KG, 95 KG, OPEN)
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _divisions.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: AppTheme.space8),
                        itemBuilder: (context, idx) {
                          final div = _divisions[idx];
                          final isSelected = _selectedDivision == div;
                          return ChoiceChip(
                            label: Text(
                              div == 'ALL' ? 'ALL DIVISIONS' : div,
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                color: isSelected
                                    ? AppTheme.voidBackground
                                    : AppTheme.textSecondary,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppTheme.goldPrimary,
                            backgroundColor: const Color(0xCC0B0F19),
                            showCheckmark: false,
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSmall),
                              side: BorderSide(
                                color: isSelected
                                    ? AppTheme.goldPrimary
                                    : const Color(0x26FFFFFF),
                              ),
                            ),
                            onSelected: (_) {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedDivision = div);
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppTheme.space14),
                    if (championships.isEmpty)
                      const AppEmptyState(
                        icon: Icons.emoji_events_outlined,
                        title: 'No active championship titles',
                        subtitle:
                            'Official federation title belts will appear here once sanctioned.',
                      )
                    else
                      ...List.generate(championships.length, (index) {
                        final c = championships[index];
                        final id = c['id']?.toString() ?? '';
                        final name =
                            c['name']?.toString() ?? 'Championship Title';
                        final arm =
                            (c['arm']?.toString() ?? 'RIGHT').toUpperCase();
                        final weightClass =
                            c['weightClass']?.toString() ?? '';
                        final ageGroup =
                            (c['division'] ?? c['ageGroup'])?.toString() ?? '';

                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == championships.length - 1
                                ? 0
                                : AppTheme.space12,
                          ),
                          child: RepaintBoundary(
                            child: ElevatedActionCard(
                              padding: const EdgeInsets.all(AppTheme.space16),
                              onTap: id.isEmpty
                                  ? null
                                  : () => context.push('/championship/$id'),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Championship Medallion Emblem
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppTheme.glassSurface,
                                      borderRadius: BorderRadius.circular(
                                          AppTheme.radiusSmall),
                                      border: Border.all(
                                          color: AppTheme.goldPrimary,
                                          width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.goldPrimary
                                              .withValues(alpha: 0.15),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                              label: arm.contains('RIGHT')
                                                  ? 'RIGHT ARM'
                                                  : 'LEFT ARM',
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
                          ),
                        );
                      }),
                  ],
                );
              },
            ),
          ),
        ],
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
    final challengesAsync = ref.watch(championshipChallengesProvider);
    final authState = ref.watch(authProvider);

    final title = titlesAsync.value
        ?.where((t) => t['id']?.toString() == championshipId)
        .cast<Map<String, dynamic>?>()
        .firstWhere((t) => t != null, orElse: () => null);

    final titleName = title?['name']?.toString() ?? 'Championship Title';
    final arm = (title?['arm']?.toString() ?? 'RIGHT').toUpperCase();
    final weightClass = title?['weightClass']?.toString() ?? '';
    final ageGroup = (title?['division'] ?? title?['ageGroup'])?.toString() ?? '';
    final currentHolderId = title?['currentHolderId']?.toString() ??
        (title?['currentHolder'] is Map ? title!['currentHolder']['id']?.toString() : null) ??
        '';
    final currentHolderName = title?['currentHolderName']?.toString() ??
        (title?['currentHolder'] is Map ? title!['currentHolder']['displayName']?.toString() : null) ??
        'Vacant Belt';
    final userId = authState.userProfile?['id']?.toString() ??
        authState.userProfile?['athleteId']?.toString() ??
        '';

    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: const CrystalHeaderStageBar(
          domain: ArmSphereStageDomain.championships,
        ),
        elevation: 0,
        leading: const CrystalBackButton(),
        title: const Text(
          'Title Lineage Ledger',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: const [CrystalHomeButton()],
      ),
      body: Stack(
        children: [
          const CrystalStageBackdrop(domain: ArmSphereStageDomain.championships),
          RefreshIndicator(
            color: AppTheme.goldPrimary,
            backgroundColor: AppTheme.cardSurface,
            onRefresh: () async {
              ref.invalidate(beltLineageProvider(championshipId));
              ref.invalidate(championshipChallengesProvider);
            },
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                AppTheme.space16,
                165,
                AppTheme.space16,
                MainShellScope.bottomClearance(context, additionalPadding: 44),
              ),
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
                              color: AppTheme.glassSurface,
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
                  const SizedBox(height: AppTheme.space14),
                  const Divider(height: 1, color: AppTheme.border),
                  const SizedBox(height: AppTheme.space12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'REIGNING CHAMPION',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentHolderName,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.goldLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          final effectiveChallengerId = userId.isNotEmpty
                              ? userId
                              : '00000000-0000-0000-0000-000000000001';
                          try {
                            await ref.read(championshipRepositoryProvider).submitChallenge(
                                  titleId: championshipId,
                                  challengerId: effectiveChallengerId,
                                );
                            ref.invalidate(championshipChallengesProvider);
                            if (context.mounted) {
                              CrystalToast.show(
                                context,
                                title: 'Challenge Issued',
                                message: 'Official title challenge filed for $titleName.',
                                type: CrystalToastType.success,
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              CrystalToast.show(
                                context,
                                title: 'Challenge Logged',
                                message: 'Unable to submit live challenge: $e',
                                type: CrystalToastType.warning,
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.goldPrimary,
                          foregroundColor: AppTheme.voidBackground,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                        ),
                        icon: const Icon(Icons.sports_mma_rounded, size: 16),
                        label: const Text(
                          'ISSUE CHALLENGE',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space16),

            // 1b. Active Title Challenges Section
            challengesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (allChallenges) {
                final beltChallenges = allChallenges.where((c) {
                  final cid = (c['titleId'] ?? c['championshipTitleId'] ?? '').toString();
                  return cid.isEmpty || cid == championshipId;
                }).toList();
                if (beltChallenges.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.bolt_rounded, size: 16, color: AppTheme.goldPrimary),
                        SizedBox(width: 6),
                        Text(
                          'ACTIVE CONTENDER CHALLENGES',
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
                    const SizedBox(height: AppTheme.space10),
                    for (final ch in beltChallenges)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppTheme.space8),
                        child: ElevatedActionCard(
                          padding: const EdgeInsets.all(AppTheme.space12),
                          child: Builder(
                            builder: (context) {
                              final challengeId = ch['id']?.toString() ?? '';
                              final challengerName = ch['challengerName']?.toString() ??
                                  (ch['challenger'] is Map
                                      ? ch['challenger']['displayName']?.toString()
                                      : null) ??
                                  'Sanctioned Contender';
                              final status = (ch['status']?.toString() ?? 'PENDING').toUpperCase();
                              final isPending = status == 'PENDING';
                              final canRespond = isPending &&
                                  (currentHolderId.isEmpty ||
                                      currentHolderId == userId ||
                                      (authState.activeRole ?? '').contains('ADMIN'));

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '$challengerName vs. $currentHolderName',
                                          style: const TextStyle(
                                            fontFamily: AppTheme.fontDisplay,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13.5,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                      ),
                                      StatusChip(
                                        label: status,
                                        type: status == 'ACCEPTED'
                                            ? StatusType.success
                                            : (status == 'DECLINED' ? StatusType.error : StatusType.warning),
                                      ),
                                    ],
                                  ),
                                  if (canRespond && challengeId.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton(
                                          onPressed: () async {
                                            HapticFeedback.selectionClick();
                                            try {
                                              await ref
                                                  .read(championshipRepositoryProvider)
                                                  .respondToChallenge(
                                                    challengeId: challengeId,
                                                    accept: false,
                                                  );
                                              ref.invalidate(championshipChallengesProvider);
                                              if (context.mounted) {
                                                CrystalToast.show(
                                                  context,
                                                  title: 'Challenge Declined',
                                                  message: 'Contender challenge declined.',
                                                  type: CrystalToastType.info,
                                                );
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                CrystalToast.show(
                                                  context,
                                                  title: 'Action Failed',
                                                  message: '$e',
                                                  type: CrystalToastType.error,
                                                );
                                              }
                                            }
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppTheme.crimsonPrimary,
                                            side: const BorderSide(color: AppTheme.crimsonPrimary),
                                            minimumSize: const Size(76, 32),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          ),
                                          child: const Text('DECLINE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () async {
                                            HapticFeedback.mediumImpact();
                                            try {
                                              await ref
                                                  .read(championshipRepositoryProvider)
                                                  .respondToChallenge(
                                                    challengeId: challengeId,
                                                    accept: true,
                                                  );
                                              ref.invalidate(championshipChallengesProvider);
                                              if (context.mounted) {
                                                CrystalToast.show(
                                                  context,
                                                  title: 'Challenge Accepted',
                                                  message: 'Title bout challenge accepted for sanctioning.',
                                                  type: CrystalToastType.success,
                                                );
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                CrystalToast.show(
                                                  context,
                                                  title: 'Action Failed',
                                                  message: '$e',
                                                  type: CrystalToastType.error,
                                                );
                                              }
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.success,
                                            foregroundColor: AppTheme.voidBackground,
                                            minimumSize: const Size(76, 32),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          ),
                                          child: const Text('ACCEPT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: AppTheme.space12),
                  ],
                );
              },
            ),

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
              error: (e, _) => AppErrorView(
                error: e,
                title: 'Could not load lineage',
                onRetry: () => ref.invalidate(beltLineageProvider(championshipId)),
                onSecondaryAction: () => context.pop(),
                secondaryActionLabel: 'Back to Championships',
              ),
              data: (lineage) {
                if (lineage.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(AppTheme.space24),
                    decoration: BoxDecoration(
                      color: AppTheme.glassSurface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      border: Border.all(color: AppTheme.borderTitanium),
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
                      _ReignCard(
                        reign: lineage[i],
                        isCurrent: i == 0 && lineage[i]['vacatedAt'] == null,
                      ),
                  ],
                );
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

class _ReignCard extends StatelessWidget {
  final Map<String, dynamic> reign;
  final bool isCurrent;

  const _ReignCard({required this.reign, required this.isCurrent});

  int _computeReignDays() {
    final explicitDays = reign['reignDays'];
    if (explicitDays is num) return explicitDays.toInt();
    final acquiredStr = reign['acquiredAt']?.toString();
    if (acquiredStr == null) return 0;
    final acquired = DateTime.tryParse(acquiredStr);
    if (acquired == null) return 0;
    final vacatedStr = reign['vacatedAt']?.toString();
    final end = (vacatedStr != null ? DateTime.tryParse(vacatedStr) : null) ?? DateTime.now();
    final diff = end.difference(acquired).inDays;
    return diff < 0 ? 0 : diff;
  }

  @override
  Widget build(BuildContext context) {
    final defenses = reign['defensesCount'] ?? 0;
    final days = _computeReignDays().toString();
    final reason = reign['reason']?.toString() ?? '';
    final displayName = reign['displayName']?.toString() ?? '';
    final athleteId = reign['athleteId']?.toString() ?? '—';
    final shortAthleteId = athleteId.length >= 8 ? athleteId.substring(0, 8).toUpperCase() : athleteId;
    final championLabel = displayName.isNotEmpty ? displayName : 'Champion #$shortAthleteId';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space8),
      child: RepaintBoundary(
        child: ElevatedActionCard(
          padding: const EdgeInsets.all(AppTheme.space14),
          borderColor: isCurrent ? AppTheme.goldPrimary : AppTheme.borderTitanium,
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isCurrent ? AppTheme.goldPrimary.withValues(alpha: 0.15) : AppTheme.glassSurface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCurrent ? AppTheme.goldPrimary : AppTheme.borderTitanium,
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
                        Flexible(
                          child: Text(
                            championLabel,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isCurrent ? AppTheme.goldLight : AppTheme.textPrimary,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
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
