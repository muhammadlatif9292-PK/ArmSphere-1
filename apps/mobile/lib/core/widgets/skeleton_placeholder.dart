// lib/core/widgets/skeleton_placeholder.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Standardized Crystal Glassmorphic Shimmer Skeleton Loader
///
/// Upgraded to ArmSphere Crystal Glassmorphism System:
/// - Automatically renders a **Structured Crystal Glass Skeleton Card** with realistic
///   inner anatomy (leading squircle icon/avatar bone, primary & secondary text bones,
///   metadata caption bones, and trailing status badge capsule) whenever instantiated
///   at card dimensions (`height >= 56` and `shape == BoxShape.rectangle`).
/// - Renders a precision shimmer bone for compact inline elements (`height < 56`,
///   `SkeletonPlaceholder.avatar`, `SkeletonPlaceholder.textLine`, or `isRawBone: true`).
/// - Powered by a single synchronized 15-degree optical shimmer sweep per card.
class SkeletonPlaceholder extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final String? semanticLabel;
  final BoxShape shape;
  final bool isRawBone;

  const SkeletonPlaceholder({
    super.key,
    this.width,
    this.height,
    this.borderRadius = AppTheme.radiusMedium,
    this.semanticLabel,
    this.shape = BoxShape.rectangle,
    this.isRawBone = false,
  });

  const SkeletonPlaceholder.avatar({
    super.key,
    double size = 48.0,
    this.semanticLabel = 'Loading profile avatar',
  })  : width = size,
        height = size,
        borderRadius = 0,
        shape = BoxShape.circle,
        isRawBone = true;

  const SkeletonPlaceholder.textLine({
    super.key,
    this.width = 120.0,
    this.height = 14.0,
    this.borderRadius = 4.0,
    this.semanticLabel = 'Loading text',
  })  : shape = BoxShape.rectangle,
        isRawBone = true;

  const SkeletonPlaceholder.card({
    super.key,
    this.width = double.infinity,
    this.height = 96.0,
    this.borderRadius = AppTheme.radiusMedium,
    this.semanticLabel = 'Loading card content',
  })  : shape = BoxShape.rectangle,
        isRawBone = false;

  @override
  State<SkeletonPlaceholder> createState() => _SkeletonPlaceholderState();
}

class _SkeletonPlaceholderState extends State<SkeletonPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _gradientAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    )..repeat();
    _gradientAnimation = Tween<double>(begin: -1.4, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  LinearGradient _boneShimmerGradient(double progress, {bool subtle = false}) {
    final baseColor =
        subtle ? const Color(0xFF17202E) : const Color(0xFF1A2434);
    final highlightColor =
        subtle ? const Color(0xFF233044) : const Color(0xFF2B3B54);
    return LinearGradient(
      begin: const Alignment(-1.0, -0.27),
      end: const Alignment(1.0, 0.27),
      colors: [
        baseColor,
        highlightColor,
        baseColor,
      ],
      stops: [
        (progress - 0.32).clamp(0.0, 1.0),
        progress,
        (progress + 0.32).clamp(0.0, 1.0),
      ],
    );
  }

  Widget _buildBone({
    required double progress,
    double? width,
    double? widthFactor,
    required double height,
    double radius = 5.0,
    bool subtle = false,
    bool hasBorder = false,
  }) {
    Widget bone = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: _boneShimmerGradient(progress, subtle: subtle),
        border: hasBorder
            ? Border.all(color: const Color(0x24FFFFFF), width: 1.0)
            : null,
      ),
    );
    if (widthFactor != null) {
      return FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: widthFactor,
        child: bone,
      );
    }
    return bone;
  }

  Widget _buildStructuredCrystalCard(double progress) {
    final double targetHeight = widget.height ?? 92.0;

    return Container(
      width: widget.width,
      height: targetHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        gradient: LinearGradient(
          begin: const Alignment(-1.0, -0.35),
          end: const Alignment(1.0, 0.35),
          colors: const [
            Color(0xD9121824),
            Color(0xE6182232),
            Color(0xD9101620),
          ],
          stops: [
            (progress - 0.38).clamp(0.0, 1.0),
            progress,
            (progress + 0.38).clamp(0.0, 1.0),
          ],
        ),
        border: Border.all(
          color: AppTheme.borderTitanium,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          (widget.borderRadius - 1.0).clamp(4.0, 32.0),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double maxW = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : 340.0;
            final double maxH = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : targetHeight;

            if (maxW < 150 || maxH < 54) {
              return _buildBone(
                progress: progress,
                width: maxW,
                height: maxH,
                radius: widget.borderRadius,
              );
            }

            // Feature / Large Card Anatomy (height >= 126dp)
            if (maxH >= 126) {
              final bool showFooterStrip = maxH >= 164;
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Header row: Avatar squircle + Title/Subtitle + Badge pill
                    Row(
                      children: [
                        _buildBone(
                          progress: progress,
                          width: 38,
                          height: 38,
                          radius: 10,
                          hasBorder: true,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildBone(
                                progress: progress,
                                widthFactor: 0.68,
                                height: 12,
                                radius: 4,
                              ),
                              const SizedBox(height: 6),
                              _buildBone(
                                progress: progress,
                                widthFactor: 0.44,
                                height: 9,
                                radius: 4,
                                subtle: true,
                              ),
                            ],
                          ),
                        ),
                        if (maxW >= 230) ...[
                          const SizedBox(width: 10),
                          _buildBone(
                            progress: progress,
                            width: 58,
                            height: 22,
                            radius: 6,
                            hasBorder: true,
                          ),
                        ],
                      ],
                    ),
                    Container(
                      height: 1,
                      color: const Color(0x16FFFFFF),
                    ),
                    // Body prose lines
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildBone(
                          progress: progress,
                          widthFactor: 0.90,
                          height: 10,
                          radius: 4,
                          subtle: true,
                        ),
                        const SizedBox(height: 6),
                        _buildBone(
                          progress: progress,
                          widthFactor: 0.62,
                          height: 10,
                          radius: 4,
                          subtle: true,
                        ),
                      ],
                    ),
                    if (showFooterStrip)
                      Row(
                        children: [
                          Expanded(
                            child: _buildBone(
                              progress: progress,
                              height: 22,
                              radius: 6,
                              subtle: true,
                              hasBorder: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildBone(
                              progress: progress,
                              height: 22,
                              radius: 6,
                              subtle: true,
                              hasBorder: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildBone(
                              progress: progress,
                              height: 22,
                              radius: 6,
                              subtle: true,
                              hasBorder: true,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            }

            // Standard List / Ticket / Notification Card Anatomy (56dp <= height < 126dp)
            final double iconBoxSize = (maxH - 24.0).clamp(32.0, 42.0);
            final bool showThirdMetaLine = maxH >= 84.0;

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 10.0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildBone(
                    progress: progress,
                    width: iconBoxSize,
                    height: iconBoxSize,
                    radius: 10,
                    hasBorder: true,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildBone(
                          progress: progress,
                          widthFactor: 0.70,
                          height: 12,
                          radius: 4,
                        ),
                        const SizedBox(height: 6),
                        _buildBone(
                          progress: progress,
                          widthFactor: 0.46,
                          height: 9,
                          radius: 4,
                          subtle: true,
                        ),
                        if (showThirdMetaLine) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildBone(
                                progress: progress,
                                width: 48,
                                height: 7,
                                radius: 3,
                                subtle: true,
                              ),
                              const SizedBox(width: 6),
                              _buildBone(
                                progress: progress,
                                width: 34,
                                height: 7,
                                radius: 3,
                                subtle: true,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (maxW >= 220) ...[
                    const SizedBox(width: 10),
                    _buildBone(
                      progress: progress,
                      width: 54,
                      height: 22,
                      radius: 6,
                      hasBorder: true,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool useStructuredCard = !widget.isRawBone &&
        widget.shape == BoxShape.rectangle &&
        (widget.height != null && widget.height! >= 56.0) &&
        (widget.width == null || widget.width! >= 160.0);

    return Semantics(
      label: widget.semanticLabel ?? 'Loading content placeholder',
      child: AnimatedBuilder(
        animation: _gradientAnimation,
        builder: (context, child) {
          final progress =
              ((_gradientAnimation.value + 1.4) / 2.8).clamp(0.0, 1.0);

          if (useStructuredCard) {
            return _buildStructuredCrystalCard(progress);
          }

          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              shape: widget.shape,
              borderRadius: widget.shape == BoxShape.circle
                  ? null
                  : BorderRadius.circular(widget.borderRadius),
              gradient: _boneShimmerGradient(progress),
              border: Border.all(
                color: const Color(0x1EFFFFFF),
                width: 0.8,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Reusable full-screen or section-level Structured Crystal Skeleton List.
///
/// Replaces plain centered spinners on list/feed/directory screens with
/// staggered Crystal Glass skeleton cards.
class CrystalScreenLoadingView extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsetsGeometry padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const CrystalScreenLoadingView({
    super.key,
    this.itemCount = 4,
    this.itemHeight = 92.0,
    this.padding = const EdgeInsets.all(AppTheme.space16),
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: AppTheme.space12),
      itemBuilder: (_, index) => SkeletonPlaceholder(
        height: index == 0 && itemCount >= 4 ? itemHeight + 8.0 : itemHeight,
        borderRadius: AppTheme.radiusMedium,
      ),
    );
  }
}
