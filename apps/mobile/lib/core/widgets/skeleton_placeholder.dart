import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Standardized Shimmer Skeleton Loader
///
/// Upgraded to Canonical Stage 2 Specification (Slice 9 / [P1-04] / Debt 77):
/// - Base color: #121826 (AppTheme.cardSurface).
/// - Highlight color: #1E293B (AppTheme.elevatedSurface).
/// - Linear gradient locked at 15-degree sweep angle.
/// - Preset constructors for cards, text lines, avatars, and list tiles.
class SkeletonPlaceholder extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final String? semanticLabel;
  final BoxShape shape;

  const SkeletonPlaceholder({
    super.key,
    this.width,
    this.height,
    this.borderRadius = AppTheme.radiusSmall,
    this.semanticLabel,
    this.shape = BoxShape.rectangle,
  });

  const SkeletonPlaceholder.avatar({
    super.key,
    double size = 48.0,
    this.semanticLabel = 'Loading profile avatar',
  })  : width = size,
        height = size,
        borderRadius = 0,
        shape = BoxShape.circle;

  const SkeletonPlaceholder.textLine({
    super.key,
    this.width = 120.0,
    this.height = 14.0,
    this.borderRadius = 4.0,
    this.semanticLabel = 'Loading text',
  }) : shape = BoxShape.rectangle;

  const SkeletonPlaceholder.card({
    super.key,
    this.width = double.infinity,
    this.height = 100.0,
    this.borderRadius = AppTheme.radiusSmall,
    this.semanticLabel = 'Loading card content',
  }) : shape = BoxShape.rectangle;

  @override
  State<SkeletonPlaceholder> createState() => _SkeletonPlaceholderState();
}

class _SkeletonPlaceholderState extends State<SkeletonPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _gradientAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _gradientAnimation = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel ?? 'Loading content placeholder',
      child: AnimatedBuilder(
        animation: _gradientAnimation,
        builder: (context, child) {
          final progress = ((_gradientAnimation.value + 1.5) / 3.0).clamp(0.0, 1.0);

          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              shape: widget.shape,
              borderRadius: widget.shape == BoxShape.circle
                  ? null
                  : BorderRadius.circular(widget.borderRadius),
              // 15-degree sweep angle: Alignment(-1.0, -0.27) to Alignment(1.0, 0.27)
              gradient: LinearGradient(
                begin: const Alignment(-1.0, -0.27),
                end: const Alignment(1.0, 0.27),
                colors: const [
                  AppTheme.cardSurface,      // #121826 Base
                  AppTheme.elevatedSurface,  // #1E293B Highlight
                  AppTheme.cardSurface,      // #121826 Base
                ],
                stops: [
                  (progress - 0.3).clamp(0.0, 1.0),
                  progress,
                  (progress + 0.3).clamp(0.0, 1.0),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
