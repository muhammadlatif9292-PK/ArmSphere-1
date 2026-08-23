import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
class FloatingParticlesPainter extends CustomPainter {
  final double progress;

  FloatingParticlesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final particlePaint = Paint()..style = PaintingStyle.fill;

    final particles = [
      Offset(size.width * 0.15, size.height * (0.2 + 0.1 * math.sin(progress * 3.14))),
      Offset(size.width * 0.45, size.height * (0.7 - 0.15 * math.cos(progress * 3.14))),
      Offset(size.width * 0.75, size.height * (0.3 + 0.1 * math.sin(progress * 2 * 3.14))),
      Offset(size.width * 0.25, size.height * (0.8 - 0.08 * math.sin(progress * 3.14))),
      Offset(size.width * 0.60, size.height * (0.15 + 0.1 * math.cos(progress * 3.14))),
      Offset(size.width * 0.85, size.height * (0.75 - 0.12 * math.sin(progress * 3.14))),
    ];

    for (int i = 0; i < particles.length; i++) {
      final isGold = i % 2 == 0;
      particlePaint.color = isGold
          ? AppTheme.goldPrimary.withOpacity(0.25 + 0.15 * math.sin(progress * 3.14 + i))
          : Color(0xFF00E5FF).withOpacity(0.2 + 0.1 * math.cos(progress * 3.14 + i));

      final radius = 1.2 + (i % 3) * 0.8;
      canvas.drawCircle(particles[i], radius, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant FloatingParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

