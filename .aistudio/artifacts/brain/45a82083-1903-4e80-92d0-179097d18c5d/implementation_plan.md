# Crystal Glass Action Bars, Error States, Interactive Buttons, Chronological Navigation & Scroll-to-Top Plan

## 1. Root Cause Analysis

### A. Flat Action Completion Bars (SnackBars) & Error Presentations
- **Current Issue**: Action completion bars (such as `"All alerts marked as read"` in `NotificationsListScreen`) use standard full-width `SnackBar` blocks (`SnackBarBehavior.fixed`) with solid flat green (`AppTheme.success`) or red (`AppTheme.error`) backgrounds that sit directly at the bottom edge of the viewport, colliding with the floating Crystal Glass navigation dock. Inline error states and `AppErrorView` also rely on flat boxes rather than refractive Crystal Glass surfaces.
- **Solution**:
  - Introduce a unified **`CrystalToast` / Crystal `SnackBar` Subsystem** (`apps/mobile/lib/core/widgets/crystal_toast.dart`) and configure global `SnackBarThemeData` in `AppTheme` so every action completion bar and error alert renders as a **floating Crystal Glass capsule above the dock** (`BackdropFilter` blur `sigma: 16`, status icon badge, semantic emerald/gold/crimson specular rim, ambient glow, and dock-safe bottom margin).
  - Upgrade `AppErrorView` (`apps/mobile/lib/core/widgets/app_error_view.dart`) and inline error banners across screens into frosted Crystal Glass diagnostic panels with refractive retry buttons.

### B. Legacy Flat Action Buttons, Header Pills & Floating Action Buttons (FABs)
- **Current Issue**:
  - In-screen CTA buttons in `AppEmptyState` (e.g., `"Log a Session"`, `"Open Support Ticket"`, `"Create Team"`, `"Upload a Video"`), inline screen buttons, and header action buttons (e.g., plain yellow `"Mark all read"` text in `NotificationsListScreen` or flat `"NEW TICKET"` outline in `SupportTicketsScreen`) lack the refractive Crystal Glassmorphic styling.
  - Bottom-right `FloatingActionButton` widgets (such as the flat yellow square `+` button on `Training Log & PRs`, `CommunityFeedScreen`, `TeamsListScreen`, `InformalEventDirectoryScreen`, and `VenueDirectoryScreen`) use flat solid fills without glass refraction or specular rims.
- **Solution**:
  - Create reusable **`CrystalActionButton`**, **`CrystalHeaderActionPill`**, and **`CrystalFloatingActionButton`** components in `apps/mobile/lib/core/widgets/crystal_glass_nav_controls.dart`.
  - Upgrade `AppEmptyState` (`apps/mobile/lib/core/widgets/app_empty_state.dart`), `AppErrorView`, header action pills (`"Mark all read"`, `"New Ticket"`, etc.), in-screen action buttons (`"Log a Session"`, `"Create Team"`, `"Upload Video"`, etc.), and all `FloatingActionButton` instances across the app to frosted Crystal Glassmorphic capsules and 56×56dp squircle FABs with gold/crimson specular rims.

### C. Tab Highlighting Desync, Pushed Route Dock Visibility & Step-by-Step Back History
- **Current Issue**:
  1. When tapping Profile/Passport, Discover, Events, or Community from `AthleteDashboardScreen` (or anywhere else in the app via `context.push('/athlete/profile')` or `context.push('/discover')`), the screen opens on top of the current branch without syncing `StatefulNavigationShell`, leaving **Arena** highlighted on the bottom dock instead of highlighting **Passport** (or the target main tab).
  2. In `MainShellScreen._isRootTabRoute`, `router.routeInformationProvider.value.uri.path` was checked before `router.routerDelegate.currentConfiguration`. In `go_router`, `routeInformationProvider` does not update on `context.push(...)` calls (like `/notifications` or `/athlete/:id/training-log`), causing `_isRootTabRoute` to falsely see `/home` and keep the bottom dock visible on inner pushed screens.
  3. Pressing Back on main tabs or cross-navigated screens did not step backward through the exact chronological path of visited tabs/screens.
- **Solution**:
  - **Fix Top-Most Route Detection**: Update `MainShellScreen` to inspect `GoRouter.of(context).routerDelegate.currentConfiguration.last.matchedLocation` and `routerDelegate.currentConfiguration.uri.path` first.
  - **Auto-Highlight Active Main Tab From Anywhere**: Map all 5 canonical root tab routes (`/home` → `0`, `/discover` → `1`, `/tournaments` → `2`, `/community/feed` → `3`, `/athlete/profile` → `4`) in `MainShellScreen`. Whenever any screen navigates to one of the 5 main tab routes (whether via bottom dock tap, dashboard profile header tap, quick command card, or deep link), switch/sync the active shell branch so the corresponding bottom dock tab (`Arena`, `Discover`, `Events`, `Community`, `Passport`) is immediately highlighted.
  - **Chronological Step-by-Step Back History Stack**: Maintain a chronological navigation history stack (`_tabHistoryStack`) in `MainShellScreen` (coupled with `PopScope` and `CrystalBackButton` integration). Navigating across tabs or screens (e.g., `Arena → Discover → Passport` or `Arena → Passport`) records each step; pressing Back steps backward one screen/tab at a time along the exact path the user took, rather than jumping straight to Arena or exiting prematurely.

### D. Scroll-to-Top Reset on Every Tab Shift & Screen Open
- **Current Issue**: Because `StatefulShellRoute.indexedStack` preserves branch states and several scroll views retain old scroll offsets, returning to or switching tabs leaves the screen scrolled halfway down from previous browsing.
- **Solution**:
  - Implement an automatic **Scroll-to-Top Reset** in `MainShellScreen` and screen scroll controllers so that whenever the user switches tabs, opens a main tab from another screen, or navigates back/forward to a screen, the active scroll hierarchy resets smoothly/cleanly to offset `0.0` (the very top of the screen).

---

## 2. Planned Changes by File

1. **`apps/mobile/lib/core/widgets/crystal_toast.dart` (New Component)**:
   - Implement `CrystalToast` & `showCrystalSnackBar(BuildContext context, {required String message, CrystalToastType type, ...})` + `CrystalSnackBarContent` widget featuring optical `BackdropFilter` blur (`sigma: 16`), semantic status icon capsule (emerald check for success, gold info badge, crimson alert icon for errors), 1.2px specular gradient rim, and dock-aware floating margin.
2. **`apps/mobile/lib/core/widgets/crystal_glass_nav_controls.dart`**:
   - Add `CrystalActionButton` (frosted glass CTA button with gold or crimson specular rim, optional leading icon, and loading spinner support).
   - Add `CrystalHeaderActionPill` (compact 34dp crystal capsule for AppBar actions like `"Mark all read"`, `"New Ticket"`, `"Filter"`, etc.).
   - Add `CrystalFloatingActionButton` (56×56dp squircle refractive glass FAB with top-left specular highlight, gold/crimson rim, and ambient elevation glow).
   - Enhance `CrystalBackButton` so that when invoked on a root tab or pushed route, it respects the chronological navigation history step-by-step before falling back to `/home`.
3. **`apps/mobile/lib/core/widgets/main_shell_screen.dart`**:
   - Fix `_resolveCurrentPath` to prioritize `router.routerDelegate.currentConfiguration` so inner pushed routes (`/notifications`, `/athlete/:id/training-log`, etc.) accurately hide the bottom dock, while all 5 root tab paths (`/home`, `/discover`, `/tournaments`, `/community/feed`, `/athlete/profile`) display the dock with the matching tab highlighted.
   - Intercept cross-screen navigation to any of the 5 main tab routes so `navigationShell.goBranch(targetTabIndex)` is synchronized and the target tab is highlighted on the dock.
   - Maintain a chronological `_tabHistory` stack and wrap `MainShellScreen` in `PopScope(canPop: ...)` so system Back and top-left Back step through the exact sequence of previously visited tabs/screens one by one.
   - Add `_resetActiveBranchScrollToTop()` triggered on every tab switch and route transition to reset all active `ScrollPosition`s in the current subtree to `0.0`.
4. **`apps/mobile/lib/core/widgets/app_empty_state.dart` & `apps/mobile/lib/core/widgets/app_error_view.dart`**:
   - Upgrade `AppEmptyState` icon halo and action CTA button (`"Log a Session"`, `"Open Support Ticket"`, `"Create Team"`, etc.) to `CrystalActionButton`.
   - Upgrade `AppErrorView` container and retry CTA button to a frosted Crystal Glass error panel with crimson specular border and `CrystalActionButton`.
5. **`apps/mobile/lib/core/theme/app_theme.dart`**:
   - Configure global `snackBarTheme` with `SnackBarBehavior.floating`, transparent outer canvas, dock-safe margin, and rounded squircle shape so all standard `SnackBar` calls inherit floating glass positioning.
6. **App-Wide Screen Upgrades (Action Bars, Header Pills, CTAs, FABs & Tab Navigation Links)**:
   - **`notification_screens.dart`**: Upgrade `"Mark all read"` header button to `CrystalHeaderActionPill` and upgrade the completion `SnackBar` (`"All alerts marked as read"`) to `showCrystalSnackBar`.
   - **`training_log_screen.dart`**: Upgrade the bottom-right `+` `FloatingActionButton` to `CrystalFloatingActionButton`, upgrade inline error banner to Crystal Glass, and upgrade SnackBars to `showCrystalSnackBar`.
   - **`athlete_screens.dart`**: Ensure tapping the Profile/Passport banner or quick links to `/athlete/profile`, `/discover`, `/tournaments`, `/community/feed` transitions cleanly into the corresponding highlighted shell tab and records chronological history; upgrade action buttons and SnackBars to Crystal Glass.
   - **`community_feed_screen.dart`, `team_screens.dart`, `support_screens.dart`, `informal_event_screens.dart`, `venue_screens.dart`, `tournament_screens.dart`, `nomination_screens.dart`, `role_application_screens.dart`**: Upgrade FABs (`+`, `"Create Team"`, `"Upload Video"`, `"Log Session"`, `"New Ticket"`), header action pills, and completion/error `SnackBar`s to the unified Crystal Glass components.
7. **`apps/mobile/test/core/widgets/main_shell_nav_dock_test.dart`**:
   - Add widget tests verifying active tab highlighting when navigating to Passport/Discover from Dashboard, step-by-step chronological back navigation across tabs, and scroll-to-top reset on tab change.
