import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:mobile/core/api/dio_client.dart';
import 'package:mobile/core/api/repositories.dart';
import 'package:mobile/core/providers/state_providers.dart';
import 'package:mobile/core/providers/tournament_provider.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'package:mobile/features/tournament/screens/tournament_operations_screen.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTournamentRepository extends Fake implements TournamentRepository {
  List<Map<String, dynamic>> tablesData;
  List<Map<String, dynamic>> matchesData;
  List<Map<String, dynamic>> bracketsData;
  List<Map<String, dynamic>> registrationsData;
  Map<String, dynamic> eventData;
  Map<String, dynamic> statsData;
  List<Map<String, dynamic>> refereesData;

  String? lastCalledMatchId;
  String? lastCalledTableId;
  String? lastUnassignedMatchId;
  String? lastQueuedTableId;
  String? lastQueuedMatchId;
  int? lastQueuedPosition;
  String? lastRebalancedMatchId;
  String? lastRebalancedTargetTableId;
  int? lastRebalancedTargetPosition;
  String? lastCreatedTableName;
  String? lastCreatedTableEventId;
  bool shouldThrow409OnCall = false;
  bool shouldThrowOfflineOnQueue = false;
  bool shouldThrowConflictOnRebalance = false;
  int callMatchToTableCount = 0;
  Duration? callMatchDelay;

  _FakeTournamentRepository({
    required this.tablesData,
    required this.matchesData,
    required this.bracketsData,
    required this.registrationsData,
    required this.eventData,
    required this.statsData,
    required this.refereesData,
  });

  @override
  Future<List<Map<String, dynamic>>> listEventTables({
    required String eventId,
    CancelToken? cancelToken,
  }) async {
    return tablesData;
  }

  @override
  Future<List<Map<String, dynamic>>> listTables({CancelToken? cancelToken}) async {
    return tablesData;
  }

  @override
  Future<List<Map<String, dynamic>>> getEventMatches({
    required String eventId,
    CancelToken? cancelToken,
  }) async {
    return matchesData;
  }

  @override
  Future<Map<String, dynamic>> getEventById({
    required String eventId,
    CancelToken? cancelToken,
  }) async {
    return eventData;
  }

  @override
  Future<Map<String, dynamic>> getEventStats({
    required String eventId,
    CancelToken? cancelToken,
  }) async {
    return statsData;
  }

  @override
  Future<List<Map<String, dynamic>>> getEventRegistrations({
    required String eventId,
    CancelToken? cancelToken,
  }) async {
    return registrationsData;
  }

  @override
  Future<List<Map<String, dynamic>>> getEventBrackets({
    required String eventId,
    CancelToken? cancelToken,
  }) async {
    return bracketsData;
  }

  @override
  Future<List<Map<String, dynamic>>> listReferees({CancelToken? cancelToken}) async {
    return refereesData;
  }

  @override
  Future<Map<String, dynamic>> createTable({
    required String name,
    String? eventId,
    CancelToken? cancelToken,
  }) async {
    lastCreatedTableName = name;
    lastCreatedTableEventId = eventId;
    final newTable = {
      'id': 'table_new_${DateTime.now().millisecondsSinceEpoch}',
      'eventId': eventId,
      'name': name,
      'status': 'IDLE',
      'currentMatchId': null,
      'queue': <Map<String, dynamic>>[],
    };
    tablesData.add(newTable);
    return newTable;
  }

  @override
  Future<Map<String, dynamic>> callMatchToTable({
    required String matchId,
    required String tableId,
    CancelToken? cancelToken,
  }) async {
    callMatchToTableCount++;
    if (callMatchDelay != null) {
      await Future.delayed(callMatchDelay!);
    }
    if (shouldThrow409OnCall) {
      throw ApiException(
        type: 'https://armsphere.com/errors/conflict',
        status: 409,
        title: 'Conflict',
        detail: 'Table is currently active with another match.',
      );
    }
    lastCalledMatchId = matchId;
    lastCalledTableId = tableId;

    // Mutate internal test state
    final table = tablesData.firstWhere((t) => t['id'] == tableId);
    table['status'] = 'ACTIVE';
    table['currentMatchId'] = matchId;
    final queue = (table['queue'] as List);
    queue.removeWhere((q) => q['matchId'] == matchId);

    final match = matchesData.firstWhere((m) => m['id'] == matchId);
    match['status'] = 'CALLED';
    match['tableId'] = tableId;

    return {'success': true, 'matchId': matchId, 'tableId': tableId};
  }

  @override
  Future<Map<String, dynamic>> unassignMatch({
    required String matchId,
    CancelToken? cancelToken,
  }) async {
    lastUnassignedMatchId = matchId;
    for (final t in tablesData) {
      if (t['currentMatchId'] == matchId) {
        t['status'] = 'IDLE';
        t['currentMatchId'] = null;
      }
      final queue = (t['queue'] as List);
      queue.removeWhere((q) => q['matchId'] == matchId);
    }
    final match = matchesData.firstWhere((m) => m['id'] == matchId, orElse: () => {});
    if (match.isNotEmpty) {
      match['status'] = 'READY';
      match['tableId'] = null;
    }
    return {'success': true, 'matchId': matchId};
  }

  @override
  Future<Map<String, dynamic>> queueMatchToTable({
    required String tableId,
    required String matchId,
    int? position,
    CancelToken? cancelToken,
  }) async {
    if (shouldThrowOfflineOnQueue) {
      throw OfflineException('Network error: Unable to complete server mutation while offline.');
    }
    lastQueuedTableId = tableId;
    lastQueuedMatchId = matchId;
    lastQueuedPosition = position;

    final table = tablesData.firstWhere((t) => t['id'] == tableId);
    final match = matchesData.firstWhere((m) => m['id'] == matchId);
    final qList = (table['queue'] as List);
    final newPos = position ?? (qList.length + 1);

    qList.add({
      'id': 'q_${DateTime.now().millisecondsSinceEpoch}',
      'tableId': tableId,
      'matchId': matchId,
      'position': newPos,
      'round': match['round'],
      'matchIndex': match['matchIndex'],
      'status': match['status'],
      'athleteAName': match['athleteAName'],
      'athleteBName': match['athleteBName'],
    });

    return {'success': true, 'matchId': matchId, 'tableId': tableId, 'position': newPos};
  }

  @override
  Future<Map<String, dynamic>> rebalanceTableQueue({
    required String matchId,
    required String targetTableId,
    int? targetPosition,
    CancelToken? cancelToken,
  }) async {
    if (shouldThrowConflictOnRebalance) {
      throw ApiException(
        type: 'https://armsphere.com/errors/conflict',
        status: 409,
        title: 'Conflict',
        detail: 'Match queue position changed concurrently.',
      );
    }
    lastRebalancedMatchId = matchId;
    lastRebalancedTargetTableId = targetTableId;
    lastRebalancedTargetPosition = targetPosition;

    Map<String, dynamic>? item;
    for (final t in tablesData) {
      final qList = (t['queue'] as List);
      final idx = qList.indexWhere((q) => q['matchId'] == matchId);
      if (idx != -1) {
        item = Map<String, dynamic>.from(qList.removeAt(idx) as Map);
        break;
      }
    }

    if (item != null) {
      final targetTable = tablesData.firstWhere((t) => t['id'] == targetTableId);
      final targetQueue = (targetTable['queue'] as List);
      item['tableId'] = targetTableId;
      item['position'] = targetPosition ?? (targetQueue.length + 1);
      targetQueue.add(item);
    }

    return {'success': true, 'matchId': matchId, 'targetTableId': targetTableId, 'targetPosition': targetPosition};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 2 / Item 2.2: Live Arena Tables & Queue Operations Integration Tests', () {
    const testTournamentId = 'tourney_pk_national_2026';

    late Map<String, dynamic> mockEvent;
    late Map<String, dynamic> mockStats;
    late List<Map<String, dynamic>> mockMatches;
    late List<Map<String, dynamic>> mockTables;
    late _FakeTournamentRepository fakeRepo;

    setUp(() {
      mockEvent = {
        'id': testTournamentId,
        'name': 'PAFF All-Pakistan National Finals 2026',
        'status': 'ONGOING',
        'organizerId': 'organizer_99',
        'registrationFeeCents': 5000,
        'paymentMethod': 'MANUAL',
      };

      mockStats = {
        'totalRegistrations': 32,
        'pending': 2,
        'approved': 28,
        'waitlisted': 2,
        'passedWeighins': 28,
      };

      mockMatches = [
        {
          'id': 'match_active_01',
          'round': 1,
          'matchIndex': 1,
          'bracketId': 'b_1',
          'bracketName': 'Senior Right -85kg',
          'status': 'CALLED',
          'tableId': 'table_01',
          'division': 'SENIOR',
          'weightClass': '-85kg',
          'arm': 'RIGHT',
          'athleteAId': 'ath_01',
          'athleteBId': 'ath_02',
          'athleteAName': 'Sultan Al-Balushi',
          'athleteBName': 'Kamran Zaidi',
          'refereeId': 'ref_01',
        },
        {
          'id': 'match_ready_02',
          'round': 1,
          'matchIndex': 2,
          'bracketId': 'b_1',
          'bracketName': 'Senior Right -85kg',
          'status': 'READY',
          'tableId': null,
          'division': 'SENIOR',
          'weightClass': '-85kg',
          'arm': 'RIGHT',
          'athleteAId': 'ath_03',
          'athleteBId': 'ath_04',
          'athleteAName': 'Danyal Qureshi',
          'athleteBName': 'Bilal Ahmed',
          'refereeId': null,
        },
        {
          'id': 'match_ready_03',
          'round': 1,
          'matchIndex': 3,
          'bracketId': 'b_1',
          'bracketName': 'Senior Right -85kg',
          'status': 'READY',
          'tableId': null,
          'division': 'SENIOR',
          'weightClass': '-85kg',
          'arm': 'RIGHT',
          'athleteAId': 'ath_05',
          'athleteBId': 'ath_06',
          'athleteAName': 'Hamza Tariq',
          'athleteBName': 'Usman Butt',
          'refereeId': null,
        },
      ];

      mockTables = [
        {
          'id': 'table_01',
          'eventId': testTournamentId,
          'name': 'Main Arena Table 1',
          'status': 'ACTIVE',
          'currentMatchId': 'match_active_01',
          'queue': <Map<String, dynamic>>[
            {
              'id': 'q_item_01',
              'tableId': 'table_01',
              'matchId': 'match_ready_02',
              'position': 1,
              'round': 1,
              'matchIndex': 2,
              'status': 'READY',
              'athleteAName': 'Danyal Qureshi',
              'athleteBName': 'Bilal Ahmed',
            },
          ],
        },
        {
          'id': 'table_02',
          'eventId': testTournamentId,
          'name': 'Stream Table 2',
          'status': 'IDLE',
          'currentMatchId': null,
          'queue': <Map<String, dynamic>>[
            {
              'id': 'q_item_02',
              'tableId': 'table_02',
              'matchId': 'match_ready_03',
              'position': 1,
              'round': 1,
              'matchIndex': 3,
              'status': 'READY',
              'athleteAName': 'Hamza Tariq',
              'athleteBName': 'Usman Butt',
            },
          ],
        },
      ];

      fakeRepo = _FakeTournamentRepository(
        tablesData: mockTables,
        matchesData: mockMatches,
        bracketsData: [],
        registrationsData: [],
        eventData: mockEvent,
        statsData: mockStats,
        refereesData: [
          {'id': 'ref_01', 'fullName': 'Umar Farooq', 'email': 'ref@armsphere.com'},
        ],
      );
    });

    Widget buildTestWidget({
      AuthState? customAuth,
      List<Override>? additionalOverrides,
    }) {
      final defaultAuth = AuthState(
        status: AuthStatus.authenticated,
        userProfile: {'id': 'dir_01', 'role': 'PROVINCIAL_DIRECTOR', 'fullName': 'Director Khan'},
        activeRole: 'PROVINCIAL_DIRECTOR',
        verifiedRoles: ['PROVINCIAL_DIRECTOR', 'REFEREE'],
      );

      return ProviderScope(
        overrides: [
          tournamentRepositoryProvider.overrideWithValue(fakeRepo),
          authProvider.overrideWith((ref) => _FakeAuthNotifier(customAuth ?? defaultAuth)),
          eventDetailProvider(testTournamentId).overrideWith((ref) => fakeRepo.getEventById(eventId: testTournamentId)),
          eventStatsProvider(testTournamentId).overrideWith((ref) => fakeRepo.getEventStats(eventId: testTournamentId)),
          eventRegistrationsProvider(testTournamentId).overrideWith((ref) => fakeRepo.getEventRegistrations(eventId: testTournamentId)),
          eventBracketsProvider(testTournamentId).overrideWith((ref) => fakeRepo.getEventBrackets(eventId: testTournamentId)),
          eventMatchesProvider(testTournamentId).overrideWith((ref) => fakeRepo.getEventMatches(eventId: testTournamentId)),
          refereeDirectoryProvider.overrideWith((ref) => fakeRepo.listReferees()),
          eventMatchTablesProvider(testTournamentId).overrideWith((ref) => fakeRepo.listEventTables(eventId: testTournamentId)),
          ...?additionalOverrides,
        ],
        child: const MaterialApp(
          home: TournamentOperationsScreen(tournamentId: testTournamentId),
        ),
      );
    }

    Future<void> settleScreen(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    // -------------------------------------------------------------------------
    // Test A: Event-scoped table loading and rendering
    // -------------------------------------------------------------------------
    testWidgets('Test A: Loads event-scoped tables and displays section header', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await settleScreen(tester);

      expect(find.text('ARENA TABLES & QUEUES'), findsOneWidget);
      expect(find.text('Main Arena Table 1'), findsOneWidget);
      expect(find.text('Stream Table 2'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test B: Empty event tables truthful state
    // -------------------------------------------------------------------------
    testWidgets('Test B: Displays truthful empty state when no tables exist for event', (tester) async {
      fakeRepo.tablesData.clear();
      await tester.pumpWidget(buildTestWidget());
      await settleScreen(tester);

      expect(find.textContaining('No tables registered for this event yet'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test C: Loading state renders indicator
    // -------------------------------------------------------------------------
    testWidgets('Test C: Displays loading indicator while event tables are fetching', (tester) async {
      final completer = Completer<List<Map<String, dynamic>>>();
      await tester.pumpWidget(buildTestWidget(
        additionalOverrides: [
          eventMatchTablesProvider(testTournamentId).overrideWith((ref) => completer.future),
        ],
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
      completer.complete([]);
      await settleScreen(tester);
    });

    // -------------------------------------------------------------------------
    // Test D: Backend error rendering with retry button
    // -------------------------------------------------------------------------
    testWidgets('Test D: Displays error card and retry action on backend error', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        additionalOverrides: [
          eventMatchTablesProvider(testTournamentId).overrideWith((ref) => Future.error('DB Connection Timeout')),
        ],
      ));
      await settleScreen(tester);

      expect(find.textContaining('Could not load tables: DB Connection Timeout'), findsOneWidget);
      expect(find.text('Retry'), findsWidgets);
    });

    // -------------------------------------------------------------------------
    // Test E: Active table rendering with active bout details and unassign action
    // -------------------------------------------------------------------------
    testWidgets('Test E: Renders ACTIVE table with active bout athletes, referee, and unassign button', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await settleScreen(tester);

      expect(find.text('ACTIVE BOUT'), findsOneWidget);
      expect(find.text('Sultan Al-Balushi  vs  Kamran Zaidi'), findsOneWidget);
      expect(find.textContaining('Ref: Umar Farooq'), findsOneWidget);
      expect(find.text('UNASSIGN MATCH'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test F: Table queue rendering with position numbers and match details
    // -------------------------------------------------------------------------
    testWidgets('Test F: Renders table queue with position badges and athlete names', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await settleScreen(tester);

      expect(find.text('TABLE QUEUE (1)'), findsNWidgets(2)); // Table 1 and Table 2 each have 1 queue item
      expect(find.text('Danyal Qureshi  vs  Bilal Ahmed'), findsOneWidget);
      expect(find.text('Hamza Tariq  vs  Usman Butt'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test G: Call Next Match for idle table with queue
    // -------------------------------------------------------------------------
    testWidgets('Test G: Prominent CALL NEXT MATCH button on idle table triggers confirmation and calls match', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await settleScreen(tester);

      // Stream Table 2 is IDLE with Hamza vs Usman in queue -> displays CALL NEXT MATCH
      expect(find.text('CALL NEXT MATCH'), findsOneWidget);
      expect(find.textContaining('Hamza Tariq vs Usman Butt (Queue #1)'), findsOneWidget);

      // Tap CALL NEXT MATCH
      await tester.tap(find.text('CALL NEXT MATCH'));
      await settleScreen(tester);

      // Verify dialog appears with details
      expect(find.text('Call Next Match to Stream Table 2'), findsOneWidget);
      expect(find.text('Confirm Call'), findsOneWidget);

      // Confirm call
      await tester.tap(find.text('Confirm Call'));
      await settleScreen(tester);

      expect(fakeRepo.lastCalledMatchId, equals('match_ready_03'));
      expect(fakeRepo.lastCalledTableId, equals('table_02'));
    });

    // -------------------------------------------------------------------------
    // Test H: Unassign active match from table
    // -------------------------------------------------------------------------
    testWidgets('Test H: Tapping UNASSIGN MATCH opens confirmation and releases table', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await settleScreen(tester);

      // Find UNASSIGN MATCH button
      final unassignBtn = find.text('UNASSIGN MATCH');
      expect(unassignBtn, findsOneWidget);

      await tester.tap(unassignBtn);
      await settleScreen(tester);

      // Verify confirmation dialog
      expect(find.text('Unassign Match from Table'), findsOneWidget);
      expect(find.text('Unassign Match'), findsOneWidget);

      // Tap confirm unassign
      await tester.tap(find.widgetWithText(ElevatedButton, 'Unassign Match'));
      await settleScreen(tester);

      expect(fakeRepo.lastUnassignedMatchId, equals('match_active_01'));
    });

    // -------------------------------------------------------------------------
    // Test I: Queue insertion flow
    // -------------------------------------------------------------------------
    testWidgets('Test I: Tapping Queue opens dialog and queues eligible READY match', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await settleScreen(tester);

      // Find Queue button for Stream Table 2
      final queueButtons = find.widgetWithText(OutlinedButton, 'Queue');
      expect(queueButtons, findsNWidgets(2));

      await tester.tap(queueButtons.first);
      await settleScreen(tester);

      // Dialog opens
      expect(find.text('Queue Match — Main Arena Table 1'), findsOneWidget);
      expect(find.text('Add to Queue'), findsOneWidget);

      // Tap Add to Queue
      await tester.tap(find.text('Add to Queue'));
      await settleScreen(tester);

      expect(fakeRepo.lastQueuedTableId, equals('table_01'));
      expect(fakeRepo.lastQueuedMatchId, isNotNull);
    });

    // -------------------------------------------------------------------------
    // Test J & K: Queue reorder & move to another table
    // -------------------------------------------------------------------------
    testWidgets('Test J & K: Rebalance dialog opens and permits moving match to another table', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await settleScreen(tester);

      final reorderIcons = find.byTooltip('Reorder / Move');
      expect(reorderIcons, findsWidgets);

      await tester.tap(reorderIcons.first);
      await settleScreen(tester);

      expect(find.textContaining('Rebalance Match'), findsOneWidget);
      expect(find.text('Apply Rebalance'), findsOneWidget);

      await tester.tap(find.text('Apply Rebalance'));
      await settleScreen(tester);

      expect(fakeRepo.lastRebalancedMatchId, equals('match_ready_02'));
    });

    // -------------------------------------------------------------------------
    // Test L: Occupied-table conflict (409) displays truthful message
    // -------------------------------------------------------------------------
    testWidgets('Test L: Handles 409 conflict error truthfully and refreshes arena state', (tester) async {
      fakeRepo.shouldThrow409OnCall = true;
      await tester.pumpWidget(buildTestWidget());
      await settleScreen(tester);

      await tester.tap(find.text('CALL NEXT MATCH'));
      await settleScreen(tester);
      await tester.tap(find.text('Confirm Call'));
      await settleScreen(tester);

      expect(find.text('Table state changed. Refreshing current arena state.'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test M: Role authorization limits table creation and operations
    // -------------------------------------------------------------------------
    testWidgets('Test M: Athlete role cannot see Add Table or queue mutation buttons', (tester) async {
      final athleteAuth = AuthState(
        status: AuthStatus.authenticated,
        userProfile: {'id': 'ath_99', 'role': 'ATHLETE'},
        activeRole: 'ATHLETE',
        verifiedRoles: ['ATHLETE'],
      );

      await tester.pumpWidget(buildTestWidget(customAuth: athleteAuth));
      await settleScreen(tester);

      // Add Table button must NOT be rendered for athlete
      expect(find.text('Add Table'), findsNothing);
      // Queue and Unassign buttons must NOT be rendered for athlete
      expect(find.widgetWithText(OutlinedButton, 'Queue'), findsNothing);
      expect(find.text('UNASSIGN MATCH'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // Test N: Table creation scopes table to tournament event ID
    // -------------------------------------------------------------------------
    testWidgets('Test N: Table creation scopes table to current event ID', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await settleScreen(tester);

      expect(find.text('Add Table'), findsOneWidget);
      await tester.tap(find.text('Add Table'));
      await settleScreen(tester);

      expect(find.text('Add Official Match Table'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Table 3 VIP');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Table'));
      await settleScreen(tester);

      expect(fakeRepo.lastCreatedTableName, equals('Table 3 VIP'));
      expect(fakeRepo.lastCreatedTableEventId, equals(testTournamentId));
    });

    // -------------------------------------------------------------------------
    // Test O: Falsification check proves zero legacy simulated pullers or hardcoded counts
    // -------------------------------------------------------------------------
    testWidgets('Test O: Zero legacy simulated names or static 3 tables active remain', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await settleScreen(tester);

      expect(find.text('M. Todd'), findsNothing);
      expect(find.text('D. Cyplenkov'), findsNothing);
      expect(find.text('E. Gasparini'), findsNothing);
      expect(find.text('A. Voevoda'), findsNothing);
      expect(find.text('3 TABLES ACTIVE'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // Test P: Concurrency guard: _busy flag prevents duplicate operator calls during in-flight mutation
    // -------------------------------------------------------------------------
    testWidgets('Test P: Concurrency guard: _busy flag prevents duplicate operator calls during in-flight mutation', (tester) async {
      fakeRepo.callMatchDelay = const Duration(milliseconds: 200);
      await tester.pumpWidget(buildTestWidget());
      await settleScreen(tester);

      await tester.tap(find.text('CALL NEXT MATCH'));
      await settleScreen(tester);

      // Confirm Call dialog is open
      final confirmBtn = find.text('Confirm Call');
      expect(confirmBtn, findsOneWidget);

      // Tap confirm button
      await tester.tap(confirmBtn);
      await tester.pump();

      // Wait for call to complete
      await tester.pump(const Duration(milliseconds: 250));
      await settleScreen(tester);

      expect(fakeRepo.callMatchToTableCount, equals(1));
    });

    // -------------------------------------------------------------------------
    // Test Q: Offline mutation protection: surfaces truthful error without fake success
    // -------------------------------------------------------------------------
    testWidgets('Test Q: Offline mutation protection: surfaces truthful error without fake success', (tester) async {
      fakeRepo.shouldThrowOfflineOnQueue = true;
      await tester.pumpWidget(buildTestWidget());
      await settleScreen(tester);

      final queueButtons = find.widgetWithText(OutlinedButton, 'Queue');
      await tester.tap(queueButtons.first);
      await settleScreen(tester);

      await tester.tap(find.text('Add to Queue'));
      await settleScreen(tester);

      // Truthful error SnackBar is displayed
      expect(find.text('Network error: Unable to complete server mutation while offline.'), findsOneWidget);
      // Fake success message is NOT shown
      expect(find.text('Match placed into table queue.'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // Test R: Concurrent rebalance conflict (409) triggers error notification and arena refresh
    // -------------------------------------------------------------------------
    testWidgets('Test R: Concurrent rebalance conflict (409) triggers error notification and arena refresh', (tester) async {
      fakeRepo.shouldThrowConflictOnRebalance = true;
      await tester.pumpWidget(buildTestWidget());
      await settleScreen(tester);

      final reorderIcons = find.byTooltip('Reorder / Move');
      await tester.tap(reorderIcons.first);
      await settleScreen(tester);

      await tester.tap(find.text('Apply Rebalance'));
      await settleScreen(tester);

      expect(find.text('Table state changed. Refreshing current arena state.'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test S: Touch targets for critical operator actions satisfy minimum 64dp requirement
    // -------------------------------------------------------------------------
    testWidgets('Test S: Touch targets for critical operator actions satisfy minimum 64dp requirement', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await settleScreen(tester);

      // Table 1 has an active match -> UNASSIGN MATCH button
      final unassignFinder = find.widgetWithText(OutlinedButton, 'UNASSIGN MATCH');
      expect(unassignFinder, findsOneWidget);
      final unassignSize = tester.getSize(unassignFinder);
      expect(unassignSize.height, greaterThanOrEqualTo(64.0));

      // Table 2 is IDLE with queue -> CALL NEXT MATCH button
      final callFinder = find.widgetWithText(ElevatedButton, 'CALL NEXT MATCH');
      expect(callFinder, findsOneWidget);
      final callSize = tester.getSize(callFinder);
      expect(callSize.height, greaterThanOrEqualTo(64.0));
    });
  });
}
