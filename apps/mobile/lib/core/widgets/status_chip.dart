import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum StatusType {
  success,
  warning,
  error,
  info,
  neutral,
  live,
}

/// Standardized StatusChip
///
/// Grounded in `docs/design/09_COMPONENT_SYSTEM.md` Section 2.3 and `39_DESIGN_DEBT_MAP.md`.
/// Enforces WCAG AA compliant semantic colors with compact 8dp radii.
class StatusChip extends StatelessWidget {
  final String label;
  final StatusType type;
  final IconData? icon;
  final VoidCallback? onTap;

  const StatusChip({
    super.key,
    required this.label,
    this.type = StatusType.neutral,
    this.icon,
    this.onTap,
  });

  /// Const constructors for common federation statuses
  const StatusChip.success({super.key, required this.label, this.icon, this.onTap})
      : type = StatusType.success;

  const StatusChip.warning({super.key, required this.label, this.icon, this.onTap})
      : type = StatusType.warning;

  const StatusChip.error({super.key, required this.label, this.icon, this.onTap})
      : type = StatusType.error;

  const StatusChip.info({super.key, required this.label, this.icon, this.onTap})
      : type = StatusType.info;

  const StatusChip.neutral({super.key, required this.label, this.icon, this.onTap})
      : type = StatusType.neutral;

  const StatusChip.live({super.key, required this.label, this.icon, this.onTap})
      : type = StatusType.live;

  Color _getForegroundColor() {
    switch (type) {
      case StatusType.success:
        return AppTheme.verifiedEmerald;
      case StatusType.warning:
        return AppTheme.championshipGold;
      case StatusType.error:
        return AppTheme.competitionCrimson;
      case StatusType.info:
        return AppTheme.electricCyan;
      case StatusType.neutral:
        return AppTheme.textSecondary;
      case StatusType.live:
        return AppTheme.competitionCrimson;
    }
  }

  Color _getBackgroundColor() {
    return _getForegroundColor().withValues(alpha: 0.14);
  }

  Color _getBorderColor() {
    return _getForegroundColor().withValues(alpha: 0.38);
  }

  @override
  Widget build(BuildContext context) {
    final fgColor = _getForegroundColor();
    final bgColor = _getBackgroundColor();
    final borderColor = _getBorderColor();
    final isLive = type == StatusType.live;

    Widget chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: borderColor, width: 1.0),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            bgColor,
          ],
        ),
        boxShadow: isLive
            ? [
                BoxShadow(
                  color: AppTheme.competitionCrimson.withValues(alpha: 0.25),
                  blurRadius: 8,
                  spreadRadius: 0.5,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isLive) ...[
            Container(
              width: 6.0,
              height: 6.0,
              margin: const EdgeInsets.only(right: 5.0),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.competitionCrimson,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.competitionCrimson,
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ] else if (icon != null) ...[
            Icon(icon, size: 12.0, color: fgColor),
            const SizedBox(width: 4.0),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontWeight: FontWeight.w800,
              fontSize: 10.0,
              color: fgColor,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      chip = GestureDetector(
        onTap: onTap,
        child: chip,
      );
    }

    return chip;
  }
}

/// Arm Indicator Pill distinguishing Right Arm vs. Left Arm competitions
class ArmIndicatorPill extends StatelessWidget {
  final bool isRightArm;

  const ArmIndicatorPill({
    super.key,
    required this.isRightArm,
  });

  @override
  Widget build(BuildContext context) {
    final color = isRightArm ? AppTheme.electricCyan : AppTheme.championshipGold;
    final label = isRightArm ? 'RIGHT ARM' : 'LEFT ARM';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.0),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            color.withValues(alpha: 0.12),
          ],
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTheme.fontDisplay,
          fontWeight: FontWeight.w800,
          fontSize: 9.5,
          color: color,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
