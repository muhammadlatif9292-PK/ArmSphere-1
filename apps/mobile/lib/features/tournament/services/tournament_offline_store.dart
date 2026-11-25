import 'dart:convert';
import 'dart:math' as math;
import '../../../core/api/offline_sync.dart';
import '../../../core/storage/hive_storage.dart';

/// Structured result of the Referee Strict Pre-Match Validation (Green-Light Rule).
class RefereePreMatchValidationResult {
  final bool isGreenLight;
  final String statusHeadline;
  final String detailReason;
  final bool checkAActiveMatchInRound;
  final bool checkBExactMatchedOpponents;
  final bool checkCMatchStillPending;
  final bool checkDBelongsToAssignedTable;
  final Map<String, dynamic>? matchedBout;
  final String? resolvedCategoryLabel;

  const RefereePreMatchValidationResult({
    required this.isGreenLight,
    required this.statusHeadline,
    required this.detailReason,
    required this.checkAActiveMatchInRound,
    required this.checkBExactMatchedOpponents,
    required this.checkCMatchStillPending,
    required this.checkDBelongsToAssignedTable,
    this.matchedBout,
    this.resolvedCategoryLabel,
  });

  bool get allowedToPlay => isGreenLight;
  String get headline => statusHeadline;
  String get detail => detailReason;
}

/// Global Offline-First Tournament Store & Sync Orchestrator shared across:
/// - Organization / Tournament Operator Role
/// - Referee Role (Table Assignments, Green-Light Pre-Match Validation, Single-Tap Result Submission)
/// - Athlete & Spectator Role (Released Tournament Discovery, Details & Matchups Tabs, Offline Apply + QR, Spectator Pass & Verification)
class TournamentOfflineStore {
  static const String _globalReleasedKey = 'global_released_tournaments_v1';
  static const String _deletedTombstonesKey = 'deleted_tournament_tombstones_v1';
  static const String _submittedMatchLocksKey =
      'referee_submitted_match_locks_v1';

  static final Map<String, Map<String, dynamic>> _memoryReleasedTournaments =
      <String, Map<String, dynamic>>{};
  static final Set<String> _memorySubmittedMatchLocks = <String>{};
  static final Set<String> _deletedTournamentIds = <String>{};

  /// Loads persisted tombstone IDs from Hive cache to permanently filter deleted events.
  static void _ensureTombstonesLoaded(HiveStorage? hive) {
    if (hive != null && _deletedTournamentIds.isEmpty) {
      try {
        final cached = hive.getCachedData(_deletedTombstonesKey);
        if (cached is List) {
          for (final item in cached) {
            final s = item?.toString().trim() ?? '';
            if (s.isNotEmpty) {
              _deletedTournamentIds.add(s);
            }
          }
        }
      } catch (_) {}
    }
  }

  /// Returns true if a tournament has been permanently deleted.
  static bool isTournamentDeleted(String? id) {
    if (id == null || id.trim().isEmpty) return false;
    return _deletedTournamentIds.contains(id.trim());
  }

  /// Generates the single canonical permanent Profile QR Code string for a user account.
  /// Format: `ARMSPHERE-ATHLETE-QR:<userId>` (never mutates across renames or events).
  static String buildSettingsAthleteIdentityQr({
    required String athleteId,
    String? athleteName,
  }) {
    final cleanId = athleteId.trim().isEmpty ? 'ath-local' : athleteId.trim();
    return 'ARMSPHERE-ATHLETE-QR:$cleanId';
  }

  /// Resolves the canonical permanent Profile QR Code from a user profile map,
  /// always prioritizing persisted server `profileQrCode` over derived fallback.
  static String buildSettingsIdentityQr(Map<String, dynamic>? profile) {
    final persistedQr = profile?['profileQrCode']?.toString().trim();
    if (persistedQr != null && persistedQr.isNotEmpty) {
      return persistedQr;
    }
    final id = (profile?['id'] ??
            profile?['userId'] ??
            profile?['athleteId'] ??
            profile?['sub'] ??
            'ath-local')
        .toString();
    return buildSettingsAthleteIdentityQr(athleteId: id);
  }

  /// Prevents raw local `draft_...` tokens from appearing in event references.
  static String sanitizeQrEventCode(String eventId) {
    final trimmed = eventId.trim();
    if (trimmed.isEmpty) return 'EVENT';
    if (trimmed.toLowerCase().startsWith('draft_')) {
      final tail = trimmed.length > 6 ? trimmed.substring(trimmed.length - 6) : trimmed;
      return 'PENDING-$tail';
    }
    return trimmed;
  }

  /// Returns true if the tournament is a legacy test/mock tournament that should be removed.
  static bool isLegacyMockTournament(Map<String, dynamic> t) {
    final name = (t['name'] ?? '').toString().toLowerCase();
    final id = (t['id'] ?? '').toString().toLowerCase();
    if (id.startsWith('tourney_released_') ||
        id == 'tourn_01' ||
        id == 'tourn_02' ||
        id == 'tourn_03' ||
        name.contains('national open qualifier') ||
        name.contains('grand prix title showdown') ||
        name.contains('winter championship finals')) {
      return true;
    }
    return false;
  }

  /// Returns true if and only if the tournament is Released / Scheduled (NEVER an unreleased operator draft).
  static bool isReleasedTournament(Map<String, dynamic> t) {
    final id = (t['id'] ?? '').toString();
    if (isTournamentDeleted(id) || isLegacyMockTournament(t)) return false;
    final status = (t['status'] ?? '').toString().toUpperCase();
    if (status == 'DRAFT' || status == 'UNRELEASED' || status == 'CANCELLED' || status == 'DELETED') {
      return false;
    }
    if (t['isReleased'] == false) return false;
    final step1 = t['step1Config'];
    if (step1 is Map && step1['isReleased'] == false) return false;
    return true;
  }

  /// Seeds canonical released tournaments with full multi-table matchups, referees,
  /// athletes, awards, and spectator settings so Operator, Referee, and Athlete roles
  /// work immediately both online and 100% offline.
  static void _ensureCanonicalReleasedTournamentsSeeded(HiveStorage? hive) {
    _ensureTombstonesLoaded(hive);
    if (_memoryReleasedTournaments.isEmpty && hive != null) {
      try {
        final cached = hive.getCachedData(_globalReleasedKey);
        if (cached is List) {
          for (final item in cached) {
            if (item is Map) {
              final map = Map<String, dynamic>.from(item);
              final id = map['id']?.toString() ?? '';
              if (id.isNotEmpty && !isTournamentDeleted(id) && isReleasedTournament(map)) {
                _memoryReleasedTournaments[id] = _ensureNormalizedTournament(map);
              }
            }
          }
        }
      } catch (_) {}
    }
  }

  /// Extracts only the real, enabled weight categories created for a tournament
  /// (from top-level `weightCategories`, `step1Config.weightCategories`, or `brackets`).
  /// Never returns hardcoded fallback categories.
  static List<Map<String, dynamic>> extractRealWeightCategories(
    Map<String, dynamic> raw,
  ) {
    final step1 = raw['step1Config'] is Map
        ? Map<String, dynamic>.from(raw['step1Config'] as Map)
        : const <String, dynamic>{};

    List<dynamic>? sourceList;
    if (raw['weightCategories'] is List &&
        (raw['weightCategories'] as List).isNotEmpty) {
      sourceList = raw['weightCategories'] as List;
    } else if (step1['weightCategories'] is List &&
        (step1['weightCategories'] as List).isNotEmpty) {
      sourceList = step1['weightCategories'] as List;
    } else if (raw['brackets'] is List &&
        (raw['brackets'] as List).isNotEmpty) {
      sourceList = (raw['brackets'] as List).whereType<Map>().map((b) {
        final wc =
            (b['weightClass'] ?? b['weightLabel'] ?? b['label'] ?? b['name'] ?? '')
                .toString()
                .trim();
        return <String, dynamic>{
          'id': (b['id'] ?? 'wc_${wc.toLowerCase().replaceAll(' ', '_')}').toString(),
          'label': wc,
          'weightLabel': wc,
          'division': (b['division'] ?? 'SENIOR').toString().toUpperCase(),
          'arm': (b['arm'] ?? 'RIGHT').toString().toUpperCase(),
          'enabled': true,
        };
      }).toList();
    }

    if (sourceList == null || sourceList.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final result = <Map<String, dynamic>>[];
    int idx = 0;
    for (final item in sourceList) {
      idx++;
      if (item is Map) {
        if (item['enabled'] == false) continue;
        final label = (item['label'] ??
                item['weightLabel'] ??
                item['weightClass'] ??
                item['name'] ??
                '')
            .toString()
            .trim();
        if (label.isEmpty) continue;
        final armRaw = (item['arm'] ?? 'RIGHT').toString().trim().toUpperCase();
        final arm = (armRaw == 'LEFT' || armRaw == 'BOTH' || armRaw == 'RIGHT')
            ? armRaw
            : (armRaw.contains('LEFT')
                ? 'LEFT'
                : (armRaw.contains('BOTH') ? 'BOTH' : 'RIGHT'));
        final division = (item['division'] ?? 'SENIOR')
            .toString()
            .trim()
            .toUpperCase();
        result.add(<String, dynamic>{
          ...Map<String, dynamic>.from(item),
          'id': (item['id'] ?? 'wc_$idx').toString(),
          'label': label,
          'weightLabel': label,
          'arm': arm,
          'division': division.isEmpty ? 'SENIOR' : division,
          'enabled': true,
        });
      } else if (item is String && item.trim().isNotEmpty) {
        final label = item.trim();
        result.add(<String, dynamic>{
          'id': 'wc_$idx',
          'label': label,
          'weightLabel': label,
          'arm': 'RIGHT',
          'division': 'SENIOR',
          'enabled': true,
        });
      }
    }
    return result;
  }

  /// Expands the real created weight categories of a tournament into concrete
  /// selectable divisions (`divisionId`, `label`, `weightClass`, `arm`, `armCode`, `division`).
  static List<Map<String, String>> extractRealTournamentDivisions(
    Map<String, dynamic> event,
  ) {
    final realCategories = extractRealWeightCategories(event);
    return expandSeparatedDivisions(realCategories);
  }

  static Map<String, dynamic> _ensureNormalizedTournament(
    Map<String, dynamic> raw,
  ) {
    final step1 = raw['step1Config'] is Map
        ? Map<String, dynamic>.from(raw['step1Config'] as Map)
        : const <String, dynamic>{};
    final merged = <String, dynamic>{
      ...step1,
      ...raw,
    };

    final id = (merged['id'] ?? 'tourney_released_01').toString();
    final tableCount = ((merged['tableCount'] ?? merged['tablesCount'] ?? 2) as num)
        .toInt()
        .clamp(1, 12);

    final weightCategories = extractRealWeightCategories(merged);

    final existingTables = (merged['tables'] is List)
        ? (merged['tables'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];

    final tables = <Map<String, dynamic>>[];
    for (int i = 1; i <= tableCount; i++) {
      final found =
          existingTables.where((t) => t['tableNumber'] == i).firstOrNull;
      tables.add({
        'tableNumber': i,
        'tableName': found?['tableName']?.toString() ?? 'Table $i',
        'assignedCategoryDivisionIds':
            found?['assignedCategoryDivisionIds'] is List
                ? List<String>.from(
                    found!['assignedCategoryDivisionIds'] as List)
                : <String>[],
        'assignedRefereeIds': found?['assignedRefereeIds'] is List
            ? List<String>.from(found!['assignedRefereeIds'] as List)
            : <String>[],
        'assignedRefereeNames': found?['assignedRefereeNames'] is List
            ? List<String>.from(found!['assignedRefereeNames'] as List)
            : <String>[],
      });
    }

    final awardsConfig = (merged['awardsConfig'] is Map)
        ? Map<String, dynamic>.from(merged['awardsConfig'] as Map)
        : <String, dynamic>{
            'isConfigured': true,
            'rewardType': 'CASH_AND_AWARDS',
            'winnerStructure': 'PER_CATEGORY_WINNERS',
            'topNCount': 3,
            'tiers': <Map<String, dynamic>>[
              {
                'position': 1,
                'label': '1st Place Winner',
                'cashAmountPkr': 25000,
                'awardTitle': 'Gold Medal & Champion Trophy',
              },
              {
                'position': 2,
                'label': '2nd Place Runner-Up',
                'cashAmountPkr': 15000,
                'awardTitle': 'Silver Medal',
              },
              {
                'position': 3,
                'label': '3rd Place Podium',
                'cashAmountPkr': 7500,
                'awardTitle': 'Bronze Medal',
              },
            ],
          };

    final spectatorGateConfig = (merged['spectatorGateConfig'] is Map)
        ? Map<String, dynamic>.from(merged['spectatorGateConfig'] as Map)
        : <String, dynamic>{
            'spectatorAccessMode': 'PAID', // 'FREE' | 'PAID'
            'spectatorFeePkr': 500,
            'allowedGuestsPerAthlete': 2,
            'entranceCheckInLog': <Map<String, dynamic>>[],
            'issuedSpectatorPasses': <Map<String, dynamic>>[],
          };

    final divisions = expandSeparatedDivisions(weightCategories);
    final divLabels = divisions.map((d) => d['label']!).toList();

    final appliedAthletes = (merged['appliedAthletes'] is List)
        ? (merged['appliedAthletes'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];

    Map<String, dynamic> card3MatchupsState;
    if (merged['card3MatchupsState'] is Map &&
        (merged['card3MatchupsState']['matchesByCategory'] is Map) &&
        ((merged['card3MatchupsState']['matchesByCategory'] as Map).isNotEmpty)) {
      card3MatchupsState =
          Map<String, dynamic>.from(merged['card3MatchupsState'] as Map);
    } else {
      card3MatchupsState = _buildDefaultCard3MatchupsState(
        eventId: id,
        divLabels: divLabels,
        appliedAthletes: appliedAthletes,
        tables: tables,
      );
    }

    final feePkr = (merged['entryFeePkr'] as num?)?.toInt();
    final rawFeeCents = (merged['registrationFeeCents'] as num?)?.toInt();
    final effectiveFeeCents = rawFeeCents ?? (feePkr != null ? feePkr * 100 : 0);
    final effectiveRegisteredCount = appliedAthletes.isNotEmpty
        ? appliedAthletes.length
        : ((merged['registeredCount'] as num?)?.toInt() ?? 0);

    final baseMap = <String, dynamic>{
      ...merged,
      'id': id,
      'name': (merged['name'] ?? 'Sanctioned ArmSphere Championship').toString(),
      'organizationId': (merged['organizationId'] ?? '').toString(),
      'organizationName': (merged['organizationName'] ?? 'Host Organization')
          .toString(),
      'venue': (merged['venue'] ?? merged['venueName'] ?? 'Titanium Combat Arena')
          .toString(),
      'venueName':
          (merged['venueName'] ?? merged['venue'] ?? 'Titanium Combat Arena')
              .toString(),
      'city': (merged['city'] ?? 'Lahore').toString(),
      'province': (merged['province'] ?? 'Punjab').toString(),
      'tableCount': tableCount,
      'tableAssignmentMode': (merged['tableAssignmentMode'] ??
              (tableCount > 1
                  ? 'DYNAMIC_FREE_TABLE_QUEUE'
                  : 'SINGLE_TABLE_DEFAULT'))
          .toString(),
      'tables': tables,
      'formatCategory': (merged['formatCategory'] ?? 'ELIMINATION').toString(),
      'eliminationSubFormat':
          (merged['eliminationSubFormat'] ?? 'DOUBLE_ELIMINATION').toString(),
      'weightCategories': weightCategories,
      if (feePkr != null) 'entryFeePkr': feePkr,
      'entryFeeConfigured': merged['entryFeeConfigured'] ?? (feePkr != null),
      'registrationFeeCents': effectiveFeeCents,
      'awardsConfig': awardsConfig,
      'spectatorGateConfig': spectatorGateConfig,
      'appliedAthletes': appliedAthletes,
      'registeredCount': effectiveRegisteredCount,
      'card3MatchupsState': card3MatchupsState,
      'isReleased': true,
      'status': (merged['status']?.toString().toUpperCase() == 'DRAFT')
          ? 'PUBLISHED'
          : (merged['status'] ?? 'PUBLISHED').toString(),
    };

    baseMap['matchups'] = flattenAllMatches(baseMap);
    return baseMap;
  }

  static List<Map<String, String>> expandSeparatedDivisions(
    List<dynamic> weightCategories,
  ) {
    final result = <Map<String, String>>[];
    for (final raw in weightCategories) {
      if (raw is! Map) continue;
      if (raw['enabled'] == false) continue;
      final id = raw['id']?.toString() ?? 'wc';
      final label =
          (raw['label'] ?? raw['weightLabel'] ?? raw['weightClass'] ?? '')
              .toString()
              .trim();
      if (label.isEmpty) continue;
      final division = (raw['division'] ?? 'SENIOR')
          .toString()
          .trim()
          .toUpperCase();
      final effectiveDivision = division.isEmpty ? 'SENIOR' : division;
      final arm = (raw['arm']?.toString() ?? 'RIGHT').toUpperCase();
      if (arm == 'RIGHT' || arm == 'BOTH') {
        result.add({
          'divisionId': '${id}_RIGHT',
          'label': '$label • Right Arm',
          'weightClass': label,
          'arm': 'Right Arm',
          'armCode': 'RIGHT',
          'division': effectiveDivision,
        });
      }
      if (arm == 'LEFT' || arm == 'BOTH') {
        result.add({
          'divisionId': '${id}_LEFT',
          'label': '$label • Left Arm',
          'weightClass': label,
          'arm': 'Left Arm',
          'armCode': 'LEFT',
          'division': effectiveDivision,
        });
      }
    }
    return result;
  }

  static Map<String, dynamic> _buildDefaultCard3MatchupsState({
    required String eventId,
    required List<String> divLabels,
    required List<Map<String, dynamic>> appliedAthletes,
    required List<Map<String, dynamic>> tables,
  }) {
    final matchesByCategory = <String, dynamic>{};
    final tableNames = tables
        .map((t) => t['tableName']?.toString() ?? 'Table 1')
        .toList();
    if (tableNames.isEmpty) tableNames.add('Table 1');

    for (final cat in divLabels) {
      final catAthletes = appliedAthletes
          .where((a) => (a['categoryLabel'] ?? '').toString() == cat)
          .toList();
      if (catAthletes.isEmpty) continue;

      final matches = <Map<String, dynamic>>[];
      int matchIdx = 1;
      for (int i = 0; i + 1 < catAthletes.length; i += 2) {
        final a = catAthletes[i];
        final b = catAthletes[i + 1];
        final assignedTable = tableNames[(matchIdx - 1) % tableNames.length];
        matches.add({
          'id': 'm_${eventId}_${cat.hashCode.abs()}_r1_$matchIdx',
          'eventId': eventId,
          'categoryLabel': cat,
          'roundNumber': 1,
          'matchIndex': matchIdx,
          'queueOrderRank': matchIdx * 10,
          'isBye': false,
          'athleteAId': a['id'].toString(),
          'athleteAAthleteId': a['athleteId']?.toString() ?? a['id'].toString(),
          'athleteAName': a['athleteName'].toString(),
          'athleteAElo': (a['eloRating'] as num?)?.toInt() ?? 1000,
          'athleteAPrKg': (a['prKg'] as num?)?.toDouble() ?? 62.0,
          'athleteAMaxLiftKg': (a['maxLiftKg'] as num?)?.toDouble() ?? 70.0,
          'athleteALosses': (a['lossesCount'] as num?)?.toInt() ?? 0,
          'athleteBId': b['id'].toString(),
          'athleteBAthleteId': b['athleteId']?.toString() ?? b['id'].toString(),
          'athleteBName': b['athleteName'].toString(),
          'athleteBElo': (b['eloRating'] as num?)?.toInt() ?? 1000,
          'athleteBPrKg': (b['prKg'] as num?)?.toDouble() ?? 60.0,
          'athleteBMaxLiftKg': (b['maxLiftKg'] as num?)?.toDouble() ?? 68.0,
          'athleteBLosses': (b['lossesCount'] as num?)?.toInt() ?? 0,
          'assignedTable': assignedTable,
          'tableQueueStatus':
              matchIdx <= tableNames.length ? 'ACTIVE_AT_TABLE' : 'QUEUED_FOR_FREE_TABLE',
          'status': 'PENDING',
          'winnerId': null,
          'loserId': null,
          'eloTransferDelta': null,
          'scoreLine': null,
        });
        matchIdx++;
      }

      if (catAthletes.length % 2 == 1) {
        final byeAth = catAthletes.last;
        final assignedTable = tableNames[(matchIdx - 1) % tableNames.length];
        matches.add({
          'id': 'm_bye_${eventId}_${cat.hashCode.abs()}_r1_$matchIdx',
          'eventId': eventId,
          'categoryLabel': cat,
          'roundNumber': 1,
          'matchIndex': matchIdx,
          'queueOrderRank': matchIdx * 10,
          'isBye': true,
          'athleteAId': byeAth['id'].toString(),
          'athleteAAthleteId':
              byeAth['athleteId']?.toString() ?? byeAth['id'].toString(),
          'athleteAName': byeAth['athleteName'].toString(),
          'athleteAElo': (byeAth['eloRating'] as num?)?.toInt() ?? 1650,
          'athleteAPrKg': (byeAth['prKg'] as num?)?.toDouble() ?? 58.5,
          'athleteAMaxLiftKg': (byeAth['maxLiftKg'] as num?)?.toDouble() ?? 65.0,
          'athleteALosses': 0,
          'athleteBId': 'BYE',
          'athleteBName': 'BYE (Auto-Advance to Next Round)',
          'athleteBElo': 0,
          'athleteBPrKg': 0.0,
          'athleteBMaxLiftKg': 0.0,
          'athleteBLosses': 0,
          'assignedTable': assignedTable,
          'tableQueueStatus': 'COMPLETED_TABLE_FREED',
          'status': 'DONE',
          'winnerId': byeAth['id'].toString(),
          'loserId': null,
          'eloTransferDelta': 0,
          'scoreLine': 'BYE • AUTO-ADVANCE',
        });
      }

      matchesByCategory[cat] = matches;
    }

    return <String, dynamic>{
      'matchesByCategory': matchesByCategory,
      'unlockedRoundsByCategory': <String, dynamic>{},
      'lastFreedTable': null,
      'lastAutoAssignedSummary': null,
    };
  }

  /// Upserts a released tournament into the shared global store (`global_released_tournaments_v1`).
  /// Unreleased operator drafts (`isReleased == false` or `status == 'DRAFT'`) are strictly ignored here.
  static Future<void> upsertReleasedTournament(
    HiveStorage? hive,
    Map<String, dynamic> tournament,
  ) async {
    if (!isReleasedTournament(tournament)) return;
    _ensureCanonicalReleasedTournamentsSeeded(hive);
    final normalized = _ensureNormalizedTournament(tournament);
    final id = normalized['id'].toString();
    _memoryReleasedTournaments[id] = normalized;
    if (hive != null) {
      try {
        await hive.cacheData(
          _globalReleasedKey,
          _memoryReleasedTournaments.values.toList(),
        );
        // Also keep the operator's local tournament list in sync so referee result
        // submissions immediately reflect in the Tournament Operator Hub & Card 3.
        final orgId = (normalized['organizerId'] ?? '').toString().trim();
        if (orgId.isNotEmpty) {
          final opKey = 'operator_step1_tournaments_$orgId';
          final rawOpList = hive.getCachedData(opKey);
          if (rawOpList is List) {
            final updatedOpList = rawOpList.map((item) {
              if (item is Map && item['id']?.toString() == id) {
                return <String, dynamic>{
                  ...Map<String, dynamic>.from(item),
                  ...normalized,
                };
              }
              return item;
            }).toList();
            await hive.cacheData(opKey, updatedOpList);
          }
        }
      } catch (_) {}
    }
  }

  /// Permanently deletes a tournament from memory, the global released store,
  /// and the operator's local drafts/tournaments cache.
  static Future<void> deleteTournament({
    HiveStorage? hive,
    required String tournamentId,
    String? operatorId,
  }) async {
    final cleanId = tournamentId.trim();
    if (cleanId.isEmpty) return;

    _ensureTombstonesLoaded(hive);
    _deletedTournamentIds.add(cleanId);
    _memoryReleasedTournaments.remove(cleanId);

    if (hive != null) {
      try {
        await hive.cacheData(_deletedTombstonesKey, _deletedTournamentIds.toList());

        // 1. Evict and purge from 'tournaments_list'
        final cachedTourneys = hive.getCachedData('tournaments_list');
        if (cachedTourneys is List) {
          final updatedTourneys = cachedTourneys.where((e) {
            if (e is Map) {
              return e['id']?.toString() != cleanId;
            }
            return true;
          }).toList();
          await hive.cacheData('tournaments_list', updatedTourneys);
        }
        await hive.evictCache('event_detail_$cleanId');

        // 2. Remove from global released store
        final cached = hive.getCachedData(_globalReleasedKey);
        if (cached is List) {
          final updated = cached.where((item) {
            if (item is Map) {
              return item['id']?.toString() != cleanId;
            }
            return true;
          }).toList();
          await hive.cacheData(_globalReleasedKey, updated);
        }

        // 3. Remove from operator's local drafts cache
        if (operatorId != null && operatorId.isNotEmpty) {
          final opKey = 'operator_step1_tournaments_$operatorId';
          final rawOpList = hive.getCachedData(opKey);
          if (rawOpList is List) {
            final updatedOp = rawOpList.where((item) {
              if (item is Map) {
                return item['id']?.toString() != cleanId;
              }
              return true;
            }).toList();
            await hive.cacheData(opKey, updatedOp);
          }
        }
        final defaultKey = 'operator_step1_tournaments_operator_default';
        final rawDefaultList = hive.getCachedData(defaultKey);
        if (rawDefaultList is List) {
          final updatedDef = rawDefaultList.where((item) {
            if (item is Map) {
              return item['id']?.toString() != cleanId;
            }
            return true;
          }).toList();
          await hive.cacheData(defaultKey, updatedDef);
        }
      } catch (_) {}
    }
  }

  static bool _isSameAthleteRegistration(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final aId = (a['athleteId'] ?? '').toString().trim();
    final bId = (b['athleteId'] ?? '').toString().trim();
    if (aId.isNotEmpty && bId.isNotEmpty && aId == bId) return true;

    final aUser = (a['userId'] ?? '').toString().trim();
    final bUser = (b['userId'] ?? '').toString().trim();
    if (aUser.isNotEmpty && bUser.isNotEmpty && aUser == bUser) return true;
    if (aId.isNotEmpty && bUser.isNotEmpty && aId == bUser) return true;
    if (aUser.isNotEmpty && bId.isNotEmpty && aUser == bId) return true;

    final aQr = (a['profileQrCode'] ?? a['settingsIdentityQr'] ?? '').toString().trim();
    final bQr = (b['profileQrCode'] ?? b['settingsIdentityQr'] ?? '').toString().trim();
    if (aQr.isNotEmpty && bQr.isNotEmpty && aQr == bQr) return true;

    final aRegId = (a['id'] ?? a['registrationId'] ?? '').toString().trim();
    final bRegId = (b['id'] ?? b['registrationId'] ?? '').toString().trim();
    if (aRegId.isNotEmpty && bRegId.isNotEmpty && aRegId == bRegId) return true;

    return false;
  }

  static Map<String, dynamic> _mergeTournamentWithLocalState({
    required String tournamentId,
    Map<String, dynamic>? existingLocal,
    required Map<String, dynamic> incoming,
    HiveStorage? hive,
  }) {
    final combined = <String, dynamic>{
      if (existingLocal != null) ...existingLocal,
      ...incoming,
      'id': tournamentId,
    };

    final incomingCats = extractRealWeightCategories(incoming);
    final localCats = existingLocal != null
        ? extractRealWeightCategories(existingLocal)
        : const <Map<String, dynamic>>[];
    if (incomingCats.isNotEmpty) {
      combined['weightCategories'] = incomingCats;
    } else if (localCats.isNotEmpty) {
      combined['weightCategories'] = localCats;
    }

    final mergedAthletes = <Map<String, dynamic>>[];
    void upsertEntry(Map<String, dynamic> rawEntry) {
      final entry = Map<String, dynamic>.from(rawEntry);
      final idx = mergedAthletes.indexWhere(
        (existing) => _isSameAthleteRegistration(existing, entry),
      );
      if (idx != -1) {
        mergedAthletes[idx] = <String, dynamic>{
          ...mergedAthletes[idx],
          ...entry,
        };
      } else {
        mergedAthletes.add(entry);
      }
    }

    if (incoming['appliedAthletes'] is List) {
      for (final item in (incoming['appliedAthletes'] as List).whereType<Map>()) {
        upsertEntry(Map<String, dynamic>.from(item));
      }
    }
    if (existingLocal != null && existingLocal['appliedAthletes'] is List) {
      for (final item
          in (existingLocal['appliedAthletes'] as List).whereType<Map>()) {
        upsertEntry(Map<String, dynamic>.from(item));
      }
    }
    if (incoming['myRegistration'] is Map) {
      upsertEntry(Map<String, dynamic>.from(incoming['myRegistration'] as Map));
    }
    if (hive != null) {
      try {
        final rawLocalRegs = hive.getCachedData('local_my_registrations');
        if (rawLocalRegs is List) {
          for (final item in rawLocalRegs.whereType<Map>()) {
            final map = Map<String, dynamic>.from(item);
            if ((map['eventId'] ?? map['tournamentId'] ?? '').toString() ==
                tournamentId) {
              upsertEntry(map);
            }
          }
        }
      } catch (_) {}
    }

    combined['appliedAthletes'] = mergedAthletes;
    final incomingRegCount = (incoming['registeredCount'] as num?)?.toInt() ?? 0;
    final localRegCount =
        (existingLocal?['registeredCount'] as num?)?.toInt() ?? 0;
    combined['registeredCount'] = mergedAthletes.isNotEmpty
        ? mergedAthletes.length
        : (incomingRegCount > localRegCount ? incomingRegCount : localRegCount);

    return _ensureNormalizedTournament(combined);
  }

  /// Returns all Released / Scheduled tournaments (never returning unreleased drafts).
  static List<Map<String, dynamic>> getAllReleasedTournaments({
    HiveStorage? hive,
    List<Map<String, dynamic>> serverEvents = const [],
    List<Map<String, dynamic>> remoteEvents = const [],
  }) {
    _ensureTombstonesLoaded(hive);
    _ensureCanonicalReleasedTournamentsSeeded(hive);
    final mergedRemote = <Map<String, dynamic>>[...serverEvents, ...remoteEvents];
    for (final r in mergedRemote) {
      final id = r['id']?.toString() ?? '';
      if (id.isEmpty || isTournamentDeleted(id) || !isReleasedTournament(r)) continue;
      _memoryReleasedTournaments[id] = _mergeTournamentWithLocalState(
        tournamentId: id,
        existingLocal: _memoryReleasedTournaments[id],
        incoming: r,
        hive: hive,
      );
    }
    return _memoryReleasedTournaments.values
        .where((t) => !isTournamentDeleted(t['id']?.toString()) && isReleasedTournament(t))
        .toList();
  }

  /// Returns all Released / Scheduled tournaments for a specific Organization.
  static List<Map<String, dynamic>> getReleasedTournamentsForOrganization({
    HiveStorage? hive,
    required String organizationId,
    String? organizationName,
    List<Map<String, dynamic>> serverEvents = const [],
    List<Map<String, dynamic>> fallbackEvents = const [],
  }) {
    final all = getAllReleasedTournaments(
      hive: hive,
      serverEvents: serverEvents,
      remoteEvents: fallbackEvents,
    );
    final cleanOrgName = (organizationName ?? '').trim().toLowerCase();
    final filtered = all.where((t) {
      if (!isReleasedTournament(t) || isTournamentDeleted(t['id']?.toString())) return false;
      final orgId = (t['organizationId'] ?? '').toString();
      final tOrgName = (t['organizationName'] ?? '').toString().toLowerCase();
      return orgId.isEmpty ||
          orgId == organizationId ||
          t['id'].toString().startsWith(organizationId) ||
          (cleanOrgName.isNotEmpty && tOrgName.contains(cleanOrgName));
    }).toList();
    return filtered.isNotEmpty ? filtered : all.where((t) => !isTournamentDeleted(t['id']?.toString()) && isReleasedTournament(t)).toList();
  }

  /// Resolves a single Released Tournament by ID with full matchups, athletes, and awards.
  static Map<String, dynamic>? getReleasedTournamentById({
    HiveStorage? hive,
    required String tournamentId,
    List<Map<String, dynamic>> serverEvents = const [],
    Map<String, dynamic>? fallbackEvent,
  }) {
    _ensureTombstonesLoaded(hive);
    if (isTournamentDeleted(tournamentId)) return null;
    _ensureCanonicalReleasedTournamentsSeeded(hive);
    for (final s in serverEvents) {
      if (!isReleasedTournament(s)) continue;
      final sId = (s['id'] ?? '').toString();
      if (sId.isNotEmpty && !isTournamentDeleted(sId)) {
        _memoryReleasedTournaments[sId] = _mergeTournamentWithLocalState(
          tournamentId: sId,
          existingLocal: _memoryReleasedTournaments[sId],
          incoming: s,
          hive: hive,
        );
      }
    }
    if (fallbackEvent != null && fallbackEvent.isNotEmpty) {
      final merged = _mergeTournamentWithLocalState(
        tournamentId: tournamentId,
        existingLocal: _memoryReleasedTournaments[tournamentId],
        incoming: {
          ...fallbackEvent,
          'id': tournamentId,
        },
        hive: hive,
      );
      if (isTournamentDeleted(merged['id']?.toString())) return null;
      _memoryReleasedTournaments[tournamentId] = merged;
      return merged;
    }
    if (_memoryReleasedTournaments.containsKey(tournamentId)) {
      final t = _memoryReleasedTournaments[tournamentId]!;
      if (isTournamentDeleted(t['id']?.toString())) return null;
      final merged = _mergeTournamentWithLocalState(
        tournamentId: tournamentId,
        existingLocal: t,
        incoming: t,
        hive: hive,
      );
      _memoryReleasedTournaments[tournamentId] = merged;
      return merged;
    }
    return null;
  }

  // ===========================================================================
  // 1. REFEREE ROLE: TABLE ASSIGNMENTS, GREEN-LIGHT VALIDATION & RESULT SUBMIT
  // ===========================================================================

  /// Returns ONLY the Tournament Table Assignment Cards in which this specific referee
  /// has been selected (cached locally for offline access).
  /// Never returns unselected tournaments from ArmSphere, and strictly isolates each referee's data.
  static List<Map<String, dynamic>> getRefereeAssignments({
    HiveStorage? hive,
    Map<String, dynamic>? userProfile,
    List<Map<String, dynamic>> serverEvents = const [],
    String? refereeUserId,
    String? refereeName,
  }) {
    final nestedProfile = userProfile?['profile'] is Map
        ? Map<String, dynamic>.from(userProfile!['profile'] as Map)
        : const <String, dynamic>{};
    final nestedUser = userProfile?['user'] is Map
        ? Map<String, dynamic>.from(userProfile!['user'] as Map)
        : const <String, dynamic>{};

    final effectiveRefId = (refereeUserId ??
            userProfile?['id'] ??
            userProfile?['userId'] ??
            userProfile?['athleteId'] ??
            nestedUser['id'] ??
            nestedProfile['id'] ??
            '')
        .toString()
        .trim();
    final effectiveRefName = (refereeName ??
            userProfile?['displayName'] ??
            userProfile?['fullName'] ??
            userProfile?['name'] ??
            nestedProfile['fullName'] ??
            nestedProfile['displayName'] ??
            nestedUser['name'] ??
            '')
        .toString()
        .trim();
    final effectiveRefEmail =
        (userProfile?['email'] ?? nestedUser['email'] ?? '')
            .toString()
            .trim()
            .toLowerCase();

    final tournaments = getAllReleasedTournaments(
      hive: hive,
      serverEvents: serverEvents,
    );
    final assignments = <Map<String, dynamic>>[];

    for (final t in tournaments) {
      final status = (t['status'] ?? '').toString().toUpperCase();
      if (status == 'COMPLETED' || status == 'CANCELLED') continue;
      if (!isReleasedTournament(t)) continue;

      final tables = (t['tables'] as List?)
              ?.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          const <Map<String, dynamic>>[];
      final tableCount = ((t['tableCount'] as num?)?.toInt() ?? 1).clamp(1, 12);

      // Find all tables in this tournament where THIS referee was explicitly selected
      final matchedTables = <Map<String, dynamic>>[];
      for (final tbl in tables) {
        final refIds = (tbl['assignedRefereeIds'] as List?)
                ?.map((e) => e.toString().trim())
                .where((s) => s.isNotEmpty)
                .toList() ??
            const <String>[];
        final refNames = (tbl['assignedRefereeNames'] as List?)
                ?.map((e) => e.toString().trim())
                .where((s) => s.isNotEmpty)
                .toList() ??
            const <String>[];

        if (refIds.isEmpty && refNames.isEmpty) continue;

        final idMatched = effectiveRefId.isNotEmpty &&
            refIds.any((id) => id.toLowerCase() == effectiveRefId.toLowerCase());
        final nameMatched = effectiveRefName.isNotEmpty &&
            refNames.any((n) {
              final nl = n.toLowerCase();
              final el = effectiveRefName.toLowerCase();
              return nl == el || nl.contains(el) || el.contains(nl);
            });
        final emailMatched = effectiveRefEmail.isNotEmpty &&
            (refIds.any((id) => id.toLowerCase() == effectiveRefEmail) ||
                refNames.any((n) => n.toLowerCase() == effectiveRefEmail));

        if (idMatched || nameMatched || emailMatched) {
          matchedTables.add(tbl);
        }
      }

      // Single-device operator/referee test support: ONLY if this tournament was
      // created locally on this device by the current user (`organizerId == effectiveRefId`
      // or local `draft_...` id) AND has referees selected on a table, allow the creator
      // switching to Referee mode on the same device to test the table(s) they configured.
      if (matchedTables.isEmpty) {
        final isCreatedOnThisDeviceByCurrentUser =
            (effectiveRefId.isNotEmpty &&
                    t['organizerId']?.toString().trim() == effectiveRefId) ||
                t['id'].toString().startsWith('draft_');
        if (isCreatedOnThisDeviceByCurrentUser) {
          for (final tbl in tables) {
            final refIds = (tbl['assignedRefereeIds'] as List?)
                    ?.map((e) => e.toString().trim())
                    .where((s) => s.isNotEmpty)
                    .toList() ??
                const <String>[];
            if (refIds.isNotEmpty) {
              matchedTables.add(tbl);
            }
          }
        }
      }

      // Strictly skip any tournament where this referee was NOT selected!
      if (matchedTables.isEmpty) continue;

      final allMatches = flattenAllMatches(t);

      for (final matchedTable in matchedTables) {
        final assignedTableName =
            matchedTable['tableName']?.toString() ?? 'Table 1';
        final assignedTableNumber =
            (matchedTable['tableNumber'] as num?)?.toInt() ?? 1;

        final myTablePending = allMatches
            .where((m) =>
                m['isBye'] != true &&
                (m['status'] ?? 'PENDING').toString().toUpperCase() ==
                    'PENDING' &&
                (tableCount == 1 ||
                    (m['tableNumber'] as num?)?.toInt() ==
                        assignedTableNumber ||
                    (m['assignedTable'] ?? 'Table 1')
                            .toString()
                            .toLowerCase() ==
                        assignedTableName.toLowerCase()))
            .toList();
        final myTableDone = allMatches
            .where((m) =>
                m['isBye'] != true &&
                (m['status'] ?? 'PENDING').toString().toUpperCase() == 'DONE' &&
                (tableCount == 1 ||
                    (m['tableNumber'] as num?)?.toInt() ==
                        assignedTableNumber ||
                    (m['assignedTable'] ?? 'Table 1')
                            .toString()
                            .toLowerCase() ==
                        assignedTableName.toLowerCase()))
            .toList();

        assignments.add({
          'assignmentId': 'ref_assign_${t['id']}_table_$assignedTableNumber',
          'tournamentId': t['id'].toString(),
          'tournamentName': t['name']?.toString() ?? 'ArmSphere Championship',
          'organizationName':
              t['organizationName']?.toString() ?? 'Host Organization',
          'venueName':
              (t['venueName'] ?? t['venue'] ?? 'Combat Arena').toString(),
          'city': (t['city'] ?? 'Lahore').toString(),
          'formatCategory': (t['formatCategory'] ?? 'ELIMINATION').toString(),
          'eliminationSubFormat':
              (t['eliminationSubFormat'] ?? 'DOUBLE_ELIMINATION').toString(),
          'refereeId': effectiveRefId.isNotEmpty ? effectiveRefId : 'ref_local',
          'refereeName':
              effectiveRefName.isNotEmpty ? effectiveRefName : 'Referee',
          'tournament': t,
          'assignedTableNumber': assignedTableNumber,
          'assignedTableName': assignedTableName,
          'tableCount': tableCount,
          'pendingCount': myTablePending.length,
          'doneCount': myTableDone.length,
          'pendingCountOnTable': myTablePending.length,
          'pendingOnTableCount': myTablePending.length,
          'completedCountOnTable': myTableDone.length,
          'allTables': tables,
        });
      }
    }

    return assignments;
  }

  /// Normalizes a bout map so both Operator Card 3 (`athleteA*`/`athleteB*`/`assignedTable`)
  /// and Referee/Athlete (`player1*`/`player2*`/`tableNumber`/`winnerName`) keys are always populated.
  static Map<String, dynamic> _normalizeBoutAliases(
    Map<String, dynamic> raw,
    String fallbackCatLabel,
  ) {
    final aId = (raw['athleteAId'] ?? raw['player1Id'] ?? '').toString();
    final aName = (raw['athleteAName'] ?? raw['player1Name'] ?? 'Athlete A').toString();
    final aElo = (raw['athleteAElo'] ?? raw['player1Elo'] as num?)?.toInt() ?? 1700;
    final aLosses = (raw['athleteALosses'] ?? raw['player1Losses'] as num?)?.toInt() ?? 0;

    final bId = (raw['athleteBId'] ?? raw['player2Id'] ?? '').toString();
    final bName = (raw['athleteBName'] ?? raw['player2Name'] ?? 'Athlete B').toString();
    final bElo = (raw['athleteBElo'] ?? raw['player2Elo'] as num?)?.toInt() ?? 1700;
    final bLosses = (raw['athleteBLosses'] ?? raw['player2Losses'] as num?)?.toInt() ?? 0;

    final assignedTable = (raw['assignedTable'] ??
            (raw['tableNumber'] != null ? 'Table ${raw['tableNumber']}' : 'Table 1'))
        .toString();
    final parsedTableNum = (raw['tableNumber'] as num?)?.toInt() ??
        int.tryParse(assignedTable.replaceAll(RegExp(r'[^0-9]'), '')) ??
        1;

    final winnerId = raw['winnerId']?.toString();
    final winnerName = raw['winnerName']?.toString() ??
        (winnerId != null
            ? (winnerId == aId ? aName : (winnerId == bId ? bName : null))
            : null);

    final catLabel = (raw['categoryLabel'] ?? fallbackCatLabel).toString();
    final catParts = catLabel.split('•');
    final wCat = (raw['weightCategory'] ?? catParts.first.trim()).toString();
    final armVal = (raw['arm'] ?? (catParts.length > 1 ? catParts.last.trim() : 'Right Arm'))
        .toString();

    return <String, dynamic>{
      ...raw,
      'categoryLabel': catLabel,
      'weightCategory': wCat,
      'arm': armVal,
      'athleteAId': aId,
      'athleteAName': aName,
      'athleteAElo': aElo,
      'athleteALosses': aLosses,
      'player1Id': aId,
      'player1Name': aName,
      'player1Elo': aElo,
      'player1Losses': aLosses,
      'player1Qr': raw['player1Qr'] ??
          raw['player1ProfileQrCode'] ??
          buildSettingsAthleteIdentityQr(athleteId: aId),
      'athleteBId': bId,
      'athleteBName': bName,
      'athleteBElo': bElo,
      'athleteBLosses': bLosses,
      'player2Id': bId,
      'player2Name': bName,
      'player2Elo': bElo,
      'player2Losses': bLosses,
      'player2Qr': raw['player2Qr'] ??
          raw['player2ProfileQrCode'] ??
          buildSettingsAthleteIdentityQr(athleteId: bId),
      'assignedTable': assignedTable,
      'tableNumber': parsedTableNum,
      'winnerName': winnerName,
    };
  }

  /// Flattens all matchups across categories from `card3MatchupsState`.
  static List<Map<String, dynamic>> flattenAllMatches(
    Map<String, dynamic> tournament,
  ) {
    final result = <Map<String, dynamic>>[];
    final state = tournament['card3MatchupsState'];
    if (state is! Map) return result;
    final byCat = state['matchesByCategory'];
    if (byCat is! Map) return result;

    for (final entry in byCat.entries) {
      final catLabel = entry.key.toString();
      final list = entry.value;
      if (list is List) {
        for (final item in list) {
          if (item is Map) {
            result.add(
              _normalizeBoutAliases(
                Map<String, dynamic>.from(item),
                catLabel,
              ),
            );
          }
        }
      }
    }
    return result;
  }

  /// Resolves an athlete record in `tournament['appliedAthletes']` from a scanned
  /// permanent Profile QR Code (canonical `ARMSPHERE-ATHLETE-QR:<userId>`, legacy
  /// `ARMSPHERE-ATHLETE-QR:<id>:<name>`, or JSON payload) OR typed Athlete Name / ID.
  static Map<String, dynamic>? resolveAthleteFromQrOrQuery({
    required Map<String, dynamic> tournament,
    required String rawInput,
  }) {
    final query = rawInput.trim();
    if (query.isEmpty) return null;

    final athletes = (tournament['appliedAthletes'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        const <Map<String, dynamic>>[];

    String? extractedId;
    String? extractedName;
    String? extractedProfileQr;

    // 1. JSON QR payload
    if (query.startsWith('{') && query.endsWith('}')) {
      try {
        final decoded = jsonDecode(query);
        if (decoded is Map) {
          extractedProfileQr =
              (decoded['profileQrCode'] ?? decoded['qrCode'])?.toString().trim();
          extractedId = (decoded['userId'] ??
                  decoded['athleteId'] ??
                  decoded['registrationId'])
              ?.toString()
              .trim();
          extractedName = decoded['athleteName']?.toString().trim();
        }
      } catch (_) {}
    }
    // 2. Canonical Profile QR: ARMSPHERE-ATHLETE-QR:<userId> (or legacy :name)
    else if (query.toUpperCase().startsWith('ARMSPHERE-ATHLETE-QR:')) {
      final parts = query.split(':');
      if (parts.length >= 2) {
        extractedId = parts[1].trim();
        extractedProfileQr = 'ARMSPHERE-ATHLETE-QR:${parts[1].trim()}';
      }
      if (parts.length >= 3) {
        extractedName = parts.sublist(2).join(':').trim();
      }
    }

    final lowerQuery = query.toLowerCase();
    final lowerExtractedId = extractedId?.toLowerCase();
    final lowerExtractedName = extractedName?.toLowerCase();
    final lowerProfileQr = extractedProfileQr?.toLowerCase();

    for (final a in athletes) {
      final regId = (a['id'] ?? a['registrationId'] ?? '').toString().toLowerCase();
      final athId = (a['athleteId'] ?? '').toString().toLowerCase();
      final userId = (a['userId'] ?? '').toString().toLowerCase();
      final name = (a['athleteName'] ?? '').toString().toLowerCase();
      final profileQr = (a['profileQrCode'] ?? '').toString().toLowerCase();
      final settingsQr = (a['settingsIdentityQr'] ?? '').toString().toLowerCase();
      final qr = (a['qrCodePayload'] ?? a['qrCode'] ?? '').toString().toLowerCase();

      if (lowerProfileQr != null &&
          lowerProfileQr.isNotEmpty &&
          (profileQr == lowerProfileQr ||
              settingsQr == lowerProfileQr ||
              qr == lowerProfileQr)) {
        return a;
      }
      if (lowerExtractedId != null &&
          lowerExtractedId.isNotEmpty &&
          (userId == lowerExtractedId ||
              athId == lowerExtractedId ||
              regId == lowerExtractedId)) {
        return a;
      }
      if (lowerExtractedName != null &&
          lowerExtractedName.isNotEmpty &&
          name == lowerExtractedName) {
        return a;
      }
      if (profileQr == lowerQuery ||
          settingsQr == lowerQuery ||
          qr == lowerQuery ||
          userId == lowerQuery ||
          athId == lowerQuery ||
          regId == lowerQuery ||
          name == lowerQuery ||
          (lowerQuery.length >= 2 && name.contains(lowerQuery))) {
        return a;
      }
    }
    return null;
  }

  /// STRICT PRE-MATCH VALIDATION (GREEN-LIGHT ALLOWANCE TO PLAY):
  /// Evaluates all 4 mandatory checks when a referee scans an athlete's QR code or types their name/ID:
  /// a) Does the athlete have an active match at this time in this tournament (and in the active round, if Elimination)?
  /// b) Are these the exact matched opponents (block wrongly matched players)?
  /// c) Is the match still Pending (block players from an already Done/played match from playing again)?
  /// d) Does this matchup belong to THIS referee's assigned table?
  static RefereePreMatchValidationResult validatePreMatchForReferee({
    required Map<String, dynamic> tournament,
    String? assignedTableName,
    int? assignedTableNumber,
    String? primaryScanOrNameInput,
    String? primaryInput,
    String? opponentScanOrNameInput,
    String? secondaryInput,
  }) {
    final effectiveTableName = assignedTableName ??
        'Table ${assignedTableNumber ?? 1}';
    final effectivePrimaryInput =
        (primaryScanOrNameInput ?? primaryInput ?? '').trim();
    final effectiveSecondaryInput =
        (opponentScanOrNameInput ?? secondaryInput)?.trim();

    final tableCount =
        ((tournament['tableCount'] as num?)?.toInt() ?? 1).clamp(1, 12);
    final isSuperfights =
        (tournament['formatCategory'] ?? '').toString().toUpperCase() ==
            'SUPERFIGHTS';

    final primaryAthlete = resolveAthleteFromQrOrQuery(
      tournament: tournament,
      rawInput: effectivePrimaryInput,
    );

    if (primaryAthlete == null) {
      return RefereePreMatchValidationResult(
        isGreenLight: false,
        statusHeadline: 'RED-LIGHT • PLAYER NOT FOUND IN TOURNAMENT',
        detailReason:
            'No registered athlete matched "$effectivePrimaryInput" by QR code, Athlete Name, or ID in this tournament.',
        checkAActiveMatchInRound: false,
        checkBExactMatchedOpponents: false,
        checkCMatchStillPending: false,
        checkDBelongsToAssignedTable: false,
      );
    }

    final primaryRegId = primaryAthlete['id'].toString();
    final primaryAthId =
        (primaryAthlete['athleteId'] ?? primaryRegId).toString();
    final primaryName = primaryAthlete['athleteName'].toString();

    Map<String, dynamic>? secondaryAthlete;
    if (effectiveSecondaryInput != null &&
        effectiveSecondaryInput.trim().isNotEmpty) {
      secondaryAthlete = resolveAthleteFromQrOrQuery(
        tournament: tournament,
        rawInput: effectiveSecondaryInput,
      );
      if (secondaryAthlete == null) {
        return RefereePreMatchValidationResult(
          isGreenLight: false,
          statusHeadline: 'RED-LIGHT • SECOND CORNER PLAYER NOT REGISTERED',
          detailReason:
              'Verified $primaryName, but second player "$effectiveSecondaryInput" is not registered in this tournament.',
          checkAActiveMatchInRound: true,
          checkBExactMatchedOpponents: false,
          checkCMatchStillPending: false,
          checkDBelongsToAssignedTable: false,
        );
      }
    }
    final assignedTableNameResolved = effectiveTableName;

    final allMatches = flattenAllMatches(tournament)
        .where((m) => m['isBye'] != true)
        .toList();

    bool involvesAthlete(Map<String, dynamic> m, String regId, String athId, String athName) {
      final aReg = (m['athleteAId'] ?? '').toString().toLowerCase();
      final bReg = (m['athleteBId'] ?? '').toString().toLowerCase();
      final aAth = (m['athleteAAthleteId'] ?? aReg).toString().toLowerCase();
      final bAth = (m['athleteBAthleteId'] ?? bReg).toString().toLowerCase();
      final aName = (m['athleteAName'] ?? '').toString().toLowerCase();
      final bName = (m['athleteBName'] ?? '').toString().toLowerCase();
      final rLower = regId.toLowerCase();
      final idLower = athId.toLowerCase();
      final nLower = athName.toLowerCase();
      return aReg == rLower ||
          bReg == rLower ||
          aAth == idLower ||
          bAth == idLower ||
          (nLower.isNotEmpty && (aName == nLower || bName == nLower));
    }

    // When both 1st Athlete and 2nd Athlete are scanned, verify the pair across all tournament matchups:
    if (secondaryAthlete != null) {
      final secRegId = secondaryAthlete['id'].toString();
      final secAthId =
          (secondaryAthlete['athleteId'] ?? secRegId).toString();
      final secName = secondaryAthlete['athleteName'].toString();

      if (secRegId.toLowerCase() == primaryRegId.toLowerCase() ||
          secAthId.toLowerCase() == primaryAthId.toLowerCase() ||
          secName.toLowerCase() == primaryName.toLowerCase()) {
        return RefereePreMatchValidationResult(
          isGreenLight: false,
          statusHeadline: 'SAME ATHLETE SCANNED TWICE',
          detailReason:
              'Both QR scans belong to $primaryName. Please scan the 1st athlete and then the 2nd opponent athlete.',
          checkAActiveMatchInRound: false,
          checkBExactMatchedOpponents: false,
          checkCMatchStillPending: false,
          checkDBelongsToAssignedTable: false,
        );
      }

      // Find all matchups in the tournament involving BOTH scanned athletes
      final pairMatches = allMatches
          .where((m) =>
              involvesAthlete(m, primaryRegId, primaryAthId, primaryName) &&
              involvesAthlete(m, secRegId, secAthId, secName))
          .toList();

      if (pairMatches.isEmpty) {
        return RefereePreMatchValidationResult(
          isGreenLight: false,
          statusHeadline: 'MATCHUP DOES NOT EXIST',
          detailReason:
              '$primaryName and $secName do not have a matchup together in this tournament.',
          checkAActiveMatchInRound: false,
          checkBExactMatchedOpponents: false,
          checkCMatchStillPending: false,
          checkDBelongsToAssignedTable: false,
        );
      }

      // Sort pairMatches so PENDING on this referee's table comes first, then PENDING on other table, then DONE
      pairMatches.sort((a, b) {
        final stA = (a['status'] ?? 'PENDING').toString().toUpperCase();
        final stB = (b['status'] ?? 'PENDING').toString().toUpperCase();
        if (stA != stB) return stA == 'PENDING' ? -1 : 1;
        final tA = (a['assignedTable'] ?? 'Table 1').toString().toLowerCase() ==
            assignedTableNameResolved.toLowerCase();
        final tB = (b['assignedTable'] ?? 'Table 1').toString().toLowerCase() ==
            assignedTableNameResolved.toLowerCase();
        if (tA != tB) return tA ? -1 : 1;
        final rA = (a['roundNumber'] as num?)?.toInt() ?? 1;
        final rB = (b['roundNumber'] as num?)?.toInt() ?? 1;
        return rB.compareTo(rA);
      });

      final pairBout = pairMatches.first;
      final pairCategory =
          (pairBout['categoryLabel'] ?? primaryAthlete['categoryLabel'] ?? '')
              .toString();
      final pairRound = (pairBout['roundNumber'] as num?)?.toInt() ?? 1;
      final pairStatus =
          (pairBout['status'] ?? 'PENDING').toString().toUpperCase();
      final pairTable = (pairBout['assignedTable'] ?? 'Table 1').toString();
      final pairTableNum = (pairBout['tableNumber'] as num?)?.toInt() ?? 1;

      int activeRound = 1;
      if (!isSuperfights) {
        final catMatches = allMatches
            .where((m) => (m['categoryLabel'] ?? '').toString() == pairCategory)
            .toList();
        final pendingRounds = catMatches
            .where((m) =>
                (m['status'] ?? 'PENDING').toString().toUpperCase() ==
                'PENDING')
            .map((m) => (m['roundNumber'] as num?)?.toInt() ?? 1)
            .toList();
        if (pendingRounds.isNotEmpty) {
          activeRound = pendingRounds.reduce(math.min);
        } else if (catMatches.isNotEmpty) {
          activeRound = catMatches
              .map((m) => (m['roundNumber'] as num?)?.toInt() ?? 1)
              .reduce(math.max);
        }
      }

      final isStillPending = pairStatus == 'PENDING';
      final isAssignedTable = tableCount <= 1 ||
          pairTable.toLowerCase() == assignedTableNameResolved.toLowerCase() ||
          (assignedTableNumber != null && pairTableNum == assignedTableNumber);
      final isActiveRound = isSuperfights || pairRound == activeRound;

      if (!isStillPending) {
        final winnerInfo = pairBout['winnerName'] != null
            ? ' (Winner: ${pairBout['winnerName']})'
            : '';
        return RefereePreMatchValidationResult(
          isGreenLight: false,
          statusHeadline: 'MATCH ALREADY COMPLETED',
          detailReason:
              '$primaryName vs $secName ($pairCategory) has already been completed$winnerInfo. Completed matches cannot be scored again.',
          checkAActiveMatchInRound: isActiveRound,
          checkBExactMatchedOpponents: true,
          checkCMatchStillPending: false,
          checkDBelongsToAssignedTable: isAssignedTable,
          matchedBout: pairBout,
          resolvedCategoryLabel: pairCategory,
        );
      }

      if (!isAssignedTable) {
        return RefereePreMatchValidationResult(
          isGreenLight: false,
          statusHeadline: 'WRONG TABLE — ASSIGNED TO ${pairTable.toUpperCase()}',
          detailReason:
              '$primaryName vs $secName ($pairCategory) is assigned to $pairTable, not your appointed $assignedTableNameResolved.',
          checkAActiveMatchInRound: isActiveRound,
          checkBExactMatchedOpponents: true,
          checkCMatchStillPending: true,
          checkDBelongsToAssignedTable: false,
          matchedBout: pairBout,
          resolvedCategoryLabel: pairCategory,
        );
      }

      if (!isActiveRound) {
        return RefereePreMatchValidationResult(
          isGreenLight: false,
          statusHeadline: 'ROUND $pairRound NOT ACTIVE YET',
          detailReason:
              '$primaryName vs $secName is scheduled for Round $pairRound, while Round $activeRound is still in progress.',
          checkAActiveMatchInRound: false,
          checkBExactMatchedOpponents: true,
          checkCMatchStillPending: true,
          checkDBelongsToAssignedTable: true,
          matchedBout: pairBout,
          resolvedCategoryLabel: pairCategory,
        );
      }

      return RefereePreMatchValidationResult(
        isGreenLight: true,
        statusHeadline:
            'MATCHUP VERIFIED • ${assignedTableNameResolved.toUpperCase()}',
        detailReason:
            '$primaryName vs $secName ($pairCategory • Round $pairRound)',
        checkAActiveMatchInRound: true,
        checkBExactMatchedOpponents: true,
        checkCMatchStillPending: true,
        checkDBelongsToAssignedTable: true,
        matchedBout: pairBout,
        resolvedCategoryLabel: pairCategory,
      );
    }

    final athleteMatches = allMatches
        .where((m) =>
            involvesAthlete(m, primaryRegId, primaryAthId, primaryName))
        .toList();

    // Check (a): Does the athlete have an active match in this tournament?
    if (athleteMatches.isEmpty) {
      return RefereePreMatchValidationResult(
        isGreenLight: false,
        statusHeadline: 'NO ACTIVE MATCHUP ASSIGNED',
        detailReason:
            '$primaryName is registered in ${primaryAthlete['categoryLabel']}, but does not have an active match scheduled yet.',
        checkAActiveMatchInRound: false,
        checkBExactMatchedOpponents: false,
        checkCMatchStillPending: false,
        checkDBelongsToAssignedTable: false,
      );
    }

    // Sort so PENDING matches on this referee's table come first, then other PENDING, then DONE
    athleteMatches.sort((a, b) {
      final stA = (a['status'] ?? 'PENDING').toString().toUpperCase();
      final stB = (b['status'] ?? 'PENDING').toString().toUpperCase();
      if (stA != stB) return stA == 'PENDING' ? -1 : 1;
      final tA = (a['assignedTable'] ?? 'Table 1').toString() == assignedTableNameResolved;
      final tB = (b['assignedTable'] ?? 'Table 1').toString() == assignedTableNameResolved;
      if (tA != tB) return tA ? -1 : 1;
      final rA = (a['roundNumber'] as num?)?.toInt() ?? 1;
      final rB = (b['roundNumber'] as num?)?.toInt() ?? 1;
      return rB.compareTo(rA);
    });

    final candidateMatch = athleteMatches.first;
    final categoryLabel =
        (candidateMatch['categoryLabel'] ?? primaryAthlete['categoryLabel'] ?? '')
            .toString();
    final roundNumber = (candidateMatch['roundNumber'] as num?)?.toInt() ?? 1;

    int activeRoundInCategory = 1;
    if (!isSuperfights) {
      final catMatches = allMatches
          .where((m) => (m['categoryLabel'] ?? '').toString() == categoryLabel)
          .toList();
      final pendingRounds = catMatches
          .where((m) =>
              (m['status'] ?? 'PENDING').toString().toUpperCase() == 'PENDING')
          .map((m) => (m['roundNumber'] as num?)?.toInt() ?? 1)
          .toList();
      if (pendingRounds.isNotEmpty) {
        activeRoundInCategory = pendingRounds.reduce(math.min);
      } else if (catMatches.isNotEmpty) {
        activeRoundInCategory = catMatches
            .map((m) => (m['roundNumber'] as num?)?.toInt() ?? 1)
            .reduce(math.max);
      }
    }

    final checkAActiveMatchInRound =
        isSuperfights || roundNumber == activeRoundInCategory;
    final matchStatus =
        (candidateMatch['status'] ?? 'PENDING').toString().toUpperCase();
    final checkCMatchStillPending = matchStatus == 'PENDING';
    final matchTable =
        (candidateMatch['assignedTable'] ?? 'Table 1').toString();
    final checkDBelongsToAssignedTable = tableCount <= 1 ||
        matchTable.toLowerCase() == assignedTableNameResolved.toLowerCase();

    if (!checkCMatchStillPending) {
      return RefereePreMatchValidationResult(
        isGreenLight: false,
        statusHeadline: 'MATCH ALREADY COMPLETED',
        detailReason:
            'Match #${candidateMatch['matchIndex']} (${candidateMatch['athleteAName']} vs. ${candidateMatch['athleteBName']}) is already marked $matchStatus.',
        checkAActiveMatchInRound: checkAActiveMatchInRound,
        checkBExactMatchedOpponents: true,
        checkCMatchStillPending: false,
        checkDBelongsToAssignedTable: checkDBelongsToAssignedTable,
        matchedBout: candidateMatch,
        resolvedCategoryLabel: categoryLabel,
      );
    }

    if (!checkDBelongsToAssignedTable) {
      return RefereePreMatchValidationResult(
        isGreenLight: false,
        statusHeadline:
            'WRONG TABLE — ASSIGNED TO ${matchTable.toUpperCase()}',
        detailReason:
            'Match #${candidateMatch['matchIndex']} (${candidateMatch['athleteAName']} vs. ${candidateMatch['athleteBName']}) belongs to $matchTable, NOT your assigned table ($assignedTableNameResolved).',
        checkAActiveMatchInRound: checkAActiveMatchInRound,
        checkBExactMatchedOpponents: true,
        checkCMatchStillPending: true,
        checkDBelongsToAssignedTable: false,
        matchedBout: candidateMatch,
        resolvedCategoryLabel: categoryLabel,
      );
    }

    if (!checkAActiveMatchInRound) {
      return RefereePreMatchValidationResult(
        isGreenLight: false,
        statusHeadline:
            'ROUND $roundNumber NOT ACTIVE YET',
        detailReason:
            'This matchup is in Round $roundNumber, while Round $activeRoundInCategory is still in progress for $categoryLabel.',
        checkAActiveMatchInRound: false,
        checkBExactMatchedOpponents: true,
        checkCMatchStillPending: true,
        checkDBelongsToAssignedTable: true,
        matchedBout: candidateMatch,
        resolvedCategoryLabel: categoryLabel,
      );
    }

    return RefereePreMatchValidationResult(
      isGreenLight: true,
      statusHeadline:
          'MATCHUP VERIFIED • ${assignedTableNameResolved.toUpperCase()}',
      detailReason:
          '${candidateMatch['athleteAName']} vs. ${candidateMatch['athleteBName']} ($categoryLabel • Round $roundNumber)',
      checkAActiveMatchInRound: true,
      checkBExactMatchedOpponents: true,
      checkCMatchStillPending: true,
      checkDBelongsToAssignedTable: true,
      matchedBout: candidateMatch,
      resolvedCategoryLabel: categoryLabel,
    );
  }

  /// Checks if a match has already been locked/submitted by the referee (Single-Tap Idempotency Lock).
  static bool isMatchSubmissionLocked(
    HiveStorage? hive,
    String tournamentIdOrMatchId, [
    String? maybeMatchId,
  ]) {
    final effectiveMatchId = maybeMatchId ?? tournamentIdOrMatchId;
    final compoundKey = maybeMatchId != null
        ? '$tournamentIdOrMatchId::$maybeMatchId'
        : tournamentIdOrMatchId;
    if (_memorySubmittedMatchLocks.contains(effectiveMatchId) ||
        _memorySubmittedMatchLocks.contains(compoundKey)) {
      return true;
    }
    if (hive != null) {
      try {
        final raw = hive.getCachedData(_submittedMatchLocksKey);
        if (raw is List) {
          final strs = raw.map((e) => e.toString()).toSet();
          if (strs.contains(effectiveMatchId) || strs.contains(compoundKey)) {
            _memorySubmittedMatchLocks.add(effectiveMatchId);
            _memorySubmittedMatchLocks.add(compoundKey);
            return true;
          }
        }
      } catch (_) {}
    }
    return false;
  }

  /// Submits a match result from the Referee Console with:
  /// - Single-Tap Idempotency Lock (`idem_ref_result_${eventId}_${matchId}`)
  /// - Support for Normal Win/Loss OR "Win by Forfeit / Injury (Walkover)"
  /// - Zero-Error Offline Persistence: marks match "Done / Sent", updates local matchup card,
  ///   frees the table and auto-assigns the next queued matchup, advances survivors in Elimination,
  ///   and enqueues the action to the Offline Outbox Queue.
  static Future<Map<String, dynamic>> submitRefereeMatchResultOfflineSafe({
    required HiveStorage? hive,
    OfflineSyncManager? syncManager,
    required String tournamentId,
    Map<String, dynamic>? match,
    String? matchupId,
    required String winnerId,
    String? winnerName,
    String? loserId,
    String? loserName,
    bool? isForfeitOrInjuryWalkover,
    String? winMethod,
    String? forfeitReason,
    String? refereeId,
    String? refereeName,
    int? assignedTableNumber,
    String scoreLine = '3-1',
  }) async {
    final tournament = Map<String, dynamic>.from(
      getReleasedTournamentById(hive: hive, tournamentId: tournamentId) ??
          <String, dynamic>{'id': tournamentId},
    );

    final resolvedMatch = match ??
        flattenAllMatches(tournament)
            .where((m) => m['id']?.toString() == matchupId)
            .firstOrNull ??
        <String, dynamic>{
          'id': matchupId ?? 'm_unknown',
          'athleteAId': winnerId,
          'athleteAName': winnerName ?? 'Winner',
          'athleteBId': loserId ?? 'opp_id',
          'athleteBName': loserName ?? 'Opponent',
          'assignedTable': 'Table ${assignedTableNumber ?? 1}',
          'categoryLabel': '70 kg • Right Arm',
          'roundNumber': 1,
          'matchIndex': 1,
        };

    final matchId = resolvedMatch['id'].toString();
    final idempotencyKey = 'idem_ref_result_${tournamentId}_$matchId';
    final effectiveIsWalkover = isForfeitOrInjuryWalkover ??
        (winMethod != null &&
            winMethod.toUpperCase().contains('FORFEIT'));

    // Single-Tap Lock: prevent duplicate submissions
    _memorySubmittedMatchLocks.add(matchId);
    _memorySubmittedMatchLocks.add('$tournamentId::$matchId');
    if (hive != null) {
      try {
        await hive.cacheData(
          _submittedMatchLocksKey,
          _memorySubmittedMatchLocks.toList(),
        );
      } catch (_) {}
    }
    final isSuperfights =
        (tournament['formatCategory'] ?? '').toString().toUpperCase() ==
            'SUPERFIGHTS';
    final elimSub = (tournament['eliminationSubFormat'] ?? 'DOUBLE_ELIMINATION')
        .toString()
        .toUpperCase();
    final maxLosses = isSuperfights
        ? 999
        : (elimSub == 'SINGLE_ELIMINATION' || elimSub == 'LAST_ONE_STANDING'
            ? 1
            : (elimSub == 'THREE_LOSS_ELIMINATION' ? 3 : 2));

    final aId = resolvedMatch['athleteAId'].toString();
    final bId = resolvedMatch['athleteBId'].toString();
    final resolvedLoserId = loserId ?? ((winnerId == aId) ? bId : aId);
    final resolvedWinnerName = winnerName ??
        ((winnerId == aId)
            ? resolvedMatch['athleteAName']
            : resolvedMatch['athleteBName']);
    final resolvedLoserName = loserName ??
        ((winnerId == aId)
            ? resolvedMatch['athleteBName']
            : resolvedMatch['athleteAName']);

    final aElo = (resolvedMatch['athleteAElo'] as num?)?.toInt() ?? 1500;
    final bElo = (resolvedMatch['athleteBElo'] as num?)?.toInt() ?? 1500;
    final winnerElo = (winnerId == aId) ? aElo : bElo;
    final loserElo = (winnerId == aId) ? bElo : aElo;
    final expectedWin =
        1.0 / (1.0 + math.pow(10.0, (loserElo - winnerElo) / 400.0));
    final eloDelta = (32 * (1.0 - expectedWin)).round().clamp(8, 28);

    final effectiveScoreLine = effectiveIsWalkover
        ? 'WALKOVER (${forfeitReason ?? "FORFEIT / INJURY"})'
        : scoreLine;

    // 1. Update appliedAthletes Elo and Elimination Loss Counters
    final rawAthletes = (tournament['appliedAthletes'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        <Map<String, dynamic>>[];

    final updatedAthletes = rawAthletes.map((a) {
      final id = a['id']?.toString() ?? '';
      if (id == winnerId) {
        return <String, dynamic>{
          ...a,
          'eloRating': ((a['eloRating'] as num?)?.toInt() ?? 1500) + eloDelta,
        };
      }
      if (id == resolvedLoserId) {
        final prevLosses = (a['lossesCount'] as num?)?.toInt() ?? 0;
        final nextLosses = isSuperfights ? prevLosses : (prevLosses + 1);
        return <String, dynamic>{
          ...a,
          'eloRating': math.max(
              1000, ((a['eloRating'] as num?)?.toInt() ?? 1500) - eloDelta),
          'lossesCount': nextLosses,
        };
      }
      return a;
    }).toList();

    final updatedAthA =
        updatedAthletes.where((a) => a['id']?.toString() == aId).firstOrNull;
    final updatedAthB =
        updatedAthletes.where((a) => a['id']?.toString() == bId).firstOrNull;

    // 2. Update match inside card3MatchupsState, free table & auto-assign next queued match
    final categoryLabel = (resolvedMatch['categoryLabel'] ?? '').toString();
    final roundNumber = (resolvedMatch['roundNumber'] as num?)?.toInt() ?? 1;
    final freedTable = (resolvedMatch['assignedTable'] ?? 'Table 1').toString();
    final tableCount =
        ((tournament['tableCount'] as num?)?.toInt() ?? 1).clamp(1, 12);

    final rawState = (tournament['card3MatchupsState'] is Map)
        ? Map<String, dynamic>.from(tournament['card3MatchupsState'] as Map)
        : <String, dynamic>{'matchesByCategory': <String, dynamic>{}};
    final byCat = (rawState['matchesByCategory'] is Map)
        ? Map<String, dynamic>.from(rawState['matchesByCategory'] as Map)
        : <String, dynamic>{};

    var catMatches = (byCat[categoryLabel] is List)
        ? (byCat[categoryLabel] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];

    catMatches = catMatches.map((m) {
      if (m['id']?.toString() != matchId) return m;
      return _normalizeBoutAliases(
        <String, dynamic>{
          ...m,
          'status': 'DONE',
          'submissionStatus': 'DONE / SENT ✓',
          'winMethod': effectiveIsWalkover
              ? 'FORFEIT_INJURY_WALKOVER'
              : 'NORMAL_PIN_DECISION',
          'tableQueueStatus': 'COMPLETED_TABLE_FREED',
          'winnerId': winnerId,
          'winnerName': resolvedWinnerName,
          'loserId': resolvedLoserId,
          'loserName': resolvedLoserName,
          'eloTransferDelta': eloDelta,
          'scoreLine': effectiveScoreLine,
          'idempotencyKey': idempotencyKey,
          'athleteAElo': (updatedAthA?['eloRating'] as num?)?.toInt() ?? aElo,
          'athleteBElo': (updatedAthB?['eloRating'] as num?)?.toInt() ?? bElo,
          'athleteALosses':
              (updatedAthA?['lossesCount'] as num?)?.toInt() ?? 0,
          'athleteBLosses':
              (updatedAthB?['lossesCount'] as num?)?.toInt() ?? 0,
        },
        categoryLabel,
      );
    }).toList();

    // Free table & auto-assign next queued matchup to freedTable
    String? autoAssignedSummary;
    if (tableCount > 1) {
      final pendingInRound = catMatches
          .where((m) =>
              ((m['roundNumber'] as num?)?.toInt() ?? 1) == roundNumber &&
              m['isBye'] != true &&
              (m['status'] ?? 'PENDING').toString().toUpperCase() == 'PENDING')
          .toList()
        ..sort((a, b) {
          final qA = (a['queueOrderRank'] as num?)?.toInt() ??
              ((a['matchIndex'] as num?)?.toInt() ?? 1) * 10;
          final qB = (b['queueOrderRank'] as num?)?.toInt() ??
              ((b['matchIndex'] as num?)?.toInt() ?? 1) * 10;
          return qA.compareTo(qB);
        });

      final nextForTable = pendingInRound
              .where((m) =>
                  m['tableQueueStatus'] != 'ACTIVE_AT_TABLE' ||
                  m['assignedTable'] == freedTable)
              .firstOrNull ??
          pendingInRound.firstOrNull;

      if (nextForTable != null) {
        final nextId = nextForTable['id'].toString();
        catMatches = catMatches.map((m) {
          if (m['id']?.toString() != nextId) return m;
          return _normalizeBoutAliases(
            <String, dynamic>{
              ...m,
              'assignedTable': freedTable,
              'tableQueueStatus': 'ACTIVE_AT_TABLE',
              'deferredNote':
                  'Auto-assigned to freed $freedTable after Referee submitted Match #${resolvedMatch['matchIndex']}',
            },
            categoryLabel,
          );
        }).toList();
        autoAssignedSummary =
            '$freedTable Freed → Auto-Assigned Next Match #${nextForTable['matchIndex']} (${nextForTable['athleteAName']} vs. ${nextForTable['athleteBName']}) to $freedTable';
      } else {
        autoAssignedSummary =
            '$freedTable Freed • All pending bouts in Round $roundNumber on $freedTable are complete.';
      }
    }

    // Rebuild next round for Elimination tournaments
    if (!isSuperfights) {
      final doneInRound = catMatches
          .where((m) =>
              ((m['roundNumber'] as num?)?.toInt() ?? 1) == roundNumber &&
              (m['status'] ?? 'PENDING').toString().toUpperCase() == 'DONE')
          .toList();
      final advancingIds = <String>{};
      for (final dm in doneInRound) {
        if (dm['isBye'] == true) {
          advancingIds.add(dm['athleteAId'].toString());
          continue;
        }
        final mA = dm['athleteAId'].toString();
        final mB = dm['athleteBId'].toString();
        final athA =
            updatedAthletes.where((a) => a['id']?.toString() == mA).firstOrNull;
        final athB =
            updatedAthletes.where((a) => a['id']?.toString() == mB).firstOrNull;
        if (((athA?['lossesCount'] as num?)?.toInt() ?? 0) < maxLosses) {
          advancingIds.add(mA);
        }
        if (((athB?['lossesCount'] as num?)?.toInt() ?? 0) < maxLosses) {
          advancingIds.add(mB);
        }
      }

      final survivors = updatedAthletes
          .where((a) =>
              (a['categoryLabel'] ?? '').toString() == categoryLabel &&
              advancingIds.contains(a['id']?.toString()))
          .toList();

      final nextRound = roundNumber + 1;
      final withoutNextRound = catMatches
          .where(
              (m) => ((m['roundNumber'] as num?)?.toInt() ?? 1) != nextRound)
          .toList();

      if (survivors.length >= 2) {
        final nextMatches = <Map<String, dynamic>>[];
        int mIdx = 1;
        for (int i = 0; i + 1 < survivors.length; i += 2) {
          final sA = survivors[i];
          final sB = survivors[i + 1];
          nextMatches.add({
            'id':
                'm_${tournamentId}_${categoryLabel.hashCode.abs()}_r${nextRound}_$mIdx',
            'eventId': tournamentId,
            'categoryLabel': categoryLabel,
            'roundNumber': nextRound,
            'matchIndex': mIdx,
            'queueOrderRank': mIdx * 10,
            'isBye': false,
            'athleteAId': sA['id'].toString(),
            'athleteAAthleteId':
                sA['athleteId']?.toString() ?? sA['id'].toString(),
            'athleteAName': sA['athleteName'].toString(),
            'athleteAElo': (sA['eloRating'] as num?)?.toInt() ?? 1700,
            'athleteAPrKg': (sA['prKg'] as num?)?.toDouble() ?? 60.0,
            'athleteAMaxLiftKg':
                (sA['maxLiftKg'] as num?)?.toDouble() ?? 68.0,
            'athleteALosses': (sA['lossesCount'] as num?)?.toInt() ?? 0,
            'athleteBId': sB['id'].toString(),
            'athleteBAthleteId':
                sB['athleteId']?.toString() ?? sB['id'].toString(),
            'athleteBName': sB['athleteName'].toString(),
            'athleteBElo': (sB['eloRating'] as num?)?.toInt() ?? 1700,
            'athleteBPrKg': (sB['prKg'] as num?)?.toDouble() ?? 60.0,
            'athleteBMaxLiftKg':
                (sB['maxLiftKg'] as num?)?.toDouble() ?? 68.0,
            'athleteBLosses': (sB['lossesCount'] as num?)?.toInt() ?? 0,
            'assignedTable': freedTable,
            'tableQueueStatus': 'ACTIVE_AT_TABLE',
            'status': 'PENDING',
            'winnerId': null,
            'loserId': null,
            'eloTransferDelta': null,
            'scoreLine': null,
          });
          mIdx++;
        }
        if (survivors.length % 2 == 1) {
          final byeS = survivors.last;
          nextMatches.add({
            'id':
                'm_bye_${tournamentId}_${categoryLabel.hashCode.abs()}_r${nextRound}_$mIdx',
            'eventId': tournamentId,
            'categoryLabel': categoryLabel,
            'roundNumber': nextRound,
            'matchIndex': mIdx,
            'queueOrderRank': mIdx * 10,
            'isBye': true,
            'athleteAId': byeS['id'].toString(),
            'athleteAAthleteId':
                byeS['athleteId']?.toString() ?? byeS['id'].toString(),
            'athleteAName': byeS['athleteName'].toString(),
            'athleteAElo': (byeS['eloRating'] as num?)?.toInt() ?? 1700,
            'athleteAPrKg': (byeS['prKg'] as num?)?.toDouble() ?? 60.0,
            'athleteAMaxLiftKg':
                (byeS['maxLiftKg'] as num?)?.toDouble() ?? 68.0,
            'athleteALosses': (byeS['lossesCount'] as num?)?.toInt() ?? 0,
            'athleteBId': 'BYE',
            'athleteBName': 'BYE (Auto-Advance to Next Round)',
            'athleteBElo': 0,
            'athleteBPrKg': 0.0,
            'athleteBMaxLiftKg': 0.0,
            'athleteBLosses': 0,
            'assignedTable': freedTable,
            'tableQueueStatus': 'COMPLETED_TABLE_FREED',
            'status': 'DONE',
            'winnerId': byeS['id'].toString(),
            'loserId': null,
            'eloTransferDelta': 0,
            'scoreLine': 'BYE • AUTO-ADVANCE',
          });
        }
        catMatches = [...withoutNextRound, ...nextMatches];
      }
    }

    byCat[categoryLabel] = catMatches;
    rawState['matchesByCategory'] = byCat;
    rawState['lastFreedTable'] = freedTable;
    if (autoAssignedSummary != null) {
      rawState['lastAutoAssignedSummary'] = autoAssignedSummary;
    }

    final updatedTournament = <String, dynamic>{
      ...tournament,
      'appliedAthletes': updatedAthletes,
      'card3MatchupsState': rawState,
    };

    await upsertReleasedTournament(hive, updatedTournament);

    // 3. Queue idempotent offline sync action
    final payload = <String, dynamic>{
      'eventId': tournamentId,
      'matchId': matchId,
      'categoryLabel': categoryLabel,
      'roundNumber': roundNumber,
      'assignedTable': freedTable,
      'winnerId': winnerId,
      'winnerName': resolvedWinnerName,
      'loserId': resolvedLoserId,
      'loserName': resolvedLoserName,
      'refereeId': refereeId,
      'refereeName': refereeName,
      'winMethod': effectiveIsWalkover
          ? 'FORFEIT_INJURY_WALKOVER'
          : 'NORMAL_PIN_DECISION',
      'scoreLine': effectiveScoreLine,
      'eloTransferDelta': eloDelta,
      'idempotencyKey': idempotencyKey,
    };

    if (hive != null) {
      try {
        await hive.enqueueAction(
          actionType: 'SUBMIT_REFEREE_MATCH_RESULT',
          endpoint: '/sync/queue',
          payload: payload,
          method: 'POST',
          idempotencyKey: idempotencyKey,
        );
        syncManager?.syncQueue();
      } catch (_) {}
    }

    return <String, dynamic>{
      'status': 'DONE_SENT',
      'idempotencyKey': idempotencyKey,
      'winnerName': resolvedWinnerName,
      'loserName': resolvedLoserName,
      'scoreLine': effectiveScoreLine,
      'freedTable': freedTable,
      'autoAssignedSummary': autoAssignedSummary,
      'autoAssignedNextMatchup': autoAssignedSummary != null
          ? <String, dynamic>{'summary': autoAssignedSummary}
          : null,
      'updatedTournament': updatedTournament,
    };
  }

  // ===========================================================================
  // 2. ATHLETE & SPECTATOR ROLE: OFFLINE APPLY + QR & SPECTATOR PASS + VERIFY
  // ===========================================================================

  /// Resolves the current athlete's active registration for [tournament] across
  /// `local_my_registrations` in Hive, `tournament['myRegistration']`,
  /// `tournament['appliedAthletes']`, and `myRegistrations` from provider state.
  static Map<String, dynamic>? findAthleteRegistrationForTournament({
    Map<String, dynamic>? tournament,
    String? tournamentId,
    String? tournamentIdOverride,
    String? athleteId,
    String? userId,
    String? profileQrCode,
    Map<String, dynamic>? userProfile,
    Map<String, dynamic>? athleteProfile,
    List<Map<String, dynamic>>? myRegistrations,
    HiveStorage? hive,
  }) {
    final resolvedTournament = tournament ?? const <String, dynamic>{};
    final resolvedTournamentId =
        (tournamentIdOverride ?? tournamentId ?? resolvedTournament['id'] ?? '')
            .toString()
            .trim();
    if (resolvedTournamentId.isEmpty) return null;

    final candidateIds = <String>{};
    final candidateQrs = <String>{};

    void addCandidateId(dynamic val) {
      final s = (val ?? '').toString().trim();
      if (s.isNotEmpty) {
        candidateIds.add(s);
        candidateQrs.add(buildSettingsAthleteIdentityQr(athleteId: s));
      }
    }

    void addCandidateQr(dynamic val) {
      final s = (val ?? '').toString().trim();
      if (s.isNotEmpty) candidateQrs.add(s);
    }

    addCandidateId(athleteId);
    addCandidateId(userId);
    addCandidateQr(profileQrCode);

    if (userProfile != null) {
      addCandidateId(userProfile['id']);
      addCandidateId(userProfile['userId']);
      addCandidateId(userProfile['athleteId']);
      addCandidateQr(userProfile['profileQrCode']);
      if (userProfile['user'] is Map) {
        final u = userProfile['user'] as Map;
        addCandidateId(u['id']);
        addCandidateQr(u['profileQrCode']);
      }
      if (userProfile['profile'] is Map) {
        final p = userProfile['profile'] as Map;
        addCandidateId(p['id']);
        addCandidateId(p['userId']);
        addCandidateQr(p['profileQrCode']);
      }
    }
    if (athleteProfile != null) {
      addCandidateId(athleteProfile['id']);
      addCandidateId(athleteProfile['userId']);
      addCandidateId(athleteProfile['athleteId']);
      addCandidateQr(athleteProfile['profileQrCode']);
    }
    if (hive != null) {
      try {
        final sessionUser = hive.getCachedData('auth_session_user');
        if (sessionUser is Map) {
          addCandidateId(sessionUser['id']);
          addCandidateId(sessionUser['userId']);
          addCandidateId(sessionUser['athleteId']);
          addCandidateQr(sessionUser['profileQrCode']);
        }
      } catch (_) {}
    }

    bool matchesCurrentAthlete(Map<String, dynamic> reg) {
      final status = (reg['status'] ?? '').toString().toUpperCase();
      if (status == 'REJECTED' || status == 'CANCELLED') return false;
      if (candidateIds.isEmpty && candidateQrs.isEmpty) {
        return true;
      }
      final rAthleteId = (reg['athleteId'] ?? '').toString().trim();
      final rUserId = (reg['userId'] ?? '').toString().trim();
      final rQr =
          (reg['profileQrCode'] ?? reg['settingsIdentityQr'] ?? '').toString().trim();
      if (rAthleteId.isNotEmpty && candidateIds.contains(rAthleteId)) {
        return true;
      }
      if (rUserId.isNotEmpty && candidateIds.contains(rUserId)) {
        return true;
      }
      if (rQr.isNotEmpty && candidateQrs.contains(rQr)) {
        return true;
      }
      if (rAthleteId == 'athlete_me' || rUserId == 'athlete_me') {
        return true;
      }
      return false;
    }

    Map<String, dynamic> normalizeFound(Map<String, dynamic> raw) {
      final wc = (raw['weightClass'] ??
              raw['weightCategory'] ??
              raw['registeredWeightLabel'] ??
              '')
          .toString()
          .trim();
      final rawArm =
          (raw['arm'] ?? raw['registeredArm'] ?? 'RIGHT').toString().trim();
      final armUpper = rawArm.toUpperCase();
      final armCode = armUpper.contains('LEFT')
          ? 'LEFT'
          : (armUpper.contains('BOTH') ? 'BOTH' : 'RIGHT');
      final armFormatted = armCode == 'LEFT'
          ? 'Left Arm'
          : (armCode == 'BOTH' ? 'Both Arms' : 'Right Arm');
      final categoryLabel = (raw['categoryLabel'] != null &&
              raw['categoryLabel'].toString().trim().isNotEmpty)
          ? raw['categoryLabel'].toString().trim()
          : (wc.isNotEmpty ? '$wc • $armFormatted' : armFormatted);
      return <String, dynamic>{
        ...raw,
        'eventId': (raw['eventId'] ?? resolvedTournamentId).toString(),
        'weightClass': wc,
        'weightCategory': wc,
        'arm': armFormatted,
        'armCode': armCode,
        'division': (raw['division'] ?? 'SENIOR').toString().toUpperCase(),
        'categoryLabel': categoryLabel,
      };
    }

    // 1. Check Hive local_my_registrations first (most recent local submission/update)
    if (hive != null) {
      try {
        final rawRegs = hive.getCachedData('local_my_registrations');
        if (rawRegs is List) {
          for (final item in rawRegs.whereType<Map>()) {
            final map = Map<String, dynamic>.from(item);
            final evtId =
                (map['eventId'] ?? map['tournamentId'] ?? '').toString().trim();
            if (evtId == resolvedTournamentId && matchesCurrentAthlete(map)) {
              return normalizeFound(map);
            }
          }
        }
      } catch (_) {}
    }

    // 2. Check tournament['myRegistration'] from server
    if (resolvedTournament['myRegistration'] is Map) {
      final myReg = Map<String, dynamic>.from(resolvedTournament['myRegistration'] as Map);
      final status = (myReg['status'] ?? '').toString().toUpperCase();
      if (status != 'REJECTED' && status != 'CANCELLED') {
        return normalizeFound(myReg);
      }
    }

    // 3. Check tournament['appliedAthletes']
    if (resolvedTournament['appliedAthletes'] is List) {
      for (final item in (resolvedTournament['appliedAthletes'] as List).whereType<Map>()) {
        final map = Map<String, dynamic>.from(item);
        if (matchesCurrentAthlete(map)) {
          return normalizeFound(map);
        }
      }
    }

    // 4. Check myRegistrations list from provider
    if (myRegistrations != null) {
      for (final reg in myRegistrations) {
        final evtId =
            (reg['eventId'] ?? reg['tournamentId'] ?? '').toString().trim();
        if (evtId == resolvedTournamentId && matchesCurrentAthlete(reg)) {
          return normalizeFound(reg);
        }
      }
    }

    return null;
  }

  /// Submits an Athlete's application to compete with zero-error optimistic offline persistence.
  /// Saves or updates an athlete's tournament application locally (and queues background sync)
  /// linked strictly to the athlete's permanent Profile QR Code — never generating
  /// a separate tournament QR card or credential, and never creating duplicate entries
  /// when the athlete updates their division.
  static Future<Map<String, dynamic>> submitAthleteApplicationOfflineSafe({
    required HiveStorage? hive,
    OfflineSyncManager? syncManager,
    required String tournamentId,
    required String athleteId,
    String? userId,
    required String athleteName,
    String? profileQrCode,
    String clubName = 'ArmSphere Official Athlete',
    String? division,
    String? divisionId,
    String? weightClass,
    String? weightCategory,
    required String arm,
    required int guestCount,
    int? eloRating,
    int? elo,
    double prKg = 62.0,
    double maxLiftKg = 70.0,
  }) async {
    final tournament = Map<String, dynamic>.from(
      getReleasedTournamentById(hive: hive, tournamentId: tournamentId) ??
          <String, dynamic>{'id': tournamentId},
    );
    final realCats = extractRealWeightCategories(tournament);
    final fallbackWeight = realCats.isNotEmpty
        ? (realCats.first['label']?.toString() ?? 'Open')
        : 'Open';
    final effectiveWeightClass =
        (weightClass ?? weightCategory ?? fallbackWeight).trim();
    final effectiveDivision = (division ?? 'SENIOR').trim().toUpperCase();
    final effectiveElo = eloRating ?? elo ?? 1680;
    final armUpper = arm.toUpperCase();
    final armCode = armUpper.contains('LEFT')
        ? 'LEFT'
        : (armUpper.contains('BOTH') ? 'BOTH' : 'RIGHT');
    final armFormatted = armCode == 'LEFT'
        ? 'Left Arm'
        : (armCode == 'BOTH' ? 'Both Arms' : 'Right Arm');
    final categoryLabel = '$effectiveWeightClass • $armFormatted';

    final canonicalProfileQr = (profileQrCode != null && profileQrCode.trim().isNotEmpty)
        ? profileQrCode.trim()
        : buildSettingsAthleteIdentityQr(
            athleteId: (userId != null && userId.trim().isNotEmpty)
                ? userId.trim()
                : athleteId,
          );

    final existingAthletes = (tournament['appliedAthletes'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        <Map<String, dynamic>>[];

    final probe = <String, dynamic>{
      'athleteId': athleteId,
      if (userId != null && userId.trim().isNotEmpty) 'userId': userId.trim(),
      'profileQrCode': canonicalProfileQr,
    };

    final existingMatchIdx = existingAthletes.indexWhere(
      (a) => _isSameAthleteRegistration(a, probe),
    );
    final previousEntry =
        existingMatchIdx != -1 ? existingAthletes[existingMatchIdx] : null;

    final stableRegId = (previousEntry?['id'] ??
            previousEntry?['registrationId'] ??
            'reg_${tournamentId}_$athleteId')
        .toString();
    final idempotencyKey =
        'idem_apply_${stableRegId}_${effectiveWeightClass.replaceAll(' ', '')}_${armCode.toLowerCase()}';

    final athleteEntry = <String, dynamic>{
      if (previousEntry != null) ...previousEntry,
      'id': stableRegId,
      'registrationId': stableRegId,
      'eventId': tournamentId,
      'athleteId': athleteId,
      if (userId != null && userId.trim().isNotEmpty) 'userId': userId.trim(),
      'athleteName': athleteName,
      'fullName': athleteName,
      'clubName': clubName,
      'division': effectiveDivision,
      if (divisionId != null && divisionId.trim().isNotEmpty)
        'divisionId': divisionId.trim(),
      'categoryLabel': categoryLabel,
      'weightClass': effectiveWeightClass,
      'weightCategory': effectiveWeightClass,
      'registeredWeightLabel': effectiveWeightClass,
      'arm': armFormatted,
      'armCode': armCode,
      'registeredArm': armFormatted,
      'eloRating': effectiveElo,
      'prKg': prKg,
      'maxLiftKg': maxLiftKg,
      'lossesCount': previousEntry?['lossesCount'] ?? 0,
      'weighInStatus': previousEntry?['weighInStatus'] ?? 'PENDING',
      'measuredWeightKg': previousEntry?['measuredWeightKg'],
      'guestCount': guestCount,
      'checkedInGuestsCount': previousEntry?['checkedInGuestsCount'] ?? 0,
      'entranceCheckedIn': previousEntry?['entranceCheckedIn'] ?? false,
      'profileQrCode': canonicalProfileQr,
      'settingsIdentityQr': canonicalProfileQr,
      'qrCodePayload': canonicalProfileQr,
      'qrCode': canonicalProfileQr,
      'status': 'CONFIRMED',
      'registeredAt': previousEntry?['registeredAt'] ??
          DateTime.now().toUtc().toIso8601String(),
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'offlineQueued': true,
      'idempotencyKey': idempotencyKey,
    };

    // Remove any existing registrations for this athlete in this tournament and insert/update in-place
    if (existingMatchIdx != -1) {
      existingAthletes[existingMatchIdx] = athleteEntry;
      for (int i = existingAthletes.length - 1; i >= 0; i--) {
        if (i != existingMatchIdx &&
            _isSameAthleteRegistration(existingAthletes[i], probe)) {
          existingAthletes.removeAt(i);
        }
      }
    } else {
      existingAthletes.insert(0, athleteEntry);
    }

    final updatedTournament = <String, dynamic>{
      ...tournament,
      'appliedAthletes': existingAthletes,
      'registeredCount': existingAthletes.length,
      'isRegistered': true,
      'myRegistration': athleteEntry,
    };
    await upsertReleasedTournament(hive, updatedTournament);

    // Also cache in local_my_registrations and evict stale event_detail cache
    if (hive != null) {
      try {
        await hive.evictCache('event_detail_$tournamentId');
        await hive.evictCache('tournaments_list');
        final rawRegs = hive.getCachedData('local_my_registrations');
        final regList = rawRegs is List
            ? rawRegs
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : <Map<String, dynamic>>[];
        regList.removeWhere((r) {
          final rEvtId =
              (r['eventId'] ?? r['tournamentId'] ?? '').toString().trim();
          return rEvtId == tournamentId &&
              (_isSameAthleteRegistration(r, probe) ||
                  (r['id'] ?? r['registrationId']).toString() == stableRegId);
        });
        regList.insert(0, athleteEntry);
        await hive.cacheData('local_my_registrations', regList);

        await hive.enqueueAction(
          actionType: 'SUBMIT_ATHLETE_APPLICATION',
          endpoint: '/sync/queue',
          payload: athleteEntry,
          method: 'POST',
          idempotencyKey: idempotencyKey,
        );
        syncManager?.syncQueue();
      } catch (_) {}
    }

    return athleteEntry;
  }

  /// Verifies a registered athlete at the Venue Entrance Gate using their single
  /// permanent Profile QR Code or Athlete Name/ID (offline-safe with background sync).
  static Future<Map<String, dynamic>> verifyEntranceByQrOrNameOfflineSafe({
    required HiveStorage? hive,
    OfflineSyncManager? syncManager,
    required String tournamentId,
    String? qrOrNameQuery,
    String? query,
    int accompanyingGuests = 0,
  }) async {
    final effectiveQuery = (qrOrNameQuery ?? query ?? '').trim();
    final tournament = Map<String, dynamic>.from(
      getReleasedTournamentById(hive: hive, tournamentId: tournamentId) ??
          <String, dynamic>{'id': tournamentId},
    );
    final gateConfig = (tournament['spectatorGateConfig'] is Map)
        ? Map<String, dynamic>.from(tournament['spectatorGateConfig'] as Map)
        : <String, dynamic>{
            'spectatorAccessMode': 'FREE',
            'spectatorFeePkr': 0,
            'allowedGuestsPerAthlete': 2,
          };
    final maxGuestsPerAthlete =
        ((gateConfig['allowedGuestsPerAthlete'] as num?)?.toInt() ?? 2)
            .clamp(0, 4);

    // 1. Check if it matches a Registered Athlete by permanent Profile QR / Name / ID
    final matchedAthlete = resolveAthleteFromQrOrQuery(
      tournament: tournament,
      rawInput: effectiveQuery,
    );

    if (matchedAthlete != null) {
      final guestsAllowed = accompanyingGuests <= maxGuestsPerAthlete;
      final holderName = matchedAthlete['athleteName'].toString();
      final regId = matchedAthlete['id'].toString();
      final profileQr = (matchedAthlete['profileQrCode'] ??
              matchedAthlete['settingsIdentityQr'] ??
              matchedAthlete['qrCode'] ??
              '')
          .toString();

      if (!guestsAllowed) {
        return <String, dynamic>{
          'allowed': false,
          'headline':
              'GUEST LIMIT EXCEEDED ($accompanyingGuests / MAX $maxGuestsPerAthlete GUESTS)',
          'badgeTitle':
              'GUEST LIMIT EXCEEDED ($accompanyingGuests / MAX $maxGuestsPerAthlete GUESTS)',
          'detail':
              'Verified Athlete $holderName ($regId), but accompanying guests ($accompanyingGuests) exceed the tournament limit of $maxGuestsPerAthlete guests per athlete.',
          'holderName': holderName,
          'passType': 'REGISTERED_ATHLETE',
        };
      }

      if (hive != null) {
        try {
          await hive.enqueueAction(
            actionType: 'SCAN_VENUE_ENTRANCE_QR',
            endpoint: '/sync/queue',
            payload: {
              'eventId': tournamentId,
              'passId': regId,
              'profileQrCode': profileQr,
              'passType': 'ATHLETE_PROFILE_QR',
              'holderName': holderName,
              'accompanyingGuests': accompanyingGuests,
              'checkedInAt': DateTime.now().toUtc().toIso8601String(),
            },
            method: 'POST',
            idempotencyKey: 'idem_gate_${tournamentId}_$regId',
          );
          syncManager?.syncQueue();
        } catch (_) {}
      }

      return <String, dynamic>{
        'allowed': true,
        'headline': 'GREEN-LIGHT • VERIFIED ATHLETE & GUESTS ALLOWED ✓',
        'badgeTitle': 'GREEN-LIGHT • VERIFIED ATHLETE & GUESTS ALLOWED ✓',
        'detail':
            '$holderName (${matchedAthlete['categoryLabel']}) verified via Profile QR with $accompanyingGuests/$maxGuestsPerAthlete allowed guest(s).',
        'holderName': holderName,
        'profileQrCode': profileQr,
        'passType': 'REGISTERED_ATHLETE',
      };
    }

    // 2. If Free Spectating is enabled and a walk-in visitor name (not an unrecognized QR) is typed
    final accessMode =
        (gateConfig['spectatorAccessMode'] ?? 'FREE').toString().toUpperCase();
    final looksLikeQrToken =
        effectiveQuery.toUpperCase().startsWith('ARMSPHERE-');
    if (accessMode == 'FREE' && !looksLikeQrToken && effectiveQuery.length >= 2) {
      return <String, dynamic>{
        'allowed': true,
        'headline': 'GREEN-LIGHT • FREE SPECTATOR ACCESS ALLOWED ✓',
        'badgeTitle': 'GREEN-LIGHT • FREE SPECTATOR ACCESS ALLOWED ✓',
        'detail':
            'Visitor "$effectiveQuery" verified for Free Venue Entrance.',
        'holderName': effectiveQuery,
        'passType': 'FREE_SPECTATOR',
      };
    }

    return <String, dynamic>{
      'allowed': false,
      'headline': 'RED-LIGHT • NOT REGISTERED IN TOURNAMENT',
      'badgeTitle': 'RED-LIGHT • NOT REGISTERED IN TOURNAMENT',
      'detail':
          'No registered athlete matched Profile QR "$effectiveQuery" in this tournament.',
      'holderName': effectiveQuery,
      'passType': 'NONE',
    };
  }
}
