import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/elevated_action_card.dart';
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
        padding: const EdgeInsets.all(AppTheme.space20),
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
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                onRetry();
              },
              child: const Text('Retry'),
            ),
          ),
        ],
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(AppTheme.space20),
            children: const [
              SizedBox(height: 100),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.group_outlined, size: 48, color: AppTheme.textMuted),
                    SizedBox(height: 12),
                    Text('Nobody here yet',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  ],
                ),
              ),
            ],
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppTheme.space16),
          itemCount: rows.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppTheme.space10),
          itemBuilder: (context, index) {
            final row = rows[index];
            final name = row['displayName']?.toString() ?? 'Athlete';
            final photo = row['profilePhoto']?.toString() ?? '';
            final subtitle = [
              row['city']?.toString(),
              row['province']?.toString(),
            ].where((v) => v != null && v.isNotEmpty).join(', ');

            return RepaintBoundary(
              child: ElevatedActionCard(
                onTap: () {
                  HapticFeedback.lightImpact();
                  final id = row['id']?.toString();
                  if (id != null && id.isNotEmpty) context.push('/athlete/$id');
                },
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.space14, vertical: AppTheme.space12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.primaryRed.withValues(alpha: 0.15),
                      backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                      onBackgroundImageError: photo.isNotEmpty ? (exception, stackTrace) {} : null,
                      child: photo.isEmpty
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryRed),
                            )
                          : null,
                    ),
                    const SizedBox(width: AppTheme.space14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: AppTheme.space2),
                            Text(
                              subtitle,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 20, color: AppTheme.textMuted),
                  ],
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
      ),
      body: _AthleteRows(
        listAsync: ref.watch(followingProvider(athleteId)),
        onRetry: () => ref.invalidate(followingProvider(athleteId)),
      ),
    );
  }
}
