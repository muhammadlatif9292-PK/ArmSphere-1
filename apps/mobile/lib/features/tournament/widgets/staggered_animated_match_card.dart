import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
class StaggeredAnimatedMatchCard extends StatefulWidget {
  final int index;
  final Widget child;

  const StaggeredAnimatedMatchCard({
    Key? key,
    required this.index,
    required this.child,
  }) : super(key: key);

  @override
  State<StaggeredAnimatedMatchCard> createState() => _StaggeredAnimatedMatchCardState();
}

class _StaggeredAnimatedMatchCardState extends State<StaggeredAnimatedMatchCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    final delayMs = (widget.index * 40).clamp(0, 400);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final translateY = (1.0 - _fadeAnimation.value) * 8.0;
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, translateY),
            child: widget.child,
          ),
        );
      },
    );
  }
}

