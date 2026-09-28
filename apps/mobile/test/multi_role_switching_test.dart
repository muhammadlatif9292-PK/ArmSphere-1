import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mobile/core/storage/secure_storage.dart';
import 'package:mobile/core/storage/hive_storage.dart';
import 'package:mobile/core/api/repositories.dart';
import 'package:mobile/core/notifications/push_notification_manager.dart';
import 'package:mobile/core/api/differential_sync.dart';
import 'package:mobile/core/api/offline_sync.dart';
import 'package:mobile/core/providers/dependency_providers.dart';
import 'package:mobile/core/providers/state_providers.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';

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
  Future<void> clearSession() async => data.clear();
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSecureStorage fakeSecureStorage;
  late FakeHiveStorage fakeHiveStorage;
  late MockAuthRepository mockAuthRepository;
  late MockPushNotificationManager mockPushManager;
  late MockDifferentialSyncManager mockDiffSync;
  late MockOfflineSyncManager mockOfflineSync;

  setUp(() {
    fakeSecureStorage = FakeSecureStorage();
    fakeHiveStorage = FakeHiveStorage();
    mockAuthRepository = MockAuthRepository();
    mockPushManager = MockPushNotificationManager();
    mockDiffSync = MockDifferentialSyncManager();
    mockOfflineSync = MockOfflineSyncManager();

    when(() => mockPushManager.deregisterCurrentDevice()).thenAnswer((_) async {});
    when(() => mockDiffSync.resetCache()).thenAnswer((_) async {});
    when(() => mockDiffSync.startListening()).thenReturn(null);
    when(() => mockDiffSync.dispose()).thenReturn(null);
    when(() => mockOfflineSync.startListening()).thenReturn(null);
    when(() => mockOfflineSync.dispose()).thenReturn(null);
    when(() => mockDiffSync.pullDelta()).thenAnswer((_) async {});
    when(() => mockOfflineSync.syncQueue()).thenAnswer((_) async {});
    when(() => mockAuthRepository.logout()).thenAnswer((_) async {});
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(fakeSecureStorage),
        hiveStorageProvider.overrideWithValue(fakeHiveStorage),
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
        pushNotificationManagerProvider.overrideWithValue(mockPushManager),
        differentialSyncManagerProvider.overrideWithValue(mockDiffSync),
        offlineSyncManagerProvider.overrideWithValue(mockOfflineSync),
      ],
    );
  }

  test('AuthState initializes with multi-role verified roles and activeRole', () {
    final state = AuthState(
      status: AuthStatus.authenticated,
      verifiedRoles: const ['ATHLETE', 'REFEREE'],
      activeRole: 'ATHLETE',
    );

    expect(state.verifiedRoles, contains('ATHLETE'));
    expect(state.verifiedRoles, contains('REFEREE'));
    expect(state.activeRole, equals('ATHLETE'));

    final copied = state.copyWith(activeRole: 'REFEREE');
    expect(copied.activeRole, equals('REFEREE'));
    expect(copied.verifiedRoles, equals(['ATHLETE', 'REFEREE']));
  });

  test('AuthNotifier cold start restores verifiedRoles and activeRole from storage', () async {
    // Seed authenticated session in secure storage with dual roles
    final profile = {
      'id': 'user-123',
      'email': 'dual@armsphere.com',
      'role': 'ATHLETE',
      'isOnboarded': true,
      'verifiedRoles': ['ATHLETE', 'REFEREE'],
    };
    await fakeSecureStorage.setRefreshToken('valid_refresh_token');
    await fakeSecureStorage.setSessionUserData(jsonEncode(profile));
    // Seed active persona preference in Hive
    await fakeHiveStorage.cacheData('auth_active_role', {'activeRole': 'REFEREE'});

    final container = createContainer();
    final notifier = container.read(authProvider.notifier);
    await notifier.checkInitialSession();

    final state = container.read(authProvider);
    expect(state.status, equals(AuthStatus.authenticated));
    expect(state.verifiedRoles, containsAll(['ATHLETE', 'REFEREE']));
    expect(state.activeRole, equals('REFEREE'));
  });

  test('switchActiveRole switches activeRole and persists preference to Hive', () async {
    final profile = {
      'id': 'user-123',
      'email': 'dual@armsphere.com',
      'role': 'ATHLETE',
      'isOnboarded': true,
      'verifiedRoles': ['ATHLETE', 'REFEREE'],
    };
    await fakeSecureStorage.setRefreshToken('valid_refresh_token');
    await fakeSecureStorage.setSessionUserData(jsonEncode(profile));

    final container = createContainer();
    final notifier = container.read(authProvider.notifier);
    await notifier.checkInitialSession();

    expect(container.read(authProvider).activeRole, equals('ATHLETE'));

    // Switch to REFEREE
    await notifier.switchActiveRole('REFEREE');

    expect(container.read(authProvider).activeRole, equals('REFEREE'));
    final cached = fakeHiveStorage.getCachedData('auth_active_role');
    expect(cached['activeRole'], equals('REFEREE'));
  });

  test('switchActiveRole to an unverified role throws an exception', () async {
    final profile = {
      'id': 'user-123',
      'email': 'dual@armsphere.com',
      'role': 'ATHLETE',
      'isOnboarded': true,
      'verifiedRoles': ['ATHLETE'],
    };
    await fakeSecureStorage.setRefreshToken('valid_refresh_token');
    await fakeSecureStorage.setSessionUserData(jsonEncode(profile));

    final container = createContainer();
    final notifier = container.read(authProvider.notifier);
    await notifier.checkInitialSession();

    // Attempt to switch to SYSTEM_ADMIN without a verified grant
    expect(
      () => notifier.switchActiveRole('SYSTEM_ADMIN'),
      throwsA(isA<Exception>()),
    );
    expect(container.read(authProvider).activeRole, equals('ATHLETE'));
  });

  test('logout evicts auth_active_role and resets multi-role state', () async {
    final profile = {
      'id': 'user-123',
      'email': 'dual@armsphere.com',
      'role': 'ATHLETE',
      'isOnboarded': true,
      'verifiedRoles': ['ATHLETE', 'REFEREE'],
    };
    await fakeSecureStorage.setRefreshToken('valid_refresh_token');
    await fakeSecureStorage.setSessionUserData(jsonEncode(profile));
    await fakeHiveStorage.cacheData('auth_active_role', {'activeRole': 'REFEREE'});

    final container = createContainer();
    final notifier = container.read(authProvider.notifier);
    await notifier.checkInitialSession();

    expect(container.read(authProvider).status, equals(AuthStatus.authenticated));

    await notifier.logout();

    expect(container.read(authProvider).status, equals(AuthStatus.unauthenticated));
    expect(container.read(authProvider).verifiedRoles, isEmpty);
    expect(container.read(authProvider).activeRole, isNull);
    expect(fakeHiveStorage.getCachedData('auth_active_role'), isNull);
  });
}
