import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/main_shell_screen.dart';

const _tabs = <({String label, IconData icon, IconData activeIcon})>[
  (label: 'Arena', icon: Icons.home_outlined, activeIcon: Icons.home_rounded),
  (
    label: 'Discover',
    icon: Icons.travel_explore_outlined,
    activeIcon: Icons.travel_explore_rounded
  ),
  (
    label: 'Events',
    icon: Icons.emoji_events_outlined,
    activeIcon: Icons.emoji_events_rounded
  ),
  (
    label: 'Community',
    icon: Icons.forum_outlined,
    activeIcon: Icons.forum_rounded
  ),
  (
    label: 'Passport',
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded
  ),
];

Future<GoRouter> _pumpShell(
  WidgetTester tester, {
  double textScale = 1.0,
}) async {
  final router = GoRouter(
    initialLocation: '/arena',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShellScreen(navigationShell: navigationShell),
        branches: [
          for (final tab in _tabs)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/${tab.label.toLowerCase()}',
                  builder: (context, state) =>
                      Center(child: Text('${tab.label} page')),
                ),
              ],
            ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

Icon _iconFor(WidgetTester tester, IconData data) =>
    tester.widget<Icon>(find.byIcon(data));

Text _labelFor(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label));

Semantics _navSemantics(WidgetTester tester, String label) =>
    tester.widget<Semantics>(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == '$label tab',
      ),
    );

void main() {
  group('MainShellScreen floating dock', () {
    testWidgets('renders the five tabs in order', (tester) async {
      await _pumpShell(tester);

      for (final tab in _tabs) {
        expect(find.text(tab.label), findsOneWidget);
      }
      final xs = [
        for (final tab in _tabs) tester.getCenter(find.text(tab.label)).dx,
      ];
      expect(xs, orderedEquals([...xs]..sort()));
    });

    testWidgets('every tab uses the crimson accent when active, never gold',
        (tester) async {
      await _pumpShell(tester);

      for (var i = 0; i < _tabs.length; i++) {
        final tab = _tabs[i];
        await tester.tap(find.text(tab.label));
        await tester.pumpAndSettle();

        final icon = _iconFor(tester, tab.activeIcon);
        expect(icon.color, AppTheme.crimson, reason: '${tab.label} icon');
        expect(icon.color, isNot(AppTheme.goldPrimary));

        final pill = tester.widget<AnimatedContainer>(
          find.ancestor(
            of: find.byIcon(tab.activeIcon),
            matching: find.byType(AnimatedContainer),
          ),
        );
        final deco = pill.decoration! as BoxDecoration;
        expect(deco.color, AppTheme.crimson.withValues(alpha: 0.12),
            reason: '${tab.label} pill fill');
        expect((deco.border! as Border).top.color,
            AppTheme.crimson.withValues(alpha: 0.35),
            reason: '${tab.label} pill border');
      }
    });

    testWidgets('active label is titanium white, inactive labels are muted',
        (tester) async {
      await _pumpShell(tester);
      await tester.tap(find.text('Events'));
      await tester.pumpAndSettle();

      for (final tab in _tabs) {
        final style = _labelFor(tester, tab.label).style!;
        if (tab.label == 'Events') {
          expect(style.color, AppTheme.textPrimary);
          expect(style.fontWeight, FontWeight.w700);
        } else {
          expect(style.color, AppTheme.textMuted);
          expect(style.fontWeight, FontWeight.w600);
          expect(_iconFor(tester, tab.icon).color, AppTheme.textMuted);
        }
        expect(style.fontFamily, AppTheme.fontDisplay);
      }
    });

    testWidgets('inactive pill keeps the same footprint as the active pill',
        (tester) async {
      await _pumpShell(tester);
      final before = tester.getTopLeft(find.text('Discover'));
      await tester.tap(find.text('Discover'));
      await tester.pumpAndSettle();
      final after = tester.getTopLeft(find.text('Discover'));
      expect(after, before, reason: 'label must not jump when activated');
    });

    testWidgets('labels are single-line and ellipsize', (tester) async {
      await _pumpShell(tester);
      for (final tab in _tabs) {
        final text = _labelFor(tester, tab.label);
        expect(text.maxLines, 1);
        expect(text.overflow, TextOverflow.ellipsis);
      }
    });

    testWidgets('exposes button + selected semantics for every tab',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpShell(tester);

      for (var i = 0; i < _tabs.length; i++) {
        await tester.tap(find.text(_tabs[i].label));
        await tester.pumpAndSettle();

        for (var j = 0; j < _tabs.length; j++) {
          final p = _navSemantics(tester, _tabs[j].label).properties;
          expect(p.button, isTrue);
          expect(p.selected, i == j, reason: 'tab $j while tab $i is active');
          expect(p.label, '${_tabs[j].label} tab');
          expect(p.tooltip, _tabs[j].label);
          expect(find.bySemanticsLabel('${_tabs[j].label} tab'),
              findsOneWidget);
        }
      }
      handle.dispose();
    });

    testWidgets('tapping a tab switches branch; tapping active tab is safe',
        (tester) async {
      final router = await _pumpShell(tester);
      expect(find.text('Arena page'), findsOneWidget);

      await tester.tap(find.text('Passport'));
      await tester.pumpAndSettle();
      expect(find.text('Passport page'), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/passport');

      await tester.tap(find.text('Passport'));
      await tester.pumpAndSettle();
      expect(find.text('Passport page'), findsOneWidget);

      await tester.tap(find.text('Arena'));
      await tester.pumpAndSettle();
      expect(find.text('Arena page'), findsOneWidget);
    });

    testWidgets('does not overflow at 360dp wide with 1.5x text scale',
        (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpShell(tester, textScale: 1.5);
      for (final tab in _tabs) {
        await tester.tap(find.text(tab.label));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  });
}
