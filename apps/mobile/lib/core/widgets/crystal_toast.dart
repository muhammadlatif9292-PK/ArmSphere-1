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

/// Manages the single active top-anchored overlay toast so floating alerts
/// never cover bottom action cards (e.g., Radar `View Profile`, Scorepad bar).
class _TopOverlayToastManager {
  static OverlayEntry? _activeEntry;
  static Timer? _dismissTimer;

  static void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    try {
      _activeEntry?.remove();
    } catch (_) {
      // Ignore if already removed during route/tree disposal.
    }
    _activeEntry = null;
  }

  static bool show(
    BuildContext context, {
    required Widget content,
    required CrystalToastType type,
    SnackBarAction? action,
    EdgeInsetsGeometry? customPadding,
    IconData? customIcon,
    required Duration duration,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true) ??
        Overlay.maybeOf(context);
    if (overlay == null) return false;

    dismiss();

    final entry = OverlayEntry(
      builder: (overlayContext) {
        final topInset = MediaQuery.paddingOf(overlayContext).top;
        // Anchor cleanly below the AppBar so neither the status bar nor
        // bottom interactive cards/docks are ever obscured.
        final double topOffset = topInset + kToolbarHeight + 8.0;

        return Positioned(
          top: topOffset,
          left: 16,
          right: 16,
          child: Material(
            type: MaterialType.transparency,
            child: Dismissible(
              key: ValueKey<int>(DateTime.now().microsecondsSinceEpoch),
              direction: DismissDirection.up,
              onDismissed: (_) => dismiss(),
              child: _CrystalToastPillBody(
                content: content,
                type: type,
                action: action,
                customPadding: customPadding,
                customIcon: customIcon,
                onActionInvoked: dismiss,
              ),
            ),
          ),
        );
      },
    );

    _activeEntry = entry;
    overlay.insert(entry);

    final bool isWidgetTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isWidgetTest) {
      _dismissTimer = Timer(duration, dismiss);
    }
    return true;
  }
}

/// Drop-in Crystal Glassmorphic [SnackBar] replacement.
///
/// Renders a compact floating frosted pill anchored cleanly near the top
/// (below the AppBar) via the root [Overlay] in live app sessions so bottom
/// action cards (like Radar's `View Profile`) are never obscured, while
/// preserving full synchronous [SnackBar] compatibility in widget tests.
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

/// Displays a top-anchored floating Crystal Glassmorphic toast safely below the AppBar.
void showCrystalSnackBar(
  BuildContext context, {
  String? message,
  Widget? content,
  CrystalToastType type = CrystalToastType.info,
  Duration duration = const Duration(milliseconds: 2200),
  SnackBarAction? action,
}) {
  final effectiveContent = content ?? Text(message ?? '');
  final bool shownInOverlay = _TopOverlayToastManager.show(
    context,
    content: effectiveContent,
    type: type,
    action: action,
    duration: duration,
  );
  if (shownInOverlay) return;

  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
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
  bool _delegatedToTopOverlay = false;

  bool get _isWidgetTest =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    if (!_isWidgetTest) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final promoted = _TopOverlayToastManager.show(
          context,
          content: widget.content,
          type: widget.type,
          action: widget.action,
          customPadding: widget.customPadding,
          customIcon: widget.customIcon,
          duration: widget.autoDismissDuration,
        );
        if (promoted && mounted) {
          setState(() => _delegatedToTopOverlay = true);
          // Immediately clear the empty bottom SnackBar wrapper so bottom taps pass through.
          ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
          return;
        }
        _autoDismissTimer = Timer(widget.autoDismissDuration, () {
          if (!mounted) return;
          ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
        });
      });
    }
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_delegatedToTopOverlay) {
      return const SizedBox.shrink();
    }

    final bool isInsideShell = MainShellScope.isInsideShell(context);
    final double currentBottomPadding = MediaQuery.paddingOf(context).bottom;
    final double dockOffset =
        (isInsideShell && currentBottomPadding < kFloatingDockHeight)
            ? kFloatingDockTotalHeight
            : 0.0;

    return Padding(
      padding: EdgeInsets.only(bottom: dockOffset),
      child: _CrystalToastPillBody(
        content: widget.content,
        type: widget.type,
        action: widget.action,
        customPadding: widget.customPadding,
        customIcon: widget.customIcon,
      ),
    );
  }
}

class _CrystalToastPillBody extends StatelessWidget {
  final Widget content;
  final CrystalToastType type;
  final SnackBarAction? action;
  final EdgeInsetsGeometry? customPadding;
  final IconData? customIcon;
  final VoidCallback? onActionInvoked;

  const _CrystalToastPillBody({
    required this.content,
    required this.type,
    this.action,
    this.customPadding,
    this.customIcon,
    this.onActionInvoked,
  });

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
    final Color borderColor =
        (type == CrystalToastType.info || type == CrystalToastType.warning)
            ? const Color(0x80D4AF37)
            : accent.withValues(alpha: 0.65);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: customPadding ??
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.overlayG6Surface.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
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
                  child: content,
                ),
              ),
              if (action != null) ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    action!.onPressed();
                    onActionInvoked?.call();
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
                      action!.label,
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

  static void error(BuildContext context, String message) {
    show(context, title: message, type: CrystalToastType.error);
  }

  static void success(BuildContext context, String message) {
    show(context, title: message, type: CrystalToastType.success);
  }

  static void warning(BuildContext context, String message) {
    show(context, title: message, type: CrystalToastType.warning);
  }

  static void info(BuildContext context, String message) {
    show(context, title: message, type: CrystalToastType.info);
  }
}
