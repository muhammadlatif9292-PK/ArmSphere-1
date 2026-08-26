import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/social_provider.dart';
import '../../../core/providers/tournament_provider.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/glass_card.dart';

/// Blocked Users Screen
class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedAsync = ref.watch(blockedUsersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Blocked Users')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(blockedUsersProvider),
        child: blockedAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 80),
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text('Could not load blocked users', textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () => ref.invalidate(blockedUsersProvider),
                  child: const Text('Retry'),
                ),
              ),
            ],
          ),
          data: (blocked) {
            if (blocked.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  AppEmptyState(
                    icon: Icons.block_outlined,
                    title: 'No blocked users',
                    subtitle:
                        'People you block will no longer be able to interact with you.',
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: blocked.length,
              itemBuilder: (context, index) {
                final user = blocked[index];
                final name = user['displayName']?.toString() ?? 'User';
                final location = [
                  user['city']?.toString(),
                  user['province']?.toString(),
                ].where((v) => v != null && v.isNotEmpty).join(', ');
                final id = user['id']?.toString() ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: ListTile(
                      title: Text(name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(location.isEmpty ? 'Blocked' : location),
                      trailing: OutlinedButton(
                        onPressed: id.isEmpty
                            ? null
                            : () => ref
                                .read(blockedUsersProvider.notifier)
                                .unblockUser(id),
                        child: const Text('Unblock'),
                      ),
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

/// My Tickets Screen
class MyTicketsScreen extends ConsumerWidget {
  const MyTicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(myTicketsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Tickets & Passes')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myTicketsProvider),
        child: ticketsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 80),
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text('Could not load tickets', textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () => ref.invalidate(myTicketsProvider),
                  child: const Text('Retry'),
                ),
              ),
            ],
          ),
          data: (tickets) {
            if (tickets.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  AppEmptyState(
                    icon: Icons.confirmation_number_outlined,
                    title: 'No purchased tickets',
                    subtitle:
                        'Passes you purchase for events will appear here.',
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                final event = ticket['event'] as Map<String, dynamic>?;
                final tier = ticket['ticketType'] as Map<String, dynamic>?;
                final eventName =
                    event?['name']?.toString() ?? 'Event';
                final accessSpec = tier?['name']?.toString();
                final startDate = event?['startDate']?.toString() ?? '';
                final location = [
                  event?['city']?.toString(),
                  event?['province']?.toString(),
                ].where((v) => v != null && v.isNotEmpty).join(', ');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(Icons.confirmation_number,
                                size: 36),
                            if (accessSpec != null && accessSpec.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(accessSpec,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(eventName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        if (location.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(location,
                              style: const TextStyle(fontSize: 13)),
                        ],
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                              startDate.length >= 10
                                  ? startDate.substring(0, 10)
                                  : startDate,
                              style:
                                  const TextStyle(fontSize: 11)),
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
