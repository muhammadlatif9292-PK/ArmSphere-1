import 'dart:io';

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
      expect(ArmSphereAssets.texKnurl, startsWith('assets/images/textures/'));
      expect(ArmSphereAssets.texKnurl, endsWith('.webp'));

      expect(ArmSphereAssets.texChalk, startsWith('assets/images/textures/'));
      expect(ArmSphereAssets.texChalk, endsWith('.webp'));

      expect(ArmSphereAssets.heroArena, startsWith('assets/images/heroes/'));
      expect(ArmSphereAssets.heroArena, endsWith('.webp'));

      expect(ArmSphereAssets.heroGrip, startsWith('assets/images/heroes/'));
      expect(ArmSphereAssets.heroGrip, endsWith('.webp'));
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
      final allImages = [
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
      ];

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
