import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/constants/asset_paths.dart';
import 'package:mobile/core/widgets/armsphere_image.dart';
import 'package:mobile/features/athlete/screens/athlete_screens.dart';
import 'package:mobile/features/athlete/screens/public_profile_screen.dart';
import 'package:mobile/features/athlete/screens/rankings_screen.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'package:mobile/core/providers/athlete_provider.dart';
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

class _FakeRankingsNotifier extends RankingsNotifier {
  final List<Map<String, dynamic>> _rankings;
  _FakeRankingsNotifier(this._rankings);

  @override
  Future<List<Map<String, dynamic>>> build() async => _rankings;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 1C Batch 2: Athlete Identity Media Integration Tests', () {
    testWidgets('AthleteProfileScreen renders avatar and division badge via ArmSphereImage', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(
                  AuthState(
                    status: AuthStatus.authenticated,
                    userProfile: {
                      'id': 'ath_heavy_1',
                      'displayName': 'Sultan Khan',
                      'email': 'sultan@armsphere.com',
                      'role': 'ATHLETE',
                      'weightKg': 105,
                      'weightClass': 'Heavyweight',
                    },
                  ),
                )),
            athleteProfileProvider.overrideWith(() => _FakeAthleteProfileNotifier({
                  'id': 'ath_heavy_1',
                  'weightKg': 105,
                  'weightClass': 'Heavyweight',
                })),
          ],
          child: const MaterialApp(
            home: AthleteProfileScreen(),
          ),
        ),
      );

      await tester.pump();

      // 1. Verify athlete avatar uses ArmSphereImage.avatar with fallbackAsset and semanticLabel
      final avatarFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ArmSphereImage &&
            widget.width == 72 &&
            widget.height == 72 &&
            widget.fallbackAsset == ArmSphereAssets.defaultAvatar &&
            widget.semanticLabel == 'Athlete Avatar for Sultan Khan',
      );
      expect(avatarFinder, findsOneWidget);

      // 2. Verify division badge is rendered for Heavyweight competitor
      final badgeFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ArmSphereImage &&
            widget.assetPath == ArmSphereAssets.badgeHeavy &&
            widget.width == 20 &&
            widget.height == 20 &&
            widget.semanticLabel == 'Division Category Badge',
      );
      expect(badgeFinder, findsOneWidget);

      // 3. Verify competitor identity texts
      expect(find.text('Sultan Khan'), findsOneWidget);
      expect(find.text('Official PAFF Competitor'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('PublicAthleteProfileScreen renders 96px avatar and division badge', (WidgetTester tester) async {
      const athleteId = 'ath_public_1';
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            athleteProfileProvider.overrideWith(() => _FakeAthleteProfileNotifier({
                  'id': athleteId,
                })),
            publicAthleteProfileProvider(athleteId).overrideWith((ref) async => {
                  'id': athleteId,
                  'displayName': 'Farhan Tiger',
                  'profilePhoto': '',
                  'city': 'Lahore',
                  'province': 'Punjab',
                  'weightClass': 'Middleweight',
                  'dominantArm': 'RIGHT',
                  'rightArmElo': 1820,
                  'leftArmElo': 1710,
                  'club': {'name': 'Lahore Armwrestling Club'},
                  'biography': 'Top-ranked middleweight puller in Punjab.',
                }),
          ],
          child: const MaterialApp(
            home: PublicAthleteProfileScreen(athleteId: athleteId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify public avatar uses ArmSphereImage.avatar with 96px size
      final avatarFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ArmSphereImage &&
            widget.width == 96 &&
            widget.height == 96 &&
            widget.fallbackAsset == ArmSphereAssets.defaultAvatar &&
            widget.semanticLabel == 'Athlete profile photo for Farhan Tiger',
      );
      expect(avatarFinder, findsOneWidget);

      // 2. Verify division badge is rendered for Middleweight
      final badgeFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ArmSphereImage &&
            widget.assetPath == ArmSphereAssets.badgeMiddle &&
            widget.width == 18 &&
            widget.height == 18 &&
            widget.semanticLabel == 'Middleweight division badge',
      );
      expect(badgeFinder, findsOneWidget);

      // 3. Verify core profile info & ELO figures are preserved
      expect(find.text('Farhan Tiger'), findsOneWidget);
      expect(find.text('MIDDLEWEIGHT'), findsOneWidget);
      expect(find.text('Lahore, Punjab'), findsOneWidget);
      expect(find.text('1820 ELO'), findsOneWidget);
      expect(find.text('1710 ELO'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('RankingsScreen renders sealFed in AppBar and bounded avatars in list', (WidgetTester tester) async {
      final mockAthletes = [
        {
          'rank': 1,
          'athleteId': 'ath_101',
          'displayName': 'Hamza Iron',
          'eloRating': 1950,
          'weightClass': 'Heavyweight',
          'province': 'Punjab',
          'avatarUrl': null,
        },
        {
          'rank': 2,
          'athleteId': 'ath_102',
          'displayName': 'Bilal Steel',
          'eloRating': 1880,
          'weightClass': 'Middleweight',
          'province': 'Sindh',
          'avatarUrl': null,
        },
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            rankingsProvider.overrideWith(() => _FakeRankingsNotifier(mockAthletes)),
          ],
          child: const MaterialApp(
            home: RankingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify Federation Seal in AppBar
      final sealFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ArmSphereImage &&
            widget.assetPath == ArmSphereAssets.sealFed &&
            widget.width == 24 &&
            widget.height == 24 &&
            widget.semanticLabel == 'Official Federation Seal',
      );
      expect(sealFinder, findsOneWidget);

      // 2. Verify bounded avatar memory decode (cacheWidth: 80, cacheHeight: 80) in list
      final avatarFinders = find.byWidgetPredicate(
        (widget) =>
            widget is ArmSphereImage &&
            widget.width == 40 &&
            widget.height == 40 &&
            widget.cacheWidth == 80 &&
            widget.cacheHeight == 80 &&
            widget.fallbackAsset == ArmSphereAssets.defaultAvatar,
      );
      expect(avatarFinders, findsNWidgets(2));

      // 3. Verify rank numbers and competitor names
      expect(find.text('Leaderboard & Rankings'), findsOneWidget);
      expect(find.text('Hamza Iron'), findsOneWidget);
      expect(find.text('Bilal Steel'), findsOneWidget);
      expect(find.text('1950'), findsOneWidget);
      expect(find.text('1880'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  });
}
