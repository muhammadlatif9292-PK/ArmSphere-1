import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state_providers.dart';
import '../../features/auth/providers/auth_provider.dart';

class AthleteProfileNotifier extends AutoDisposeAsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() async {
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

  Future<bool> updateVisibility({required String profileVisibility, required bool isSearchable}) async {
    try {
      final repo = ref.read(athleteRepositoryProvider);
      final profile = await repo.updateVisibility(profileVisibility, isSearchable);
      state = AsyncData(profile);
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

final publicAthleteProfileProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, athleteId) async {
  final repo = ref.watch(athleteRepositoryProvider);
  return repo.getProfile(athleteId);
});

final trainingLogProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, athleteId) async {
  final repo = ref.watch(athleteRepositoryProvider);
  return repo.getTrainingLog(athleteId);
});

final trainingLogPRsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, athleteId) async {
  final repo = ref.watch(athleteRepositoryProvider);
  return repo.getTrainingLogPRs(athleteId);
});

