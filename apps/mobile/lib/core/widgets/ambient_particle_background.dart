// lib/core/widgets/ambient_particle_background.dart
import 'package:flutter/material.dart';
import '../constants/asset_paths.dart';
import '../theme/app_theme.dart';
import 'armsphere_image.dart';

/// Full-Screen Crystal-Clear Atmospheric Background Substrate
///
/// Renders a 100% sharp, unblurred, full-viewport (`Positioned.fill`) background
/// tailored to the active functional tab or screen (`tabIndex` / `backgroundAsset`),
/// layered with subtle chalk/knurl texture, directional stadium spotlights, and
/// deterministic stardust particles.
class AmbientParticleBackground extends StatelessWidget {
  final Widget? child;
  final Color? particleColor;
  final int? tabIndex;
  final String? backgroundAsset;

  const AmbientParticleBackground({
    super.key,
    this.child,
    this.particleColor,
    this.tabIndex,
    this.backgroundAsset,
  });

  String _resolvePrimaryAsset() {
    if (backgroundAsset != null && backgroundAsset!.isNotEmpty) {
      return backgroundAsset!;
    }
    switch (tabIndex) {
      case 0: // Arena
        return ArmSphereAssets.heroArena;
      case 1: // Discover
        return ArmSphereAssets.heroGrip;
      case 2: // Events / Competitions
        return ArmSphereAssets.defaultTournament;
      case 3: // Community
        return ArmSphereAssets.defaultClub;
      case 4: // Passport
        return ArmSphereAssets.heroGrip;
      default:
        return ArmSphereAssets.heroArena;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Full-screen crystal-clear photographic stage + spotlight mesh
        _StaticAtmosphereSubstrate(primaryAsset: _resolvePrimaryAsset()),

        // 2. Frozen subtle stardust particles (zero runtime CPU/GPU cost)
        RepaintBoundary(
          child: CustomPaint(
            painter: _StaticStardustPainter(
              accentColor: particleColor ?? AppTheme.goldLight,
            ),
          ),
        ),

        // 3. Child content (if any)
        if (child != null) Positioned.fill(child: child!),
      ],
    );
  }
}

class _StaticAtmosphereSubstrate extends StatelessWidget {
  final String primaryAsset;

  const _StaticAtmosphereSubstrate({required this.primaryAsset});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.voidBackground,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Full-Screen Crystal-Clear Functional Photography (NO BLUR, 100% sharp)
          Opacity(
            opacity: 0.44,
            child: ArmSphereImage(
              assetPath: primaryAsset,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              excludeFromSemantics: true,
            ),
          ),

          // 2. Full-Screen Atmospheric Chalk Dust Overlay
          const Opacity(
            opacity: 0.30,
            child: ArmSphereImage(
              assetPath: ArmSphereAssets.texChalk,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              excludeFromSemantics: true,
            ),
          ),

          // 3. Central overhead arena glow mesh
          const Positioned(
            top: -120,
            left: 0,
            right: 0,
            height: 480,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 0.85,
                  colors: [
                    Color(0x1894A3B8),
                    Color(0x0694A3B8),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // 4. Top-right subtle championship gold ambient highlight
          const Positioned(
            top: -80,
            right: -60,
            width: 360,
            height: 360,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0x18D4AF37),
                    Color(0x06D4AF37),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // 5. Mid-left subtle competition crimson arena glow
          const Positioned(
            top: 260,
            left: -100,
            width: 400,
            height: 400,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0x14E23B3B),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.7],
                ),
              ),
            ),
          ),

          // 6. Light cinema contrast grade so full background stays crystal clear
          //    from top to bottom while keeping foreground white text 100% readable
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x52070A11),
                  Color(0x36070A11),
                  Color(0x45070A11),
                  Color(0x66070A11),
                ],
                stops: [0.0, 0.35, 0.72, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaticStardustPainter extends CustomPainter {
  final Color accentColor;

  static const List<Offset> _fixedPoints = [
    Offset(0.12, 0.08),
    Offset(0.85, 0.14),
    Offset(0.35, 0.22),
    Offset(0.72, 0.31),
    Offset(0.18, 0.45),
    Offset(0.91, 0.52),
    Offset(0.48, 0.61),
    Offset(0.24, 0.74),
    Offset(0.78, 0.82),
    Offset(0.62, 0.18),
    Offset(0.08, 0.88),
    Offset(0.88, 0.94),
  ];

  static const List<double> _fixedSizes = [
    1.4,
    2.0,
    1.2,
    1.8,
    1.5,
    2.2,
    1.3,
    1.6,
    1.9,
    1.1,
    1.7,
    1.5,
  ];

  static const List<double> _fixedAlphas = [
    0.25,
    0.35,
    0.20,
    0.30,
    0.18,
    0.32,
    0.22,
    0.28,
    0.30,
    0.15,
    0.24,
    0.20,
  ];

  const _StaticStardustPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < _fixedPoints.length; i++) {
      final pt = _fixedPoints[i];
      final px = pt.dx * size.width;
      final py = pt.dy * size.height;
      final rad = _fixedSizes[i];
      final alpha = _fixedAlphas[i];

      paint.color = accentColor.withValues(alpha: alpha);
      canvas.drawCircle(Offset(px, py), rad, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StaticStardustPainter oldDelegate) {
    return oldDelegate.accentColor != accentColor;
  }
}
