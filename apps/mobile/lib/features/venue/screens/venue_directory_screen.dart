import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/venue_provider.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/glass_card.dart';

class VenueDirectoryScreen extends ConsumerWidget {
  const VenueDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venuesAsync = ref.watch(venueListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Armwrestling Venues'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt_outlined),
            onPressed: () => context.push('/venues/submit'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(venueListProvider),
        child: venuesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 80),
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text('Could not load venues', textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () => ref.invalidate(venueListProvider),
                  child: const Text('Retry'),
                ),
              ),
            ],
          ),
          data: (venues) {
            if (venues.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  AppEmptyState(
                    icon: Icons.location_on_outlined,
                    title: 'No venues listed yet',
                    subtitle:
                        'Know a training space with official tables? Submit it for verification.',
                    ctaLabel: 'Submit a Venue',
                    onCtaTap: () => context.push('/venues/submit'),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: venues.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final v = venues[index];
                final id = v['id']?.toString() ?? '';
                final name = v['name']?.toString() ?? 'Venue';
                final addressLine = [
                  v['address']?.toString(),
                  v['city']?.toString(),
                  v['province']?.toString(),
                ].where((part) => part != null && part.isNotEmpty).join(', ');
                return GestureDetector(
                  onTap: id.isEmpty ? null : () => context.push('/venues/$id'),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 16)),
                              if (addressLine.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(addressLine,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                              ],
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
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
