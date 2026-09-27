import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/armsphere_image.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';

/// Canary 1: Welcome & Onboarding Screen (`/welcome` & `/onboarding`)
///
/// Implements Canary 1 & Stage 6 Convergence Specification:
/// - Substrate: L0 Canvas (`#070A11`) with subtle magnesium chalk grain (1.5%).
/// - Hero Layer: High-contrast armwrestling combat emblem with rim lighting (M1-01 Master Still). Zero autoplaying background video (enforcing AX-3).
/// - Surface: Floating L4 card (`#121826`, 16dp rounded top chamfer, 1px `#334155` border).
/// - Role Selection Cards: 4 horizontal cards (Athlete, Referee, Organizer, Spectator).
///   Tapping a card initiates TactileTap (Cat A): Scale compresses to 0.97 in 100ms (`Curves.easeOutCubic`),
///   border illuminates in Gold (`#D4AF37`), `HapticFeedback.lightImpact()`.
/// - CTA "ENTER ARENA": Fixed 52dp height, 8dp chamfer, Gold fill (`#D4AF37`), black text (`#070A11`, `SpaceGrotesk-Bold`).
/// - Motion Choreography:
///   - Ingress: Staggered entrance. Hero media fades in (0–300ms, `Curves.easeOutCubic`).
///   - Title and role cards slide up 24dp sequentially with 40ms stagger (300–550ms).
/// - Performance: Cold launch time to interactive <450ms. Zero network wait.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ingressController;
  late final Animation<double> _heroFadeAnimation;
  late final Animation<double> _contentSlideAnimation;

  String _selectedRole = 'athlete';

  static const _roles = <_RoleCardData>[
    _RoleCardData(
      id: 'athlete',
      title: 'ATHLETE',
      subtitle: 'Compete in brackets & rankings',
      icon: Icons.sports_kabaddi,
    ),
    _RoleCardData(
      id: 'referee',
      title: 'REFEREE',
      subtitle: 'Table-side live officiating',
      icon: Icons.gavel_outlined,
    ),
    _RoleCardData(
      id: 'organizer',
      title: 'ORGANIZER',
      subtitle: 'Sanctioned tournament brackets',
      icon: Icons.event_available_outlined,
    ),
    _RoleCardData(
      id: 'spectator',
      title: 'SPECTATOR',
      subtitle: 'Live tables, streams & community',
      icon: Icons.visibility_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _ingressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _heroFadeAnimation = CurvedAnimation(
      parent: _ingressController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    );

    _contentSlideAnimation = CurvedAnimation(
      parent: _ingressController,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
    );

    _ingressController.forward();
  }

  @override
  void dispose() {
    _ingressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
      body: Stack(
        children: [
          // Substrate: L0 Canvas (#070A11) + Subtle Magnesium Chalk Grain
          Positioned.fill(
            child: Container(
              color: AppTheme.voidBackground,
              child: CustomPaint(
                painter: _MagnesiumChalkGrainPainter(),
              ),
            ),
          ),

          // Environmental Hero Visual Anchor (M1-HERO-GRIP) with Downward Void Scrim
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 280,
            child: ShaderMask(
              shaderCallback: (rect) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x8CFFFFFF), // ~55% opacity at top so void breathes
                    Color(0x33FFFFFF),
                    Colors.transparent, // Dissolves seamlessly into void canvas
                  ],
                  stops: [0.0, 0.55, 1.0],
                ).createShader(rect);
              },
              blendMode: BlendMode.dstIn,
              child: const ArmSphereImage(
                assetPath: ArmSphereAssets.heroGrip,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 280,
                excludeFromSemantics: true,
              ),
            ),
          ),

          // Ambient Gold Horizon Scrim
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.75),
                  radius: 1.2,
                  colors: [
                    Color(0x24D4AF37), // 14% subtle ambient gold halo
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Hero Layer: M0 Icon Gold Master Emblem (0–300ms fade-in) ──
                      FadeTransition(
                        opacity: _heroFadeAnimation,
                        child: Column(
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.cardSurface,
                                border: Border.all(
                                  color: AppTheme.goldPrimary,
                                  width: 2.0,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: AppTheme.goldGlow,
                                    blurRadius: 36,
                                    spreadRadius: 4,
                                  ),
                                  BoxShadow(
                                    color: Colors.black,
                                    blurRadius: 16,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: ArmSphereImage(
                                  assetPath: ArmSphereAssets.iconGold,
                                  width: 96,
                                  height: 96,
                                  fit: BoxFit.cover,
                                  semanticLabel: 'ArmSphere Official Federation Emblem',
                                  fallbackIcon: Icons.sports_kabaddi,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'ARMSPHERE',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Space Grotesk',
                                fontWeight: FontWeight.w900,
                                fontSize: 34,
                                letterSpacing: 1.5,
                                color: AppTheme.goldPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'THE INTERNATIONAL ARMWRESTLING FEDERATION SYSTEM',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Space Grotesk',
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Content Slide Ingress (300–550ms) ──────────────────
                      AnimatedBuilder(
                        animation: _contentSlideAnimation,
                        builder: (context, child) {
                          final dy = (1.0 - _contentSlideAnimation.value) * 24.0;
                          return Transform.translate(
                            offset: Offset(0, dy),
                            child: Opacity(
                              opacity: _contentSlideAnimation.value,
                              child: child,
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Choose Your Federation Role Header ────────────
                            Row(
                              children: [
                                Container(
                                  width: 3.5,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: AppTheme.goldPrimary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'SELECT YOUR ROLE IN THE ARENA',
                                  style: TextStyle(
                                    fontFamily: 'Space Grotesk',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // ── 4 Role Selection Cards (TactileTap Cat A) ─────
                            ..._roles.map((role) {
                              final isSelected = _selectedRole == role.id;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _RoleSelectCard(
                                  data: role,
                                  isSelected: isSelected,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    setState(() {
                                      _selectedRole = role.id;
                                    });
                                  },
                                ),
                              );
                            }),

                            const SizedBox(height: 20),

                            // ── Inside ArmSphere Institutional Card ───────────
                            ElevatedActionCard(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: AppTheme.goldPrimary,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'SANCTIONED COMPETITIVE ECOSYSTEM',
                                        style: TextStyle(
                                          fontFamily: 'Space Grotesk',
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                          color: AppTheme.goldPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  const _BenefitRow(
                                    icon: Icons.emoji_events_outlined,
                                    title: 'Live Bracket Battles',
                                    subtitle: 'Real-time table calls, certified weigh-ins & dual-arm records.',
                                  ),
                                  const _BenefitRow(
                                    icon: Icons.leaderboard_outlined,
                                    title: 'National Federation Rankings',
                                    subtitle: 'Provincial ELO tracking with dynamic combat rating updates.',
                                  ),
                                  const _BenefitRow(
                                    icon: Icons.gavel_outlined,
                                    title: 'Table-Side Precision Scoring',
                                    subtitle: 'Sanctioned referee console with 400ms physical pin-hold locks.',
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // ── Primary Action: Fixed 52dp "ENTER ARENA" ───────
                            _TactileEnterArenaButton(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                context.go('/register', extra: {'role': _selectedRole});
                              },
                            ),

                            const SizedBox(height: 12),

                            // ── Secondary Action: Existing Account ────────────
                            OutlinedButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                context.go('/login');
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.textPrimary,
                                side: const BorderSide(color: AppTheme.border, width: 1.2),
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                ),
                                textStyle: const TextStyle(
                                  fontFamily: 'Space Grotesk',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              child: const Text('I ALREADY HAVE AN ACCOUNT'),
                            ),

                            const SizedBox(height: 20),

                            // Disclaimer Footer
                            const Text(
                              'By entering you agree to the ArmSphere Federation Charter\nand Anti-Doping Fair Play Code.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10.5,
                                color: AppTheme.textMuted,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tactical Role Selection Card (Canary 1 Cat A TactileTap)
class _RoleSelectCard extends StatelessWidget {
  final _RoleCardData data;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleSelectCard({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TactilePressWrapper(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.goldPrimary.withValues(alpha: 0.12)
              : AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(
            color: isSelected ? AppTheme.goldPrimary : AppTheme.borderSubtle,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.goldPrimary.withValues(alpha: 0.22),
                    blurRadius: 10,
                    spreadRadius: 0.5,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppTheme.goldPrimary.withValues(alpha: 0.2)
                    : AppTheme.elevatedSurface,
                border: Border.all(
                  color: isSelected ? AppTheme.goldPrimary : AppTheme.borderSubtle,
                  width: 1.0,
                ),
              ),
              child: Icon(
                data.icon,
                size: 20,
                color: isSelected ? AppTheme.goldPrimary : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.4,
                      color: isSelected ? AppTheme.goldPrimary : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.goldPrimary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppTheme.goldPrimary : AppTheme.borderSubtle,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.black)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Fixed 52dp "ENTER ARENA" CTA Button with Tactile 120ms Depression
class _TactileEnterArenaButton extends StatefulWidget {
  final VoidCallback onTap;

  const _TactileEnterArenaButton({required this.onTap});

  @override
  State<_TactileEnterArenaButton> createState() => _TactileEnterArenaButtonState();
}

class _TactileEnterArenaButtonState extends State<_TactileEnterArenaButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppTheme.goldPrimary,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            boxShadow: [
              BoxShadow(
                color: AppTheme.goldPrimary.withValues(alpha: 0.4),
                blurRadius: 14,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'ENTER ARENA',
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF070A11),
                  letterSpacing: 0.8,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: Color(0xFF070A11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCardData {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;

  const _RoleCardData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.elevatedSurface,
              border: Border.all(color: AppTheme.goldPrimary.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, size: 16, color: AppTheme.goldPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
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

/// Subtle 1.5% opacity magnesium chalk grain painter for L0 Canvas
class _MagnesiumChalkGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.015)
      ..strokeWidth = 1.0;

    // Fixed procedural chalk distribution without expensive noise library
    for (double y = 15; y < size.height; y += 45) {
      for (double x = 12; x < size.width; x += 40) {
        final offset = (x * 7 + y * 13) % 20;
        canvas.drawCircle(Offset(x + offset, y), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
