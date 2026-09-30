import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/providers/tournament_provider.dart';
import 'package:mobile/features/tournament/screens/tournament_screens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 2 / Item 2.1: Live Arena Tables Real-Data Binding Integration Tests', () {
    const testTournamentId = 'tourney_paff_national_2026';

    final mockEventDetail = {
      'id': testTournamentId,
      'name': 'PAFF All-Pakistan National Armwrestling Finals 2026',
      'status': 'ONGOING',
      'venueName': 'Liaquat Gymnasium',
      'city': 'Islamabad',
      'province': 'Federal Capital',
      'startDate': '2026-10-15T09:00:00.000Z',
      'endDate': '2026-10-17T18:00:00.000Z',
      'registrationFeeCents': 5000,
      'registeredCount': 32,
      'capacity': 64,
      'description': 'Premier national armwrestling championship live telemetry.',
    };

    final mockLiveTables = [
      {
        'id': 'match_senior_85_01',
        'bracketId': 'bracket_senior_85_r',
        'tableNumber': 'TABLE 1',
        'stageName': 'Main Stage',
        'status': 'IN BOUT',
        'rawStatus': 'IN_PROGRESS',
        'isLive': true,
        'weightClass': '-85 KG · RIGHT ARM',
        'division': 'SENIOR',
        'arm': 'RIGHT',
        'rawWeightClass': '-85 KG',
        'redCornerName': 'Sultan Al-Balushi',
        'redCornerCountry': 'PK',
        'blueCornerName': 'Kamran Zaidi',
        'blueCornerCountry': 'PK',
        'round': 1,
        'matchIndex': 1,
      },
      {
        'id': 'match_senior_75_01',
        'bracketId': 'bracket_senior_75_l',
        'tableNumber': 'TABLE 2',
        'stageName': 'Stream Table A',
        'status': 'ON DECK',
        'rawStatus': 'CALLED',
        'isLive': false,
        'weightClass': '-75 KG · LEFT ARM',
        'division': 'SENIOR',
        'arm': 'LEFT',
        'rawWeightClass': '-75 KG',
        'redCornerName': 'Danyal Qureshi',
        'redCornerCountry': 'PK',
        'blueCornerName': 'Bilal Ahmed',
        'blueCornerCountry': 'PK',
        'round': 1,
        'matchIndex': 2,
      },
    ];

    Future<void> settleScreen(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    // -------------------------------------------------------------------------
    // Test 1: Real-data live arena tables render genuine athlete names and active bout cards
    // -------------------------------------------------------------------------
    testWidgets('Requirement 1: Real-data live arena tables render genuine athlete names and active bout cards',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventDetailProvider(testTournamentId).overrideWith((ref) async => mockEventDetail),
            eventLiveArenaTablesProvider(testTournamentId).overrideWith((ref) async => mockLiveTables),
          ],
          child: const MaterialApp(
            home: TournamentDetailScreen(tournamentId: testTournamentId),
          ),
        ),
      );
      await settleScreen(tester);

      // Verify active tables header count reflects real data (2 tables active)
      expect(find.text('2 TABLES ACTIVE'), findsOneWidget);

      // Verify Table 1 bout card rendering
      expect(find.text('TABLE 1'), findsOneWidget);
      expect(find.text('Main Stage'), findsOneWidget);
      expect(find.text('IN BOUT'), findsOneWidget);
      expect(find.text('-85 KG · RIGHT ARM'), findsOneWidget);
      expect(find.text('Sultan Al-Balushi (PK)'), findsOneWidget);
      expect(find.text('Kamran Zaidi (PK)'), findsOneWidget);

      // Verify Table 2 on deck card rendering
      expect(find.text('TABLE 2'), findsOneWidget);
      expect(find.text('Stream Table A'), findsOneWidget);
      expect(find.text('ON DECK'), findsOneWidget);
      expect(find.text('-75 KG · LEFT ARM'), findsOneWidget);
      expect(find.text('Danyal Qureshi (PK)'), findsOneWidget);
      expect(find.text('Bilal Ahmed (PK)'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 2: Zero simulated exhibition pullers gate
    // -------------------------------------------------------------------------
    testWidgets('Requirement 2: Falsification audit proves zero hardcoded exhibition pullers or static counts',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventDetailProvider(testTournamentId).overrideWith((ref) async => mockEventDetail),
            eventLiveArenaTablesProvider(testTournamentId).overrideWith((ref) async => mockLiveTables),
          ],
          child: const MaterialApp(
            home: TournamentDetailScreen(tournamentId: testTournamentId),
          ),
        ),
      );
      await settleScreen(tester);

      // Zero occurrence of legacy simulated names
      expect(find.text('M. Todd'), findsNothing);
      expect(find.text('D. Cyplenkov'), findsNothing);
      expect(find.text('E. Gasparini'), findsNothing);
      expect(find.text('A. Voevoda'), findsNothing);
      expect(find.text('3 TABLES ACTIVE'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // Test 3: Truthful empty state when no arena tables are active
    // -------------------------------------------------------------------------
    testWidgets('Requirement 3: Truthfully displays 0 TABLES ACTIVE and empty state when no matches are active',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventDetailProvider(testTournamentId).overrideWith((ref) async => mockEventDetail),
            eventLiveArenaTablesProvider(testTournamentId).overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: TournamentDetailScreen(tournamentId: testTournamentId),
          ),
        ),
      );
      await settleScreen(tester);

      // Header shows honest 0 tables badge
      expect(find.text('0 TABLES ACTIVE'), findsOneWidget);

      // Body displays truthful empty message
      expect(find.text('No Live Arena Tables Active'), findsOneWidget);
      expect(find.text('Arena tables will appear here once matches are called to the table.'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 4: Category Filter Tray filters active arena tables by weight class
    // -------------------------------------------------------------------------
    testWidgets('Requirement 4: Category Filter Tray filters active arena tables by weight class and arm',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventDetailProvider(testTournamentId).overrideWith((ref) async => mockEventDetail),
            eventLiveArenaTablesProvider(testTournamentId).overrideWith((ref) async => mockLiveTables),
          ],
          child: const MaterialApp(
            home: TournamentDetailScreen(tournamentId: testTournamentId),
          ),
        ),
      );
      await settleScreen(tester);

      // Both matches visible initially with 'ALL' filter
      expect(find.text('Sultan Al-Balushi (PK)'), findsOneWidget);
      expect(find.text('Danyal Qureshi (PK)'), findsOneWidget);

      // Tap '-85 KG' filter chip
      await tester.tap(find.text('-85 KG'));
      await settleScreen(tester);

      // Only -85 KG match remains visible
      expect(find.text('Sultan Al-Balushi (PK)'), findsOneWidget);
      expect(find.text('Danyal Qureshi (PK)'), findsNothing);

      // Tap 'ALL' filter chip to restore full view
      await tester.tap(find.text('ALL'));
      await settleScreen(tester);

      expect(find.text('Sultan Al-Balushi (PK)'), findsOneWidget);
      expect(find.text('Danyal Qureshi (PK)'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 5: Category Filter Tray displays category-specific empty state
    // -------------------------------------------------------------------------
    testWidgets('Requirement 5: Category Filter Tray displays specific empty state when selected division has no active bouts',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventDetailProvider(testTournamentId).overrideWith((ref) async => mockEventDetail),
            eventLiveArenaTablesProvider(testTournamentId).overrideWith((ref) async => mockLiveTables),
          ],
          child: const MaterialApp(
            home: TournamentDetailScreen(tournamentId: testTournamentId),
          ),
        ),
      );
      await settleScreen(tester);

      // Tap '+105 KG' filter chip
      await tester.tap(find.text('+105 KG'));
      await settleScreen(tester);

      // Category-specific empty state is displayed
      expect(find.text('No Live Tables in +105 KG'), findsOneWidget);
      expect(find.text('Select "ALL" to view active tables across all divisions.'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 6: Error state renders honest failure banner and retry affordance
    // -------------------------------------------------------------------------
    testWidgets('Requirement 6: Error state renders failure banner and retry affordance',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventDetailProvider(testTournamentId).overrideWith((ref) async => mockEventDetail),
            eventLiveArenaTablesProvider(testTournamentId).overrideWith((ref) async => throw Exception('Network timeout')),
          ],
          child: const MaterialApp(
            home: TournamentDetailScreen(tournamentId: testTournamentId),
          ),
        ),
      );
      await settleScreen(tester);

      expect(find.text('Could not load live arena tables'), findsOneWidget);
      expect(find.text('Retry'), findsWidgets);
    });

    // -------------------------------------------------------------------------
    // Test 7: Accessible semantics on Arena Table Cards
    // -------------------------------------------------------------------------
    testWidgets('Requirement 7: Arena table cards provide comprehensive Semantics descriptions',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventDetailProvider(testTournamentId).overrideWith((ref) async => mockEventDetail),
            eventLiveArenaTablesProvider(testTournamentId).overrideWith((ref) async => mockLiveTables),
          ],
          child: const MaterialApp(
            home: TournamentDetailScreen(tournamentId: testTournamentId),
          ),
        ),
      );
      await settleScreen(tester);

      // Look for Semantics label matching Table 1
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              (w.properties.label?.contains('TABLE 1') ?? false) &&
              (w.properties.label?.contains('Sultan Al-Balushi') ?? false),
        ),
        findsOneWidget,
      );
    });
  });
}
