import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import 'crystal_stage_scaffold.dart';
import 'main_shell_screen.dart';
import 'tactile_press_wrapper.dart';

export 'crystal_modal_sheet.dart';

/// Shared 38x38dp Crystal Glassmorphic Capsule Icon used across all inner-screen
/// headers for Back and Home navigation actions.
class CrystalNavCapsuleIcon extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final Color iconColor;
  final Color? accentBorderColor;

  const CrystalNavCapsuleIcon({
    super.key,
    required this.icon,
    this.iconSize = 18.0,
    this.iconColor = AppTheme.textPure,
    this.accentBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = accentBorderColor ?? const Color(0x26FFFFFF);
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0x99070A11),
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 12,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          size: iconSize,
          color: iconColor,
        ),
      ),
    );
  }
}

/// Reusable 38x38px circular smoked-crystal icon pill button (`#99070A11` fill, `1px #26FFFFFF` border)
/// for top header actions (search, notifications, settings, refresh, role switch).
class CrystalIconPillButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color iconColor;
  final double iconSize;
  final Color? borderColor;
  final Widget? badgeOverlay;

  const CrystalIconPillButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.iconColor = AppTheme.textPure,
    this.iconSize = 18.0,
    this.borderColor,
    this.badgeOverlay,
  });

  @override
  Widget build(BuildContext context) {
    Widget pill = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0x99070A11),
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor ?? const Color(0x26FFFFFF),
          width: 1.0,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            icon,
            size: iconSize,
            color: iconColor,
          ),
          if (badgeOverlay != null) badgeOverlay!,
        ],
      ),
    );

    return Semantics(
      button: true,
      label: tooltip,
      tooltip: tooltip,
      excludeSemantics: tooltip != null,
      onTap: onPressed == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onPressed!();
            },
      child: Tooltip(
        message: tooltip ?? '',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onPressed!();
                },
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(child: pill),
          ),
        ),
      ),
    );
  }
}

/// Standardized top-left Crystal Glass Back button for all inner screens.
///
/// Always sits in the `AppBar.leading` slot with identical 38x38dp crystal glass
/// geometry inside a 44x44dp ergonomic touch hitbox, haptic click feedback, and
/// chronological step-by-step back navigation.
class CrystalBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String fallbackRoute;
  final String tooltip;

  const CrystalBackButton({
    super.key,
    this.onPressed,
    this.fallbackRoute = '/home',
    this.tooltip = 'Back',
  });

  /// Returns a [CrystalBackButton] only when rendered outside [MainShellScreen],
  /// useful for role-aware screens that can serve as either the `/home` tab root
  /// or a pushed inner route.
  static Widget? maybeForInnerScreen(
    BuildContext context, {
    VoidCallback? onPressed,
    String fallbackRoute = '/home',
  }) {
    if (MainShellScope.isInsideShell(context)) {
      return null;
    }
    return CrystalBackButton(
      onPressed: onPressed,
      fallbackRoute: fallbackRoute,
    );
  }

  void _handlePress(BuildContext context) {
    HapticFeedback.selectionClick();
    if (onPressed != null) {
      onPressed!();
      return;
    }
    final router = GoRouter.maybeOf(context);
    if (router != null && router.canPop()) {
      router.pop();
      return;
    }
    final nav = Navigator.maybeOf(context);
    if (nav != null && nav.canPop()) {
      nav.pop();
      return;
    }
    if (MainShellScope.stepBackIfPossible(context)) {
      return;
    }
    if (MainShellScope.goToMainTabByPath(context, fallbackRoute)) {
      return;
    }
    if (router != null) {
      router.go(fallbackRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      tooltip: tooltip,
      excludeSemantics: true,
      onTap: () => _handlePress(context),
      child: Tooltip(
        message: tooltip,
        child: Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _handlePress(context),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: CrystalNavCapsuleIcon(
                  icon: Icons.arrow_back_ios_new_rounded,
                  iconSize: 17,
                  iconColor: AppTheme.textPure,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Standardized top-right Crystal Glass Quick-Jump Home (`Arena`) button
/// for inner screens so users can return to the main tabs in a single tap
/// from any deep screen.
class CrystalHomeButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String homeRoute;
  final String tooltip;

  const CrystalHomeButton({
    super.key,
    this.onPressed,
    this.homeRoute = '/home',
    this.tooltip = 'Home Arena',
  });

  /// Returns a [CrystalHomeButton] only when rendered outside [MainShellScreen].
  static Widget? maybeForInnerScreen(BuildContext context) {
    if (MainShellScope.isInsideShell(context)) {
      return null;
    }
    return const CrystalHomeButton();
  }

  void _handlePress(BuildContext context) {
    HapticFeedback.lightImpact();
    if (onPressed != null) {
      onPressed!();
      return;
    }
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      while (router.canPop()) {
        router.pop();
      }
      if (!MainShellScope.goToMainTabByPath(context, homeRoute)) {
        router.go(homeRoute);
      }
      return;
    }
    Navigator.maybeOf(context)?.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Semantics(
        button: true,
        label: tooltip,
        tooltip: tooltip,
        excludeSemantics: true,
        onTap: () => _handlePress(context),
        child: Tooltip(
          message: tooltip,
          child: Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _handlePress(context),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: CrystalNavCapsuleIcon(
                    icon: Icons.home_rounded,
                    iconSize: 18,
                    iconColor: AppTheme.textPure,
                    accentBorderColor:
                        AppTheme.crimson.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact Frosted Crystal Glass Header Action Pill for `AppBar.actions`
/// (e.g., "Mark all read", "NEW TICKET", "CREATE TEAM", "POST CLIP", "SUBMIT VENUE").
class CrystalHeaderActionPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final VoidCallback? onPressed;
  final Color accentColor;

  const CrystalHeaderActionPill({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.onPressed,
    this.accentColor = AppTheme.goldPrimary,
  });

  VoidCallback? get _effectiveCallback => onTap ?? onPressed;

  @override
  Widget build(BuildContext context) {
    final callback = _effectiveCallback;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Center(
        child: TactilePressWrapper(
          onTap: callback == null
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  callback();
                },
          semanticLabel: label,
          child: Container(
            constraints: const BoxConstraints(minHeight: 34),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.42),
                  blurRadius: 12,
                  spreadRadius: -2,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.16),
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xB80B101C),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.58),
                      width: 1.1,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0.0, 0.5, 1.0],
                      colors: [
                        accentColor.withValues(alpha: 0.22),
                        const Color(0x16FFFFFF),
                        const Color(0x08FFFFFF),
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          size: 14,
                          color: accentColor,
                        ),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        label,
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPure,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Frosted Crystal Glassmorphic Action Button for in-screen CTAs
/// (e.g., "Log a Session", "Open Support Ticket", "Create a team", "Share a video").
class CrystalActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color accentColor;
  final bool isPrimary;
  final bool fullWidth;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;

  const CrystalActionButton({
    super.key,
    required this.label,
    this.icon,
    VoidCallback? onTap,
    VoidCallback? onPressed,
    this.accentColor = AppTheme.goldPrimary,
    this.isPrimary = true,
    bool? fullWidth,
    bool? expand,
    this.isLoading = false,
    this.padding,
  })  : onTap = onPressed ?? onTap,
        fullWidth = expand ?? fullWidth ?? false;

  @override
  Widget build(BuildContext context) {
    final Color effectiveAccent =
        isPrimary ? accentColor : AppTheme.textSecondary;
    final Widget buttonBody = Container(
      width: fullWidth ? double.infinity : null,
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.48),
            blurRadius: 18,
            spreadRadius: -2,
            offset: const Offset(0, 6),
          ),
          if (isPrimary && onTap != null)
            BoxShadow(
              color: effectiveAccent.withValues(alpha: 0.24),
              blurRadius: 16,
              spreadRadius: -2,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xCC0B101C),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isPrimary
                    ? effectiveAccent.withValues(alpha: 0.62)
                    : AppTheme.borderTitanium,
                width: isPrimary ? 1.2 : 1.0,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.45, 1.0],
                colors: isPrimary
                    ? [
                        effectiveAccent.withValues(alpha: 0.26),
                        const Color(0x1EFFFFFF),
                        const Color(0x0AFFFFFF),
                      ]
                    : [
                        const Color(0x1FFFFFFF),
                        const Color(0x0EFFFFFF),
                        const Color(0x05FFFFFF),
                      ],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 0,
                  left: 14,
                  right: 14,
                  height: 1.0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.52),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                if (isLoading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: isPrimary ? effectiveAccent : AppTheme.textPure,
                    ),
                  )
                else
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(
                            icon,
                            size: 17,
                            color:
                                isPrimary ? effectiveAccent : AppTheme.textPure,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: isPrimary
                                ? AppTheme.textPure
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    return TactilePressWrapper(
      onTap: isLoading || onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      semanticLabel: label,
      child: buttonBody,
    );
  }
}

/// 56x56dp Squircle Frosted Crystal Glass Floating Action Button (`+` FAB)
/// with optical blur, gold or crimson specular rim, and ambient glow.
class CrystalFloatingActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;
  final Color accentColor;
  final Object? heroTag;

  const CrystalFloatingActionButton({
    super.key,
    required this.onPressed,
    this.icon = Icons.add_rounded,
    this.tooltip,
    this.accentColor = AppTheme.goldPrimary,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final Widget button = Semantics(
      button: true,
      label: tooltip ?? 'Action',
      tooltip: tooltip,
      excludeSemantics: true,
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.56),
                blurRadius: 22,
                spreadRadius: -2,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: accentColor.withValues(alpha: 0.28),
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
                decoration: BoxDecoration(
                  color: const Color(0xD90B101C),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.68),
                    width: 1.3,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: const [0.0, 0.48, 1.0],
                    colors: [
                      accentColor.withValues(alpha: 0.30),
                      const Color(0x22FFFFFF),
                      const Color(0x0B0F19),
                    ],
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: 0,
                      left: 10,
                      right: 10,
                      height: 1.2,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(alpha: 0.65),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Icon(
                      icon,
                      size: 26,
                      color: accentColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return FloatingActionButton(
      heroTag: heroTag,
      onPressed: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      tooltip: tooltip,
      backgroundColor: Colors.transparent,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      disabledElevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: button,
    );
  }
}

/// Drop-in standardized Crystal Glass AppBar for all inner screens.
///
/// Automatically provides [CrystalBackButton] in `leading`, appends
/// [CrystalHomeButton] to `actions` (when [showHomeButton] is true), and renders
/// [CrystalHeaderStageBar] in `flexibleSpace` so the stage backdrop extends behind
/// the top header with 100% occlusion against route bleed-through.
class CrystalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final String? titleText;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? flexibleSpace;
  final VoidCallback? onBackPressed;
  final String fallbackRoute;
  final bool showBackButton;
  final bool showHomeButton;
  final bool centerTitle;
  final Color backgroundColor;
  final double elevation;

  const CrystalAppBar({
    super.key,
    this.title,
    this.titleText,
    this.actions,
    this.bottom,
    this.flexibleSpace,
    this.onBackPressed,
    this.fallbackRoute = '/home',
    this.showBackButton = true,
    this.showHomeButton = true,
    this.centerTitle = false,
    this.backgroundColor = Colors.transparent,
    this.elevation = 0,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );

  @override
  Widget build(BuildContext context) {
    final bool isInsideShell = MainShellScope.isInsideShell(context);
    final Widget? resolvedLeading = !showBackButton || isInsideShell
        ? null
        : CrystalBackButton(
            onPressed: onBackPressed,
            fallbackRoute: fallbackRoute,
          );

    final List<Widget> resolvedActions = <Widget>[
      if (actions != null) ...actions!,
      if (showHomeButton && !isInsideShell) const CrystalHomeButton(),
    ];

    return AppBar(
      backgroundColor: backgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: elevation,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      leading: resolvedLeading,
      flexibleSpace: flexibleSpace ?? const CrystalHeaderStageBar(),
      title: title ??
          (titleText != null
              ? Text(
                  titleText!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppTheme.textPure,
                  ),
                )
              : null),
      actions: resolvedActions,
      bottom: bottom,
    );
  }
}
