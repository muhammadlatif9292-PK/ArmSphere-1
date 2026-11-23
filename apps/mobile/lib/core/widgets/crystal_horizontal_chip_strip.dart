import 'package:flutter/material.dart';

/// Horizontally scrollable filter chip strip with consistent `16px` horizontal
/// padding, trailing breathing room, and a subtle right-edge scroll fade so the
/// rightmost visible chip is never abruptly cut mid-letter.
class CrystalHorizontalChipStrip extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final EdgeInsetsGeometry padding;
  final double? height;
  final CrossAxisAlignment crossAxisAlignment;

  const CrystalHorizontalChipStrip({
    super.key,
    required this.children,
    this.spacing = 8.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0),
    this.height,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> spacedChildren = [];
    for (int i = 0; i < children.length; i++) {
      if (i > 0 && spacing > 0) {
        spacedChildren.add(SizedBox(width: spacing));
      }
      spacedChildren.add(children[i]);
    }
    // Extra trailing breathing room so the last chip clears the right-edge fade cleanly.
    spacedChildren.add(const SizedBox(width: 12));

    Widget strip = ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (Rect bounds) {
        return const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: <double>[0.0, 0.90, 1.0],
          colors: <Color>[
            Color(0xFFFFFFFF),
            Color(0xFFFFFFFF),
            Color(0x00FFFFFF),
          ],
        ).createShader(bounds);
      },
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: padding,
        child: Row(
          crossAxisAlignment: crossAxisAlignment,
          children: spacedChildren,
        ),
      ),
    );

    if (height != null) {
      strip = SizedBox(height: height, child: strip);
    }

    return strip;
  }
}
