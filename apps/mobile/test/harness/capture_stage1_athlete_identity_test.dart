import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
    final materialIconsFile =
        File(r'E:\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf');
    if (materialIconsFile.existsSync()) {
      final bytes = materialIconsFile.readAsBytesSync();
      await ui.loadFontFromList(bytes, fontFamily: 'MaterialIcons');
    }

    final sgFile = File('assets/fonts/SpaceGrotesk.ttf');
    if (sgFile.existsSync()) {
      final bytes = sgFile.readAsBytesSync();
      await ui.loadFontFromList(bytes, fontFamily: 'SpaceGrotesk');
      await ui.loadFontFromList(bytes, fontFamily: 'Space Grotesk');
    }

    final interFile = File('assets/fonts/Inter-Regular.ttf');
    if (interFile.existsSync()) {
      final bytes = interFile.readAsBytesSync();
      await ui.loadFontFromList(bytes, fontFamily: 'Inter');
    }
  });
  _fontsLoaded = true;
}

class TestAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
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
  @override
  Future<List<Map<String, dynamic>>> build() async => [
        {
          'id': 'match_101',
          'title': 'SUPERMATCH: PRO ARMS SERIES 12',
          'scheduledTime': 'Tonight, 20:00 UTC',
          'opponentName': 'Denis Cyplenkov',
          'opponentElo': 2140,
          'arm': 'Right Arm',
          'weightClass': 'Super Heavyweight (110kg+)',
          'status': 'CONFIRMED',
        }
      ];
}

class FakeTournamentNotifier extends TournamentNotifier {
  @override
  Future<List<Map<String, dynamic>>> build() async => [
        {
          'id': 'tourn_01',
          'name': 'National Armwrestling Championship 2026',
          'date': 'Nov 14-16, 2026',
          'location': 'Lahore Expo Center',
          'status': 'Registration Open',
          'registeredAthletes': 128,
        }
      ];
}

class FakeRankingsNotifier extends RankingsNotifier {
  @override
  Future<List<Map<String, dynamic>>> build() async => [
        {'rank': 1, 'name': 'John Brzenk', 'elo': 2150, 'country': 'USA'},
        {'rank': 2, 'name': 'Levan Saginashvili', 'elo': 2145, 'country': 'GEO'},
        {'rank': 3, 'name': 'Devon Larratt', 'elo': 2120, 'country': 'CAN'},
      ];
}

Widget _buildHarnessApp({
  required GlobalKey repaintKey,
  required double textScale,
  List<Map<String, dynamic>> trainingLogs = const [],
}) {
  final athleteData = {
    'id': 'athlete_test_01',
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
  };

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
      liveMatchesProvider.overrideWith(() => FakeLiveMatchesNotifier()),
      tournamentProvider.overrideWith(() => FakeTournamentNotifier()),
      rankingsProvider.overrideWith(() => FakeRankingsNotifier()),
      trainingLogProvider('athlete_test_01')
          .overrideWith((ref) async => trainingLogs),
      trainingLogPRsProvider('athlete_test_01')
          .overrideWith((ref) async => prsData),
    ],
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
  );
}

final recordedOverflowErrors = <String>[];

Future<void> _capture({
  required WidgetTester tester,
  required double width,
  required double height,
  required double textScale,
  required double pixelRatio,
  required String outputPath,
}) async {
  await _ensureProductionFontsLoaded(tester);

  tester.view.physicalSize = Size(width * pixelRatio, height * pixelRatio);
  tester.view.devicePixelRatio = pixelRatio;

  final repaintKey = GlobalKey();
  final app = _buildHarnessApp(
    repaintKey: repaintKey,
    textScale: textScale,
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
    // Use short pump durations to accommodate active animated widgets
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final boundary = repaintKey.currentContext!.findRenderObject()
        as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      final file = File(outputPath);
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(pngBytes);
    });
  } finally {
    FlutterError.onError = originalOnError;
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }
}

void main() {
  group('Stage 1 Athlete Identity Renderer', () {
    const outDir =
        r'E:\assets\claude_visual_reviews\stage1_athlete_identity\screenshots';

    setUp(() {
      recordedOverflowErrors.clear();
    });

    testWidgets('Capture 360x740 Phone - Candidate Nominal', (tester) async {
      await _capture(
        tester: tester,
        width: 360,
        height: 740,
        textScale: 1.0,
        pixelRatio: 2.0,
        outputPath: '$outDir/candidate_360x740_nominal.png',
      );
      expect(recordedOverflowErrors, isEmpty,
          reason: 'No RenderFlex overflow on 360dp nominal');
    });

    testWidgets('Capture 412x915 Large Phone - Candidate Nominal', (tester) async {
      await _capture(
        tester: tester,
        width: 412,
        height: 915,
        textScale: 1.0,
        pixelRatio: 2.0,
        outputPath: '$outDir/candidate_412x915_nominal.png',
      );
      expect(recordedOverflowErrors, isEmpty,
          reason: 'No RenderFlex overflow on 412dp nominal');
    });

    testWidgets('Capture 360x740 Phone @ 1.4x Text Scale - Candidate', (tester) async {
      await _capture(
        tester: tester,
        width: 360,
        height: 740,
        textScale: 1.4,
        pixelRatio: 2.0,
        outputPath: '$outDir/candidate_360x740_scale1.4x.png',
      );
      expect(recordedOverflowErrors, isEmpty,
          reason: 'No RenderFlex overflow on 360dp at 1.4x text scale');
    });
  });
}
