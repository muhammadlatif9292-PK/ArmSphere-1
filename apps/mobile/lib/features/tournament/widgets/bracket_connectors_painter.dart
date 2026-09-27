import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'bracket_connector_line.dart';
class BracketConnectorsPainter extends CustomPainter {
  final List<BracketConnectorLine> connectors;

  BracketConnectorsPainter({required this.connectors});

  @override
  void paint(Canvas canvas, Size size) {
    for (final conn in connectors) {
      final p1 = conn.startPt;
      final p2 = conn.endPt;
      final midX = (p1.dx + p2.dx) / 2;

      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(midX, p1.dy)
        ..lineTo(midX, p2.dy)
        ..lineTo(p2.dx, p2.dy);

      if (conn.isHighlighted) {
        // SIG-6: Bracket Advance Lightning Line (Champagne Gold bloom + core)
        final bloomPaint = Paint()
          ..color = AppTheme.goldPrimary.withValues(alpha: 0.35)
          ..strokeWidth = 5.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(path, bloomPaint);

        final corePaint = Paint()
          ..color = AppTheme.goldPrimary
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(path, corePaint);
      } else {
        final neutralPaint = Paint()
          ..color = AppTheme.borderSubtle
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(path, neutralPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant BracketConnectorsPainter oldDelegate) {
    return oldDelegate.connectors != connectors;
  }
}

