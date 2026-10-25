import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'package:mobile/core/providers/athlete_provider.dart';
import 'package:mobile/core/providers/live_matches_provider.dart';
import 'package:mobile/core/providers/tournament_provider.dart';
import 'package:mobile/core/providers/rankings_provider.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/main_shell_screen.dart';
import 'package:mobile/features/athlete/screens/athlete_screens.dart';
import 'package:mobile/features/home/screens/discover_screen.dart';

bool _fontsLoaded = false;

Future<void> _ensureProductionFontsLoaded(WidgetTester tester) async {
  if (_fontsLoaded) return;
  await tester.runAsync(() async {
    // 1. MaterialIcons
    final materialIconsFile = File(
        r'E:\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf');
    if (materialIconsFile.existsSync()) {
      final bytes = materialIconsFile.readAsBytesSync();
      await ui.loadFontFromList(bytes, fontFamily: 'MaterialIcons');
    }

    // 2. Production Bundled Space Grotesk
    final sgFile = File('assets/fonts/SpaceGrotesk.ttf');
    if (sgFile.existsSync()) {
      final bytes = sgFile.readAsBytesSync();
      await ui.loadFontFromList(bytes, fontFamily: 'SpaceGrotesk');
      await ui.loadFontFromList(bytes, fontFamily: 'Space Grotesk');
    }

    // 3. Production Bundled Inter
    final interFile = File('assets/fonts/Inter-Regular.ttf');
    if (interFile.existsSync()) {
      final bytes = interFile.readAsBytesSync();
      await ui.loadFontFromList(bytes, fontFamily: 'Inter');
    }
  });
  _fontsLoaded = true;
}

class _DiskAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final file = File(key);
    if (file.existsSync()) {
      final bytes = file.readAsBytesSync();
      return ByteData.sublistView(Uint8List.fromList(bytes));
    }
    final mobileFile = File('apps/mobile/$key');
    if (mobileFile.existsSync()) {
      final bytes = mobileFile.readAsBytesSync();
      return ByteData.sublistView(Uint8List.fromList(bytes));
    }
    final unitTestFile = File('apps/mobile/build/unit_test_assets/$key');
    if (unitTestFile.existsSync()) {
      final bytes = unitTestFile.readAsBytesSync();
      return ByteData.sublistView(Uint8List.fromList(bytes));
    }
    return rootBundle.load(key);
  }
}

class TestAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  TestAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAthleteProfileNotifier extends AthleteProfileNotifier {
  final Map<String, dynamic> _profile;
  FakeAthleteProfileNotifier(this._profile);
  @override
  Future<Map<String, dynamic>> build() async => _profile;
}

class FakeLiveMatchesNotifier extends LiveMatchesNotifier {
  final List<Map<String, dynamic>> _matches;
  FakeLiveMatchesNotifier(this._matches);
  @override
  Future<List<Map<String, dynamic>>> build() async => _matches;
}

class FakeTournamentNotifier extends TournamentNotifier {
  final List<Map<String, dynamic>> _tournaments;
  FakeTournamentNotifier(this._tournaments);
  @override
  Future<List<Map<String, dynamic>>> build() async => _tournaments;
}

class FakeRankingsNotifier extends RankingsNotifier {
  final List<Map<String, dynamic>> _rankings;
  FakeRankingsNotifier(this._rankings);
  @override
  Future<List<Map<String, dynamic>>> build() async => _rankings;
}

/// Realistic Stage 3 Match Fixtures:
/// - Match 1: Decided Win (+24 ELO, TOPROLL, 3-0)
/// - Match 2: Decided Loss (-14 ELO, HOOK, 1-3)
/// - Match 3: Unplayed / Pending match (neutral symbol, no ELO delta tag)
/// - Match 4: Active Scheduled supermatch (triggers Live Fight Card)
final defaultStage3Matches = [
  {
    'id': 'match_win_01',
    'status': 'VERIFIED',
    'athleteAId': 'profile_1',
    'athleteAName': 'Tariq "The Titan" Malik',
    'athleteBId': 'profile_opp_01',
    'athleteBName': 'Denis Cyplenkov',
    'opponentName': 'Denis Cyplenkov',
    'arm': 'RIGHT',
    'winnerId': 'profile_1',
    'winMethod': 'TOPROLL',
    'scoreLine': '3-0',
    'eloDelta': 24,
    'verifiedAt':
        DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
  },
  {
    'id': 'match_loss_02',
    'status': 'VERIFIED',
    'athleteAId': 'profile_1',
    'athleteAName': 'Tariq "The Titan" Malik',
    'athleteBId': 'profile_opp_02',
    'athleteBName': 'Devon Larratt',
    'opponentName': 'Devon Larratt',
    'arm': 'LEFT',
    'winnerId': 'profile_opp_02',
    'winMethod': 'HOOK',
    'scoreLine': '1-3',
    'eloDelta': -14,
    'verifiedAt':
        DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
  },
  {
    'id': 'match_unplayed_03',
    'status': 'SCHEDULED',
    'athleteAId': 'profile_1',
    'athleteAName': 'Tariq "The Titan" Malik',
    'athleteBId': 'profile_opp_03',
    'athleteBName': 'John Brzenk',
    'opponentName': 'John Brzenk',
    'arm': 'RIGHT',
    'createdAt':
        DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
  },
  {
    'id': 'match_decided_04',
    'status': 'COMPLETED',
    'athleteAId': 'profile_1',
    'athleteAName': 'Tariq "The Titan" Malik',
    'athleteBId': 'profile_opp_04',
    'athleteBName': 'Genadi Kvikvinia',
    'opponentName': 'Genadi Kvikvinia',
    'arm': 'RIGHT',
    'winnerId': 'profile_1',
    'winMethod': 'PRESS',
    'scoreLine': '3-1',
    'eloDelta': 16,
    'verifiedAt':
        DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
  },
  {
    'id': 'match_live_supermatch',
    'title': 'SUPERMATCH: PRO ARMS SERIES 12',
    'scheduledTime': 'Tonight, 20:00 UTC',
    'tournamentName': 'East vs West 12',
    'tableNumber': 'Table 1',
    'athleteAId': 'profile_1',
    'athleteAName': 'Tariq "The Titan" Malik',
    'athleteBId': 'profile_opp_01',
    'athleteBName': 'Denis Cyplenkov',
    'opponentName': 'Denis Cyplenkov',
    'opponentElo': 2140,
    'arm': 'Right Arm',
    'weightClass': 'Super Heavyweight (110kg+)',
    'status': 'SCHEDULED',
  },
];

/// Realistic Stage 3 Tournaments: 3 upcoming events
final defaultStage3Tournaments = [
  {
    'id': 'tourn_01',
    'name': 'National Armwrestling Championship 2026',
    'startDate': '2026-11-14T09:00:00Z',
    'date': 'Nov 14-16, 2026',
    'city': 'Lahore',
    'venue': 'Expo Center Hall 2',
    'status': 'Registration Open',
    'registeredAthletes': 128,
  },
  {
    'id': 'tourn_02',
    'name': 'East vs West 12 Supermatch Series',
    'startDate': '2026-12-05T10:00:00Z',
    'date': 'Dec 05, 2026',
    'city': 'Istanbul',
    'venue': 'Pullman Convention Center',
    'status': 'Official Sanctioned',
    'registeredAthletes': 64,
  },
  {
    'id': 'tourn_03',
    'name': 'King of the Table 10',
    'startDate': '2027-01-22T14:00:00Z',
    'date': 'Jan 22, 2027',
    'city': 'Dubai',
    'venue': 'Space Sports Arena',
    'status': 'Upcoming',
    'registeredAthletes': 32,
  },
];

/// Realistic Stage 3 Rankings: Global Top 3
final defaultStage3Rankings = [
  {
    'rank': 1,
    'athleteName': 'John Brzenk',
    'name': 'John Brzenk',
    'displayName': 'John Brzenk',
    'clubName': 'Wasatch Arm Club',
    'club': 'Wasatch Arm Club',
    'eloRating': 2150,
    'elo': 2150,
  },
  {
    'rank': 2,
    'athleteName': 'Levan Saginashvili',
    'name': 'Levan Saginashvili',
    'displayName': 'Levan Saginashvili',
    'clubName': 'Tbilisi Warriors',
    'club': 'Tbilisi Warriors',
    'eloRating': 2145,
    'elo': 2145,
  },
  {
    'rank': 3,
    'athleteName': 'Devon Larratt',
    'name': 'Devon Larratt',
    'displayName': 'Devon Larratt',
    'clubName': 'Ottawa Arm Brawlers',
    'club': 'Ottawa Arm Brawlers',
    'eloRating': 2120,
    'elo': 2120,
  },
];

Widget _buildHarnessApp({
  required GlobalKey repaintKey,
  required double textScale,
  List<Map<String, dynamic>>? matches,
  List<Map<String, dynamic>>? tournaments,
  List<Map<String, dynamic>>? rankings,
  List<Map<String, dynamic>>? trainingLogs,
}) {
  final athleteData = {
    'id': 'profile_1',
    'displayName': 'Tariq "The Titan" Malik',
    'rank': '1',
    'rankDelta': '2',
    'weightKg': 94.5,
    'winRate': 85.0,
    'armDominance': 'Right Arm',
    'club': 'Lahore Armwrestling Club',
    'country': 'PK',
    'rightArmElo': 2150,
    'leftArmElo': 1980,
    'eloDelta': 18,
    'role': 'ATHLETE',
    'avatarUrl': 'assets/images/defaults/avatar_neutral_dark.webp',
  };

  final effectiveMatches = matches ?? defaultStage3Matches;
  final effectiveTournaments = tournaments ?? defaultStage3Tournaments;
  final effectiveRankings = rankings ?? defaultStage3Rankings;
  final effectiveTrainingLogs = trainingLogs ??
      [
        {
          'id': 'log_01',
          'date': DateTime.now()
              .subtract(const Duration(hours: 14))
              .toIso8601String(),
          'notes': 'Heavy hook training',
        },
        {
          'id': 'log_02',
          'date': DateTime.now()
              .subtract(const Duration(days: 2))
              .toIso8601String(),
          'notes': 'Top roll drills',
        },
      ];

  final prsData = [
    {'exerciseType': 'BICEP_CURL', 'weightKg': 65},
    {'exerciseType': 'WRIST_CURL', 'weightKg': 80},
    {'exerciseType': 'SIDE_PRESSURE', 'weightKg': 52},
    {'exerciseType': 'PRONATION', 'weightKg': 48},
  ];

  final router = GoRouter(
    initialLocation: '/arena',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/arena',
                builder: (context, state) => const AthleteDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/discover',
                builder: (context, state) => const DiscoverScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/events',
                builder: (context, state) =>
                    const Scaffold(body: Center(child: Text('Events'))),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/community',
                builder: (context, state) =>
                    const Scaffold(body: Center(child: Text('Community'))),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/passport',
                builder: (context, state) =>
                    const Scaffold(body: Center(child: Text('Passport'))),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authProvider.overrideWith((ref) => TestAuthNotifier(
            AuthState(
              status: AuthStatus.authenticated,
              userProfile: athleteData,
            ),
          )),
      athleteProfileProvider
          .overrideWith(() => FakeAthleteProfileNotifier(athleteData)),
      liveMatchesProvider
          .overrideWith(() => FakeLiveMatchesNotifier(effectiveMatches)),
      tournamentProvider
          .overrideWith(() => FakeTournamentNotifier(effectiveTournaments)),
      rankingsProvider
          .overrideWith(() => FakeRankingsNotifier(effectiveRankings)),
      trainingLogProvider('profile_1')
          .overrideWith((ref) async => effectiveTrainingLogs),
      trainingLogPRsProvider('profile_1').overrideWith((ref) async => prsData),
    ],
    child: DefaultAssetBundle(
      bundle: _DiskAssetBundle(),
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: RepaintBoundary(
            key: repaintKey,
            child: child!,
          ),
        ),
      ),
    ),
  );
}

final recordedOverflowErrors = <String>[];
final cropCoordinates = <String, Map<String, dynamic>>{};

Future<void> _capture({
  required WidgetTester tester,
  required double width,
  required double height,
  required double textScale,
  required double pixelRatio,
  required String outputPath,
  Finder? ensureVisibleFinder,
  int? selectTab,
  bool selectLeftArm = false,
  List<Map<String, dynamic>>? matches,
  List<Map<String, dynamic>>? tournaments,
  List<Map<String, dynamic>>? rankings,
  List<Map<String, dynamic>>? trainingLogs,
  String? cropKey,
  Finder? cropTargetFinder,
}) async {
  await _ensureProductionFontsLoaded(tester);

  tester.view.physicalSize = Size(width * pixelRatio, height * pixelRatio);
  tester.view.devicePixelRatio = pixelRatio;

  final repaintKey = GlobalKey();
  final app = _buildHarnessApp(
    repaintKey: repaintKey,
    textScale: textScale,
    matches: matches,
    tournaments: tournaments,
    rankings: rankings,
    trainingLogs: trainingLogs,
  );

  final originalOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.toString().contains('overflowed') ||
        details.toString().contains('RenderFlex')) {
      recordedOverflowErrors.add(details.toString());
      return;
    }
    originalOnError?.call(details);
  };

  try {
    await tester.pumpWidget(app);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Yield to real event loop so engine image decoder isolate decodes WebP asset bytes
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 800));
    });
    for (int i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // 1. Element-based scrolling using Scrollable.ensureVisible
    if (ensureVisibleFinder != null) {
      if (ensureVisibleFinder.evaluate().isNotEmpty) {
        await tester.ensureVisible(ensureVisibleFinder.first);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    // 2. Tab selection on Intelligence Deck
    if (selectTab != null) {
      final tabLabels = ['Recent Bouts', 'Tournaments', 'Global Top 3'];
      final tabFinder = find.text(tabLabels[selectTab]);
      if (tabFinder.evaluate().isNotEmpty) {
        await tester.ensureVisible(tabFinder.first);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(tabFinder.first);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));
      }
      // Re-ensure visibility if specified
      if (ensureVisibleFinder != null &&
          ensureVisibleFinder.evaluate().isNotEmpty) {
        await tester.ensureVisible(ensureVisibleFinder.first);
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    // 3. Arm toggling
    if (selectLeftArm) {
      final leftPill = find.text('LEFT');
      if (leftPill.evaluate().isNotEmpty) {
        await tester.tap(leftPill.first);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    // 4. Record dynamic element bounding box for crops if requested
    if (cropKey != null &&
        cropTargetFinder != null &&
        cropTargetFinder.evaluate().isNotEmpty) {
      final rect = tester.getRect(cropTargetFinder.first);
      cropCoordinates[cropKey] = {
        'x': rect.left.round(),
        'y': rect.top.round(),
        'width': rect.width.round(),
        'height': rect.height.round(),
        'textScale': textScale,
        'sourceImage': outputPath,
      };
    }

    // 5. Render and save PNG
    final boundary =
        repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      final file = File(outputPath);
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(pngBytes);

      // Also mirror to Stage 3 reviews directory
      const stage3Dir =
          r'E:\assets\claude_visual_reviews\stage3_intelligence_deck\screenshots';
      final fileName = file.uri.pathSegments.last;
      final mirrorFile = File('$stage3Dir/$fileName');
      mirrorFile.parent.createSync(recursive: true);
      mirrorFile.writeAsBytesSync(pngBytes);
    });
  } finally {
    FlutterError.onError = originalOnError;
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }
}

void main() {
  group('ArmSphere Stage 3 Intelligence Deck & Fight Card Visual Audit', () {
    const outDir =
        r'E:\assets\claude_visual_reviews\stage3_intelligence_deck\screenshots';

    setUp(() {
      recordedOverflowErrors.clear();
    });

    tearDownAll(() {
      // Write crop coordinates JSON for post-processing
      final coordFile = File(
          r'E:\assets\claude_visual_reviews\stage3_intelligence_deck\crop_coordinates.json');
      coordFile.parent.createSync(recursive: true);
      coordFile.writeAsStringSync(jsonEncode(cropCoordinates));
    });

    final fightCardFinder = find.byWidgetPredicate((w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).gradient ==
            AppTheme.upcomingMatchGradient);

    Finder getDeckContainer() => find
        .ancestor(
            of: find.byType(IntelligenceDeckTabBar),
            matching: find.byType(Container))
        .first;

    Finder getEloRail() => find.ancestor(
        of: find.text('DYNAMIC ELO'), matching: find.byType(IntrinsicHeight));

    // =========================================================================
    // SECTION 1: LIVE FIGHT CARD FULL HEIGHT (Element-Based Scrolling)
    // =========================================================================
    testWidgets('Live Fight Card - 360x740 Nominal (Element Scrolled)',
        (tester) async {
      await _capture(
        tester: tester,
        width: 360,
        height: 740,
        textScale: 1.0,
        pixelRatio: 2.0,
        outputPath: '$outDir/live_card_360x740_nominal.png',
        ensureVisibleFinder: fightCardFinder,
        cropKey: 'crop_live_card_nominal',
        cropTargetFinder: fightCardFinder,
      );
      expect(recordedOverflowErrors, isEmpty);
    });

    testWidgets('Live Fight Card - 412x915 Nominal (Full Viewport)',
        (tester) async {
      await _capture(
        tester: tester,
        width: 412,
        height: 915,
        textScale: 1.0,
        pixelRatio: 2.0,
        outputPath: '$outDir/live_card_412x915_nominal.png',
        ensureVisibleFinder: fightCardFinder,
      );
      expect(recordedOverflowErrors, isEmpty);
    });

    testWidgets(
        'Live Fight Card - 360x740 @ 1.4x Text Scale (Element Scrolled Full Card)',
        (tester) async {
      await _capture(
        tester: tester,
        width: 360,
        height: 740,
        textScale: 1.4,
        pixelRatio: 2.0,
        outputPath: '$outDir/live_card_360x740_scale1.4x.png',
        ensureVisibleFinder: fightCardFinder,
        cropKey: 'crop_live_card_scale1.4x',
        cropTargetFinder: fightCardFinder,
      );
      expect(recordedOverflowErrors, isEmpty);
    });

    testWidgets(
        'Live Fight Card - 360x740 @ 2.0x Text Scale (Element Scrolled Full Card)',
        (tester) async {
      await _capture(
        tester: tester,
        width: 360,
        height: 740,
        textScale: 2.0,
        pixelRatio: 2.0,
        outputPath: '$outDir/live_card_360x740_scale2.0x.png',
        ensureVisibleFinder: fightCardFinder,
        cropKey: 'crop_live_card_scale2.0x',
        cropTargetFinder: fightCardFinder,
      );
      expect(recordedOverflowErrors, isEmpty);
    });

    // =========================================================================
    // SECTION 2: RECOVERY STATES & ELO RAIL
    // =========================================================================
    testWidgets('Neutral Recovery State (0 logs, No Data)', (tester) async {
      await _capture(
        tester: tester,
        width: 360,
        height: 740,
        textScale: 1.0,
        pixelRatio: 2.0,
        outputPath: '$outDir/recovery_neutral_360x740.png',
        ensureVisibleFinder: find.text('COMPETITIVE STANDING'),
        trainingLogs: [], // Zero logs -> Genuine neutral state
      );
      expect(recordedOverflowErrors, isEmpty);
    });

    testWidgets('Populated Recovery State (2 logs, Today)', (tester) async {
      await _capture(
        tester: tester,
        width: 360,
        height: 740,
        textScale: 1.0,
        pixelRatio: 2.0,
        outputPath: '$outDir/recovery_populated_360x740.png',
        ensureVisibleFinder: find.text('COMPETITIVE STANDING'),
        trainingLogs: [
          {
            'id': 'log_p1',
            'date': DateTime.now()
                .subtract(const Duration(hours: 14))
                .toIso8601String(),
            'notes': 'Heavy hook training',
          },
          {
            'id': 'log_p2',
            'date': DateTime.now()
                .subtract(const Duration(days: 2))
                .toIso8601String(),
            'notes': 'Top roll drills',
          },
        ],
        cropKey: 'crop_elo_rail_right_arm',
        cropTargetFinder: getEloRail(),
      );
      expect(recordedOverflowErrors, isEmpty);
    });

    testWidgets('ELO Rail Left Arm Active', (tester) async {
      await _capture(
        tester: tester,
        width: 360,
        height: 740,
        textScale: 1.0,
        pixelRatio: 2.0,
        outputPath: '$outDir/candidate_360x740_left_arm_active.png',
        ensureVisibleFinder: find.text('COMPETITIVE STANDING'),
        selectLeftArm: true,
        cropKey: 'crop_elo_rail_left_arm',
        cropTargetFinder: getEloRail(),
      );
      expect(recordedOverflowErrors, isEmpty);
    });

    // =========================================================================
    // SECTION 3: INTELLIGENCE DECK TAB 0 (Recent Bouts Populated)
    // =========================================================================
    testWidgets('Deck - Recent Bouts 360x740 Nominal', (tester) async {
      await _capture(
        tester: tester,
        width: 360,
        height: 740,
        textScale: 1.0,
        pixelRatio: 2.0,
        outputPath: '$outDir/deck_recent_bouts_360x740_nominal.png',
        selectTab: 0,
        ensureVisibleFinder: getDeckContainer(),
        cropKey: 'crop_deck_recent_bouts_nominal',
        cropTargetFinder: getDeckContainer(),
      );
      expect(recordedOverflowErrors, isEmpty);
    });

    testWidgets('Deck - Recent Bouts 412x915 Nominal', (tester) async {
      await _capture(
        tester: tester,
        width: 412,
        height: 915,
        textScale: 1.0,
        pixelRatio: 2.0,
        outputPath: '$outDir/deck_recent_bouts_412x915_nominal.png',
        selectTab: 0,
        ensureVisibleFinder: getDeckContainer(),
      );
      expect(recordedOverflowErrors, isEmpty);
    });

    testWidgets('Deck - Recent Bouts 360x740 @ 1.4x Text Scale',
        (tester) async {
      await _capture(
        tester: tester,
        width: 360,
        height: 740,
        textScale: 1.4,
        pixelRatio: 2.0,
        outputPath: '$outDir/deck_recent_bouts_360x740_scale1.4x.png',
        selectTab: 0,
        ensureVisibleFinder: getDeckContainer(),
      );
      expect(recordedOverflowErrors, isEmpty);
    });

    testWidgets('Deck - Recent Bouts 360x740 @ 2.0x Text Scale',
        (tester) async {
      await _capture(
        tester: tester,
        width: 360,
        height: 740,
        textScale: 2.0,
        pixelRatio: 2.0,
        outputPath: '$outDir/deck_recent_bouts_360x740_scale2.0x.png',
        selectTab: 0,
        ensureVisibleFinder: getDeckContainer(),
      );
      expect(recordedOverflowErrors, isEmpty);
    });

    // =========================================================================
    // SECTION 4: INTELLIGENCE DECK TAB 1 (Tournaments Populated)
    // =========================================================================
    testWidgets('Deck - Tournaments 360x740 Nominal', (tester) async {
      await _capture(
        tester: tester,
        width: 360,
        height: 740,
        textScale: 1.0,
        pixelRatio: 2.0,
        outputPath: '$outDir/deck_tournaments_360x740_nominal.png',
        selectTab: 1,
        ensureVisibleFinder: getDeckContainer(),
        cropKey: 'crop_deck_tournaments_nominal',
        cropTargetFinder: getDeckContainer(),
      );
      expect(recordedOverflowErrors, isEmpty);
    });

    testWidgets('Deck - Tournaments 412x915 Nominal', (tester) async {
      await _capture(
        tester: tester,
        width: 412,
        height: 915,
        textScale: 1.0,
        pixelRatio: 2.0,
        outputPath: '$outDir/deck_tournaments_412x915_nominal.png',
        selectTab: 1,
        ensureVisibleFinder: getDeckContainer(),
      );
      expect(recordedOverflowErrors, isEmpty);
    });

    testWidgets('Deck - Tournaments 360x740 @ 1.4x Text Scale', (tester) async {
      await _capture(
        tester: tester,
        width: 360,
        height: 740,
        textScale: 1.4,
        pixelRatio: 2.0,
        outputPath: '$outDir/deck_tournaments_360x740_scale1.4x.png',
        selectTab: 1,
        ensureVisibleFinder: getDeckContainer(),
      );
      expect(recordedOverflowErrors, isEmpty);
    });

    testWidgets('Deck - Tournaments 360x740 @ 2.0x Text Scale', (tester) async {
      await _capture(
        tester: tester,
        width: 360,
        height: 740,
        textScale: 2.0,
        pixelRatio: 2.0,
        outputPath: '$outDir/deck_tournaments_360x740_scale2.0x.png',
        selectTab: 1,
        ensureVisibleFinder: getDeckContainer(),
      );
      expect(recordedOverflowErrors, isEmpty);
    });

    // =========================================================================
    // SECTION 5: INTELLIGENCE DECK TAB 2 (Global Top 3 Populated)
    // =========================================================================
    testWidgets('Deck - Rankings 360x740 Nominal', (tester) async {
      await _capture(
        tester: tester,
        width: 360,
        height: 740,
        textScale: 1.0,
        pixelRatio: 2.0,
        outputPath: '$outDir/deck_rankings_360x740_nominal.png',
        selectTab: 2,
        ensureVisibleFinder: getDeckContainer(),
        cropKey: 'crop_deck_rankings_nominal',
        cropTargetFinder: getDeckContainer(),
      );
      expect(recordedOverflowErrors, isEmpty);
    });

    testWidgets('Deck - Rankings 412x915 Nominal', (tester) async {
      await _capture(
        tester: tester,
        width: 412,
        height: 915,
        textScale: 1.0,
        pixelRatio: 2.0,
        outputPath: '$outDir/deck_rankings_412x915_nominal.png',
        selectTab: 2,
        ensureVisibleFinder: getDeckContainer(),
      );
      expect(recordedOverflowErrors, isEmpty);
    });

    testWidgets('Deck - Rankings 360x740 @ 1.4x Text Scale', (tester) async {
      await _capture(
        tester: tester,
        width: 360,
        height: 740,
        textScale: 1.4,
        pixelRatio: 2.0,
        outputPath: '$outDir/deck_rankings_360x740_scale1.4x.png',
        selectTab: 2,
        ensureVisibleFinder: getDeckContainer(),
      );
      expect(recordedOverflowErrors, isEmpty);
    });

    testWidgets('Deck - Rankings 360x740 @ 2.0x Text Scale', (tester) async {
      await _capture(
        tester: tester,
        width: 360,
        height: 740,
        textScale: 2.0,
        pixelRatio: 2.0,
        outputPath: '$outDir/deck_rankings_360x740_scale2.0x.png',
        selectTab: 2,
        ensureVisibleFinder: getDeckContainer(),
      );
      expect(recordedOverflowErrors, isEmpty);
    });

    // =========================================================================
    // SECTION 6: INTELLIGENCE DECK EMPTY STATES
    // =========================================================================
    testWidgets('Deck Empty State - Recent Bouts', (tester) async {
      await _capture(
        tester: tester,
        width: 360,
        height: 740,
        textScale: 1.0,
        pixelRatio: 2.0,
        outputPath: '$outDir/deck_empty_recent_bouts.png',
        matches: [], // Empty matches
        selectTab: 0,
        ensureVisibleFinder: getDeckContainer(),
      );
      expect(recordedOverflowErrors, isEmpty);
    });

    testWidgets('Deck Empty State - Tournaments', (tester) async {
      await _capture(
        tester: tester,
        width: 360,
        height: 740,
        textScale: 1.0,
        pixelRatio: 2.0,
        outputPath: '$outDir/deck_empty_tournaments.png',
        tournaments: [], // Empty tournaments
        selectTab: 1,
        ensureVisibleFinder: getDeckContainer(),
      );
      expect(recordedOverflowErrors, isEmpty);
    });

    testWidgets('Deck Empty State - Global Top 3', (tester) async {
      await _capture(
        tester: tester,
        width: 360,
        height: 740,
        textScale: 1.0,
        pixelRatio: 2.0,
        outputPath: '$outDir/deck_empty_rankings.png',
        rankings: [], // Empty rankings
        selectTab: 2,
        ensureVisibleFinder: getDeckContainer(),
      );
      expect(recordedOverflowErrors, isEmpty);
    });
  });
}
