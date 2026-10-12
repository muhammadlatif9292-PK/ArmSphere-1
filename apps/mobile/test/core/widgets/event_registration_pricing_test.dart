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
  group('EventRegistrationScreen Dynamic Pricing & Summary Tests (Task 38 - ISSUE-P1-04)', () {
    const testTournamentId = 'tournament_test_01';

    final testEvent = {
      'id': testTournamentId,
      'name': 'National Armwrestling Open 2026',
      'location': 'Titanium Combat Arena',
      'city': 'Toronto',
      'registrationFeeCents': 5000, // CAD $50.00
    };

    final authenticatedAuth = AuthState(
      status: AuthStatus.authenticated,
      userProfile: {
        'id': 'athlete_444',
        'displayName': 'John Puller',
        'email': 'john@example.com',
      },
    );

    testWidgets('Renders anchored RegistrationSummaryCard and dynamic pricing CTA for single arm entry', (tester) async {
      final fakeTournament = _FakeTournamentNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(authenticatedAuth)),
            tournamentProvider.overrideWith(() => fakeTournament),
            eventDetailProvider(testTournamentId).overrideWith((ref) async => testEvent),
          ],
          child: const MaterialApp(
            home: EventRegistrationScreen(tournamentId: testTournamentId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify Event Name & Venue are displayed
      expect(find.text('National Armwrestling Open 2026'), findsOneWidget);
      expect(find.text('Titanium Combat Arena, Toronto'), findsOneWidget);

      // 2. Verify Registration Summary Card is anchored and present
      final summaryCardFinder = find.byKey(const ValueKey('registration_summary_card'));
      expect(summaryCardFinder, findsOneWidget);
      expect(find.text('REGISTRATION SUMMARY'), findsOneWidget);
      expect(find.text('SANCTIONED ENTRY'), findsOneWidget);

      // 3. Initial state: Senior, -85kg, Right Arm (1 Bracket)
      expect(find.textContaining('Senior (Open) • -85kg • Right Arm (1 Bracket)'), findsOneWidget);
      expect(find.text('Division Entry Fee'), findsOneWidget);
      expect(find.text('CAD \$50'), findsNWidgets(2)); // Card header pill and breakdown

      // 4. Verify Total Due in summary card
      final totalFeeFinder = find.byKey(const ValueKey('registration_total_fee_text'));
      expect(totalFeeFinder, findsOneWidget);
      expect(tester.widget<Text>(totalFeeFinder).data, 'CAD \$50');

      // 5. Verify Sticky Bottom Action Bar displays calculated price directly on CTA
      expect(find.text('Complete Registration — CAD \$50'), findsOneWidget);
    });

    testWidgets('Selecting Both Arms (Double Bracket) dynamically calculates second arm surcharge and updates CTA', (tester) async {
      final fakeTournament = _FakeTournamentNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(authenticatedAuth)),
            tournamentProvider.overrideWith(() => fakeTournament),
            eventDetailProvider(testTournamentId).overrideWith((ref) async => testEvent),
          ],
          child: const MaterialApp(
            home: EventRegistrationScreen(tournamentId: testTournamentId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initial state is single arm ($50)
      expect(find.text('Complete Registration — CAD \$50'), findsOneWidget);

      // Open Pulling Arm dropdown and select 'BOTH' (Both Arms Double Bracket)
      final armDropdown = find.byWidgetPredicate(
        (w) => w is DropdownButtonFormField<String> && w.initialValue == 'RIGHT',
      );
      expect(armDropdown, findsOneWidget);

      await tester.tap(armDropdown);
      await tester.pumpAndSettle();

      final bothArmsItem = find.text('Both Arms (Double Bracket)').last;
      await tester.tap(bothArmsItem);
      await tester.pumpAndSettle();

      // 1. Verify summary card configuration pill updated
      expect(find.textContaining('Both Arms (Double Bracket)'), findsWidgets);

      // 2. Verify itemized pricing displays base fee and second arm entry surcharge
      expect(find.text('Base Division Fee (Right Arm)'), findsOneWidget);
      expect(find.text('Second Arm Entry (Left Arm)'), findsOneWidget);
      expect(find.text('+ CAD \$50'), findsOneWidget);

      // 3. Verify total due is now $100
      final totalFeeFinder = find.byKey(const ValueKey('registration_total_fee_text'));
      expect(tester.widget<Text>(totalFeeFinder).data, 'CAD \$100');

      // 4. Verify sticky bottom submit CTA updated in real-time
      expect(find.text('Complete Registration — CAD \$100'), findsOneWidget);
    });

    testWidgets('Free entry event correctly renders Free Entry label in summary card and CTA', (tester) async {
      final freeEvent = {
        'id': testTournamentId,
        'name': 'Community Sparring Championship',
        'location': 'Local Community Gym',
        'city': 'Montreal',
        'registrationFeeCents': 0, // Free entry
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

      // Summary card shows 'Free entry'
      final totalFeeFinder = find.byKey(const ValueKey('registration_total_fee_text'));
      expect(tester.widget<Text>(totalFeeFinder).data, 'Free entry');

      // Sticky CTA displays 'Complete Registration — Free Entry'
      expect(find.text('Complete Registration — Free Entry'), findsOneWidget);
    });

    testWidgets('Submitting registration dispatches selected parameters and communicates success', (tester) async {
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
            eventDetailProvider(testTournamentId).overrideWith((ref) async => testEvent),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap submit CTA
      final submitButton = find.text('Complete Registration — CAD \$50');
      expect(submitButton, findsOneWidget);

      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // 1. Verify registerAthlete was called with the selected parameters
      expect(fakeTournament.lastRegistrationPayload, isNotNull);
      expect(fakeTournament.lastRegistrationPayload!['eventId'], testTournamentId);
      expect(fakeTournament.lastRegistrationPayload!['athleteId'], 'athlete_444');
      expect(fakeTournament.lastRegistrationPayload!['division'], 'SENIOR');
      expect(fakeTournament.lastRegistrationPayload!['weightClass'], '-85kg');
      expect(fakeTournament.lastRegistrationPayload!['arm'], 'RIGHT');

      // 2. Verify SnackBar communicates success
      expect(find.textContaining('Registration Recorded!'), findsOneWidget);
    });
  });
}
