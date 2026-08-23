import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/providers/state_providers.dart';

class AthleteTrainingLogScreen extends ConsumerWidget {
  final String athleteId;

  const AthleteTrainingLogScreen({super.key, required this.athleteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // Static lists representing exercise logs and personal records (PRs)
    final prs = [
      {'exercise': 'Cupping', 'weight': '65 kg', 'date': 'Today'},
      {'exercise': 'Pronation Lift', 'weight': '48 kg', 'date': 'Yesterday'},
      {'exercise': 'Rising Lift', 'weight': '32 kg', 'date': 'Last week'},
    ];

    final logs = [
      {'exercise': 'Cupping sets', 'details': '4 sets x 8 reps @ 60kg', 'time': '9:30 AM'},
      {'exercise': 'Static Holds', 'details': '5 sets x 15s hold @ 45kg', 'time': '8:45 AM'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Log'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'PERSONAL RECORDS (PRs)',
              style: theme.textTheme.labelMedium?.copyWith(
                letterSpacing: 1.0,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: prs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = prs[index];
                return GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.emoji_events, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            item['exercise']!,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            item['weight']!,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Text(
                            item['date']!,
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurface.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            Text(
              'TODAY\'S SESSION',
              style: theme.textTheme.labelMedium?.copyWith(
                letterSpacing: 1.0,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              padding: EdgeInsets.zero,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: logs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.fitness_center, size: 16, color: theme.colorScheme.primary),
                    ),
                    title: Text(
                      log['exercise']!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Text(log['details']!, style: const TextStyle(fontSize: 12)),
                    trailing: Text(
                      log['time']!,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Log new exercise stub
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logging exercise stub')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
class AthleteTrainingLogScreenDep extends AthleteTrainingLogScreen {
  const AthleteTrainingLogScreenDep({super.key, required super.athleteId});
}
