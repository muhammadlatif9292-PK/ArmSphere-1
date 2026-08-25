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
      _refreshEventScopes(eventId);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _refreshEventScopes(String eventId) {
    ref.invalidate(eventRegistrationsProvider(eventId));
    ref.invalidate(eventStatsProvider(eventId));
    ref.invalidate(eventBracketsProvider(eventId));
  }

  /// Runs a lifecycle mutation and refreshes every event-scoped list on success.
  /// Rethrows so the console can surface the backend's real error message.
  Future<Map<String, dynamic>> runLifecycleAction({
    required String eventId,
    required Future<Map<String, dynamic>> Function() action,
  }) async {
    final result = await action();
    _refreshEventScopes(eventId);
    return result;
  }
}

final tournamentProvider = AsyncNotifierProvider.autoDispose<TournamentNotifier, List<Map<String, dynamic>>>(() {
  return TournamentNotifier();
});

final eventDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, eventId) async {
  final repo = ref.watch(tournamentRepositoryProvider);
  return repo.getEventById(eventId: eventId);
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

/// Brackets belonging to one event. The API lists all brackets without an
/// eventId filter, so the scoping happens client-side.
final eventBracketsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, eventId) async {
  final repo = ref.watch(tournamentRepositoryProvider);
  final all = await repo.listBrackets();
  return all.where((b) => b['eventId']?.toString() == eventId).toList();
});

final eventStatsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, eventId) async {
  final repo = ref.watch(tournamentRepositoryProvider);
  return repo.getEventStats(eventId: eventId);
});

final ticketTypesProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, eventId) async {
  final repo = ref.watch(tournamentRepositoryProvider);
  return repo.getTicketTypes(eventId: eventId);
});

final myTicketsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(tournamentRepositoryProvider);
  return repo.getMyTickets();
});
