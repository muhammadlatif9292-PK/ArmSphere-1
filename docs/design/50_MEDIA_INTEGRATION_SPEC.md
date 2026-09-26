# ArmSphere Stage 3 — Media Integration & Pipeline Specification
**Document Version**: 1.0.0 (Authoritative Technical Media Integration Guide)
**Date**: September 26, 2026
**Status**: APPROVED & AUDITED
**Authority**: `docs/design/00_DESIGN_AUTHORITY.md`, `14_IMAGE_ASSET_STRATEGY.md`, `17_MEDIA_PERFORMANCE_BUDGET.md`, & `46_MASTER_MEDIA_ASSET_MAP.md`
**Scope**: Directory Architecture, Asset Manifest, Multi-Density Variants, Flutter Caching Pipeline, Memory Bounds, and Fallback Ladder Implementation.

---

## 1. Physical Directory Architecture in `apps/mobile/`

To enforce strict separation of concerns, eliminate asset clutter, and prevent missing asset build errors, all mobile assets must be organized into the following authoritative directory tree:

```
apps/mobile/assets/
├── fonts/
│   ├── Inter-Bold.ttf
│   ├── Inter-Medium.ttf
│   ├── Inter-Regular.ttf
│   ├── SpaceGrotesk-Bold.ttf
│   ├── SpaceGrotesk-Medium.ttf
│   └── SpaceGrotesk-Regular.ttf
├── sounds/
│   ├── challenge_accepted.wav       [40 KB - M6 Combat Challenge Sync]
│   ├── match_won.mp3                [41 KB - M6 Match Win / Celebration]
│   ├── pr_achieved.wav              [91 KB - M6 Personal Record Stamp]
│   └── pro_tick.wav                 [8 KB  - M6 Scorepad / Tactile Click]
└── images/
    ├── brand/
    │   ├── m0_logo_full.webp        [Champagne Gold Full Brand Monogram]
    │   ├── m0_icon_gold.webp        [Embossed Anvil & Grip App Icon]
    │   └── m0_seal_fed.webp         [Official Federation Watermark Seal]
    ├── textures/
    │   ├── m1_tex_knurl.webp        [Seamless Diamond Knurled Steel Pattern]
    │   └── m1_tex_chalk.webp        [Atmospheric Arena Chalk Dust Vignette]
    ├── heroes/
    │   ├── m1_hero_arena.webp       [Championship Stage Spotlight & Table]
    │   ├── m1_hero_grip.webp        [The Clash - Macro Forearm Tension]
    │   ├── 2.0x/                    [@2x resolution variants]
    │   └── 3.0x/                    [@3x resolution variants]
    ├── badges/
    │   ├── m4_bdg_heavy.webp        [Super Heavyweight Titanium Anvil]
    │   ├── m4_bdg_middle.webp       [Middleweight Damascus Steel Crest]
    │   ├── m4_bdg_light.webp        [Lightweight Tempered Raptor Claw]
    │   ├── m4_bdg_junior.webp       [Junior Bronze Wing Emblem]
    │   ├── m4_bdg_masters.webp      [Masters Gold Laurel Emblem]
    │   ├── m4_ref_master.webp       [Master International Referee Insignia]
    │   └── m4_ref_nat.webp          [Senior National Referee Insignia]
    ├── empty_states/
    │   ├── m1_emp_notourn.webp      [Empty Arena Championship Table]
    │   ├── m1_emp_notrain.webp      [Loading Pin & Straps on Rubber Floor]
    │   ├── m1_emp_nochall.webp      [Chalked Table Center Line & Straps]
    │   └── m1_emp_offline.webp      [Severed Steel Cable Sparks Frozen]
    └── defaults/
        ├── avatar_neutral_dark.webp [Fallback Athlete Silhouette]
        ├── tournament_poster.webp   [Fallback Tournament Card Poster]
        └── club_banner.webp         [Fallback Club Training Banner]
```

---

## 2. Pubspec Asset Declaration Specification

Assets must be declared in `apps/mobile/pubspec.yaml` using clean directory declarations:

```yaml
flutter:
  uses-material-design: true

  assets:
    - assets/fonts/
    - assets/sounds/
    - assets/images/brand/
    - assets/images/textures/
    - assets/images/heroes/
    - assets/images/badges/
    - assets/images/empty_states/
    - assets/images/defaults/

  fonts:
    - family: SpaceGrotesk
      fonts:
        - asset: assets/fonts/SpaceGrotesk-Regular.ttf
        - asset: assets/fonts/SpaceGrotesk-Medium.ttf
          weight: 500
        - asset: assets/fonts/SpaceGrotesk-Bold.ttf
          weight: 700
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
```

---

## 3. Authoritative Code Constants (`asset_paths.dart`)

To prevent runtime 404s and string typos, all code references MUST resolve through `apps/mobile/lib/core/constants/asset_paths.dart`:

```dart
/// Authoritative ArmSphere Media & Asset Path Registry
abstract final class ArmSphereAssets {
  // Brand Core (M0)
  static const String logoFull = 'assets/images/brand/m0_logo_full.webp';
  static const String iconGold = 'assets/images/brand/m0_icon_gold.webp';
  static const String sealFederation = 'assets/images/brand/m0_seal_fed.webp';

  // Textures (M1)
  static const String texKnurl = 'assets/images/textures/m1_tex_knurl.webp';
  static const String texChalk = 'assets/images/textures/m1_tex_chalk.webp';

  // Heroes (M1)
  static const String heroArena = 'assets/images/heroes/m1_hero_arena.webp';
  static const String heroGrip = 'assets/images/heroes/m1_hero_grip.webp';

  // Badges (M4)
  static const String badgeHeavyweight = 'assets/images/badges/m4_bdg_heavy.webp';
  static const String badgeMiddleweight = 'assets/images/badges/m4_bdg_middle.webp';
  static const String badgeLightweight = 'assets/images/badges/m4_bdg_light.webp';
  static const String badgeJunior = 'assets/images/badges/m4_bdg_junior.webp';
  static const String badgeMasters = 'assets/images/badges/m4_bdg_masters.webp';
  static const String refMaster = 'assets/images/badges/m4_ref_master.webp';
  static const String refNational = 'assets/images/badges/m4_ref_nat.webp';

  // Empty States (M1)
  static const String emptyTournaments = 'assets/images/empty_states/m1_emp_notourn.webp';
  static const String emptyTraining = 'assets/images/empty_states/m1_emp_notrain.webp';
  static const String emptyChallenges = 'assets/images/empty_states/m1_emp_nochall.webp';
  static const String emptyOffline = 'assets/images/empty_states/m1_emp_offline.webp';

  // Fallbacks
  static const String defaultAvatar = 'assets/images/defaults/avatar_neutral_dark.webp';
  static const String defaultTournament = 'assets/images/defaults/tournament_poster.webp';
  static const String defaultClub = 'assets/images/defaults/club_banner.webp';

  // Sounds (M6)
  static const String soundChallengeAccepted = 'assets/sounds/challenge_accepted.wav';
  static const String soundMatchWon = 'assets/sounds/match_won.mp3';
  static const String soundPRAchieved = 'assets/sounds/pr_achieved.wav';
  static const String soundTick = 'assets/sounds/pro_tick.wav';
}
```

---

## 4. Flutter Image Caching Pipeline (`ArmSphereImage`)

To guarantee strict enforcement of:
1. `cacheWidth` and `cacheHeight` constraints.
2. The 3-Level Fallback Ladder.
3. Shimmer loading placeholders with zero layout shift.
4. Memory pressure protection.

All images across all 66 screens will be rendered via a centralized widget:

```dart
class ArmSphereImage extends StatelessWidget {
  final String? imageUrl;
  final String? assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String fallbackAsset;
  final IconData fallbackIcon;
  final int? cacheWidth;
  final int? cacheHeight;

  const ArmSphereImage({
    super.key,
    this.imageUrl,
    this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallbackAsset = ArmSphereAssets.defaultTournament,
    this.fallbackIcon = Icons.fitness_center_rounded,
    this.cacheWidth,
    this.cacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    // Level 1: Network Image with disk caching
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: cacheWidth ?? (width != null ? (width! * 3).toInt() : null),
        memCacheHeight: cacheHeight ?? (height != null ? (height! * 3).toInt() : null),
        placeholder: (context, url) => _buildShimmerPlaceholder(),
        errorWidget: (context, url, error) => _buildLevel2Fallback(),
      );
    }

    // Level 1b: Bundled Local Asset
    if (assetPath != null && assetPath!.isNotEmpty) {
      return Image.asset(
        assetPath!,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        errorBuilder: (context, error, stackTrace) => _buildLevel2Fallback(),
      );
    }

    return _buildLevel2Fallback();
  }

  // Level 2 Fallback: Bundled Generic Image
  Widget _buildLevel2Fallback() {
    return Image.asset(
      fallbackAsset,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _buildLevel3Fallback(),
    );
  }

  // Level 3 Fallback: Procedural GPU Gradient + Vector Icon
  Widget _buildLevel3Fallback() {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF070A11), Color(0xFF121826)],
        ),
      ),
      child: Center(
        child: Icon(
          fallbackIcon,
          color: const Color(0xFF38BDF8).withOpacity(0.4),
          size: (width != null && height != null) ? math.min(width!, height!) * 0.4 : 32,
        ),
      ),
    );
  }

  Widget _buildShimmerPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFF121826),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
          ),
        ),
      ),
    );
  }
}
```

---

## 5. Global Memory Cache Configuration

To eliminate Out-Of-Memory (OOM) crashes on low-end budget smartphones (e.g. Android devices with 2GB-3GB RAM), the Flutter `PaintingBinding` cache limits will be initialized in `main.dart`:

```dart
void configureArmSphereImageCache() {
  // Cap image cache to 100 MB max uncompressed bitmap RAM
  PaintingBinding.instance.imageCache.maximumSizeBytes = 100 * 1024 * 1024;
  // Cap image cache to 100 individual concurrent images
  PaintingBinding.instance.imageCache.maximumSize = 100;
}
```

---

## 6. Pipeline Readiness Gate

- **Asset Paths Centralized**: 100% of asset constants locked.
- **Memory Safety Enforced**: Multi-density decoders capped with `cacheWidth` / `cacheHeight`.
- **Zero White Flashes**: Seamless transitions guaranteed via `ArmSphereImage`.
- **Approved Sign-Off**: Ready for Stage 3 Production Timeline (`51_PREMIUM_PRODUCTION_TIMELINE.md`).
