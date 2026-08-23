import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import 'bracket_connector_line.dart';
class BracketConnectorsPainter extends CustomPainter {
  final List<BracketConnectorLine> connectors;

  BracketConnectorsPainter({required this.connectors});

  @override
  void paint(Canvas canvas, Size size) {
    for (final conn in connectors) {
      final paint = Paint()
        ..color = conn.isHighlighted ? AppTheme.primaryAccent : AppTheme.border
        ..strokeWidth = conn.isHighlighted ? 2.0 : 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final p1 = conn.startPt;
      final p2 = conn.endPt;
      final midX = (p1.dx + p2.dx) / 2;

      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(midX, p1.dy)
        ..lineTo(midX, p2.dy)
        ..lineTo(p2.dx, p2.dy);

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant BracketConnectorsPainter oldDelegate) {
    return oldDelegate.connectors != connectors;
  }
}

