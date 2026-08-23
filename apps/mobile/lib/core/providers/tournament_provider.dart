import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state_providers.dart';

class TournamentNotifier extends AutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final repo = ref.watch(tournamentRepositoryProvider);
    return repo.getTournaments();
  }

  Future<Map<String, dynamic>?> registerAthlete({
    required String eventId,
    required String athleteId,
    required String division,
    required String weightClass,
    required String arm,
    String? notes,
  }) async {
    try {
      final repo = ref.read(tournamentRepositoryProvider);
      final response = await repo.registerAthlete(
        eventId: eventId,
        athleteId: athleteId,
        division: division,
        weightClass: weightClass,
        arm: arm,
        notes: notes,
      );
      ref.invalidateSelf();
      return response;
    } catch (_) {
      return null;
    }
  }

  Future<bool> patchEvent({
    required String eventId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final repo = ref.read(tournamentRepositoryProvider);
      await repo.patchEvent(eventId: eventId, data: data);
      ref.invalidateSelf();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> confirmManualPayment({
    required String registrationId,
    required String eventId,
  }) async {
    try {
      final repo = ref.read(tournamentRepositoryProvider);
      await repo.confirmManualPayment(registrationId: registrationId);
      ref.invalidate(eventRegistrationsProvider(eventId));
      return true;
    } catch (_) {
      return false;
    }
  }
}

final tournamentProvider = AsyncNotifierProvider.autoDispose<TournamentNotifier, List<Map<String, dynamic>>>(() {
  return TournamentNotifier();
});

final eventRegistrationsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, eventId) async {
  final repo = ref.watch(tournamentRepositoryProvider);
  return repo.getEventRegistrations(eventId: eventId);
});

final bracketDetailsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, bracketId) async {
  final repo = ref.watch(tournamentRepositoryProvider);
  return repo.getBracket(bracketId);
});

final bracketsListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(tournamentRepositoryProvider);
  return repo.listBrackets();
});

final ticketTypesProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, eventId) async {
  final repo = ref.watch(tournamentRepositoryProvider);
  return repo.getTicketTypes(eventId: eventId);
});

final myTicketsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(tournamentRepositoryProvider);
  return repo.getMyTickets();
});
