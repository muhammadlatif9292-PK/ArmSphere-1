# ArmSphere Video Asset Strategy
**Playback Constraints, Loop Budgets & Bandwidth Protection**
**Document Version**: 1.0.0
**Status**: APPROVED & LOCKED

---

## 1. Master Video Usage Matrix

Video is a high-cost asset in mobile engineering. In ArmSphere, video is strictly segregated into **two permissible categories**:
1. **User Community Video Links** (External embeds from YouTube, TikTok, Facebook)
2. **Optional Ambient Hero Loops** (Short atmospheric background loops in major event headers)

```
┌────────────────────────────────────────────────────────────────────────┐
│                        VIDEO USAGE MATRIX                              │
├────┬────────────────────────────┬──────────────┬───────────────────────┤
│ ID │ Screen / Placement         │ Allowed?     │ Technical Constraints │
├────┼────────────────────────────┼──────────────┼───────────────────────┤
│ V1 │ Community Feed Posts       │ **APPROVED** │ On-demand modal only; │
│    │                            │              │ No inline autoplay    │
│ V2 │ Major Event Hero Header    │ **OPTIONAL** │ 4–6s loop, muted,     │
│    │ (National Championships)   │              │ WiFi only, < 2.5 MB   │
│ V3 │ Welcome / Splash           │ **FORBIDDEN**│ Use Flutter animation │
│ V4 │ Referee Scorepad           │ **FORBIDDEN**│ Strict 0ms latency    │
│ V5 │ Rankings & Leaderboards    │ **FORBIDDEN**│ Prevents table jank   │
│ V6 │ Brackets & Match Nodes     │ **FORBIDDEN**│ Canvas performance    │
│ V7 │ Settings, Forms & Auth     │ **FORBIDDEN**│ Unnecessary payload   │
└────┴────────────────────────────┴──────────────┴───────────────────────┘
```

---

## 2. Community Video Embed Rules

In `CommunityFeedScreen` (`features/community/screens/community_feed_screen.dart`):
1. **Zero Inline Video Spawning**: Feed list cards render a lightweight static thumbnail with a platform play badge (YouTube / TikTok / Facebook).
2. **Modal Playback Only**: Tapping the card opens `VideoPlayerModal` (`video_player_modal.dart`), loading the sanitized embed URL inside an isolated `webview_flutter` surface.
3. **Disposal**: Closing the modal immediately terminates the WebView process and frees all audio/video buffers, preventing memory leaks.

---

## 3. Ambient Hero Video Loop Specification

For sanctioned national championships (e.g. Pakistan National Championship 2026):
- **Maximum Loop Duration**: 4 to 6 seconds (seamless loop point).
- **Resolution**: 720p maximum (1280×720px at 24fps).
- **Encoding**: H.264 Baseline Profile in `.mp4` container.
- **File Size Target**: Strictly **under 2.5 MB**.
- **Audio**: 100% muted track (zero audio stream).
- **Scroll Pause Rule**: Any vertical scroll offset > 50dp immediately pauses the video controller to preserve GPU cycles for list rendering.
- **Battery Saver Guard**: If Android Battery Saver mode is active or connectivity is metered cellular, the video controller is skipped entirely in favor of the high-res static poster image.
