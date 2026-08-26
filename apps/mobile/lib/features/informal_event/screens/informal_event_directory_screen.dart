import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/informal_event_provider.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/glass_card.dart';

class InformalEventDirectoryScreen extends ConsumerWidget {
  const InformalEventDirectoryScreen({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(informalEventListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice Meetups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => context.push('/informal-events/create'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(informalEventListProvider),
        child: eventsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 80),
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text('Could not load practice meetups', textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () => ref.invalidate(informalEventListProvider),
                  child: const Text('Retry'),
                ),
              ),
            ],
          ),
          data: (events) {
            if (events.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  AppEmptyState(
                    icon: Icons.sports_martial_arts_outlined,
                    title: 'No upcoming meetups',
                    subtitle:
                        'Practice meetups near you will appear here. Host one to get started.',
                    ctaLabel: 'Host a Meetup',
                    onCtaTap: () => context.push('/informal-events/create'),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final e = events[index];
                final id = e['id']?.toString() ?? '';
                final title = e['title']?.toString() ?? 'Meetup';
                final city = e['city']?.toString() ?? '';
                final date = _formatDate(e['scheduledAt']?.toString() ?? '');
                final participantCount =
                    (e['participantCount'] as num?)?.toInt() ?? 0;
                return GestureDetector(
                  onTap: () => context.push('/informal-events/$id'),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(city,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text('$participantCount joined',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.5))),
                            ],
                          ),
                        ),
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
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
