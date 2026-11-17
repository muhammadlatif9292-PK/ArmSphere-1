import 'dart:math' as math;
import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/crystal_toast.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/status_chip.dart';

/// Card 3 — Matchups & Brackets Screen (Operator Tournament Hub)
///
/// Implements:
/// 1. Manual Pairing, Smart "Random Matchups" (by Elo, PRs, and Max Lift), and
///    Odd-Numbered "BYE (Auto-Advance to Next Round)" handling + full manual edit/swap.
/// 2. Context-Aware Filter Bars (NO Superfights vs. Elimination filter since locked in Card 1):
///    - Weight Category Filters (70kg Right, 70kg Left, 80kg Right, etc.)
///    - Pairing Status Filters ("Matched Up" vs. "Non-Matched Up")
///    - Completion Status Filters (inside Matched Up: "Pending", "Done", "All")
///    - Elimination Round Filters (ONLY shown for Elimination formats; hidden for Superfights):
///      "First Round / First Matchups", "Second Round Matches", ..., up to "Final"
///    - Table Filters (ONLY shown when No. of Tables > 1): "Table 1", "Table 2", etc.
/// 3. Matchup Card UI (Left-vs-Right athlete layout with Name, Elo, PR/Max Lift badge, Table badge):
///    - Superfights: Compact result badge showing Elo point transfer (+N ELO <- -N ELO),
///      "Winner" highlighted on winner side, "Loss" on loser side, or "Pending".
///    - Elimination: Loss Counter Badges ("0L", "1L", "2L", "3L", "Eliminated") and
///      automatic survivor advancement into next round matchups up to the "Final".
/// 4. Round Locking & Operator "Next Round Matchups & Cancel Any Left Pending" Override.
/// 5. Multi-Table Display & Manual Table Reassignment (when Tables > 1) +
///    Dynamic Free-Table Queue & Absent Players Rule ("Skip for Now / Play Next Matchup").
/// 6. Automatic Category Winners / Podium Summary Card (1st, 2nd, 3rd Place) &
///    Overall Tournament Winners Summary connected directly to Card 1 Awards & Prizes.
class Card3MatchupsBracketsView extends StatefulWidget {
  final Map<String, dynamic> tournament;
  final List<Map<String, String>> separatedDivisions;
  final List<Map<String, dynamic>> appliedAthletes;
  final String autoSaveBannerText;
  final Future<void> Function({
    required Map<String, dynamic> updatedMatchupsState,
    required List<Map<String, dynamic>> updatedAthletes,
    required String actionType,
    required Map<String, dynamic> syncPayload,
    required String bannerMessage,
  }) onCommitMatchupsAction;
  final VoidCallback onBackToHub;

  const Card3MatchupsBracketsView({
    super.key,
    required this.tournament,
    required this.separatedDivisions,
    required this.appliedAthletes,
    required this.autoSaveBannerText,
    required this.onCommitMatchupsAction,
    required this.onBackToHub,
  });

  @override
  State<Card3MatchupsBracketsView> createState() =>
      _Card3MatchupsBracketsViewState();
}

class _Card3MatchupsBracketsViewState extends State<Card3MatchupsBracketsView> {
  late String _selectedCategory;
  String _pairingFilter = 'MATCHED_UP'; // 'MATCHED_UP' | 'NON_MATCHED_UP'
  String _completionFilter = 'ALL'; // 'ALL' | 'PENDING' | 'DONE'
  int _selectedRound = 1;
  String _selectedTableFilter = 'ALL'; // 'ALL' | 'Table 1' | 'Table 2' ...
  String _byeAssignmentPolicy = 'HIGHEST_ELO_PR'; // 'HIGHEST_ELO_PR' | 'RANDOM'

  late Map<String, dynamic> _matchupsState;
  late List<Map<String, dynamic>> _athletes;

  @override
  void initState() {
    super.initState();
    _athletes = _normalizeAthletesWithPrAndMaxLift(widget.appliedAthletes);
    final categories = _availableCategoryLabels();
    _selectedCategory =
        categories.isNotEmpty ? categories.first : '70 kg • Right Arm';

    final rawState = widget.tournament['card3MatchupsState'];
    _matchupsState = rawState is Map
        ? Map<String, dynamic>.from(rawState)
        : <String, dynamic>{
            'matchesByCategory': <String, dynamic>{},
            'unlockedRoundsByCategory': <String, dynamic>{},
            'lastFreedTable': null,
            'lastAutoAssignedSummary': null,
          };

    _ensureInitialMatchupsSeededForCategories(categories);
    _synchronizeDynamicFreeTableActiveSlots(_selectedCategory);
  }

  @override
  void didUpdateWidget(covariant Card3MatchupsBracketsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tournament['card3MatchupsState'] is Map) {
      _matchupsState = Map<String, dynamic>.from(
        widget.tournament['card3MatchupsState'] as Map,
      );
    }
    _athletes = _normalizeAthletesWithPrAndMaxLift(widget.appliedAthletes);
  }

  bool get _isSuperfights {
    final fmt = (widget.tournament['formatCategory'] ?? 'ELIMINATION')
        .toString()
        .toUpperCase();
    return fmt == 'SUPERFIGHTS';
  }

  String get _eliminationSubFormat {
    return (widget.tournament['eliminationSubFormat'] ?? 'DOUBLE_ELIMINATION')
        .toString()
        .toUpperCase();
  }

  int get _maxLossesBeforeElimination {
    if (_isSuperfights) return 999;
    switch (_eliminationSubFormat) {
      case 'SINGLE_ELIMINATION':
        return 1;
      case 'DOUBLE_ELIMINATION':
        return 2;
      case 'THREE_LOSS_ELIMINATION':
        return 3;
      case 'LAST_ONE_STANDING':
        return 1;
      default:
        return 2;
    }
  }

  int get _tableCount {
    return ((widget.tournament['tableCount'] as num?)?.toInt() ?? 1)
        .clamp(1, 12);
  }

  String get _tableAssignmentMode {
    final raw = (widget.tournament['tableAssignmentMode'] ?? '')
        .toString()
        .toUpperCase();
    if (raw.isEmpty) {
      return _tableCount > 1 ? 'DYNAMIC_FREE_TABLE_QUEUE' : 'SINGLE_TABLE_DEFAULT';
    }
    return raw;
  }

  bool get _isDynamicFreeTableMode {
    if (_tableCount <= 1) return false;
    return _tableAssignmentMode == 'DYNAMIC_FREE_TABLE_QUEUE' ||
        _tableAssignmentMode == 'DYNAMIC_FREE_TABLE' ||
        _matchupsState['forceDynamicFreeTableQueue'] == true;
  }

  List<String> get _tableNames {
    final tables = (widget.tournament['tables'] as List?) ?? const [];
    final names = <String>[];
    for (int i = 1; i <= _tableCount; i++) {
      final found = tables
          .whereType<Map>()
          .where((t) => t['tableNumber'] == i)
          .firstOrNull;
      names.add(found?['tableName']?.toString() ?? 'Table $i');
    }
    return names;
  }

  Map<String, dynamic> get _awardsConfig {
    final raw = widget.tournament['awardsConfig'];
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return <String, dynamic>{
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
  }

  String _formatPrizeForPosition(int position) {
    final cfg = _awardsConfig;
    final rewardType = (cfg['rewardType'] ?? 'CASH_PKR').toString().toUpperCase();
    final rawTiers = (cfg['tiers'] as List?) ?? const [];
    final tier = rawTiers
        .whereType<Map>()
        .where((t) => ((t['position'] as num?)?.toInt() ?? 0) == position)
        .firstOrNull;

    final cashPkr = (tier?['cashAmountPkr'] as num?)?.toInt() ??
        (position == 1 ? 25000 : (position == 2 ? 15000 : 7500));
    final awardTitle = (tier?['awardTitle'] ??
            (position == 1
                ? 'Gold Medal & Champion Trophy'
                : (position == 2 ? 'Silver Medal' : 'Bronze Medal')))
        .toString();

    if (rewardType == 'CASH_PKR') {
      return 'PKR $cashPkr';
    } else if (rewardType == 'AWARDS') {
      return awardTitle;
    } else {
      return 'PKR $cashPkr + $awardTitle';
    }
  }

  List<Map<String, dynamic>> _normalizeAthletesWithPrAndMaxLift(
    List<Map<String, dynamic>> source,
  ) {
    return source.map((a) {
      final elo = (a['eloRating'] as num?)?.toInt() ?? 1550;
      final existingPr = (a['prKg'] as num?)?.toDouble();
      final existingMaxLift = (a['maxLiftKg'] as num?)?.toDouble();
      final derivedPr =
          existingPr ?? double.parse(((elo - 1100) * 0.085).toStringAsFixed(1));
      final derivedMax = existingMaxLift ??
          double.parse((derivedPr * 1.12).toStringAsFixed(1));
      return <String, dynamic>{
        ...a,
        'eloRating': elo,
        'prKg': derivedPr,
        'maxLiftKg': derivedMax,
        'lossesCount': (a['lossesCount'] as num?)?.toInt() ?? 0,
      };
    }).toList();
  }

  List<String> _availableCategoryLabels() {
    final labels = <String>[];
    for (final d in widget.separatedDivisions) {
      final l = (d['label'] ?? '').trim();
      if (l.isNotEmpty && !labels.contains(l)) {
        labels.add(l);
      }
    }
    for (final a in _athletes) {
      final l = (a['categoryLabel'] ?? '').toString().trim();
      if (l.isNotEmpty && !labels.contains(l)) {
        labels.add(l);
      }
    }
    if (labels.isEmpty) {
      labels.addAll(const [
        '70 kg • Right Arm',
        '70 kg • Left Arm',
        '80 kg • Right Arm',
      ]);
    }
    return labels;
  }

  List<Map<String, dynamic>> _athletesInCategory(String categoryLabel) {
    return _athletes
        .where((a) =>
            (a['categoryLabel'] ?? '').toString().trim() == categoryLabel &&
            a['weighInStatus'] != 'UNMATCHED_OUT')
        .toList();
  }

  double _compositeSmartScore(Map<String, dynamic> athlete) {
    final elo = (athlete['eloRating'] as num?)?.toDouble() ?? 1500.0;
    final pr = (athlete['prKg'] as num?)?.toDouble() ?? 55.0;
    final maxLift = (athlete['maxLiftKg'] as num?)?.toDouble() ?? 62.0;
    return elo + (pr * 4.5) + (maxLift * 3.5);
  }

  String _pickTableForMatch(String categoryLabel, int matchIdx) {
    final names = _tableNames;
    if (names.isEmpty) return 'Table 1';
    if (names.length == 1) return names.first;

    final mode = _tableAssignmentMode;
    final tables = (widget.tournament['tables'] as List?) ?? const [];
    if (mode == 'CATEGORY_BY_TABLE') {
      for (final raw in tables) {
        if (raw is! Map) continue;
        final assigned = (raw['assignedCategoryDivisionIds'] as List?) ?? const [];
        for (final div in widget.separatedDivisions) {
          if (div['label'] == categoryLabel &&
              assigned.contains(div['divisionId'])) {
            return raw['tableName']?.toString() ?? 'Table 1';
          }
        }
      }
    }
    return names[matchIdx % names.length];
  }

  List<Map<String, dynamic>> _getMatchesForCategory(String categoryLabel) {
    final map = (_matchupsState['matchesByCategory'] is Map)
        ? Map<String, dynamic>.from(_matchupsState['matchesByCategory'] as Map)
        : <String, dynamic>{};
    final rawList = map[categoryLabel];
    if (rawList is List) {
      return rawList
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  void _setMatchesForCategory(
    String categoryLabel,
    List<Map<String, dynamic>> matches,
  ) {
    final byCat = (_matchupsState['matchesByCategory'] is Map)
        ? Map<String, dynamic>.from(_matchupsState['matchesByCategory'] as Map)
        : <String, dynamic>{};
    byCat[categoryLabel] = matches;
    _matchupsState = <String, dynamic>{
      ..._matchupsState,
      'matchesByCategory': byCat,
    };
  }

  bool _isRoundUnlockedByOverride(String categoryLabel, int roundNumber) {
    if (roundNumber <= 1) return true;
    final unlockedMap = (_matchupsState['unlockedRoundsByCategory'] is Map)
        ? Map<String, dynamic>.from(
            _matchupsState['unlockedRoundsByCategory'] as Map)
        : <String, dynamic>{};
    final list = unlockedMap[categoryLabel];
    if (list is List) {
      return list.map((e) => (e as num).toInt()).contains(roundNumber);
    }
    return false;
  }

  void _markRoundUnlockedByOverride(String categoryLabel, int roundNumber) {
    final unlockedMap = (_matchupsState['unlockedRoundsByCategory'] is Map)
        ? Map<String, dynamic>.from(
            _matchupsState['unlockedRoundsByCategory'] as Map)
        : <String, dynamic>{};
    final existing = (unlockedMap[categoryLabel] is List)
        ? (unlockedMap[categoryLabel] as List)
            .map((e) => (e as num).toInt())
            .toSet()
        : <int>{1};
    existing.add(roundNumber);
    unlockedMap[categoryLabel] = existing.toList();
    _matchupsState = <String, dynamic>{
      ..._matchupsState,
      'unlockedRoundsByCategory': unlockedMap,
    };
  }

  /// Dynamically calculates the Elimination Round Tabs for a category based on player count.
  List<Map<String, dynamic>> _buildDynamicRoundTabs(String categoryLabel) {
    if (_isSuperfights) {
      return const [
        {'round': 1, 'label': 'Superfight Bouts'},
      ];
    }
    final count = math.max(2, _athletesInCategory(categoryLabel).length);
    final baseRounds = (math.log(count) / math.ln2).ceil().clamp(2, 6);
    final extraRounds = _maxLossesBeforeElimination > 1 ? 1 : 0;
    final totalRounds = (baseRounds + extraRounds).clamp(2, 6);

    final existingMatches = _getMatchesForCategory(categoryLabel);
    int highestExistingRound = 1;
    for (final m in existingMatches) {
      final r = (m['roundNumber'] as num?)?.toInt() ?? 1;
      if (r > highestExistingRound) highestExistingRound = r;
    }
    final finalRoundCount = math.max(totalRounds, highestExistingRound);

    final tabs = <Map<String, dynamic>>[];
    for (int r = 1; r <= finalRoundCount; r++) {
      String label;
      if (r == 1) {
        label = 'First Round / First Matchups';
      } else if (r == finalRoundCount) {
        label = 'Final';
      } else if (r == finalRoundCount - 1 && finalRoundCount >= 3) {
        label = 'Semi-Final (Round $r)';
      } else if (r == 2) {
        label = 'Second Round Matches';
      } else if (r == 3) {
        label = 'Third Round Matches';
      } else {
        label = 'Round $r Matches';
      }
      tabs.add({'round': r, 'label': label});
    }
    return tabs;
  }

  void _ensureInitialMatchupsSeededForCategories(List<String> categories) {
    for (final cat in categories) {
      final existing = _getMatchesForCategory(cat);
      if (existing.isEmpty) {
        final built = _generateSmartRandomMatchupsList(
          categoryLabel: cat,
          roundNumber: 1,
          candidates: _athletesInCategory(cat),
        );
        _setMatchesForCategory(cat, built);
      }
    }
  }

  /// Ensures each available table in Dynamic Free-Table mode has at most 1 active
  /// on-table match in the current round, while remaining pending matches are queued in order.
  void _synchronizeDynamicFreeTableActiveSlots(String categoryLabel) {
    if (_tableCount <= 1) return;
    final allMatches = _getMatchesForCategory(categoryLabel);
    if (allMatches.isEmpty) return;

    final busyTables = <String>{};
    final updated = <Map<String, dynamic>>[];

    // Sort by roundNumber, then queueOrderRank (or matchIndex)
    final sorted = List<Map<String, dynamic>>.from(allMatches)
      ..sort((a, b) {
        final rA = (a['roundNumber'] as num?)?.toInt() ?? 1;
        final rB = (b['roundNumber'] as num?)?.toInt() ?? 1;
        if (rA != rB) return rA.compareTo(rB);
        final qA = (a['queueOrderRank'] as num?)?.toInt() ??
            ((a['matchIndex'] as num?)?.toInt() ?? 1) * 10;
        final qB = (b['queueOrderRank'] as num?)?.toInt() ??
            ((b['matchIndex'] as num?)?.toInt() ?? 1) * 10;
        return qA.compareTo(qB);
      });

    for (final m in sorted) {
      final st = (m['status'] ?? 'PENDING').toString().toUpperCase();
      final isBye = m['isBye'] == true;
      final r = (m['roundNumber'] as num?)?.toInt() ?? 1;
      final tName = (m['assignedTable'] ?? _tableNames.first).toString();
      if (st == 'PENDING' && !isBye && r == _selectedRound) {
        if (!busyTables.contains(tName)) {
          busyTables.add(tName);
          updated.add({
            ...m,
            'tableQueueStatus': 'ACTIVE_AT_TABLE',
          });
        } else {
          updated.add({
            ...m,
            'tableQueueStatus':
                m['tableQueueStatus'] == 'DEFERRED_PLAYS_NEXT'
                    ? 'DEFERRED_PLAYS_NEXT'
                    : 'QUEUED_FOR_FREE_TABLE',
          });
        }
      } else {
        updated.add({
          ...m,
          'tableQueueStatus': st == 'DONE' ? 'COMPLETED_TABLE_FREED' : 'INACTIVE',
        });
      }
    }

    _setMatchesForCategory(categoryLabel, updated);
  }

  /// Builds smart matchups ordered by composite Elo + PR + Max Lift,
  /// and handles odd numbers of athletes with a clean "BYE (Auto-Advance to Next Round)".
  List<Map<String, dynamic>> _generateSmartRandomMatchupsList({
    required String categoryLabel,
    required int roundNumber,
    required List<Map<String, dynamic>> candidates,
    String? forcedByeAthleteId,
  }) {
    if (candidates.isEmpty) return <Map<String, dynamic>>[];

    final sorted = List<Map<String, dynamic>>.from(candidates)
      ..sort((a, b) =>
          _compositeSmartScore(b).compareTo(_compositeSmartScore(a)));

    Map<String, dynamic>? byeAthlete;
    final pool = List<Map<String, dynamic>>.from(sorted);

    // Odd Number of Athletes ("BYE" Auto-Advance Rule)
    if (pool.length % 2 == 1) {
      if (forcedByeAthleteId != null) {
        final idx =
            pool.indexWhere((a) => a['id']?.toString() == forcedByeAthleteId);
        if (idx != -1) {
          byeAthlete = pool.removeAt(idx);
        }
      }
      if (byeAthlete == null) {
        if (_byeAssignmentPolicy == 'RANDOM') {
          final rndIdx = DateTime.now().millisecondsSinceEpoch % pool.length;
          byeAthlete = pool.removeAt(rndIdx);
        } else {
          // Highest Elo / PR / Max Lift receives automatic BYE
          byeAthlete = pool.removeAt(0);
        }
      }
    }

    final result = <Map<String, dynamic>>[];
    int matchIndex = 1;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    for (int i = 0; i + 1 < pool.length; i += 2) {
      final a = pool[i];
      final b = pool[i + 1];
      final table = _pickTableForMatch(categoryLabel, matchIndex - 1);
      final isInitialOnTable = matchIndex <= _tableCount;
      result.add({
        'id': 'm_${categoryLabel.hashCode.abs()}_r${roundNumber}_${matchIndex}_$nowMs',
        'categoryLabel': categoryLabel,
        'roundNumber': roundNumber,
        'matchIndex': matchIndex,
        'queueOrderRank': matchIndex * 10,
        'isBye': false,
        'athleteAId': a['id'].toString(),
        'athleteAName': a['athleteName'].toString(),
        'athleteAElo': (a['eloRating'] as num?)?.toInt() ?? 1500,
        'athleteAPrKg': (a['prKg'] as num?)?.toDouble() ?? 55.0,
        'athleteAMaxLiftKg': (a['maxLiftKg'] as num?)?.toDouble() ?? 62.0,
        'athleteALosses': (a['lossesCount'] as num?)?.toInt() ?? 0,
        'athleteBId': b['id'].toString(),
        'athleteBName': b['athleteName'].toString(),
        'athleteBElo': (b['eloRating'] as num?)?.toInt() ?? 1500,
        'athleteBPrKg': (b['prKg'] as num?)?.toDouble() ?? 55.0,
        'athleteBMaxLiftKg': (b['maxLiftKg'] as num?)?.toDouble() ?? 62.0,
        'athleteBLosses': (b['lossesCount'] as num?)?.toInt() ?? 0,
        'assignedTable': table,
        'tableQueueStatus':
            isInitialOnTable ? 'ACTIVE_AT_TABLE' : 'QUEUED_FOR_FREE_TABLE',
        'absentSkippedCount': 0,
        'deferredNote': null,
        'status': 'PENDING', // 'PENDING' | 'DONE' | 'CANCELLED_PENDING'
        'winnerId': null,
        'loserId': null,
        'eloTransferDelta': null,
        'scoreLine': null,
      });
      matchIndex++;
    }

    if (byeAthlete != null) {
      final table = _pickTableForMatch(categoryLabel, matchIndex - 1);
      result.add({
        'id':
            'm_bye_${categoryLabel.hashCode.abs()}_r${roundNumber}_${matchIndex}_$nowMs',
        'categoryLabel': categoryLabel,
        'roundNumber': roundNumber,
        'matchIndex': matchIndex,
        'queueOrderRank': matchIndex * 10,
        'isBye': true,
        'athleteAId': byeAthlete['id'].toString(),
        'athleteAName': byeAthlete['athleteName'].toString(),
        'athleteAElo': (byeAthlete['eloRating'] as num?)?.toInt() ?? 1500,
        'athleteAPrKg': (byeAthlete['prKg'] as num?)?.toDouble() ?? 55.0,
        'athleteAMaxLiftKg':
            (byeAthlete['maxLiftKg'] as num?)?.toDouble() ?? 62.0,
        'athleteALosses': (byeAthlete['lossesCount'] as num?)?.toInt() ?? 0,
        'athleteBId': 'BYE',
        'athleteBName': 'BYE (Auto-Advance to Next Round)',
        'athleteBElo': 0,
        'athleteBPrKg': 0.0,
        'athleteBMaxLiftKg': 0.0,
        'athleteBLosses': 0,
        'assignedTable': table,
        'tableQueueStatus': 'COMPLETED_TABLE_FREED',
        'absentSkippedCount': 0,
        'deferredNote': null,
        'status': 'DONE', // BYE automatically advances
        'winnerId': byeAthlete['id'].toString(),
        'loserId': null,
        'eloTransferDelta': 0,
        'scoreLine': 'BYE • AUTO-ADVANCE',
      });
    }

    return result;
  }

  /// Dynamically rebuilds the next round (`roundNumber + 1`) preview/live matchups
  /// whenever results are submitted in `roundNumber` (for Elimination tournaments).
  void _rebuildNextRoundFromSubmittedResults(
    String categoryLabel,
    int completedRound,
  ) {
    if (_isSuperfights) return;
    final allMatches = _getMatchesForCategory(categoryLabel);
    final currentRoundMatches = allMatches
        .where(
            (m) => ((m['roundNumber'] as num?)?.toInt() ?? 1) == completedRound)
        .toList();

    if (currentRoundMatches.isEmpty) return;

    // Collect athletes whose matches in `completedRound` are already DONE
    // and who have not reached the elimination loss threshold.
    final advancingAthleteIds = <String>{};
    for (final m in currentRoundMatches) {
      final st = (m['status'] ?? 'PENDING').toString().toUpperCase();
      if (st != 'DONE') continue;

      if (m['isBye'] == true) {
        final aId = m['athleteAId']?.toString() ?? '';
        if (aId.isNotEmpty) advancingAthleteIds.add(aId);
        continue;
      }

      final aId = m['athleteAId']?.toString() ?? '';
      final bId = m['athleteBId']?.toString() ?? '';
      final aAthlete =
          _athletes.where((x) => x['id']?.toString() == aId).firstOrNull;
      final bAthlete =
          _athletes.where((x) => x['id']?.toString() == bId).firstOrNull;

      final aLosses = (aAthlete?['lossesCount'] as num?)?.toInt() ?? 0;
      final bLosses = (bAthlete?['lossesCount'] as num?)?.toInt() ?? 0;

      if (aId.isNotEmpty && aLosses < _maxLossesBeforeElimination) {
        advancingAthleteIds.add(aId);
      }
      if (bId.isNotEmpty && bLosses < _maxLossesBeforeElimination) {
        advancingAthleteIds.add(bId);
      }
    }

    final advancingAthletes = _athletesInCategory(categoryLabel)
        .where((a) => advancingAthleteIds.contains(a['id']?.toString()))
        .toList();

    final nextRound = completedRound + 1;
    final otherRoundsMatches = allMatches
        .where((m) => ((m['roundNumber'] as num?)?.toInt() ?? 1) != nextRound)
        .toList();

    if (advancingAthletes.length >= 2) {
      final nextRoundBuilt = _generateSmartRandomMatchupsList(
        categoryLabel: categoryLabel,
        roundNumber: nextRound,
        candidates: advancingAthletes,
      );
      _setMatchesForCategory(categoryLabel, [
        ...otherRoundsMatches,
        ...nextRoundBuilt,
      ]);
    } else {
      _setMatchesForCategory(categoryLabel, otherRoundsMatches);
    }
  }

  /// Checks whether submitting results in `roundNumber` is currently allowed.
  bool _canSubmitResultsInRound(String categoryLabel, int roundNumber) {
    if (roundNumber <= 1 || _isSuperfights) return true;
    if (_isRoundUnlockedByOverride(categoryLabel, roundNumber)) return true;

    final allMatches = _getMatchesForCategory(categoryLabel);
    final prevRoundMatches = allMatches
        .where(
            (m) => ((m['roundNumber'] as num?)?.toInt() ?? 1) == roundNumber - 1)
        .toList();
    if (prevRoundMatches.isEmpty) return false;
    return prevRoundMatches.every((m) {
      final st = (m['status'] ?? 'PENDING').toString().toUpperCase();
      return st == 'DONE' || st == 'CANCELLED_PENDING';
    });
  }

  /// MULTI-TABLE MANUAL REASSIGNMENT:
  /// Allows the operator to manually select and change any matchup from one table to another
  /// at any time with instant optimistic UI update and background sync.
  Future<void> _reassignMatchupTable(
    Map<String, dynamic> match,
    String newTable,
  ) async {
    final previousTable = (match['assignedTable'] ?? 'Table 1').toString();
    if (previousTable == newTable) return;

    HapticFeedback.selectionClick();
    final matchId = match['id'].toString();
    final updated = _getMatchesForCategory(_selectedCategory).map((m) {
      if (m['id'].toString() != matchId) return m;
      return <String, dynamic>{
        ...m,
        'assignedTable': newTable,
        'tableQueueStatus': 'ACTIVE_AT_TABLE',
      };
    }).toList();

    setState(() {
      _setMatchesForCategory(_selectedCategory, updated);
      _synchronizeDynamicFreeTableActiveSlots(_selectedCategory);
    });

    await widget.onCommitMatchupsAction(
      updatedMatchupsState: _matchupsState,
      updatedAthletes: _athletes,
      actionType: 'REASSIGN_MATCHUP_TABLE',
      syncPayload: {
        'eventId': widget.tournament['id'],
        'categoryLabel': _selectedCategory,
        'matchId': matchId,
        'previousTable': previousTable,
        'assignedTable': newTable,
      },
      bannerMessage:
          'Saved / Done • Match #${match['matchIndex']} Moved from $previousTable → $newTable',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      CrystalSnackBar(
        content: Text(
          'Saved / Done: Match #${match['matchIndex']} (${match['athleteAName']} vs. ${match['athleteBName']}) reassigned to $newTable.',
        ),
        backgroundColor: AppTheme.cyan,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// DYNAMIC FREE-TABLE QUEUE — ABSENT / NOT PRESENT PLAYERS HANDLING:
  /// "Skip for Now / Play Next Matchup"
  /// Immediately promotes the next ready pending matchup onto `freedOrCurrentTable`
  /// while keeping the absent matchup queued right behind it so it plays right after them.
  Future<void> _handleSkipAbsentAndPlayNextMatchup(
    Map<String, dynamic> absentMatch,
  ) async {
    HapticFeedback.heavyImpact();
    final roundNumber = (absentMatch['roundNumber'] as num?)?.toInt() ?? 1;
    final tableName = (absentMatch['assignedTable'] ?? _tableNames.first).toString();
    final absentMatchId = absentMatch['id'].toString();

    final allMatches = _getMatchesForCategory(_selectedCategory);
    final pendingCandidates = allMatches
        .where((m) =>
            ((m['roundNumber'] as num?)?.toInt() ?? 1) == roundNumber &&
            m['isBye'] != true &&
            (m['status'] ?? 'PENDING').toString().toUpperCase() == 'PENDING' &&
            m['id'].toString() != absentMatchId)
        .toList()
      ..sort((a, b) {
        final qA = (a['queueOrderRank'] as num?)?.toInt() ??
            ((a['matchIndex'] as num?)?.toInt() ?? 1) * 10;
        final qB = (b['queueOrderRank'] as num?)?.toInt() ??
            ((b['matchIndex'] as num?)?.toInt() ?? 1) * 10;
        return qA.compareTo(qB);
      });

    if (pendingCandidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        CrystalSnackBar(
          content: const Text(
            'No other pending matchups are waiting in this round queue to step up.',
          ),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final promotedMatch = pendingCandidates.first;
    final promotedId = promotedMatch['id'].toString();
    final promotedRank = (promotedMatch['queueOrderRank'] as num?)?.toInt() ??
        ((promotedMatch['matchIndex'] as num?)?.toInt() ?? 1) * 10;

    // Place the promoted match first on `tableName`, and queue the absent match right after it!
    final updatedMatches = allMatches.map((m) {
      final id = m['id'].toString();
      if (id == promotedId) {
        return <String, dynamic>{
          ...m,
          'assignedTable': tableName,
          'queueOrderRank': promotedRank - 5,
          'tableQueueStatus': 'ACTIVE_AT_TABLE',
          'deferredNote':
              'Stepped up onto $tableName (replacing absent Match #${absentMatch['matchIndex']})',
        };
      }
      if (id == absentMatchId) {
        final prevSkips = (m['absentSkippedCount'] as num?)?.toInt() ?? 0;
        return <String, dynamic>{
          ...m,
          'assignedTable': tableName,
          'queueOrderRank': promotedRank + 1,
          'tableQueueStatus': 'DEFERRED_PLAYS_NEXT',
          'absentSkippedCount': prevSkips + 1,
          'deferredNote':
              'Skipped for now (Athletes Absent) • Queued to play right after Match #${promotedMatch['matchIndex']} on $tableName',
        };
      }
      return m;
    }).toList();

    _matchupsState['lastFreedTable'] = tableName;
    _matchupsState['lastAutoAssignedSummary'] =
        'Absent Match #${absentMatch['matchIndex']} skipped for now → Promoted Match #${promotedMatch['matchIndex']} (${promotedMatch['athleteAName']} vs. ${promotedMatch['athleteBName']}) onto $tableName. Match #${absentMatch['matchIndex']} stays queued right after!';

    setState(() {
      _setMatchesForCategory(_selectedCategory, updatedMatches);
      _synchronizeDynamicFreeTableActiveSlots(_selectedCategory);
    });

    await widget.onCommitMatchupsAction(
      updatedMatchupsState: _matchupsState,
      updatedAthletes: _athletes,
      actionType: 'SKIP_ABSENT_MATCHUP_PLAY_NEXT',
      syncPayload: {
        'eventId': widget.tournament['id'],
        'categoryLabel': _selectedCategory,
        'roundNumber': roundNumber,
        'tableName': tableName,
        'skippedMatchId': absentMatchId,
        'promotedMatchId': promotedId,
      },
      bannerMessage:
          'Saved / Done • $tableName: Match #${promotedMatch['matchIndex']} Stepped Up • Absent Match #${absentMatch['matchIndex']} Queued Right After',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      CrystalSnackBar(
        content: Text(
          'Saved / Done: Match #${promotedMatch['matchIndex']} (${promotedMatch['athleteAName']} vs. ${promotedMatch['athleteBName']}) is now playing on $tableName. Absent Match #${absentMatch['matchIndex']} is queued right after them!',
        ),
        backgroundColor: AppTheme.goldPrimary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleSmartRandomMatchupsForCurrentRound() async {
    HapticFeedback.heavyImpact();
    final allMatches = _getMatchesForCategory(_selectedCategory);
    final otherRounds = allMatches
        .where(
            (m) => ((m['roundNumber'] as num?)?.toInt() ?? 1) != _selectedRound)
        .toList();

    List<Map<String, dynamic>> eligible = _athletesInCategory(_selectedCategory);
    if (!_isSuperfights && _selectedRound > 1) {
      eligible = eligible
          .where((a) =>
              ((a['lossesCount'] as num?)?.toInt() ?? 0) <
              _maxLossesBeforeElimination)
          .toList();
    }

    final generated = _generateSmartRandomMatchupsList(
      categoryLabel: _selectedCategory,
      roundNumber: _selectedRound,
      candidates: eligible,
    );

    setState(() {
      _setMatchesForCategory(_selectedCategory, [...otherRounds, ...generated]);
      _synchronizeDynamicFreeTableActiveSlots(_selectedCategory);
      _pairingFilter = 'MATCHED_UP';
    });

    await widget.onCommitMatchupsAction(
      updatedMatchupsState: _matchupsState,
      updatedAthletes: _athletes,
      actionType: 'CREATE_CATEGORY_MATCHUPS',
      syncPayload: {
        'eventId': widget.tournament['id'],
        'categoryLabel': _selectedCategory,
        'roundNumber': _selectedRound,
        'matchCount': generated.length,
        'mode': 'SMART_RANDOM_ELO_PR_MAXLIFT',
      },
      bannerMessage:
          'Saved / Done • Smart Random Matchups Built for $_selectedCategory (Round $_selectedRound)',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      CrystalSnackBar(
        content: Text(
          'Saved / Done: Created ${generated.length} smart matchups for $_selectedCategory by Elo, PRs & Max Lift.',
        ),
        backgroundColor: AppTheme.emerald,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Operator Override: "Next Round Matchups (and Cancel Any Left Pending)"
  Future<void> _handleNextRoundAndCancelPendingOverride() async {
    HapticFeedback.heavyImpact();
    final currentRound = _selectedRound;
    final nextRound = currentRound + 1;
    final allMatches = _getMatchesForCategory(_selectedCategory);

    int cancelledCount = 0;
    final updatedMatches = allMatches.map((m) {
      final r = (m['roundNumber'] as num?)?.toInt() ?? 1;
      final st = (m['status'] ?? 'PENDING').toString().toUpperCase();
      if (r == currentRound && st == 'PENDING') {
        cancelledCount++;
        return <String, dynamic>{
          ...m,
          'status': 'CANCELLED_PENDING',
          'tableQueueStatus': 'INACTIVE',
          'scoreLine': 'CANCELLED BY OPERATOR OVERRIDE',
        };
      }
      return m;
    }).toList();

    setState(() {
      _setMatchesForCategory(_selectedCategory, updatedMatches);
      _markRoundUnlockedByOverride(_selectedCategory, nextRound);
      _rebuildNextRoundFromSubmittedResults(_selectedCategory, currentRound);
      _selectedRound = nextRound;
      _synchronizeDynamicFreeTableActiveSlots(_selectedCategory);
      _completionFilter = 'ALL';
      _pairingFilter = 'MATCHED_UP';
    });

    await widget.onCommitMatchupsAction(
      updatedMatchupsState: _matchupsState,
      updatedAthletes: _athletes,
      actionType: 'ADVANCE_ROUND_OVERRIDE',
      syncPayload: {
        'eventId': widget.tournament['id'],
        'categoryLabel': _selectedCategory,
        'fromRound': currentRound,
        'toRound': nextRound,
        'cancelledPendingCount': cancelledCount,
      },
      bannerMessage:
          'Saved / Done • Round $nextRound Unlocked & $cancelledCount Pending Cancelled',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      CrystalSnackBar(
        content: Text(
          'Saved / Done: Round $nextRound is now active ($cancelledCount pending match(es) cancelled). Next round matchups are unlocked for submission.',
        ),
        backgroundColor: AppTheme.goldPrimary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Submits a match result (Referee / Operator submission) with optimistic UI + offline sync.
  /// Also implements the DYNAMIC FREE-TABLE QUEUE rule:
  /// As soon as a match is finished and submitted, marks that table as Freed and automatically
  /// assigns the next queued matchup to that freed table!
  Future<void> _submitMatchWinner({
    required Map<String, dynamic> match,
    required String winnerId,
    String scoreLine = '3-1',
  }) async {
    final roundNumber = (match['roundNumber'] as num?)?.toInt() ?? 1;
    if (!_canSubmitResultsInRound(_selectedCategory, roundNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        CrystalSnackBar(
          content: Text(
            'Round $roundNumber results are locked until Round ${roundNumber - 1} matches are Done, OR tap "Next Round Matchups & Cancel Any Left Pending" to unlock now.',
          ),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    HapticFeedback.heavyImpact();
    final matchId = match['id'].toString();
    final freedTable = (match['assignedTable'] ?? _tableNames.first).toString();
    final aId = match['athleteAId'].toString();
    final bId = match['athleteBId'].toString();
    final loserId = (winnerId == aId) ? bId : aId;

    final aElo = (match['athleteAElo'] as num?)?.toInt() ?? 1500;
    final bElo = (match['athleteBElo'] as num?)?.toInt() ?? 1500;
    final winnerElo = (winnerId == aId) ? aElo : bElo;
    final loserElo = (winnerId == aId) ? bElo : aElo;

    // Calculate Elo point transfer delta (standard K=32 Elo formula)
    final expectedWin =
        1.0 / (1.0 + math.pow(10.0, (loserElo - winnerElo) / 400.0));
    final eloDelta = (32 * (1.0 - expectedWin)).round().clamp(8, 28);

    // Update athlete Elo and Loss Counter
    _athletes = _athletes.map((a) {
      final id = a['id']?.toString() ?? '';
      if (id == winnerId) {
        return <String, dynamic>{
          ...a,
          'eloRating': ((a['eloRating'] as num?)?.toInt() ?? 1500) + eloDelta,
        };
      }
      if (id == loserId) {
        final prevLosses = (a['lossesCount'] as num?)?.toInt() ?? 0;
        final nextLosses = _isSuperfights ? prevLosses : (prevLosses + 1);
        return <String, dynamic>{
          ...a,
          'eloRating': math.max(
              1000, ((a['eloRating'] as num?)?.toInt() ?? 1500) - eloDelta),
          'lossesCount': nextLosses,
        };
      }
      return a;
    }).toList();

    final updatedAthleteA =
        _athletes.where((x) => x['id']?.toString() == aId).firstOrNull;
    final updatedAthleteB =
        _athletes.where((x) => x['id']?.toString() == bId).firstOrNull;

    var allMatches = _getMatchesForCategory(_selectedCategory).map((m) {
      if (m['id']?.toString() != matchId) return m;
      return <String, dynamic>{
        ...m,
        'status': 'DONE',
        'tableQueueStatus': 'COMPLETED_TABLE_FREED',
        'winnerId': winnerId,
        'loserId': loserId,
        'eloTransferDelta': eloDelta,
        'scoreLine': scoreLine,
        'athleteAElo':
            (updatedAthleteA?['eloRating'] as num?)?.toInt() ?? aElo,
        'athleteBElo':
            (updatedAthleteB?['eloRating'] as num?)?.toInt() ?? bElo,
        'athleteALosses':
            (updatedAthleteA?['lossesCount'] as num?)?.toInt() ?? 0,
        'athleteBLosses':
            (updatedAthleteB?['lossesCount'] as num?)?.toInt() ?? 0,
      };
    }).toList();

    // DYNAMIC FREE-TABLE QUEUE RULE:
    // As soon as this match is finished, mark `freedTable` as Freed and automatically
    // assign the next queued pending matchup to `freedTable`!
    String? autoAssignedQueueNotice;
    if (_tableCount > 1) {
      final queuedPending = allMatches
          .where((m) =>
              ((m['roundNumber'] as num?)?.toInt() ?? 1) == roundNumber &&
              m['isBye'] != true &&
              (m['status'] ?? 'PENDING').toString().toUpperCase() == 'PENDING')
          .toList()
        ..sort((a, b) {
          // Prefer deferred/ready matches in queueOrderRank order
          final qA = (a['queueOrderRank'] as num?)?.toInt() ??
              ((a['matchIndex'] as num?)?.toInt() ?? 1) * 10;
          final qB = (b['queueOrderRank'] as num?)?.toInt() ??
              ((b['matchIndex'] as num?)?.toInt() ?? 1) * 10;
          return qA.compareTo(qB);
        });

      // Pick the first pending matchup that isn't already actively playing on another table,
      // or the next queued matchup waiting for a free table.
      final nextForFreedTable = queuedPending
              .where((m) =>
                  m['tableQueueStatus'] != 'ACTIVE_AT_TABLE' ||
                  m['assignedTable'] == freedTable)
              .firstOrNull ??
          queuedPending.firstOrNull;

      if (nextForFreedTable != null) {
        final nextId = nextForFreedTable['id'].toString();
        allMatches = allMatches.map((m) {
          if (m['id'].toString() != nextId) return m;
          return <String, dynamic>{
            ...m,
            'assignedTable': freedTable,
            'tableQueueStatus': 'ACTIVE_AT_TABLE',
            'deferredNote':
                'Auto-assigned to freed $freedTable after Match #${match['matchIndex']} finished',
          };
        }).toList();
        autoAssignedQueueNotice =
            '$freedTable Freed → Auto-Assigned Next Queued Match #${nextForFreedTable['matchIndex']} (${nextForFreedTable['athleteAName']} vs. ${nextForFreedTable['athleteBName']}) to $freedTable';
        _matchupsState['lastFreedTable'] = freedTable;
        _matchupsState['lastAutoAssignedSummary'] = autoAssignedQueueNotice;
      } else {
        _matchupsState['lastFreedTable'] = freedTable;
        _matchupsState['lastAutoAssignedSummary'] =
            '$freedTable Freed • All queued bouts in Round $roundNumber have been assigned.';
      }
    }

    setState(() {
      _setMatchesForCategory(_selectedCategory, allMatches);
      // Dynamically update next round matchups smoothly as submissions arrive!
      _rebuildNextRoundFromSubmittedResults(_selectedCategory, roundNumber);
      _synchronizeDynamicFreeTableActiveSlots(_selectedCategory);
    });

    final winnerName =
        (winnerId == aId) ? match['athleteAName'] : match['athleteBName'];

    await widget.onCommitMatchupsAction(
      updatedMatchupsState: _matchupsState,
      updatedAthletes: _athletes,
      actionType: 'SUBMIT_REFEREE_MATCH_RESULT',
      syncPayload: {
        'eventId': widget.tournament['id'],
        'matchId': matchId,
        'categoryLabel': _selectedCategory,
        'roundNumber': roundNumber,
        'freedTable': freedTable,
        'autoAssignedQueueNotice': autoAssignedQueueNotice,
        'winnerId': winnerId,
        'loserId': loserId,
        'eloTransferDelta': eloDelta,
        'scoreLine': scoreLine,
      },
      bannerMessage: autoAssignedQueueNotice != null
          ? 'Saved / Sent / Done • $winnerName Won • $autoAssignedQueueNotice'
          : 'Saved / Sent / Done • $winnerName Won (+$eloDelta ELO)',
    );
  }

  // ===========================================================================
  // AUTOMATIC WINNERS / PODIUM SUMMARY (1ST, 2ND, 3RD PLACE & OVERALL WINNERS)
  // ===========================================================================

  /// Determines if the "Final" match of `categoryLabel` is marked `DONE`
  /// (or for Superfights, whether all bouts in `categoryLabel` are `DONE`).
  bool _isCategoryFinalCompleted(String categoryLabel) {
    final allMatches = _getMatchesForCategory(categoryLabel);
    if (allMatches.isEmpty) return false;

    if (_isSuperfights) {
      final nonBye = allMatches.where((m) => m['isBye'] != true).toList();
      return nonBye.isNotEmpty &&
          nonBye.every(
              (m) => (m['status'] ?? 'PENDING').toString().toUpperCase() == 'DONE');
    }

    final roundTabs = _buildDynamicRoundTabs(categoryLabel);
    final finalRoundNumber =
        (roundTabs.last['round'] as num?)?.toInt() ?? roundTabs.length;

    final finalRoundMatches = allMatches
        .where((m) =>
            ((m['roundNumber'] as num?)?.toInt() ?? 1) == finalRoundNumber &&
            m['isBye'] != true)
        .toList();

    if (finalRoundMatches.isNotEmpty &&
        finalRoundMatches.every(
            (m) => (m['status'] ?? 'PENDING').toString().toUpperCase() == 'DONE')) {
      return true;
    }

    // Also check if an explicit Final or Championship match was completed in the highest played round
    // leaving only 1 undefeated/surviving champion in the category.
    final nonByeDone = allMatches
        .where((m) =>
            m['isBye'] != true &&
            (m['status'] ?? 'PENDING').toString().toUpperCase() == 'DONE')
        .toList();
    if (nonByeDone.isEmpty) return false;

    final catAthletes = _athletesInCategory(categoryLabel);
    final surviving = catAthletes
        .where((a) =>
            ((a['lossesCount'] as num?)?.toInt() ?? 0) <
            _maxLossesBeforeElimination)
        .toList();
    return surviving.length == 1 && nonByeDone.length >= 2;
  }

  /// Computes the 1st, 2nd, and 3rd Place Podium for `categoryLabel`, connected
  /// directly to the Awards / Prizes structure configured in Card 1.
  List<Map<String, dynamic>> _computeCategoryPodium(String categoryLabel) {
    final allMatches = _getMatchesForCategory(categoryLabel);
    final catAthletes = _athletesInCategory(categoryLabel);
    if (catAthletes.isEmpty) return const [];

    Map<String, dynamic>? findAthlete(String? id) {
      if (id == null || id.isEmpty) return null;
      return catAthletes.where((a) => a['id']?.toString() == id).firstOrNull ??
          _athletes.where((a) => a['id']?.toString() == id).firstOrNull;
    }

    final doneMatches = allMatches
        .where((m) =>
            m['isBye'] != true &&
            (m['status'] ?? 'PENDING').toString().toUpperCase() == 'DONE')
        .toList()
      ..sort((a, b) {
        final rA = (a['roundNumber'] as num?)?.toInt() ?? 1;
        final rB = (b['roundNumber'] as num?)?.toInt() ?? 1;
        if (rB != rA) return rB.compareTo(rA);
        final iA = (a['matchIndex'] as num?)?.toInt() ?? 1;
        final iB = (b['matchIndex'] as num?)?.toInt() ?? 1;
        return iB.compareTo(iA);
      });

    Map<String, dynamic>? firstPlace;
    Map<String, dynamic>? secondPlace;
    Map<String, dynamic>? thirdPlace;

    if (!_isSuperfights && doneMatches.isNotEmpty) {
      final finalMatch = doneMatches.first;
      firstPlace = findAthlete(finalMatch['winnerId']?.toString());
      secondPlace = findAthlete(finalMatch['loserId']?.toString());
    }

    // Rank remaining athletes by fewest losses, then highest composite Elo + PR + Max Lift
    final rankedRest = List<Map<String, dynamic>>.from(catAthletes)
      ..sort((a, b) {
        final lA = (a['lossesCount'] as num?)?.toInt() ?? 0;
        final lB = (b['lossesCount'] as num?)?.toInt() ?? 0;
        if (lA != lB) return lA.compareTo(lB);
        return _compositeSmartScore(b).compareTo(_compositeSmartScore(a));
      });

    for (final candidate in rankedRest) {
      final cId = candidate['id']?.toString();
      if (firstPlace == null) {
        firstPlace = candidate;
      } else if (secondPlace == null && cId != firstPlace?['id']?.toString()) {
        secondPlace = candidate;
      } else if (thirdPlace == null &&
          cId != firstPlace?['id']?.toString() &&
          cId != secondPlace?['id']?.toString()) {
        thirdPlace = candidate;
        break;
      }
    }

    final podium = <Map<String, dynamic>>[];
    final rawTopN = ((_awardsConfig['topNCount'] as num?)?.toInt() ?? 3).clamp(3, 5);
    final placements = [
      if (firstPlace != null) (1, '1ST PLACE CHAMPION', firstPlace),
      if (secondPlace != null) (2, '2ND PLACE RUNNER-UP', secondPlace),
      if (thirdPlace != null) (3, '3RD PLACE PODIUM', thirdPlace),
    ];

    for (final entry in placements) {
      if (entry.$1 > rawTopN) continue;
      final ath = entry.$3;
      podium.add({
        'position': entry.$1,
        'title': entry.$2,
        'athleteId': ath['id']?.toString() ?? '',
        'athleteName': ath['athleteName']?.toString() ?? 'Athlete',
        'clubName': ath['clubName']?.toString() ?? 'ArmSphere Club',
        'eloRating': (ath['eloRating'] as num?)?.toInt() ?? 1500,
        'prKg': (ath['prKg'] as num?)?.toDouble() ?? 55.0,
        'maxLiftKg': (ath['maxLiftKg'] as num?)?.toDouble() ?? 62.0,
        'lossesCount': (ath['lossesCount'] as num?)?.toInt() ?? 0,
        'prizeDescription': _formatPrizeForPosition(entry.$1),
      });
    }

    return podium;
  }

  /// Fast helper to simulate/complete the Final match of the selected category so the
  /// operator can immediately verify or certify the Final & Podium Summary Card in 1 tap.
  Future<void> _handleCompleteFinalAndCertifyPodiumNow() async {
    HapticFeedback.heavyImpact();
    final roundTabs = _buildDynamicRoundTabs(_selectedCategory);
    final finalRound =
        (roundTabs.last['round'] as num?)?.toInt() ?? roundTabs.length;

    final catAthletes = List<Map<String, dynamic>>.from(
      _athletesInCategory(_selectedCategory),
    )..sort((a, b) =>
        _compositeSmartScore(b).compareTo(_compositeSmartScore(a)));

    if (catAthletes.length < 2) return;

    final finalistA = catAthletes[0];
    final finalistB = catAthletes[1];
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final tableName = _tableNames.first;

    final allMatches = _getMatchesForCategory(_selectedCategory);
    final otherMatches = allMatches
        .where((m) => ((m['roundNumber'] as num?)?.toInt() ?? 1) != finalRound)
        .toList();

    final finalMatch = <String, dynamic>{
      'id': 'm_final_${_selectedCategory.hashCode.abs()}_r${finalRound}_$nowMs',
      'categoryLabel': _selectedCategory,
      'roundNumber': finalRound,
      'matchIndex': 1,
      'queueOrderRank': 10,
      'isBye': false,
      'athleteAId': finalistA['id'].toString(),
      'athleteAName': finalistA['athleteName'].toString(),
      'athleteAElo': ((finalistA['eloRating'] as num?)?.toInt() ?? 1800) + 18,
      'athleteAPrKg': (finalistA['prKg'] as num?)?.toDouble() ?? 65.0,
      'athleteAMaxLiftKg': (finalistA['maxLiftKg'] as num?)?.toDouble() ?? 73.0,
      'athleteALosses': 0,
      'athleteBId': finalistB['id'].toString(),
      'athleteBName': finalistB['athleteName'].toString(),
      'athleteBElo': ((finalistB['eloRating'] as num?)?.toInt() ?? 1750) - 18,
      'athleteBPrKg': (finalistB['prKg'] as num?)?.toDouble() ?? 62.0,
      'athleteBMaxLiftKg': (finalistB['maxLiftKg'] as num?)?.toDouble() ?? 70.0,
      'athleteBLosses': _maxLossesBeforeElimination,
      'assignedTable': tableName,
      'tableQueueStatus': 'COMPLETED_TABLE_FREED',
      'status': 'DONE',
      'winnerId': finalistA['id'].toString(),
      'loserId': finalistB['id'].toString(),
      'eloTransferDelta': 18,
      'scoreLine': '3-1 • FINAL CHAMPIONSHIP',
    };

    setState(() {
      _setMatchesForCategory(_selectedCategory, [...otherMatches, finalMatch]);
      _markRoundUnlockedByOverride(_selectedCategory, finalRound);
      _selectedRound = finalRound;
      _completionFilter = 'ALL';
      _pairingFilter = 'MATCHED_UP';
    });

    final podium = _computeCategoryPodium(_selectedCategory);
    await widget.onCommitMatchupsAction(
      updatedMatchupsState: _matchupsState,
      updatedAthletes: _athletes,
      actionType: 'CERTIFY_CATEGORY_PODIUM',
      syncPayload: {
        'eventId': widget.tournament['id'],
        'categoryLabel': _selectedCategory,
        'finalMatchId': finalMatch['id'],
        'podium': podium,
      },
      bannerMessage:
          'Saved / Done • $_selectedCategory Final Completed & Podium Summary Generated',
    );
  }

  /// Manual Pairing & BYE Creation Dialog
  Future<void> _openManualPairOrByeDialog({
    String? preselectedAthleteAId,
  }) async {
    final catAthletes = _athletesInCategory(_selectedCategory);
    if (catAthletes.isEmpty) return;

    String selectedA =
        preselectedAthleteAId ?? catAthletes.first['id'].toString();
    String selectedB = catAthletes.length > 1
        ? catAthletes
            .firstWhere((a) => a['id'].toString() != selectedA,
                orElse: () => catAthletes.first)['id']
            .toString()
        : 'BYE';
    String selectedTable = _tableNames.first;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.titanium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            side: const BorderSide(color: AppTheme.goldPrimary),
          ),
          title: Text(
            'Manual Matchup / BYE Assignment ($_selectedCategory • R$_selectedRound)',
            style: const TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontWeight: FontWeight.w900,
              fontSize: 14.5,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedA,
                  isExpanded: true,
                  items: [
                    for (final a in catAthletes)
                      DropdownMenuItem(
                        value: a['id'].toString(),
                        child: Text(
                          '${a['athleteName']} (${a['eloRating']} ELO • PR ${a['prKg']}kg)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedA = v);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Left Corner Athlete *',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedB,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(
                      value: 'BYE',
                      child: Text(
                        '★ BYE (Auto-Advance to Next Round)',
                        style: TextStyle(
                          color: AppTheme.goldPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    for (final b in catAthletes)
                      if (b['id'].toString() != selectedA)
                        DropdownMenuItem(
                          value: b['id'].toString(),
                          child: Text(
                            '${b['athleteName']} (${b['eloRating']} ELO • PR ${b['prKg']}kg)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedB = v);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Right Corner Opponent (or BYE) *',
                  ),
                ),
                if (_tableCount > 1) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedTable,
                    isExpanded: true,
                    items: [
                      for (final t in _tableNames)
                        DropdownMenuItem(value: t, child: Text(t)),
                    ],
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selectedTable = v);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Assigned Table',
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(
                'CANCEL',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldPrimary,
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                'SAVE MATCHUP',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;
    HapticFeedback.mediumImpact();

    final athA =
        catAthletes.firstWhere((a) => a['id'].toString() == selectedA);
    final isBye = selectedB == 'BYE' || selectedB == selectedA;
    final athB = isBye
        ? null
        : catAthletes.firstWhere((a) => a['id'].toString() == selectedB);

    final allMatches = _getMatchesForCategory(_selectedCategory);
    final roundMatches = allMatches
        .where(
            (m) => ((m['roundNumber'] as num?)?.toInt() ?? 1) == _selectedRound)
        .toList();
    final nextIdx = roundMatches.length + 1;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final newMatch = <String, dynamic>{
      'id':
          'm_manual_${_selectedCategory.hashCode.abs()}_r${_selectedRound}_$nowMs',
      'categoryLabel': _selectedCategory,
      'roundNumber': _selectedRound,
      'matchIndex': nextIdx,
      'queueOrderRank': nextIdx * 10,
      'isBye': isBye,
      'athleteAId': athA['id'].toString(),
      'athleteAName': athA['athleteName'].toString(),
      'athleteAElo': (athA['eloRating'] as num?)?.toInt() ?? 1500,
      'athleteAPrKg': (athA['prKg'] as num?)?.toDouble() ?? 55.0,
      'athleteAMaxLiftKg': (athA['maxLiftKg'] as num?)?.toDouble() ?? 62.0,
      'athleteALosses': (athA['lossesCount'] as num?)?.toInt() ?? 0,
      'athleteBId': isBye ? 'BYE' : athB!['id'].toString(),
      'athleteBName': isBye
          ? 'BYE (Auto-Advance to Next Round)'
          : athB!['athleteName'].toString(),
      'athleteBElo':
          isBye ? 0 : ((athB!['eloRating'] as num?)?.toInt() ?? 1500),
      'athleteBPrKg':
          isBye ? 0.0 : ((athB!['prKg'] as num?)?.toDouble() ?? 55.0),
      'athleteBMaxLiftKg':
          isBye ? 0.0 : ((athB!['maxLiftKg'] as num?)?.toDouble() ?? 62.0),
      'athleteBLosses':
          isBye ? 0 : ((athB!['lossesCount'] as num?)?.toInt() ?? 0),
      'assignedTable': selectedTable,
      'tableQueueStatus':
          isBye ? 'COMPLETED_TABLE_FREED' : 'QUEUED_FOR_FREE_TABLE',
      'status': isBye ? 'DONE' : 'PENDING',
      'winnerId': isBye ? athA['id'].toString() : null,
      'loserId': null,
      'eloTransferDelta': isBye ? 0 : null,
      'scoreLine': isBye ? 'BYE • AUTO-ADVANCE' : null,
    };

    setState(() {
      _setMatchesForCategory(_selectedCategory, [...allMatches, newMatch]);
      if (isBye) {
        _rebuildNextRoundFromSubmittedResults(_selectedCategory, _selectedRound);
      }
      _synchronizeDynamicFreeTableActiveSlots(_selectedCategory);
      _pairingFilter = 'MATCHED_UP';
    });

    await widget.onCommitMatchupsAction(
      updatedMatchupsState: _matchupsState,
      updatedAthletes: _athletes,
      actionType: 'UPDATE_MATCHUP_PAIRING',
      syncPayload: {
        'eventId': widget.tournament['id'],
        'categoryLabel': _selectedCategory,
        'roundNumber': _selectedRound,
        'match': newMatch,
      },
      bannerMessage: isBye
          ? 'Saved / Done • ${athA['athleteName']} assigned BYE (Auto-Advance)'
          : 'Saved / Done • Paired ${athA['athleteName']} vs. ${athB!['athleteName']}',
    );
  }

  /// Edit / Swap / Change Any Existing Matchup Dialog
  Future<void> _openEditOrSwapMatchupDialog(Map<String, dynamic> match) async {
    final catAthletes = _athletesInCategory(_selectedCategory);
    if (catAthletes.isEmpty) return;

    String selectedA = match['athleteAId']?.toString() ??
        catAthletes.first['id'].toString();
    if (!catAthletes.any((a) => a['id'].toString() == selectedA)) {
      selectedA = catAthletes.first['id'].toString();
    }
    String selectedB = (match['isBye'] == true)
        ? 'BYE'
        : (match['athleteBId']?.toString() ?? 'BYE');
    if (selectedB != 'BYE' &&
        !catAthletes.any((a) => a['id'].toString() == selectedB)) {
      selectedB = 'BYE';
    }
    String selectedTable =
        match['assignedTable']?.toString() ?? _tableNames.first;
    if (!_tableNames.contains(selectedTable)) {
      selectedTable = _tableNames.first;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.titanium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            side: const BorderSide(color: AppTheme.goldPrimary),
          ),
          title: Text(
            'Edit / Swap Matchup #${match['matchIndex']} (Round ${match['roundNumber']})',
            style: const TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontWeight: FontWeight.w900,
              fontSize: 14.5,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedA,
                  isExpanded: true,
                  items: [
                    for (final a in catAthletes)
                      DropdownMenuItem(
                        value: a['id'].toString(),
                        child: Text(
                          '${a['athleteName']} (${a['eloRating']} ELO • PR ${a['prKg']}kg)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedA = v);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Left Corner Athlete',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedB,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(
                      value: 'BYE',
                      child: Text(
                        '★ BYE (Auto-Advance to Next Round)',
                        style: TextStyle(
                          color: AppTheme.goldPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    for (final b in catAthletes)
                      DropdownMenuItem(
                        value: b['id'].toString(),
                        child: Text(
                          '${b['athleteName']} (${b['eloRating']} ELO • PR ${b['prKg']}kg)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedB = v);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Right Corner Opponent (or BYE)',
                  ),
                ),
                if (_tableCount > 1) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedTable,
                    isExpanded: true,
                    items: [
                      for (final t in _tableNames)
                        DropdownMenuItem(value: t, child: Text(t)),
                    ],
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selectedTable = v);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Assigned Table',
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(
                'CANCEL',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldPrimary,
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                'UPDATE MATCHUP',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;
    HapticFeedback.mediumImpact();

    final athA =
        catAthletes.firstWhere((a) => a['id'].toString() == selectedA);
    final isBye = selectedB == 'BYE' || selectedB == selectedA;
    final athB = isBye
        ? null
        : catAthletes.firstWhere((a) => a['id'].toString() == selectedB);

    final matchId = match['id'].toString();
    final updatedMatches = _getMatchesForCategory(_selectedCategory).map((m) {
      if (m['id'].toString() != matchId) return m;
      return <String, dynamic>{
        ...m,
        'isBye': isBye,
        'athleteAId': athA['id'].toString(),
        'athleteAName': athA['athleteName'].toString(),
        'athleteAElo': (athA['eloRating'] as num?)?.toInt() ?? 1500,
        'athleteAPrKg': (athA['prKg'] as num?)?.toDouble() ?? 55.0,
        'athleteAMaxLiftKg': (athA['maxLiftKg'] as num?)?.toDouble() ?? 62.0,
        'athleteALosses': (athA['lossesCount'] as num?)?.toInt() ?? 0,
        'athleteBId': isBye ? 'BYE' : athB!['id'].toString(),
        'athleteBName': isBye
            ? 'BYE (Auto-Advance to Next Round)'
            : athB!['athleteName'].toString(),
        'athleteBElo':
            isBye ? 0 : ((athB!['eloRating'] as num?)?.toInt() ?? 1500),
        'athleteBPrKg':
            isBye ? 0.0 : ((athB!['prKg'] as num?)?.toDouble() ?? 55.0),
        'athleteBMaxLiftKg':
            isBye ? 0.0 : ((athB!['maxLiftKg'] as num?)?.toDouble() ?? 62.0),
        'athleteBLosses':
            isBye ? 0 : ((athB!['lossesCount'] as num?)?.toInt() ?? 0),
        'assignedTable': selectedTable,
        'status': isBye ? 'DONE' : 'PENDING',
        'winnerId': isBye ? athA['id'].toString() : null,
        'loserId': null,
        'eloTransferDelta': isBye ? 0 : null,
        'scoreLine': isBye ? 'BYE • AUTO-ADVANCE' : null,
      };
    }).toList();

    setState(() {
      _setMatchesForCategory(_selectedCategory, updatedMatches);
      _rebuildNextRoundFromSubmittedResults(
        _selectedCategory,
        (match['roundNumber'] as num?)?.toInt() ?? 1,
      );
      _synchronizeDynamicFreeTableActiveSlots(_selectedCategory);
    });

    await widget.onCommitMatchupsAction(
      updatedMatchupsState: _matchupsState,
      updatedAthletes: _athletes,
      actionType: 'UPDATE_MATCHUP_PAIRING',
      syncPayload: {
        'eventId': widget.tournament['id'],
        'categoryLabel': _selectedCategory,
        'matchId': matchId,
      },
      bannerMessage: 'Saved / Done • Matchup Updated Locally & Queued for Sync',
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = _availableCategoryLabels();
    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = categories.first;
    }

    final roundTabs = _buildDynamicRoundTabs(_selectedCategory);
    if (_isSuperfights) {
      _selectedRound = 1;
    } else if (!roundTabs.any((t) => t['round'] == _selectedRound)) {
      _selectedRound = 1;
    }

    final allCategoryMatches = _getMatchesForCategory(_selectedCategory);
    final roundMatches = allCategoryMatches
        .where((m) =>
            _isSuperfights ||
            ((m['roundNumber'] as num?)?.toInt() ?? 1) == _selectedRound)
        .toList()
      ..sort((a, b) {
        final qA = (a['queueOrderRank'] as num?)?.toInt() ??
            ((a['matchIndex'] as num?)?.toInt() ?? 1) * 10;
        final qB = (b['queueOrderRank'] as num?)?.toInt() ??
            ((b['matchIndex'] as num?)?.toInt() ?? 1) * 10;
        return qA.compareTo(qB);
      });

    final tableFilteredMatches = roundMatches.where((m) {
      if (_tableCount <= 1 || _selectedTableFilter == 'ALL') return true;
      return (m['assignedTable'] ?? 'Table 1').toString() ==
          _selectedTableFilter;
    }).toList();

    final completionFilteredMatches = tableFilteredMatches.where((m) {
      final st = (m['status'] ?? 'PENDING').toString().toUpperCase();
      if (_completionFilter == 'PENDING') return st == 'PENDING';
      if (_completionFilter == 'DONE') return st == 'DONE';
      return true;
    }).toList();

    // Determine "Non-Matched Up" athletes in this category and round
    final pairedAthleteIdsInRound = <String>{};
    for (final m in roundMatches) {
      final a = m['athleteAId']?.toString() ?? '';
      final b = m['athleteBId']?.toString() ?? '';
      if (a.isNotEmpty) pairedAthleteIdsInRound.add(a);
      if (b.isNotEmpty && b != 'BYE') pairedAthleteIdsInRound.add(b);
    }

    final catAthletes = _athletesInCategory(_selectedCategory);
    final nonMatchedAthletes = catAthletes
        .where((a) => !pairedAthleteIdsInRound.contains(a['id']?.toString()))
        .toList();

    final pendingInRoundCount = roundMatches
        .where((m) =>
            (m['status'] ?? 'PENDING').toString().toUpperCase() == 'PENDING')
        .length;
    final doneInRoundCount = roundMatches
        .where(
            (m) => (m['status'] ?? 'PENDING').toString().toUpperCase() == 'DONE')
        .length;
    final isCurrentRoundSubmissionAllowed =
        _canSubmitResultsInRound(_selectedCategory, _selectedRound);

    final isFinalDoneForSelectedCategory =
        _isCategoryFinalCompleted(_selectedCategory);
    final selectedCategoryPodium = isFinalDoneForSelectedCategory
        ? _computeCategoryPodium(_selectedCategory)
        : const <Map<String, dynamic>>[];

    final formatBadgeText = _isSuperfights
        ? 'SUPERFIGHTS'
        : _eliminationSubFormat.replaceAll('_', ' ');

    String compactDiv(String raw) {
      String w = raw.split('•').first.trim().replaceAll(' ', '');
      final up = raw.toUpperCase();
      if (up.contains('RIGHT')) return '$w R';
      if (up.contains('LEFT')) return '$w L';
      return raw;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space16,
        12,
        AppTheme.space16,
        40,
      ),
      children: [
        // =====================================================================
        // 0. SLEEK FORGED-CRYSTAL STAGE HEADER
        // =====================================================================
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF171C26), Color(0xFF0C0F16)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.goldPrimary.withValues(alpha: 0.45),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: widget.onBackToHub,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppTheme.obsidian,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.goldPrimary.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 12,
                        color: AppTheme.goldPrimary,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'HUB',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.goldPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MATCHUPS, BRACKETS & PODIUM • $formatBadgeText',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${compactDiv(_selectedCategory)} • ${catAthletes.length} Pullers • $doneInRoundCount Done / $pendingInRoundCount Pending',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.emerald,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isFinalDoneForSelectedCategory)
                InkWell(
                  key: const ValueKey('card3_complete_final_podium_button'),
                  borderRadius: BorderRadius.circular(9),
                  onTap: _handleCompleteFinalAndCertifyPodiumNow,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.goldPrimary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: AppTheme.goldPrimary.withValues(alpha: 0.65),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.emoji_events_rounded,
                          size: 13,
                          color: AppTheme.goldPrimary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'PODIUM',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.goldPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // =====================================================================
        // AUTOMATIC 1ST, 2ND & 3RD PLACE CATEGORY PODIUM BANNER
        // =====================================================================
        if (isFinalDoneForSelectedCategory &&
            selectedCategoryPodium.isNotEmpty) ...[
          _buildCategoryPodiumSummaryCard(
            categoryLabel: _selectedCategory,
            podium: selectedCategoryPodium,
          ),
          const SizedBox(height: 12),
          if ((_awardsConfig['winnerStructure'] ?? '')
                  .toString()
                  .toUpperCase() ==
              'OVERALL_WINNERS') ...[
            _buildOverallTournamentWinnersCard(categories),
            const SizedBox(height: 12),
          ],
        ],

        // =====================================================================
        // 1. TOP COMMAND ACTION BAR
        // =====================================================================
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF171D29), Color(0xFF0C1017)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.goldPrimary.withValues(alpha: 0.45),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: GestureDetector(
                      key: const ValueKey('card3_smart_random_matchups_button'),
                      onTap: _handleSmartRandomMatchupsForCurrentRound,
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3A1216), Color(0xFF1C080B)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE23B3B),
                            width: 1.3,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bolt_rounded,
                              size: 18,
                              color: AppTheme.goldPrimary,
                            ),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '⚡ SMART RANDOM PAIRING',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textPrimary,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      key: const ValueKey('card3_manual_pair_button'),
                      onTap: () => _openManualPairOrByeDialog(),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2B2210), Color(0xFF141008)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.goldPrimary,
                            width: 1.2,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              size: 17,
                              color: AppTheme.goldPrimary,
                            ),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '+ MANUAL BOUT',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.goldPrimary,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (catAthletes.length % 2 == 1) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.fast_forward_rounded,
                      size: 14,
                      color: AppTheme.goldPrimary,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'ODD ROSTER BYE:',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.goldPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text(
                        'Top ELO/PR',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                      selected: _byeAssignmentPolicy == 'HIGHEST_ELO_PR',
                      onSelected: (_) => setState(
                          () => _byeAssignmentPolicy = 'HIGHEST_ELO_PR'),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text(
                        'Random BYE',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                      selected: _byeAssignmentPolicy == 'RANDOM',
                      onSelected: (_) =>
                          setState(() => _byeAssignmentPolicy = 'RANDOM'),
                    ),
                  ],
                ),
              ],
              if (!_isSuperfights &&
                  _selectedRound < roundTabs.length &&
                  (doneInRoundCount > 0 || pendingInRoundCount > 0)) ...[
                const SizedBox(height: 10),
                GestureDetector(
                  key: const ValueKey(
                      'card3_next_round_cancel_pending_override_button'),
                  onTap: _handleNextRoundAndCancelPendingOverride,
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF102B22), Color(0xFF081712)],
                      ),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: AppTheme.emerald,
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        pendingInRoundCount > 0
                            ? '⏭ ADVANCE TO NEXT ROUND (OVERRIDE $pendingInRoundCount PENDING)'
                            : '⏭ ADVANCE TO NEXT ROUND (ROUND ${_selectedRound + 1}) →',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.emerald,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // =====================================================================
        // 2. CLEAN CONTEXT-AWARE FILTER STRIPS (ZERO CLUTTER)
        // =====================================================================
        // Row 1: Horizontal Weight & Arm Division chips (70kg R, 70kg L, 80kg R...)
        SingleChildScrollView(
          key: const ValueKey('card3_weight_category_filter_bar'),
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final cat in categories)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedCategory = cat;
                        _selectedRound = 1;
                        _synchronizeDynamicFreeTableActiveSlots(cat);
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: _selectedCategory == cat
                            ? const LinearGradient(
                                colors: [Color(0xFF2B2210), Color(0xFF141008)],
                              )
                            : const LinearGradient(
                                colors: [Color(0xFF151923), Color(0xFF0C0F16)],
                              ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _selectedCategory == cat
                              ? AppTheme.goldPrimary
                              : const Color(0x28FFFFFF),
                          width: _selectedCategory == cat ? 1.3 : 1.0,
                        ),
                      ),
                      child: Text(
                        '${_isCategoryFinalCompleted(cat) ? "🏆 " : ""}${compactDiv(cat)} (${_athletesInCategory(cat).length})',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontWeight: FontWeight.w900,
                          fontSize: 11.5,
                          color: _selectedCategory == cat
                              ? AppTheme.goldPrimary
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Row 2: Compact Segmented Bar for [ Matched ] vs [ Unmatched ] + Status Pills (All, Pending, Completed)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1017),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x28FFFFFF)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      key: const ValueKey('card3_filter_matched_up'),
                      borderRadius: BorderRadius.circular(8),
                      onTap: () =>
                          setState(() => _pairingFilter = 'MATCHED_UP'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _pairingFilter == 'MATCHED_UP'
                              ? const Color(0xFFE23B3B).withValues(alpha: 0.22)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: _pairingFilter == 'MATCHED_UP'
                              ? Border.all(color: const Color(0xFFE23B3B))
                              : null,
                        ),
                        child: Text(
                          'Matched (${roundMatches.length})',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: _pairingFilter == 'MATCHED_UP'
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      key: const ValueKey('card3_filter_non_matched_up'),
                      borderRadius: BorderRadius.circular(8),
                      onTap: () =>
                          setState(() => _pairingFilter = 'NON_MATCHED_UP'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _pairingFilter == 'NON_MATCHED_UP'
                              ? AppTheme.warning.withValues(alpha: 0.22)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: _pairingFilter == 'NON_MATCHED_UP'
                              ? Border.all(color: AppTheme.warning)
                              : null,
                        ),
                        child: Text(
                          'Unmatched (${nonMatchedAthletes.length})',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: _pairingFilter == 'NON_MATCHED_UP'
                                ? AppTheme.warning
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_pairingFilter == 'MATCHED_UP') ...[
                const SizedBox(width: 8),
                for (final comp in [
                  ('ALL', 'All (${roundMatches.length})'),
                  ('PENDING', 'Pending ($pendingInRoundCount)'),
                  ('DONE', 'Completed ($doneInRoundCount)'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      key: ValueKey('card3_completion_filter_${comp.$1}'),
                      label: Text(
                        comp.$2,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      selected: _completionFilter == comp.$1,
                      onSelected: (_) =>
                          setState(() => _completionFilter = comp.$1),
                    ),
                  ),
              ],
            ],
          ),
        ),

        // Row 3 (Shown ONLY for Elimination): Round Progression Pills with Connecting Line
        if (!_isSuperfights) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            key: const ValueKey('card3_elimination_round_filter_bar'),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < roundTabs.length; i++) ...[
                  if (i > 0)
                    Container(
                      width: 14,
                      height: 2,
                      color: AppTheme.goldPrimary.withValues(alpha: 0.45),
                    ),
                  Builder(
                    builder: (_) {
                      final rt = roundTabs[i];
                      final rNum = rt['round'] as int;
                      final isSel = _selectedRound == rNum;
                      return InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedRound = rNum;
                            _synchronizeDynamicFreeTableActiveSlots(
                                _selectedCategory);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: isSel
                                ? AppTheme.goldPrimary.withValues(alpha: 0.2)
                                : const Color(0xFF131722),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSel
                                  ? AppTheme.goldPrimary
                                  : const Color(0x28FFFFFF),
                              width: isSel ? 1.3 : 1.0,
                            ),
                          ),
                          child: Text(
                            rt['label'].toString(),
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              color: isSel
                                  ? AppTheme.goldPrimary
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],

        // Row 4 (Shown ONLY when Tables > 1): Table Filter Pills
        if (_tableCount > 1) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            key: const ValueKey('card3_table_filter_bar'),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text(
                    'All Tables',
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  selected: _selectedTableFilter == 'ALL',
                  onSelected: (_) =>
                      setState(() => _selectedTableFilter = 'ALL'),
                ),
                const SizedBox(width: 6),
                for (final tName in _tableNames)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(
                        tName,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      selected: _selectedTableFilter == tName,
                      onSelected: (_) =>
                          setState(() => _selectedTableFilter = tName),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildDynamicFreeTableQueuePanel(roundMatches),
        ],
        const SizedBox(height: 12),

        // Unlock Override Pill if viewing a locked future round
        if (!_isSuperfights && !isCurrentRoundSubmissionAllowed) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.warning),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_clock_rounded,
                  size: 16,
                  color: AppTheme.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Round $_selectedRound awaiting Round ${_selectedRound - 1} completion',
                    style: const TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.warning,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    setState(() {
                      _markRoundUnlockedByOverride(
                          _selectedCategory, _selectedRound);
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.goldPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.goldPrimary),
                    ),
                    child: const Text(
                      'UNLOCK NOW',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.goldPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // =====================================================================
        // 3. BOUT PLATES OR UNMATCHED ATHLETE LIST
        // =====================================================================
        if (_pairingFilter == 'NON_MATCHED_UP')
          _buildNonMatchedUpAthletesList(nonMatchedAthletes)
        else if (completionFilteredMatches.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF121620),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x28FFFFFF)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'No bouts in this filter view.',
                    style:
                        TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _handleSmartRandomMatchupsForCurrentRound,
                  icon: const Icon(Icons.bolt_rounded, size: 16),
                  label: const Text('SMART PAIR'),
                ),
              ],
            ),
          )
        else
          for (final match in completionFilteredMatches) ...[
            _buildMatchupCard(
              match: match,
              isSubmissionAllowed: isCurrentRoundSubmissionAllowed,
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }

  /// COMPACT MULTI-TABLE LIVE DECK & FREE-TABLE QUEUE STRIP (When Tables > 1)
  Widget _buildDynamicFreeTableQueuePanel(
    List<Map<String, dynamic>> roundMatches,
  ) {
    final pendingMatches = roundMatches
        .where((m) =>
            m['isBye'] != true &&
            (m['status'] ?? 'PENDING').toString().toUpperCase() == 'PENDING')
        .toList();

    final lastSummary = _matchupsState['lastAutoAssignedSummary']?.toString();

    return Container(
      key: const ValueKey('card3_dynamic_free_table_queue_panel'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111621),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.table_restaurant_rounded,
                  size: 15, color: AppTheme.cyan),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'LIVE MULTI-TABLE QUEUE ($_tableCount TABLES)',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.cyan,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              StatusChip(
                label: _isDynamicFreeTableMode
                    ? 'FREE-TABLE AUTO QUEUE'
                    : _tableAssignmentMode.replaceAll('_', ' '),
                type: StatusType.info,
              ),
            ],
          ),
          if (lastSummary != null && lastSummary.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              lastSummary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppTheme.fontMono,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppTheme.emerald,
              ),
            ),
          ],
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final tName in _tableNames)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildSingleTableQueueStatusCard(
                      tableName: tName,
                      pendingMatches: pendingMatches,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleTableQueueStatusCard({
    required String tableName,
    required List<Map<String, dynamic>> pendingMatches,
  }) {
    final tablePending = pendingMatches
        .where((m) => (m['assignedTable'] ?? 'Table 1').toString() == tableName)
        .toList();

    final activeMatch = tablePending.firstOrNull;

    return Container(
      width: 235,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.obsidian,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: activeMatch != null
              ? AppTheme.cyan.withValues(alpha: 0.55)
              : AppTheme.emerald.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tableName.toUpperCase(),
                style: const TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.goldPrimary,
                ),
              ),
              Text(
                activeMatch != null
                    ? 'BOUT #${activeMatch['matchIndex']}'
                    : 'TABLE FREE ✓',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  color:
                      activeMatch != null ? AppTheme.cyan : AppTheme.emerald,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          if (activeMatch != null) ...[
            Text(
              '${activeMatch['athleteAName']} vs ${activeMatch['athleteBName']}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              key: ValueKey(
                  'card3_table_skip_absent_${tableName.replaceAll(' ', '_')}'),
              borderRadius: BorderRadius.circular(7),
              onTap: () => _handleSkipAbsentAndPlayNextMatchup(activeMatch),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: AppTheme.warning.withValues(alpha: 0.65),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.skip_next_rounded,
                        size: 13, color: AppTheme.warning),
                    SizedBox(width: 4),
                    Text(
                      '⏭ SKIP (ABSENT)',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else
            const Text(
              'Ready for next queued bout',
              style: TextStyle(fontSize: 10.5, color: AppTheme.emerald),
            ),
        ],
      ),
    );
  }

  /// PRESTIGIOUS CHAMPIONSHIP PODIUM BANNER (1st Gold, 2nd Silver, 3rd Bronze + PKR Purse)
  Widget _buildCategoryPodiumSummaryCard({
    required String categoryLabel,
    required List<Map<String, dynamic>> podium,
  }) {
    return Container(
      key: ValueKey('card3_category_podium_summary_$categoryLabel'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF282010), Color(0xFF100E09)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.goldPrimary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.goldPrimary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.goldPrimary),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  size: 20,
                  color: AppTheme.goldPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CHAMPIONSHIP PODIUM STANDINGS',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.emerald,
                        letterSpacing: 0.7,
                      ),
                    ),
                    Text(
                      categoryLabel.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.goldPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const StatusChip(
                label: 'FINAL CERTIFIED ✓',
                type: StatusType.success,
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final p in podium) ...[
            Builder(
              builder: (_) {
                final pos = (p['position'] as num?)?.toInt() ?? 1;
                final Color medalColor = pos == 1
                    ? const Color(0xFFD4AF37) // 1st Gold
                    : pos == 2
                        ? const Color(0xFFE2E8F0) // 2nd Silver
                        : const Color(0xFFCD7F32); // 3rd Bronze
                final String medalTitle = pos == 1
                    ? '1ST GOLD'
                    : pos == 2
                        ? '2ND SILVER'
                        : '3RD BRONZE';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF12151E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: medalColor.withValues(alpha: pos == 1 ? 0.85 : 0.45),
                      width: pos == 1 ? 1.4 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: medalColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: medalColor),
                        ),
                        child: Text(
                          medalTitle,
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: medalColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (p['athleteName'] ?? 'Champion').toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'ELO ${p['eloRating']} • PR ${p['prKg']}kg',
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.emerald.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: AppTheme.emerald.withValues(alpha: 0.7),
                          ),
                        ),
                        child: Text(
                          p['prizeDescription'].toString(),
                          style: const TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.emerald,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  /// OVERALL TOURNAMENT WINNERS SUMMARY CARD
  Widget _buildOverallTournamentWinnersCard(List<String> categories) {
    final championsPool = <Map<String, dynamic>>[];
    for (final cat in categories) {
      final podium = _computeCategoryPodium(cat);
      if (podium.isNotEmpty) {
        championsPool.add({
          ...podium.first,
          'categoryLabel': cat,
        });
      }
    }
    championsPool.sort((a, b) =>
        ((b['eloRating'] as num?)?.toInt() ?? 0)
            .compareTo((a['eloRating'] as num?)?.toInt() ?? 0));

    final topOverall = championsPool.take(3).toList();
    if (topOverall.isEmpty) return const SizedBox.shrink();

    return ElevatedActionCard(
      key: const ValueKey('card3_overall_tournament_winners_card'),
      padding: const EdgeInsets.all(14),
      borderColor: AppTheme.emerald,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.workspace_premium_rounded,
                  size: 20, color: AppTheme.emerald),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'OVERALL TOURNAMENT CHAMPIONS',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.emerald,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < topOverall.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '#${i + 1} ${topOverall[i]['athleteName']} (${topOverall[i]['categoryLabel']})',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    _formatPrizeForPosition(i + 1),
                    style: const TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.goldPrimary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNonMatchedUpAthletesList(
    List<Map<String, dynamic>> nonMatchedAthletes,
  ) {
    if (nonMatchedAthletes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF121620),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.45)),
        ),
        child: const Text(
          'All athletes in this division and round are paired.',
          style: TextStyle(fontSize: 12, color: AppTheme.emerald),
        ),
      );
    }

    return Column(
      children: [
        for (final a in nonMatchedAthletes) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF151923),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: AppTheme.warning.withValues(alpha: 0.55)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a['athleteName']?.toString() ?? 'Athlete',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ELO ${a['eloRating']} • PR ${a['prKg']}kg • Lift ${a['maxLiftKg']}kg',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.goldPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(9),
                  onTap: () => _openManualPairOrByeDialog(
                    preselectedAthleteAId: a['id'].toString(),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2B2210), Color(0xFF141008)],
                      ),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: AppTheme.goldPrimary),
                    ),
                    child: const Text(
                      '+ PAIR / BYE',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.goldPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  /// CHAMPIONSHIP "RED CORNER VS. GOLD/BLUE CORNER" MATCHUP CARD UI (BOUT PLATE)
  Widget _buildMatchupCard({
    required Map<String, dynamic> match,
    required bool isSubmissionAllowed,
  }) {
    final isBye = match['isBye'] == true;
    final status = (match['status'] ?? 'PENDING').toString().toUpperCase();
    final isDone = status == 'DONE';
    final isCancelled = status == 'CANCELLED_PENDING';
    final winnerId = match['winnerId']?.toString();
    final eloDelta = (match['eloTransferDelta'] as num?)?.toInt() ?? 16;
    final tableBadge = (match['assignedTable'] ?? 'Table 1').toString();
    final tableQueueStatus =
        (match['tableQueueStatus'] ?? 'ACTIVE_AT_TABLE').toString();
    final deferredNote = match['deferredNote']?.toString();
    final roundNumber = (match['roundNumber'] as num?)?.toInt() ?? 1;
    final matchIndex = (match['matchIndex'] as num?)?.toInt() ?? 1;

    final aId = match['athleteAId']?.toString() ?? '';
    final bId = match['athleteBId']?.toString() ?? '';
    final aIsWinner = isDone && winnerId == aId;
    final bIsWinner = isDone && winnerId == bId;

    final String statusLabel = isBye
        ? 'BYE ADVANCE'
        : isDone
            ? 'COMPLETED ✓'
            : isCancelled
                ? 'OVERRIDDEN'
                : (tableQueueStatus == 'ACTIVE_AT_TABLE' && _tableCount > 1
                    ? 'ON TABLE'
                    : 'PENDING');

    final Color statusColor = isBye
        ? AppTheme.goldPrimary
        : isDone
            ? AppTheme.emerald
            : isCancelled
                ? AppTheme.crimson
                : (tableQueueStatus == 'ACTIVE_AT_TABLE'
                    ? AppTheme.cyan
                    : AppTheme.warning);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF171C28), Color(0xFF0D1017)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone
              ? AppTheme.emerald.withValues(alpha: 0.55)
              : isBye
                  ? AppTheme.goldPrimary.withValues(alpha: 0.65)
                  : const Color(0x33FFFFFF),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. TOP STRIP: Bout # & Round tag on left, Assigned Table pill in center, Match Status pill on right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.obsidian,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: AppTheme.goldPrimary.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  _isSuperfights
                      ? 'BOUT #$matchIndex • SUPERFIGHT'
                      : 'BOUT #$matchIndex • ROUND $roundNumber',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.goldPrimary,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              // Center Assigned Table Pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.cyan.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: AppTheme.cyan.withValues(alpha: 0.55),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.table_bar_rounded,
                      size: 11,
                      color: AppTheme.cyan,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      tableBadge.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.cyan,
                      ),
                    ),
                  ],
                ),
              ),
              // Right Match Status Pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.7),
                  ),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          // Multi-Table Reassignment Strip (When Tables > 1)
          if (_tableCount > 1) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final tName in _tableNames)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        key: ValueKey(
                            'card3_reassign_${match['id']}_${tName.replaceAll(' ', '_')}'),
                        visualDensity: VisualDensity.compact,
                        label: Text(
                          tName,
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 10,
                            fontWeight: tableBadge == tName
                                ? FontWeight.w900
                                : FontWeight.w600,
                          ),
                        ),
                        selected: tableBadge == tName,
                        onSelected: (_) => _reassignMatchupTable(match, tName),
                      ),
                    ),
                ],
              ),
            ),
          ],

          if (deferredNote != null && deferredNote.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              deferredNote,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.warning,
              ),
            ),
          ],

          const SizedBox(height: 10),

          // 2. CENTER FACE-OFF ROW: Red Corner vs. Medallion vs. White/Gold Corner
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // LEFT ATHLETE (RED CORNER — 3px Competition Crimson #E23B3B left edge bar)
              Expanded(
                child: _buildCornerColumn(
                  isLeftCorner: true,
                  name: (match['athleteAName'] ?? 'Athlete A').toString(),
                  elo: (match['athleteAElo'] as num?)?.toInt() ?? 1500,
                  prKg: (match['athleteAPrKg'] as num?)?.toDouble() ?? 55.0,
                  maxLiftKg:
                      (match['athleteAMaxLiftKg'] as num?)?.toDouble() ?? 62.0,
                  losses: (match['athleteALosses'] as num?)?.toInt() ?? 0,
                  isDone: isDone,
                  isWinner: aIsWinner,
                  isBye: isBye,
                  eloDelta: eloDelta,
                ),
              ),

              // CENTER VS MEDALLION (or +16 / -16 ELO delta once completed)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF282010), Color(0xFF120F08)],
                        ),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: AppTheme.goldPrimary.withValues(alpha: 0.75),
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        isBye ? 'BYE' : 'VS',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.goldPrimary,
                        ),
                      ),
                    ),
                    if (isDone && !isBye) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.obsidian,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: AppTheme.goldPrimary.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          '+$eloDelta / -$eloDelta ELO',
                          style: const TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.goldPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // RIGHT ATHLETE (WHITE/GOLD CORNER — 3px 24k Gold/Titanium right edge bar, or BYE badge)
              Expanded(
                child: isBye
                    ? Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: AppTheme.goldPrimary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(11),
                          border: const Border(
                            right: BorderSide(
                              color: AppTheme.goldPrimary,
                              width: 3.0,
                            ),
                            top: BorderSide(
                              color: Color(0x66D4AF37),
                              width: 1.0,
                            ),
                            bottom: BorderSide(
                              color: Color(0x66D4AF37),
                              width: 1.0,
                            ),
                            left: BorderSide(
                              color: Color(0x66D4AF37),
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'BYE • AUTO-ADVANCE',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.goldPrimary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Advances to next round',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _buildCornerColumn(
                        isLeftCorner: false,
                        name: (match['athleteBName'] ?? 'Athlete B').toString(),
                        elo: (match['athleteBElo'] as num?)?.toInt() ?? 1500,
                        prKg:
                            (match['athleteBPrKg'] as num?)?.toDouble() ?? 55.0,
                        maxLiftKg: (match['athleteBMaxLiftKg'] as num?)
                                ?.toDouble() ??
                            62.0,
                        losses:
                            (match['athleteBLosses'] as num?)?.toInt() ?? 0,
                        isDone: isDone,
                        isWinner: bIsWinner,
                        isBye: false,
                        eloDelta: eloDelta,
                      ),
              ),
            ],
          ),

          // 3. BOTTOM QUICK-ACTION STRIP: [ ✓ Record Winner ], [ ⇄ Swap / Edit ], [ ⏭ Skip (Absent) ]
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0x22FFFFFF), width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isBye)
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(9),
                          onTap: () =>
                              _submitMatchWinner(match: match, winnerId: aId),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: aIsWinner
                                  ? AppTheme.emerald.withValues(alpha: 0.2)
                                  : const Color(0xFF131823),
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: aIsWinner
                                    ? AppTheme.emerald
                                    : const Color(0x38FFFFFF),
                              ),
                            ),
                            child: Text(
                              aIsWinner
                                  ? '✓ WINNER: ${match['athleteAName']}'
                                  : '✓ Win: ${match['athleteAName']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                color: aIsWinner
                                    ? AppTheme.emerald
                                    : AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(9),
                          onTap: () =>
                              _submitMatchWinner(match: match, winnerId: bId),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: bIsWinner
                                  ? AppTheme.emerald.withValues(alpha: 0.2)
                                  : const Color(0xFF131823),
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: bIsWinner
                                    ? AppTheme.emerald
                                    : const Color(0x38FFFFFF),
                              ),
                            ),
                            child: Text(
                              bIsWinner
                                  ? '✓ WINNER: ${match['athleteBName']}'
                                  : '✓ Win: ${match['athleteBName']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                color: bIsWinner
                                    ? AppTheme.emerald
                                    : AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _openEditOrSwapMatchupDialog(match),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.obsidian,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.goldPrimary.withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              '⇄ Swap / Edit',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.goldPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (!isBye && !isDone && !isCancelled) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          key: ValueKey(
                              'card3_skip_absent_play_next_${match['id']}'),
                          borderRadius: BorderRadius.circular(8),
                          onTap: () =>
                              _handleSkipAbsentAndPlayNextMatchup(match),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.warning.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.warning.withValues(alpha: 0.65),
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                '⏭ Skip (Absent)',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.warning,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerColumn({
    required bool isLeftCorner,
    required String name,
    required int elo,
    required double prKg,
    required double maxLiftKg,
    required int losses,
    required bool isDone,
    required bool isWinner,
    required bool isBye,
    required int eloDelta,
  }) {
    final align =
        isLeftCorner ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    final textAlign = isLeftCorner ? TextAlign.left : TextAlign.right;
    final isEliminated =
        !_isSuperfights && losses >= _maxLossesBeforeElimination;

    // Red Corner (#E23B3B) on Left, 24k Gold (#D4AF37) on Right
    final Color cornerEdgeColor = isLeftCorner
        ? const Color(0xFFE23B3B)
        : const Color(0xFFD4AF37);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDone
            ? (isWinner
                ? AppTheme.emerald.withValues(alpha: 0.14)
                : AppTheme.crimson.withValues(alpha: 0.08))
            : const Color(0xFF11151F),
        borderRadius: BorderRadius.circular(11),
        border: Border(
          left: BorderSide(
            color: isLeftCorner ? cornerEdgeColor : const Color(0x28FFFFFF),
            width: isLeftCorner ? 3.0 : 1.0,
          ),
          right: BorderSide(
            color: !isLeftCorner ? cornerEdgeColor : const Color(0x28FFFFFF),
            width: !isLeftCorner ? 3.0 : 1.0,
          ),
          top: BorderSide(
            color: isDone && isWinner
                ? AppTheme.emerald
                : const Color(0x28FFFFFF),
            width: 1.0,
          ),
          bottom: BorderSide(
            color: isDone && isWinner
                ? AppTheme.emerald
                : const Color(0x28FFFFFF),
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Row(
            mainAxisAlignment: isLeftCorner
                ? MainAxisAlignment.start
                : MainAxisAlignment.end,
            children: [
              Text(
                isLeftCorner ? 'RED CORNER' : 'GOLD CORNER',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  color: cornerEdgeColor,
                  letterSpacing: 0.6,
                ),
              ),
              if (isDone) ...[
                const SizedBox(width: 5),
                Text(
                  isWinner ? '• WIN ✓' : '• LOSS',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    color: isWinner ? AppTheme.emerald : AppTheme.crimson,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 3),
          Text(
            name,
            textAlign: textAlign,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 5),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            alignment:
                isLeftCorner ? WrapAlignment.start : WrapAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.obsidian,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: AppTheme.goldPrimary.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  'ELO $elo',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.goldPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.obsidian,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: AppTheme.cyan.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  'PR ${prKg.toStringAsFixed(0)}kg',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.cyan,
                  ),
                ),
              ),
              if (!_isSuperfights)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isEliminated
                        ? AppTheme.crimson.withValues(alpha: 0.2)
                        : (losses == 0
                            ? AppTheme.emerald.withValues(alpha: 0.16)
                            : AppTheme.warning.withValues(alpha: 0.18)),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: isEliminated
                          ? AppTheme.crimson
                          : (losses == 0
                              ? AppTheme.emerald
                              : AppTheme.warning),
                    ),
                  ),
                  child: Text(
                    isEliminated ? '${losses}L / ELIMINATED' : '${losses}L',
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: isEliminated
                          ? AppTheme.crimson
                          : (losses == 0
                              ? AppTheme.emerald
                              : AppTheme.warning),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

