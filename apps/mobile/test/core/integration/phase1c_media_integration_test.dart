import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/constants/asset_paths.dart';
import 'package:mobile/core/widgets/armsphere_image.dart';
import 'package:mobile/features/auth/screens/splash_screen.dart';
import 'package:mobile/features/auth/screens/welcome_screen.dart';
import 'package:mobile/features/athlete/screens/athlete_screens.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'package:mobile/core/providers/athlete_provider.dart';
import 'package:mobile/core/providers/live_matches_provider.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

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
  @override
  Future<List<Map<String, dynamic>>> build() async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 1C Batch 1: Controlled Screen Media Integration Tests', () {
    testWidgets('SplashScreen integrates ArmSphereAssets.iconGold via ArmSphereImage', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      // Verify that ArmSphereImage is present and points to the official iconGold asset
      final imageFinder = find.byWidgetPredicate(
        (widget) => widget is ArmSphereImage && widget.assetPath == ArmSphereAssets.iconGold,
      );
      expect(imageFinder, findsOneWidget);

      // Verify branding typography and federation subtitle remain intact
      expect(find.text('ArmSphere'), findsOneWidget);
      expect(find.text('THE COMPETITIVE ARMWRESTLING ECOSYSTEM'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('WelcomeScreen integrates ArmSphereAssets.heroGrip and iconGold via ArmSphereImage', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WelcomeScreen(),
          ),
        ),
      );

      await tester.pump();

      // Verify heroGrip environmental anchor is present with excludeFromSemantics
      final gripHeroFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ArmSphereImage &&
            widget.assetPath == ArmSphereAssets.heroGrip &&
            widget.excludeFromSemantics == true,
      );
      expect(gripHeroFinder, findsOneWidget);

      // Verify iconGold official emblem is present with accessibility semantic label
      final emblemFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ArmSphereImage &&
            widget.assetPath == ArmSphereAssets.iconGold &&
            widget.semanticLabel == 'ArmSphere Official Federation Emblem',
      );
      expect(emblemFinder, findsOneWidget);

      // Verify core action buttons are present and interactive
      expect(find.text('ENTER ARENA'), findsOneWidget);
      expect(find.text('I ALREADY HAVE AN ACCOUNT'), findsOneWidget);
      expect(find.text('SELECT YOUR ROLE IN THE ARENA'), findsOneWidget);
    });

    testWidgets('AthleteDashboardScreen integrates ArmSphereAssets.heroArena and avatar', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(
                  AuthState(
                    status: AuthStatus.authenticated,
                    userProfile: {'id': 'test_ath_1', 'displayName': 'Tariq Iron Grip', 'role': 'ATHLETE'},
                  ),
                )),
            athleteProfileProvider.overrideWith(() => _FakeAthleteProfileNotifier({
                  'id': 'test_ath_1',
                  'rightArmElo': 1750,
                  'leftArmElo': 1690,
                })),
            liveMatchesProvider.overrideWith(() => _FakeLiveMatchesNotifier()),
            trainingLogPRsProvider('test_ath_1').overrideWith((ref) async => <Map<String, dynamic>>[]),
          ],
          child: const MaterialApp(
            home: AthleteDashboardScreen(),
          ),
        ),
      );

      await tester.pump();

      // Verify heroArena environmental anchor is present in the Sanctioned Arena Radar
      final arenaFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ArmSphereImage &&
            widget.assetPath == ArmSphereAssets.heroArena &&
            widget.excludeFromSemantics == true,
      );
      expect(arenaFinder, findsOneWidget);

      // Verify the Sanctioned Arena Radar copy
      expect(find.text('SANCTIONED ARENA RADAR'), findsOneWidget);
      expect(find.text('Championship Arena Active'), findsOneWidget);

      // Verify real athlete data is preserved
      expect(find.text('Tariq Iron Grip'), findsOneWidget);
      expect(find.text('COMPETITIVE STANDING'), findsOneWidget);
      expect(find.text('QUICK COMMANDS'), findsOneWidget);
    });
  });
}
