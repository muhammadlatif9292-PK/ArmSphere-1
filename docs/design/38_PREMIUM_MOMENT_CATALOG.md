# ArmSphere Premium Moment Catalog & Emotional Design
**The 8 Signature Athletic Ceremonies, Emotional Physics & Restrained Polish**
**Document Version**: 2.0.0 (Authoritative)
**Status**: APPROVED & LOCKED INTO REPOSITORY
**Authority**: `docs/design/00_DESIGN_AUTHORITY.md`, `docs/design/11_MOTION_SYSTEM.md` & `docs/design/24_ANTI_SLOP_RULES.md`
**Scope**: Complete Design and Choreography for the 8 Ceremonial High-Adrenaline Moments in ArmSphere.

---

## 1. Emotional Design Philosophy: Ceremonial vs Calm Utility

A premier sports application must know when to be completely invisible and when to celebrate athletic glory. 

### The Dual-State Architecture:
1. **Calm Utility Surfaces (95% of App Time)**:
   - When browsing brackets, adjusting settings, reading referee guidelines, or entering weights, the app is an austere, high-contrast, razor-sharp instrument. Zero unprompted confetti, zero dancing animations, zero visual noise.
2. **Ceremonial Premium Moments (5% of App Time)**:
   - When an athlete wins a grueling semifinal, makes weight after weeks of dieting, locks in a rivalry duel, or smashes an all-time PR, the app steps forward with high-production, visceral celebration that matches the physical magnitude of the achievement.

---

## 2. The 8 Signature Premium Moments

```
[THE 8 SIGNATURE MOMENTS]
  1. THE BOUT PIN & WIN              ──► ELO Count-Up + Resonant Arena Bell
  2. THE CHAMPIONSHIP CROWNING       ──► Gold Border Sweep + Trophy Unlock + Card Export
  3. THE PERSONAL RECORD (PR) SPIKE  ──► Trajectory Surge + Plate Clang + Heavy Thud
  4. THE CHALLENGE DUAL-LOCK         ──► Metallic Chime + Split-Screen Standoff
  5. THE WEIGH-IN SCALE CLEARANCE    ──► Heavy Stamp Impact + Bracket Credential
  6. THE ELO TIER PROMOTION          ──► Hexagon Shield Transformation + Glow Fanfare
  7. THE DIGITAL LANYARD CHECK-IN    ──► Credential Unfold + Table Routing Reveal
  8. THE RIVALRY STANDOFF (TAPE)     ──► Symmetrical Comparison + Tension Audio
```

---

### Moment 1: The Bout Win & ELO Surge
- **Emotional Meaning**: The culmination of rounds of intense isometric struggle. The pin is down, the referee signals, and victory is officially certified.
- **Trigger Condition**: Referee confirms 400ms hold on PIN button, or cloud bracket updates athlete to WINNER.
- **Visual Choreography (600ms total)**:
  1. Screen border flashes a brief 1px Cyan & Gold perimeter pulse (`#38BDF8` / `#D4AF37`).
  2. Bottom sheet smoothly slides up (`MatchWonCelebrationModal`):
     - Winner's name and division header appear in `SpaceGrotesk Bold`.
     - Numeric ELO Counter: Animates upward from previous rating to new rating over 450ms (e.g. `2,442` ➔ `2,470`, `+28 ELO`).
     - ELO digit color turns Emerald Green (`#10B981`) upon completion.
     - Directional Chalk Burst: 12 subtle white/gray chalk dust micro-particles float outward and fade over 400ms.
- **Audio Cue**: `match_won.mp3` (Resonant arena bell strike).
- **Haptic Cue**: `HapticFeedback.heavyImpact()`.
- **Dismiss / Continue Path**: Single prominent CTA: `VIEW UPDATED BRACKET` or `DISMISS`.

---

### Moment 2: The Championship Crowning (Division Gold)
- **Emotional Meaning**: Winning the finals of a sanctioned provincial, national, or international tournament.
- **Trigger Condition**: Final round of a tournament bracket concludes with the user as Gold Medalist.
- **Visual Choreography (900ms total)**:
  1. Viewport transitions to full-bleed dark arena podium background (`#070A11`).
  2. A milled Champagne Gold championship medallion (`#D4AF37`) drops in with subtle scale damping (`1.2x` ➔ `1.0x`, `Curves.easeOutCubic`).
  3. Dynamic Border Shimmer: A continuous soft gold metallic sheen sweeps diagonally across the championship card at a 45-degree angle.
  4. Header text in `SpaceGrotesk Bold`: **"ONTARIO PROVINCIAL CHAMPION — SENIOR MEN 85KG"**.
- **Audio Cue**: `match_won.mp3` accompanied by celebratory brass fanfare undertone.
- **Haptic Cue**: Double `HapticFeedback.heavyImpact()` (separated by 120ms).
- **Shareable Card**: Floating button `SHARE CHAMPIONSHIP CARD` exports an auto-generated 9:16 high-contrast graphic directly to Instagram Stories / WhatsApp with athlete photo and official federation seal.
- **Dismiss / Continue Path**: Bottom text button: `RETURN TO TOURNAMENT STANDINGS`.

---

### Moment 3: The Personal Record (PR) Spike
- **Emotional Meaning**: An athlete breaks their personal best in cupping, pronation, rising, or grip dynamometer.
- **Trigger Condition**: Athlete enters a new maximum weight value in `TrainingLogEditor` that exceeds their historical database record.
- **Visual Choreography (500ms total)**:
  1. The entered numeric value (`e.g. 52.5 kg`) scales up `1.25x` and shifts from textSecondary to Gold (`#D4AF37`).
  2. Below the input, the historical strength trajectory chart triggers an upward animated spline surge:
     - The line chart draws forward rapidly, spiking above the dashed historical ceiling line.
     - A gold star marker pulses once at the peak apex.
  3. Floating badge drops down: **"NEW ALL-TIME PR — +2.5 KG"**.
- **Audio Cue**: `pr_achieved.wav` (Synth surge into resonant plate-clang).
- **Haptic Cue**: `HapticFeedback.heavyImpact()`.
- **Dismiss / Continue Path**: Automatic 2.5-second settle into normal form state, with button active: `SAVE WORKOUT ENTRY`.

---

### Moment 4: The Challenge Dual-Lock (Rivalry Accepted)
- **Emotional Meaning**: Mutual agreement to a sanctioned armwrestling match. Both competitors have staked their reputation and ELO.
- **Trigger Condition**: Opponent drags the "SLIDE TO ACCEPT BOUT" slider to 100%.
- **Visual Choreography (550ms total)**:
  1. Slider thumb locks into the end-stop with an authoritative metallic snap.
  2. Screen splits symmetrically down the diagonal: Challenger on top-left, Opponent on bottom-right.
  3. A bright 1.5px Cyan laser line sweeps across the diagonal divide.
  4. Stakes badge fades in between both portraits: **"BEST OF 5 • RIGHT ARM • ±26 ELO"**.
- **Audio Cue**: `challenge_accepted.wav` (Clean metallic chime into sub-bass thump).
- **Haptic Cue**: `HapticFeedback.heavyImpact()`.
- **Dismiss / Continue Path**: Auto-navigates after 1.8 seconds to the active `BoutContractDetailScreen`.

---

### Moment 5: The Weigh-In Scale Clearance ("MADE WEIGHT")
- **Emotional Meaning**: Making weight is half the battle in combat sports. Weeks of caloric restriction and water cuts culminate at the scale.
- **Trigger Condition**: Official Marshall records scale weight <= division weight limit and taps "APPROVE & LOCK".
- **Visual Choreography (400ms total)**:
  1. Scale weight numbers lock in high-contrast emerald text: **"84.6 KG / 186.5 LBS"**.
  2. A massive emerald rubber-stamp badge drops onto the card with physical gravity: **"OFFICIALLY CLEARED"**.
  3. Stamp scale: `1.8x` ➔ `1.0x` over 140ms (`Curves.easeInQuad`) simulating an authoritative physical ink stamp hitting paper.
  4. Digital Credential badge below turns from "PENDING WEIGH-IN" (Amber) to "BRACKET ACTIVE" (Green).
- **Audio Cue**: Muted tactile thud (no music, official operational focus).
- **Haptic Cue**: `HapticFeedback.heavyImpact()` timed exactly to the 140ms stamp landing.
- **Dismiss / Continue Path**: Button displays: `GENERATE COMPETITION PASS` or `NEXT WEIGH-IN`.

---

### Moment 6: The ELO Tier Promotion
- **Emotional Meaning**: Ascending from Club Puller to Provincial Contender, or from Master to Grandmaster.
- **Trigger Condition**: Athlete's ELO crosses a defined tier threshold (e.g. crossing 2,000 ELO to achieve "Federation Master").
- **Visual Choreography (750ms total)**:
  1. Full-screen modal overlay fades in with deep charcoal scrim (`#070A11` at 92% opacity).
  2. The previous tier badge (Silver Hexagon) smoothly dissolves while new tier badge (Milled Gold Shield) scales forward from `0.8x` to `1.05x`, then settles to `1.0x`.
  3. Luminous glow ring expands outward from the badge perimeter (40dp radius, `#D4AF37` at 25% opacity).
  4. Monospace readout: **"TIER UNLOCKED: FEDERATION MASTER (2,000+ ELO)"**.
- **Audio Cue**: `match_won.mp3` (Resonant bell).
- **Haptic Cue**: `HapticFeedback.mediumImpact()` followed by `heavyImpact()`.
- **Dismiss / Continue Path**: Button: `CONTINUE TO PROFILE`.

---

### Moment 7: The First Tournament Check-In (Digital Lanyard)
- **Emotional Meaning**: Arriving at the tournament venue, feeling the electric atmosphere, and receiving official credentials.
- **Trigger Condition**: Athlete checks in at venue reception or scans venue arrival QR.
- **Visual Choreography (600ms total)**:
  1. Digital Credential unfolds vertically like an official physical lanyard card (`Transform` with 3D Y-axis rotation from -90° to 0°).
  2. Top header displays high-contrast barcode and QR code.
  3. Live Table Assignment illuminates: **"WELCOME, LATIF. ASSIGNED TO WARMUP TABLE 4."**
  4. Athlete photo, division, seed number (`Seed #3`), and emergency contact displayed in crisp institutional layout.
- **Audio Cue**: Subtle chime.
- **Haptic Cue**: `HapticFeedback.mediumImpact()`.
- **Dismiss / Continue Path**: Action: `ADD TO GOOGLE WALLET` or `PROCEED TO WEIGH-IN`.

---

### Moment 8: The Rivalry Standoff (Tale of the Tape)
- **Emotional Meaning**: Sizing up your rival before gripping up. Comparing hand size, lever length, and past history.
- **Trigger Condition**: Viewing a scheduled Supermatch card or opening a head-to-head comparison.
- **Visual Choreography (500ms total)**:
  1. Symmetrical split cards animate inward from left and right screen edges (`Offset(±0.5, 0)` ➔ `Offset.zero`).
  2. Metric comparison bars (Arm Length, Forearm Circumference, ELO, Win Rate) fill inward toward the center line.
  3. The higher metric in each category illuminates in Luminous Cyan (`#38BDF8`), while the lower metric remains muted (`#94A3B8`).
  4. Historical rivalry score displays at center: **"SERIES: 3 – 2 (LATIF LEADS)"**.
- **Audio Cue**: Low atmospheric tension hum (optional, respects silence).
- **Haptic Cue**: Sequential `HapticFeedback.selectionClick()` as each metric bar reaches its value.
- **Dismiss / Continue Path**: Action: `VIEW PAST MATCH FILM` or `BACK TO BRACKET`.

---

## 3. Premium Moment Resource Matrix

| Moment | Visual Asset / Animation | Audio Asset | Haptic Impulse | Duration |
| :--- | :--- | :--- | :--- | :--- |
| **1. Bout Win** | ELO counter + chalk particles | `match_won.mp3` | `heavyImpact()` | 600ms |
| **2. Championship** | Gold medal drop + border shimmer | `match_won.mp3` | Double `heavyImpact()` | 900ms |
| **3. PR Spike** | Trajectory chart spline surge | `pr_achieved.wav` | `heavyImpact()` | 500ms |
| **4. Challenge Lock**| Diagonal split + laser sweep | `challenge_accepted.wav` | `heavyImpact()` | 550ms |
| **5. Weigh-In Clear**| "OFFICIALLY CLEARED" stamp drop | Muted thud | `heavyImpact()` | 400ms |
| **6. Tier Promotion**| Shield morph + glow pulse | `match_won.mp3` | `medium` + `heavy` | 750ms |
| **7. Lanyard Check-In**| 3D card unfold + QR illuminate | Soft chime | `mediumImpact()` | 600ms |
| **8. Rivalry Standoff**| Symmetrical metric bar sweeps | Tension hum | `selectionClick()` ticks | 500ms |

---

## 4. Verification & Non-Contradiction Proof
This catalog strictly complies with `docs/design/00_DESIGN_AUTHORITY.md` Rules 15, 16, 17, and 18. All animations are strictly event-driven (zero continuous background particle loops), respect reduced-motion settings, utilize only preloaded approved audio files, and maintain strict athletic dignity.
