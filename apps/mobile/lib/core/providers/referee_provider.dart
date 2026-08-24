import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'dependency_providers.dart';

class RefereeNotifier extends AutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final dioClient = ref.watch(dioClientProvider);
    final response = await dioClient.dio.get('/matches');
    final body = response.data;
    final payload = (body is Map && body.containsKey('data'))
        ? body['data']
        : body;

    if (payload is List) {
      return payload.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  Future<bool> verifyMatch(String matchId, {required int scoreA, required int scoreB}) async {
    try {
      final dioClient = ref.read(dioClientProvider);
      await dioClient.dio.post('/matches/$matchId/verify', data: {
        'scoreA': scoreA,
        'scoreB': scoreB,
        'status': 'VERIFIED',
      });
      ref.invalidateSelf();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> submitMatchScorepad(Map<String, dynamic> matchData) async {
    try {
      final dioClient = ref.read(dioClientProvider);
      await dioClient.dio.post('/matches', data: matchData);
      ref.invalidateSelf();
      return true;
    } catch (_) {
      return false;
    }
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
