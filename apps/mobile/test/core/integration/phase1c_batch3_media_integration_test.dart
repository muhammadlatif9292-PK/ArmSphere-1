import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/constants/asset_paths.dart';
import 'package:mobile/core/widgets/armsphere_image.dart';
import 'package:mobile/features/tournament/screens/tournament_screens.dart';
import 'package:mobile/features/match/screens/head_to_head_screen.dart';
import 'package:mobile/core/providers/tournament_provider.dart';
import 'package:mobile/core/providers/state_providers.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 1C Batch 3: Competition Identity Media Integration Tests', () {
    testWidgets('TournamentDetailScreen renders hero banner and sanctioning seal via ArmSphereImage',
        (WidgetTester tester) async {
      const tourneyId = 'tourney_test_1';
      final mockTournament = {
        'id': tourneyId,
        'name': 'National Armwrestling Championship 2026',
        'status': 'PUBLISHED',
        'startDate': '2026-10-15T09:00:00Z',
        'endDate': '2026-10-17T18:00:00Z',
        'venueName': 'Liaquat Gymnasium',
        'city': 'Islamabad',
        'province': 'Federal Capital',
        'registrationFeeCents': 250000,
        'capacity': 128,
        'registeredCount': 84,
        'imageUrl': null,
        'description': 'The premier national armwrestling showdown.',
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(
                  AuthState(
                    status: AuthStatus.authenticated,
                    userProfile: {
                      'id': 'usr_athlete_1',
                      'role': 'ATHLETE',
                    },
                  ),
                )),
            eventDetailProvider(tourneyId).overrideWith((ref) async => mockTournament),
          ],
          child: const MaterialApp(
            home: TournamentDetailScreen(tournamentId: tourneyId),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Verify Hero Banner renders ArmSphereImage with defaultTournament fallback
      final heroImageFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ArmSphereImage &&
            widget.fallbackAsset == ArmSphereAssets.defaultTournament &&
            widget.fit == BoxFit.cover &&
            widget.semanticLabel == 'Tournament banner for National Armwrestling Championship 2026',
      );
      expect(heroImageFinder, findsOneWidget);

      // 2. Verify Sanctioning metric renders ArmSphereImage with sealFed
      final sanctioningSealFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ArmSphereImage &&
            widget.assetPath == ArmSphereAssets.sealFed &&
            widget.width == 14 &&
            widget.height == 14 &&
            widget.semanticLabel == 'Sanctioning official seal',
      );
      expect(sanctioningSealFinder, findsOneWidget);

      // 3. Verify real tournament data preservation
      expect(find.text('National Armwrestling Championship 2026'), findsWidgets);
      expect(find.text('IFA / WAF Certified'), findsOneWidget);
      expect(find.text('84 / 128 Athletes'), findsOneWidget);
      expect(find.text('PKR 2,500'), findsOneWidget);
      expect(find.text('Liaquat Gymnasium, Islamabad, Federal Capital'), findsOneWidget);

      // Clean teardown
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('TournamentDetailScreen preserves error state on load failure', (WidgetTester tester) async {
      const tourneyId = 'tourney_error_1';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(
                  AuthState(status: AuthStatus.unauthenticated),
                )),
            eventDetailProvider(tourneyId).overrideWith((ref) async => throw Exception('Network timeout')),
          ],
          child: const MaterialApp(
            home: TournamentDetailScreen(tournamentId: tourneyId),
          ),
        ),
      );

      await tester.pump();

      // Verify error UI is displayed without crashing
      expect(find.text('Could not load tournament'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Clean teardown
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('HeadToHeadScreen renders federation seal and corner avatars via ArmSphereImage',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(
                  AuthState(status: AuthStatus.authenticated),
                )),
          ],
          child: const MaterialApp(
            home: HeadToHeadScreen(),
          ),
        ),
      );

      // Advance walkout sequence
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // 1. Verify AppBar title renders ArmSphereImage with sealFed
      final appBarSealFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ArmSphereImage &&
            widget.assetPath == ArmSphereAssets.sealFed &&
            widget.width == 16 &&
            widget.height == 16 &&
            widget.semanticLabel == 'Official Federation Sanctioned Match',
      );
      expect(appBarSealFinder, findsOneWidget);
      expect(find.text('TALE OF THE TAPE'), findsOneWidget);

      // 2. Verify Red Corner avatar uses ArmSphereImage.avatar with defaultAvatar fallback
      final redAvatarFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ArmSphereImage &&
            widget.width == 52 &&
            widget.height == 52 &&
            widget.fallbackAsset == ArmSphereAssets.defaultAvatar &&
            widget.semanticLabel == 'Red corner competitor avatar for Hamza "The Hammer" Khan',
      );
      expect(redAvatarFinder, findsOneWidget);

      // 3. Verify Blue Corner avatar uses ArmSphereImage.avatar with defaultAvatar fallback
      final blueAvatarFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ArmSphereImage &&
            widget.width == 52 &&
            widget.height == 52 &&
            widget.fallbackAsset == ArmSphereAssets.defaultAvatar &&
            widget.semanticLabel == 'Blue corner competitor avatar for Tariq "Iron Grip" Malik',
      );
      expect(blueAvatarFinder, findsOneWidget);

      // 4. Verify competitor names and ELO figures are preserved
      expect(find.text('Hamza "The Hammer" Khan'), findsOneWidget);
      expect(find.text('Tariq "Iron Grip" Malik'), findsOneWidget);
      expect(find.text('1945 ELO'), findsOneWidget);
      expect(find.text('1885 ELO'), findsOneWidget);

      // Clean teardown
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('HeadToHeadScreen renders dynamic competitor comparison with custom avatars',
        (WidgetTester tester) async {
      const id1 = 'ath_dyn_1';
      const id2 = 'ath_dyn_2';

      final mockComparison = {
        'athlete1': {
          'id': id1,
          'displayName': 'Rashid "The Bull" Qureshi',
          'clubName': 'Karachi Pullers',
          'province': 'Sindh',
          'weightClass': '-95 KG',
          'avatarUrl': 'https://storage.armsphere.com/avatars/rashid.jpg',
          'eloRating': 2010,
          'dominantArm': 'RIGHT',
          'measurements': {
            'forearmCircumference': 44.0,
            'bicepCircumference': 47.0,
            'handSpan': 23.0,
          },
          'reachCm': 186.0,
          'weightKg': 94.2,
        },
        'athlete2': {
          'id': id2,
          'displayName': 'Bilal "The Anvil" Butt',
          'clubName': 'Gujranwala Giants',
          'province': 'Punjab',
          'weightClass': '-95 KG',
          'avatarUrl': 'https://storage.armsphere.com/avatars/bilal.jpg',
          'eloRating': 1990,
          'dominantArm': 'LEFT',
          'measurements': {
            'forearmCircumference': 43.5,
            'bicepCircumference': 46.5,
            'handSpan': 22.5,
          },
          'reachCm': 184.0,
          'weightKg': 93.8,
        },
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(
                  AuthState(status: AuthStatus.authenticated),
                )),
            athleteComparisonProvider((athlete1Id: id1, athlete2Id: id2)).overrideWith((ref) async => mockComparison),
          ],
          child: const MaterialApp(
            home: HeadToHeadScreen(
              athleteId1: id1,
              athleteId2: id2,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // 1. Verify Red Corner dynamic avatar
      final redDynFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ArmSphereImage &&
            widget.imageUrl == 'https://storage.armsphere.com/avatars/rashid.jpg' &&
            widget.width == 52 &&
            widget.semanticLabel == 'Red corner competitor avatar for Rashid "The Bull" Qureshi',
      );
      expect(redDynFinder, findsOneWidget);

      // 2. Verify Blue Corner dynamic avatar
      final blueDynFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ArmSphereImage &&
            widget.imageUrl == 'https://storage.armsphere.com/avatars/bilal.jpg' &&
            widget.width == 52 &&
            widget.semanticLabel == 'Blue corner competitor avatar for Bilal "The Anvil" Butt',
      );
      expect(blueDynFinder, findsOneWidget);

      // 3. Verify competitor identities & ELO
      expect(find.text('Rashid "The Bull" Qureshi'), findsOneWidget);
      expect(find.text('Bilal "The Anvil" Butt'), findsOneWidget);
      expect(find.text('2010 ELO'), findsOneWidget);
      expect(find.text('1990 ELO'), findsOneWidget);

      // Clean teardown
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  });
}
