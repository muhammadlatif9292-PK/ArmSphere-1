import 'package:flutter/widgets.dart';

/// Clip categories used to resolve category-specific video thumbnail fallbacks.
enum ClipCategory {
  sparring,
  technique,
  tournament,
  supermatch,
  match,
}

/// Authoritative ArmSphere 28-Asset Canonical Registry & Semantic Resolver
///
/// Exclusively binds the 28 hand-crafted `.webp` artworks across:
/// - `assets/images/heroes/` (Core Heroes, Cards, and 9:16 Domain Stages)
/// - `assets/images/bento/` (Discover Hub 2x2 Asymmetric Bento Mosaic)
/// - `assets/images/defaults/` (Tournament Poster, Clip Fallbacks, Avatar & Crest)
abstract final class ArmSphereAssets {
  // ---------------------------------------------------------------------------
  // Focal Alignment Presets
  // ---------------------------------------------------------------------------

  /// Top-weighted stage focal preset (0.0, -0.50) for 9:16 stages and Arena Radar
  static const Alignment stageTopFocal = Alignment(0.0, -0.50);

  /// Walkout & Welcome grip focal preset (0.0, -0.35)
  static const Alignment walkoutFocal = Alignment(0.0, -0.35);

  /// Right-weighted athlete silhouette focal preset (0.35, 0.0) for Athlete Dashboard Hero
  static const Alignment cardRightFocal = Alignment(0.35, 0.0);

  /// Tournament detail poster header focal preset (0.0, -0.20)
  static const Alignment posterTopFocal = Alignment(0.0, -0.20);

  /// Bento ELO Rankings trophy focal preset (0.0, -0.50)
  static const Alignment bentoRankingsFocal = Alignment(0.0, -0.50);

  // ---------------------------------------------------------------------------
  // A. Core Heroes & Onboarding Headers (5 Assets)
  // ---------------------------------------------------------------------------

  /// 1. Athlete Dashboard Hero Banner (16:9 / 210dp, cardRightFocal)
  static const String heroAthleteDashboard =
      'assets/images/heroes/m1_hero_athlete_dashboard.webp';

  /// 2. Arena Radar Live Match Card (16:9 / 170dp, stageTopFocal)
  static const String cardArenaRadar =
      'assets/images/heroes/m1_card_arena_radar.webp';

  /// 3. Supermatch VS Bout Card (16:9 / 185dp, Alignment.center)
  static const String cardSupermatchVs =
      'assets/images/heroes/m1_card_supermatch_vs.webp';
  static const String supermatchVsCard = cardSupermatchVs;

  /// 4. Welcome / Onboarding Screen Grip Hero (Top 42% viewport, walkoutFocal)
  static const String heroWelcomeGrip =
      'assets/images/heroes/m1_hero_welcome_grip.webp';

  /// 5. Tournament Detail Header Banner (16:9 / 220dp, posterTopFocal)
  static const String tournamentPoster =
      'assets/images/defaults/tournament_poster.webp';

  // ---------------------------------------------------------------------------
  // B. Discover Hub Bento Grid — 2x2 Asymmetric Mosaic (4 Assets)
  // ---------------------------------------------------------------------------

  /// 6. Venues & Gym Directory (1.1x Span Bento Card, Alignment.center)
  static const String bentoVenues =
      'assets/images/bento/m1_bento_venues.webp';

  /// 7. Pickup Sparring & Meetups (Standard Bento Card, Alignment.center)
  static const String bentoPickupSparring =
      'assets/images/bento/m1_bento_pickup_sparring.webp';

  /// 8. Community Stories & Media (Standard Bento Card, Alignment.center)
  static const String bentoCommunityFeed =
      'assets/images/bento/m1_bento_community_feed.webp';

  /// 9. Global ELO Leaderboards (1.1x Span Bento Card, bentoRankingsFocal)
  static const String bentoEloRankings =
      'assets/images/bento/m1_bento_elo_rankings.webp';

  // ---------------------------------------------------------------------------
  // C. Full-Bleed 9:16 Domain Stage Backdrops — VoidStageScaffold (13 Assets)
  // ---------------------------------------------------------------------------

  /// 10. Main Arena & Live Tables (stageTopFocal)
  static const String stageArena9x16 =
      'assets/images/heroes/m1_stage_arena_9x16.webp';

  /// 11. Training Log, PR Vault & Workout Analytics (stageTopFocal)
  static const String stageTrainingLab9x16 =
      'assets/images/heroes/m1_stage_training_lab_9x16.webp';

  /// 12. Athlete H2H Comparison & Tale of the Tape (Alignment.topCenter)
  static const String stageHeadToHead9x16 =
      'assets/images/heroes/m1_stage_rankings_9x16.webp';

  /// 13. Tournament Awards & Ceremony Screen (stageTopFocal)
  static const String stageChampionshipBelts9x16 =
      'assets/images/heroes/m1_stage_referee_9x16.webp';

  /// 14. Global Leaderboards & Tier Ladders (stageTopFocal)
  static const String stageRankings9x16 =
      'assets/images/heroes/m1_stage_admin_governance_9x16.webp';

  /// 15. Referee Match Controller & Official Scorepad (walkoutFocal)
  static const String stageReferee9x16 =
      'assets/images/heroes/m1_stage_teams_9x16.webp';

  /// 16. Federation Governance, Dispute Logs & Roster (stageTopFocal)
  static const String stageAdminGovernance9x16 =
      'assets/images/heroes/m1_stage_venues_9x16.webp';

  /// 17. Team Directory & Club Roster Hub (stageTopFocal)
  static const String stageTeams9x16 =
      'assets/images/heroes/m1_stage_discover_9x16.webp';

  /// 18. Venue & Table Locator (stageTopFocal)
  static const String stageVenues9x16 =
      'assets/images/heroes/m1_stage_passport_vault_9x16.webp';

  /// 19. Discover Screen Custom Scroll Canvas (stageTopFocal)
  static const String stageDiscover9x16 =
      'assets/images/heroes/m1_stage_auth_walkout_9x16.webp';

  /// 20. Athlete Passport & Biometric Security Screen (stageTopFocal)
  static const String stagePassportVault9x16 =
      'assets/images/heroes/m1_stage_community_9x16.webp';

  /// 21. Login, Register, MFA & Password Screens (walkoutFocal)
  static const String stageAuthWalkout9x16 =
      'assets/images/heroes/m1_stage_auth_walkout_9x16.webp';

  /// 22. Community Social Feed & Media Hub (stageTopFocal)
  static const String stageCommunity9x16 =
      'assets/images/heroes/m1_stage_community_9x16.webp';

  // ---------------------------------------------------------------------------
  // D. System Fallbacks, Emblems & Standby States (6 Assets)
  // ---------------------------------------------------------------------------

  /// 23. Standby Arena Table Card (empty match queues and offline tables)
  static const String cardStandbyTable =
      'assets/images/heroes/m1_card_standby_table.webp';

  /// 24. Live Stream Standby Banner (before broadcast commences)
  static const String cardLiveBroadcast =
      'assets/images/heroes/m1_card_live_broadcast.webp';

  /// 25. Video Thumbnail Placeholder for Sparring & Technical Breakdowns
  static const String clipFallbackSparring =
      'assets/images/defaults/clip_fallback_sparring.webp';

  /// 26. Video Thumbnail Placeholder for Official Sanctioned Matches
  static const String clipFallbackMatch =
      'assets/images/defaults/clip_fallback_match.webp';

  /// 27. High-Contrast Neutral Athlete Silhouette Avatar Default
  static const String avatarNeutralDark =
      'assets/images/defaults/avatar_neutral_dark.webp';

  /// 28. Forged Steel and Crimson Crest for Clubs Without Custom Emblems
  static const String teamCrestDefault =
      'assets/images/defaults/team_crest_default.webp';

  // ---------------------------------------------------------------------------
  // Complete 28-Asset Canonical Inventory
  // ---------------------------------------------------------------------------
  static const List<String> canonical28Assets = [
    heroAthleteDashboard,
    cardArenaRadar,
    cardSupermatchVs,
    heroWelcomeGrip,
    tournamentPoster,
    bentoVenues,
    bentoPickupSparring,
    bentoCommunityFeed,
    bentoEloRankings,
    'assets/images/heroes/m1_stage_arena_9x16.webp',
    'assets/images/heroes/m1_stage_training_lab_9x16.webp',
    'assets/images/heroes/m1_stage_head_to_head_9x16.webp',
    'assets/images/heroes/m1_stage_championship_belts_9x16.webp',
    'assets/images/heroes/m1_stage_rankings_9x16.webp',
    'assets/images/heroes/m1_stage_referee_9x16.webp',
    'assets/images/heroes/m1_stage_admin_governance_9x16.webp',
    'assets/images/heroes/m1_stage_teams_9x16.webp',
    'assets/images/heroes/m1_stage_venues_9x16.webp',
    'assets/images/heroes/m1_stage_discover_9x16.webp',
    'assets/images/heroes/m1_stage_passport_vault_9x16.webp',
    'assets/images/heroes/m1_stage_auth_walkout_9x16.webp',
    'assets/images/heroes/m1_stage_community_9x16.webp',
    cardStandbyTable,
    cardLiveBroadcast,
    clipFallbackSparring,
    clipFallbackMatch,
    avatarNeutralDark,
    teamCrestDefault,
  ];

  /// Backward-compatible alias for canonical28Assets
  static const List<String> allTieredWebpAssets = canonical28Assets;

  /// Video clip center focal alignment
  static const Alignment clipCenterFocal = Alignment.center;

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

  // ---------------------------------------------------------------------------
  // Semantic Slot Resolution Engine
  // ---------------------------------------------------------------------------
  /// Resolves a semantic slot identifier or legacy asset path to one of the canonical assets.
  static String resolveSemanticAsset(
    String? slotId, {
    String fallback = '',
  }) {
    if (slotId == null || slotId.trim().isEmpty) return fallback;
    final trimmed = slotId.trim();
    switch (trimmed) {
      case 'profile.athlete.dashboard_hero':
      case 'arena.home.hero':
        return heroAthleteDashboard;
      case 'arena.home.radar_card':
        return cardArenaRadar;
      case 'arena.home.supermatch_card':
        return cardSupermatchVs;
      case 'arena.standby.table':
        return cardStandbyTable;
      case 'arena.live.broadcast':
        return cardLiveBroadcast;
      case 'discover.hub.venues_tile':
      case 'discover.bento.venues':
        return bentoVenues;
      case 'discover.hub.pickup_meetups_tile':
      case 'discover.hub.pickup_tile':
      case 'discover.bento.sparring':
        return bentoPickupSparring;
      case 'discover.hub.community_feed_tile':
      case 'discover.hub.community_tile':
      case 'discover.bento.community':
        return bentoCommunityFeed;
      case 'discover.hub.elo_rankings_tile':
      case 'discover.hub.rankings_tile':
      case 'discover.bento.rankings':
        return bentoEloRankings;
      case 'events.tournament.detail_hero':
      case 'tournament.detail.poster':
        return fallback.isNotEmpty ? fallback : defaultTournament;
      case 'auth.welcome.hero_banner':
      case 'auth.welcome.hero':
        return heroWelcomeGrip;
      case 'auth.stage.walkout':
        return stageAuthWalkout9x16;
      case 'arena.home.background':
      case 'stage.arena':
        return stageArena9x16;
      case 'training.log.background':
      case 'stage.training':
        return stageTrainingLab9x16;
      case 'stage.h2h':
        return stageHeadToHead9x16;
      case 'stage.championship':
        return stageChampionshipBelts9x16;
      case 'stage.rankings':
        return stageRankings9x16;
      case 'stage.referee':
        return stageReferee9x16;
      case 'stage.governance':
        return stageAdminGovernance9x16;
      case 'stage.teams':
        return stageTeams9x16;
      case 'stage.venues':
        return stageVenues9x16;
      case 'stage.discover':
        return stageDiscover9x16;
      case 'stage.passport':
        return stagePassportVault9x16;
      case 'stage.community':
        return stageCommunity9x16;
      case 'clip.fallback.sparring':
        return clipFallbackSparring;
      case 'clip.fallback.match':
        return clipFallbackMatch;
      case 'avatar.default':
        return avatarNeutralDark;
      case 'team.crest.default':
        return teamCrestDefault;
      default:
        if (trimmed.endsWith('.png')) {
          final candidate = trimmed.replaceFirst('.png', '.webp');
          return candidate;
        }
        return fallback.isNotEmpty ? fallback : trimmed;
    }
  }

  // ---------------------------------------------------------------------------
  // Canonical Compatibility Aliases (Mapped Strictly to the 28 Assets)
  // ---------------------------------------------------------------------------
  static const String welcomeGripHero = heroWelcomeGrip;
  static const String athleteDashboardHero = heroAthleteDashboard;
  static const String arenaRadarCard = cardArenaRadar;

  // Semantic Canonical Constants (Used by Visual Preferences & Tests)
  static const String semanticProfileAthleteDashboardHero = heroAthleteDashboard;
  static const String semanticArenaHomeRadarCard          = cardArenaRadar;
  static const String semanticArenaHomeSupermatchCard     = cardSupermatchVs;
  static const String semanticDiscoverHubVenuesTile       = bentoVenues;
  static const String semanticDiscoverHubPickupMeetupsTile = bentoPickupSparring;
  static const String semanticDiscoverHubCommunityFeedTile = bentoCommunityFeed;
  static const String semanticDiscoverHubEloRankingsTile  = bentoEloRankings;
  static const String semanticEventsTournamentDetailHero  = tournamentPoster;
  static const String semanticAuthWelcomeHeroBanner       = heroWelcomeGrip;
  static const String semanticArenaHomeBackground         = stageArena9x16;
  static const String semanticTrainingLogBackground       = stageTrainingLab9x16;

  static const String stageAuthWalkout = stageAuthWalkout9x16;
  static const String stageDiscover = stageDiscover9x16;
  static const String stageRankings = stageRankings9x16;
  static const String stageArena = stageArena9x16;
  static const String stageTrainingLab = stageTrainingLab9x16;
  static const String stageCommunity = stageCommunity9x16;
  static const String stageVenues = stageVenues9x16;
  static const String stageTeams = stageTeams9x16;
  static const String stageHeadToHead = stageHeadToHead9x16;
  static const String stageChampionshipBelts = stageChampionshipBelts9x16;
  static const String stageReferee = stageReferee9x16;
  static const String stageAdminGovernance = stageAdminGovernance9x16;
  static const String stagePassportVault = stagePassportVault9x16;

  static const String defaultAvatar = avatarNeutralDark;
  static const String defaultTournament = tournamentPoster;
  static const String defaultClub = teamCrestDefault;

  // ===========================================================================
  // M0: System & Brand Core (assets/images/brand/)
  // ===========================================================================
  static const String logoFull       = 'assets/images/brand/m0_logo_full.webp';
  static const String iconGold       = 'assets/images/brand/m0_icon_gold.webp';
  static const String sealFederation = 'assets/images/brand/m0_seal_fed.webp';

  // ===========================================================================
  // M1: Legacy Compatibility Constants (Remapped to Canonical 28 Assets)
  // ===========================================================================
  static const String texKnurl   = stageArena9x16;
  static const String texChalk   = stageArena9x16;
  static const String heroArena  = stageArena9x16;
  static const String heroGrip   = heroWelcomeGrip;

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

  // ---------------------------------------------------------------------------
  // M6: Audio Sensory Pack (assets/sounds/)
  // ---------------------------------------------------------------------------
  static const String soundChallengeAccepted =
      'assets/sounds/challenge_accepted.wav';
  static const String soundMatchWon = 'assets/sounds/match_won.mp3';
  static const String soundPRAchieved = 'assets/sounds/pr_achieved.wav';
}
