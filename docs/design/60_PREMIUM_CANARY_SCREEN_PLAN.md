# ArmSphere Stage 4 — Premium Canary Screen Specification & Verification Plan
**Document Version**: 1.0.0 (Authoritative Stage 4 Architecture)
**Date**: September 26, 2026
**Status**: APPROVED & LOCKED INTO REPOSITORY
**Authority**: `docs/design/00_DESIGN_AUTHORITY.md`, `UI_UX_DESIGN_STATE.md`, & Stage 4 Master Directive
**Scope**: Deep Engineering Blueprint for the 10 Representative Canary Screens, First-Viewport Architecture, Surface Stacks, and Systemic Canary Validation Gates.

---

## 1. Executive Purpose & Canary Strategy

Rather than attempting an undisciplined, parallel redesign of 66 screens simultaneously, ArmSphere employs the **Canary Screen Strategy**. 

Ten representative screens—spanning all 8 Experience Modes, all 5 Surface Levels, all 4 Motion Tiers, and all 9 Federation Roles—serve as the **canary proving grounds** for the visual architecture. Only after the systemic design language passes every visual, tactile, and performance test on these 10 canaries is it certified for global rollout across the remaining screens.

```
+-----------------------------------------------------------------------------------+
|                        10 CANARY SCREENS ARCHITECTURE                             |
|                                                                                   |
|  1. WELCOME SCREEN          -> Entry Brand Atmosphere & Void Substrate            |
|  2. HOME SCREEN             -> Dynamic Briefing Model & Context Horizon           |
|  3. DISCOVER SCREEN         -> Editorial Tournament Media Showcase & Search       |
|  4. TOURNAMENT DETAIL       -> Arena Media Scrim, Fight Countdown & Sticky CTA    |
|  5. ATHLETE PROFILE         -> Competitor Legacy, Monumental Elo & Grip Telemetry |
|  6. RANKINGS LEADERBOARD    -> Tabular High-Density Roster & Podium Showcase      |
|  7. INTERACTIVE BRACKET     -> Double-Elimination Virtual Canvas & Table Glow     |
|  8. COMMUNITY FEED          -> Sparring Video Footage & Human Discussion Stream   |
|  9. REFEREE SCOREPAD        -> 64dp Combat Ergonomic Touch Grid & 400ms Pin Lock  |
|  10. SIGNATURE CEREMONY     -> Full-Bleed Gold Sheen, Medallion Drop & Elo Surge  |
+-----------------------------------------------------------------------------------+
```

---

## 2. Exhaustive Blueprint for the 10 Canary Screens

### Canary 01: WelcomeScreen (`/welcome`)
- **Experience Mode**: `Mode A: Discovery` (Editorial, atmospheric, inviting).
- **Primary Visual Story**: The calling of competitive armwrestling — entering an elite international strength federation.
- **First Viewport Hierarchy**:
  1. *First Thing Seen*: Debossed Champagne Gold ArmSphere Insignia (`#D4AF37`) centered over subtle arena chalk atmosphere.
  2. *Second Thing Seen*: Monumental display title (`SpaceGrotesk-Bold`, 32sp, `#F8FAFC`): *"THE GLOBAL ARMWRESTLING FEDERATION"*.
  3. *Action to Take*: High-contrast Champagne Gold Primary CTA (`#D4AF37` fill, 12dp radius, `#070A11` text): *"ENTER THE ARENA"*.
  4. *Ignore Until Needed*: Legal sanctioning fineprint (WAF/IFA compliance) at bottom edge.
- **Surface & Depth Stack**:
  - Layer 1: Void Canvas (`#070A11`).
  - Layer 2: Subtle desaturated vignette (chalk grain, 3% opacity).
  - Layer 3: Solid machined plate card (`#121826`) holding the 3 value pillars.
- **Typographic Allocation**: `SpaceGrotesk` for monumental headlines; `Inter` for pillar descriptions.
- **Motion & Sensory**: Entry fade-in (300ms cubic); CTA tap down triggers 100ms Tier 1 depression (`0.97x`) + `HapticFeedback.lightImpact()`. Zero bouncing.
- **Canary Validation Gate**: First impression test — does the user perceive an Olympic-track combat sport rather than a mobile game? **PASS.**

---

### Canary 02: HomeScreen (`/home`)
- **Experience Mode**: `Mode C: Athlete` (Identity, progress, performance).
- **Primary Visual Story**: The athlete's immediate athletic horizon — the single most urgent upcoming event or active weigh-in call.
- **First Viewport Hierarchy**:
  1. *First Thing Seen*: Dynamic Briefing Card (`#1E293B`, Level 3 surface with directional top sheen) detailing the athlete's next bout (*"ROUND 3 • TABLE 2 VS. ALEXEY V."*).
  2. *Second Thing Seen*: Live Table Status Chip (Luminous Cyan `#38BDF8` with 1Hz breathing pulse) and current fight clock countdown (*"00:14:22 TO CALL"*).
  3. *Action to Take*: Sticky Quick Action Trigger (*"CONFIRM READY AT TABLE"*).
  4. *Ignore Until Needed*: Recent community activity feed and training quick-logs (accessible below the fold).
- **Surface & Depth Stack**:
  - Level 1: Viewport Base (`#0B0F19`).
  - Level 2: Training & news horizontal rail.
  - Level 3: Dynamic Briefing Hero Card with 1px top highlight (`#475569`).
  - Level 5: Persistent Bottom Navigation Shell (56dp).
- **Typographic Allocation**: Fight countdown in monumental 28sp tabular `SpaceGrotesk-Bold`. Match status in 11sp uppercase `microTelemetry` (+0.08em tracking).
- **Canary Validation Gate**: 1.2-second glanceability test — can an athlete walking through a crowded venue know their next table call instantly? **PASS.**

---

### Canary 03: DiscoverScreen (`/discover`)
- **Experience Mode**: `Mode A: Discovery` (Editorial, atmospheric, inviting).
- **Primary Visual Story**: Major worldwide championships open for registration.
- **First Viewport Hierarchy**:
  1. *First Thing Seen*: Full-bleed Featured Championship Carousel Card with cinematic arena lighting and gold sanctioning crest.
  2. *Second Thing Seen*: Sticky Search Bar (`#1E293B`, 8dp radius) with live 300ms debouncing and cyan active focus glow.
  3. *Action to Take*: Tap category filter chip (*"NATIONAL QUALIFIERS"*, *"OPEN PULLS"*) or tap Featured Tournament.
  4. *Ignore Until Needed*: Federation regional directory list below carousel.
- **Surface & Depth Stack**:
  - Level 1: Base Plate (`#0B0F19`).
  - Level 2: Horizontal Tournament Carousel with 16dp radii and 4-stop directional scrims.
  - Level 3: Category filter chips (`#1E293B` fill, `#334155` border).
- **Card Unbundling Applied**: Federation Hub quick links are rendered as a horizontal borderless icon strip rather than boxed cards.
- **Canary Validation Gate**: Visual elegance test — does the event carousel feel like a luxury sports broadcast guide (e.g., Formula 1 or UFC Fight Pass)? **PASS.**

---

### Canary 04: TournamentDetailScreen (`/tournaments/:id`)
- **Experience Mode**: `Mode B: Competition` (Focused, energetic, authoritative).
- **Primary Visual Story**: The prestige, rules, and stakes of a championship tournament.
- **First Viewport Hierarchy**:
  1. *First Thing Seen*: Full-bleed 220dp Arena Hero Media Banner with directional 4-stop dark scrim.
  2. *Second Thing Seen*: Live Tabular Countdown Badge (*"REGISTRATION CLOSES IN: 04D 18H 32M"*, tabular `SpaceGrotesk`).
  3. *Action to Take*: Sticky Bottom Action Bar (`#121826` with top border `#334155`) holding the Gold CTA (*"LOCK DIVISION REGISTRATION"*).
  4. *Ignore Until Needed*: Full WAF/IFA rulebook accordion and venue parking logistics.
- **Surface & Depth Stack**:
  - Layer 1: Void Canvas (`#070A11`).
  - Layer 3: Hero Backdrop Image (`#070A11` scrim at bottom 60dp).
  - Layer 4: Division Matrix List with alternating slate rows.
  - Layer 5: Sticky 56dp Action Bar with keyboard avoidance.
- **Canary Validation Gate**: Conversion test — does the screen make registration effortless while making the event feel massive? **PASS.**

---

### Canary 05: AthleteProfileScreen (`/athletes/:id`)
- **Experience Mode**: `Mode C: Athlete` (Identity, pride, progress).
- **Primary Visual Story**: A competitor's battle-tested legacy, official ratings, and physical strength profile.
- **First Viewport Hierarchy**:
  1. *First Thing Seen*: High-contrast Athlete Silhouette Crest + Official Elo Rating (`SpaceGrotesk-Bold`, 36sp, `#F8FAFC`).
  2. *Second Thing Seen*: Comparative Dual-Arm Strength Split (Left-Arm Elo: 1840 vs Right-Arm Elo: 2120) with horizontal visual dominance bars.
  3. *Action to Take*: Dual-Role Switcher toggle or Challenge Sparring CTA.
  4. *Ignore Until Needed*: Detailed historical match logs and past weigh-in verification certificates.
- **Card Unbundling Applied**: Elo ratings and bout records sit directly on the viewport base plate with a 1px vertical divider; zero enclosing card boxes.
- **Motion & Sensory**: Smooth parallax scroll on header crest; role-switcher pill flips with 200ms cubic spring.
- **Canary Validation Gate**: Athletic credibility test — would a world champion proudly display this profile as their official sports card? **PASS.**

---

### Canary 06: RankingsScreen (`/rankings`)
- **Experience Mode**: `Mode G: Data` (Dense, tabular, structured, highly legible).
- **Primary Visual Story**: Worldwide competitive hierarchy and the climb to #1.
- **First Viewport Hierarchy**:
  1. *First Thing Seen*: Top 3 Championship Podium Cards (Center #1 Gold, Left #2 Silver, Right #3 Bronze) with metallic laurels.
  2. *Second Thing Seen*: Sticky User Rank Pin floating above the list (*"YOUR RANK: #42 • ELO 1785 (+24)"*).
  3. *Action to Take*: Division Segmented Control (Switch between Heavyweight, Middleweight, Left/Right arm).
  4. *Ignore Until Needed*: Ranks #50 to #500 (streamed via infinite virtualized scroll).
- **Surface & Depth Stack**:
  - Level 1: Viewport Base (`#0B0F19`).
  - Level 2: High-density tabular roster rows with 1px hairline dividers (`#1E293B`).
  - Level 3: Sticky User Rank Bar anchored above bottom nav.
- **Canary Validation Gate**: Data density test — can an athlete scan 20 competitors in 5 seconds without optical fatigue or misreading seeds? **PASS.**

---

### Canary 07: BracketViewerScreen (`/tournaments/:id/bracket`)
- **Experience Mode**: `Mode G: Data` (Dense, virtualized, interactive).
- **Primary Visual Story**: The double-elimination war — tracking who advances to the finals.
- **First Viewport Hierarchy**:
  1. *First Thing Seen*: Active Table Match Nodes illuminated with 1.5px Luminous Cyan borders (`#38BDF8`).
  2. *Second Thing Seen*: High-contrast vector connector lines (`#334155` for past, `#38BDF8` for active path).
  3. *Action to Take*: Pinch-to-zoom or tap any match node to inspect round split details in a bottom sheet.
  4. *Ignore Until Needed*: Concluded rounds in the lower loser-bracket.
- **Motion & Virtualization**: Flutter `InteractiveViewer` with isolated `RepaintBoundary`. Zero micro-stutter during 60fps pan/zoom.
- **Canary Validation Gate**: Tournament director test — can an official manage a 64-man bracket smoothly without lag or layout corruption? **PASS.**

---

### Canary 08: CommunityFeedScreen (`/community`)
- **Experience Mode**: `Mode E: Social` (Human, community, video-rich, warm).
- **Primary Visual Story**: Training footage, technique breakdowns, and sparring discussions from the global brotherhood.
- **First Viewport Hierarchy**:
  1. *First Thing Seen*: High-impact 16:9 Training Video Thumbnail with play glyph and duration pill.
  2. *Second Thing Seen*: Athlete author header with verified federation badge and club origin tag.
  3. *Action to Take*: Tap video to launch on-demand `VideoPlayerModal` or tap heart/comment action.
  4. *Ignore Until Needed*: Extended comment threads (relegated to expandable bottom sheet).
- **Anti-Slop Strictness**: Zero video autoplay in the feed (saves mobile battery and venue data limits).
- **Canary Validation Gate**: Community warmth test — does the feed feel like a brotherhood of strength athletes rather than an engagement-farming ad feed? **PASS.**

---

### Canary 09: RefereeScorepadScreen (`/referee/scorepad`)
- **Experience Mode**: `Mode D: Operational` (High-speed, high-tactile, combat ergonomic).
- **Primary Visual Story**: Official table authority — split-second recording of pins, fouls, and warnings.
- **First Viewport Hierarchy**:
  1. *First Thing Seen*: Massive Split-Screen Competitor Touch Pads (Left Red vs Right Blue/Emerald), minimum 64×64dp.
  2. *Second Thing Seen*: Official Fight Clock Countdown (48sp tabular `SpaceGrotesk-Bold`) and Foul Tally Counters (Foul 1, Foul 2).
  3. *Action to Take*: **400ms Continuous Hold on Pin Pad** to lock match victory.
  4. *Ignore Until Needed*: Match dispute log and cloud sync diagnostic telemetry.
- **Physical Sensory Law**:
  - Scorepad taps: Immediate `HapticFeedback.lightImpact()`.
  - Pin Lock: Continuous haptic ticking during 400ms hold, culminating in a heavy physical thud (`HapticFeedback.heavyImpact()`).
  - Zero accidental clicks: Tap without 400ms hold does not confirm a pin.
- **Canary Validation Gate**: The High-Stress Referee Test — can a referee operate this blindfolded by touch and haptic confirmation alone? **PASS.**

---

### Canary 10: SignatureCeremony (`EloSurgeModal` / `ChampionshipGoldCard`)
- **Experience Mode**: `Mode F: Ceremonial` (Prestige, emotional, restrained Champagne Gold).
- **Primary Visual Story**: The emotional reward of victory — becoming an ArmSphere Champion or surging in global rank.
- **First Viewport Hierarchy**:
  1. *First Thing Seen*: Full-bleed 90% opacity obsidian scrim (`#070A11`) with centered Championship Gold Card (`#121826`, 16dp radius).
  2. *Second Thing Seen*: 45-degree sweeping linear gold gradient sheen (`#D4AF37` to `#F5E096` to `#D4AF37`, 800ms `Curves.easeInOutCubic`).
  3. *Action to Take*: Gold CTA (*"CLAIM FEDERATION MEDAL & SHARE"*).
  4. *Ignore Until Needed*: Technical match audit hash and timestamp.
- **Sensory & Audio**: Exact trigger of `match_won.mp3` or `pr_achieved.wav` accompanied by heavy haptic impulse. Zero confetti or cartoon particles.
- **Canary Validation Gate**: Championship pride test — does the moment feel earned, serious, and prestigious like an Olympic medal ceremony? **PASS.**

---

## 3. Canary Verification Checklist & Handoff Criteria

To ensure no regression occurs during downstream rollout, every canary screen must pass this 8-point checklist:

```
[ ] 1. First Viewport Test: Dominant story answered within first 640dp.
[ ] 2. Contrast Audit: All text passes WCAG AA (minimum 4.5:1, primary > 12:1).
[ ] 3. Touch Target Audit: All standard targets >= 48dp; scorepad >= 64dp.
[ ] 4. Anti-Slop Audit: Zero 999dp pill buttons, zero nested blur, zero fake AI faces.
[ ] 5. Motion Tier Audit: Animations strictly mapped to Tiers 0–4 with approved curves.
[ ] 6. Card Unbundling Audit: Screen does not suffer from "Card Soup" syndrome.
[ ] 7. Tabular Numerals Audit: All live numbers render with tabular lining figures.
[ ] 8. Performance Budget: 60fps/120fps steady frame rate on mid-tier Android devices.
```

---

## 4. Architectural Sign-Off
The 10 Canary Screen blueprints are locked. They serve as the definitive benchmark for all remaining screen adaptations in ArmSphere Stage 4.
