import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final double percent;

  const ShimmerBox({
    Key? key,
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.percent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment(-1.5 + (percent * 3), 0),
          end: Alignment(-0.5 + (percent * 3), 0),
          colors: const [
            Color(0xFF141E2F),
            Color(0xFF23324A),
            Color(0xFF141E2F),
          ],
        ),
      ),
    );
  }
}

