# ArmSphere Stage 3 — Premium Motion & Sensory Choreography Refinement
**Document Version**: 1.0.0 (Authoritative Motion & Sensory Choreography Specification)
**Date**: September 26, 2026
**Status**: APPROVED & AUDITED
**Authority**: `docs/design/00_DESIGN_AUTHORITY.md`, `11_MOTION_SYSTEM.md`, `31_ACTION_CHOREOGRAPHY.md`, & `32_HAPTIC_AND_AUDIO_UX.md`
**Scope**: Five-Tier Motion Hierarchy (T0–T4), Signature Moment Choreography, Haptic-Audio Synthesis, and Strict Reduced-Motion Accessibility Rules.

---

## 1. The Five-Tier Motion Hierarchy (T0 to T4)

To prevent visual fatigue while maximizing athletic responsiveness, every motion in ArmSphere is categorized into an immutable five-tier physics and duration framework:

| Tier | Category Name | Duration | Physics Curve | Target UI Contexts | Haptic & Sound Pairing |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **T0** | **Functional / Instant** | **0 ms** | Flat Step | Live Match Scorepad (Screen 26), Referee Fouls, Emergency Stops, Disciplinary Locks | Immediate `HapticFeedback.lightImpact()`, optional `pro_tick.wav` |
| **T1** | **Tactile Micro-Interactions** | **120 – 160 ms** | `Cubic(0.2, 0.0, 0.0, 1.0)` | Button depress (scale 0.98), Pill chip toggles, Tab switches, Like/Bookmark heart pops | `HapticFeedback.selectionClick()` |
| **T2** | **Surface & Container Shifts** | **220 – 280 ms** | `Cubic(0.0, 0.0, 0.2, 1.0)` (Decel) | Modal sheets, Drawer slides, Card hero expansions, Accordion disclosure | `HapticFeedback.mediumImpact()` on sheet detent snap |
| **T3** | **Signature Hero Moments** | **450 – 750 ms** | Custom Spring / Overshoot | Tournament Victory, PR Lock, Bracket Advance, Challenge Accepted, Weigh-In Pass | Full sensory sync: Heavy Haptic + Spatial Sound Pack |
| **T4** | **Ambient & Status Shimmers** | **1800 – 3000 ms**| Sine Wave Loop | Live table indicator pulse, gold medal specular sweep, sync heartbeat dot | Zero haptic, zero sound (Pure ambient visual) |

---

## 2. Signature Moment Choreography Specifications

### 2.1 Signature Moment 1: Tournament Victory & Podium Elevation
- **Trigger**: Referee records match-winning pin in Championship Finals or Operator commits tournament results.
- **Context**: `Modal 3: CelebrationOverlay` over `Screen 18 (BracketViewerScreen)`.
- **Duration**: Total 750 ms sequence.
- **Visual Choreography**:
  1. **0ms – 80ms**: Screen briefly flashes to 15% opacity Champagne Gold overlay (`#D4AF37`) before receding to dark obsidian scrim (`#070A11` at 90%).
  2. **80ms – 320ms**: The Champion’s 3D metallic trophy badge drops in with a spring bounce (`dampingRatio: 0.65`, `stiffness: 180`).
  3. **320ms – 600ms**: A high-density stream of 45 physical gold foil particles emanates upward behind the trophy with parabolic gravity drift.
  4. **600ms – 750ms**: Final match score (`3 - 1`) and Elo delta (`+38 ELO`) count up rapidly in `SpaceGrotesk-Bold`.
- **Sensory Pairing**:
  - **Haptic**: Triple pulse: Medium (at 0ms) -> Pause (80ms) -> Heavy Impact (at 320ms trophy land).
  - **Audio**: `match_won.mp3` triggers synchronously at 0ms.

### 2.2 Signature Moment 2: Personal Record (PR) Weight Lock
- **Trigger**: Athlete saves a new lift (Cupping, Pronation, Rise, Bench) exceeding previous historical max.
- **Context**: `Screen 14 (AddPRScreen)` transitioning to `Screen 13 (PersonalRecordsScreen)`.
- **Duration**: Total 500 ms sequence.
- **Visual Choreography**:
  1. **0ms – 250ms**: Numeric stepper accelerates and rolls rapidly to the new record value (e.g., `42.5 KG`).
  2. **250ms – 400ms**: An embossed "NEW PR" Champagne Gold stamp scales down from 1.3x to 1.0x with an elastic stamp impact.
  3. **400ms – 500ms**: The PR card border flashes with a Luminous Cyan perimeter trace.
- **Sensory Pairing**:
  - **Haptic**: Rapid roll clicks (light) ending in a resonant `HapticFeedback.heavyImpact()` at 250ms stamp lock.
  - **Audio**: `pr_achieved.wav` triggers at 250ms stamp lock.

### 2.3 Signature Moment 3: Tournament Bracket Dynamic Advancement
- **Trigger**: Operator advances winner in `Screen 23 (BracketManagementScreen)` or live score syncs in `Screen 18`.
- **Duration**: Total 450 ms sequence.
- **Visual Choreography**:
  1. **0ms – 150ms**: The winning competitor’s node card gains a 2px Champagne Gold border with an elevated drop-shadow (4dp blur). The losing competitor’s node smoothly dims to 35% opacity.
  2. **150ms – 350ms**: A vector bezier connector line draws from the winning node to the next round slot with a golden laser sweep effect.
  3. **350ms – 450ms**: The destination slot in the next round pulses once in Luminous Cyan and populates the competitor’s name and seed.
- **Sensory Pairing**:
  - **Haptic**: `HapticFeedback.mediumImpact()` when destination slot locks.

### 2.4 Signature Moment 4: The Gauntlet Thrown (Challenge Accepted)
- **Trigger**: Athlete accepts an official head-to-head match challenge.
- **Context**: `Screen 33 (ChallengeScreen)`.
- **Duration**: Total 600 ms sequence.
- **Visual Choreography**:
  1. **0ms – 280ms**: Two competitor profile cards slide inward from left and right screen boundaries with high-velocity deceleration (`Cubic(0.0, 0.0, 0.2, 1.0)`).
  2. **280ms – 350ms**: The two cards "slam" together at the center line, separated by an angled steel "VS" badge with a momentary 2px camera shake shake effect (3 cycles at 50Hz).
  3. **350ms – 600ms**: Official match countdown timer begins ticking below the matchup card.
- **Sensory Pairing**:
  - **Haptic**: High-intensity `HapticFeedback.heavyImpact()` at exactly 280ms contact point.
  - **Audio**: `challenge_accepted.wav` triggers at 280ms contact.

### 2.5 Signature Moment 5: Referee Scorepad Instantaneous Pin (0ms Latency)
- **Trigger**: Referee taps "PIN" button for Red Corner or Blue Corner during a live match.
- **Context**: `Screen 26 (LiveMatchScorepadScreen)`.
- **Duration**: **0 ms visual latency** (State updates immediately on `onPointerDown`).
- **Visual Choreography**:
  - Instant background flash: Winning corner illuminates at 100% saturation for 120ms before settling.
  - Round score increment updates in 0ms (no roll animation to avoid perceptual referee delay).
- **Sensory Pairing**:
  - **Haptic**: Instantaneous `HapticFeedback.mediumImpact()` triggered on pointer down event.
  - **Audio**: Short metallic click `pro_tick.wav` (if sound enabled in settings).

---

## 3. Sensory Matrix: Audio & Haptic Choreography

| User / System Action | Haptic Feedback API Call | Audio Asset | Playback Policy |
| :--- | :--- | :--- | :--- |
| **Scorepad Tap / Pin** | `HapticFeedback.mediumImpact()` | `pro_tick.wav` | Omit audio if system volume is zero; haptic always fires. |
| **Foul Recorded** | `HapticFeedback.heavyImpact()` | `None` (Silent) | Silent to avoid referee table confusion. |
| **Match Victory Locked**| Heavy Impact -> Light Impact | `match_won.mp3` | Duck background audio, respect silent mode. |
| **New PR Achieved** | Heavy Impact | `pr_achieved.wav` | Duck background audio, respect silent mode. |
| **Challenge Accepted** | Heavy Impact | `challenge_accepted.wav` | Respect silent mode. |
| **Tab / Pill Selection**| `HapticFeedback.selectionClick()` | `None` | Pure tactile feedback. |
| **Pull to Refresh Snap**| `HapticFeedback.lightImpact()` | `None` | Tactile snap at threshold. |
| **Error / Invalid Input**| Dual Light Impact (Double-buzz)| `None` | Tactile warning pattern. |

---

## 4. Accessibility: Reduced-Motion Architecture

To ensure ArmSphere is fully accessible and comfortable for users with vestibular sensitivities or motion sickness:

### 4.1 Global Reduced-Motion Switch
In Flutter, all animation controllers must observe `MediaQuery.of(context).disableAnimations`:

```dart
final bool reduceMotion = MediaQuery.of(context).disableAnimations;

// For T2 Container Transitions:
Duration transitionDuration = reduceMotion ? Duration.zero : const Duration(milliseconds: 250);

// For T3 Hero Moments:
if (reduceMotion) {
  // Render instant static state with celebratory badge, zero camera shake, zero particles.
}
```

### 4.2 Reduced-Motion Fallback Rules
1. **Confetti & Particle Emitters**: Automatically disabled. Displays static gold laurel badge.
2. **Camera Shake Effects**: Replaced with a stationary 100ms color pulse.
3. **Hero Video Loops**: Replaced with static WebP posters.
4. **Bracket Connector Laser Tracing**: Replaced with static solid vector lines.
5. **Haptics**: Haptic feedback is preserved regardless of motion preferences, providing clear non-visual confirmation.
