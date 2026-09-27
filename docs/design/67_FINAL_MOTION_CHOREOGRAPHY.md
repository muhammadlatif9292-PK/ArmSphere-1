# ArmSphere Final Motion Choreography & Timing Engine
**Document Version**: 1.0.0 (Stage 6 Experience Convergence)
**Date**: September 27, 2026
**Status**: APPROVED & LOCKED INTO REPOSITORY
**Authority**: `docs/design/00_DESIGN_AUTHORITY.md`, `UI_UX_DESIGN_STATE.md`, `docs/design/64_RESEARCH_VALIDATION_AND_CONTRADICTION_AUDIT.md`, `docs/design/66_ARMSPHERE_SIGNATURE_INTERACTIONS.md`
**Scope**: Definitive 5-tier motion system (T0–T4), strict Flutter curve governance, spatial transition choreography, GPU frame budget protocols, and accessibility reduced-motion fallbacks.

---

## 1. Motion Philosophy: The Combat Physics Engine

Motion in ArmSphere is not decorative flourish; it is **structural feedback, physical weight, and competitive certainty**. 

Armwrestling is an uncompromising sport where millimeters decide championships and milliseconds decide referee calls. Consequently:
- **No Float, No Floatation**: Animations never float gently like clouds or drift without friction.
- **No Elastic Playfulness**: Spring overshoots and toy-like bounces (`Curves.elasticOut`, `Curves.bounceOut`) are strictly prohibited across all screens and components.
- **Decisive Deceleration**: Every moving element enters with purpose and snaps to an exact mechanical stop via controlled cubic deceleration.

---

## 2. Unified 5-Tier Motion Timing System (T0–T4)

Every animation in ArmSphere must be assigned to one of five authoritative timing tiers:

```
[T0: Instantaneous]  <50ms     Referee table scoring, foul triggers, pin touches
[T1: Micro-Action]   100–150ms Button depressions, icon flips, chip toggles
[T2: State Shift]    200–300ms Bottom sheet slides, accordion expansion, tab glide
[T3: Route Shift]    350–450ms Screen transitions, hero zooms, modal popups
[T4: Ceremony]       500–800ms Championship unboxing, bracket victory line, ELO bell
```

### Tier T0: Instantaneous Operational Actions (<50ms)
- **Primary Use Case**: Live referee scoring, foul calls, pin pad press registration, table emergency stops.
- **Duration**: **0ms to 40ms maximum**.
- **Execution**: Pure synchronous state mutation with immediate UI repaint on the next raster frame. Zero tween interpolation. 
- **Rationale**: Referees operating at table-side must feel zero disconnect between finger contact and system registration. Any artificial animation delay risks athlete disputes.

### Tier T1: Micro-Interactions (100–150ms)
- **Primary Use Case**: Button depressions, checkbox marks, switch toggles, search clear clicks, icon state transforms.
- **Duration**: Exactly **120ms** standard (100ms minimum, 150ms maximum).
- **Curve**: `Curves.easeOutCubic` (fast attack, decisive settling).
- **Properties**: Scale (1.00 -> 0.97 -> 1.00), Opacity (1.00 -> 0.85 -> 1.00), Border color cross-fade.

### Tier T2: State Shifts & In-View Transitions (200–300ms)
- **Primary Use Case**: Bottom sheet presentations, card drawer expansions, tab bar indicator glides, filter drawer slides.
- **Duration**: **220ms** standard (200ms minimum, 280ms maximum).
- **Curve**: `Curves.easeInOutCubic` (smooth industrial acceleration and deceleration) or `Curves.easeOutCubic`.
- **Properties**: Translation (Y: +100% -> 0), Container height interpolation, Backdrop scrim opacity (0% -> 65%).

### Tier T3: Route Transitions & Spatial Shifts (350–450ms)
- **Primary Use Case**: Navigating between screens (e.g., Tournament List -> Tournament Detail), shared element Hero flights, full-screen image views.
- **Duration**: **350ms** standard (push), **280ms** standard (pop).
- **Curve**: `Curves.easeOutCubic` for screen entrance, `Curves.easeInCubic` for screen exit.
- **Properties**: Horizontal translation (X: 100% -> 0%), parent screen scale compression (1.00 -> 0.96), scrim fade-in.

### Tier T4: Ceremonial Moments (500–800ms)
- **Primary Use Case**: Tournament Champion crown reveal, Bracket Final Advance Line, Weigh-in Stamp impact, ELO surge roll.
- **Duration**: **600ms** standard (500ms minimum, 800ms maximum).
- **Curve**: Sequenced multi-stage tweens with `Interval` mappings.
- **Properties**: Staggered opacity, vector path generation, 3D card perspective flips, localized particle dissipation.

---

## 3. Authoritative Flutter Curve Governance

To eliminate visual inconsistency and eradicate bouncy anti-patterns, all animation controllers in ArmSphere are restricted to the following approved Flutter curves:

### Approved Curves (The Canonical Set)
| Curve Token | Formula / Behavior | Usage Scope |
| :--- | :--- | :--- |
| **`Curves.easeOutCubic`** | Fast initial speed, abrupt but smooth mechanical stop. | **Universal Default**: Micro-interactions, button releases, sheet entrances, popups. |
| **`Curves.easeInOutCubic`** | Symmetrical acceleration and deceleration. | **Spatial Navigation**: Tab indicator glides, bracket panning centering, card flipping. |
| **`Curves.easeOutQuad`** | Gentle deceleration with continuous momentum. | **Data Readouts**: ELO counters, score rollups, timer progress indicators. |
| **`Curves.easeInQuad`** | Accelerating exit curve. | **Dismissals & Aborts**: Sheet dismissals, failed pin hold abort collapse, popup closes. |
| **`Curves.linear`** | Constant speed across duration. | **Deterministic Progress**: 400ms Pin Hold radial sweep, stopwatches, audio scrubbers. |

### Strictly Prohibited Curves (Lint-Enforced Ban)
- ❌ **`Curves.elasticOut` / `Curves.elasticIn`**: Strictly banned. Violates combat sports gravity and physical realism.
- ❌ **`Curves.bounceOut` / `Curves.bounceIn`**: Strictly banned. Creates cartoonish, unstable visual flutter.
- ❌ **`Curves.slowMiddle`**: Banned. Unnatural pacing that frustrates task completion.

---

## 4. Spatial Transition Choreography & Route Mechanics

Screen transitions in ArmSphere follow strict physical directional rules to preserve the user's mental model:

```
[Hierarchy Level 0: Global Navigation]
       Home ──(Cross-fade 150ms)── Schedule ──(Cross-fade 150ms)── Athletes
         │
         ▼ (Vertical Push 300ms)
[Hierarchy Level 1: Match Walkout / Scorepad]
         │
         ▼ (Horizontal Slide-in 300ms)
[Hierarchy Level 2: Athlete Head-to-Head / Deep Stats]
```

1. **Top-Level Bottom Navigation Switching**:
   - Zero horizontal slide. Instant cross-fade (120ms, `Curves.linear`) with simultaneous bottom nav icon indicator glide (180ms, `Curves.easeInOutCubic`).
2. **Master-to-Detail Push (e.g., Tournament Card -> Detail)**:
   - Target screen slides in from Right (X: 100% -> 0%) in 320ms (`Curves.easeOutCubic`).
   - Origin screen slides left by -20% and receives a 25% black scrim overlay.
3. **Modal & Action Sheet Presentation**:
   - Slides up from bottom (Y: 100% -> 0%) in 240ms (`Curves.easeOutCubic`).
   - Screen substrate behind dims to 65% opacity without scale deformation.
4. **Hero Transitions (Avatars & Badges)**:
   - Wrapped in `Hero` with `FlightShuttleBuilder` maintaining exact corner radius (8dp) and 1px border throughout flight to prevent visual pop.

---

## 5. 60fps GPU Frame Budget & Hardware Optimization Protocols

To guarantee seamless 60fps (and 120Hz ProMotion on modern devices) performance on mid-tier hardware under hot arena conditions:

1. **The 16.6ms Raster Deadline**:
   - Every animation frame must render within **16.6ms** (8.33ms for 120Hz).
   - Zero `setState()` calls at the page root during animation loops. All animations must use `AnimatedBuilder`, `ValueListenableBuilder`, or specialized transition widgets (`SlideTransition`, `FadeTransition`, `ScaleTransition`).
2. **RepaintBoundary Isolation**:
   - Every animating signature component (Pin Hold Button, Bracket Advance Path, ELO Counter) MUST be isolated in its own `RepaintBoundary` to prevent invalidating the surrounding page raster cache.
3. **Zero Layout Reflows**:
   - Never animate `width`, `height`, `margin`, or `padding` directly during real-time gestures. Always animate `Transform.translate`, `Transform.scale`, or `Transform.rotate` which operate exclusively on the GPU compositor thread.
4. **Off-Screen Asset Management**:
   - When a video post or animated media component scrolls more than 100dp out of the viewport, its controller must immediately pause and release hardware decoder buffers.

---

## 6. Accessibility & Reduced Motion Protocol (`prefers-reduced-motion`)

For users with vestibular disorders or devices operating under OS Battery Saver / Low Power Mode:

1. **Automatic Detection**:
   - Query `MediaQuery.of(context).disableAnimations` or `accessibleNavigation`.
2. **Fallback Behavior When Reduced Motion is Active**:
   - **T1 Micro-interactions**: Duration reduced to 0ms; instant state change.
   - **T2 & T3 Transitions**: Sliding translations are disabled. Replaced with instantaneous cross-fades (100ms max) or immediate route swaps.
   - **T4 Ceremonial Moments**: Vector line animations and 3D card flips are replaced with a single static high-contrast confirmation screen.
   - **Pin Hold Lock (SIG-2)**: The 400ms duration is PRESERVED (as it is a mission-critical safety rule), but the radial progress stroke is replaced with a static linear percentage bar (`0%` -> `50%` -> `100%`).
