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
    this.borderRadius = 16.0,
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
    final effectiveBorderColor =
        borderColor ?? Colors.white.withValues(alpha: 0.22);

    Widget cardBody = Container(
      margin: margin,
      decoration: BoxDecoration(
        // Pillar 2: High Transparency (0.03 - 0.05 faint white tint + subtle gloss)
        color: Colors.white.withValues(alpha: surfaceOpacity),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white
                .withValues(alpha: (surfaceOpacity + 0.02).clamp(0.0, 0.14)),
            Colors.white.withValues(alpha: surfaceOpacity),
            Colors.white
                .withValues(alpha: (surfaceOpacity * 0.5).clamp(0.0, 0.08)),
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
        borderRadius: effectiveRadius,
        // Pillar 3: Specular Light-Catching Border
        border: Border.all(
          color: effectiveBorderColor,
          width: borderWidth,
        ),
        // Pillar 4: Levitating Y-Axis Drop Shadow
        boxShadow: customShadows ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                offset: const Offset(0, 10),
                blurRadius: 24,
                spreadRadius: -2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                offset: const Offset(0, 4),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
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

            // Top specular rim highlight (1px light-catching crest)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 1,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.06),
                        Colors.white.withValues(alpha: 0.40),
                        Colors.white.withValues(alpha: 0.06),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Pillar 5: High-Contrast Foreground Envelope
            Padding(
              padding: padding,
              child: DefaultTextStyle.merge(
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  shadows: [
                    Shadow(
                      color: Color(0xBD000000),
                      offset: Offset(0, 1.5),
                      blurRadius: 4.0,
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
