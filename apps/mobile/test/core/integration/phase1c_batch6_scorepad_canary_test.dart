import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:mobile/core/api/dio_client.dart';
import 'package:mobile/core/api/repositories.dart';
import 'package:mobile/core/providers/state_providers.dart';
import 'package:mobile/core/routing/app_router.dart';
import 'package:mobile/features/referee/screens/referee_screens.dart';
import 'package:mobile/features/referee/widgets/live_scorepad_controller.dart';

class _FakeTournamentRepository extends Fake implements TournamentRepository {
  final Future<Map<String, dynamic>> Function({
    required String matchId,
    required String winnerId,
    required String scoreLine,
    CancelToken? cancelToken,
  })? onSubmitTournamentResult;

  _FakeTournamentRepository({this.onSubmitTournamentResult});

  @override
  Future<Map<String, dynamic>> submitTournamentResult({
    required String matchId,
    required String winnerId,
    required String scoreLine,
    CancelToken? cancelToken,
  }) async {
    if (onSubmitTournamentResult != null) {
      return onSubmitTournamentResult!(
        matchId: matchId,
        winnerId: winnerId,
        scoreLine: scoreLine,
        cancelToken: cancelToken,
      );
    }
    return {'status': 'COMPLETED', 'matchId': matchId, 'winnerId': winnerId};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 1C Batch 6: Referee Scorepad Canary Integration Tests (Canary 7)', () {
    // -------------------------------------------------------------------------
    // Test 1: Canonical /referee/scorepad route exists and resolves properly
    // -------------------------------------------------------------------------
    testWidgets('Requirement 1: Canonical /referee/scorepad & /referee/submit-scorepad routes are registered in AppRouter',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      final routes = router.configuration.routes;

      final canonicalRoute = routes.whereType<GoRoute>().firstWhere(
            (r) => r.path == '/referee/scorepad',
            orElse: () => throw StateError('Missing /referee/scorepad route'),
          );
      final legacyRoute = routes.whereType<GoRoute>().firstWhere(
            (r) => r.path == '/referee/submit-scorepad',
            orElse: () => throw StateError('Missing /referee/submit-scorepad route'),
          );

      expect(canonicalRoute, isNotNull);
      expect(canonicalRoute.name, 'referee_scorepad');
      expect(legacyRoute, isNotNull);
      expect(legacyRoute.name, 'referee_submit_scorepad');
    });

    // -------------------------------------------------------------------------
    // Test 2: Missing or null match extra handling
    // -------------------------------------------------------------------------
    testWidgets('Requirement 2: Renders clean competitor selection state when match extra is null or empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MatchSubmissionScreen(match: null),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Select Table Competitors'), findsOneWidget);
      expect(find.text('Select athletes for Corner Red and Corner White to unlock the live interactive scorepad.'), findsOneWidget);
      expect(find.text('+ Red Corner'), findsOneWidget);
      expect(find.text('+ White Corner'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 3: Loaded match with competitors displays table-side HUD
    // -------------------------------------------------------------------------
    testWidgets('Requirement 3: Renders full symmetrical Corner Red and Corner White scoring cards when match is loaded',
        (WidgetTester tester) async {
      final testMatch = {
        'id': 'match_live_01',
        'athleteAId': 'ath_sultan',
        'athleteAName': 'Sultan Al-Balushi',
        'athleteBId': 'ath_kamran',
        'athleteBName': 'Kamran Zaidi',
        'arm': 'RIGHT',
      };

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MatchSubmissionScreen(match: testMatch),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CORNER RED'), findsOneWidget);
      expect(find.text('Sultan Al-Balushi'), findsOneWidget);
      expect(find.text('CORNER WHITE'), findsOneWidget);
      expect(find.text('Kamran Zaidi'), findsOneWidget);
      expect(find.text('RIGHT ARM'), findsOneWidget);
      expect(find.text('00:00'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 4: Strict 64dp Touch Targets (Point, Foul, Deduct, Pin Hold)
    // -------------------------------------------------------------------------
    testWidgets('Requirement 4: Point, Foul, Deduct (-1), and Pin Hold controls meet strict >= 64dp hit target specification',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LiveScorepadController(
                challengerName: 'Sultan Al-Balushi',
                opponentName: 'Kamran Zaidi',
                arm: 'RIGHT',
                maxPoints: 3,
                onMatchFinished: ({
                  required int challengerScore,
                  required int opponentScore,
                  required String winnerSide,
                  required String scoreLine,
                }) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. POINT Buttons (Red and White Corners)
      final pointButtons = find.widgetWithText(ElevatedButton, 'POINT');
      expect(pointButtons, findsNWidgets(2));
      final redPointTargetSize = tester.getSize(pointButtons.first);
      expect(redPointTargetSize.height, greaterThanOrEqualTo(64.0));

      // 2. FOUL Buttons (Red and White Corners)
      final foulButtons = find.widgetWithText(OutlinedButton, 'FOUL');
      expect(foulButtons, findsNWidgets(2));
      final redFoulTargetSize = tester.getSize(foulButtons.first);
      expect(redFoulTargetSize.height, greaterThanOrEqualTo(64.0));

      // 3. DEDUCT (-1) Buttons (Red and White Corners)
      final deductButtons = find.widgetWithText(OutlinedButton, '-1');
      expect(deductButtons, findsNWidgets(2));
      final redDeductTargetSize = tester.getSize(deductButtons.first);
      expect(redDeductTargetSize.height, greaterThanOrEqualTo(64.0));

      // 4. PIN HOLD Buttons (Red and White Corners)
      final pinHoldLabels = find.text('HOLD TO PIN (400ms)');
      expect(pinHoldLabels, findsNWidgets(2));
      final pinHoldParents = find.ancestor(
        of: pinHoldLabels.first,
        matching: find.byType(Container),
      );
      final pinHoldSize = tester.getSize(pinHoldParents.first);
      expect(pinHoldSize.height, greaterThanOrEqualTo(64.0));
    });

    // -------------------------------------------------------------------------
    // Test 5: Interactive Scoring, Foul Rule (2 Fouls = 1 Point to Opponent)
    // -------------------------------------------------------------------------
    testWidgets('Requirement 5: Point increment, point deduct, and 2 fouls auto-point to opponent operate accurately',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LiveScorepadController(
                challengerName: 'Sultan Al-Balushi',
                opponentName: 'Kamran Zaidi',
                arm: 'RIGHT',
                maxPoints: 3,
                onMatchFinished: ({
                  required int challengerScore,
                  required int opponentScore,
                  required String winnerSide,
                  required String scoreLine,
                }) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Increment Red point
      final pointButtons = find.widgetWithText(ElevatedButton, 'POINT');
      await tester.tap(pointButtons.first);
      await tester.pump();
      expect(find.text('1'), findsOneWidget); // Red has 1 point

      // Deduct Red point (-1)
      final deductButtons = find.widgetWithText(OutlinedButton, '-1');
      await tester.tap(deductButtons.first);
      await tester.pump();
      expect(find.text('0'), findsNWidgets(2)); // Both back to 0

      // Add 1st Foul on Red Corner
      final foulButtons = find.widgetWithText(OutlinedButton, 'FOUL');
      await tester.tap(foulButtons.first);
      await tester.pump();
      expect(find.text('F: 1/2'), findsOneWidget);

      // Add 2nd Foul on Red Corner -> Automatic point to White Corner
      await tester.tap(foulButtons.first);
      await tester.pump();
      expect(find.text('2 Fouls on Red Corner: Point awarded to White Corner.'), findsOneWidget);
      expect(find.text('1'), findsOneWidget); // White Corner now has 1 point!
    });

    // -------------------------------------------------------------------------
    // Test 6: 400ms Long-Press Pin Confirmation Lock (SIG-2)
    // -------------------------------------------------------------------------
    testWidgets('Requirement 6: 400ms Hold-to-Pin locks pin, triggers heavy feedback, and awards point',
        (WidgetTester tester) async {
      int finishedScoreChallenger = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LiveScorepadController(
                challengerName: 'Sultan Al-Balushi',
                opponentName: 'Kamran Zaidi',
                arm: 'RIGHT',
                maxPoints: 3,
                onMatchFinished: ({
                  required int challengerScore,
                  required int opponentScore,
                  required String winnerSide,
                  required String scoreLine,
                }) {
                  finishedScoreChallenger = challengerScore;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Gesture down on Pin Hold button for Red Corner
      final pinHoldGesture = await tester.startGesture(tester.getCenter(find.text('HOLD TO PIN (400ms)').first));
      await tester.pump(const Duration(milliseconds: 200));

      // Midpoint feedback active
      expect(find.textContaining('LOCKING PIN:'), findsOneWidget);

      // Complete 400ms hold threshold
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('PIN CONFIRMED'), findsOneWidget);
      expect(find.text('1'), findsOneWidget); // Score incremented to 1!

      await pinHoldGesture.up();
      await tester.pump(const Duration(milliseconds: 100)); // 80ms settle
    });

    // -------------------------------------------------------------------------
    // Test 7: Match Conclusion & Duplicate Submission Guard
    // -------------------------------------------------------------------------
    testWidgets('Requirement 7: Match conclusion displays sheet and guards against duplicate submission',
        (WidgetTester tester) async {
      int submitCount = 0;
      final completer = Completer<Map<String, dynamic>>();

      final fakeRepo = _FakeTournamentRepository(
        onSubmitTournamentResult: ({
          required String matchId,
          required String winnerId,
          required String scoreLine,
          CancelToken? cancelToken,
        }) async {
          submitCount++;
          return completer.future;
        },
      );

      final testMatch = {
        'id': 'match_live_99',
        'athleteAId': 'ath_sultan',
        'athleteAName': 'Sultan Al-Balushi',
        'athleteBId': 'ath_kamran',
        'athleteBName': 'Kamran Zaidi',
        'arm': 'RIGHT',
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tournamentRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: MatchSubmissionScreen(match: testMatch),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Increment Red Corner to 3 points (Win)
      final pointButtons = find.widgetWithText(ElevatedButton, 'POINT');
      await tester.tap(pointButtons.first);
      await tester.pump();
      await tester.tap(pointButtons.first);
      await tester.pump();
      await tester.tap(pointButtons.first);
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify conclusion sheet opened
      expect(find.text('MATCH CONCLUDED'), findsOneWidget);
      expect(find.textContaining('Sultan Al-Balushi wins the bout with score line 3-0.'), findsOneWidget);

      // Tap SUBMIT OFFICIAL RESULT
      final submitButton = find.widgetWithText(ElevatedButton, 'SUBMIT OFFICIAL RESULT');
      await tester.tap(submitButton);
      await tester.pump();

      // Tap again while loading to verify double-submission guard
      await tester.tap(find.byType(ElevatedButton).last, warnIfMissed: false);
      await tester.pump();

      expect(submitCount, 1); // Exactly 1 call made, second was blocked

      completer.complete({'status': 'COMPLETED'});
      await tester.pumpAndSettle();
      expect(find.text('Match result confirmed by server.'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 8: Offline Queue Feedback
    // -------------------------------------------------------------------------
    testWidgets('Requirement 8: OfflineException displays honest queued operational message and exits scorepad',
        (WidgetTester tester) async {
      final fakeRepo = _FakeTournamentRepository(
        onSubmitTournamentResult: ({
          required String matchId,
          required String winnerId,
          required String scoreLine,
          CancelToken? cancelToken,
        }) async {
          throw OfflineException('Submission queued offline. Will sync automatically when back online.');
        },
      );

      final testMatch = {
        'id': 'match_offline_01',
        'athleteAId': 'ath_sultan',
        'athleteAName': 'Sultan Al-Balushi',
        'athleteBId': 'ath_kamran',
        'athleteBName': 'Kamran Zaidi',
        'arm': 'RIGHT',
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tournamentRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: MatchSubmissionScreen(match: testMatch),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Reach conclusion (3 points)
      final pointButtons = find.widgetWithText(ElevatedButton, 'POINT');
      await tester.tap(pointButtons.first);
      await tester.pump();
      await tester.tap(pointButtons.first);
      await tester.pump();
      await tester.tap(pointButtons.first);
      await tester.pumpAndSettle();

      // Tap Submit
      await tester.tap(find.widgetWithText(ElevatedButton, 'SUBMIT OFFICIAL RESULT'));
      await tester.pumpAndSettle();

      // Verify honest offline feedback SnackBar
      expect(find.text('Result saved on this device and queued to sync when connection returns.'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 9: Reduced Motion & Accessibility Semantics
    // -------------------------------------------------------------------------
    testWidgets('Requirement 9: Respects disableAnimations and provides complete accessibility semantics',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: SingleChildScrollView(
                child: LiveScorepadController(
                  challengerName: 'Sultan Al-Balushi',
                  opponentName: 'Kamran Zaidi',
                  arm: 'RIGHT',
                  maxPoints: 3,
                  onMatchFinished: ({
                    required int challengerScore,
                    required int opponentScore,
                    required String winnerSide,
                    required String scoreLine,
                  }) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify semantics tags exist for key interactive elements
      expect(find.bySemanticsLabel('Add point for Sultan Al-Balushi on CORNER RED'), findsOneWidget);
      expect(find.bySemanticsLabel('Deduct point from Sultan Al-Balushi on CORNER RED'), findsOneWidget);
      expect(find.bySemanticsLabel('Assess foul on Sultan Al-Balushi on CORNER RED. Current fouls: 0 of 2'), findsOneWidget);
      expect(find.bySemanticsLabel('Assess warning on Sultan Al-Balushi on CORNER RED. Current warnings: 0 of 2'), findsOneWidget);
      expect(find.bySemanticsLabel('Hold for 400 milliseconds to confirm pin lock'), findsNWidgets(2));
      expect(find.bySemanticsLabel('Start match timer'), findsOneWidget);
      expect(find.bySemanticsLabel('Apply straps to competitors'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 10: Long Athlete Name Resilience
    // -------------------------------------------------------------------------
    testWidgets('Requirement 10: Layout remains robust with long athlete names without RenderFlex overflow',
        (WidgetTester tester) async {
      const longNameA = 'Grandmaster Muhammad Hamad Latif Sultan Al-Balushi of Balochistan Iron Hands';
      const longNameB = 'Senior National Champion Kamran Zaidi of Punjab TopRollers Armwrestling Club';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LiveScorepadController(
                challengerName: longNameA,
                opponentName: longNameB,
                arm: 'RIGHT',
                maxPoints: 3,
                onMatchFinished: ({
                  required int challengerScore,
                  required int opponentScore,
                  required String winnerSide,
                  required String scoreLine,
                }) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verified: no Flutter errors or overflow exceptions thrown
      expect(tester.takeException(), isNull);
      expect(find.text(longNameA), findsOneWidget);
      expect(find.text(longNameB), findsOneWidget);
    });
  });
}
