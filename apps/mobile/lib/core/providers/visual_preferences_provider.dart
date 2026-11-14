// lib/core/providers/visual_preferences_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/asset_paths.dart';
import '../theme/app_theme.dart';
import 'athlete_provider.dart';
import 'state_providers.dart';

/// Functional Screen / Domain Category for full-screen crystal-clear backgrounds.
enum ArmSphereStageDomain {
  arena,
  training,
  discover,
  events,
  championships,
  community,
  passport,
  rankings,
  venues,
  referee,
  governance,
  headToHead,
  teams,
  authWalkout,
}

/// Target customization slot for the Visual Customization Studio sheet.
enum VisualCustomizeSlot {
  portrait,
  heroCard,
  screenBackdrop,
}

/// Presentation mode for the Athlete Dashboard Hero Identity Card.
enum AthleteHeroPresentationMode {
  /// Full-bleed widescreen/landscape artwork where the subject and atmosphere
  /// span the entire card continuously.
  fullBleedContinuous,

  /// Combined presentation when a separate portrait/square athlete photo or cutout
  /// is provided: blends the portrait on the left subject stage without stretching it,
  /// over a coordinated atmospheric card background.
  portraitSubjectWithStage,
}

/// Image-independent configuration for the Athlete Dashboard Hero Card.
///
/// Decouples the card layout from any single artwork's dimensions, focal point,
/// or composition so future official artworks and user-uploaded photos work
/// without screen layout changes.
class AthleteHeroImageConfig {
  final String semanticId;
  final String backgroundSource;
  final String? subjectSource;
  final Alignment backgroundAlignment;
  final Alignment subjectAlignment;
  final BoxFit backgroundFit;
  final BoxFit subjectFit;
  final double backgroundOpacity;
  final double scrimIntensity;
  final AthleteHeroPresentationMode mode;

  const AthleteHeroImageConfig({
    this.semanticId = ArmSphereAssets.semanticProfileAthleteDashboardHero,
    required this.backgroundSource,
    this.subjectSource,
    this.backgroundAlignment = const Alignment(-0.55, -0.24),
    this.subjectAlignment = const Alignment(0.0, -0.32),
    this.backgroundFit = BoxFit.cover,
    this.subjectFit = BoxFit.cover,
    this.backgroundOpacity = 1.0,
    this.scrimIntensity = 1.0,
    this.mode = AthleteHeroPresentationMode.fullBleedContinuous,
  });
}

/// Curated High-Class Pro Preset definition for Screen & Card Backgrounds.
class ArmSphereVisualPreset {
  final String id;
  final String title;
  final String subtitle;
  final String primaryAsset;
  final String? secondaryTextureAsset;
  final Color primaryGlowColor;
  final Color secondaryGlowColor;
  final Alignment defaultFocalAlignment;

  const ArmSphereVisualPreset({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.primaryAsset,
    this.secondaryTextureAsset,
    required this.primaryGlowColor,
    required this.secondaryGlowColor,
    this.defaultFocalAlignment = Alignment.topCenter,
  });
}

/// Canonical catalog of High-Class Pro Presets mapped strictly to the 28 Master Assets.
const List<ArmSphereVisualPreset> kArmSphereProPresets = [
  ArmSphereVisualPreset(
    id: 'championship_arena',
    title: 'Championship Main Stage',
    subtitle: 'Overhead lighting truss, jumbotron canopy & glossy stage floor',
    primaryAsset: ArmSphereAssets.stageArena,
    secondaryTextureAsset: null,
    primaryGlowColor: AppTheme.crimson,
    secondaryGlowColor: AppTheme.goldPrimary,
    defaultFocalAlignment: Alignment.topCenter,
  ),
  ArmSphereVisualPreset(
    id: 'discover_hub_stage',
    title: 'Global Discover Hub',
    subtitle: 'World ecosystem radar & sanctioning discovery stage',
    primaryAsset: ArmSphereAssets.stageDiscover,
    secondaryTextureAsset: null,
    primaryGlowColor: AppTheme.crimson,
    secondaryGlowColor: AppTheme.cyan,
    defaultFocalAlignment: Alignment.topCenter,
  ),
  ArmSphereVisualPreset(
    id: 'grand_prix_poster',
    title: 'Championship Belts & Events',
    subtitle: 'Gold title prestige, sanctioned bracket stage & championship belts',
    primaryAsset: ArmSphereAssets.stageChampionshipBelts,
    secondaryTextureAsset: null,
    primaryGlowColor: AppTheme.goldPrimary,
    secondaryGlowColor: AppTheme.crimson,
    defaultFocalAlignment: Alignment.topCenter,
  ),
  ArmSphereVisualPreset(
    id: 'community_arena_stage',
    title: 'Community Arena & Broadcast',
    subtitle: 'Social arena stage, match clips & federation dispatches',
    primaryAsset: ArmSphereAssets.stageCommunity,
    secondaryTextureAsset: null,
    primaryGlowColor: AppTheme.emerald,
    secondaryGlowColor: AppTheme.goldPrimary,
    defaultFocalAlignment: Alignment.topCenter,
  ),
  ArmSphereVisualPreset(
    id: 'passport_vault_stage',
    title: 'Athlete Passport Vault',
    subtitle: 'Biometric federation identity & official dossier vault',
    primaryAsset: ArmSphereAssets.stagePassportVault,
    secondaryTextureAsset: null,
    primaryGlowColor: AppTheme.cyan,
    secondaryGlowColor: AppTheme.goldPrimary,
    defaultFocalAlignment: Alignment.topCenter,
  ),
  ArmSphereVisualPreset(
    id: 'strength_training_lab',
    title: 'Strength & Performance Lab',
    subtitle: 'Table pulley rig, wrist wrench, weight stack & PR vault',
    primaryAsset: ArmSphereAssets.stageTrainingLab,
    secondaryTextureAsset: null,
    primaryGlowColor: AppTheme.crimson,
    secondaryGlowColor: AppTheme.goldPrimary,
    defaultFocalAlignment: Alignment.topCenter,
  ),
  ArmSphereVisualPreset(
    id: 'referee_command_stage',
    title: 'Referee Command & Scorepad',
    subtitle: 'Sanctioned table officiating, foul matrix & certification stage',
    primaryAsset: ArmSphereAssets.stageReferee,
    secondaryTextureAsset: null,
    primaryGlowColor: AppTheme.goldPrimary,
    secondaryGlowColor: AppTheme.crimson,
    defaultFocalAlignment: Alignment.topCenter,
  ),
  ArmSphereVisualPreset(
    id: 'admin_governance_stage',
    title: 'Federation Governance & Ops',
    subtitle: 'Executive tribunal, roster authority & arena operations',
    primaryAsset: ArmSphereAssets.stageAdminGovernance,
    secondaryTextureAsset: null,
    primaryGlowColor: AppTheme.goldPrimary,
    secondaryGlowColor: AppTheme.cyan,
    defaultFocalAlignment: Alignment.topCenter,
  ),
  ArmSphereVisualPreset(
    id: 'elo_rankings_stage',
    title: 'Global ELO Rankings Ladder',
    subtitle: 'World tier standings, division points & nominations',
    primaryAsset: ArmSphereAssets.stageRankings,
    secondaryTextureAsset: null,
    primaryGlowColor: AppTheme.goldPrimary,
    secondaryGlowColor: AppTheme.crimson,
    defaultFocalAlignment: Alignment.topCenter,
  ),
  ArmSphereVisualPreset(
    id: 'head_to_head_stage',
    title: 'Head-to-Head Tale of the Tape',
    subtitle: 'Biometric matchup comparison & combat radar stage',
    primaryAsset: ArmSphereAssets.stageHeadToHead,
    secondaryTextureAsset: null,
    primaryGlowColor: AppTheme.crimson,
    secondaryGlowColor: AppTheme.cyan,
    defaultFocalAlignment: Alignment.topCenter,
  ),
  ArmSphereVisualPreset(
    id: 'teams_clubs_stage',
    title: 'Clubs & Teams Roster Stage',
    subtitle: 'Sanctioned armwrestling clubs, chapters & team crests',
    primaryAsset: ArmSphereAssets.stageTeams,
    secondaryTextureAsset: null,
    primaryGlowColor: AppTheme.emerald,
    secondaryGlowColor: AppTheme.goldPrimary,
    defaultFocalAlignment: Alignment.topCenter,
  ),
  ArmSphereVisualPreset(
    id: 'venues_pickup_stage',
    title: 'Training Venues & Pickup Pulls',
    subtitle: 'Verified practice tables, gyms & live sparring sessions',
    primaryAsset: ArmSphereAssets.stageVenues,
    secondaryTextureAsset: null,
    primaryGlowColor: AppTheme.cyan,
    secondaryGlowColor: AppTheme.emerald,
    defaultFocalAlignment: Alignment.topCenter,
  ),
  ArmSphereVisualPreset(
    id: 'auth_walkout_stage',
    title: 'Championship Walkout Tunnel',
    subtitle: 'Arena walkout entrance for authentication & onboarding',
    primaryAsset: ArmSphereAssets.stageAuthWalkout,
    secondaryTextureAsset: null,
    primaryGlowColor: AppTheme.crimson,
    secondaryGlowColor: AppTheme.goldPrimary,
    defaultFocalAlignment: Alignment.topCenter,
  ),
  ArmSphereVisualPreset(
    id: ArmSphereAssets.semanticProfileAthleteDashboardHero,
    title: 'Shadowed Hero in Crimson Smoke',
    subtitle: 'Official Void athlete silhouette & crimson atmospheric smoke stage',
    primaryAsset: ArmSphereAssets.heroAthleteDashboard,
    secondaryTextureAsset: null,
    primaryGlowColor: AppTheme.crimson,
    secondaryGlowColor: AppTheme.goldPrimary,
    defaultFocalAlignment: Alignment(-0.55, -0.24),
  ),
];

/// Normalizes any persisted path ending in `m1_hero_athlete_dashboard.png` to
/// `ArmSphereAssets.heroAthleteDashboard` (`.webp`) so local Hive preferences
/// never break after the `.png` -> `.webp` migration.
String? normalizeLegacyVisualAssetPath(String? rawPath) {
  if (rawPath == null) return null;
  final trimmed = rawPath.trim();
  if (trimmed.isEmpty) return rawPath;
  if (trimmed.endsWith('m1_hero_athlete_dashboard.png')) {
    return ArmSphereAssets.heroAthleteDashboard;
  }
  return trimmed;
}

/// Immutable state holding the user's custom uploaded or preset visual choices.
class VisualPreferencesState {
  /// Custom uploaded or preset portrait image URL / data URI / asset path.
  final String? customPortraitImage;

  /// Custom uploaded or preset Hero Identity Card background image URL / data URI / asset path.
  final String? customCardBannerImage;

  /// Selected Pro Preset ID for the Hero Identity Card (`profile.athlete.dashboard_hero`, `championship_arena`, etc.).
  final String selectedCardPresetId;

  /// Custom uploaded full-screen stage background URL / data URI / asset path (optional override).
  final String? customScreenBackdropImage;

  /// Selected Pro Preset ID override for the user's personal Arena & Passport screens (null = domain default).
  final String? selectedScreenPresetId;

  /// Whether an image upload/selection operation is currently in progress.
  final bool isUploading;

  const VisualPreferencesState({
    this.customPortraitImage,
    this.customCardBannerImage,
    this.selectedCardPresetId =
        ArmSphereAssets.semanticProfileAthleteDashboardHero,
    this.customScreenBackdropImage,
    this.selectedScreenPresetId,
    this.isUploading = false,
  });

  VisualPreferencesState copyWith({
    String? customPortraitImage,
    bool clearPortrait = false,
    String? customCardBannerImage,
    bool clearCardBanner = false,
    String? selectedCardPresetId,
    String? customScreenBackdropImage,
    bool clearScreenBackdrop = false,
    String? selectedScreenPresetId,
    bool clearScreenPreset = false,
    bool? isUploading,
  }) {
    return VisualPreferencesState(
      customPortraitImage: clearPortrait
          ? null
          : normalizeLegacyVisualAssetPath(
              customPortraitImage ?? this.customPortraitImage),
      customCardBannerImage: clearCardBanner
          ? null
          : normalizeLegacyVisualAssetPath(
              customCardBannerImage ?? this.customCardBannerImage),
      selectedCardPresetId: selectedCardPresetId ?? this.selectedCardPresetId,
      customScreenBackdropImage: clearScreenBackdrop
          ? null
          : normalizeLegacyVisualAssetPath(
              customScreenBackdropImage ?? this.customScreenBackdropImage),
      selectedScreenPresetId: clearScreenPreset
          ? null
          : (selectedScreenPresetId ?? this.selectedScreenPresetId),
      isUploading: isUploading ?? this.isUploading,
    );
  }

  /// Resolves the effective Hero Card background image (user upload -> selected preset asset -> semantic default).
  String get effectiveCardBannerImage {
    if (customCardBannerImage != null &&
        customCardBannerImage!.trim().isNotEmpty) {
      return ArmSphereAssets.resolveSemanticAsset(
          normalizeLegacyVisualAssetPath(customCardBannerImage));
    }
    final preset = kArmSphereProPresets.firstWhere(
      (p) => p.id == selectedCardPresetId,
      orElse: () => kArmSphereProPresets.last,
    );
    return ArmSphereAssets.resolveSemanticAsset(preset.primaryAsset);
  }

  /// Resolves the complete image-independent configuration for the Athlete Dashboard
  /// Hero Card (`profile.athlete.dashboard_hero`).
  ///
  /// - When a widescreen/landscape card artwork is active without a separate
  ///   portrait photo, uses [AthleteHeroPresentationMode.fullBleedContinuous].
  /// - When a distinct portrait or square athlete photo ([customPortraitImage] or
  ///   [profileAvatarUrl]) is present, uses [AthleteHeroPresentationMode.portraitSubjectWithStage]
  ///   so the portrait photo is never stretched into a widescreen aspect ratio.
  AthleteHeroImageConfig resolveAthleteHeroConfig({
    String? profileAvatarUrl,
    String? cardBannerOverride,
    Alignment? focalOverride,
  }) {
    final rawBanner = (cardBannerOverride != null &&
            cardBannerOverride.trim().isNotEmpty)
        ? normalizeLegacyVisualAssetPath(cardBannerOverride)!
        : effectiveCardBannerImage;
    final resolvedBanner = ArmSphereAssets.resolveSemanticAsset(rawBanner);

    final preset = kArmSphereProPresets.firstWhere(
      (p) =>
          p.id == selectedCardPresetId || p.primaryAsset == resolvedBanner,
      orElse: () => kArmSphereProPresets.last,
    );

    final candidatePortrait =
        (customPortraitImage != null && customPortraitImage!.trim().isNotEmpty)
            ? normalizeLegacyVisualAssetPath(customPortraitImage)
            : (profileAvatarUrl != null && profileAvatarUrl.trim().isNotEmpty)
                ? normalizeLegacyVisualAssetPath(profileAvatarUrl)
                : null;

    final widescreenHeroAssets = <String>{
      ...ArmSphereAssets.canonical28Assets,
    };
    widescreenHeroAssets.remove(ArmSphereAssets.avatarNeutralDark);

    final resolvedPortrait = candidatePortrait != null
        ? ArmSphereAssets.resolveSemanticAsset(candidatePortrait)
        : null;

    final hasDistinctPortraitSubject = resolvedPortrait != null &&
        resolvedPortrait != resolvedBanner &&
        !widescreenHeroAssets.contains(resolvedPortrait);

    return AthleteHeroImageConfig(
      semanticId: ArmSphereAssets.semanticProfileAthleteDashboardHero,
      backgroundSource: resolvedBanner,
      subjectSource: hasDistinctPortraitSubject ? resolvedPortrait : null,
      backgroundAlignment: focalOverride ?? preset.defaultFocalAlignment,
      subjectAlignment: const Alignment(0.0, -0.32),
      backgroundFit: BoxFit.cover,
      subjectFit: BoxFit.cover,
      backgroundOpacity: 1.0,
      scrimIntensity: 1.0,
      mode: hasDistinctPortraitSubject
          ? AthleteHeroPresentationMode.portraitSubjectWithStage
          : AthleteHeroPresentationMode.fullBleedContinuous,
    );
  }

  /// Resolves the effective full-screen background for any functional screen domain.
  ///
  /// Each tab/screen gets its own distinct functional default background unless
  /// the user has explicitly uploaded or chosen a custom screen backdrop.
  ArmSphereVisualPreset presetForDomain(ArmSphereStageDomain domain) {
    if (selectedScreenPresetId != null &&
        domain == ArmSphereStageDomain.arena) {
      return kArmSphereProPresets.firstWhere(
        (p) => p.id == selectedScreenPresetId,
        orElse: () => _defaultPresetForDomain(domain),
      );
    }
    return _defaultPresetForDomain(domain);
  }

  static ArmSphereVisualPreset _defaultPresetForDomain(
      ArmSphereStageDomain domain) {
    switch (domain) {
      case ArmSphereStageDomain.arena:
        return kArmSphereProPresets[0]; // stageArena9x16
      case ArmSphereStageDomain.discover:
        return kArmSphereProPresets[1]; // stageDiscover9x16
      case ArmSphereStageDomain.events:
      case ArmSphereStageDomain.championships:
        return kArmSphereProPresets[2]; // stageChampionshipBelts9x16
      case ArmSphereStageDomain.community:
        return kArmSphereProPresets[3]; // stageCommunity9x16
      case ArmSphereStageDomain.passport:
        return kArmSphereProPresets[4]; // stagePassportVault9x16
      case ArmSphereStageDomain.training:
        return kArmSphereProPresets[5]; // stageTrainingLab9x16
      case ArmSphereStageDomain.referee:
        return kArmSphereProPresets[6]; // stageReferee9x16
      case ArmSphereStageDomain.governance:
        return kArmSphereProPresets[7]; // stageAdminGovernance9x16
      case ArmSphereStageDomain.rankings:
        return kArmSphereProPresets[8]; // stageRankings9x16
      case ArmSphereStageDomain.headToHead:
        return kArmSphereProPresets[9]; // stageHeadToHead9x16
      case ArmSphereStageDomain.teams:
        return kArmSphereProPresets[10]; // stageTeams9x16
      case ArmSphereStageDomain.venues:
        return kArmSphereProPresets[11]; // stageVenues9x16
      case ArmSphereStageDomain.authWalkout:
        return kArmSphereProPresets[12]; // stageAuthWalkout9x16
    }
  }
}

class VisualPreferencesNotifier extends StateNotifier<VisualPreferencesState> {
  final Ref _ref;
  static const String _boxName = 'armsphere_visual_prefs';

  VisualPreferencesNotifier(this._ref) : super(const VisualPreferencesState()) {
    _loadPersisted();
  }

  Future<void> _loadPersisted() async {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        final box = Hive.box(_boxName);
        _applyFromBox(box);
      } else if (Hive.isBoxOpen('local_data_cache') ||
          Hive.isBoxOpen('offline_sync_queue')) {
        final box = await Hive.openBox(_boxName);
        _applyFromBox(box);
      }
    } catch (_) {
      // Safe fallback in unit/widget test environments where Hive is not initialized
    }
  }

  void _applyFromBox(Box box) {
    if (!mounted) return;
    final rawPortrait = box.get('customPortraitImage') as String?;
    final rawCardBanner = box.get('customCardBannerImage') as String?;
    final rawScreenBackdrop = box.get('customScreenBackdropImage') as String?;

    final normalizedPortrait = normalizeLegacyVisualAssetPath(rawPortrait);
    final normalizedCardBanner = normalizeLegacyVisualAssetPath(rawCardBanner);
    final normalizedScreenBackdrop =
        normalizeLegacyVisualAssetPath(rawScreenBackdrop);

    state = VisualPreferencesState(
      customPortraitImage: normalizedPortrait,
      customCardBannerImage: normalizedCardBanner,
      selectedCardPresetId: (box.get('selectedCardPresetId') as String?) ??
          ArmSphereAssets.semanticProfileAthleteDashboardHero,
      customScreenBackdropImage: normalizedScreenBackdrop,
      selectedScreenPresetId: box.get('selectedScreenPresetId') as String?,
    );

    if (rawPortrait != normalizedPortrait ||
        rawCardBanner != normalizedCardBanner ||
        rawScreenBackdrop != normalizedScreenBackdrop) {
      _saveToBox();
    }
  }

  Future<void> _saveToBox() async {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        final box = Hive.box(_boxName);
        await box.put('customPortraitImage', state.customPortraitImage);
        await box.put('customCardBannerImage', state.customCardBannerImage);
        await box.put('selectedCardPresetId', state.selectedCardPresetId);
        await box.put(
            'customScreenBackdropImage', state.customScreenBackdropImage);
        await box.put('selectedScreenPresetId', state.selectedScreenPresetId);
      }
    } catch (_) {}
  }

  /// Picks an image from the device gallery/filesystem and applies it as the
  /// Athlete Portrait (`profilePhoto`), syncing to the backend when available.
  Future<bool> pickAndUploadPortrait() async {
    try {
      state = state.copyWith(isUploading: true);
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (picked == null) {
        state = state.copyWith(isUploading: false);
        return false;
      }

      final bytes = await picked.readAsBytes();
      final base64Str = base64Encode(bytes);
      final dataUri = 'data:image/jpeg;base64,$base64Str';

      state = state.copyWith(
        customPortraitImage: dataUri,
        isUploading: false,
      );
      await _saveToBox();

      // Best-effort sync to backend profilePhoto
      try {
        final profile = _ref.read(athleteProfileProvider).value;
        final athleteId = profile?['id']?.toString();
        final repo = _ref.read(athleteRepositoryProvider);
        if (athleteId != null && athleteId.isNotEmpty) {
          await repo.updateProfile(athleteId, {'profilePhoto': dataUri});
          _ref.invalidate(athleteProfileProvider);
        }
      } catch (_) {
        // Local dataUri remains active even if offline
      }
      return true;
    } catch (_) {
      state = state.copyWith(isUploading: false);
      return false;
    }
  }

  /// Picks a custom image from the device gallery for the Hero Identity Card background.
  Future<bool> pickCustomCardBanner() async {
    try {
      state = state.copyWith(isUploading: true);
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1000,
        imageQuality: 85,
      );
      if (picked == null) {
        state = state.copyWith(isUploading: false);
        return false;
      }
      final bytes = await picked.readAsBytes();
      final dataUri = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      state = state.copyWith(
        customCardBannerImage: dataUri,
        isUploading: false,
      );
      await _saveToBox();
      return true;
    } catch (_) {
      state = state.copyWith(isUploading: false);
      return false;
    }
  }

  /// Picks a custom image from the device gallery for the Full-Screen Stage Backdrop.
  Future<bool> pickCustomScreenBackdrop() async {
    try {
      state = state.copyWith(isUploading: true);
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked == null) {
        state = state.copyWith(isUploading: false);
        return false;
      }
      final bytes = await picked.readAsBytes();
      final dataUri = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      state = state.copyWith(
        customScreenBackdropImage: dataUri,
        isUploading: false,
      );
      await _saveToBox();
      return true;
    } catch (_) {
      state = state.copyWith(isUploading: false);
      return false;
    }
  }

  /// Sets a direct URL or preset asset for the Athlete Portrait.
  Future<void> setPortraitPresetOrUrl(String? imageSource) async {
    if (imageSource == null || imageSource.trim().isEmpty) {
      state = state.copyWith(clearPortrait: true);
    } else {
      state = state.copyWith(customPortraitImage: imageSource.trim());
    }
    await _saveToBox();
  }

  /// Selects a Pro Preset for the Hero Identity Card background (and clears custom card upload).
  Future<void> selectCardPreset(String presetId) async {
    state = state.copyWith(
      selectedCardPresetId: presetId,
      clearCardBanner: true,
    );
    await _saveToBox();
  }

  /// Selects a Pro Preset for the Full-Screen Stage Backdrop (or null to use automatic functional screen themes).
  Future<void> selectScreenPreset(String? presetId) async {
    if (presetId == null) {
      state = state.copyWith(
        clearScreenPreset: true,
        clearScreenBackdrop: true,
      );
    } else {
      state = state.copyWith(
        selectedScreenPresetId: presetId,
        clearScreenBackdrop: true,
      );
    }
    await _saveToBox();
  }

  /// Resets all visual customizations to the default functional championship themes.
  Future<void> resetToDefaults() async {
    state = const VisualPreferencesState();
    await _saveToBox();
  }
}

final visualPreferencesProvider =
    StateNotifierProvider<VisualPreferencesNotifier, VisualPreferencesState>(
        (ref) {
  return VisualPreferencesNotifier(ref);
});
