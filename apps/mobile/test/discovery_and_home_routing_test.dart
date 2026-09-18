import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/routing/app_router.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'package:mobile/features/athlete/screens/athlete_screens.dart';
import 'package:mobile/features/referee/screens/referee_screens.dart';
import 'package:mobile/features/governance/screens/governance_screens.dart';
import 'package:mobile/features/home/screens/discover_screen.dart';
import 'package:mobile/core/providers/athlete_provider.dart';
import 'package:mobile/core/providers/live_matches_provider.dart';
import 'package:mobile/core/providers/tournament_provider.dart';
import 'package:mobile/core/providers/dispute_provider.dart';
import 'package:mobile/core/providers/referee_provider.dart';

class TestAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  TestAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAthleteProfileNotifier extends AthleteProfileNotifier {
  final Map<String, dynamic> _profile;
  FakeAthleteProfileNotifier(this._profile);

  @override
  Future<Map<String, dynamic>> build() async => _profile;
}

class FakeLiveMatchesNotifier extends LiveMatchesNotifier {
  @override
  Future<List<Map<String, dynamic>>> build() async => [];
}

class FakeDisputeNotifier extends DisputeNotifier {
  @override
  Future<List<Map<String, dynamic>>> build() async => [];
}

class FakeTournamentNotifier extends TournamentNotifier {
  @override
  Future<List<Map<String, dynamic>>> build() async => [];
}

void main() {
  group('RoleAwareHomeScreen Personalized Dashboard Routing Tests', () {
    testWidgets('Renders AthleteDashboardScreen for ATHLETE role', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => TestAuthNotifier(
                  AuthState(
                    status: AuthStatus.authenticated,
                    userProfile: {'id': 'user_1', 'displayName': 'Ali Khan', 'role': 'ATHLETE'},
                  ),
                )),
            athleteProfileProvider.overrideWith(() => FakeAthleteProfileNotifier({
                  'id': 'profile_1',
                  'rightArmElo': 1500,
                  'leftArmElo': 1480,
                  'weightClass': '78kg',
                })),
            liveMatchesProvider.overrideWith(() => FakeLiveMatchesNotifier()),
            trainingLogPRsProvider('profile_1').overrideWith((ref) async => <Map<String, dynamic>>[]),
          ],
          child: const MaterialApp(
            home: Scaffold(body: RoleAwareHomeScreen()),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(AthleteDashboardScreen), findsOneWidget);
      expect(find.byType(RefereeDashboardScreen), findsNothing);
      expect(find.byType(GovernanceDashboardScreen), findsNothing);
    });

    testWidgets('Renders RefereeDashboardScreen for REFEREE role', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => TestAuthNotifier(
                  AuthState(
                    status: AuthStatus.authenticated,
                    userProfile: {'id': 'user_2', 'displayName': 'Referee Ahmed', 'role': 'REFEREE'},
                  ),
                )),
            refereeCertificationsProvider.overrideWith((ref) async => <Map<String, dynamic>>[]),
            tournamentProvider.overrideWith(() => FakeTournamentNotifier()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: RoleAwareHomeScreen()),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(RefereeDashboardScreen), findsOneWidget);
      expect(find.byType(AthleteDashboardScreen), findsNothing);
      expect(find.byType(GovernanceDashboardScreen), findsNothing);
    });

    testWidgets('Renders GovernanceDashboardScreen for TOURNAMENT_OPERATOR role', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => TestAuthNotifier(
                  AuthState(
                    status: AuthStatus.authenticated,
                    userProfile: {'id': 'user_3', 'displayName': 'Director Usman', 'role': 'TOURNAMENT_OPERATOR'},
                  ),
                )),
            disputeProvider.overrideWith(() => FakeDisputeNotifier()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: RoleAwareHomeScreen()),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(GovernanceDashboardScreen), findsOneWidget);
      expect(find.byType(AthleteDashboardScreen), findsNothing);
      expect(find.byType(RefereeDashboardScreen), findsNothing);
    });

    testWidgets('Renders AthleteDashboardScreen by default when role is absent', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => TestAuthNotifier(
                  AuthState(
                    status: AuthStatus.authenticated,
                    userProfile: {'id': 'user_4', 'displayName': 'Guest User'},
                  ),
                )),
            athleteProfileProvider.overrideWith(() => FakeAthleteProfileNotifier({
                  'id': 'profile_4',
                  'rightArmElo': 1200,
                  'leftArmElo': 1200,
                })),
            liveMatchesProvider.overrideWith(() => FakeLiveMatchesNotifier()),
            trainingLogPRsProvider('profile_4').overrideWith((ref) async => <Map<String, dynamic>>[]),
          ],
          child: const MaterialApp(
            home: Scaffold(body: RoleAwareHomeScreen()),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(AthleteDashboardScreen), findsOneWidget);
    });
  });

  group('Discover Screen Architecture Verification', () {
    test('DiscoverScreen is a valid ConsumerWidget', () {
      const screen = DiscoverScreen();
      expect(screen, isA<ConsumerWidget>());
    });
  });
}
