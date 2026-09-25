import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/athlete_provider.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/sensory_feedback_service.dart';

/// Athlete Training Log & Personal Records (PR) Screen
///
/// Upgraded to Canonical Stage 2 Specification (Slice 11 / [P1-04] / Debt 69):
/// - ElevatedActionCard list rows with zero raster overhead.
/// - Tactile PR ceremonial feedback (`pr_achieved.wav` + heavy haptic).
/// - Space Grotesk typography for weights and performance metrics.
class AthleteTrainingLogScreen extends ConsumerWidget {
  final String athleteId;

  const AthleteTrainingLogScreen({super.key, required this.athleteId});

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

  Widget _errorView(BuildContext context, WidgetRef ref, Object e) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 80),
        const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
        const SizedBox(height: 12),
        Text(
          'Could not load training log',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(trainingLogProvider(athleteId));
              ref.invalidate(trainingLogPRsProvider(athleteId));
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prsAsync = ref.watch(trainingLogPRsProvider(athleteId));
    final logsAsync = ref.watch(trainingLogProvider(athleteId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Training Log & PRs',
          style: TextStyle(fontFamily: 'Space Grotesk', fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(trainingLogPRsProvider(athleteId));
          ref.invalidate(trainingLogProvider(athleteId));
        },
        child: logsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.goldPrimary),
          ),
          error: (e, _) => _errorView(context, ref, e),
          data: (logs) => ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              // Personal records — computed server-side from post history
              prsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(color: AppTheme.goldPrimary),
                  ),
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
                                SnackBar(
                                  content: Text('Personal Record: $exercise - ${weight ?? '—'} kg!'),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: AppTheme.elevatedSurface,
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
                                        color: AppTheme.goldPrimary.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.fitness_center, color: AppTheme.goldPrimary, size: 18),
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
                                        color: AppTheme.goldPrimary,
                                      ),
                                    ),
                                    if (date.isNotEmpty)
                                      Text(
                                        date,
                                        style: const TextStyle(
                                          fontSize: 11,
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
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

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
                  subtitle: 'Share a GYM post with your exercise details and it will appear here.',
                  ctaLabel: 'Log a Session',
                  onCtaTap: () => context.push('/community/create'),
                )
              else
                ElevatedActionCard(
                  padding: EdgeInsets.zero,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: logs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.borderSubtle),
                    itemBuilder: (context, index) {
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

                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.elevatedSurface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.fitness_center, size: 16, color: AppTheme.goldPrimary),
                        ),
                        title: Text(
                          exercise,
                          style: const TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          caption.isNotEmpty && details.isNotEmpty
                              ? '$caption ($details)'
                              : caption.isNotEmpty
                                  ? caption
                                  : details,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        trailing: Text(
                          time,
                          style: const TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'training_log_add',
        tooltip: 'Log a session',
        backgroundColor: AppTheme.goldPrimary,
        foregroundColor: Colors.black,
        onPressed: () {
          HapticFeedback.selectionClick();
          context.push('/community/create');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
