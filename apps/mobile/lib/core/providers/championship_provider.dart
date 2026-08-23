import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state_providers.dart';

class ChampionshipNotifier extends AutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final repo = ref.watch(championshipRepositoryProvider);
    return repo.getActiveTitles();
  }
}

final championshipProvider = AsyncNotifierProvider.autoDispose<ChampionshipNotifier, List<Map<String, dynamic>>>(() {
  return ChampionshipNotifier();
});

final beltLineageProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, titleId) async {
  final repo = ref.watch(championshipRepositoryProvider);
  return repo.getBeltLineage(titleId);
});
