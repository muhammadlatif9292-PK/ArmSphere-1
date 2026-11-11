import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Geometric slash modes for non-image crystal-transparent cards & rows.
/// Keeps ~78% of the card interior 100% transparent (`Colors.transparent`)
/// while painting precision diagonal crimson, obsidian, and titanium-gold
/// telemetry ribbons clipped to the card's border radius.
enum CrystalSlashMode {
  /// Sequential flowing 3-ribbon pattern for horizontal bar cards & stacked rows.
  sequentialRow,

  /// Crossed A-Frame / X-Strap pattern for larger rectangular cards & KPI boxes.
  crossedCard,
}

@immutable
class CrystalSlashVariant {
  final CrystalSlashMode mode;
  final int rowIndex;
  final double intensity;

  const CrystalSlashVariant.sequentialRow([
    this.rowIndex = 0,
    this.intensity = 1.0,
  ]) : mode = CrystalSlashMode.sequentialRow;

  const CrystalSlashVariant.crossedCard({this.intensity = 1.0})
    : mode = CrystalSlashMode.crossedCard,
      rowIndex = 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CrystalSlashVariant &&
          runtimeType == other.runtimeType &&
          mode == other.mode &&
          rowIndex == other.rowIndex &&
          intensity == other.intensity;

  @override
  int get hashCode => Object.hash(mode, rowIndex, intensity);
}

/// Reusable wrapper that paints diagonal crimson & obsidian-titanium stripes
/// behind [child], strictly clipped to [borderRadius].
class CrystalSlashWrapper extends StatelessWidget {
  final Widget child;
  final CrystalSlashVariant variant;
  final BorderRadius borderRadius;
  final bool enabled;

  const CrystalSlashWrapper({
    super.key,
    required this.child,
    this.variant = const CrystalSlashVariant.crossedCard(),
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.enabled = true,
  });

  factory CrystalSlashWrapper.sequentialRow({
    Key? key,
    required Widget child,
    int rowIndex = 0,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(16)),
    double intensity = 1.0,
    bool enabled = true,
  }) {
    return CrystalSlashWrapper(
      key: key,
      variant: CrystalSlashVariant.sequentialRow(rowIndex, intensity),
      borderRadius: borderRadius,
      enabled: enabled,
      child: child,
    );
  }

  factory CrystalSlashWrapper.crossedCard({
    Key? key,
    required Widget child,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(18)),
    double intensity = 1.0,
    bool enabled = true,
  }) {
    return CrystalSlashWrapper(
      key: key,
      variant: CrystalSlashVariant.crossedCard(intensity: intensity),
      borderRadius: borderRadius,
      enabled: enabled,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return ClipRRect(
      borderRadius: borderRadius,
      child: CustomPaint(
        painter: CrystalSlashPainter(variant: variant),
        child: child,
      ),
    );
  }
}

class CrystalSlashPainter extends CustomPainter {
  final CrystalSlashVariant variant;

  const CrystalSlashPainter({required this.variant});

  Color _scaleAlpha(Color color, double factor) {
    final double f = factor.clamp(0.0, 1.5);
    final int newAlpha = ((color.a * 255.0) * f).round().clamp(0, 255);
    return color.withAlpha(newAlpha);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    switch (variant.mode) {
      case CrystalSlashMode.sequentialRow:
        _paintSequentialRow(canvas, size);
        break;
      case CrystalSlashMode.crossedCard:
        _paintCrossedCard(canvas, size);
        break;
    }
  }

  void _paintSequentialRow(Canvas canvas, Size size) {
    final int idx = variant.rowIndex.abs();
    final double k = variant.intensity;

    // 1. Slash 1 (Left-Center, ~x: 0.24 - (rowIndex % 4) * 0.035, width: 16px, angle: 28 deg)
    final double x1 = (0.24 - (idx % 4) * 0.035) * size.width;
    _drawAngledRibbon(
      canvas: canvas,
      size: size,
      centerX: x1,
      width: 16.0,
      angleDegrees: 28.0,
      gradientColors: [
        _scaleAlpha(const Color(0x40E23B3B), k),
        _scaleAlpha(const Color(0x7305070C), k),
      ],
      leadingEdgeColor: _scaleAlpha(const Color(0x66E23B3B), k),
      trailingEdgeColor: _scaleAlpha(const Color(0x26E23B3B), k),
    );

    // 2. Slash 2 (Center-Right, ~x: 0.54 - (rowIndex % 4) * 0.035, width: 28px, angle: 32 deg)
    final double x2 = (0.54 - (idx % 4) * 0.035) * size.width;
    _drawAngledRibbon(
      canvas: canvas,
      size: size,
      centerX: x2,
      width: 28.0,
      angleDegrees: 32.0,
      gradientColors: [
        _scaleAlpha(const Color(0x8005070C), k),
        _scaleAlpha(const Color(0x2EE23B3B), k),
        _scaleAlpha(const Color(0x8005070C), k),
      ],
      leadingEdgeColor: _scaleAlpha(const Color(0x4094A3B8), k),
      trailingEdgeColor: _scaleAlpha(const Color(0x3394A3B8), k),
    );

    // 3. Slash 3 (Far-Right Counter-Accent, ~x: 0.78 + (rowIndex % 3) * 0.025, width: 12px, angle: -22 deg)
    final double x3 = (0.78 + (idx % 3) * 0.025) * size.width;
    _drawAngledRibbon(
      canvas: canvas,
      size: size,
      centerX: x3,
      width: 12.0,
      angleDegrees: -22.0,
      gradientColors: [
        _scaleAlpha(const Color(0x33E23B3B), k),
        _scaleAlpha(const Color(0x26D4AF37), k),
      ],
      leadingEdgeColor: _scaleAlpha(const Color(0x40D4AF37), k),
      trailingEdgeColor: _scaleAlpha(const Color(0x26E23B3B), k),
    );
  }

  void _paintCrossedCard(Canvas canvas, Size size) {
    final double k = variant.intensity;

    // 1. Two Parallel Upward-Right Straps (width: 22px and 26px)
    // Running from bottom-left (x: 0.16, y: 1.0) -> top-center (x: 0.38, y: 0.0)
    // and (x: 0.42, y: 1.0) -> (x: 0.66, y: 0.0)
    _drawPointToPointRibbon(
      canvas: canvas,
      size: size,
      start: Offset(size.width * 0.16, size.height),
      end: Offset(size.width * 0.38, 0.0),
      width: 22.0,
      gradientColors: [
        _scaleAlpha(const Color(0x8805070C), k),
        _scaleAlpha(const Color(0x38E23B3B), k),
        _scaleAlpha(const Color(0x8805070C), k),
      ],
      edgeColor: _scaleAlpha(const Color(0x59E23B3B), k),
    );

    _drawPointToPointRibbon(
      canvas: canvas,
      size: size,
      start: Offset(size.width * 0.42, size.height),
      end: Offset(size.width * 0.66, 0.0),
      width: 26.0,
      gradientColors: [
        _scaleAlpha(const Color(0x8805070C), k),
        _scaleAlpha(const Color(0x38E23B3B), k),
        _scaleAlpha(const Color(0x8805070C), k),
      ],
      edgeColor: _scaleAlpha(const Color(0x59E23B3B), k),
    );

    // 2. One Intersecting Counter-Diagonal Slash (width: 10px)
    // Running from top-left-center (x: 0.38, y: 0.0) -> bottom-right (x: 0.76, y: 1.0)
    _drawPointToPointRibbon(
      canvas: canvas,
      size: size,
      start: Offset(size.width * 0.38, 0.0),
      end: Offset(size.width * 0.76, size.height),
      width: 10.0,
      gradientColors: [
        _scaleAlpha(const Color(0x33E23B3B), k),
        _scaleAlpha(const Color(0x5905070C), k),
        _scaleAlpha(const Color(0x33E23B3B), k),
      ],
      edgeColor: _scaleAlpha(const Color(0x3394A3B8), k),
    );

    // 3. One Subtle Horizontal/Angled Tension Bridge (height: 6px, y: 0.56, spanning x: 0.24..0.68)
    final double bridgeY = size.height * 0.56;
    final Rect bridgeRect = Rect.fromLTWH(
      size.width * 0.24,
      bridgeY - 3.0,
      size.width * (0.68 - 0.24),
      6.0,
    );
    final Paint bridgePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          _scaleAlpha(const Color(0x1AE23B3B), k),
          _scaleAlpha(const Color(0x33E23B3B), k),
          _scaleAlpha(const Color(0x1AD4AF37), k),
        ],
      ).createShader(bridgeRect);
    canvas.drawRect(bridgeRect, bridgePaint);

    final Paint bridgeEdgePaint = Paint()
      ..color = _scaleAlpha(const Color(0x40E23B3B), k)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(bridgeRect.left, bridgeRect.top),
      Offset(bridgeRect.right, bridgeRect.top),
      bridgeEdgePaint,
    );
  }

  void _drawAngledRibbon({
    required Canvas canvas,
    required Size size,
    required double centerX,
    required double width,
    required double angleDegrees,
    required List<Color> gradientColors,
    required Color leadingEdgeColor,
    required Color trailingEdgeColor,
  }) {
    final double radians = angleDegrees * (math.pi / 180.0);
    final double dx = (size.height * 0.5) * math.tan(radians);
    final double halfWidth = width * 0.5;

    final Offset topLeft = Offset(centerX + dx - halfWidth, 0.0);
    final Offset topRight = Offset(centerX + dx + halfWidth, 0.0);
    final Offset bottomRight = Offset(centerX - dx + halfWidth, size.height);
    final Offset bottomLeft = Offset(centerX - dx - halfWidth, size.height);

    final Path path = Path()
      ..moveTo(topLeft.dx, topLeft.dy)
      ..lineTo(topRight.dx, topRight.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..lineTo(bottomLeft.dx, bottomLeft.dy)
      ..close();

    final Rect bounds = path.getBounds();
    final Paint fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: gradientColors,
      ).createShader(bounds);

    canvas.drawPath(path, fillPaint);

    final Paint leadingStroke = Paint()
      ..color = leadingEdgeColor
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;
    canvas.drawLine(bottomLeft, topLeft, leadingStroke);

    final Paint trailingStroke = Paint()
      ..color = trailingEdgeColor
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;
    canvas.drawLine(bottomRight, topRight, trailingStroke);
  }

  void _drawPointToPointRibbon({
    required Canvas canvas,
    required Size size,
    required Offset start,
    required Offset end,
    required double width,
    required List<Color> gradientColors,
    required Color edgeColor,
  }) {
    final double halfW = width * 0.5;
    final Offset p1 = Offset(start.dx - halfW, start.dy);
    final Offset p2 = Offset(start.dx + halfW, start.dy);
    final Offset p3 = Offset(end.dx + halfW, end.dy);
    final Offset p4 = Offset(end.dx - halfW, end.dy);

    final Path path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p4.dx, p4.dy)
      ..close();

    final Rect bounds = path.getBounds();
    final Paint fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradientColors,
      ).createShader(bounds);

    canvas.drawPath(path, fillPaint);

    final Paint edgeStroke = Paint()
      ..color = edgeColor
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;
    canvas.drawLine(p1, p4, edgeStroke);
    canvas.drawLine(p2, p3, edgeStroke);
  }

  @override
  bool shouldRepaint(covariant CrystalSlashPainter oldDelegate) {
    return oldDelegate.variant != variant;
  }
}

/// 3D Vapor Dissolve scroll edge wrapper.
/// Dissolves scrolling content at the top (0.0 -> 0.055) and bottom (0.91 -> 1.0)
/// while keeping the center zone (0.055 -> 0.91) 100% clear, and optionally
/// constrains the bottom viewport boundary 10px above the floating bottom nav pill.
class CrystalVaporDissolve extends StatelessWidget {
  final Widget child;
  final bool enabled;
  final double bottomMargin;

  const CrystalVaporDissolve({
    super.key,
    required this.child,
    this.enabled = true,
    this.bottomMargin = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    Widget masked = ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (Rect bounds) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: <double>[0.0, 0.025, 0.055, 0.91, 0.945, 0.98, 1.0],
          colors: <Color>[
            Color(0x00FFFFFF),
            Color(0x66FFFFFF),
            Color(0xFFFFFFFF),
            Color(0xFFFFFFFF),
            Color(0x80FFFFFF),
            Color(0x1AFFFFFF),
            Color(0x00FFFFFF),
          ],
        ).createShader(bounds);
      },
      child: child,
    );

    if (bottomMargin > 0) {
      masked = Padding(
        padding: EdgeInsets.only(bottom: bottomMargin),
        child: masked,
      );
    }

    return masked;
  }
}
