import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';

/// First-open landing experience for unauthenticated visitors.
///
/// Introduces the ArmSphere platform and routes into authentication.
/// The router sends every signed-out user here, so it must work as a
/// standalone entry point (no back button expectations).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.8, -0.9),
            radius: 1.4,
            colors: [
              Color(0x2ED4AF37),
              AppTheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Brand identity ────────────────────────────────
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.glassSurface,
                          border: Border.all(color: AppTheme.glassBorder),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.goldGlow,
                              blurRadius: 32,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.sports_kabaddi,
                          size: 56,
                          color: AppTheme.goldPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'ArmSphere',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.5,
                        color: AppTheme.goldPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Armwrestling, organized. Compete in sanctioned tournaments,\nclimb national rankings, and prove your strength.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── What you get ──────────────────────────────────
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Inside ArmSphere',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppTheme.goldPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _BenefitRow(
                            icon: Icons.emoji_events_outlined,
                            title: 'Compete in tournaments',
                            subtitle: 'Register for events, brackets and matches near you.',
                          ),
                          _BenefitRow(
                            icon: Icons.leaderboard_outlined,
                            title: 'National rankings',
                            subtitle: 'Earn points every match and climb your weight class.',
                          ),
                          _BenefitRow(
                            icon: Icons.travel_explore_outlined,
                            title: 'Discover athletes',
                            subtitle: 'Follow rivals and training partners across Pakistan.',
                          ),
                          _BenefitRow(
                            icon: Icons.groups_3_outlined,
                            title: 'Community & clubs',
                            subtitle: 'Share PRs, join teams and follow live results.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Primary actions ───────────────────────────────
                    FilledButton(
                      onPressed: () => context.go('/register'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.goldPrimary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('Create your account'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => context.go('/login'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary,
                        side: const BorderSide(color: AppTheme.glassBorder, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('I already have an account'),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'By continuing you agree to the ArmSphere Terms of Use\nand Athlete Code of Conduct.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.goldGlow,
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: Icon(icon, size: 18, color: AppTheme.goldLight),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
