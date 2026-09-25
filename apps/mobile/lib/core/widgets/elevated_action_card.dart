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

  const ElevatedActionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.space16),
    this.margin,
    this.borderRadius = AppTheme.radiusMedium,
    this.borderColor,
    this.backgroundColor,
    this.onTap,
    this.semanticLabel,
    this.customShadow,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = borderColor ?? AppTheme.border;
    final effectiveBgColor = backgroundColor ?? AppTheme.cardSurface;

    Widget cardContent = Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: effectiveBgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: effectiveBorderColor,
          width: 1.0,
        ),
        boxShadow: customShadow ?? [AppTheme.cardShadow()],
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
