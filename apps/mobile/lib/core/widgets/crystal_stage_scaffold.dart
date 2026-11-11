// lib/core/widgets/crystal_stage_scaffold.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/asset_paths.dart';
import '../providers/visual_preferences_provider.dart';
import '../theme/app_theme.dart';
import 'armsphere_image.dart';
import 'crystal_gloss_card.dart';

export '../providers/visual_preferences_provider.dart'
    show ArmSphereStageDomain, VisualCustomizeSlot;
export 'crystal_modal_sheet.dart';

/// Renders a 100% Full-Viewport, Crystal-Clear, Zero-Blur Functional Stage Background.
///
/// Unlike top-only headers that fade to black after 280dp, [CrystalStageBackdrop]
/// fills the entire screen (`Positioned.fill`) with sharp, high-contrast championship
/// photography matched to the screen's functional domain (or the user's custom uploaded
/// backdrop), so every [CrystalGlossCard] and [ElevatedActionCard] floats over a vivid,
/// undistorted full-screen canvas.
class CrystalStageBackdrop extends ConsumerWidget {
  final ArmSphereStageDomain domain;
  final String? customImageOverride;
  final Alignment viewportAlignment;

  const CrystalStageBackdrop({
    super.key,
    required this.domain,
    this.customImageOverride,
    this.viewportAlignment = Alignment.bottomCenter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    VisualPreferencesState prefs;
    try {
      prefs = ref.watch(visualPreferencesProvider);
    } catch (_) {
      prefs = const VisualPreferencesState();
    }
    final preset = prefs.presetForDomain(domain);

    // Determine primary image source: explicit override -> user custom screen upload -> domain preset
    final String? customImg = customImageOverride ??
        ((domain == ArmSphereStageDomain.arena ||
                domain == ArmSphereStageDomain.passport)
            ? prefs.customScreenBackdropImage
            : null);

    final Size screenSize = MediaQuery.sizeOf(context);
    final double targetWidth = screenSize.width > 0 ? screenSize.width : 400.0;
    final double targetHeight = screenSize.height > 0 ? screenSize.height : 840.0;

    return IgnorePointer(
      child: ClipRect(
        child: OverflowBox(
          alignment: viewportAlignment,
          minWidth: targetWidth,
          maxWidth: targetWidth,
          minHeight: targetHeight,
          maxHeight: targetHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Deep void base canvas
              const ColoredBox(color: AppTheme.voidBackground),

              // 2. Full-Screen Crystal-Clear Primary Functional Image (100% native opacity, NO BLUR)
              (customImg != null && customImg.trim().isNotEmpty)
                  ? ArmSphereImage(
                      imageUrl: ArmSphereAssets.resolveSemanticAsset(customImg),
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      width: double.infinity,
                      height: double.infinity,
                      fallbackAsset: preset.primaryAsset,
                      excludeFromSemantics: true,
                    )
                  : ArmSphereImage(
                      assetPath: ArmSphereAssets.resolveSemanticAsset(
                          preset.primaryAsset),
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      width: double.infinity,
                      height: double.infinity,
                      excludeFromSemantics: true,
                    ),

              // 3. Crystal-Clear Top Showcase Vignette (Top 38% 100% transparent, fading to obsidian floor)
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.36, 0.62, 1.0],
                    colors: [
                      Color(0x00070A11), // 0% opacity — 100% crystal-clear top 3D showcase
                      Color(0x14070A11), // 8% opacity — subtle transition
                      Color(0xBF070A11), // 75% opacity — smooth text-readability anchor
                      Color(0xF5070A11), // 96% opacity — deep pitch-black obsidian UI floor
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-Bleed Crystal Stage Top Header Scrim for `AppBar.flexibleSpace`.
///
/// Renders the top slice of the full-viewport [CrystalStageBackdrop] aligned seamlessly
/// with the screen body, preserving 100% clarity in the top 38% 3D showcase zone.
class CrystalHeaderStageBar extends StatelessWidget {
  final ArmSphereStageDomain domain;
  final String? customImageOverride;

  const CrystalHeaderStageBar({
    super.key,
    this.domain = ArmSphereStageDomain.arena,
    this.customImageOverride,
  });

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold != null && scaffold.widget.extendBodyBehindAppBar) {
      return const SizedBox.expand();
    }
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: AppTheme.voidBackground),
          CrystalStageBackdrop(
            domain: domain,
            customImageOverride: customImageOverride,
            viewportAlignment: Alignment.topCenter,
          ),
        ],
      ),
    );
  }
}

/// Interactive Bottom Sheet for customizing Profile Portrait, Hero Card Background,
/// and Full-Screen Functional Backdrop (Upload Custom Images + 5 Pro Presets).
Future<void> showVisualCustomizationSheet(
  BuildContext context, {
  WidgetRef? ref,
  VisualCustomizeSlot? initialSlot,
  ArmSphereStageDomain? domain,
}) async {
  HapticFeedback.mediumImpact();
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: const Color(0xEB0B0F19),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      side: BorderSide(color: Color(0x38FFFFFF), width: 1.0),
    ),
    builder: (sheetContext) {
      return _VisualCustomizationStudioSheet(
        initialSlot: initialSlot,
        domain: domain,
      );
    },
  );
}

class _VisualCustomizationStudioSheet extends ConsumerWidget {
  final VisualCustomizeSlot? initialSlot;
  final ArmSphereStageDomain? domain;

  const _VisualCustomizationStudioSheet({
    this.initialSlot,
    this.domain,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(visualPreferencesProvider);
    final notifier = ref.read(visualPreferencesProvider.notifier);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.55,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppTheme.goldPrimary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.goldPrimary.withValues(alpha: 0.45),
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppTheme.goldPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ARENA VISUAL & CARD STUDIO',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: AppTheme.textPure,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Upload your own photos or choose Pro Championship Presets',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (prefs.isUploading)
              const Padding(
                padding: EdgeInsets.only(bottom: 14),
                child: LinearProgressIndicator(
                  color: AppTheme.goldPrimary,
                  backgroundColor: AppTheme.borderSubtle,
                ),
              ),

            // 1. Athlete Portrait / Avatar Upload & Presets
            const Text(
              '1. ATHLETE PORTRAIT & AVATAR',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppTheme.goldPrimary,
              ),
            ),
            const SizedBox(height: 8),
            CrystalGlossCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      ArmSphereImage.avatar(
                        imageUrl: prefs.customPortraitImage,
                        assetPath: prefs.customPortraitImage == null
                            ? ArmSphereAssets.heroGrip
                            : null,
                        size: 56,
                        border: Border.all(
                            color: AppTheme.goldPrimary, width: 1.5),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pro Athlete Cutout / Portrait',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppTheme.textPure,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Displayed in your Hero Identity Card, VS Matchups & Passport',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final ok = await notifier.pickAndUploadPortrait();
                          if (ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Portrait photo updated!'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.upload_file_rounded, size: 16),
                        label: const Text('Upload Photo'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(130, 38),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => notifier.setPortraitPresetOrUrl(
                            ArmSphereAssets.heroGrip),
                        icon: const Icon(Icons.flash_on_rounded,
                            size: 15, color: AppTheme.goldPrimary),
                        label: const Text('Pro Grip Portrait'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(120, 38),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => notifier.setPortraitPresetOrUrl(
                            ArmSphereAssets.defaultAvatar),
                        icon: const Icon(Icons.person_outline_rounded,
                            size: 15, color: AppTheme.textSecondary),
                        label: const Text('Silhouette'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(100, 38),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // 2. Whole Hero Card Background Image
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '2. HERO CARD BACKGROUND ART',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppTheme.goldPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final ok = await notifier.pickCustomCardBanner();
                    if (ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Custom Hero Card background applied!'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.add_photo_alternate_outlined,
                      size: 16, color: AppTheme.cyan),
                  label: const Text(
                    'Upload Custom Card Image',
                    style: TextStyle(fontSize: 12, color: AppTheme.cyan),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 112,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: kArmSphereProPresets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final preset = kArmSphereProPresets[index];
                  final isSelected = prefs.customCardBannerImage == null &&
                      prefs.selectedCardPresetId == preset.id;
                  return _PresetThumbnailTile(
                    preset: preset,
                    isSelected: isSelected,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      notifier.selectCardPreset(preset.id);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 22),

            // 3. Full-Screen Crystal Stage Background
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '3. FULL-SCREEN STAGE BACKGROUND',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppTheme.goldPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final ok = await notifier.pickCustomScreenBackdrop();
                    if (ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Custom full-screen background applied!'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.wallpaper_rounded,
                      size: 16, color: AppTheme.cyan),
                  label: const Text(
                    'Upload Custom Wallpaper',
                    style: TextStyle(fontSize: 12, color: AppTheme.cyan),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 112,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: kArmSphereProPresets.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final isAuto = prefs.customScreenBackdropImage == null &&
                        prefs.selectedScreenPresetId == null;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        notifier.selectScreenPreset(null);
                      },
                      child: Container(
                        width: 148,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isAuto
                                ? AppTheme.goldPrimary
                                : Colors.white.withValues(alpha: 0.22),
                            width: isAuto ? 2.0 : 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Icon(Icons.auto_mode_rounded,
                                    color: AppTheme.goldPrimary, size: 18),
                                if (isAuto)
                                  const Icon(Icons.check_circle,
                                      color: AppTheme.goldPrimary, size: 16),
                              ],
                            ),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Auto By Tab Function',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPure,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Matches Arena, Discover, Events & Club',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.textSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final preset = kArmSphereProPresets[index - 1];
                  final isSelected = prefs.customScreenBackdropImage == null &&
                      prefs.selectedScreenPresetId == preset.id;
                  return _PresetThumbnailTile(
                    preset: preset,
                    isSelected: isSelected,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      notifier.selectScreenPreset(preset.id);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Reset & Done Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      notifier.resetToDefaults();
                    },
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: const Text('Reset Defaults'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Apply & Close'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _PresetThumbnailTile extends StatelessWidget {
  final ArmSphereVisualPreset preset;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetThumbnailTile({
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 156,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppTheme.goldPrimary
                : Colors.white.withValues(alpha: 0.24),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              offset: const Offset(0, 6),
              blurRadius: 14,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.5),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ArmSphereImage(
                assetPath: preset.primaryAsset,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x26070A11),
                      Color(0xD9070A11),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: preset.primaryGlowColor,
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: AppTheme.goldPrimary,
                            size: 16,
                          ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preset.title,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPure,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          preset.subtitle,
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
