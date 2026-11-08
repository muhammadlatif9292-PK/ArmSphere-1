import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/asset_paths.dart';
import 'package:mobile/core/providers/athlete_provider.dart';
import 'package:mobile/core/providers/live_matches_provider.dart';
import 'package:mobile/core/providers/rankings_provider.dart';
import 'package:mobile/core/providers/tournament_provider.dart';
import 'package:mobile/core/providers/visual_preferences_provider.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/armsphere_image.dart';
import 'package:mobile/features/athlete/screens/athlete_screens.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';

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
  @override
  Future<List<Map<String, dynamic>>> build() async => const [];
}

class _FakeTournamentNotifier extends TournamentNotifier {
  @override
  Future<List<Map<String, dynamic>>> build() async => const [];
}

class _FakeRankingsNotifier extends RankingsNotifier {
  @override
  Future<List<Map<String, dynamic>>> build() async => const [];
}

class _FakeVisualPreferencesNotifier extends VisualPreferencesNotifier {
  _FakeVisualPreferencesNotifier(super.ref, VisualPreferencesState initialState) {
    state = initialState;
  }
}

Future<void> _pumpHeroDashboard(
  WidgetTester tester, {
  double width = 412,
  double height = 840,
  double textScale = 1.0,
  VisualPreferencesState? visualPrefs,
  Map<String, dynamic>? athleteProfile,
}) async {
  tester.view.physicalSize = Size(width * 2.0, height * 2.0);
  tester.view.devicePixelRatio = 2.0;

  final profile = athleteProfile ??
      {
        'id': 'ath_hero_1',
        'displayName': 'Levan Saginashvili',
        'rank': '1',
        'rankDelta': '2',
        'weightKg': 175.0,
        'winRate': 96.4,
        'armDominance': 'Right Arm',
        'club': 'Titan Pullers Tbilisi',
        'country': 'GEO',
        'rightArmElo': 1890,
        'leftArmElo': 1810,
        'eloDelta': 28,
      };

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(
          (ref) => _TestAuthNotifier(
            AuthState(
              status: AuthStatus.authenticated,
              userProfile: {
                'id': 'ath_hero_1',
                'displayName': profile['displayName'] ?? 'Levan Saginashvili',
                'role': 'ATHLETE',
              },
            ),
          ),
        ),
        athleteProfileProvider
            .overrideWith(() => _FakeAthleteProfileNotifier(profile)),
        liveMatchesProvider.overrideWith(() => _FakeLiveMatchesNotifier()),
        tournamentProvider.overrideWith(() => _FakeTournamentNotifier()),
        rankingsProvider.overrideWith(() => _FakeRankingsNotifier()),
        trainingLogProvider('ath_hero_1')
            .overrideWith((ref) async => <Map<String, dynamic>>[]),
        trainingLogPRsProvider('ath_hero_1')
            .overrideWith((ref) async => <Map<String, dynamic>>[]),
        if (visualPrefs != null)
          visualPreferencesProvider.overrideWith(
            (ref) => _FakeVisualPreferencesNotifier(ref, visualPrefs),
          ),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
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

Future<void> _disposeHeroDashboard(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

void main() {
  group('Athlete Dashboard Hero Card Redesign (profile.athlete.dashboard_hero)', () {
    testWidgets(
      'resolves semantic ID profile.athlete.dashboard_hero to supplied crimson-smoke artwork by default',
      (tester) async {
        expect(
          ArmSphereAssets.resolveSemanticAsset('profile.athlete.dashboard_hero'),
          equals(ArmSphereAssets.heroAthleteDashboard),
        );
        expect(
          ArmSphereAssets.resolveSemanticAsset('arena.home.radar_card'),
          equals(ArmSphereAssets.cardArenaRadar),
        );
        expect(
          normalizeLegacyVisualAssetPath(
            'assets/images/heroes/m1_hero_athlete_dashboard.png',
          ),
          equals(ArmSphereAssets.heroAthleteDashboard),
        );
        expect(
          const VisualPreferencesState()
              .presetForDomain(ArmSphereStageDomain.training)
              .primaryAsset,
          equals(ArmSphereAssets.stageTrainingLab9x16),
        );

        await _pumpHeroDashboard(tester);

        expect(
          find.byKey(const ValueKey('profile.athlete.dashboard_hero')),
          findsOneWidget,
        );

        // Verify the Sanctioned Arena Radar uses the dedicated cardArenaRadar asset
        final radarImgFinder = find.byWidgetPredicate(
          (w) =>
              w is ArmSphereImage &&
              w.assetPath == ArmSphereAssets.cardArenaRadar &&
              w.alignment == const Alignment(0.45, 0.0),
        );
        expect(radarImgFinder, findsOneWidget);

        // Verify the full-bleed hero artwork uses ArmSphereAssets.heroAthleteDashboard (.webp)
        final heroImgFinder = find.byWidgetPredicate(
          (w) =>
              w is ArmSphereImage &&
              w.assetPath == ArmSphereAssets.heroAthleteDashboard &&
              w.alignment == const Alignment(-0.55, -0.24) &&
              w.semanticLabel == 'Athlete Hero Artwork: Levan Saginashvili',
        );
        expect(heroImgFinder, findsOneWidget);

        // Verify hierarchy: Name, Credentials, Club/Country, Prominent ELO callout, 4-stat ribbon
        expect(find.text('Levan Saginashvili'), findsOneWidget);
        expect(find.text('VERIFIED'), findsOneWidget);
        expect(find.text('PAFF COMPETITOR'), findsOneWidget);
        expect(find.text('GEO'), findsOneWidget);
        expect(find.textContaining('Titan Pullers Tbilisi'), findsOneWidget);
        expect(find.text('R-ARM RATING'), findsOneWidget);
        expect(find.text('ELO 1890'), findsOneWidget);
        expect(find.text('▲ +28'), findsOneWidget);
        expect(find.text('WORLD RANK'), findsOneWidget);
        expect(find.text('175.0 kg'), findsOneWidget);
        expect(find.text('96.4%'), findsOneWidget);
        expect(find.text('Right Arm'), findsOneWidget);

        expect(tester.takeException(), isNull);
        await _disposeHeroDashboard(tester);
      },
    );

    testWidgets(
      'accommodates alternative widescreen and portrait/square images without layout changes',
      (tester) async {
        // 1. Alternative widescreen preset
        await _pumpHeroDashboard(
          tester,
          visualPrefs: const VisualPreferencesState(
            selectedCardPresetId: 'championship_arena',
          ),
        );
        expect(tester.takeException(), isNull);

        // 2. Portrait / square athlete photo blended on the left subject stage
        await _pumpHeroDashboard(
          tester,
          visualPrefs: const VisualPreferencesState(
            customPortraitImage: ArmSphereAssets.defaultAvatar,
            selectedCardPresetId:
                ArmSphereAssets.semanticProfileAthleteDashboardHero,
          ),
        );

        final portraitSubjectFinder = find.byWidgetPredicate(
          (w) =>
              w is ArmSphereImage &&
              w.assetPath == ArmSphereAssets.defaultAvatar &&
              w.semanticLabel == 'Athlete Avatar: Levan Saginashvili',
        );
        expect(portraitSubjectFinder, findsOneWidget);
        expect(tester.takeException(), isNull);

        await _disposeHeroDashboard(tester);
      },
    );

    for (final (width, scale) in <(double, double)>[
      (360, 1.0),
      (360, 1.4),
      (360, 2.0),
      (412, 1.0),
      (600, 1.0),
    ]) {
      testWidgets(
        'renders without overflow at ${width}dp width and ${scale}x text scale',
        (tester) async {
          await _pumpHeroDashboard(tester, width: width, textScale: scale);
          expect(tester.takeException(), isNull);
          expect(find.text('Levan Saginashvili'), findsOneWidget);
          expect(find.text('ELO 1890'), findsOneWidget);
          await _disposeHeroDashboard(tester);
        },
      );
    }
  });
}
