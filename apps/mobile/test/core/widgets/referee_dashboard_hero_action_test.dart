import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/providers/referee_provider.dart';
import 'package:mobile/core/providers/tournament_provider.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'package:mobile/features/referee/screens/referee_screens.dart';

class _TestAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _TestAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTournamentNotifier extends TournamentNotifier {
  @override
  Future<List<Map<String, dynamic>>> build() async => [];
}

void main() {
  group('RefereeDashboardScreen Hero Action Layout Tests (ISSUE-P2-03 / BTN-022)', () {
    Widget buildRefereeDashboardApp({GoRouter? router}) {
      final defaultRouter = router ??
          GoRouter(
            initialLocation: '/referee/dashboard',
            routes: [
              GoRoute(
                path: '/referee/dashboard',
                builder: (context, state) => const RefereeDashboardScreen(),
              ),
              GoRoute(
                path: '/referee/submit-scorepad',
                builder: (context, state) => const Scaffold(body: Text('TARGET: /referee/submit-scorepad')),
              ),
              GoRoute(
                path: '/referee/certifications',
                builder: (context, state) => const Scaffold(body: Text('TARGET: /referee/certifications')),
              ),
              GoRoute(
                path: '/referee/search-athletes',
                builder: (context, state) => const Scaffold(body: Text('TARGET: /referee/search-athletes')),
              ),
              GoRoute(
                path: '/referee/upload-evidence',
                builder: (context, state) => const Scaffold(body: Text('TARGET: /referee/upload-evidence')),
              ),
            ],
          );

      return ProviderScope(
        overrides: [
          authProvider.overrideWith(
            (ref) => _TestAuthNotifier(
              AuthState(
                status: AuthStatus.authenticated,
                userProfile: {'id': 'ref_1', 'displayName': 'Head Ref Marcus', 'role': 'REFEREE'},
              ),
            ),
          ),
          tournamentProvider.overrideWith(() => _FakeTournamentNotifier()),
          refereeCertificationsProvider.overrideWith((ref) async => <Map<String, dynamic>>[]),
        ],
        child: MaterialApp.router(
          routerConfig: defaultRouter,
        ),
      );
    }

    testWidgets('Renders prominent Live Table Scorepad hero card with title, LIVE badge and subtitle', (tester) async {
      await tester.pumpWidget(buildRefereeDashboardApp());
      await tester.pumpAndSettle();

      expect(find.text('OFFICIAL ACTIONS'), findsOneWidget);
      expect(find.text('Live Table Scorepad'), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);
      expect(find.text('Launch table-side scoring & foul console'), findsOneWidget);
      expect(find.byIcon(Icons.sports_score_rounded), findsOneWidget);
    });

    testWidgets('Renders balanced secondary action cards row below hero card', (tester) async {
      await tester.pumpWidget(buildRefereeDashboardApp());
      await tester.pumpAndSettle();

      expect(find.text('Certifications'), findsOneWidget);
      expect(find.byIcon(Icons.verified_outlined), findsOneWidget);

      expect(find.text('Search Athletes'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);

      expect(find.text('Upload Evidence'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);

      // Verify old grid label 'Submit Scorepad' is no longer present as a tile
      expect(find.text('Submit Scorepad'), findsNothing);
    });

    testWidgets('Tapping Live Table Scorepad navigates to /referee/submit-scorepad', (tester) async {
      await tester.pumpWidget(buildRefereeDashboardApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Live Table Scorepad'));
      await tester.pumpAndSettle();

      expect(find.text('TARGET: /referee/submit-scorepad'), findsOneWidget);
    });

    testWidgets('Tapping secondary cards navigates to their respective routes', (tester) async {
      // Test Certifications
      await tester.pumpWidget(buildRefereeDashboardApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Certifications'));
      await tester.pumpAndSettle();
      expect(find.text('TARGET: /referee/certifications'), findsOneWidget);

      // Test Search Athletes
      await tester.pumpWidget(buildRefereeDashboardApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Search Athletes'));
      await tester.pumpAndSettle();
      expect(find.text('TARGET: /referee/search-athletes'), findsOneWidget);

      // Test Upload Evidence
      await tester.pumpWidget(buildRefereeDashboardApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Upload Evidence'));
      await tester.pumpAndSettle();
      expect(find.text('TARGET: /referee/upload-evidence'), findsOneWidget);
    });

    testWidgets('Adapts gracefully to narrow viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildRefereeDashboardApp());
      await tester.pumpAndSettle();

      expect(find.text('Live Table Scorepad'), findsOneWidget);
      expect(find.text('Certifications'), findsOneWidget);
      expect(find.text('Search Athletes'), findsOneWidget);
      expect(find.text('Upload Evidence'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
