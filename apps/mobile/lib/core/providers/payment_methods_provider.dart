import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dependency_providers.dart';

final paymentConfiguredProvider = StateProvider<bool>((ref) => true);

class PaymentMethodsNotifier extends AutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final dioClient = ref.watch(dioClientProvider);
    final response = await dioClient.dio.get('/payments/methods');
    if (response.statusCode == 200 && response.data is Map) {
      final body = response.data as Map;
      final meta = body['meta'];
      final bool configuredFromMeta =
          meta is Map && meta['paymentConfigured'] is bool
              ? meta['paymentConfigured'] as bool
              : true;
      final bool enabledFlag =
          body['enabled'] is bool ? body['enabled'] as bool : configuredFromMeta;
      ref.read(paymentConfiguredProvider.notifier).state =
          configuredFromMeta && enabledFlag;
      final success = body['success'] == true;
      if (success && body['data'] is List) {
        final list = body['data'] as List<dynamic>;
        return list.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    }
    return [];
  }

  Future<void> deletePaymentMethod(String id) async {
    final dioClient = ref.read(dioClientProvider);
    await dioClient.dio.delete('/payments/methods/$id');
    
    // Refresh the list state locally after deletion
    ref.invalidateSelf();
  }

  Future<Map<String, dynamic>> createSetupIntent() async {
    final dioClient = ref.read(dioClientProvider);
    final response = await dioClient.dio.post('/payments/setup-intent');
    if ((response.statusCode == 201 || response.statusCode == 200) && response.data is Map) {
      final data = Map<String, dynamic>.from(response.data as Map);
      if (data['enabled'] == false) {
        ref.read(paymentConfiguredProvider.notifier).state = false;
      }
      return data;
    }
    throw Exception('Failed to create SetupIntent: ${response.data}');
  }
}

final paymentMethodsProvider = AsyncNotifierProvider.autoDispose<PaymentMethodsNotifier, List<Map<String, dynamic>>>(() {
  return PaymentMethodsNotifier();
});
