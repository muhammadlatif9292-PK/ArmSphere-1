// lib/core/widgets/elevated_action_card.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'tactile_press_wrapper.dart';

/// High-Performance Crystal Glassmorphic / Glossmorphic Action Card
///
/// Upgraded to enforce the 5 Crystal Glassmorphism pillars across all lists,
/// dashboards, and detail screens in ArmSphere:
/// 1. NO BLUR: Zero BackdropFilter or ImageFilter.blur — background stays 100% sharp.
/// 2. HIGH TRANSPARENCY: Faint white surface tint (0.04 alpha) + subtle gloss gradient.
/// 3. SPECULAR BORDER: Crisp 1.0px semi-transparent white light-catching border.
/// 4. ELEVATION & FLOATING EFFECT: Y-axis offset BoxShadow for levitating depth.
/// 5. FOREGROUND CONTRAST: High-contrast text shadow envelope for guaranteed legibility.
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
    // Pillar 3: Crisp semi-transparent white specular border
    final effectiveBorderColor =
        borderColor ?? Colors.white.withValues(alpha: 0.22);

    // Pillar 2: High-transparency faint white surface plane (0.04 alpha)
    final bool useCrystalDefault =
        backgroundColor == null ||
        backgroundColor == AppTheme.cardSurface ||
        backgroundColor == AppTheme.elevatedSurface ||
        backgroundColor == AppTheme.background ||
        backgroundColor == AppTheme.voidBackground;

    final Color effectiveBgColor = useCrystalDefault
        ? Colors.white.withValues(alpha: 0.04)
        : backgroundColor!;

    final Gradient effectiveGradient = gradient ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.06),
            Colors.white.withValues(alpha: 0.04),
            Colors.white.withValues(alpha: 0.02),
          ],
          stops: const [0.0, 0.45, 1.0],
        );

    // Pillar 4: Levitating Y-Axis Floating Shadow
    final List<BoxShadow> effectiveShadows = customShadow ??
        boxShadow ??
        [
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
        ];

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
        boxShadow: effectiveShadows,
      ),
      child: Material(
        type: MaterialType.transparency,
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
          child: child,
        ),
      ),
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
