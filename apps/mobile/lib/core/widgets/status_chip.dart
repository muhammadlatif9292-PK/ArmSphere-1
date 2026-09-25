import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum StatusType {
  success,
  warning,
  error,
  info,
  neutral,
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

  /// Factory constructors for common federation statuses
  factory StatusChip.success({required String label, IconData? icon, VoidCallback? onTap}) =>
      StatusChip(label: label, type: StatusType.success, icon: icon, onTap: onTap);

  factory StatusChip.warning({required String label, IconData? icon, VoidCallback? onTap}) =>
      StatusChip(label: label, type: StatusType.warning, icon: icon, onTap: onTap);

  factory StatusChip.error({required String label, IconData? icon, VoidCallback? onTap}) =>
      StatusChip(label: label, type: StatusType.error, icon: icon, onTap: onTap);

  factory StatusChip.info({required String label, IconData? icon, VoidCallback? onTap}) =>
      StatusChip(label: label, type: StatusType.info, icon: icon, onTap: onTap);

  factory StatusChip.neutral({required String label, IconData? icon, VoidCallback? onTap}) =>
      StatusChip(label: label, type: StatusType.neutral, icon: icon, onTap: onTap);

  Color _getForegroundColor() {
    switch (type) {
      case StatusType.success:
        return AppTheme.success;
      case StatusType.warning:
        return AppTheme.secondaryAccent;
      case StatusType.error:
        return AppTheme.error;
      case StatusType.info:
        return AppTheme.info;
      case StatusType.neutral:
        return AppTheme.textSecondary;
    }
  }

  Color _getBackgroundColor() {
    return _getForegroundColor().withValues(alpha: 0.12);
  }

  Color _getBorderColor() {
    return _getForegroundColor().withValues(alpha: 0.35);
  }

  @override
  Widget build(BuildContext context) {
    final fgColor = _getForegroundColor();
    final bgColor = _getBackgroundColor();
    final borderColor = _getBorderColor();

    Widget chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12.0, color: fgColor),
            const SizedBox(width: 4.0),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: AppTheme.fontBody,
              fontWeight: FontWeight.w700,
              fontSize: 10.5,
              color: fgColor,
              letterSpacing: 0.5,
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
    final color = isRightArm ? AppTheme.cyanAccent : AppTheme.secondaryAccent;
    final label = isRightArm ? 'RIGHT ARM' : 'LEFT ARM';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTheme.fontDisplay,
          fontWeight: FontWeight.bold,
          fontSize: 10.0,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
