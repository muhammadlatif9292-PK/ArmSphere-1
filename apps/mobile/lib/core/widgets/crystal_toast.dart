import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'main_shell_screen.dart';

/// Semantic classification for Crystal Glass action completion and alert bars.
enum CrystalToastType {
  success,
  error,
  warning,
  info,
}

/// Drop-in Crystal Glassmorphic [SnackBar] replacement.
///
/// Transforms standard Material [SnackBar] notifications (such as "All alerts
/// marked as read" or error messages) into a floating, frosted Crystal Glass
/// capsule positioned cleanly above the navigation dock with a semantic status
/// icon capsule and glowing specular rim.
class CrystalSnackBar extends SnackBar {
  CrystalSnackBar({
    super.key,
    required Widget content,
    Color? backgroundColor,
    double? elevation,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    double? width,
    ShapeBorder? shape,
    HitTestBehavior? hitTestBehavior,
    SnackBarBehavior? behavior,
    SnackBarAction? action,
    double? actionOverflowThreshold,
    bool? showCloseIcon,
    Color? closeIconColor,
    Duration duration = const Duration(seconds: 4),
    Animation<double>? animation,
    VoidCallback? onVisible,
    DismissDirection? dismissDirection,
    Clip clipBehavior = Clip.none,
    CrystalToastType? toastType,
    CrystalToastType? type,
    IconData? customIcon,
  }) : super(
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          margin: width != null
              ? null
              : (margin ?? const EdgeInsets.fromLTRB(16, 0, 16, 16)),
          width: width,
          padding: EdgeInsets.zero,
          shape: shape ??
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
          hitTestBehavior: hitTestBehavior,
          action: null,
          actionOverflowThreshold: actionOverflowThreshold,
          showCloseIcon: false,
          closeIconColor: closeIconColor,
          duration: duration,
          animation: animation,
          onVisible: onVisible,
          dismissDirection: dismissDirection ?? DismissDirection.horizontal,
          clipBehavior: clipBehavior,
          content: CrystalToastCapsule(
            content: content,
            type: type ?? toastType ?? CrystalToastCapsule.inferType(backgroundColor),
            action: action,
            customPadding: padding,
            customIcon: customIcon,
          ),
        );
}

/// Displays a floating Crystal Glassmorphic completion or error bar via [ScaffoldMessenger].
void showCrystalSnackBar(
  BuildContext context, {
  required String message,
  CrystalToastType type = CrystalToastType.info,
  Duration duration = const Duration(seconds: 3),
  SnackBarAction? action,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      CrystalSnackBar(
        content: Text(message),
        toastType: type,
        duration: duration,
        action: action,
      ),
    );
}

/// Refractive Crystal Glassmorphic capsule rendered inside [CrystalSnackBar].
class CrystalToastCapsule extends StatelessWidget {
  final Widget content;
  final CrystalToastType type;
  final SnackBarAction? action;
  final EdgeInsetsGeometry? customPadding;
  final IconData? customIcon;

  const CrystalToastCapsule({
    super.key,
    required this.content,
    this.type = CrystalToastType.info,
    this.action,
    this.customPadding,
    this.customIcon,
  });

  /// Infers the semantic [CrystalToastType] from legacy [SnackBar.backgroundColor] tokens.
  static CrystalToastType inferType(Color? color) {
    if (color == null) return CrystalToastType.info;
    final int val = color.toARGB32();
    if (val == AppTheme.success.toARGB32() ||
        val == AppTheme.emerald.toARGB32() ||
        val == const Color(0xFF2E7D32).toARGB32() ||
        val == Colors.green.toARGB32()) {
      return CrystalToastType.success;
    }
    if (val == AppTheme.error.toARGB32() ||
        val == AppTheme.crimson.toARGB32() ||
        val == Colors.red.toARGB32() ||
        val == Colors.redAccent.toARGB32()) {
      return CrystalToastType.error;
    }
    if (val == AppTheme.warning.toARGB32() ||
        val == AppTheme.goldPrimary.toARGB32() ||
        val == AppTheme.accentOrange.toARGB32() ||
        val == Colors.orange.toARGB32() ||
        val == Colors.amber.toARGB32()) {
      return CrystalToastType.warning;
    }
    return CrystalToastType.info;
  }

  Color _accentColor() {
    switch (type) {
      case CrystalToastType.success:
        return AppTheme.emerald;
      case CrystalToastType.error:
        return AppTheme.crimson;
      case CrystalToastType.warning:
        return AppTheme.goldPrimary;
      case CrystalToastType.info:
        return AppTheme.goldPrimary;
    }
  }

  IconData _statusIcon() {
    if (customIcon != null) {
      return customIcon!;
    }
    switch (type) {
      case CrystalToastType.success:
        return Icons.check_circle_rounded;
      case CrystalToastType.error:
        return Icons.error_outline_rounded;
      case CrystalToastType.warning:
        return Icons.warning_amber_rounded;
      case CrystalToastType.info:
        return Icons.auto_awesome_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = _accentColor();
    final bool isInsideShell = MainShellScope.isInsideShell(context);
    final double dockOffset = isInsideShell ? kFloatingDockTotalHeight : 0.0;

    return Padding(
      padding: EdgeInsets.only(bottom: dockOffset),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.56),
              blurRadius: 24,
              spreadRadius: -2,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: accent.withValues(alpha: 0.22),
              blurRadius: 18,
              spreadRadius: -2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: customPadding ??
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xEB0B101C),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: accent.withValues(alpha: 0.55),
                  width: 1.2,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0.0, 0.48, 1.0],
                  colors: [
                    accent.withValues(alpha: 0.18),
                    const Color(0xE80D1422),
                    const Color(0xF2080C15),
                  ],
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Top specular crystal highlight rim
                  Positioned(
                    top: -12,
                    left: 18,
                    right: 18,
                    height: 1.0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.0),
                            Colors.white.withValues(alpha: 0.55),
                            accent.withValues(alpha: 0.65),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.35, 0.65, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      // Frosted status icon squircle capsule
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.48),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.24),
                              blurRadius: 10,
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            _statusIcon(),
                            size: 18,
                            color: accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DefaultTextStyle(
                          style: const TextStyle(
                            fontFamily: AppTheme.fontBody,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPure,
                            height: 1.35,
                            letterSpacing: 0.1,
                          ),
                          child: content,
                        ),
                      ),
                      if (action != null) ...[
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            action!.onPressed();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.52),
                                width: 1.0,
                              ),
                            ),
                            child: Text(
                              action!.label,
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: accent,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


/// Static toast invocation helper matching the AI Studio component contract.
class CrystalToast {
  static void show(
    BuildContext context, {
    required String title,
    String? message,
    CrystalToastType type = CrystalToastType.info,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    final textWidget = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: AppTheme.textPure,
          ),
        ),
        if (message != null && message.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            message,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ],
    );

    showCrystalSnackBar(
      context,
      content: textWidget,
      type: type,
      duration: duration,
      action: action,
    );
  }
}
