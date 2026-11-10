import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/providers/informal_event_provider.dart';
import 'package:mobile/core/providers/social_provider.dart';
import 'package:mobile/core/providers/venue_provider.dart';
import 'package:mobile/core/widgets/main_shell_screen.dart';
import 'package:mobile/features/informal_event/screens/informal_event_directory_screen.dart';
import 'package:mobile/features/team/screens/team_screens.dart';
import 'package:mobile/features/venue/screens/venue_directory_screen.dart';

class _FakeVenueListNotifier extends VenueListNotifier {
  final List<Map<String, dynamic>> _data;
  _FakeVenueListNotifier(this._data);

  @override
  Future<List<Map<String, dynamic>>> build() async => _data;
}

class _FakeInformalEventListNotifier extends InformalEventListNotifier {
  final List<Map<String, dynamic>> _data;
  _FakeInformalEventListNotifier(this._data);

  @override
  Future<List<Map<String, dynamic>>> build() async => _data;
}

class _FakeMyTeamsNotifier extends MyTeamsNotifier {
  final List<Map<String, dynamic>> _data;
  _FakeMyTeamsNotifier(this._data);

  @override
  Future<List<Map<String, dynamic>>> build() async => _data;
}

void main() {
  group('Directory Creation Action Consistency Tests (Task 37)', () {
    group('VenueDirectoryScreen (S-048)', () {
      testWidgets('Empty state renders persistent AppBar CTA and onboarding CTA, both routing to /venues/submit', (tester) async {
        final router = GoRouter(
          initialLocation: '/venues',
          routes: [
            GoRoute(
              path: '/venues',
              builder: (context, state) => const VenueDirectoryScreen(),
            ),
            GoRoute(
              path: '/venues/submit',
              builder: (context, state) => const Scaffold(body: Text('TARGET: /venues/submit')),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              venueListProvider.overrideWith(() => _FakeVenueListNotifier([])),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 1. Persistent styled AppBar CTA must be present and labeled
        final appBarButton = find.byKey(const ValueKey('venue_directory_create_button'));
        expect(appBarButton, findsOneWidget);
        expect(find.text('SUBMIT VENUE'), findsOneWidget);

        // 2. Empty state onboarding CTA must also be present
        final emptyStateButton = find.text('Submit a Venue');
        expect(emptyStateButton, findsOneWidget);

        // 3. Tapping AppBar CTA triggers navigation to /venues/submit
        await tester.tap(appBarButton);
        await tester.pumpAndSettle();
        expect(find.text('TARGET: /venues/submit'), findsOneWidget);
      });

      testWidgets('Populated state retains persistent AppBar CTA in identical location and applies dock clearance', (tester) async {
        final sampleVenues = [
          {
            'id': 'v-101',
            'name': 'Iron Arm Armwrestling Club',
            'city': 'Lahore',
            'province': 'Punjab',
            'address': 'Gulberg III, Main Blvd',
            'verificationStatus': 'VERIFIED',
          },
        ];

        final router = GoRouter(
          initialLocation: '/venues',
          routes: [
            GoRoute(
              path: '/venues',
              builder: (context, state) => const MainShellScope(
                child: VenueDirectoryScreen(),
              ),
            ),
            GoRoute(
              path: '/venues/submit',
              builder: (context, state) => const Scaffold(body: Text('TARGET: /venues/submit')),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              venueListProvider.overrideWith(() => _FakeVenueListNotifier(sampleVenues)),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 1. Venue item is rendered
        expect(find.text('Iron Arm Armwrestling Club'), findsOneWidget);

        // 2. Empty state CTA is gone
        expect(find.text('Submit a Venue'), findsNothing);

        // 3. Persistent styled AppBar CTA remains visible and discoverable
        final appBarButton = find.byKey(const ValueKey('venue_directory_create_button'));
        expect(appBarButton, findsOneWidget);
        expect(find.text('SUBMIT VENUE'), findsOneWidget);

        // 4. ListView has bottom clearance that clears the floating dock
        final listViewFinder = find.byKey(const PageStorageKey<String>('venue_directory_list_view'));
        expect(listViewFinder, findsOneWidget);
        final listView = tester.widget<ListView>(listViewFinder);
        final padding = listView.padding as EdgeInsets;
        expect(padding.bottom, greaterThanOrEqualTo(kFloatingDockTotalHeight + 16.0));

        // 5. Tapping AppBar CTA triggers navigation to /venues/submit
        await tester.tap(appBarButton);
        await tester.pumpAndSettle();
        expect(find.text('TARGET: /venues/submit'), findsOneWidget);
      });
    });

    group('InformalEventDirectoryScreen (S-050)', () {
      testWidgets('Empty state renders persistent AppBar CTA and onboarding CTA, both routing to /informal-events/create', (tester) async {
        final router = GoRouter(
          initialLocation: '/informal-events',
          routes: [
            GoRoute(
              path: '/informal-events',
              builder: (context, state) => const InformalEventDirectoryScreen(),
            ),
            GoRoute(
              path: '/informal-events/create',
              builder: (context, state) => const Scaffold(body: Text('TARGET: /informal-events/create')),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              informalEventListProvider.overrideWith(() => _FakeInformalEventListNotifier([])),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 1. Persistent styled AppBar CTA must be present and labeled
        final appBarButton = find.byKey(const ValueKey('informal_event_directory_create_button'));
        expect(appBarButton, findsOneWidget);
        expect(find.text('HOST MEETUP'), findsOneWidget);

        // 2. Empty state onboarding CTA must also be present
        final emptyStateButton = find.text('Host a Meetup');
        expect(emptyStateButton, findsOneWidget);

        // 3. Tapping AppBar CTA triggers navigation to /informal-events/create
        await tester.tap(appBarButton);
        await tester.pumpAndSettle();
        expect(find.text('TARGET: /informal-events/create'), findsOneWidget);
      });

      testWidgets('Populated state retains persistent AppBar CTA and applies dock clearance', (tester) async {
        final sampleEvents = [
          {
            'id': 'ie-202',
            'title': 'Sunday Morning Heavyweight Sparring',
            'city': 'Karachi',
            'scheduledAt': '2026-10-18T10:00:00Z',
            'participantCount': 6,
            'maxParticipants': 12,
          },
        ];

        final router = GoRouter(
          initialLocation: '/informal-events',
          routes: [
            GoRoute(
              path: '/informal-events',
              builder: (context, state) => const MainShellScope(
                child: InformalEventDirectoryScreen(),
              ),
            ),
            GoRoute(
              path: '/informal-events/create',
              builder: (context, state) => const Scaffold(body: Text('TARGET: /informal-events/create')),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              informalEventListProvider.overrideWith(() => _FakeInformalEventListNotifier(sampleEvents)),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 1. Meetup item is rendered
        expect(find.text('Sunday Morning Heavyweight Sparring'), findsOneWidget);

        // 2. Empty state CTA is gone
        expect(find.text('Host a Meetup'), findsNothing);

        // 3. Persistent styled AppBar CTA remains visible and discoverable
        final appBarButton = find.byKey(const ValueKey('informal_event_directory_create_button'));
        expect(appBarButton, findsOneWidget);
        expect(find.text('HOST MEETUP'), findsOneWidget);

        // 4. ListView has bottom clearance that clears the floating dock
        final listViewFinder = find.byKey(const PageStorageKey<String>('informal_event_directory_list_view'));
        expect(listViewFinder, findsOneWidget);
        final listView = tester.widget<ListView>(listViewFinder);
        final padding = listView.padding as EdgeInsets;
        expect(padding.bottom, greaterThanOrEqualTo(kFloatingDockTotalHeight + 16.0));

        // 5. Tapping AppBar CTA triggers navigation to /informal-events/create
        await tester.tap(appBarButton);
        await tester.pumpAndSettle();
        expect(find.text('TARGET: /informal-events/create'), findsOneWidget);
      });
    });

    group('TeamsListScreen (S-054)', () {
      testWidgets('Empty state renders persistent AppBar CTA and onboarding CTA, both routing to /teams/create', (tester) async {
        final router = GoRouter(
          initialLocation: '/teams',
          routes: [
            GoRoute(
              path: '/teams',
              builder: (context, state) => const TeamsListScreen(),
            ),
            GoRoute(
              path: '/teams/create',
              builder: (context, state) => const Scaffold(body: Text('TARGET: /teams/create')),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              myTeamsProvider.overrideWith(() => _FakeMyTeamsNotifier([])),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 1. Persistent styled AppBar CTA must be present and labeled
        final appBarButton = find.byKey(const ValueKey('teams_list_create_button'));
        expect(appBarButton, findsOneWidget);
        expect(find.text('CREATE TEAM'), findsOneWidget);

        // 2. Empty state onboarding CTA must also be present
        final emptyStateButton = find.text('Create a team');
        expect(emptyStateButton, findsOneWidget);

        // 3. Tapping AppBar CTA triggers navigation to /teams/create
        await tester.tap(appBarButton);
        await tester.pumpAndSettle();
        expect(find.text('TARGET: /teams/create'), findsOneWidget);
      });

      testWidgets('Populated state retains persistent AppBar CTA and applies dock clearance', (tester) async {
        final sampleTeams = [
          {
            'id': 'team-303',
            'name': 'Titanium Pullers Club',
            'clubName': 'National League',
            'role': 'CAPTAIN',
          },
        ];

        final router = GoRouter(
          initialLocation: '/teams',
          routes: [
            GoRoute(
              path: '/teams',
              builder: (context, state) => const MainShellScope(
                child: TeamsListScreen(),
              ),
            ),
            GoRoute(
              path: '/teams/create',
              builder: (context, state) => const Scaffold(body: Text('TARGET: /teams/create')),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              myTeamsProvider.overrideWith(() => _FakeMyTeamsNotifier(sampleTeams)),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 1. Team item is rendered
        expect(find.text('Titanium Pullers Club'), findsOneWidget);

        // 2. Empty state CTA is gone
        expect(find.text('Create a team'), findsNothing);

        // 3. Persistent styled AppBar CTA remains visible and discoverable
        final appBarButton = find.byKey(const ValueKey('teams_list_create_button'));
        expect(appBarButton, findsOneWidget);
        expect(find.text('CREATE TEAM'), findsOneWidget);

        // 4. ListView has bottom clearance that clears the floating dock
        final listViewFinder = find.byKey(const PageStorageKey<String>('teams_list_view'));
        expect(listViewFinder, findsOneWidget);
        final listView = tester.widget<ListView>(listViewFinder);
        final padding = listView.padding as EdgeInsets;
        expect(padding.bottom, greaterThanOrEqualTo(kFloatingDockTotalHeight + 16.0));

        // 5. Tapping AppBar CTA triggers navigation to /teams/create
        await tester.tap(appBarButton);
        await tester.pumpAndSettle();
        expect(find.text('TARGET: /teams/create'), findsOneWidget);
      });
    });
  });
}
