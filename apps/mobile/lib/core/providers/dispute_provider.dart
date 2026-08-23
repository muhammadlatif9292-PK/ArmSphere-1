import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state_providers.dart';

class DisputeNotifier extends AutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final repo = ref.watch(disputeRepositoryProvider);
    return repo.getDisputes();
  }

  Future<bool> submitDispute(Map<String, dynamic> payload) async {
    try {
      final repo = ref.read(disputeRepositoryProvider);
      await repo.submitDispute(payload);
      ref.invalidateSelf();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final disputeProvider = AsyncNotifierProvider.autoDispose<DisputeNotifier, List<Map<String, dynamic>>>(() {
  return DisputeNotifier();
});
