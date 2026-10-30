// lib/core/widgets/glass_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Crystal Glassmorphic / Glossmorphic Container
///
/// Enforces the 5 strict Crystal Glassmorphism pillars:
/// 1. NO BLUR: Zero BackdropFilter or ImageFilter.blur — background stays 100% sharp.
/// 2. HIGH TRANSPARENCY: Faint white surface tint (0.04 alpha) + subtle gloss sheen.
/// 3. SPECULAR BORDER: Crisp 1.0px semi-transparent white light-catching border.
/// 4. ELEVATION & FLOATING EFFECT: Soft Y-axis drop shadow for levitating depth.
/// 5. FOREGROUND CONTRAST: High-contrast foreground text shadow envelope.
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
    this.blurAmount = 0.0,
    this.onTap,
    this.enableGlow = false,
    this.glowColor,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard>
    with SingleTickerProviderStateMixin {
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
    final effectiveBorderColor =
        widget.borderColor ?? Colors.white.withValues(alpha: 0.22);
    final effectiveGlowColor = widget.glowColor ?? AppTheme.cyanGlow;

    Widget content = Container(
      margin: widget.margin,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: effectiveBorderColor,
          width: 1.0,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.06),
            Colors.white.withValues(alpha: 0.04),
            Colors.white.withValues(alpha: 0.02),
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
        boxShadow: [
          if (widget.enableGlow)
            BoxShadow(
              color: effectiveGlowColor,
              blurRadius: 18.0,
              spreadRadius: 0.0,
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.44),
            offset: const Offset(0, 10),
            blurRadius: 24,
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            offset: const Offset(0, 4),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(
          shadows: [
            Shadow(
              color: Color(0xB3000000),
              offset: Offset(0, 1.2),
              blurRadius: 3.5,
            ),
          ],
        ),
        child: widget.child,
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
