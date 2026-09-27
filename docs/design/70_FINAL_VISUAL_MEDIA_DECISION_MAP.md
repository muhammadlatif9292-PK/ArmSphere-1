# ArmSphere Final Visual & Media Decision Map
**Document Version**: 1.0.0 (Stage 6 Experience Convergence)
**Date**: September 27, 2026
**Status**: APPROVED & LOCKED INTO REPOSITORY
**Authority**: `docs/design/00_DESIGN_AUTHORITY.md`, `UI_UX_DESIGN_STATE.md`, Stage 3 Suite (45–53), Stage 4 Suite (54–62), and Stage 6 Convergence Suite (64–69)
**Scope**: Master visual anchors, definitive static vs. animated vs. video boundaries, Google Flow prompt mappings (M0–M7), offline fallback hierarchy, and immutable media governance.

---

## 1. Executive Mandate & Purpose

This document provides the definitive, single-source-of-truth decision map for all visual assets and media types across ArmSphere. It permanently closes the historical divide between speculative design explorations and operational engineering realities.

Every visual element in the application is governed by three strict classification rules:
1. **Zero Media in Operational Critical Paths**: The Referee Scorepad, Tournament Bracket, Live Timer, and Authentication flows are 100% vector- and code-driven. No raster image or video decoding is ever permitted to block a scoring or marshaling operation.
2. **Deterministic Fallbacks**: Every rich asset (Flow AI image, video clip, ceremonial particle) must have an offline, zero-bandwidth vector or solid-color fallback that renders instantly with 0ms network latency.
3. **Asset Budget Enforcement**: Maximum asset bundle footprints are locked (Total app install size <45MB; individual hero image <180KB; individual clip <4MB).

---

## 2. Canonical Media Boundary Rules (Static vs. Animated vs. Video)

The media ecosystem is strictly segregated into three immutable technical tiers:

```
┌─────────────────────────────────────────────────────────────┐
│                 ARMSPHERE MEDIA BOUNDARIES                  │
├──────────────────────────────┬──────────────────────────────┤
│ TIER 1: CODE & VECTOR ONLY   │ TIER 2: STATIC WEB P IMAGES  │
│ - Referee Scorepads          │ - Onboarding Hero (M1-01)    │
│ - Bracket Trees & Nodes      │ - Athlete Avatars & Badges   │
│ - Timers & ELO Readouts      │ - Tournament Banners         │
│ - Form Fields & Inputs       │ - Category Backgrounds       │
├──────────────────────────────┼──────────────────────────────┤
│ TIER 3: CONTROLLED VIDEO     │ TIER 4: STRICTLY PROHIBITED  │
│ - Community Clip Feeds       │ ❌ Video on Splash           │
│ - Technique Training Hub     │ ❌ Video on Login/Auth       │
│ - Tournament Highlights      │ ❌ Video on Scorepads        │
│ (Lazy loaded, muted default) │ ❌ Video on Brackets         │
└──────────────────────────────┴──────────────────────────────┘
```

### Tier 1: Code & Vector Only (Zero Raster/Video Assets)
- **Screens Covered**: `RefereeScorepadScreen`, `BracketScreen`, `WeighInScreen`, `AuthLoginScreen`, `SettingsScreen`.
- **Implementation**: Pure Flutter `CustomPainter`, `SvgPicture.asset`, Flutter icons (`Icons.*`), and core typography.
- **Performance**: Guaranteed 60fps / 120Hz; 0ms asset decoding; 100% offline operational guarantee.

### Tier 2: Static High-Performance WebP Images
- **Screens Covered**: `WelcomeOnboardingScreen`, `HomeScreen`, `AthleteProfileScreen`, `TournamentDetailScreen`, `HeadToHeadScreen`.
- **Format**: WebP format with 85% quality compression, encoded at 2x and 3x device pixel densities.
- **Maximum File Size**: 180KB for full-bleed hero banners; 45KB for athlete portraits; 15KB for federation badges.
- **Delivery**: Bundled into local asset cache for core canaries; cached via `cached_network_image` with local SQLite disk persistence for dynamic tournament assets.

### Tier 3: Controlled & Encapsulated Video
- **Screens Covered**: `CommunityFeedScreen`, `MediaHubScreen`, `TrainingVaultScreen`.
- **Format**: H.264 / MP4 encoded at 1080p / 720p with variable bitrate (VBR) capped at 2.5 Mbps.
- **Playback Protocols**:
  - Encapsulated inside `MediaPostWidget` or `VideoPlayerController`.
  - Muted by default with explicit user tap-to-unmute.
  - Paused immediately when scrolled more than 100dp out of viewport.
  - Maximum of ONE active video player hardware decoder held in GPU memory at any time.

---

## 3. Master Flow Asset Map & Prompt Cross-Reference (M0–M7)

All visual assets planned for production generation via Google Flow / Imagen are indexed here with their precise screen bindings, file specifications, and prompt links from `docs/design/47_FLOW_IMAGE_PROMPT_PACK.md`:

| Asset Tier | Asset Code | Asset Name & Description | Target Screen Binding | Resolution & Format | Authoritative Prompt File |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **M0** | `M0-01` | Federation Shield Vector Emblem | Splash / Navigation Header | Vector SVG (Infinite) | `47_FLOW_IMAGE_PROMPT_PACK.md#M0` |
| **M1** | `M1-01` | Grip Lock Silhouette (Master Still) | Onboarding Hero Screen | 1080x1920 WebP (160KB)| `47_FLOW_IMAGE_PROMPT_PACK.md#M1-01`|
| **M1** | `M1-02` | Arena Lighting Atmosphere Still | Tournament Hub Background | 1920x1080 WebP (175KB)| `47_FLOW_IMAGE_PROMPT_PACK.md#M1-02`|
| **M2** | `M2-01` | Heavyweight Champion Avatar | Master Athlete Profile | 512x512 WebP (42KB) | `47_FLOW_IMAGE_PROMPT_PACK.md#M2-01`|
| **M2** | `M2-02` | Armwrestling Table Top Down | Table Layout / Staging Hub | 1024x1024 WebP (95KB) | `47_FLOW_IMAGE_PROMPT_PACK.md#M2-02`|
| **M3** | `M3-01` | Knurled Steel Grip Macro | Bottom Sheet Drag Handle Texture | 256x256 WebP (12KB) | `47_FLOW_IMAGE_PROMPT_PACK.md#M3-01`|
| **M4** | `M4-01` | World Championship Trophy | Awards Ceremony Canary | 1024x1024 WebP (110KB)| `47_FLOW_IMAGE_PROMPT_PACK.md#M4-01`|
| **M5** | `M5-01` | Hook vs Toproll Tactical Diagram | Training & Technique Hub | Vector SVG (18KB) | `47_FLOW_IMAGE_PROMPT_PACK.md#M5-01`|
| **M6** | `M6-01` | Gold Medalist Podium Still | Tournament Victory Screen | 1080x1080 WebP (125KB)| `47_FLOW_IMAGE_PROMPT_PACK.md#M6-01`|
| **M7** | `M7-01` | Community Training Reel Cover | Community Feed Default Cover | 720x1280 WebP (85KB) | `47_FLOW_IMAGE_PROMPT_PACK.md#M7-01`|

---

## 4. Multi-Tier Offline & Low-Power Fallback Hierarchy

To ensure uninterrupted tournament operations regardless of signal degradation or device thermal throttling:

```
[Tier A: High-Bandwidth / Connected]
  Full WebP Hero Images + Autoplaying Community Video + Real-Time Sync
         │
         ▼ (Signal Drops or Cellular Saver On)
[Tier B: Low-Bandwidth / Cached]
  Locally Cached WebP Images + Static Video Poster Frames + SQLite Sync
         │
         ▼ (Signal Completely Lost / Offline Arena)
[Tier C: Full Offline Mode]
  Zero Remote Fetches + Local SQLite Storage + Pre-bundled Vector Graphics
         │
         ▼ (Battery Saver / Low Power Active)
[Tier D: Emergency Low-Power Mode]
  Solid Color Substrates (#0B0F19) + High-Contrast Typography + 0ms Animations
```

### Fallback Implementation Rules:
1. When `connectivity == none`, every network image widget falls back immediately to a pre-bundled local placeholder vector (`assets/images/placeholders/arena_placeholder.svg`) with zero UI layout jumping.
2. In `RefereeScorepadScreen`, network connectivity is completely decoupled from UI rendering. The scorepad runs exclusively on local in-memory state backed by SQLite transaction logs.
3. In low-power mode, video previews render as static high-contrast poster thumbnails with a central play button overlay.

---

## 5. Visual Asset Governance & Production Readiness Checklist

Before any newly generated image or video asset is merged into `apps/mobile/assets/`:
- [x] **WCAG AA Compliance**: Foreground typography placed over the asset must maintain at least 4.5:1 contrast (or be protected by a 60% opacity dark scrim `#070A11`).
- [x] **Resolution & Compression**: Exact WebP formatting; image must not exceed 180KB.
- [x] **Zero AI Hallucinations**: Anatomical correctness verified (e.g., exactly 5 fingers per hand, accurate armwrestling table proportions, correct federation strap placement).
- [x] **Zero Cartoonish Tropes**: Realistic physical textures (chalk, steel, sweat); no generic cyberpunk glows, neon laser grids, or sci-fi armor.

---

## 6. Single Source of Truth Sign-Off

With Documents 64 through 70 completed, the **Stage 6 Premium Experience Convergence** is fully established, mathematically bounded, and locked into repository memory.
