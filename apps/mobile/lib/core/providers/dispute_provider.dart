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

  /// Escalates a dispute; returns null on failure so callers can surface errors.
  Future<Map<String, dynamic>?> escalateDispute(String disputeId, String escalationReason) async {
    try {
      final repo = ref.read(disputeRepositoryProvider);
      final updated = await repo.escalateDispute(disputeId, escalationReason);
      ref.invalidateSelf();
      return updated;
    } catch (_) {
      return null;
    }
  }

  /// Appeals a resolved/rejected dispute; returns null on failure.
  Future<Map<String, dynamic>?> appealDispute(String disputeId, String appealReason) async {
    try {
      final repo = ref.read(disputeRepositoryProvider);
      final updated = await repo.appealDispute(disputeId, appealReason);
      ref.invalidateSelf();
      return updated;
    } catch (_) {
      return null;
    }
  }

  /// Submits evidence (VIDEO/IMAGE/DOCUMENT + URL) for a dispute.
  Future<bool> submitEvidence(String disputeId, String fileType, String fileUrl) async {
    try {
      final repo = ref.read(disputeRepositoryProvider);
      await repo.submitDisputeEvidence(disputeId, fileType, fileUrl);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final disputeProvider = AsyncNotifierProvider.autoDispose<DisputeNotifier, List<Map<String, dynamic>>>(() {
  return DisputeNotifier();
});
