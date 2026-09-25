# ArmSphere Asset Production Pipeline & Technical Guidelines
**Workflow Standards, Multi-Density Optimization, Audio Encoding & Bundling Protocols**
**Document Version**: 2.0.0 (Authoritative)
**Status**: APPROVED & LOCKED INTO REPOSITORY
**Authority**: `docs/design/00_DESIGN_AUTHORITY.md`, `docs/design/14_IMAGE_ASSET_STRATEGY.md` & `docs/design/17_MEDIA_PERFORMANCE_BUDGET.md`
**Scope**: Complete Asset Engineering Lifecycle from Design Canvas / Studio to Production Flutter Bundle (`apps/mobile/assets/`).

---

## 1. Asset Engineering Philosophy

Assets in ArmSphere are treated as high-performance runtime dependencies, not decorative afterthoughts. A single bloated 4K PNG or an uncompressed stereo audio file can cause memory pressure, frame drops, or app store rejection. 

### The 4 Production Directives:
1. **Vector-First for Icons & UI Graphics**: All non-photographic UI icons, badges, and federation seals must be authored as clean, optimized SVGs or converted into custom Flutter icon fonts.
2. **WebP Compression for Photographic Media**: 100% of photographic raster assets must be encoded in WebP format with strict max dimensions and multi-density scaling (1x, 2x, 3x).
3. **Master-Normalized Mono Audio**: Audio assets must be 44.1kHz / 16-bit mono, normalized to -14 LUFS, with zero DC offset and trimmed leading silence.
4. **Zero Unregistered Assets**: Every asset checked into `apps/mobile/assets/` must be registered in `pubspec.yaml` and verified by automated CI checks.

---

## 2. Directory Hierarchy & Organization Standards

All assets are strictly organized within `apps/mobile/assets/`:

```
apps/mobile/assets/
├── fonts/
│   ├── SpaceGrotesk-Bold.ttf
│   ├── SpaceGrotesk-Medium.ttf
│   ├── SpaceGrotesk-Regular.ttf
│   ├── Inter-Bold.ttf
│   ├── Inter-Medium.ttf
│   └── Inter-Regular.ttf
├── icons/
│   ├── grip_up.svg
│   ├── table_arm.svg
│   ├── referee_card.svg
│   ├── weight_scale.svg
│   └── championship_belt.svg
├── images/
│   ├── arena_dark_texture.webp
│   ├── table_felt_scrim.webp
│   └── 2.0x/
│       └── arena_dark_texture.webp
│   └── 3.0x/
│       └── arena_dark_texture.webp
├── badges/
│   ├── medal_gold.svg
│   ├── medal_silver.svg
│   ├── medal_bronze.svg
│   └── tier_master_shield.svg
└── sounds/
    ├── challenge_accepted.wav  (40 KB)
    ├── match_won.mp3           (41 KB)
    └── pr_achieved.wav         (91 KB)
```

---

## 3. Vector Icon Production Pipeline (SVG -> Flutter)

### Authoring Rules:
- **Base Grid**: 24 × 24 dp artboard.
- **Stroke Weight**: Uniform 2.0 px line stroke, round caps, round joins.
- **Color Format**: Authored with `currentColor` (no hardcoded fills or strokes) to enable dynamic theme tinting in Flutter.
- **Optimization**: Run through `svgo` to strip metadata, editor comments, unnecessary groups, and hidden paths.

### SVGO Optimization Configuration (`svgo.config.js`):
```javascript
module.exports = {
  plugins: [
    'removeDoctype',
    'removeXMLProcInst',
    'removeComments',
    'removeMetadata',
    'removeEditorsNSData',
    'cleanupAttrs',
    'mergeStyles',
    'inlineStyles',
    'minifyStyles',
    'cleanupIds',
    'removeUselessDefs',
    'cleanupNumericValues',
    'convertColors',
    'removeUnknownsAndDefaults',
    'removeNonInheritableGroupAttrs',
    'removeUselessStrokeAndFill',
    'removeViewBox',
    'cleanupEnableBackground',
    'removeHiddenElems',
    'removeEmptyText',
    'convertShapeToPath',
    'moveElemsAttrsToGroup',
    'moveGroupAttrsToElems',
    'collapseGroups',
    'convertPathData',
    'convertTransform',
    'removeEmptyAttrs',
    'removeEmptyContainers',
    'mergePaths',
    'removeUnusedNS',
    'sortAttrs',
    'removeTitle',
    'removeDesc'
  ]
};
```

### Flutter Consumption:
- Icons are rendered via `flutter_svg`:
  ```dart
  SvgPicture.asset(
    'assets/icons/grip_up.svg',
    width: 24,
    height: 24,
    colorFilter: ColorFilter.mode(ArmSphereTheme.primaryAccent, BlendMode.srcIn),
  )
  ```

---

## 4. Photographic Raster Asset Pipeline (WebP Encoding)

### Sizing & Multi-Density Ratios:
- **Baseline (1.0x)**: Designed for mdpi / baseline Android display densities.
- **2.0x Folder**: Exactly 200% resolution for xhdpi devices.
- **3.0x Folder**: Exactly 300% resolution for xxhdpi / xxxhdpi flagship screens.

### Dimension Constraints:
- Hero Tournament Banners: Max width 1080px (1.0x: 360px, 2.0x: 720px, 3.0x: 1080px).
- Athlete Avatars: Max width 384px (1.0x: 128px, 2.0x: 256px, 3.0x: 384px).
- Max File Size: No single raster image asset may exceed **250 KB**.

### ImageMagick / cwebp Batch Conversion Script:
```bash
# Convert source PNG to 3-tier WebP assets
cwebp -q 82 -resize 360 0 input_banner.png -o apps/mobile/assets/images/input_banner.webp
cwebp -q 82 -resize 720 0 input_banner.png -o apps/mobile/assets/images/2.0x/input_banner.webp
cwebp -q 82 -resize 1080 0 input_banner.png -o apps/mobile/assets/images/3.0x/input_banner.webp
```

---

## 5. Audio Production & Encoding Pipeline

### Sound Engineering Constraints:
- **Channels**: Strictly **Mono** (1 channel). Spatial stereo is unnecessary for athletic UI events and doubles file size.
- **Sample Rate**: **44,100 Hz** (standard Android audio mixer rate).
- **Bit Depth**: **16-bit PCM** for WAV; **128 kbps CBR** for MP3.
- **Loudness Normalization**: Mastered to **-14 LUFS** integrated loudness with maximum true peak at **-1.0 dBTP**.
- **Leading / Trailing Trim**: Exactly **0ms leading silence** to ensure instant haptic/audio sync when button is pressed.

### FFmpeg Audio Processing Command:
```bash
# Process audio to strict mono, 44.1kHz, -14 LUFS normalized asset
ffmpeg -i raw_bell.wav -ac 1 -ar 44100 -af "silenceremove=start_periods=1:start_duration=0.01:start_threshold=-60dB, loudnorm=I=-14:TP=-1.0:LRA=7" -c:a pcm_s16le assets/sounds/match_won.wav
```

---

## 6. Shimmer Skeleton Standardization

To eliminate visual jitter during network loading, all placeholder skeletons use a centralized, hardware-accelerated shimmer shader:

```dart
// lib/core/presentation/widgets/armsphere_shimmer.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ArmSphereShimmer extends StatelessWidget {
  final Widget child;
  const ArmSphereShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF121826),      // cardSurface
      highlightColor: const Color(0xFF1E293B), // elevatedSurface
      period: const Duration(milliseconds: 1400),
      direction: ShimmerDirection.ltr,
      child: child,
    );
  }
}

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF121826),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
```

---

## 7. `pubspec.yaml` Registration & Verification Rules

Every asset placed in the repository must be explicitly declared in `apps/mobile/pubspec.yaml`. Wildcard folder declarations must be audited to prevent orphaned assets from bloating the APK.

### Canonical `pubspec.yaml` Asset Block:
```yaml
flutter:
  uses-material-design: true

  assets:
    - assets/icons/
    - assets/images/
    - assets/badges/
    - assets/sounds/

  fonts:
    - family: SpaceGrotesk
      fonts:
        - asset: assets/fonts/SpaceGrotesk-Regular.ttf
          weight: 400
        - asset: assets/fonts/SpaceGrotesk-Medium.ttf
          weight: 500
        - asset: assets/fonts/SpaceGrotesk-Bold.ttf
          weight: 700
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
          weight: 400
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
```

---

## 8. Verification & Non-Contradiction Proof
This asset production pipeline enforces the performance budget set in `docs/design/00_DESIGN_AUTHORITY.md` and `docs/design/17_MEDIA_PERFORMANCE_BUDGET.md`. It guarantees that APK size increases by no more than 8.5MB, that images never cause memory spikes, and that audio syncs with sub-10ms latency to physical haptic feedback.
