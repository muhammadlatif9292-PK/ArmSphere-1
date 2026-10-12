import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/providers/announcement_provider.dart';
import 'package:mobile/core/providers/messaging_provider.dart';
import 'package:mobile/core/providers/nomination_provider.dart';
import 'package:mobile/core/providers/tournament_provider.dart';
import 'package:mobile/core/widgets/app_empty_state.dart';
import 'package:mobile/core/widgets/app_error_view.dart';
import 'package:mobile/features/championship/screens/tournament_awards_ceremony_screen.dart';
import 'package:mobile/features/messaging/screens/announcement_screens.dart';
import 'package:mobile/features/messaging/screens/messaging_screens.dart';
import 'package:mobile/features/nomination/screens/my_nominations_screen.dart';
import 'package:mobile/features/tournament/screens/tournament_screens.dart';

class _FakeConversationsNotifier extends ConversationsNotifier {
  final List<Map<String, dynamic>> _data;
  _FakeConversationsNotifier(this._data);

  @override
  Future<List<Map<String, dynamic>>> build() async => _data;
}

class _FakeAnnouncementsNotifier extends AnnouncementsNotifier {
  final List<Map<String, dynamic>> _data;
  final Object? _error;
  _FakeAnnouncementsNotifier({List<Map<String, dynamic>>? data, Object? error})
      : _data = data ?? [],
        _error = error;

  @override
  Future<List<Map<String, dynamic>>> build() async {
    final err = _error;
    if (err != null) throw err;
    return _data;
  }
}

class _FakeNominationsNotifier extends NominationListNotifier {
  final List<Map<String, dynamic>> _data;
  final Object? _error;
  _FakeNominationsNotifier({List<Map<String, dynamic>>? data, Object? error})
      : _data = data ?? [],
        _error = error;

  @override
  Future<List<Map<String, dynamic>>> build() async {
    final err = _error;
    if (err != null) throw err;
    return _data;
  }
}

void main() {
  group('Dead-End Fallbacks & Recovery UX Tests (ISSUE-P2-02)', () {
    testWidgets('AppEmptyState renders both primary and secondary actions when supplied', (tester) async {
      bool primaryTapped = false;
      bool secondaryTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppEmptyState(
              icon: Icons.search,
              title: 'Empty Search',
              subtitle: 'No items matching criteria.',
              ctaLabel: 'Refresh Items',
              onCtaTap: () => primaryTapped = true,
              secondaryCtaLabel: 'Return to Hub',
              onSecondaryCtaTap: () => secondaryTapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Empty Search'), findsOneWidget);
      expect(find.text('Refresh Items'), findsOneWidget);
      expect(find.text('Return to Hub'), findsOneWidget);

      await tester.tap(find.text('Refresh Items'));
      await tester.pumpAndSettle();
      expect(primaryTapped, isTrue);

      await tester.tap(find.text('Return to Hub'));
      await tester.pumpAndSettle();
      expect(secondaryTapped, isTrue);
    });

    testWidgets('TournamentDetailScreen (S-038) renders AppErrorView with secondary escape action', (tester) async {
      final router = GoRouter(
        initialLocation: '/tournaments/t_error',
        routes: [
          GoRoute(
            path: '/tournaments/t_error',
            builder: (context, state) => const TournamentDetailScreen(tournamentId: 't_error'),
          ),
          GoRoute(
            path: '/tournaments',
            builder: (context, state) => const Scaffold(body: Text('TARGET: /tournaments')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventDetailProvider('t_error').overrideWith((ref) => Future.error('Event not found on server')),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorView), findsOneWidget);
      expect(find.text('Tournament Unavailable'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Return to Tournaments'), findsOneWidget);

      await tester.tap(find.text('Return to Tournaments'));
      await tester.pumpAndSettle();
      expect(find.text('TARGET: /tournaments'), findsOneWidget);
    });

    testWidgets('TournamentAwardsCeremonyScreen (S-041) empty state provides brackets and directory navigation', (tester) async {
      final router = GoRouter(
        initialLocation: '/tournaments/t_1/awards',
        routes: [
          GoRoute(
            path: '/tournaments/t_1/awards',
            builder: (context, state) => const TournamentAwardsCeremonyScreen(tournamentId: 't_1'),
          ),
          GoRoute(
            path: '/tournaments/t_1/brackets',
            builder: (context, state) => const Scaffold(body: Text('TARGET: /tournaments/t_1/brackets')),
          ),
          GoRoute(
            path: '/tournaments',
            builder: (context, state) => const Scaffold(body: Text('TARGET: /tournaments')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventDetailProvider('t_1').overrideWith((ref) async => {'id': 't_1', 'name': 'National Arm Wars'}),
            eventAwardsProvider('t_1').overrideWith((ref) async => {'awards': []}),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('OFFICIAL PODIUM PENDING'), findsOneWidget);
      expect(find.text('REFRESH RESULTS'), findsOneWidget);
      expect(find.text('VIEW BRACKETS'), findsOneWidget);
      expect(find.text('RETURN TO TOURNAMENTS'), findsOneWidget);

      await tester.tap(find.text('VIEW BRACKETS'));
      await tester.pumpAndSettle();
      expect(find.text('TARGET: /tournaments/t_1/brackets'), findsOneWidget);
    });

    testWidgets('ConversationsListScreen (S-042) empty state renders sparring and home escape CTAs', (tester) async {
      final router = GoRouter(
        initialLocation: '/messages',
        routes: [
          GoRoute(
            path: '/messages',
            builder: (context, state) => const ConversationsListScreen(),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) => const Scaffold(body: Text('TARGET: /search')),
          ),
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(body: Text('TARGET: /home')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            conversationsProvider.overrideWith(() => _FakeConversationsNotifier([])),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No conversations yet'), findsOneWidget);
      expect(find.text('Find Sparring Partners'), findsOneWidget);
      expect(find.text('Return to Home'), findsOneWidget);

      await tester.tap(find.text('Find Sparring Partners'));
      await tester.pumpAndSettle();
      expect(find.text('TARGET: /search'), findsOneWidget);
    });

    testWidgets('AnnouncementsListScreen (S-047) provides two-way recovery on both error and empty states', (tester) async {
      // 1. Error state
      final errorRouter = GoRouter(
        initialLocation: '/bulletins',
        routes: [
          GoRoute(
            path: '/bulletins',
            builder: (context, state) => const AnnouncementsListScreen(),
          ),
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(body: Text('TARGET: /home')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            announcementsProvider.overrideWith(() => _FakeAnnouncementsNotifier(error: 'Network exception')),
          ],
          child: MaterialApp.router(routerConfig: errorRouter),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorView), findsOneWidget);
      expect(find.text('Could not load bulletins'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Return to Home'), findsOneWidget);

      await tester.tap(find.text('Return to Home'));
      await tester.pumpAndSettle();
      expect(find.text('TARGET: /home'), findsOneWidget);

      // 2. Empty state
      final emptyRouter = GoRouter(
        initialLocation: '/bulletins',
        routes: [
          GoRoute(
            path: '/bulletins',
            builder: (context, state) => const AnnouncementsListScreen(),
          ),
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(body: Text('TARGET: /home')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            announcementsProvider.overrideWith(() => _FakeAnnouncementsNotifier(data: [])),
          ],
          child: MaterialApp.router(routerConfig: emptyRouter),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No active bulletins'), findsOneWidget);
      expect(find.text('Refresh Bulletins'), findsOneWidget);
      expect(find.text('Return to Home'), findsOneWidget);

      await tester.tap(find.text('Return to Home'));
      await tester.pumpAndSettle();
      expect(find.text('TARGET: /home'), findsOneWidget);
    });

    testWidgets('MyNominationsScreen (S-052) provides two-way recovery on both error and empty states', (tester) async {
      // 1. Error state
      final errorRouter = GoRouter(
        initialLocation: '/nominations',
        routes: [
          GoRoute(
            path: '/nominations',
            builder: (context, state) => const MyNominationsScreen(),
          ),
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(body: Text('TARGET: /home')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            nominationListProvider.overrideWith(() => _FakeNominationsNotifier(error: 'Server timeout')),
          ],
          child: MaterialApp.router(routerConfig: errorRouter),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorView), findsOneWidget);
      expect(find.text('Could not load nominations'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Return to Home'), findsOneWidget);

      // 2. Empty state
      final emptyRouter = GoRouter(
        initialLocation: '/nominations',
        routes: [
          GoRoute(
            path: '/nominations',
            builder: (context, state) => const MyNominationsScreen(),
          ),
          GoRoute(
            path: '/nominate',
            builder: (context, state) => const Scaffold(body: Text('TARGET: /nominate')),
          ),
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(body: Text('TARGET: /home')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            nominationListProvider.overrideWith(() => _FakeNominationsNotifier(data: [])),
          ],
          child: MaterialApp.router(routerConfig: emptyRouter),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No active nominations'), findsOneWidget);
      expect(find.text('Submit a Nomination'), findsOneWidget);
      expect(find.text('Return to Home'), findsOneWidget);

      await tester.tap(find.text('Submit a Nomination'));
      await tester.pumpAndSettle();
      expect(find.text('TARGET: /nominate'), findsOneWidget);
    });
  });
}
