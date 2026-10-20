import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/providers/athlete_provider.dart';
import 'package:mobile/core/providers/live_matches_provider.dart';
import 'package:mobile/core/providers/rankings_provider.dart';
import 'package:mobile/core/providers/tournament_provider.dart';
import 'package:mobile/core/widgets/elevated_action_card.dart';
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
  EdgeInsets mediaQueryPadding = EdgeInsets.zero,
  List<Map<String, dynamic>>? matches,
  List<Map<String, dynamic>>? trainingLogs,
  List<Map<String, dynamic>>? prs,
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
            .overrideWith((ref) async => prs ?? <Map<String, dynamic>>[]),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            padding: mediaQueryPadding,
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

  group('Truthful match outcomes and ELO calculation in Recent Bouts', () {
    testWidgets('unplayed fixture renders neutral symbol and omits ELO tag',
        (tester) async {
      final unplayedMatch = [
        {
          'id': 'match_unplayed_01',
          'opponentName': 'Denis Cyplenkov',
          'status': 'CONFIRMED',
          'arm': 'Right Arm',
        }
      ];

      await _pumpDashboard(tester, matches: unplayedMatch);

      final rowFinder = find.textContaining('Denis');
      await tester.ensureVisible(rowFinder);
      await tester.pump();

      // Renders neutral en-dash symbol
      expect(find.text('–'), findsOneWidget);
      // Never fabricates a win or loss
      expect(find.text('W'), findsNothing);
      expect(find.text('L'), findsNothing);
      // Omits fabricated ELO tag entirely within the bout row
      final boutRow =
          find.ancestor(of: rowFinder, matching: find.byType(Row)).first;
      expect(find.descendant(of: boutRow, matching: find.textContaining('ELO')),
          findsNothing);
      // Subtitle formats discipline cleanly without .Arm duplication
      expect(find.text('MATCH • Right Arm'), findsOneWidget);

      expect(tester.takeException(), isNull);
      await _disposeDashboard(tester);
    });

    testWidgets('decided win renders W and positive ELO delta', (tester) async {
      final winMatch = [
        {
          'id': 'match_win_01',
          'opponentName': 'Michael Todd',
          'winnerId': 'profile_1',
          'winMethod': 'TOPROLL',
          'arm': 'RIGHT',
          'eloDelta': 24,
        }
      ];

      await _pumpDashboard(tester, matches: winMatch);

      final eloTagFinder = find.text('+24 ELO');
      await tester.ensureVisible(eloTagFinder);
      await tester.pump();

      expect(find.text('W'), findsOneWidget);
      expect(eloTagFinder, findsOneWidget);
      expect(find.text('TOPROLL • Right Arm'), findsOneWidget);

      expect(tester.takeException(), isNull);
      await _disposeDashboard(tester);
    });

    testWidgets('decided loss renders L and negative ELO delta',
        (tester) async {
      final lossMatch = [
        {
          'id': 'match_loss_01',
          'opponentName': 'Devon Larratt',
          'winnerId': 'profile_other',
          'winMethod': 'HOOK',
          'arm': 'Left Arm',
          'eloDelta': -14,
        }
      ];

      await _pumpDashboard(tester, matches: lossMatch);

      final eloTagFinder = find.text('-14 ELO');
      await tester.ensureVisible(eloTagFinder);
      await tester.pump();

      expect(find.text('L'), findsOneWidget);
      expect(eloTagFinder, findsOneWidget);
      expect(find.text('HOOK • Left Arm'), findsOneWidget);

      expect(tester.takeException(), isNull);
      await _disposeDashboard(tester);
    });

    testWidgets(
        'upcoming match with status CONFIRMED and winnerId does not display win/loss chip',
        (tester) async {
      final match = [
        {
          'id': 'match_upcoming_with_winner_01',
          'opponentName': 'Devon Larratt',
          'status': 'CONFIRMED',
          'winnerId': 'profile_1',
          'arm': 'Right Arm',
        }
      ];
      await _pumpDashboard(tester, matches: match);
      // Renders neutral en-dash symbol
      expect(find.text('–'), findsOneWidget);
      expect(find.text('W'), findsNothing);
      expect(find.text('L'), findsNothing);
      await _disposeDashboard(tester);
    });

    testWidgets(
        'in-progress match with winnerId does not display win/loss chip',
        (tester) async {
      final match = [
        {
          'id': 'match_in_progress_01',
          'opponentName': 'Levan Saginashvili',
          'status': 'IN_PROGRESS',
          'winnerId': 'profile_1',
          'arm': 'RIGHT',
        }
      ];
      await _pumpDashboard(tester, matches: match);
      expect(find.text('–'), findsOneWidget);
      expect(find.text('W'), findsNothing);
      expect(find.text('L'), findsNothing);
      await _disposeDashboard(tester);
    });

    testWidgets('match without arm data does not display Right Arm in bout row',
        (tester) async {
      final match = [
        {
          'id': 'match_no_arm_01',
          'opponentName': 'John Brzenk',
          'winMethod': 'PIN',
          // 'arm' is omitted
        }
      ];
      await _pumpDashboard(tester, matches: match);
      final pinFinder = find.text('PIN');
      expect(pinFinder, findsOneWidget);
      // Verify the bout row subtitle displays only 'PIN' and does not invent 'Right Arm'
      final boutRow =
          find.ancestor(of: pinFinder, matching: find.byType(Row)).first;
      expect(
          find.descendant(
              of: boutRow, matching: find.textContaining('Right Arm')),
          findsNothing);
      expect(find.descendant(of: boutRow, matching: find.textContaining('Arm')),
          findsNothing);
      await _disposeDashboard(tester);
    });

    testWidgets('normalized arm disciplines render with clean Title Case',
        (tester) async {
      final matches = [
        {
          'id': 'match_arm_01',
          'opponentName': 'Athlete A',
          'arm': 'RIGHT',
          'winMethod': 'HOOK',
        },
        {
          'id': 'match_arm_02',
          'opponentName': 'Athlete B',
          'arm': 'left',
          'winMethod': 'TOPROLL',
        },
        {
          'id': 'match_arm_03',
          'opponentName': 'Athlete C',
          'arm': 'Right Arm',
          'winMethod': 'PRESS',
        },
      ];
      await _pumpDashboard(tester, matches: matches);
      expect(find.text('HOOK • Right Arm'), findsOneWidget);
      expect(find.text('TOPROLL • Left Arm'), findsOneWidget);
      expect(find.text('PRESS • Right Arm'), findsOneWidget);
      // No raw uppercase 'RIGHT' in any bout row subtitle
      final boutsSection = find
          .ancestor(
              of: find.text('HOOK • Right Arm'), matching: find.byType(Column))
          .first;
      expect(
          find.descendant(
              of: boutsSection, matching: find.textContaining('RIGHT')),
          findsNothing);
      await _disposeDashboard(tester);
    });
  });

  group('Full-width badge and ribbon space-between alignment', () {
    testWidgets(
        'PAFF badge right edge aligns with card wrap boundary and enforces inter-element gap',
        (tester) async {
      await _pumpDashboard(tester, width: 412);

      final verifiedFinder = find.text('VERIFIED');
      final paffFinder = find.text('PAFF COMPETITOR');

      final wrapFinder =
          find.ancestor(of: paffFinder, matching: find.byType(Wrap)).first;
      final wrapRect = tester.getRect(wrapFinder);
      final verifiedBadgeRect = tester.getRect(find
          .ancestor(of: verifiedFinder, matching: find.byType(Container))
          .first);
      final paffBadgeRect = tester.getRect(find
          .ancestor(of: paffFinder, matching: find.byType(Container))
          .first);

      // Verify intended ordering: left badge precedes right badge
      expect(verifiedBadgeRect.right, lessThan(paffBadgeRect.left));

      // Assert meaningful minimum gap between neighboring badges (Claude threshold > 8.5dp).
      // If the parent Wrap shrink-wrapped instead of double.infinity, the gap would only be spacing: 8.0dp.
      expect(paffBadgeRect.left - verifiedBadgeRect.right, greaterThan(8.5));

      // Verified is pinned to the left edge of the parent Wrap
      expect(verifiedBadgeRect.left - wrapRect.left, lessThan(5.0));
      // PAFF COMPETITOR is pinned to the right edge of the parent Wrap
      expect(wrapRect.right - paffBadgeRect.right, lessThan(5.0));

      expect(tester.takeException(), isNull);
      await _disposeDashboard(tester);
    });

    testWidgets(
        'Athlete banner bio ribbon spans full width with inter-stat spacing exceeding wrap spacing',
        (tester) async {
      await _pumpDashboard(tester, width: 600);

      final ribbonWrapFinder = find
          .ancestor(of: find.text('DISCIPLINE'), matching: find.byType(Wrap))
          .first;
      final ribbonRect = tester.getRect(ribbonWrapFinder);

      // Render boxes of each individual bio stat column
      final rankRect = tester.getRect(find
          .ancestor(of: find.text('WORLD RANK'), matching: find.byType(Column))
          .first);
      final weightRect = tester.getRect(find
          .ancestor(of: find.text('WEIGHT'), matching: find.byType(Column))
          .first);
      final winRateRect = tester.getRect(find
          .ancestor(of: find.text('WIN RATE'), matching: find.byType(Column))
          .first);
      final disciplineRect = tester.getRect(find
          .ancestor(of: find.text('DISCIPLINE'), matching: find.byType(Column))
          .first);

      // Verify intended horizontal ordering across all 4 stats
      expect(rankRect.right, lessThan(weightRect.left));
      expect(weightRect.right, lessThan(winRateRect.left));
      expect(winRateRect.right, lessThan(disciplineRect.left));

      // Assert meaningful minimum gaps between all neighboring stats (Claude threshold > 16.5dp).
      // If the ribbon Wrap shrink-wrapped, each gap would be exactly spacing: 16.0dp.
      expect(weightRect.left - rankRect.right, greaterThan(16.5));
      expect(winRateRect.left - weightRect.right, greaterThan(16.5));
      expect(disciplineRect.left - winRateRect.right, greaterThan(16.5));

      // Left-most stat aligns with ribbon left edge
      expect(rankRect.left - ribbonRect.left, lessThan(5.0));
      // Right-most stat is pushed to ribbon right boundary
      expect(ribbonRect.right - disciplineRect.right, lessThan(5.0));

      expect(tester.takeException(), isNull);
      await _disposeDashboard(tester);
    });

    testWidgets(
        'Dynamic ELO row aligns rating to left, badge to right, and enforces inter-element gap',
        (tester) async {
      await _pumpDashboard(tester, width: 600);

      final eloNumFinder = find.text('1500');
      final eloBadgeFinder = find.text('PROVISIONAL');

      final eloWrapFinder =
          find.ancestor(of: eloNumFinder, matching: find.byType(Wrap)).first;
      final eloWrapRect = tester.getRect(eloWrapFinder);
      final eloNumRect = tester.getRect(eloNumFinder);
      final eloBadgeRect = tester.getRect(find
          .ancestor(of: eloBadgeFinder, matching: find.byType(Container))
          .first);

      // Verify intended ordering: rating number precedes status badge
      expect(eloNumRect.right, lessThan(eloBadgeRect.left));

      // Assert meaningful minimum gap between rating and badge (Claude threshold > 8.5dp).
      // If the Wrap shrink-wrapped, the gap would only be spacing: 8.0dp.
      expect(eloBadgeRect.left - eloNumRect.right, greaterThan(8.5));

      // ELO number sits at the left boundary of the wrap
      expect(eloNumRect.left - eloWrapRect.left, lessThan(5.0));
      // Provisional badge aligns with the right boundary of the wrap
      expect(eloWrapRect.right - eloBadgeRect.right, lessThan(5.0));

      expect(tester.takeException(), isNull);
      await _disposeDashboard(tester);
    });

    testWidgets(
        'Arena Schedule STANDBY tag aligns with right boundary and enforces inter-element gap',
        (tester) async {
      await _pumpDashboard(tester, width: 360);

      final standbyFinder = find.text('STANDBY');
      await tester.ensureVisible(standbyFinder);
      await tester.pump();

      final standbyWrapFinder =
          find.ancestor(of: standbyFinder, matching: find.byType(Wrap)).first;
      final standbyWrapRect = tester.getRect(standbyWrapFinder);

      final scheduleHeaderFinder = find
          .ancestor(
            of: find.text('ARENA SCHEDULE'),
            matching: find.byType(FittedBox),
          )
          .first;
      final scheduleHeaderRect = tester.getRect(scheduleHeaderFinder);

      final standbyBadgeRect = tester.getRect(find
          .ancestor(of: standbyFinder, matching: find.byType(Container))
          .first);

      // Verify intended ordering: header precedes standby tag
      expect(scheduleHeaderRect.right, lessThan(standbyBadgeRect.left));

      // Assert meaningful minimum gap between header and badge (Claude threshold > 8.5dp).
      // If the Wrap shrink-wrapped, the gap would only be spacing: 8.0dp.
      expect(
          standbyBadgeRect.left - scheduleHeaderRect.right, greaterThan(8.5));

      // Header aligns with left edge of wrap
      expect(scheduleHeaderRect.left - standbyWrapRect.left, lessThan(5.0));
      // Standby badge aligns with right edge of wrap
      expect(standbyWrapRect.right - standbyBadgeRect.right, lessThan(5.0));

      expect(tester.takeException(), isNull);
      await _disposeDashboard(tester);
    });
  });

  group('Recovery card heading and accessibility', () {
    for (final scale in [1.0, 1.4, 2.0]) {
      testWidgets(
          'RECOVERY STATUS heading layout, text integrity, and clamped scaling at ${scale}x text',
          (tester) async {
        await _pumpDashboard(tester, textScale: scale);

        final headingFinder = find.text('RECOVERY STATUS');
        expect(headingFinder, findsOneWidget);

        // Asserts no FittedBox is used to artificially shrink the text
        expect(
          find.ancestor(of: headingFinder, matching: find.byType(FittedBox)),
          findsNothing,
        );

        // Inspect Text widget textScaler configuration directly
        final Text textWidget = tester.widget<Text>(headingFinder);
        expect(textWidget.textScaler, isNotNull);

        // Inspect RenderParagraph directly
        final RenderParagraph paragraph =
            tester.renderObject<RenderParagraph>(headingFinder);
        expect(paragraph.text.toPlainText(), 'RECOVERY STATUS');

        // Check height and width: heading renders cleanly without overflowing
        expect(paragraph.size.height, greaterThan(0.0));
        expect(paragraph.size.width, greaterThan(0.0));

        // Assert effective scaling applied to the heading respects the intended maximum of 1.4x
        final effectiveScaleFactor = paragraph.textScaler.scale(10.0) / 10.0;
        final expectedScaleFactor = scale > 1.4 ? 1.4 : scale;
        expect(effectiveScaleFactor, closeTo(expectedScaleFactor, 0.001));

        // When system text scaling is 2.0x, verify that effective font size is clamped to 1.4x (11.9sp)
        // and strictly does not scale to unclamped 2.0x (17.0sp)
        if (scale == 2.0) {
          expect(paragraph.textScaler.scale(8.5), closeTo(11.9, 0.01));
          expect(paragraph.textScaler.scale(8.5), lessThan(17.0));
        }

        // Verifies the widget renders cleanly without layout exceptions or RenderFlex overflows;
        // the textScaler clamp verified above prevents font overscaling that caused mid-word breaking.
        expect(tester.takeException(), isNull);
        await _disposeDashboard(tester);
      });
    }

    testWidgets(
        'recovery card exposes SemanticsAction.tap and button flag in populated state',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpDashboard(tester, trainingLogs: [
        {'id': '1', 'date': DateTime.now().toIso8601String()},
      ]);

      final cardFinder = find.bySemanticsLabel(
        'Recovery status: 1 Logged. Last activity: Today. Tap to view training log.',
      );
      expect(cardFinder, findsOneWidget);

      final semanticsData = tester.getSemantics(cardFinder).getSemanticsData();
      expect(semanticsData.hasAction(SemanticsAction.tap), isTrue);
      expect(semanticsData.flagsCollection.isButton, isTrue);

      expect(tester.takeException(), isNull);
      handle.dispose();
      await _disposeDashboard(tester);
    });

    testWidgets(
        'recovery card handles null/unparseable date without "nulld ago" in semantics',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpDashboard(tester, trainingLogs: [
        {'id': '1', 'date': null, 'createdAt': null},
      ]);

      final cardFinder = find.bySemanticsLabel(
        'Recovery status: 1 Logged. Last activity: Activity tracked. Tap to view training log.',
      );
      expect(cardFinder, findsOneWidget);

      // Verify no string interpolation of 'null' exists anywhere in semantics
      expect(find.bySemanticsLabel(RegExp(r'null')), findsNothing);

      final semanticsData = tester.getSemantics(cardFinder).getSemanticsData();
      expect(semanticsData.hasAction(SemanticsAction.tap), isTrue);
      expect(semanticsData.flagsCollection.isButton, isTrue);

      expect(tester.takeException(), isNull);
      handle.dispose();
      await _disposeDashboard(tester);
    });

    testWidgets(
        'recovery card exposes SemanticsAction.tap and button flag in empty state',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpDashboard(tester, trainingLogs: []);

      final cardFinder = find.bySemanticsLabel(
        'Recovery data unavailable. Tap to log training.',
      );
      expect(cardFinder, findsOneWidget);

      final semanticsData = tester.getSemantics(cardFinder).getSemanticsData();
      expect(semanticsData.hasAction(SemanticsAction.tap), isTrue);
      expect(semanticsData.flagsCollection.isButton, isTrue);

      expect(tester.takeException(), isNull);
      handle.dispose();
      await _disposeDashboard(tester);
    });
  });

  group('Quick commands vertical spacing to Personal Records', () {
    testWidgets(
        'GridView padding is zero and clearance from final grid tile to PRs header remains 24dp under ambient dock padding',
        (tester) async {
      final prsData = [
        {'exerciseType': 'BICEP_CURL', 'weightKg': 65},
      ];
      // Ambient bottom padding of 82.0dp simulates the shell navigation dock
      await _pumpDashboard(
        tester,
        prs: prsData,
        mediaQueryPadding: const EdgeInsets.only(bottom: 82.0),
      );

      final grid = tester.widget<GridView>(find.byType(GridView));
      expect(grid.padding, EdgeInsets.zero);

      final prsHeaderFinder = find.text('PERSONAL RECORDS & LIFTS');
      await tester.ensureVisible(prsHeaderFinder);
      await tester.pump();

      // Locate the final grid tile ('Messages' ElevatedActionCard)
      final lastTileFinder = find
          .ancestor(
            of: find.text('Messages'),
            matching: find.byType(ElevatedActionCard),
          )
          .first;
      expect(lastTileFinder, findsOneWidget);

      final lastTileRect = tester.getRect(lastTileFinder);
      final prsRect = tester.getRect(prsHeaderFinder);
      final gridRect = tester.getRect(find.byType(GridView));

      // Measure directly from the bottom edge of the final grid tile to the top edge of the PRs header.
      // Confirms the actual spacing remains exactly 24dp and does not expand to 24 + 82 = 106dp
      // which would occur if GridView inherited ambient bottom padding into its viewport.
      expect(prsRect.top - lastTileRect.bottom, closeTo(24.0, 1.0));

      // Also verify GridView boundary alignment
      expect(prsRect.top - gridRect.bottom, closeTo(24.0, 1.0));
      expect(gridRect.bottom - lastTileRect.bottom, closeTo(0.0, 1.0));

      expect(tester.takeException(), isNull);
      await _disposeDashboard(tester);
    });
  });
}
