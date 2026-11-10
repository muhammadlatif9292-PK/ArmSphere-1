# ArmSphere — Complete Existing Image Usage Audit & Image Replacement Blueprint

> **Document Purpose**: Authoritative code-verified audit of every existing image asset in the ArmSphere Flutter application (`apps/mobile/`), every distinct UI location where those images are displayed, and the complete creative and technical specification for replacing repeated placeholder imagery with purpose-designed artwork.
>
> **Companion Machine-Readable Register**: [`docs/armsphere_image_placement_register.json`](./armsphere_image_placement_register.json)

---

## Executive Summary & Key Metrics

| Metric | Count | Notes |
|---|---:|---|
| **Original Core Scene/Hero Images Reused Across the App** | **3** (+ **11** newly integrated dedicated WebP artworks) | Legacy shared images: `m1_hero_arena.webp`, `m1_hero_grip.webp`, `club_banner.webp` (plus 11 integrated WebP artworks across Tier 0, Tier 1, and Tier 2 stage backdrops). |
| **Total Bundled Image Files in `apps/mobile/assets/images/`** | **28** | 14 hero/banner/bento/stage scenes, 2 atmospheric textures (`m1_tex_chalk.webp`, `m1_tex_knurl.webp`), 1 default avatar (`avatar_neutral_dark.webp`), 3 brand emblems (`m0_icon_gold.webp`, `m0_logo_full.webp`, `m0_seal_fed.webp`), and 8 division/referee badges (`m4_bdg_*`, `m4_ref_*`). |
| **Total Distinct Image Placements Discovered** | **92** | 58 full-screen stage backdrops, 12 hero/feature cards & banners, 10 avatar/portrait slots, 4 atmospheric card texture overlays, and 8 brand/badge insignia placements. |
| **Unique Replacement Artworks Recommended** | **26** | **11 Integrated** (`profile.athlete.dashboard_hero`, `arena.home.radar_card`, `arena.home.supermatch_card`, `discover.hub.venues_tile`, `discover.hub.pickup_meetups_tile`, `discover.hub.community_feed_tile`, `discover.hub.elo_rankings_tile`, `events.tournament.detail_hero`, `auth.welcome.hero_banner`, `arena.home.background`, `training.log.background`), **15 Remaining**. |
| **Intentionally Shared Assets Recommended** | **15** | Sub-flows sharing their parent domain backdrop (e.g., Auth sub-screens, Settings sub-screens, Referee sub-screens), 2 shared textures (`texChalk`, `texKnurl`), 3 canonical brand seals, and 8 official division/referee badges. |
| **Unresolved Locations** | **0** | 100% of routes, shared scaffolds, and image widgets in `apps/mobile/lib/` have been traced and verified. |

---

## Part A — Existing Image Inventory

### A.1 The Core Reused Scene & Newly Integrated Hero/Bento/Stage Artworks

Historically, almost every background, card banner, and feature tile in ArmSphere was powered by **4 widescreen WebP images** (`m1_hero_arena.webp`, `m1_hero_grip.webp`, `tournament_poster.webp`, `club_banner.webp`). With the integration of the **11 approved WebP artworks** (including the upgraded `2752×1536` `tournament_poster.webp` and the conversion of `m1_hero_athlete_dashboard` from `.png` to `.webp`), the active scene/hero/stage inventory is:

| # | Constant in `ArmSphereAssets` | Exact Asset Path | Format | Dimensions & Aspect Ratio | File Size | MD5 Checksum | Primary Code References & Visual Transformation |
|---|---|---|---|---|---:|---|---|
| **1** | `ArmSphereAssets.heroArena` | `assets/images/heroes/m1_hero_arena.webp` | WEBP (VP8) | `1236 × 695` (`16:9`) | 50,550 B (49.4 KB) | `532beb4a73419044aca5a146b422a91b` | Referenced in `VisualPreferencesState` preset `titanium_knurl_vault` (used by `rankings`, `referee`, `governance`); `CommunityFeedScreen` (fallback for non-sparring video posts); and `ArmSphereImage.hero` default `fallbackAsset`. |
| **2** | `ArmSphereAssets.heroGrip` | `assets/images/heroes/m1_hero_grip.webp` | WEBP (VP8) | `1236 × 695` (`16:9`) | 130,908 B (127.8 KB) | `b84a5e3926e7409ba35250d3cff3d470` | Referenced in `VisualPreferencesState` preset `crimson_grip_clash` (used by `ArmSphereStageDomain.discover` & `passport`); `AmbientParticleBackground` (Tabs 1 & 4); `CommunityFeedScreen` (fallback for `SPARRING`/`TECHNIQUE` video posts); `CreatePostScreen` (media preview fallback); and `CrystalStageScaffold` (studio portrait preset button). |
| **3** | `ArmSphereAssets.defaultTournament` | `assets/images/defaults/tournament_poster.webp` | WEBP (VP8) | `2752 × 1536` (`16:9`) | 449,266 B (438.7 KB) | `7102750fd65cb74cdba8b1601a979d30` | **Upgraded & Integrated** (`events.tournament.detail_hero`): Referenced in `TournamentDetailScreen` (`SliverAppBar` parallax header with `Alignment(0.0, -0.20)` and `AppTheme.heroScrim()`); `VisualPreferencesState` preset `grand_prix_poster` (`ArmSphereStageDomain.events`); `AmbientParticleBackground` (Tab 2); and `ArmSphereImage` default fallback. |
| **4** | `ArmSphereAssets.defaultClub` | `assets/images/defaults/club_banner.webp` | WEBP (VP8) | `720 × 405` (`16:9`) | 45,410 B (44.3 KB) | `d61278a802b5082ad1b7125d762f8c3b` | Referenced in `VisualPreferencesState` preset `underground_iron_club` (used by `ArmSphereStageDomain.community` & `venues`) and `AmbientParticleBackground` (Tab 3). |
| **5** | `ArmSphereAssets.heroAthleteDashboard` | `assets/images/heroes/m1_hero_athlete_dashboard.webp` | WEBP (VP8) | `1672 × 941` (`16:9`) | 42,810 B (41.8 KB) | `4c2daaf931425047bb2bb470423931e0` | **Integrated** (`profile.athlete.dashboard_hero`): Default artwork on `AthleteDashboardScreen._buildAthleteCinematicBanner` (`opacity: 0.94`, focal alignment `Alignment(-0.55, -0.24)`). Replaces obsolete 1.32 MB `.png`. |
| **6** | `ArmSphereAssets.cardArenaRadar` | `assets/images/heroes/m1_card_arena_radar.webp` | WEBP (VP8) | `1920 × 820` (`21:9`) | 112,662 B (110.0 KB) | `9d07d82d77e1a23e2a9551abaa0ea0fb` | **Integrated** (`arena.home.radar_card`): Dedicated artwork on `AthleteDashboardScreen._buildSanctionedArenaRadar` (`BoxFit.cover`, `Alignment(0.45, 0.0)`, 4-stop horizontal readability scrim). |
| **7** | `ArmSphereAssets.cardSupermatchVs` | `assets/images/heroes/m1_card_supermatch_vs.webp` | WEBP (VP8) | `2752 × 1536` (`16:9`) | 414,914 B (405.2 KB) | `95d7e3986dc7855d558aa9db74f9d27d` | **Integrated** (`arena.home.supermatch_card`): Dedicated fight-stage artwork on `AthleteDashboardScreen._buildUpcomingSupermatchCard` (`BoxFit.cover`, `Alignment(0.0, 0.15)`, `opacity: 0.48`, top/bottom vignette). |
| **8** | `ArmSphereAssets.bentoVenues` | `assets/images/heroes/m1_bento_venues.webp` | WEBP (VP8) | `2752 × 1536` (`16:9`) | 650,090 B (634.9 KB) | `a8cbcba2bef9de1754995b6671ff5847` | **Integrated** (`discover.hub.venues_tile`): Dedicated Training Venues Bento tile artwork on `DiscoverScreen` (`BoxFit.cover`, `Alignment(0.35, 0.0)`, `opacity: 0.55`, bottom-left dark scrim). |
| **9** | `ArmSphereAssets.bentoPickupSparring` | `assets/images/heroes/m1_bento_pickup_sparring.webp` | WEBP (VP8) | `1200 × 896` (`4:3`) | 80,520 B (78.6 KB) | `f4009da50fa5a50e8a71ad1477fc3725` | **Integrated** (`discover.hub.pickup_meetups_tile`): Dedicated Pickup Meetups Bento tile artwork on `DiscoverScreen` (`BoxFit.cover`, `Alignment(0.30, -0.15)`, `opacity: 0.55`, bottom-left dark scrim). |
| **10** | `ArmSphereAssets.bentoCommunityFeed` | `assets/images/heroes/m1_bento_community_feed.webp` | WEBP (VP8) | `2400 × 1792` (`4:3`) | 294,896 B (288.0 KB) | `7d461b388b2f64eacbd87cb1f47d529f` | **Integrated** (`discover.hub.community_feed_tile`): Dedicated Community Feed Bento tile artwork on `DiscoverScreen` (`BoxFit.cover`, `Alignment(0.30, -0.15)`, `opacity: 0.55`, bottom-left dark scrim). |
| **11** | `ArmSphereAssets.bentoEloRankings` | `assets/images/heroes/m1_bento_elo_rankings.webp` | WEBP (VP8) | `2400 × 1792` (`4:3`) | 394,096 B (384.9 KB) | `3f05eed3eff225c968fd2e7b7fc05194` | **Integrated** (`discover.hub.elo_rankings_tile`): Dedicated ELO Rankings Bento tile artwork on `DiscoverScreen` (`BoxFit.cover`, `Alignment(0.35, -0.10)`, `opacity: 0.55`, bottom-left dark scrim). |
| **12** | `ArmSphereAssets.heroWelcomeGrip` | `assets/images/heroes/m1_hero_welcome_grip.webp` | WEBP (VP8) | `2752 × 1536` (`16:9`) | 313,156 B (305.8 KB) | `269811fbb518a5637e99ee33a50d8e06` | **Integrated** (`auth.welcome.hero_banner`): Dedicated top hero banner on `WelcomeScreen` (`BoxFit.cover`, `Alignment(0.0, -0.25)`, `opacity: 0.68`, 4-stop vertical fade into `#070A11`). |
| **13** | `ArmSphereAssets.stageArena9x16` | `assets/images/heroes/m1_stage_arena_9x16.webp` | WEBP (VP8) | `768 × 1376` (`9:16`) | 60,278 B (58.9 KB) | `1df5a096862bf4d6e166552338442cf6` | **Integrated** (`arena.home.background`): Default `9:16` full-screen stage backdrop for `ArmSphereStageDomain.arena` and `AmbientParticleBackground` Tab 0 (`BoxFit.cover`, `Alignment(0.0, -0.55)`, `opacity: 0.46`, + `m1_tex_chalk.webp`). |
| **14** | `ArmSphereAssets.stageTrainingLab9x16` | `assets/images/heroes/m1_stage_training_lab_9x16.webp` | WEBP (VP8) | `768 × 1376` (`9:16`) | 74,380 B (72.6 KB) | `ea0e913bfafefebee0f3fdecaf99a83b` | **Integrated** (`training.log.background`): Dedicated `9:16` full-screen stage backdrop for `ArmSphereStageDomain.training` on `TrainingLogScreen` (`BoxFit.cover`, `Alignment(0.0, -0.45)`, `opacity: 0.46`, + `m1_tex_chalk.webp`). |

---

### A.2 Atmospheric Textures, Default Avatar, Brand Seals & Insignia Badges (14 Assets)

| # | Constant in `ArmSphereAssets` | Exact Asset Path | Format | Dimensions & Aspect Ratio | File Size | Role & Visual Treatment |
|---|---|---|---|---|---:|---|
| **7** | `ArmSphereAssets.texChalk` | `assets/images/textures/m1_tex_chalk.webp` | WEBP (VP8) | `1080 × 1920` (`9:16`) | 92,234 B | Secondary atmospheric overlay in `CrystalStageBackdrop` (`opacity: 0.32`), `AmbientParticleBackground` (`opacity: 0.30`), and Athlete Dashboard cards (`opacity: 0.32–0.36`). |
| **8** | `ArmSphereAssets.texKnurl` | `assets/images/textures/m1_tex_knurl.webp` | WEBP (VP8) | `512 × 512` (`1:1`) | 45,598 B | Secondary machined-steel grid overlay in `CrystalStageBackdrop` (`opacity: 0.32`) for `community`, `venues`, `rankings`, `referee`, and `governance` domains. |
| **9** | `ArmSphereAssets.defaultAvatar` | `assets/images/defaults/avatar_neutral_dark.webp` | WEBP (VP8) | `256 × 256` (`1:1`) | 8,834 B | Level-2 fallback in `ArmSphereImage.avatar` across all athlete, opponent, ranking, podium, and comment avatars when `imageUrl` is null or offline. |
| **10** | `ArmSphereAssets.iconGold` | `assets/images/brand/m0_icon_gold.webp` | WEBP (VP8) | `512 × 512` (`1:1`) | 31,592 B | App crest emblem displayed in `SplashScreen` (`96×96`), `WelcomeScreen` (`68×68`), and `AthleteDashboardScreen._buildBrandHeader` (`36×36`). |
| **11** | `ArmSphereAssets.logoFull` | `assets/images/brand/m0_logo_full.webp` | WEBP (VP8) | `960 × 360` (`8:3`) | 28,160 B | Registered in `ArmSphereAssets.logoFull` (currently unused in active screen widgets). |
| **12** | `ArmSphereAssets.sealFederation` / `sealFed` | `assets/images/brand/m0_seal_fed.webp` | WEBP (VP8) | `384 × 384` (`1:1`) | 39,340 B | Official federation seal used in `RankingsScreen`, `HeadToHeadScreen`, `TournamentDetailScreen`, `TournamentAwardsCeremonyScreen`, `CommunityFeedScreen`, `CreatePostScreen`, and `PostCommentsScreen`. |
| **13** | `ArmSphereAssets.badgeHeavyweight` / `badgeHeavy` | `assets/images/badges/m4_bdg_heavy.webp` | WEBP (VP8) | `256 × 256` (`1:1`) | 7,140 B | Super Heavyweight (`95kg+` / `110kg+`) division badge in `PublicProfileScreen` and `AthleteDashboardScreen`. |
| **14** | `ArmSphereAssets.badgeMiddleweight` / `badgeMiddle` | `assets/images/badges/m4_bdg_middle.webp` | WEBP (VP8) | `256 × 256` (`1:1`) | 7,988 B | Middleweight (`75–94kg`) division badge in `PublicProfileScreen` and `AthleteDashboardScreen`. |
| **15** | `ArmSphereAssets.badgeLightweight` / `badgeLight` | `assets/images/badges/m4_bdg_light.webp` | WEBP (VP8) | `256 × 256` (`1:1`) | 7,808 B | Lightweight (`<75kg`) division badge in `PublicProfileScreen` and `AthleteDashboardScreen`. |
| **16** | `ArmSphereAssets.badgeJunior` | `assets/images/badges/m4_bdg_junior.webp` | WEBP (VP8) | `256 × 256` (`1:1`) | 8,370 B | Junior / Youth division badge in `PublicProfileScreen` and `AthleteDashboardScreen`. |
| **17** | `ArmSphereAssets.badgeMasters` | `assets/images/badges/m4_bdg_masters.webp` | WEBP (VP8) | `256 × 256` (`1:1`) | 9,156 B | Masters (`40+`) division badge in `PublicProfileScreen` and `AthleteDashboardScreen`. |
| **18** | `ArmSphereAssets.refMaster` | `assets/images/badges/m4_ref_master.webp` | WEBP (VP8) | `256 × 256` (`1:1`) | 8,554 B | Master International Referee certification badge (`AthleteProfileScreen`). |
| **19** | `ArmSphereAssets.refNational` / `refNat` | `assets/images/badges/m4_ref_nat.webp` | WEBP (VP8) | `256 × 256` (`1:1`) | 7,442 B | Senior National Referee certification badge (`AthleteProfileScreen`). |
| **20** | `ArmSphereAssets.refRegional` / `refReg` | `assets/images/badges/m4_ref_reg.webp` | WEBP (VP8) | `256 × 256` (`1:1`) | 6,572 B | Regional Referee certification badge (`AthleteProfileScreen`). |

---

## Part B — Complete Usage Map (Every Distinct Image Placement)

Crucial architectural discovery:
1. **`MainShellScreen` (`apps/mobile/lib/core/widgets/main_shell_screen.dart:599`)** renders `AmbientParticleBackground(tabIndex: effectiveTabIndex)` behind the root shell tabs (`0`: Arena, `1`: Discover, `2`: Events, `3`: Community, `4`: Passport).
2. **Individual Screens** also render `CrystalStageBackdrop(domain: ArmSphereStageDomain.<domain>)` (either directly in their `Scaffold.body` `Stack` or via `StickyFormScaffold`), which resolves to one of **only 4 images** in `VisualPreferencesState._defaultPresetForDomain`:
   - `ArmSphereStageDomain.arena` $\rightarrow$ `m1_hero_arena.webp` + `m1_tex_chalk.webp`
   - `ArmSphereStageDomain.discover` $\rightarrow$ `m1_hero_grip.webp` + `m1_tex_chalk.webp`
   - `ArmSphereStageDomain.passport` $\rightarrow$ `m1_hero_grip.webp` + `m1_tex_chalk.webp`
   - `ArmSphereStageDomain.events` $\rightarrow$ `tournament_poster.webp` + `m1_tex_chalk.webp`
   - `ArmSphereStageDomain.community` $\rightarrow$ `club_banner.webp` + `m1_tex_knurl.webp`
   - `ArmSphereStageDomain.venues` $\rightarrow$ `club_banner.webp` + `m1_tex_knurl.webp`
   - `ArmSphereStageDomain.rankings` $\rightarrow$ `m1_hero_arena.webp` + `m1_tex_knurl.webp`
   - `ArmSphereStageDomain.referee` $\rightarrow$ `m1_hero_arena.webp` + `m1_tex_knurl.webp`
   - `ArmSphereStageDomain.governance` $\rightarrow$ `m1_hero_arena.webp` + `m1_tex_knurl.webp`

Below is the complete, ungrouped inventory of every distinct image placement in the application.

### B.1 Hero Banners, Feature Cards & In-Screen Media Placements (16 Placements)

| Placement ID | Screen / Feature | Route | Widget / Method | Exact Source File & Line | Current Image Used | Visual Role & Applied Treatment |
|---|---|---|---|---|---|---|
| `auth.splash.brand_emblem` | Splash Screen | `/splash` | `SplashScreen.build` | `lib/features/auth/screens/splash_screen.dart:111` | `m0_icon_gold.webp` | Centered `96×96` rounded-24dp emblem container with gold border and radial glow. |
| `auth.welcome.hero_banner` | Welcome Screen | `/welcome` | `WelcomeScreen.build` | `lib/features/auth/screens/welcome_screen.dart:128` | `m1_hero_welcome_grip.webp` (**Generated & Integrated**) | Top `280dp` full-width header image (`BoxFit.cover`, `opacity: 0.68`, `Alignment(0.0, -0.25)`) under a 4-stop vertical dark fade into `#070A11`. |
| `auth.welcome.brand_emblem` | Welcome Screen | `/welcome` | `WelcomeScreen.build` | `lib/features/auth/screens/welcome_screen.dart:201` | `m0_icon_gold.webp` | Centered `68×68` rounded-18dp federation crest above "ENTER THE ARENA" headline. |
| `arena.home.brand_emblem` | Athlete Dashboard | `/athlete` | `_buildBrandHeader` | `lib/features/athlete/screens/athlete_screens.dart:426` | `m0_icon_gold.webp` | Top-left `36×36` rounded-10dp app bar emblem next to "ARMSPHERE" logotype. |
| `arena.home.radar_card` | Athlete Dashboard | `/athlete` | `_buildSanctionedArenaRadar` | `lib/features/athlete/screens/athlete_screens.dart:664` | `m1_card_arena_radar.webp` (**Generated & Integrated**) | Full-bleed background of the `minHeight: 96dp` "SANCTIONED ARENA RADAR" card (`BoxFit.cover`, `Alignment(0.45, 0.0)`, 4-stop horizontal readability scrim). |
| `profile.athlete.dashboard_hero` | Athlete Dashboard | `/athlete` | `_buildAthleteCinematicBanner` | `lib/features/athlete/screens/athlete_screens.dart:901` | `m1_hero_athlete_dashboard.webp` (**Generated & Integrated**) | Full-card integrated athlete identity composition (`BoxFit.cover`, `opacity: 0.94`, focal alignment `Alignment(-0.55, -0.24)`, adaptive left-to-right + bottom scrims). |
| `profile.athlete.dashboard_portrait` | Athlete Dashboard | `/athlete` | `_buildAthleteCinematicBanner` | `lib/features/athlete/screens/athlete_screens.dart:965` | User portrait or `avatar_neutral_dark.webp` fallback | Optional blended left-stage portrait subject (`widthFactor: 0.48`, `heightFactor: 0.88`, dual `ShaderMask` edge feathering) when a distinct portrait photo is uploaded. |
| `arena.home.supermatch_card` | Athlete Dashboard | `/athlete` | `_buildUpcomingSupermatchCard` | `lib/features/athlete/screens/athlete_screens.dart:2270` | `m1_card_supermatch_vs.webp` (**Generated & Integrated**) | Full-card internal fight-stage background (`opacity: 0.48`, `Alignment(0.0, 0.15)` + `texChalk` at `0.28` + red left / cyan right radial corner spotlights + top/bottom readability vignette). |
| `arena.home.no_bouts_card` | Athlete Dashboard | `/athlete` | `_buildNoUpcomingBoutsCard` | `lib/features/athlete/screens/athlete_screens.dart:2498` | `tournament_poster.webp` (+ `m1_tex_chalk.webp`) | Full-card background (`opacity: 0.18` + `texChalk` at `0.32` + heavy left-to-right dark scrim `0xE60B0F17 -> 0x990B0F17`) behind "ARENA SCHEDULE • NO UPCOMING BOUTS SCHEDULED". |
| `arena.home.intelligence_deck_texture` | Athlete Dashboard | `/athlete` | `_buildIntelligenceDeck` | `lib/features/athlete/screens/athlete_screens.dart:2649` | `m1_tex_chalk.webp` | Internal atmospheric particle texture (`opacity: 0.36`) inside the 3-tab Intelligence Deck container (Recent Bouts / Tournaments / Global Top 3). |
| `discover.hub.venues_tile` | Discover Screen | `/discover` | `_buildFederationHubSection` / `_buildBentoPortalTile` | `lib/features/home/screens/discover_screen.dart:944, 1038` | `m1_bento_venues.webp` (**Generated & Integrated**) | Top-left tile in the 2×2 "Federation Hub" Bento grid ("Training Venues • Verified clubs & tables", `opacity: 0.55`, `Alignment(0.35, 0.0)`, bottom-left dark readability scrim). |
| `discover.hub.pickup_meetups_tile` | Discover Screen | `/discover` | `_buildFederationHubSection` / `_buildBentoPortalTile` | `lib/features/home/screens/discover_screen.dart:953, 1038` | `m1_bento_pickup_sparring.webp` (**Generated & Integrated**) | Top-right tile in the 2×2 "Federation Hub" Bento grid ("Pickup Meetups • Sparring & roll calls", `opacity: 0.55`, `Alignment(0.30, -0.15)`, bottom-left dark readability scrim). |
| `discover.hub.community_feed_tile` | Discover Screen | `/discover` | `_buildFederationHubSection` / `_buildBentoPortalTile` | `lib/features/home/screens/discover_screen.dart:962, 1038` | `m1_bento_community_feed.webp` (**Generated & Integrated**) | Bottom-left tile in the 2×2 "Federation Hub" Bento grid ("Community Feed • Technique clips & chats", `opacity: 0.55`, `Alignment(0.30, -0.15)`, bottom-left dark readability scrim). |
| `discover.hub.elo_rankings_tile` | Discover Screen | `/discover` | `_buildFederationHubSection` / `_buildBentoPortalTile` | `lib/features/home/screens/discover_screen.dart:971, 1038` | `m1_bento_elo_rankings.webp` (**Generated & Integrated**) | Bottom-right tile in the 2×2 "Federation Hub" Bento grid ("ELO Rankings • National leaderboards", `opacity: 0.55`, `Alignment(0.35, -0.10)`, bottom-left dark readability scrim). |
| `events.tournament.detail_hero` | Tournament Detail Screen | `/tournament/:id` | `TournamentDetailScreen.build` (`SliverAppBar.flexibleSpace`) | `lib/features/tournament/screens/tournament_screens.dart:409` | `event['imageUrl']` or `tournament_poster.webp` (**Upgraded & Integrated**) | Full-bleed collapsible `SliverAppBar` hero banner (`expandedHeight: 240dp`, `BoxFit.cover`, `Alignment(0.0, -0.20)`, `AppTheme.heroScrim()` 4-stop vertical gradient). |
| `community.feed.post_media_card` | Community Feed & Reels | `/community`, `/post/create` | `_buildFeedCard`, `_buildReelPage`, `CreatePostScreen` | `lib/features/community/screens/community_feed_screen.dart:327, 508, 781, 809` & `create_post_screen.dart:261` | `m1_hero_grip.webp` (Sparring/Technique) or `m1_hero_arena.webp` (Other) | `190dp`-tall 16:9 video preview card in standard feed & full-viewport vertical reel background when YouTube thumbnail is unavailable or offline, overlaid with `_GridTexturePainter` and `AppTheme.heroScrim()`. |

---

### B.2 Full-Screen Stage Backdrop Placements (`CrystalStageBackdrop` & `AmbientParticleBackground` — 56 Placements)

Every screen below renders `CrystalStageBackdrop` (`opacity: 0.46` primary image + `opacity: 0.32` secondary texture + radial corner glows + 4-stop vertical vignette):

| Placement ID | Screen Name | Route | Widget / Class | Source File & Line | Domain Enum | Current Primary Image + Texture |
|---|---|---|---|---|---|---|
| `shell.root.ambient_backdrop` | Main Navigation Shell | Shell wrapper | `MainShellScreen` $\rightarrow$ `AmbientParticleBackground` | `lib/core/widgets/main_shell_screen.dart:599` | Tab `0..4` | Tab 0: `m1_stage_arena_9x16.webp`; Tab 1: `m1_hero_grip.webp`; Tab 2: `tournament_poster.webp`; Tab 3: `club_banner.webp`; Tab 4: `m1_hero_grip.webp` (all + `m1_tex_chalk.webp`). |
| `arena.home.background` | Athlete Dashboard (Home) | `/athlete` | `AthleteDashboardScreen` | `lib/features/athlete/screens/athlete_screens.dart:170` | `arena` | `m1_stage_arena_9x16.webp` + `m1_tex_chalk.webp` (**Generated & Integrated**) |
| `arena.challenges.background` | Challenge Command Center | `/challenges` | `ChallengeInboxScreen` | `lib/features/athlete/screens/athlete_screens.dart:5156` | `arena` | `m1_stage_arena_9x16.webp` + `m1_tex_chalk.webp` (**Generated & Integrated**) |
| `training.log.background` | Training Log & PR Vault | `/training-log` | `TrainingLogScreen` | `lib/features/athlete/screens/training_log_screen.dart:167` | `training` | `m1_stage_training_lab_9x16.webp` + `m1_tex_chalk.webp` (**Generated & Integrated**) |
| `match.head_to_head.background` | Head-to-Head Tale of the Tape | `/head-to-head` | `HeadToHeadScreen` | `lib/features/match/screens/head_to_head_screen.dart:572` | `arena` | `m1_hero_arena.webp` + `m1_tex_chalk.webp` |
| `auth.login.background` | Login Screen | `/login` | `LoginScreen` | `lib/features/auth/screens/login_screen.dart:170` | `arena` | `m1_hero_arena.webp` + `m1_tex_chalk.webp` |
| `auth.register.background` | Register Screen | `/register` | `RegisterScreen` | `lib/features/auth/screens/register_screen.dart:98` | `arena` | `m1_hero_arena.webp` + `m1_tex_chalk.webp` |
| `auth.role_intent.background` | Role Selection Screen | `/role-intent` | `RoleIntentScreen` | `lib/features/auth/screens/role_intent_screen.dart:198` | `arena` | `m1_hero_arena.webp` + `m1_tex_chalk.webp` |
| `auth.forgot_password.background` | Forgot Password Screen | `/forgot-password` | `ForgotPasswordScreen` | `lib/features/auth/screens/forgot_password_screen.dart:87` | `arena` | `m1_hero_arena.webp` + `m1_tex_chalk.webp` |
| `auth.reset_password.background` | Reset Password Screen | `/reset-password` | `ResetPasswordScreen` | `lib/features/auth/screens/reset_password_screen.dart:91` | `arena` | `m1_hero_arena.webp` + `m1_tex_chalk.webp` |
| `auth.onboarding.background` | Athlete Onboarding Wizard | `/onboarding` | `OnboardingScreen` | `lib/features/athlete/screens/onboarding_screen.dart:231` | `arena` | `m1_hero_arena.webp` + `m1_tex_chalk.webp` |
| `discover.home.background` | Discover Hub Screen | `/discover` | `DiscoverScreen` | `lib/features/home/screens/discover_screen.dart:464` | `discover` | `m1_hero_grip.webp` + `m1_tex_chalk.webp` |
| `discover.search.background` | Global Search Screen | `/search` | `SearchScreen` | `lib/features/search/screens/search_screen.dart:113` | `discover` | `m1_hero_grip.webp` + `m1_tex_chalk.webp` |
| `teams.directory.background` | Clubs & Teams Directory | `/teams` | `TeamsDirectoryScreen` | `lib/features/team/screens/team_screens.dart:70` | `discover` | `m1_hero_grip.webp` + `m1_tex_chalk.webp` |
| `teams.detail.background` | Team / Club Profile Screen | `/team/:id` | `TeamDetailScreen` | `lib/features/team/screens/team_screens.dart:682` | `discover` | `m1_hero_grip.webp` + `m1_tex_chalk.webp` |
| `teams.create.background` | Create Team / Club Screen | `/team/create` | `CreateTeamScreen` (`StickyFormScaffold`) | `lib/features/team/screens/team_screens.dart:1862` | `arena` (default in `StickyFormScaffold`) | `m1_hero_arena.webp` + `m1_tex_chalk.webp` |
| `admin.roster.background` | Admin Athlete Roster & Reviews | `/admin/roster` | `AdminRosterScreen` | `lib/features/admin/screens/admin_roster_screen.dart:972` | `discover` | `m1_hero_grip.webp` + `m1_tex_chalk.webp` |
| `events.directory.background` | Tournaments Directory | `/tournaments` | `TournamentListScreen` | `lib/features/tournament/screens/tournament_screens.dart:112` | `events` | `tournament_poster.webp` + `m1_tex_chalk.webp` |
| `events.detail.background` | Tournament Detail Body | `/tournament/:id` | `TournamentDetailScreen` | `lib/features/tournament/screens/tournament_screens.dart:377` | `events` | `tournament_poster.webp` + `m1_tex_chalk.webp` |
| `events.registration.background` | Event Registration Screen | `/tournament/:id/register` | `EventRegistrationScreen` | `lib/features/tournament/screens/event_registration_screen.dart:245` | `events` | `tournament_poster.webp` + `m1_tex_chalk.webp` |
| `events.operations.background` | Tournament Bracket & Ops | `/tournament/:id/operations` | `TournamentOperationsScreen` | `lib/features/tournament/screens/tournament_operations_screen.dart:956` | `events` | `tournament_poster.webp` + `m1_tex_chalk.webp` |
| `events.operator_dashboard.background` | Operator Dashboard | `/operator/dashboard` | `TournamentOperatorDashboardScreen` | `lib/features/tournament/screens/tournament_operator_dashboard_screen.dart:128` | `events` | `tournament_poster.webp` + `m1_tex_chalk.webp` |
| `events.weigh_in.background` | Official Weigh-In Console | `/tournament/:id/weigh-in` | `TournamentWeighInScreen` | `lib/features/tournament/screens/tournament_weigh_in_screen.dart:261, 353` | `events` | `tournament_poster.webp` + `m1_tex_chalk.webp` |
| `championship.belts_list.background` | Championship Belts Hall | `/championships` | `ChampionshipsScreen` | `lib/features/championship/screens/championship_screens.dart:52` | `events` | `tournament_poster.webp` + `m1_tex_chalk.webp` |
| `championship.belt_detail.background` | Belt Lineage & Reign Detail | `/championship/:id` | `ChampionshipDetailScreen` | `lib/features/championship/screens/championship_screens.dart:245` | `events` | `tournament_poster.webp` + `m1_tex_chalk.webp` |
| `championship.awards_ceremony.background` | Tournament Awards & Podium | `/tournament/:id/awards` | `TournamentAwardsCeremonyScreen` | `lib/features/championship/screens/tournament_awards_ceremony_screen.dart:287, 1327, 1410, 1529` | `events` | `tournament_poster.webp` + `m1_tex_chalk.webp` |
| `admin.arena_ops.background` | Admin Arena Ops & Belts | `/admin/arena-ops` | `AdminArenaOpsScreen` | `lib/features/admin/screens/admin_arena_ops_screen.dart:1009` | `events` | `tournament_poster.webp` + `m1_tex_chalk.webp` |
| `community.feed.background` | Community Feed Screen | `/community` | `CommunityFeedScreen` | `lib/features/community/screens/community_feed_screen.dart:209` | `community` | `club_banner.webp` + `m1_tex_knurl.webp` |
| `community.comments.background` | Post Comments Sheet/Screen | `/post/:id/comments` | `PostCommentsScreen` | `lib/features/community/screens/post_comments_screen.dart:102` | `community` | `club_banner.webp` + `m1_tex_knurl.webp` |
| `community.create_post.background` | Create Community Post | `/post/create` | `CreatePostScreen` (`StickyFormScaffold`) | `lib/features/community/screens/create_post_screen.dart:144` | `arena` (default in `StickyFormScaffold`) | `m1_hero_arena.webp` + `m1_tex_chalk.webp` |
| `community.followers.background` | Followers / Following List | `/athlete/:id/followers` | `FollowersListScreen` | `lib/features/athlete/screens/followers_list_screen.dart:163, 196` | `community` | `club_banner.webp` + `m1_tex_knurl.webp` |
| `messaging.inbox.background` | Direct Messages Inbox | `/messages` | `ConversationsListScreen` | `lib/features/messaging/screens/messaging_screens.dart:55` | `community` | `club_banner.webp` + `m1_tex_knurl.webp` |
| `messaging.chat.background` | Direct Message Thread | `/messages/:id` | `ChatScreen` | `lib/features/messaging/screens/messaging_screens.dart:304` | `community` | `club_banner.webp` + `m1_tex_knurl.webp` |
| `messaging.announcements.background` | Federation Announcements | `/announcements` | `AnnouncementsScreen` | `lib/features/messaging/screens/announcement_screens.dart:48` | `community` | `club_banner.webp` + `m1_tex_knurl.webp` |
| `notifications.inbox.background` | Notifications Center | `/notifications` | `NotificationsScreen` | `lib/features/notifications/screens/notification_screens.dart:164` | `community` | `club_banner.webp` + `m1_tex_knurl.webp` |
| `venues.directory.background` | Training Venues Directory | `/venues` | `VenueDirectoryScreen` | `lib/features/venue/screens/venue_directory_screen.dart:63` | `venues` | `club_banner.webp` + `m1_tex_knurl.webp` |
| `venues.detail.background` | Training Venue Detail | `/venue/:id` | `VenueDetailScreen` | `lib/features/venue/screens/venue_detail_screen.dart:49` | `venues` | `club_banner.webp` + `m1_tex_knurl.webp` |
| `venues.submit.background` | Submit Training Venue | `/venue/submit` | `SubmitVenueScreen` (`StickyFormScaffold`) | `lib/features/venue/screens/submit_venue_screen.dart:79` | `arena` (default in `StickyFormScaffold`) | `m1_hero_arena.webp` + `m1_tex_chalk.webp` |
| `informal_events.directory.background` | Pickup Meetups Directory | `/informal-events` | `InformalEventDirectoryScreen` | `lib/features/informal_event/screens/informal_event_directory_screen.dart:75` | `venues` | `club_banner.webp` + `m1_tex_knurl.webp` |
| `informal_events.detail.background` | Pickup Meetup Detail | `/informal-event/:id` | `InformalEventDetailScreen` | `lib/features/informal_event/screens/informal_event_detail_screen.dart:100` | `venues` | `club_banner.webp` + `m1_tex_knurl.webp` |
| `informal_events.create.background` | Host Pickup Meetup | `/informal-event/create` | `CreateInformalEventScreen` (`StickyFormScaffold`) | `lib/features/informal_event/screens/create_informal_event_screen.dart:142` | `arena` (default in `StickyFormScaffold`) | `m1_hero_arena.webp` + `m1_tex_chalk.webp` |
| `passport.profile.background` | Athlete Passport & Profile | `/athlete/profile` | `AthleteProfileScreen` | `lib/features/athlete/screens/athlete_screens.dart:3918` | `passport` | `m1_hero_grip.webp` + `m1_tex_chalk.webp` |
| `settings.hub.background` | Settings & Security Hub | `/settings`, `/settings/*` | `SettingsHubScreen`, `SettingsScreen`, `AccountRolesScreen`, `PaymentMethodsScreen`, `SessionScreens`, `SupportScreens`, `MfaScreens` | `lib/features/settings/screens/settings_hub_screens.dart:36, 462, 582, 664`, `settings_screens.dart:39, 179`, `account_roles_screen.dart:196`, `payment_methods_screen.dart:137`, `session_screens.dart:100, 381`, `support_screens.dart:110, 670`, `mfa_setup_screen.dart:85` | `passport` | `m1_hero_grip.webp` + `m1_tex_chalk.webp` |
| `admin.dossier.background` | Admin Security & Audit Dossier | `/admin/dossier` | `AdminDossierScreen` | `lib/features/admin/screens/admin_dossier_screen.dart:206` | `passport` | `m1_hero_grip.webp` + `m1_tex_chalk.webp` |
| `rankings.leaderboard.background` | Global & National ELO Rankings | `/rankings` | `RankingsScreen` | `lib/features/athlete/screens/rankings_screen.dart:131` | `rankings` | `m1_hero_arena.webp` + `m1_tex_knurl.webp` |
| `nominations.list.background` | Athlete Talent Nominations | `/nominations` | `MyNominationsScreen` | `lib/features/nomination/screens/my_nominations_screen.dart:58` | `rankings` | `m1_hero_arena.webp` + `m1_tex_knurl.webp` |
| `referee.hub.background` | Referee Command & Live Scorepad | `/referee`, `/referee/scorepad/:id`, `/referee/*` | `RefereeDashboardScreen`, `OfficialScorepadScreen`, `RefereeCertificationScreen`, `RefereeDisputeScreen`, `RefereeHistoryScreen` | `lib/features/referee/screens/referee_screens.dart:282, 943, 1316, 1703, 1843` & `official_scorepad_screen.dart:270` | `referee` | `m1_hero_arena.webp` + `m1_tex_knurl.webp` |
| `admin.command.background` | Admin Federation Command | `/admin/command` | `AdminCommandScreen` | `lib/features/admin/screens/admin_command_screen.dart:621` | `governance` | `m1_hero_arena.webp` + `m1_tex_knurl.webp` |
| `admin.governance.background` | Admin Federation Governance | `/admin/governance` | `AdminGovernanceScreen` | `lib/features/admin/screens/admin_governance_screen.dart:625` | `governance` | `m1_hero_arena.webp` + `m1_tex_knurl.webp` |

---

### B.3 Avatar, Portrait & Dynamic Remote Media Placements (10 Placements)

| Placement ID | Screen / Feature | Route | Widget / Method | Exact Source File & Line | Current Image / Fallback | Visual Role & Applied Treatment |
|---|---|---|---|---|---|---|
| `passport.profile.avatar` | Athlete Passport Screen | `/athlete/profile` | `AthleteProfileScreen` | `lib/features/athlete/screens/athlete_screens.dart:3978` | `customPortraitImage` / `profilePhoto` $\rightarrow$ `avatar_neutral_dark.webp` | `84×84` circular portrait frame with gold border (`ArmSphereImage.avatar`). |
| `profile.public.avatar` | Public Athlete Profile | `/athlete/:id` | `PublicProfileScreen` | `lib/features/athlete/screens/public_profile_screen.dart:156` | `athlete['avatarUrl']` $\rightarrow$ `avatar_neutral_dark.webp` | `88×88` circular athlete portrait in public dossier header. |
| `rankings.leaderboard.row_avatar` | Global Rankings Screen | `/rankings` | `RankingsScreen` | `lib/features/athlete/screens/rankings_screen.dart:376` | `athlete['avatarUrl']` $\rightarrow$ `avatar_neutral_dark.webp` | `40×40` circular avatar per leaderboard row. |
| `match.head_to_head.left_avatar` | Head-to-Head Screen | `/head-to-head` | `HeadToHeadScreen` | `lib/features/match/screens/head_to_head_screen.dart:784` | `athleteA['avatarUrl']` $\rightarrow$ `avatar_neutral_dark.webp` | `72×72` circular Red-Corner fighter portrait in Tale of the Tape header. |
| `match.head_to_head.right_avatar` | Head-to-Head Screen | `/head-to-head` | `HeadToHeadScreen` | `lib/features/match/screens/head_to_head_screen.dart:899` | `athleteB['avatarUrl']` $\rightarrow$ `avatar_neutral_dark.webp` | `72×72` circular Blue-Corner challenger portrait in Tale of the Tape header. |
| `match.head_to_head.picker_avatar` | Head-to-Head Athlete Picker | `/head-to-head` | `HeadToHeadScreen` | `lib/features/match/screens/head_to_head_screen.dart:1741` | `athlete['avatarUrl']` $\rightarrow$ `avatar_neutral_dark.webp` | `40×40` circular avatar in searchable opponent selector modal. |
| `championship.awards.podium_avatar` | Tournament Awards Ceremony | `/tournament/:id/awards` | `TournamentAwardsCeremonyScreen` | `lib/features/championship/screens/tournament_awards_ceremony_screen.dart:769` | `medalist['avatarUrl']` $\rightarrow$ `avatar_neutral_dark.webp` | Circular gold/silver/bronze podium medalist portrait. |
| `community.feed.author_avatar` | Community Feed & Comments | `/community`, `/post/:id/comments` | `CommunityFeedScreen`, `PostCommentsScreen` | `lib/features/community/screens/community_feed_screen.dart:361, 968` & `post_comments_screen.dart:149` | `author['avatarUrl']` $\rightarrow$ `avatar_neutral_dark.webp` | `36×36` / `32×32` circular author avatar next to post/comment header. |
| `events.tournament.live_stream_card` | Tournament Live Stream Card | `/tournament/:id` | `LiveStreamCardWidget` | `lib/features/tournament/widgets/live_stream_card_widget.dart:181` | `stream['thumbnailUrl']` (via `DecorationImage(NetworkImage)`) | Broadcast preview card background (`180dp` height) — currently bypasses `ArmSphereImage` when `thumbnailUrl` is set, or renders a plain dark gradient when null. |
| `events.tournament.participants_avatar` | Participants Carousel Widget | `/tournament/:id` | `ParticipantsCarouselWidget` | `lib/features/tournament/widgets/participants_carousel_widget.dart:276, 499` | `participant['avatarUrl']` (via `Image.network`) | Registered competitor avatar in horizontal tournament roster — currently uses raw `Image.network` instead of `ArmSphereImage.avatar`. |

---

## Part C — Individual Replacement Specifications

Below are the complete 21-field specifications for the **26 unique replacement artworks** needed to eliminate inappropriate repetition across ArmSphere.

### C.1 Primary Athlete Dashboard & Welcome Hero Cards

#### 1. `profile.athlete.dashboard_hero` (Generated & Integrated)
| Field | Specification |
|---|---|
| **Placement ID** | `profile.athlete.dashboard_hero` |
| **Current image** | `assets/images/heroes/m1_hero_athlete_dashboard.webp` (`Shadowed Hero in Crimson Smoke.webp` — integrated) |
| **Screen** | Primary Athlete Dashboard (`AthleteDashboardScreen`) |
| **Route** | `/athlete` |
| **Widget** | `_buildAthleteCinematicBanner` |
| **Source file** | `apps/mobile/lib/features/athlete/screens/athlete_screens.dart:901` |
| **Purpose** | Primary athlete identity & competitive status dossier card at the top of the Athlete Dashboard. |
| **Image role** | Full-card integrated hero artwork (`16:9` continuous composition). |
| **Replacement concept** | Shadowed elite arm-wrestler upper-body silhouette emerging from deep obsidian and crimson magnesium smoke on the left 40% of the frame, transitioning smoothly into dark negative space on the right 60%. |
| **Main subject** | Muscular athlete silhouette (head, shoulders, traps, and upper arms) positioned in the left visual stage. |
| **Environment** | Dark Void studio atmosphere with subtle diagonal brushed-titanium light beams and restrained crimson corner smoke. |
| **Composition** | Asymmetric left-heavy composition: subject occupies `x: 5%–42%`, `y: 8%–95%`; right side (`x: 45%–98%`) is low-detail atmospheric darkness. |
| **Aspect ratio** | `16:9` |
| **Resolution** | `1920 × 1080` (or `1672 × 941` current production PNG) |
| **Focal point** | `Alignment(-0.55, -0.24)` (head and upper torso on the left). |
| **Empty space** | Right 58% (`x: 42%–100%`) for Athlete Name, Country/Club, and ELO Callout; bottom 22% (`y: 78%–100%`) across full width for the 4-stat biometric ribbon. |
| **Lighting and atmosphere** | Rim-lit crimson/silver edge highlight on the athlete's silhouette against `#070A11` obsidian void. |
| **Image treatment** | `BoxFit.cover`, `opacity: 0.94`, adaptive left-to-right and bottom dark gradient scrims. |
| **Motion potential** | High — subtle looping ember/chalk smoke drift behind the silhouette in a future WebM/Lottie pass. |
| **Customization** | Yes — user can replace via `VisualPreferencesNotifier` (supports both widescreen hero presets and blended portrait photos). |
| **Priority** | **Generated & Integrated (Baseline Reference Standard)** |

---

#### 2. `arena.home.radar_card` (Generated & Integrated — Pending Live Flutter Screenshot Verification)
| Field | Specification |
|---|---|
| **Placement ID** | `arena.home.radar_card` |
| **Current image** | `assets/images/heroes/m1_card_arena_radar.webp` (`1920×820` WEBP — **Generated & Integrated**) |
| **Screen** | Primary Athlete Dashboard (`AthleteDashboardScreen`) |
| **Route** | `/athlete` |
| **Widget** | `_buildSanctionedArenaRadar` |
| **Source file** | `apps/mobile/lib/features/athlete/screens/athlete_screens.dart:664` |
| **Purpose** | Compact horizontal environmental anchor banner (`minHeight: 96dp`) above the Athlete Hero Card that launches the user into live sanctioned tournaments & table calls (`/tournaments`). |
| **Image role** | Wide ribbon card background (`~3.5:1` visible viewport slice). |
| **Replacement concept** | Wide-angle `1920×820` (`21:9`) championship arena composition with a dark text-safe obsidian and crimson-smoke area on the left (`x: 0%–45%`) and a spotlighted red-and-black competition arm-wrestling table beneath a circular arena jumbotron on the right-center (`x: 50%–86%`). |
| **Main subject** | Official competition arm-wrestling table pad and overhead championship light rig / jumbotron positioned on the right-center (`x: 50%–86%`). |
| **Environment** | Sanctioned international championship arena with crimson and white stage beams cutting through dark slate haze. |
| **Composition** | Ultra-wide horizontal ribbon composition: dark low-clutter left 48% (`x: 0%–48%`) where the 3 lines of text ("SANCTIONED ARENA RADAR", "Championship Arena Active", "Official tournament brackets & table calls") sit; dramatic lit arena table and spotlight truss on the right-center (`x: 52%–86%`) beside the "Explore >" button. |
| **Aspect ratio** | `21:9` (`1920 × 820`) |
| **Resolution** | `1920 × 820` (140,838 bytes WEBP) |
| **Focal point** | `Alignment(0.30, 0.28)` (illuminated stage table and spotlight beams on the right-center). |
| **Empty space** | Left 48% (`x: 0%–48%`) remains dark and calm for the gold/white typography; far right (`x: 86%–100%`) frames the "Explore >" button. |
| **Lighting and atmosphere** | Crimson and white overhead stage beams, obsidian floor reflections, zero visual clutter behind left text. |
| **Image treatment** | `BoxFit.cover`, `Alignment(0.30, 0.28)`, tuned 4-stop horizontal scrim (`0x66070A11 -> 0x38070A11 -> 0x14070A11 -> 0x2E070A11`). |
| **Motion potential** | Medium — subtle volumetric spotlight sweep. |
| **Customization** | No (official Federation environmental status banner). |
| **Priority** | **Generated & Integrated (`verified: false` — awaiting live Flutter screenshot inspection)** |

---

#### 3. `arena.home.supermatch_card`
| Field | Specification |
|---|---|
| **Placement ID** | `arena.home.supermatch_card` |
| **Current image** | `assets/images/heroes/m1_hero_grip.webp` (reused 10+ times across the app) |
| **Screen** | Primary Athlete Dashboard (`AthleteDashboardScreen`) |
| **Route** | `/athlete` |
| **Widget** | `_buildUpcomingSupermatchCard` |
| **Source file** | `apps/mobile/lib/features/athlete/screens/athlete_screens.dart:2270` |
| **Purpose** | Broadcast Fight Card displaying the athlete's next scheduled head-to-head supermatch (Fighter A vs. Fighter B, weight class, arm discipline, and "VIEW BRACKET" CTA). |
| **Image role** | Full-card combat matchup stage background (`~16:10` card aspect). |
| **Replacement concept** | Symmetrical eye-level macro shot of an official two-tone arm-wrestling competition table center peg and referee strap resting on the table pad, split by a dramatic crimson spotlight from the left corner and an electric cyan/ice-blue spotlight from the right corner, with airborne chalk dust in the center gap. |
| **Main subject** | Competition table surface, center pegs, pin pads, and woven referee strap waiting at center table (`x: 35%–65%`, `y: 35%–75%`). |
| **Environment** | Dark broadcast superfight stage with dual corner lighting (Red Corner left, Blue Corner right). |
| **Composition** | Symmetrical VS broadcast stage: central focal point at the table center directly behind the "VS" badge (`x: 42%–58%`), while the left (`x: 5%–38%`) and right (`x: 62%–95%`) zones provide clean dark crimson and dark slate-blue backdrops behind Fighter A and Fighter B names. |
| **Aspect ratio** | `16:9` |
| **Resolution** | `1920 × 1080` |
| **Focal point** | `Alignment(0.0, 0.15)` (center table pad & strap). |
| **Empty space** | Top 20% (`y: 0%–20%`) for match status header; left/right middle wings for fighter names; bottom 22% (`y: 78%–100%`) for metadata & "VIEW BRACKET" button. |
| **Lighting and atmosphere** | High-contrast Red vs. Blue corner rim lighting meeting in a white-hot chalk dust center vertical axis. |
| **Image treatment** | `BoxFit.cover`, `opacity: 0.48` (increased from `0.20` once purpose-built dark VS artwork is supplied), top/bottom readability vignette. |
| **Motion potential** | High — floating chalk particles and pulsing red/blue corner light flares. |
| **Customization** | No (system broadcast matchup card). |
| **Priority** | **High (Tier 1)** |

---

#### 4. `arena.home.no_bouts_card`
| Field | Specification |
|---|---|
| **Placement ID** | `arena.home.no_bouts_card` |
| **Current image** | `assets/images/defaults/tournament_poster.webp` |
| **Screen** | Primary Athlete Dashboard (`AthleteDashboardScreen`) |
| **Route** | `/athlete` |
| **Widget** | `_buildNoUpcomingBoutsCard` |
| **Source file** | `apps/mobile/lib/features/athlete/screens/athlete_screens.dart:2498` |
| **Purpose** | Empty-state "ARENA SCHEDULE • NO UPCOMING BOUTS SCHEDULED" card prompting the athlete to browse and register for upcoming sanctioned tournaments. |
| **Image role** | Card background (`~16:9` container, `170dp` height). |
| **Replacement concept** | Quiet, moody after-hours view of a single spotlighted arm-wrestling table standing ready in a dark arena hall, with a coiled referee strap resting on the elbow pad—communicating "the table is waiting for your next bout." |
| **Main subject** | Spotlighted elbow pad and coiled strap on the right third of the frame (`x: 62%–92%`). |
| **Environment** | Darkened championship hall in standby mode with a single overhead cone of warm gold light. |
| **Composition** | Left 60% (`x: 0%–60%`) in deep obsidian shadow for the left-aligned title and subtitle; right 40% (`x: 60%–100%`) reveals the waiting table pad above the "BROWSE TOURNAMENTS" button. |
| **Aspect ratio** | `16:9` |
| **Resolution** | `1600 × 900` |
| **Focal point** | `Alignment(0.55, -0.10)` (spotlighted elbow pad on the right). |
| **Empty space** | Left 60% (`x: 0%–60%`) and bottom 28% (`y: 72%–100%`) for the full-width CTA button. |
| **Lighting and atmosphere** | Restrained, atmospheric "calm before the battle" with a single champagne-gold overhead beam in `#070A11` darkness. |
| **Image treatment** | `BoxFit.cover`, `opacity: 0.52`, left-to-right gradient scrim. |
| **Motion potential** | Low. |
| **Customization** | No. |
| **Priority** | **Medium (Tier 2)** |

---

#### 5. `auth.welcome.hero_banner`
| Field | Specification |
|---|---|
| **Placement ID** | `auth.welcome.hero_banner` |
| **Current image** | `assets/images/heroes/m1_hero_grip.webp` |
| **Screen** | Welcome / Onboarding Entry Screen (`WelcomeScreen`) |
| **Route** | `/welcome` |
| **Widget** | `WelcomeScreen.build` |
| **Source file** | `apps/mobile/lib/features/auth/screens/welcome_screen.dart:128` |
| **Purpose** | First visual impression of ArmSphere for unauthenticated users choosing their role (Athlete, Tournament Organizer, Referee, Spectator) and entering the arena. |
| **Image role** | Top `340dp` full-bleed hero header fading into the `#070A11` screen body. |
| **Replacement concept** | Iconic overhead-angled cinematic shot of two athletes locking hands at the center of an illuminated championship table—muscular forearms chalked in white magnesium, referee's hands hovering over the grip to set the center, framed by dramatic stadium spotlights in the upper background. |
| **Main subject** | Locked hands & forearms at center table with referee's hands setting the grip (`x: 25%–75%`, `y: 15%–68%`). |
| **Environment** | Grand championship arena coliseum with dark atmospheric depth and gold/crimson stadium lights in the upper sky. |
| **Composition** | Centered heroic composition in the upper 65% of the canvas (`y: 10%–65%`), fading naturally into dark shadow in the bottom 35% (`y: 65%–100%`) where the gold federation emblem and "ARMSPHERE" title overlap. |
| **Aspect ratio** | `16:10` or `4:3` |
| **Resolution** | `1920 × 1200` |
| **Focal point** | `Alignment(0.0, -0.25)` (locked grip in upper-center). |
| **Empty space** | Bottom 35% (`y: 65%–100%`) must darken smoothly for the overlapping crest and headline. |
| **Lighting and atmosphere** | High-drama stadium rim lighting, crisp chalk texture, obsidian and gold prestige palette. |
| **Image treatment** | `BoxFit.cover`, `Alignment(0.0, -0.25)`, 4-stop vertical bottom fade into `#070A11`. |
| **Motion potential** | High — slow-motion chalk rise on first app launch. |
| **Customization** | No. |
| **Priority** | **High (Tier 1)** |

---

### C.2 Discover Screen — 4 Federation Hub Bento Portal Cards

Currently, the 2×2 Bento grid on `/discover` (`_buildFederationHubSection` in `discover_screen.dart:935–1002`) simply reuses the 4 global placeholder images (`defaultClub`, `heroGrip`, `heroArena`, `defaultTournament`). Even worse, two of them are semantically mismatched ("Community Feed" uses `heroArena` and "ELO Rankings" uses `tournament_poster`). Each of these 4 portal tiles needs its own dedicated card artwork:

#### 6. `discover.hub.venues_tile`
| Field | Specification |
|---|---|
| **Placement ID** | `discover.hub.venues_tile` |
| **Current image** | `assets/images/defaults/club_banner.webp` |
| **Screen** | Discover Screen (`DiscoverScreen`) |
| **Route** | `/discover` (launches `/venues`) |
| **Widget** | `_buildFederationHubSection` $\rightarrow$ `_buildBentoPortalTile` |
| **Source file** | `apps/mobile/lib/features/home/screens/discover_screen.dart:944` |
| **Purpose** | Portal card launching the Verified Training Venues & Clubs Directory (`/venues`). |
| **Image role** | Bento grid card background (`~4:3` tile aspect ratio). |
| **Replacement concept** | Atmospheric interior shot of an elite arm-wrestling training facility: custom steel practice tables, wall-mounted cable pulley rigs with rolling handles, and chalk bowls under warm industrial pendant lights. |
| **Main subject** | Professional club practice table and arm-wrestling cable pulley station on the right-center (`x: 40%–95%`). |
| **Environment** | Authentic high-end strength & arm-wrestling club gym with dark matte iron equipment. |
| **Composition** | Subject positioned in the middle-right (`x: 40%–95%`, `y: 20%–80%`), keeping the top-left (`DIRECTORY` chip + icon) and bottom-left (`Training Venues / Verified clubs & tables`) dark and legible. |
| **Aspect ratio** | `4:3` |
| **Resolution** | `1200 × 900` |
| **Focal point** | `Alignment(0.35, 0.0)` |
| **Empty space** | Left 55% and bottom 35% darkened for tile title and subtitle. |
| **Lighting and atmosphere** | Warm amber/gold rim light on dark iron gym equipment. |
| **Image treatment** | `BoxFit.cover`, `opacity: 0.55`, bottom-left dark readability gradient. |
| **Motion potential** | Low. |
| **Customization** | No. |
| **Priority** | **High (Tier 1)** |

---

#### 7. `discover.hub.pickup_meetups_tile`
| Field | Specification |
|---|---|
| **Placement ID** | `discover.hub.pickup_meetups_tile` |
| **Current image** | `assets/images/heroes/m1_hero_grip.webp` |
| **Screen** | Discover Screen (`DiscoverScreen`) |
| **Route** | `/discover` (launches `/informal-events`) |
| **Widget** | `_buildFederationHubSection` $\rightarrow$ `_buildBentoPortalTile` |
| **Source file** | `apps/mobile/lib/features/home/screens/discover_screen.dart:953` |
| **Purpose** | Portal card launching Pickup Meetups, Open Table Practice Pulls & Sparring Roll Calls (`/informal-events`). |
| **Image role** | Bento grid card background (`~4:3` tile aspect ratio). |
| **Replacement concept** | Tight, energetic close-up of two training partners gripping up at a club practice table while a third training partner watches beside the table—conveying grassroots sparring, open table sessions, and brotherhood. |
| **Main subject** | Two athletes locked in an informal practice pull grip (`x: 35%–90%`, `y: 15%–75%`). |
| **Environment** | Underground club practice room with subtle emerald/cyan rim light and chalk dust. |
| **Composition** | Action focused in the upper-right quadrant (`x: 38%–95%`, `y: 15%–70%`), leaving bottom-left clean for "Pickup Meetups • Sparring & roll calls". |
| **Aspect ratio** | `4:3` |
| **Resolution** | `1200 × 900` |
| **Focal point** | `Alignment(0.30, -0.15)` |
| **Empty space** | Top-left (`SPARRING` badge) and bottom 35% (`y: 65%–100%`) for text. |
| **Lighting and atmosphere** | Raw, kinetic gym lighting with subtle emerald (`#10B981`) accent rim light. |
| **Image treatment** | `BoxFit.cover`, `opacity: 0.55`, directional bottom-left dark scrim. |
| **Motion potential** | Low. |
| **Customization** | No. |
| **Priority** | **High (Tier 1)** |

---

#### 8. `discover.hub.community_feed_tile`
| Field | Specification |
|---|---|
| **Placement ID** | `discover.hub.community_feed_tile` |
| **Current image** | `assets/images/heroes/m1_hero_arena.webp` (mismatched — shows empty arena podiums for a social/video clip feed) |
| **Screen** | Discover Screen (`DiscoverScreen`) |
| **Route** | `/discover` (launches `/community`) |
| **Widget** | `_buildFederationHubSection` $\rightarrow$ `_buildBentoPortalTile` |
| **Source file** | `apps/mobile/lib/features/home/screens/discover_screen.dart:962` |
| **Purpose** | Portal card launching the Community Feed, Technique Breakdown Clips & Athlete Discussions (`/community`). |
| **Image role** | Bento grid card background (`~4:3` tile aspect ratio). |
| **Replacement concept** | Over-the-shoulder perspective of an arm-wrestling technique session being filmed on a tripod/camera rig next to a table, with glowing cyan light framing the athletes demonstrating a toproll/hook setup. |
| **Main subject** | Forearm technique demonstration at table pad with subtle cinema camera/Creator lighting (`x: 35%–92%`). |
| **Environment** | Dark studio/gym creator space with cool cyan (`#38BDF8`) and slate rim lighting. |
| **Composition** | Subject in upper-right/center (`x: 35%–92%`, `y: 15%–72%`); clean dark bottom-left for "Community Feed • Technique clips & chats". |
| **Aspect ratio** | `4:3` |
| **Resolution** | `1200 × 900` |
| **Focal point** | `Alignment(0.30, -0.15)` |
| **Empty space** | Top-left (`SOCIAL` tag) and bottom 35% (`y: 65%–100%`). |
| **Lighting and atmosphere** | Cool electric cyan and obsidian creator-studio aesthetic. |
| **Image treatment** | `BoxFit.cover`, `opacity: 0.55`, bottom-left dark scrim. |
| **Motion potential** | Low. |
| **Customization** | No. |
| **Priority** | **High (Tier 1)** |

---

#### 9. `discover.hub.elo_rankings_tile`
| Field | Specification |
|---|---|
| **Placement ID** | `discover.hub.elo_rankings_tile` |
| **Current image** | `assets/images/defaults/tournament_poster.webp` |
| **Screen** | Discover Screen (`DiscoverScreen`) |
| **Route** | `/discover` (launches `/rankings`) |
| **Widget** | `_buildFederationHubSection` $\rightarrow$ `_buildBentoPortalTile` |
| **Source file** | `apps/mobile/lib/features/home/screens/discover_screen.dart:971` |
| **Purpose** | Portal card launching the National & Global ELO Rankings Leaderboard (`/rankings`). |
| **Image role** | Bento grid card background (`~4:3` tile aspect ratio). |
| **Replacement concept** | Macro hero composition of an embossed gold championship belt / #1 tier crest resting on a dark brushed-titanium pedestal with subtle ascending light bars in the background—symbolizing ELO progression and national standing. |
| **Main subject** | Champagne-gold championship plate / #1 trophy emblem on dark titanium (`x: 40%–92%`, `y: 18%–75%`). |
| **Environment** | Obsidian hall of fame vault with subtle gold vertical light telemetry lines. |
| **Composition** | Trophy/emblem anchored on the right (`x: 42%–92%`); dark left and bottom zones for `STANDINGS` tag and "ELO Rankings • National leaderboards". |
| **Aspect ratio** | `4:3` |
| **Resolution** | `1200 × 900` |
| **Focal point** | `Alignment(0.35, -0.10)` |
| **Empty space** | Top-left and bottom 35% (`y: 65%–100%`). |
| **Lighting and atmosphere** | Warm 24k gold (`#D4AF37`) specular highlights on dark gunmetal slate. |
| **Image treatment** | `BoxFit.cover`, `opacity: 0.55`, bottom-left dark scrim. |
| **Motion potential** | Low. |
| **Customization** | No. |
| **Priority** | **High (Tier 1)** |

---

### C.3 Full-Screen Domain & Feature Stage Backdrops

As discovered in Part B.2, 56 screens use `CrystalStageBackdrop`, which currently maps 9 domains onto just **4 images** (`heroArena`, `heroGrip`, `defaultTournament`, `defaultClub`). Below are the specifications for giving each major functional domain (and high-value standalone experiences like Training Log, Head-to-Head VS, and Championship Belts) its own purpose-designed full-screen stage artwork:

#### 10. `arena.home.background` (Arena & Challenge Command Stage)
| Field | Specification |
|---|---|
| **Placement ID** | `arena.home.background` |
| **Current image** | `assets/images/heroes/m1_hero_arena.webp` |
| **Screen** | Athlete Dashboard (`/athlete`) & Challenge Command Center (`/challenges`) |
| **Route** | `/athlete`, `/challenges` |
| **Widget** | `CrystalStageBackdrop(domain: ArmSphereStageDomain.arena)` |
| **Source file** | `apps/mobile/lib/core/widgets/crystal_stage_scaffold.dart:81` |
| **Purpose** | Full-viewport (`9:16`) environmental stage behind the primary Athlete Dashboard and Challenge Command screens. |
| **Image role** | Full-screen portrait stage backdrop (`Positioned.fill`). |
| **Replacement concept** | Vertical `9:16` architectural view of a dark championship arena coliseum: overhead octagonal lighting truss in the upper 25% casting subtle volumetric shafts down into a deep obsidian arena floor at the bottom 25%, with a calm, low-frequency dark middle zone (`y: 25%–75%`) so floating dark glass cards remain crisp. |
| **Main subject** | Championship arena lighting architecture at top and subtle stage floor reflections at bottom. |
| **Environment** | Sanctioned international arm-wrestling arena in deep obsidian, slate, and restrained crimson/gold light. |
| **Composition** | Top 25% (`y: 0%–25%`): stadium truss & spotlight beams; Middle 50% (`y: 25%–75%`): calm atmospheric charcoal haze; Bottom 25% (`y: 75%–100%`): dark stage floor perspective lines. |
| **Aspect ratio** | `9:16` (currently uses a `16:9` image cropped severely on portrait phones!) |
| **Resolution** | `1080 × 1920` |
| **Focal point** | `Alignment(0.0, -0.55)` (upper stadium light rig). |
| **Empty space** | Central 55% (`y: 22%–77%`) kept low-contrast so stacked dashboard cards don't fight busy details. |
| **Lighting and atmosphere** | Obsidian `#070A11` base, subtle crimson (`#E23B3B`) left-top rim, champagne gold (`#D4AF37`) right-bottom warmth. |
| **Image treatment** | `BoxFit.cover`, `opacity: 0.46`, 4-stop vertical contrast vignette. |
| **Motion potential** | Medium — subtle atmospheric dust drift. |
| **Customization** | Yes — user-customizable via `VisualCustomizeSlot.screenBackdrop` in Visual Studio. |
| **Priority** | **High (Tier 1)** |

---

#### 11. `training.log.background` (Strength & Performance Lab Stage)
| Field | Specification |
|---|---|
| **Placement ID** | `training.log.background` |
| **Current image** | `assets/images/heroes/m1_hero_arena.webp` (inappropriately reuses the tournament stage for personal strength/workout logging) |
| **Screen** | Training Log & PR Vault (`TrainingLogScreen`) |
| **Route** | `/training-log` |
| **Widget** | `CrystalStageBackdrop` (currently using `ArmSphereStageDomain.arena`) |
| **Source file** | `apps/mobile/lib/features/athlete/screens/training_log_screen.dart:167` |
| **Purpose** | Personal strength telemetry, workout session logging, recovery status, and Personal Record (PR) ledger for arm-wrestling specific lifts (pronation, cupping, side pressure, rising). |
| **Image role** | Full-screen portrait stage backdrop (`9:16`). |
| **Replacement concept** | Vertical `9:16` dark performance lab environment featuring specialized arm-wrestling strength equipment: heavy steel loading pins, thick-grip rolling thunder handles, pronation straps, and calibrated iron plates racked in dramatic side-lighting. |
| **Main subject** | Arm-wrestling specific cable attachment, pronation strap, and calibrated weight plates in the upper-right and lower-left periphery. |
| **Environment** | Elite dark iron performance lab with brushed steel surfaces and chalked knurling. |
| **Composition** | Upper 28% (`y: 0%–28%`) shows cable pulley/strap hardware in moody rim light; center (`y: 28%–75%`) is dark matte charcoal behind the PR and workout log cards; bottom 25% shows iron plates on a gym floor. |
| **Aspect ratio** | `9:16` |
| **Resolution** | `1080 × 1920` |
| **Focal point** | `Alignment(0.0, -0.45)` |
| **Empty space** | Middle 50% (`y: 25%–75%`) for PR chips and training log list cards. |
| **Lighting and atmosphere** | High-contrast steel rim lighting with subtle emerald (`#10B981`) and gold performance accents. |
| **Image treatment** | `BoxFit.cover`, `opacity: 0.46`, vertical vignette. |
| **Motion potential** | Low. |
| **Customization** | No. |
| **Priority** | **High (Tier 1)** |

---

#### 12. `match.head_to_head.background` (Tale of the Tape VS Stage)
| Field | Specification |
|---|---|
| **Placement ID** | `match.head_to_head.background` |
| **Current image** | `assets/images/heroes/m1_hero_arena.webp` |
| **Screen** | Head-to-Head Tale of the Tape (`HeadToHeadScreen`) |
| **Route** | `/head-to-head` |
| **Widget** | `CrystalStageBackdrop` |
| **Source file** | `apps/mobile/lib/features/match/screens/head_to_head_screen.dart:572` |
| **Purpose** | Biometric and ELO comparison screen pitting two athletes side-by-side (Red Corner on left vs. Blue Corner on right) across bicep, forearm, wrist, win rate, and common opponents. |
| **Image role** | Full-screen portrait stage backdrop (`9:16`). |
| **Replacement concept** | Symmetrical split-duality `9:16` broadcast stage: a subtle vertical center laser/light seam dividing a deep crimson-lit left architectural wing from a deep ice-cyan/slate-lit right architectural wing, with an overhead competition table silhouette at the top center. |
| **Main subject** | Split Red Corner (left) vs. Blue Corner (right) broadcast light architecture and center division axis. |
| **Environment** | Pay-per-view superfight broadcast studio. |
| **Composition** | Strict vertical symmetry around `x: 50%`: left half (`x: 0%–48%`) has warm crimson atmospheric depth behind Athlete A; right half (`x: 52%–100%`) has cool cyan/steel depth behind Athlete B. |
| **Aspect ratio** | `9:16` |
| **Resolution** | `1080 × 1920` |
| **Focal point** | `Alignment(0.0, -0.35)` |
| **Empty space** | Center body (`y: 20%–85%`) kept free of hard geometric clutter so horizontal comparison bars read cleanly. |
| **Lighting and atmosphere** | Dual-tone Crimson (`#E23B3B`) vs. Cyan (`#38BDF8`) on `#070A11` obsidian. |
| **Image treatment** | `BoxFit.cover`, `opacity: 0.48`, vertical vignette. |
| **Motion potential** | Medium — subtle center energy seam pulse. |
| **Customization** | No. |
| **Priority** | **High (Tier 1)** |

---

#### 13. `discover.home.background` (Discover & Search Stage)
| Field | Specification |
|---|---|
| **Placement ID** | `discover.home.background` |
| **Current image** | `assets/images/heroes/m1_hero_grip.webp` |
| **Screen** | Discover Hub (`/discover`) & Global Search (`/search`) |
| **Route** | `/discover`, `/search` |
| **Widget** | `CrystalStageBackdrop(domain: ArmSphereStageDomain.discover)` |
| **Source file** | `apps/mobile/lib/features/home/screens/discover_screen.dart:464` & `search_screen.dart:113` |
| **Purpose** | Ecosystem discovery hub for exploring athletes, clubs, pickup meetups, rankings, and federation bulletins. |
| **Image role** | Full-screen portrait stage backdrop (`9:16`). |
| **Replacement concept** | Wide architectural view of a global federation hall with subtle illuminated world-map/compass grid arcs in the upper sky and dark brushed-slate architectural columns framing the edges. |
| **Main subject** | Subtle federation globe/compass light geometry in the upper 30% (`y: 5%–32%`). |
| **Environment** | Modern dark titanium sports network hub. |
| **Composition** | Upper 30% features subtle architectural/network light lines behind the search bar and filter pills; lower 70% transitions into deep obsidian slate behind the Bento grid and athlete cards. |
| **Aspect ratio** | `9:16` |
| **Resolution** | `1080 × 1920` |
| **Focal point** | `Alignment(0.0, -0.60)` |
| **Empty space** | `y: 25%–90%` kept calm so the 4 Bento portal cards and horizontal carousels pop with zero background interference. |
| **Lighting and atmosphere** | Obsidian, brushed steel, and subtle cyan/gold optical accents. |
| **Image treatment** | `BoxFit.cover`, `opacity: 0.42`, vertical vignette. |
| **Motion potential** | Low. |
| **Customization** | No. |
| **Priority** | **Medium (Tier 2)** |

---

#### 14. `teams.directory.background` & `teams.profile.cover` (Clubs & Teams Identity Stage)
| Field | Specification |
|---|---|
| **Placement ID** | `teams.directory.background` |
| **Current image** | `assets/images/heroes/m1_hero_grip.webp` (currently mapped to `ArmSphereStageDomain.discover`) |
| **Screen** | Clubs & Teams Directory (`/teams`), Team Profile (`/team/:id`), Create Team (`/team/create`) |
| **Route** | `/teams`, `/team/:id`, `/team/create` |
| **Widget** | `CrystalStageBackdrop` |
| **Source file** | `apps/mobile/lib/features/team/screens/team_screens.dart:70, 682, 1862` |
| **Purpose** | Team rosters, club crests, collective ELO power ratings, and club membership management. |
| **Image role** | Full-screen stage backdrop (`9:16`) and Team Header Cover (`16:9` top slice). |
| **Replacement concept** | Dramatic low-angle view of a circle of club teammates standing around two practice arm-wrestling tables in a rugged iron gym, banners hanging from the ceiling rafters in the upper frame, lit by warm gold and emerald rim light. |
| **Main subject** | Club practice tables and silhouetted team brotherhood in the upper third (`y: 8%–38%`). |
| **Environment** | Authentic arm-wrestling club headquarters with rafters, banners, and chalked tables. |
| **Composition** | Upper third (`y: 5%–38%`) establishes the club environment; lower two-thirds (`y: 38%–100%`) fades into dark charcoal slate behind team roster cards. |
| **Aspect ratio** | `9:16` |
| **Resolution** | `1080 × 1920` |
| **Focal point** | `Alignment(0.0, -0.50)` |
| **Empty space** | Middle and lower zones (`y: 35%–95%`) for team stats and member lists. |
| **Lighting and atmosphere** | Warm industrial gold and emerald (`#10B981`) club pride atmosphere. |
| **Image treatment** | `BoxFit.cover`, `opacity: 0.46`, vertical vignette. |
| **Motion potential** | Low. |
| **Customization** | Yes (team captains can eventually set custom club cover art). |
| **Priority** | **Medium (Tier 2)** |

---

#### 15. `events.directory.background` & `events.tournament.detail_hero` (Sanctioned Tournaments Stage & Default Poster)
| Field | Specification |
|---|---|
| **Placement ID** | `events.tournament.detail_hero` (and `events.directory.background`) |
| **Current image** | `assets/images/defaults/tournament_poster.webp` (`720×405` low-res file reused as both global fallback and tournament header) |
| **Screen** | Tournament Detail (`TournamentDetailScreen`) & Tournaments Directory (`TournamentListScreen`) |
| **Route** | `/tournament/:id`, `/tournaments` |
| **Widget** | `SliverAppBar.flexibleSpace` (`tournament_screens.dart:409`) & `CrystalStageBackdrop(domain: ArmSphereStageDomain.events)` |
| **Source file** | `apps/mobile/lib/features/tournament/screens/tournament_screens.dart:112, 377, 409` |
| **Purpose** | Official tournament showcase header (`240dp` parallax `SliverAppBar`) and sanctioned events stage backdrop. |
| **Image role** | Widescreen `16:9` Championship Event Hero Banner (and vertical stage backdrop). |
| **Replacement concept** | High-resolution `16:9` grand championship stage perspective: an elevated center-stage arm-wrestling table flanked by golden championship trophies/belts on podium pedestals, dramatic vertical pyrotechnic/spotlight beams in the background, and a darkened lower third for the tournament title overlay. |
| **Main subject** | Center-stage championship table and gold trophy pedestal (`x: 20%–80%`, `y: 12%–68%`). |
| **Environment** | Grand Prix international championship arena stage. |
| **Composition** | Upper two-thirds (`y: 0%–66%`) showcases the illuminated championship stage and lighting rig; bottom third (`y: 66%–100%`) is dark shadowed stage floor so the bottom-pinned white tournament title (`22sp`), status chip (`PUBLISHED`/`ONGOING`), countdown timer, and location pin are 100% legible. |
| **Aspect ratio** | `16:9` |
| **Resolution** | `1920 × 1080` (replacing the `720 × 405` low-res asset) |
| **Focal point** | `Alignment(0.0, -0.20)` |
| **Empty space** | Bottom 35% (`y: 65%–100%`, `x: 0%–100%`) reserved for the tournament title and metadata overlay; top-left/top-right (`y: 0%–20%`) kept clean for the back, share, and home buttons. |
| **Lighting and atmosphere** | Champagne gold (`#D4AF37`), crimson (`#E23B3B`), and obsidian championship broadcast lighting. |
| **Image treatment** | `BoxFit.cover`, `AppTheme.heroScrim()` 4-stop vertical gradient overlay. |
| **Motion potential** | High — stage spotlight shimmer. |
| **Customization** | Yes — tournament organizers can supply `event['imageUrl']` per tournament. |
| **Priority** | **High (Tier 1)** |

---

#### 16. `championship.belts_list.background` (Championship Belts & Lineage Hall Stage)
| Field | Specification |
|---|---|
| **Placement ID** | `championship.belts_list.background` |
| **Current image** | `assets/images/defaults/tournament_poster.webp` |
| **Screen** | Championship Belts Hall (`/championships`), Belt Lineage Detail (`/championship/:id`), Awards Ceremony (`/tournament/:id/awards`) |
| **Route** | `/championships`, `/championship/:id`, `/tournament/:id/awards` |
| **Widget** | `CrystalStageBackdrop` |
| **Source file** | `apps/mobile/lib/features/championship/screens/championship_screens.dart:52, 245` & `tournament_awards_ceremony_screen.dart:287` |
| **Purpose** | Showcases reigning divisional titleholders, historical championship belt lineage, title defenses, and official gold/silver/bronze tournament podium ceremonies. |
| **Image role** | Full-screen portrait stage backdrop (`9:16`). |
| **Replacement concept** | Regal `9:16` Hall of Champions vault: a macro view of an ornate leather-and-24k-gold arm-wrestling world championship belt resting on a dark black-marble pedestal in the upper third, with subtle golden bokeh dust rising into obsidian darkness. |
| **Main subject** | Heavy gold championship belt plate with embossed arm-wrestling motif (`y: 8%–35%`). |
| **Environment** | Prestige championship vault with black marble and warm gold museum-grade spotlighting. |
| **Composition** | Belt centerpiece in the upper third (`y: 8%–35%`); deep obsidian lower two-thirds (`y: 35%–100%`) behind the divisional champion cards and lineage timeline. |
| **Aspect ratio** | `9:16` |
| **Resolution** | `1080 × 1920` |
| **Focal point** | `Alignment(0.0, -0.50)` |
| **Empty space** | `y: 35%–95%` for belt holder cards and "Challenge Champion" / "Manage Reign" controls. |
| **Lighting and atmosphere** | Museum-grade 24k gold specular rim light against `#070A11` obsidian. |
| **Image treatment** | `BoxFit.cover`, `opacity: 0.46`, vertical vignette. |
| **Motion potential** | Medium — subtle gold dust particles. |
| **Customization** | No. |
| **Priority** | **High (Tier 1)** |

---

#### 17. `rankings.leaderboard.background` (Global & National Rankings Stage)
| Field | Specification |
|---|---|
| **Placement ID** | `rankings.leaderboard.background` |
| **Current image** | `assets/images/heroes/m1_hero_arena.webp` |
| **Screen** | Global & National ELO Rankings (`RankingsScreen`) & Talent Nominations (`MyNominationsScreen`) |
| **Route** | `/rankings`, `/nominations` |
| **Widget** | `CrystalStageBackdrop(domain: ArmSphereStageDomain.rankings)` |
| **Source file** | `apps/mobile/lib/features/athlete/screens/rankings_screen.dart:131` |
| **Purpose** | Official federation ELO leaderboard filtered by arm (Right/Left), weight division, and country, featuring the top-3 podium and ranked athlete rows. |
| **Image role** | Full-screen portrait stage backdrop (`9:16`). |
| **Replacement concept** | Vertical `9:16` monument-style composition of a 3-tier black titanium championship podium (`#1` center elevated, `#2` left, `#3` right) illuminated by crisp overhead cyan and gold laser beams in the upper 35% of the frame, fading into a machined steel grid floor below. |
| **Main subject** | Illuminated 3-step championship podium in the upper third (`y: 8%–36%`). |
| **Environment** | High-tech federation rankings hall with cyan (`#38BDF8`) and gold (`#D4AF37`) light geometry. |
| **Composition** | Podium aligned with the top-3 header zone (`y: 8%–36%`); clean dark slate below (`y: 36%–100%`) for ranked athlete list rows. |
| **Aspect ratio** | `9:16` |
| **Resolution** | `1080 × 1920` |
| **Focal point** | `Alignment(0.0, -0.52)` |
| **Empty space** | `y: 36%–100%` for dense tabular ranking rows. |
| **Lighting and atmosphere** | Cool titanium cyan and championship gold on `#070A11`. |
| **Image treatment** | `BoxFit.cover`, `opacity: 0.44` + `texKnurl` overlay. |
| **Motion potential** | Low. |
| **Customization** | No. |
| **Priority** | **Medium (Tier 2)** |

---

#### 18. `referee.hub.background` (Referee Officiating & Live Scorepad Stage)
| Field | Specification |
|---|---|
| **Placement ID** | `referee.hub.background` |
| **Current image** | `assets/images/heroes/m1_hero_arena.webp` |
| **Screen** | Referee Hub (`/referee`), Official Live Scorepad (`/referee/scorepad/:id`), Certification, Disputes & Officiating History |
| **Route** | `/referee`, `/referee/scorepad/:id`, `/referee/certification`, `/referee/disputes`, `/referee/history` |
| **Widget** | `CrystalStageBackdrop(domain: ArmSphereStageDomain.referee)` |
| **Source file** | `apps/mobile/lib/features/referee/screens/referee_screens.dart:282` & `official_scorepad_screen.dart:270` |
| **Purpose** | Tactical officiating console for head/side referees to manage table calls, run the live round timer, record elbow/false-start fouls, and lock official match pins. |
| **Image role** | Full-screen portrait stage backdrop (`9:16`). |
| **Replacement concept** | Referee's-eye top-down/45-degree perspective of an official competition arm-wrestling table: crisp white foul/center lines, brass/steel peg posts, Touch/Pin pads, and a black-and-white striped referee cuff/whistle resting at the table edge under cool studio task lighting. |
| **Main subject** | Competition table surface geometry, pin pads, and referee strap/whistle (`y: 10%–40%`). |
| **Environment** | Precision officiating table zone with clean technical lines and zero distracting crowd clutter. |
| **Composition** | Upper third (`y: 8%–36%`) highlights the referee table lines and pin pad; lower two-thirds (`y: 36%–100%`) is deep dark gunmetal so foul counters, round timers, and score buttons have maximum tactical clarity. |
| **Aspect ratio** | `9:16` |
| **Resolution** | `1080 × 1920` |
| **Focal point** | `Alignment(0.0, -0.48)` |
| **Empty space** | `y: 32%–100%` must remain very dark and uniform for live scorepad controls. |
| **Lighting and atmosphere** | Crisp white/silver referee task lighting with subtle gold certification accents on `#070A11`. |
| **Image treatment** | `BoxFit.cover`, `opacity: 0.40` + `texKnurl` overlay. |
| **Motion potential** | Low (avoid motion distraction during live match officiating). |
| **Customization** | No. |
| **Priority** | **Medium (Tier 2)** |

---

#### 19. `admin.command.background` (Federation Governance & Command Stage)
| Field | Specification |
|---|---|
| **Placement ID** | `admin.command.background` |
| **Current image** | `assets/images/heroes/m1_hero_arena.webp` |
| **Screen** | Admin Command Center (`/admin/command`), Admin Governance (`/admin/governance`), Admin Dossier (`/admin/dossier`), Admin Roster (`/admin/roster`), Admin Arena Ops (`/admin/arena-ops`) |
| **Route** | `/admin/command`, `/admin/governance`, `/admin/dossier`, `/admin/roster`, `/admin/arena-ops` |
| **Widget** | `CrystalStageBackdrop(domain: ArmSphereStageDomain.governance)` |
| **Source file** | `apps/mobile/lib/features/admin/screens/admin_command_screen.dart:621` & `admin_governance_screen.dart:625` |
| **Purpose** | Executive sports federation command center for national/provincial directors and system admins to review athlete sanctions, manage ELO distribution, oversee live arena operations, and audit cryptographic ledger integrity. |
| **Image role** | Full-screen portrait stage backdrop (`9:16`). |
| **Replacement concept** | Architectural view of a dark, modern sports federation control room / boardroom overlooking a glass-walled arena below, with subtle gold federation seal geometry and dark brushed-titanium wall panels. |
| **Main subject** | Executive federation control suite architecture and subtle holographic seal watermark in the upper 30%. |
| **Environment** | High-trust institutional sports federation headquarters in obsidian, charcoal, and muted gold. |
| **Composition** | Upper 28% (`y: 5%–28%`) shows architectural depth and control glass; lower 72% (`y: 28%–100%`) is ultra-clean dark obsidian-slate so dense admin data tables, ELO bars, and audit logs remain effortless to read. |
| **Aspect ratio** | `9:16` |
| **Resolution** | `1080 × 1920` |
| **Focal point** | `Alignment(0.0, -0.55)` |
| **Empty space** | `y: 25%–95%` kept very dark and low-contrast for high-density administrative telemetry. |
| **Lighting and atmosphere** | Restrained institutional gold (`#D4AF37`) and cool steel blue (`#38BDF8`) on `#070A11`. |
| **Image treatment** | `BoxFit.cover`, `opacity: 0.38` + `texKnurl` overlay. |
| **Motion potential** | Low. |
| **Customization** | No. |
| **Priority** | **Medium (Tier 2)** |

---

#### 20. `venues.directory.background` (Training Venues & Informal Pickup Stage)
| Field | Specification |
|---|---|
| **Placement ID** | `venues.directory.background` |
| **Current image** | `assets/images/defaults/club_banner.webp` (`720×405` low-res file) |
| **Screen** | Training Venues Directory (`/venues`), Venue Detail (`/venue/:id`), Pickup Meetups Directory (`/informal-events`), Pickup Meetup Detail (`/informal-event/:id`) |
| **Route** | `/venues`, `/venue/:id`, `/informal-events`, `/informal-event/:id` |
| **Widget** | `CrystalStageBackdrop(domain: ArmSphereStageDomain.venues)` |
| **Source file** | `apps/mobile/lib/features/venue/screens/venue_directory_screen.dart:63` & `informal_event_directory_screen.dart:75` |
| **Purpose** | Discovering verified local arm-wrestling tables, gyms, practice hours, and open sparring sessions. |
| **Image role** | Full-screen portrait stage backdrop (`9:16`). |
| **Replacement concept** | Vertical `9:16` atmospheric shot of a dedicated arm-wrestling training room: two regulation practice tables in the upper third lit by industrial overhead lamps, chalk dust hanging in the air, and dark rubberized gym flooring extending into the lower frame. |
| **Main subject** | Regulation practice tables and chalk station in an authentic training hall (`y: 8%–38%`). |
| **Environment** | Hardcore arm-wrestling gym / practice venue. |
| **Composition** | Upper third (`y: 8%–38%`) showcases the training tables; lower two-thirds (`y: 38%–100%`) fades into dark gym flooring behind venue directory cards. |
| **Aspect ratio** | `9:16` |
| **Resolution** | `1080 × 1920` |
| **Focal point** | `Alignment(0.0, -0.48)` |
| **Empty space** | `y: 35%–95%` for venue cards, GPS distance chips, and table counts. |
| **Lighting and atmosphere** | Warm tungsten/gold overhead gym lamps with subtle emerald accents on dark slate. |
| **Image treatment** | `BoxFit.cover`, `opacity: 0.46`, vertical vignette. |
| **Motion potential** | Low. |
| **Customization** | No. |
| **Priority** | **Medium (Tier 2)** |

---

#### 21. `passport.profile.background` (Athlete Passport & Security Vault Stage)
| Field | Specification |
|---|---|
| **Placement ID** | `passport.profile.background` |
| **Current image** | `assets/images/heroes/m1_hero_grip.webp` |
| **Screen** | Athlete Passport & Profile (`/athlete/profile`) & Settings / Security Vault (`/settings/*`) |
| **Route** | `/athlete/profile`, `/settings`, `/settings/*` |
| **Widget** | `CrystalStageBackdrop(domain: ArmSphereStageDomain.passport)` |
| **Source file** | `apps/mobile/lib/features/athlete/screens/athlete_screens.dart:3918` & `settings_hub_screens.dart:36` |
| **Purpose** | Official Federation Athlete Passport displaying verified biometrics, division insignia, career win/loss ledger, achievements, and account security settings. |
| **Image role** | Full-screen portrait stage backdrop (`9:16`). |
| **Replacement concept** | Vertical `9:16` luxury titanium vault & athlete dressing-room atmosphere: subtle brushed-titanium architectural ribs and warm studio rim lights in the upper third, framing the centered circular athlete portrait (`y: 10%–28%`), transitioning into deep obsidian carbon below. |
| **Main subject** | Studio rim-light halo and brushed-titanium architectural ribs in the upper third (`y: 6%–32%`). |
| **Environment** | Elite athlete locker/prep studio and federation credential vault. |
| **Composition** | Symmetrical halo framing the top-center avatar zone (`x: 25%–75%`, `y: 8%–30%`); dark low-contrast body (`y: 30%–100%`) behind passport credential cards. |
| **Aspect ratio** | `9:16` |
| **Resolution** | `1080 × 1920` |
| **Focal point** | `Alignment(0.0, -0.55)` |
| **Empty space** | `y: 30%–95%` for biometric tiles, division badges, and settings rows. |
| **Lighting and atmosphere** | Champagne gold (`#D4AF37`) and crimson rim glow on dark brushed titanium (`#0B0F17`). |
| **Image treatment** | `BoxFit.cover`, `opacity: 0.46`, vertical vignette. |
| **Motion potential** | Low. |
| **Customization** | Yes — user-customizable via `VisualCustomizeSlot.screenBackdrop`. |
| **Priority** | **Medium (Tier 2)** |

---

### C.4 Specialized In-Screen Media Cards & Default Fallbacks

| # | Placement ID | Screen & Route | Source File & Line | Current Image | Recommended Replacement Concept & Composition | Aspect Ratio & Resolution | Priority |
|---|---|---|---|---|---|---|---|
| **22** | `community.feed.sparring_fallback_card` | Community Feed & Reels (`/community`) | `community_feed_screen.dart:327, 508, 781` | `m1_hero_grip.webp` | **Technique & Sparring Clip Fallback Plate**: Cinematic `16:9` close-up of two chalked hands demonstrating a high-knuckle toproll setup over a table pad, with subtle camera viewfinder corner marks and dark center space for the play button overlay. | `16:9` (`1280 × 720`) | **Low (Tier 3)** |
| **23** | `community.feed.match_fallback_card` | Community Feed & Reels (`/community`) | `community_feed_screen.dart:328, 508, 782` | `m1_hero_arena.webp` | **Tournament Match Clip Fallback Plate**: `16:9` broadcast camera angle of a live tournament match table under stage lights with a referee crouched at center table, leaving the center clear for the `56×56` play button. | `16:9` (`1280 × 720`) | **Low (Tier 3)** |
| **24** | `events.tournament.live_stream_card` | Tournament Detail Live Stream Card (`/tournament/:id`) | `live_stream_card_widget.dart:181` | Raw `NetworkImage` or empty gradient | **Official Broadcast Stream Standby Plate**: `16:9` multi-camera broadcast production view of a championship table with "LIVE BROADCAST FEED" optical lens flare in dark crimson and gold, wired through `ArmSphereImage`. | `16:9` (`1280 × 720`) | **Medium (Tier 2)** |
| **25** | `profile.avatar.default_fallback` | All Athlete / Opponent / Leaderboard Avatars (`ArmSphereImage.avatar`) | `armsphere_image.dart:108` (`avatar_neutral_dark.webp`) | `avatar_neutral_dark.webp` (`256×256` low-res) | **High-Res Neutral Athlete Silhouette Portrait**: Crisp `512 × 512` (`1:1`) front-facing studio rim-lit silhouette of an athlete's head and traps on a `#0B0F17` dark slate background, centered with generous circular crop headroom (`x: 18%–82%`, `y: 12%–92%`). | `1:1` (`512 × 512`) | **Medium (Tier 2)** |
| **26** | `auth.gateway.background` | Login, Register, Role Intent, Forgot/Reset Password & Onboarding (`/login`, `/register`, `/role-intent`, `/onboarding`) | `login_screen.dart:170`, `register_screen.dart:98`, `role_intent_screen.dart:198` | `m1_hero_arena.webp` | **Authentication Gateway Stage Backdrop**: Dedicated `9:16` dark architectural tunnel leading out toward a bright stadium stage light in the upper distance—symbolizing "walking out into the arena" while keeping the center glass auth form cards (`y: 20%–85%`) over calm obsidian shadow. | `9:16` (`1080 × 1920`) | **Medium (Tier 2)** |

---

## Part D — Visual Evidence & Real UI Overlay Analysis

### D.1 Existing Captured Visual Evidence in Repository
The workspace contains 39 actual screen captures in `public/assets/aistudio/` documenting the current placements and their UI overlays:
- **Primary Athlete Dashboard & Hero Card**:
  - `public/assets/aistudio/Shadowed_Hero_in_Crimson_Smoke_37693bf7.png` — The newly integrated default artwork for `profile.athlete.dashboard_hero`.
  - `public/assets/aistudio/Screenshot_20261103-205412_60229083.png` & `Screenshot_20261103-205418_baef8748.png` — Athlete Dashboard showing the top Brand Header (`m0_icon_gold.webp`), Sanctioned Arena Radar (`m1_hero_arena.webp`), Athlete Hero Card, Competitive Standing ELO rail, and Upcoming Supermatch card (`m1_hero_grip.webp`).
- **Discover Hub & 2×2 Bento Portal Tiles**:
  - `public/assets/aistudio/Screenshot_20261103-205422_68c38cc2.png` & `Screenshot_20261103-205430_52a781f4.png` — Shows the 4 Federation Hub Bento tiles (`Training Venues`, `Pickup Meetups`, `Community Feed`, `ELO Rankings`) reusing `club_banner.webp`, `m1_hero_grip.webp`, `m1_hero_arena.webp`, and `tournament_poster.webp`.
- **Tournaments, Community Feed & Passport**:
  - `public/assets/aistudio/Screenshot_20261103-205434_c62956d5.png`, `Screenshot_20261103-205436_530871f5.png`, `Screenshot_20261103-205445_50a83d8c.png`, `Screenshot_20261103-205454_7e69eb08.png` — Shows Tournament cards, Community Feed video cards, and Athlete Passport screens.
- **Admin Command, Roster, Arena Ops & Governance**:
  - `public/assets/aistudio/Screenshot_20261103-205457_599f99fe.png`, `Screenshot_20261103-205501_360cf36a.png`, `Screenshot_20261103-205513_1ec9fe13.png`, `Screenshot_20261103-205521_3ead8308.png` — Shows the Admin screens sharing `CrystalStageBackdrop`.

### D.2 Exact Visible vs. Occluded Zones by Placement Type
1. **Athlete Dashboard Hero Card (`profile.athlete.dashboard_hero`)**:
   - **Visible Zone**: Left 38% (`x: 0%–38%`, `y: 14%–78%`) is completely unobstructed at `0.94` opacity so the athlete figure commands the card.
   - **Occluded / Overlay Zone**: Top 14% has `VERIFIED` (left) and `PAFF COMPETITOR` (right) badges; Right 62% (`x: 38%–100%`, `y: 16%–76%`) carries the Athlete Name (`22sp`), Country/Club line, and ELO Callout container over a dark horizontal scrim; Bottom 22% (`y: 78%–100%`) carries the 4-stat ribbon (`WORLD RANK`, `WEIGHT`, `WIN RATE`, `DISCIPLINE`) and `#1` watermark.
2. **Sanctioned Arena Radar Card (`arena.home.radar_card`)**:
   - **Visible Zone**: Right-center (`x: 55%–82%`) between the text stack and the "Explore >" button.
   - **Occluded / Overlay Zone**: Left 60% is covered by 3 stacked text lines; far right (`x: 82%–96%`) is covered by the machined titanium "Explore >" button.
3. **Upcoming Supermatch Card (`arena.home.supermatch_card`)**:
   - **Visible Zone**: Center vertical band (`x: 36%–64%`) around the `VS` emblem and upper/lower atmospheric margins.
   - **Occluded / Overlay Zone**: Top header row (`LIVE SUPERMATCH` / status chip), Left & Right fighter identity columns, and bottom action bar (`VIEW BRACKET`).
4. **Discover 2×2 Bento Portal Tiles (`discover.hub.*_tile`)**:
   - **Visible Zone**: Upper-right and center-right (`x: 38%–96%`, `y: 12%–68%`).
   - **Occluded / Overlay Zone**: Top-left icon + category chip (`DIRECTORY`, `SPARRING`, `SOCIAL`, `STANDINGS`) and bottom-left title + subtitle (`y: 65%–95%`).
5. **Tournament Detail SliverAppBar (`events.tournament.detail_hero`)**:
   - **Visible Zone**: Upper 65% (`y: 0%–65%`) of the `240dp` parallax header.
   - **Occluded / Overlay Zone**: Bottom 35% (`y: 65%–100%`) is covered by the status chip, countdown badge, 2-line tournament title, and location row over `AppTheme.heroScrim()`.
6. **Full-Screen Stage Backdrops (`CrystalStageBackdrop`)**:
   - **Visible Zone**: Top 28% (`y: 0%–28%`, visible through the transparent app bar and around header titles), inter-card vertical gaps (`12–16dp`), and bottom margins.
   - **Occluded / Overlay Zone**: Middle 55% (`y: 25%–80%`) is ~75% covered by smoked dark glass cards (`#D1101622`, ~82% opacity), meaning full-screen stage artworks must put their main architectural focal points in the **upper 30%** (`y: 5%–32%`) and keep the middle 50% calm and dark.

---

## Part E — Image Reuse & Retirement Decisions

### E.1 Placements That MUST Receive Unique Artwork (Eliminating False Reuse)
1. **`arena.home.radar_card`** — Must not share the full-screen background image (`heroArena`); needs a dedicated `21:9` horizontal stage-table ribbon artwork.
2. **`arena.home.supermatch_card`** — Must not share the Discover/Passport background (`heroGrip`); needs a symmetrical Red-vs-Blue corner VS table artwork.
3. **`arena.home.no_bouts_card`** — Must not share the active tournament poster (`tournament_poster.webp`); needs a quiet "standby spotlighted table" artwork.
4. **All 4 Discover Bento Portal Tiles (`discover.hub.venues_tile`, `pickup_meetups_tile`, `community_feed_tile`, `elo_rankings_tile`)** — Currently reuse the 4 global backgrounds on the same screen simultaneously; each tile needs its own distinct `4:3` feature artwork.
5. **`training.log.background`** — Currently reuses `heroArena`; needs a dedicated Strength & Performance Lab (`9:16`) backdrop.
6. **`match.head_to_head.background`** — Currently reuses `heroArena`; needs a dedicated split Red/Blue Tale of the Tape (`9:16`) backdrop.
7. **`championship.belts_list.background`** — Currently reuses `tournament_poster.webp`; needs a dedicated Hall of Champions Gold Belt Vault (`9:16`) backdrop.
8. **`rankings.leaderboard.background`**, **`referee.hub.background`**, and **`admin.command.background`** — Currently all 3 domains (`rankings`, `referee`, `governance`) point to the exact same `kArmSphereProPresets[4]` (`heroArena` + `texKnurl`) in `VisualPreferencesState._defaultPresetForDomain`! Each of these three domains must receive its own distinct `9:16` stage artwork.

### E.2 Placements That Should Intentionally Share Assets
1. **Authentication Flow Sub-Screens (`/login`, `/register`, `/role-intent`, `/forgot-password`, `/reset-password`, `/onboarding`)** — Should intentionally share one cohesive `auth.gateway.background` stage artwork so transitioning between Login, Register, and Onboarding feels like a unified walkout sequence.
2. **Settings, Security & Account Sub-Screens (`/settings`, `/settings/security`, `/settings/roles`, `/settings/payments`, `/sessions`, `/support`, `/mfa-*`)** — Should intentionally share the `passport.profile.background` titanium vault backdrop.
3. **Referee Sub-Screens (`/referee`, `/referee/scorepad/:id`, `/referee/certification`, `/referee/disputes`, `/referee/history`)** — Should intentionally share the new `referee.hub.background` officiating backdrop.
4. **Admin Console Tabs (`/admin/command`, `/admin/roster`, `/admin/arena-ops`, `/admin/governance`, `/admin/dossier`)** — Should intentionally share the new `admin.command.background` executive control suite backdrop for visual continuity across the 5 bottom tabs of the Admin shell.
5. **Atmospheric Overlay Textures (`m1_tex_chalk.webp`, `m1_tex_knurl.webp`), Brand Emblems (`m0_icon_gold.webp`, `m0_seal_fed.webp`), and Official Division/Referee Insignia (`m4_bdg_*`, `m4_ref_*`)** — Legitimate system-wide design tokens that should remain shared across the app.

### E.3 Retirement vs. Retention Decisions
- **Retain**:
  - `m1_hero_athlete_dashboard.webp`, `m1_card_arena_radar.webp`, `m1_card_supermatch_vs.webp`, `m1_bento_venues.webp`, `m1_bento_pickup_sparring.webp`, `m1_bento_community_feed.webp`, `m1_bento_elo_rankings.webp`, `tournament_poster.webp` (`2752×1536`), `m1_hero_welcome_grip.webp`, `m1_stage_arena_9x16.webp`, and `m1_stage_training_lab_9x16.webp` (Approved and integrated WebP artworks).
  - `m1_tex_chalk.webp` & `m1_tex_knurl.webp` (Effective atmospheric texture overlays).
  - `m0_icon_gold.webp`, `m0_logo_full.webp`, `m0_seal_fed.webp` (Canonical brand emblems).
  - `m4_bdg_*.webp` & `m4_ref_*.webp` (8 division & referee certification badges).
- **Retire / Replace**:
  - `m1_hero_arena.webp`, `m1_hero_grip.webp`, `tournament_poster.webp` (`720×405`), and `club_banner.webp` (`720×405`) should be progressively retired from their over-reused placements as each purpose-built replacement artwork is approved and integrated.

---

## Part F — Current Infrastructure & Replacement Readiness Audit

### F.1 Existing Infrastructure Assessment
We inspected `ArmSphereAssets` (`lib/core/constants/asset_paths.dart`), `ArmSphereImage` (`lib/core/widgets/armsphere_image.dart`), `VisualPreferencesState` (`lib/core/providers/visual_preferences_provider.dart`), and `CrystalStageBackdrop` (`lib/core/widgets/crystal_stage_scaffold.dart`):
1. **Semantic Asset Catalog (`ArmSphereAssets.semanticCatalog` & `resolveSemanticAsset`)**:
   - Already implemented and active in `asset_paths.dart` and `ArmSphereImage`! Passing any semantic key (such as `'profile.athlete.dashboard_hero'`) to `ArmSphereImage(assetPath: ...)` or `ArmSphereAssets.resolveSemanticAsset(...)` automatically resolves to its physical asset path.
2. **Focal Alignment & Fit Control (`ArmSphereImage.alignment` & `fit`)**:
   - Already implemented and active! Every `ArmSphereImage` supports custom `Alignment(x, y)` focal positioning, `BoxFit`, memory-bounded `cacheWidth`/`cacheHeight`, and the 3-level offline-safe fallback ladder.
3. **User Customization & Persistence (`VisualPreferencesNotifier`)**:
   - Supports user-uploaded or preset images for `portrait`, `heroCard` (`profile.athlete.dashboard_hero`), and `screenBackdrop` (`arena` / `passport`), persisted locally in Hive (`armsphere_visual_prefs`).

### F.2 Placement Readiness Classification
| Readiness Category | Placements Included | How to Integrate Approved Artwork |
|---|---|---|
| **Category 1: Semantic Slot Ready Now** | `profile.athlete.dashboard_hero`, `profile.athlete.dashboard_portrait` | Already wired to `ArmSphereAssets.semanticCatalog` and `VisualPreferencesState.resolveAthleteHeroConfig`. Drop in asset and update `semanticCatalog` map entry. |
| **Category 2: Domain Stage Preset Slot (`CrystalStageBackdrop`)** | All 56 full-screen stage backdrops (`arena`, `discover`, `events`, `community`, `passport`, `rankings`, `venues`, `referee`, `governance`) | Add the approved `9:16` asset path to `ArmSphereAssets` and update `_defaultPresetForDomain(domain)` in `visual_preferences_provider.dart` (plus pass explicit `stageDomain` to the 4 `StickyFormScaffold` screens). |
| **Category 3: Direct `ArmSphereAssets` Constant in Card Widget** | `arena.home.radar_card`, `arena.home.supermatch_card`, `arena.home.no_bouts_card`, `auth.welcome.hero_banner`, `discover.hub.*_tile` (4 tiles), `events.tournament.detail_hero`, `community.feed.post_media_card` | Register the placement's semantic ID in `ArmSphereAssets.semanticCatalog` and point the widget's `assetPath` / `fallbackAsset` to the semantic ID. |
| **Category 4: Bypassing `ArmSphereImage` (Needs 1-Line Wrapper Swap)** | `events.tournament.live_stream_card` (`live_stream_card_widget.dart:181` uses `DecorationImage(NetworkImage)`), `events.tournament.participants_avatar` (`participants_carousel_widget.dart:276, 499` uses raw `Image.network`) | Replace raw `NetworkImage`/`Image.network` with `ArmSphereImage` / `ArmSphereImage.avatar` when integrating their approved fallback assets. |

---

## Part G — Recommended Production Priority Queue

To maximize visual impact per image created, we recommend creating and approving replacement images one at a time in the following priority order:

### Tier 1 — High-Impact Hero Cards & Primary Visible Surfaces (Create First)
1. **`arena.home.radar_card`** — Top of Athlete Dashboard ("Sanctioned Arena Radar" `21:9` stage table ribbon).
2. **`arena.home.supermatch_card`** — Athlete Dashboard Broadcast Fight Card (`16:9` Red vs. Blue Corner table clash).
3. **`discover.hub.venues_tile`** — Discover 2×2 Bento Card 1: Training Venues (`4:3` elite club gym & cable rig).
4. **`discover.hub.pickup_meetups_tile`** — Discover 2×2 Bento Card 2: Pickup Meetups (`4:3` club sparring grip-up).
5. **`discover.hub.community_feed_tile`** — Discover 2×2 Bento Card 3: Community Feed (`4:3` filmed technique session).
6. **`discover.hub.elo_rankings_tile`** — Discover 2×2 Bento Card 4: ELO Rankings (`4:3` gold championship crest & telemetry).
7. **`events.tournament.detail_hero`** — Tournament Detail Header & Default Event Poster (`16:9` Grand Prix championship stage).
8. **`auth.welcome.hero_banner`** — Welcome Screen Top Hero (`16:10` iconic center-table grip lock).

### Tier 2 — Core Full-Screen `9:16` Domain Stage Backdrops
9. **`arena.home.background`** — Primary Arena & Challenges `9:16` stage backdrop.
10. **`training.log.background`** — Strength & Performance Lab `9:16` stage backdrop (`/training-log`).
11. **`match.head_to_head.background`** — Tale of the Tape Red/Blue Split `9:16` stage backdrop (`/head-to-head`).
12. **`championship.belts_list.background`** — Hall of Champions Belt Vault `9:16` stage backdrop (`/championships`).
13. **`rankings.leaderboard.background`** — Global ELO Rankings Podium `9:16` stage backdrop (`/rankings`).
14. **`referee.hub.background`** — Official Referee Table & Scorepad `9:16` stage backdrop (`/referee`).
15. **`admin.command.background`** — Federation Executive Control Suite `9:16` stage backdrop (`/admin/*`).
16. **`teams.directory.background`** — Clubs & Teams Brotherhood `9:16` stage backdrop (`/teams`).
17. **`venues.directory.background`** — Training Venues & Pickup Pulls `9:16` stage backdrop (`/venues`, `/informal-events`).
18. **`discover.home.background`** — Discover & Global Search `9:16` stage backdrop (`/discover`, `/search`).
19. **`passport.profile.background`** — Athlete Passport & Security Vault `9:16` stage backdrop (`/athlete/profile`, `/settings`).
20. **`auth.gateway.background`** — Arena Tunnel Walkout `9:16` stage backdrop (`/login`, `/register`, `/onboarding`).

### Tier 3 — Secondary Empty-State Cards, Video Fallbacks & High-Res Avatar Fallback
21. **`arena.home.no_bouts_card`** — Athlete Dashboard Standby Table Card (`16:9`).
22. **`events.tournament.live_stream_card`** — Live Stream Broadcast Standby Plate (`16:9`).
23. **`community.feed.sparring_fallback_card`** — Community Feed Sparring/Technique Video Fallback (`16:9`).
24. **`community.feed.match_fallback_card`** — Community Feed Tournament Video Fallback (`16:9`).
25. **`profile.avatar.default_fallback`** — High-Res `512×512` (`1:1`) Neutral Athlete Silhouette Avatar Fallback.
26. **`community.feed.background`** — Community Social & Messaging `9:16` stage backdrop (`/community`, `/messages`).

---

## Part H — Unresolved Questions & Ready-to-Start Confirmation

- **Codebase Coverage**: Zero unresolved image references remain. Every `ArmSphereImage`, `CrystalStageBackdrop`, `AmbientParticleBackground`, `StickyFormScaffold`, `Image.asset`, `Image.network`, and `DecorationImage` in `apps/mobile/lib/` has been audited and mapped.
- **Next Step in Workflow**:
  Select any **Placement ID** from **Tier 1** (for example, `arena.home.radar_card` or `arena.home.supermatch_card`), create/approve the image using the exact composition, aspect ratio, focal point, and safe-zone specification in **Part C**, and provide the approved image + Placement ID for immediate integration.
