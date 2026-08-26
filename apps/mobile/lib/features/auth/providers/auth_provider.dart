import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/state_providers.dart';
import '../../../core/providers/dependency_providers.dart';
import '../../../core/storage/hive_storage.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/notifications/push_notification_manager.dart';

enum AuthStatus {
  unknown,
  unauthenticated,
  mfaRequired,
  onboardingRequired,
  authenticated,
}

/// Role intents a user can express during first-run onboarding.
///
/// Intent is a product preference only. Actual capabilities are always
/// granted server-side; selecting an intent never elevates permissions.
class AuthState {
  final AuthStatus status;
  final Map<String, dynamic>? userProfile;
  final String? errorMessage;
  final String? roleIntent;

  AuthState({
    required this.status,
    this.userProfile,
    this.errorMessage,
    this.roleIntent,
  });

  AuthState copyWith({
    AuthStatus? status,
    Map<String, dynamic>? userProfile,
    String? errorMessage,
    String? roleIntent,
  }) {
    return AuthState(
      status: status ?? this.status,
      userProfile: userProfile ?? this.userProfile,
      errorMessage: errorMessage ?? this.errorMessage,
      roleIntent: roleIntent ?? this.roleIntent,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;

  AuthNotifier(this.ref) : super(AuthState(status: AuthStatus.unknown)) {
    _init();
  }

  /// Re-checks cached session state and restores authentication.
  Future<void> checkInitialSession() => _init();

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

  /// Restores the previous session from encrypted storage.
  ///
  /// Tokens live in SecureStorage only; the Hive cache keeps a sanitized
  /// profile mirror (no tokens) used for fast startup and diagnostics.
  Future<void> _init() async {
    try {
      final hiveStorage = ref.read(hiveStorageProvider);
      await hiveStorage.initialize();
      final secureStorage = ref.read(secureStorageProvider);

      Map<String, dynamic>? profile = await _loadStoredProfile(secureStorage);

      if (profile == null) {
        // Legacy fallback: older builds kept the session in the Hive cache.
        final legacy = hiveStorage.getCachedData('auth_session_user');
        if (legacy is Map) {
          profile = _normalizeProfile(Map<String, dynamic>.from(legacy));
        }
      }

      if (profile == null) {
        state = AuthState(status: AuthStatus.unauthenticated);
        return;
      }

      final refreshToken = await secureStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        // Without session credentials no authenticated API call can be made.
        state = AuthState(status: AuthStatus.unauthenticated);
        return;
      }

      final onboarded = profile['isOnboarded'] as bool? ?? false;
      state = AuthState(
        status: onboarded ? AuthStatus.authenticated : AuthStatus.onboardingRequired,
        userProfile: profile,
        roleIntent: _readRoleIntent(hiveStorage),
      );
      if (onboarded) {
        _initializeSync();
      }
    } catch (_) {
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<Map<String, dynamic>?> _loadStoredProfile(SecureStorage secureStorage) async {
    final raw = await secureStorage.getSessionUserData();
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return _normalizeProfile(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
    return null;
  }

  /// Unwraps a nested `user` payload and strips credential material.
  Map<String, dynamic> _normalizeProfile(Map<String, dynamic> raw) {
    final nested = raw['user'];
    final base = nested is Map ? Map<String, dynamic>.from(nested) : raw;
    base.remove('accessToken');
    base.remove('refreshToken');
    base.remove('deviceTrustToken');
    base.remove('passwordHash');
    return base;
  }

  String? _readRoleIntent(HiveStorage hiveStorage) {
    try {
      final value = hiveStorage.getCachedData('auth_role_intent');
      if (value is Map && value['intent'] is String) {
        return value['intent'] as String;
      }
    } catch (_) {}
    return null;
  }

  /// Persists tokens to SecureStorage plus a sanitized profile mirror to Hive.
  ///
  /// Pass null for tokens when they should be left untouched.
  Future<void> _persistSession(
    Map<String, dynamic> profile,
    String? accessToken,
    String? refreshToken,
  ) async {
    final secureStorage = ref.read(secureStorageProvider);
    final hiveStorage = ref.read(hiveStorageProvider);

    if (accessToken != null && accessToken.isNotEmpty) {
      await secureStorage.setAccessToken(accessToken);
    }
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await secureStorage.setRefreshToken(refreshToken);
    }
    await secureStorage.setSessionUserData(jsonEncode(profile));

    final safeCopy = Map<String, dynamic>.from(profile);
    safeCopy.remove('accessToken');
    safeCopy.remove('refreshToken');
    safeCopy.remove('deviceTrustToken');
    await hiveStorage.cacheData('auth_session_user', safeCopy);
  }

  /// Exchanges credentials for tokens and stores the session.
  ///
  /// Used by both [login] and [register] so every entry into the app runs on
  /// a real authenticated session before any protected API call.
  Future<Map<String, dynamic>> _establishSession(String email, String password) async {
    final data = await ref.read(authRepositoryProvider).login(email, password);

    if (data['mfaRequired'] == true) {
      throw Exception('Additional verification is required. Please sign in.');
    }

    final profile = data['user'] is Map
        ? Map<String, dynamic>.from(data['user'])
        : Map<String, dynamic>.from(data);
    profile['isOnboarded'] = profile['isOnboarded'] as bool? ?? false;

    await _persistSession(profile, data['accessToken']?.toString(), data['refreshToken']?.toString());
    return profile;
  }

  Future<void> login(String email, String password) async {
    try {
      state = state.copyWith(errorMessage: null);
      final profile = await _establishSession(email, password);
      final onboarded = profile['isOnboarded'] as bool? ?? false;

      state = AuthState(
        status: onboarded ? AuthStatus.authenticated : AuthStatus.onboardingRequired,
        userProfile: profile,
        roleIntent: state.roleIntent,
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

      // 1. Create the account.
      await repo.register(email, password, name);

      // 2. Establish the real authenticated session immediately so that the
      //    protected onboarding APIs receive a valid bearer token. Without
      //    this handoff, profile submission would fail with 401.
      final profile = await _establishSession(email, password);

      state = AuthState(
        status: AuthStatus.onboardingRequired,
        userProfile: profile,
        roleIntent: state.roleIntent,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Records what the user wants to do on ArmSphere. Purely informational —
  /// verified roles are provisioned by federation staff, never by selection.
  Future<void> setRoleIntent(String intent) async {
    try {
      final hiveStorage = ref.read(hiveStorageProvider);
      await hiveStorage.cacheData('auth_role_intent', {'intent': intent});
    } catch (_) {}
    state = state.copyWith(roleIntent: intent);
  }

  Future<void> completeOnboarding(Map<String, dynamic> onboardingData) async {
    try {
      state = state.copyWith(errorMessage: null);
      final repo = ref.read(athleteRepositoryProvider);
      final profile = await repo.submitOnboarding(onboardingData);

      final updatedUser = Map<String, dynamic>.from(state.userProfile ?? {});
      updatedUser['isOnboarded'] = true;
      if (profile is Map) {
        updatedUser['profile'] = Map<String, dynamic>.from(profile);
      } else {
        updatedUser['profile'] = profile;
      }

      // Persist the completed onboarding state so cold starts restore it.
      await _persistSession(updatedUser, null, null);

      state = AuthState(
        status: AuthStatus.authenticated,
        userProfile: updatedUser,
        roleIntent: state.roleIntent,
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
      final currentUser = state.userProfile?['user'] as Map<String, dynamic>? ?? state.userProfile ?? {};
      final userId = currentUser['id']?.toString() ?? currentUser['userId']?.toString();
      if (userId == null || userId.isEmpty) {
        throw Exception('MFA session is missing user context.');
      }

      final data = await ref.read(authRepositoryProvider).verifyMfa(code, userId: userId);
      final profile = data['user'] is Map
          ? Map<String, dynamic>.from(data['user'])
          : Map<String, dynamic>.from(currentUser);
      final onboarded = profile['isOnboarded'] as bool? ?? false;

      await _persistSession(profile, data['accessToken']?.toString(), data['refreshToken']?.toString());

      state = AuthState(
        status: onboarded ? AuthStatus.authenticated : AuthStatus.onboardingRequired,
        userProfile: profile,
        roleIntent: state.roleIntent,
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
      try {
        final hiveStorage = ref.read(hiveStorageProvider);
        await hiveStorage.evictCache('auth_session_user');
      } catch (_) {}
    } finally {
      // Role intent belongs to the account session; clear it on sign-out.
      try {
        final hiveStorage = ref.read(hiveStorageProvider);
        await hiveStorage.evictCache('auth_role_intent');
      } catch (_) {}
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Phase 12: real in-app account deletion (DELETE /auth/me).
  /// Server deactivates + anonymizes the account and revokes every session;
  /// local session material is cleared unconditionally.
  Future<void> deleteAccount() async {
    _disposeSync();
    final repo = ref.read(authRepositoryProvider);
    try {
      await repo.deleteAccount();
    } finally {
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
