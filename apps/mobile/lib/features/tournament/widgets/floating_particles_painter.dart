import 'package:flutter/material.dart';

class FloatingParticlesPainter extends CustomPainter {
  final double progress;

  const FloatingParticlesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Intentionally empty: all dust/particle speck overlays have been purged.
  }

  @override
  bool shouldRepaint(covariant FloatingParticlesPainter oldDelegate) => false;
}
