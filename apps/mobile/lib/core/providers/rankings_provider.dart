import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state_providers.dart';

/// Leaderboard filter state. Only dimensions the backend actually filters on
/// are exposed (arm / province / search); division and weightClass are
/// accepted-but-unfiltered server-side, so they are deliberately not offered.
final rankingsArmProvider = StateProvider<String>((ref) => 'RIGHT');
final rankingsProvinceProvider = StateProvider<String>((ref) => '');
final rankingsSearchQueryProvider = StateProvider<String>((ref) => '');

class RankingsNotifier extends AutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final repo = ref.watch(rankingsRepositoryProvider);
    final arm = ref.watch(rankingsArmProvider);
    final province = ref.watch(rankingsProvinceProvider);
    final search = ref.watch(rankingsSearchQueryProvider);
    return await repo.getLeaderboards(
      arm: arm,
      province: province.isEmpty ? null : province,
      search: search.isEmpty ? null : search,
      limit: 100,
    );
  }
}

final rankingsProvider = AsyncNotifierProvider.autoDispose<RankingsNotifier, List<Map<String, dynamic>>>(() {
  return RankingsNotifier();
});
