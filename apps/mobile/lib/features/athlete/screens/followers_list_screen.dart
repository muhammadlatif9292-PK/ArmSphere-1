import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/providers/state_providers.dart';

/// Followers List Screen
class FollowersListScreen extends ConsumerWidget {
  final String athleteId;

  const FollowersListScreen({super.key, required this.athleteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final followers = [
      {'name': 'Zain "The Zephyr" Shah', 'location': 'Islamabad, Pakistan'},
      {'name': 'Arsalan "Apex" Malik', 'location': 'Karachi, Pakistan'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Followers'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: followers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = followers[index];
          return GlassCard(
            padding: const EdgeInsets.all(12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                child: const Icon(Icons.person),
              ),
              title: Text(item['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(item['location']!, style: const TextStyle(fontSize: 12)),
              trailing: TextButton(
                onPressed: () {},
                child: const Text('Remove'),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Following List Screen
class FollowingListScreen extends ConsumerWidget {
  final String athleteId;

  const FollowingListScreen({super.key, required this.athleteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final following = [
      {'name': 'Haider "The Hammer" Khan', 'location': 'Lahore, Pakistan'},
      {'name': 'Farhan "Flash" Ahmed', 'location': 'Peshawar, Pakistan'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Following'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: following.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = following[index];
          return GlassCard(
            padding: const EdgeInsets.all(12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                child: const Icon(Icons.person),
              ),
              title: Text(item['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(item['location']!, style: const TextStyle(fontSize: 12)),
              trailing: OutlinedButton(
                onPressed: () {},
                child: const Text('Unfollow'),
              ),
            ),
          );
        },
      ),
    );
  }
}
