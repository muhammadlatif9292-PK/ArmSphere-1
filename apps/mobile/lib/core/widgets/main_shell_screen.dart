import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_particle_background.dart';

/// Dimensions and footprint metrics for the floating bottom navigation dock.
const double kFloatingDockHeight = 64.0;
const double kFloatingDockBottomMargin = 12.0;

/// Total vertical height of the floating dock including its bottom margin (76.0 dp).
const double kFloatingDockTotalHeight = kFloatingDockHeight + kFloatingDockBottomMargin;

/// Calculates dynamic bottom clearance for scrollable views inside or outside [MainShellScreen].
///
/// If inside the shell: returns `kFloatingDockTotalHeight + safeArea.bottom + additionalPadding`.
/// If outside the shell: returns `safeArea.bottom + additionalPadding`.
double mainShellBottomClearance(BuildContext context, {double additionalPadding = 16.0}) {
  return MainShellScope.bottomClearance(context, additionalPadding: additionalPadding);
}

/// A [FloatingActionButtonLocation] that positions the button safely above the floating dock.
/// It delegates horizontal alignment to [FloatingActionButtonLocation.endFloat] and offsets
/// the vertical coordinate upward by [bottomOffset] (default: [kFloatingDockTotalHeight]).
class DockAwareEndFloatLocation extends FloatingActionButtonLocation {
  final double bottomOffset;

  const DockAwareEndFloatLocation({this.bottomOffset = kFloatingDockTotalHeight});

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX = FloatingActionButtonLocation.endFloat.getOffset(scaffoldGeometry).dx;
    final double fabY = FloatingActionButtonLocation.endFloat.getOffset(scaffoldGeometry).dy - bottomOffset;
    return Offset(fabX, fabY);
  }
}

/// Scope provided by [MainShellScreen] to inform descendant screens and widgets
/// of the floating navigation dock's dimensions and clearance requirements.
class MainShellScope extends InheritedWidget {
  static const double kShellClearance = kFloatingDockTotalHeight;

  final double dockHeight;
  final double dockBottomMargin;

  const MainShellScope({
    super.key,
    this.dockHeight = kFloatingDockHeight,
    this.dockBottomMargin = kFloatingDockBottomMargin,
    required super.child,
  });

  static MainShellScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MainShellScope>();
  }

  static bool isInsideShell(BuildContext context) {
    return maybeOf(context) != null;
  }

  /// Calculates dynamic bottom clearance for scrollable views.
  ///
  /// - If inside [MainShellScreen]: returns `dockHeight + dockBottomMargin + safeArea.bottom + additionalPadding`.
  /// - If outside the shell: returns `safeArea.bottom + additionalPadding`.
  static double bottomClearance(BuildContext context, {double additionalPadding = 16.0}) {
    final scope = maybeOf(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    if (scope != null) {
      return scope.dockHeight + scope.dockBottomMargin + bottomInset + additionalPadding;
    }
    return bottomInset + additionalPadding;
  }

  /// Returns a [FloatingActionButtonLocation] that lifts the button above the floating dock
  /// when rendered inside [MainShellScreen], or defaults to [FloatingActionButtonLocation.endFloat]
  /// when viewed outside the shell.
  static FloatingActionButtonLocation fabLocation(BuildContext context, {double extraOffset = 0.0}) {
    if (isInsideShell(context)) {
      return DockAwareEndFloatLocation(bottomOffset: kFloatingDockTotalHeight + extraOffset);
    }
    return FloatingActionButtonLocation.endFloat;
  }

  @override
  bool updateShouldNotify(MainShellScope oldWidget) =>
      dockHeight != oldWidget.dockHeight || dockBottomMargin != oldWidget.dockBottomMargin;
}

/// Primary Navigation Shell for ArmSphere
///
/// Upgraded to ArmSphere Titanium Glass Master Design System:
/// - Floating smoked optical glass navigation dock with backdrop diffusion.
/// - Machined titanium rim borders and top specular reflection sheen.
/// - Tactile haptic feedback and competition crimson/cyan active states.
class MainShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellScreen({
    super.key,
    required this.navigationShell,
  });

  void _onTap(BuildContext context, int index) {
    if (index != navigationShell.currentIndex) {
      HapticFeedback.selectionClick();
    }
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainShellScope(
      child: Scaffold(
        backgroundColor: AppTheme.voidBackground,
        extendBody: true,
        body: Stack(
          children: [
            const AmbientParticleBackground(),
            SafeArea(
              bottom: false,
              child: navigationShell,
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, kFloatingDockBottomMargin),
            child: Container(
              height: kFloatingDockHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                AppTheme.glassDockShadow(),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.glassSurfaceHeavy,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.borderTitanium,
                      width: 1.0,
                    ),
                    gradient: const LinearGradient(
                      // Vertical (left/right symmetric) sheen: a diagonal one
                      // lightened only the first two tabs and cut their
                      // inactive-label contrast to ~2.6:1.
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0, 0.30, 1.0],
                      colors: [
                        Color(0x1AFFFFFF), // Specular reflection sheen
                        Color(0xB3151B24),
                        Color(0x0A000000),
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        context,
                        index: 0,
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home_rounded,
                        label: 'Arena',
                      ),
                      _buildNavItem(
                        context,
                        index: 1,
                        icon: Icons.travel_explore_outlined,
                        activeIcon: Icons.travel_explore_rounded,
                        label: 'Discover',
                      ),
                      _buildNavItem(
                        context,
                        index: 2,
                        icon: Icons.emoji_events_outlined,
                        activeIcon: Icons.emoji_events_rounded,
                        label: 'Events',
                      ),
                      _buildNavItem(
                        context,
                        index: 3,
                        icon: Icons.forum_outlined,
                        activeIcon: Icons.forum_rounded,
                        label: 'Community',
                      ),
                      _buildNavItem(
                        context,
                        index: 4,
                        icon: Icons.person_outline_rounded,
                        activeIcon: Icons.person_rounded,
                        label: 'Passport',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = navigationShell.currentIndex == index;
    // Owner directive: crimson is the single active-navigation accent for all
    // five tabs. Gold stays reserved for championship/achievement cues.
    const activeColor = AppTheme.crimson;

    return Expanded(
      child: Semantics(
        container: true,
        button: true,
        selected: isSelected,
        label: '$label tab',
        tooltip: label,
        onTap: () => _onTap(context, index),
        // The visible icon/label are replaced by the single label above so
        // screen readers do not announce the tab twice.
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _onTap(context, index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                // Border is always present (transparent when idle) so the
                // label does not shift 2dp down when a tab becomes active.
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? activeColor.withValues(alpha: 0.35)
                        : Colors.transparent,
                    width: 1.0,
                  ),
                ),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  size: 22,
                  color: isSelected ? activeColor : AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 3),
              // Fixed-height dock: cap label scaling at 1.3x and shrink a
              // too-wide label to fit rather than showing "Communi...".
              // The tab's semantics label/tooltip carry the full name.
              MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.3,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 10.5,
                      // SpaceGrotesk bundles w400-w700 only; w800 would be synthesized.
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      letterSpacing: 0.3,
                      // Crimson text on the dock is ~4.06:1 (< 4.5:1 AA), so the
                      // active label uses titanium white; crimson stays on icon + pill.
                      color:
                          isSelected ? AppTheme.textPrimary : AppTheme.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
