import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/armsphere_image.dart';
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
          // Full-Bleed 9:16 Walkout Stage Backdrop at 100% Opacity
          Positioned.fill(
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: AppTheme.voidBackground),
                const ArmSphereImage(
                  assetPath: ArmSphereAssets.stageAuthWalkout,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  width: double.infinity,
                  height: double.infinity,
                  excludeFromSemantics: true,
                  showLoadingIndicator: false,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0, 0.45, 0.78, 1.0],
                      colors: [
                        Color(0x00000000),
                        Color(0x00000000),
                        Color(0x40000000),
                        Color(0x73000000),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Environmental Hero Visual Anchor (M1-HERO-WELCOME-GRIP) at 100% Opacity
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 310,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ArmSphereImage(
                  assetPath: ArmSphereAssets.welcomeGripHero,
                  fit: BoxFit.cover,
                  alignment: Alignment(0.0, -0.20),
                  width: double.infinity,
                  height: 310,
                  fallbackAsset: ArmSphereAssets.welcomeGripHero,
                  excludeFromSemantics: true,
                ),
                // Bottom-only pure-black fade so silver chiaroscuro locked grip and crimson smoke pop at 100% clarity
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x00000000),
                        Color(0x00000000),
                        Color(0x80000000),
                        Color(0xB3000000),
                      ],
                      stops: [0.0, 0.62, 0.86, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 48).clamp(0.0, double.infinity),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Open Upper Hero Showcase Spacer (zero circular seal overlay over locked hands) ──
                            const SizedBox(height: 220),
                            FadeTransition(
                              opacity: _heroFadeAnimation,
                              child: const Column(
                                children: [
                                  Text(
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
                                  SizedBox(height: 6),
                                  Text(
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
                                  const SizedBox(height: 14),

                                  // ── 4 Role Selection Cards (TactileTap Cat A) ─────
                                  ..._roles.map((role) {
                                    final isSelected = _selectedRole == role.id;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
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

                                  const SizedBox(height: 28),

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
                );
              },
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
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0x73D4AF37) : const Color(0x38FFFFFF),
            width: isSelected ? 1.2 : 1.0,
          ),
          boxShadow: const [],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? const Color(0x73D4AF37) : const Color(0x38FFFFFF),
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
                      letterSpacing: 0.5,
                      color: isSelected ? AppTheme.goldPrimary : AppTheme.textPrimary,
                      shadows: const [
                        Shadow(color: Color(0xE6000000), blurRadius: 6, offset: Offset(0, 1)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppTheme.textMuted,
                      shadows: [
                        Shadow(color: Color(0xE6000000), blurRadius: 6, offset: Offset(0, 1)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppTheme.goldPrimary : const Color(0x38FFFFFF),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 13, color: AppTheme.goldPrimary)
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
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0x73D4AF37),
              width: 1.2,
            ),
            boxShadow: const [],
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
                  color: AppTheme.goldPrimary,
                  letterSpacing: 0.8,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: AppTheme.goldPrimary,
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
