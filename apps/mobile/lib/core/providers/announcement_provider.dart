import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state_providers.dart';

class AnnouncementsNotifier extends AutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    ref.keepAlive();
    final repo = ref.watch(messagingRepositoryProvider);
    return repo.getAnnouncements();
  }

  Future<void> refresh({bool silent = true}) async {
    if (!silent || !state.hasValue) {
      state = const AsyncValue.loading();
    }
    try {
      final repo = ref.read(messagingRepositoryProvider);
      final items = await repo.getAnnouncements();
      state = AsyncValue.data(items);
    } catch (e, st) {
      if (!state.hasValue) {
        state = AsyncValue.error(e, st);
      }
    }
  }
}

final announcementsProvider = AsyncNotifierProvider.autoDispose<AnnouncementsNotifier, List<Map<String, dynamic>>>(() {
  return AnnouncementsNotifier();
});
