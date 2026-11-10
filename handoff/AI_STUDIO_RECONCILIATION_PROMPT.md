# Master AI Studio Reconciliation Prompt for Gemini 4 Argon (Version 9)

Copy and paste the exact text block below into Google AI Studio to synchronize Gemini 4 Argon with the green-verified GitHub Actions repository state:

---

```markdown
# ArmSphere — Continuous Synchronization & Verification Directive (v9 Master State)

Assalam u Alaikum Gemini 4 Argon,

We have successfully integrated, verified, and stabilized the ArmSphere project repository in GitHub Actions CI based on your v9 export (`armsphere-1 (2).zip`). All 383 unit and widget tests are 100% GREEN, Flutter static analysis has ZERO errors, and production-signed Android artifacts (`app-release.apk` and `app-release.aab`) have been generated and verified.

## 1. What Has Been Preserved & Verified

1. **Floating Material Architecture**:
   - `AppTheme.cardBorder` and `cardSurface` are set to `Colors.transparent` so card borders no longer frame the entire screen background.
   - Design tokens `AppTheme.obsidianRimBorder` (`0x33FFFFFF`) and `AppTheme.smokedObsidianGlass` (`0x55070A11`) are active across all glass surfaces.
   - `VoidStageScaffold` incorporates `ArmSphereAppBar`, `SmokedGlassCard`, and `mainShellBottomClearance` (84dp) to clear the floating dock.

2. **TacticalCommandSheet Persona Switcher**:
   - `apps/mobile/lib/core/widgets/tactical_command_sheet.dart` is live and wired to provide instant 1-tap switching between Athlete, Referee, Federation Admin, Organizer, and Medical Staff personas.

3. **28-Asset Void Catalog & Semantic Resolution**:
   - `ArmSphereAssets.resolveSemanticAsset(slotId, {String fallback = ''})` reliably maps all canonical slot IDs (`profile.athlete.dashboard_hero`, `arena.home.radar_card`, `discover.hub.venues_tile`, `events.tournament.detail_hero`, etc.) to the 28 physical WebP assets while preserving portrait image bindings and category clip fallbacks.
   - Dedicated assets for Brand (`m0_logo_full.webp`, `m0_icon_gold.webp`, `m0_seal_fed.webp`), Textures (`m1_tex_knurl.webp`, `m1_tex_chalk.webp`), and Badges (`m4_bdg_*.webp`, `m4_ref_*.webp`) are preserved.

4. **Component Compatibility**:
   - `AppEmptyState`: Fully supports both `subtitle:` and `description:`, and renders both primary `ctaLabel` and `secondaryCtaLabel` with haptic feedback.
   - `CrystalScreenLoadingView`: Supports `itemCount`, `cardHeight`, and `padding`.
   - `ElevatedActionCard`: Supports custom `gradient:` in addition to `backgroundColor`.

## 2. Strict Rules For Your Next Edits

To maintain 100% green CI and prevent workspace compilation freezes:

1. **NEVER Replace Production Screens with Stubs**:
   - Retain full production screen architectures, navigation stacks, providers, and test finders.
   - Do not truncate or stub out multi-role views, intelligence decks, or tournament tables.

2. **Zero-Diff Workflow Integrity**:
   - Do not modify files in `.github/workflows/` (modifying workflow files will cause git push rejections).
   - Ensure all parameters passed to core widgets (`VoidStageScaffold`, `AppEmptyState`, `CrystalScreenLoadingView`, `ElevatedActionCard`) match their defined signatures.

3. **Design System Consistency**:
   - Always wrap full-screen experiences in `VoidStageScaffold`.
   - Apply `mainShellBottomClearance` (84dp) or `bottomPadding` wherever a screen has a scrolling ListView, GridView, or SingleChildScrollView to prevent content from hiding behind the floating navigation dock.
   - Use `AppTheme.fontDisplay` (Space Grotesk) for bold uppercase headers and numerical stats, and `AppTheme.fontBody` (Inter) for labels, descriptions, and body copy.

Continue developing the next features, refinements, and animations smoothly under these verified guidelines!
```
