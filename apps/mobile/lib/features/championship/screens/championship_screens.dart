import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/championship_provider.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/glass_card.dart';

class ChampionshipsListScreen extends ConsumerWidget {
  const ChampionshipsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final championshipsAsync = ref.watch(championshipProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Championship Leagues'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(championshipProvider),
        child: championshipsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 80),
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text('Could not load championships', textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () => ref.invalidate(championshipProvider),
                  child: const Text('Retry'),
                ),
              ),
            ],
          ),
          data: (championships) {
            if (championships.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  AppEmptyState(
                    icon: Icons.emoji_events_outlined,
                    title: 'No active titles',
                    subtitle:
                        'Championship titles will appear once the federation activates them.',
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: championships.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final c = championships[index];
                final id = c['id']?.toString() ?? '';
                final name = c['name']?.toString() ?? 'Title';
                final meta = [
                  c['arm']?.toString(),
                  c['weightClass']?.toString(),
                  c['ageGroup']?.toString(),
                ].where((v) => v != null && v.isNotEmpty).join(' • ');
                return GestureDetector(
                  onTap: id.isEmpty ? null : () => context.push('/championship/$id'),
                  child: GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (meta.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            meta,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Championship Details'),
      ),
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.invalidate(beltLineageProvider(championshipId)),
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            GlassCard(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title?['name']?.toString() ?? 'Championship Title',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    [
                      title?['arm']?.toString(),
                      title?['weightClass']?.toString(),
                      title?['ageGroup']?.toString(),
                    ]
                        .where((v) => v != null && v.isNotEmpty)
                        .join(' • '),
                    style: const TextStyle(height: 1.5, fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('BELT LINEAGE',
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(letterSpacing: 1.0, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            lineageAsync.when(
              loading: () => const Center(
                  child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )),
              error: (e, _) => GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                        child: Text('Could not load lineage: $e',
                            style: const TextStyle(fontSize: 13))),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(beltLineageProvider(championshipId)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (lineage) {
                if (lineage.isEmpty) {
                  return GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: ListTile(
                      leading: const Icon(Icons.hourglass_empty),
                      title: const Text('No reigns recorded yet'),
                      subtitle: const Text(
                          'The lineage appears once a champion is crowned.'),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final reign in lineage)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: ListTile(
                            leading: const Icon(Icons.military_tech),
                            title: Text(
                                'Champion #${reign['athleteId']?.toString() ?? '—'}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text(
                              '${reign['defensesCount'] ?? 0} defense(s)'
                              ' • ${(reign['reignDays'] ?? 0).toString()} day(s)'
                              '${reign['reason'] != null ? ' • ${reign['reason']}' : ''}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
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
