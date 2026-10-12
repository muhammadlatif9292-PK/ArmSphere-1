import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/providers/state_providers.dart';
import 'package:mobile/features/match/screens/head_to_head_screen.dart';
import 'package:mobile/features/tournament/widgets/bracket_tree_widget.dart';

void main() {
  group('P3 Polish & Canvas Controls Tests', () {
    testWidgets('HeadToHeadScreen renders high-contrast dual-arm switcher and clickable avatars (ISSUE-P3-01)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Return empty/null or mock data for comparison
            athleteComparisonProvider((athlete1Id: 'ath_1', athlete2Id: 'ath_2')).overrideWith(
              (ref) async => {
                'athlete1': {
                  'id': 'ath_1',
                  'displayName': 'John Brzenk',
                  'clubName': 'Heritage Pullers',
                  'province': 'Utah',
                  'weightClass': '-95 KG',
                  'eloRating': 2100,
                  'dominantArm': 'RIGHT',
                  'measurements': {
                    'forearmCircumference': 43.0,
                    'bicepCircumference': 45.0,
                    'handSpan': 23.0,
                  },
                },
                'athlete2': {
                  'id': 'ath_2',
                  'displayName': 'Devon Larratt',
                  'clubName': 'Arm Gods',
                  'province': 'Ontario',
                  'weightClass': '-105 KG',
                  'eloRating': 2250,
                  'dominantArm': 'RIGHT',
                  'measurements': {
                    'forearmCircumference': 44.0,
                    'bicepCircumference': 46.0,
                    'handSpan': 25.0,
                  },
                },
              },
            ),
          ],
          child: const MaterialApp(
            home: HeadToHeadScreen(
              athleteId1: 'ath_1',
              athleteId2: 'ath_2',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the high-contrast dual-arm switcher exists
      expect(find.text('RIGHT'), findsOneWidget);
      expect(find.text('LEFT'), findsOneWidget);

      // Verify semantic label for arm toggle
      expect(
        find.bySemanticsLabel(RegExp(r'Switch arm comparison.*Right Arm.*selected')),
        findsOneWidget,
      );

      // Verify tooltips on contender avatars
      expect(find.byTooltip('View John Brzenk Passport'), findsOneWidget);
      expect(find.byTooltip('View Devon Larratt Passport'), findsOneWidget);

      // Tap 'LEFT' arm segment to toggle arm
      await tester.tap(find.text('LEFT'));
      await tester.pumpAndSettle();

      // Verify semantic label updated to Left Arm selected
      expect(
        find.bySemanticsLabel(RegExp(r'Switch arm comparison.*Left Arm.*selected')),
        findsOneWidget,
      );
    });

    testWidgets('BracketTreeWidget renders zoom controls and handles zoom in, out, and reset (S-039)',
        (WidgetTester tester) async {
      final matches = [
        {
          'id': 'm_1',
          'round': 1,
          'matchIndex': 0,
          'status': 'SCHEDULED',
          'bracketType': 'WINNERS',
          'competitor1': {'name': 'Puller A', 'score': 0},
          'competitor2': {'name': 'Puller B', 'score': 0},
        },
        {
          'id': 'm_2',
          'round': 1,
          'matchIndex': 1,
          'status': 'SCHEDULED',
          'bracketType': 'WINNERS',
          'competitor1': {'name': 'Puller C', 'score': 0},
          'competitor2': {'name': 'Puller D', 'score': 0},
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BracketTreeWidget(
              matches: matches,
              titlePrefix: 'WINNERS',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify zoom controls are present
      expect(find.byIcon(Icons.zoom_in_rounded), findsOneWidget);
      expect(find.byIcon(Icons.zoom_out_rounded), findsOneWidget);
      expect(find.text('RESET'), findsOneWidget);

      // Tap Zoom In
      await tester.tap(find.byIcon(Icons.zoom_in_rounded));
      await tester.pumpAndSettle();

      // Tap Zoom Out
      await tester.tap(find.byIcon(Icons.zoom_out_rounded));
      await tester.pumpAndSettle();

      // Tap Reset
      await tester.tap(find.text('RESET'));
      await tester.pumpAndSettle();

      // Verify widget still renders properly after zoom cycles
      expect(find.text('RESET'), findsOneWidget);
    });
  });
}
