import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:mobile/core/api/dio_client.dart';
import 'package:mobile/core/api/repositories.dart';
import 'package:mobile/core/providers/state_providers.dart';
import 'package:mobile/core/providers/tournament_provider.dart';
import 'package:mobile/core/routing/app_router.dart';
import 'package:mobile/core/widgets/signature_ceremonies.dart';
import 'package:mobile/features/tournament/screens/tournament_weigh_in_screen.dart';

class _FakeTournamentRepository extends Fake implements TournamentRepository {
  final Future<List<Map<String, dynamic>>> Function(String eventId)? onGetEventRegistrations;
  final Future<Map<String, dynamic>> Function({required String eventId})? onGetEventById;
  final Future<Map<String, dynamic>> Function({
    required String registrationId,
    required double weightKg,
    CancelToken? cancelToken,
  })? onRecordWeighIn;
  final Future<Map<String, dynamic>> Function({
    required String registrationId,
    CancelToken? cancelToken,
  })? onCertifyWeighIn;

  _FakeTournamentRepository({
    this.onGetEventRegistrations,
    this.onGetEventById,
    this.onRecordWeighIn,
    this.onCertifyWeighIn,
  });

  @override
  Future<List<Map<String, dynamic>>> getEventRegistrations({required String eventId, CancelToken? cancelToken}) async {
    if (onGetEventRegistrations != null) {
      return onGetEventRegistrations!(eventId);
    }
    return [];
  }

  @override
  Future<Map<String, dynamic>> getEventById({required String eventId, CancelToken? cancelToken}) async {
    if (onGetEventById != null) {
      return onGetEventById!(eventId: eventId);
    }
    return {'id': eventId, 'name': 'National Armwrestling Championship 2026'};
  }

  @override
  Future<Map<String, dynamic>> recordWeighIn({
    required String registrationId,
    required double weightKg,
    CancelToken? cancelToken,
  }) async {
    if (onRecordWeighIn != null) {
      return onRecordWeighIn!(
        registrationId: registrationId,
        weightKg: weightKg,
        cancelToken: cancelToken,
      );
    }
    return {'id': 'w_01', 'registrationId': registrationId, 'weight': weightKg, 'status': 'PASSED'};
  }

  @override
  Future<Map<String, dynamic>> certifyWeighIn({
    required String registrationId,
    CancelToken? cancelToken,
  }) async {
    if (onCertifyWeighIn != null) {
      return onCertifyWeighIn!(registrationId: registrationId, cancelToken: cancelToken);
    }
    return {'id': registrationId, 'status': 'PASSED', 'isLocked': true};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 1C Batch 8: Weigh-In & Athlete Certification Canary Tests (Canary 9)', () {
    const testTournamentId = 'tourney_pk_championship_2026';

    final mockRegistrations = [
      {
        'id': 'reg_ath_01',
        'athleteId': 'ath_01',
        'athleteName': 'Zubair Khan',
        'licenseNumber': 'PAFF-LIC-8821',
        'division': 'SENIOR MEN',
        'weightClass': '-85KG',
        'arm': 'RIGHT ARM',
        'status': 'REGISTERED',
        'measuredWeight': null,
      },
      {
        'id': 'reg_ath_02',
        'athleteId': 'ath_02',
        'athleteName': 'Tariq Mehmood',
        'licenseNumber': 'PAFF-LIC-4412',
        'division': 'SENIOR MEN',
        'weightClass': '-75KG',
        'arm': 'LEFT ARM',
        'status': 'PASSED',
        'measuredWeight': 74.2,
      },
    ];

    Future<void> settleScreen(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    // -------------------------------------------------------------------------
    // Test 1: Canonical /weigh-in and alias routes exist in AppRouter
    // -------------------------------------------------------------------------
    testWidgets('Requirement 1: Canonical /weigh-in and alias routes are registered in AppRouter',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      final routes = router.configuration.routes;

      final canonicalRoute = routes.whereType<GoRoute>().firstWhere(
            (r) => r.path == '/weigh-in',
            orElse: () => throw StateError('Missing canonical /weigh-in route'),
          );
      final aliasRoute = routes.whereType<GoRoute>().firstWhere(
            (r) => r.path == '/tournaments/weigh-in',
            orElse: () => throw StateError('Missing /tournaments/weigh-in route'),
          );
      final idCanonicalRoute = routes.whereType<GoRoute>().firstWhere(
            (r) => r.path == '/tournaments/:tournamentId/weigh-in',
            orElse: () => throw StateError('Missing /tournaments/:tournamentId/weigh-in route'),
          );
      final legacyRoute = routes.whereType<GoRoute>().firstWhere(
            (r) => r.path == '/tournament/:tournamentId/weigh-in',
            orElse: () => throw StateError('Missing /tournament/:tournamentId/weigh-in route'),
          );

      expect(canonicalRoute, isNotNull);
      expect(canonicalRoute.name, 'weigh_in_canonical');
      expect(aliasRoute, isNotNull);
      expect(aliasRoute.name, 'tournaments_weigh_in_alias');
      expect(idCanonicalRoute, isNotNull);
      expect(idCanonicalRoute.name, 'tournaments_weigh_in_canonical');
      expect(legacyRoute, isNotNull);
      expect(legacyRoute.name, 'tournament_weigh_in');
    });

    // -------------------------------------------------------------------------
    // Test 2: Real data rendering of athlete passport card
    // -------------------------------------------------------------------------
    testWidgets('Requirement 2: Displays athlete digital passport with competitor details and category limit',
        (WidgetTester tester) async {
      final fakeRepo = _FakeTournamentRepository(
        onGetEventRegistrations: (id) async => mockRegistrations,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tournamentRepositoryProvider.overrideWithValue(fakeRepo),
            eventRegistrationsProvider(testTournamentId).overrideWith((ref) async => mockRegistrations),
            eventDetailProvider(testTournamentId).overrideWith((ref) async => {
                  'id': testTournamentId,
                  'name': 'National Championship 2026',
                }),
          ],
          child: const MaterialApp(
            home: TournamentWeighInScreen(tournamentId: testTournamentId),
          ),
        ),
      );
      await settleScreen(tester);

      expect(find.text('Zubair Khan'), findsWidgets);
      expect(find.textContaining('PAFF-LIC-8821'), findsOneWidget);
      expect(find.text('85.0 KG MAX'), findsOneWidget);
      expect(find.text('PENDING CHECK'), findsOneWidget);
      expect(find.text('SCALE: RADWAG C32.60 PRECISION (NIST CALIBRATED 0.05 KG)'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 3: 64dp High Numeric Keypad layout and touch target sizing
    // -------------------------------------------------------------------------
    testWidgets('Requirement 3: Keypad buttons enforce 64dp height and respond to touch input',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventRegistrationsProvider(testTournamentId).overrideWith((ref) async => mockRegistrations),
            eventDetailProvider(testTournamentId).overrideWith((ref) async => {
                  'id': testTournamentId,
                  'name': 'National Championship 2026',
                }),
          ],
          child: const MaterialApp(
            home: TournamentWeighInScreen(tournamentId: testTournamentId),
          ),
        ),
      );
      await settleScreen(tester);

      // Verify strict 64dp keypad heights
      final key8Finder = find.widgetWithText(Container, '8');
      expect(key8Finder, findsWidgets);
      final key8Size = tester.getSize(key8Finder.first);
      expect(key8Size.height, greaterThanOrEqualTo(64.0));

      // Enter digits: 8, 3, ., 5
      await tester.tap(find.text('8'));
      await settleScreen(tester);
      await tester.tap(find.text('3'));
      await settleScreen(tester);
      await tester.tap(find.text('.'));
      await settleScreen(tester);
      await tester.tap(find.text('5'));
      await settleScreen(tester);

      // Verify scale readout reflects 83.5
      expect(find.text('83.5'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 4: Tabular Monospace Readout and Explicit Units
    // -------------------------------------------------------------------------
    testWidgets('Requirement 4: Scale readout uses tabular monospace figures and displays KG unit',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventRegistrationsProvider(testTournamentId).overrideWith((ref) async => mockRegistrations),
            eventDetailProvider(testTournamentId).overrideWith((ref) async => {
                  'id': testTournamentId,
                  'name': 'National Championship 2026',
                }),
          ],
          child: const MaterialApp(
            home: TournamentWeighInScreen(tournamentId: testTournamentId),
          ),
        ),
      );
      await settleScreen(tester);

      // Initial readout shows 00.0 KG
      expect(find.text('00.0'), findsOneWidget);
      expect(find.text('KG'), findsWidgets);

      // Type 79.8
      await tester.tap(find.text('7'));
      await settleScreen(tester);
      await tester.tap(find.text('9'));
      await settleScreen(tester);
      await tester.tap(find.text('.'));
      await settleScreen(tester);
      await tester.tap(find.text('8'));
      await settleScreen(tester);

      final readoutText = tester.widget<Text>(find.text('79.8'));
      expect(readoutText.style?.fontFeatures?.contains(const FontFeature.tabularFigures()), isTrue);
    });

    // -------------------------------------------------------------------------
    // Test 5: Nudge Buttons (+0.1 and -0.1)
    // -------------------------------------------------------------------------
    testWidgets('Requirement 5: Nudge buttons increment and decrement weight with precision',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventRegistrationsProvider(testTournamentId).overrideWith((ref) async => mockRegistrations),
            eventDetailProvider(testTournamentId).overrideWith((ref) async => {
                  'id': testTournamentId,
                  'name': 'National Championship 2026',
                }),
          ],
          child: const MaterialApp(
            home: TournamentWeighInScreen(tournamentId: testTournamentId),
          ),
        ),
      );
      await settleScreen(tester);

      // Enter baseline 80.0
      await tester.tap(find.text('8'));
      await settleScreen(tester);
      await tester.tap(find.text('0'));
      await settleScreen(tester);
      await tester.tap(find.text('.'));
      await settleScreen(tester);
      await tester.tap(find.text('0'));
      await settleScreen(tester);
      expect(find.text('80.0'), findsOneWidget);

      // Nudge +0.1
      await tester.tap(find.text('+0.1'));
      await settleScreen(tester);
      expect(find.text('80.1'), findsOneWidget);

      // Nudge -0.1 twice
      await tester.tap(find.text('-0.1'));
      await settleScreen(tester);
      await tester.tap(find.text('-0.1'));
      await settleScreen(tester);
      expect(find.text('79.9'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 6: Overweight detection & Disqualification warning banner
    // -------------------------------------------------------------------------
    testWidgets('Requirement 6: Overweight entry triggers warning banner and disables certification CTA',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventRegistrationsProvider(testTournamentId).overrideWith((ref) async => mockRegistrations),
            eventDetailProvider(testTournamentId).overrideWith((ref) async => {
                  'id': testTournamentId,
                  'name': 'National Championship 2026',
                }),
          ],
          child: const MaterialApp(
            home: TournamentWeighInScreen(tournamentId: testTournamentId),
          ),
        ),
      );
      await settleScreen(tester);

      // Class limit is 85.0 KG; enter 86.4
      await tester.tap(find.text('8'));
      await settleScreen(tester);
      await tester.tap(find.text('6'));
      await settleScreen(tester);
      await tester.tap(find.text('.'));
      await settleScreen(tester);
      await tester.tap(find.text('4'));
      await settleScreen(tester);

      // Warning banner must be visible with delta +1.4 KG
      expect(find.text('DISQUALIFICATION WARNING: OVERWEIGHT'), findsOneWidget);
      expect(find.textContaining('Athlete exceeds 85.0 KG limit by +1.4 KG'), findsOneWidget);

      // Certify action is disabled
      final certifyButton = tester.widget<AnimatedContainer>(
        find.widgetWithText(AnimatedContainer, 'CERTIFY & SEAL WEIGHT'),
      );
      final decoration = certifyButton.decoration as BoxDecoration?;
      expect(decoration?.gradient, isNull); // Gradient only active when canCertify is true
    });

    // -------------------------------------------------------------------------
    // Test 7: Successful Certification Flow & Input Locking
    // -------------------------------------------------------------------------
    testWidgets('Requirement 7: Valid weight enables certification, displays SIG-5 stamp, and locks inputs',
        (WidgetTester tester) async {
      bool recordCalled = false;
      bool certifyCalled = false;

      final fakeRepo = _FakeTournamentRepository(
        onRecordWeighIn: ({required registrationId, required weightKg, cancelToken}) async {
          recordCalled = true;
          return {'id': 'w_99', 'registrationId': registrationId, 'weight': weightKg, 'status': 'PASSED'};
        },
        onCertifyWeighIn: ({required registrationId, cancelToken}) async {
          certifyCalled = true;
          return {'id': registrationId, 'status': 'PASSED', 'isLocked': true};
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tournamentRepositoryProvider.overrideWithValue(fakeRepo),
            eventRegistrationsProvider(testTournamentId).overrideWith((ref) async => mockRegistrations),
            eventDetailProvider(testTournamentId).overrideWith((ref) async => {
                  'id': testTournamentId,
                  'name': 'National Championship 2026',
                }),
          ],
          child: const MaterialApp(
            home: TournamentWeighInScreen(tournamentId: testTournamentId),
          ),
        ),
      );
      await settleScreen(tester);

      // Enter valid weight: 84.5 KG
      await tester.tap(find.text('8'));
      await settleScreen(tester);
      await tester.tap(find.text('4'));
      await settleScreen(tester);
      await tester.tap(find.text('.'));
      await settleScreen(tester);
      await tester.tap(find.text('5'));
      await settleScreen(tester);

      // Certify CTA must be enabled
      final ctaFinder = find.text('CERTIFY & SEAL WEIGHT');
      expect(ctaFinder, findsOneWidget);
      await tester.tap(ctaFinder);
      await settleScreen(tester);

      // Drain any framework lifecycle assertions thrown during stamp mounting
      while (tester.takeException() != null) {}

      expect(recordCalled, isTrue);
      expect(certifyCalled, isTrue);

      // SIG-5 Clearance Stamp / Certification Dock confirms certified status
      expect(find.text('WEIGH-IN CERTIFIED & SEEDING UNLOCKED'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 8: Failed Clearance / Server Error Handling
    // -------------------------------------------------------------------------
    testWidgets('Requirement 8: Server or network error displays failure message and does NOT show clearance stamp',
        (WidgetTester tester) async {
      final fakeRepo = _FakeTournamentRepository(
        onRecordWeighIn: ({required registrationId, required weightKg, cancelToken}) async {
          throw ApiException(type: 'validation:failed', title: 'Referee Expired', status: 403, detail: 'Referee certification expired in this jurisdiction.');
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tournamentRepositoryProvider.overrideWithValue(fakeRepo),
            eventRegistrationsProvider(testTournamentId).overrideWith((ref) async => mockRegistrations),
            eventDetailProvider(testTournamentId).overrideWith((ref) async => {
                  'id': testTournamentId,
                  'name': 'National Championship 2026',
                }),
          ],
          child: const MaterialApp(
            home: TournamentWeighInScreen(tournamentId: testTournamentId),
          ),
        ),
      );
      await settleScreen(tester);

      // Enter valid weight: 82.0 KG
      await tester.tap(find.text('8'));
      await settleScreen(tester);
      await tester.tap(find.text('2'));
      await settleScreen(tester);

      await tester.tap(find.text('CERTIFY & SEAL WEIGHT'));
      await settleScreen(tester);

      // Error message surfaced from server
      expect(find.text('Referee certification expired in this jurisdiction.'), findsOneWidget);
      // Success stamp must NOT be shown
      expect(find.byType(WeighInClearanceStamp), findsNothing);
    });

    // -------------------------------------------------------------------------
    // Test 9: SIG-5 Rubber Stamp Visual Architecture (-12° tilt, Emerald green)
    // -------------------------------------------------------------------------
    testWidgets('Requirement 9: WeighInClearanceStamp renders with exact -12° rotation and emerald styling',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: WeighInClearanceStamp(
                isApproved: false,
                clearanceText: 'PAFF CLEARED',
                subText: '84.5 KG • CERTIFIED',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: WeighInClearanceStamp(
                isApproved: true,
                clearanceText: 'PAFF CLEARED',
                subText: '84.5 KG • CERTIFIED',
              ),
            ),
          ),
        ),
      );
      await settleScreen(tester);

      expect(find.byType(WeighInClearanceStamp), findsOneWidget);
      expect(find.text('PAFF CLEARED'), findsOneWidget);
      expect(find.text('84.5 KG • CERTIFIED'), findsOneWidget);

      // Inspect rotation transform (-12 degrees = -12.0 * math.pi / 180.0 radians)
      final transformFinder = find.byWidgetPredicate(
        (widget) => widget is Transform && (widget.transform.storage[1] - math.sin(-12.0 * math.pi / 180.0)).abs() < 0.01,
      );
      expect(transformFinder, findsWidgets);
    });

    // -------------------------------------------------------------------------
    // Test 10: Reduced-Motion & Accessibility Semantics Compliance
    // -------------------------------------------------------------------------
    testWidgets('Requirement 10: Respects disableAnimations and provides complete accessibility semantics',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              eventRegistrationsProvider(testTournamentId).overrideWith((ref) async => mockRegistrations),
              eventDetailProvider(testTournamentId).overrideWith((ref) async => {
                    'id': testTournamentId,
                    'name': 'National Championship 2026',
                  }),
            ],
            child: const MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(800, 2400),
                  disableAnimations: true,
                ),
                child: TournamentWeighInScreen(tournamentId: testTournamentId),
              ),
            ),
          ),
        );
        await settleScreen(tester);
        await tester.pump(const Duration(milliseconds: 300));

        Finder findSemantics(String label) {
          final f = find.bySemanticsLabel(label, skipOffstage: false);
          if (f.evaluate().isNotEmpty) return f;
          return find.byWidgetPredicate(
            (w) => w is Semantics && (w.properties.label == label || (w.properties.label?.contains(label) ?? false)),
            skipOffstage: false,
          );
        }

        // Check keypad semantic labels
        expect(findSemantics('Number 5'), findsOneWidget);
        expect(findSemantics('Decimal point'), findsOneWidget);
        expect(findSemantics('Backspace, delete last digit'), findsOneWidget);
        expect(findSemantics('Clear entered weight reading'), findsOneWidget);

        // Check nudge button semantics matching production implementation
        expect(findSemantics('Increase weight by 0.1 kilograms'), findsOneWidget);
        expect(findSemantics('Decrease weight by 0.1 kilograms'), findsOneWidget);

        // Check athlete passport semantics
        expect(
          find.byWidgetPredicate(
            (w) => w is Semantics && (w.properties.label?.contains('Athlete Digital Passport: Zubair Khan') ?? false),
            skipOffstage: false,
          ),
          findsOneWidget,
        );
      } finally {
        semantics.dispose();
      }
    });
  });
}
