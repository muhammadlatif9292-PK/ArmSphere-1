import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import 'main_shell_screen.dart';

/// Unified Crystal Glassmorphism 38x38dp visual capsule for top-bar navigation icons.
class CrystalNavCapsuleIcon extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final Color iconColor;
  final Color? accentBorderColor;

  const CrystalNavCapsuleIcon({
    super.key,
    required this.icon,
    this.iconSize = 17.0,
    this.iconColor = AppTheme.textPure,
    this.accentBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.48, 1.0],
          colors: [
            Color(0x28FFFFFF),
            Color(0x12FFFFFF),
            Color(0x08FFFFFF),
          ],
        ),
        border: Border.all(
          color: accentBorderColor ?? const Color(0x42FFFFFF),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.38),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Center(
            child: Icon(
              icon,
              size: iconSize,
              color: iconColor,
            ),
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
/// safe fallback navigation to `/home` when the navigation stack cannot pop.
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
    if (router != null) {
      if (router.canPop()) {
        router.pop();
      } else {
        router.go(fallbackRoute);
      }
      return;
    }
    final nav = Navigator.maybeOf(context);
    if (nav != null && nav.canPop()) {
      nav.pop();
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
    this.tooltip = 'Back to Arena',
  });

  void _handlePress(BuildContext context) {
    HapticFeedback.selectionClick();
    if (onPressed != null) {
      onPressed!();
      return;
    }
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.go(homeRoute);
      return;
    }
    final nav = Navigator.maybeOf(context);
    if (nav != null) {
      nav.popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6, left: 2),
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
                    accentBorderColor: AppTheme.crimson.withValues(alpha: 0.45),
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

/// Drop-in standardized Crystal Glass AppBar for all inner screens.
///
/// Automatically provides [CrystalBackButton] in `leading` and appends
/// [CrystalHomeButton] to `actions` (when [showHomeButton] is true), ensuring
/// 100% consistent top navigation geometry and behavior across ArmSphere.
class CrystalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final String? titleText;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
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
      title: title ??
          (titleText != null
              ? Text(
                  titleText!,
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
