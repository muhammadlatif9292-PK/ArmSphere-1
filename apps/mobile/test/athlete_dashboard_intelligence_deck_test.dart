import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/providers/athlete_provider.dart';
import 'package:mobile/core/providers/live_matches_provider.dart';
import 'package:mobile/core/providers/rankings_provider.dart';
import 'package:mobile/core/providers/tournament_provider.dart';
import 'package:mobile/features/athlete/screens/athlete_screens.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// Fakes (same shape as discovery_and_home_routing_test.dart)
// ---------------------------------------------------------------------------
class _TestAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  _TestAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAthleteProfileNotifier extends AthleteProfileNotifier {
  final Map<String, dynamic> _profile;
  _FakeAthleteProfileNotifier(this._profile);

  @override
  Future<Map<String, dynamic>> build() async => _profile;
}

class _FakeLiveMatchesNotifier extends LiveMatchesNotifier {
  final List<Map<String, dynamic>> _matches;
  _FakeLiveMatchesNotifier([this._matches = const []]);

  @override
  Future<List<Map<String, dynamic>>> build() async => _matches;
}

class _FakeTournamentNotifier extends TournamentNotifier {
  @override
  Future<List<Map<String, dynamic>>> build() async => [];
}

class _FakeRankingsNotifier extends RankingsNotifier {
  @override
  Future<List<Map<String, dynamic>>> build() async => [];
}

const _labels = ['Recent Bouts', 'Tournaments', 'Global Top 3'];

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
Future<void> _pumpTabBar(
  WidgetTester tester, {
  required double width,
  double textScale = 1.0,
  int selected = 0,
  ValueChanged<int>? onSelected,
}) {
  return tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: IntelligenceDeckTabBar(
              labels: _labels,
              selectedIndex: selected,
              onSelected: onSelected ?? (_) {},
            ),
          ),
        ),
      ),
    ),
  );
}

List<Rect> _tabRects(WidgetTester tester) {
  final tabs = find.descendant(
    of: find.byType(IntelligenceDeckTabBar),
    matching: find.byType(AnimatedContainer),
  );
  expect(tabs, findsNWidgets(3));
  return [for (var i = 0; i < 3; i++) tester.getRect(tabs.at(i))];
}

Semantics _semanticsFor(WidgetTester tester, String label) =>
    tester.widget<Semantics>(
      find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == label),
    );

Future<void> _pumpDashboard(
  WidgetTester tester, {
  double textScale = 1.0,
  double width = 360,
  double height = 740,
  List<Map<String, dynamic>>? matches,
  List<Map<String, dynamic>>? trainingLogs,
}) async {
  tester.view.physicalSize = Size(width * 2.0, height * 2.0);
  tester.view.devicePixelRatio = 2.0;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => _TestAuthNotifier(
              AuthState(
                status: AuthStatus.authenticated,
                userProfile: {
                  'id': 'profile_1',
                  'displayName': 'Ali Khan',
                  'role': 'ATHLETE'
                },
              ),
            )),
        athleteProfileProvider.overrideWith(() => _FakeAthleteProfileNotifier({
              'id': 'profile_1',
              'rightArmElo': 1500,
              'leftArmElo': 1480,
              'armDominance': 'Right Arm',
            })),
        liveMatchesProvider
            .overrideWith(() => _FakeLiveMatchesNotifier(matches ?? [])),
        tournamentProvider.overrideWith(() => _FakeTournamentNotifier()),
        rankingsProvider.overrideWith(() => _FakeRankingsNotifier()),
        trainingLogProvider('profile_1').overrideWith(
            (ref) async => trainingLogs ?? <Map<String, dynamic>>[]),
        trainingLogPRsProvider('profile_1')
            .overrideWith((ref) async => <Map<String, dynamic>>[]),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: const AthleteDashboardScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _disposeDashboard(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

Finder _deckTab(String label) => find.descendant(
      of: find.byType(IntelligenceDeckTabBar),
      matching: find.text(label),
    );

void main() {
  group('IntelligenceDeckTabBar layout', () {
    // (available width, text scale). 296 is the real deck inner width on a
    // 360dp phone (360 - 2*16 screen padding - 2*16 card padding).
    const cases = <(double, double)>[
      (296, 1.0),
      (296, 1.4),
      (296, 2.0),
      (240, 1.0),
      (240, 1.4),
    ];

    for (final (width, scale) in cases) {
      testWidgets(
          'never overflows at ${width}dp, ${scale}x text; all tabs stay visible',
          (tester) async {
        await _pumpTabBar(tester, width: width, textScale: scale);

        expect(tester.takeException(), isNull);
        for (final label in _labels) {
          expect(find.text(label), findsOneWidget);
        }
        for (final rect in _tabRects(tester)) {
          expect(rect.left, greaterThanOrEqualTo(-0.01));
          expect(rect.right, lessThanOrEqualTo(width + 0.01));
        }
      });
    }

    testWidgets('uses one equal-width row when the labels fit', (tester) async {
      await _pumpTabBar(tester, width: 600);

      final rects = _tabRects(tester);
      expect(rects.map((r) => r.top.round()).toSet().length, 1,
          reason: 'single row');
      expect(rects[0].width, closeTo(rects[1].width, 0.5));
      expect(rects[1].width, closeTo(rects[2].width, 0.5));
    });

    testWidgets(
        'wraps onto further rows instead of overflowing when they do not fit',
        (tester) async {
      await _pumpTabBar(tester, width: 296);

      final rects = _tabRects(tester);
      expect(rects.map((r) => r.top.round()).toSet().length, greaterThan(1),
          reason: 'wrapped to a second row');
      expect(tester.takeException(), isNull);
    });

    testWidgets('every tab keeps a >=40dp touch target in both layouts',
        (tester) async {
      for (final width in [600.0, 296.0]) {
        await _pumpTabBar(tester, width: width);
        for (final rect in _tabRects(tester)) {
          expect(rect.height, greaterThanOrEqualTo(40.0),
              reason: 'width $width');
        }
      }
    });

    testWidgets('selecting a tab does not change any tab size or position',
        (tester) async {
      await _pumpTabBar(tester, width: 296, selected: 0);
      final before = _tabRects(tester);
      await _pumpTabBar(tester, width: 296, selected: 2);
      await tester.pumpAndSettle();
      final after = _tabRects(tester);
      expect(after, before);
    });
  });

  group('IntelligenceDeckTabBar behaviour', () {
    testWidgets('tapping a tab reports its index', (tester) async {
      final taps = <int>[];
      await _pumpTabBar(tester, width: 296, onSelected: taps.add);

      await tester.tap(find.text('Tournaments'));
      await tester.tap(find.text('Global Top 3'));
      await tester.tap(find.text('Recent Bouts'));

      expect(taps, [1, 2, 0]);
    });

    testWidgets('exposes button + selected semantics for every tab',
        (tester) async {
      final handle = tester.ensureSemantics();
      for (var selected = 0; selected < _labels.length; selected++) {
        await _pumpTabBar(tester, width: 296, selected: selected);
        for (var i = 0; i < _labels.length; i++) {
          final p = _semanticsFor(tester, _labels[i]).properties;
          expect(p.button, isTrue);
          expect(p.selected, i == selected,
              reason: '${_labels[i]} while tab $selected is active');
          expect(find.bySemanticsLabel(_labels[i]), findsOneWidget);
        }
      }
      handle.dispose();
    });
  });

  group('AthleteDashboardScreen intelligence deck + arm selector', () {
    testWidgets('deck tabs switch content and keep their labels',
        (tester) async {
      await _pumpDashboard(tester);

      expect(find.byType(IntelligenceDeckTabBar), findsOneWidget);
      for (final label in _labels) {
        expect(_deckTab(label), findsOneWidget);
      }
      expect(find.text('No verified bouts yet'), findsOneWidget);

      await tester.ensureVisible(_deckTab('Tournaments'));
      await tester.pump();
      await tester.tap(_deckTab('Tournaments'));
      await tester.pump();
      expect(find.text('No tournaments scheduled'), findsOneWidget);
      expect(find.text('No verified bouts yet'), findsNothing);

      await tester.tap(_deckTab('Global Top 3'));
      await tester.pump();
      expect(find.text('Rankings data unavailable'), findsOneWidget);

      await tester.tap(_deckTab('Recent Bouts'));
      await tester.pump();
      expect(find.text('No verified bouts yet'), findsOneWidget);

      expect(tester.takeException(), isNull);
      await _disposeDashboard(tester);
    });

    testWidgets(
        'arm selector switches ELO, exposes semantics and has >=34dp targets',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpDashboard(tester);

      expect(find.text('1500'), findsOneWidget);
      expect(_semanticsFor(tester, 'Right arm').properties.selected, isTrue);
      expect(_semanticsFor(tester, 'Left arm').properties.selected, isFalse);

      final target = find
          .ancestor(
              of: find.text('LEFT'), matching: find.byType(GestureDetector))
          .first;
      expect(tester.getSize(target).height, greaterThanOrEqualTo(34.0));

      await tester.ensureVisible(find.text('LEFT'));
      await tester.pump();
      await tester.tap(find.text('LEFT'));
      await tester.pump();

      expect(find.text('1480'), findsOneWidget);
      expect(find.text('1500'), findsNothing);
      expect(_semanticsFor(tester, 'Left arm').properties.selected, isTrue);
      expect(_semanticsFor(tester, 'Right arm').properties.selected, isFalse);

      expect(tester.takeException(), isNull);
      handle.dispose();
      await _disposeDashboard(tester);
    });

    testWidgets('discipline does not duplicate the word "Arm"', (tester) async {
      await _pumpDashboard(tester);

      expect(find.text('Right Arm'), findsOneWidget);
      expect(find.text('Right Arm Arm'), findsNothing);
      await _disposeDashboard(tester);
    });
  });

  group('Sanctioned Arena Radar header and background scaling', () {
    for (final scale in [1.0, 1.4, 2.0]) {
      testWidgets('radar renders cleanly without overflow at ${scale}x text',
          (tester) async {
        await _pumpDashboard(tester, textScale: scale);
        expect(tester.takeException(), isNull);

        expect(find.text('SANCTIONED ARENA RADAR'), findsOneWidget);
        expect(find.text('Championship Arena Active'), findsOneWidget);
        expect(find.text('Explore'), findsOneWidget);

        await _disposeDashboard(tester);
      });
    }
  });

  group('Recovery status empty state and accessibility semantics', () {
    testWidgets(
        'shows compact No Data and Tap to log with semantics when empty',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpDashboard(tester, trainingLogs: []);

      expect(find.text('No Data'), findsOneWidget);
      expect(find.text('Tap to log'), findsOneWidget);
      expect(find.text('Data Unavailable'), findsNothing);

      expect(
        find.bySemanticsLabel(
            'Recovery data unavailable. Tap to log training.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      handle.dispose();
      await _disposeDashboard(tester);
    });

    testWidgets('shows logged count when training logs populated',
        (tester) async {
      await _pumpDashboard(tester, trainingLogs: [
        {'id': '1', 'date': DateTime.now().toIso8601String()},
        {'id': '2', 'date': DateTime.now().toIso8601String()},
      ]);

      expect(find.text('2 Logged'), findsOneWidget);
      expect(find.text('Last: Today'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _disposeDashboard(tester);
    });

    for (final scale in [1.0, 1.4, 2.0]) {
      testWidgets('recovery card renders without overflow at ${scale}x text',
          (tester) async {
        await _pumpDashboard(tester, textScale: scale, trainingLogs: []);
        expect(tester.takeException(), isNull);
        expect(find.text('No Data'), findsOneWidget);
        await _disposeDashboard(tester);
      });
    }
  });

  group('Quick commands grid responsiveness', () {
    for (final scale in [1.0, 1.4, 2.0, 2.5]) {
      testWidgets('renders all commands without overflow at ${scale}x text',
          (tester) async {
        await _pumpDashboard(tester, textScale: scale);

        final labels = [
          'Scorepad Entry',
          'Tournaments',
          'Training Log',
          'Clubs & Teams',
          'Messages',
        ];

        for (final label in labels) {
          final finder = find.descendant(
            of: find.byType(GridView),
            matching: find.text(label),
          );
          await tester.ensureVisible(finder);
          await tester.pump();
          expect(finder, findsOneWidget);
        }

        expect(tester.takeException(), isNull);
        await _disposeDashboard(tester);
      });
    }
  });

  group('Recent bouts row with long opponent names', () {
    final longMatch = [
      {
        'id': 'match_long_01',
        'opponentName': 'Grandmaster Denis "The Beast" Cyplenkov-Rustamov',
        'winnerId': 'profile_1',
        'winMethod': 'PIN',
        'arm': 'RIGHT',
        'eloDelta': 120,
      }
    ];

    for (final scale in [1.0, 1.4, 2.0]) {
      testWidgets(
          'never overflows horizontally with long names at ${scale}x text',
          (tester) async {
        await _pumpDashboard(tester, textScale: scale, matches: longMatch);

        final eloTagFinder = find.text('+120 ELO');
        await tester.ensureVisible(eloTagFinder);
        await tester.pump();

        expect(eloTagFinder, findsOneWidget);
        expect(find.textContaining('Denis'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await _disposeDashboard(tester);
      });
    }
  });
}
