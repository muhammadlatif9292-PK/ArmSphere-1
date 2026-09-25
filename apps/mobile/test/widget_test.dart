import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile/main.dart';
import 'package:mobile/core/providers/state_providers.dart';
import 'package:mobile/core/providers/dependency_providers.dart';
import 'package:mobile/core/providers/tournament_provider.dart';
import 'package:mobile/core/api/repositories.dart';
import 'package:mobile/core/storage/hive_storage.dart';
import 'package:mobile/core/notifications/push_notification_manager.dart';
import 'package:mobile/features/settings/screens/settings_screens.dart';
import 'package:mobile/features/venue/screens/submit_venue_screen.dart';

// Mocks
class MockHiveStorage extends Mock implements HiveStorage {}
class MockVenueRepository extends Mock implements VenueRepository {}
class MockPushNotificationManager extends Mock implements PushNotificationManager {}

void main() {
  late MockHiveStorage mockHive;
  late MockVenueRepository mockVenueRepository;

  setUpAll(() {
    registerFallbackValue(const AsyncLoading<Map<String, dynamic>?>());
  });

  setUp(() {
    mockHive = MockHiveStorage();
    mockVenueRepository = MockVenueRepository();

    // Setup standard mock behavior
    when(() => mockHive.initialize()).thenAnswer((_) async {});
    when(() => mockHive.cacheData(any(), any())).thenAnswer((_) async {});
    when(() => mockHive.getCachedData(any())).thenReturn(null);
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
        find.text('Passes you purchase for events will appear here.'),
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
      expect(find.text('VIP Front Row'), findsOneWidget);
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
}
