import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state_providers.dart';

class SettingsNotifier extends AutoDisposeAsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() async {
    final repo = ref.watch(messagingRepositoryProvider);
    return repo.getPreferences();
  }

  Future<void> updatePreference({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? smsEnabled,
  }) async {
    final repo = ref.read(messagingRepositoryProvider);
    final current = state.value ?? {};
    
    final updates = {
      'pushEnabled': pushEnabled ?? current['pushEnabled'] ?? true,
      'emailEnabled': emailEnabled ?? current['emailEnabled'] ?? true,
      'smsEnabled': smsEnabled ?? current['smsEnabled'] ?? true,
    };

    // Optimistically update the state
    state = AsyncValue.data({
      ...current,
      ...updates,
    });

    try {
      final result = await repo.updatePreferences(updates);
      state = AsyncValue.data(result);
    } catch (e, st) {
      // Revert if it fails
      state = AsyncValue.error(e, st);
    }
  }
}

final settingsProvider = AsyncNotifierProvider.autoDispose<SettingsNotifier, Map<String, dynamic>>(() {
  return SettingsNotifier();
});
