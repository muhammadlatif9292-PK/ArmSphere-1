import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
class LiveCountdownTimerWidget extends StatefulWidget {
  final Duration initialDuration;

  const LiveCountdownTimerWidget({
    Key? key,
    this.initialDuration = const Duration(days: 4, hours: 12, minutes: 38, seconds: 45),
  }) : super(key: key);

  @override
  State<LiveCountdownTimerWidget> createState() => _LiveCountdownTimerWidgetState();
}

class _LiveCountdownTimerWidgetState extends State<LiveCountdownTimerWidget> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.initialDuration;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remaining.inSeconds > 0) {
            _remaining = _remaining - const Duration(seconds: 1);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = _remaining.inDays.toString().padLeft(2, '0');
    final hours = (_remaining.inHours % 24).toString().padLeft(2, '0');
    final minutes = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_remaining.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Color(0xFFFFB300).withOpacity(0.18),
        border: Border.all(color: Color(0xFFFFB300).withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFFB300).withOpacity(0.25),
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        '${days}d : ${hours}h : ${minutes}m : ${seconds}s',
        style: const TextStyle(
          fontFamily: AppTheme.fontDisplay,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: Color(0xFFFFB300),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

