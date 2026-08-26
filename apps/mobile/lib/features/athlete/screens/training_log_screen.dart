import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/athlete_provider.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/glass_card.dart';

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
        const Icon(Icons.error_outline, size: 48),
        const SizedBox(height: 12),
        Text('Could not load training log', textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton(
            onPressed: () {
              ref.invalidate(trainingLogProvider(athleteId));
              ref.invalidate(trainingLogPRsProvider(athleteId));
            },
            child: const Text('Retry'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final prsAsync = ref.watch(trainingLogPRsProvider(athleteId));
    final logsAsync = ref.watch(trainingLogProvider(athleteId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Log'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(trainingLogPRsProvider(athleteId));
          ref.invalidate(trainingLogProvider(athleteId));
        },
        child: logsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _errorView(context, ref, e),
          data: (logs) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Personal records — computed server-side from post history
              prsAsync.when(
                loading: () => const Center(
                    child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                )),
                error: (_, __) => const SizedBox.shrink(),
                data: (prs) {
                  if (prs.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'PERSONAL RECORDS (PRs)',
                        style: theme.textTheme.labelMedium?.copyWith(
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.bold,
                          color:
                              theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...prs.map((item) {
                        final exercise =
                            item['exerciseType']?.toString() ?? 'Exercise';
                        final weight = item['weightKg'] as num?;
                        final date =
                            _formatDate(item['createdAt']?.toString() ?? '');
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.emoji_events,
                                        color: theme.colorScheme.primary,
                                        size: 20),
                                    const SizedBox(width: 12),
                                    Text(exercise,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      weight != null ? '${weight} kg' : '-',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    if (date.isNotEmpty)
                                      Text(
                                        date,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.4),
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

              Text(
                'SESSION HISTORY',
                style: theme.textTheme.labelMedium?.copyWith(
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 12),
              if (logs.isEmpty)
                AppEmptyState(
                  icon: Icons.fitness_center,
                  title: 'No training logged yet',
                  subtitle:
                      'Share a GYM post with your exercise details and it will appear here.',
                  ctaLabel: 'Log a Session',
                  onCtaTap: () => context.push('/community/create'),
                )
              else
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: logs.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final exercise =
                          log['exerciseType']?.toString() ?? 'Session';
                      final caption = log['caption']?.toString() ?? '';
                      final weight = log['weightKg'] as num?;
                      final reps = log['reps'] as num?;
                      final details = [
                        if (weight != null) '${weight} kg',
                        if (reps != null) '$reps reps',
                      ].join(' x ');
                      final time =
                          _formatDate(log['createdAt']?.toString() ?? '');
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                theme.colorScheme.primary.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.fitness_center,
                              size: 16, color: theme.colorScheme.primary),
                        ),
                        title: Text(
                          exercise,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text(
                          caption.isNotEmpty && details.isNotEmpty
                              ? '$caption ($details)'
                              : caption.isNotEmpty
                                  ? caption
                                  : details,
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Text(
                          time,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.4),
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
        onPressed: () => context.push('/community/create'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
