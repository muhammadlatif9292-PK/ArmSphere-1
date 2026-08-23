import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SkeletonPlaceholder extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final String? semanticLabel;
  final BoxShape shape;

  const SkeletonPlaceholder({
    Key? key,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.semanticLabel,
    this.shape = BoxShape.rectangle,
  }) : super(key: key);

  @override
  State<SkeletonPlaceholder> createState() => _SkeletonPlaceholderState();
}

class _SkeletonPlaceholderState extends State<SkeletonPlaceholder> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _gradientAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
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
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              shape: widget.shape,
              borderRadius: widget.shape == BoxShape.circle 
                  ? null 
                  : BorderRadius.circular(widget.borderRadius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: const [
                  AppTheme.surface, // Steel slate base
                  AppTheme.border, // Shimmer highlight
                  AppTheme.surface, // Steel slate base
                ],
                stops: [
                  0.0,
                  ((_gradientAnimation.value + 1.5) / 3.0).clamp(0.0, 1.0),
                  1.0,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
