import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/providers/social_provider.dart';
import '../../../core/theme/app_theme.dart';

/// Shared list rendering for followers / following rows.
class _AthleteRows extends ConsumerWidget {
  final AsyncValue<List<Map<String, dynamic>>> listAsync;
  final VoidCallback onRetry;

  const _AthleteRows({required this.listAsync, required this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return listAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 80),
          const Center(
            child: Icon(Icons.error_outline, size: 44, color: AppTheme.error),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text('Could not load list',
                style: Theme.of(context).textTheme.titleSmall),
          ),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ),
        ],
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: const [
              SizedBox(height: 100),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.group_outlined, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('Nobody here yet',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ],
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: rows.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final row = rows[index];
            final name = row['displayName']?.toString() ?? 'Athlete';
            final photo = row['profilePhoto']?.toString() ?? '';
            final subtitle = [
              row['city']?.toString(),
              row['province']?.toString(),
            ].where((v) => v != null && v.isNotEmpty).join(', ');

            return GestureDetector(
              onTap: () {
                final id = row['id']?.toString();
                if (id != null && id.isNotEmpty) context.push('/athlete/$id');
              },
              child: GlassCard(
                padding: const EdgeInsets.all(12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.12),
                    backgroundImage:
                        photo.isNotEmpty ? NetworkImage(photo) : null,
                    onBackgroundImageError:
                        photo.isNotEmpty ? (exception, stackTrace) {} : null,
                    child: photo.isEmpty
                        ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?')
                        : null,
                  ),
                  title: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: subtitle.isNotEmpty
                      ? Text(subtitle, style: const TextStyle(fontSize: 12))
                      : null,
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Followers List Screen
class FollowersListScreen extends ConsumerWidget {
  final String athleteId;

  const FollowersListScreen({super.key, required this.athleteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Followers'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _AthleteRows(
        listAsync: ref.watch(followersProvider(athleteId)),
        onRetry: () => ref.invalidate(followersProvider(athleteId)),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Following'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _AthleteRows(
        listAsync: ref.watch(followingProvider(athleteId)),
        onRetry: () => ref.invalidate(followingProvider(athleteId)),
      ),
    );
  }
}
