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
      const screenSize = Size(400, 800);
      const bottomInset = 34.0;

      // Render standard endFloat FAB
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: screenSize,
            padding: EdgeInsets.only(bottom: bottomInset),
            viewPadding: EdgeInsets.only(bottom: bottomInset),
          ),
          child: MaterialApp(
            home: Scaffold(
              floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
              floatingActionButton: FloatingActionButton(
                onPressed: () {},
                child: const Icon(Icons.add),
              ),
              body: const SizedBox(),
            ),
          ),
        ),
      );

      final standardFabRect = tester.getRect(find.byType(FloatingActionButton));

      // Render DockAwareEndFloatLocation FAB
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: screenSize,
            padding: EdgeInsets.only(bottom: bottomInset),
            viewPadding: EdgeInsets.only(bottom: bottomInset),
          ),
          child: MaterialApp(
            home: Scaffold(
              floatingActionButtonLocation: const DockAwareEndFloatLocation(),
              floatingActionButton: FloatingActionButton(
                onPressed: () {},
                child: const Icon(Icons.add),
              ),
              body: const SizedBox(),
            ),
          ),
        ),
      );

      final dockFabRect = tester.getRect(find.byType(FloatingActionButton));

      // Horizontal coordinate must remain identical
      expect(dockFabRect.left, standardFabRect.left);

      // Vertical position must be shifted upward by exactly kFloatingDockTotalHeight (76.0)
      expect(dockFabRect.top, standardFabRect.top - kFloatingDockTotalHeight);
      expect(dockFabRect.bottom, standardFabRect.bottom - kFloatingDockTotalHeight);

      // Verify that the bottom edge of the FAB sits 16.0 logical pixels above the dock top
      // Dock top is at: screenSize.height - (kFloatingDockTotalHeight + bottomInset)
      final dockTop = screenSize.height - (kFloatingDockTotalHeight + bottomInset);
      expect(dockTop - dockFabRect.bottom, 16.0);
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
      const screenSize = Size(390, 844);
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
          child: MediaQuery(
            data: const MediaQueryData(
              size: screenSize,
              padding: EdgeInsets.only(bottom: bottomInset),
              viewPadding: EdgeInsets.only(bottom: bottomInset),
            ),
            child: const MaterialApp(
              home: MainShellScope(
                child: AthleteTrainingLogScreen(athleteId: 'athlete_test_1'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find FAB
      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);

      final fabRect = tester.getRect(fabFinder);

      // Floating dock top edge is at: screenSize.height - (76.0 + bottomInset)
      final dockTopEdgeY = screenSize.height - (kFloatingDockTotalHeight + bottomInset);

      // FAB bottom edge (fabRect.bottom) must be strictly at or above the dock top edge
      expect(fabRect.bottom, lessThanOrEqualTo(dockTopEdgeY));

      // Verify clearance gap is at least 16 logical pixels
      final clearanceGap = dockTopEdgeY - fabRect.bottom;
      expect(clearanceGap, greaterThanOrEqualTo(16.0 - 0.001));

      // Verify ListView bottom padding includes dock clearance + FAB breathing room
      final listViewFinder = find.byType(ListView);
      expect(listViewFinder, findsOneWidget);
      final listView = tester.widget<ListView>(listViewFinder);
      final padding = listView.padding as EdgeInsets;

      // Bottom padding should be kFloatingDockTotalHeight (76) + bottomInset (34) + 80 = 190.0
      expect(padding.bottom, 76.0 + bottomInset + 80.0);
    });

    testWidgets('Renders FAB with standard endFloat when viewed outside MainShellScope', (tester) async {
      const screenSize = Size(390, 844);
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
          child: MediaQuery(
            data: const MediaQueryData(
              size: screenSize,
              padding: EdgeInsets.only(bottom: bottomInset),
              viewPadding: EdgeInsets.only(bottom: bottomInset),
            ),
            child: const MaterialApp(
              home: AthleteTrainingLogScreen(athleteId: 'athlete_test_2'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);

      final fabRect = tester.getRect(fabFinder);

      // Outside shell: FAB should sit at 16dp above the bottom safe area inset
      // Expected FAB bottom = screenSize.height - bottomInset - 16.0
      final expectedFabBottom = screenSize.height - bottomInset - 16.0;
      expect((fabRect.bottom - expectedFabBottom).abs(), lessThan(1.0));
    });
  });
}
