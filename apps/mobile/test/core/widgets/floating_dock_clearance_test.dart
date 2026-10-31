import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/widgets/main_shell_screen.dart';
import 'package:mobile/features/athlete/screens/training_log_screen.dart';
import 'package:mobile/core/providers/athlete_provider.dart';

void main() {
  group('MainShellScope & Floating Dock Clearance Contract Tests', () {
    test('Calculates correct dock constants', () {
      expect(kFloatingDockHeight, 64.0);
      expect(kFloatingDockBottomMargin, 12.0);
      expect(kFloatingDockTotalHeight, 76.0);
    });

    testWidgets('Detects shell presence correctly via isInsideShell', (tester) async {
      bool? insideWithoutShell;
      bool? insideWithShell;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              insideWithoutShell = MainShellScope.isInsideShell(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(insideWithoutShell, isFalse);

      await tester.pumpWidget(
        MaterialApp(
          home: MainShellScope(
            child: Builder(
              builder: (context) {
                insideWithShell = MainShellScope.isInsideShell(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(insideWithShell, isTrue);
    });

    testWidgets('Calculates bottomClearance dynamically based on shell and safe-area insets', (tester) async {
      double? clearanceNoShellZeroInset;
      double? clearanceNoShellGestureInset;
      double? clearanceShellZeroInset;
      double? clearanceShellGestureInset;

      // 1. Outside shell, 0 inset (3-button navigation)
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.zero),
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                clearanceNoShellZeroInset = MainShellScope.bottomClearance(context, additionalPadding: 16.0);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // Outside shell: 0 + 16.0 = 16.0
      expect(clearanceNoShellZeroInset, 16.0);

      // 2. Outside shell, 34px inset (gesture navigation)
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.only(bottom: 34.0)),
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                clearanceNoShellGestureInset = MainShellScope.bottomClearance(context, additionalPadding: 16.0);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // Outside shell: 34.0 + 16.0 = 50.0
      expect(clearanceNoShellGestureInset, 50.0);

      // 3. Inside shell, 0 inset (3-button navigation)
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.zero),
          child: MaterialApp(
            home: MainShellScope(
              child: Builder(
                builder: (context) {
                  clearanceShellZeroInset = MainShellScope.bottomClearance(context, additionalPadding: 16.0);
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      // Inside shell: 76.0 + 0 + 16.0 = 92.0
      expect(clearanceShellZeroInset, 92.0);

      // 4. Inside shell, 34px inset (gesture navigation)
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.only(bottom: 34.0)),
          child: MaterialApp(
            home: MainShellScope(
              child: Builder(
                builder: (context) {
                  clearanceShellGestureInset = MainShellScope.bottomClearance(context, additionalPadding: 20.0);
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      // Inside shell: 76.0 + 34.0 + 20.0 = 130.0
      expect(clearanceShellGestureInset, 130.0);
    });

    testWidgets('DockAwareEndFloatLocation shifts FAB upward by exactly 76 logical pixels compared to endFloat', (tester) async {
      // Render standard endFloat FAB
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
            body: const SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final standardFabRect = tester.getRect(find.byType(FloatingActionButton));

      // Render DockAwareEndFloatLocation FAB
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            key: const ValueKey('dockScaffold'),
            floatingActionButtonLocation: const DockAwareEndFloatLocation(),
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
            body: const SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final dockFabRect = tester.getRect(find.byType(FloatingActionButton));

      // Horizontal coordinate must remain identical
      expect(dockFabRect.left, standardFabRect.left);

      // Vertical position must be shifted upward by exactly kFloatingDockTotalHeight (76.0)
      expect(standardFabRect.top - dockFabRect.top, kFloatingDockTotalHeight);
      expect(standardFabRect.bottom - dockFabRect.bottom, kFloatingDockTotalHeight);
    });

    testWidgets('MainShellScope.fabLocation selects DockAwareEndFloatLocation inside shell and endFloat outside', (tester) async {
      FloatingActionButtonLocation? locationOutside;
      FloatingActionButtonLocation? locationInside;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              locationOutside = MainShellScope.fabLocation(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(locationOutside, FloatingActionButtonLocation.endFloat);

      await tester.pumpWidget(
        MaterialApp(
          home: MainShellScope(
            child: Builder(
              builder: (context) {
                locationInside = MainShellScope.fabLocation(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(locationInside, isA<DockAwareEndFloatLocation>());
    });
  });

  group('AthleteTrainingLogScreen FAB & Dock Clearance Integration Tests', () {
    testWidgets('Renders FAB above dock when wrapped in MainShellScope with gesture navigation', (tester) async {
      const bottomInset = 34.0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trainingLogProvider('athlete_test_1').overrideWith(
              (ref) async => <Map<String, dynamic>>[
                {
                  'id': 'log_1',
                  'exercise': 'CUPPING WRIST CURL',
                  'weightKg': 45.0,
                  'reps': 10,
                  'createdAt': '2026-10-10T14:00:00Z',
                },
              ],
            ),
            trainingLogPRsProvider('athlete_test_1').overrideWith(
              (ref) async => <Map<String, dynamic>>[],
            ),
          ],
          child: const MediaQuery(
            data: MediaQueryData(
              padding: EdgeInsets.only(bottom: bottomInset),
              viewPadding: EdgeInsets.only(bottom: bottomInset),
            ),
            child: MaterialApp(
              home: MainShellScope(
                child: AthleteTrainingLogScreen(athleteId: 'athlete_test_1'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find FAB and assert presence
      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);

      // Verify Scaffold has DockAwareEndFloatLocation configured
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.floatingActionButtonLocation, isA<DockAwareEndFloatLocation>());

      // Verify root ListView bottom padding includes dock clearance (76) + bottomInset (34) + FAB breathing room (80)
      final rootListView = tester.widgetList<ListView>(find.byType(ListView)).first;
      final padding = rootListView.padding as EdgeInsets;
      expect(padding.bottom, 76.0 + bottomInset + 80.0);
    });

    testWidgets('Renders FAB with standard endFloat when viewed outside MainShellScope', (tester) async {
      const bottomInset = 34.0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trainingLogProvider('athlete_test_2').overrideWith(
              (ref) async => <Map<String, dynamic>>[],
            ),
            trainingLogPRsProvider('athlete_test_2').overrideWith(
              (ref) async => <Map<String, dynamic>>[],
            ),
          ],
          child: const MediaQuery(
            data: MediaQueryData(
              padding: EdgeInsets.only(bottom: bottomInset),
              viewPadding: EdgeInsets.only(bottom: bottomInset),
            ),
            child: MaterialApp(
              home: AthleteTrainingLogScreen(athleteId: 'athlete_test_2'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find FAB and assert presence
      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);

      // Verify Scaffold has standard endFloat location configured
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.floatingActionButtonLocation, FloatingActionButtonLocation.endFloat);

      // Verify root ListView bottom padding outside shell has no dock clearance
      final rootListView = tester.widgetList<ListView>(find.byType(ListView)).first;
      final padding = rootListView.padding as EdgeInsets;
      expect(padding.bottom, bottomInset + 80.0);
    });
  });
}
