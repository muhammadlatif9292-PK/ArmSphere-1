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
/// Upgraded to ArmSphere Crystal Glassmorphism Design System:
/// - Compact floating crystal dock with optical backdrop blur (`sigma: 28`).
/// - Crisp specular rim highlight and refractive crimson active tab capsule.
/// - Restricted strictly to the 5 primary root tab destinations.
/// - Smoothly auto-hides when scrolling down and reveals when scrolling up.
class MainShellScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  /// Canonical root tab paths where the bottom navigation dock is permitted to appear.
  static const Set<String> kRootTabPaths = <String>{
    '/home',
    '/discover',
    '/tournaments',
    '/community/feed',
    '/athlete/profile',
    // Test harness root tab aliases:
    '/arena',
    '/events',
    '/community',
    '/passport',
  };

  const MainShellScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  bool _isDockVisible = true;
  double _scrollDeltaAccumulator = 0.0;

  @override
  void didUpdateWidget(covariant MainShellScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigationShell.currentIndex != widget.navigationShell.currentIndex) {
      _isDockVisible = true;
      _scrollDeltaAccumulator = 0.0;
    }
  }

  bool _isRootTabRoute(BuildContext context) {
    String? uriPath;
    try {
      uriPath = GoRouterState.of(context).uri.path;
    } catch (_) {
      final router = GoRouter.maybeOf(context);
      uriPath = router?.routeInformationProvider.value.uri.path;
    }
    if (uriPath == null || uriPath.isEmpty) {
      return true;
    }
    final normalized = uriPath.length > 1 && uriPath.endsWith('/')
        ? uriPath.substring(0, uriPath.length - 1)
        : uriPath;
    return MainShellScreen.kRootTabPaths.contains(normalized);
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }

    // Always reveal the dock when at or near the top of the scroll view.
    if (notification.metrics.pixels <= 16.0) {
      _scrollDeltaAccumulator = 0.0;
      if (!_isDockVisible) {
        setState(() => _isDockVisible = true);
      }
      return false;
    }

    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0.0;
      if ((delta > 0 && _scrollDeltaAccumulator < 0) ||
          (delta < 0 && _scrollDeltaAccumulator > 0)) {
        _scrollDeltaAccumulator = 0.0;
      }
      _scrollDeltaAccumulator += delta;

      // Scrolling down past threshold -> auto-hide dock
      if (_scrollDeltaAccumulator > 10.0 &&
          notification.metrics.pixels > 24.0 &&
          _isDockVisible) {
        _scrollDeltaAccumulator = 0.0;
        setState(() => _isDockVisible = false);
      } else if (_scrollDeltaAccumulator < -8.0 && !_isDockVisible) {
        // Scrolling up -> reveal dock
        _scrollDeltaAccumulator = 0.0;
        setState(() => _isDockVisible = true);
      }
    }
    return false;
  }

  void _onTap(BuildContext context, int index) {
    if (index != widget.navigationShell.currentIndex) {
      HapticFeedback.selectionClick();
    }
    if (!_isDockVisible) {
      setState(() {
        _isDockVisible = true;
        _scrollDeltaAccumulator = 0.0;
      });
    }
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isRootTab = _isRootTabRoute(context);
    final bool showDock = isRootTab && _isDockVisible;

    return MainShellScope(
      child: Scaffold(
        backgroundColor: AppTheme.voidBackground,
        extendBody: true,
        body: NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: Stack(
            children: [
              AmbientParticleBackground(tabIndex: widget.navigationShell.currentIndex),
              SafeArea(
                bottom: false,
                child: widget.navigationShell,
              ),
            ],
          ),
        ),
        bottomNavigationBar: !isRootTab
            ? null
            : IgnorePointer(
                ignoring: !showDock,
                child: AnimatedSlide(
                  key: const ValueKey('crystal_floating_nav_slide'),
                  offset: showDock ? Offset.zero : const Offset(0.0, 1.35),
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  child: AnimatedOpacity(
                    key: const ValueKey('crystal_floating_nav_opacity'),
                    opacity: showDock ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          18,
                          0,
                          18,
                          kFloatingDockBottomMargin,
                        ),
                        child: Container(
                          key: const ValueKey('crystal_floating_nav_dock'),
                          height: kFloatingDockHeight,
                          decoration: BoxDecoration(
                            color: const Color(0xB8080C15),
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: const Color(0x42FFFFFF),
                              width: 1.0,
                            ),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              stops: [0.0, 0.45, 1.0],
                              colors: [
                                Color(0x28FFFFFF),
                                Color(0x10FFFFFF),
                                Color(0x06FFFFFF),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.56),
                                offset: const Offset(0, 10),
                                blurRadius: 28,
                                spreadRadius: -2,
                              ),
                              BoxShadow(
                                color: AppTheme.crimson.withValues(alpha: 0.08),
                                offset: const Offset(0, 2),
                                blurRadius: 18,
                                spreadRadius: -4,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Top specular crystal rim reflection line
                                  Positioned(
                                    top: 0,
                                    left: 24,
                                    right: 24,
                                    height: 1.0,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withValues(alpha: 0.0),
                                            Colors.white.withValues(alpha: 0.55),
                                            Colors.white.withValues(alpha: 0.0),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Row(
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
                                ],
                              ),
                            ),
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
    final isSelected = widget.navigationShell.currentIndex == index;
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
                      ? activeColor.withValues(alpha: 0.16)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? activeColor.withValues(alpha: 0.45)
                        : Colors.transparent,
                    width: 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.28),
                            blurRadius: 12,
                            spreadRadius: -2,
                          ),
                        ]
                      : null,
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
