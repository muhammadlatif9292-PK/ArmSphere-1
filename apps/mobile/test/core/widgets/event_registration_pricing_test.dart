import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/providers/tournament_provider.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'package:mobile/features/tournament/screens/event_registration_screen.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTournamentNotifier extends TournamentNotifier {
  final Map<String, dynamic>? registerResult;
  Map<String, dynamic>? lastRegistrationPayload;

  _FakeTournamentNotifier({this.registerResult});

  @override
  Future<List<Map<String, dynamic>>> build() async => [];

  @override
  Future<Map<String, dynamic>?> registerAthlete({
    required String eventId,
    required String athleteId,
    required String division,
    required String weightClass,
    required String arm,
    String? notes,
  }) async {
    lastRegistrationPayload = {
      'eventId': eventId,
      'athleteId': athleteId,
      'division': division,
      'weightClass': weightClass,
      'arm': arm,
    };
    return registerResult ?? {'status': 'PENDING'};
  }
}

void main() {
  group('EventRegistrationScreen Pricing Source-of-Truth Tests (Task 39)', () {
    const testTournamentId = 'tournament_test_01';

    final standardEvent = {
      'id': testTournamentId,
      'name': 'National Armwrestling Open 2026',
      'location': 'Titanium Combat Arena',
      'city': 'Toronto',
      'registrationFeeCents': 5000, // CAD $50.00
      'weightCategories': [
        {
          'id': 'wc_85',
          'label': '-85kg',
          'division': 'SENIOR',
          'arm': 'BOTH',
          'enabled': true,
        },
      ],
    };

    final authenticatedAuth = AuthState(
      status: AuthStatus.authenticated,
      userProfile: {
        'id': 'athlete_444',
        'displayName': 'John Puller',
        'email': 'john@example.com',
      },
    );

    testWidgets('1. Configured single-arm fee (CAD \$50) correctly populates summary card and CTA', (tester) async {
      final fakeTournament = _FakeTournamentNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(authenticatedAuth)),
            tournamentProvider.overrideWith(() => fakeTournament),
            eventDetailProvider(testTournamentId).overrideWith((ref) async => standardEvent),
          ],
          child: const MaterialApp(
            home: EventRegistrationScreen(tournamentId: testTournamentId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Event Name & Venue
      expect(find.text('National Armwrestling Open 2026'), findsOneWidget);
      expect(find.textContaining('Titanium Combat Arena, Toronto'), findsOneWidget);

      // Verify Registration Summary Card
      final summaryCardFinder = find.byKey(const ValueKey('registration_summary_card'));
      expect(summaryCardFinder, findsOneWidget);
      expect(find.text('REGISTRATION SUMMARY'), findsOneWidget);
      expect(find.text('SANCTIONED ENTRY'), findsOneWidget);

      // Initial state: Senior, -85kg, Right Arm
      expect(
        find.descendant(
          of: summaryCardFinder,
          matching: find.textContaining('-85kg • Right Arm'),
        ),
        findsOneWidget,
      );
      expect(find.text('Accompanied Spectator Guests'), findsOneWidget);
      expect(find.text('CAD \$50'), findsWidgets);

      // Verify Total Due in summary card matches authoritative event fee
      final totalFeeFinder = find.byKey(const ValueKey('registration_total_fee_text'));
      expect(totalFeeFinder, findsOneWidget);
      expect(tester.widget<Text>(totalFeeFinder).data, 'CAD \$50');

      // Verify Sticky Bottom Action Bar displays authoritative price directly on CTA
      expect(find.text('Apply to Compete — CAD \$50'), findsOneWidget);
    });

    testWidgets('2. Selecting Left Arm Bracket reflects selected bracket in summary without invented surcharge', (tester) async {
      final fakeTournament = _FakeTournamentNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(authenticatedAuth)),
            tournamentProvider.overrideWith(() => fakeTournament),
            eventDetailProvider(testTournamentId).overrideWith((ref) async => standardEvent),
          ],
          child: const MaterialApp(
            home: EventRegistrationScreen(tournamentId: testTournamentId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initial state is Right Arm ($50)
      expect(find.text('Apply to Compete — CAD \$50'), findsOneWidget);

      // Select 'LEFT' (Left Arm Bracket)
      final armDropdown = find.byWidgetPredicate(
        (w) => w is DropdownButtonFormField<String> && w.initialValue == 'RIGHT',
      );
      expect(armDropdown, findsOneWidget);

      await tester.ensureVisible(armDropdown);
      await tester.pumpAndSettle();
      await tester.tap(armDropdown);
      await tester.pumpAndSettle();

      final leftArmItem = find.text('Left Arm Bracket').last;
      await tester.tap(leftArmItem);
      await tester.pumpAndSettle();

      // Verify summary card configuration updated
      final summaryCardFinder = find.byKey(const ValueKey('registration_summary_card'));
      expect(
        find.descendant(
          of: summaryCardFinder,
          matching: find.textContaining('-85kg • Left Arm'),
        ),
        findsOneWidget,
      );

      // Authoritative pricing breakdown remains CAD $50 without surcharge
      expect(find.text('Accompanied Spectator Guests'), findsOneWidget);
      expect(find.text('+ CAD \$50'), findsNothing);

      // Total due remains authoritative event fee (CAD $50), NOT $100
      final totalFeeFinder = find.byKey(const ValueKey('registration_total_fee_text'));
      expect(tester.widget<Text>(totalFeeFinder).data, 'CAD \$50');

      // Sticky CTA remains synchronized with authoritative total (CAD $50)
      expect(find.text('Apply to Compete — CAD \$50'), findsOneWidget);
      expect(find.text('Apply to Compete — CAD \$100'), findsNothing);
    });

    testWidgets('3. Different event fees dynamically populate summary card and CTA from model (e.g. CAD \$25)', (tester) async {
      final tieredEvent = {
        'id': testTournamentId,
        'name': 'Provincial Qualifying Tournament',
        'location': 'Metro Convention Centre',
        'city': 'Calgary',
        'registrationFeeCents': 2500, // CAD $25.00
        'weightCategories': [
          {
            'id': 'wc_85',
            'label': '-85kg',
            'division': 'SENIOR',
            'arm': 'BOTH',
            'enabled': true,
          },
        ],
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(authenticatedAuth)),
            tournamentProvider.overrideWith(() => _FakeTournamentNotifier()),
            eventDetailProvider(testTournamentId).overrideWith((ref) async => tieredEvent),
          ],
          child: const MaterialApp(
            home: EventRegistrationScreen(tournamentId: testTournamentId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Summary card shows CAD $25
      final totalFeeFinder = find.byKey(const ValueKey('registration_total_fee_text'));
      expect(tester.widget<Text>(totalFeeFinder).data, 'CAD \$25');

      // Sticky CTA reflects CAD $25
      expect(find.text('Apply to Compete — CAD \$25'), findsOneWidget);
    });

    testWidgets('4. Free registration (0 cents) correctly renders Free Entry label in summary card and CTA', (tester) async {
      final freeEvent = {
        'id': testTournamentId,
        'name': 'Community Sparring Championship',
        'location': 'Local Community Gym',
        'city': 'Montreal',
        'registrationFeeCents': 0, // Free entry
        'weightCategories': [
          {
            'id': 'wc_85',
            'label': '-85kg',
            'division': 'SENIOR',
            'arm': 'BOTH',
            'enabled': true,
          },
        ],
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(authenticatedAuth)),
            tournamentProvider.overrideWith(() => _FakeTournamentNotifier()),
            eventDetailProvider(testTournamentId).overrideWith((ref) async => freeEvent),
          ],
          child: const MaterialApp(
            home: EventRegistrationScreen(tournamentId: testTournamentId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Summary card shows 'Free Entry'
      final totalFeeFinder = find.byKey(const ValueKey('registration_total_fee_text'));
      expect(tester.widget<Text>(totalFeeFinder).data, 'Free Entry');

      // Sticky CTA displays 'Apply to Compete — Free Entry'
      expect(find.text('Apply to Compete — Free Entry'), findsOneWidget);
    });

    testWidgets('5. Missing or unconfigured fee data (null) safely defaults to Free Entry without crash', (tester) async {
      final unconfiguredFeeEvent = {
        'id': testTournamentId,
        'name': 'Informal Club Open',
        'location': 'ArmSphere HQ',
        'city': 'Vancouver',
        'registrationFeeCents': null, // Unconfigured / null
        'weightCategories': [
          {
            'id': 'wc_85',
            'label': '-85kg',
            'division': 'SENIOR',
            'arm': 'BOTH',
            'enabled': true,
          },
        ],
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(authenticatedAuth)),
            tournamentProvider.overrideWith(() => _FakeTournamentNotifier()),
            eventDetailProvider(testTournamentId).overrideWith((ref) async => unconfiguredFeeEvent),
          ],
          child: const MaterialApp(
            home: EventRegistrationScreen(tournamentId: testTournamentId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Summary card shows 'Free Entry'
      final totalFeeFinder = find.byKey(const ValueKey('registration_total_fee_text'));
      expect(tester.widget<Text>(totalFeeFinder).data, 'Free Entry');

      // Sticky CTA displays 'Apply to Compete — Free Entry'
      expect(find.text('Apply to Compete — Free Entry'), findsOneWidget);
    });

    testWidgets('6. Loading state disables submit CTA and prevents premature free entry assumption', (tester) async {
      const loadingTournamentId = 'tournament_loading_test_06';
      final completer = Completer<Map<String, dynamic>>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(authenticatedAuth)),
            tournamentProvider.overrideWith(() => _FakeTournamentNotifier()),
            eventDetailProvider(loadingTournamentId).overrideWith((ref) => completer.future),
          ],
          child: const MaterialApp(
            home: EventRegistrationScreen(tournamentId: loadingTournamentId),
          ),
        ),
      );

      // Initial pump: eventAsync is loading
      await tester.pump();

      // CTA indicates loading and is disabled
      expect(find.text('Loading Event Details...'), findsOneWidget);
      expect(find.text('Loading...'), findsWidgets);

      // Now resolve event data
      completer.complete({
        ...standardEvent,
        'id': loadingTournamentId,
      });
      await tester.pumpAndSettle();

      // CTA is now active with authoritative fee
      expect(find.text('Apply to Compete — CAD \$50'), findsOneWidget);
    });

    testWidgets('7. Submitting registration dispatches selected parameters with arm choice and communicates success', (tester) async {
      final fakeTournament = _FakeTournamentNotifier(
        registerResult: {'status': 'PENDING'},
      );

      final router = GoRouter(
        initialLocation: '/register',
        routes: [
          GoRoute(
            path: '/register',
            builder: (context, state) => const EventRegistrationScreen(tournamentId: testTournamentId),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(authenticatedAuth)),
            tournamentProvider.overrideWith(() => fakeTournament),
            eventDetailProvider(testTournamentId).overrideWith((ref) async => standardEvent),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Select 'LEFT' (Left Arm Bracket)
      final armDropdown = find.byWidgetPredicate(
        (w) => w is DropdownButtonFormField<String> && w.initialValue == 'RIGHT',
      );
      await tester.ensureVisible(armDropdown);
      await tester.pumpAndSettle();
      await tester.tap(armDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Left Arm Bracket').last);
      await tester.pumpAndSettle();

      // Tap submit CTA
      final submitButton = find.text('Apply to Compete — CAD \$50');
      expect(submitButton, findsOneWidget);

      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verify registerAthlete was called with arm: LEFT
      expect(fakeTournament.lastRegistrationPayload, isNotNull);
      expect(fakeTournament.lastRegistrationPayload!['eventId'], testTournamentId);
      expect(fakeTournament.lastRegistrationPayload!['athleteId'], 'athlete_444');
      expect(fakeTournament.lastRegistrationPayload!['division'], 'SENIOR');
      expect(fakeTournament.lastRegistrationPayload!['weightClass'], '-85kg');
      expect(fakeTournament.lastRegistrationPayload!['arm'], 'LEFT');

      // Verify confirmation dialog communicates success
      expect(find.text('REGISTRATION CONFIRMED'), findsOneWidget);
      expect(find.textContaining('Confirmed • -85kg • Left Arm'), findsOneWidget);
    });
  });
}
