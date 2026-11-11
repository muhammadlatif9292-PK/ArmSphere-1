import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/crystal_glass_nav_controls.dart';
import 'package:mobile/core/widgets/crystal_modal_sheet.dart';
import 'package:mobile/core/widgets/crystal_toast.dart';
import 'package:mobile/core/widgets/main_shell_screen.dart';
import 'package:mobile/core/widgets/skeleton_placeholder.dart';

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

    testWidgets('every tab uses gold icon, crimson border, and white label when active',
        (tester) async {
      await _pumpShell(tester);

      for (var i = 0; i < _tabs.length; i++) {
        final tab = _tabs[i];
        await tester.tap(find.text(tab.label));
        await tester.pumpAndSettle();

        final icon = _iconFor(tester, tab.activeIcon);
        expect(icon.color, const Color(0xFFD4AF37), reason: '${tab.label} icon');

        final pill = tester.widget<AnimatedContainer>(
          find.ancestor(
            of: find.byIcon(tab.activeIcon),
            matching: find.byType(AnimatedContainer),
          ),
        );
        final deco = pill.decoration! as BoxDecoration;
        expect(
          deco.color,
          Colors.transparent,
          reason: '${tab.label} pill fill',
        );
        expect(
          deco.gradient,
          isNull,
          reason: '${tab.label} pill gradient',
        );
        final topBorder = (deco.border! as Border).top;
        expect(
          topBorder.color,
          const Color(0xFFE23B3B),
          reason: '${tab.label} pill border',
        );
        expect(
          topBorder.width,
          1.3,
          reason: '${tab.label} pill border width',
        );
      }
    });

    testWidgets('active label is white, inactive labels are crisp ice-slate',
        (tester) async {
      await _pumpShell(tester);
      await tester.tap(find.text('Events'));
      await tester.pumpAndSettle();

      for (final tab in _tabs) {
        final style = _labelFor(tester, tab.label).style!;
        if (tab.label == 'Events') {
          expect(style.color, const Color(0xFFFFFFFF));
          expect(style.fontWeight, FontWeight.w700);
        } else {
          expect(style.color, const Color(0xFFF1F5F9));
          expect(style.fontWeight, FontWeight.w600);
          expect(_iconFor(tester, tab.icon).color, const Color(0xFFF1F5F9));
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

    testWidgets('labels stay readable: >=10sp, text scale capped, no truncation',
        (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpShell(tester, textScale: 1.5);
      for (final tab in _tabs) {
        final finder = find.text(tab.label);
        expect(_labelFor(tester, tab.label).style!.fontSize,
            greaterThanOrEqualTo(10.0));
        // Dock caps label scaling at 1.3x even when the system asks for 1.5x.
        final scaled =
            MediaQuery.textScalerOf(tester.element(finder)).scale(10);
        expect(scaled, closeTo(13.0, 0.01), reason: '${tab.label} scale');
        // Too-wide labels shrink to fit instead of ellipsizing.
        expect(
          find.ancestor(of: finder, matching: find.byType(FittedBox)),
          findsWidgets,
          reason: '${tab.label} fits via FittedBox',
        );
      }
      expect(tester.takeException(), isNull);
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

    testWidgets('auto-hides dock when scrolling down and reveals when scrolling up',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) =>
                MainShellScreen(navigationShell: navigationShell),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/home',
                    builder: (context, state) => ListView.builder(
                      itemCount: 40,
                      itemExtent: 60,
                      itemBuilder: (context, index) => Text('Item $index'),
                    ),
                  ),
                ],
              ),
              for (var i = 1; i < _tabs.length; i++)
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/${_tabs[i].label.toLowerCase()}',
                      builder: (context, state) =>
                          Center(child: Text('${_tabs[i].label} page')),
                    ),
                  ],
                ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      AnimatedOpacity dockOpacity() => tester.widget<AnimatedOpacity>(
            find.ancestor(
              of: find.byKey(const ValueKey('crystal_floating_nav_dock')),
              matching: find.byType(AnimatedOpacity),
            ),
          );

      expect(dockOpacity().opacity, 1.0);

      // Drag up to scroll down -> dock auto-hides
      await tester.drag(find.byType(ListView), const Offset(0, -180));
      await tester.pumpAndSettle();
      expect(dockOpacity().opacity, 0.0);

      // Drag down to scroll up -> dock reveals
      await tester.drag(find.byType(ListView), const Offset(0, 120));
      await tester.pumpAndSettle();
      expect(dockOpacity().opacity, 1.0);
    });

    testWidgets('hides floating dock completely on non-root inner sub-routes',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) =>
                MainShellScreen(navigationShell: navigationShell),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/home',
                    builder: (context, state) => const Center(child: Text('Home root')),
                    routes: [
                      GoRoute(
                        path: 'details',
                        builder: (context, state) =>
                            const Center(child: Text('Inner details screen')),
                      ),
                    ],
                  ),
                ],
              ),
              for (var i = 1; i < _tabs.length; i++)
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/${_tabs[i].label.toLowerCase()}',
                      builder: (context, state) =>
                          Center(child: Text('${_tabs[i].label} page')),
                    ),
                  ],
                ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('crystal_floating_nav_dock')), findsOneWidget);

      router.go('/home/details');
      await tester.pumpAndSettle();
      expect(find.text('Inner details screen'), findsOneWidget);
      expect(find.byKey(const ValueKey('crystal_floating_nav_dock')), findsNothing);
    });

    testWidgets('hides floating dock when pushing a top-level inner route like /settings',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/profile',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) =>
                MainShellScreen(navigationShell: navigationShell),
            branches: [
              for (var i = 0; i < _tabs.length - 1; i++)
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/${_tabs[i].label.toLowerCase()}',
                      builder: (context, state) =>
                          Center(child: Text('${_tabs[i].label} page')),
                    ),
                  ],
                ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/profile',
                    builder: (context, state) =>
                        const Center(child: Text('Passport root')),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('Settings screen'))),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('crystal_floating_nav_dock')), findsOneWidget);

      router.push('/settings');
      await tester.pumpAndSettle();
      expect(find.text('Settings screen'), findsOneWidget);
      expect(find.byKey(const ValueKey('crystal_floating_nav_dock')), findsNothing);
    });

    testWidgets('SkeletonPlaceholder renders structured crystal card details for card heights',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  SkeletonPlaceholder(height: 96),
                  SizedBox(height: 12),
                  SkeletonPlaceholder(height: 156),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(SkeletonPlaceholder), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'CrystalModalSheet keeps Save button pinned, unfocuses active input on background tap, and closes on handle tap',
        (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      bool saved = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      useRootNavigator: true,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => CrystalModalSheet(
                        title: 'EDIT PROFILE & BIOMETRICS',
                        subtitle: 'Official PAFF Competitor Dossier',
                        primaryActionLabel: 'Save Changes',
                        onPrimaryAction: () {
                          saved = true;
                          Navigator.of(ctx).pop();
                        },
                        child: Column(
                          children: [
                            TextField(
                              key: const ValueKey('test_bio_input'),
                              focusNode: focusNode,
                              decoration: CrystalModalSheet.inputDecoration(
                                labelText: 'Body Weight (kg)',
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text('Tap Area Outside Field'),
                          ],
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Editor'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Editor'));
      await tester.pumpAndSettle();

      // Verify pinned Save Changes button is visible
      expect(
        find.byKey(const ValueKey('crystal_modal_primary_action')),
        findsOneWidget,
      );
      expect(find.text('Save Changes'), findsOneWidget);

      // Focus the TextField, then tap on the sheet background text to unfocus
      await tester.tap(find.byKey(const ValueKey('test_bio_input')));
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      await tester.tap(find.text('Tap Area Outside Field'));
      await tester.pump();
      expect(focusNode.hasFocus, isFalse);

      // Tapping the primary action invokes callback and closes
      await tester.tap(find.byKey(const ValueKey('crystal_modal_primary_action')));
      await tester.pumpAndSettle();
      expect(saved, isTrue);
    });

    testWidgets(
        'highlights Passport tab when navigated from Arena and steps back chronologically',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) =>
                MainShellScreen(navigationShell: navigationShell),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/home',
                    builder: (context, state) => Column(
                      children: [
                        const Text('Arena root'),
                        ElevatedButton(
                          onPressed: () => MainShellScope.goToMainTabByPath(
                              context, '/discover'),
                          child: const Text('Go Discover'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/discover',
                    builder: (context, state) => Column(
                      children: [
                        const Text('Discover root'),
                        ElevatedButton(
                          onPressed: () => MainShellScope.goToMainTabByPath(
                              context, '/athlete/profile'),
                          child: const Text('Go Passport'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/tournaments',
                    builder: (context, state) => const Text('Events root'),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/community/feed',
                    builder: (context, state) => const Text('Community root'),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/athlete/profile',
                    builder: (context, state) => Column(
                      children: [
                        const Text('Passport root'),
                        const CrystalBackButton(),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(_navSemantics(tester, 'Arena').properties.selected, isTrue);
      expect(_navSemantics(tester, 'Passport').properties.selected, isFalse);

      // Navigate Arena -> Discover -> Passport
      await tester.tap(find.text('Go Discover'));
      await tester.pumpAndSettle();
      expect(_navSemantics(tester, 'Discover').properties.selected, isTrue);

      await tester.tap(find.text('Go Passport'));
      await tester.pumpAndSettle();
      expect(_navSemantics(tester, 'Passport').properties.selected, isTrue);
      expect(_navSemantics(tester, 'Arena').properties.selected, isFalse);

      // Step back once -> returns to Discover (not straight to Arena)
      final passportContext = tester.element(find.text('Passport root'));
      final steppedToDiscover =
          MainShellScope.stepBackIfPossible(passportContext);
      await tester.pumpAndSettle();
      expect(steppedToDiscover, isTrue);
      expect(_navSemantics(tester, 'Discover').properties.selected, isTrue);

      // Step back again -> returns to Arena
      final discoverContext = tester.element(find.text('Discover root'));
      final steppedToArena = MainShellScope.stepBackIfPossible(discoverContext);
      await tester.pumpAndSettle();
      expect(steppedToArena, isTrue);
      expect(_navSemantics(tester, 'Arena').properties.selected, isTrue);
    });

    testWidgets('resets vertical scroll position to top when shifting tabs',
        (tester) async {
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) =>
                MainShellScreen(navigationShell: navigationShell),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/home',
                    builder: (context, state) => ListView.builder(
                      controller: scrollController,
                      itemCount: 50,
                      itemExtent: 60,
                      itemBuilder: (context, index) => Text('Row $index'),
                    ),
                  ),
                ],
              ),
              for (var i = 1; i < _tabs.length; i++)
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/${_tabs[i].label.toLowerCase()}',
                      builder: (context, state) =>
                          Center(child: Text('${_tabs[i].label} page')),
                    ),
                  ],
                ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      scrollController.jumpTo(360.0);
      await tester.pump();
      expect(scrollController.offset, 360.0);

      // Switch to Events tab and back to Arena tab -> scroll resets to 0.0
      await tester.tap(find.text('Events'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Arena'));
      await tester.pumpAndSettle();

      expect(scrollController.offset, 0.0);
    });

    testWidgets(
        'CrystalSnackBar, CrystalActionButton, CrystalHeaderActionPill, and CrystalFloatingActionButton render cleanly',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                CrystalHeaderActionPill(
                  label: 'Mark all read',
                  icon: Icons.done_all_rounded,
                  onTap: () {},
                ),
              ],
            ),
            body: Builder(
              builder: (context) => Center(
                child: CrystalActionButton(
                  label: 'Log a Session',
                  icon: Icons.fitness_center,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      CrystalSnackBar(
                        content: const Text('All alerts marked as read'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  },
                ),
              ),
            ),
            floatingActionButton: CrystalFloatingActionButton(
              tooltip: 'Log a session',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Mark all read'), findsOneWidget);
      expect(find.text('Log a Session'), findsOneWidget);
      expect(find.byType(CrystalFloatingActionButton), findsOneWidget);

      await tester.tap(find.text('Log a Session'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('All alerts marked as read'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

