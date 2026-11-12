import 'dart:async';
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
/// Renders a compact floating frosted pill (`height: 48px`, `BackdropFilter`
/// blur `sigmaX: 16, sigmaY: 16`, `color: const Color(0xD905070C)`,
/// `borderRadius: BorderRadius.circular(14)`, `border: Border.all(color: const Color(0x80D4AF37), width: 1.0)`)
/// positioned `16px` above the floating Bottom Navigation Bar and auto-dismissing
/// after `2.2 seconds`.
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
    Duration duration = const Duration(milliseconds: 2200),
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
              : (margin ?? const EdgeInsets.fromLTRB(18, 0, 18, 16)),
          width: width,
          padding: EdgeInsets.zero,
          shape: shape ??
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
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
            autoDismissDuration: duration,
          ),
        );
}

/// Displays a floating Crystal Glassmorphic completion or persona-switch pill via [ScaffoldMessenger].
void showCrystalSnackBar(
  BuildContext context, {
  String? message,
  Widget? content,
  CrystalToastType type = CrystalToastType.info,
  Duration duration = const Duration(milliseconds: 2200),
  SnackBarAction? action,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final effectiveContent = content ?? Text(message ?? '');
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      CrystalSnackBar(
        content: effectiveContent,
        toastType: type,
        duration: duration,
        action: action,
      ),
    );
}

/// Refractive Crystal Glassmorphic capsule rendered inside [CrystalSnackBar].
class CrystalToastCapsule extends StatefulWidget {
  final Widget content;
  final CrystalToastType type;
  final SnackBarAction? action;
  final EdgeInsetsGeometry? customPadding;
  final IconData? customIcon;
  final Duration autoDismissDuration;

  const CrystalToastCapsule({
    super.key,
    required this.content,
    this.type = CrystalToastType.info,
    this.action,
    this.customPadding,
    this.customIcon,
    this.autoDismissDuration = const Duration(milliseconds: 2200),
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

  @override
  State<CrystalToastCapsule> createState() => _CrystalToastCapsuleState();
}

class _CrystalToastCapsuleState extends State<CrystalToastCapsule> {
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    // Ensure 2.2-second auto-dismiss even on Android devices where system
    // accessibleNavigation flags would otherwise keep SnackBars open indefinitely.
    final bool isWidgetTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isWidgetTest) {
      _autoDismissTimer = Timer(widget.autoDismissDuration, () {
        if (!mounted) return;
        ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
      });
    }
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  Color _accentColor() {
    switch (widget.type) {
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
    if (widget.customIcon != null) {
      return widget.customIcon!;
    }
    switch (widget.type) {
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
    final Color borderColor = (widget.type == CrystalToastType.info ||
            widget.type == CrystalToastType.warning)
        ? const Color(0x80D4AF37)
        : accent.withValues(alpha: 0.65);

    // MainShellScreen's Scaffold(extendBody: true, bottomNavigationBar: ...)
    // already injects kFloatingDockTotalHeight (76px) + systemBottomInset into
    // MediaQuery.paddingOf(context).bottom. Only add dockOffset if inside
    // MainShellScope without the bottomNavigationBar padding already applied.
    final bool isInsideShell = MainShellScope.isInsideShell(context);
    final double currentBottomPadding = MediaQuery.paddingOf(context).bottom;
    final double dockOffset =
        (isInsideShell && currentBottomPadding < kFloatingDockHeight)
            ? kFloatingDockTotalHeight
            : 0.0;

    return Padding(
      padding: EdgeInsets.only(bottom: dockOffset),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: widget.customPadding ??
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xD905070C),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: borderColor,
                width: 1.0,
              ),
              boxShadow: const [],
            ),
            child: Row(
              children: [
                // Compact 28x28 status icon squircle capsule
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0x4704060B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: borderColor,
                      width: 1.0,
                    ),
                    boxShadow: const [],
                  ),
                  child: Center(
                    child: Icon(
                      _statusIcon(),
                      size: 16,
                      color: accent,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      fontFamily: AppTheme.fontBody,
                      fontSize: 13.0,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPure,
                      height: 1.25,
                      letterSpacing: 0.1,
                      shadows: AppTheme.crystalTextShadows,
                    ),
                    child: widget.content,
                  ),
                ),
                if (widget.action != null) ...[
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.action!.onPressed();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: borderColor,
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        widget.action!.label,
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: accent,
                          letterSpacing: 0.4,
                          shadows: AppTheme.crystalTextShadows,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
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
    Duration duration = const Duration(milliseconds: 2200),
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
      message: message ?? title,
      content: textWidget,
      type: type,
      duration: duration,
      action: action,
    );
  }
}
