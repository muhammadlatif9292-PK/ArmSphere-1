import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'tactile_press_wrapper.dart';

/// High-Performance Athletic Action Card
///
/// Solid substrate container designed for high-density vertical lists (Rankings,
/// Tournaments, Match Queues, Training Logs) where `GlassCard`'s GPU `BackdropFilter`
/// would cause fill-rate bottlenecking or frame drops.
///
/// Grounded in `docs/design/09_COMPONENT_SYSTEM.md` and `docs/design/39_DESIGN_DEBT_MAP.md`.
class ElevatedActionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? borderColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final List<BoxShadow>? customShadow;
  final List<BoxShadow>? boxShadow;

  final Gradient? gradient;
  final bool enableMachinedFinish;

  const ElevatedActionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.space16),
    this.margin,
    this.borderRadius = AppTheme.radiusMedium,
    this.borderColor,
    this.backgroundColor,
    this.gradient,
    this.enableMachinedFinish = true,
    this.onTap,
    this.semanticLabel,
    this.customShadow,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = borderColor ?? AppTheme.borderTitanium;
    final effectiveBgColor = backgroundColor ?? (gradient != null ? null : (enableMachinedFinish ? null : AppTheme.cardSurface));
    final effectiveGradient = gradient ?? (backgroundColor == null && enableMachinedFinish ? AppTheme.machinedTitaniumGradient : null);

    Widget cardContent = Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: effectiveBgColor,
        gradient: effectiveGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: effectiveBorderColor,
          width: 1.0,
        ),
        boxShadow: customShadow ?? boxShadow ?? [AppTheme.titaniumShadow()],
      ),
      child: child,
    );

    if (onTap != null) {
      cardContent = TactilePressWrapper(
        onTap: onTap,
        semanticLabel: semanticLabel,
        child: cardContent,
      );
    }

    return cardContent;
  }
}
