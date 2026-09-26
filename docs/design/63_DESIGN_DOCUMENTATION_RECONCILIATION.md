# ArmSphere Stage Consolidation & Design Governance Reconciliation
**Document Version**: 1.0.0 (Authoritative Governance Reconciliation)
**Date**: September 27, 2026
**Status**: APPROVED & LOCKED INTO REPOSITORY
**Authority**: `docs/design/00_DESIGN_AUTHORITY.md`, `UI_UX_DESIGN_STATE.md`, Stage 3 Architecture (45–53), Stage 4 Architecture (54–62), & Master Reconciliation Directive
**Scope**: Definitive 20-Section Master Reconciliation Report, Elimination of Numbering Collisions, Resolution of Media/Video Contradictions, Empirical Claim Classification, and Single Source of Truth Hierarchy.

---

## 1. Previous State & Architectural Context

Prior to this reconciliation pass, the ArmSphere design ecosystem had progressed through multiple intensive phases:
1. **Foundational Architecture (Docs 00–44)**: Codified the 26-feature inventory, 66-screen catalog, 9 federation roles, 4-tier theme engine, 8dp spatial grid, and accessibility baseline.
2. **Implementation Slices 1–12 (Phases 1–3)**: Successfully implemented and verified 12 critical code slices in `apps/mobile/lib/` (theme token normalization, 64dp referee scorepad targets, 400ms pin hold, sticky action bars, tournament detail scrims, 3-step onboarding wizard, bracket RepaintBoundary isolation, skeleton shimmer, and signature ceremonial moments).
3. **Stage 3 (Docs 45–53)**: Produced the Master Media Asset Map (M0–M7), Google Flow image prompt packs, video shotlists, motion refinement, and media integration specifications.
4. **Stage 4 (Docs 45–53)**: Produced the 19-dimensional North Star visual reference deconstruction, 16-factor visual DNA matrix, refined semantic token hierarchy, 6-level surface architecture, 7-layer depth stack, screen composition language, and 10 canary screen specifications.

---

## 2. Problems & Ambiguities Discovered

An exhaustive audit of `docs/design/` revealed four critical structural issues that threatened long-term AI memory and engineering execution:
1. **Direct Numbering Collision (45–53)**: Both Stage 3 and Stage 4 simultaneously claimed file numbers `45` through `53`, resulting in conflicting filename prefixes (e.g., two `45_*.md` files, two `53_*.md` files).
2. **Duplicate Deep Research Brief**: `docs/design/52_STAGE_4_DEEP_RESEARCH_BRIEF.md` existed alongside an unnumbered mirror `docs/design/STAGE_4_DEEP_RESEARCH_BRIEF.md`.
3. **Competing "Final / Master Handoff" Claims**: Multiple documents (`29_FINAL_DESIGN_HANDOFF.md`, `53_PREMIUM_FINAL_HANDOFF.md`, and Stage 4's `53_STAGE_4_FINAL_VISUAL_HANDOFF.md`) claimed exclusive final authority without an explicit parent-child governance chain.
4. **Video Policy Drift**: Early exploratory documents (`15_VIDEO_ASSET_STRATEGY.md`) discussed speculative video backgrounds, whereas later operational documents (`48_FLOW_VIDEO_SHOTLIST.md`) strictly prohibited video on splash, scorepads, brackets, and auth forms.
5. **Empirical Claim Conflation**: Strong terms like `100% COMPLETE`, `PASS`, `VERIFIED`, and `ZERO` were occasionally used without clear distinction between repository-verified code facts, design specifications, and planned future laboratory tests.

---

## 3. Numbering Collision Resolution

To eliminate the collision permanently while preserving historical commit continuity, the **Stage 3 suite remains locked at 45–53**, and the **Stage 4 suite is renumbered into the sequential canonical range 54–62**:

| Stage | Original Numbering | Canonical Renumbered Identifier | Document Title |
| :--- | :--- | :--- | :--- |
| **Stage 3** | `45` | `docs/design/45_PREMIUM_LAYER_AUDIT.md` | Premium Layer Audit |
| **Stage 3** | `46` | `docs/design/46_MASTER_MEDIA_ASSET_MAP.md` | Master Media Asset Map (M0–M7) |
| **Stage 3** | `47` | `docs/design/47_FLOW_IMAGE_PROMPT_PACK.md` | Flow Image Prompt Pack |
| **Stage 3** | `48` | `docs/design/48_FLOW_VIDEO_SHOTLIST.md` | Master Flow Video Shotlist |
| **Stage 3** | `49` | `docs/design/49_PREMIUM_MOTION_ENGAGEMENT_REFINEMENT.md` | Motion & Sensory Refinement |
| **Stage 3** | `50` | `docs/design/50_MEDIA_INTEGRATION_SPEC.md` | Media Integration Specification |
| **Stage 3** | `51` | `docs/design/51_PREMIUM_PRODUCTION_TIMELINE.md` | Media Production Timeline |
| **Stage 3** | `52` | `docs/design/52_PREMIUM_VISUAL_QA.md` | Master Visual QA Protocol |
| **Stage 3** | `53` | `docs/design/53_PREMIUM_FINAL_HANDOFF.md` | Stage 3 Media & Motion Handoff |
| **Stage 4** | `45` | **`docs/design/54_VISUAL_REFERENCE_DECONSTRUCTION.md`** | Visual Reference Deconstruction |
| **Stage 4** | `46` | **`docs/design/55_ARMSPHERE_VISUAL_DNA.md`** | ArmSphere Visual DNA Matrix |
| **Stage 4** | `47` | **`docs/design/56_VISUAL_TOKEN_REFINEMENT.md`** | Visual Token Refinement |
| **Stage 4** | `48` | **`docs/design/57_SURFACE_AND_DEPTH_ARCHITECTURE.md`** | Surface & Depth Architecture |
| **Stage 4** | `49` | **`docs/design/58_SCREEN_COMPOSITION_LANGUAGE.md`** | Screen Composition Language |
| **Stage 4** | `50` | **`docs/design/59_PREMIUM_MOTION_LANGUAGE.md`** | Premium Motion Language |
| **Stage 4** | `51` | **`docs/design/60_PREMIUM_CANARY_SCREEN_PLAN.md`** | Premium Canary Screen Plan |
| **Stage 4** | `52` | **`docs/design/61_STAGE_4_DEEP_RESEARCH_BRIEF.md`** | Canonical Deep Research Brief |
| **Stage 4** | `53` | **`docs/design/62_STAGE_4_FINAL_VISUAL_HANDOFF.md`** | Stage 4 Visual Architecture Handoff |
| **Consolidation**| — | **`docs/design/63_DESIGN_DOCUMENTATION_RECONCILIATION.md`** | Master Reconciliation Authority |

---

## 4. Renames Performed via Git

All renames were executed using `git mv` to guarantee unbroken Git tracking:
- `git mv docs/design/45_VISUAL_REFERENCE_DECONSTRUCTION.md docs/design/54_VISUAL_REFERENCE_DECONSTRUCTION.md`
- `git mv docs/design/46_ARMSPHERE_VISUAL_DNA.md docs/design/55_ARMSPHERE_VISUAL_DNA.md`
- `git mv docs/design/47_VISUAL_TOKEN_REFINEMENT.md docs/design/56_VISUAL_TOKEN_REFINEMENT.md`
- `git mv docs/design/48_SURFACE_AND_DEPTH_ARCHITECTURE.md docs/design/57_SURFACE_AND_DEPTH_ARCHITECTURE.md`
- `git mv docs/design/49_SCREEN_COMPOSITION_LANGUAGE.md docs/design/58_SCREEN_COMPOSITION_LANGUAGE.md`
- `git mv docs/design/50_PREMIUM_MOTION_LANGUAGE.md docs/design/59_PREMIUM_MOTION_LANGUAGE.md`
- `git mv docs/design/51_PREMIUM_CANARY_SCREEN_PLAN.md docs/design/60_PREMIUM_CANARY_SCREEN_PLAN.md`
- `git mv docs/design/52_STAGE_4_DEEP_RESEARCH_BRIEF.md docs/design/61_STAGE_4_DEEP_RESEARCH_BRIEF.md`
- `git mv docs/design/53_STAGE_4_FINAL_VISUAL_HANDOFF.md docs/design/62_STAGE_4_FINAL_VISUAL_HANDOFF.md`

All internal markdown cross-references and links across `54_`, `62_`, and `UI_UX_DESIGN_STATE.md` were updated to point to the new canonical identifiers.

---

## 5. Duplicate Files Discovered & Audited

- **Duplicate Identified**: `docs/design/STAGE_4_DEEP_RESEARCH_BRIEF.md` was found to be a redundant unnumbered mirror of `52_STAGE_4_DEEP_RESEARCH_BRIEF.md`.
- **Content Comparison**: The numbered file contained 100% of the comprehensive 13 research vectors, research constraints, and universal extraction schema. The unnumbered file was an abbreviated pointer.

---

## 6. Files Merged

No fragmented information required manual merging; the complete text already resided in `61_STAGE_4_DEEP_RESEARCH_BRIEF.md`.

---

## 7. Files Removed

- **Removed via Git**: `docs/design/STAGE_4_DEEP_RESEARCH_BRIEF.md` was safely deleted via `git rm`.
- **Result**: Exactly **ONE canonical Deep Research Brief** remains: [`docs/design/61_STAGE_4_DEEP_RESEARCH_BRIEF.md`](file:///e:/ArmSphere/docs/design/61_STAGE_4_DEEP_RESEARCH_BRIEF.md).

---

## 8. Video Policy Reconciliation (Single Canonical Rule)

### The Conflict:
Early exploration in `15_VIDEO_ASSET_STRATEGY.md` discussed potential video loops for onboarding and splash. Later documents (`48_FLOW_VIDEO_SHOTLIST.md`, `50_MEDIA_INTEGRATION_SPEC.md`, `57_SURFACE_AND_DEPTH_ARCHITECTURE.md`) established strict latency, battery, and 60fps GPU constraints.

### Canonical Video Placement Policy (Authoritative Law):
Video is a high-cost, high-cognitive-load medium. It is **exclusively authorized for four specific functional touchpoints**:

```
+-----------------------------------------------------------------------------------+
|                        CANONICAL VIDEO PLACEMENT POLICY                           |
|                                                                                   |
|  APPROVED PLACEMENTS (4 ONLY):             STRICTLY FORBIDDEN CONTEXTS (BANNED):  |
|  1. TournamentDetail Hero Loop (M5)        X App Splash / Boot Screen (<400ms)    |
|     (World/National Tier only, 5s muted)   X Referee Scorepad (0ms touch latency) |
|  2. Community Video Post Modal             X Interactive Bracket Viewers (GPU 60fps)|
|     (On-demand tap, NO autoplay with audio)X Form Entry & Auth Backgrounds (Focus)|
|  3. Live Stream Match Broadcast            X Global App Scaffolding / Drawer      |
|     (Dedicated spectator canvas)           X Settings & Profile Configuration     |
|  4. Referee Foul Dispute Video Replay      X Onboarding Setup Wizard              |
+-----------------------------------------------------------------------------------+
```

### Fallback & Accessibility Mandate:
If `MediaQuery.of(context).disableAnimations` is `true`, OR the battery level is below 20%, OR network connectivity is degraded, all video decoders are disposed from memory and immediately replaced by static high-resolution WebP posters (`M1-HERO-ARENA.webp`).

---

## 9. Image Strategy Reconciliation

### Canonical Asset Family (M0–M7):
Rather than generating an unconstrained sprawl of hundreds of AI images, ArmSphere locks into the **minimal, coherent asset family** defined in [`docs/design/46_MASTER_MEDIA_ASSET_MAP.md`](file:///e:/ArmSphere/docs/design/46_MASTER_MEDIA_ASSET_MAP.md) and [`docs/design/57_SURFACE_AND_DEPTH_ARCHITECTURE.md`](file:///e:/ArmSphere/docs/design/57_SURFACE_AND_DEPTH_ARCHITECTURE.md):
- **M0: Brand Identity**: Debossed Champagne Gold Insignia (`#D4AF37`) on void substrate.
- **M1: Arena Heroes**: 16:9 widescreen arena spotlights, chalk dust vignettes, and competition tables.
- **M2: Macro Textures**: Knurled steel grip alloys, cold-rolled steel plates, and chalk dust.
- **M3: Division Crests**: Heavyweight Anvil, Middleweight Damascus Shield, Lightweight Raptor Claw.
- **M4: Empty States**: Atmospheric narrative scenes for empty tournaments, training logs, and feeds.
- **M5: Video Assets**: Exactly 4 approved video contexts (Section 8 above).
- **M6: Certified Badges**: 3D metallic federation credentials and referee whistles.
- **M7: Fallback Shaders**: 3-level fallback ladder (Network WebP -> Bundled Asset -> Custom GPU Shader Gradient).

### Text-Safe Scrim Law:
All images placed beneath UI text must utilize the **Directional 4-Stop Scrim** (`#070A11` at 100% -> 80% -> 40% -> 0%). Text overlays are restricted strictly to the 100% and 80% scrim zones, guaranteeing minimum 9:1 contrast (WCAG AAA).

---

## 10. Motion Policy Reconciliation

### The Conflict:
`11_MOTION_SYSTEM.md` established foundational tiers; `49_PREMIUM_MOTION_ENGAGEMENT_REFINEMENT.md` introduced sensory haptics; `59_PREMIUM_MOTION_LANGUAGE.md` codified Flutter curve governance.

### Canonical Motion Hierarchy:
The 5-tier motion hierarchy codified in [`docs/design/59_PREMIUM_MOTION_LANGUAGE.md`](file:///e:/ArmSphere/docs/design/59_PREMIUM_MOTION_LANGUAGE.md) is the **single governing authority**:
- **Tier 0 (0ms)**: Immediate state swaps (reduced motion, live scorepad readouts).
- **Tier 1 (80–120ms)**: Micro-feedback scale depression (`0.97x`) with `HapticFeedback.lightImpact()`.
- **Tier 2 (180–240ms)**: Local sheet expansion (`Curves.easeOutCubic`).
- **Tier 3 (250–320ms)**: Directional screen slide with shared-element `Hero` transitions.
- **Tier 4 (600–900ms)**: Cinematic ceremony (45° sweeping gold sheen, rubber stamp drop, Elo surge count-up).
- **Banned Curves**: `Curves.bounceOut`, `Curves.bounceInOut`, `Curves.elasticOut`, and `Curves.elasticInOut` are permanently forbidden.

---

## 11. Color & Visual Token Reconciliation

### Unified Semantic Token Truth:
All colors across all documentation and production Flutter code strictly resolve to [`apps/mobile/lib/core/theme/app_theme.dart`](file:///e:/ArmSphere/apps/mobile/lib/core/theme/app_theme.dart) and [`docs/design/56_VISUAL_TOKEN_REFINEMENT.md`](file:///e:/ArmSphere/docs/design/56_VISUAL_TOKEN_REFINEMENT.md):
- **Void Canvas (`#070A11`)**: Base canvas substrate (18.2:1 contrast against `#F8FAFC`).
- **Viewport Base (`#0B0F19`)**: Elevated structural ground.
- **Solid Surface (`#121826`)**: Standard card container.
- **Elevated Surface (`#1E293B`)**: Interactive cells, form inputs, scorepad triggers.
- **Champagne Gold (`#D4AF37`)**: Restricted to championships, medals, title belts, and master CTAs.
- **Luminous Cyan (`#38BDF8`)**: Navigation focus, active tabs, fight clock telemetry.
- **Adrenaline Crimson (`#EF4444`)**: Table fouls, pins against, forfeits, live alerts.
- **Amber Gold (`#F59E0B`)**: Warnings, in-straps status, pending sanctions.
- **Emerald Mint (`#10B981`)**: Confirmed pins, weigh-in clearances, match victories.

---

## 12. Screen & Feature Inventory Authority

- **Feature Count**: Exactly **26 verified user-facing features** (F01–F26) as inventoried in `docs/design/02_FEATURE_INVENTORY.md`. Zero features were added or deleted during Stage 3 or Stage 4.
- **Screen Count**: Exactly **66 production screen classes + 3 modals** as inventoried in `docs/design/03_SCREEN_INVENTORY.md`. 
- **Mapping Verification**: All 66 screens are comprehensively mapped into the 8 Experience Modes, Surface Levels, and Primary Visual Stories in [`docs/design/58_SCREEN_COMPOSITION_LANGUAGE.md`](file:///e:/ArmSphere/docs/design/58_SCREEN_COMPOSITION_LANGUAGE.md). Zero ghost screens exist.

---

## 13. Role & Persona Authority

The **9 official federation personas** defined in `packages/types` and `docs/design/20_ROLE_BASED_UX.md` remain strictly authoritative:
1. `Athlete` (Competitor, ranking, sparring, Elo)
2. `Referee` (Master official, scorepad, foul dispute)
3. `Organizer` (Tournament director, bracket coordinator)
4. `Coach` (Corner corner-man, athlete analytics)
5. `Club Manager` (Local venue, practice table host)
6. `Federation Official` (Sanctioning, compliance, anti-doping)
7. `Sponsor / Partner` (Prize pool, branding, credentials)
8. `Spectator / Fan` (Live stream, bracket viewing, feed)
9. `System Administrator` (Audit logs, database sync, role verification)

---

## 14. Strong-Claim Audit & Classification

To ensure intellectual integrity and prevent misleading downstream implementation, all authoritative claims across the documentation are categorized into five rigorous epistemic tiers:

```
+-----------------------------------------------------------------------------------+
|                        EPISTEMIC CLAIM CLASSIFICATION                             |
|                                                                                   |
|  [TIER A: REPOSITORY-VERIFIED FACT]                                               |
|  * 58 Neon PostgreSQL tables mapped to Drizzle ORM schemas.                       |
|  * 66 production screen classes compiled in apps/mobile/lib/.                     |
|  * Slices 1–12 (Phases 1–3) implemented and verified in Flutter codebase.         |
|  * SpaceGrotesk and Inter font binaries bundled in apps/mobile/assets/fonts/.     |
|                                                                                   |
|  [TIER B: DESIGN SYSTEM SPECIFICATION]                                            |
|  * 6-level surface architecture (Levels 0–5) and 7-layer depth stack.             |
|  * 8dp harmonic spatial grid tokens and bounded radii (8dp, 12dp, 16dp).           |
|  * 66-screen composition mapping across 8 Experience Modes.                       |
|  * 4-stop directional gradient scrim formulas.                                    |
|                                                                                   |
|  [TIER C: ACCEPTANCE CRITERIA]                                                    |
|  * Minimum 48×48dp touch targets (standard) and 64×64dp (referee scorepad).       |
|  * Mathematical WCAG 2.1 AA/AAA contrast ratios against calculated hex values.    |
|  * 0 RenderFlex layout overflows under 200% dynamic type scaling.                 |
|  * Zero bounceOut/elasticOut animation curves.                                    |
|                                                                                   |
|  [TIER D: PLANNED FUTURE VALIDATION (NOT YET EMPIRICALLY MEASURED ON HARDWARE)]   |
|  * Direct sunlight legibility under physical 2000-lumen arena spotlights.         |
|  * Continuous 30-minute referee battery drain test on low-end Android hardware.   |
|  * Sweaty-finger physical scorepad tap trial during live tournament combat.       |
|                                                                                   |
|  [TIER E: EXTERNAL OPERATOR / PRODUCTION DEPENDENCY]                              |
|  * Generation and delivery of M1–M7 raster assets via Google Flow / Imagen 3.     |
|  * Cloudflare Stream live broadcast CDN integration.                              |
+-----------------------------------------------------------------------------------+
```

---

## 15. Canonical Reading Order for Future AI Agents

Any future AI session entering this repository must ingest design authority in the following **strict sequential order**:

1. **FIRST**: [`docs/design/00_DESIGN_AUTHORITY.md`](file:///e:/ArmSphere/docs/design/00_DESIGN_AUTHORITY.md) (The non-negotiable governance charter).
2. **SECOND**: [`UI_UX_DESIGN_STATE.md`](file:///e:/ArmSphere/UI_UX_DESIGN_STATE.md) (Long-term architectural memory and current code state).
3. **THIRD**: Foundational Architecture (`docs/design/01` through `05` — Features, Screens, Navigation).
4. **FOURTH**: Core Design System (`docs/design/06` through `13` — Tokens, Typography, Components, Motion).
5. **FIFTH**: Media & Asset Strategy (`docs/design/14` through `17`, and Stage 3 `45` through `53`).
6. **SIXTH**: Stage 4 Visual Architecture (`docs/design/54` through `60` — DNA, Tokens, Surfaces, Composition, Canaries).
7. **SEVENTH**: Canonical Deep Research Brief ([`docs/design/61_STAGE_4_DEEP_RESEARCH_BRIEF.md`](file:///e:/ArmSphere/docs/design/61_STAGE_4_DEEP_RESEARCH_BRIEF.md)).
8. **EIGHTH**: Stage 4 Final Handoff ([`docs/design/62_STAGE_4_FINAL_VISUAL_HANDOFF.md`](file:///e:/ArmSphere/docs/design/62_STAGE_4_FINAL_VISUAL_HANDOFF.md)).
9. **NINTH**: Stage Consolidation & Reconciliation (This document, `docs/design/63_DESIGN_DOCUMENTATION_RECONCILIATION.md`).
10. **TENTH**: Implementation Backlog ([`docs/design/27_UI_UX_IMPLEMENTATION_BACKLOG.md`](file:///e:/ArmSphere/docs/design/27_UI_UX_IMPLEMENTATION_BACKLOG.md)).

---

## 16. Current Authoritative Document Hierarchy

```
00_DESIGN_AUTHORITY.md (Constitutional Authority)
       ↓
UI_UX_DESIGN_STATE.md (Persistent Long-Term Memory)
       ↓
FOUNDATIONAL SPECS (01–44: Features, Screens, Roles, Quality Gates)
       ↓
STAGE 3 ARCHITECTURE (45–53: Master Media Map, Video Shotlists, Motion Refinement)
       ↓
STAGE 4 VISUAL ARCHITECTURE (54–60: DNA Matrix, Tokens, Surfaces, 66-Screen Mapping, Canaries)
       ↓
CANONICAL DEEP RESEARCH BRIEF (61_STAGE_4_DEEP_RESEARCH_BRIEF.md)
       ↓
STAGE 4 MASTER HANDOFF (62_STAGE_4_FINAL_VISUAL_HANDOFF.md)
       ↓
GOVERNANCE RECONCILIATION (63_DESIGN_DOCUMENTATION_RECONCILIATION.md)
       ↓
IMPLEMENTATION BACKLOG (27_UI_UX_IMPLEMENTATION_BACKLOG.md)
```

---

## 17. Remaining Genuine Open Questions

The following unresolved design challenges cannot be answered by internal theory alone and are formally assigned to **Gemini Deep Research**:
1. *Optimal Fight Clock Typography Under Glare*: Exact font optical tracking and color transition curves for 48sp fight clocks under 2000-lumen arena lighting.
2. *Asymmetrical Bilateral Telemetry*: Best-in-class mobile patterns for displaying separate Left vs. Right arm ratings without visual clutter.
3. *Mobile Double-Elimination Virtualization*: Start.gg / Challonge UX patterns for 64-competitor bracket navigation on 6.1" smartphones.
4. *No-Look Referee Touch Confirmation*: Industrial safety / sports timing patterns for 64dp hit targets and haptic feedback confirmation loops.

---

## 18. Deep Research Readiness

Document [`docs/design/61_STAGE_4_DEEP_RESEARCH_BRIEF.md`](file:///e:/ArmSphere/docs/design/61_STAGE_4_DEEP_RESEARCH_BRIEF.md) is 100% complete, fully reconciled, bounded against generic redesign creep, and ready for immediate deployment to Gemini Deep Research.

---

## 19. Git Integrity & Code Safety Verification

- **Production Code Status**: Exactly **0 lines** of production Flutter source (`apps/mobile/lib/`), backend API code, or database schemas were modified during this reconciliation.
- **Git File Tracking**: All 9 Stage 4 documents were renumbered via `git mv`; the redundant duplicate was removed via `git rm`.
- **Working Tree Cleanliness**: All documentation changes are cleanly tracked in Git without untracked artifacts.

---

## 20. Final Next Step
The documentation architecture is fully consolidated and sealed. The repository is cleared to proceed to **Phase 5: Gemini Deep Research Execution** utilizing [`docs/design/61_STAGE_4_DEEP_RESEARCH_BRIEF.md`](file:///e:/ArmSphere/docs/design/61_STAGE_4_DEEP_RESEARCH_BRIEF.md).
