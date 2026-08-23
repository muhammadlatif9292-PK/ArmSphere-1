import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'dependency_providers.dart';

class SessionNotifier extends AutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final dioClient = ref.watch(dioClientProvider);
    final response = await dioClient.dio.get('/auth/sessions');
    
    final body = response.data;
    final payload = (body is Map && body.containsKey('data'))
        ? body['data']
        : body;
        
    if (payload is List) {
      return payload.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  Future<bool> revokeSession(String sessionId) async {
    try {
      final dioClient = ref.read(dioClientProvider);
      await dioClient.dio.post('/auth/sessions/$sessionId/revoke');
      ref.invalidateSelf();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> revokeOthers() async {
    try {
      final dioClient = ref.read(dioClientProvider);
      await dioClient.dio.post('/auth/sessions/revoke-others');
      ref.invalidateSelf();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final sessionProvider = AsyncNotifierProvider.autoDispose<SessionNotifier, List<Map<String, dynamic>>>(() {
  return SessionNotifier();
});
