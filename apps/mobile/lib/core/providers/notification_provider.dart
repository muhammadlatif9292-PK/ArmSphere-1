import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state_providers.dart';
import '../../features/auth/providers/auth_provider.dart';

class NotificationNotifier extends AutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    ref.keepAlive();
    ref.watch(authSessionScopeProvider);
    final repo = ref.watch(notificationRepositoryProvider);
    return repo.getNotifications();
  }

  Future<void> markAsRead(String notificationId) async {
    final repo = ref.read(notificationRepositoryProvider);
    await repo.markAsRead(notificationId);
    ref.invalidateSelf();
  }
}

final notificationProvider = AsyncNotifierProvider.autoDispose<NotificationNotifier, List<Map<String, dynamic>>>(() {
  return NotificationNotifier();
});
