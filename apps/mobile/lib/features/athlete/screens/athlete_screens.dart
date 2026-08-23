import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/achievements_section.dart';
import '../../../core/providers/state_providers.dart';

/// Athlete Dashboard Screen
class AthleteDashboardScreen extends ConsumerWidget {
  const AthleteDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final profile = authState.userProfile ?? {};
    final displayName = profile['displayName'] ?? 'Athlete';

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

          // Rating specs Card
          GlassCard(
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
                        'Class: Heavyweight',
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
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          '1,842',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Right Arm',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    VerticalDivider(width: 1, thickness: 1),
                    Column(
                      children: [
                        Text(
                          '1,695',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Left Arm',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
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
                onTap: () => context.push('/teams/my-team-id'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Horizontal Achievements Section widget
          const AchievementsSection(),
        ],
      ),
    );
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
