import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'dependency_providers.dart';

class RefereeNotifier extends AutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    // Real federation referee directory (admin surface). Returns
    // { success, data } envelope with referee users + certification metrics.
    final dioClient = ref.watch(dioClientProvider);
    final response = await dioClient.dio.get('/admin/referees');
    final body = response.data;
    final payload = (body is Map && body.containsKey('data'))
        ? body['data']
        : body;

    if (payload is List) {
      return payload.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }
}

final refereeProvider = AsyncNotifierProvider.autoDispose<RefereeNotifier, List<Map<String, dynamic>>>(() {
  return RefereeNotifier();
});

final refereeCertificationsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final auth = ref.watch(authProvider);
  final userId = auth.userProfile?['id'] ?? auth.userProfile?['userId'] ?? '';
  if (userId.isEmpty) return [];

  try {
    final dioClient = ref.watch(dioClientProvider);
    final response = await dioClient.dio.get('/referees/$userId/certifications');
    final body = response.data;
    final payload = (body is Map && body.containsKey('data'))
        ? body['data']
        : body;

    if (payload is List) {
      return payload.map((e) => Map<String, dynamic>.from(e)).toList();
    }
  } catch (_) {
    // If endpoint fails or is not found, return empty array gracefully
  }
  return [];
});
