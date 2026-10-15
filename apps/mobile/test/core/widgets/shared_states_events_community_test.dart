import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/api/dio_client.dart';
import 'package:mobile/core/providers/community_provider.dart';
import 'package:mobile/core/providers/tournament_provider.dart';
import 'package:mobile/core/widgets/app_empty_state.dart';
import 'package:mobile/core/widgets/app_error_view.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'package:mobile/features/community/screens/community_feed_screen.dart';
import 'package:mobile/features/tournament/screens/tournament_screens.dart';

int _builds = 0;
Object? _failWith;

class _EventsNotifier extends TournamentNotifier {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    _builds++;
    final err = _failWith;
    if (err != null) throw err;
    return <Map<String, dynamic>>[];
  }
}

class _FeedNotifier extends CommunityFeedNotifier {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    _builds++;
    final err = _failWith;
    if (err != null) throw err;
    return <Map<String, dynamic>>[];
  }
}

class _FakeAuth extends StateNotifier<AuthState> implements AuthNotifier {
  bool logoutCalled = false;
  _FakeAuth()
      : super(AuthState(
          status: AuthStatus.authenticated,
          userProfile: {'id': 'u1', 'role': 'ATHLETE'},
        ));

  @override
  Future<void> logout() async {
    logoutCalled = true;
    state = AuthState(status: AuthStatus.unauthenticated);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ApiException _expired() => ApiException(
      type: 'auth:session-expired',
      title: 'Session Expired',
      status: 401,
      detail: 'Please log in again.',
    );

Future<void> _pump(WidgetTester t, Widget home, List<Override> overrides) async {
  await t.pumpWidget(ProviderScope(overrides: overrides, child: MaterialApp(home: home)));
  await t.pump();
  await t.pump(const Duration(milliseconds: 600));
}

Future<void> _settle(WidgetTester t) async {
  await t.pump();
  await t.pump(const Duration(milliseconds: 600));
}

Future<void> _teardown(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await t.pump();
}

void main() {
  setUp(() {
    _builds = 0;
    _failWith = null;
  });

  group('Events list', () {
    testWidgets('error hides raw text, retries the events provider, no redundant escape', (t) async {
      _failWith = Exception('SocketException: Failed host lookup api.internal');
      await _pump(t, const TournamentsListScreen(), [
        tournamentProvider.overrideWith(() => _EventsNotifier()),
      ]);
      expect(find.byType(AppErrorView), findsOneWidget);
      expect(find.text('Could not load competitions'), findsOneWidget);
      expect(find.textContaining('Failed host lookup'), findsNothing);
      expect(find.textContaining('Exception'), findsNothing);
      expect(find.text('Return to Home'), findsNothing);
      expect(find.text('Go Back'), findsNothing);
      expect(_builds, 1);
      await t.tap(find.text('Retry'));
      await _settle(t);
      expect(_builds, 2);
      await _teardown(t);
    });

    testWidgets('401 shows Sign In Again, which calls the existing auth logout', (t) async {
      _failWith = _expired();
      final auth = _FakeAuth();
      await _pump(t, const TournamentsListScreen(), [
        tournamentProvider.overrideWith(() => _EventsNotifier()),
        authProvider.overrideWith((ref) => auth),
      ]);
      expect(find.text('Sign In Again'), findsOneWidget);
      expect(find.textContaining('[401]'), findsNothing);
      expect(auth.logoutCalled, isFalse);
      await t.tap(find.text('Sign In Again'));
      await _settle(t);
      expect(auth.logoutCalled, isTrue);
      await _teardown(t);
    });

    testWidgets('empty state is inside the pull-to-refresh list and Refresh Events reloads', (t) async {
      await _pump(t, const TournamentsListScreen(), [
        tournamentProvider.overrideWith(() => _EventsNotifier()),
      ]);
      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.descendant(of: find.byType(RefreshIndicator), matching: find.byType(AppEmptyState)), findsOneWidget);
      expect(find.text('No competitions published yet'), findsOneWidget);
      expect(find.text('Check back soon for upcoming sanctioned events'), findsOneWidget);
      expect(_builds, 1);
      await t.tap(find.text('Refresh Events'));
      await _settle(t);
      expect(_builds, 2);
      await _teardown(t);
    });
  });

  group('Community feed', () {
    testWidgets('error hides raw text, retries the feed provider, no redundant escape', (t) async {
      _failWith = Exception('SocketException: Failed host lookup api.internal');
      await _pump(t, const CommunityFeedScreen(), [
        communityFeedProvider.overrideWith(() => _FeedNotifier()),
      ]);
      expect(find.byType(AppErrorView), findsOneWidget);
      expect(find.text('Could not load feed'), findsOneWidget);
      expect(find.textContaining('Failed host lookup'), findsNothing);
      expect(find.textContaining('Exception'), findsNothing);
      expect(find.text('Return to Home'), findsNothing);
      expect(_builds, 1);
      await t.tap(find.text('Retry'));
      await _settle(t);
      expect(_builds, 2);
      await _teardown(t);
    });

    testWidgets('401 shows Sign In Again, which calls the existing auth logout', (t) async {
      _failWith = _expired();
      final auth = _FakeAuth();
      await _pump(t, const CommunityFeedScreen(), [
        communityFeedProvider.overrideWith(() => _FeedNotifier()),
        authProvider.overrideWith((ref) => auth),
      ]);
      expect(find.text('Sign In Again'), findsOneWidget);
      await t.tap(find.text('Sign In Again'));
      await _settle(t);
      expect(auth.logoutCalled, isTrue);
      await _teardown(t);
    });
  });

  group('AppErrorView defaults are preserved', () {
    testWidgets('default 401 action still navigates to /login and escape action is still added', (t) async {
      final router = GoRouter(routes: [
        GoRoute(
          path: '/',
          builder: (c, s) => Scaffold(body: AppErrorView(error: _expired())),
        ),
        GoRoute(path: '/login', builder: (c, s) => const Scaffold(body: Text('TARGET: /login'))),
      ]);
      await t.pumpWidget(MaterialApp.router(routerConfig: router));
      await t.pump(const Duration(milliseconds: 600));
      expect(find.text('Return to Home'), findsOneWidget);
      await t.tap(find.text('Sign In Again'));
      await t.pump(const Duration(milliseconds: 600));
      expect(find.text('TARGET: /login'), findsOneWidget);
    });

    testWidgets('showSecondaryAction false hides the auto escape but keeps an explicit one', (t) async {
      await t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppErrorView(
            title: 'T',
            message: 'M',
            showSecondaryAction: false,
            secondaryActionLabel: 'Explicit',
            onSecondaryAction: () {},
          ),
        ),
      ));
      await t.pump(const Duration(milliseconds: 600));
      expect(find.text('Return to Home'), findsNothing);
      expect(find.text('Explicit'), findsOneWidget);
    });
  });
}
