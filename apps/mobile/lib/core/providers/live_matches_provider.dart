import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state_providers.dart';
import 'athlete_provider.dart';

// AsyncNotifier with optimistic update capabilities
class LiveMatchesNotifier extends AutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>> > build() async {
    // Match rows are keyed by athlete PROFILE ids (athlete_profiles.id), which
    // differ from auth user ids — resolve through the profile provider first.
    final profile = await ref.watch(athleteProfileProvider.future);
    final athleteId = profile['id']?.toString();
    if (athleteId == null || athleteId.isEmpty) return [];
    final repo = ref.watch(matchRepositoryProvider);
    return repo.getMatchHistory(athleteId);
  }

  /// Submits match with optimistic update pattern for high UI responsiveness
  Future<void> submitMatchOptimistic(Map<String, dynamic> matchPayload) async {
    final originalState = state;
    
    // 1. Construct temporary optimistic record
    final optimisticRecord = {
      'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
      'opponentName': matchPayload['opponentName'] ?? 'Unknown Opponent',
      'divisionName': matchPayload['divisionName'] ?? 'Middleweight',
      'score': matchPayload['score'] ?? '0-0',
      'isPendingSync': true,
      'createdAt': DateTime.now().toIso8601String(),
    };

    // 2. Optimistically update local Riverpod state immediately
    state = AsyncData([optimisticRecord, ...?state.value]);

    try {
      final repo = ref.read(matchRepositoryProvider);
      await repo.submitMatchResult(matchPayload);

      // Refresh database to overwrite with real server state
      ref.invalidateSelf();
    } catch (e) {
      // Rollback to original valid server state on total network exception,
      // then rethrow so callers can surface the real backend error.
      state = originalState;
      rethrow;
    }
  }
}

final liveMatchesProvider = AsyncNotifierProvider.autoDispose<LiveMatchesNotifier, List<Map<String, dynamic>>>(() {
  return LiveMatchesNotifier();
});
