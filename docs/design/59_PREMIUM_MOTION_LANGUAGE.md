# ArmSphere Stage 4 — Premium Motion & Interaction Language Specification
**Document Version**: 1.0.0 (Authoritative Stage 4 Architecture)
**Date**: September 26, 2026
**Status**: APPROVED & LOCKED INTO REPOSITORY
**Authority**: `docs/design/00_DESIGN_AUTHORITY.md`, `UI_UX_DESIGN_STATE.md`, & Stage 4 Master Directive
**Scope**: 5-Tier Motion Choreography System, Strict Flutter Curve Governance, Spatial Continuity Transition Protocols, and the 10-State Micro-Interaction Physics Engine.

---

## 1. Executive Purpose & Physical Motion Physics

Motion in ArmSphere is not decorative entertainment; it is an **instrument of physical feedback and spatial orientation**. Armwrestling is a combat sport governed by raw kinetic leverage, explosive isometric holds, and sudden, decisive pin drops.

The motion engine mirrors these physical realities:
- **Instantaneous Touch Registration**: Sub-50ms tactile feedback eliminates perceived latency.
- **Snappy Combat Decelerations**: Mechanical components snap into place with authoritative cubic deceleration (`Curves.easeOutCubic`).
- **Zero Playful Bouncing**: Playful, springy, or jelly-like animations (`bounceOut`, `elasticOut`) are **permanently banned**. A sports federation platform must communicate absolute structural rigidity and weight.

---

## 2. The 5-Tier Motion Choreography System

Every animation in the mobile client must belong to one of five rigorously bounded duration tiers:

```
+-----------------------------------------------------------------------------------+
|                        5-TIER MOTION CHOREOGRAPHY MATRIX                          |
|                                                                                   |
|  TIER 0: NO MOTION (0ms)           -> Instant state flips, accessibility mode     |
|  TIER 1: MICRO FEEDBACK (80-120ms) -> Button scale depression (0.97x), haptic tick|
|  TIER 2: LOCAL TRANSITION (180-240ms)-> Sheet expansion, accordion drawer, filters|
|  TIER 3: SCREEN CHOREOGRAPHY (250-320ms)-> Shared hero element, route push/pop    |
|  TIER 4: CINEMATIC CEREMONY (600-900ms)-> Elo surge count-up, championship sheen  |
+-----------------------------------------------------------------------------------+
```

### Detailed Tier Specifications

| Tier | Duration Window | Approved Easing Curve | Visual & Spatial Mechanics | Haptic Trigger | Typical Triggers |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Tier 0: Immediate** | `0ms` | Instant (`Curves.linear`) | Immediate content swap; zero frame interpolation. Used when `disableAnimations == true` or live hardware sync updates. | None | Hardware disconnect, accessibility override, fast tab cycling. |
| **Tier 1: Micro Feedback** | `80ms – 120ms` | `Curves.easeOutQuad` | Scale depression to `0.97x` on tap-down; spring return to `1.0x` on release. Subtle 1px border illumination. | `HapticFeedback.lightImpact()` | Scorepad button tap, tab select, chip filter tap, form submit click. |
| **Tier 2: Local Transition** | `180ms – 240ms` | `Curves.easeOutCubic` | Vertical translation (`Offset(0, 0.1)` to `Offset.zero`) + alpha fade. Accordion height expansion. | `HapticFeedback.selectionClick()`| Bottom sheet open/close, category drawer expand, dropdown open. |
| **Tier 3: Screen Choreography** | `250ms – 320ms` | `Curves.easeOutCubic` | Directional horizontal slide (`Offset(0.08, 0)` -> `Offset.zero`) with shared element Hero flight for avatars and tournament cards. | None | Screen push/pop, bottom nav tab switch, bracket detail view. |
| **Tier 4: Cinematic Ceremony** | `600ms – 900ms` | `Curves.easeInOutCubic` | 45-degree sweeping linear gold gradient sheen across card surface; radial glow bloom; sequential numerical count-up. | `HapticFeedback.heavyImpact()` | Championship win, Elo surge modal, Weigh-in official stamp. |

---

## 3. Strict Flutter Curve Governance (Approved vs. Banned)

Flutter provides dozens of easing curves. Only four curves are certified for production use in ArmSphere:

```
+-----------------------------------------------------------------------------------+
|                           CURVE GOVERNANCE MATRIX                                 |
|                                                                                   |
|  [CERTIFIED FOR USE]                       [STRICTLY BANNED AS SLOP]              |
|  * Curves.easeOutCubic  (Deceleration)     X Curves.bounceOut   (Jelly bounce)    |
|  * Curves.easeInOutCubic (Ceremonies)      X Curves.bounceInOut (Jelly bounce)    |
|  * Curves.easeOutQuad   (Micro feedback)   X Curves.elasticOut  (Cartoon spring)  |
|  * Curves.easeInQuad    (Stamp drop only)  X Curves.elasticInOut(Cartoon spring)  |
+-----------------------------------------------------------------------------------+
```

### Rationale for Bans:
- **`Curves.bounceOut` & `Curves.elasticOut`**: Create visual oscillation that makes UI controls feel imprecise, cheap, and delayed. In an official match scorepad, an element bouncing after being tapped causes cognitive panic (did the tap register, or is it undoing itself?).
- **`Curves.easeOutCubic`**: Provides immediate high-velocity feedback at $T=0$ and smoothly decelerates into rest, mimicking the deceleration of a heavy steel plate sliding across an anvil.

---

## 4. Accessibility & Reduced Motion Mandate

Every animation in ArmSphere must strictly respect the operating system's accessibility settings:

```dart
/// Universal Motion Safety Extension for Flutter
extension MotionSafety on BuildContext {
  /// Evaluates whether the system has requested reduced motion.
  bool get prefersReducedMotion => MediaQuery.of(this).disableAnimations;

  /// Returns 0ms if reduced motion is enabled; otherwise returns the standard duration.
  Duration safeDuration(Duration standardDuration) {
    return prefersReducedMotion ? Duration.zero : standardDuration;
  }
}
```

*RULE: When `prefersReducedMotion` is true, all duration tiers collapse to 0ms instant cuts. The app remains 100% functionally operable without visual motion.*

---

## 5. Spatial Continuity & Screen Transition Language

Users must always understand **where they came from, where they are going, and what changed**:

```
+-----------------------------------------------------------------------------------+
|                        SPATIAL NAVIGATION CONTINUITY                              |
|                                                                                   |
|  [FORWARD PUSH]      -> Screen enters from Right (+8% X-axis offset), 280ms cubic |
|  [BACKWARD POP]      -> Current screen exits to Right (+8% X-axis offset), 240ms  |
|  [MODAL SHEET ENTRY] -> Sheet rises from Bottom (+100% Y-axis), 260ms cubic       |
|  [MODAL SHEET EXIT]  -> Sheet sinks to Bottom (+100% Y-axis), 200ms cubic         |
|  [ROLE SWITCH FLIP]  -> Horizontal 3D perspective flip (180° Y-axis), 300ms cubic |
+-----------------------------------------------------------------------------------+
```

### Hero Element Shared Transitions:
1. **Tournament Card to Tournament Detail**: The tournament hero banner seamlessly expands from the 16dp rounded card into the full-bleed detail hero backdrop via Flutter `Hero` widget with `Curves.easeOutCubic`.
2. **Athlete Avatar to Athlete Profile**: The 48dp circular avatar smoothly flies and scales into the 96dp profile crest.
3. **Bracket Match Node to Live Bout**: The selected bracket card expands radially into the split-screen match face-off canvas.

---

## 6. The 10-State Micro-Interaction Physics Engine

Every interactive component across all 66 screens conforms to a unified 10-state interaction matrix:

| Interaction State | Scale | Border Illumination | Surface Color | Haptic Feedback | Visual Mechanism |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1. IDLE** | `1.00x` | `borderVisible (#334155)` | `surfaceSecondary (#1E293B)` | None | Rest state with directional top sheen. |
| **2. PRESSED** | `0.97x` | `borderLight (#475569)` | `Color(0xFF161F2E)` | `HapticFeedback.lightImpact()` | Instant 100ms scale depression. |
| **3. FOCUSED** | `1.00x` | `borderActiveCyan (#38BDF8)` | `surfaceSecondary (#1E293B)` | None | 1.5px high-contrast cyan outline. |
| **4. LOADING** | `1.00x` | `borderVisible (#334155)` | `surfaceSecondary (#1E293B)` | None | Skeleton shimmer wave (1200ms linear loop). |
| **5. SUCCESS** | `1.00x` | `combatEmerald (#10B981)` | `Color(0xFF0D281E)` | `HapticFeedback.mediumImpact()`| 200ms flash into deep emerald surface. |
| **6. FAILURE** | `1.00x` | `combatCrimson (#EF4444)` | `Color(0xFF2A1215)` | `HapticFeedback.heavyImpact()` | 3-cycle horizontal micro-shake (±4dp, 160ms). |
| **7. DISABLED** | `1.00x` | `borderSubtle (#1E293B)` | `Color(0xFF0F1520)` | None | 40% alpha opacity; zero pointer events. |
| **8. SELECTED** | `1.00x` | `borderActiveCyan (#38BDF8)` | `surfaceTertiary (#283548)` | `HapticFeedback.selectionClick()`| Cyan bottom notch indicator illuminates. |
| **9. LIVE ACTIVE** | `1.00x` | `combatCrimson (#EF4444)` | `surfaceSecondary (#1E293B)` | None | 1Hz gentle breathing aura (4dp blur halo). |
| **10. COMPLETE** | `1.00x` | `goldPrimary (#D4AF37)` | `Color(0xFF241E0D)` | `HapticFeedback.heavyImpact()` | Gold medallion drop + 45° sweeping sheen. |

---

## 7. Reusable Motion Widgets in Production

All motion patterns are implemented via standardized, reusable Flutter primitives in `apps/mobile/lib/core/widgets/`:

1. **`ElevatedActionCard`**: Wraps any content container with the standard 100ms Tier 1 touch depression (`0.97x`), light haptic impulse, and directional top-edge chamfer.
2. **`SignatureCeremonies`**:
   - `EloSurgeModal`: Manages the Tier 4 sequential rating count-up with resonant bell audio and delta badge explosion.
   - `ChampionshipGoldCard`: Executes the 45-degree sweeping linear gold gradient sheen (`LinearGradient(begin: -1.0, end: 2.0)`).
   - `WeighInClearanceStamp`: Executes the physical rubber stamp clearance (140ms `Curves.easeInQuad` scale drop from `1.8x` to `1.0x` with `-8°` tilt and `HapticFeedback.heavyImpact()`).

---

## 8. Architectural Sign-Off
This motion language specification eliminates arbitrary timing values, erratic easing curves, and performance-degrading animation loops. It is authoritative for all transition builders, gesture detectors, and ceremonial overlays across ArmSphere.
