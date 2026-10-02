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
  final List<String> verifiedRoles;
  final List<Map<String, dynamic>> pendingRoleApplications;
  final String? activeRole;

  AuthState({
    required this.status,
    this.userProfile,
    this.errorMessage,
    this.roleIntent,
    this.verifiedRoles = const [],
    this.pendingRoleApplications = const [],
    this.activeRole,
  });

  AuthState copyWith({
    AuthStatus? status,
    Map<String, dynamic>? userProfile,
    String? errorMessage,
    String? roleIntent,
    List<String>? verifiedRoles,
    List<Map<String, dynamic>>? pendingRoleApplications,
    String? activeRole,
  }) {
    return AuthState(
      status: status ?? this.status,
      userProfile: userProfile ?? this.userProfile,
      errorMessage: errorMessage ?? this.errorMessage,
      roleIntent: roleIntent ?? this.roleIntent,
      verifiedRoles: verifiedRoles ?? this.verifiedRoles,
      pendingRoleApplications: pendingRoleApplications ?? this.pendingRoleApplications,
      activeRole: activeRole ?? this.activeRole,
    );
  }

  bool hasRole(String role) {
    final r = role.toUpperCase();
    if (activeRole?.toUpperCase() == r) return true;
    if (userProfile?['role']?.toString().toUpperCase() == r) return true;
    return verifiedRoles.any((vr) => vr.toUpperCase() == r);
  }

  bool hasAnyRole(Iterable<String> roles) => roles.any(hasRole);
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
      final verified = _extractVerifiedRoles(profile);
      final pending = _extractPendingApplications(profile);
      final cachedRole = _readActiveRole(hiveStorage);
      final activeRole = _resolveActiveRole(verified, profile, cachedRole);

      state = AuthState(
        status: onboarded ? AuthStatus.authenticated : AuthStatus.onboardingRequired,
        userProfile: profile,
        roleIntent: _readRoleIntent(hiveStorage),
        verifiedRoles: verified,
        pendingRoleApplications: pending,
        activeRole: activeRole,
      );
      if (onboarded) {
        _initializeSync();
      }
    } catch (_) {
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  List<String> _extractVerifiedRoles(Map<String, dynamic>? profile) {
    if (profile == null) return const [];
    if (profile['verifiedRoles'] is List) {
      final roles = (profile['verifiedRoles'] as List).map((e) => e.toString()).toList();
      if (roles.contains('SYSTEM_ADMIN') || profile['role'] == 'SYSTEM_ADMIN') {
        return ['SYSTEM_ADMIN', 'ATHLETE', 'REFEREE', 'TOURNAMENT_OPERATOR'];
      }
      return roles;
    }
    final primaryRole = profile['role']?.toString();
    if (primaryRole != null && primaryRole.isNotEmpty) {
      if (primaryRole == 'SYSTEM_ADMIN') {
        return ['SYSTEM_ADMIN', 'ATHLETE', 'REFEREE', 'TOURNAMENT_OPERATOR'];
      }
      return [primaryRole];
    }
    return const ['ATHLETE'];
  }

  List<Map<String, dynamic>> _extractPendingApplications(Map<String, dynamic>? profile) {
    if (profile == null) return const [];
    if (profile['pendingApplications'] is List) {
      return (profile['pendingApplications'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  String _resolveActiveRole(
    List<String> verified,
    Map<String, dynamic>? profile,
    String? cachedRole,
  ) {
    if (cachedRole != null && verified.contains(cachedRole)) {
      return cachedRole;
    }
    final primary = profile?['role']?.toString();
    if (primary != null && verified.contains(primary)) {
      return primary;
    }
    if (verified.isNotEmpty) {
      return verified.first;
    }
    return primary ?? 'ATHLETE';
  }

  String? _readActiveRole(HiveStorage hiveStorage) {
    try {
      final cached = hiveStorage.getCachedData('auth_active_role');
      if (cached is Map && cached['activeRole'] is String) {
        return cached['activeRole'] as String;
      } else if (cached is String) {
        return cached;
      }
    } catch (_) {}
    return null;
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
      final verified = _extractVerifiedRoles(profile);
      final pending = _extractPendingApplications(profile);
      final hiveStorage = ref.read(hiveStorageProvider);
      final cachedRole = _readActiveRole(hiveStorage);
      final activeRole = _resolveActiveRole(verified, profile, cachedRole);

      state = AuthState(
        status: onboarded ? AuthStatus.authenticated : AuthStatus.onboardingRequired,
        userProfile: profile,
        roleIntent: state.roleIntent,
        verifiedRoles: verified,
        pendingRoleApplications: pending,
        activeRole: activeRole,
      );
      if (onboarded) {
        _initializeSync();
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> register(String email, String password, String name, {String? username}) async {
    try {
      state = state.copyWith(errorMessage: null);
      final repo = ref.read(authRepositoryProvider);

      // 1. Create the account.
      await repo.register(email, password, name, username: username);

      // 2. Establish the real authenticated session immediately so that the
      //    protected onboarding APIs receive a valid bearer token. Without
      //    this handoff, profile submission would fail with 401.
      final profile = await _establishSession(email, password);
      final verified = _extractVerifiedRoles(profile);
      final pending = _extractPendingApplications(profile);
      final hiveStorage = ref.read(hiveStorageProvider);
      final cachedRole = _readActiveRole(hiveStorage);
      final activeRole = _resolveActiveRole(verified, profile, cachedRole);

      state = AuthState(
        status: AuthStatus.onboardingRequired,
        userProfile: profile,
        roleIntent: state.roleIntent,
        verifiedRoles: verified,
        pendingRoleApplications: pending,
        activeRole: activeRole,
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
      updatedUser['profile'] = Map<String, dynamic>.from(profile);

      // Persist the completed onboarding state so cold starts restore it.
      await _persistSession(updatedUser, null, null);

      state = AuthState(
        status: AuthStatus.authenticated,
        userProfile: updatedUser,
        roleIntent: state.roleIntent,
        verifiedRoles: state.verifiedRoles,
        pendingRoleApplications: state.pendingRoleApplications,
        activeRole: state.activeRole,
      );
      _initializeSync();
    } catch (e) {
      // Graceful offline / local fallback so the user is never permanently blocked from entering the app
      final updatedUser = Map<String, dynamic>.from(state.userProfile ?? {});
      updatedUser['isOnboarded'] = true;
      updatedUser['profile'] = Map<String, dynamic>.from(onboardingData);
      await _persistSession(updatedUser, null, null);

      state = AuthState(
        status: AuthStatus.authenticated,
        userProfile: updatedUser,
        roleIntent: state.roleIntent,
        verifiedRoles: state.verifiedRoles,
        pendingRoleApplications: state.pendingRoleApplications,
        activeRole: state.activeRole,
      );
      _initializeSync();
    }
  }

  /// Allows the user to tour and explore the app immediately without being
  /// blocked by mandatory onboarding forms.
  Future<void> skipOnboarding() async {
    final updatedUser = Map<String, dynamic>.from(state.userProfile ?? {});
    updatedUser['isOnboarded'] = true;
    if (updatedUser['displayName'] == null || updatedUser['displayName'].toString().isEmpty) {
      updatedUser['displayName'] = updatedUser['name'] ?? 'Armwrestler';
    }
    await _persistSession(updatedUser, null, null);

    state = AuthState(
      status: AuthStatus.authenticated,
      userProfile: updatedUser,
      roleIntent: state.roleIntent ?? 'athlete',
      verifiedRoles: state.verifiedRoles,
      pendingRoleApplications: state.pendingRoleApplications,
      activeRole: state.activeRole,
    );
    _initializeSync();
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
      final verified = _extractVerifiedRoles(profile);
      final pending = _extractPendingApplications(profile);
      final hiveStorage = ref.read(hiveStorageProvider);
      final cachedRole = _readActiveRole(hiveStorage);
      final activeRole = _resolveActiveRole(verified, profile, cachedRole);

      await _persistSession(profile, data['accessToken']?.toString(), data['refreshToken']?.toString());

      state = AuthState(
        status: onboarded ? AuthStatus.authenticated : AuthStatus.onboardingRequired,
        userProfile: profile,
        roleIntent: state.roleIntent,
        verifiedRoles: verified,
        pendingRoleApplications: pending,
        activeRole: activeRole,
      );
      if (onboarded) {
        _initializeSync();
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  bool _isLoggingOut = false;

  Future<void> logout() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;
    try {
      // 1. Terminate realtime listeners and periodic sync tasks
      try {
        _disposeSync();
      } catch (_) {}

      // 2. Best-effort server-side push token deregistration
      try {
        await ref.read(pushNotificationManagerProvider).deregisterCurrentDevice();
      } catch (_) {}

      // 3. Best-effort offline/differential sync cache reset
      try {
        await ref.read(differentialSyncManagerProvider).resetCache();
      } catch (_) {}

      // 4. Server-side session revocation via repository (best-effort over the wire)
      try {
        final repo = ref.read(authRepositoryProvider);
        await repo.logout();
      } catch (_) {}
    } finally {
      // 5. Unconditional local credential & session destruction:
      // Even if every network or auxiliary step above threw or timed out,
      // local security credentials must NEVER survive logout.
      try {
        final secureStorage = ref.read(secureStorageProvider);
        await secureStorage.clearSession();
      } catch (_) {}

      try {
        final hiveStorage = ref.read(hiveStorageProvider);
        await hiveStorage.evictCache('auth_session_user');
        await hiveStorage.evictCache('auth_role_intent');
        await hiveStorage.evictCache('auth_active_role');
      } catch (_) {}

      state = AuthState(status: AuthStatus.unauthenticated);
      _isLoggingOut = false;
    }
  }

  /// Phase 12: real in-app account deletion (DELETE /auth/me).
  /// Server deactivates + anonymizes the account and revokes every session;
  /// local session material is cleared unconditionally.
  Future<void> deleteAccount() async {
    try {
      try {
        _disposeSync();
      } catch (_) {}

      final repo = ref.read(authRepositoryProvider);
      try {
        await repo.deleteAccount();
      } catch (_) {}
    } finally {
      try {
        final secureStorage = ref.read(secureStorageProvider);
        await secureStorage.clearSession();
      } catch (_) {}

      try {
        final hiveStorage = ref.read(hiveStorageProvider);
        await hiveStorage.evictCache('auth_session_user');
        await hiveStorage.evictCache('auth_role_intent');
        await hiveStorage.evictCache('auth_active_role');
      } catch (_) {}

      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Switches the client presentation persona to another verified role.
  /// Server authorization never trusts activeRole; permissions remain server-authoritative.
  Future<void> switchActiveRole(String newRole) async {
    if (!state.verifiedRoles.contains(newRole)) {
      throw Exception('Role $newRole is not verified for this account.');
    }
    try {
      final hiveStorage = ref.read(hiveStorageProvider);
      await hiveStorage.cacheData('auth_active_role', {'activeRole': newRole});
    } catch (_) {}

    state = state.copyWith(activeRole: newRole);
  }

  /// Refreshes verified roles and pending applications from the backend.
  Future<void> refreshUserRoles() async {
    try {
      final repo = ref.read(authRepositoryProvider);
      final rolesData = await repo.getUserRoles();
      final verified = (rolesData['verifiedRoles'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          state.verifiedRoles;
      final pending = (rolesData['pendingApplications'] as List?)
              ?.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          state.pendingRoleApplications;

      final hiveStorage = ref.read(hiveStorageProvider);
      final cachedRole = _readActiveRole(hiveStorage);
      final currentActive = _resolveActiveRole(
        verified,
        state.userProfile,
        state.activeRole ?? cachedRole,
      );

      state = state.copyWith(
        verifiedRoles: verified,
        pendingRoleApplications: pending,
        activeRole: currentActive,
      );
    } catch (_) {}
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
