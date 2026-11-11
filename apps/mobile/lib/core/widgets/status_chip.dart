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
    return Colors.transparent;
  }

  Color _getBorderColor() {
    switch (type) {
      case StatusType.success:
        return const Color(0x6610B981);
      case StatusType.warning:
        return const Color(0x73D4AF37);
      case StatusType.error:
      case StatusType.live:
        return const Color(0x80E23B3B);
      case StatusType.info:
        return const Color(0x6638BDF8);
      case StatusType.neutral:
        return const Color(0x38FFFFFF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fgColor = _getForegroundColor();
    final borderColor = _getBorderColor();
    final isLive = type == StatusType.live;

    Widget chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.5),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: const [],
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
              shadows: AppTheme.crystalTextShadows,
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
    final borderColor =
        isRightArm ? const Color(0x6638BDF8) : const Color(0x73D4AF37);
    final label = isRightArm ? 'RIGHT ARM' : 'LEFT ARM';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.5),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: const [],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTheme.fontDisplay,
          fontWeight: FontWeight.w800,
          fontSize: 9.5,
          color: color,
          letterSpacing: 0.6,
          shadows: AppTheme.crystalTextShadows,
        ),
      ),
    );
  }
}
