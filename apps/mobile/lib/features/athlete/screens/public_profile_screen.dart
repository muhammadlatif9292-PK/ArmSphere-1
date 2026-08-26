import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/providers/athlete_provider.dart';
import '../../../core/providers/social_provider.dart';
import '../../../core/providers/messaging_provider.dart';

class PublicAthleteProfileScreen extends ConsumerWidget {
  final String athleteId;

  const PublicAthleteProfileScreen({super.key, required this.athleteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(publicAthleteProfileProvider(athleteId));
    final followAsync = ref.watch(followStatusProvider(athleteId));

    // Own profile id (athlete_profiles.id) decides whether to hide Follow.
    final myProfileId =
        ref.watch(athleteProfileProvider).value?['id']?.toString();
    final isSelf = myProfileId != null && myProfileId == athleteId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Athlete Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off_outlined, size: 44, color: Colors.grey),
              const SizedBox(height: 12),
              Text('Profile unavailable',
                  style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text('$err',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(publicAthleteProfileProvider(athleteId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (p) {
          final displayName = (p['displayName']?.toString().isNotEmpty ?? false)
              ? p['displayName'].toString()
              : 'Athlete';
          final photo = p['profilePhoto']?.toString() ?? '';
          final location = [
            p['city']?.toString(),
            p['province']?.toString(),
          ].where((v) => v != null && v.isNotEmpty).join(', ');
          final weightClass = p['weightClass']?.toString();
          final dominantArm = p['dominantArm']?.toString();
          final rightElo = (p['rightArmElo'] as num?)?.toInt();
          final leftElo = (p['leftArmElo'] as num?)?.toInt();
          final clubName = p['club'] is Map ? p['club']['name']?.toString() : null;
          final bio = p['biography']?.toString();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                        backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                        onBackgroundImageError: photo.isNotEmpty
                            ? (exception, stackTrace) {}
                            : null,
                        child: photo.isEmpty
                            ? Text(
                                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                style: TextStyle(
                                    fontSize: 40, color: theme.colorScheme.primary),
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        displayName,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          location,
                          style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.5)),
                        ),
                      ],
                      if (clubName != null && clubName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          clubName,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Social Action buttons
                if (!isSelf)
                  Row(
                    children: [
                      Expanded(
                        child: followAsync.when(
                          loading: () => const ElevatedButton(
                            onPressed: null,
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          error: (_, __) => ElevatedButton(
                            onPressed: () =>
                                ref.invalidate(followStatusProvider(athleteId)),
                            child: const Text('Follow'),
                          ),
                          data: (isFollowing) => ElevatedButton(
                            onPressed: () async {
                              try {
                                final notifier = ref.read(
                                    followStatusProvider(athleteId).notifier);
                                if (isFollowing) {
                                  await notifier.unfollow();
                                } else {
                                  await notifier.follow();
                                }
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Could not update follow status')),
                                  );
                                }
                              }
                            },
                            child: Text(isFollowing ? 'Unfollow' : 'Follow'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _startConversation(context, ref, p),
                          child: const Text('Message'),
                        ),
                      ),
                    ],
                  ),
                if (!isSelf) const SizedBox(height: 32),

                // Specs — real fields only
                Text(
                  'ATHLETIC OVERVIEW',
                  style: theme.textTheme.labelMedium?.copyWith(
                      letterSpacing: 1.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _SpecRow(
                          label: 'Weight Category',
                          value:
                              (weightClass == null || weightClass.isEmpty) ? '—' : weightClass),
                      const Divider(height: 24),
                      _SpecRow(
                          label: 'Dominant Arm',
                          value: (dominantArm == null || dominantArm.isEmpty)
                              ? '—'
                              : (dominantArm == 'LEFT' ? 'Left Arm' : 'Right Arm')),
                      const Divider(height: 24),
                      _SpecRow(
                          label: 'Right Arm ELO',
                          value: rightElo?.toString() ?? '—'),
                      const Divider(height: 24),
                      _SpecRow(
                          label: 'Left Arm ELO',
                          value: leftElo?.toString() ?? '—'),
                    ],
                  ),
                ),
                if (bio != null && bio.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'ABOUT',
                    style: theme.textTheme.labelMedium?.copyWith(
                        letterSpacing: 1.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Text(bio,
                        style: const TextStyle(fontSize: 13, height: 1.5)),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  /// Opens (or creates) a DIRECT conversation with this athlete and
  /// navigates to the chat thread.
  Future<void> _startConversation(
      BuildContext context, WidgetRef ref, Map<String, dynamic> profile) async {
    final targetUserId = profile['userId']?.toString();
    if (targetUserId == null || targetUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('This athlete cannot be messaged yet'),
            backgroundColor: Colors.red),
      );
      return;
    }

    try {
      final conversation = await ref
          .read(conversationsProvider.notifier)
          .getOrCreateConversation(targetUserId);
      if (!context.mounted) return;
      if (conversation == null || conversation['id'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not start conversation'),
              backgroundColor: Colors.red),
        );
        return;
      }
      context.push('/messages/${conversation['id']}');
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not start conversation'),
              backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _SpecRow extends StatelessWidget {
  final String label;
  final String value;

  const _SpecRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
