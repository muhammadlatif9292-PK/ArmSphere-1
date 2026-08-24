import 'package:flutter/material.dart';

class TactilePressWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;

  /// Whether to lift the child upward while pressed.
  final bool enableLift;

  /// Vertical offset applied while lifted when [enableLift] is true.
  final double liftDistance;

  const TactilePressWrapper({
    Key? key,
    required this.child,
    required this.onTap,
    this.semanticLabel,
    this.enableLift = false,
    this.liftDistance = -4.0,
  }) : super(key: key);

  @override
  State<TactilePressWrapper> createState() => _TactilePressWrapperState();
}

class _TactilePressWrapperState extends State<TactilePressWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _liftAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _liftAnimation = Tween<double>(
      begin: 0.0,
      end: widget.enableLift ? widget.liftDistance : 0.0,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _controller.reverse();
      widget.onTap!();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final detector = GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _liftAnimation.value),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );

    if (widget.semanticLabel != null) {
      return Semantics(
        button: true,
        label: widget.semanticLabel,
        enabled: widget.onTap != null,
        child: detector,
      );
    }

    return detector;
  }
}
