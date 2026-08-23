import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Single data point for Performance Graph
class PerformanceDataPoint {
  final String label; // e.g., 'Jan 10', 'Match 12'
  final String matchTitle; // e.g., 'vs. Devon L.'
  final double elo; // e.g., 1980
  final int eloChange; // e.g., +24
  final bool isWin; // true for W, false for L

  const PerformanceDataPoint({
    required this.label,
    required this.matchTitle,
    required this.elo,
    required this.eloChange,
    required this.isWin,
  });
}

/// CustomPainter for smooth cubic spline bezier graph line, gradient fill, and interactive scrubbing line
class _PerformanceChartPainter extends CustomPainter {
  final List<PerformanceDataPoint> dataPoints;
  final double progress; // 0.0 to 1.0 animation on load
  final int? selectedIndex; // Selected index when user scrubs
  final Color lineColor = AppTheme.goldPrimary;
  final Color fillGradientStart = const Color(0x33D4AF37);

  _PerformanceChartPainter({
    required this.dataPoints,
    required this.progress,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final paddingLeft = 16.0;
    final paddingRight = 16.0;
    final paddingTop = 20.0;
    final paddingBottom = 24.0;

    final width = size.width - paddingLeft - paddingRight;
    final height = size.height - paddingTop - paddingBottom;

    // Find min and max ELO
    double minElo = dataPoints.first.elo;
    double maxElo = dataPoints.first.elo;
    for (var p in dataPoints) {
      if (p.elo < minElo) minElo = p.elo;
      if (p.elo > maxElo) maxElo = p.elo;
    }
    // Add margin to min and max so line doesn't hit absolute edge
    final eloRange = (maxElo - minElo) == 0 ? 100.0 : (maxElo - minElo) * 1.25;
    final eloBase = minElo - (eloRange * 0.1);

    // Compute screen coordinates for points
    final points = <Offset>[];
    for (int i = 0; i < dataPoints.length; i++) {
      final x = paddingLeft + (i / (dataPoints.length - 1)) * width;
      final normalizedY = (dataPoints[i].elo - eloBase) / eloRange;
      final y = paddingTop + height - (normalizedY * height);
      points.add(Offset(x, y));
    }

    // Draw horizontal background guide lines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 3; i++) {
      final y = paddingTop + (height / 3) * i;
      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width - paddingRight, y), gridPaint);
    }

    // Generate smooth spline path using Bezier curves
    final path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);

      for (int i = 0; i < points.length - 1; i++) {
        final current = points[i];
        final next = points[i + 1];

        final controlPoint1 = Offset(
          current.dx + (next.dx - current.dx) / 2,
          current.dy,
        );
        final controlPoint2 = Offset(
          current.dx + (next.dx - current.dx) / 2,
          next.dy,
        );

        path.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          next.dx,
          next.dy,
        );
      }
    }

    // Trim path according to animation progress
    final pathMetrics = path.computeMetrics().toList();
    if (pathMetrics.isEmpty) return;

    final totalLength = pathMetrics.first.length;
    final animatedPath = pathMetrics.first.extractPath(0, totalLength * progress);

    // Draw Area Fill under animated path
    final fillPath = Path.from(animatedPath);
    if (points.isNotEmpty) {
      final currentLastX = paddingLeft + (progress * width);
      fillPath.lineTo(currentLastX, paddingTop + height);
      fillPath.lineTo(paddingLeft, paddingTop + height);
      fillPath.close();

      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            fillGradientStart,
            fillGradientStart.withOpacity(0.05),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw Glow shadow behind the line
    final lineGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..color = lineColor.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawPath(animatedPath, lineGlowPaint);

    // Draw Solid Curve Line
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = lineColor
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(animatedPath, linePaint);

    // Draw Joint Dots
    final dotPaint = Paint()..style = PaintingStyle.fill;
    final dotBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = lineColor;

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      // Only draw dots that have been reached by animation
      if (p.dx <= paddingLeft + (progress * width) + 1) {
        final isSelected = selectedIndex == i;
        final dp = dataPoints[i];

        // Fill dot
        dotPaint.color = dp.isWin ? AppTheme.success : AppTheme.error;
        canvas.drawCircle(p, isSelected ? 5.0 : 3.0, dotPaint);
        canvas.drawCircle(p, isSelected ? 5.0 : 3.0, dotBorderPaint);

        if (isSelected) {
          // Glow ring around selected dot
          final selectGlow = Paint()
            ..color = lineColor.withOpacity(0.3)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(p, 10.0, selectGlow);

          // Vertical scrub guide line
          final scrubPaint = Paint()
            ..color = lineColor.withOpacity(0.4)
            ..strokeWidth = 1.0
            ..style = PaintingStyle.stroke;

          canvas.drawLine(
            Offset(p.dx, paddingTop),
            Offset(p.dx, paddingTop + height),
            scrubPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PerformanceChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.dataPoints != dataPoints;
  }
}

/// Ultra-Premium Interactive Performance Graph Card (Concept 2 - Glass Morphism Luxury)
class PerformanceGraphCard extends StatefulWidget {
  final List<PerformanceDataPoint>? customData;

  const PerformanceGraphCard({
    Key? key,
    this.customData,
  }) : super(key: key);

  @override
  State<PerformanceGraphCard> createState() => _PerformanceGraphCardState();
}

class _PerformanceGraphCardState extends State<PerformanceGraphCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _drawController;
  late List<PerformanceDataPoint> _dataPoints;
  int? _selectedIndex;
  String _activeFilter = 'ELO History';

  @override
  void initState() {
    super.initState();

    _dataPoints = widget.customData ??
        const [
          PerformanceDataPoint(
            label: 'Match 1',
            matchTitle: 'vs. Bilawal M.',
            elo: 1910,
            eloChange: 14,
            isWin: true,
          ),
          PerformanceDataPoint(
            label: 'Match 2',
            matchTitle: 'vs. Usman R.',
            elo: 1928,
            eloChange: 18,
            isWin: true,
          ),
          PerformanceDataPoint(
            label: 'Match 3',
            matchTitle: 'vs. Zarak K.',
            elo: 1916,
            eloChange: -12,
            isWin: false,
          ),
          PerformanceDataPoint(
            label: 'Match 4',
            matchTitle: 'vs. Tarkan A.',
            elo: 1952,
            eloChange: 36,
            isWin: true,
          ),
          PerformanceDataPoint(
            label: 'Match 5',
            matchTitle: 'vs. Rashid S.',
            elo: 1980,
            eloChange: 28,
            isWin: true,
          ),
          PerformanceDataPoint(
            label: 'Match 6',
            matchTitle: 'vs. Devon L.',
            elo: 2016,
            eloChange: 36,
            isWin: true,
          ),
        ];

    // Select latest match by default
    _selectedIndex = _dataPoints.length - 1;

    // Smooth line drawing animation on load (380ms crisp draw)
    _drawController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _drawController.forward();
  }

  @override
  void dispose() {
    _drawController.dispose();
    super.dispose();
  }

  void _handleTouch(Offset localPosition, Size size) {
    const paddingLeft = 16.0;
    const paddingRight = 16.0;
    final width = size.width - paddingLeft - paddingRight;

    final dx = (localPosition.dx - paddingLeft).clamp(0.0, width);
    final ratio = dx / width;
    final index = (ratio * (_dataPoints.length - 1)).round().clamp(0, _dataPoints.length - 1);

    if (_selectedIndex != index) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedPoint = _selectedIndex != null ? _dataPoints[_selectedIndex!] : _dataPoints.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row with Filter Pills
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppTheme.goldPrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'PERFORMANCE TREND',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),

            // Mode Selector
            Row(
              children: ['ELO History', 'Win Rate'].map((filter) {
                final isSelected = filter == _activeFilter;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _activeFilter = filter;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.goldPrimary.withOpacity(0.18)
                          : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.goldPrimary.withOpacity(0.5)
                            : Colors.transparent,
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                        color: isSelected ? AppTheme.goldLight : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Glassmorphic Chart Container
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 16.0,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: AppTheme.goldPrimary.withOpacity(0.06),
                blurRadius: 20.0,
                spreadRadius: -2.0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14.0, sigmaY: 14.0),
              child: Container(
                padding: const EdgeInsets.all(18.0),
                decoration: BoxDecoration(
                  color: const Color(0xDD121622),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(
                    color: AppTheme.goldPrimary.withOpacity(0.2),
                    width: 1.0,
                  ),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1E2332),
                      Color(0xFF121622),
                      Color(0xFF0D0F18),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Interactive Glass Tooltip Bay
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xCC0E111A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.goldPrimary.withOpacity(0.2),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${selectedPoint.label} • ${selectedPoint.matchTitle}',
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontBody,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    '${selectedPoint.elo.toInt()} ELO',
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Result Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (selectedPoint.isWin ? AppTheme.success : AppTheme.error).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${selectedPoint.isWin ? 'WIN' : 'LOSS'} ${selectedPoint.eloChange >= 0 ? '+' : ''}${selectedPoint.eloChange}',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: selectedPoint.isWin ? AppTheme.success : AppTheme.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: const [
                              Text(
                                'DRAG GRAPH',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.goldPrimary,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              SizedBox(height: 2),
                              Icon(
                                Icons.touch_app_outlined,
                                size: 16,
                                color: AppTheme.goldLight,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Canvas Chart Area with Gesture Scrubbing
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final canvasSize = Size(constraints.maxWidth, 140);
                        return GestureDetector(
                          onPanStart: (details) => _handleTouch(details.localPosition, canvasSize),
                          onPanUpdate: (details) => _handleTouch(details.localPosition, canvasSize),
                          onTapDown: (details) => _handleTouch(details.localPosition, canvasSize),
                          child: AnimatedBuilder(
                            animation: _drawController,
                            builder: (context, child) {
                              return CustomPaint(
                                size: canvasSize,
                                painter: _PerformanceChartPainter(
                                  dataPoints: _dataPoints,
                                  progress: _drawController.value,
                                  selectedIndex: _selectedIndex,
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 10),

                    // X-Axis Match Labels
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _dataPoints.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final dp = entry.value;
                        final isSelected = idx == _selectedIndex;

                        return Text(
                          dp.label,
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 9.5,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                            color: isSelected ? AppTheme.goldPrimary : AppTheme.textMuted,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
