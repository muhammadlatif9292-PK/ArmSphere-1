import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'dependency_providers.dart';

class PaymentMethodsNotifier extends AutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final dioClient = ref.watch(dioClientProvider);
    final response = await dioClient.dio.get('/payments/methods');
    if (response.statusCode == 200 && response.data != null) {
      final success = response.data['success'] == true;
      if (success && response.data['data'] != null) {
        final list = response.data['data'] as List<dynamic>;
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
    if (response.statusCode == 201 && response.data != null) {
      return Map<String, dynamic>.from(response.data);
    }
    throw Exception('Failed to create SetupIntent: ${response.data}');
  }
}

final paymentMethodsProvider = AsyncNotifierProvider.autoDispose<PaymentMethodsNotifier, List<Map<String, dynamic>>>(() {
  return PaymentMethodsNotifier();
});
