import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/theme/app_theme.dart';

/// Compact HUD Mini-Map Viewport Radar for Tournament Brackets
///
/// Complies with Canary 8 (Tournament Bracket) specification:
/// - 88dp x 64dp bottom-right floating radar.
/// - Shows full bracket topology with micro-nodes.
/// - Synchronizes interactive viewport bounding box with InteractiveViewer.
/// - Allows tap-to-center and drag navigation across dense bracket trees.
/// - 100% vector / code-rendered without external assets.
class BracketMinimapHud extends StatelessWidget {
  final TransformationController controller;
  final Size canvasSize;
  final List<Offset> matchOffsets;
  final Size cardSize;
  final Size viewportSize;

  const BracketMinimapHud({
    super.key,
    required this.controller,
    required this.canvasSize,
    required this.matchOffsets,
    this.cardSize = const Size(200.0, 94.0),
    required this.viewportSize,
  });

  static const double minimapWidth = 92.0;
  static const double minimapHeight = 64.0;
  static const double pad = 4.0;

  @override
  Widget build(BuildContext context) {
    if (canvasSize.width <= 0 || canvasSize.height <= 0) {
      return const SizedBox.shrink();
    }

    final availW = minimapWidth - (pad * 2);
    final availH = minimapHeight - (pad * 2);
    final miniScale = math.min(availW / canvasSize.width, availH / canvasSize.height);

    return Semantics(
      label: 'Tournament bracket mini-map radar indicator. Tap to jump viewport.',
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) => _handleInteraction(details.localPosition, miniScale),
        onPanUpdate: (details) => _handleInteraction(details.localPosition, miniScale),
        child: Container(
          width: minimapWidth,
          height: minimapHeight,
          decoration: BoxDecoration(
            color: AppTheme.cardSurface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(
              color: AppTheme.borderSubtle,
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                return CustomPaint(
                  size: const Size(minimapWidth, minimapHeight),
                  painter: _BracketMinimapPainter(
                    controller: controller,
                    canvasSize: canvasSize,
                    matchOffsets: matchOffsets,
                    cardSize: cardSize,
                    viewportSize: viewportSize,
                    miniScale: miniScale,
                    pad: pad,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _handleInteraction(Offset localOffset, double miniScale) {
    if (miniScale <= 0) return;

    final clickCanvasX = (localOffset.dx - pad) / miniScale;
    final clickCanvasY = (localOffset.dy - pad) / miniScale;

    final matrix = controller.value;
    final currentScale = matrix.getMaxScaleOnAxis().clamp(0.5, 2.5);

    final newTx = -(clickCanvasX * currentScale - (viewportSize.width / 2));
    final newTy = -(clickCanvasY * currentScale - (viewportSize.height / 2));

    HapticFeedback.selectionClick();
    controller.value = Matrix4.identity()
      ..translate(newTx, newTy)
      ..scale(currentScale);
  }
}

class _BracketMinimapPainter extends CustomPainter {
  final TransformationController controller;
  final Size canvasSize;
  final List<Offset> matchOffsets;
  final Size cardSize;
  final Size viewportSize;
  final double miniScale;
  final double pad;

  _BracketMinimapPainter({
    required this.controller,
    required this.canvasSize,
    required this.matchOffsets,
    required this.cardSize,
    required this.viewportSize,
    required this.miniScale,
    required this.pad,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Match Nodes as Micro-Rectangles
    final nodePaint = Paint()
      ..color = AppTheme.borderSubtle.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final nodeW = math.max(2.0, cardSize.width * miniScale);
    final nodeH = math.max(1.5, cardSize.height * miniScale);

    for (final pos in matchOffsets) {
      final rect = Rect.fromLTWH(
        pad + (pos.dx * miniScale),
        pad + (pos.dy * miniScale),
        nodeW,
        nodeH,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(1)), nodePaint);
    }

    // 2. Viewport Radar Box
    final matrix = controller.value;
    final scale = matrix.getMaxScaleOnAxis();
    if (scale <= 0) return;

    final tx = -matrix.getTranslation().x;
    final ty = -matrix.getTranslation().y;

    final vx = tx / scale;
    final vy = ty / scale;
    final vw = viewportSize.width / scale;
    final vh = viewportSize.height / scale;

    final vpLeft = pad + (vx * miniScale);
    final vpTop = pad + (vy * miniScale);
    final vpWidth = vw * miniScale;
    final vpHeight = vh * miniScale;

    final vpRect = Rect.fromLTWH(vpLeft, vpTop, vpWidth, vpHeight);

    // Viewport fill (subtle gold sheen)
    final radarFill = Paint()
      ..color = AppTheme.goldPrimary.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(vpRect, const Radius.circular(2)), radarFill);

    // Viewport border (1px gold radar frame)
    final radarBorder = Paint()
      ..color = AppTheme.goldPrimary
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(RRect.fromRectAndRadius(vpRect, const Radius.circular(2)), radarBorder);
  }

  @override
  bool shouldRepaint(covariant _BracketMinimapPainter oldDelegate) {
    return oldDelegate.canvasSize != canvasSize ||
        oldDelegate.matchOffsets != matchOffsets ||
        oldDelegate.viewportSize != viewportSize;
  }
}
