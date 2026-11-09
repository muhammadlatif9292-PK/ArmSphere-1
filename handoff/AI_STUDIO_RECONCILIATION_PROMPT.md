# ArmSphere — Gemini 4 Argon AI Studio Reconciliation & Sync Prompt (Version 8)

*Instructions: Copy and paste this prompt directly into Google AI Studio (Gemini 4 Argon) to synchronize the project state with the verified GitHub repository.*

---

```markdown
# ArmSphere Workspace Sync & CI Verification Handoff — Version 8

Hello Argon,

Your latest candidate export (`armsphere-1.zip`) has been integrated, differential-analyzed, and 100% verified against our GitHub Actions production CI pipelines on branch `feat/aistudio-flutter-sync-v8-20261109` (commit `0ba4bf4`, PR #9).

All Flutter Android tests (**383 / 383 passed, 100%**), static analysis (0 fatal errors), release APK / AAB compilation, and keystore signing verification are completely **GREEN**.

**IMPORTANT:** You do NOT need to regenerate or overwrite the full codebase. You only need to know how the new assets and `VoidStageScaffold` have been integrated alongside our complete, production-hardened screen architectures.

Alternatively, you can extract the lightweight **`armsphere-repairs-only.zip` (3.8 MB, 53 files only)** or full sync archive **`armsphere-aistudio-sync.zip` (118 MB)** located in `handoff/`.

---

### Key Architectural Unifications in Version 8

#### 1. `apps/mobile/lib/core/widgets/void_stage_scaffold.dart` (Dual Parameter Support)
`VoidStageScaffold` now accepts both `child` and `body` parameters seamlessly:
```dart
class VoidStageScaffold extends StatelessWidget {
  final String backgroundAsset;
  final Alignment focalAlignment;
  final Widget? child;
  final Widget? body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? drawer;
  final Widget? endDrawer;
  final bool? resizeToAvoidBottomInset;
  final bool useSafeArea;

  const VoidStageScaffold({
    super.key,
    required this.backgroundAsset,
    this.child,
    this.body,
    this.focalAlignment = ArmSphereAssets.stageTopFocal,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.drawer,
    this.endDrawer,
    this.resizeToAvoidBottomInset,
    this.useSafeArea = true,
  }) : assert(child != null || body != null, 'Either child or body must be provided to VoidStageScaffold');

  @override
  Widget build(BuildContext context) {
    final Widget content = child ?? body ?? const SizedBox();
    return Scaffold(
      backgroundColor: const Color(0xFF070A11),
      extendBodyBehindAppBar: true,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      drawer: drawer,
      endDrawer: endDrawer,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ExcludeSemantics(
            child: Image.asset(
              backgroundAsset,
              fit: BoxFit.cover,
              alignment: focalAlignment,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stackTrace) => const ColoredBox(
                color: Color(0xFF070A11),
              ),
            ),
          ),
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.35, 0.70, 1.0],
                  colors: [
                    Color(0x33070A11),
                    Color(0x1A070A11),
                    Color(0xCC070A11),
                    Color(0xFF070A11),
                  ],
                ),
              ),
            ),
          ),
          useSafeArea ? SafeArea(child: content) : content,
        ],
      ),
    );
  }
}
```

#### 2. `apps/mobile/lib/core/constants/asset_paths.dart` (Full 28-Asset Void Suite & Resolver)
`ArmSphereAssets` contains all 28 Tier 0–3 WebP assets and the backwards-compatible resolver:
```dart
static String resolveSemanticAsset(
  String? slotId, {
  String fallback = '',
}) {
  if (slotId == null || slotId.trim().isEmpty) return fallback;
  final trimmed = slotId.trim();
  switch (trimmed) {
    case 'profile.athlete.dashboard_hero': return athleteDashboardHero;
    case 'arena.home.radar_card': return arenaRadarCard;
    case 'arena.home.supermatch_card': return supermatchVsCard;
    case 'discover.hub.venues_tile': return bentoVenues;
    case 'discover.hub.pickup_meetups_tile':
    case 'discover.hub.pickup_tile': return bentoPickupSparring;
    case 'discover.hub.community_feed_tile':
    case 'discover.hub.community_tile': return bentoCommunityFeed;
    case 'discover.hub.elo_rankings_tile':
    case 'discover.hub.rankings_tile': return bentoEloRankings;
    case 'events.tournament.detail_hero': return fallback.isNotEmpty ? fallback : defaultTournament;
    case 'auth.welcome.hero_banner': return welcomeGripHero;
    case 'arena.home.background': return stageArena;
    case 'training.log.background': return stageTrainingLab;
    default:
      if (trimmed.endsWith('.png')) {
        return trimmed.replaceFirst('.png', '.webp');
      }
      return fallback.isNotEmpty ? fallback : trimmed;
  }
}
```

#### 3. `apps/mobile/lib/core/widgets/armsphere_image.dart` (Club Constructor Added)
```dart
const ArmSphereImage.club({
  super.key,
  this.imageUrl,
  this.assetPath,
  double size = 48.0,
  this.fit = BoxFit.cover,
  this.alignment = Alignment.center,
  this.fallbackAsset = ArmSphereAssets.teamCrestDefault,
  this.fallbackIcon = Icons.shield_rounded,
  this.initial,
  this.cacheWidth,
  this.cacheHeight,
  this.borderRadius,
  this.shape = BoxShape.circle,
  this.border,
  this.semanticLabel,
  this.excludeFromSemantics = false,
  this.showLoadingIndicator = true,
}) : width = size, height = size;
```

#### 4. `apps/mobile/pubspec.yaml`
```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/images/brand/
    - assets/images/heroes/
    - assets/images/bento/
    - assets/images/defaults/
    - assets/images/badges/
    - assets/images/textures/
    - assets/sounds/
```

---

### Verification Summary
- **GitHub Workflow Run:** https://github.com/muhammadlatif9292-PK/ArmSphere-1/actions/runs/42558845786
- **Test Suite Pass Rate:** **383 / 383 tests (100% Green)**
- **Release APK:** `build/app/outputs/flutter-apk/app-release.apk` (Signed, Verified)
- **Release AppBundle:** `build/app/outputs/bundle/release/app-release.aab` (Signed, Verified)
- **GitHub PR:** [#9](https://github.com/muhammadlatif9292-PK/ArmSphere-1/pull/9)

You can now continue expanding features in Google AI Studio with confidence!
```
