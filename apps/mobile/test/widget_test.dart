import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile/main.dart';
import 'package:mobile/core/providers/state_providers.dart';
import 'package:mobile/core/providers/dependency_providers.dart';
import 'package:mobile/core/providers/tournament_provider.dart';
import 'package:mobile/core/providers/biometric_provider.dart';
import 'package:mobile/core/api/repositories.dart';
import 'package:mobile/core/storage/hive_storage.dart';
import 'package:mobile/core/notifications/push_notification_manager.dart';
import 'package:mobile/core/widgets/main_shell_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/auth/screens/welcome_screen.dart';
import 'package:mobile/features/auth/screens/register_screen.dart';
import 'package:mobile/features/auth/screens/login_screen.dart';
import 'package:mobile/features/settings/screens/settings_screens.dart';
import 'package:mobile/features/settings/screens/settings_hub_screens.dart';
import 'package:mobile/features/referee/screens/referee_screens.dart';
import 'package:mobile/features/athlete/screens/athlete_screens.dart';
import 'package:mobile/features/venue/screens/submit_venue_screen.dart';

// Mocks
class MockHiveStorage extends Mock implements HiveStorage {}
class MockVenueRepository extends Mock implements VenueRepository {}
class MockTournamentRepository extends Mock implements TournamentRepository {}
class MockAthleteRepository extends Mock implements AthleteRepository {}
class MockPushNotificationManager extends Mock implements PushNotificationManager {}

void main() {
  late MockHiveStorage mockHive;
  late MockVenueRepository mockVenueRepository;
  late MockTournamentRepository mockTournamentRepository;
  late MockAthleteRepository mockAthleteRepository;

  setUpAll(() {
    registerFallbackValue(const AsyncLoading<Map<String, dynamic>?>());
  });

  setUp(() {
    mockHive = MockHiveStorage();
    mockVenueRepository = MockVenueRepository();
    mockTournamentRepository = MockTournamentRepository();
    mockAthleteRepository = MockAthleteRepository();

    // Setup standard mock behavior
    when(() => mockHive.initialize()).thenAnswer((_) async {});
    when(() => mockHive.cacheData(any(), any())).thenAnswer((_) async {});
    when(() => mockHive.getCachedData(any())).thenReturn(null);
    when(() => mockTournamentRepository.getTournaments()).thenAnswer((_) async => <Map<String, dynamic>>[]);
    when(() => mockAthleteRepository.getProfile(any())).thenAnswer((_) async => <String, dynamic>{
          'id': 'athlete_1',
          'displayName': 'Muhammad Hamad',
          'role': 'SYSTEM_ADMIN',
          'weightKg': 60,
          'heightCm': 175,
          'reachCm': 175,
          'dominantArm': 'RIGHT',
          'weightClass': 'Senior • 60kg',
          'eloRight': 1000,
          'eloLeft': 1000,
        });
  });

  group('Splash Screen Tests', () {
    testWidgets('ArmSphereApp splash screen renders correct branding', (WidgetTester tester) async {
      final mockPush = MockPushNotificationManager();
      when(() => mockPush.initialize(any())).thenAnswer((_) async {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hiveStorageProvider.overrideWithValue(mockHive),
            pushNotificationManagerProvider.overrideWithValue(mockPush),
          ],
          child: const ArmSphereApp(),
        ),
      );

      expect(find.text('ArmSphere'), findsOneWidget);
      expect(find.text('THE COMPETITIVE ARMWRESTLING ECOSYSTEM'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('MyTicketsScreen Widget Tests', () {
    testWidgets('Renders Empty State when tickets list is empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myTicketsProvider.overrideWith((ref) async => <Map<String, dynamic>>[]),
          ],
          child: const MaterialApp(
            home: MyTicketsScreen(),
          ),
        ),
      );

      // Allow the future to resolve
      await tester.pumpAndSettle();

      expect(find.text('My Tickets & Passes'), findsOneWidget);
      expect(find.text('No purchased tickets'), findsOneWidget);
      expect(
        find.text('Passes and registration tickets you purchase for tournaments and seminars will appear here.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.confirmation_number_outlined), findsOneWidget);
    });

    testWidgets('Renders Populated State when tickets are returned', (WidgetTester tester) async {
      final mockTickets = [
        {
          'id': 'ticket_1',
          'status': 'PAID',
          'confirmationCode': 'TKT-VIP-552',
          'event': {
            'name': 'East vs West Qualifiers',
            'venue': 'Sheraton Convention Hall',
            'city': 'Toronto',
            'province': 'Ontario',
          },
          'ticketType': {
            'name': 'VIP Front Row',
            'priceCents': 7500, // $75.00
          }
        }
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myTicketsProvider.overrideWith((ref) async => mockTickets),
          ],
          child: const MaterialApp(
            home: MyTicketsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('My Tickets & Passes'), findsOneWidget);
      expect(find.text('East vs West Qualifiers'), findsOneWidget);
      expect(find.text('VIP FRONT ROW'), findsOneWidget);
      expect(find.text('Toronto, Ontario'), findsOneWidget);
    });

    testWidgets('Renders Error State when future fails', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myTicketsProvider.overrideWith(
              (ref) => Future<List<Map<String, dynamic>>>.error('Network Timeout Error'),
            ),
          ],
          child: const MaterialApp(
            home: MyTicketsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('My Tickets & Passes'), findsOneWidget);
      expect(find.text('Could not load tickets'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });

  group('SubmitVenueScreen Form Validation Tests', () {
    testWidgets('Displays validation errors when submitting an empty form', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            venueRepositoryProvider.overrideWithValue(mockVenueRepository),
          ],
          child: const MaterialApp(
            home: SubmitVenueScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap submit button without filling fields
      final submitButton = find.text('Submit Facility for Certification');
      expect(submitButton, findsOneWidget);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verify that validation error messages appear
      expect(find.text('Venue name is required'), findsOneWidget);
      expect(find.text('Address is required'), findsOneWidget);

      // Verify repository submission was NOT called
      verifyNever(() => mockVenueRepository.submitVenue(
            name: any(named: 'name'),
            city: any(named: 'city'),
            province: any(named: 'province'),
            address: any(named: 'address'),
          ));
    });

    testWidgets('Calls submitVenue when form is valid', (WidgetTester tester) async {
      when(() => mockVenueRepository.submitVenue(
            name: 'Metro Armwrestling Club',
            city: '456 College St',
            province: 'UNKNOWN',
            address: '456 College St',
          )).thenAnswer((_) async => {
            'id': 'venue_823',
            'name': 'Metro Armwrestling Club',
          });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            venueRepositoryProvider.overrideWithValue(mockVenueRepository),
          ],
          child: const MaterialApp(
            home: SubmitVenueScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter valid form inputs
      await tester.enterText(
        find.byType(TextFormField).first,
        'Metro Armwrestling Club',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        '456 College St',
      );

      await tester.pumpAndSettle();

      // Tap submit
      await tester.tap(find.text('Submit Facility for Certification'));
      await tester.pump(); // Start request

      // Verify correct API invocation parameters on the mock repository
      verify(() => mockVenueRepository.submitVenue(
            name: 'Metro Armwrestling Club',
            city: '456 College St',
            province: 'UNKNOWN',
            address: '456 College St',
          )).called(1);
    });
  });

  group('Welcome & Register Navigation Tests', () {
    testWidgets(
      'WelcomeScreen omits Sanctioned Competitive Ecosystem card and navigates from Register to Sign In cleanly',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final router = GoRouter(
          initialLocation: '/welcome',
          routes: [
            GoRoute(
              path: '/welcome',
              builder: (context, state) => const WelcomeScreen(),
            ),
            GoRoute(
              path: '/register',
              builder: (context, state) => const RegisterScreen(),
            ),
            GoRoute(
              path: '/login',
              builder: (context, state) => const LoginScreen(),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // WelcomeScreen core elements are present and removed ecosystem block is absent
        expect(find.text('ENTER ARENA'), findsOneWidget);
        expect(find.text('I ALREADY HAVE AN ACCOUNT'), findsOneWidget);
        expect(find.text('SANCTIONED COMPETITIVE ECOSYSTEM'), findsNothing);
        expect(find.text('Live Bracket Battles'), findsNothing);
        expect(find.text('National Federation Rankings'), findsNothing);
        expect(find.text('Table-Side Precision Scoring'), findsNothing);

        // Tap ENTER ARENA to go to /register
        await tester.tap(find.text('ENTER ARENA'));
        await tester.pumpAndSettle();

        expect(find.text('Join ArmSphere'), findsOneWidget);
        expect(find.text('Already have an account?'), findsOneWidget);

        // Tap Sign In on RegisterScreen and verify navigation to LoginScreen (/login)
        await tester.tap(find.widgetWithText(TextButton, 'Sign In'));
        await tester.pumpAndSettle();

        expect(find.text('Sign in to your competitive account'), findsOneWidget);
        expect(find.text('Sign In to Account'), findsOneWidget);
      },
    );
  });

  group('Referee, Settings & Athlete Profile Cleanup Tests', () {
    testWidgets(
      'RefereeDashboardScreen header omits logout door icon',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              tournamentRepositoryProvider.overrideWithValue(mockTournamentRepository),
            ],
            child: const MaterialApp(
              home: RefereeDashboardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Referee Panel'), findsOneWidget);
        expect(find.byIcon(Icons.logout), findsNothing);
      },
    );

    testWidgets(
      'SettingsHubScreen omits redundant Profile row under ACCOUNT and clears bottom navigation bar for Log Out',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              biometricCapabilityProvider.overrideWith((ref) async => BiometricCapability.unsupported),
            ],
            child: const MaterialApp(
              home: MainShellScope(
                child: SettingsHubScreen(),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Redundant Profile tile is removed; Account Roles is first under ACCOUNT
        expect(find.text('View and manage your athlete profile'), findsNothing);
        expect(find.text('Account Roles'), findsOneWidget);

        // Scroll to bottom of SettingsHubScreen and verify Delete Account & Log Out are visible
        await tester.scrollUntilVisible(
          find.text('Log Out'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(find.text('Delete Account'), findsOneWidget);
        expect(find.text('Log Out'), findsOneWidget);

        final listView = tester.widget<ListView>(find.byType(ListView));
        final padding = listView.padding as EdgeInsets;
        expect(padding.bottom, greaterThanOrEqualTo(MainShellScope.kShellClearance));
      },
    );

    testWidgets(
      'AthleteProfileScreen omits Athlete Mode/Official Mode toggle and Referee & Operations Console row',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              athleteRepositoryProvider.overrideWithValue(mockAthleteRepository),
            ],
            child: const MaterialApp(
              home: MainShellScope(
                child: AthleteProfileScreen(),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Athlete Profile'), findsOneWidget);
        expect(find.text('Athlete Mode'), findsNothing);
        expect(find.text('Official Mode'), findsNothing);
        expect(find.text('Referee & Operations Console'), findsNothing);
      },
    );
  });
}
