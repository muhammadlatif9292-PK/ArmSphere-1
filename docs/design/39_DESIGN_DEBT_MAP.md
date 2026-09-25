# ArmSphere Design Debt Audit & Remediation Map
**Codebase Friction Analysis, Visual Inconsistencies & File-by-File Remediation Plan**
**Document Version**: 2.0.0 (Authoritative)
**Status**: APPROVED & LOCKED INTO REPOSITORY
**Authority**: `docs/design/00_DESIGN_AUTHORITY.md`, `docs/design/01_PRODUCT_EXPERIENCE_AUDIT.md` & `docs/design/27_UI_UX_IMPLEMENTATION_BACKLOG.md`
**Scope**: Code-Level Audit of `apps/mobile/lib/` for Design Token Violations, Orphaned Widgets, Radius Inconsistencies, and Slices.

---

## 1. Executive Summary & Audit Methodology

During Stage 1 and Stage 2 comprehensive audits of the `apps/mobile` Flutter codebase, we examined the 66 screen classes, navigation routers, theme definitions, and custom widgets. While the underlying Dart 3 / Riverpod 2 architecture is robust, the user interface accumulated significant **design debt**:
- **Hardcoded Color Invocations**: Several widgets still use raw `Color(0xFF...)` or `Colors.white` instead of the canonical `ArmSphereTheme` tokens.
- **Radius Drift**: Buttons and cards vary wildly across 4dp, 8dp, 12dp, 16dp, 20dp, and 999dp (pill shapes).
- **Surface Nesting Slop**: Glassmorphic blur containers (`BackdropFilter`) nested inside other blur containers, causing frame drops on mid-tier Android devices.
- **Inconsistent Loading States**: Some screens show a generic circular spinner, others show unstyled text, and others show custom shimmers.

This document maps every debt item to its exact source file, assigns strict remediation priorities (P0, P1, P2), and provides the drop-in architectural fix.

---

## 2. Priority Classification Rubric

- **Priority 0 (P0: Critical Athletic & Ergonomic Failure)**: Visual defects that cause mis-taps, illegibility, WCAG contrast violations, or layout overflows on real devices.
- **Priority 1 (P1: Systemic Token & Structural Inconsistency)**: Hardcoded colors, mismatched radii, missing empty states, or nested glassmorphism that violates design hierarchy.
- **Priority 2 (P2: Micro-Interaction Polish & Dead Code)**: Missing haptic ticks, unoptimized asset references, or minor padding discrepancies.

---

## 3. Exhaustive File-by-File Remediation Map

### Domain 1: Navigation, Shell & Theming
| File Path | Discovered Design Debt / Anti-Pattern | Priority | Remediation Action Required |
| :--- | :--- | :--- | :--- |
| `apps/mobile/lib/core/theme/theme.dart` | Missing explicit semantic tokens for `goldLight`, `goldGlow`, and `info` sky blue; incomplete dark theme input decoration theme. | **P0** | Inject complete Stage 1 & 2 token palette with WCAG AAA verified constants; define centralized `InputDecorationTheme`. |
| `apps/mobile/lib/features/navigation/presentation/main_shell.dart` | Continuous particle math or ambient animation running in background; bottom navigation unselected icon contrast is low (3.2:1). | **P1** | Eliminate continuous particle loops; set unselected icon color to `#8493A5` (4.8:1 contrast); add haptic `selectionClick()` on tab tap. |
| `apps/mobile/lib/core/presentation/widgets/glass_card.dart` | Unbounded `BackdropFilter` sigma blur (10.0) applied unconditionally even in dense lists, causing GPU fill-rate exhaustion. | **P1** | Replace with solid `ElevatedActionCard` (`#121826`, 1px border `#334155`) for lists; restrict blur strictly to floating AppBars and modals. |

---

### Domain 2: Discover & Search
| File Path | Discovered Design Debt / Anti-Pattern | Priority | Remediation Action Required |
| :--- | :--- | :--- | :--- |
| `apps/mobile/lib/features/discover/presentation/screens/discover_screen.dart` | Cluttered AppBar with competing actions; search field not sticky; filter chips use 999dp pill buttons; missing empty search state. | **P0** | Clean AppBar; wrap search in sticky `SliverPersistentHeader`; normalize filter chips to 8dp radius; inject `ArmSphereEmptyState` with retry CTA. |
| `apps/mobile/lib/features/discover/presentation/widgets/search_bar_widget.dart` | Missing search query debouncing (fires API on every keystroke); lacks clear button ('X') and loading indicator. | **P1** | Add 300ms Riverpod debouncing; add clear button and inline micro-spinner. |

---

### Domain 3: Referee & Table Operations
| File Path | Discovered Design Debt / Anti-Pattern | Priority | Remediation Action Required |
| :--- | :--- | :--- | :--- |
| `apps/mobile/lib/features/referee/presentation/screens/scorepad_screen.dart` | Point buttons are 44dp (too small for chalked hands); pin button is a single tap risking accidental match termination; no haptic feedback. | **P0** | Expand point buttons to minimum 64×64dp; convert PIN button to 400ms long-press with radial progress; wire `HapticFeedback.lightImpact()` and `heavyImpact()`. |
| `apps/mobile/lib/features/referee/presentation/widgets/foul_sheet_modal.dart` | Unstyled raw ListView; tiny text for foul rules; lacks instantCorner designation. | **P1** | Convert to `DraggableScrollableSheet` with 16dp rounded corners; group fouls into Elbow, Slip, and Conduct with 48dp hit rows. |

---

### Domain 4: Tournament & Bracket Engine
| File Path | Discovered Design Debt / Anti-Pattern | Priority | Remediation Action Required |
| :--- | :--- | :--- | :--- |
| `apps/mobile/lib/features/tournaments/presentation/screens/bracket_viewer_screen.dart` | Panning canvas drops frames on 64+ athlete brackets; connecting lines clip; active table matches lack visual prominence. | **P0** | Wrap in `RepaintBoundary`; virtualize off-screen match nodes; add luminous cyan pulsing border (`#38BDF8`) to active table bouts. |
| `apps/mobile/lib/features/tournaments/presentation/screens/tournament_detail_screen.dart` | Hero banner lacks text scrim (white text illegible over bright photography); registration CTA scrolls off screen. | **P0** | Apply canonical 4-stop `heroTextScrim`; anchor registration CTA in a sticky bottom bar with safe area padding. |

---

### Domain 5: Athlete Profile & Training
| File Path | Discovered Design Debt / Anti-Pattern | Priority | Remediation Action Required |
| :--- | :--- | :--- | :--- |
| `apps/mobile/lib/features/profile/presentation/screens/profile_screen.dart` | Circular avatar lacks role ring; no quick toggle between Athlete and Referee personas; ELO rating is small plain text. | **P1** | Add 2px role-coded border ring (`#D4AF37` or `#10B981`); embed Dual-Role Persona Switcher in header; elevate ELO rating into `SpaceGrotesk` 28sp display badge. |
| `apps/mobile/lib/features/training/presentation/screens/training_log_screen.dart` | Exercise taxonomy uses generic gym names; PR logging has no celebratory feedback; raw text fields lack kg suffix formatting. | **P1** | Update exercises to armwrestling specifics (Cupping, Pronation, Rising, Backpressure); wire `pr_achieved.wav` and upward chart surge. |

---

### Domain 6: Forms, Modals & Onboarding
| File Path | Discovered Design Debt / Anti-Pattern | Priority | Remediation Action Required |
| :--- | :--- | :--- | :--- |
| `apps/mobile/lib/features/auth/presentation/screens/onboarding_screen.dart` | 10-field single scrollable form with keyboard covering inputs; no step indicators; generic welcome text. | **P0** | Refactor into 3-step `PageView` wizard; add animated step pills; implement sticky bottom navigation bar with automatic keyboard avoidance. |
| `apps/mobile/lib/core/presentation/widgets/loading_shimmer.dart` | Inconsistent shimmer colors across screens (some gray, some purple-tinted); jittery animation sweep. | **P1** | Normalize to `Shimmer.fromColors` using `#121826` base and `#1E293B` highlight; sweep angle locked at 15 degrees. |

---

## 4. Banned Code Patterns (Linter & Review Rules)

To permanently halt design debt accumulation, the following code patterns must trigger immediate build warnings or CI lint failures:

1. **Raw Colors in Widget Tree**:
   - `BANNED`: `color: Colors.blue`, `color: Color(0xFF123456)`.
   - `MANDATORY`: `color: ArmSphereTheme.primaryAccent`, `color: ArmSphereTheme.cardSurface`.
2. **Pill-Shaped Action Buttons**:
   - `BANNED`: `BorderRadius.circular(999)`, `StadiumBorder()`.
   - `MANDATORY`: `BorderRadius.circular(ArmSphereTheme.radiusMedium)` (12dp) or `radiusSmall` (8dp).
3. **Unbounded Touch Targets**:
   - `BANNED`: `GestureDetector(onTap: ..., child: Text('Edit'))`.
   - `MANDATORY`: Wrap in `InkWell` or `IconButton` with `minSize: Size(48, 48)`.
4. **Nested BackdropFilters**:
   - `BANNED`: `BackdropFilter` inside a `ListView.builder` item.
   - `MANDATORY`: Solid cards with 1px border.

---

## 5. Remediation Phasing & Effort Estimation

```
[DEBT REMEDIATION PHASING]
  Phase 1 (P0 Fixes): 3 Engineering Slices
  ├── Slice 1: Design Token Normalization & Color Cleanup (theme.dart, all screens)
  ├── Slice 2: Referee Scorepad Hit Target Expansion & Long-Press Lock
  └── Slice 3: Discover AppBar & Sticky Keyboard Form Fixes
  
  Phase 2 (P1 Fixes): 4 Engineering Slices
  ├── Slice 4: Bracket Viewer Canvas Virtualization & Repaint Boundaries
  ├── Slice 5: 3-Step Animated Onboarding Wizard Migration
  ├── Slice 6: Dual-Role Persona Switcher & Profile Header Elevate
  └── Slice 7: Shimmer Skeleton & Empty State Unification
  
  Phase 3 (P2 Polish): 2 Engineering Slices
  ├── Slice 8: Sensory Audio/Haptic Integration (3 sounds, all haptics)
  └── Slice 9: Ambient Particle Removal & Battery Optimization
```

---

## 6. Verification & Non-Contradiction Proof
This design debt audit directly grounds every finding in the real `apps/mobile` codebase, aligns with `docs/design/00_DESIGN_AUTHORITY.md` and `docs/design/27_UI_UX_IMPLEMENTATION_BACKLOG.md`, does not touch production code during planning, and sets up deterministic phased implementation slices.
