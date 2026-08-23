import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/state_providers.dart';
import '../../../core/providers/dependency_providers.dart';
import '../../../core/notifications/push_notification_manager.dart';

enum AuthStatus {
  unknown,
  unauthenticated,
  mfaRequired,
  onboardingRequired,
  authenticated,
}

class AuthState {
  final AuthStatus status;
  final Map<String, dynamic>? userProfile;
  final String? errorMessage;

  AuthState({
    required this.status,
    this.userProfile,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    Map<String, dynamic>? userProfile,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      userProfile: userProfile ?? this.userProfile,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;

  AuthNotifier(this.ref) : super(AuthState(status: AuthStatus.unknown)) {
    _init();
  }

  void _initializeSync() {
    try {
      final diffSync = ref.read(differentialSyncManagerProvider);
      final offlineSync = ref.read(offlineSyncManagerProvider);
      
      diffSync.startListening();
      offlineSync.startListening();
      
      diffSync.pullDelta();
      offlineSync.syncQueue();

      // Initialize Push Notifications and register FCM token
      ref.read(pushNotificationManagerProvider).initialize(ref);
    } catch (_) {
      // safe fallback to prevent bootstrap errors
    }
  }

  void _disposeSync() {
    try {
      ref.read(differentialSyncManagerProvider).dispose();
      ref.read(offlineSyncManagerProvider).dispose();
    } catch (_) {
      // safe fallback
    }
  }

  Future<void> _init() async {
    try {
      final hiveStorage = ref.read(hiveStorageProvider);
      await hiveStorage.initialize();
      final cachedProfile = hiveStorage.getCachedData('auth_session_user');
      if (cachedProfile != null && cachedProfile is Map) {
        final profileMap = Map<String, dynamic>.from(cachedProfile);
        final onboarded = profileMap['isOnboarded'] as bool? ?? true;
        
        state = AuthState(
          status: onboarded ? AuthStatus.authenticated : AuthStatus.onboardingRequired,
          userProfile: profileMap,
        );
        if (onboarded) {
          _initializeSync();
        }
      } else {
        state = AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    try {
      state = state.copyWith(errorMessage: null);
      final repo = ref.read(authRepositoryProvider);
      final response = await repo.login(email, password);

      final data = response is Map && response.containsKey('data') ? Map<String, dynamic>.from(response['data']) : response;
      final isMfaRequired = data['mfaRequired'] as bool? ?? false;
      if (isMfaRequired) {
        state = state.copyWith(status: AuthStatus.mfaRequired, userProfile: data);
        return;
      }

      final profile = data['user'] as Map<String, dynamic>? ?? data;
      final onboarded = profile['isOnboarded'] as bool? ?? true;

      final secureStorage = ref.read(secureStorageProvider);
      final accessToken = data['accessToken']?.toString();
      final refreshToken = data['refreshToken']?.toString();
      if (accessToken != null && accessToken.isNotEmpty) {
        await secureStorage.setAccessToken(accessToken);
      }
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await secureStorage.setRefreshToken(refreshToken);
      }
      await secureStorage.setSessionUserData(jsonEncode(profile));

      state = AuthState(
        status: onboarded ? AuthStatus.authenticated : AuthStatus.onboardingRequired,
        userProfile: profile,
      );
      if (onboarded) {
        _initializeSync();
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> register(String email, String password, String name) async {
    try {
      state = state.copyWith(errorMessage: null);
      final repo = ref.read(authRepositoryProvider);
      final response = await repo.register(email, password, name);
      final user = response is Map && response.containsKey('data') ? Map<String, dynamic>.from(response['data']) : response;

      final profile = Map<String, dynamic>.from(user as Map? ?? <String, dynamic>{});
      profile['isOnboarded'] = false;

      final hiveStorage = ref.read(hiveStorageProvider);
      await hiveStorage.cacheData('auth_session_user', profile);

      state = AuthState(
        status: AuthStatus.onboardingRequired,
        userProfile: profile,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> completeOnboarding(Map<String, dynamic> onboardingData) async {
    try {
      state = state.copyWith(errorMessage: null);
      final repo = ref.read(athleteRepositoryProvider);
      final profile = await repo.submitOnboarding(onboardingData);
      
      final updatedUser = Map<String, dynamic>.from(state.userProfile ?? {});
      updatedUser['isOnboarded'] = true;
      updatedUser['profile'] = profile;

      final hiveStorage = ref.read(hiveStorageProvider);
      await hiveStorage.cacheData('auth_session_user', updatedUser);

      state = AuthState(
        status: AuthStatus.authenticated,
        userProfile: updatedUser,
      );
      _initializeSync();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> verifyMfa(String code) async {
    try {
      state = state.copyWith(errorMessage: null);
      final repo = ref.read(authRepositoryProvider);
      final currentUser = state.userProfile?['user'] as Map<String, dynamic>? ?? state.userProfile ?? {};
      final userId = currentUser['id']?.toString() ?? currentUser['userId']?.toString();
      if (userId == null || userId.isEmpty) {
        throw Exception('MFA session is missing user context.');
      }

      final response = await repo.verifyMfa(code, userId: userId);
      final data = response is Map && response.containsKey('data') ? Map<String, dynamic>.from(response['data']) : response;
      final profile = data['user'] as Map<String, dynamic>? ?? currentUser;
      final onboarded = profile['isOnboarded'] as bool? ?? true;

      final secureStorage = ref.read(secureStorageProvider);
      final accessToken = data['accessToken']?.toString();
      final refreshToken = data['refreshToken']?.toString();
      if (accessToken != null && accessToken.isNotEmpty) {
        await secureStorage.setAccessToken(accessToken);
      }
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await secureStorage.setRefreshToken(refreshToken);
      }
      await secureStorage.setSessionUserData(jsonEncode(profile));

      state = AuthState(
        status: onboarded ? AuthStatus.authenticated : AuthStatus.onboardingRequired,
        userProfile: profile,
      );
      if (onboarded) {
        _initializeSync();
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      _disposeSync();
      // Deregister FCM token from server on logout to ensure security
      await ref.read(pushNotificationManagerProvider).deregisterCurrentDevice();
      await ref.read(differentialSyncManagerProvider).resetCache();
      final repo = ref.read(authRepositoryProvider);
      await repo.logout();
    } catch (_) {
      final hiveStorage = ref.read(hiveStorageProvider);
      await hiveStorage.evictCache('auth_session_user');
    } finally {
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
