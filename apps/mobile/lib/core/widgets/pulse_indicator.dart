import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PulseIndicator extends StatefulWidget {
  final Color color;
  final double size;
  final String? semanticLabel;
  final Duration duration;

  const PulseIndicator({
    Key? key,
    this.color = AppTheme.primaryAccent, // Crimson accent default
    this.size = 8.0,
    this.semanticLabel,
    this.duration = const Duration(milliseconds: 1200),
  }) : super(key: key);

  @override
  State<PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<PulseIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String accessibilityLabel = widget.semanticLabel ?? 'Live indicator pulsing';

    return Semantics(
      label: accessibilityLabel,
      liveRegion: true,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulsing ring
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: widget.size * 2.2,
                height: widget.size * 2.2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withOpacity((1.0 - _pulseAnimation.value) * 0.4),
                ),
              );
            },
          ),
          // Inner breathing dot
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _pulseAnimation.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
