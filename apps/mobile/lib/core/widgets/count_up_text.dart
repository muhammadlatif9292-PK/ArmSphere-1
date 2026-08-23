import 'package:flutter/material.dart';

class CountUpText extends StatefulWidget {
  final num value;
  final TextStyle? style;
  final String? prefix;
  final String? suffix;
  final int decimalPlaces;
  final Duration duration;
  final String? semanticLabel;
  final String Function(num)? formatter;

  const CountUpText({
    Key? key,
    required this.value,
    this.style,
    this.prefix,
    this.suffix,
    this.decimalPlaces = 0,
    this.duration = const Duration(milliseconds: 350),
    this.semanticLabel,
    this.formatter,
  }) : super(key: key);

  @override
  State<CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  num _oldValue = 0;

  @override
  void initState() {
    super.initState();
    _oldValue = widget.value;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(
      begin: widget.value.toDouble(),
      end: widget.value.toDouble(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void didUpdateWidget(CountUpText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _oldValue = oldWidget.value;
      _controller.reset();
      _animation = Tween<double>(
        begin: _oldValue.toDouble(),
        end: widget.value.toDouble(),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ensure display font is used as scoreboard default if none is provided
    final defaultStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontFamily: 'SpaceGrotesk',
      fontWeight: FontWeight.bold,
    );

    final textStyle = (widget.style ?? defaultStyle)?.copyWith(
      fontFamily: 'SpaceGrotesk', // Hard mandate: ALL stats use Space Grotesk
    );

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final animatedVal = _animation.value;
        final formattedValue = widget.formatter != null
            ? widget.formatter!(animatedVal)
            : animatedVal.toStringAsFixed(widget.decimalPlaces);
        final displayText = '${widget.prefix ?? ''}$formattedValue${widget.suffix ?? ''}';

        return Semantics(
          label: widget.semanticLabel ?? 'Stat value: $displayText',
          value: displayText,
          child: Text(
            displayText,
            style: textStyle,
          ),
        );
      },
    );
  }
}
