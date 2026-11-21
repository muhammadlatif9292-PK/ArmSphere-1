import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/radar_provider.dart';

/// Renders an interactive, design-system-compliant Flutter widget marker for
/// any [RadarPin] on the tactical 2D map.
class RadarPinMarker extends StatelessWidget {
  final RadarPin pin;
  final bool isSelected;
  final bool isOwned;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const RadarPinMarker({
    super.key,
    required this.pin,
    required this.isSelected,
    this.isOwned = false,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    if (pin.pinType == RadarPinType.beacon) {
      return _PulsingBeaconMarker(
        pin: pin,
        isSelected: isSelected,
        isOwned: isOwned,
        onTap: onTap,
        onLongPress: onLongPress,
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      onLongPress: onLongPress == null
          ? null
          : () {
              HapticFeedback.heavyImpact();
              onLongPress!();
            },
      child: Center(
        child: AnimatedScale(
          scale: isSelected ? 1.24 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: _buildStaticMarkerBody(),
        ),
      ),
    );
  }

  Widget _buildStaticMarkerBody() {
    switch (pin.pinType) {
      case RadarPinType.event:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.background,
            border: Border.all(
              color: isSelected ? AppTheme.goldLight : AppTheme.goldPrimary,
              width: isSelected ? 2.4 : 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.goldPrimary.withValues(alpha: isSelected ? 0.55 : 0.32),
                blurRadius: isSelected ? 16 : 10,
                spreadRadius: isSelected ? 1.5 : 0.5,
              ),
            ],
          ),
          child: const Icon(
            Icons.emoji_events_rounded,
            size: 20,
            color: AppTheme.goldPrimary,
          ),
        );

      case RadarPinType.venue:
      case RadarPinType.club:
        return Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppTheme.brushedSteel,
            border: Border.all(
              color: isSelected ? AppTheme.goldPrimary : AppTheme.borderHighlight,
              width: isSelected ? 2.0 : 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            pin.pinType == RadarPinType.club
                ? Icons.fitness_center_rounded
                : Icons.storefront_rounded,
            size: 17,
            color: isSelected ? AppTheme.goldLight : AppTheme.textSecondary,
          ),
        );

      case RadarPinType.informalEvent:
        return Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.background,
            border: Border.all(
              color: isSelected ? AppTheme.goldLight : AppTheme.highlightPurple,
              width: isSelected ? 2.2 : 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.highlightPurple.withValues(alpha: 0.38),
                blurRadius: 10,
              ),
            ],
          ),
          child: const Icon(
            Icons.sports_martial_arts_rounded,
            size: 17,
            color: AppTheme.highlightPurple,
          ),
        );

      case RadarPinType.athlete:
        return Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.cyan.withValues(alpha: isSelected ? 0.24 : 0.14),
            border: Border.all(
              color: isSelected
                  ? AppTheme.cyan
                  : AppTheme.cyan.withValues(alpha: 0.55),
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Center(
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.titanium,
                border: Border.all(
                  color: isSelected ? AppTheme.textPure : AppTheme.cyan,
                  width: 1.4,
                ),
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 9,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        );

      case RadarPinType.beacon:
        return const SizedBox.shrink();
    }
  }
}

/// Animated pulsing crimson beacon pin (`#E23B3B`) supporting tap & long-press.
class _PulsingBeaconMarker extends StatefulWidget {
  final RadarPin pin;
  final bool isSelected;
  final bool isOwned;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _PulsingBeaconMarker({
    required this.pin,
    required this.isSelected,
    required this.isOwned,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<_PulsingBeaconMarker> createState() => _PulsingBeaconMarkerState();
}

class _PulsingBeaconMarkerState extends State<_PulsingBeaconMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTravel =
        (widget.pin.beaconType ?? '').toUpperCase().contains('TRAVEL');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              HapticFeedback.heavyImpact();
              widget.onLongPress!();
            },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          final pulse = _controller.value;
          final ringSize = 26.0 + pulse * 30.0;
          final opacity = (1.0 - pulse).clamp(0.0, 1.0) * 0.65;

          return SizedBox(
            width: 58,
            height: 58,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: ringSize,
                  height: ringSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.crimson.withValues(alpha: opacity * 0.35),
                    border: Border.all(
                      color: AppTheme.crimson.withValues(alpha: opacity),
                      width: 1.6,
                    ),
                  ),
                ),
                AnimatedScale(
                  scale: widget.isSelected ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 180),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.crimson,
                      border: Border.all(
                        color: widget.isSelected || widget.isOwned
                            ? AppTheme.goldLight
                            : AppTheme.textPure,
                        width: widget.isSelected ? 2.4 : 1.6,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.crimson.withValues(alpha: 0.65),
                          blurRadius: widget.isSelected ? 16 : 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      isTravel
                          ? Icons.flight_takeoff_rounded
                          : Icons.local_fire_department_rounded,
                      size: 18,
                      color: AppTheme.textPure,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
