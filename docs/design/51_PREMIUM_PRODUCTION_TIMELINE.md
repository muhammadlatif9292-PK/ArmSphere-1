# ArmSphere Stage 3 — Master Production Timeline & Execution Gates
**Document Version**: 1.0.0 (Authoritative Phased Implementation Roadmap)
**Date**: September 26, 2026
**Status**: APPROVED & AUDITED
**Authority**: `docs/design/00_DESIGN_AUTHORITY.md`, `27_UI_UX_IMPLEMENTATION_BACKLOG.md`, & Stage 3 Master Directive
**Scope**: 12 Phased Execution Stages (Phase A to Phase L), Explicit Inputs/Outputs, Gate Criteria, and Rollback Protocols.

---

## 1. Executive Master Timeline Structure

The transition of ArmSphere from functional completeness to release-grade premium elevation is structured into **twelve strict, sequential phases (A through L)**. No phase may commence until its predecessor passes all automated and manual gate criteria.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ MASTER PRODUCTION TIMELINE PHASING OVERVIEW                                │
├──────────┬──────────────────────────────────────────┬───────────────────────┤
│ Phase    │ Focus & Core Deliverables                │ Critical Gate         │
├──────────┼──────────────────────────────────────────┼───────────────────────┤
│ Phase A  │ Flow Image & Asset Generation (WebP 85%) │ Hand/Contrast Pass    │
│ Phase B  │ Asset Tree Ingestion & Pubspec Binding   │ flutter pub get Pass  │
│ Phase C  │ Media Infrastructure (ArmSphereImage)    │ Fallback Ladder Pass  │
│ Phase D  │ Tier 1 Flagship Screens Elevation (18 Sc)│ 60fps & 0ms Scorepad  │
│ Phase E  │ Tier 2 Competition & Workflows (20 Sc)   │ Zero Route Breakage   │
│ Phase F  │ Tier 3 Federation & Community (18 Sc)    │ Clean Data Binding    │
│ Phase G  │ Tier 4 System & Utility Screens (10 Sc)  │ Full Settings Sync    │
│ Phase H  │ Sensory Binding (Haptics + Audio Pack)   │ Silent Mode Honor     │
│ Phase I  │ Accessibility & Reduced-Motion Audit     │ WCAG AAA + 0 Motion   │
│ Phase J  │ Performance, Memory & FPS Profiling      │ <100MB RAM / 60fps    │
│ Phase K  │ Release Build Compilation & Emulation    │ APK Compiles Clean    │
│ Phase L  │ Production Git Tagging & Release Handoff │ Hash Verified Artifact│
└──────────┴──────────────────────────────────────────┴───────────────────────┘
```

---

## 2. Detailed Phase Specifications (Phases A through L)

### Phase A: Asset Generation & Photographic Master Validation
- **Objective**: Execute generation of M0, M1, and M4 assets using prompt packs defined in `47_FLOW_IMAGE_PROMPT_PACK.md`.
- **Inputs**: Google Flow / Imagen 3 API, Prompt Pack `47_`, WebP converter tool.
- **Outputs**: Verified, metadata-stripped `.webp` images at @1x, @2x, and @3x resolutions.
- **Gate Criteria**:
  - Hand verification: Zero deformed fingers or melted knuckle anatomy on macro grips.
  - Scrim verification: Bottom 45% text-safe area exceeds 18:1 contrast ratio against `#F8FAFC`.
  - Disk budget: Combined bundled assets must not exceed 2.0 MB total.
- **Rollback Protocol**: Re-generate failing prompt with tighter negative constraints; use procedural Level 3 fallback until resolved.

### Phase B: Physical Asset Tree Setup & Pubspec Registration
- **Objective**: Place generated assets into `apps/mobile/assets/images/` subdirectories and register them in `pubspec.yaml`.
- **Inputs**: Generated assets from Phase A, `apps/mobile/pubspec.yaml`.
- **Outputs**: Committed asset tree, updated `pubspec.yaml`, clean `flutter pub get` exit code 0.
- **Gate Criteria**: `flutter pub get` completes with 0 errors or warnings; all asset paths resolve.
- **Rollback Protocol**: Revert `pubspec.yaml` to previous working commit; re-verify folder names.

### Phase C: Core Media Infrastructure Implementation
- **Objective**: Implement `ArmSphereAssets` constants, `ArmSphereImage` widget, and `main.dart` cache limits.
- **Inputs**: `docs/design/50_MEDIA_INTEGRATION_SPEC.md`.
- **Outputs**:
  - `apps/mobile/lib/core/constants/asset_paths.dart`
  - `apps/mobile/lib/core/widgets/arm_sphere_image.dart`
  - Memory bounds initialized in `apps/mobile/lib/main.dart`.
- **Gate Criteria**: Unit test verifying 3-level fallback ladder (Network -> Bundled -> Procedural) passes 100%.
- **Rollback Protocol**: Revert to default `CachedNetworkImage` until widget unit tests pass.

### Phase D: Tier 1 Flagship Screens Elevation (18 High-Impact Screens)
- **Objective**: Integrate "Raw Iron & Precision Steel" surfaces, Flow hero banners, and T1/T3 motion across 18 flagship screens (Screens 01, 06, 07, 08, 09, 16, 17, 18, 19, 24, 26, 30, 33, 37, 40, 42, 52, Modal 3).
- **Inputs**: Screens from Domain 1, 2, 3, 4, 5, 6, 7, 9.
- **Outputs**: Elevated UI code preserving 100% of Riverpod state bindings and routing parameters.
- **Gate Criteria**:
  - Scorepad (Screen 26) retains exact 0ms input latency (zero async blocking).
  - Navigation between all 18 screens maintains 60fps with zero jank frames.
- **Rollback Protocol**: Isolate failing screen to previous git commit while leaving others intact.

### Phase E: Tier 2 Competition & Athlete Workflows (20 Screens)
- **Objective**: Elevate Training Log, PRs, Bracket Management, Referee Console, and Operator tools.
- **Inputs**: Screens 10–15, 20–23, 25, 27–28, 34, 38–39, 53–56.
- **Outputs**: Polished tabular typography, numeric steppers, division emblems, and weigh-in displays.
- **Gate Criteria**: All form submissions (Weigh-in, PR creation, Table assignment) complete without mutation regression.
- **Rollback Protocol**: Git revert affected feature directory.

### Phase F: Tier 3 Federation, Community & Integrity (18 Screens)
- **Objective**: Elevate Community feed, Post detail, Clubs, Federation Governance, and Compliance screens.
- **Inputs**: Screens 31–32, 35–36, 41, 43–51, 57–60.
- **Outputs**: High-performance virtualized lists, official federation seal watermarks, and case status badges.
- **Gate Criteria**: Member directory search renders in <50ms; document review pan/zoom functions smoothly.
- **Rollback Protocol**: Revert individual screen commits.

### Phase G: Tier 4 System, Support & Utility Screens (10 Screens)
- **Objective**: Elevate Auth secondary screens (Register, Forgot, Reset, Verify), Rulebook, Settings, and Admin.
- **Inputs**: Screens 02–05, 29, 61–66, Modals 1 & 2.
- **Outputs**: Precision toggle switches, biometric shields, rulebook accordion index, and system telemetry gauges.
- **Gate Criteria**: Notification toggles persist to SQLite/Isar immediately; 2FA backup card copies to clipboard.
- **Rollback Protocol**: Revert settings UI components.

### Phase H: Sensory System Binding (Audio & Haptics)
- **Objective**: Bind `HapticFeedback` patterns and sound pack (`challenge_accepted.wav`, `match_won.mp3`, `pr_achieved.wav`, `pro_tick.wav`) to signature actions.
- **Inputs**: `docs/design/49_PREMIUM_MOTION_ENGAGEMENT_REFINEMENT.md`.
- **Outputs**: Centralized `SensoryService` in `core/services/sensory_service.dart`.
- **Gate Criteria**:
  - Silent/vibrate mode on device is strictly respected (0 audio emitted when muted).
  - Haptic feedback fires cleanly without audio delays.
- **Rollback Protocol**: Toggle audio enabled flag to `false` in `SensoryService`.

### Phase I: Accessibility & Reduced-Motion Audit
- **Objective**: Validate screen reader Semantics, contrast ratios, and `prefers-reduced-motion` compliance across all 66 screens.
- **Inputs**: `docs/design/18_ACCESSIBILITY_SPEC.md` and `49_`.
- **Outputs**: Automated accessibility audit report.
- **Gate Criteria**:
  - Zero unlabelled icon buttons.
  - Text scales cleanly up to 200% without clipping or RenderFlex overflow.
  - With `disableAnimations: true`, zero confetti particles or camera shakes execute.
- **Rollback Protocol**: Patch offending widgets with explicit `Semantics` and `Expanded` wrappers.

### Phase J: Performance, Memory & FPS Profiling
- **Objective**: Profile application on physical/emulated hardware under heavy load (scrolling 100-item ranking list, bracket panning, rapid scorepad tapping).
- **Inputs**: Flutter DevTools Memory & Performance profilers.
- **Outputs**: Performance benchmark telemetry report.
- **Gate Criteria**:
  - Frame budget: 95th percentile < 16.6ms (60fps steady).
  - Memory: Max resident RAM < 120 MB.
  - Leaks: 0 leaked `AnimationController` or `VideoPlayerController` instances.
- **Rollback Protocol**: Optimize `cacheWidth` or reduce particle counts.

### Phase K: Cross-Platform Build Compilation & Verification
- **Objective**: Compile release-mode Android APK and Web bundle; verify on virtual emulator / cloud device.
- **Inputs**: GitHub Actions CI workflow, local Gradle compiler.
- **Outputs**: `app-release.apk` and `build/web` bundle.
- **Gate Criteria**:
  - APK builds with exit code 0 and is signed.
  - Web preview deploys cleanly to GitHub Pages.
  - Authenticated smoke test succeeds with test credentials (`muhammadhamadlatif94747@gmail.com`).
- **Rollback Protocol**: Inspect Gradle build logs and fix missing asset dependencies.

### Phase L: Production Tagging & Master Handoff
- **Objective**: Commit all elevated code, tag release in Git (`v1.3.0-stage3`), archive SHA-256 artifacts, and deliver final documentation.
- **Inputs**: All verified code and documentation artifacts.
- **Outputs**: Git commit pushed to `origin/main`, release tagged, canonical documentation complete.
- **Gate Criteria**: Clean working tree, CI passing green, user acceptance confirmed.
- **Rollback Protocol**: Git checkout previous release tag.
