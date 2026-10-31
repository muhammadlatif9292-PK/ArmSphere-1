# Crystal Glassmorphism Navigation & Inner-Screen Header Completion Plan

Completes the full rollout of the Crystal Glassmorphism navigation architecture by adding a reusable `CrystalAppBar` header wrapper, upgrading all remaining inner screens across Tournaments, Championships, Referee Scorepad, Venues, Informal Events, Community, Support, Notifications, Teams, Nominations, Role Applications, and Auth to use unified `CrystalBackButton` and `CrystalHomeButton` controls, and enforcing strict 5-tab isolation in the router.

## User Review & Critical Decisions

> [!IMPORTANT]
> All core design and navigation choices were confirmed by you in prior turns and in your completion checklist. No additional questions are required before execution.

- **Confirmed Decision 1 (Main-Tab-Only Dock + Auto-Hide)**: The bottom floating crystal dock appears strictly on the 5 primary root tabs (`Arena`, `Discover`, `Events`, `Community`, `Passport`) and smoothly auto-hides when scrolling down.
- **Confirmed Decision 2 (Compact Crystal Glass Dock)**: Low-profile floating pill with optical blur (`sigma: 28`), crisp top specular rim, and refractive crimson active capsule.
- **Confirmed Decision 3 (Unified Inner-Screen Top Navigation)**: Every inner/pushed screen features the identical 38×38dp `CrystalBackButton` on the top-left and `CrystalHomeButton` (`Back to Arena`) on the top-right, backed by a drop-in `CrystalAppBar` component.

---

## 1. Overview & Core Concept

- **What It Does**: Eliminates legacy unstyled back arrows (`Icons.arrow_back`, `Icons.arrow_back_ios_new`) and missing home-jump actions across the remaining 20+ inner screens, while extracting secondary routes out of the 5-tab shell branches so inner flows never inherit bottom navigation bar clutter.
- **Target Audience / Persona**: Athletes, Referees, Tournament Operators, and Governance Officials navigating deep into tournament brackets, live scorepads, award ceremonies, venue directories, informal events, support tickets, and role workflows.
- **Key Value**: 100% visual and behavioral consistency across every screen in ArmSphere—every inner screen shares the exact same top-left Crystal Back button and top-right Quick-Jump Arena Home button, with 85%+ unobstructed viewport space.

---

## 2. User Experience & Visual Design

- **Key User Flows**:
  1. **Root Tab Browsing**: Users switch between the 5 main tabs using the floating Crystal Glass dock. Scrolling down any feed or list smoothly slides and fades the dock out of the way; scrolling up or reaching the top restores it immediately.
  2. **Deep Inner-Screen Navigation**: Opening any tournament detail, live scorepad, awards ceremony, venue, informal event, post comment thread, support ticket, nomination, or settings sub-screen renders full-screen without the bottom dock.
  3. **One-Tap Return**: Users can either step back one level via the top-left `CrystalBackButton` or jump straight back to the main `/home` Arena tab from any depth via the top-right `CrystalHomeButton`.
- **Visual Identity & Theme**:
  - *Aesthetic Direction*: Refractive Dark Crystal Glassmorphism over atmospheric arena photography.
  - *Color Palette & Mood*:
    - Primary Canvas: Obsidian Void (`#07090E`) with translucent crystal surfaces (`rgba(255, 255, 255, 0.08)` to `0.16`).
    - Specular Borders: Crisp 1px top-left refractive white rim (`rgba(255, 255, 255, 0.26)`) paired with Crimson (`#E11D48`) accent borders (`rgba(225, 29, 72, 0.45)`) on quick-jump controls.
    - Text Hierarchy: Pure White (`#FFFFFF`) display headers and crisp muted silver secondary labels.
  - *Typography & Hierarchy*: Bold uppercase display headers (`Bebas Neue` / `Oswald` tracking) in a compact 56dp top app bar, keeping sticky chrome well under the 15% mobile viewport cap.
  - *Component Styling & Layout*: 38×38dp squircle (`borderRadius: 12dp`) crystal capsules wrapped in a ≥44×44dp interactive touch target for ergonomic thumb and finger reach.
- **Interactive Feedback & Motion**:
  - Haptic selection click (`HapticFeedback.selectionClick()`) on every back and home tap.
  - 200ms–240ms `Curves.easeOutCubic` compositor-friendly slide and opacity transitions for the floating dock.

---

## 3. Key Product Decisions & Trade-Offs

- **Decision 1: Drop-In `CrystalAppBar` PreferredSizeWidget + Sliver Support**
  - *Chosen Approach*: Introduce `CrystalAppBar` (implementing `PreferredSizeWidget`) and `CrystalSliverAppBar` inside the shared navigation controls module, automatically wiring `CrystalBackButton` as `leading` and appending `CrystalHomeButton` to `actions`.
  - *Why*: Guarantees identical 56dp bar height, leading width, button alignment, and fallback routing across all remaining screens without repetitive boilerplate.
  - *Alternatives Considered*: Manually copying `leading` and `actions` into every `AppBar`—prone to subtle padding or action-order drift.
- **Decision 2: Strict Root Navigator Boundary for Secondary Routes**
  - *Chosen Approach*: Move secondary routes (`/athlete/dashboard`, `/referee/dashboard`, `/governance`, `/rankings`, `/tournament/dashboard`) out of `StatefulShellBranch` into top-level router entries while preserving the route-aware dock check in `MainShellScreen` as a secondary defense-in-depth guard.
  - *Why*: Ensures pushed and role-dispatched inner screens mount cleanly at the root navigator level with zero bottom dock overlap.

---

## 4. Technical Architecture & Data Strategy

### Architecture & Component Diagram

```
┌───────────────────────────────────────────────────────────────────────────┐
│                         GoRouter Navigation Layer                         │
├───────────────────────────────────┬───────────────────────────────────────┤
│   StatefulShellRoute (5 Branches) │       Top-Level Inner GoRoutes        │
│   • /home (Arena)                 │   • Tournaments, Live Match, Ceremony │
│   • /discover                     │   • Official Scorepad & Referee Ops   │
│   • /tournaments                  │   • Venues & Informal Events          │
│   • /community/feed               │   • Community Post Create & Comments  │
│   • /athlete/profile              │   • Support, Sessions, Notifications  │
│                                   │   • Teams, Nominations, Roles, Auth   │
└─────────────────┬─────────────────┴───────────────────┬───────────────────┘
                  │                                     │
                  ▼                                     ▼
┌───────────────────────────────────┐ ┌─────────────────────────────────────┐
│          MainShellScreen          │ │   CrystalAppBar / Inner Headers     │
│ • ScrollNotification Auto-Hide    │ │ • Left: CrystalBackButton (38x38dp) │
│ • _isRootTabRoute Safeguard       │ │   -> canPop() ? pop() : go('/home') │
│ • Compact Crystal Floating Dock   │ │ • Right: Contextual Actions +       │
│   (BackdropFilter sigma 28)       │ │   CrystalHomeButton -> go('/home')  │
└───────────────────────────────────┘ └─────────────────────────────────────┘
```

### Interactive Component & State Mapping

- **`CrystalAppBar` & Header Unification**:
  - Automatically injects `CrystalBackButton(fallbackRoute: ...)` in the left slot and appends `CrystalHomeButton()` as the terminal right-hand action (preserving any existing contextual actions such as filter, refresh, or share buttons to its left).
  - For screens with custom header rows or `SliverAppBar` (such as Tournament Detail, Awards Ceremony, Venues, and Informal Events), replaces legacy `IconButton(icon: Icon(Icons.arrow_back...))` with `CrystalBackButton` and adds `CrystalHomeButton` in the trailing action cluster.
  - For pre-authentication screens (`Login`, `Register`, `MFA Verification`, `Forgot/Reset Password`), uses `CrystalBackButton(fallbackRoute: '/welcome')` without showing the authenticated `/home` jump button.
- **Verification**:
  - Run widget tests and static analysis across all updated modules to verify zero regressions and full compilation.
