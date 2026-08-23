import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
class EloChartPainter extends CustomPainter {
  final List<double> eloPoints;
  final int selectedIndex;

  EloChartPainter({required this.eloPoints, required this.selectedIndex});

  @override
  void paint(Canvas canvas, Size size) {
    if (eloPoints.isEmpty) return;

    final double minElo = 1400;
    final double maxElo = 2300;

    final Paint linePaint = Paint()
      ..color = AppTheme.goldPrimary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.goldPrimary.withOpacity(0.35),
          AppTheme.goldPrimary.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final Path path = Path();
    final Path fillPath = Path();

    final double stepX = size.width / (eloPoints.length - 1);

    List<Offset> points = [];

    for (int i = 0; i < eloPoints.length; i++) {
      final double x = i * stepX;
      final double normalizedY = (eloPoints[i] - minElo) / (maxElo - minElo);
      final double y = size.height - 40 - (normalizedY * (size.height - 50));
      points.add(Offset(x, y));
    }

    path.moveTo(points[0].dx, points[0].dy);
    fillPath.moveTo(points[0].dx, size.height - 25);
    fillPath.lineTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final Offset p1 = points[i];
      final Offset p2 = points[i + 1];
      final Offset controlPoint1 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p1.dy);
      final Offset controlPoint2 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p2.dy);

      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p2.dx,
        p2.dy,
      );

      fillPath.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p2.dx,
        p2.dy,
      );
    }

    fillPath.lineTo(points.last.dx, size.height - 25);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant EloChartPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex || oldDelegate.eloPoints != eloPoints;
}
  }
// ELO SPARKLINE PAINTER (Custom GPU-friendly curve)
