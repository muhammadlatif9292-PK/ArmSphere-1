import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';

/// Screen Spec 01: SplashScreen
///
/// Canonical Stage 2 Specification:
/// - Background: Canvas void #070A11 with ambient radial gold glow.
/// - Hero: Central gold-embossed ArmSphere insignia inside circular badge.
/// - Wordmark: 'ArmSphere' in Space Grotesk 32sp bold, #D4AF37.
/// - Federation Subtitle: 'THE COMPETITIVE ARMWRESTLING ECOSYSTEM' with 1.5 letterspacing.
/// - Motion: Level 4 (800ms ease-in curve) with tap-to-skip support.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSkip() {
    if (!_controller.isCompleted) {
      HapticFeedback.selectionClick();
      _controller.forward(from: 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
      body: GestureDetector(
        onTap: _onSkip,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.0, -0.2),
              radius: 1.2,
              colors: [
                Color(0x22D4AF37), // Subtle 13% ambient gold halo
                AppTheme.voidBackground,
              ],
            ),
          ),
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Semantics(
                  label: 'ArmSphere Mobile. Verifying session.',
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Central gold-embossed insignia badge
                      Container(
                        width: 96,
                        height: 96,
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
                            size: 48,
                            color: AppTheme.goldPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Brand Wordmark in Space Grotesk
                      const Text(
                        'ArmSphere',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontWeight: FontWeight.w800,
                          fontSize: 34,
                          letterSpacing: -1.2,
                          color: AppTheme.goldPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Official Federation Subtitle
                      const Text(
                        'THE COMPETITIVE ARMWRESTLING ECOSYSTEM',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 10.5,
                          letterSpacing: 1.6,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 52),

                      // Gold Loading Indicator
                      const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
