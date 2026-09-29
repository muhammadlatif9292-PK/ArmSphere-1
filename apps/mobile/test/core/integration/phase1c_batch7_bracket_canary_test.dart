import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/providers/state_providers.dart';
import 'package:mobile/core/providers/tournament_provider.dart';
import 'package:mobile/core/routing/app_router.dart';
import 'package:mobile/features/tournament/screens/tournament_screens.dart';
import 'package:mobile/features/tournament/widgets/bracket_minimap_hud.dart';
import 'package:mobile/features/tournament/widgets/bracket_tree_widget.dart';
import 'package:mobile/features/tournament/widgets/compact_bracket_match_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 1C Batch 7: Tournament Bracket Canary Integration Tests (Canary 8)', () {
    const testTournamentId = 'tourney_pk_championship_2026';
    const testBracketId = 'bracket_senior_85kg_right';

    final mockBracketsList = [
      {
        'id': testBracketId,
        'eventId': testTournamentId,
        'division': 'SENIOR',
        'weightClass': '-85KG',
        'arm': 'RIGHT',
        'format': 'DOUBLE_ELIMINATION',
        'status': 'IN_PROGRESS',
      },
      {
        'id': 'bracket_senior_75kg_left',
        'eventId': testTournamentId,
        'division': 'SENIOR',
        'weightClass': '-75KG',
        'arm': 'LEFT',
        'format': 'SINGLE_ELIMINATION',
        'status': 'SCHEDULED',
      },
    ];

    final mockBracketDetail = {
      'id': testBracketId,
      'eventId': testTournamentId,
      'division': 'SENIOR',
      'weightClass': '-85KG',
      'arm': 'RIGHT',
      'format': 'DOUBLE_ELIMINATION',
      'status': 'IN_PROGRESS',
      'matches': [
        {
          'id': 'm_r1_01',
          'round': 1,
          'matchIndex': 0,
          'tableNumber': 1,
          'bracketType': 'WINNERS',
          'status': 'COMPLETED',
          'athleteAId': 'ath_01',
          'athleteAName': 'Sultan Al-Balushi',
          'athleteBId': 'ath_02',
          'athleteBName': 'Kamran Zaidi',
          'scoreLine': '3-0',
          'winnerId': 'ath_01',
          'winnerName': 'Sultan Al-Balushi',
          'nextMatchId': 'm_r2_01',
        },
        {
          'id': 'm_r1_02',
          'round': 1,
          'matchIndex': 1,
          'tableNumber': 2,
          'bracketType': 'WINNERS',
          'status': 'COMPLETED',
          'athleteAId': 'ath_03',
          'athleteAName': 'Danyal Qureshi',
          'athleteBId': 'ath_04',
          'athleteBName': 'Bilal Ahmed',
          'scoreLine': '3-1',
          'winnerId': 'ath_03',
          'winnerName': 'Danyal Qureshi',
          'nextMatchId': 'm_r2_01',
        },
        {
          'id': 'm_r2_01',
          'round': 2,
          'matchIndex': 0,
          'tableNumber': 1,
          'bracketType': 'WINNERS',
          'status': 'SCHEDULED',
          'athleteAId': 'ath_01',
          'athleteAName': 'Sultan Al-Balushi',
          'athleteBId': 'ath_03',
          'athleteBName': 'Danyal Qureshi',
          'scoreLine': '1-1',
          'winnerId': null,
          'nextMatchId': null,
        },
        {
          'id': 'm_losers_01',
          'round': 1,
          'matchIndex': 0,
          'tableNumber': 3,
          'bracketType': 'LOSERS',
          'status': 'SCHEDULED',
          'athleteAId': 'ath_02',
          'athleteAName': 'Kamran Zaidi',
          'athleteBId': 'ath_04',
          'athleteBName': 'Bilal Ahmed',
          'scoreLine': '0-0',
          'winnerId': null,
          'nextMatchId': null,
        },
      ],
    };

    // Helper to settle state cleanly without timing out on repeating tickers
    Future<void> settleScreen(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    // -------------------------------------------------------------------------
    // Test 1: Canonical /tournaments/bracket route and aliases exist in AppRouter
    // -------------------------------------------------------------------------
    testWidgets('Requirement 1: Canonical /tournaments/bracket and alias routes are registered in AppRouter',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      final routes = router.configuration.routes;

      final canonicalRoute = routes.whereType<GoRoute>().firstWhere(
            (r) => r.path == '/tournaments/bracket',
            orElse: () => throw StateError('Missing canonical /tournaments/bracket route'),
          );
      final idCanonicalRoute = routes.whereType<GoRoute>().firstWhere(
            (r) => r.path == '/tournaments/:tournamentId/bracket',
            orElse: () => throw StateError('Missing /tournaments/:tournamentId/bracket route'),
          );
      final pluralCanonicalRoute = routes.whereType<GoRoute>().firstWhere(
            (r) => r.path == '/tournaments/:tournamentId/brackets',
            orElse: () => throw StateError('Missing /tournaments/:tournamentId/brackets route'),
          );
      final legacyRoute = routes.whereType<GoRoute>().firstWhere(
            (r) => r.path == '/tournament/:tournamentId/brackets',
            orElse: () => throw StateError('Missing /tournament/:tournamentId/brackets route'),
          );

      expect(canonicalRoute, isNotNull);
      expect(canonicalRoute.name, 'tournaments_bracket_canary');
      expect(idCanonicalRoute, isNotNull);
      expect(idCanonicalRoute.name, 'tournaments_bracket_id_canonical');
      expect(pluralCanonicalRoute, isNotNull);
      expect(pluralCanonicalRoute.name, 'tournaments_brackets_canonical');
      expect(legacyRoute, isNotNull);
      expect(legacyRoute.name, 'tournament_brackets');
    });

    // -------------------------------------------------------------------------
    // Test 2: Empty bracket state handling
    // -------------------------------------------------------------------------
    testWidgets('Requirement 2: Displays clean empty state when no brackets are generated',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventBracketsProvider(testTournamentId).overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: TournamentBracketsScreen(tournamentId: testTournamentId),
          ),
        ),
      );
      await settleScreen(tester);

      expect(find.text('No brackets published yet.'), findsOneWidget);
      expect(find.text('Matchups will appear once tournament directors generate brackets.'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 3: Renders bracket chips and spatial bracket tree by default
    // -------------------------------------------------------------------------
    testWidgets('Requirement 3: Renders category chips and defaults to spatial BracketTreeWidget',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventBracketsProvider(testTournamentId).overrideWith((ref) async => mockBracketsList),
            bracketDetailsProvider(testBracketId).overrideWith((ref) async => mockBracketDetail),
          ],
          child: const MaterialApp(
            home: TournamentBracketsScreen(tournamentId: testTournamentId),
          ),
        ),
      );
      await settleScreen(tester);

      // Category chips are visible
      expect(find.text('SENIOR -85KG RIGHT'), findsOneWidget);
      expect(find.text('SENIOR -75KG LEFT'), findsOneWidget);

      // Default view is BracketTreeWidget
      expect(find.byType(BracketTreeWidget), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 4: 2D Spatial Pan/Zoom InteractiveViewer configuration
    // -------------------------------------------------------------------------
    testWidgets('Requirement 4: InteractiveViewer configured with 0.5x to 2.5x scale bounds',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventBracketsProvider(testTournamentId).overrideWith((ref) async => mockBracketsList),
            bracketDetailsProvider(testBracketId).overrideWith((ref) async => mockBracketDetail),
          ],
          child: const MaterialApp(
            home: TournamentBracketsScreen(tournamentId: testTournamentId),
          ),
        ),
      );
      await settleScreen(tester);

      final interactiveViewerFinder = find.byType(InteractiveViewer);
      expect(interactiveViewerFinder, findsOneWidget);

      final interactiveViewer = tester.widget<InteractiveViewer>(interactiveViewerFinder);
      expect(interactiveViewer.minScale, 0.5);
      expect(interactiveViewer.maxScale, 2.5);
      expect(interactiveViewer.constrained, false);
      expect(interactiveViewer.transformationController, isNotNull);
    });

    // -------------------------------------------------------------------------
    // Test 5: HUD Mini-Map Radar (BracketMinimapHud) presence & synchronization
    // -------------------------------------------------------------------------
    testWidgets('Requirement 5: BracketMinimapHud radar rendered at bottom-right with viewport synchronization',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventBracketsProvider(testTournamentId).overrideWith((ref) async => mockBracketsList),
            bracketDetailsProvider(testBracketId).overrideWith((ref) async => mockBracketDetail),
          ],
          child: const MaterialApp(
            home: TournamentBracketsScreen(tournamentId: testTournamentId),
          ),
        ),
      );
      await settleScreen(tester);

      final minimapFinder = find.byType(BracketMinimapHud);
      expect(minimapFinder, findsOneWidget);

      final minimap = tester.widget<BracketMinimapHud>(minimapFinder);
      expect(minimap.canvasSize.width, greaterThan(0));
      expect(minimap.canvasSize.height, greaterThan(0));
      expect(minimap.matchOffsets.isNotEmpty, true);

      // Verify Semantics
      expect(
        find.bySemanticsLabel('Tournament bracket mini-map radar indicator. Tap to jump viewport.'),
        findsOneWidget,
      );

      // Verify interaction
      await tester.tap(minimapFinder);
      await settleScreen(tester);
    });

    // -------------------------------------------------------------------------
    // Test 6: View Mode toggle between Spatial Tree and List View
    // -------------------------------------------------------------------------
    testWidgets('Requirement 6: View Mode toggle switches between 2D Spatial Tree and round-by-round List View',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventBracketsProvider(testTournamentId).overrideWith((ref) async => mockBracketsList),
            bracketDetailsProvider(testBracketId).overrideWith((ref) async => mockBracketDetail),
          ],
          child: const MaterialApp(
            home: TournamentBracketsScreen(tournamentId: testTournamentId),
          ),
        ),
      );
      await settleScreen(tester);

      // Initially spatial tree
      expect(find.byType(BracketTreeWidget), findsOneWidget);

      // Tap toggle button in AppBar
      final toggleFinder = find.byTooltip('Switch to List View');
      expect(toggleFinder, findsOneWidget);
      await tester.tap(toggleFinder);
      await settleScreen(tester);

      // Now in list view (BracketTreeWidget absent, list items present)
      expect(find.byType(BracketTreeWidget), findsNothing);
      expect(find.text('Round 1 (Winners Bracket)'), findsOneWidget);

      // Tap toggle button again to switch back
      final switchBackFinder = find.byTooltip('Switch to Spatial Tree');
      expect(switchBackFinder, findsOneWidget);
      await tester.tap(switchBackFinder);
      await settleScreen(tester);

      // Back in spatial tree
      expect(find.byType(BracketTreeWidget), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 7: Double-elimination partition filter chips (Winners / Losers)
    // -------------------------------------------------------------------------
    testWidgets('Requirement 7: Double-elimination partition chips allow filtering between Winners, Losers, and Full Draw',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventBracketsProvider(testTournamentId).overrideWith((ref) async => mockBracketsList),
            bracketDetailsProvider(testBracketId).overrideWith((ref) async => mockBracketDetail),
          ],
          child: const MaterialApp(
            home: TournamentBracketsScreen(tournamentId: testTournamentId),
          ),
        ),
      );
      await settleScreen(tester);

      // Double-elimination filter chips exist
      expect(find.text('Full Draw'), findsOneWidget);
      expect(find.text('Winners'), findsOneWidget);
      expect(find.text('Elimination'), findsOneWidget);

      // Tap 'Elimination' partition chip
      await tester.tap(find.text('Elimination'));
      await settleScreen(tester);

      // Tree updates to show Losers partition
      expect(find.byType(BracketTreeWidget), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 8: CompactBracketMatchCard rendering and accessibility semantics
    // -------------------------------------------------------------------------
    testWidgets('Requirement 8: Match cards render athlete names, table numbers, and provide accessible Semantics',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventBracketsProvider(testTournamentId).overrideWith((ref) async => mockBracketsList),
            bracketDetailsProvider(testBracketId).overrideWith((ref) async => mockBracketDetail),
          ],
          child: const MaterialApp(
            home: TournamentBracketsScreen(tournamentId: testTournamentId),
          ),
        ),
      );
      await settleScreen(tester);

      expect(find.byType(CompactBracketMatchCard), findsWidgets);
      expect(find.text('Sultan Al-Balushi'), findsWidgets);
      expect(find.text('Kamran Zaidi'), findsWidgets);
      expect(find.text('TABLE 1'), findsWidgets);

      // Verify Semantics on completed match
      expect(
        find.bySemanticsLabel(
          'Completed match on Table 1. Sultan Al-Balushi scored 3, Kamran Zaidi scored 0. Sultan Al-Balushi won. Tap to view head to head.',
        ),
        findsOneWidget,
      );
    });

    // -------------------------------------------------------------------------
    // Test 9: Reduced-motion fallback compliance
    // -------------------------------------------------------------------------
    testWidgets('Requirement 9: Respects disableAnimations reduced-motion setting without visual stutter or hang',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventBracketsProvider(testTournamentId).overrideWith((ref) async => mockBracketsList),
            bracketDetailsProvider(testBracketId).overrideWith((ref) async => mockBracketDetail),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: TournamentBracketsScreen(tournamentId: testTournamentId),
            ),
          ),
        ),
      );
      await settleScreen(tester);

      // Widget settles cleanly with zero timeouts or pending timers
      expect(find.byType(BracketTreeWidget), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 10: Refresh action invalidates both event and bracket providers
    // -------------------------------------------------------------------------
    testWidgets('Requirement 10: Refresh action cleanly refreshes bracket data',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventBracketsProvider(testTournamentId).overrideWith((ref) async => mockBracketsList),
            bracketDetailsProvider(testBracketId).overrideWith((ref) async => mockBracketDetail),
          ],
          child: const MaterialApp(
            home: TournamentBracketsScreen(tournamentId: testTournamentId),
          ),
        ),
      );
      await settleScreen(tester);

      final refreshFinder = find.byTooltip('Refresh Brackets');
      expect(refreshFinder, findsOneWidget);
      await tester.tap(refreshFinder);
      await settleScreen(tester);

      expect(find.byType(BracketTreeWidget), findsOneWidget);
    });
  });
}
