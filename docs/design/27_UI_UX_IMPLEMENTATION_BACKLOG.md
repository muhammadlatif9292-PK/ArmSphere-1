# ArmSphere UI/UX Implementation Backlog
**Phased Engineering Slices Prioritized Strictly by Usability & Impact**
**Document Version**: 1.0.0
**Status**: APPROVED & LOCKED

---

## 1. Backlog Prioritization Schema

Items are ranked strictly by **usability, architectural integrity, and operational impact**:
1. Usability & Accessibility (Touch targets, readability, contrast, error recovery)
2. Information Architecture & Navigation (Resolving clutter, eliminating friction)
3. Hierarchy & Scanning (Card structure, typographic discipline)
4. Interaction Quality (Tactile haptics, responsive form states)
5. Motion & Transitions (Purposeful spatial continuity)
6. Cinematic Polish (Ambient lighting, celebratory overlays)

```
┌────────────────────────────────────────────────────────────────────────┐
│                        PRIORITIZED BACKLOG SUMMARY                     │
├──────┬──────────────────────┬─────────────┬────────────────────────────┤
│ Tier │ Classification       │ Task Count  │ Focus                      │
├──────┼──────────────────────┼─────────────┼────────────────────────────┤
│ P0   │ Structural & Usability│ 06 Tasks    │ Core navigation & friction │
│ P1   │ Major Visual / Touch │ 08 Tasks    │ Cards, haptics, skeletons  │
│ P2   │ Premium Polish       │ 06 Tasks    │ Transitions, audio, badges │
│ P3   │ Optional Enhancement │ 04 Tasks    │ Ambient hero video loops   │
└──────┴──────────────────────┴─────────────┴────────────────────────────┘
```

---

## 2. P0: Fundamental Structural & Usability Slices (Launch-Critical)

### [P0-01] Eliminate Discover Screen AppBar Clutter
- **Problem**: 5 action buttons packed into Discover AppBar (`/venues`, `/informal-events`, `/community/feed`, `/search`, `/home`) causing title truncation on narrow devices.
- **Solution**: Strip AppBar actions down to Search and Notifications. Move Venue Partners and Pickup Meetups into a clean, horizontal segmented discovery section on the Discover feed.
- **Files**: `apps/mobile/lib/features/home/screens/discover_screen.dart`.
- **Estimate**: 2 hours.

### [P0-02] Implement Sticky Bottom Action Bar with Keyboard Avoidance for Forms
- **Problem**: On `event_registration_screen.dart` and `submit_complaint_screen.dart`, opening the soft keyboard pushes the Submit CTA off-screen.
- **Solution**: Pin primary action buttons to a persistent bottom container with `MediaQuery.of(context).viewInsets.bottom` padding and safe-area wrapping.
- **Files**: `features/tournament/screens/event_registration_screen.dart`, `features/governance/screens/submit_complaint_screen.dart`.
- **Estimate**: 3 hours.

### [P0-03] Implement Dual-Role Persona Switcher for Certified Athletes
- **Problem**: Athletes who are certified referees must tap an obscure shortcut button to reach officiating tools, jumping out of the shell.
- **Solution**: Add an official role-switcher toggle in the athlete profile header for dual-role users, allowing smooth in-shell switching between Athlete and Official modes.
- **Files**: `features/athlete/screens/athlete_screens.dart`, `core/routing/app_router.dart`.
- **Estimate**: 4 hours.

### [P0-04] Standardize Shimmer Skeleton Loaders
- **Problem**: Several screens render raw centered circular progress indicators, causing jarring layout shifts when data arrives.
- **Solution**: Replace spinners on `TournamentsListScreen`, `RankingsScreen`, and `AthleteProfileScreen` with geometric shimmer placeholders (`SkeletonPlaceholder` / `ShimmerBox`).
- **Files**: `features/tournament/screens/tournament_screens.dart`, `features/athlete/screens/rankings_screen.dart`.
- **Estimate**: 3 hours.

### [P0-05] Add Physical Haptic Actuation to Table-Side Scorepad
- **Problem**: Referees tapping scorepads at physical tables receive no tactile feedback, causing uncertainty under pressure.
- **Solution**: Integrate `HapticFeedback.selectionClick()` on score increments and `HapticFeedback.heavyImpact()` on match completion.
- **Files**: `features/referee/screens/official_scorepad_screen.dart`, `features/referee/screens/referee_screens.dart`.
- **Estimate**: 2 hours.

### [P0-06] Unify Status Chip Token Mappings Across All Domains
- **Problem**: Status colors (green, amber, red) are declared inconsistently across tournament, governance, and weigh-in screens.
- **Solution**: Refactor all status chips to use the canonical `AppTheme` semantic status tokens.
- **Files**: `features/tournament/widgets/`, `features/governance/screens/governance_screens.dart`.
- **Estimate**: 2 hours.

---

## 3. P1: Major Visual & Interaction Enhancements

### [P1-01] De-Clutter Glassmorphism & Enforce 3-Tier Surface Hierarchy
- **Problem**: `GlassCard` applied indiscriminately across long vertical lists, causing GPU raster slowdowns.
- **Solution**: Implement `ElevatedActionCard` (solid dark slate `#141C2E` with 1px border) for dense list rows; reserve `GlassCard` strictly for hero and focal cards.
- **Files**: `core/widgets/glass_card.dart`, `features/athlete/screens/rankings_screen.dart`.
- **Estimate**: 4 hours.

### [P1-02] Upgrade Multi-Step Onboarding to Animated PageView
- **Problem**: Onboarding steps currently swap instantly via `setState`, creating an abrupt visual cut.
- **Solution**: Wrap steps in a directional animated `PageView` with smooth horizontal slide (280ms `Curves.easeInOutCubic`) and animated progress stepper.
- **Files**: `features/athlete/screens/onboarding_screen.dart`.
- **Estimate**: 3 hours.

### [P1-03] Eliminate Continuous Background Particle Loop in Shell Stack
- **Problem**: 50 animated particles running in `AmbientParticleBackground` continuously draw GPU cycles in the root stack.
- **Solution**: Replace with a performant static radial gradient substrate; freeze particles into an aesthetic backdrop.
- **Files**: `core/widgets/ambient_particle_background.dart`, `core/widgets/main_shell_screen.dart`.
- **Estimate**: 1.5 hours.

### [P1-04] Standardize 48dp Minimum Touch Targets
- **Problem**: Several micro-buttons and icon triggers have touch areas under 40dp.
- **Solution**: Wrap all icon buttons in padding ensuring a strict 48×48dp hit test box.
- **Files**: App-wide audit across `core/widgets/`.
- **Estimate**: 3 hours.

### [P1-05] Tabular Number Formatting on ELO and Timers
- **Problem**: Shifting number widths cause horizontal text jitter during countdowns and score updates.
- **Solution**: Apply `FontFeature.tabularFigures()` across all countdown clocks, ELO displays, and set scores.
- **Files**: `core/theme/app_theme.dart`, `features/tournament/widgets/live_countdown_timer_widget.dart`.
- **Estimate**: 2 hours.

### [P1-06] Refactor Login ↔ Register Transition into Directional Slide
- **Problem**: Switching between Login and Register causes an abrupt full-screen reload.
- **Solution**: Encase auth forms in an `AnimatedSwitcher` with directional horizontal slide (Login slides left; Register slides right).
- **Files**: `features/auth/screens/login_screen.dart`, `features/auth/screens/register_screen.dart`.
- **Estimate**: 2.5 hours.

### [P1-07] Add Unsaved Changes Protection on Event Registration & Scorepad
- **Problem**: Accidental back swipe discards in-progress registrations or active match scores without warning.
- **Solution**: Wrap screens in `PopScope` to show a confirmation bottom sheet before discarding state.
- **Files**: `features/tournament/screens/event_registration_screen.dart`, `features/referee/screens/official_scorepad_screen.dart`.
- **Estimate**: 2 hours.

### [P1-08] Refine Contrast on Subtitles and Secondary Metadata
- **Problem**: Some secondary text uses dark gray (`#64748B`), which falls slightly below 4.5:1 on deep substrates.
- **Solution**: Promote all secondary metadata to `AppTheme.textMuted` (`#8493A5`), guaranteeing verified 4.8:1 WCAG AA contrast.
- **Files**: `core/theme/app_theme.dart`.
- **Estimate**: 1.5 hours.

---

## 4. P2: Premium Polish & Athletic Ceremony

### [P2-01] Smooth Splash Exit to Welcome / Home
- **Problem**: Splash screen fade ends abruptly with a hard cut to the next route.
- **Solution**: Implement shared-element-like emblem scale-down transition into the AppBar or Welcome hero header.
- **Files**: `features/auth/screens/splash_screen.dart`.
- **Estimate**: 3 hours.

### [P2-02] Celebratory Confetti & Sound Trigger on PR Breakthrough
- **Problem**: Logging a personal record displays only a standard toast.
- **Solution**: Play `pr_achieved.wav` and trigger `CelebrationOverlay` golden particle burst when a lift exceeds previous PR.
- **Files**: `features/athlete/screens/training_log_screen.dart`.
- **Estimate**: 2 hours.

### [P2-03] Golden Sheen Border Shimmer on Active Championship Titles
- **Problem**: Championship belt cards look static and identical to ordinary tournament cards.
- **Solution**: Add an animated 1.5px gold gradient border sweep (`#D4AF37` to `#F5E096`) to active championship titles.
- **Files**: `features/championship/screens/championship_screens.dart`.
- **Estimate**: 2 hours.

### [P2-04] Interactive Pan/Zoom Enhancements on Double-Elimination Brackets
- **Problem**: Navigating dense 64-puller brackets can feel cramped on small phone screens.
- **Solution**: Add mini-map viewport radar indicator in bottom right corner of `TournamentBracketsScreen`.
- **Files**: `features/tournament/widgets/bracket_tree_widget.dart`.
- **Estimate**: 4 hours.

### [P2-05] High-Contrast Empty State Artwork
- **Problem**: Empty states display generic Material warning icons.
- **Solution**: Replace with bespoke isometric armwrestling table vector (`empty_state_table_vector.png`).
- **Files**: `core/widgets/app_empty_state.dart`.
- **Estimate**: 2 hours.

### [P2-06] Haptic Feedback Sound Sync Check
- **Problem**: Sound effects may play while phone is set to silent or vibrate.
- **Solution**: Check system ringer mode before playing audio assets to avoid embarrassing users in quiet venues.
- **Files**: `core/audio/audio_manager.dart`.
- **Estimate**: 1.5 hours.

---

## 5. P3: Optional Enhancements & Explorations

### [P3-01] Ambient Arena Video Loop for National Championship Hero
- **Task**: Load short 4s H.264 ambient arena video loop in `TournamentDetailsHeroWidget` on WiFi and high-end hardware.
- **Estimate**: 3 hours.

### [P3-02] Dynamic Radar Chart for Arm Biometrics
- **Task**: Upgrade athlete biometrics card with interactive 5-axis polygon radar chart (`PerformanceRadarChartPainter`).
- **Estimate**: 4 hours.

### [P3-03] 3D Championship Belt Interactive Tilt Effect
- **Task**: Apply subtle gyroscope / accelerometer tilt parallax to championship belt cards on profile.
- **Estimate**: 3 hours.

### [P3-04] Offline Bracket PDF Vector Export
- **Task**: Allow tournament operators to export a printable vector PDF of active brackets directly from the mobile app.
- **Estimate**: 5 hours.
