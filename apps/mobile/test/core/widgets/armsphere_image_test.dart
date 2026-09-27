import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/widgets/armsphere_image.dart';

void main() {
  group('ArmSphereImage Widget Tests', () {
    testWidgets('renders Level 3 procedural fallback with fallbackIcon when no image or asset exists', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ArmSphereImage(
              fallbackAsset: null,
              fallbackIcon: Icons.sports_kabaddi_rounded,
              width: 100,
              height: 100,
            ),
          ),
        ),
      );

      // Level 3 procedural fallback renders Container with fallbackIcon
      expect(find.byIcon(Icons.sports_kabaddi_rounded), findsOneWidget);
    });

    testWidgets('renders Level 3 monogram when initial is provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ArmSphereImage.avatar(
              initial: 'Tariq',
              size: 64,
              fallbackAsset: null,
            ),
          ),
        ),
      );

      // Should extract first letter and render 'T'
      expect(find.text('T'), findsOneWidget);
      expect(find.byType(ClipOval), findsOneWidget);
    });

    testWidgets('respects accessibility semanticLabel', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ArmSphereImage(
              semanticLabel: 'Official Championship Table',
              fallbackAsset: null,
              width: 120,
              height: 80,
            ),
          ),
        ),
      );

      final semanticsFinder = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == 'Official Championship Table',
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('respects excludeFromSemantics flag', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ArmSphereImage(
              excludeFromSemantics: true,
              fallbackAsset: null,
              width: 120,
              height: 80,
            ),
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(ArmSphereImage),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
    });

    testWidgets('applies borderRadius with ClipRRect', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArmSphereImage(
              fallbackAsset: null,
              borderRadius: BorderRadius.circular(16.0),
              width: 150,
              height: 100,
            ),
          ),
        ),
      );

      expect(find.byType(ClipRRect), findsOneWidget);
      final clipRRect = tester.widget<ClipRRect>(find.byType(ClipRRect));
      expect(clipRRect.borderRadius, BorderRadius.circular(16.0));
    });

    testWidgets('renders hero named constructor with default hero configuration', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ArmSphereImage.hero(
              fallbackAsset: null,
              fallbackIcon: Icons.military_tech_rounded,
              height: 180,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.military_tech_rounded), findsOneWidget);
    });

    testWidgets('offline-safe: non-existent local asset does not throw unhandled exception', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ArmSphereImage(
              assetPath: 'assets/images/non_existent_image.webp',
              fallbackAsset: null,
              fallbackIcon: Icons.signal_wifi_off_rounded,
              width: 200,
              height: 120,
            ),
          ),
        ),
      );
      await tester.pump();

      // Gracefully catches missing asset and renders procedural fallback
      expect(find.byIcon(Icons.signal_wifi_off_rounded), findsOneWidget);
    });
  });
}
