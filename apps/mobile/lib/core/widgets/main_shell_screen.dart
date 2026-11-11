import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../constants/asset_paths.dart';
import '../security/admin_permissions.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_particle_background.dart';

/// Dimensions and footprint metrics for the floating bottom navigation dock.
const double kFloatingDockHeight = 64.0;
const double kFloatingDockBottomMargin = 12.0;

/// Total vertical height of the floating dock including its bottom margin (76.0 dp).
const double kFloatingDockTotalHeight =
    kFloatingDockHeight + kFloatingDockBottomMargin;

/// Calculates dynamic bottom clearance for scrollable views inside or outside [MainShellScreen].
///
/// If inside the shell: returns `kFloatingDockTotalHeight + safeArea.bottom + additionalPadding`.
/// If outside the shell: returns `safeArea.bottom + additionalPadding`.
double mainShellBottomClearance(
  BuildContext context, {
  double additionalPadding = 44.0,
}) {
  return MainShellScope.bottomClearance(
    context,
    additionalPadding: additionalPadding,
  );
}

/// A [FloatingActionButtonLocation] that positions the button safely above the floating dock.
/// It delegates horizontal alignment to [FloatingActionButtonLocation.endFloat] and offsets
/// the vertical coordinate upward by [bottomOffset] (default: [kFloatingDockTotalHeight]).
class DockAwareEndFloatLocation extends FloatingActionButtonLocation {
  final double bottomOffset;

  const DockAwareEndFloatLocation({
    this.bottomOffset = kFloatingDockTotalHeight,
  });

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX =
        FloatingActionButtonLocation.endFloat.getOffset(scaffoldGeometry).dx;
    final double fabY =
        FloatingActionButtonLocation.endFloat.getOffset(scaffoldGeometry).dy -
            bottomOffset;
    return Offset(fabX, fabY);
  }
}

/// Scope provided by [MainShellScreen] to inform descendant screens and widgets
/// of the floating navigation dock's dimensions, active tab state, and
/// chronological step-by-step tab navigation controls.
class MainShellScope extends InheritedWidget {
  static const double kShellClearance = kFloatingDockTotalHeight;

  final double dockHeight;
  final double dockBottomMargin;
  final bool isRootTab;
  final int activeTabIndex;
  final bool canStepBackTab;
  final ValueChanged<int>? onNavigateToTab;
  final bool Function()? onStepBackTab;

  const MainShellScope({
    super.key,
    this.dockHeight = kFloatingDockHeight,
    this.dockBottomMargin = kFloatingDockBottomMargin,
    this.isRootTab = true,
    this.activeTabIndex = 0,
    this.canStepBackTab = false,
    this.onNavigateToTab,
    this.onStepBackTab,
    required super.child,
  });

  static MainShellScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MainShellScope>();
  }

  static bool isInsideShell(BuildContext context) {
    final scope = maybeOf(context);
    return scope != null && scope.isRootTab;
  }

  /// Navigates to one of the 5 canonical main tabs (`0..4`), highlighting it on
  /// the bottom navigation dock, recording the current tab in chronological
  /// back history, and resetting scroll offset to the top.
  static void goToMainTab(BuildContext context, int tabIndex) {
    final clamped = tabIndex.clamp(0, 4);
    final scope = maybeOf(context);
    if (scope?.onNavigateToTab != null) {
      scope!.onNavigateToTab!(clamped);
      return;
    }
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.go(MainShellScreen.pathForTabIndex(clamped));
    }
  }

  /// Navigates to a main tab by its route path (e.g., `'/athlete/profile'`,
  /// `'/discover'`, `'/tournaments'`, `'/community/feed'`, `'/home'`).
  /// Returns `true` if [path] matched one of the 5 main tabs.
  static bool goToMainTabByPath(BuildContext context, String path) {
    final tabIndex = MainShellScreen.tabIndexForPath(path);
    if (tabIndex == null) return false;
    goToMainTab(context, tabIndex);
    return true;
  }

  /// Steps back one entry in the shell's chronological tab history stack if available.
  static bool stepBackIfPossible(BuildContext context) {
    final scope = maybeOf(context);
    if (scope?.onStepBackTab != null) {
      return scope!.onStepBackTab!();
    }
    return false;
  }

  /// Calculates dynamic bottom clearance for scrollable views.
  ///
  /// - If inside [MainShellScreen] on a root tab: returns `dockHeight + dockBottomMargin + safeArea.bottom + additionalPadding`.
  /// - If outside the shell or on a non-root route: returns `safeArea.bottom + additionalPadding`.
  static double bottomClearance(
    BuildContext context, {
    double additionalPadding = 44.0,
  }) {
    final scope = maybeOf(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    if (scope != null && scope.isRootTab) {
      return scope.dockHeight +
          scope.dockBottomMargin +
          bottomInset +
          additionalPadding;
    }
    return bottomInset + additionalPadding;
  }

  /// Returns a [FloatingActionButtonLocation] that lifts the button above the floating dock
  /// when rendered inside [MainShellScreen], or defaults to [FloatingActionButtonLocation.endFloat]
  /// when viewed outside the shell.
  static FloatingActionButtonLocation fabLocation(
    BuildContext context, {
    double extraOffset = 0.0,
  }) {
    if (isInsideShell(context)) {
      return DockAwareEndFloatLocation(
        bottomOffset: kFloatingDockTotalHeight + extraOffset,
      );
    }
    return FloatingActionButtonLocation.endFloat;
  }

  @override
  bool updateShouldNotify(MainShellScope oldWidget) =>
      dockHeight != oldWidget.dockHeight ||
      dockBottomMargin != oldWidget.dockBottomMargin ||
      isRootTab != oldWidget.isRootTab ||
      activeTabIndex != oldWidget.activeTabIndex ||
      canStepBackTab != oldWidget.canStepBackTab;
}

/// Primary Navigation Shell for ArmSphere
///
/// Upgraded to ArmSphere Crystal Glassmorphism Design System:
/// - Compact floating crystal dock with optical backdrop blur (`sigma: 28`).
/// - Crisp specular rim highlight and refractive crimson active tab capsule.
/// - Restricted strictly to the 5 primary root tab destinations.
/// - Auto-highlights the corresponding tab whenever any main screen is opened from anywhere.
/// - Tracks chronological tab visit history so pressing Back steps backward one screen at a time.
/// - Resets scroll position to the top (`0.0`) whenever shifting tabs or opening a screen.
class MainShellScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  final bool? isAdminModeOverride;

  /// Canonical root tab paths where the bottom navigation dock is permitted to appear.
  static const Set<String> kRootTabPaths = <String>{
    '/home',
    '/discover',
    '/tournaments',
    '/community/feed',
    '/athlete/profile',
    // Test harness & secondary alias root tab paths:
    '/arena',
    '/events',
    '/community',
    '/passport',
    '/profile',
  };

  /// Maps any canonical root tab path to its `0..4` bottom dock index.
  static int? tabIndexForPath(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return null;
    final clean = normalizePath(rawPath);
    switch (clean) {
      case '/home':
      case '/arena':
      case '/athlete/dashboard':
        return 0;
      case '/discover':
        return 1;
      case '/tournaments':
      case '/events':
      case '/tournament/dashboard':
        return 2;
      case '/community/feed':
      case '/community':
        return 3;
      case '/athlete/profile':
      case '/passport':
      case '/profile':
        return 4;
      default:
        return null;
    }
  }

  /// Returns the canonical primary route path for a `0..4` tab index.
  static String pathForTabIndex(int index) {
    switch (index) {
      case 0:
        return '/home';
      case 1:
        return '/discover';
      case 2:
        return '/tournaments';
      case 3:
        return '/community/feed';
      case 4:
        return '/athlete/profile';
      default:
        return '/home';
    }
  }

  static String normalizePath(String path) {
    if (path.isEmpty) return '/';
    final qIndex = path.indexOf('?');
    final clean = qIndex >= 0 ? path.substring(0, qIndex) : path;
    if (clean.length > 1 && clean.endsWith('/')) {
      return clean.substring(0, clean.length - 1);
    }
    return clean;
  }

  const MainShellScreen({
    super.key,
    required this.navigationShell,
    this.isAdminModeOverride,
  });

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  bool _isDockVisible = true;
  double _scrollDeltaAccumulator = 0.0;
  RouteInformationProvider? _routeInfoProvider;
  RouterDelegate<Object>? _routerDelegate;

  /// Chronological stack of previously visited root tab indices (`0..4`).
  final List<int> _tabHistory = <int>[];
  late int _lastRecordedTabIndex;
  String? _lastObservedTopPath;
  bool? _lastObservedAdminMode;
  bool _isSteppingBackTab = false;
  bool _isRedirectingPushedTab = false;
  bool _didPrecacheStageAssets = false;

  static const List<String> _kStartupPrecacheAssets = <String>[
    ArmSphereAssets.stageArena,
    ArmSphereAssets.stageDiscover,
    ArmSphereAssets.stageChampionshipBelts,
    ArmSphereAssets.stageCommunity,
    ArmSphereAssets.stagePassportVault,
    ArmSphereAssets.stageReferee,
    ArmSphereAssets.stageAdminGovernance,
    ArmSphereAssets.stageAuthWalkout,
    ArmSphereAssets.athleteDashboardHero,
    ArmSphereAssets.arenaRadarCard,
    ArmSphereAssets.cardStandbyTable,
    ArmSphereAssets.avatarNeutralDark,
    ArmSphereAssets.teamCrestDefault,
  ];

  void _precachePrimaryAssets() {
    if (_didPrecacheStageAssets) return;
    _didPrecacheStageAssets = true;
    for (final path in _kStartupPrecacheAssets) {
      precacheImage(AssetImage(path), context).catchError((_) {});
    }
  }

  bool _resolveIsAdminMode(BuildContext context) {
    if (widget.isAdminModeOverride != null) {
      return widget.isAdminModeOverride!;
    }
    try {
      final container = ProviderScope.containerOf(context);
      final authState = container.read(authProvider);
      final profileRole = authState.userProfile?['role']?.toString();
      final effectiveRole = authState.activeRole ??
          (authState.verifiedRoles.length == 1
              ? authState.verifiedRoles.first
              : (profileRole ?? 'ATHLETE'));
      return AdminPermissions.isAdminWorkspaceRole(effectiveRole);
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _lastRecordedTabIndex = widget.navigationShell.currentIndex;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precachePrimaryAssets();
    final router = GoRouter.maybeOf(context);
    final newInfoProvider = router?.routeInformationProvider;
    final newDelegate = router?.routerDelegate;
    if (_routeInfoProvider != newInfoProvider) {
      _routeInfoProvider?.removeListener(_onRouteChanged);
      _routeInfoProvider = newInfoProvider;
      _routeInfoProvider?.addListener(_onRouteChanged);
    }
    if (_routerDelegate != newDelegate) {
      _routerDelegate?.removeListener(_onRouteChanged);
      _routerDelegate = newDelegate;
      _routerDelegate?.addListener(_onRouteChanged);
    }
    _lastObservedTopPath ??= _resolveTopRoutePath(context);
  }

  @override
  void dispose() {
    _routeInfoProvider?.removeListener(_onRouteChanged);
    _routerDelegate?.removeListener(_onRouteChanged);
    super.dispose();
  }

  void _onRouteChanged() {
    if (!mounted) return;
    final String topPath = _resolveTopRoutePath(context);
    final bool pathChanged = topPath != _lastObservedTopPath;
    _lastObservedTopPath = topPath;

    final int? pathTabIdx = MainShellScreen.tabIndexForPath(topPath);

    // If a main tab route (e.g. '/athlete/profile', '/discover', '/tournaments')
    // was imperatively pushed on top of a different shell branch via context.push(),
    // pop the duplicate pushed route and switch the shell branch cleanly so the
    // bottom navigation dock highlights the target tab and history is preserved.
    if (pathTabIdx != null &&
        pathTabIdx != widget.navigationShell.currentIndex &&
        !_isRedirectingPushedTab) {
      final router = GoRouter.maybeOf(context);
      bool canPopSafely = false;
      try {
        canPopSafely = router != null && router.canPop();
      } catch (_) {
        canPopSafely = false;
      }
      if (canPopSafely) {
        _isRedirectingPushedTab = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          try {
            try {
              if (router?.canPop() ?? false) {
                router?.pop();
              }
            } catch (_) {}
            _navigateToTabInternal(pathTabIdx, recordHistory: true);
          } finally {
            _isRedirectingPushedTab = false;
          }
        });
      }
    }

    if (pathChanged) {
      _isDockVisible = true;
      _scrollDeltaAccumulator = 0.0;
      _resetScrollPositionsToTop();
    }

    setState(() {});
  }

  @override
  void didUpdateWidget(covariant MainShellScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final int newIndex = widget.navigationShell.currentIndex;
    if (oldWidget.navigationShell.currentIndex != newIndex) {
      if (!_isSteppingBackTab && _lastRecordedTabIndex != newIndex) {
        if (_tabHistory.isEmpty || _tabHistory.last != _lastRecordedTabIndex) {
          _tabHistory.add(_lastRecordedTabIndex);
        }
      }
      _lastRecordedTabIndex = newIndex;
      _isDockVisible = true;
      _scrollDeltaAccumulator = 0.0;
      _resetScrollPositionsToTop();
    }
  }

  /// Walks the descendant element tree and resets all active vertical
  /// [ScrollPosition]s to offset `0.0` so newly opened or switched tabs always
  /// start cleanly at the top.
  void _resetScrollPositionsToTop() {
    if (!mounted) return;
    void visitor(Element element) {
      if (element is StatefulElement && element.state is ScrollableState) {
        final scrollableState = element.state as ScrollableState;
        final position = scrollableState.position;
        if (position.axis == Axis.vertical &&
            position.hasPixels &&
            position.pixels > 0.0) {
          try {
            position.jumpTo(0.0);
          } catch (_) {}
        }
      }
      element.visitChildren(visitor);
    }

    try {
      final primary = PrimaryScrollController.maybeOf(context);
      if (primary != null && primary.hasClients) {
        for (final pos in primary.positions) {
          if (pos.axis == Axis.vertical && pos.hasPixels && pos.pixels > 0.0) {
            try {
              pos.jumpTo(0.0);
            } catch (_) {}
          }
        }
      }
      context.visitChildElements(visitor);
    } catch (_) {}
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final primary = PrimaryScrollController.maybeOf(context);
        if (primary != null && primary.hasClients) {
          for (final pos in primary.positions) {
            if (pos.axis == Axis.vertical && pos.hasPixels && pos.pixels > 0.0) {
              try {
                pos.jumpTo(0.0);
              } catch (_) {}
            }
          }
        }
        context.visitChildElements(visitor);
      } catch (_) {}
    });
  }

  /// Resolves the top-most active route path, prioritizing
  /// `routerDelegate.currentConfiguration.last.matchedLocation` so imperative
  /// `context.push(...)` routes (like `/notifications` or `/athlete/:id/training-log`)
  /// are accurately detected instead of being masked by `routeInformationProvider`.
  String _resolveTopRoutePath(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      try {
        final config = router.routerDelegate.currentConfiguration;
        if (config.isNotEmpty) {
          final lastMatched = config.last.matchedLocation;
          if (lastMatched.isNotEmpty) {
            return MainShellScreen.normalizePath(lastMatched);
          }
        }
        final configUriPath = config.uri.path;
        if (configUriPath.isNotEmpty) {
          return MainShellScreen.normalizePath(configUriPath);
        }
      } catch (_) {}
      try {
        final infoPath = router.routeInformationProvider.value.uri.path;
        if (infoPath.isNotEmpty) {
          return MainShellScreen.normalizePath(infoPath);
        }
      } catch (_) {}
    }
    try {
      final statePath = GoRouterState.of(context).uri.path;
      if (statePath.isNotEmpty) {
        return MainShellScreen.normalizePath(statePath);
      }
    } catch (_) {}
    return '/home';
  }

  bool _isRootTabRoute(BuildContext context) {
    final topPath = _resolveTopRoutePath(context);
    return MainShellScreen.kRootTabPaths.contains(topPath);
  }

  int _resolveEffectiveTabIndex(BuildContext context) {
    final topPath = _resolveTopRoutePath(context);
    return MainShellScreen.tabIndexForPath(topPath) ??
        widget.navigationShell.currentIndex;
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
      // Only auto-hide or reveal on user drag gestures, never on programmatic jumpTo
      if (notification.dragDetails == null) {
        return false;
      }
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

  void _navigateToTabInternal(int index, {required bool recordHistory}) {
    final int currentIdx = widget.navigationShell.currentIndex;
    if (recordHistory && index != currentIdx) {
      if (_tabHistory.isEmpty || _tabHistory.last != currentIdx) {
        _tabHistory.add(currentIdx);
      }
    }
    _lastRecordedTabIndex = index;
    if (!_isDockVisible) {
      setState(() {
        _isDockVisible = true;
        _scrollDeltaAccumulator = 0.0;
      });
    } else {
      _scrollDeltaAccumulator = 0.0;
    }
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == currentIdx,
    );
    _resetScrollPositionsToTop();
  }

  /// Steps back one tab in `_tabHistory`. Returns `true` if a step back was performed.
  bool _stepBackTab() {
    final router = GoRouter.maybeOf(context);
    if (router != null && router.canPop()) {
      router.pop();
      return true;
    }
    if (_tabHistory.isNotEmpty) {
      final int previousTab = _tabHistory.removeLast();
      _isSteppingBackTab = true;
      try {
        HapticFeedback.selectionClick();
        _navigateToTabInternal(previousTab, recordHistory: false);
      } finally {
        _isSteppingBackTab = false;
      }
      setState(() {});
      return true;
    }
    if (widget.navigationShell.currentIndex != 0) {
      _isSteppingBackTab = true;
      try {
        HapticFeedback.selectionClick();
        _navigateToTabInternal(0, recordHistory: false);
      } finally {
        _isSteppingBackTab = false;
      }
      setState(() {});
      return true;
    }
    return false;
  }

  void _onTap(BuildContext context, int index) {
    if (index != widget.navigationShell.currentIndex) {
      HapticFeedback.selectionClick();
    }
    _navigateToTabInternal(index, recordHistory: true);
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdminMode = _resolveIsAdminMode(context);
    if (_lastObservedAdminMode != null &&
        _lastObservedAdminMode != isAdminMode) {
      _tabHistory.clear();
      _isDockVisible = true;
      _scrollDeltaAccumulator = 0.0;
      _resetScrollPositionsToTop();
    }
    _lastObservedAdminMode = isAdminMode;

    final bool isRootTab = _isRootTabRoute(context);
    final int effectiveTabIndex = _resolveEffectiveTabIndex(context);
    final bool showDock = isRootTab && _isDockVisible;
    final bool canInterceptBack =
        _tabHistory.isNotEmpty || widget.navigationShell.currentIndex != 0;

    return MainShellScope(
      isRootTab: isRootTab,
      activeTabIndex: effectiveTabIndex,
      canStepBackTab: canInterceptBack,
      onNavigateToTab: (index) =>
          _navigateToTabInternal(index, recordHistory: true),
      onStepBackTab: _stepBackTab,
      child: PopScope(
        canPop: !canInterceptBack,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            _stepBackTab();
          }
        },
        child: Scaffold(
          backgroundColor: AppTheme.voidBackground,
          extendBody: true,
          body: NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: Stack(
              children: [
                AmbientParticleBackground(
                  tabIndex: effectiveTabIndex,
                  isAdminMode: isAdminMode,
                ),
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
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: const Color(0x38FFFFFF),
                                width: 1.0,
                              ),
                              boxShadow: const [],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(27),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: isAdminMode
                                    ? [
                                        _buildNavItem(
                                          context,
                                          index: 0,
                                          activeTabIndex: effectiveTabIndex,
                                          icon: Icons.space_dashboard_outlined,
                                          activeIcon:
                                              Icons.space_dashboard_rounded,
                                          label: 'Command',
                                        ),
                                        _buildNavItem(
                                          context,
                                          index: 1,
                                          activeTabIndex: effectiveTabIndex,
                                          icon: Icons.badge_outlined,
                                          activeIcon: Icons.badge_rounded,
                                          label: 'Roster',
                                        ),
                                        _buildNavItem(
                                          context,
                                          index: 2,
                                          activeTabIndex: effectiveTabIndex,
                                          icon: Icons.emoji_events_outlined,
                                          activeIcon:
                                              Icons.emoji_events_rounded,
                                          label: 'Arena Ops',
                                        ),
                                        _buildNavItem(
                                          context,
                                          index: 3,
                                          activeTabIndex: effectiveTabIndex,
                                          icon: Icons.gavel_outlined,
                                          activeIcon: Icons.gavel_rounded,
                                          label: 'Governance',
                                        ),
                                        _buildNavItem(
                                          context,
                                          index: 4,
                                          activeTabIndex: effectiveTabIndex,
                                          icon: Icons
                                              .admin_panel_settings_outlined,
                                          activeIcon:
                                              Icons.admin_panel_settings_rounded,
                                          label: 'Dossier',
                                        ),
                                      ]
                                    : [
                                        _buildNavItem(
                                          context,
                                          index: 0,
                                          activeTabIndex: effectiveTabIndex,
                                          icon: Icons.home_outlined,
                                          activeIcon: Icons.home_rounded,
                                          label: 'Arena',
                                        ),
                                        _buildNavItem(
                                          context,
                                          index: 1,
                                          activeTabIndex: effectiveTabIndex,
                                          icon: Icons.travel_explore_outlined,
                                          activeIcon:
                                              Icons.travel_explore_rounded,
                                          label: 'Discover',
                                        ),
                                        _buildNavItem(
                                          context,
                                          index: 2,
                                          activeTabIndex: effectiveTabIndex,
                                          icon: Icons.emoji_events_outlined,
                                          activeIcon:
                                              Icons.emoji_events_rounded,
                                          label: 'Events',
                                        ),
                                        _buildNavItem(
                                          context,
                                          index: 3,
                                          activeTabIndex: effectiveTabIndex,
                                          icon: Icons.forum_outlined,
                                          activeIcon: Icons.forum_rounded,
                                          label: 'Community',
                                        ),
                                        _buildNavItem(
                                          context,
                                          index: 4,
                                          activeTabIndex: effectiveTabIndex,
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
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required int activeTabIndex,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = activeTabIndex == index;

    return Expanded(
      child: Semantics(
        container: true,
        button: true,
        selected: isSelected,
        label: '$label tab',
        tooltip: label,
        onTap: () => _onTap(context, index),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0x80E23B3B)
                        : Colors.transparent,
                    width: isSelected ? 1.2 : 1.0,
                  ),
                  boxShadow: const [],
                ),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  size: 22,
                  color: isSelected
                      ? const Color(0xFFFFFFFF)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              const SizedBox(height: 3),
              MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.3,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 10.5,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      letterSpacing: 0.3,
                      color: isSelected
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFFCBD5E1),
                      shadows: AppTheme.crystalTextShadows,
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
