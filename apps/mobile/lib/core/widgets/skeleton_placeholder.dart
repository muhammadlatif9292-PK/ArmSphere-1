import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'pulse_indicator.dart';

/// Minimal Floating Gold Pulse Loading Indicator
///
/// Replaces solid dark-grey rectangular skeleton boxes so the 9:16 stage
/// artwork remains completely unobstructed while data loads.
class SkeletonPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final String? semanticLabel;
  final BoxShape shape;

  const SkeletonPlaceholder({
    super.key,
    this.width,
    this.height,
    this.borderRadius = AppTheme.radiusSmall,
    this.semanticLabel,
    this.shape = BoxShape.rectangle,
  });

  const SkeletonPlaceholder.avatar({
    super.key,
    double size = 48.0,
    this.semanticLabel = 'Loading profile avatar',
  })  : width = size,
        height = size,
        borderRadius = 0,
        shape = BoxShape.circle;

  const SkeletonPlaceholder.textLine({
    super.key,
    this.width = 120.0,
    this.height = 14.0,
    this.borderRadius = 4.0,
    this.semanticLabel = 'Loading text',
  }) : shape = BoxShape.rectangle;

  const SkeletonPlaceholder.card({
    super.key,
    this.width = double.infinity,
    this.height = 100.0,
    this.borderRadius = AppTheme.radiusSmall,
    this.semanticLabel = 'Loading card content',
  }) : shape = BoxShape.rectangle;

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = height ?? 36.0;
    // For tiny text-line placeholders, render nothing so only primary loaders pulse cleanly
    if (effectiveHeight < 28.0) {
      return const SizedBox.shrink();
    }

    return Semantics(
      label: semanticLabel ?? 'Loading content',
      child: SizedBox(
        width: width,
        height: effectiveHeight.clamp(36.0, 72.0),
        child: const Center(
          child: PulseIndicator(
            color: AppTheme.goldPrimary,
            size: 10.0,
          ),
        ),
      ),
    );
  }
}


/// Compatibility Loading View using the minimal floating gold pulse
class CrystalScreenLoadingView extends StatelessWidget {
  final String? message;
  final int itemCount;
  final double cardHeight;
  final String? semanticLabel;

  const CrystalScreenLoadingView({
    super.key,
    this.message,
    this.itemCount = 3,
    this.cardHeight = 100.0,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PulseIndicator(color: AppTheme.goldPrimary, size: 16.0),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(
              message!,
              style: const TextStyle(
                fontFamily: AppTheme.fontBody,
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
