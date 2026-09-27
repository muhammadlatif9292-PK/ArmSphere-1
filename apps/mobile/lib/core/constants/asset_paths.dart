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
