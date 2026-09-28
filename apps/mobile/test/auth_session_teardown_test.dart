import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';

import 'package:mobile/core/storage/secure_storage.dart';
import 'package:mobile/core/storage/hive_storage.dart';
import 'package:mobile/core/api/repositories.dart';
import 'package:mobile/core/notifications/push_notification_manager.dart';
import 'package:mobile/core/api/differential_sync.dart';
import 'package:mobile/core/api/offline_sync.dart';
import 'package:mobile/core/providers/dependency_providers.dart';
import 'package:mobile/core/providers/state_providers.dart';
import 'package:mobile/core/providers/biometric_provider.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'package:mobile/features/settings/screens/settings_hub_screens.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockPushNotificationManager extends Mock implements PushNotificationManager {}
class MockDifferentialSyncManager extends Mock implements DifferentialSyncManager {}
class MockOfflineSyncManager extends Mock implements OfflineSyncManager {}

class FakeSecureStorage implements SecureStorage {
  final Map<String, String> data = {};

  @override
  Future<void> setAccessToken(String token) async => data['access_token'] = token;
  @override
  Future<String?> getAccessToken() async => data['access_token'];
  @override
  Future<void> setRefreshToken(String token) async => data['refresh_token'] = token;
  @override
  Future<String?> getRefreshToken() async => data['refresh_token'];
  @override
  Future<void> setSessionUserData(String jsonStr) async => data['session_user_data'] = jsonStr;
  @override
  Future<String?> getSessionUserData() async => data['session_user_data'];
  @override
  Future<void> clearSession() async {
    data.remove('access_token');
    data.remove('refresh_token');
    data.remove('session_user_data');
  }
  @override
  Future<void> clearAll() async => data.clear();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeHiveStorage implements HiveStorage {
  final Map<String, dynamic> cache = {};

  @override
  Future<void> initialize() async {}
  @override
  Future<void> cacheData(String key, dynamic value) async => cache[key] = value;
  @override
  dynamic getCachedData(String key) => cache[key];
  @override
  Future<void> evictCache(String key) async => cache.remove(key);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockBiometricEnabledNotifier extends StateNotifier<AsyncValue<bool>>
    implements BiometricEnabledNotifier {
  MockBiometricEnabledNotifier() : super(const AsyncValue.data(false));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ControlledLogoutNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  final Completer<void> logoutCompleter;
  bool logoutCalled = false;
  bool logoutFinished = false;

  ControlledLogoutNotifier({required this.logoutCompleter})
      : super(AuthState(
          status: AuthStatus.authenticated,
          userProfile: {'id': 'user_1', 'role': 'ATHLETE'},
        ));

  @override
  Future<void> logout() async {
    logoutCalled = true;
    await logoutCompleter.future;
    logoutFinished = true;
    state = AuthState(status: AuthStatus.unauthenticated);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSecureStorage fakeSecureStorage;
  late FakeHiveStorage fakeHiveStorage;
  late MockAuthRepository mockAuthRepository;
  late MockPushNotificationManager mockPushNotificationManager;
  late MockDifferentialSyncManager mockDifferentialSyncManager;
  late MockOfflineSyncManager mockOfflineSyncManager;

  setUp(() {
    fakeSecureStorage = FakeSecureStorage();
    fakeHiveStorage = FakeHiveStorage();
    mockAuthRepository = MockAuthRepository();
    mockPushNotificationManager = MockPushNotificationManager();
    mockDifferentialSyncManager = MockDifferentialSyncManager();
    mockOfflineSyncManager = MockOfflineSyncManager();

    // Default clean setups
    when(() => mockPushNotificationManager.deregisterCurrentDevice())
        .thenAnswer((_) async {});
    when(() => mockDifferentialSyncManager.resetCache()).thenAnswer((_) async {});
    when(() => mockDifferentialSyncManager.dispose()).thenReturn(null);
    when(() => mockOfflineSyncManager.dispose()).thenReturn(null);
    when(() => mockAuthRepository.logout()).thenAnswer((_) async {});
    when(() => mockAuthRepository.deleteAccount()).thenAnswer((_) async {});
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(fakeSecureStorage),
        hiveStorageProvider.overrideWithValue(fakeHiveStorage),
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
        pushNotificationManagerProvider.overrideWithValue(mockPushNotificationManager),
        differentialSyncManagerProvider.overrideWithValue(mockDifferentialSyncManager),
        offlineSyncManagerProvider.overrideWithValue(mockOfflineSyncManager),
      ],
    );
  }

  group('Auth Session Teardown - Unit & Failure Resilience Tests', () {
    test(
      'B, C, D: Secure storage and Hive cache are cleared even when FCM, sync, and server logout throw',
      () async {
        // Populate existing session credentials
        await fakeSecureStorage.setAccessToken('jwt.access.test_token');
        await fakeSecureStorage.setRefreshToken('jwt.refresh.test_token');
        await fakeSecureStorage.setSessionUserData('{"id":"athlete_1","role":"ATHLETE"}');
        await fakeHiveStorage.cacheData('auth_session_user', {'id': 'athlete_1', 'role': 'ATHLETE'});
        await fakeHiveStorage.cacheData('auth_role_intent', {'intent': 'athlete'});

        // Make upstream services throw errors
        when(() => mockPushNotificationManager.deregisterCurrentDevice())
            .thenThrow(Exception('FCM network failure or timeout'));
        when(() => mockDifferentialSyncManager.resetCache())
            .thenThrow(Exception('Sync cache reset I/O failure'));
        when(() => mockAuthRepository.logout())
            .thenThrow(Exception('Server 500 internal error'));

        final container = createContainer();

        // Trigger logout
        await container.read(authProvider.notifier).logout();

        // B & C: Assert that local credentials cannot survive the failure path
        expect(fakeSecureStorage.data.containsKey('access_token'), isFalse);
        expect(fakeSecureStorage.data.containsKey('refresh_token'), isFalse);
        expect(fakeSecureStorage.data.containsKey('session_user_data'), isFalse);
        expect(fakeHiveStorage.cache.containsKey('auth_session_user'), isFalse);
        expect(fakeHiveStorage.cache.containsKey('auth_role_intent'), isFalse);

        // D: Assert signed-out state is reached
        expect(container.read(authProvider).status, equals(AuthStatus.unauthenticated));
      },
    );

    test('E: Clean logout path clears all credentials and reaches unauthenticated state', () async {
      await fakeSecureStorage.setAccessToken('access_token_abc');
      await fakeSecureStorage.setRefreshToken('refresh_token_xyz');
      await fakeSecureStorage.setSessionUserData('{"id":"user_normal","role":"REFEREE"}');
      await fakeHiveStorage.cacheData('auth_session_user', {'id': 'user_normal', 'role': 'REFEREE'});
      await fakeHiveStorage.cacheData('auth_role_intent', {'intent': 'referee'});

      final container = createContainer();

      await container.read(authProvider.notifier).logout();

      expect(fakeSecureStorage.data.isEmpty, isTrue);
      expect(fakeHiveStorage.cache.isEmpty, isTrue);
      expect(container.read(authProvider).status, equals(AuthStatus.unauthenticated));
    });

    test('deleteAccount clears all local credentials even if server call throws', () async {
      await fakeSecureStorage.setAccessToken('access_token_del');
      await fakeSecureStorage.setRefreshToken('refresh_token_del');
      await fakeSecureStorage.setSessionUserData('{"id":"user_del","role":"ATHLETE"}');
      await fakeHiveStorage.cacheData('auth_session_user', {'id': 'user_del'});
      await fakeHiveStorage.cacheData('auth_role_intent', {'intent': 'athlete'});

      when(() => mockAuthRepository.deleteAccount()).thenThrow(Exception('Network timeout'));

      final container = createContainer();

      await container.read(authProvider.notifier).deleteAccount();

      expect(fakeSecureStorage.data.isEmpty, isTrue);
      expect(fakeHiveStorage.cache.isEmpty, isTrue);
      expect(container.read(authProvider).status, equals(AuthStatus.unauthenticated));
    });
  });

  group('Auth Session Teardown - Navigation & Widget Awaiting Tests', () {
    testWidgets('A: Logout is awaited before navigation to /login occurs', (WidgetTester tester) async {
      final completer = Completer<void>();
      final controlledNotifier = ControlledLogoutNotifier(logoutCompleter: completer);
      final navigatedRoutes = <String>[];

      final testRouter = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsHubScreen(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) {
              navigatedRoutes.add('/login');
              return const Scaffold(body: Text('Login Screen'));
            },
          ),
          GoRoute(
            path: '/welcome',
            builder: (context, state) => const Scaffold(body: Text('Welcome Screen')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => controlledNotifier),
            biometricCapabilityProvider
                .overrideWith((ref) async => BiometricCapability.unsupported),
            biometricEnabledProvider
                .overrideWith((ref) => MockBiometricEnabledNotifier()),
          ],
          child: MaterialApp.router(
            routerConfig: testRouter,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the Log Out tile
      final logoutTile = find.widgetWithText(ListTile, 'Log Out');
      expect(logoutTile, findsOneWidget);

      // Tap Log Out
      await tester.tap(logoutTile);
      await tester.pump();

      // Verify logout() has been triggered
      expect(controlledNotifier.logoutCalled, isTrue);

      // Verify that while logout() is still in-flight (completer not completed),
      // navigation to /login has NOT completed yet!
      expect(controlledNotifier.logoutFinished, isFalse);
      expect(navigatedRoutes.contains('/login'), isFalse);

      // Now complete the logout operation
      completer.complete();
      await tester.pumpAndSettle();

      // Verify logout finished and navigation to /login succeeded
      expect(controlledNotifier.logoutFinished, isTrue);
      expect(navigatedRoutes.contains('/login'), isTrue);
    });
  });
}
