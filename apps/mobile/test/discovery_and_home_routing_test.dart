import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/routing/app_router.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'package:mobile/features/athlete/screens/athlete_screens.dart';
import 'package:mobile/features/referee/screens/referee_screens.dart';
import 'package:mobile/features/governance/screens/governance_screens.dart';
import 'package:mobile/features/tournament/screens/tournament_operator_dashboard_screen.dart';
import 'package:mobile/features/home/screens/discover_screen.dart';
import 'package:mobile/core/providers/athlete_provider.dart';
import 'package:mobile/core/providers/live_matches_provider.dart';
import 'package:mobile/core/providers/tournament_provider.dart';
import 'package:mobile/core/providers/rankings_provider.dart';
import 'package:mobile/core/providers/dispute_provider.dart';
import 'package:mobile/core/providers/referee_provider.dart';
import 'package:mobile/core/providers/discover_provider.dart';
import 'package:mobile/core/providers/venue_provider.dart';

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

class FakeRankingsNotifier extends RankingsNotifier {
  @override
  Future<List<Map<String, dynamic>>> build() async => [];
}

class FakeDiscoverFeedNotifier extends DiscoverFeedNotifier {
  final Map<String, dynamic> _feed;
  FakeDiscoverFeedNotifier(this._feed);

  @override
  Future<Map<String, dynamic>> build() async => _feed;
}

class FakeVenueListNotifier extends VenueListNotifier {
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
                    userProfile: {'id': 'profile_1', 'displayName': 'Ali Khan', 'role': 'ATHLETE'},
                  ),
                )),
            athleteProfileProvider.overrideWith(() => FakeAthleteProfileNotifier({
                  'id': 'profile_1',
                  'rightArmElo': 1500,
                  'leftArmElo': 1480,
                  'weightClass': '78kg',
                })),
            liveMatchesProvider.overrideWith(() => FakeLiveMatchesNotifier()),
            tournamentProvider.overrideWith(() => FakeTournamentNotifier()),
            rankingsProvider.overrideWith(() => FakeRankingsNotifier()),
            trainingLogProvider('profile_1').overrideWith((ref) async => <Map<String, dynamic>>[]),
            trainingLogPRsProvider('profile_1').overrideWith((ref) async => <Map<String, dynamic>>[]),
            trainingLogPRsProvider('user_1').overrideWith((ref) async => <Map<String, dynamic>>[]),
          ],
          child: const MaterialApp(
            home: Scaffold(body: RoleAwareHomeScreen()),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(AthleteDashboardScreen), findsOneWidget);
      expect(find.byType(RefereeDashboardScreen), findsNothing);
      expect(find.byType(TournamentOperatorDashboardScreen), findsNothing);
      expect(find.byType(GovernanceDashboardScreen), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
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
      expect(find.byType(TournamentOperatorDashboardScreen), findsNothing);
      expect(find.byType(GovernanceDashboardScreen), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('Renders TournamentOperatorDashboardScreen for TOURNAMENT_OPERATOR role', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => TestAuthNotifier(
                  AuthState(
                    status: AuthStatus.authenticated,
                    userProfile: {'id': 'user_3', 'displayName': 'Director Usman', 'role': 'TOURNAMENT_OPERATOR'},
                  ),
                )),
            tournamentProvider.overrideWith(() => FakeTournamentNotifier()),
            disputeProvider.overrideWith(() => FakeDisputeNotifier()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: RoleAwareHomeScreen()),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(TournamentOperatorDashboardScreen), findsOneWidget);
      expect(find.byType(AthleteDashboardScreen), findsNothing);
      expect(find.byType(RefereeDashboardScreen), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('Renders AthleteDashboardScreen by default when role is absent', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => TestAuthNotifier(
                  AuthState(
                    status: AuthStatus.authenticated,
                    userProfile: {'id': 'profile_4', 'displayName': 'Guest User'},
                  ),
                )),
            athleteProfileProvider.overrideWith(() => FakeAthleteProfileNotifier({
                  'id': 'profile_4',
                  'rightArmElo': 1200,
                  'leftArmElo': 1200,
                })),
            liveMatchesProvider.overrideWith(() => FakeLiveMatchesNotifier()),
            tournamentProvider.overrideWith(() => FakeTournamentNotifier()),
            rankingsProvider.overrideWith(() => FakeRankingsNotifier()),
            trainingLogProvider('profile_4').overrideWith((ref) async => <Map<String, dynamic>>[]),
            trainingLogPRsProvider('profile_4').overrideWith((ref) async => <Map<String, dynamic>>[]),
            trainingLogPRsProvider('user_4').overrideWith((ref) async => <Map<String, dynamic>>[]),
          ],
          child: const MaterialApp(
            home: Scaffold(body: RoleAwareHomeScreen()),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(AthleteDashboardScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  });

  group('Discover Screen Architecture Verification', () {
    test('DiscoverScreen is a valid ConsumerStatefulWidget', () {
      const screen = DiscoverScreen();
      expect(screen, isA<ConsumerStatefulWidget>());
    });

    testWidgets('Renders 2x2 Federation Hub portals, framed sections, and compact empty states', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            discoverFeedProvider.overrideWith(() => FakeDiscoverFeedNotifier({
                  'liveMatches': <Map<String, dynamic>>[],
                  'announcements': <Map<String, dynamic>>[],
                  'upcomingTournaments': <Map<String, dynamic>>[],
                  'topAthletes': [
                    {
                      'id': 'ath_1',
                      'rank': 1,
                      'displayName': 'Muhammad Latif',
                      'division': 'SENIOR',
                      'eloRating': 1000,
                    },
                  ],
                  'recentCompletedMatches': <Map<String, dynamic>>[],
                })),
            tournamentProvider.overrideWith(() => FakeTournamentNotifier()),
            venueListProvider.overrideWith(() => FakeVenueListNotifier()),
          ],
          child: const MaterialApp(
            home: DiscoverScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify all 4 Federation Hub portals render simultaneously in the 2x2 bento grid
      expect(find.text('Federation Hub'), findsOneWidget);
      expect(find.text('Training Venues'), findsOneWidget);
      expect(find.text('Pickup Meetups'), findsOneWidget);
      expect(find.text('Community Feed'), findsOneWidget);
      expect(find.text('ELO Rankings'), findsOneWidget);

      // Verify active Top Rankings Leaderboard section is prioritized above empty sections
      expect(find.text('Top Rankings Leaderboard'), findsOneWidget);
      expect(find.text('Muhammad Latif'), findsOneWidget);
      expect(find.text('1000 ELO'), findsOneWidget);

      // Verify framed empty state banners render cleanly
      expect(find.text('Sanctioned Tournaments'), findsOneWidget);
      expect(find.text('No tournaments scheduled'), findsOneWidget);
    });
  });
}

