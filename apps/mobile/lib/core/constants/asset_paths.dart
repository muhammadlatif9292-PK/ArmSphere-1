import 'package:flutter/painting.dart';

/// Clip categories used to resolve category-specific video thumbnail fallbacks.
enum ClipCategory {
  sparring,
  technique,
  tournament,
  supermatch,
  match,
}

/// Authoritative ArmSphere Media & Asset Path Registry
///
/// Compile-safe constants for the complete 28-asset `.webp` "Void" visual suite
/// (`#070A11` pitch-black obsidian, brushed titanium, and blood-crimson smoke)
/// alongside M0-M6 brand, badge, texture, and audio assets.
class ArmSphereAssets {
  ArmSphereAssets._();

  // ===========================================================================
  // TIER 0 & 1: CORE HEROES, BENTO PORTALS & TOURNAMENT HEADERS (v2 Bundle)
  // ===========================================================================
  static const String athleteDashboardHero = 'assets/images/heroes/m1_hero_athlete_dashboard.webp';
  static const String arenaRadarCard       = 'assets/images/heroes/m1_card_arena_radar.webp';
  static const String supermatchVsCard     = 'assets/images/heroes/m1_card_supermatch_vs.webp';
  static const String welcomeGripHero      = 'assets/images/heroes/m1_hero_welcome_grip.webp';
  static const String tournamentPoster     = 'assets/images/defaults/tournament_poster.webp';

  static const String bentoVenues          = 'assets/images/bento/m1_bento_venues.webp';
  static const String bentoPickupSparring  = 'assets/images/bento/m1_bento_pickup_sparring.webp';
  static const String bentoCommunityFeed   = 'assets/images/bento/m1_bento_community_feed.webp';
  static const String bentoEloRankings     = 'assets/images/bento/m1_bento_elo_rankings.webp';

  // ===========================================================================
  // TIER 2: FULL-SCREEN 9:16 DOMAIN STAGE BACKDROPS (v2 + v3 Bundles)
  // ===========================================================================
  static const String stageArena             = 'assets/images/heroes/m1_stage_arena_9x16.webp';
  static const String stageTrainingLab       = 'assets/images/heroes/m1_stage_training_lab_9x16.webp';
  static const String stageHeadToHead        = 'assets/images/heroes/m1_stage_head_to_head_9x16.webp';
  static const String stageChampionshipBelts = 'assets/images/heroes/m1_stage_championship_belts_9x16.webp';
  static const String stageRankings          = 'assets/images/heroes/m1_stage_rankings_9x16.webp';
  static const String stageReferee           = 'assets/images/heroes/m1_stage_referee_9x16.webp';
  static const String stageAdminGovernance   = 'assets/images/heroes/m1_stage_admin_governance_9x16.webp';
  static const String stageTeams             = 'assets/images/heroes/m1_stage_teams_9x16.webp';
  static const String stageVenues            = 'assets/images/heroes/m1_stage_venues_9x16.webp';
  static const String stageDiscover          = 'assets/images/heroes/m1_stage_discover_9x16.webp';
  static const String stagePassportVault     = 'assets/images/heroes/m1_stage_passport_vault_9x16.webp';
  static const String stageAuthWalkout       = 'assets/images/heroes/m1_stage_auth_walkout_9x16.webp';
  static const String stageCommunity         = 'assets/images/heroes/m1_stage_community_9x16.webp';

  // ===========================================================================
  // TIER 3: EMPTY-STATE CARDS, VIDEO FALLBACKS & 1:1 AVATARS (v3 Bundle)
  // ===========================================================================
  static const String cardStandbyTable     = 'assets/images/heroes/m1_card_standby_table.webp';
  static const String cardLiveBroadcast    = 'assets/images/heroes/m1_card_live_broadcast.webp';
  static const String clipFallbackSparring = 'assets/images/defaults/clip_fallback_sparring.webp';
  static const String clipFallbackMatch    = 'assets/images/defaults/clip_fallback_match.webp';
  static const String avatarNeutralDark    = 'assets/images/defaults/avatar_neutral_dark.webp';
  static const String teamCrestDefault     = 'assets/images/defaults/team_crest_default.webp';

  // ===========================================================================
  // TIER 0-3 CANONICAL 28-ASSET VOID SUITE
  // ===========================================================================
  static const List<String> allTieredWebpAssets = [
    athleteDashboardHero,
    arenaRadarCard,
    supermatchVsCard,
    welcomeGripHero,
    tournamentPoster,
    bentoVenues,
    bentoPickupSparring,
    bentoCommunityFeed,
    bentoEloRankings,
    stageArena,
    stageTrainingLab,
    stageHeadToHead,
    stageChampionshipBelts,
    stageRankings,
    stageReferee,
    stageAdminGovernance,
    stageTeams,
    stageVenues,
    stageDiscover,
    stagePassportVault,
    stageAuthWalkout,
    stageCommunity,
    cardStandbyTable,
    cardLiveBroadcast,
    clipFallbackSparring,
    clipFallbackMatch,
    avatarNeutralDark,
    teamCrestDefault,
  ];

  // ===========================================================================
  // FOCAL ALIGNMENT PRESETS (Protects UI Safe Zones)
  // ===========================================================================
  static const Alignment stageTopFocal     = Alignment(0.0, -0.50);
  static const Alignment walkoutFocal      = Alignment(0.0, -0.35);
  static const Alignment cardRightFocal    = Alignment(0.35, 0.0);
  static const Alignment clipCenterFocal   = Alignment.center;

  /// Resolves the appropriate `.webp` fallback thumbnail for a video clip by enum category.
  static String clipFallbackForCategory(ClipCategory category) {
    switch (category) {
      case ClipCategory.sparring:
      case ClipCategory.technique:
        return clipFallbackSparring;
      case ClipCategory.tournament:
      case ClipCategory.supermatch:
      case ClipCategory.match:
        return clipFallbackMatch;
    }
  }

  /// Resolves the appropriate `.webp` fallback thumbnail from a raw category string.
  static String resolveClipFallback(String? rawCategory) {
    final normalized = (rawCategory ?? '').trim().toUpperCase();
    if (normalized.contains('TOURNAMENT') ||
        normalized.contains('SUPERMATCH') ||
        normalized.contains('MATCH') ||
        normalized.contains('CHAMPIONSHIP') ||
        normalized.contains('HIGHLIGHT')) {
      return clipFallbackMatch;
    }
    return clipFallbackSparring;
  }

  // ===========================================================================
  // BACKWARDS COMPATIBILITY ALIASES
  // ===========================================================================
  static const String heroAthleteDashboard = athleteDashboardHero;
  static const String cardArenaRadar       = arenaRadarCard;
  static const String cardSupermatchVs     = supermatchVsCard;
  static const String heroWelcomeGrip      = welcomeGripHero;
  static const String stageArena9x16       = stageArena;
  static const String stageTrainingLab9x16 = stageTrainingLab;

  static const String semanticProfileAthleteDashboardHero = athleteDashboardHero;
  static const String semanticArenaHomeRadarCard          = arenaRadarCard;
  static const String semanticArenaHomeSupermatchCard     = supermatchVsCard;
  static const String semanticDiscoverHubVenuesTile       = bentoVenues;
  static const String semanticDiscoverHubPickupMeetupsTile = bentoPickupSparring;
  static const String semanticDiscoverHubCommunityFeedTile  = bentoCommunityFeed;
  static const String semanticDiscoverHubEloRankingsTile  = bentoEloRankings;
  static const String semanticEventsTournamentDetailHero  = tournamentPoster;
  static const String semanticAuthWelcomeHeroBanner       = welcomeGripHero;
  static const String semanticArenaHomeBackground         = stageArena;
  static const String semanticTrainingLogBackground       = stageTrainingLab;

  /// Semantic slot resolver for dynamic asset bindings
  static String resolveSemanticAsset(
    String? slotId, {
    String fallback = '',
  }) {
    if (slotId == null || slotId.trim().isEmpty) return fallback;
    final trimmed = slotId.trim();
    switch (trimmed) {
      case 'profile.athlete.dashboard_hero':
        return athleteDashboardHero;
      case 'arena.home.radar_card':
        return arenaRadarCard;
      case 'arena.home.supermatch_card':
        return supermatchVsCard;
      case 'discover.hub.venues_tile':
        return bentoVenues;
      case 'discover.hub.pickup_meetups_tile':
      case 'discover.hub.pickup_tile':
        return bentoPickupSparring;
      case 'discover.hub.community_feed_tile':
      case 'discover.hub.community_tile':
        return bentoCommunityFeed;
      case 'discover.hub.elo_rankings_tile':
      case 'discover.hub.rankings_tile':
        return bentoEloRankings;
      case 'events.tournament.detail_hero':
        return fallback.isNotEmpty ? fallback : defaultTournament;
      case 'auth.welcome.hero_banner':
        return welcomeGripHero;
      case 'arena.home.background':
        return stageArena;
      case 'training.log.background':
        return stageTrainingLab;
      default:
        if (trimmed.endsWith('.png')) {
          final candidate = trimmed.replaceFirst('.png', '.webp');
          return candidate;
        }
        return fallback.isNotEmpty ? fallback : trimmed;
    }
  }

  // ===========================================================================
  // M0: System & Brand Core (assets/images/brand/)
  // ===========================================================================
  static const String logoFull       = 'assets/images/brand/m0_logo_full.webp';
  static const String iconGold       = 'assets/images/brand/m0_icon_gold.webp';
  static const String sealFederation = 'assets/images/brand/m0_seal_fed.webp';

  // ===========================================================================
  // M1: Bundled Textures & Canonical Hero Backdrops
  // ===========================================================================
  static const String texKnurl   = 'assets/images/textures/m1_tex_knurl.webp';
  static const String texChalk   = 'assets/images/textures/m1_tex_chalk.webp';
  static const String heroArena  = 'assets/images/heroes/m1_hero_arena.webp';
  static const String heroGrip   = 'assets/images/heroes/m1_hero_grip.webp';

  // ===========================================================================
  // M4: Division Badges & Referee Certification Insignia (assets/images/badges/)
  // ===========================================================================
  static const String badgeHeavyweight = 'assets/images/badges/m4_bdg_heavy.webp';
  static const String badgeMiddleweight = 'assets/images/badges/m4_bdg_middle.webp';
  static const String badgeLightweight  = 'assets/images/badges/m4_bdg_light.webp';
  static const String badgeJunior       = 'assets/images/badges/m4_bdg_junior.webp';
  static const String badgeMasters      = 'assets/images/badges/m4_bdg_masters.webp';
  static const String refMaster         = 'assets/images/badges/m4_ref_master.webp';
  static const String refNational       = 'assets/images/badges/m4_ref_nat.webp';
  static const String refRegional       = 'assets/images/badges/m4_ref_reg.webp';

  /// Concise canonical aliases matching physical asset short filenames
  static const String sealFed     = sealFederation;
  static const String badgeHeavy  = badgeHeavyweight;
  static const String badgeMiddle = badgeMiddleweight;
  static const String badgeLight  = badgeLightweight;
  static const String refNat      = refNational;
  static const String refReg      = refRegional;

  // ===========================================================================
  // Level 2 Fallbacks & System Defaults (assets/images/defaults/)
  // ===========================================================================
  static const String defaultAvatar     = avatarNeutralDark;
  static const String defaultTournament = tournamentPoster;
  static const String defaultClub       = 'assets/images/defaults/club_banner.webp';

  // ===========================================================================
  // M6: Audio Sensory Pack (assets/sounds/)
  // ===========================================================================
  static const String soundChallengeAccepted = 'assets/sounds/challenge_accepted.wav';
  static const String soundMatchWon          = 'assets/sounds/match_won.mp3';
  static const String soundPRAchieved        = 'assets/sounds/pr_achieved.wav';
}
