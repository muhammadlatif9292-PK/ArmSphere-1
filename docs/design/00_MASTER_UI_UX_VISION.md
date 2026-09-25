# ArmSphere Master UI/UX Vision & Visual North Star
**Authoritative Experience Blueprint**
**Document Version**: 1.0.0
**Status**: APPROVED

---

## 1. Executive Summary & Brand Identity

ArmSphere is the definitive international competitive armwrestling platform—governing sanctioned tournaments, national ranking ladders, verified referee scoring, championship title lineages, athlete biometric profiles, and grassroots community meetups across Pakistan and international federations.

The product identity merges **athletic raw power** with **high-precision federation governance**:
- **Not a generic social network**: This is a serious competitive sports instrument.
- **Not an arcade video game**: The visual language conveys institutional trust, cryptographic integrity, and athletic prestige.
- **Not a cramped corporate spreadsheet**: Information density is balanced with breathing room, strong typographic hierarchy, and atmospheric depth.

---

## 2. Visual North Star Grammar

Derived from the visual reference direction, ArmSphere adheres to an uncompromising, dark-mode-first aesthetic grammar:

```
┌─────────────────────────────────────────────────────────────────┐
│                      VISUAL ARCHITECTURE                        │
├─────────────────────────────────────────────────────────────────┤
│ Foundation: Deep Charcoal Navy Void (#070A11 / #0B0F19)         │
│ Layer 1: Glass Substrate Cards (Surface 1: #121826 @ 0.85)      │
│ Layer 2: Elevated Interactive Cells (Surface 2: #1E293B @ 0.90) │
│ Accent A: Luminous Cyan / Ice Blue Highlights (#38BDF8 / #7DD3FC│
│ Accent B: Prestige Champagne & Burnished Gold (#D4AF37 / #F5E096│
│ Semantic: Emerald Mint (#10B981) • High-Contrast Coral (#FF5252)│
│ Borders: Ultra-Thin Precision Lines (1px @ 0.12 - 0.20 Opacity) │
│ Atmosphere: Subdued Monochromatic Arena Light Gradients (5-10%) │
└─────────────────────────────────────────────────────────────────┘
```

### Visual Characteristics:
1. **Deep Black / Charcoal / Navy Foundation**:
   - Background colors `#070A11` and `#0B0F19` ground the interface, conserving OLED battery life on Android devices and focusing attention onto the active competition data.
2. **Silver-Gray & Glass Structural Surfaces**:
   - Elevated cards use layered semi-transparency (`#121826` with 12px blur on high-performance devices, falling back to solid `#141C2E` on low-end hardware).
3. **Luminous Ice-Blue Highlights**:
   - Represents the technological pulse: active tab indicators, selection pill outlines, live timeline connectors, and ELO rating graphs.
4. **Restrained Gold for Prestige**:
   - Reserved strictly for championships, titles, podium finishes, national rankings, and verified official badges. Never used as generic button background across common forms.
5. **Restrained Mint / Emerald for Operational Flow**:
   - Signals verified weigh-in approvals, recorded match wins, connected real-time tunnels, and active table calls.
6. **Controlled Warm Coral / Red for Critical States**:
   - Alerts referees to match fouls, disputed scorecards, emergency cancellations, and irreversible account actions.
7. **Cool-White Precision Typography**:
   - Headings and technical metrics use `SpaceGrotesk` with tight letter spacing for an engineered, athletic feel. Body content uses `Inter` for legibility under bright outdoor competition lighting.
8. **Restrained Atmosphere Over Pure Darkness**:
   - Subtle background gradients (5-8% opacity ambient light cones) prevent the dark mode from feeling sterile or flat without sacrificing contrast.

---

## 3. The 8 Distinct Experience Modes

ArmSphere serves diverse users—from an athlete stepping up to the tournament table to a referee logging fouls under time pressure, or a federation director reviewing dispute evidence. One size does not fit all. We partition the application into **8 Experience Modes**, each tuned for specific mental models while sharing the unified design tokens:

```
┌───────────────────────────────────────────────────────────────────────┐
│                      THE 8 EXPERIENCE MODES                           │
├────────┬─────────────────────┬──────────────────┬─────────────────────┤
│ Mode   │ Domain              │ Visual Cadence   │ Primary Objective   │
├────────┼─────────────────────┼──────────────────┼─────────────────────┤
│ Mode A │ Entry & Trust       │ Calm, Cinematic  │ Establish authority │
│ Mode B │ Discovery           │ Expressive, Rich │ Explore athletes/evs│
│ Mode C │ Live Competition    │ High-contrast    │ Low-latency updates │
│ Mode D │ Instrument Data     │ Dense, Precision │ Read ELO/brackets   │
│ Mode E │ Community Social    │ Warm, Engaging   │ Video & discussions │
│ Mode F │ Training & Biometric│ Focused, Metric  │ Log PRs & progress  │
│ Mode G │ Official Governance │ Serious, Neutral │ Unbiased arbitrate  │
│ Mode H │ Security & Payments │ Secure, Clear    │ Zero friction auth  │
└────────┴─────────────────────┴──────────────────┴─────────────────────┘
```

### Mode A: Entry & Trust (Splash, Welcome, Role Intent, Onboarding)
- **Atmosphere**: Cinematic introduction to Pakistan's armwrestling federation.
- **Pacing**: Deliberate, smooth transitions; establishes prestige and security.
- **Visuals**: Ambient light cone, gold federation seal, clear value pillars.

### Mode B: Discovery (Discover Screen, Search, Venues, Informal Meetups)
- **Atmosphere**: Exploratory, engaging, content-driven.
- **Pacing**: Responsive cards, quick previews, horizontal chips for quick filtering.
- **Visuals**: Event banner artwork, venue photos, athlete avatars with verified badges.

### Mode C: Live Competition (Live Table Callouts, Countdown, Active Matches)
- **Atmosphere**: High adrenaline, laser focus, instant orientation.
- **Pacing**: Zero visual clutter; massive scores, table numbers, pulsating status dots.
- **Visuals**: High-contrast coral/crimson live indicators (`liveGlow()`), bold player names, timer countdowns.

### Mode D: Instrument Data (Rankings Ladder, Brackets, ELO Ledger, Lineage)
- **Atmosphere**: Technical, authoritative, data-dense instrument panel.
- **Pacing**: Rapid scanning, sticky headers, sorted columns, sparkline graphs.
- **Visuals**: Compact row heights, mono-aligned numbers, tier badges (Gold/Silver/Bronze), ELO differential indicators (+/- ELO).

### Mode E: Community & Social (Feed, Video Posts, Comments, Team Rosters)
- **Atmosphere**: Communal, peer-celebrating, athletic camaraderie.
- **Pacing**: Fluid vertical scroll, responsive video embeds (YouTube/TikTok/FB), like counters.
- **Visuals**: Clean media aspect ratio boxes, athlete profile tags, compact comment threads.

### Mode F: Training & Biometrics (Training Logs, PR Tracker, Arm Dominance Specs)
- **Atmosphere**: Personal workshop, strength tracking, self-improvement.
- **Pacing**: Direct input, quick exercise pills (Bicep Curl, Wrist Wrench, Cup, Pronation).
- **Visuals**: Radar charts of arm dimensions, PR milestone badges, weight curve graphs.

### Mode G: Official Governance & Officiating (Referee Scorepad, Dispute Arbitration)
- **Atmosphere**: Legal, judicial, unshakeable recordkeeping.
- **Pacing**: Defensive confirmations, high-contrast toggle buttons (Foul, Warning, Pin, Flash Pin).
- **Visuals**: Neutral slate backgrounds, cryptographic hash indicators, evidence attachments, formal status stamps.

### Mode H: Security, Identity & Payments (MFA, Active Sessions, Stripe Checkout)
- **Atmosphere**: Cryptographic vault, reassuring clarity, error-free.
- **Pacing**: Uncluttered single-column forms, explicit button states, biometric prompts.
- **Visuals**: Security shields, active session device badges, Stripe payment sheet integration.

---

## 4. Mobile Ergonomics & Handheld Physics

ArmSphere is engineered for physical armwrestling environments:
- **Sweaty Hands / Table-side Usage**: Touch targets are enlarged to a minimum of 48×48dp (with active hit areas extending to 56dp for referee score buttons).
- **One-Handed Navigation**: Critical navigation anchors (Main Shell Bottom Nav, Primary CTAs, Floating Action Buttons) live in the natural thumb zone (bottom 35% of the screen).
- **High Glare Outdoor Visibility**: Text contrast against dark cards is strictly maintained above 7:1 for headers and 4.5:1 for secondary labels, ensuring readability under outdoor venue floodlights or direct sun.
- **Haptic Confirmations**: Critical referee button presses (Score Increment, Match Pin, Foul Declared) utilize device haptic feedback (`HapticFeedback.heavyImpact()`) so officials receive physical confirmation without looking away from the table.
