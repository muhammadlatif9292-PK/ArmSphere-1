/// Authoritative ArmSphere Media & Asset Path Registry
///
/// Compile-safe constants for all canonically approved assets defined in:
/// - `docs/design/46_MASTER_MEDIA_ASSET_MAP.md`
/// - `docs/design/50_MEDIA_INTEGRATION_SPEC.md`
/// - `docs/design/70_FINAL_VISUAL_MEDIA_DECISION_MAP.md`
///
/// Organizes assets according to the M0–M7 Media Classification Taxonomy.
abstract final class ArmSphereAssets {
  // ---------------------------------------------------------------------------
  // M0: System & Brand Core (Shipped in APK: assets/images/brand/)
  // ---------------------------------------------------------------------------

  /// Master Monogram + Logotype in Champagne Gold (4:1 ratio)
  static const String logoFull = 'assets/images/brand/m0_logo_full.webp';

  /// Embossed Gold Grip & Anvil App Icon (1:1 ratio)
  static const String iconGold = 'assets/images/brand/m0_icon_gold.webp';

  /// Official Federation Holographic Watermark / Seal (1:1 ratio)
  static const String sealFederation = 'assets/images/brand/m0_seal_fed.webp';

  // ---------------------------------------------------------------------------
  // M1: Bundled Textures & Hero Backgrounds (assets/images/textures/, assets/images/heroes/)
  // ---------------------------------------------------------------------------

  /// Seamless Dark Knurled Steel Grid Pattern (1:1 tileable)
  static const String texKnurl = 'assets/images/textures/m1_tex_knurl.webp';

  /// Subtle Arena Chalk Dust & Atmospheric Vignette (9:16 ratio)
  static const String texChalk = 'assets/images/textures/m1_tex_chalk.webp';

  /// Championship Stage Lighting & Dual Podiums Hero (16:9 ratio)
  static const String heroArena = 'assets/images/heroes/m1_hero_arena.webp';

  /// Macro Forearm Clash, Knuckles & Chalk Smoke (16:9 ratio)
  static const String heroGrip = 'assets/images/heroes/m1_hero_grip.webp';

  /// Shadowed Athlete in Crimson Smoke — Default Athlete Dashboard Hero (16:9 ratio)
  static const String heroAthleteDashboard =
      'assets/images/heroes/m1_hero_athlete_dashboard.webp';

  /// Sanctioned Arena Radar Card — Spotlighted Competition Table & Jumbotron (21:9 ratio, 1920x820)
  static const String cardArenaRadar =
      'assets/images/heroes/m1_card_arena_radar.webp';

  /// Upcoming Supermatch Card — Split Red/Blue Corner Table & Referee Strap (16:9 ratio)
  static const String cardSupermatchVs =
      'assets/images/heroes/m1_card_supermatch_vs.webp';

  /// Discover Federation Hub Bento Tile 1 — Training Venues & Club Directory (4:3 ratio)
  static const String bentoVenues =
      'assets/images/heroes/m1_bento_venues.webp';

  /// Discover Federation Hub Bento Tile 2 — Pickup Meetups & Sparring (4:3 ratio)
  static const String bentoPickupSparring =
      'assets/images/heroes/m1_bento_pickup_sparring.webp';

  /// Discover Federation Hub Bento Tile 3 — Community Feed & Technique Clips (4:3 ratio)
  static const String bentoCommunityFeed =
      'assets/images/heroes/m1_bento_community_feed.webp';

  /// Discover Federation Hub Bento Tile 4 — ELO Rankings & Championship Standings (4:3 ratio)
  static const String bentoEloRankings =
      'assets/images/heroes/m1_bento_elo_rankings.webp';

  /// Welcome Screen Hero Banner — Macro Chalked Forearm Lockup Over Void (16:9 ratio)
  static const String heroWelcomeGrip =
      'assets/images/heroes/m1_hero_welcome_grip.webp';

  /// Full-Screen 9:16 Stage Backdrop — Main Championship Arena Canopy & Floor
  static const String stageArena9x16 =
      'assets/images/heroes/m1_stage_arena_9x16.webp';

  /// Full-Screen 9:16 Stage Backdrop — Strength & Performance Lab (Table Pulley & Wrist Wrench)
  static const String stageTrainingLab9x16 =
      'assets/images/heroes/m1_stage_training_lab_9x16.webp';

  // ---------------------------------------------------------------------------
  // Canonical Semantic Asset Identifiers
  // ---------------------------------------------------------------------------

  static const String semanticProfileAthleteDashboardHero =
      'profile.athlete.dashboard_hero';
  static const String semanticArenaHomeRadarCard = 'arena.home.radar_card';
  static const String semanticArenaHomeSupermatchCard =
      'arena.home.supermatch_card';
  static const String semanticDiscoverHubVenuesTile =
      'discover.hub.venues_tile';
  static const String semanticDiscoverHubPickupMeetupsTile =
      'discover.hub.pickup_meetups_tile';
  static const String semanticDiscoverHubCommunityFeedTile =
      'discover.hub.community_feed_tile';
  static const String semanticDiscoverHubEloRankingsTile =
      'discover.hub.elo_rankings_tile';
  static const String semanticEventsTournamentDetailHero =
      'events.tournament.detail_hero';
  static const String semanticAuthWelcomeHeroBanner =
      'auth.welcome.hero_banner';
  static const String semanticArenaHomeBackground = 'arena.home.background';
  static const String semanticTrainingLogBackground = 'training.log.background';

  /// Semantic Asset Catalog mapping logical slot IDs to bundled default assets.
  static const Map<String, String> semanticCatalog = {
    'profile.athlete.dashboard_hero': heroAthleteDashboard,
    'arena.home.radar_card': cardArenaRadar,
    'arena.home.supermatch_card': cardSupermatchVs,
    'discover.hub.venues_tile': bentoVenues,
    'discover.hub.pickup_meetups_tile': bentoPickupSparring,
    'discover.hub.community_feed_tile': bentoCommunityFeed,
    'discover.hub.elo_rankings_tile': bentoEloRankings,
    'events.tournament.detail_hero': defaultTournament,
    'auth.welcome.hero_banner': heroWelcomeGrip,
    'arena.home.background': stageArena9x16,
    'training.log.background': stageTrainingLab9x16,
  };

  /// Normalizes legacy `.png` hero paths to `.webp` and resolves semantic asset
  /// identifiers (such as `profile.athlete.dashboard_hero`) to their registered
  /// asset path, or returns [keyOrPath] unchanged if it is already a direct
  /// asset path, network URL, or data URI.
  static String resolveSemanticAsset(
    String? keyOrPath, {
    String fallback = heroAthleteDashboard,
  }) {
    if (keyOrPath == null) return fallback;
    final trimmed = keyOrPath.trim();
    if (trimmed.isEmpty) return fallback;
    if (trimmed.endsWith('m1_hero_athlete_dashboard.png')) {
      return heroAthleteDashboard;
    }
    return semanticCatalog[trimmed] ?? trimmed;
  }

  // ---------------------------------------------------------------------------
  // M4: Division Badges & Referee Certification Insignia (assets/images/badges/)
  // ---------------------------------------------------------------------------

  /// Super Heavyweight (110kg+) - Titanium Anvil Emblem
  static const String badgeHeavyweight = 'assets/images/badges/m4_bdg_heavy.webp';

  /// Middleweight (86-105kg) - Forged Steel Shield Emblem
  static const String badgeMiddleweight = 'assets/images/badges/m4_bdg_middle.webp';

  /// Lightweight (-85kg) - Tempered Blade Emblem
  static const String badgeLightweight = 'assets/images/badges/m4_bdg_light.webp';

  /// Junior / Youth Division - Bronze Wing Emblem
  static const String badgeJunior = 'assets/images/badges/m4_bdg_junior.webp';

  /// Masters Division (40+) - Gold Laurel Emblem
  static const String badgeMasters = 'assets/images/badges/m4_bdg_masters.webp';

  /// Master International Referee - Gold Compass & Whistle
  static const String refMaster = 'assets/images/badges/m4_ref_master.webp';

  /// Senior National Referee - Polished Silver Compass
  static const String refNational = 'assets/images/badges/m4_ref_nat.webp';

  /// Certified Regional Referee - Gunmetal Steel Shield
  static const String refRegional = 'assets/images/badges/m4_ref_reg.webp';

  /// Concise canonical aliases matching physical asset short filenames
  static const String sealFed = sealFederation;
  static const String badgeHeavy = badgeHeavyweight;
  static const String badgeMiddle = badgeMiddleweight;
  static const String badgeLight = badgeLightweight;
  static const String refNat = refNational;
  static const String refReg = refRegional;

  // ---------------------------------------------------------------------------
  // Level 2 Fallbacks & System Defaults (assets/images/defaults/)
  // ---------------------------------------------------------------------------

  /// Neutral dark athlete silhouette avatar fallback
  static const String defaultAvatar = 'assets/images/defaults/avatar_neutral_dark.webp';

  /// Default tournament card poster fallback
  static const String defaultTournament = 'assets/images/defaults/tournament_poster.webp';

  /// Default club training banner fallback
  static const String defaultClub = 'assets/images/defaults/club_banner.webp';

  // ---------------------------------------------------------------------------
  // M6: Audio Sensory Pack (assets/sounds/)
  // ---------------------------------------------------------------------------

  /// Official challenge accepted sync audio (WAV)
  static const String soundChallengeAccepted = 'assets/sounds/challenge_accepted.wav';

  /// Match pin recorded & victory fanfare (MP3)
  static const String soundMatchWon = 'assets/sounds/match_won.mp3';

  /// Personal record locked into ledger audio (WAV)
  static const String soundPRAchieved = 'assets/sounds/pr_achieved.wav';
}
