import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'tactile_press_wrapper.dart';

/// Invisible Interactive Floating Container
///
/// Renders zero visible background slab, border, or shadow so text, icons,
/// avatars, and badges float directly over the 9:16 stage artwork while
/// preserving full container bounds and tactile hit-target responsiveness.
class ElevatedActionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? borderColor;
  final Color? backgroundColor;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final List<BoxShadow>? customShadow;
  final List<BoxShadow>? boxShadow;

  const ElevatedActionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.space16),
    this.margin,
    this.borderRadius = 18.0,
    this.borderColor,
    this.backgroundColor,
    this.gradient,
    this.onTap,
    this.semanticLabel,
    this.customShadow,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = (borderColor != null &&
            borderColor != Colors.transparent)
        ? borderColor!
        : const Color(0x38FFFFFF);

    Widget cardContent = Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: effectiveBorderColor,
          width: 1.0,
        ),
        boxShadow: const [],
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(
          shadows: AppTheme.crystalTextShadows,
        ),
        child: child,
      ),
    );

    if (onTap != null) {
      cardContent = TactilePressWrapper(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap!();
        },
        semanticLabel: semanticLabel,
        child: cardContent,
      );
    }

    return cardContent;
  }
}
