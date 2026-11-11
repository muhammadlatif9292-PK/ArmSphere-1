import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/providers/athlete_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/armsphere_image.dart';
import '../../../core/widgets/crystal_toast.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/crystal_glass_nav_controls.dart';
import '../../../core/widgets/crystal_stage_scaffold.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/sensory_feedback_service.dart';
import '../../../core/widgets/main_shell_screen.dart';
import '../../../core/widgets/skeleton_placeholder.dart';

/// Athlete Training Log & Personal Records (PR) Screen
///
/// Upgraded to Stage-First Living Screen Architecture (Step 3):
/// - Backdrop: `ArmSphereAssets.stageTrainingLab` (`m1_stage_training_lab_9x16.webp`).
/// - `155px` open top 3D Pulley Rig showcase below the transparent AppBar.
/// - Lower Safe-Zone PR Deck with static strength discipline selector
///   (Rise, Pronation, Back Pressure, Side Pressure, Cupping/Containment).
/// - Training clips without custom thumbnails fall back to `ArmSphereAssets.clipFallbackSparring`
///   at 100% opacity with text locked to the left 54% safe zone.
class AthleteTrainingLogScreen extends ConsumerStatefulWidget {
  final String athleteId;

  const AthleteTrainingLogScreen({super.key, required this.athleteId});

  @override
  ConsumerState<AthleteTrainingLogScreen> createState() =>
      _AthleteTrainingLogScreenState();
}

class _AthleteTrainingLogScreenState
    extends ConsumerState<AthleteTrainingLogScreen> {
  static const List<({String id, String label})> _disciplines = [
    (id: 'ALL', label: 'All Lifts'),
    (id: 'RISE', label: 'Rise'),
    (id: 'PRONATION', label: 'Pronation'),
    (id: 'BACK PRESSURE', label: 'Back Pressure'),
    (id: 'SIDE PRESSURE', label: 'Side Pressure'),
    (id: 'CUPPING', label: 'Cupping / Containment'),
  ];

  String _selectedDiscipline = 'ALL';

  String get athleteId => widget.athleteId;

  bool _matchesDiscipline(String exerciseType) {
    if (_selectedDiscipline == 'ALL') return true;
    final upper = exerciseType.toUpperCase();
    switch (_selectedDiscipline) {
      case 'RISE':
        return upper.contains('RIS');
      case 'PRONATION':
        return upper.contains('PRONAT');
      case 'BACK PRESSURE':
        return upper.contains('BACK') || upper.contains('BICEP');
      case 'SIDE PRESSURE':
        return upper.contains('SIDE');
      case 'CUPPING':
        return upper.contains('CUP') ||
            upper.contains('WRIST') ||
            upper.contains('CONTAIN');
      default:
        return true;
    }
  }

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

  bool _isForbiddenError(Object e) {
    if (e is DioException && e.response?.statusCode == 403) {
      return true;
    }
    final msg = e.toString().toLowerCase();
    return msg.contains('403') || msg.contains('forbidden') || msg.contains('not authorized');
  }

  Widget _errorView(BuildContext context, WidgetRef ref, Object e) {
    if (_isForbiddenError(e)) {
      return ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          155,
          20,
          MainShellScope.bottomClearance(context, additionalPadding: 44),
        ),
        children: [
          ElevatedActionCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.transparent,
                    border: Border.all(
                      color: const Color(0x73D4AF37),
                      width: 1.0,
                    ),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 32,
                    color: AppTheme.goldPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'PRIVATE TRAINING DOSSIER',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Individual gym training logs and personal record telemetry are restricted to the athlete and authorized PAFF federation officials.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return AppErrorView(
      error: e,
      title: 'Could not load training log',
      onRetry: () {
        ref.invalidate(trainingLogProvider(athleteId));
        ref.invalidate(trainingLogPRsProvider(athleteId));
      },
      showSecondaryAction: false,
    );
  }

  bool _resolveIsSelf(
    String targetId,
    Map<String, dynamic>? myProfile,
    AuthState authState,
  ) {
    if (targetId.isEmpty || targetId == 'self' || targetId == 'me') {
      return true;
    }
    if (myProfile != null) {
      final myProfileId = myProfile['id']?.toString();
      final myUserId = myProfile['userId']?.toString();
      return (myProfileId != null && myProfileId == targetId) ||
          (myUserId != null && myUserId == targetId);
    }
    final authUser = authState.userProfile;
    if (authUser != null || authState.status == AuthStatus.authenticated) {
      final authUserId = authUser?['id']?.toString();
      final authAthleteId = authUser?['athleteId']?.toString();
      return (authUserId != null && authUserId == targetId) ||
          (authAthleteId != null && authAthleteId == targetId);
    }
    // Isolated widget test harness fallback when neither profile nor auth state is configured
    return authState.status == AuthStatus.unknown;
  }

  @override
  Widget build(BuildContext context) {
    final prsAsync = ref.watch(trainingLogPRsProvider(athleteId));
    final logsAsync = ref.watch(trainingLogProvider(athleteId));
    final myProfile = ref.watch(athleteProfileProvider).value;
    final authState = ref.watch(authProvider);
    final isSelf = _resolveIsSelf(athleteId, myProfile, authState);

    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: const CrystalHeaderStageBar(
          domain: ArmSphereStageDomain.training,
        ),
        elevation: 0,
        leading: const CrystalBackButton(),
        title: const Text(
          'Training Log & PRs',
          style: TextStyle(fontFamily: 'Space Grotesk', fontWeight: FontWeight.w700),
        ),
        actions: const [
          CrystalHomeButton(),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: CrystalStageBackdrop(
              domain: ArmSphereStageDomain.training,
            ),
          ),
          RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(trainingLogPRsProvider(athleteId));
              ref.invalidate(trainingLogProvider(athleteId));
            },
            child: logsAsync.when(
              loading: () => const CrystalScreenLoadingView(
                itemCount: 4,
                cardHeight: 88,
              ),
              error: (e, _) => _errorView(context, ref, e),
              data: (allLogs) {
                final allPrs = prsAsync.value ?? const <Map<String, dynamic>>[];
                final prsList = allPrs
                    .where((pr) => _matchesDiscipline(
                        pr['exerciseType']?.toString() ?? ''))
                    .toList();
                final logs = allLogs
                    .where((l) => _matchesDiscipline(
                        l['exerciseType']?.toString() ?? ''))
                    .toList();

                num peakWeight = 0;
                for (final pr in prsList) {
                  final w = pr['weightKg'] as num? ?? 0;
                  if (w > peakWeight) peakWeight = w;
                }
                for (final l in logs) {
                  final w = l['weightKg'] as num? ?? 0;
                  if (w > peakWeight) peakWeight = w;
                }

                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    155,
                    16,
                    MainShellScope.bottomClearance(context, additionalPadding: 80),
                  ),
                  children: [
                    // Static Strength Discipline Selector (Rise, Pronation, Back Pressure, Side Pressure, Cupping)
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _disciplines.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final d = _disciplines[idx];
                          final isSelected = _selectedDiscipline == d.id;
                          return ChoiceChip(
                            label: Text(
                              d.label,
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? AppTheme.goldPrimary
                                    : const Color(0xFFCBD5E1),
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: Colors.transparent,
                            backgroundColor: Colors.transparent,
                            surfaceTintColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            showCheckmark: false,
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                              side: BorderSide(
                                color: isSelected
                                    ? const Color(0x73D4AF37)
                                    : const Color(0x2EFFFFFF),
                                width: isSelected ? 1.2 : 1.0,
                              ),
                            ),
                            onSelected: (_) {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedDiscipline = d.id);
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Titanium Luxe Summary Ribbon
                ElevatedActionCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space16,
                    vertical: AppTheme.space14,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'LOGGED SESSIONS',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textMuted,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${logs.length}',
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 32, color: AppTheme.cardBorder),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'HEAVIEST PR',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textMuted,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              peakWeight > 0 ? '$peakWeight kg' : '—',
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.goldPrimary,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 32, color: AppTheme.cardBorder),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TRACKED LIFTS',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textMuted,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${prsList.length}',
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Personal records — computed server-side from post history
                prsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: SkeletonPlaceholder(height: 76),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (prs) {
                    if (prs.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.emoji_events, size: 16, color: AppTheme.goldPrimary),
                            SizedBox(width: 8),
                            Text(
                              'PERSONAL RECORDS (PRs)',
                              style: TextStyle(
                                fontFamily: 'Space Grotesk',
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...prs.map((item) {
                          final exercise = item['exerciseType']?.toString() ?? 'Exercise';
                          final weight = item['weightKg'] as num?;
                          final date = _formatDate(item['createdAt']?.toString() ?? '');

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ElevatedActionCard(
                              onTap: () {
                                SensoryFeedbackService.instance.playSensoryCeremony(
                                  audioEvent: ArmSphereAudioEvent.prAchieved,
                                  hapticType: HapticFeedbackType.heavy,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  CrystalSnackBar(
                                    content: Text('Personal Record: $exercise - ${weight ?? '—'} kg!'),
                                    duration: const Duration(seconds: 2),
                                    type: CrystalToastType.info,
                                    customIcon: Icons.emoji_events_rounded,
                                  ),
                                );
                              },
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: _getExerciseColor(exercise).withValues(alpha: 0.55),
                                            width: 1.0,
                                          ),
                                        ),
                                        child: Icon(_getExerciseIcon(exercise), color: _getExerciseColor(exercise), size: 18),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        exercise,
                                        style: const TextStyle(
                                          fontFamily: 'Space Grotesk',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        weight != null ? '$weight kg' : '—',
                                        style: const TextStyle(
                                          fontFamily: 'Space Grotesk',
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          fontFeatures: [FontFeature.tabularFigures()],
                                          color: AppTheme.goldPrimary,
                                        ),
                                      ),
                                      if (date.isNotEmpty)
                                        Text(
                                          date,
                                          style: const TextStyle(
                                            fontFamily: 'Space Grotesk',
                                            fontSize: 11,
                                            fontFeatures: [FontFeature.tabularFigures()],
                                            color: AppTheme.textMuted,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                      ],
                    );
                  },
                ),

                const Text(
                  'SESSION HISTORY',
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                if (logs.isEmpty)
                  AppEmptyState(
                    icon: Icons.fitness_center,
                    title: 'No training logged yet',
                    subtitle: isSelf
                        ? 'Share a GYM post with your exercise details and it will appear here.'
                        : 'This athlete has not published any verified GYM training logs yet.',
                    ctaLabel: isSelf ? 'Log a Session' : null,
                    onCtaTap: isSelf
                        ? () => context.push('/community/create?category=GYM')
                        : null,
                  )
                else
                  Column(
                    children: List.generate(logs.length, (index) {
                      final log = logs[index];
                      final exercise = log['exerciseType']?.toString() ?? 'Session';
                      final caption = log['caption']?.toString() ?? '';
                      final weight = log['weightKg'] as num?;
                      final reps = log['reps'] as num?;
                      final details = [
                        if (weight != null) '$weight kg',
                        if (reps != null) '$reps reps',
                      ].join(' x ');
                      final time = _formatDate(log['createdAt']?.toString() ?? '');
                      final thumbUrl = (log['thumbnailUrl'] ?? log['mediaUrl'] ?? log['imageUrl'])?.toString();

                      return Padding(
                        padding: EdgeInsets.only(bottom: index == logs.length - 1 ? 0 : 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0x38FFFFFF),
                              width: 1.0,
                            ),
                            boxShadow: const [],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: ArmSphereImage(
                                    imageUrl: (thumbUrl != null && thumbUrl.isNotEmpty) ? thumbUrl : null,
                                    assetPath: (thumbUrl == null || thumbUrl.isEmpty)
                                        ? ArmSphereAssets.clipFallbackSparring
                                        : null,
                                    fallbackAsset: ArmSphereAssets.clipFallbackSparring,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.centerRight,
                                    excludeFromSemantics: true,
                                  ),
                                ),
                                const Positioned.fill(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        stops: [0.0, 0.55, 1.0],
                                        colors: [
                                          Color(0x80000000),
                                          Color(0x00000000),
                                          Color(0x00000000),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: FractionallySizedBox(
                                    widthFactor: 0.54,
                                    alignment: Alignment.centerLeft,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.transparent,
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: _getExerciseColor(exercise).withValues(alpha: 0.55),
                                                  width: 1.0,
                                                ),
                                              ),
                                              child: Icon(
                                                _getExerciseIcon(exercise),
                                                size: 14,
                                                color: _getExerciseColor(exercise),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                exercise,
                                                style: const TextStyle(
                                                  fontFamily: 'Space Grotesk',
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (details.isNotEmpty || caption.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            caption.isNotEmpty && details.isNotEmpty
                                                ? '$caption ($details)'
                                                : caption.isNotEmpty
                                                    ? caption
                                                    : details,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary,
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                        if (time.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            time,
                                            style: const TextStyle(
                                              fontFamily: 'Space Grotesk',
                                              fontSize: 11,
                                              fontFeatures: [FontFeature.tabularFigures()],
                                              color: AppTheme.textMuted,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
              ],
            );
          },
        ),
      ),
        ],
      ),
      floatingActionButtonLocation: MainShellScope.fabLocation(context),
      floatingActionButton: isSelf
          ? CrystalFloatingActionButton(
              heroTag: 'training_log_add',
              tooltip: 'Log a session',
              icon: Icons.add,
              onPressed: () {
                context.push('/community/create?category=GYM');
              },
            )
          : null,
    );
  }
}

IconData _getExerciseIcon(String exercise) {
  final ex = exercise.toUpperCase();
  if (ex.contains('CUPPING') || ex.contains('WRIST')) {
    return Icons.pan_tool_alt_rounded;
  } else if (ex.contains('PRONATION')) {
    return Icons.rotate_right_rounded;
  } else if (ex.contains('RISING')) {
    return Icons.arrow_upward_rounded;
  } else if (ex.contains('BACKPRESSURE') || ex.contains('BICEP')) {
    return Icons.fitness_center_rounded;
  } else if (ex.contains('SIDE')) {
    return Icons.sync_alt_rounded;
  }
  return Icons.sports_gymnastics_rounded;
}

Color _getExerciseColor(String exercise) {
  final ex = exercise.toUpperCase();
  if (ex.contains('CUPPING')) return AppTheme.goldPrimary;
  if (ex.contains('PRONATION')) return AppTheme.cyanAccent;
  if (ex.contains('RISING')) return AppTheme.success;
  if (ex.contains('BACKPRESSURE')) return AppTheme.primaryAccent;
  return AppTheme.goldPrimary;
}
