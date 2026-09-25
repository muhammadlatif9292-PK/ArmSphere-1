# ArmSphere Current Product Experience Audit
**Deep UX, Interaction & Visual Quality Audit**
**Document Version**: 1.0.0
**Audit Date**: September 25, 2026
**Target**: ArmSphere Flutter Mobile Application (`apps/mobile`)

---

## 1. Executive Summary

A comprehensive source-code and UX audit was conducted across all 17 feature domains, 66 screen classes, and 53 tournament widgets in the ArmSphere repository. 

The core engineering, state management (Riverpod 2.6), API communication (Dio with SSL pinning and circuit-breaking), and offline database schema (Hive + 58 PostgreSQL tables) are **technically robust, production-tested (RC-2 verified), and functionally complete**.

However, the user experience currently exhibits **visual fragmentation, inconsistent component usage, navigation friction, and opportunities to eliminate generic AI UI tropes**. This audit documents every concrete issue discovered across 5 architectural layers.

---

## 2. Product Structure & Information Architecture Audit

### 2.1 Navigation Overcrowding in AppBar Actions
- **Finding**: In `features/home/screens/discover_screen.dart` (lines 33–60), the AppBar contains **5 icon action buttons** simultaneously (`/venues`, `/informal-events`, `/community/feed`, `/search`, `/home`), plus the title.
- **UX Impact**: High cognitive overload. On narrower Android devices (e.g. 360dp width), the AppBar titles truncate or collide with actions. Users cannot deduce which icon represents which feature without tapping.
- **Architectural Solution**: Move Venue Directory and Informal Events into a structured contextual discovery carousel or segmented sub-header on Discover. Restrict AppBar actions to Global Search and Notifications.

### 2.2 Role-Aware Routing Disconnect
- **Finding**: In `core/routing/app_router.dart`, `RoleAwareHomeScreen` switches between `AthleteDashboardScreen`, `RefereeDashboardScreen`, and `GovernanceDashboardScreen` based on role. However:
  - If a Referee navigates to the Discover tab or Tournaments tab, their bottom navigation remains standard, but they lose contextual awareness of their pending table calls.
  - An Athlete with referee certifications who wants to switch roles must tap a quick shortcut (`Referee Console` in `athlete_screens.dart`), which pushes a new route over the shell rather than smoothly pivoting the workspace mode.
- **Architectural Solution**: Introduce an official "Role Switcher Pill" in the athlete profile header for dual-role users (Athlete + Certified Official), providing a clean modal transition between Athlete and Official modes.

### 2.3 Competing Navigation Paths
- **Finding**: Brackets can be opened from:
  1. `TournamentDetailScreen` (`/tournament/:id/brackets`)
  2. Legacy route `/tournament/brackets` with `extra` payload
  3. `FullInteractiveBracketModal` bottom sheet modal
- **UX Impact**: Multiple duplicate ways to view brackets with inconsistent back-navigation behavior.
- **Architectural Solution**: Canonicalize all bracket viewing onto `/tournament/:id/brackets` with an optional full-screen zoom toggle.

---

## 3. Screen Composition & Visual Hierarchy Audit

### 3.1 Indiscriminate Use of `GlassCard`
- **Finding**: `GlassCard` (`core/widgets/glass_card.dart`) is currently applied everywhere—to high-level hero sections, small shortcut buttons, form fields, and nested list items.
- **UX Impact**: "Glassmorphism fatigue". When a glass card sits inside another semi-transparent container with background particles, the blurred backdrop compounds, creating visual noise, contrast degradation, and unnecessary GPU raster cache churn.
- **Architectural Solution**: Establish a 3-tier surface hierarchy:
  - **Tier 1 (Substrate)**: Solid dark slate `#0B0F19` with subtle 1px border `#1E293B`.
  - **Tier 2 (Structural Card)**: Elevated dark surface `#121826` with 0.90 opacity and 1px border `#334155 @ 0.15`.
  - **Tier 3 (Glass Focal / Hero)**: Reserved strictly for Hero cards, Live Scorepads, and Title Championship Lineages.

### 3.2 Repetitive Centered Layouts & Template Aesthetic
- **Finding**: `SplashScreen`, `WelcomeScreen`, and empty states all rely on identical center-stacked iconography with circular background glows.
- **UX Impact**: Gives the application a generic template feel rather than the bespoke, commanding presence of an international sports federation.
- **Architectural Solution**: Introduce asymmetric, athletic editorial compositions: left-aligned bold typography with right-aligned stat badges, diagonal metallic accent lines, and dynamic sports photography backdrops.

### 3.3 Status Chip Color Inconsistency
- **Finding**: Event status colors vary across screens:
  - In `tournament_screens.dart`: `PUBLISHED` is `amber`, `ONGOING` is `greenAccent`, `COMPLETED` is `grey`.
  - In `tournament_operations_screen.dart`: `APPROVED` is `green`, `PENDING_PAYMENT` is `amber.shade700`, `WAITLISTED` is `purple`.
  - In `governance_screens.dart`: `ESCALATED` is `primaryAccent` (Crimson), `OPEN` is `warning` (Orange).
- **UX Impact**: Users cannot build consistent muscle memory regarding status semantics.
- **Architectural Solution**: Unify all statuses into the canonical design token system (`docs/design/07_COLOR_AND_THEME_TOKENS.md`).

---

## 4. Interaction Quality & Handheld Feedback Audit

### 4.1 Missing Haptic Feedback on High-Stakes Actions
- **Finding**: In `referee_screens.dart` and `official_scorepad_screen.dart`, incrementing match scores, calling matches to tables, and declaring winner pins rely solely on standard touch taps with no physical haptic feedback.
- **Operational Reality**: At physical armwrestling tables, referees are looking at athlete elbow pads and hands—not at their smartphone screen. They need physical haptic confirmation when tapping scorepads.
- **Architectural Solution**: Implement `HapticFeedback.selectionClick()` on score increments and `HapticFeedback.heavyImpact()` on match completion and foul declarations.

### 4.2 Inconsistent Loading and Error Presentations
- **Finding**:
  - `tournaments_screens.dart` renders a raw `Center(child: CircularProgressIndicator())`.
  - `community_feed_screen.dart` renders `SkeletonPlaceholder(height: 180)`.
  - `athlete_screens.dart` renders an empty `SizedBox(height: 90)` with a small spinner.
  - Error states range from `Text('$error')` to `AppEmptyState` with a retry button.
- **UX Impact**: Jerky layout shifts when screens load. A screen jumping from a centered spinner to a dense list produces visual stutter.
- **Architectural Solution**: Standardize on shimmer skeleton loaders matching the exact geometric footprint of incoming cards (`tournament_skeleton_loading_widget.dart` pattern).

### 4.3 Form Keyboard Dismissal & Viewport Resizing
- **Finding**: In `event_registration_screen.dart` and `submit_complaint_screen.dart`, opening the software keyboard shrinks the viewport, occasionally pushing the primary "Submit" CTA off-screen without a sticky bottom button bar.
- **Architectural Solution**: Wrap all multi-input forms in `CustomScrollView` with sliver body and pin the primary action to a sticky bottom navigation bar with keyboard avoidance (`bottomNavigationBar` with safe area padding).

---

## 5. Flow Quality & Transition Continuity Audit

### 5.1 The "Abrupt Splash Exit" Problem
- **Finding**: `SplashScreen` runs a 1500ms fade animation, then GoRouter abruptly cuts to `WelcomeScreen` or `RoleAwareHomeScreen`.
- **UX Impact**: The user experiences a momentary flash of unrendered state or an abrupt route replacement.
- **Architectural Solution**: Implement a shared-element-like fade-and-scale exit where the ArmSphere logo subtly scales down to become the AppBar brand mark or Welcome hero icon.

### 5.2 The "Continue / Next" Multi-Step Transition
- **Finding**: In `onboarding_screen.dart` (3-step athlete onboarding), tapping "Next" swaps form fields instantly using `setState(() => _step++)`.
- **UX Impact**: Sudden jumping of fields without directional continuity. The user cannot feel whether they moved forward or backward.
- **Architectural Solution**: Encase steps in an animated `PageView` or directional `AnimatedSwitcher` with horizontal slide-and-fade (forward slide from right; back slide from left) over 280ms (`Curves.easeInOutCubic`).

### 5.3 Back Navigation & Scroll Restoration
- **Finding**: Returning from `TournamentDetailScreen` to `TournamentsListScreen` occasionally resets the list scroll position if the provider is invalidated.
- **Architectural Solution**: Preserve `PageStorageKey` across all major list screens so scroll positions and tab selections remain rock solid when navigating back.

---

## 6. Anti-UI-Slop & Generic AI Tropes Audit

To ensure ArmSphere achieves genuine athletic federation prestige, the following generic AI tropes are explicitly identified for elimination:

| Trope Detected in Legacy UI | Why it is Slop / Weak | ArmSphere Athletic Alternative |
| :--- | :--- | :--- |
| **Purposeless Ambient Particles** (`ambient_particle_background.dart` running 50 particles in main shell stack) | Burns battery and GPU compute on idle screens; makes the app feel like a crypto scam or sci-fi demo. | Replace with static, ultra-subtle atmospheric radial gradient (3-5% opacity) behind hero sections only. Zero GPU render loops. |
| **Every Button Has a Heavy Gradient** | Destroys button hierarchy; primary and secondary actions compete visually. | Reserve solid gold `#D4AF37` for the single primary action. Use dark structural borders `#334155` for secondary actions. |
| **Everything In A Glass Pill** | Over-rounded 999px pills for standard cards look like bubble toys. | Use crisp 12px or 16px geometric corners (`BorderRadius.circular(12)`). Reserve circular shapes strictly for athlete avatars and status dots. |
| **Generic Centered Empty States** | Big floating icon with "No data" centered in a blank void looks unfinished. | Context-rich empty states: actionable coaching text, illustration of an armwrestling table, and direct CTA (e.g. "Register for your first event"). |
| **Floating Decorative Shapes** | Triangles, floating rings, and decorative blobs with no semantic meaning. | **Zero decorative floating geometry.** All shapes represent real entities: brackets, cables, belts, medals, or tables. |
