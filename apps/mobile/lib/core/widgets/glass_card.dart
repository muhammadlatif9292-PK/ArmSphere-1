import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Ultra-Premium Glassmorphic Container designed for Concept 2 (Glass Morphism Luxury)
/// Combines backdrop blur, 1px subtle gold/frost rim borders, deep radial gradient backgrounds,
/// and smooth micro-scale tactile press animation curves.
class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? borderColor;
  final Color? backgroundColor;
  final double blurAmount;
  final VoidCallback? onTap;
  final bool enableGlow;
  final Color? glowColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
    this.borderRadius = 16.0,
    this.borderColor,
    this.backgroundColor,
    this.blurAmount = 12.0,
    this.onTap,
    this.enableGlow = false,
    this.glowColor,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.975).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      HapticFeedback.selectionClick();
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _controller.reverse();
      widget.onTap!();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = widget.borderColor ?? AppTheme.glassBorder;
    final effectiveBgColor = widget.backgroundColor ?? AppTheme.glassSurface;
    final effectiveGlowColor = widget.glowColor ?? AppTheme.cyanGlow;

    Widget content = Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: widget.enableGlow
            ? [
                BoxShadow(
                  color: effectiveGlowColor,
                  blurRadius: 18.0,
                  spreadRadius: 0.0,
                ),
                AppTheme.cardShadow(),
              ]
            : [AppTheme.cardShadow()],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: widget.blurAmount,
            sigmaY: widget.blurAmount,
          ),
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              color: effectiveBgColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: effectiveBorderColor,
                width: 1.0,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0x28FFFFFF), // 16% specular light catch at top-left rim
                  effectiveBgColor,
                  const Color(0x0A000000), // Grounded separation at bottom-right
                ],
                stops: const [0.0, 0.38, 1.0],
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
          child: content,
        ),
      );
    }

    return content;
  }
}
