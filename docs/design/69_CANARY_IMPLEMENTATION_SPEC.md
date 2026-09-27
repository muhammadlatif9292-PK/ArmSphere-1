# ArmSphere Canary Implementation Specifications
**Document Version**: 1.0.0 (Stage 6 Experience Convergence)
**Date**: September 27, 2026
**Status**: APPROVED & LOCKED INTO REPOSITORY
**Authority**: `docs/design/00_DESIGN_AUTHORITY.md`, `UI_UX_DESIGN_STATE.md`, `docs/design/60_PREMIUM_CANARY_SCREEN_PLAN.md`, and Stage 6 Convergence Suite (64–68)
**Scope**: Complete, production-grade interaction, motion, visual composition, and performance specifications for the 10 ArmSphere Canary Screens.

---

## 1. The 10 Canary Screens Overview

The 10 Canary screens represent the critical surface area of ArmSphere. Perfecting these screens guarantees the structural integrity and premium feel of the entire 66-screen catalog:

1. **Canary 1: Welcome & Onboarding Screen** (`/onboarding`)
2. **Canary 2: Home & Dashboard Screen** (`/home`)
3. **Canary 3: Athlete Profile Screen** (`/athletes/:id`)
4. **Canary 4: Tournament Detail Screen** (`/tournaments/:id`)
5. **Canary 5: Head-to-Head Comparison Screen** (`/matches/head-to-head`)
6. **Canary 6: Community Media & Clip Feed Screen** (`/community`)
7. **Canary 7: Referee Live Scorepad Screen** (`/referee/scorepad`)
8. **Canary 8: Tournament Bracket Visualization Screen** (`/tournaments/:id/bracket`)
9. **Canary 9: Weigh-In & Athlete Certification Screen** (`/tournaments/:id/weigh-in`)
10. **Canary 10: Championship Awards & Ceremony Screen** (`/tournaments/:id/awards`)

---

## 2. Detailed Screen-by-Screen Implementation Specifications

---

### Canary 1: Welcome & Onboarding Screen (`/onboarding`)
- **Primary Purpose**: Immediate brand indoctrination, role selection (Athlete, Referee, Fan, Coach), and initial authentication.
- **Visual Composition**:
  - Substrate: L0 Canvas (`#070A11`) with subtle magnesium chalk grain (1.5%).
  - Hero Layer: M1-01 Master Still (High-contrast armwrestling grip in dark silhouette with rim lighting). Zero autoplaying background video (enforcing AX-3).
  - Surface: 3-step progressive wizard anchored by a bottom floating card (L4, `#121826`, 16dp rounded top chamfer, 1px `#334155` border).
- **Interactions**:
  - *Role Selection Cards*: 4 horizontal cards (Athlete, Referee, Organizer, Spectator). Tapping a card initiates **TactileTap** (Cat A): Scale compresses to 0.97 in 100ms (`Curves.easeOutCubic`), border illuminates in Gold (`#D4AF37`), `HapticFeedback.lightImpact()`.
  - *CTA "Enter Arena"*: Fixed 52dp height, 8dp chamfer, Gold fill (`#D4AF37`), black text (`#070A11`, `SpaceGrotesk-Bold`). Tap triggers 120ms depression followed by forward route push.
- **Motion Choreography**:
  - Ingress: Staggered entrance. Hero media fades in (0–300ms, `Curves.easeOutCubic`). Title and role cards slide up 24dp sequentially with 40ms stagger (300–550ms).
  - Step Transition: Sliding horizontal translation of wizard steps (X: 100% -> 0%, 250ms, `Curves.easeInOutCubic`).
- **Performance & Guardrails**:
  - Cold launch time to interactive: **<450ms**.
  - All assets pre-cached in local memory; zero network wait for first paint.

---

### Canary 2: Home & Dashboard Screen (`/home`)
- **Primary Purpose**: Daily central command showing live tournaments, upcoming bouts, personalized athlete summary, and federation alerts.
- **Visual Composition**:
  - Viewport Base: L1 (`#0B0F19`).
  - Top Bar: Compact federation header with live network sentinel dot and unread notification badge (L3, 56dp height).
  - Unbundled Sections: 
    - Section 1: "LIVE ARENAS" — Snapping horizontal rail of live tournament cards (L2, `#121826`).
    - Section 2: "UPCOMING BOUTS" — Full-bleed editorial rows separated by 1px hairlines (`#334155`).
    - Section 3: "FEDERATION LEADERBOARD" — Top 5 ELO readouts with monospace figures.
- **Interactions**:
  - *Chalk Dust Pull-to-Refresh (SIG-7)*: Pulling down triggers knurled cable tension, 80dp threshold haptic snap, and instant SQLite tournament check.
  - *Tournament Rail Snapping (Cat H)*: `PageView` with snapping physics; center card locks with subtle Gold top-edge sheen.
- **Motion Choreography**:
  - Initial Load: Skeleton shimmer (Cat R) sweeps for 400ms before fading into live tournament cards (150ms cross-fade).
  - Scroll Response: Top app bar pins cleanly; live indicator dot pulses smoothly every 2000ms via `Curves.easeInOut`.
- **Performance & Guardrails**:
  - Frame rate target: Solid 60fps during high-speed vertical flick scrolls.
  - Rail cards wrapped in `RepaintBoundary`.

---

### Canary 3: Athlete Profile Screen (`/athletes/:id`)
- **Primary Purpose**: Comprehensive biometric, match history, ELO rating, and achievement showcase for an individual competitor.
- **Visual Composition**:
  - Hero Layer: Parallax collapsing header (320dp expanded, 56dp pinned) with high-contrast athlete portrait and national flag watermark.
  - Surface Architecture: L1 background (`#0B0F19`) housing sticky segment tabs: `[STATS]`, `[MATCHES]`, `[TROPHIES]`, `[MEDIA]`.
- **Interactions**:
  - *Arm-Switch Flip (SIG-4)*: Tapping the "LEFT ARM / RIGHT ARM" toggle triggers an authentic 3D card perspective flip (240ms total duration, `HapticFeedback.selectionClick()`), instantly reloading arm-specific ELO and records.
  - *ELO Surge Bell (SIG-3)*: Displays ELO rating with animated tabular number roll and floating differential badge.
  - *Match History Expansion (Cat T)*: Accordion expansion on past bouts revealing referee name, round times, and fouls in 200ms (`Curves.easeInOutCubic`).
- **Motion Choreography**:
  - Scroll: Hero image scales down subtly (1.00 -> 0.95) with parallax factor 0.5. Top title compresses and snaps to pinned app bar.
- **Performance & Guardrails**:
  - Zero image decoding hiccups during scroll via pre-warmed image cache.

---

### Canary 4: Tournament Detail Screen (`/tournaments/:id`)
- **Primary Purpose**: The hub of an active tournament: pools, tables, schedule, live streaming link, and registration status.
- **Visual Composition**:
  - Header: Dual-tone stadium hero banner with event status chip: `[● LIVE - TABLE 1 TO 6 ACTIVE]`.
  - Body: Multi-table status grid (L2 cards) showing current table occupants and on-deck armwrestlers.
- **Interactions**:
  - *Table Card Tap*: Initiates **Match Reveal / Walkout Transition (SIG-1)** into the live bout view.
  - *Filter Tray (Cat N)*: Sticky filter pills for Weight Classes (-75kg, -85kg, +110kg) with instant debounced list updates.
- **Motion Choreography**:
  - Table Status Update: When a table transitions from "WARMUP" to "IN BOUT", the card border transitions from `#334155` to Emerald Green (`#10B981`) in 200ms (`Curves.easeOutCubic`).
- **Performance & Guardrails**:
  - Real-time updates delivered via WebSockets/Supabase Realtime with local SQLite fallback.

---

### Canary 5: Head-to-Head Comparison Screen (`/matches/head-to-head`)
- **Primary Purpose**: Tale of the tape: direct physical, tactical, and statistical comparison between two scheduled opponents.
- **Visual Composition**:
  - Layout: Vertical split screen with 15° diagonal shear divider in Champagne Gold (`#D4AF37`).
  - Left Competitor: Red Corner (`#EF4444` ambient hue).
  - Right Competitor: Blue Corner (`#38BDF8` ambient hue).
  - Center Axis: Comparative biometric bars (Forearm circumference, Bicep, Hand size, Reach, Win Rate).
- **Interactions**:
  - *Metric Bar Growth*: On screen ingress, comparative horizontal bars expand outward from center axis to their respective athlete values in 350ms (`Curves.easeOutCubic`).
  - *Arm Toggle*: Switching arms triggers synchronized dual-card 3D flip.
- **Motion Choreography**:
  - Walkout Entry: Athletes enter from left and right edges (200ms, `Curves.easeOutCubic`), laser line cuts down center (150ms).
- **Performance & Guardrails**:
  - Monospace figure alignment prevents numerical jitter during bar animation.

---

### Canary 6: Community Media & Clip Feed Screen (`/community`)
- **Primary Purpose**: High-engagement video clips, training techniques, tournament highlights, and community discussions.
- **Visual Composition**:
  - Viewport: Full-screen 9:16 vertical card feed with technical HUD overlay.
  - Surface: Pure black substrate (`#000000`) with high-contrast text overlays and translucent action dock.
- **Interactions**:
  - *Tactical Video Player (Cat O)*: In-view autoplay with audio muted; tap to unmute with volume fade; double-tap right/left for ±5s seek; drag scrubber for precision timeline preview.
  - *Like / Bookmark*: Instant scale bounce (0.90 -> 1.15 -> 1.00, 150ms) with `HapticFeedback.lightImpact()`.
- **Motion Choreography**:
  - Vertical Feed Scroll: Snapping vertical `PageView` with instant video controller disposal for off-screen items.
- **Performance & Guardrails**:
  - Maximum 1 active video player in GPU memory. Memory capped at <120MB.

---

### Canary 7: Referee Live Scorepad Screen (`/referee/scorepad`)
- **Primary Purpose**: Zero-latency, table-side scoring interface for sanctioned federation referees.
- **Visual Composition**:
  - Mode: **Referee Precision Mode (Mode 3)**.
  - Theme: High-contrast dark substrate (`#070A11`). All bottom bars, search bars, and banners hidden.
  - Layout: Split table pads (Left Competitor vs Right Competitor).
  - Targets: Extra-large touch pads (minimum **64dp x 64dp**).
- **Interactions**:
  - *400ms Pin Hold Lock (SIG-2)*: Touch-and-hold pin confirmation with radial progress sweep, millisecond countdown, and heavy haptic bell lock.
  - *Referee Table Foul Flash (SIG-8)*: Single tap on "FOUL" triggers instantaneous (0ms) dual-border red screen pulse and score deduction lock.
- **Motion Choreography**:
  - Timing: Strict **T0 Tier (<50ms)**. Zero artificial animations on scoring paths.
- **Performance & Guardrails**:
  - **0ms input latency**. UI writes immediately to local SQLite database with background queue sync.

---

### Canary 8: Tournament Bracket Visualization Screen (`/tournaments/:id/bracket`)
- **Primary Purpose**: Navigating, inspecting, and tracking a 64-competitor double-elimination tournament tree.
- **Visual Composition**:
  - Canvas: 2D spatial plane rendered via custom `CustomPainter`.
  - Nodes: Compact match cells (L2, `#121826`, 8dp chamfer) linked by technical 1.5px orthogonal connector lines (`#334155`).
- **Interactions**:
  - *Bracket Spatial Navigation (Cat G)*: Smooth multi-touch pan and pinch-zoom (0.5x to 2.5x) with bottom-right HUD mini-map.
  - *Bracket Advance Lightning Line (SIG-6)*: Winner node illuminates in Gold; glowing vector pulse advances along connector path to next round slot (250ms, `Curves.easeInOutCubic`).
- **Motion Choreography**:
  - Double-tap node zooms and centers viewport on selected match in 250ms (`Curves.easeInOutCubic`).
- **Performance & Guardrails**:
  - Entire bracket tree isolated in `RepaintBoundary`. Rendered off-screen with level-of-detail culling to sustain 60fps.

---

### Canary 9: Weigh-In & Athlete Certification Screen (`/tournaments/:id/weigh-in`)
- **Primary Purpose**: Official athlete weigh-in check-in, weight certification, and division clearance.
- **Visual Composition**:
  - Viewport Base: L1 (`#0B0F19`).
  - Target Card: Athlete digital passport with live weight class status indicator (`ALLOWED: 80.0 - 85.0 KG`).
  - Keypad: 64dp high numeric keypad with large monospace readout.
- **Interactions**:
  - *Rubber Stamp Clearance (SIG-5)*: Official taps "CERTIFY WEIGHT"; octagonal green rubber stamp descends rapidly from Scale 2.5 to 1.0 with a -12° rotation, hitting card with heavy haptic shockwave.
  - *Weight Over Limit Alert*: Amber border pulse and inline error message if weight exceeds class ceiling.
- **Motion Choreography**:
  - Stamp impact settles in 150ms (`Curves.easeInQuad`) with faint chalk dust particle dissipation.
- **Performance & Guardrails**:
  - Offline capable; certifications stored locally with cryptographically signed referee hash.

---

### Canary 10: Championship Awards & Ceremony Screen (`/tournaments/:id/awards`)
- **Primary Purpose**: The final ceremonial celebration: podium presentation, medal awards, and tournament closure.
- **Visual Composition**:
  - Viewport: Deep Void Black (`#070A11`) with Champagne Gold ambient lighting.
  - Centerpiece: 3-tier podium (1st Gold `#D4AF37`, 2nd Silver `#CBD5E1`, 3rd Bronze `#D97706`).
- **Interactions**:
  - *Podium Reveal Tap*: Tapping a podium tier triggers an expanding trophy card with athlete tournament highlights and full federation medal badge.
  - *Share Podium Graphic*: Generates high-res exportable tournament certificate for social media.
- **Motion Choreography**:
  - Ceremony Sequence (T4 Tier, 600ms): Podium tiers rise sequentially from bottom margin (40ms stagger); championship trophy glides in with soft specular shimmer; 24 momentary gold particles dissipate outward.
- **Performance & Guardrails**:
  - Particle effects auto-terminate after 600ms to preserve GPU thermals.

---

## 3. Canary Implementation Quality Verification Matrix

| Canary Screen | Route Identifier | Key Material | Primary Signature Interaction | Frame Budget | Offline Resilience |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Canary 1: Onboarding** | `/onboarding` | Chalk / Steel | TactileTap (Cat A) | <16.6ms | Full Local Cache |
| **Canary 2: Home** | `/home` | Steel / Rubber | Chalk Pull Refresh (SIG-7) | <16.6ms | SQLite Sync |
| **Canary 3: Athlete Profile**| `/athletes/:id` | Steel / Brass | Arm-Switch Flip (SIG-4) | <16.6ms | Cached Records |
| **Canary 4: Tournament Detail**| `/tournaments/:id`| Table Rubber | Match Reveal Walkout (SIG-1)| <16.6ms | SQLite Sync |
| **Canary 5: Head-to-Head** | `/matches/h2h` | Brass / Steel | Laser Axis Settle (SIG-1) | <16.6ms | Cached Biometrics |
| **Canary 6: Community Media**| `/community` | Chalk / Film | Tactical Video Player (Cat O)| <16.6ms | Cached Thumbnails |
| **Canary 7: Referee Scorepad**| `/referee/scorepad`| Table Rubber | 400ms Pin Hold (SIG-2) / Foul (SIG-8)| **<8.3ms (0ms paint)**| 100% Offline SQLite |
| **Canary 8: Tournament Bracket**| `/tournaments/bracket`| Knurled Steel| Bracket Advance Line (SIG-6)| <16.6ms | Local Tree Cache |
| **Canary 9: Weigh-In** | `/weigh-in` | Rubber / Brass | Rubber Stamp Clearance (SIG-5)| <16.6ms | Offline Hash Sign |
| **Canary 10: Awards Ceremony**| `/awards` | Gold / Brass | Podium Rise (T4 Ceremony) | <16.6ms | Local Cert Gen |
