import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:mobile/core/api/dio_client.dart';
import 'package:mobile/core/storage/hive_storage.dart';
import 'package:mobile/core/api/repositories.dart';

// Mock Classes
class MockDioClient extends Mock implements DioClient {}
class MockDio extends Mock implements Dio {}
class MockHiveStorage extends Mock implements HiveStorage {}
class MockCancelToken extends Mock implements CancelToken {}

void main() {
  late MockDioClient mockDioClient;
  late MockDio mockDio;
  late MockHiveStorage mockHiveStorage;

  setUpAll(() {
    registerFallbackValue(MockCancelToken());
  });

  setUp(() {
    mockDioClient = MockDioClient();
    mockDio = MockDio();
    mockHiveStorage = MockHiveStorage();

    // Link the mock Dio instance to the mock DioClient
    when(() => mockDioClient.dio).thenReturn(mockDio);

    // Stub caching operations to prevent NullPointer/un-stubbed errors
    when(() => mockHiveStorage.cacheData(any(), any())).thenAnswer((_) async {});
    when(() => mockHiveStorage.getCachedData(any())).thenReturn(null);
  });

  group('MessagingRepository Unit Tests', () {
    test('getConversations handles successful API response and parses conversations', () async {
      final repository = MessagingRepository(
        dioClient: mockDioClient,
        hiveStorage: mockHiveStorage,
      );

      final apiPayload = {
        'data': [
          {
            'id': 'conv_1',
            'type': 'DIRECT',
            'lastMessage': 'See you at the practice!',
            'updatedAt': '2026-07-20T20:00:00.000Z',
          },
          {
            'id': 'conv_2',
            'type': 'DIRECT',
            'lastMessage': 'Are we pullin right or left arm first?',
            'updatedAt': '2026-07-20T21:00:00.000Z',
          }
        ]
      };

      // Mock the GET request to conversations endpoint
      when(() => mockDio.get(
            '/communication/conversations',
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/communication/conversations'),
            statusCode: 200,
            data: apiPayload,
          ));

      final conversations = await repository.getConversations();

      expect(conversations, isNotEmpty);
      expect(conversations.length, equals(2));
      expect(conversations[0]['id'], equals('conv_1'));
      expect(conversations[1]['lastMessage'], equals('Are we pullin right or left arm first?'));

      // Verify the cached copy was saved
      verify(() => mockHiveStorage.cacheData('local_conversations_list', apiPayload)).called(1);
      
      // Verify correct API endpoint was hit
      verify(() => mockDio.get(
            '/communication/conversations',
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
    });
  });

  group('AthleteRepository Unit Tests', () {
    test('updateVisibility patches correct visibility details and returns parsed profile', () async {
      final repository = AthleteRepository(
        dioClient: mockDioClient,
        hiveStorage: mockHiveStorage,
      );

      final profilePayload = {
        'data': {
          'id': 'athlete_84',
          'displayName': 'Lachlan Adair',
          'profileVisibility': 'PRIVATE',
          'isSearchable': false,
        }
      };

      // Mock the PATCH request for me/visibility endpoint
      when(() => mockDio.patch(
            '/athletes/me/visibility',
            data: {
              'profileVisibility': 'PRIVATE',
              'isSearchable': false,
            },
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/athletes/me/visibility'),
            statusCode: 200,
            data: profilePayload,
          ));

      final updatedProfile = await repository.updateVisibility('PRIVATE', false);

      expect(updatedProfile, isNotNull);
      expect(updatedProfile['id'], equals('athlete_84'));
      expect(updatedProfile['profileVisibility'], equals('PRIVATE'));
      expect(updatedProfile['isSearchable'], isFalse);

      // Verify profile is cached locally
      verify(() => mockHiveStorage.cacheData('athlete_profile_self', profilePayload['data'])).called(1);

      // Verify API invocation parameters
      verify(() => mockDio.patch(
            '/athletes/me/visibility',
            data: {
              'profileVisibility': 'PRIVATE',
              'isSearchable': false,
            },
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
    });
  });

  group('TournamentRepository Unit Tests', () {
    test('confirmManualPayment posts and returns confirmation data', () async {
      final repository = TournamentRepository(
        dioClient: mockDioClient,
        hiveStorage: mockHiveStorage,
      );

      final manualPaymentPayload = {
        'id': 'reg_382',
        'eventId': 'event_72',
        'status': 'CONFIRMED',
        'paymentType': 'MANUAL',
        'confirmedAt': '2026-07-20T21:15:00.000Z',
      };

      // Mock manual payment confirmation post request
      when(() => mockDio.post(
            '/tournaments/registrations/reg_382/confirm-manual-payment',
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(
              path: '/tournaments/registrations/reg_382/confirm-manual-payment',
            ),
            statusCode: 200,
            data: manualPaymentPayload,
          ));

      final result = await repository.confirmManualPayment(registrationId: 'reg_382');

      expect(result, isNotNull);
      expect(result['id'], equals('reg_382'));
      expect(result['status'], equals('CONFIRMED'));
      expect(result['paymentType'], equals('MANUAL'));

      // Verify local caching for the registration status
      verify(() => mockHiveStorage.cacheData(
            'confirm_manual_payment_reg_382',
            manualPaymentPayload,
          )).called(1);

      // Verify API endpoint details
      verify(() => mockDio.post(
            '/tournaments/registrations/reg_382/confirm-manual-payment',
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
    });
  });
}
