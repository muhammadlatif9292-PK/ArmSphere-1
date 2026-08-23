import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state_providers.dart';

class AnnouncementsNotifier extends AutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final repo = ref.watch(messagingRepositoryProvider);
    return repo.getAnnouncements();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(messagingRepositoryProvider);
      return repo.getAnnouncements();
    });
  }
}

final announcementsProvider = AsyncNotifierProvider.autoDispose<AnnouncementsNotifier, List<Map<String, dynamic>>>(() {
  return AnnouncementsNotifier();
});
