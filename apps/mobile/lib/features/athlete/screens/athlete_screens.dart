import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/achievements_section.dart';
import '../../../core/providers/athlete_provider.dart';
import '../../../core/providers/live_matches_provider.dart';

const Map<int, String> _months = {
  1: 'Jan', 2: 'Feb', 3: 'Mar', 4: 'Apr', 5: 'May', 6: 'Jun',
  7: 'Jul', 8: 'Aug', 9: 'Sep', 10: 'Oct', 11: 'Nov', 12: 'Dec',
};

String _fmtDate(dynamic iso) {
  final d = DateTime.tryParse(iso?.toString() ?? '');
  if (d == null) return '';
  return '${d.day} ${_months[d.month] ?? ''} ${d.year}';
}

/// Athlete Dashboard Screen
class AthleteDashboardScreen extends ConsumerWidget {
  const AthleteDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final profile = authState.userProfile ?? {};
    final displayName = profile['displayName'] ?? 'Athlete';
    // Officials get a direct console entry on the home tab.
    final role = profile['role']?.toString().toUpperCase();
    const officialRoles = {'REFEREE', 'PROVINCIAL_DIRECTOR', 'NATIONAL_DIRECTOR', 'SYSTEM_ADMIN'};
    final isOfficial = role != null && officialRoles.contains(role);
    final profileAsync = ref.watch(athleteProfileProvider);
    // Match rows and PRs are keyed by the athlete PROFILE id, not the auth user id.
    final myProfileId = profileAsync.value?['id']?.toString();
    final matchesAsync = ref.watch(liveMatchesProvider);
    final prsAsync = myProfileId == null
        ? const AsyncValue<List<Map<String, dynamic>>>.data([])
        : ref.watch(trainingLogPRsProvider(myProfileId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  Text(
                    displayName,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined),
                onPressed: () => context.push('/notifications'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Rating specs Card — real per-arm ELO from the athlete profile API
          profileAsync.when(
            loading: () => const GlassCard(
              padding: EdgeInsets.all(20),
              child: SizedBox(
                height: 90,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (err, _) => GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('Could not load your rating',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => ref.invalidate(athleteProfileProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (p) {
              final rightElo = (p['rightArmElo'] as num?)?.toInt();
              final leftElo = (p['leftArmElo'] as num?)?.toInt();
              final weightClass = p['weightClass']?.toString();

              return GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ELO RATING',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            fontSize: 12,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            weightClass == null || weightClass.isEmpty ? 'Open Class' : 'Class: $weightClass',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              rightElo?.toString() ?? '—',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Text(
                              'Right Arm',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        const VerticalDivider(width: 1, thickness: 1),
                        Column(
                          children: [
                            Text(
                              leftElo?.toString() ?? '—',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Text(
                              'Left Arm',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Active Shortcuts
          Text(
            'QUICK SHORTCUTS',
            style: theme.textTheme.labelMedium?.copyWith(
              letterSpacing: 1.0,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2.2,
            children: [
              if (isOfficial)
                _ShortcutButton(
                  icon: Icons.sports,
                  label: 'Referee Console',
                  color: Colors.deepOrange,
                  onTap: () => context.push('/referee/dashboard'),
                ),
              _ShortcutButton(
                icon: Icons.sports_kabaddi,
                label: 'Record Match',
                color: theme.colorScheme.primary,
                onTap: () => context.push('/referee/submit-scorepad'),
              ),
              _ShortcutButton(
                icon: Icons.emoji_events,
                label: 'Tournaments',
                color: Colors.amber,
                onTap: () => context.push('/tournaments'),
              ),
              _ShortcutButton(
                icon: Icons.fitness_center,
                label: 'Training Log',
                color: Colors.teal,
                onTap: () => context.push('/athlete/self/training-log'),
              ),
              _ShortcutButton(
                icon: Icons.group,
                label: 'My Team',
                color: Colors.blue,
                onTap: () => context.push('/teams'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent verified matches — real match history
          Text(
            'RECENT MATCHES',
            style: theme.textTheme.labelMedium?.copyWith(
              letterSpacing: 1.0,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 12),
          matchesAsync.when(
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )),
            error: (err, _) => Text(
              'Could not load matches',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            data: (matches) {
              if (matches.isEmpty) {
                return Text(
                  'No verified matches yet — record your first result to start climbing the rankings.',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                );
              }
              final recent = matches.take(5).toList();
              return Column(
                children: [
                  for (final m in recent)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'vs ${m['opponentName'] ?? 'Unknown'}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    [
                                      m['arm']?.toString(),
                                      _fmtDate(m['verifiedAt'] ?? m['createdAt']),
                                    ].where((v) => v != null && v.isNotEmpty).join(' • '),
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            Builder(builder: (context) {
                              final winnerId = m['winnerId']?.toString();
                              final isWin = myProfileId != null && winnerId == myProfileId;
                              final decided = winnerId != null && winnerId.isNotEmpty;
                              final color = !decided
                                  ? Colors.grey
                                  : (isWin ? Colors.green : Colors.redAccent);
                              final label = !decided
                                  ? (m['status']?.toString() ?? 'PENDING')
                                  : (isWin ? 'WIN' : 'LOSS');
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Personal records — real training-log PRs (hidden until any exist)
          prsAsync.maybeWhen(
            data: (prs) {
              if (prs.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PERSONAL RECORDS',
                    style: theme.textTheme.labelMedium?.copyWith(
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final pr in prs)
                        GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _prettyExercise(pr['exerciseType']?.toString()),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(pr['weightKg'] as num?)?.toInt() ?? '—'} kg',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  static String _prettyExercise(String? raw) {
    if (raw == null || raw.isEmpty) return 'Exercise';
    return raw
        .toLowerCase()
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

/// Helper Shortcut Button
class _ShortcutButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShortcutButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Athlete Profile Tab Screen
class AthleteProfileScreen extends ConsumerWidget {
  const AthleteProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(ref.read(authProvider).status == AuthStatus.authenticated ? authProvider : authProvider);
    final profile = authState.userProfile ?? {};
    final displayName = profile['displayName'] ?? 'Athlete';
    final email = profile['email'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Profile Header Row
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                backgroundImage: (profile['profilePhoto'] != null && profile['profilePhoto'].toString().isNotEmpty)
                    ? NetworkImage(profile['profilePhoto'].toString())
                    : null,
                onBackgroundImageError: (profile['profilePhoto'] != null && profile['profilePhoto'].toString().isNotEmpty)
                    ? (exception, stackTrace) {
                        // Handle image load or signature expiry failures gracefully
                      }
                    : null,
                child: (profile['profilePhoto'] != null && profile['profilePhoto'].toString().isNotEmpty)
                    ? null
                    : Icon(Icons.person, size: 40, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Physical parameters
          Text(
            'BIOMETRICS & SPECIFICATIONS',
            style: theme.textTheme.labelMedium?.copyWith(
              letterSpacing: 1.0,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SpecItem(label: 'Weight', value: '${(profile['weight'] ?? 85).toString()}kg'),
                _SpecItem(label: 'Height', value: '${(profile['height'] ?? 182).toString()}cm'),
                _SpecItem(label: 'Reach', value: '${(profile['reach'] ?? 180).toString()}cm'),
                _SpecItem(label: 'Dominance', value: profile['dominantArm']?.toString() ?? 'RIGHT'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Account Options
          Text(
            'ACCOUNT & SETTINGS',
            style: theme.textTheme.labelMedium?.copyWith(
              letterSpacing: 1.0,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            padding: EdgeInsets.zero,
            child: ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                ListTile(
                  leading: const Icon(Icons.payment),
                  title: const Text('Payment Methods'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/payment-methods'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.local_activity_outlined),
                  title: const Text('My Tickets'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/tickets'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.block_flipped),
                  title: const Text('Blocked Users'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/blocked'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  onTap: () {
                    ref.read(authProvider.notifier).logout();
                    context.go('/login');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecItem extends StatelessWidget {
  final String label;
  final String value;

  const _SpecItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}

/// Athlete Achievements Details Screen
class AthleteAchievementsScreen extends StatelessWidget {
  final String? athleteId;

  const AthleteAchievementsScreen({super.key, this.athleteId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Athletic Honors'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const AchievementsSection(),
            const SizedBox(height: 32),
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'About Athlete Achievements',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Achievements in ArmSphere are conferred automatically based on certified tournament reports, referee scorepads, and official ELO rating recalculations. Medals are secured cryptographically using SHA-256 state hashing to prevent tampering.',
                    style: TextStyle(height: 1.5, fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
