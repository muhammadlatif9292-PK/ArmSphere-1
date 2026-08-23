import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
class PerformanceRadarChartPainter extends CustomPainter {
  final Map<String, double> attributes;
  final double progress;

  PerformanceRadarChartPainter({
    required this.attributes,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (attributes.isEmpty) return;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width < size.height ? size.width / 2 : size.height / 2) - 32;

    final List<String> keys = attributes.keys.toList();
    final int count = keys.length;
    final double angleStep = (2 * math.pi) / count;

    // Web Grid Lines (5 concentric polygons: 20%, 40%, 60%, 80%, 100%)
    final Paint webPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final Paint axisPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 1.0;

    for (int step = 1; step <= 5; step++) {
      final double r = radius * (step / 5.0);
      final Path webPath = Path();

      for (int i = 0; i < count; i++) {
        final double angle = -math.pi / 2 + (i * angleStep);
        final double x = center.dx + r * math.cos(angle);
        final double y = center.dy + r * math.sin(angle);

        if (i == 0) {
          webPath.moveTo(x, y);
        } else {
          webPath.lineTo(x, y);
        }
      }
      webPath.close();
      canvas.drawPath(webPath, webPaint);
    }

    // Spokes / Axis Lines
    for (int i = 0; i < count; i++) {
      final double angle = -math.pi / 2 + (i * angleStep);
      final double x = center.dx + radius * math.cos(angle);
      final double y = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), axisPaint);

      // Label
      final String label = keys[i];
      final double labelRadius = radius + 18;
      final double lx = center.dx + labelRadius * math.cos(angle);
      final double ly = center.dy + labelRadius * math.sin(angle);

      final TextSpan span = TextSpan(
        text: label.toUpperCase(),
        style: const TextStyle(
          fontFamily: AppTheme.fontDisplay,
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: AppTheme.textMuted,
        ),
      );
      final TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(lx - (tp.width / 2), ly - (tp.height / 2)));
    }

    // Animated Attribute Polygon
    final List<Offset> points = [];
    for (int i = 0; i < count; i++) {
      final double val = (attributes[keys[i]] ?? 50.0) / 100.0;
      final double r = radius * val * progress;
      final double angle = -math.pi / 2 + (i * angleStep);
      final double x = center.dx + r * math.cos(angle);
      final double y = center.dy + r * math.sin(angle);
      points.add(Offset(x, y));
    }

    if (points.isNotEmpty) {
      final Path polygonPath = Path()..addPolygon(points, true);

      // Gradient Fill
      final Paint fillPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            AppTheme.goldPrimary.withOpacity(0.45 * progress),
            AppTheme.primaryAccent.withOpacity(0.15 * progress),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.fill;

      canvas.drawPath(polygonPath, fillPaint);

      // Stroke Path
      final Paint strokePaint = Paint()
        ..color = AppTheme.goldPrimary
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(polygonPath, strokePaint);

      // Glowing Vertices
      for (final pt in points) {
        canvas.drawCircle(pt, 4.5, Paint()..color = AppTheme.goldPrimary.withOpacity(0.35));
        canvas.drawCircle(pt, 2.5, Paint()..color = AppTheme.goldPrimary);
        canvas.drawCircle(pt, 1.2, Paint()..color = Colors.black);
      }
    }
  }

  @override
  bool shouldRepaint(covariant PerformanceRadarChartPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.attributes != attributes;
  }
}

// ===============================================================================

// CUSTOM PAINTER FOR INTERACTIVE ELO JOURNEY LINE CHART
