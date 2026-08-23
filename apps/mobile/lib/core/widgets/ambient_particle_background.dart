import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Single particle model for floating ambient background effect
class _Particle {
  double x; // 0.0 to 1.0 relative width
  double y; // 0.0 to 1.0 relative height
  double size;
  double speedY;
  double alpha;
  double pulse;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedY,
    required this.alpha,
    required this.pulse,
  });
}

/// CustomPainter for rendering animated particle dots and soft moving light beams
class _AmbientParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double animationValue;
  final Color? particleColor;

  _AmbientParticlePainter({
    required this.particles,
    required this.animationValue,
    this.particleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Mesh Gradient Background Fill
    final meshGradient = RadialGradient(
      center: Alignment(
        0.3 * math.sin(animationValue * 2 * math.pi),
        -0.5 + 0.2 * math.cos(animationValue * 2 * math.pi),
      ),
      radius: 1.2,
      colors: const [
        Color(0xFF1E2332), // Deep Slate Navy Accent
        Color(0xFF121622), // Onyx Glass Surface
        Color(0xFF0D0F18), // Deep Background
      ],
      stops: const [0.0, 0.55, 1.0],
    );

    canvas.drawRect(
      rect,
      Paint()..shader = meshGradient.createShader(rect),
    );

    // 2. Soft Moving Gold Light Beams
    final beamX1 = size.width * (0.2 + 0.25 * math.sin(animationValue * 2 * math.pi));
    final beamY1 = size.height * (0.15 + 0.1 * math.cos(animationValue * 2 * math.pi));

    final beamPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.goldPrimary.withOpacity(0.08),
          AppTheme.goldPrimary.withOpacity(0.02),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(beamX1, beamY1), radius: 220));

    canvas.drawCircle(Offset(beamX1, beamY1), 220, beamPaint);

    final beamX2 = size.width * (0.75 - 0.2 * math.cos(animationValue * 2 * math.pi));
    final beamY2 = size.height * (0.65 + 0.15 * math.sin(animationValue * 2 * math.pi));

    final beamPaint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          Color(0xFFEF4444).withOpacity(0.06), // Subtle Crimson accent beam
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(beamX2, beamY2), radius: 260));

    canvas.drawCircle(Offset(beamX2, beamY2), 260, beamPaint2);

    // 3. Render Floating Particles
    final particlePaint = Paint()..style = PaintingStyle.fill;

    for (var p in particles) {
      final px = p.x * size.width;
      // Animate Y position smoothly upward
      final currentY = (p.y - (animationValue * p.speedY * 2.0)) % 1.0;
      final py = currentY * size.height;

      final currentAlpha = (p.alpha * (0.6 + 0.4 * math.sin((animationValue + p.pulse) * 2 * math.pi))).clamp(0.0, 1.0);

      final color = particleColor ?? AppTheme.goldLight;
      particlePaint.color = color.withOpacity(currentAlpha * 0.45);
      canvas.drawCircle(Offset(px, py), p.size, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientParticlePainter oldDelegate) {
    return true; // Always repaint during smooth background animation loop
  }
}

/// Atmospheric Background Widget that provides continuous soft particle floats and ambient light beams
class AmbientParticleBackground extends StatefulWidget {
  final Widget? child;
  final Color? particleColor;

  const AmbientParticleBackground({
    Key? key,
    this.child,
    this.particleColor,
  }) : super(key: key);

  @override
  State<AmbientParticleBackground> createState() => _AmbientParticleBackgroundState();
}

class _AmbientParticleBackgroundState extends State<AmbientParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _loopController;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();

    // 12-second continuous ambient loop
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    final rand = math.Random();
    _particles = List.generate(24, (index) {
      return _Particle(
        x: rand.nextDouble(),
        y: rand.nextDouble(),
        size: 1.2 + rand.nextDouble() * 2.2,
        speedY: 0.05 + rand.nextDouble() * 0.12,
        alpha: 0.3 + rand.nextDouble() * 0.5,
        pulse: rand.nextDouble(),
      );
    });
  }

  @override
  void dispose() {
    _loopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Canvas Painter for Ambient Mesh & Particles
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _loopController,
            builder: (context, child) {
              return CustomPaint(
                painter: _AmbientParticlePainter(
                  particles: _particles,
                  animationValue: _loopController.value,
                  particleColor: widget.particleColor,
                ),
              );
            },
          ),
        ),

        // Content
        if (widget.child != null)
          Positioned.fill(child: widget.child!),
      ],
    );
  }
}
