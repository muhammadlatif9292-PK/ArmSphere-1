import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state_providers.dart';
import '../../features/auth/providers/auth_provider.dart';

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
    ref.invalidate(eventMatchesProvider(eventId));
    ref.invalidate(eventLiveArenaTablesProvider(eventId));
    ref.invalidate(matchTablesProvider);
    ref.invalidate(refereeDirectoryProvider);
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

final eventAwardsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, eventId) async {
  final repo = ref.watch(tournamentRepositoryProvider);
  return repo.getAwards(eventId: eventId);
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

/// Every bracket match in one event (match-day board + referee assignments).
final eventMatchesProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, eventId) async {
  final repo = ref.watch(tournamentRepositoryProvider);
  return repo.getEventMatches(eventId: eventId);
});

/// Physical match tables (IDLE/ACTIVE) used for match calls.
final matchTablesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(tournamentRepositoryProvider);
  return repo.listTables();
});

/// Referee directory (admin surface; director roles only).
final refereeDirectoryProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(tournamentRepositoryProvider);
  return repo.listReferees();
});

final ticketTypesProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, eventId) async {
  final repo = ref.watch(tournamentRepositoryProvider);
  return repo.getTicketTypes(eventId: eventId);
});

final myTicketsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(tournamentRepositoryProvider);
  return repo.getMyTickets();
});

/// Live active arena tables for an event (IN_PROGRESS, CALLED, READY matches mapped to arena tables).
final eventLiveArenaTablesProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, eventId) async {
  final repo = ref.watch(tournamentRepositoryProvider);

  // Gather all brackets for this event
  final allBrackets = await repo.listBrackets();
  final eventBrackets = allBrackets.where((b) => b['eventId']?.toString() == eventId).toList();

  List<Map<String, dynamic>> matches = [];

  // Check if current user has an operator/referee role
  final auth = ref.watch(authProvider);
  final role = auth.userProfile?['role']?.toString().toUpperCase();
  const operatorRoles = {'REFEREE', 'PROVINCIAL_DIRECTOR', 'NATIONAL_DIRECTOR', 'SYSTEM_ADMIN'};
  final isOperator = operatorRoles.contains(role);

  if (isOperator) {
    try {
      matches = await repo.getEventMatches(eventId: eventId);
    } catch (_) {
      matches = [];
    }
  }

  // If not operator or if getEventMatches is empty, fetch matches via bracket details
  if (matches.isEmpty && eventBrackets.isNotEmpty) {
    final detailFutures = eventBrackets.map((b) async {
      try {
        final detail = await repo.getBracket(b['id'].toString());
        final rawMatches = (detail['matches'] as List?) ?? [];
        return rawMatches.map((m) {
          final map = Map<String, dynamic>.from(m as Map);
          map['bracketName'] = detail['name'];
          map['division'] = detail['division'];
          map['weightClass'] = detail['weightClass'];
          map['arm'] = detail['arm'];
          map['bracketId'] = detail['id'];
          return map;
        }).toList();
      } catch (_) {
        return <Map<String, dynamic>>[];
      }
    });
    final results = await Future.wait(detailFutures);
    matches = results.expand((list) => list).toList();
  }

  // Fetch table names if accessible
  Map<String, String> tableNames = {};
  if (isOperator) {
    try {
      final tables = await repo.listTables();
      for (final t in tables) {
        if (t['id'] != null && t['name'] != null) {
          tableNames[t['id'].toString()] = t['name'].toString();
        }
      }
    } catch (_) {}
  }

  // Filter for live/active matches (IN_PROGRESS, CALLED, READY)
  const activeStatuses = {'IN_PROGRESS', 'CALLED', 'READY'};
  final activeMatches = matches.where((m) {
    final s = (m['status']?.toString() ?? '').toUpperCase();
    if (!activeStatuses.contains(s)) return false;
    final a = m['athleteAName']?.toString() ?? '';
    final b = m['athleteBName']?.toString() ?? '';
    return a.isNotEmpty || b.isNotEmpty;
  }).toList();

  // Sort priority: IN_PROGRESS (0) -> CALLED (1) -> READY (2), then round & matchIndex
  int statusPriority(String s) {
    switch (s.toUpperCase()) {
      case 'IN_PROGRESS':
        return 0;
      case 'CALLED':
        return 1;
      case 'READY':
        return 2;
      default:
        return 3;
    }
  }

  activeMatches.sort((a, b) {
    final pA = statusPriority(a['status']?.toString() ?? '');
    final pB = statusPriority(b['status']?.toString() ?? '');
    if (pA != pB) return pA.compareTo(pB);
    final rA = (a['round'] as num?)?.toInt() ?? 0;
    final rB = (b['round'] as num?)?.toInt() ?? 0;
    if (rA != rB) return rA.compareTo(rB);
    final iA = (a['matchIndex'] as num?)?.toInt() ?? 0;
    final iB = (b['matchIndex'] as num?)?.toInt() ?? 0;
    return iA.compareTo(iB);
  });

  return List.generate(activeMatches.length, (index) {
    final m = activeMatches[index];
    final rawStatus = (m['status']?.toString() ?? '').toUpperCase();
    final tableId = m['tableId']?.toString();
    final hasNamedTable = tableId != null && tableNames.containsKey(tableId);

    final tableNumber = hasNamedTable
        ? tableNames[tableId]!.toUpperCase()
        : 'TABLE ${index + 1}';

    final stageName = m['bracketName']?.toString().isNotEmpty == true
        ? m['bracketName'].toString()
        : (hasNamedTable ? 'Main Stage' : 'Arena Table ${index + 1}');

    String statusLabel;
    if (rawStatus == 'IN_PROGRESS') {
      statusLabel = 'IN BOUT';
    } else if (rawStatus == 'CALLED') {
      statusLabel = 'ON DECK';
    } else {
      statusLabel = 'READY';
    }

    final isLive = rawStatus == 'IN_PROGRESS';

    final div = (m['division']?.toString() ?? '').toUpperCase();
    final wt = (m['weightClass']?.toString() ?? '').toUpperCase();
    final arm = (m['arm']?.toString() ?? '').toUpperCase();

    String weightClassFormatted;
    if (wt.isNotEmpty && arm.isNotEmpty) {
      weightClassFormatted = '$wt · $arm ARM';
    } else if (wt.isNotEmpty) {
      weightClassFormatted = wt;
    } else if (div.isNotEmpty && arm.isNotEmpty) {
      weightClassFormatted = '$div · $arm ARM';
    } else {
      weightClassFormatted = m['bracketName']?.toString() ?? 'OPEN CATEGORY';
    }

    return {
      'id': m['id'],
      'bracketId': m['bracketId'],
      'tableNumber': tableNumber,
      'stageName': stageName,
      'status': statusLabel,
      'rawStatus': rawStatus,
      'isLive': isLive,
      'weightClass': weightClassFormatted,
      'division': div,
      'arm': arm,
      'rawWeightClass': wt,
      'redCornerName': m['athleteAName']?.toString() ?? 'TBD',
      'redCornerCountry': m['athleteACountry']?.toString() ?? '',
      'blueCornerName': m['athleteBName']?.toString() ?? 'TBD',
      'blueCornerCountry': m['athleteBCountry']?.toString() ?? '',
      'round': m['round'],
      'matchIndex': m['matchIndex'],
    };
  });
});
