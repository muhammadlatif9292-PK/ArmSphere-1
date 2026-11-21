import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state_providers.dart';
import '../../features/auth/providers/auth_provider.dart';

class AthleteProfileNotifier extends AutoDisposeAsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() async {
    ref.keepAlive();
    final authState = ref.watch(authProvider);
    final user = authState.userProfile;
    final athleteId = user?['id']?.toString() ?? 'self';
    final repo = ref.watch(athleteRepositoryProvider);
    return repo.getProfile(athleteId);
  }

  Future<bool> updateOnboarding(Map<String, dynamic> data) async {
    try {
      final repo = ref.read(athleteRepositoryProvider);
      final profile = await repo.submitOnboarding(data);
      state = AsyncData(profile);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateVisibility({
    required String profileVisibility,
    required bool isSearchable,
    String? locationVisibility,
  }) async {
    try {
      final repo = ref.read(athleteRepositoryProvider);
      final profile = await repo.updateVisibility(
        profileVisibility,
        isSearchable,
        locationVisibility: locationVisibility,
      );
      state = AsyncData(profile);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateLocationVisibility(String locationVisibility) async {
    final normalized = locationVisibility.trim().toUpperCase();
    if (normalized != 'AREA' && normalized != 'TRAVEL_ONLY' && normalized != 'GHOST') {
      return false;
    }
    try {
      final current = state.value ?? <String, dynamic>{};
      final profileVisibility =
          (current['profileVisibility']?.toString() ?? 'PUBLIC').toUpperCase();
      final isSearchable = current['isSearchable'] is bool
          ? current['isSearchable'] as bool
          : true;
      final repo = ref.read(athleteRepositoryProvider);
      final updated = await repo.updateVisibility(
        profileVisibility,
        isSearchable,
        locationVisibility: normalized,
      );
      state = AsyncData({
        ...current,
        ...updated,
        'locationVisibility': normalized,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateProfileAndBiometrics({
    required String athleteId,
    required Map<String, dynamic> profileData,
    Map<String, dynamic>? biometricsData,
  }) async {
    try {
      final repo = ref.read(athleteRepositoryProvider);
      if (profileData.isNotEmpty) {
        await repo.updateProfile(athleteId, profileData);
      }
      if (biometricsData != null && biometricsData.isNotEmpty) {
        await repo.updateBiometricsDetails(biometricsData);
      }
      final refreshed = await repo.getProfile(athleteId);
      state = AsyncData(refreshed);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final athleteProfileProvider = AsyncNotifierProvider.autoDispose<AthleteProfileNotifier, Map<String, dynamic>>(() {
  return AthleteProfileNotifier();
});

final athleteSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final athleteSearchProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final query = ref.watch(athleteSearchQueryProvider);
  if (query.isEmpty) return [];
  final repo = ref.watch(athleteRepositoryProvider);
  return repo.searchAthletes(query);
});

final clubsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  ref.keepAlive();
  final repo = ref.watch(athleteRepositoryProvider);
  return repo.getClubs();
});

final publicAthleteProfileProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, athleteId) async {
  ref.keepAlive();
  final repo = ref.watch(athleteRepositoryProvider);
  return repo.getProfile(athleteId);
});

final trainingLogProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, athleteId) async {
  ref.keepAlive();
  final repo = ref.watch(athleteRepositoryProvider);
  return repo.getTrainingLog(athleteId);
});

final trainingLogPRsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, athleteId) async {
  ref.keepAlive();
  final repo = ref.watch(athleteRepositoryProvider);
  return repo.getTrainingLogPRs(athleteId);
});

final athleteMatchesProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, athleteId) async {
  ref.keepAlive();
  final repo = ref.watch(matchRepositoryProvider);
  return repo.getMatchHistory(athleteId);
});
