import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state_providers.dart';

// 1. Notifier to manage user's own nominations list
class NominationListNotifier extends AutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final repo = ref.watch(nominationRepositoryProvider);
    return repo.getOwnNominations();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(nominationRepositoryProvider);
      final nominations = await repo.getOwnNominations();
      state = AsyncValue.data(nominations);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final nominationListProvider = AsyncNotifierProvider.autoDispose<NominationListNotifier, List<Map<String, dynamic>>>(() {
  return NominationListNotifier();
});

// 2. Notifier for submitting a new Nomination
class NominationSubmissionNotifier extends AutoDisposeAsyncNotifier<Map<String, dynamic>?> {
  @override
  Future<Map<String, dynamic>?> build() async {
    return null;
  }

  Future<void> submit({
    required String nomineeName,
    required String city,
    required String province,
    String? nomineeContact,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(nominationRepositoryProvider);
      final newNomination = await repo.submitNomination(
        nomineeName: nomineeName,
        city: city,
        province: province,
        nomineeContact: nomineeContact,
        notes: notes,
      );
      state = AsyncValue.data(newNomination);
      
      // Invalidate list to trigger reload
      ref.invalidate(nominationListProvider);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}

final nominationSubmissionProvider = AsyncNotifierProvider.autoDispose<NominationSubmissionNotifier, Map<String, dynamic>?>(() {
  return NominationSubmissionNotifier();
});
