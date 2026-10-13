import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:mobile/core/api/dio_client.dart';
import 'package:mobile/core/storage/hive_storage.dart';
import 'package:mobile/core/storage/secure_storage.dart';
import 'package:mobile/core/api/repositories.dart';

// Mock Classes
class MockDioClient extends Mock implements DioClient {}
class MockDio extends Mock implements Dio {}
class MockHiveStorage extends Mock implements HiveStorage {}
class MockSecureStorage extends Mock implements SecureStorage {}
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

      final cancelToken = MockCancelToken();
      final conversations = await repository.getConversations(cancelToken: cancelToken);

      expect(conversations, isNotEmpty);
      expect(conversations.length, equals(2));
      expect(conversations[0]['id'], equals('conv_1'));
      expect(conversations[1]['lastMessage'], equals('Are we pullin right or left arm first?'));

      // Verify the cached copy was saved
      verify(() => mockHiveStorage.cacheData('local_conversations_list', apiPayload)).called(1);
      
      // Verify correct API endpoint was hit
      verify(() => mockDio.get(
            '/communication/conversations',
            cancelToken: cancelToken,
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

      final cancelToken = MockCancelToken();
      final updatedProfile = await repository.updateVisibility('PRIVATE', false, cancelToken: cancelToken);

      expect(updatedProfile, isNotNull);
      expect(updatedProfile['id'], equals('athlete_84'));
      expect(updatedProfile['profileVisibility'], equals('PRIVATE'));
      expect(updatedProfile['isSearchable'], isFalse);

      // Verify profile is cached locally
      verify(() => mockHiveStorage.cacheData('athlete_profile_self', profilePayload)).called(1);

      // Verify API invocation parameters
      verify(() => mockDio.patch(
            '/athletes/me/visibility',
            data: {
              'profileVisibility': 'PRIVATE',
              'isSearchable': false,
            },
            cancelToken: cancelToken,
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

      final cancelToken = MockCancelToken();
      final result = await repository.confirmManualPayment(registrationId: 'reg_382', cancelToken: cancelToken);

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
            cancelToken: cancelToken,
          )).called(1);
    });

    test('publishEvent, completeEvent, and cancelEvent post to canonical event lifecycle endpoints', () async {
      final repository = TournamentRepository(
        dioClient: mockDioClient,
        hiveStorage: mockHiveStorage,
      );

      when(() => mockDio.post(
            '/tournaments/events/evt_10/publish',
            data: any(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/tournaments/events/evt_10/publish'),
            statusCode: 200,
            data: {'id': 'evt_10', 'status': 'PUBLISHED'},
          ));

      when(() => mockDio.post(
            '/tournaments/events/evt_10/complete',
            data: any(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/tournaments/events/evt_10/complete'),
            statusCode: 200,
            data: {'id': 'evt_10', 'status': 'COMPLETED'},
          ));

      when(() => mockDio.post(
            '/tournaments/events/evt_10/cancel',
            data: any(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/tournaments/events/evt_10/cancel'),
            statusCode: 200,
            data: {'id': 'evt_10', 'status': 'CANCELLED'},
          ));

      final published = await repository.publishEvent('evt_10');
      expect(published['status'], equals('PUBLISHED'));

      final completed = await repository.completeEvent('evt_10');
      expect(completed['status'], equals('COMPLETED'));

      final cancelled = await repository.cancelEvent('evt_10', reason: 'Venue flooding');
      expect(cancelled['status'], equals('CANCELLED'));
    });
  });

  group('AuthRepository Unit Tests', () {
    test('logout posts to /auth/logout and clears secureStorage and hiveCache', () async {
      final mockSecureStorage = MockSecureStorage();
      when(() => mockDioClient.secureStorage).thenReturn(mockSecureStorage);
      when(() => mockDio.post('/auth/logout', cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/auth/logout'),
                statusCode: 200,
              ));
      when(() => mockSecureStorage.clearSession()).thenAnswer((_) async {});
      when(() => mockHiveStorage.evictCache(any())).thenAnswer((_) async {});

      final repository = AuthRepository(
        dioClient: mockDioClient,
        hiveStorage: mockHiveStorage,
      );

      await repository.logout();

      verify(() => mockDio.post('/auth/logout', cancelToken: any(named: 'cancelToken'))).called(1);
      verify(() => mockSecureStorage.clearSession()).called(1);
      verify(() => mockHiveStorage.evictCache('auth_session_user')).called(1);
      verify(() => mockHiveStorage.evictCache('auth_role_intent')).called(1);
    });

    test('logout clears secureStorage and hiveCache even if server call throws', () async {
      final mockSecureStorage = MockSecureStorage();
      when(() => mockDioClient.secureStorage).thenReturn(mockSecureStorage);
      when(() => mockDio.post('/auth/logout', cancelToken: any(named: 'cancelToken')))
          .thenThrow(DioException(
            requestOptions: RequestOptions(path: '/auth/logout'),
            type: DioExceptionType.connectionError,
          ));
      when(() => mockSecureStorage.clearSession()).thenAnswer((_) async {});
      when(() => mockHiveStorage.evictCache(any())).thenAnswer((_) async {});

      final repository = AuthRepository(
        dioClient: mockDioClient,
        hiveStorage: mockHiveStorage,
      );

      // Should complete cleanly without throwing unhandled network error
      await repository.logout();

      verify(() => mockSecureStorage.clearSession()).called(1);
      verify(() => mockHiveStorage.evictCache('auth_session_user')).called(1);
      verify(() => mockHiveStorage.evictCache('auth_role_intent')).called(1);
    });
  });

  group('SocialRepository Organization Leader & Sparring Invites Unit Tests', () {
    test('updateTeamMemberRole patches /social/teams/:teamId/members/:athleteId/role', () async {
      final repository = SocialRepository(
        dioClient: mockDioClient,
        hiveStorage: mockHiveStorage,
      );

      final responsePayload = {
        'data': {
          'teamId': 'team_1',
          'athleteId': 'athlete_2',
          'role': 'CAPTAIN',
        }
      };

      when(() => mockDio.patch(
            '/social/teams/team_1/members/athlete_2/role',
            data: {'role': 'CAPTAIN'},
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/social/teams/team_1/members/athlete_2/role'),
            statusCode: 200,
            data: responsePayload,
          ));

      final result = await repository.updateTeamMemberRole('team_1', 'athlete_2', 'CAPTAIN');

      expect(result['role'], equals('CAPTAIN'));
      verify(() => mockDio.patch(
            '/social/teams/team_1/members/athlete_2/role',
            data: {'role': 'CAPTAIN'},
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
    });

    test('createSparringInvite and respondSparringInvite call canonical /sparring-invites endpoints', () async {
      final repository = SocialRepository(
        dioClient: mockDioClient,
        hiveStorage: mockHiveStorage,
      );

      when(() => mockDio.post(
            '/sparring-invites',
            data: any(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/sparring-invites'),
            statusCode: 201,
            data: {
              'data': {
                'id': 'invite_99',
                'senderTeamId': 'team_1',
                'recipientTeamId': 'team_2',
                'status': 'PENDING',
              }
            },
          ));

      final created = await repository.createSparringInvite(
        senderTeamId: 'team_1',
        recipientTeamId: 'team_2',
        location: 'Lahore Table 1',
        message: '5v5 squad practice',
      );
      expect(created['id'], equals('invite_99'));
      expect(created['status'], equals('PENDING'));

      when(() => mockDio.post(
            '/sparring-invites/invite_99/respond',
            data: {'action': 'ACCEPT'},
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/sparring-invites/invite_99/respond'),
            statusCode: 200,
            data: {
              'data': {
                'invite': {'id': 'invite_99', 'status': 'ACCEPTED'},
                'conversationId': 'conv_sparring_99',
              }
            },
          ));

      final responded = await repository.respondSparringInvite('invite_99', 'ACCEPT');
      expect(responded['conversationId'], equals('conv_sparring_99'));
    });
  });

  group('SupportRepository Helpdesk Unit Tests', () {
    test('createTicket, getTicket, addTicketMessage, and updateTicketStatus call /support/tickets', () async {
      final repository = SupportRepository(
        dioClient: mockDioClient,
        hiveStorage: mockHiveStorage,
      );

      when(() => mockDio.post(
            '/support/tickets',
            data: any(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/support/tickets'),
            statusCode: 201,
            data: {
              'data': {
                'id': 'ticket_1',
                'subject': 'Bracket seeding inquiry',
                'category': 'EVENT',
                'priority': 'HIGH',
                'status': 'OPEN',
              }
            },
          ));

      final created = await repository.createTicket(
        subject: 'Bracket seeding inquiry',
        description: 'Need clarification on weight class bracket placement.',
        category: 'EVENT',
        priority: 'HIGH',
      );
      expect(created['id'], equals('ticket_1'));
      expect(created['status'], equals('OPEN'));

      when(() => mockDio.patch(
            '/support/tickets/ticket_1/status',
            data: {
              'status': 'RESOLVED',
              'resolutionNotes': 'Confirmed seeding order with director.',
            },
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/support/tickets/ticket_1/status'),
            statusCode: 200,
            data: {
              'data': {
                'id': 'ticket_1',
                'status': 'RESOLVED',
                'resolutionNotes': 'Confirmed seeding order with director.',
              }
            },
          ));

      final updated = await repository.updateTicketStatus(
        'ticket_1',
        status: 'RESOLVED',
        resolutionNotes: 'Confirmed seeding order with director.',
      );
      expect(updated['status'], equals('RESOLVED'));
    });

    test('assignTicket and addTicketMessage send both field aliases for API contract resilience', () async {
      final repository = SupportRepository(
        dioClient: mockDioClient,
        hiveStorage: mockHiveStorage,
      );

      when(() => mockDio.patch(
            '/support/tickets/ticket_1/assign',
            data: any(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/support/tickets/ticket_1/assign'),
            statusCode: 200,
            data: {
              'data': {
                'id': 'ticket_1',
                'assignedAgentId': 'agent_42',
                'status': 'IN_PROGRESS',
              }
            },
          ));

      final assigned = await repository.assignTicket('ticket_1', 'agent_42');
      expect(assigned['assignedAgentId'], equals('agent_42'));

      verify(() => mockDio.patch(
            '/support/tickets/ticket_1/assign',
            data: {
              'agentId': 'agent_42',
              'assignedAgentId': 'agent_42',
            },
            cancelToken: any(named: 'cancelToken'),
          )).called(1);

      when(() => mockDio.post(
            '/support/tickets/ticket_1/messages',
            data: any(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/support/tickets/ticket_1/messages'),
            statusCode: 201,
            data: {
              'data': {
                'id': 'msg_1',
                'message': 'Bracket seed corrected.',
                'content': 'Bracket seed corrected.',
                'isInternal': false,
              }
            },
          ));

      final msg = await repository.addTicketMessage(
        'ticket_1',
        message: 'Bracket seed corrected.',
        isInternal: false,
      );
      expect(msg['id'], equals('msg_1'));

      verify(() => mockDio.post(
            '/support/tickets/ticket_1/messages',
            data: {
              'message': 'Bracket seed corrected.',
              'content': 'Bracket seed corrected.',
              'isInternal': false,
            },
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
    });
  });
}
