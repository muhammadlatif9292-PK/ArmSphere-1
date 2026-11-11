import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/asset_paths.dart';

void main() {
  group('ArmSphereAssets Registry Tests', () {
    test('M0 Brand Core assets have valid paths and webp extensions', () {
      expect(ArmSphereAssets.logoFull, startsWith('assets/images/brand/'));
      expect(ArmSphereAssets.logoFull, endsWith('.webp'));

      expect(ArmSphereAssets.iconGold, startsWith('assets/images/brand/'));
      expect(ArmSphereAssets.iconGold, endsWith('.webp'));

      expect(ArmSphereAssets.sealFederation, startsWith('assets/images/brand/'));
      expect(ArmSphereAssets.sealFederation, endsWith('.webp'));
    });

    test('M1 Textures & Heroes have valid paths and webp extensions', () {
      expect(ArmSphereAssets.texKnurl, startsWith('assets/images/heroes/'));
      expect(ArmSphereAssets.texKnurl, endsWith('.webp'));

      expect(ArmSphereAssets.texChalk, startsWith('assets/images/heroes/'));
      expect(ArmSphereAssets.texChalk, endsWith('.webp'));

      expect(ArmSphereAssets.heroArena, startsWith('assets/images/heroes/'));
      expect(ArmSphereAssets.heroArena, endsWith('.webp'));

      expect(ArmSphereAssets.heroGrip, startsWith('assets/images/heroes/'));
      expect(ArmSphereAssets.heroGrip, endsWith('.webp'));
    });

    test('Tier 0-3 Void 28-asset catalog paths and focal alignments are valid', () {
      expect(ArmSphereAssets.allTieredWebpAssets.length, equals(28));
      for (final path in ArmSphereAssets.allTieredWebpAssets) {
        expect(path, endsWith('.webp'));
      }

      expect(ArmSphereAssets.stageTopFocal, equals(const Alignment(0.0, -0.50)));
      expect(ArmSphereAssets.walkoutFocal, equals(const Alignment(0.0, -0.35)));
      expect(ArmSphereAssets.cardRightFocal, equals(const Alignment(0.35, 0.0)));
      expect(ArmSphereAssets.clipCenterFocal, equals(Alignment.center));

      expect(
        ArmSphereAssets.clipFallbackForCategory(ClipCategory.sparring),
        equals(ArmSphereAssets.clipFallbackSparring),
      );
      expect(
        ArmSphereAssets.clipFallbackForCategory(ClipCategory.match),
        equals(ArmSphereAssets.clipFallbackMatch),
      );
      expect(
        ArmSphereAssets.resolveClipFallback('SPARRING'),
        equals(ArmSphereAssets.clipFallbackSparring),
      );
      expect(
        ArmSphereAssets.resolveClipFallback('TOURNAMENT'),
        equals(ArmSphereAssets.clipFallbackMatch),
      );
    });

    test('Semantic catalog maps approved slot IDs and normalizes legacy .png paths', () {
      expect(
        ArmSphereAssets.resolveSemanticAsset('profile.athlete.dashboard_hero'),
        equals(ArmSphereAssets.heroAthleteDashboard),
      );
      expect(
        ArmSphereAssets.resolveSemanticAsset('arena.home.radar_card'),
        equals(ArmSphereAssets.cardArenaRadar),
      );
      expect(
        ArmSphereAssets.resolveSemanticAsset('arena.home.supermatch_card'),
        equals(ArmSphereAssets.cardSupermatchVs),
      );
      expect(
        ArmSphereAssets.resolveSemanticAsset('discover.hub.venues_tile'),
        equals(ArmSphereAssets.bentoVenues),
      );
      expect(
        ArmSphereAssets.resolveSemanticAsset('discover.hub.pickup_meetups_tile'),
        equals(ArmSphereAssets.bentoPickupSparring),
      );
      expect(
        ArmSphereAssets.resolveSemanticAsset('discover.hub.community_feed_tile'),
        equals(ArmSphereAssets.bentoCommunityFeed),
      );
      expect(
        ArmSphereAssets.resolveSemanticAsset('discover.hub.elo_rankings_tile'),
        equals(ArmSphereAssets.bentoEloRankings),
      );
      expect(
        ArmSphereAssets.resolveSemanticAsset('events.tournament.detail_hero'),
        equals(ArmSphereAssets.defaultTournament),
      );
      expect(
        ArmSphereAssets.resolveSemanticAsset('auth.welcome.hero_banner'),
        equals(ArmSphereAssets.heroWelcomeGrip),
      );
      expect(
        ArmSphereAssets.resolveSemanticAsset('arena.home.background'),
        equals(ArmSphereAssets.stageArena9x16),
      );
      expect(
        ArmSphereAssets.resolveSemanticAsset('training.log.background'),
        equals(ArmSphereAssets.stageTrainingLab9x16),
      );
      expect(
        ArmSphereAssets.resolveSemanticAsset(
          'assets/images/heroes/m1_hero_athlete_dashboard.png',
        ),
        equals(ArmSphereAssets.heroAthleteDashboard),
      );
    });

    test('M4 Badges & Insignia have valid paths and webp extensions', () {
      final badges = [
        ArmSphereAssets.badgeHeavyweight,
        ArmSphereAssets.badgeMiddleweight,
        ArmSphereAssets.badgeLightweight,
        ArmSphereAssets.badgeJunior,
        ArmSphereAssets.badgeMasters,
        ArmSphereAssets.refMaster,
        ArmSphereAssets.refNational,
        ArmSphereAssets.refRegional,
      ];

      for (final badge in badges) {
        expect(badge, startsWith('assets/images/badges/'));
        expect(badge, endsWith('.webp'));
      }
    });

    test('Concise aliases map identically to canonical constants', () {
      expect(ArmSphereAssets.sealFed, equals(ArmSphereAssets.sealFederation));
      expect(ArmSphereAssets.badgeHeavy, equals(ArmSphereAssets.badgeHeavyweight));
      expect(ArmSphereAssets.badgeMiddle, equals(ArmSphereAssets.badgeMiddleweight));
      expect(ArmSphereAssets.badgeLight, equals(ArmSphereAssets.badgeLightweight));
      expect(ArmSphereAssets.refNat, equals(ArmSphereAssets.refNational));
      expect(ArmSphereAssets.refReg, equals(ArmSphereAssets.refRegional));
    });

    test('System Defaults & Fallbacks have valid paths and webp extensions', () {
      expect(ArmSphereAssets.defaultAvatar, startsWith('assets/images/defaults/'));
      expect(ArmSphereAssets.defaultAvatar, endsWith('.webp'));

      expect(ArmSphereAssets.defaultTournament, startsWith('assets/images/defaults/'));
      expect(ArmSphereAssets.defaultTournament, endsWith('.webp'));

      expect(ArmSphereAssets.defaultClub, startsWith('assets/images/defaults/'));
      expect(ArmSphereAssets.defaultClub, endsWith('.webp'));
    });

    test('M6 Audio Sensory Pack has valid audio extensions', () {
      expect(ArmSphereAssets.soundChallengeAccepted, startsWith('assets/sounds/'));
      expect(ArmSphereAssets.soundChallengeAccepted, endsWith('.wav'));

      expect(ArmSphereAssets.soundMatchWon, startsWith('assets/sounds/'));
      expect(ArmSphereAssets.soundMatchWon, endsWith('.mp3'));

      expect(ArmSphereAssets.soundPRAchieved, startsWith('assets/sounds/'));
      expect(ArmSphereAssets.soundPRAchieved, endsWith('.wav'));
    });

    test('All declared image assets physically exist on disk and are non-empty', () {
      final allImages = {
        ...ArmSphereAssets.allTieredWebpAssets,
        ArmSphereAssets.logoFull,
        ArmSphereAssets.iconGold,
        ArmSphereAssets.sealFederation,
        ArmSphereAssets.texKnurl,
        ArmSphereAssets.texChalk,
        ArmSphereAssets.heroArena,
        ArmSphereAssets.heroGrip,
        ArmSphereAssets.badgeHeavyweight,
        ArmSphereAssets.badgeMiddleweight,
        ArmSphereAssets.badgeLightweight,
        ArmSphereAssets.badgeJunior,
        ArmSphereAssets.badgeMasters,
        ArmSphereAssets.refMaster,
        ArmSphereAssets.refNational,
        ArmSphereAssets.refRegional,
        ArmSphereAssets.defaultAvatar,
        ArmSphereAssets.defaultTournament,
        ArmSphereAssets.defaultClub,
      };

      for (final relativePath in allImages) {
        final file = File(relativePath).existsSync()
            ? File(relativePath)
            : File('apps/mobile/$relativePath');
        expect(file.existsSync(), isTrue, reason: 'Missing physical asset on disk: $relativePath');
        expect(file.lengthSync(), greaterThan(0), reason: 'Asset file is empty: $relativePath');
      }
    });
  });
}
