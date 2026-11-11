// lib/core/widgets/ambient_particle_background.dart
import 'package:flutter/material.dart';
import '../constants/asset_paths.dart';
import '../theme/app_theme.dart';
import 'armsphere_image.dart';

/// Full-Screen Crystal-Clear 9:16 Stage Background Substrate
///
/// Renders a 100% sharp, unblurred, full-viewport (`Positioned.fill`) 9:16 stage
/// artwork at 100% native opacity with `Alignment.topCenter` and the Crystal-Clear
/// Top Showcase 4-stop vertical scrim (`stops: [0.0, 0.36, 0.62, 1.0]`).
/// Zero stardust particles, zero cubic grids, and zero milky opacity filters.
class AmbientParticleBackground extends StatelessWidget {
  final Widget? child;
  final Color? particleColor;
  final int? tabIndex;
  final String? backgroundAsset;
  final bool isAdminMode;

  const AmbientParticleBackground({
    super.key,
    this.child,
    this.particleColor,
    this.tabIndex,
    this.backgroundAsset,
    this.isAdminMode = false,
  });

  String _resolvePrimaryAsset() {
    if (backgroundAsset != null && backgroundAsset!.isNotEmpty) {
      return ArmSphereAssets.resolveSemanticAsset(backgroundAsset!);
    }
    if (isAdminMode) {
      switch (tabIndex) {
        case 4: // Official Dossier
          return ArmSphereAssets.stagePassportVault;
        default: // Command, Roster, Arena Ops, Governance
          return ArmSphereAssets.stageAdminGovernance;
      }
    }
    switch (tabIndex) {
      case 0: // Arena
        return ArmSphereAssets.stageArena;
      case 1: // Discover
        return ArmSphereAssets.stageDiscover;
      case 2: // Events / Championships
        return ArmSphereAssets.stageChampionshipBelts;
      case 3: // Community
        return ArmSphereAssets.stageCommunity;
      case 4: // Passport
        return ArmSphereAssets.stagePassportVault;
      default:
        return ArmSphereAssets.stageArena;
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolvedAsset = _resolvePrimaryAsset();
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppTheme.voidBackground),
        ArmSphereImage(
          assetPath: resolvedAsset,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          width: double.infinity,
          height: double.infinity,
          excludeFromSemantics: true,
          showLoadingIndicator: false,
        ),
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
        if (child != null) Positioned.fill(child: child!),
      ],
    );
  }
}
