import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
class BracketLinesPainter extends CustomPainter {
  final double pulseValue;

  BracketLinesPainter({required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF00E5FF).withOpacity(0.35 * pulseValue + 0.15)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    // Draw representative connecting bracket lines between QF, SF, Final & Champion
    // Line 1: QF to SF (top pair)
    final path1 = Path();
    path1.moveTo(160, 40);
    path1.lineTo(178, 40);
    path1.lineTo(178, 70);
    path1.lineTo(192, 70);
    canvas.drawPath(path1, paint);

    // Line 2: SF to Final
    final path2 = Path();
    path2.moveTo(350, 70);
    path2.lineTo(368, 70);
    path2.lineTo(368, 70);
    path2.lineTo(384, 70);
    canvas.drawPath(path2, paint);

    // Line 3: Final to Champion
    final path3 = Path();
    path3.moveTo(540, 70);
    path3.lineTo(570, 70);
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(covariant BracketLinesPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue;
  }
}

