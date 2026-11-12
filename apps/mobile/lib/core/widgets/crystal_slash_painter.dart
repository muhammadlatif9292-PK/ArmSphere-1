import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Forged Arm-Wrestling Crystal Modes (replaces legacy diagonal crossing stripes).
///
/// Layer 1: Whisper-Dark Optical Crystal Lens (`Color(0x4704060B)`, 28% pure obsidian).
/// Layer 2: Forged Regulation Table Hardware Edge Accents (Edges Only — zero lines crossing text).
/// Layer 3: Micro-Subtle (4.5% Opacity, `Color(0x0CFFFFFF)`) Arm-Wrestling Instrument Watermarks.
enum CrystalSlashMode {
  /// Horizontal Bar Card mode (`ForgedCrystalRow`):
  /// 3.5px Forged Corner-Pad Bar along the left vertical edge + 28px horizontal edge glow.
  sequentialRow,

  /// Rectangular Feature Card mode (`ForgedCrystalCard`):
  /// Precision L-Shaped Steel Table Corner Brackets (14px arm, 2.0px stroke) on top-left & bottom-right
  /// + optional 4.5% opacity arm-wrestling instrument watermark in bottom-right corner.
  crossedCard,
}

/// Domain-specific Arm-Wrestling Instrument Watermarks (4.5% opacity `Color(0x0CFFFFFF)`).
enum ForgedWatermarkType {
  /// No watermark (clean optical lens + corner brackets only).
  none,

  /// ELO & Standing Cards: Regulation Table Pin-Pad & Steel Peg silhouette.
  pinPadAndPeg,

  /// Recovery & Training Cards: Knurled Steel Pulley Handle & Pronation Strap silhouette.
  pulleyAndStrap,

  /// Biometrics Card: Subtle precision caliper graduation ticks along the bottom edge.
  caliperTicks,

  /// Bout & Referee Cards: Coiled Referee Buckle Strap silhouette.
  refereeStrap,

  /// Admin & Dossier Cards: Octagonal Locked-Forearms Shield silhouette.
  adminOctagonShield,
}

@immutable
class CrystalSlashVariant {
  final CrystalSlashMode mode;
  final int rowIndex;
  final double intensity;
  final Color? accentColor;
  final ForgedWatermarkType watermark;

  const CrystalSlashVariant.sequentialRow([
    this.rowIndex = 0,
    this.intensity = 1.0,
    this.accentColor,
  ]) : mode = CrystalSlashMode.sequentialRow,
       watermark = ForgedWatermarkType.none;

  const CrystalSlashVariant.crossedCard({
    this.intensity = 1.0,
    this.accentColor,
    this.watermark = ForgedWatermarkType.none,
  }) : mode = CrystalSlashMode.crossedCard,
       rowIndex = 0;

  CrystalSlashVariant copyWith({
    CrystalSlashMode? mode,
    int? rowIndex,
    double? intensity,
    Color? accentColor,
    ForgedWatermarkType? watermark,
  }) {
    if ((mode ?? this.mode) == CrystalSlashMode.sequentialRow) {
      return CrystalSlashVariant.sequentialRow(
        rowIndex ?? this.rowIndex,
        intensity ?? this.intensity,
        accentColor ?? this.accentColor,
      );
    }
    return CrystalSlashVariant.crossedCard(
      intensity: intensity ?? this.intensity,
      accentColor: accentColor ?? this.accentColor,
      watermark: watermark ?? this.watermark,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CrystalSlashVariant &&
          runtimeType == other.runtimeType &&
          mode == other.mode &&
          rowIndex == other.rowIndex &&
          intensity == other.intensity &&
          accentColor == other.accentColor &&
          watermark == other.watermark;

  @override
  int get hashCode =>
      Object.hash(mode, rowIndex, intensity, accentColor, watermark);
}

/// Rectangular Feature Card wrapper in the Forged Arm-Wrestling Crystal system.
class ForgedCrystalCard extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final Color accentColor;
  final ForgedWatermarkType watermark;
  final bool enabled;
  final bool paintOpticalLens;

  const ForgedCrystalCard({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.accentColor = const Color(0xFFE23B3B),
    this.watermark = ForgedWatermarkType.none,
    this.enabled = true,
    this.paintOpticalLens = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return ClipRRect(
      borderRadius: borderRadius,
      child: CustomPaint(
        painter: CrystalSlashPainter(
          variant: CrystalSlashVariant.crossedCard(
            accentColor: accentColor,
            watermark: watermark,
          ),
          borderRadius: borderRadius,
          paintOpticalLens: paintOpticalLens,
        ),
        child: child,
      ),
    );
  }
}

/// Horizontal Bar Card wrapper in the Forged Arm-Wrestling Crystal system.
class ForgedCrystalRow extends StatelessWidget {
  final Widget child;
  final int rowIndex;
  final BorderRadius borderRadius;
  final Color? accentColor;
  final bool enabled;
  final bool paintOpticalLens;

  const ForgedCrystalRow({
    super.key,
    required this.child,
    this.rowIndex = 0,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.accentColor,
    this.enabled = true,
    this.paintOpticalLens = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return ClipRRect(
      borderRadius: borderRadius,
      child: CustomPaint(
        painter: CrystalSlashPainter(
          variant: CrystalSlashVariant.sequentialRow(
            rowIndex,
            1.0,
            accentColor,
          ),
          borderRadius: borderRadius,
          paintOpticalLens: paintOpticalLens,
        ),
        child: child,
      ),
    );
  }
}

/// Forged Arm-Wrestling Crystal wrapper (drop-in replacement for `CrystalSlashWrapper`).
/// Renders ZERO crossing diagonal lines behind typography or numbers.
class CrystalSlashWrapper extends StatelessWidget {
  final Widget child;
  final CrystalSlashVariant variant;
  final BorderRadius borderRadius;
  final bool enabled;
  final bool paintOpticalLens;

  const CrystalSlashWrapper({
    super.key,
    required this.child,
    this.variant = const CrystalSlashVariant.crossedCard(),
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.enabled = true,
    this.paintOpticalLens = true,
  });

  factory CrystalSlashWrapper.sequentialRow({
    Key? key,
    required Widget child,
    int rowIndex = 0,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(16)),
    double intensity = 1.0,
    Color? accentColor,
    bool enabled = true,
    bool paintOpticalLens = true,
  }) {
    return CrystalSlashWrapper(
      key: key,
      variant: CrystalSlashVariant.sequentialRow(
        rowIndex,
        intensity,
        accentColor,
      ),
      borderRadius: borderRadius,
      enabled: enabled,
      paintOpticalLens: paintOpticalLens,
      child: child,
    );
  }

  factory CrystalSlashWrapper.crossedCard({
    Key? key,
    required Widget child,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(18)),
    double intensity = 1.0,
    Color? accentColor,
    ForgedWatermarkType watermark = ForgedWatermarkType.none,
    bool enabled = true,
    bool paintOpticalLens = true,
  }) {
    return CrystalSlashWrapper(
      key: key,
      variant: CrystalSlashVariant.crossedCard(
        intensity: intensity,
        accentColor: accentColor,
        watermark: watermark,
      ),
      borderRadius: borderRadius,
      enabled: enabled,
      paintOpticalLens: paintOpticalLens,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return ClipRRect(
      borderRadius: borderRadius,
      child: CustomPaint(
        painter: CrystalSlashPainter(
          variant: variant,
          borderRadius: borderRadius,
          paintOpticalLens: paintOpticalLens,
        ),
        child: child,
      ),
    );
  }
}

class CrystalSlashPainter extends CustomPainter {
  final CrystalSlashVariant variant;
  final BorderRadius borderRadius;
  final bool paintOpticalLens;

  static const Color opticalLensColor = Color(0x4704060B);
  static const Color competitionCrimson = Color(0xFFE23B3B);
  static const Color championshipGold = Color(0xFFD4AF37);
  static const Color watermarkColor = Color(0x0CFFFFFF);

  const CrystalSlashPainter({
    required this.variant,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.paintOpticalLens = true,
  });

  Color _resolveAccentColor() {
    if (variant.accentColor != null) {
      final c = variant.accentColor!;
      // Map gold-like accents to 24k Champagne Gold, everything else to Competition Crimson
      // unless explicitly gold or crimson.
      if (c.value == championshipGold.value ||
          (c.r > 0.75 && c.g > 0.55 && c.b < 0.35)) {
        return championshipGold;
      }
      return competitionCrimson;
    }
    if (variant.mode == CrystalSlashMode.sequentialRow) {
      return (variant.rowIndex.abs() % 3 == 1)
          ? championshipGold
          : competitionCrimson;
    }
    if (variant.watermark == ForgedWatermarkType.adminOctagonShield) {
      return championshipGold;
    }
    return competitionCrimson;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Layer 1: Whisper-Dark Optical Crystal Lens (28% pure obsidian, zero crossing lines)
    if (paintOpticalLens) {
      final Paint lensPaint = Paint()
        ..color = opticalLensColor
        ..style = PaintingStyle.fill;
      canvas.drawRect(Offset.zero & size, lensPaint);
    }

    // Layer 2: Forged Regulation Table Hardware Edge Accents
    switch (variant.mode) {
      case CrystalSlashMode.sequentialRow:
        _paintForgedCornerPadRow(canvas, size);
        break;
      case CrystalSlashMode.crossedCard:
        _paintForgedTableCornerBrackets(canvas, size);
        // Layer 3: Micro-Subtle (4.5% Opacity) Arm-Wrestling Instrument Watermarks
        if (variant.watermark != ForgedWatermarkType.none) {
          _paintInstrumentWatermark(canvas, size, variant.watermark);
        }
        break;
    }
  }

  /// Layer 2A: Horizontal Bar Card (`ForgedCrystalRow`)
  /// Crisp 3.5px Forged Corner-Pad Bar along the left vertical edge (inset by 1px)
  /// + soft 28px-wide horizontal edge glow (`0x24` -> `Colors.transparent`).
  void _paintForgedCornerPadRow(Canvas canvas, Size size) {
    final Color accent = _resolveAccentColor();
    final Color glowStart = accent.value == championshipGold.value
        ? const Color(0x24D4AF37)
        : const Color(0x24E23B3B);

    // 1. Soft 28px-wide horizontal edge glow from left edge
    final Rect glowRect = Rect.fromLTWH(1.0, 0.0, 28.0, size.height);
    final Paint glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[glowStart, Colors.transparent],
      ).createShader(glowRect);
    canvas.drawRect(glowRect, glowPaint);

    // 2. Crisp 3.5px Forged Corner-Pad Bar along the left vertical edge (inset by 1px)
    final double verticalInset = math.min(8.0, size.height * 0.18);
    final RRect padBar = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        1.0,
        verticalInset,
        3.5,
        math.max(4.0, size.height - (verticalInset * 2.0)),
      ),
      const Radius.circular(2.0),
    );
    final Paint barPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawRRect(padBar, barPaint);
  }

  /// Layer 2B: Rectangular Feature Card (`ForgedCrystalCard`)
  /// Precision L-Shaped Steel Table Corner Brackets (14px arm length, 2.0px stroke width)
  /// on the top-left and bottom-right corners of the card border.
  void _paintForgedTableCornerBrackets(Canvas canvas, Size size) {
    final Color accent = _resolveAccentColor();
    const double strokeWidth = 2.0;
    const double inset = 1.0;
    final double armLength = math.min(
      14.0,
      math.min(size.width, size.height) * 0.28,
    );
    final double r = math.min(
      borderRadius.topLeft.x.clamp(4.0, 18.0),
      armLength,
    );

    final Paint bracketPaint = Paint()
      ..color = accent
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    // Top-Left L-Bracket following the top-left corner curve (14px horizontal & vertical extent)
    final Path topLeftPath = Path()
      ..moveTo(inset, inset + armLength)
      ..lineTo(inset, inset + r)
      ..arcToPoint(
        Offset(inset + r, inset),
        radius: Radius.circular(r),
        clockwise: true,
      )
      ..lineTo(inset + armLength, inset);
    canvas.drawPath(topLeftPath, bracketPaint);

    // Bottom-Right L-Bracket following the bottom-right corner curve (14px horizontal & vertical extent)
    final Path bottomRightPath = Path()
      ..moveTo(size.width - inset - armLength, size.height - inset)
      ..lineTo(size.width - inset - r, size.height - inset)
      ..arcToPoint(
        Offset(size.width - inset, size.height - inset - r),
        radius: Radius.circular(r),
        clockwise: false,
      )
      ..lineTo(size.width - inset, size.height - inset - armLength);
    canvas.drawPath(bottomRightPath, bracketPaint);
  }

  /// Layer 3: Micro-Subtle (4.5% Opacity, `Color(0x0CFFFFFF)`) Arm-Wrestling Instrument Watermarks
  /// Tucked into the bottom-right corner (`right: 12, bottom: 10`, `48x48px`).
  void _paintInstrumentWatermark(
    Canvas canvas,
    Size size,
    ForgedWatermarkType type,
  ) {
    if (type == ForgedWatermarkType.caliperTicks) {
      _paintCaliperGraduationTicks(canvas, size);
      return;
    }

    if (size.width < 72 || size.height < 64) return;
    final Rect box = Rect.fromLTWH(
      size.width - 12.0 - 48.0,
      size.height - 10.0 - 48.0,
      48.0,
      48.0,
    );

    canvas.save();
    canvas.translate(box.left, box.top);

    final Paint fillPaint = Paint()
      ..color = watermarkColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final Paint strokePaint = Paint()
      ..color = watermarkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    switch (type) {
      case ForgedWatermarkType.pinPadAndPeg:
        // Regulation Table Pin-Pad (sloped competition pillow) + vertical Steel Grip Peg
        final Path pinPad = Path()
          ..moveTo(2.0, 38.0)
          ..lineTo(6.0, 24.0)
          ..lineTo(28.0, 26.0)
          ..lineTo(30.0, 38.0)
          ..close();
        canvas.drawPath(pinPad, fillPaint);
        canvas.drawPath(pinPad, strokePaint);
        // Base mounting plate
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(1.0, 40.0, 46.0, 4.0),
            const Radius.circular(1.5),
          ),
          fillPaint,
        );
        // Vertical cylindrical steel grip peg on the right
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(35.0, 8.0, 7.0, 32.0),
            const Radius.circular(2.5),
          ),
          fillPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(33.5, 6.0, 10.0, 3.5),
            const Radius.circular(1.5),
          ),
          fillPaint,
        );
        // Knurled grip rings on peg
        canvas.drawLine(
          const Offset(35.0, 16.0),
          const Offset(42.0, 16.0),
          strokePaint,
        );
        canvas.drawLine(
          const Offset(35.0, 22.0),
          const Offset(42.0, 22.0),
          strokePaint,
        );
        break;

      case ForgedWatermarkType.pulleyAndStrap:
        // Knurled Steel Pulley Handle + Pronation Strap loop
        // Top carabiner ring
        canvas.drawCircle(const Offset(24.0, 8.0), 4.5, strokePaint);
        // Angled steel pulley cylinder
        canvas.save();
        canvas.translate(24.0, 26.0);
        canvas.rotate(-0.32);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-6.0, -13.0, 12.0, 26.0),
            const Radius.circular(3.0),
          ),
          fillPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-6.0, -13.0, 12.0, 26.0),
            const Radius.circular(3.0),
          ),
          strokePaint,
        );
        // Knurling cross lines
        canvas.drawLine(
          const Offset(-5.0, -5.0),
          const Offset(5.0, 1.0),
          strokePaint,
        );
        canvas.drawLine(
          const Offset(-5.0, 2.0),
          const Offset(5.0, 8.0),
          strokePaint,
        );
        canvas.restore();
        // Pronation webbing strap loop sweeping around the handle
        final Path strapArc = Path()
          ..moveTo(22.0, 12.0)
          ..cubicTo(6.0, 16.0, 4.0, 36.0, 20.0, 42.0)
          ..cubicTo(36.0, 45.0, 44.0, 30.0, 30.0, 18.0);
        canvas.drawPath(
          strapArc,
          strokePaint..strokeWidth = 2.6,
        );
        break;

      case ForgedWatermarkType.refereeStrap:
        // Coiled Referee Buckle Strap silhouette
        // Heavy steel D-buckle frame
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(6.0, 10.0, 16.0, 12.0),
            const Radius.circular(2.5),
          ),
          strokePaint..strokeWidth = 2.2,
        );
        canvas.drawLine(
          const Offset(14.0, 10.0),
          const Offset(14.0, 22.0),
          strokePaint,
        );
        // Coiled double-loop competition strap bands
        final Path coilOuter = Path()
          ..moveTo(22.0, 14.0)
          ..cubicTo(42.0, 12.0, 46.0, 32.0, 28.0, 38.0)
          ..cubicTo(12.0, 43.0, 6.0, 30.0, 18.0, 25.0);
        final Path coilInner = Path()
          ..moveTo(22.0, 19.0)
          ..cubicTo(36.0, 18.0, 38.0, 30.0, 26.0, 33.0)
          ..lineTo(38.0, 43.0);
        canvas.drawPath(coilOuter, strokePaint..strokeWidth = 2.4);
        canvas.drawPath(coilInner, strokePaint..strokeWidth = 1.8);
        break;

      case ForgedWatermarkType.adminOctagonShield:
        // Octagonal Locked-Forearms Championship Shield silhouette
        final Path outerOctagon = _buildOctagonPath(
          const Offset(24.0, 24.0),
          21.0,
        );
        final Path innerOctagon = _buildOctagonPath(
          const Offset(24.0, 24.0),
          16.0,
        );
        canvas.drawPath(outerOctagon, fillPaint);
        canvas.drawPath(outerOctagon, strokePaint..strokeWidth = 1.8);
        canvas.drawPath(innerOctagon, strokePaint..strokeWidth = 1.1);
        // Locked-forearms V-grip chevron inside octagon
        final Path lockedGrip = Path()
          ..moveTo(14.0, 31.0)
          ..lineTo(24.0, 16.0)
          ..lineTo(34.0, 31.0)
          ..moveTo(19.0, 23.0)
          ..lineTo(29.0, 23.0);
        canvas.drawPath(lockedGrip, strokePaint..strokeWidth = 2.2);
        break;

      case ForgedWatermarkType.none:
      case ForgedWatermarkType.caliperTicks:
        break;
    }

    canvas.restore();
  }

  /// Subtle precision caliper graduation ticks along the bottom edge of Biometrics cards/cells.
  void _paintCaliperGraduationTicks(Canvas canvas, Size size) {
    final Paint tickPaint = Paint()
      ..color = watermarkColor
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final double startX = 16.0;
    final double endX = size.width - 16.0;
    final double baseY = size.height - 2.5;
    if (endX <= startX) return;

    // Baseline ruler bar
    canvas.drawLine(
      Offset(startX, baseY),
      Offset(endX, baseY),
      tickPaint,
    );

    int step = 0;
    for (double x = startX; x <= endX; x += 6.0) {
      final bool isMajor = step % 5 == 0;
      final bool isMedium = step % 5 == 2;
      final double tickHeight = isMajor ? 7.5 : (isMedium ? 5.0 : 3.2);
      canvas.drawLine(
        Offset(x, baseY),
        Offset(x, baseY - tickHeight),
        tickPaint,
      );
      step++;
    }
  }

  Path _buildOctagonPath(Offset center, double radius) {
    final Path path = Path();
    for (int i = 0; i < 8; i++) {
      final double angle = (math.pi / 8.0) + (i * math.pi / 4.0);
      final double x = center.dx + radius * math.cos(angle);
      final double y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CrystalSlashPainter oldDelegate) {
    return oldDelegate.variant != variant ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.paintOpticalLens != paintOpticalLens;
  }
}

/// Scroll-linked Stage Spotlight Dimmer controller & contrast veil.
///
/// Tracks the vertical scroll offset per screen [ScaffoldState]:
/// - When `scrollOffset <= 10px` (at rest at the top of the screen), renders the
///   `9:16` stage image at 100% full native brightness (`Colors.transparent`).
/// - As `scrollOffset` increases from `10px` to `70px`, smoothly interpolates an
///   obsidian contrast veil (`Color.lerp(Colors.transparent, const Color(0x7304060B), t)`)
///   over the `9:16` stage backdrop so scrolled crystal cards and white/gold
///   typography remain effortless to read over top spotlights.
class StageScrollDimmerController {
  static final Expando<ValueNotifier<double>> _scaffoldNotifiers =
      Expando<ValueNotifier<double>>('stageScrollDimmer');
  static final ValueNotifier<double> _fallbackNotifier =
      ValueNotifier<double>(0.0);

  static ValueNotifier<double> notifierFor(BuildContext context) {
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold != null) {
      return _scaffoldNotifiers[scaffold] ??= ValueNotifier<double>(0.0);
    }
    return _fallbackNotifier;
  }

  static void updateFromScroll(BuildContext context, double scrollOffset) {
    final double clamped = math.max(0.0, scrollOffset);
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold != null) {
      final notifier =
          _scaffoldNotifiers[scaffold] ??= ValueNotifier<double>(0.0);
      if ((notifier.value - clamped).abs() > 0.2) {
        notifier.value = clamped;
      }
    }
    if ((_fallbackNotifier.value - clamped).abs() > 0.2) {
      _fallbackNotifier.value = clamped;
    }
  }

  static void resetForScaffold(ScaffoldState scaffold) {
    final notifier = _scaffoldNotifiers[scaffold];
    if (notifier != null && notifier.value != 0.0) {
      notifier.value = 0.0;
    }
    if (_fallbackNotifier.value != 0.0) {
      _fallbackNotifier.value = 0.0;
    }
  }

  static double contrastFactorForOffset(double scrollOffset) {
    if (scrollOffset <= 10.0) return 0.0;
    return ((scrollOffset - 10.0) / 60.0).clamp(0.0, 1.0);
  }

  static Color contrastColorForOffset(double scrollOffset) {
    final double t = contrastFactorForOffset(scrollOffset);
    if (t <= 0.0) return Colors.transparent;
    return Color.lerp(
      Colors.transparent,
      const Color(0x7304060B),
      t,
    )!;
  }
}

/// Renders the interpolated obsidian contrast veil (`0x00000000` -> `0x7304060B`
/// between `10px` and `70px` scroll offset) over the `9:16` stage backdrop.
class StageScrollContrastVeil extends StatelessWidget {
  const StageScrollContrastVeil({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = StageScrollDimmerController.notifierFor(context);
    return ValueListenableBuilder<double>(
      valueListenable: notifier,
      builder: (context, scrollOffset, _) {
        final Color veilColor =
            StageScrollDimmerController.contrastColorForOffset(scrollOffset);
        return ColoredBox(
          key: const ValueKey<String>('stage_scroll_contrast_veil'),
          color: veilColor,
        );
      },
    );
  }
}

/// 3D Vapor Dissolve scroll edge wrapper.
///
/// Uses matched Top & Bottom smooth 3D Vapor-Dissolve stops:
/// - `stops: const [0.0, 0.032, 0.955, 1.0]`
/// - `colors: const [Color(0x00FFFFFF), Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0x00FFFFFF)]`
/// Keeping 92.3% (`0.032` to `0.955`) of the scroll viewport at 100% full brightness (`0xFFFFFFFF`),
/// and calibrating the bottom boundary to sit `18px` above the top border of the
/// floating Bottom Navigation Pill.
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
    final Widget scrollAwareChild = NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification.metrics.axis == Axis.vertical) {
          StageScrollDimmerController.updateFromScroll(
            notification.context ?? context,
            notification.metrics.pixels,
          );
        }
        return false;
      },
      child: child,
    );

    if (!enabled) return scrollAwareChild;

    Widget masked = ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (Rect bounds) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: <double>[0.0, 0.032, 0.955, 1.0],
          colors: <Color>[
            Color(0x00FFFFFF),
            Color(0xFFFFFFFF),
            Color(0xFFFFFFFF),
            Color(0x00FFFFFF),
          ],
        ).createShader(bounds);
      },
      child: scrollAwareChild,
    );

    if (bottomMargin > 0) {
      // If MainShellScreen's Scaffold(extendBody: true) already injected the 76px
      // floating dock height into MediaQuery.paddingOf(context).bottom (>= 76.0),
      // only add the 18px gap above the dock top border. Otherwise add 64 + 12 + 18 + mediaBottom.
      final double mediaBottom = MediaQuery.paddingOf(context).bottom;
      final double calibratedBottomGap = mediaBottom >= 76.0
          ? (mediaBottom + 18.0)
          : (64.0 + 12.0 + 18.0 + mediaBottom);
      masked = Padding(
        padding: EdgeInsets.only(bottom: calibratedBottomGap),
        child: masked,
      );
    }

    return masked;
  }
}
