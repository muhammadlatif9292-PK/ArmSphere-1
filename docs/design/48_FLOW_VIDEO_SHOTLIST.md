# ArmSphere Stage 3 — Master Flow Video Shotlist & Production Spec
**Document Version**: 1.0.0 (Authoritative Video & Motion Asset Specification)
**Date**: September 26, 2026
**Status**: APPROVED & AUDITED
**Authority**: `docs/design/00_DESIGN_AUTHORITY.md`, `15_VIDEO_ASSET_STRATEGY.md`, & `17_MEDIA_PERFORMANCE_BUDGET.md`
**Scope**: Production Shotlists, Frame Continuity Protocols, Encoding Specifications, Reduced-Motion Fallbacks, and Player Mechanics for Approved Video Placements.

---

## 1. Authoritative Video Policy & Zero-Tolerance Rejections

In strict adherence to `docs/design/15_VIDEO_ASSET_STRATEGY.md`, video is a high-cost, high-cognitive-load medium. It is **exclusively authorized** for four specific functional touchpoints.

### 1.1 Strictly Prohibited Video Contexts (Automatic CI/Design Rejection)
1. **App Splash / Boot Screen**: NEVER video. Must boot in <400ms to interactive UI.
2. **Referee Live Match Scorepad (Screen 26)**: NEVER video. 0ms input latency is non-negotiable; video decoders consume rendering thread time and introduce touch jitter.
3. **Interactive Bracket Viewers (Screen 18 & Modal 1)**: NEVER video. Pan/zoom 60fps vector canvas requires 100% GPU budget.
4. **Form Entry & Auth Backgrounds (Screens 01-05, 09, 20)**: NEVER looping video. Distracts from focus and drains battery during input.
5. **Global App Scaffolding / Drawer**: NEVER video.

---

## 2. Approved Placement 1: Championship Finals Hero Loop (`M5-VID-HEROLOOP`)

### 2.1 Technical Profile & Constraints
- **Target Screen**: Screen 17 (`TournamentDetailScreen`) — World / National Tier Championships only.
- **Duration**: Exactly 5.0 seconds (120 frames at 24fps).
- **Encoding**: MP4 (H.264 High Profile Level 4.0 / AV1 secondary stream).
- **Resolution**: 1920 x 1080 px (16:9 widescreen).
- **Bitrate & Budget**: Target bitrate 3.5 Mbps; Max file size: **2.2 MB**.
- **Audio Track**: None (Muted stream stripped of AAC track to save 128kbps).
- **Loop Seamlessness**: Frame 001 and Frame 120 must match with <2% RGB delta to eliminate visual jump cuts.

### 2.2 Shotlist & Action Choreography
| Timestamp | Camera Framing & Movement | Visual Action & Lighting Choreography | Lighting & Color Focus |
| :--- | :--- | :--- | :--- |
| **0.00s - 1.20s** | Extreme close-up (ECU) macro on competition hand peg and chalked wrist. Slow, imperceptible push-in (0.5% scale/sec). | Two competitors lock fingers at table center. Fingers tighten with extreme pressure. Micro-particles of white chalk gently puff from the palm. | Directional rim light in Champagne Gold (#D4AF37) catching sweat beads on knuckle ridges. |
| **1.21s - 3.40s** | ECU shifts focus from hand peg to flexing brachioradialis and bicep tendon tension. | Isometric explosion: both arms vibrate subtly with maximum tension (0.5mm physical tremor). Referee’s hands slide smoothly out of frame. | Cold Luminous Cyan (#38BDF8) edge light hits the opposite arm, creating high-contrast dual-tone combat separation. |
| **3.41s - 4.99s** | Camera pulls back 2% while slow-drifting upward. | A rising swirl of white chalk dust rises through the central spotlight beam, gently obscuring the grip into a soft bokeh silhouette. | Ambient overhead spotlight dims smoothly into the exact lighting level and color profile of Frame 001. |
| **5.00s (Loop)** | Instant seamless loop back to Frame 001. Zero perceptible stutter. | Chalk haze level precisely resets to the initial ambient state. | Total luminance matches Frame 001 within 2 nits. |

### 2.3 Reduced-Motion & Battery Saver Fallback
- If `MediaQuery.of(context).disableAnimations` is `true`, OR battery level < 20%:
  - The video decoder is completely deactivated (disposed from RAM).
  - UI displays high-res static poster `M1-HERO-ARENA.webp` with zero performance penalty.

---

## 3. Approved Placement 2: Community Technique Video Player Modal (`M5-VID-COMMFEED`)

### 3.1 Technical Profile & Behavior
- **Target Screens**: Screen 30 (`CommunityFeedScreen`) & Screen 32 (`PostDetailScreen`).
- **Trigger**: Explicit user tap on post video thumbnail with play indicator. Never auto-plays with audio.
- **Player Container**: Dedicated responsive modal with custom "Raw Iron & Precision Steel" transport controls.
- **Max Video Size**: 25 MB max cache per clip; progressive MP4 / HLS chunking.

### 3.2 UI & Interaction Choreography
1. **Initial State (Feed)**: Displays frozen first-frame poster with duration badge (`0:45`), sound-off icon, and centered metallic play button.
2. **Tap Transition**: 220ms spring container expansion into modal player. Background scrim darkens to `#070A11` at 85% opacity.
3. **Transport HUD**:
   - Top Bar: Athlete name, verified badge, weight class, close button (48dp).
   - Bottom Dock: Play/Pause toggle, high-precision scrub bar with buffered cache indicator, current time / total time (`SpaceGrotesk` tabular numbers), audio mute toggle, fullscreen expand.
   - Auto-Hide: Controls auto-fade after 2.5 seconds of user inactivity. Single tap toggles HUD visibility.

---

## 4. Approved Placement 3: Live Tournament Broadcast Stream (`M5-VID-STREAM`)

### 4.1 Technical Profile & Behavior
- **Target Screen**: Screen 24 (`TournamentLiveStreamScreen`).
- **Stream Protocol**: Low-latency HLS (LL-HLS) with adaptive bitrate ladder (1080p60 -> 720p60 -> 480p30).
- **Latency Buffer**: 2.0 to 4.5 seconds target delay.
- **Audio Ducking**: Defaults to muted when opened from background notification; user unmute persists per session.

### 4.2 Stream Overlay Telemetry (HUD)
- **Top-Left**: "LIVE" pill badge in Adrenaline Crimson (`#EF4444`) with animated red pulse ring.
- **Top-Right**: Current table identifier (e.g., `TABLE 1 - CHIEF ARBITER: J. SMITH`) and viewer count badge.
- **Bottom Overlay Bar**:
  - Competitor A (Red Corner, Left) vs. Competitor B (Blue Corner, Right).
  - Live round score (e.g., `2 - 1`).
  - Active foul ticker: Displays referee call alerts (e.g., `WARNING 1: EARLY MOVEMENT`, `FOUL: ELBOW OFF PAD`) synchronized via WebSocket events.

---

## 5. Approved Placement 4: Match Video Dispute Review (`M5-VID-DISPUTE`)

### 5.1 Technical Profile & Referee Controls
- **Target Screen**: Screen 27 (`MatchDisputeScreen`).
- **Context**: Official referee video review table during an appealed call or contested pin.
- **Framerate Requirement**: 60fps high-speed capture (mandatory for detecting 16ms micro-elbow fouls).
- **Playback Controls**:
  - Single-frame step forward / backward (16.6ms per step).
  - Variable slow-motion playback: 0.1x, 0.25x, 0.5x, 1.0x.
  - Multi-touch pinch-to-zoom (up to 400% zoom into elbow pad contact zone).
  - Split-screen comparison: Allows side-by-side synchronized comparison of Camera Angle A (Overhead) and Camera Angle B (Side Pad).

---

## 6. Implementation Guardrails & Video Codec Matrix

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ ARMSPHERE VIDEO CODEC COMPATIBILITY SPECIFICATION                           │
├──────────────────────┬──────────────────────┬───────────────────────────────┤
│ Operating Platform   │ Primary Stream Codec │ Fallback Stream Codec         │
├──────────────────────┼──────────────────────┼───────────────────────────────┤
│ Android 10+ (API 29+)│ H.264 (AVC) Baseline │ VP9 / AV1 (Hardware decode)   │
│ iOS 14+              │ H.264 / HEVC (H.265) │ Apple HLS fMP4                │
│ Flutter Web          │ WebM (VP9) / MP4     │ HLS.js HTML5 Video Element    │
└──────────────────────┴──────────────────────┴───────────────────────────────┘
```

- **Decoder Disposal**: When the user navigates away from any screen hosting a video player, `VideoPlayerController.dispose()` must be invoked synchronously within `dispose()` to prevent memory leaks and background audio leakage.
- **Quality Sign-Off**: The video strategy strictly protects mobile battery life, cellular data limits, and referee operational speed.
