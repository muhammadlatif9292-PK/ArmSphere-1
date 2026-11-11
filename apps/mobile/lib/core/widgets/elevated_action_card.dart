import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'crystal_slash_painter.dart';
import 'tactile_press_wrapper.dart';

/// Crystal-Transparent Wireframe Action Card with Diagonal Crimson/Titanium Slashes
///
/// Renders a 100% transparent interior (`Colors.transparent`) with crisp boundary
/// lines and diagonal crimson/obsidian-titanium stripes (`CrystalSlashWrapper`)
/// clipped to [borderRadius].
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
  final CrystalSlashVariant? slashVariant;
  final bool enableSlashes;

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
    this.slashVariant,
    this.enableSlashes = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = (borderColor != null &&
            borderColor != Colors.transparent)
        ? borderColor!
        : const Color(0x38FFFFFF);

    final radius = BorderRadius.circular(borderRadius);
    final effectiveVariant =
        slashVariant ?? const CrystalSlashVariant.crossedCard();

    Widget innerContent = Padding(
      padding: padding,
      child: DefaultTextStyle.merge(
        style: const TextStyle(
          shadows: AppTheme.crystalTextShadows,
        ),
        child: child,
      ),
    );

    if (enableSlashes) {
      innerContent = CrystalSlashWrapper(
        variant: effectiveVariant,
        borderRadius: radius,
        child: innerContent,
      );
    }

    Widget cardContent = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: radius,
        border: Border.all(
          color: effectiveBorderColor,
          width: 1.0,
        ),
        boxShadow: const [],
      ),
      child: innerContent,
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
