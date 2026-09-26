import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/elevated_action_card.dart';

/// Screen Spec 02: WelcomeScreen
///
/// First-open institutional landing experience for unauthenticated visitors.
/// Grounded in:
/// - docs/design/22_SCREEN_BY_SCREEN_SPEC.md (Screen Spec 02)
/// - docs/design/24_ANTI_SLOP_RULES.md (No nested glassmorphism, no 999dp pill buttons)
/// - docs/design/08_TYPOGRAPHY_SYSTEM.md (Space Grotesk + Inter)
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.8, -0.9),
            radius: 1.4,
            colors: [
              Color(0x22D4AF37), // Subtle 13% ambient gold halo
              AppTheme.voidBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Brand identity ────────────────────────────────
                    Center(
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.cardSurface,
                          border: Border.all(
                            color: AppTheme.goldPrimary.withValues(alpha: 0.6),
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: AppTheme.goldGlow,
                              blurRadius: 32,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.sports_kabaddi,
                            size: 46,
                            color: AppTheme.goldPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'ArmSphere',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontWeight: FontWeight.w800,
                        fontSize: 36,
                        letterSpacing: -1.2,
                        color: AppTheme.goldPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    const Text(
                      'Armwrestling, organized. Compete in sanctioned tournaments,\nclimb national rankings, and prove your strength.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.5,
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Platform Pillars Card (ElevatedActionCard) ─────
                    ElevatedActionCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: AppTheme.goldPrimary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'INSIDE ARMSPHERE',
                                style: TextStyle(
                                  fontFamily: 'Space Grotesk',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                  color: AppTheme.goldPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const _BenefitRow(
                            icon: Icons.emoji_events_outlined,
                            title: 'Compete in Tournaments',
                            subtitle: 'Register for sanctioned brackets, weigh-ins, and official tables.',
                          ),
                          const _BenefitRow(
                            icon: Icons.leaderboard_outlined,
                            title: 'National Rankings',
                            subtitle: 'Earn points every match and climb your provincial weight class.',
                          ),
                          const _BenefitRow(
                            icon: Icons.travel_explore_outlined,
                            title: 'Discover Athletes',
                            subtitle: 'Follow rivals, clubs, certified referees, and training partners.',
                          ),
                          const _BenefitRow(
                            icon: Icons.groups_3_outlined,
                            title: 'Community & Feed',
                            subtitle: 'Share PRs, join teams, and track live tournament results.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Primary actions ───────────────────────────────
                    FilledButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        context.go('/register');
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.goldPrimary,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      child: const Text('Create your account'),
                    ),
                    const SizedBox(height: 12),

                    OutlinedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        context.go('/login');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary,
                        side: const BorderSide(color: AppTheme.border, width: 1.2),
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('I already have an account'),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'By continuing you agree to the ArmSphere Terms of Use\nand Athlete Code of Conduct.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppTheme.textMuted,
                        height: 1.4,
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
              color: AppTheme.elevatedSurface,
              border: Border.all(color: AppTheme.goldPrimary.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, size: 18, color: AppTheme.goldPrimary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
