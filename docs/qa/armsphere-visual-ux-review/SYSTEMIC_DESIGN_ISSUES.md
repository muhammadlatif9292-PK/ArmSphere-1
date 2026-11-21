# ArmSphere Systemic UI/UX Design & Architectural Issues

**Task Reference**: ARMSPHERE TASK 31 — Comprehensive Contextual UI/UX Audit  
**Target Repository**: `E:\ArmSphere\`  
**Target Platform**: Android (Physical Device: TECNO_BG6 / Android 13, 720×1612)  
**Evidence Baseline**: Tasks 28–30 (62 Screenshot Captures across 49 Unique Screens)  
**Output Directory**: `E:\ArmSphere\docs\qa\armsphere-visual-ux-review\`  

---

## 1. Introduction

Rather than isolated styling blemishes, the visual and UX defects identified in the ArmSphere Flutter application stem from **seven systemic architectural patterns**. Because these patterns are repeated across multiple screens and feature modules, fixing individual screens in isolation would result in inconsistent user experiences and regression during future feature additions.

This document diagnoses the exact technical and spatial root causes of these recurring defects and establishes architectural standards to resolve them permanently.

---

## 2. Systemic Issue 1: Floating Dock Occlusion & Bottom Action Clearance

### Technical Root Cause:
The application uses a custom floating glass bottom navigation dock in `MainShellScreen`:
- Height: `64.0` logical pixels.
- Bottom Inset: `12.0` logical pixels above system navigation.
- Horizontal Margins: `16.0` logical pixels on left and right.
- Effective Vertical Footprint: Approximately **`88.0` to `96.0` logical pixels** including drop shadow and blur spill.

However, individual child screens embedded within this shell (e.g., `AthleteDashboardScreen`, `TournamentsListScreen`, `CommunityFeedScreen`, `TrainingLogScreen`) are rendered using standard `Scaffold` bodies and `ListView` widgets with default bottom padding of only `16.0` to `24.0` logical pixels.

```
+------------------------------------------------------+
| Content Card / Recent Verifications (Scroll Bottom)  |
|                                                      |
|   +----------------------------------------------+   |
|   |  [FLOATING GLASS DOCK - 64px + 12px INSET]   |   | <-- OCCLUDES CONTENT
|   |    [Home]   [Discover]   [Arena]   [Passport]|   |
|   +----------------------------------------------+   |
|                                                      |
+------------------------------------------------------+
```

### Observed User Impact:
1. **Content Clipping**: In `AthleteDashboardScreen` (`005-S-001-dashboard-scroll-02.png`), the lowest card ("Recent Verifications") is partially hidden behind the frosted dock. Users cannot read verification hashes or tap timestamp links without holding an overscroll drag.
2. **FAB Tap Collisions**: In `CommunityFeedScreen` (`015-S-009-community-tab-main.png`), the floating action button (`[+]`) sits at the bottom right immediately above the Tab 3 ("Community") icon. One-handed thumb reach frequently triggers an accidental tab refresh rather than opening the post creation sheet.
3. **Training Log FAB Overlap**: In `TrainingLogScreen` (`010-S-006-training-log-screen.png`), the `[Log Workout]` FAB directly collides with the dock bounds when navigated within the shell hierarchy.

### Standardized Architectural Remedy:
* Introduce an app-wide constant: `kShellBottomDockPadding = 100.0`.
* Enforce `padding: EdgeInsets.only(bottom: kShellBottomDockPadding)` on all scrollable views embedded within `MainShellScreen`.
* Offset all FABs in shell screens using `floatingActionButtonLocation: FloatingActionButtonLocation.endFloat` combined with `EdgeInsets.only(bottom: 84.0)`.

---

## 3. Systemic Issue 2: Disconnected Primary CTAs & Floating Center Actions

### Technical Root Cause:
When screens encounter empty states or API fallbacks, they render a generic `Center(child: Column(...))` without structural framing. Primary recovery actions (such as `[Retry]`, `[Refresh Results]`, or `[Create Squad]`) float in the vertical center of a dark void background, completely disconnected from the top AppBar context and lacking secondary navigation paths.

### Observed User Impact:
1. **Marooned Error States**: In `TournamentDetailScreen` (`045-S-038`), `ChampionshipsListScreen` (`050-S-043`), `DisputeDetailScreen` (`052-S-045`), and `MyNominationsScreen` (`059-S-052`), a lone `[Retry]` button floats in the screen center. If the API fails due to an expired token, tapping `[Retry]` simply flashes the screen and returns the same error, leaving the user with no path back to safety other than the Android system back gesture.
2. **Disconnected Form CTAs**: In `EventRegistrationScreen` (`051-S-044`), the primary submission button `[Complete Registration]` is pinned at the screen bottom, separated from the division and weight dropdowns by a massive vertical void. A disconnected micro-caption (*"Official sanctioned entry • Bracket seeded upon check-in"*) sits underneath, detached from the pricing data it qualifies.

### Standardized Architectural Remedy:
* Standardize on a unified `FederationEmptyState` and `FederationErrorCard` component that strictly requires:
  1. An illustrated federation emblem / icon.
  2. A human-readable title and helpful diagnostic message.
  3. A **primary recovery action** (e.g., `[Retry with Refresh]`).
  4. A **secondary escape action** (e.g., `[Return to Directory]` or `[Contact Helpdesk]`).
* On interactive forms (`EventRegistrationScreen`), embed the submission CTA within an **anchored summary card** directly adjacent to input fields or in a dedicated bottom summary panel that displays total entry cost dynamically.

---

## 4. Systemic Issue 3: Raw Technical Error Strings & Inline Technical Leakage

### Technical Root Cause:
Multiple screens catch Riverpod provider errors or HTTP exceptions and extract the raw exception message directly into the widget tree via `error.toString()`:
```dart
// Antipattern observed in code:
Text(error.toString(), style: TextStyle(color: Colors.red))
```
When JWT access tokens expire, backend microservices return HTTP 401 with standard JSON error envelopes (`{"statusCode": 401, "message": "Session Expired: Please log in again."}`). The client presents this unformatted technical string directly on consumer-facing UI.

### Observed User Impact:
Across four distinct screens:
- `ChampionshipsListScreen` (`050-S-043-championship-titles-error-state.png`)
- `DisputeDetailScreen` (`052-S-045-dispute-dossier-error-state.png`)
- `ChatScreen` (`053-S-046-match-discussion-chat-screen.png`)
- `CreateTeamScreen` (`062-S-055-register-new-team-form.png`)

Users see raw strings such as:
`[401] Session Expired: Please log in again.`  
This creates severe trust erosion, mimics developer debug builds, and offers no mechanism to perform session re-authentication.

### Standardized Architectural Remedy:
* Implement an HTTP Interceptor / Token Refresh Pipeline in the networking layer that automatically intercepts 401 responses and triggers silent JWT token renewal.
* If renewal fails, route user gracefully through a non-destructive re-authentication bottom sheet rather than displaying inline error strings.
* Build a `UserFacingExceptionMapper` that converts technical network exceptions into dignified, domain-appropriate athletic copy (e.g., *"Federation credentials need verification. Please refresh your passport."*).

---

## 5. Systemic Issue 4: Header vs Body Action Fragmentation (The Dual-Action Antipattern)

### Technical Root Cause:
In directory screens (`VenueDirectoryScreen`, `InformalEventDirectoryScreen`, `TeamsListScreen`), developers implemented two competing creation controls:
1. An icon-only `(+)` action button in the top-right `AppBar`.
2. A large, prominent elevated button in the center empty state (e.g., `[Submit a Venue]`, `[Host a Meetup]`, `[Register a Team]`).

```
+------------------------------------------------------+
| [<-] Armwrestling Venues                        (+)  | <-- Action 1 (Small, Top Right)
|------------------------------------------------------|
|                                                      |
|               (No Venues Registered)                 |
|                                                      |
|                 [ SUBMIT A VENUE ]                   | <-- Action 2 (Giant, Center)
|                                                      |
+------------------------------------------------------+
```

### Observed User Impact:
When the directory is empty, users interact with the large central button. However, once venues or meetups are populated in the database, the empty-state widget is unmounted, removing Action 2 completely. Users return to the screen expecting the large button and are disoriented trying to find the small, unlabelled icon button in the top-right AppBar.

### Standardized Architectural Remedy:
* Standardize directory creation patterns across the entire application:
  * **Option A (Preferred for Mobile)**: Dedicated Floating Action Button with label (Extended FAB): `FloatingActionButton.extended(icon: Icon(Icons.add), label: Text('Register Venue'))`.
  * **Option B**: Top AppBar action with text label and icon: `TextButton.icon(icon: Icon(Icons.add), label: Text('New'))`.
* Ensure that the action trigger remains in the **identical visual position** whether the list has 0 items or 50 items.

---

## 6. Systemic Issue 5: Form Submission Ergonomics & Keyboard Occlusion

### Technical Root Cause:
Across all data-entry forms in the application:
- `SubmitVenueScreen` (`056-S-049`, `/venues/submit`)
- `CreateInformalEventScreen` (`058-S-051`, `/informal-events/create`)
- `NominateTalentScreen` (`060-S-053`, `/nominate`)
- `CreateTeamScreen` (`062-S-055`, `/teams/create`)
- `CreatePostScreen` (`027-S-020`, `/community/create`)
- `UploadEvidenceScreen` (`023-S-016`, `/referee/upload-evidence`)
- `SubmitComplaintScreen` (`043-S-036`, `/governance/submit-complaint`)

The primary submission CTA is placed as the final element of a scrollable `ListView` or `SingleChildScrollView`. There is no persistent bottom sheet or keyboard-avoidance docking logic.

### Observed User Impact:
When a user taps an input field (such as entering a team creed, venue address, or incident description), the Android soft keyboard expands to occupy 40%–50% of the screen height (`300px` to `400px` on standard mobile viewports). The submission CTA is pushed entirely off screen. Users must know to manually tap the hardware back button or swipe down to dismiss the keyboard before they can submit the form.

### Standardized Architectural Remedy:
* Implement a reusable `StickyFormScaffold` layout:
  ```dart
  Scaffold(
    appBar: ...,
    body: SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 80),
      child: FormFields(),
    ),
    bottomNavigationBar: Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 12),
      decoration: BoxDecoration(color: Color(0xFF141414), border: Border(top: BorderSide(color: Color(0xFF262626)))),
      child: PrimarySubmitButton(),
    ),
  )
  ```
* This anchors the submit CTA above the keyboard with a real-time validation indicator, enabling instant one-tap submission without keyboard friction.

---

## 7. Systemic Issue 6: High-Stakes Destructive Proximity & Instant Persona Shifts

### Technical Root Cause:
Actions with massive, irreversible consequences are placed in close spatial proximity to benign controls, or are triggered instantly upon a single tap without confirmation safeguards.

### Observed User Impact:
1. **Referee Scorepad (`S-014`)**: At table-side during a high-speed match, `[Confirm Winner]` sits immediately adjacent to `[Reset Score]`. An errant thumb tap can clear an entire match history in front of spectators.
2. **Security Vault Sessions (`S-018`)**: `[Revoke All Other Sessions]` is placed in the top right of the active devices card, right beside the current device badge. A mis-tap instantly logs the user out of all desktop and mobile devices.
3. **Account Deletion (`S-032`)**: `[Delete Account Permanently]` is enabled as soon as the confirmation phrase is matched, with zero countdown delay or biometric verification.
4. **Account Roles (`S-017`)**: Tapping a role card immediately switches the app-wide persona without a confirmation dialogue, unexpectedly altering navigation tabs and dashboards.

### Standardized Architectural Remedy:
* **The 2-Step Destructive Rule**:
  * Destructive actions must require either a **2-second long-press with haptic vibration** or an explicit **confirmation bottom sheet**.
  * Critical resets (Scorepad) must be sequestered into an overflow AppBar menu (`...`), not placed next to the primary winner confirmation button.
* **Persona Switch Confirmation**: Tapping a role card must display a bottom sheet: *"Switch to Certified Referee Persona? This will update your active workspace and tools."* with `[Cancel]` and `[Confirm Switch]` buttons.

---

## 8. Systemic Issue 7: Visual Hierarchy, Typography & Header Inconsistencies

### Technical Root Cause:
Screens built at different stages of development utilize slightly different AppBar configurations, card border radii, and chip styling:
1. **AppBar Leading Icons**: Some screens use custom chevron arrows (`Icons.chevron_left`), while others use standard back arrows (`Icons.arrow_back`) or omit the back button entirely, relying on implicit gestures.
2. **Filter Chips**: On `DiscoverScreen` (`S-007`), category chips use solid gold background when selected with square rounded corners; on `TournamentsListScreen` (`S-008`), filters use outline borders with pill shapes; on `GovernanceDashboardScreen` (`S-035`), filters use muted grey chips.
3. **Card Contrast & Borders**: Some screens use `1px` subtle gold border lines (`#D4AF37` at 20% opacity), while others use solid dark grey borders (`#333333`) or no borders at all.

### Standardized Architectural Remedy:
* Unify all AppBar headers using `ArmSphereAppBar` with standardized title typography (`Outfit` Bold 18sp), uniform back icon (`Icons.arrow_back_ios_new_rounded`, 20sp), and consistent action button spacing.
* Standardize filter controls into `ArmSphereFilterBar` with uniform pill geometry and active gold fill tokens.
* Enforce shared card decoration `ArmSphereCardDecoration` across all list items, dossier views, and dashboard tiles.
