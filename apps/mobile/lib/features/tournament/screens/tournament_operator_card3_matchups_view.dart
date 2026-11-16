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
        const CrystalSnackBar(
          content: Text(
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
      } else if (secondPlace == null && cId != firstPlace['id']?.toString()) {
        secondPlace = candidate;
      } else if (thirdPlace == null &&
          cId != firstPlace['id']?.toString() &&
          cId != secondPlace['id']?.toString()) {
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
        ? 'SUPERFIGHTS (SINGLE BOUTS)'
        : _eliminationSubFormat.replaceAll('_', ' ');

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space16,
        12,
        AppTheme.space16,
        40,
      ),
      children: [
        // Offline-First Status & Locked Format Indicator (NO Superfights vs Elimination toggle here)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.55)),
          ),
          child: Row(
            children: [
              const Icon(Icons.offline_bolt_rounded,
                  size: 16, color: AppTheme.emerald),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'CARD 3 MATCHUPS • $formatBadgeText • ${widget.autoSaveBannerText}',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontMono,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.emerald,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // =====================================================================
        // AUTOMATIC WINNERS / PODIUM SUMMARY CARD (1ST, 2ND, 3RD PLACE)
        // Automatically shown at the top of the category when the "Final" match is Done!
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
        // 1. MATCHUP CREATION ACTION BAR (SMART RANDOM, MANUAL PAIR & BYE RULE)
        // =====================================================================
        ElevatedActionCard(
          padding: const EdgeInsets.all(14),
          borderColor: AppTheme.goldPrimary.withValues(alpha: 0.6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'MATCHUP ENGINE • $_selectedCategory (${catAthletes.length} Athletes)',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.goldPrimary,
                      ),
                    ),
                  ),
                  if (catAthletes.length % 2 == 1)
                    const StatusChip(
                      label: 'ODD ROSTER • BYE ACTIVE',
                      type: StatusType.warning,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Pair opponents manually or tap "Random Matchups" to pair smartly by Elo, PRs & Max Lift. Odd-numbered rosters automatically assign a BYE (Auto-Advance to Next Round).',
                style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      key: const ValueKey('card3_smart_random_matchups_button'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.goldPrimary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      onPressed: _handleSmartRandomMatchupsForCurrentRound,
                      icon: const Icon(Icons.shuffle_rounded, size: 17),
                      label: const Text(
                        'RANDOM MATCHUPS (BY ELO, PR & LIFT)',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      key: const ValueKey('card3_manual_pair_button'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.cyan,
                        side: const BorderSide(color: AppTheme.cyan),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      onPressed: () => _openManualPairOrByeDialog(),
                      icon:
                          const Icon(Icons.person_add_alt_1_rounded, size: 16),
                      label: const Text(
                        'MANUAL / BYE',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Odd-Number BYE Policy Selector + Quick Final Completion for Podium
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Icon(Icons.fast_forward_rounded,
                      size: 14, color: AppTheme.goldPrimary),
                  const Text(
                    'ODD-NUMBER "BYE" RULE:',
                    style: TextStyle(
                      fontFamily: AppTheme.fontMono,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  ChoiceChip(
                    label: const Text('Auto BYE → Highest Elo/PR',
                        style: TextStyle(fontSize: 10)),
                    selected: _byeAssignmentPolicy == 'HIGHEST_ELO_PR',
                    onSelected: (_) =>
                        setState(() => _byeAssignmentPolicy = 'HIGHEST_ELO_PR'),
                  ),
                  ChoiceChip(
                    label: const Text('Auto BYE → Random',
                        style: TextStyle(fontSize: 10)),
                    selected: _byeAssignmentPolicy == 'RANDOM',
                    onSelected: (_) =>
                        setState(() => _byeAssignmentPolicy = 'RANDOM'),
                  ),
                  if (!isFinalDoneForSelectedCategory)
                    ActionChip(
                      key: const ValueKey('card3_complete_final_podium_button'),
                      avatar: const Icon(Icons.emoji_events_rounded,
                          size: 14, color: AppTheme.goldPrimary),
                      label: const Text(
                        'Complete Final → Show 1st/2nd/3rd Podium',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.goldPrimary,
                        ),
                      ),
                      onPressed: _handleCompleteFinalAndCertifyPodiumNow,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // =====================================================================
        // 2. MULTI-TABLE DYNAMIC FREE-TABLE QUEUE & ABSENT PLAYERS PANEL
        // =====================================================================
        if (_tableCount > 1) ...[
          _buildDynamicFreeTableQueuePanel(roundMatches),
          const SizedBox(height: 14),
        ],

        // =====================================================================
        // 3. CONTEXT-AWARE FILTER BARS
        // =====================================================================
        // 3A. Weight Category Filters
        const Text(
          'WEIGHT CATEGORY FILTERS',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            color: AppTheme.goldPrimary,
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          key: const ValueKey('card3_weight_category_filter_bar'),
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final cat in categories)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      '${_isCategoryFinalCompleted(cat) ? "🏆 " : ""}$cat (${_athletesInCategory(cat).length})',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontWeight: _selectedCategory == cat
                            ? FontWeight.w900
                            : FontWeight.w700,
                        fontSize: 11.5,
                      ),
                    ),
                    selected: _selectedCategory == cat,
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedCategory = cat;
                        _selectedRound = 1;
                        _synchronizeDynamicFreeTableActiveSlots(cat);
                      });
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 3B. Elimination Round Filters (ONLY shown if Elimination format was selected in Card 1; hidden for Superfights)
        if (!_isSuperfights) ...[
          const Text(
            'ELIMINATION ROUND FILTERS (DYNAMIC BY CATEGORY SIZE)',
            style: TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: AppTheme.goldPrimary,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            key: const ValueKey('card3_elimination_round_filter_bar'),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final rt in roundTabs)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        rt['label'].toString(),
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontWeight: _selectedRound == rt['round']
                              ? FontWeight.w900
                              : FontWeight.w700,
                          fontSize: 11.5,
                        ),
                      ),
                      selected: _selectedRound == rt['round'],
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedRound = rt['round'] as int;
                          _synchronizeDynamicFreeTableActiveSlots(
                              _selectedCategory);
                        });
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // 3C. Pairing Status Filters ("Matched Up" vs. "Non-Matched Up") & Completion Status Filters ("Pending", "Done", "All")
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                key: const ValueKey('card3_filter_matched_up'),
                label: Text('Matched Up (${roundMatches.length})'),
                selected: _pairingFilter == 'MATCHED_UP',
                onSelected: (_) =>
                    setState(() => _pairingFilter = 'MATCHED_UP'),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                key: const ValueKey('card3_filter_non_matched_up'),
                label: Text('Non-Matched Up (${nonMatchedAthletes.length})'),
                selected: _pairingFilter == 'NON_MATCHED_UP',
                onSelected: (_) =>
                    setState(() => _pairingFilter = 'NON_MATCHED_UP'),
              ),
              if (_pairingFilter == 'MATCHED_UP') ...[
                const SizedBox(width: 14),
                Container(
                  width: 1,
                  height: 22,
                  color: const Color(0x33FFFFFF),
                ),
                const SizedBox(width: 10),
                for (final comp in [
                  ('ALL', 'All (${roundMatches.length})'),
                  ('PENDING', 'Pending ($pendingInRoundCount)'),
                  ('DONE', 'Done ($doneInRoundCount)'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      key: ValueKey('card3_completion_filter_${comp.$1}'),
                      label: Text(comp.$2, style: const TextStyle(fontSize: 11)),
                      selected: _completionFilter == comp.$1,
                      onSelected: (_) =>
                          setState(() => _completionFilter = comp.$1),
                    ),
                  ),
              ],
            ],
          ),
        ),

        // 3D. Table Filters (ONLY shown when No. of Tables > 1)
        if (_tableCount > 1) ...[
          const SizedBox(height: 10),
          SingleChildScrollView(
            key: const ValueKey('card3_table_filter_bar'),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label:
                      const Text('All Tables', style: TextStyle(fontSize: 11)),
                  selected: _selectedTableFilter == 'ALL',
                  onSelected: (_) =>
                      setState(() => _selectedTableFilter = 'ALL'),
                ),
                const SizedBox(width: 6),
                for (final tName in _tableNames)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(tName, style: const TextStyle(fontSize: 11)),
                      selected: _selectedTableFilter == tName,
                      onSelected: (_) =>
                          setState(() => _selectedTableFilter = tName),
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),

        // =====================================================================
        // 4. ROUND LOCKING & OPERATOR "NEXT ROUND & CANCEL PENDING" OVERRIDE
        // =====================================================================
        if (!_isSuperfights) ...[
          _buildRoundLockAndOverrideBanner(
            roundTabs: roundTabs,
            doneCount: doneInRoundCount,
            pendingCount: pendingInRoundCount,
            isCurrentRoundSubmissionAllowed: isCurrentRoundSubmissionAllowed,
          ),
          const SizedBox(height: 14),
        ],

        // =====================================================================
        // 5. MATCHED UP LIST OR NON-MATCHED UP LIST
        // =====================================================================
        if (_pairingFilter == 'NON_MATCHED_UP')
          _buildNonMatchedUpAthletesList(nonMatchedAthletes)
        else if (completionFilteredMatches.isEmpty)
          ElevatedActionCard(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedRound > 1 && !isCurrentRoundSubmissionAllowed
                      ? 'Next Round Preview: Complete or submit matches in Round ${_selectedRound - 1} (or tap "Next Round Matchups & Cancel Any Left Pending" above) to populate and unlock Round $_selectedRound matchups.'
                      : 'No matchups match the current filter in $_selectedCategory.',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _handleSmartRandomMatchupsForCurrentRound,
                  icon: const Icon(Icons.shuffle_rounded, size: 16),
                  label: const Text('GENERATE SMART RANDOM MATCHUPS NOW'),
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

  /// DYNAMIC FREE-TABLE QUEUE & ABSENT PLAYERS PANEL (When Tables > 1)
  Widget _buildDynamicFreeTableQueuePanel(
    List<Map<String, dynamic>> roundMatches,
  ) {
    final pendingMatches = roundMatches
        .where((m) =>
            m['isBye'] != true &&
            (m['status'] ?? 'PENDING').toString().toUpperCase() == 'PENDING')
        .toList();

    final lastSummary = _matchupsState['lastAutoAssignedSummary']?.toString();

    return ElevatedActionCard(
      key: const ValueKey('card3_dynamic_free_table_queue_panel'),
      padding: const EdgeInsets.all(14),
      borderColor: AppTheme.cyan.withValues(alpha: 0.65),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.table_restaurant_rounded,
                  size: 17, color: AppTheme.cyan),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'MULTI-TABLE LIVE DECK & DYNAMIC FREE-TABLE QUEUE (${_tableCount} TABLES)',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.cyan,
                  ),
                ),
              ),
              StatusChip(
                label: _isDynamicFreeTableMode
                    ? 'DYNAMIC FREE-TABLE ON'
                    : _tableAssignmentMode.replaceAll('_', ' '),
                type: StatusType.info,
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'When a match finishes, its table is marked Freed and the next queued matchup is automatically assigned to that table. If selected athletes are absent at the table, tap "Skip for Now / Play Next Matchup" so the next ready pair plays immediately while the absent matchup stays queued right after them.',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          if (lastSummary != null && lastSummary.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.emerald.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppTheme.emerald.withValues(alpha: 0.55)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded,
                      size: 16, color: AppTheme.emerald),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      lastSummary,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontMono,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.emerald,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final tName in _tableNames)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
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
    final nextInQueue =
        tablePending.length > 1 ? tablePending[1] : pendingMatches
            .where((m) => m['id'] != activeMatch?['id'])
            .firstOrNull;

    return Container(
      width: 265,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0x16FFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: activeMatch != null
              ? AppTheme.cyan.withValues(alpha: 0.65)
              : AppTheme.emerald.withValues(alpha: 0.65),
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
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.goldPrimary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: activeMatch != null
                      ? AppTheme.cyan.withValues(alpha: 0.2)
                      : AppTheme.emerald.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  activeMatch != null
                      ? 'ON TABLE • MATCH #${activeMatch['matchIndex']}'
                      : 'TABLE FREE ✓',
                  style: TextStyle(
                    fontFamily: AppTheme.fontMono,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color:
                        activeMatch != null ? AppTheme.cyan : AppTheme.emerald,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (activeMatch != null) ...[
            Text(
              '${activeMatch['athleteAName']} vs. ${activeMatch['athleteBName']}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              nextInQueue != null
                  ? 'Next Queued: #${nextInQueue['matchIndex']} (${nextInQueue['athleteAName']} vs. ${nextInQueue['athleteBName']})'
                  : 'Next Queued: No other pending matchups waiting',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppTheme.fontMono,
                fontSize: 9.5,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: ValueKey('card3_table_skip_absent_${tableName.replaceAll(' ', '_')}'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.warning,
                  side: const BorderSide(color: AppTheme.warning),
                  minimumSize: const Size(0, 30),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                onPressed: () =>
                    _handleSkipAbsentAndPlayNextMatchup(activeMatch),
                icon: const Icon(Icons.skip_next_rounded, size: 13),
                label: const Text(
                  'SKIP FOR NOW / PLAY NEXT MATCHUP',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ] else ...[
            const Text(
              'Table is Freed and ready for the next round or manual assignment.',
              style: TextStyle(fontSize: 10.5, color: AppTheme.emerald),
            ),
          ],
        ],
      ),
    );
  }

  /// AUTOMATIC CATEGORY WINNERS / PODIUM SUMMARY CARD (1ST, 2ND, 3RD PLACE)
  Widget _buildCategoryPodiumSummaryCard({
    required String categoryLabel,
    required List<Map<String, dynamic>> podium,
  }) {
    final winnerStructure =
        (_awardsConfig['winnerStructure'] ?? 'PER_CATEGORY_WINNERS')
            .toString()
            .toUpperCase();
    final rewardType =
        (_awardsConfig['rewardType'] ?? 'CASH_AND_AWARDS').toString();

    return ElevatedActionCard(
      key: ValueKey('card3_category_podium_summary_$categoryLabel'),
      padding: const EdgeInsets.all(16),
      borderColor: AppTheme.goldPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded,
                  size: 22, color: AppTheme.goldPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FINAL COMPLETED • CATEGORY WINNERS & PODIUM SUMMARY',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontMono,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.emerald,
                      ),
                    ),
                    Text(
                      '$categoryLabel — OFFICIAL PODIUM (1ST, 2ND, 3RD PLACE)',
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
                label: 'FINAL DONE ✓',
                type: StatusType.success,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Connected directly to Card 1 Awards & Prizes (${rewardType.replaceAll('_', ' ')} • ${winnerStructure.replaceAll('_', ' ')}).',
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          for (final p in podium) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: p['position'] == 1
                    ? AppTheme.goldPrimary.withValues(alpha: 0.16)
                    : (p['position'] == 2
                        ? AppTheme.cyan.withValues(alpha: 0.12)
                        : const Color(0x16FFFFFF)),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: p['position'] == 1
                      ? AppTheme.goldPrimary
                      : (p['position'] == 2
                          ? AppTheme.cyan.withValues(alpha: 0.7)
                          : const Color(0x44FFFFFF)),
                  width: p['position'] == 1 ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p['position'] == 1
                          ? AppTheme.goldPrimary
                          : (p['position'] == 2
                              ? AppTheme.cyan
                              : AppTheme.warning),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '#${p['position']}',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${p['title']} • ${p['athleteName']}',
                          style: const TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${p['clubName']} • ${p['eloRating']} ELO • PR ${p['prKg']}kg • Lift ${p['maxLiftKg']}kg',
                          style: const TextStyle(
                            fontFamily: AppTheme.fontMono,
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.emerald.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.emerald),
                    ),
                    child: Text(
                      p['prizeDescription'].toString(),
                      style: const TextStyle(
                        fontFamily: AppTheme.fontMono,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.emerald,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// OVERALL TOURNAMENT WINNERS SUMMARY CARD (Shown when Card 1 configured OVERALL_WINNERS)
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
                  'OVERALL TOURNAMENT WINNERS PODIUM (CARD 1 OVERALL PRIZE STRUCTURE)',
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
                      'Overall #${i + 1}: ${topOverall[i]['athleteName']} (${topOverall[i]['categoryLabel']} • ${topOverall[i]['eloRating']} ELO)',
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
                      fontFamily: AppTheme.fontMono,
                      fontSize: 10.5,
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

  Widget _buildRoundLockAndOverrideBanner({
    required List<Map<String, dynamic>> roundTabs,
    required int doneCount,
    required int pendingCount,
    required bool isCurrentRoundSubmissionAllowed,
  }) {
    final canAdvanceToNextRound = _selectedRound < roundTabs.length;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentRoundSubmissionAllowed
            ? AppTheme.emerald.withValues(alpha: 0.1)
            : AppTheme.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrentRoundSubmissionAllowed
              ? AppTheme.emerald.withValues(alpha: 0.6)
              : AppTheme.warning,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCurrentRoundSubmissionAllowed
                    ? Icons.lock_open_rounded
                    : Icons.lock_clock_rounded,
                size: 17,
                color: isCurrentRoundSubmissionAllowed
                    ? AppTheme.emerald
                    : AppTheme.warning,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isCurrentRoundSubmissionAllowed
                      ? 'ROUND $_selectedRound ACTIVE • $doneCount DONE / $pendingCount PENDING'
                      : 'ROUND $_selectedRound RESULT SUBMISSION LOCKED (PREVIOUS ROUND HAS PENDING MATCHES)',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: isCurrentRoundSubmissionAllowed
                        ? AppTheme.emerald
                        : AppTheme.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isCurrentRoundSubmissionAllowed
                ? 'As results are submitted, surviving athletes automatically build and update Round ${_selectedRound + 1} matchups by Elo, PRs & Max Lift.'
                : 'Default Rule: Next round matchups are pre-built dynamically, but result submission waits until previous round matches finish OR you click Operator Override below.',
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          if (canAdvanceToNextRound && (pendingCount > 0 || doneCount > 0)) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                key: const ValueKey(
                    'card3_next_round_cancel_pending_override_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warning,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: _handleNextRoundAndCancelPendingOverride,
                icon: const Icon(Icons.skip_next_rounded, size: 18),
                label: Text(
                  pendingCount > 0
                      ? 'NEXT ROUND MATCHUPS & CANCEL ANY LEFT PENDING ($pendingCount PENDING)'
                      : 'OPEN NEXT ROUND MATCHUPS (ROUND ${_selectedRound + 1}) →',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
          if (!isCurrentRoundSubmissionAllowed) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.goldPrimary,
                  side: const BorderSide(color: AppTheme.goldPrimary),
                ),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  setState(() {
                    _markRoundUnlockedByOverride(
                        _selectedCategory, _selectedRound);
                  });
                },
                icon: const Icon(Icons.lock_open_rounded, size: 16),
                label: Text(
                  'OPERATOR OVERRIDE: ALLOW ROUND $_selectedRound RESULT SUBMISSIONS NOW',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNonMatchedUpAthletesList(
    List<Map<String, dynamic>> nonMatchedAthletes,
  ) {
    if (nonMatchedAthletes.isEmpty) {
      return ElevatedActionCard(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: const Text(
          'All eligible athletes in this category and round are currently Matched Up (or assigned a BYE).',
          style: TextStyle(fontSize: 12, color: AppTheme.emerald),
        ),
      );
    }

    return Column(
      children: [
        for (final a in nonMatchedAthletes) ...[
          ElevatedActionCard(
            padding: const EdgeInsets.all(14),
            borderColor: AppTheme.warning.withValues(alpha: 0.6),
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
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${a['eloRating']} ELO • PR: ${a['prKg']} kg • Max Lift: ${a['maxLiftKg']} kg',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontMono,
                          fontSize: 11,
                          color: AppTheme.cyan,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.goldPrimary,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () => _openManualPairOrByeDialog(
                    preselectedAthleteAId: a['id'].toString(),
                  ),
                  child: const Text(
                    'PAIR / ASSIGN BYE',
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
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

  /// Matchup Card UI with Left-vs-Right Athlete Layout, Elo, PR/Max Lift badge,
  /// Assigned Table badge + Manual Table Reassignment, Dynamic Free-Table "Skip for Now / Play Next Matchup",
  /// Superfight Point Transfer badge, and Elimination Loss Counter badges.
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

    Color borderColor = AppTheme.border;
    if (isBye) {
      borderColor = AppTheme.goldPrimary.withValues(alpha: 0.75);
    } else if (isDone) {
      borderColor = AppTheme.emerald.withValues(alpha: 0.7);
    } else if (isCancelled) {
      borderColor = AppTheme.crimson.withValues(alpha: 0.55);
    } else if (tableQueueStatus == 'DEFERRED_PLAYS_NEXT') {
      borderColor = AppTheme.warning.withValues(alpha: 0.75);
    } else {
      borderColor = AppTheme.cyan.withValues(alpha: 0.55);
    }

    return ElevatedActionCard(
      padding: const EdgeInsets.all(14),
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Row: Bout # + Assigned Table Badge + Queue Status + Status Badge + Edit/Swap Button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.goldPrimary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: AppTheme.goldPrimary.withValues(alpha: 0.55)),
                ),
                child: Text(
                  _isSuperfights
                      ? 'SUPERFIGHT #$matchIndex'
                      : 'R$roundNumber • MATCH #$matchIndex',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontMono,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.goldPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Clearly show Assigned Table Badge ("Table 1", "Table 2", etc.) on every matchup card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.cyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border:
                      Border.all(color: AppTheme.cyan.withValues(alpha: 0.55)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.table_bar_rounded,
                        size: 11, color: AppTheme.cyan),
                    const SizedBox(width: 4),
                    Text(
                      tableBadge.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: AppTheme.fontMono,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.cyan,
                      ),
                    ),
                  ],
                ),
              ),
              if (_tableCount > 1 && !isDone && !isBye && !isCancelled) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: tableQueueStatus == 'ACTIVE_AT_TABLE'
                        ? AppTheme.emerald.withValues(alpha: 0.16)
                        : (tableQueueStatus == 'DEFERRED_PLAYS_NEXT'
                            ? AppTheme.warning.withValues(alpha: 0.18)
                            : const Color(0x18FFFFFF)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tableQueueStatus == 'ACTIVE_AT_TABLE'
                        ? 'ON TABLE NOW'
                        : (tableQueueStatus == 'DEFERRED_PLAYS_NEXT'
                            ? 'DEFERRED • PLAYS NEXT'
                            : 'QUEUED'),
                    style: TextStyle(
                      fontFamily: AppTheme.fontMono,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      color: tableQueueStatus == 'ACTIVE_AT_TABLE'
                          ? AppTheme.emerald
                          : (tableQueueStatus == 'DEFERRED_PLAYS_NEXT'
                              ? AppTheme.warning
                              : AppTheme.textSecondary),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              StatusChip(
                label: isBye
                    ? 'BYE • AUTO-ADVANCE'
                    : (isDone
                        ? 'DONE ✓'
                        : (isCancelled ? 'CANCELLED (PENDING)' : 'PENDING')),
                type: isBye
                    ? StatusType.warning
                    : (isDone
                        ? StatusType.success
                        : (isCancelled
                            ? StatusType.error
                            : StatusType.info)),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Edit / Swap Matchup or Assign BYE',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
                icon: const Icon(Icons.swap_horiz_rounded,
                    size: 18, color: AppTheme.goldPrimary),
                onPressed: () => _openEditOrSwapMatchupDialog(match),
              ),
            ],
          ),

          // Deferred / Auto-Assigned Queue Notice Banner (if applicable)
          if (deferredNote != null && deferredNote.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border:
                    Border.all(color: AppTheme.warning.withValues(alpha: 0.45)),
              ),
              child: Text(
                deferredNote,
                style: const TextStyle(
                  fontFamily: AppTheme.fontMono,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.warning,
                ),
              ),
            ),
          ],

          // MULTI-TABLE MANUAL TABLE REASSIGNMENT BAR (When Tables > 1)
          if (_tableCount > 1) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text(
                    'ASSIGNED TABLE (TAP TO CHANGE):',
                    style: TextStyle(
                      fontFamily: AppTheme.fontMono,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  for (final tName in _tableNames)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        key: ValueKey(
                            'card3_reassign_${match['id']}_${tName.replaceAll(' ', '_')}'),
                        label: Text(
                          tName,
                          style: TextStyle(
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
          const SizedBox(height: 10),

          // Left-vs-Right Athlete Layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT CORNER (ATHLETE A)
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

              // CENTER VS / POINT TRANSFER BADGE
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0x22FFFFFF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isBye ? 'BYE' : 'VS',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.goldPrimary,
                        ),
                      ),
                    ),
                    if (isDone && !isBye && _isSuperfights) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.goldPrimary.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                              color:
                                  AppTheme.goldPrimary.withValues(alpha: 0.6)),
                        ),
                        child: Text(
                          aIsWinner
                              ? '+$eloDelta ← -$eloDelta PTS'
                              : '-$eloDelta → +$eloDelta PTS',
                          style: const TextStyle(
                            fontFamily: AppTheme.fontMono,
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

              // RIGHT CORNER (ATHLETE B OR BYE)
              Expanded(
                child: isBye
                    ? Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.goldPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color:
                                  AppTheme.goldPrimary.withValues(alpha: 0.55)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'BYE (AUTO-ADVANCE)',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.goldPrimary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Odd-number bracket slot. Athlete automatically advances to the next round.',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 10.5,
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

          // Result Submission Controls + Absent Players "Skip for Now / Play Next Matchup"
          if (!isBye) ...[
            const SizedBox(height: 12),
            const Divider(color: Color(0x22FFFFFF), height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: aIsWinner
                          ? AppTheme.emerald.withValues(alpha: 0.2)
                          : Colors.transparent,
                      foregroundColor: aIsWinner
                          ? AppTheme.emerald
                          : (isSubmissionAllowed
                              ? AppTheme.textPrimary
                              : AppTheme.textMuted),
                      side: BorderSide(
                        color: aIsWinner
                            ? AppTheme.emerald
                            : const Color(0x44FFFFFF),
                      ),
                      minimumSize: const Size(0, 34),
                    ),
                    onPressed: () =>
                        _submitMatchWinner(match: match, winnerId: aId),
                    icon: Icon(
                      aIsWinner
                          ? Icons.emoji_events_rounded
                          : Icons.check_circle_outline_rounded,
                      size: 14,
                    ),
                    label: Text(
                      aIsWinner
                          ? 'WINNER: ${match['athleteAName']}'
                          : 'WIN: ${match['athleteAName']}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: bIsWinner
                          ? AppTheme.emerald.withValues(alpha: 0.2)
                          : Colors.transparent,
                      foregroundColor: bIsWinner
                          ? AppTheme.emerald
                          : (isSubmissionAllowed
                              ? AppTheme.textPrimary
                              : AppTheme.textMuted),
                      side: BorderSide(
                        color: bIsWinner
                            ? AppTheme.emerald
                            : const Color(0x44FFFFFF),
                      ),
                      minimumSize: const Size(0, 34),
                    ),
                    onPressed: () =>
                        _submitMatchWinner(match: match, winnerId: bId),
                    icon: Icon(
                      bIsWinner
                          ? Icons.emoji_events_rounded
                          : Icons.check_circle_outline_rounded,
                      size: 14,
                    ),
                    label: Text(
                      bIsWinner
                          ? 'WINNER: ${match['athleteBName']}'
                          : 'WIN: ${match['athleteBName']}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // ABSENT / NOT PRESENT PLAYERS ACTION BUTTON (When Pending)
            if (!isDone && !isCancelled) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: ValueKey('card3_skip_absent_play_next_${match['id']}'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.warning,
                    side: BorderSide(
                        color: AppTheme.warning.withValues(alpha: 0.7)),
                    minimumSize: const Size(0, 32),
                  ),
                  onPressed: () => _handleSkipAbsentAndPlayNextMatchup(match),
                  icon: const Icon(Icons.skip_next_rounded, size: 15),
                  label: Text(
                    'ATHLETES ABSENT AT $tableBadge? SKIP FOR NOW / PLAY NEXT MATCHUP (QUEUED RIGHT AFTER)',
                    style: const TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ],
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

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDone
            ? (isWinner
                ? AppTheme.emerald.withValues(alpha: 0.14)
                : AppTheme.crimson.withValues(alpha: 0.1))
            : const Color(0x12FFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDone
              ? (isWinner
                  ? AppTheme.emerald
                  : AppTheme.crimson.withValues(alpha: 0.55))
              : const Color(0x28FFFFFF),
          width: (isDone && isWinner) ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: align,
        children: [
          // Winner / Loss Highlight Badge (Superfights & Completed Bouts)
          if (isDone) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isWinner
                    ? AppTheme.emerald.withValues(alpha: 0.22)
                    : AppTheme.crimson.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isBye
                    ? 'AUTO-ADVANCE ✓'
                    : (_isSuperfights
                        ? (isWinner
                            ? 'WINNER (+$eloDelta ELO)'
                            : 'LOSS (-$eloDelta ELO)')
                        : (isWinner ? 'WINNER ✓' : 'LOSS')),
                style: TextStyle(
                  fontFamily: AppTheme.fontMono,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: isWinner ? AppTheme.emerald : AppTheme.crimson,
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],

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
          const SizedBox(height: 4),

          // Elo Rating + Elimination Loss Counter Badge ("0L", "1L", "2L", "Eliminated")
          Wrap(
            spacing: 4,
            runSpacing: 4,
            alignment:
                isLeftCorner ? WrapAlignment.start : WrapAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.goldPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$elo ELO',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontMono,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.goldPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              if (!_isSuperfights)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isEliminated
                        ? AppTheme.crimson.withValues(alpha: 0.22)
                        : (losses == 0
                            ? AppTheme.emerald.withValues(alpha: 0.18)
                            : AppTheme.warning.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isEliminated
                          ? AppTheme.crimson
                          : (losses == 0
                              ? AppTheme.emerald
                              : AppTheme.warning),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    isEliminated ? '${losses}L • ELIMINATED' : '${losses}L',
                    style: TextStyle(
                      fontFamily: AppTheme.fontMono,
                      fontSize: 9.5,
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
          const SizedBox(height: 4),

          // PR & Max Lift Badge
          Text(
            'PR: ${prKg.toStringAsFixed(0)}kg • Lift: ${maxLiftKg.toStringAsFixed(0)}kg',
            textAlign: textAlign,
            style: const TextStyle(
              fontFamily: AppTheme.fontMono,
              fontSize: 9.5,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
