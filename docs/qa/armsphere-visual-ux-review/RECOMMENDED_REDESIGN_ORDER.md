# ArmSphere Phased UI/UX Redesign Implementation Roadmap

**Task Reference**: ARMSPHERE TASK 31 — Comprehensive Contextual UI/UX Audit  
**Target Repository**: `E:\ArmSphere\`  
**Target Platform**: Android (Physical Device: TECNO_BG6 / Android 13, 720×1612)  
**Evidence Baseline**: Tasks 28–30 (62 Screenshot Captures across 49 Unique Screens)  
**Output Directory**: `E:\ArmSphere\docs\qa\armsphere-visual-ux-review\`  

---

## 1. Architectural Strategy & Phasing Principles

To execute the systematic UI/UX overhaul of the ArmSphere application without causing visual regressions, breaking live tournament flows, or destabilizing production builds, implementation must follow a **strict dependency-ordered roadmap**.

Fixing screens in isolation leads to code duplication and conflicting navigation patterns. Instead, the roadmap starts with **global layout scaffolding and systemic components** before cascading down into individual role workflows and niche feature modules.

```
       +-------------------------------------------------------------+
       |   PHASE 1: Global Shell Scaffolding & Dock Clearance        |
       +-------------------------------------------------------------+
                                      |
                                      v
       +-------------------------------------------------------------+
       |   PHASE 2: Standardized Federation Error & Empty States     |
       +-------------------------------------------------------------+
                                      |
                                      v
       +-------------------------------------------------------------+
       |   PHASE 3: Sticky Form Scaffold & Keyboard Avoidance Engine |
       +-------------------------------------------------------------+
                                      |
                                      v
       +-------------------------------------------------------------+
       |   PHASE 4: Core Role Dashboards & High-Stakes Guardrails    |
       +-------------------------------------------------------------+
                                      |
                                      v
       +-------------------------------------------------------------+
       |   PHASE 5: Secondary Directories, Canvases & Social Hubs    |
       +-------------------------------------------------------------+
                                      |
                                      v
       +-------------------------------------------------------------+
       |   PHASE 6: Authentication & Onboarding Harmonization        |
       +-------------------------------------------------------------+
```

---

## 2. Phase-by-Phase Implementation Plan

### Phase 1: Shared Shell & Global Layout Scaffolding
* **Primary Objective**: Eliminate floating glass dock content clipping, resolve FAB tap collisions, and establish uniform AppBar header conventions.
* **Scope & Targets**:
  1. `MainShellScreen`: Establish `const double kShellBottomDockPadding = 100.0`.
  2. Apply `EdgeInsets.only(bottom: kShellBottomDockPadding)` to `AthleteDashboardScreen`, `TournamentsListScreen`, `CommunityFeedScreen`, and `TrainingLogScreen`.
  3. Offset floating action buttons in `CommunityFeedScreen` and `TrainingLogScreen` by `84.0` logical pixels so they float safely above the navigation dock.
  4. Standardize `ArmSphereAppBar` component across all routes, enforcing uniform leading back icon geometry (`Icons.arrow_back_ios_new_rounded`), typography (`Outfit` 18sp), and action icon touch padding (min `48x48dp`).
* **Dependencies**: None.
* **Risk & Mitigation**: Low risk. Visual layout changes only; no business logic alteration.

---

### Phase 2: Standardized Federation Error & Empty State Cards
* **Primary Objective**: Eliminate raw technical error strings (`[401] Session Expired`), implement automatic token renewal, and provide two-way recovery navigation on all empty/error screens.
* **Scope & Targets**:
  1. Networking Layer: Implement Dio/Http auth interceptor to perform silent JWT refresh upon HTTP 401 before surfacing errors to UI.
  2. Implement `FederationErrorCard` component with an emblem, user-friendly copy, primary retry CTA, and secondary escape route button (`[Return to Home / Directory]`).
  3. Implement `FederationEmptyState` component with graphic illustration, informative explanation, and actionable discovery CTA.
  4. Migrate affected screens:
     - `ChampionshipsListScreen` (`S-043`)
     - `DisputeDetailScreen` (`S-045`)
     - `MyNominationsScreen` (`S-052`)
     - `TeamsListScreen` (`S-054`)
     - `FederationBulletinsScreen` (`S-047`)
     - `TournamentDetailScreen` (`S-038`)
     - `AthleteInboxScreen` (`S-042`)
* **Dependencies**: Relies on Phase 1 for standardized padding and styling tokens.
* **Risk & Mitigation**: Medium risk. Interceptor logic must handle network timeouts gracefully without infinite refresh loops.

---

### Phase 3: Intake Forms & Sticky Bottom CTA Bar Standard
* **Primary Objective**: Fix keyboard occlusion across all data intake funnels and ensure primary submit buttons remain docked, visible, and clickable above the soft keyboard.
* **Scope & Targets**:
  1. Create `StickyFormScaffold`:
     - Scrollable body with keyboard-aware bottom padding.
     - Anchored `bottomNavigationBar` container styled with frosted dark surface and top divider.
     - Real-time form validation state listener dynamically enabling/disabling the CTA.
  2. Migrate all intake screens to `StickyFormScaffold`:
     - `CreatePostScreen` (`S-020`)
     - `SubmitVenueScreen` (`S-049`)
     - `CreateInformalEventScreen` (`S-051`)
     - `NominateTalentScreen` (`S-053`)
     - `CreateTeamScreen` (`S-055`)
     - `UploadEvidenceScreen` (`S-016`)
     - `SubmitComplaintScreen` (`S-036`)
     - `ApplyRoleScreen` (`S-033`)
  3. Redesign `EventRegistrationScreen` (`S-044`):
     - Replace isolated bottom button with an anchored `RegistrationSummaryCard` showing real-time division fee, arm surcharge, and total calculation.
* **Dependencies**: Relies on Phase 1 design tokens.
* **Risk & Mitigation**: Low risk. Greatly improves form completion rates across all mobile viewports.

---

### Phase 4: Core Role Dashboards & High-Stakes Guardrails
* **Primary Objective**: Prevent accidental data loss in table-side refereeing, prevent accidental destructive account actions, and eliminate disorientation during persona switching.
* **Scope & Targets**:
  1. `ScorepadScreen` (`S-014`):
     - Remove `[Reset Score]` from bottom bar; relocate to top overflow menu.
     - Require 2-second hold-to-confirm for match reset.
     - Implement `PopScope` exit barrier to protect live scoring tallies.
  2. `RefereeDashboardScreen` (`S-012`):
     - Rebalance action grid: promote `[Open Scorepad]` to prominent full-width hero card.
     - Demote administrative tasks (`[Certifications]`, `[Evidence]`) to secondary grid below.
  3. Persona Switching (`S-010`, `S-017`):
     - Remove `[Official Mode]` toggle switch from `AthleteProfileScreen`.
     - Implement universal AppBar persona switcher.
     - Require explicit confirmation dialogue before switching active personas.
  4. Security & Deletion Guardrails (`S-018`, `S-032`):
     - Move `[Revoke All Other Sessions]` to list bottom with confirmation modal.
     - Add 5-second countdown timer and biometric challenge to `[Delete Account Permanently]`.
* **Dependencies**: Relies on Phases 1–3 for UI components and error handling.
* **Risk & Mitigation**: High criticality. Must be verified with simulated table-side referee testing.

---

### Phase 5: Secondary Directories, Canvases & Social Hubs
* **Primary Objective**: Eliminate dual-action creation antipatterns across directories, optimize canvas gesture controls, and harmonize social media viewing.
* **Scope & Targets**:
  1. Directory Creation Consolidation:
     - Standardize on `FloatingActionButton.extended` or top-right AppBar `[+ New]` button across `VenueDirectoryScreen` (`S-048`), `InformalEventDirectoryScreen` (`S-050`), and `TeamsListScreen` (`S-054`).
     - Remove redundant empty-state creation buttons that disappear when data loads.
  2. Interactive Canvases:
     - Add explicit `[+]` / `[-]` zoom buttons and `[Reset View]` button to `TournamentBracketsScreen` (`S-039`).
  3. Head-to-Head Analytics (`S-037`):
     - Increase arm comparison toggle pill opacity to 90% with gold border on active arm.
     - Make contender avatars clickable to open their athlete passports directly.
  4. Reels & Chat (`S-021`, `S-046`):
     - Increase right margin on Reels action rail to 20px to avoid Android edge back gestures.
     - Disable message input and send button on `ChatScreen` when thread is unauthorized.
* **Dependencies**: Relies on Phases 1–4.
* **Risk & Mitigation**: Low risk. Enhances usability and visual consistency across secondary modules.

---

### Phase 6: Authentication & Onboarding Flow Harmonization
* **Primary Objective**: Review and harmonize unauthenticated splash, login, registration, and onboarding flows within a secondary emulator or sandbox environment.
* **Scope & Targets**:
  1. Run sandbox build on secondary test device/emulator.
  2. Align `WelcomeScreen`, `LoginScreen`, `RegisterScreen`, `ForgotPasswordScreen`, and `OnboardingScreen` with the Phase 1–3 design tokens (gold accents, sticky form buttons, dignified error cards).
  3. Verify that auth redirects and biometric logins integrate smoothly with the newly scaffolded dashboard.
* **Dependencies**: Relies on all preceding phases.
* **Risk & Mitigation**: Zero risk to production device session since work is conducted in an isolated secondary environment.

---

## 3. Regression Testing & Verification Protocol

For each completed phase, the following three-stage verification must be performed:

1. **Flutter Static Analysis**:
   ```powershell
   flutter analyze --no-fatal-infos
   ```
2. **Component & Golden Tests**:
   - Verify layout rendering on both standard mobile (720×1612) and compact mobile (360×640) dimensions.
   - Verify keyboard appearance does not cause `RenderFlex overflowed` errors on any form.
3. **Physical Device Smoke Test**:
   - Verify on `TECNO_BG6` that floating dock clearance, back gesture safety, and sticky button docking function smoothly without frame drops.
