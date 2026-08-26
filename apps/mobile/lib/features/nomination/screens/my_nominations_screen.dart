import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/nomination_provider.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/theme/app_theme.dart';

class MyNominationsScreen extends ConsumerWidget {
  const MyNominationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nominationsAsync = ref.watch(nominationListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Nominations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.star_outline),
            onPressed: () => context.push('/nominate'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(nominationListProvider),
        child: nominationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 80),
              const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 12),
              Text('Could not load nominations', textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () => ref.invalidate(nominationListProvider),
                  child: const Text('Retry'),
                ),
              ),
            ],
          ),
          data: (nominations) {
            if (nominations.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  AppEmptyState(
                    icon: Icons.how_to_vote_outlined,
                    title: 'No active nominations',
                    subtitle:
                        'Nominate an athlete or referee and track its progress here.',
                    ctaLabel: 'Submit a Nomination',
                    onCtaTap: () => context.push('/nominate'),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: nominations.length,
              itemBuilder: (context, index) {
                final n = nominations[index];
                final title = n['nomineeName']?.toString() ?? 'Nomination';
                final status = (n['status']?.toString() ?? '').toUpperCase();
                final created = n['createdAt']?.toString() ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Status: ${status.isEmpty ? 'PENDING' : status}',
                          style: const TextStyle(
                              color: AppTheme.secondaryAccent,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                            created.length >= 10
                                ? created.substring(0, 10)
                                : created,
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textMuted)),
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
