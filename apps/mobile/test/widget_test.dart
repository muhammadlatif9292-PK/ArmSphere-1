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
import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'package:mobile/features/settings/screens/settings_screens.dart';
import 'package:mobile/features/venue/screens/submit_venue_screen.dart';

// Mocks
class MockHiveStorage extends Mock implements HiveStorage {}
class MockVenueRepository extends Mock implements VenueRepository {}

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
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hiveStorageProvider.overrideWithValue(mockHive),
          ],
          child: const ArmSphereApp(),
        ),
      );

      expect(find.text('ARM SPHERE'), findsOneWidget);
      expect(find.text('Competitive Armwrestling Network'), findsOneWidget);
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

      expect(find.text('My Tickets'), findsOneWidget);
      expect(find.text('No tickets purchased yet'), findsOneWidget);
      expect(
        find.text('Spectator passes purchased for upcoming events will appear here.'),
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

      expect(find.text('My Tickets'), findsOneWidget);
      expect(find.text('East vs West Qualifiers'), findsOneWidget);
      expect(find.text('PAID'), findsOneWidget);
      expect(find.text('\$75.00'), findsOneWidget);
      expect(find.text('TKT-VIP-552'), findsOneWidget);
      expect(find.text('VIP Front Row'), findsOneWidget);
      expect(find.text('Sheraton Convention Hall (Toronto, Ontario)'), findsOneWidget);
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

      expect(find.text('My Tickets'), findsOneWidget);
      expect(find.text('Failed to load tickets: Network Timeout Error'), findsOneWidget);
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
      final submitButton = find.text('Submit Venue');
      expect(submitButton, findsOneWidget);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verify that validation error messages appear
      expect(find.text('Please enter the venue name'), findsOneWidget);
      expect(find.text('Please enter the street address'), findsOneWidget);
      expect(find.text('Please enter the city'), findsOneWidget);

      // Verify repository submission was NOT called
      verifyNever(() => mockVenueRepository.submitVenue(
            name: any(named: 'name'),
            city: any(named: 'city'),
            province: any(named: 'province'),
            address: any(named: 'address'),
            contactInfo: any(named: 'contactInfo'),
            description: any(named: 'description'),
            logoUrl: any(named: 'logoUrl'),
          ));
    });

    testWidgets('Calls submitVenue when form is valid', (WidgetTester tester) async {
      when(() => mockVenueRepository.submitVenue(
            name: 'Metro Armwrestling Club',
            city: 'Toronto',
            province: 'Ontario',
            address: '456 College St',
            contactInfo: 'contact@metroarm.ca',
            description: 'Weekly practice on Thursdays at 7pm.',
            logoUrl: 'https://metroarm.ca/logo.png',
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
        find.widgetWithText(TextFormField, 'e.g. Iron Grip Athletics'),
        'Metro Armwrestling Club',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'e.g. 123 Main St W'),
        '456 College St',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'e.g. Toronto'),
        'Toronto',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'e.g. info@irongrip.com or (416) 555-0199'),
        'contact@metroarm.ca',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'e.g. https://example.com/logo.png'),
        'https://metroarm.ca/logo.png',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Describe the armwrestling table equipment, times they meet, fees...'),
        'Weekly practice on Thursdays at 7pm.',
      );

      await tester.pumpAndSettle();

      // Tap submit
      await tester.tap(find.text('Submit Venue'));
      await tester.pump(); // Start request

      // Verify correct API invocation parameters on the mock repository
      verify(() => mockVenueRepository.submitVenue(
            name: 'Metro Armwrestling Club',
            city: 'Toronto',
            province: 'Ontario',
            address: '456 College St',
            contactInfo: 'contact@metroarm.ca',
            description: 'Weekly practice on Thursdays at 7pm.',
            logoUrl: 'https://metroarm.ca/logo.png',
          )).called(1);
    });
  });
}
