import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../constants/asset_paths.dart';
import '../theme/app_theme.dart';

/// Centralized ArmSphere Image Component implementing the 3-Level Fallback Ladder.
///
/// Designed strictly around:
/// - `docs/design/46_MASTER_MEDIA_ASSET_MAP.md`
/// - `docs/design/50_MEDIA_INTEGRATION_SPEC.md`
/// - `docs/design/70_FINAL_VISUAL_MEDIA_DECISION_MAP.md`
///
/// **Fallback Philosophy**:
/// - **LEVEL 1**: Target remote URL (via [CachedNetworkImage] with memory bounds)
///   or target bundled local asset (via [Image.asset]).
/// - **LEVEL 2**: Bundled category fallback asset ([fallbackAsset], e.g. default poster or avatar).
/// - **LEVEL 3**: Safe GPU procedural gradient ([AppTheme.voidBackground] -> [AppTheme.cardSurface])
///   plus high-contrast vector glyph or monogram. 100% offline-safe, zero asset dependency, 0ms latency.
///
/// **Guarantees**:
/// - Zero white flashes or broken-image icons.
/// - Bounded memory decoding via [cacheWidth] and [cacheHeight].
/// - Semantic accessibility integration.
/// - Fully offline-safe rendering.
class ArmSphereImage extends StatelessWidget {
  /// Remote network image URL (Level 1 remote).
  final String? imageUrl;

  /// Bundled local asset path (Level 1 local).
  final String? assetPath;

  /// Target display width in logical pixels.
  final double? width;

  /// Target display height in logical pixels.
  final double? height;

  /// Content fit strategy. Defaults to [BoxFit.cover].
  final BoxFit fit;

  /// Level 2 fallback asset path if Level 1 fails or is omitted.
  final String? fallbackAsset;

  /// Level 3 fallback vector icon if Level 2 fails or is omitted.
  final IconData fallbackIcon;

  /// Optional initial character for Level 3 avatar monogram rendering.
  final String? initial;

  /// Explicit decode cache width cap. If null, automatically calculated from [width].
  final int? cacheWidth;

  /// Explicit decode cache height cap. If null, automatically calculated from [height].
  final int? cacheHeight;

  /// Optional border radius for rounded rectangle clipping.
  final BorderRadius? borderRadius;

  /// Display shape: rectangle or circle. Defaults to [BoxShape.rectangle].
  final BoxShape shape;

  /// Optional outer decorative border.
  final Border? border;

  /// Accessibility semantic label.
  final String? semanticLabel;

  /// Whether to exclude this widget from the accessibility tree.
  final bool excludeFromSemantics;

  /// Whether to show a compact gold loading indicator during network fetching.
  final bool showLoadingIndicator;

  const ArmSphereImage({
    super.key,
    this.imageUrl,
    this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallbackAsset = ArmSphereAssets.defaultTournament,
    this.fallbackIcon = Icons.fitness_center_rounded,
    this.initial,
    this.cacheWidth,
    this.cacheHeight,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.border,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.showLoadingIndicator = true,
  });

  /// Convenience constructor for circular avatars (athletes, referees, officials).
  const ArmSphereImage.avatar({
    super.key,
    this.imageUrl,
    this.assetPath,
    double size = 40.0,
    this.fit = BoxFit.cover,
    this.fallbackAsset = ArmSphereAssets.defaultAvatar,
    this.fallbackIcon = Icons.person_rounded,
    this.initial,
    this.cacheWidth,
    this.cacheHeight,
    this.border,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.showLoadingIndicator = true,
  })  : width = size,
        height = size,
        borderRadius = null,
        shape = BoxShape.circle;

  /// Convenience constructor for full-bleed or card hero banners.
  const ArmSphereImage.hero({
    super.key,
    this.assetPath,
    this.imageUrl,
    this.width,
    this.height = 200.0,
    this.fit = BoxFit.cover,
    this.fallbackAsset = ArmSphereAssets.heroArena,
    this.fallbackIcon = Icons.sports_kabaddi_rounded,
    this.initial,
    this.cacheWidth,
    this.cacheHeight,
    this.borderRadius,
    this.border,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.showLoadingIndicator = true,
  }) : shape = BoxShape.rectangle;

  int? get _effectiveCacheWidth {
    if (cacheWidth != null) return cacheWidth;
    if (width != null && width!.isFinite && width! > 0) {
      return (width! * 3).toInt().clamp(48, 1920);
    }
    return null;
  }

  int? get _effectiveCacheHeight {
    if (cacheHeight != null) return cacheHeight;
    if (height != null && height!.isFinite && height! > 0) {
      return (height! * 3).toInt().clamp(48, 1920);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    Widget content = _buildImagePipeline(context);

    // Apply geometric shaping / clipping
    if (shape == BoxShape.circle) {
      content = ClipOval(child: content);
      if (border != null) {
        content = Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: border,
          ),
          child: content,
        );
      }
    } else if (borderRadius != null) {
      content = ClipRRect(
        borderRadius: borderRadius!,
        child: content,
      );
      if (border != null) {
        content = Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: border,
          ),
          child: content,
        );
      }
    }

    // Apply accessibility semantics
    if (semanticLabel != null && semanticLabel!.isNotEmpty) {
      return Semantics(
        label: semanticLabel,
        image: true,
        excludeSemantics: excludeFromSemantics,
        child: content,
      );
    } else if (excludeFromSemantics) {
      return ExcludeSemantics(child: content);
    }

    return content;
  }

  Widget _buildImagePipeline(BuildContext context) {
    // Level 1A: Remote Network Image with disk and memory caching
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!.trim(),
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: _effectiveCacheWidth,
        memCacheHeight: _effectiveCacheHeight,
        placeholder: (ctx, url) => _buildPlaceholder(),
        errorWidget: (ctx, url, error) => _buildLevel2Fallback(context),
      );
    }

    // Level 1B: Bundled Local Asset
    if (assetPath != null && assetPath!.trim().isNotEmpty) {
      return Image.asset(
        assetPath!.trim(),
        width: width,
        height: height,
        fit: fit,
        cacheWidth: _effectiveCacheWidth,
        cacheHeight: _effectiveCacheHeight,
        errorBuilder: (ctx, error, stackTrace) => _buildLevel2Fallback(context),
      );
    }

    // Direct descent to Level 2 when neither remote nor local primary path is given
    return _buildLevel2Fallback(context);
  }

  /// Level 2: Bundled Approved Fallback Asset
  Widget _buildLevel2Fallback(BuildContext context) {
    if (fallbackAsset == null || fallbackAsset!.trim().isEmpty) {
      return _buildLevel3Fallback(context);
    }

    return Image.asset(
      fallbackAsset!.trim(),
      width: width,
      height: height,
      fit: fit,
      cacheWidth: _effectiveCacheWidth,
      cacheHeight: _effectiveCacheHeight,
      errorBuilder: (ctx, error, stackTrace) => _buildLevel3Fallback(context),
    );
  }

  /// Level 3: Safe Procedural GPU Gradient + High-Contrast Vector Glyph
  Widget _buildLevel3Fallback(BuildContext context) {
    final effectiveWidth = width;
    final effectiveHeight = height;

    final double computedMin = (effectiveWidth != null && effectiveHeight != null)
        ? math.min(effectiveWidth, effectiveHeight)
        : (effectiveWidth ?? effectiveHeight ?? 64.0);

    final double glyphSize = (computedMin * 0.38).clamp(14.0, 48.0);

    return Container(
      width: effectiveWidth,
      height: effectiveHeight,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.voidBackground, // #070A11
            AppTheme.cardSurface,    // #121826
          ],
        ),
      ),
      child: Center(
        child: (initial != null && initial!.trim().isNotEmpty)
            ? Text(
                initial!.trim().substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: glyphSize * 0.95,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.goldPrimary,
                ),
              )
            : Icon(
                fallbackIcon,
                color: AppTheme.goldPrimary.withValues(alpha: 0.65),
                size: glyphSize,
              ),
      ),
    );
  }

  /// Subtle loading placeholder aligned with AppTheme surface tokens
  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppTheme.cardSurface,
      child: showLoadingIndicator
          ? const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldPrimary),
                ),
              ),
            )
          : null,
    );
  }
}
