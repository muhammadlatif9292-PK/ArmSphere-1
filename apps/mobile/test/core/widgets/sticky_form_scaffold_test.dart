import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/widgets/main_shell_screen.dart';
import 'package:mobile/core/widgets/sticky_bottom_action_bar.dart';
import 'package:mobile/core/widgets/sticky_form_scaffold.dart';

void main() {
  group('StickyFormScaffold Widget Tests', () {
    testWidgets('Renders form child and primary submit button with correct label', (tester) async {
      var submitted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: StickyFormScaffold(
            appBar: AppBar(title: const Text('Test Form')),
            primaryActionLabel: 'Submit Test Form',
            onPrimaryAction: () {
              submitted = true;
            },
            child: const Column(
              children: [
                Text('Test Form Body'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Test Form'), findsOneWidget);
      expect(find.text('Test Form Body'), findsOneWidget);
      expect(find.text('Submit Test Form'), findsOneWidget);

      await tester.tap(find.text('Submit Test Form'));
      await tester.pump();

      expect(submitted, isTrue);
    });

    testWidgets('Renders disabled primary button when onPrimaryAction is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StickyFormScaffold(
            primaryActionLabel: 'Disabled Submit',
            onPrimaryAction: null,
            child: Text('Body'),
          ),
        ),
      );

      expect(find.text('Disabled Submit'), findsOneWidget);
      // Tapping should not throw or cause errors
      await tester.tap(find.text('Disabled Submit'));
      await tester.pump();
    });

    testWidgets('Shows CircularProgressIndicator and suppresses taps when isLoading is true', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: StickyFormScaffold(
            primaryActionLabel: 'Saving...',
            isLoading: true,
            onPrimaryAction: () {
              tapped = true;
            },
            child: const Text('Body'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(StickyBottomActionBar));
      await tester.pump();

      expect(tapped, isFalse);
    });

    testWidgets('Remains docked and visible above soft keyboard without RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Simulate open soft keyboard with 300dp viewInsets.bottom
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 600),
            viewInsets: EdgeInsets.only(bottom: 300.0),
          ),
          child: MaterialApp(
            home: StickyFormScaffold(
              primaryActionLabel: 'Docked Above Keyboard',
              onPrimaryAction: () {},
              child: Column(
                children: List.generate(
                  8,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Field $index'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Submit CTA must be visible on screen
      expect(find.text('Docked Above Keyboard'), findsOneWidget);

      // Verify that the bottom action bar's bottom edge is positioned above the 300dp inset
      final actionRect = tester.getRect(find.byType(StickyBottomActionBar));
      expect(actionRect.bottom, lessThanOrEqualTo(300.0 + 1.0)); // 600 - 300 = 300
    });

    testWidgets('Dynamically adjusts shell clearance: dock clearance when keyboard closed, 0 when keyboard open', (tester) async {
      // 1. Inside MainShellScope, keyboard closed (viewInsets = 0)
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(
            size: Size(400, 800),
            viewInsets: EdgeInsets.zero,
          ),
          child: MaterialApp(
            home: MainShellScope(
              child: StickyFormScaffold(
                primaryActionLabel: 'Shell Form Submit',
                child: Text('Shell Form Body'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final paddingFinderClosed = find.descendant(
        of: find.byType(StickyBottomActionBar),
        matching: find.byType(Padding),
      );

      // Verify at least one Padding has bottom == kFloatingDockTotalHeight (76.0)
      final paddingsClosed = tester.widgetList<Padding>(paddingFinderClosed);
      final hasShellClearanceClosed = paddingsClosed.any((p) {
        final insets = p.padding.resolve(TextDirection.ltr);
        return insets.bottom == kFloatingDockTotalHeight;
      });
      expect(hasShellClearanceClosed, isTrue);

      // 2. Inside MainShellScope, keyboard OPEN (viewInsets = 300)
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(
            size: Size(400, 800),
            viewInsets: EdgeInsets.only(bottom: 300.0),
          ),
          child: MaterialApp(
            home: MainShellScope(
              child: StickyFormScaffold(
                primaryActionLabel: 'Shell Form Submit',
                child: Text('Shell Form Body'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final paddingFinderOpen = find.descendant(
        of: find.byType(StickyBottomActionBar),
        matching: find.byType(Padding),
      );

      final paddingsOpen = tester.widgetList<Padding>(paddingFinderOpen);
      // When keyboard is open, shell clearance must be 0 (no 76.0 added above keyboard)
      final hasShellClearanceOpen = paddingsOpen.any((p) {
        final insets = p.padding.resolve(TextDirection.ltr);
        return insets.bottom == kFloatingDockTotalHeight;
      });
      expect(hasShellClearanceOpen, isFalse);
    });

    testWidgets('Wraps child in Form with provided formKey', (tester) async {
      final formKey = GlobalKey<FormState>();
      var submitted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: StickyFormScaffold(
            formKey: formKey,
            primaryActionLabel: 'Validate & Save',
            onPrimaryAction: () {
              if (formKey.currentState!.validate()) {
                submitted = true;
              }
            },
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required field' : null,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap submit with empty field
      await tester.tap(find.text('Validate & Save'));
      await tester.pump();

      expect(submitted, isFalse);
      expect(find.text('Required field'), findsOneWidget);

      // Enter text and tap submit
      await tester.enterText(find.byType(TextFormField), 'champion_puller');
      await tester.tap(find.text('Validate & Save'));
      await tester.pump();

      expect(submitted, isTrue);
    });
  });
}
