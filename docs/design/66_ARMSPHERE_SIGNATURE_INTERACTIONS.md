# ArmSphere Signature Combat Interactions
**Document Version**: 1.0.0 (Stage 6 Experience Convergence)
**Date**: September 27, 2026
**Status**: APPROVED & LOCKED INTO REPOSITORY
**Authority**: `docs/design/00_DESIGN_AUTHORITY.md`, `UI_UX_DESIGN_STATE.md`, `docs/design/64_RESEARCH_VALIDATION_AND_CONTRADICTION_AUDIT.md`, `docs/design/65_INTERACTION_REFERENCE_ATLAS.md`
**Scope**: Definitive specification of the eight proprietary ArmSphere Signature Interactions that define the platform's sensory, physical, and competitive brand identity.

---

## 1. Principles of ArmSphere Signature Interactions

Unlike generic SaaS mobile applications that rely on standard off-the-shelf component animations, ArmSphere features a tightly curated set of **proprietary combat sports interactions**. 

Every signature interaction must pass three foundational criteria:
1. **Sports Authenticity**: Grounded in the raw physical reality of armwrestling—chalk, knurled steel, high-tension isometric locks, referee table commands, and bracket progression.
2. **Deterministic Decisiveness**: Zero elastic bounce, zero playful overshoot, zero floating pastel fluff. Motions hit with weight, lock with finality, and settle immediately.
3. **Zero Operational Latency**: For critical referee and scoring interactions, visual feedback begins at **0ms** (instant local optimistic paint), with animation completing without blocking user inputs.

---

## 2. The Eight Canonical Signature Interactions

---

### Signature 1: The Match Reveal / Walkout Transition
- **Sports Context**: The moment two armwrestlers step to the table for a title match or tournament finals bout.
- **Trigger**: Opening a featured match card from Tournament Schedule or pressing "Start Bout" from staging.
- **Visual Choreography**:
  - *Stage 0 (0ms)*: Screen splits along a diagonal 15° shear line across the viewport center.
  - *Stage 1 (0–200ms)*: Left athlete panel slides in from the left (Red corner), Right athlete panel slides in from the right (Blue corner) with dramatic contrast desaturation.
  - *Stage 2 (200–350ms)*: A 2px Champagne Gold laser divider (`#D4AF37`) slices down the center shear line, illuminating the central "VS" emblem.
  - *Stage 3 (350–500ms)*: ELO rating numbers slam into place with a rapid 3-digit counter roll. The favored competitor displays an ELO differential badge (`+42 pts`).
- **Timing & Curves**:
  - Slide-in: 200ms (`Curves.easeOutCubic`).
  - Laser divider: 150ms (`Curves.easeInOutCubic`).
  - Total sequence: 500ms (Transitions smoothly into live match view).
- **Sensory Mapping**:
  - At 200ms (Laser slice): `HapticFeedback.mediumImpact()`.
  - At 350ms (VS lock): `HapticFeedback.heavyImpact()`.
- **Flutter Implementation**:
  - Implemented via custom `Flow` or `Stack` with two `ClipPath` widgets using a custom `DiagonalSplitClipper`.
  - Driven by a single `AnimationController(duration: Duration(milliseconds: 500))`.

---

### Signature 2: The 400ms Pin Hold Lock
- **Sports Context**: In international rules, a pin occurs when any part of the competitor's hand or wrist breaks the pin-pad line. A referee confirms the pin with an unequivocal touch-and-hold confirmation to prevent accidental taps.
- **Trigger**: Referee pressing the Pin Pad target button on `RefereeScorepadScreen`.
- **Visual Choreography**:
  - *Stage 0 (0ms)*: Instant button scale compression from 1.00 to 0.96; background color shifts to vivid Mint Emerald (`#10B981`); central text displays "HOLD TO CONFIRM".
  - *Stage 1 (0–399ms)*: A 4px radial progress stroke tracks clockwise around the 64dp button boundary. Center readout displays dynamic millisecond countdown (`400ms` -> `200ms` -> `0ms`). Ambient screen edge flashes a 2px green border at 20% opacity.
  - *Stage 2 (Exactly 400ms)*: Instant white flash (80ms duration) across the button. The button snaps to an immutable locked state displaying "PIN CONFIRMED".
  - *Abort Handling*: If referee releases finger at 350ms, the progress track instantly collapses to 0 in 80ms (`Curves.easeInQuad`), the score is NOT recorded, and a light error click fires.
- **Timing & Curves**:
  - Radial sweep: Linear 400ms (`Curves.linear`) for perfect temporal parity with physical hold.
  - Lock confirmation: 80ms flash (`Curves.easeOut`).
- **Sensory Mapping**:
  - 0ms (Touchdown): `HapticFeedback.lightImpact()`.
  - 200ms (Mid-hold): `HapticFeedback.selectionClick()`.
  - 400ms (Lock): `HapticFeedback.heavyImpact()` followed immediately by Federation Pin Bell chime.
- **Flutter Implementation**:
  - Implemented using a dedicated `PinHoldButton` with `Listener` (tracking `PointerDownEvent` and `PointerUpEvent`).
  - `CustomPainter` draws the high-precision arc using `canvas.drawArc()`. Isolated inside a `RepaintBoundary` to maintain 60fps on low-end tablets.

---

### Signature 3: The ELO Surge Bell
- **Sports Context**: Immediately following match result submission, both athletes' international federation ratings are updated.
- **Trigger**: Navigating to match summary or opening athlete profile after a tournament bout.
- **Visual Choreography**:
  - *Stage 0 (0–100ms)*: Current ELO readout (e.g., `1845`) is highlighted with an ambient Champagne Gold glow (`#33D4AF37`).
  - *Stage 1 (100–400ms)*: ELO counter rolls rapidly through intervening values to the new rating (e.g., `1873`). A floating badge (`+28`) rises 16dp above the number while fading in.
  - *Stage 2 (400–600ms)*: A subtle 1px ring wave expands outward from the rating badge, dissolving into the canvas substrate. If a new tier threshold is crossed (e.g., Master to Grandmaster), the badge switches to illuminated Gold with an icon badge pulse.
- **Timing & Curves**:
  - Number roll: 300ms (`Curves.easeOutQuad`).
  - Badge elevation: 250ms (`Curves.easeOutCubic`).
  - Ring wave: 300ms (`Curves.easeOut`).
- **Sensory Mapping**:
  - During counter roll: Micro-haptic ticks (`HapticFeedback.selectionClick()`) every 50ms.
  - At final number lock: `HapticFeedback.mediumImpact()`.
- **Flutter Implementation**:
  - Built with `TweenAnimationBuilder<int>` binding to an `IntTween`. Monospace numbers rendered using `FontFeature.tabularFigures()`.

---

### Signature 4: The Arm-Switch Flip
- **Sports Context**: Armwrestling operates under strict dual-division structures: Left Arm vs. Right Arm. Toggling between arms must visually represent a complete physical table rotation.
- **Trigger**: Tapping the Left/Right Arm toggle on Athlete Profile, Tournament Registration, or Rankings Screen.
- **Visual Choreography**:
  - *Stage 0 (0ms)*: Active arm card initiates a 3D Y-axis rotation away from the user.
  - *Stage 1 (0–120ms)*: Card rotates from 0° to 90° (halfway); opacity dims slightly to 0.70.
  - *Stage 2 (120ms)*: Card flips content: "RIGHT ARM" (Crimson accent `#EF4444`) swaps to "LEFT ARM" (Luminous Sky Blue accent `#38BDF8`). Data fields (ELO, Win Rate, Division Rank) reload instantly from memory.
  - *Stage 3 (120–240ms)*: Card completes rotation from 90° to 180° (restored to front face); scale settles from 0.95 back to 1.00.
- **Timing & Curves**:
  - Total flip duration: Exactly 240ms.
  - Half-flip 1: 120ms (`Curves.easeInCubic`).
  - Half-flip 2: 120ms (`Curves.easeOutCubic`).
- **Sensory Mapping**:
  - At 0ms (Initiation): `HapticFeedback.lightImpact()`.
  - At 120ms (Card face swap): `HapticFeedback.selectionClick()`.
  - At 240ms (Settled): `HapticFeedback.lightImpact()`.
- **Flutter Implementation**:
  - Utilizes `Transform` with matrix perspective: `Matrix4.identity()..setEntry(3, 2, 0.0015)..rotateY(angle)`.

---

### Signature 5: The Rubber Stamp Clearance
- **Sports Context**: During official weigh-ins, an athlete makes weight and is legally cleared by the federation official.
- **Trigger**: Tournament marshal tapping "Certify Weight" on `WeighInScreen`.
- **Visual Choreography**:
  - *Stage 0 (0ms)*: Official taps certification button; dialog or card clears.
  - *Stage 1 (0–150ms)*: A large, technical octagonal stamp badge ("CLEARED - 85.0 KG") descends rapidly from Scale 2.50 to Scale 1.00 at an angled -12° rotation.
  - *Stage 2 (150ms)*: The stamp hits the card surface with massive visual deceleration; a faint dust shockwave (8 micro-particles) expands outward and fades in 120ms.
  - *Stage 3 (150–250ms)*: The stamp color locks into high-contrast Emerald Green (`#10B981`) with a textured rubber-stamped watermark finish.
- **Timing & Curves**:
  - Stamp descent: 150ms (`Curves.easeInQuad`).
  - Shockwave fade: 120ms (`Curves.easeOut`).
- **Sensory Mapping**:
  - At 150ms (Impact): `HapticFeedback.heavyImpact()`.
- **Flutter Implementation**:
  - Implemented as a composited `ScaleTransition` + `RotationTransition` over the athlete registration card.

---

### Signature 6: The Bracket Advance Lightning Line
- **Sports Context**: Advancing a winning competitor through a 64-competitor double-elimination bracket tree.
- **Trigger**: Match result finalized on tournament bracket view.
- **Visual Choreography**:
  - *Stage 0 (0ms)*: The winning match node illuminates its border from `#334155` to vivid Champagne Gold (`#D4AF37`).
  - *Stage 1 (0–250ms)*: A glowing Gold vector stroke (2px thickness with 4px soft bloom) pulses along the bracket connector path from the current match node to the next round slot.
  - *Stage 2 (250–350ms)*: The next round slot expands slightly (Scale 1.03), athlete name and seed number slide in from the left, and the slot locks into place.
- **Timing & Curves**:
  - Vector line animation: 250ms (`Curves.easeInOutCubic`).
  - Destination slot settle: 100ms (`Curves.easeOutCubic`).
- **Sensory Mapping**:
  - At 0ms: `HapticFeedback.lightImpact()`.
  - At 250ms (Node arrival): `HapticFeedback.mediumImpact()`.
- **Flutter Implementation**:
  - Handled inside the bracket tree's custom `CustomPainter` using path metrics: `path.computeMetrics()` to animate `extractPath(0.0, length * progress)`.

---

### Signature 7: The Chalk Dust Pull-to-Refresh
- **Sports Context**: Pulling down to sync fresh tournament brackets and scores mirrors an armwrestler dusting their hands with magnesium chalk before gripping up.
- **Trigger**: Pull-down gesture on any scrollable tournament list or standings screen.
- **Visual Choreography**:
  - *Stage 0 (0–80dp pull)*: A technical steel cable icon descends from top margin. As drag distance increases, faint chalk dust particles drift downward.
  - *Stage 1 (Threshold 80dp)*: Cable snaps into tension lock with a 1px Gold horizontal line.
  - *Stage 2 (Released)*: Cable spinner rotates with industrial precision while SQLite merge executes.
  - *Stage 3 (Complete)*: Spinner resolves into a crisp green checkmark, followed by a quick upward retraction (150ms).
- **Timing & Curves**:
  - Pull tracking: Direct 1:1 displacement with logarithmic dampening.
  - Retraction: 150ms (`Curves.easeOutCubic`).
- **Sensory Mapping**:
  - At 80dp threshold: `HapticFeedback.mediumImpact()`.
  - At sync completion: `HapticFeedback.lightImpact()`.
- **Flutter Implementation**:
  - Custom `RefreshIndicator` with bespoke painter for chalk particle dissipation.

---

### Signature 8: The Referee Table Foul Flash
- **Sports Context**: Table fouls (elbow slips, intentional strap slippage, false starts) must be signaled immediately to all officials, athletes, and table-side displays.
- **Trigger**: Referee tapping "Foul" on the live scorepad.
- **Visual Choreography**:
  - *Stage 0 (0ms)*: Viewport borders (top, bottom, left, right) flash a 4px high-visibility Coral Amber/Red border (`#EF4444`).
  - *Stage 1 (0–120ms)*: The offender's athlete panel pulses with a 15% red scrim tint.
  - *Stage 2 (120–300ms)*: Border and scrim fade smoothly back to dark slate neutral (`#0B0F19`), leaving a persistent foul pip counter illuminated (`[FOUL 1 / 2]`).
- **Timing & Curves**:
  - Flash rise: 0ms (Instantaneous paint).
  - Fade out: 180ms (`Curves.easeOutQuad`).
- **Sensory Mapping**:
  - At 0ms: Immediate double heavy haptic pulse (`HapticFeedback.heavyImpact()` x 2 at 60ms interval).
- **Flutter Implementation**:
  - Implemented as an overlay layer at the root of `RefereeScorepadScreen` driven by an animated `Opacity` or `ColorFiltered` widget.

---

## 3. Signature Interaction Governance & Guardrails

| Signature ID | Interaction Name | Trigger View | Frame Budget | Latency Constraint | Primary Sensory Cue |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **SIG-1** | Match Reveal Walkout | Schedule / Match Detail | <16.6ms | <30ms push | Medium + Heavy Impact |
| **SIG-2** | 400ms Pin Hold Lock | Referee Scorepad | <16.6ms | **0ms instantaneous** | Sustained rumble + Heavy Impact + Bell |
| **SIG-3** | ELO Surge Bell | Match Summary / Profile | <16.6ms | <50ms calculation | Counter ticks + Medium Impact |
| **SIG-4** | Arm-Switch Flip | Profile / Rankings | <16.6ms | <20ms toggle | 3D Perspective Flip + Selection click |
| **SIG-5** | Rubber Stamp Clearance | Weigh-In Registration | <16.6ms | <30ms stamp | Heavy Impact + Shockwave |
| **SIG-6** | Bracket Advance Line | Tournament Bracket | <16.6ms | <40ms update | Vector path pulse + Medium Impact |
| **SIG-7** | Chalk Dust Pull Refresh | Feeds / Standings | <16.6ms | <15ms pull | Tension click + Light Impact |
| **SIG-8** | Referee Foul Flash | Referee Scorepad | <16.6ms | **0ms instantaneous** | Double Heavy Impact + Screen border pulse |

Every signature interaction must be wrapped in its own `RepaintBoundary` and test-verified at 60fps on low-end hardware.
