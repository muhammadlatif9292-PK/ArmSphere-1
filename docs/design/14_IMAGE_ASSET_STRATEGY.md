# ArmSphere Image Asset Strategy
**Photography Guidelines, Gradient Scrims & Visual Hierarchy**
**Document Version**: 1.0.0
**Status**: APPROVED & LOCKED

---

## 1. Visual Content Hierarchy

ArmSphere enforces an inviolable asset hierarchy:

```
    ┌─────────────────────────────────────────────────────────────┐
    │ 1. REAL FEDERATION DATA & ATHLETE UPLOADS (Highest Priority)│
    │    Actual competitor photos, real weigh-in photos, scores   │
    ├─────────────────────────────────────────────────────────────┤
    │ 2. REAL INSTITUTIONAL ASSETS                                │
    │    PAFF federation seal, official championship belt photos  │
    ├─────────────────────────────────────────────────────────────┤
    │ 3. VERIFIED VENUE & GYM PHOTOGRAPHY                         │
    │    Real photos of Mazurenko / official armwrestling tables  │
    ├─────────────────────────────────────────────────────────────┤
    │ 4. ATMOSPHERIC ARENA TEXTURES & LIGHTING GRADIENTS          │
    │    Dark metallic arena surfaces, spotlight cones, smoke     │
    ├─────────────────────────────────────────────────────────────┤
    │ 5. GENERATIVE ASSETS (Environment / Backgrounds Only)       │
    │    Strictly prohibited from fabricating fake athletes/faces │
    └─────────────────────────────────────────────────────────────┘
```

---

## 2. Text-Safe Composition & Gradient Scrim Rules

Placing text directly over raw sports photography is strictly prohibited. Every image placed behind text must use a **dual-stop gradient scrim**:

```dart
// Standard Tournament Hero Image Scrim
BoxDecoration heroScrim() => BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: const [0.0, 0.45, 0.85, 1.0],
    colors: [
      Colors.black.withOpacity(0.20), // Preserves top of stadium image
      Colors.black.withOpacity(0.60), // Mid-transition
      AppTheme.background.withOpacity(0.92), // High text legibility
      AppTheme.background, // Seamless blend into background
    ],
  ),
);
```

### Contrast Gate:
- White text placed over image must maintain **at least 7:1 contrast ratio** under all lighting conditions.

---

## 3. Aspect Ratio Standards & Caching Limits

To avoid layout shifts and memory blowouts on Android devices:

| Image Category | Aspect Ratio | Max Dimension | Disk Cache Budget | Fallback Strategy |
| :--- | :--- | :--- | :--- | :--- |
| **Athlete Profile Avatar** | 1:1 (Circle) | 256×256px | 50 KB | Initials circle in `AppTheme.surfaceElevated` |
| **Tournament Hero Banner** | 16:9 / 21:9 | 1280×720px | 250 KB | Atmospheric dark stadium gradient |
| **Venue Partner Photo** | 4:3 Landscape | 800×600px | 150 KB | Gym table icon with address chip |
| **Community Video Thumb** | 16:9 Landscape | 640×360px | 100 KB | Platform brand badge (YouTube/TikTok) |
| **Championship Belt Crest** | 1:1 Vector/PNG | 512×512px | 80 KB | Gold laurel wreath vector |

---

## 4. Network Image Loading & Error Resilience

All remote images are retrieved through `cached_network_image` with strict lifecycle safeguards:
- **Disk Cache Expiration**: 7 days for tournament banners; 24 hours for competitor avatars.
- **Fade Duration**: 200ms smooth cross-fade upon network receipt.
- **Graceful Error Recovery**: If an image URL returns 404 or fails SSL verification, the widget silently renders the fallback avatar without throwing uncaught exceptions.
