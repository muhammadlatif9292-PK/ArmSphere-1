# ArmSphere UI/UX Persistent Design State
**Long-Term Architectural Memory & Experience Authority for Future AI Sessions**
**Document Version**: 2.0.0 (Authoritative Comprehensive)
**Lock Date**: September 25, 2026
**Location**: Repository Root (`UI_UX_DESIGN_STATE.md`)
**Canonical Authority Documents**: `docs/design/` (00 through 44, 46 files total)

---

> [!IMPORTANT]
> **MANDATE FOR ALL FUTURE AGENTS & AI SESSIONS:**
> Do NOT rely on conversation memory. Before proposing, reviewing, refactoring, or implementing ANY UI/UX code, animation, or design token in this repository, you **MUST read this document and the referenced design specifications in `docs/design/`**.
> Never invent product features, never alter database schema names, never introduce web-only animation packages into Flutter, and never apply generic AI templates.

---

## 1. Canonical Authority Directory (46 Documents)

| Range | Core Focus | Authoritative Specifications |
| :--- | :--- | :--- |
| **00–05** | **Foundational Architecture** | `00_DESIGN_AUTHORITY.md`, `00_MASTER_UI_UX_VISION.md`, `01_PRODUCT_EXPERIENCE_AUDIT.md`, `02_FEATURE_INVENTORY.md`, `03_SCREEN_INVENTORY.md`, `04_NAVIGATION_ARCHITECTURE.md`, `05_INFORMATION_ARCHITECTURE.md` |
| **06–13** | **Design System & Motion** | `06_DESIGN_SYSTEM.md`, `07_COLOR_AND_THEME_TOKENS.md`, `08_TYPOGRAPHY_SYSTEM.md`, `09_COMPONENT_SYSTEM.md`, `10_INTERACTION_SYSTEM.md`, `11_MOTION_SYSTEM.md`, `12_SCREEN_TRANSITIONS.md`, `13_SCROLL_AND_CAROUSEL_SYSTEM.md` |
| **14–20** | **Media, Access & Roles** | `14_IMAGE_ASSET_STRATEGY.md`, `15_VIDEO_ASSET_STRATEGY.md`, `16_AI_GENERATION_PROMPT_LIBRARY.md`, `17_MEDIA_PERFORMANCE_BUDGET.md`, `18_ACCESSIBILITY_SPEC.md`, `19_OFFLINE_AND_NETWORK_UX.md`, `20_ROLE_BASED_UX.md` |
| **21–29** | **Specs, Quality & Handoff**| `21_USER_JOURNEY_MAP.md`, `22_SCREEN_BY_SCREEN_SPEC.md`, `23_COMPONENT_USAGE_RULES.md`, `24_ANTI_SLOP_RULES.md`, `25_DESIGN_DECISION_REGISTER.md`, `26_OPEN_QUESTIONS.md`, `27_UI_UX_IMPLEMENTATION_BACKLOG.md`, `28_DESIGN_QA_CHECKLIST.md`, `29_FINAL_DESIGN_HANDOFF.md` |
| **30–35** | **Experience & Art Direction**| `30_PREMIUM_EXPERIENCE_PATTERN_LIBRARY.md`, `31_ACTION_CHOREOGRAPHY.md`, `32_HAPTIC_AND_AUDIO_UX.md`, `33_UX_COPY_SYSTEM.md`, `34_PERSONALIZATION_AND_CONTEXT.md`, `35_MEDIA_ART_DIRECTION.md` |
| **36–44** | **Resilience, QA, Governance & Closure**| `36_ERROR_RECOVERY_UX.md`, `37_VISUAL_QA_PROTOCOL.md`, `38_PREMIUM_MOMENT_CATALOG.md`, `39_DESIGN_DEBT_MAP.md`, `40_ASSET_PRODUCTION_PIPELINE.md`, `41_DESIGN_RECONCILIATION.md`, `42_MASTER_EXPERIENCE_MAP.md`, `43_DESIGN_GOVERNANCE.md`, `44_DESIGN_CLOSURE_VERIFICATION.md` |

---

## 2. Approved Design Tokens (Mathematically Locked)

```dart
// Foundational Canvas & Surface Tiers
static const Color voidBackground     = Color(0xFF070A11); // Canvas Substrate
static const Color background         = Color(0xFF0B0F19); // Elevated Viewport Base
static const Color cardSurface        = Color(0xFF121826); // Base Solid Card
static const Color elevatedSurface    = Color(0xFF1E293B); // Elevated Action Cell
static const Color border             = Color(0xFF334155); // Structural Divider (1px)

// Semantic Accents (WCAG AA/AAA Verified)
static const Color primaryAccent      = Color(0xFFEF4444); // Coral Crimson (Table Fouls & Forfeits)
static const Color secondaryAccent    = Color(0xFFF59E0B); // Amber Warning & Sanction Pending
static const Color goldPrimary        = Color(0xFFD4AF37); // Champagne Gold (Championships, Medals, CTAs)
static const Color goldLight          = Color(0xFFF5E096); // Soft Gold Sheen
static const Color goldGlow           = Color(0x33D4AF37); // 20% Gold Halo
static const Color success            = Color(0xFF10B981); // Emerald Mint (Weigh-In Cleared, Pins, Wins)
static const Color error              = Color(0xFFFF5252); // High-Contrast Coral Red
static const Color warning            = Color(0xFFF97316); // High-Contrast Orange
static const Color info               = Color(0xFF38BDF8); // Luminous Cyan / Sky Blue (8.94:1 contrast)

// Typography & Neutrals
static const Color textPrimary        = Color(0xFFF8FAFC); // 18.2:1 contrast against canvas
static const Color textSecondary      = Color(0xFF94A3B8); // 7.8:1 contrast
static const Color textMuted          = Color(0xFF8493A5); // 4.8:1 contrast
static const String fontDisplay       = 'SpaceGrotesk';   // Display, ELO, Scores, Monospace Readouts
static const String fontBody          = 'Inter';          // UI Prose, Form Labels, Captions

// Spatial Grid & Radii
static const double space4 = 4.0, space8 = 8.0, space12 = 12.0, space16 = 16.0, space20 = 20.0, space24 = 24.0;
static const double radiusSmall = 8.0, radiusMedium = 12.0, radiusLarge = 16.0, radiusCircular = 999.0;
// BANNED: Never use radiusCircular (999dp) on primary action buttons or form submit bars.
```

---

## 3. Motion & Sensory Physics Standards

- **Touch Latency Budget**: Instant tactile feedback registered in `<50ms` (scale `0.97x`, haptic impulse).
- **Duration Tiers**:
  - `Level 0 (Micro Feedback)`: 100–150ms (`Curves.easeOutQuad`) — button press down, score increment.
  - `Level 1 (Local Transitions)`: 200–250ms (`Curves.easeInOutCubic`) — accordions, comment sheets.
  - `Level 2 (Navigation Routes)`: 250–300ms (`Curves.easeOutCubic`) — push/pop screen exchanges.
  - `Level 3 (Feature Moments)`: 400–600ms (`Curves.easeOutCubic`) — match win, ELO count-up.
  - `Level 4 (Cinematic Moments)`: 800–1200ms (`Curves.easeInOutCubic`) — splash boot, championship crowning.
- **Strict Motion Constraints**: Banned curves: `bounceOut` and `elasticOut`. Strictly honors `MediaQuery.of(context).disableAnimations` with instant transitions.
- **Haptic Disciplines**:
  - Scorepad taps: `HapticFeedback.lightImpact()`.
  - Pin lock: 400ms hold with continuous ticks into `HapticFeedback.heavyImpact()`.
  - Rapid tap throttling: Maximum 1 haptic event per 120ms.
- **Audio Disciplines**:
  - Exactly 3 preloaded sounds: `challenge_accepted.wav`, `match_won.mp3`, `pr_achieved.wav`.
  - Zero UI click sounds. Strictly obeys Android silent/vibrate ringer mode and audio ducking.

---

## 4. Anti-Slop & Quality Gates (Zero AI UI)

1. **NO Home Screen Database Dumping**: Home Tab 0 uses the **Dynamic Briefing Model** (`34_`), surfacing the single most urgent athletic context (T-7d to Post-Event).
2. **NO 999dp Pill Buttons**: All primary action buttons strictly use `radiusMedium` (12dp) or `radiusSmall` (8dp).
3. **NO Nested Glassmorphism**: `BackdropFilter` is restricted strictly to floating AppBars and modals; lists use solid `#121826` cards.
4. **NO Purposeless Particle Loops**: Battery-draining continuous canvas math is strictly banned.
5. **NO Inline Autoplay Video**: Feed videos show lightweight thumbnails; videos play on-demand inside `VideoPlayerModal`.
6. **NO Fake AI Human Faces**: Generated imagery is strictly restricted to arena backgrounds, knurled metal, and title belts (`35_`).
7. **NO Patronizing AI Microcopy**: Zero cheerleading or robotic error messages. Strict athletic action verbs (`33_`).

---

## 5. Screen Inventory & Code State

- **Total Screen Classes**: 66 Screens + 3 Modals mapped.
- **Database Tables**: 58 Neon PostgreSQL tables mapped to Drizzle ORM.
- **Federation Personas**: 9 verified roles with active role-switching.
- **Codebase Health**:
  - Design Architecture & Specifications: **100% COMPLETE & LOCKED** (Docs 00–44).
  - Implementation Progress: **PHASE 1 (P0: Slices 1–5), PHASE 2 (P1: Slices 6–10), and PHASE 3 (P2: Slices 11–12) 100% COMPLETED & VERIFIED**.

---

## 6. Phased Implementation Roadmap (Grounded in `39_DESIGN_DEBT_MAP.md`)

### Phase 1: Critical Ergonomics & Brokenness (P0) — [100% COMPLETED]
1. **Slice 1 (P0)**: Theme Token Normalization & Centralized Theme (`core/theme/app_theme.dart`, `core/theme/theme.dart`, `core/widgets/elevated_action_card.dart`, `core/widgets/status_chip.dart`) — **[COMPLETED & VERIFIED]**
2. **Slice 2 (P0)**: Referee Scorepad Hit Target Expansion (64dp) & 400ms Pin Long-Press (`features/referee/widgets/live_scorepad_controller.dart`, `referee_screens.dart`) — **[COMPLETED & VERIFIED]**
3. **Slice 3 (P0)**: Discover Screen AppBar cleanup, sticky search bar with 300ms debouncing, standardized category chips (8dp radiusSmall), Federation Hub quick portal carousel, and ElevatedActionCard upgrades (`features/home/screens/discover_screen.dart`, `features/search/screens/search_screen.dart`) — **[COMPLETED & VERIFIED]**
4. **Slice 4 (P0)**: Form sticky bottom action bars with keyboard avoidance and 640dp responsive constraints (`core/widgets/sticky_bottom_action_bar.dart`, `event_registration_screen.dart`, `submit_complaint_screen.dart`, `submit_venue_screen.dart`, `login_screen.dart`, `register_screen.dart`) — **[COMPLETED & VERIFIED]**
5. **Slice 5 (P0)**: Tournament Detail hero scrim gradient, dynamic 1s countdown badge, StatusChip, rulebook/timeline widgets & sticky registration CTA (`features/tournament/screens/tournament_screens.dart`) — **[COMPLETED & VERIFIED]**

### Phase 2: Structural Consistency & Identity (P1) — [100% COMPLETED]
6. **Slice 6 (P1)**: 3-Step Animated Onboarding Wizard & Complete Entry Journey Migration:
   - `splash_screen.dart`: Screen Spec 01 compliant (void canvas #070A11, gold-embossed insignia badge, Space Grotesk wordmark, gold loader, Level 4 cinematic easing).
   - `welcome_screen.dart`: Screen Spec 02 compliant (`ElevatedActionCard` pillars, zero nested glassmorphism, Space Grotesk headings, high-contrast gold primary CTA, zero 999dp pill buttons).
   - `role_intent_screen.dart`: Canonical role picker (`StickyBottomActionBar`, `ElevatedActionCard` options, 48dp+ tap targets, Space Grotesk typography, gold-styled federation verification dialog).
   - `onboarding_screen.dart`: 3-step directional `PageView` wizard (280ms cubic slide), `StepHeader`, `StickyBottomActionBar`, interactive gold sliders with haptic ticks, and Space Grotesk numeric readouts.
   - `login_screen.dart` & `register_screen.dart`: Gold primary insignia, Space Grotesk brand typography, high-contrast gold primary submit buttons with tactile haptics, and gold prefix icons. — **[COMPLETED & VERIFIED]**
7. **Slice 7 (P1)**: Dual-Role Persona Switcher in athlete profile header (`features/athlete/screens/athlete_screens.dart`) — **[COMPLETED & VERIFIED]**
8. **Slice 8 (P1)**: Interactive Bracket Viewer canvas virtualization, RepaintBoundary isolation & active table glow (`features/tournament/widgets/bracket_tree_widget.dart`, `compact_bracket_match_card.dart`, `full_interactive_bracket_modal.dart`) — **[COMPLETED & VERIFIED]**
9. **Slice 9 (P1)**: Standardized Shimmer Skeleton Loader & Empty States across all surfaces (`core/widgets/skeleton_placeholder.dart`, `core/widgets/app_empty_state.dart`) — **[COMPLETED & VERIFIED]**
10. **Slice 10 (P1)**: Shell ambient particle loop removal for 30-minute battery optimization (`core/widgets/ambient_particle_background.dart`, `core/widgets/main_shell_screen.dart`) — **[COMPLETED & VERIFIED]**

### Phase 3: Sensory Polish & Ceremonies (P2) — [100% COMPLETED]
11. **Slice 11 (P2)**: Multi-sensory integration: wiring 3 approved sounds + haptics to `SensoryFeedbackService` (`core/services/sensory_feedback_service.dart`, `core/audio/sound_service.dart`, `create_post_screen.dart`, `training_log_screen.dart`) — **[COMPLETED & VERIFIED]**
12. **Slice 12 (P2)**: Signature Ceremonial Moments (`core/widgets/signature_ceremonies.dart`, `weigh_in_verification_widget.dart`):
    - `EloSurgeModal`: Bout win celebratory ELO count-up, resonant bell, and delta surge badge.
    - `ChampionshipGoldCard`: 45-degree sweeping linear gold gradient sheen with medallion drop and share action.
    - `WeighInClearanceStamp`: Physical rubber stamp clearance (140ms `Curves.easeInQuad` scale drop from `1.8x` to `1.0x`, `-8°` tilt, and `HapticFeedback.heavyImpact()`).
    - Full eradication of `Curves.elasticOut` across all tournament and weigh-in widgets. — **[COMPLETED & VERIFIED]**

---

## 7. Verification Proof & Handoff Seal
This document synthesizes both Stage 1 and Stage 2 architectural outputs into a single permanent, non-contradictory authority file. All 12 priority implementation slices across Phase 1, Phase 2, and Phase 3—including the complete end-to-end Onboarding and Authentication entry journey—are 100% completed, rigorously verified, and grounded in the 46 canonical design documents in `docs/design/`.
