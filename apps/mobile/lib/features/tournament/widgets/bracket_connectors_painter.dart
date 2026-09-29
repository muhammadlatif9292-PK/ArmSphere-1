import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'bracket_connector_line.dart';
class BracketConnectorsPainter extends CustomPainter {
  final List<BracketConnectorLine> connectors;
  final double progress;

  BracketConnectorsPainter({
    required this.connectors,
    this.progress = 1.0,
  });

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

      // Always draw neutral underlay line
      final neutralPaint = Paint()
        ..color = AppTheme.borderSubtle
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, neutralPaint);

      if (conn.isHighlighted) {
        // SIG-6: Bracket Advance Lightning Line (Champagne Gold bloom + core)
        Path highlightPath = path;
        if (progress < 1.0 && progress > 0.0) {
          final metrics = path.computeMetrics().toList();
          if (metrics.isNotEmpty) {
            final metric = metrics.first;
            highlightPath = metric.extractPath(0.0, metric.length * progress);
          }
        }

        final bloomPaint = Paint()
          ..color = AppTheme.goldPrimary.withValues(alpha: 0.35)
          ..strokeWidth = 5.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(highlightPath, bloomPaint);

        final corePaint = Paint()
          ..color = AppTheme.goldPrimary
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(highlightPath, corePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant BracketConnectorsPainter oldDelegate) {
    return oldDelegate.connectors != connectors || oldDelegate.progress != progress;
  }
}


