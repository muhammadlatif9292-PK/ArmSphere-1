import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/constants/asset_paths.dart';
import 'package:mobile/core/providers/tournament_provider.dart';
import 'package:mobile/core/widgets/armsphere_image.dart';
import 'package:mobile/features/championship/screens/tournament_awards_ceremony_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 1C Batch 5: Ceremony & Awards Real-Data Integration Tests', () {
    const tourneyId = 'tourney_ceremony_active';

    final mockEventDetail = {
      'id': tourneyId,
      'name': 'PAFF All-Pakistan National Armwrestling Finals 2026',
      'status': 'COMPLETED',
      'venueName': 'Liaquat Gymnasium',
      'city': 'Islamabad',
      'province': 'Federal Capital',
    };

    final mockAwardsData = {
      'eventId': tourneyId,
      'eventName': 'PAFF All-Pakistan National Armwrestling Finals 2026',
      'awards': [
        {
          'bracketId': 'brk_senior_85_r',
          'bracketName': 'Men Senior -85KG Right',
          'division': 'SENIOR',
          'weightClass': '-85KG',
          'arm': 'RIGHT',
          'podium': [
            {
              'tier': '1st Place',
              'badge': 'CHAMPION',
              'medal': 'GOLD MEDAL',
              'athleteId': 'ath_sultan_01',
              'name': 'Sultan Al-Balushi',
              'club': 'Quetta Iron Hands',
              'province': 'Balochistan',
              'record': '5-0 • Undefeated Gold',
              'eloGain': '+36 ELO',
              'avatarUrl': 'https://storage.armsphere.com/avatars/sultan.webp',
            },
            {
              'tier': '2nd Place',
              'badge': 'RUNNER-UP',
              'medal': 'SILVER MEDAL',
              'athleteId': 'ath_kamran_02',
              'name': 'Kamran Zaidi',
              'club': 'Lahore Armwrestling Club',
              'province': 'Punjab',
              'record': '4-1 • Silver Medalist',
              'eloGain': '+18 ELO',
              'avatarUrl': null,
            },
            {
              'tier': '3rd Place',
              'badge': 'THIRD PLACE',
              'medal': 'BRONZE MEDAL',
              'athleteId': 'ath_danyal_03',
              'name': 'Danyal Qureshi',
              'club': 'Karachi TopRollers',
              'province': 'Sindh',
              'record': '3-2 • Bronze Medalist',
              'eloGain': '+12 ELO',
              'avatarUrl': null,
            },
          ],
        },
        {
          'bracketId': 'brk_senior_75_l',
          'bracketName': 'Men Senior -75KG Left',
          'division': 'SENIOR',
          'weightClass': '-75KG',
          'arm': 'LEFT',
          'podium': <Map<String, dynamic>>[],
        },
      ],
    };

    testWidgets('A & G: Loading state renders ceremonial indicator and never displays legacy mock athletes',
        (WidgetTester tester) async {
      final awardsCompleter = Completer<Map<String, dynamic>>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventDetailProvider(tourneyId).overrideWith((ref) async => mockEventDetail),
            eventAwardsProvider(tourneyId).overrideWith((ref) => awardsCompleter.future),
          ],
          child: const MaterialApp(
            home: TournamentAwardsCeremonyScreen(tournamentId: tourneyId),
          ),
        ),
      );

      await tester.pump();

      // 1. Verify ceremonial loading state
      expect(find.text('PREPARING OFFICIAL CEREMONY'), findsOneWidget);
      expect(find.text('Retrieving certified championship awards...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 2. Strict verification: legacy mock athletes NEVER appear during loading
      expect(find.text('Hamza Khan'), findsNothing);
      expect(find.text('Tariq Malik'), findsNothing);
      expect(find.text('Bilal Ahmed'), findsNothing);
      expect(find.text('Rawalpindi Grippers'), findsNothing);

      // Clean up
      awardsCompleter.complete(mockAwardsData);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 650));
    });

    testWidgets('B, C, H, I: Real awards response renders authoritative categories, real athletes, and federation crests',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventDetailProvider(tourneyId).overrideWith((ref) async => mockEventDetail),
            eventAwardsProvider(tourneyId).overrideWith((ref) async => mockAwardsData),
          ],
          child: const MaterialApp(
            home: TournamentAwardsCeremonyScreen(tournamentId: tourneyId),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 650)); // Allow T4 ceremony to settle

      // 1. Dynamic category tray derived from real brackets
      expect(find.text('SENIOR • -85KG • RIGHT ARM'), findsWidgets);
      expect(find.text('SENIOR • -75KG • LEFT ARM'), findsOneWidget);

      // 2. Real athlete identities rendered on podium
      expect(find.text('Sultan Al-Balushi'), findsWidgets);
      expect(find.text('Kamran Zaidi'), findsWidgets);
      expect(find.text('Danyal Qureshi'), findsWidgets);

      // 3. Strict verification: legacy mock competitors are absent
      expect(find.text('Hamza Khan'), findsNothing);
      expect(find.text('Tariq Malik'), findsNothing);
      expect(find.text('Bilal Ahmed'), findsNothing);

      // 4. Federation crest rendered via ArmSphereImage
      final sealFinders = find.byWidgetPredicate(
        (w) => w is ArmSphereImage && w.assetPath == ArmSphereAssets.sealFed,
      );
      expect(sealFinders, findsWidgets);

      // 5. Champion avatar with real avatarUrl
      final championAvatarFinder = find.byWidgetPredicate(
        (w) =>
            w is ArmSphereImage &&
            w.imageUrl == 'https://storage.armsphere.com/avatars/sultan.webp' &&
            w.fallbackAsset == ArmSphereAssets.defaultAvatar,
      );
      expect(championAvatarFinder, findsOneWidget);

      // 6. Silver avatar without remote URL cleanly uses fallbackAsset defaultAvatar
      final silverAvatarFinder = find.byWidgetPredicate(
        (w) =>
            w is ArmSphereImage &&
            w.imageUrl == null &&
            w.fallbackAsset == ArmSphereAssets.defaultAvatar &&
            w.semanticLabel == 'Kamran Zaidi profile photo',
      );
      expect(silverAvatarFinder, findsOneWidget);

      // 7. Test switching category to in-progress division
      await tester.tap(find.text('SENIOR • -75KG • LEFT ARM'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('DIVISION PODIUM IN PROGRESS'), findsOneWidget);
    });

    testWidgets('D: Empty awards array renders honest "OFFICIAL PODIUM PENDING" state',
        (WidgetTester tester) async {
      final emptyAwards = {
        'eventId': tourneyId,
        'eventName': 'PAFF All-Pakistan National Armwrestling Finals 2026',
        'awards': <Map<String, dynamic>>[],
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventDetailProvider(tourneyId).overrideWith((ref) async => mockEventDetail),
            eventAwardsProvider(tourneyId).overrideWith((ref) async => emptyAwards),
          ],
          child: const MaterialApp(
            home: TournamentAwardsCeremonyScreen(tournamentId: tourneyId),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Honest empty state
      expect(find.text('OFFICIAL PODIUM PENDING'), findsOneWidget);
      expect(
        find.text(
          'Official results and medal ceremonies will appear once championship bracket matches are completed and certified by the federation.',
        ),
        findsOneWidget,
      );
      expect(find.text('REFRESH RESULTS'), findsOneWidget);

      // 2. No mock athletes rendered
      expect(find.text('Hamza Khan'), findsNothing);
      expect(find.text('Tariq Malik'), findsNothing);
      expect(find.text('Bilal Ahmed'), findsNothing);
    });

    testWidgets('E & F: Awards API failure renders honest error state and retry triggers provider refetch',
        (WidgetTester tester) async {
      int fetchCount = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventDetailProvider(tourneyId).overrideWith((ref) async => mockEventDetail),
            eventAwardsProvider(tourneyId).overrideWith((ref) async {
              fetchCount++;
              if (fetchCount == 1) {
                throw Exception('Connection closed by remote peer');
              }
              return mockAwardsData;
            }),
          ],
          child: const MaterialApp(
            home: TournamentAwardsCeremonyScreen(tournamentId: tourneyId),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Verify honest human-readable error state
      expect(find.text('UNABLE TO LOAD CEREMONY'), findsOneWidget);
      expect(find.text('RETRY CEREMONY LOAD'), findsOneWidget);
      expect(fetchCount, 1);

      // 2. Tap RETRY and verify provider is re-queried
      await tester.tap(find.text('RETRY CEREMONY LOAD'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 650));

      expect(fetchCount, 2);
      expect(find.text('Sultan Al-Balushi'), findsWidgets);
    });

    testWidgets('J: Reduced motion (disableAnimations) completes ceremony state immediately',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventDetailProvider(tourneyId).overrideWith((ref) async => mockEventDetail),
            eventAwardsProvider(tourneyId).overrideWith((ref) async => mockAwardsData),
          ],
          child: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: MaterialApp(
              home: TournamentAwardsCeremonyScreen(tournamentId: tourneyId),
            ),
          ),
        ),
      );

      // Settle frame with zero animation delay
      await tester.pump();

      // Pedestals must be immediately visible without running 600ms ticker
      expect(find.text('Sultan Al-Balushi'), findsWidgets);
      expect(find.text('Kamran Zaidi'), findsWidgets);
      expect(find.text('Danyal Qureshi'), findsWidgets);
    });

    testWidgets('K: Long athlete names and tournament names do not cause layout overflow',
        (WidgetTester tester) async {
      final longAwardsData = {
        'eventId': tourneyId,
        'eventName': 'PAFF All-Pakistan National Inter-Provincial Grand Armwrestling Championship 2026',
        'awards': [
          {
            'bracketId': 'brk_long_1',
            'bracketName': 'Men Master Heavyweight Division Super Final',
            'division': 'MASTER SUPER HEAVYWEIGHT',
            'weightClass': '+110KG',
            'arm': 'RIGHT',
            'podium': [
              {
                'tier': '1st Place',
                'badge': 'CHAMPION',
                'medal': 'GOLD MEDAL',
                'athleteId': 'ath_long_01',
                'name': 'Muhammad Abdur Rahman Al-Hussaini Qadri',
                'club': 'Rawalpindi & Islamabad Combined Armwrestling & Strength Athletics Club',
                'province': 'Federal Capital Territory & Surrounding Divisions',
                'record': '7-0 • Undefeated Grand Champion of Pakistan',
                'eloGain': '+45 ELO',
                'avatarUrl': null,
              },
            ],
          },
        ],
      };

      // Set small handset viewport (e.g. 320x568)
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventDetailProvider(tourneyId).overrideWith((ref) async => mockEventDetail),
            eventAwardsProvider(tourneyId).overrideWith((ref) async => longAwardsData),
          ],
          child: const MaterialApp(
            home: TournamentAwardsCeremonyScreen(tournamentId: tourneyId),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 650));

      expect(tester.takeException(), isNull);
      expect(find.text('Muhammad Abdur Rahman Al-Hussaini Qadri'), findsWidgets);
    });
  });
}
