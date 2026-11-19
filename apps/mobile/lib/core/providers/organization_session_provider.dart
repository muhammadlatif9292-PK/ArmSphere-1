import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/repositories.dart';
import 'dependency_providers.dart';
import 'state_providers.dart';
import '../storage/hive_storage.dart';
import '../storage/secure_storage.dart';

class OrganizationSessionState {
  final String? orgId;
  final String? orgName;
  final String? province;
  final String? city;
  final String? token;
  final bool isOnboarded;
  final bool isAuthenticated;
  final String? presidentName;

  const OrganizationSessionState({
    this.orgId,
    this.orgName,
    this.province,
    this.city,
    this.token,
    this.isOnboarded = false,
    this.isAuthenticated = false,
    this.presidentName,
  });

  OrganizationSessionState copyWith({
    String? orgId,
    String? orgName,
    String? province,
    String? city,
    String? token,
    bool? isOnboarded,
    bool? isAuthenticated,
    String? presidentName,
  }) {
    return OrganizationSessionState(
      orgId: orgId ?? this.orgId,
      orgName: orgName ?? this.orgName,
      province: province ?? this.province,
      city: city ?? this.city,
      token: token ?? this.token,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      presidentName: presidentName ?? this.presidentName,
    );
  }

  Map<String, dynamic> toJson() => {
    'orgId': orgId,
    'orgName': orgName,
    'province': province,
    'city': city,
    'token': token,
    'isOnboarded': isOnboarded,
    'isAuthenticated': isAuthenticated,
    'presidentName': presidentName,
  };

  factory OrganizationSessionState.fromJson(Map<String, dynamic> json) {
    return OrganizationSessionState(
      orgId: json['orgId']?.toString(),
      orgName: json['orgName']?.toString(),
      province: json['province']?.toString(),
      city: json['city']?.toString(),
      token: json['token']?.toString(),
      isOnboarded: json['isOnboarded'] == true,
      isAuthenticated: json['isAuthenticated'] == true,
      presidentName: json['presidentName']?.toString(),
    );
  }
}

class OrganizationSessionNotifier extends StateNotifier<OrganizationSessionState> {
  final HiveStorage _hiveStorage;
  final SecureStorage _secureStorage;
  final OrganizationRepository _orgRepo;
  static const String _kCacheKey = 'active_organization_session_v1';

  OrganizationSessionNotifier(
    this._hiveStorage,
    this._secureStorage,
    this._orgRepo,
  ) : super(const OrganizationSessionState()) {
    _loadSavedSession();
  }

  void _loadSavedSession() {
    try {
      final cached = _hiveStorage.getCachedData(_kCacheKey);
      if (cached != null) {
        final map = cached is String
            ? jsonDecode(cached)
            : Map<String, dynamic>.from(cached as Map);
        state = OrganizationSessionState.fromJson(map);
        if (state.isAuthenticated &&
            state.token != null &&
            state.token!.isNotEmpty) {
          _secureStorage.setAccessToken(state.token!);
        }
      }
    } catch (_) {}
  }

  Future<void> loginWithCode({
    required String organizationId,
    required String accessCode,
  }) async {
    final res = await _orgRepo.verifyAccessCode(
      organizationId: organizationId,
      accessCode: accessCode,
    );

    final org = res['organization'] is Map ? Map<String, dynamic>.from(res['organization']) : <String, dynamic>{};
    final token = res['token']?.toString();

    if (token != null && token.isNotEmpty) {
      await _secureStorage.setAccessToken(token);
    }

    state = OrganizationSessionState(
      orgId: (org['id'] ?? organizationId).toString(),
      orgName: (org['name'] ?? 'Organization').toString(),
      province: org['province']?.toString(),
      city: org['city']?.toString(),
      token: token,
      isOnboarded: org['isOnboarded'] == true,
      isAuthenticated: true,
      presidentName: org['presidentName']?.toString(),
    );

    await _hiveStorage.cacheData(_kCacheKey, state.toJson());
  }

  Future<void> markOnboarded({
    required String presidentName,
    required String province,
    required String city,
  }) async {
    state = state.copyWith(
      isOnboarded: true,
      presidentName: presidentName,
      province: province,
      city: city,
    );
    await _hiveStorage.cacheData(_kCacheKey, state.toJson());
  }

  Future<void> lockOrLogout() async {
    state = const OrganizationSessionState();
    await _hiveStorage.deleteCachedData(_kCacheKey);
    await _secureStorage.clearSession();
  }
}

final organizationSessionProvider =
    StateNotifierProvider<OrganizationSessionNotifier, OrganizationSessionState>((ref) {
  final hive = ref.watch(hiveStorageProvider);
  final secure = ref.watch(secureStorageProvider);
  final repo = ref.watch(organizationRepositoryProvider);
  return OrganizationSessionNotifier(hive, secure, repo);
});
