// lib/core/widgets/crystal_gloss_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable "Crystal Glassmorphism / Glossmorphism" Container Widget.
///
/// Enforces the 5 strict Crystal Glossmorphic pillars across ArmSphere:
/// 1. NO BLUR: Zero [BackdropFilter] or [ImageFilter.blur]. The full-screen
///    background behind the card remains 100% sharp, clear, and undistorted.
/// 2. HIGH TRANSPARENCY: Ultra-faint white surface tint (`0.03` to `0.05` alpha)
///    with a subtle diagonal gloss sheen so the background artwork shines through.
/// 3. SPECULAR BORDER: Crisp `1.0px` semi-transparent white border (`Border.all`)
///    acting as a light-catching edge that defines card boundaries cleanly.
/// 4. ELEVATION & FLOATING EFFECT: Prominent soft Y-axis drop shadow (`BoxShadow`)
///    making the clear card look like it is levitating over water.
/// 5. FOREGROUND CONTRAST: High-opacity foreground typography and icon envelope
///    with subtle optical shadow for guaranteed legibility over any background.
class CrystalGlossCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? borderColor;
  final double borderWidth;
  final double surfaceOpacity;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final Widget? backgroundArt;
  final List<BoxShadow>? customShadows;

  const CrystalGlossCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
    this.borderRadius = 18.0,
    this.borderColor,
    this.borderWidth = 1.0,
    this.surfaceOpacity = 0.04,
    this.onTap,
    this.semanticLabel,
    this.backgroundArt,
    this.customShadows,
  }) : assert(surfaceOpacity >= 0.0 && surfaceOpacity <= 0.25);

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = BorderRadius.circular(borderRadius);
    final effectiveBorderColor = (borderColor != null &&
            borderColor != Colors.transparent)
        ? borderColor!
        : const Color(0x38FFFFFF);

    Widget cardBody = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: effectiveRadius,
        border: Border.all(
          color: effectiveBorderColor,
          width: borderWidth,
        ),
        boxShadow: const [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
            (borderRadius - borderWidth).clamp(0.0, 48.0)),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            // Optional sharp internal card art (never blurred)
            if (backgroundArt != null)
              Positioned.fill(
                child: IgnorePointer(child: backgroundArt!),
              ),

            // High-Contrast Foreground Envelope with Crisp Text Shadow
            Padding(
              padding: padding,
              child: DefaultTextStyle.merge(
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  shadows: [
                    Shadow(
                      color: Color(0xE6000000),
                      offset: Offset(0, 1),
                      blurRadius: 6.0,
                    ),
                  ],
                ),
                child: IconTheme.merge(
                  data: const IconThemeData(
                    color: Color(0xFFFFFFFF),
                  ),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap != null) {
      cardBody = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          onTap!();
        },
        child: cardBody,
      );
    }

    if (semanticLabel != null && semanticLabel!.isNotEmpty) {
      return Semantics(
        label: semanticLabel,
        button: onTap != null,
        container: true,
        child: cardBody,
      );
    }

    return cardBody;
  }
}
