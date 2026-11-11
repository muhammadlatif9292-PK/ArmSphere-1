import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/asset_paths.dart';
import '../theme/app_theme.dart';
import 'armsphere_image.dart';
import 'tactical_command_sheet.dart';
import 'tactile_press_wrapper.dart';

/// Full-Bleed 9:16 Domain Stage Scaffold ("Void & Titanium" Family)
///
/// Renders any of the 13 canonical 9:16 domain stage `.webp` artworks as an
/// atmospheric backdrop with a calibrated 4-stop vertical scrim (`stops: [0.0, 0.35, 0.70, 1.0]`)
/// and `extendBodyBehindAppBar: true`.
class VoidStageScaffold extends StatelessWidget {
  final String? backgroundAsset;
  final String? stageAsset;
  final Alignment focalAlignment;
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? child;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final bool extendBodyBehindAppBar;
  final bool extendBody;
  final bool? resizeToAvoidBottomInset;
  final List<double> scrimStops;
  final List<Color>? scrimColors;

  const VoidStageScaffold({
    super.key,
    this.backgroundAsset,
    this.stageAsset,
    this.focalAlignment = Alignment.topCenter,
    this.appBar,
    this.body,
    this.child,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.extendBodyBehindAppBar = true,
    this.extendBody = true,
    this.resizeToAvoidBottomInset,
    this.scrimStops = const [0.0, 0.36, 0.62, 1.0],
    this.scrimColors,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAsset =
        stageAsset ?? backgroundAsset ?? ArmSphereAssets.stageArena9x16;
    final effectiveBody = body ?? child ?? const SizedBox.shrink();
    final effectiveScrimColors = scrimColors ??
        const [
          Color(0x00070A11), // 0% opacity — 100% crystal-clear top 3D showcase
          Color(0x14070A11), // 8% opacity — subtle transition
          Color(0xBF070A11), // 75% opacity — smooth text-readability anchor
          Color(0xF5070A11), // 96% opacity — deep pitch-black obsidian UI floor
        ];

    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      extendBody: extendBody,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: ArmSphereImage(
              assetPath: effectiveAsset,
              alignment: focalAlignment,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              fallbackAsset: ArmSphereAssets.stageArena9x16,
              excludeFromSemantics: true,
              showLoadingIndicator: false,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: scrimStops,
                  colors: effectiveScrimColors,
                ),
              ),
            ),
          ),
          SafeArea(
            top: appBar != null ? extendBodyBehindAppBar : true,
            bottom: false,
            child: effectiveBody,
          ),
        ],
      ),
    );
  }

  /// Standard bottom clearance (112dp + safe area bottom inset) so scrollable
  /// lists clear the floating smoked-glass pill dock without occlusion.
  static double bottomClearance(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom + 112.0;
}

/// Global helper for floating navigation dock bottom clearance.
double mainShellBottomClearance(BuildContext context) =>
    MediaQuery.paddingOf(context).bottom + 112.0;

/// Standardized ArmSphere Top AppBar for VoidStageScaffold Screens
///
/// Supports both `String` and `Widget` for [title], and includes an integrated
/// 1-tap Tactical Command Hub launcher button so every feature and management
/// workflow is reachable in one tap from any screen.
class ArmSphereAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Object? title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;
  final bool automaticallyImplyLeading;
  final double? titleSpacing;
  final double? toolbarHeight;
  final Color? backgroundColor;
  final bool showCommandTrigger;

  const ArmSphereAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.bottom,
    this.centerTitle = false,
    this.automaticallyImplyLeading = true,
    this.titleSpacing,
    this.toolbarHeight,
    this.backgroundColor,
    this.showCommandTrigger = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        (toolbarHeight ?? kToolbarHeight) + (bottom?.preferredSize.height ?? 0.0),
      );

  Widget? _buildTitleWidget() {
    if (title == null) return null;
    final Widget primaryTitle = title is Widget
        ? (title as Widget)
        : Text(
            title.toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppTheme.textPrimary,
              letterSpacing: 0.3,
            ),
          );

    if (subtitle == null) {
      return primaryTitle;
    }

    return Column(
      crossAxisAlignment:
          centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        primaryTitle,
        Text(
          subtitle!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: AppTheme.fontBody,
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> effectiveActions = [
      if (actions != null) ...actions!,
      if (showCommandTrigger)
        IconButton(
          tooltip: 'Tactical Command Hub',
          onPressed: () => TacticalCommandSheet.show(context),
          icon: const Icon(
            Icons.grid_view_rounded,
            size: 18,
            color: AppTheme.goldPrimary,
          ),
        ),
    ];

    return AppBar(
      backgroundColor: backgroundColor ?? Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      titleSpacing: titleSpacing,
      toolbarHeight: toolbarHeight,
      leading: leading,
      actions: effectiveActions,
      bottom: bottom,
      title: _buildTitleWidget(),
    );
  }
}

/// Invisible Floating Interactive Container (replaces opaque SmokedGlassCard)
class SmokedGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;
  final String? semanticLabel;

  const SmokedGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
    this.borderRadius = 16.0,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    Widget container = Container(
      margin: margin,
      padding: padding,
      color: Colors.transparent,
      child: child,
    );

    if (onTap != null) {
      return TactilePressWrapper(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap!();
        },
        semanticLabel: semanticLabel,
        child: container,
      );
    }

    return container;
  }
}
