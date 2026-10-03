import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/constants/asset_paths.dart';
import 'package:mobile/core/providers/tournament_provider.dart';
import 'package:mobile/core/routing/app_router.dart';
import 'package:mobile/core/widgets/armsphere_image.dart';
import 'package:mobile/core/widgets/signature_ceremonies.dart';
import 'package:mobile/features/championship/screens/tournament_awards_ceremony_screen.dart';

class _FakeTournamentNotifier extends TournamentNotifier {
  final List<Map<String, dynamic>> _data;
  _FakeTournamentNotifier(this._data);

  @override
  Future<List<Map<String, dynamic>>> build() async => _data;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Canary 10: Championship Awards & Ceremony Integration Tests', () {
    const tourneyId = 'tourney_canary10_active';

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

    final mockTournamentsList = [
      {
        'id': tourneyId,
        'name': 'PAFF All-Pakistan National Armwrestling Finals 2026',
        'status': 'COMPLETED',
      },
    ];

    testWidgets('1. Canonical /awards route navigates and renders TournamentAwardsCeremonyScreen',
        (WidgetTester tester) async {
      final testRouter = GoRouter(
        initialLocation: '/awards?tournamentId=$tourneyId',
        routes: [
          GoRoute(
            path: '/awards',
            name: 'awards_canonical',
            pageBuilder: (context, state) {
              final id = state.uri.queryParameters['tournamentId'] ?? '';
              return MaterialPage(
                key: state.pageKey,
                child: TournamentAwardsCeremonyScreen(tournamentId: id),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventDetailProvider(tourneyId).overrideWith((ref) async => mockEventDetail),
            eventAwardsProvider(tourneyId).overrideWith((ref) async => mockAwardsData),
            tournamentProvider.overrideWith(() => _FakeTournamentNotifier(mockTournamentsList)),
          ],
          child: MaterialApp.router(
            routerConfig: testRouter,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 650));

      expect(find.byType(TournamentAwardsCeremonyScreen), findsOneWidget);
      expect(find.text('AWARDS & PODIUM CEREMONY'), findsOneWidget);
      expect(find.text('Sultan Al-Balushi'), findsWidgets);
    });

    testWidgets('2. Fallback to active tournament when /awards is loaded without explicit tournamentId',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tournamentProvider.overrideWith(() => _FakeTournamentNotifier(mockTournamentsList)),
            eventDetailProvider(tourneyId).overrideWith((ref) async => mockEventDetail),
            eventAwardsProvider(tourneyId).overrideWith((ref) async => mockAwardsData),
          ],
          child: const MaterialApp(
            home: TournamentAwardsCeremonyScreen(tournamentId: ''),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 650));

      expect(find.byType(TournamentAwardsCeremonyScreen), findsOneWidget);
      expect(find.text('Sultan Al-Balushi'), findsWidgets);
      expect(find.text('Kamran Zaidi'), findsWidgets);
    });

    testWidgets('3. 3-Tier Podium displays Gold (1st), Silver (2nd), and Bronze (3rd) with correct pedestal ranks',
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
      await tester.pump(const Duration(milliseconds: 650));

      // 1st, 2nd, 3rd place badges and ranks
      expect(find.text('CHAMPION'), findsWidgets);
      expect(find.text('RUNNER-UP'), findsWidgets);
      expect(find.text('THIRD PLACE'), findsWidgets);

      expect(find.text('1'), findsWidgets);
      expect(find.text('2'), findsWidgets);
      expect(find.text('3'), findsWidgets);
    });

    testWidgets('4. T4 ceremonial sequence completes and never displays legacy mock athletes',
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
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 350)); // Settle 600ms T4 sequence

      // Zero mock athletes
      expect(find.text('Hamza Khan'), findsNothing);
      expect(find.text('Tariq Malik'), findsNothing);
      expect(find.text('Bilal Ahmed'), findsNothing);

      // Real medalists present
      expect(find.text('Sultan Al-Balushi'), findsWidgets);
      expect(find.text('Kamran Zaidi'), findsWidgets);
      expect(find.text('Danyal Qureshi'), findsWidgets);
    });

    testWidgets('5. Tapping podium tier selects medalist and reveals unbox citation action',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

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
      await tester.pump(const Duration(milliseconds: 650));

      // Initial selection is Gold (Sultan)
      expect(find.text('UNBOX & INSPECT GOLD MEDAL CITATION'), findsOneWidget);

      // Tap Silver tier (Kamran Zaidi)
      await tester.tap(find.text('2'), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250)); // AnimatedSwitcher transition

      expect(find.text('UNBOX & INSPECT SILVER MEDAL CITATION'), findsOneWidget);
      expect(find.text('Lahore Armwrestling Club • Punjab'), findsOneWidget);

      // Open medal citation dialog
      await tester.tap(find.text('UNBOX & INSPECT SILVER MEDAL CITATION'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(ChampionshipGoldCard), findsOneWidget);
      expect(find.text('Share Championship Card'), findsOneWidget);

      // Close modal
      await tester.tap(find.text('Close'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(ChampionshipGoldCard), findsNothing);
    });

    testWidgets('6. Empty state renders honest "OFFICIAL PODIUM PENDING" notice',
        (WidgetTester tester) async {
      final emptyAwards = {
        'eventId': tourneyId,
        'eventName': 'PAFF National Finals',
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

      expect(find.text('OFFICIAL PODIUM PENDING'), findsOneWidget);
      expect(find.text('REFRESH RESULTS'), findsOneWidget);
    });

    testWidgets('7. Error state renders honest message and retry triggers provider refetch',
        (WidgetTester tester) async {
      int fetchCount = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventDetailProvider(tourneyId).overrideWith((ref) async => mockEventDetail),
            eventAwardsProvider(tourneyId).overrideWith((ref) async {
              fetchCount++;
              if (fetchCount == 1) {
                throw Exception('Network connection timed out');
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

      expect(find.text('UNABLE TO LOAD CEREMONY'), findsOneWidget);
      expect(find.text('RETRY CEREMONY LOAD'), findsOneWidget);
      expect(fetchCount, 1);

      await tester.tap(find.text('RETRY CEREMONY LOAD'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 650));

      expect(fetchCount, 2);
      expect(find.text('Sultan Al-Balushi'), findsWidgets);
    });

    testWidgets('8. In-progress division displays DIVISION PODIUM IN PROGRESS notice',
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
      await tester.pump(const Duration(milliseconds: 650));

      // Switch to unfinished category
      await tester.tap(find.text('SENIOR • -75KG • LEFT ARM'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('DIVISION PODIUM IN PROGRESS'), findsOneWidget);
    });

    testWidgets('9. Reduced motion (disableAnimations) settles ceremony immediately without delay',
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

      // Instant frame settlement
      await tester.pump();

      expect(find.text('Sultan Al-Balushi'), findsWidgets);
      expect(find.text('Kamran Zaidi'), findsWidgets);
      expect(find.text('Danyal Qureshi'), findsWidgets);
    });

    testWidgets('10. Accessibility Semantics declared on category chips and medal pedestals',
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
      await tester.pump(const Duration(milliseconds: 650));

      // Category chip semantics
      final categoryChipFinder = find.byWidgetPredicate(
        (w) => w is Semantics && (w.properties.label?.contains('division awards') ?? false),
      );
      expect(categoryChipFinder, findsWidgets);

      // Medal unbox button semantics
      final unboxButtonFinder = find.byWidgetPredicate(
        (w) => w is Semantics && (w.properties.label?.contains('Inspect GOLD MEDAL citation') ?? false),
      );
      expect(unboxButtonFinder, findsOneWidget);
    });
  });
}
