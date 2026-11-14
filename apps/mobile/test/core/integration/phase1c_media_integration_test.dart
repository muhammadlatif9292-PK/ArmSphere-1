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
import 'package:mobile/core/providers/tournament_provider.dart';
import 'package:mobile/core/providers/rankings_provider.dart';

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

class _FakeTournamentNotifier extends TournamentNotifier {
  @override
  Future<List<Map<String, dynamic>>> build() async => [];
}

class _FakeRankingsNotifier extends RankingsNotifier {
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

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('WelcomeScreen integrates unobstructed ArmSphereAssets.heroWelcomeGrip and stageAuthWalkout via ArmSphereImage', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WelcomeScreen(),
          ),
        ),
      );

      await tester.pump();

      // Verify heroWelcomeGrip environmental anchor is present at 100% opacity as the sole visual artwork
      final gripHeroFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ArmSphereImage &&
            widget.assetPath == ArmSphereAssets.heroWelcomeGrip &&
            widget.excludeFromSemantics == true,
      );
      expect(gripHeroFinder, findsOneWidget);

      // Verify stageAuthWalkout is NOT rendered behind heroWelcomeGrip on WelcomeScreen (zero double-background bleed)
      final walkoutStageFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ArmSphereImage &&
            widget.assetPath == ArmSphereAssets.stageAuthWalkout,
      );
      expect(walkoutStageFinder, findsNothing);

      // Verify circular iconGold seal overlay is removed so the locked grip is 100% unobstructed
      final emblemFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ArmSphereImage &&
            widget.assetPath == ArmSphereAssets.iconGold,
      );
      expect(emblemFinder, findsNothing);

      // Verify core action buttons are present and interactive
      expect(find.text('ENTER ARENA'), findsOneWidget);
      expect(find.text('I ALREADY HAVE AN ACCOUNT'), findsOneWidget);
      expect(find.text('SELECT YOUR ROLE IN THE ARENA'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('AthleteDashboardScreen integrates ArmSphereAssets.stageArena9x16, cardArenaRadar, and heroAthleteDashboard', (WidgetTester tester) async {
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
            tournamentProvider.overrideWith(() => _FakeTournamentNotifier()),
            rankingsProvider.overrideWith(() => _FakeRankingsNotifier()),
            trainingLogProvider('test_ath_1').overrideWith((ref) async => <Map<String, dynamic>>[]),
            trainingLogPRsProvider('test_ath_1').overrideWith((ref) async => <Map<String, dynamic>>[]),
          ],
          child: const MaterialApp(
            home: AthleteDashboardScreen(),
          ),
        ),
      );

      await tester.pump();

      // Verify stageArena9x16 (arena.home.background) environmental anchor is active in the full-screen CrystalStageBackdrop
      final arenaStageFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ArmSphereImage &&
            widget.assetPath == ArmSphereAssets.stageArena9x16 &&
            widget.alignment == Alignment.topCenter &&
            widget.excludeFromSemantics == true,
      );
      expect(arenaStageFinder, findsAtLeastNWidgets(1));

      // Verify dedicated cardArenaRadar (arena.home.radar_card) is integrated in the Sanctioned Arena Radar card
      final radarCardImageFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ArmSphereImage &&
            widget.assetPath == ArmSphereAssets.cardArenaRadar &&
            widget.alignment == const Alignment(0.45, 0.0) &&
            widget.excludeFromSemantics == true,
      );
      expect(radarCardImageFinder, findsOneWidget);

      // Verify the Sanctioned Arena Radar copy
      expect(find.text('SANCTIONED ARENA RADAR'), findsOneWidget);
      expect(find.text('Championship Arena Active'), findsOneWidget);

      // Verify real athlete data is preserved
      expect(find.text('Tariq Iron Grip'), findsOneWidget);
      expect(find.text('COMPETITIVE STANDING'), findsOneWidget);
      expect(find.text('QUICK COMMANDS'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  });
}
