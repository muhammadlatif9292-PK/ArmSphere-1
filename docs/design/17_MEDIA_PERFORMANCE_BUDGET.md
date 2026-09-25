# ArmSphere Media & Performance Budget
**Hardware Limits, Memory Thresholds & APK Size Constraints**
**Document Version**: 1.0.0
**Status**: APPROVED & LOCKED

---

## 1. Executive Performance Targets

To ensure seamless operation on both flagship handsets and entry-level Android devices across Pakistan:

| Metric | Target Baseline | Strict Ceiling | Verification Tooling |
| :--- | :--- | :--- | :--- |
| **Cold Startup Time** | **< 1,200 ms** | 1,800 ms | Android Vitals / Flutter DevTools |
| **Warm Startup Time** | **< 400 ms** | 600 ms | Android Vitals |
| **Steady State Memory (RAM)**| **95 MB** | 145 MB | Flutter Memory Profiler |
| **Peak Memory (Bracket Pan/Zoom)**| **150 MB** | 210 MB | Flutter Memory Profiler |
| **Frame Rate (Mid-Tier Device)**| **60 fps (16.6ms)** | Min 56 fps | Flutter Performance Overlay |
| **Frame Rate (High-Refresh OLED)**| **120 fps (8.3ms)**| Min 112 fps | Flutter Performance Overlay |
| **Release APK File Size** | **< 45 MB** | 50 MB | Gradle `assembleRelease` (RC-2: 44.9 MB) |
| **App Bundle (.aab) Size** | **< 75 MB** | 80 MB | Gradle `bundleRelease` (RC-2: 74.7 MB) |

---

## 2. Asset Memory & Network Budget

```dart
// Image Cache Configuration (core/providers/dependency_providers.dart)
void configureImageCache() {
  // Cap in-memory image cache to 50 MB to prevent Android low-memory kills
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024;
  PaintingBinding.instance.imageCache.maximumSize = 100; // Max 100 decoded images
}
```

### Bandwidth Consumption Limits:
- **Feed Scroll Budget**: Maximum **1.2 MB data transfer per 10 feed cards** scrolled.
- **Image Compression**: All remote tournament banners served in compressed WebP format (max dimension 1280px, quality 82%).
- **Audio Assets**: Preloaded into memory on startup (total footprint: 173 KB for all 3 sound files).

---

## 3. Low-End Hardware Degradation Strategy

When running on devices with <= 3GB of system RAM or power-saving mode enabled:
1. **BackdropFilter Bypass**: Replaces expensive Gaussian blur with solid 90% opaque dark slate `#141C2E`.
2. **Particle Background Freeze**: `AmbientParticleBackground` stops its ticker animation and renders a single static background gradient.
3. **Animated Gradient Hero**: Pauses rotation angle loops and holds stationary.
4. **Bracket Canvas LOD (Level of Detail)**: Hides small connector lines when zooming out beyond 50% scale.
