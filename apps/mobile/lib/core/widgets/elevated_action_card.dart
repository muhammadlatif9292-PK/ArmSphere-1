import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'crystal_slash_painter.dart';
import 'tactile_press_wrapper.dart';

/// Forged Arm-Wrestling Crystal Action Card (`ElevatedActionCard`)
///
/// Layer 1: Whisper-Dark Optical Crystal Lens (`Color(0x4704060B)` 28% pure obsidian, zero crossing lines).
/// Layer 2: Forged Regulation Table Hardware Edge Accents (L-shaped steel corner brackets on
///          rectangular cards, or 3.5px forged corner-pad bar on horizontal rows).
/// Layer 3: Optional 4.5% opacity monochrome Arm-Wrestling Instrument Watermark in bottom-right corner.
class ElevatedActionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? borderColor;
  final Color? backgroundColor;
  final Color? accentColor;
  final ForgedWatermarkType watermark;
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
    this.accentColor,
    this.watermark = ForgedWatermarkType.none,
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
    final effectiveBorderColor =
        (borderColor != null && borderColor != Colors.transparent)
            ? borderColor!
            : const Color(0x38FFFFFF);

    final effectiveAccentColor = accentColor ??
        ((borderColor != null &&
                borderColor != Colors.transparent &&
                borderColor != const Color(0x38FFFFFF))
            ? borderColor
            : null);

    final baseVariant = slashVariant ??
        CrystalSlashVariant.crossedCard(
          accentColor: effectiveAccentColor,
          watermark: watermark,
        );

    final effectiveVariant = baseVariant.copyWith(
      accentColor: effectiveAccentColor ?? baseVariant.accentColor,
      watermark: watermark != ForgedWatermarkType.none
          ? watermark
          : baseVariant.watermark,
    );

    final double effectiveRadiusValue =
        effectiveVariant.mode == CrystalSlashMode.sequentialRow &&
                borderRadius == 18.0
            ? 16.0
            : borderRadius;
    final radius = BorderRadius.circular(effectiveRadiusValue);

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
        paintOpticalLens: false,
        child: innerContent,
      );
    }

    Widget cardContent = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: const Color(0x4704060B),
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
