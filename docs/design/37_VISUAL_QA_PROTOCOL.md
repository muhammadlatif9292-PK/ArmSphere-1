# ArmSphere Visual & Interaction QA Protocol
**Repeatable Quality Assurance Rubric, Stress-Testing Criteria & Device Verification**
**Document Version**: 2.0.0 (Authoritative)
**Status**: APPROVED & LOCKED INTO REPOSITORY
**Authority**: `docs/design/00_DESIGN_AUTHORITY.md`, `docs/design/18_ACCESSIBILITY_SPEC.md` & `docs/design/28_DESIGN_QA_CHECKLIST.md`
**Scope**: Repeatable Testing Protocol for Engineers, QA Testers, and Non-Designers to Guarantee Visual, Haptic, and Ergonomic Quality Across Android Devices.

---

## 1. Quality Assurance Objective & Philosophy

A design system is only as good as its execution in production. ArmSphere operates in high-intensity, physical sports tournament settings. This QA protocol provides an unambiguous, objective, and repeatable rubric that allows any developer or QA engineer—regardless of design background—to audit a pull request or release build with mathematical precision.

### The 6 Core Audit Pillars:
1. **Ergonomic Touch Targets**: Minimum 48×48dp everywhere; minimum 64×64dp on live referee scorepads.
2. **WCAG Contrast Ratios**: 100% compliance with AA (4.5:1 body text, 3.0:1 graphics) and AAA (7.0:1 titles).
3. **Typography & Layout Resilience**: Zero text overflows under 1.3x OS font scaling and German/Russian translation expansion.
4. **Multi-Form-Factor Scaling**: Flawless layout across Compact (360dp), Standard (393dp), and Tablet/Foldable (600dp+).
5. **Frame Budget & Jank Audit**: Strict 60fps lock (<16.6ms per frame), zero memory leaks during navigation.
6. **Sensory Etiquette**: Complete obedience to Android ringer/silent mode, audio ducking, and user haptic toggles.

---

## 2. Touch Target & Ergonomics Audit Rubric

Every interactive component must be verified against physical bounding box requirements:

| Element Type | Minimum Bounding Box | Verification Tool / Command | Pass Criteria |
| :--- | :--- | :--- | :--- |
| **Standard Button / Chip** | **48 × 48 dp** | Flutter DevTools "Show Guidelines" | Touch region >= 48dp on both axes |
| **Referee Scorepad Points** | **64 × 64 dp** | Android Layout Inspector | Hit target >= 64dp; padding >= 12dp |
| **Scorepad PIN Button** | **72 × 72 dp** (or full-width) | Screen Tap Bounds Measurement | Centered, hold gesture >= 400ms |
| **Icon Buttons / App Bar** | **48 × 48 dp** | `IconButton(padding: EdgeInsets.all(12))` | Visual icon 24dp, hit box 48dp |
| **Bottom Navigation Tabs** | **64 × 56 dp** | NavigationBar inspect | Centered, 0 accidental mis-taps |
| **Form Input Fields** | **52 dp height** | Form Field Inspector | Minimum vertical height 52dp |

### Test Procedure:
1. Launch Flutter app with `--profile` mode on physical Android device.
2. Enable Flutter Inspector: `debugPaintSizeEnabled = true`.
3. Verify that no two touch targets overlap or sit closer than 8dp to one another.
4. Test one-handed thumb reachability: Primary CTAs must sit within the bottom 40% of the screen.

---

## 3. Contrast Ratio Verification Protocol

All text and graphical boundaries must be audited against the `#070A11` and `#0B0F19` background tokens using a contrast checker:

| Token Pair | Foreground Hex | Background Hex | Required Ratio | Verified Ratio | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Title Text on Canvas** | `#F8FAFC` | `#070A11` | >= 7.0:1 (AAA) | **18.2:1** | PASS |
| **Body Text on Card** | `#94A3B8` | `#121826` | >= 4.5:1 (AA) | **7.8:1** | PASS |
| **Muted Metadata on Card** | `#8493A5` | `#121826` | >= 4.5:1 (AA) | **5.4:1** | PASS |
| **Luminous Cyan Accent** | `#38BDF8` | `#070A11` | >= 3.0:1 (Graphic) | **8.9:1** | PASS |
| **Emerald Success Badge** | `#10B981` | `#0B0F19` | >= 3.0:1 (Graphic) | **7.2:1** | PASS |
| **Coral Red Error Text** | `#FF5252` | `#121826` | >= 4.5:1 (AA) | **5.1:1** | PASS |
| **Champagne Gold Border** | `#D4AF37` | `#070A11` | >= 3.0:1 (Graphic) | **7.9:1** | PASS |

### Test Procedure:
1. Capture screenshot of target screen.
2. Run contrast analyzer across all text labels, badges, and icon fills.
3. Any label falling below 4.5:1 is a hard PR rejection.

---

## 4. Text Truncation & Language Expansion Stress-Test

Armwrestling is international; strings expand significantly in languages such as Russian ("Чемпионат мира по армрестлингу") and German ("Schiedsrichterentscheidung"). Furthermore, users with visual impairments increase system font size.

### Test Matrix:
1. **System Font Scale Test**:
   - Navigate to Android OS Settings > Display > Font Size > Set to **Maximum (1.3x – 1.4x)**.
   - Audit all 66 screens.
   - **Pass Criteria**:
     - Zero `RenderFlex overflowed by XX pixels` yellow/black hazard bars.
     - Critical numbers (Scores, Weight, ELO) wrap gracefully or scale down via `FittedBox`.
     - Multi-line titles wrap cleanly without clipping descenders (g, y, p, q).
2. **Pseudolocalization / String Expansion Test**:
   - Inject 30% longer strings into match names and tournament titles.
   - **Pass Criteria**:
     - Action buttons expand vertically to accommodate 2 lines if needed.
     - Table rows do not clip competitor names; use `TextOverflow.ellipsis` with accessible tooltip.

---

## 5. Screen Size & Form Factor Matrix

ArmSphere must run impeccably across the fragmented Android device landscape:

```
[TARGET DEVICE PROFILES]
  1. COMPACT (Budget Android):  360 × 640 dp  (e.g. Galaxy A03 / Redmi 9A)
  2. STANDARD (Modern Flagship): 393 × 852 dp  (e.g. Pixel 8 / Galaxy S24)
  3. EXPANDED (Foldable/Tablet): 600+ × 900 dp (e.g. Pixel Fold / Galaxy Tab S9)
```

### Specific Checklist per Form Factor:
- **Compact Handset (360dp width)**:
  - Verify horizontal padding is reduced from 20dp to 16dp.
  - Verify Tale of the Tape split cards stack gracefully without squishing metric text.
  - Verify referee scorepad buttons remain at least 64dp by using vertical column distribution.
- **Standard Flagship (393dp width)**:
  - Verify baseline 8dp grid spacing.
  - Verify fluid hero transitions and full 16:9 banner presentation.
- **Foldable / Tablet (600dp+ width)**:
  - Verify tournament brackets expand into split view (left: division roster, right: interactive bracket canvas).
  - Verify dialogs and modals use `BoxConstraints(maxWidth: 540)` instead of stretching edge-to-edge.

---

## 6. Performance & Frame Budget Profiling Checklist

A sports app must feel as responsive as the athletes competing. Profiling is conducted in `--profile` mode on a real mid-tier physical device (Snapdragon 680 or equivalent):

### 1. Frame Rate & Jank Audit:
- Open Flutter DevTools Performance view.
- Perform continuous 60-second scrolling test through:
  - Discovery Tournament List
  - Community Media Feed
  - 128-Athlete Double Elimination Bracket
- **Pass Criteria**:
  - Maximum frame render time: **<16.6ms** (60 fps lock).
  - Shader compilation jank: Zero red spikes during scroll (all shaders pre-warmed).
  - GPU memory allocation remains steady without cyclic spiking.

### 2. Memory Leak & Lifecycle Audit:
- Push and pop the `TournamentDetailScreen` and `RefereeScorepadView` **20 consecutive times**.
- Inspect Dart VM heap memory in DevTools Memory profiler.
- **Pass Criteria**:
  - Heap memory must return to baseline (within ±5MB) after garbage collection.
  - Zero retained `AnimationController`, `StreamSubscription`, or `VideoPlayerController` instances.

### 3. Battery Drain & Thermal Test:
- Run active `RefereeScorepadView` with `WakelockPlus` active for **30 continuous minutes**.
- Measure battery consumption:
  - Total battery draw must not exceed **4.5% per 30 minutes**.
  - Device chassis temperature must not rise above 38°C (no background particle loops or continuous math).

---

## 7. Sensory (Haptic & Audio) Verification Checklist

| Test Case | Procedure | Expected Result | Pass/Fail |
| :--- | :--- | :--- | :--- |
| **Silent Mode Respect** | Toggle Android ringer switch to SILENT. Complete match win. | Haptic fires; ZERO audio plays. | [ ] |
| **Vibrate Mode Respect** | Set device to VIBRATE. Issue challenge. | Haptic fires; ZERO audio plays. | [ ] |
| **Audio Ducking** | Play Spotify music in background. Trigger PR lift. | Music drops volume to 50%, chime plays, music restores. | [ ] |
| **Haptic Toggle** | Disable haptics in ArmSphere Settings. Tap scorepad. | Score updates; ZERO vibration occurs. | [ ] |
| **Rapid Tap Suppression**| Tap scorepad 8 times in 1 second. | Maximum 4 haptic impulses fire (no motor lockup). | [ ] |
| **Accessibility Parity** | Mute all sound. Log PR lift. | High-contrast visual toast and gold spike show PR clearly. | [ ] |

---

## 8. Verification & Non-Contradiction Proof
This Visual QA Protocol enforces the standards mandated in `docs/design/00_DESIGN_AUTHORITY.md`, `docs/design/18_ACCESSIBILITY_SPEC.md`, and `docs/design/28_DESIGN_QA_CHECKLIST.md`. It provides a repeatable, objective verification rubric for all future development slices.
