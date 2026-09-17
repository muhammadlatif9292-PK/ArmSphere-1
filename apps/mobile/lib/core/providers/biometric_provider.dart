import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/biometric_service.dart';
import 'dependency_providers.dart';

export '../services/biometric_service.dart';

/// Provider for [BiometricService] using the app's configured [SecureStorage].
final biometricServiceProvider = Provider<BiometricService>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return BiometricService(secureStorage: secureStorage);
});

/// Evaluates device hardware support and user credential enrollment.
final biometricCapabilityProvider = FutureProvider<BiometricCapability>((ref) async {
  final service = ref.watch(biometricServiceProvider);
  return await service.getCapability();
});

/// Manages the user's Biometric Unlock toggle state with verified transitions.
class BiometricEnabledNotifier extends StateNotifier<AsyncValue<bool>> {
  final BiometricService _service;

  BiometricEnabledNotifier(this._service) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final enabled = await _service.isBiometricsEnabled();
      state = AsyncValue.data(enabled);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Toggles biometric unlock.
  /// If [enable] is true, prompts biometric authentication before persisting.
  /// Returns true if the state was successfully updated, false otherwise.
  Future<bool> toggle(bool enable, {String? localizedReason}) async {
    state = const AsyncValue.loading();
    try {
      final success = await _service.setBiometricsEnabled(
        enable,
        localizedReason: localizedReason,
      );
      final current = await _service.isBiometricsEnabled();
      state = AsyncValue.data(current);
      return success;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Refreshes state from storage (e.g. after background or session switch).
  Future<void> refresh() => _load();
}

/// Reactive provider for the Biometric Unlock enabled preference.
final biometricEnabledProvider =
    StateNotifierProvider<BiometricEnabledNotifier, AsyncValue<bool>>((ref) {
  final service = ref.watch(biometricServiceProvider);
  return BiometricEnabledNotifier(service);
});
