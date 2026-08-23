import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
class EloLineGraphPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final Color lineColor;

  EloLineGraphPainter({required this.data, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double width = size.width;
    final double height = size.height - 18; // reserve space for bottom labels

    // Find min and max ELO to scale graph vertically
    int minElo = 2290;
    int maxElo = 2330;

    final double stepX = width / (data.length - 1);

    List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
      final int elo = data[i]['elo'] as int;
      final double normalizedY = (elo - minElo) / (maxElo - minElo);
      final double x = i * stepX;
      final double y = height - (normalizedY * height);
      points.add(Offset(x, y));
    }

    // Grid lines
    final Paint gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(0, 0), Offset(width, 0), gridPaint);
    canvas.drawLine(Offset(0, height / 2), Offset(width, height / 2), gridPaint);
    canvas.drawLine(Offset(0, height), Offset(width, height), gridPaint);

    // Gradient fill below curve
    final Path fillPath = Path();
    fillPath.moveTo(points.first.dx, height);
    fillPath.lineTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final controlPoint1 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p1.dy);
      final controlPoint2 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p2.dy);
      fillPath.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, p2.dx, p2.dy);
    }
    fillPath.lineTo(points.last.dx, height);
    fillPath.close();

    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withOpacity(0.35),
          lineColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height));

    canvas.drawPath(fillPath, fillPaint);

    // Smooth Bezier Curve Line
    final Path linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final controlPoint1 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p1.dy);
      final controlPoint2 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p2.dy);
      linePath.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, p2.dx, p2.dy);
    }

    final Paint linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(linePath, linePaint);

    // Draw Data Point Nodes
    for (int i = 0; i < points.length; i++) {
      final pt = points[i];

      // Glow circle
      canvas.drawCircle(pt, 5, Paint()..color = lineColor.withOpacity(0.3));
      // Outer border
      canvas.drawCircle(pt, 3.5, Paint()..color = lineColor);
      // Inner core
      canvas.drawCircle(pt, 1.8, Paint()..color = Colors.black);
    }
  }

  @override
  bool shouldRepaint(covariant EloLineGraphPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor || oldDelegate.data != data;
  }
}

// CUSTOM PAINTER FOR PERFORMANCE RADAR CHART
