import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/providers/dependency_providers.dart';
import '../../../core/providers/tournament_provider.dart';
import '../../../core/security/admin_permissions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/crystal_glass_nav_controls.dart';
import '../../../core/widgets/crystal_slash_painter.dart';
import '../../../core/widgets/crystal_stage_scaffold.dart';
import '../../../core/widgets/crystal_toast.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/main_shell_screen.dart';
import '../../../core/widgets/skeleton_placeholder.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/tournament_offline_store.dart';
import 'tournament_operator_card3_matchups_view.dart';
import 'tournament_operator_hub_cards_views.dart';

const List<String> _kPakistanProvinces = [
  'Punjab',
  'Sindh',
  'KPK',
  'Balochistan',
  'Islamabad',
  'Gilgit-Baltistan',
  'Azad Kashmir',
];

const List<Map<String, String>> _kDefaultRefereePool = [
  {'id': 'ref-pk-01', 'name': 'Zubair Qureshi', 'badge': 'WAF Master Referee • Punjab'},
  {'id': 'ref-pk-02', 'name': 'Bilal Mengal', 'badge': 'National Senior • Balochistan'},
  {'id': 'ref-pk-03', 'name': 'Tariq Mehmood', 'badge': 'National Class A • Sindh'},
  {'id': 'ref-pk-04', 'name': 'Kamran Afridi', 'badge': 'National Class A • KPK'},
  {'id': 'ref-pk-05', 'name': 'Hassan Raza', 'badge': 'Provincial Official • Islamabad'},
  {'id': 'ref-pk-06', 'name': 'Usman Ghani', 'badge': 'Provincial Official • Punjab'},
  {'id': 'ref-pk-07', 'name': 'Faisal Shah', 'badge': 'National Senior • Sindh'},
  {'id': 'ref-pk-08', 'name': 'Noman Khattak', 'badge': 'Provincial Official • KPK'},
];

enum _OperatorSubView {
  mainList,
  tournamentHub,
  card1BasicDetails,
  awardsPrizesSubScreen,
  card2AppliedAthletes,
  card3MatchupsBrackets,
  card4WeighInVerification,
  spectatorEntranceQrGate,
}

/// Tournament Operator System — Step 1 Complete Implementation
///
/// 1. Operator Main Screen:
///    - Prominent "Create Tournament" button.
///    - Top List (Upcoming / Active + Unreleased Operator Drafts).
///    - Bottom List (Previous Completed Tournaments).
/// 2. Tournament Hub Screen & Strict Draft / Release Locking Flow:
///    - 4 Bold Dashboard Card Buttons with live status badges:
///      * Card 1: Basic & Mandatory Details
///      * Card 2: Applied / Registered Athletes (LOCKED until Card 1 is 100% complete AND "Release / Schedule" is clicked)
///      * Card 3: Matchups & Brackets (LOCKED until Card 1 is 100% complete AND "Release / Schedule" is clicked)
///      * Card 4: Weigh-In Verification (LOCKED until Card 1 is 100% complete AND "Release / Schedule" is clicked)
/// 3. Card 1 — Basic & Mandatory Details Screen (with instant offline-first auto-saving draft protection):
///    - Basic Info (Event Name, Schedule/Date & Time, Organization, Venue Location, Max Athletes)
///    - Weight Categories & Arm/Hand Support (70 kg, 80 kg, 90 kg, Open + custom, with Right Arm / Left Arm / Both separation)
///    - Mandatory Tournament / Match Format Type (Superfights vs Elimination: Single, Double, Three-Loss, Last-One-Standing)
///    - Number of Tables & Mandatory Table Assignment Mode (> 1 tables: Category-by-Table, Random by App, Dynamic Free-Table Queue)
///    - Mandatory Referee Selection (min 2 referees per table)
///    - Mandatory Entry / Application Fee in PKR (0 for free or any PKR amount)
///    - Separate Awards & Prizes Sub-Screen with checkmark (✓) once configured
///    - "Release / Schedule" button
class TournamentOperatorDashboardScreen extends ConsumerStatefulWidget {
  const TournamentOperatorDashboardScreen({super.key});

  @override
  ConsumerState<TournamentOperatorDashboardScreen> createState() =>
      _TournamentOperatorDashboardScreenState();
}

class _TournamentOperatorDashboardScreenState
    extends ConsumerState<TournamentOperatorDashboardScreen> {
  _OperatorSubView _activeView = _OperatorSubView.mainList;
  String? _selectedTournamentId;
  String? _selectedAthleteIdForWeighIn;
  String? _lastUserId;
  String _autoSaveBannerText = 'Saved locally • Offline-Ready';

  // Local Offline-First Drafts & Tournaments Cache (scoped per operator ID)
  final Map<String, Map<String, Map<String, dynamic>>> _operatorDraftStore = {};

  String _resolveOperatorId(Map<String, dynamic> profile) {
    return (profile['id'] ?? profile['userId'] ?? 'operator_default')
        .toString()
        .trim();
  }

  String _hiveDraftsKey(String operatorId) =>
      'operator_step1_tournaments_$operatorId';

  Map<String, Map<String, dynamic>> _loadOperatorLocalMap(String operatorId) {
    if (_operatorDraftStore.containsKey(operatorId)) {
      return _operatorDraftStore[operatorId]!;
    }
    final map = <String, Map<String, dynamic>>{};
    try {
      final hive = ref.read(hiveStorageProvider);
      final raw = hive.getCachedData(_hiveDraftsKey(operatorId));
      if (raw is List) {
        for (final item in raw) {
          if (item is Map) {
            final m = Map<String, dynamic>.from(item);
            final id = m['id']?.toString();
            if (id != null && id.isNotEmpty) {
              map[id] = m;
            }
          }
        }
      }
    } catch (_) {
      // Hive may not be initialized in unit/widget tests; memory map fallback works seamlessly
    }
    _operatorDraftStore[operatorId] = map;
    return map;
  }

  Future<void> _persistOperatorLocalMap(String operatorId) async {
    final map = _loadOperatorLocalMap(operatorId);
    try {
      final hive = ref.read(hiveStorageProvider);
      await hive.cacheData(
        _hiveDraftsKey(operatorId),
        map.values.toList(),
      );
    } catch (_) {}
  }

  Map<String, dynamic> _createFreshDraft(
    String operatorId,
    Map<String, dynamic> profile,
  ) {
    final now = DateTime.now();
    final start = now.add(const Duration(days: 14));
    final id = 'draft_${now.millisecondsSinceEpoch}';
    return <String, dynamic>{
      'id': id,
      'organizerId': operatorId,
      'name': '',
      'organizationName': (profile['organizationName'] ??
              profile['displayName'] ??
              profile['name'] ??
              '')
          .toString(),
      'venue': '',
      'city': (profile['city'] ?? 'Lahore').toString(),
      'province': (profile['province'] ?? 'Punjab').toString(),
      'startDate': start.toIso8601String(),
      'endDate': start.add(const Duration(hours: 8)).toIso8601String(),
      'capacity': 64,
      'weightCategories': <Map<String, dynamic>>[
        {'id': 'wc-70', 'label': '70 kg', 'enabled': true, 'arm': 'BOTH'},
        {'id': 'wc-80', 'label': '80 kg', 'enabled': true, 'arm': 'BOTH'},
        {'id': 'wc-90', 'label': '90 kg', 'enabled': true, 'arm': 'RIGHT'},
        {'id': 'wc-open', 'label': 'Open', 'enabled': true, 'arm': 'RIGHT'},
      ],
      'formatCategory': '', // 'SUPERFIGHTS' | 'ELIMINATION'
      'eliminationSubFormat': '', // 'SINGLE_ELIMINATION' | 'DOUBLE_ELIMINATION' | 'THREE_LOSS_ELIMINATION' | 'LAST_ONE_STANDING'
      'tableCount': 1,
      'tableAssignmentMode': 'SINGLE_TABLE_DEFAULT',
      'tables': <Map<String, dynamic>>[
        {
          'tableNumber': 1,
          'tableName': 'Table 1',
          'assignedCategoryDivisionIds': <String>[],
          'assignedRefereeIds': <String>[],
        },
      ],
      'entryFeePkr': null,
      'entryFeeConfigured': false,
      'awardsConfig': <String, dynamic>{
        'isConfigured': false,
        'rewardType': 'CASH_PKR', // 'CASH_PKR' | 'AWARDS' | 'CASH_AND_AWARDS'
        'winnerStructure': 'PER_CATEGORY_WINNERS', // 'OVERALL_WINNERS' | 'PER_CATEGORY_WINNERS'
        'topNCount': 3,
        'tiers': <Map<String, dynamic>>[
          {
            'position': 1,
            'label': '1st Place Winner',
            'cashAmountPkr': 25000,
            'awardTitle': 'Gold Medal & Champion Shield',
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
      },
      'status': 'DRAFT',
      'isReleased': false,
      'syncState': 'SAVED_LOCAL',
      'updatedAt': now.toIso8601String(),
    };
  }

  /// Normalizes a server or local tournament map into a full Step 1 record.
  Map<String, dynamic> _normalizeTournamentRecord(
    Map<String, dynamic> raw,
    String operatorId,
  ) {
    final step1 = raw['step1Config'] is Map
        ? Map<String, dynamic>.from(raw['step1Config'] as Map)
        : <String, dynamic>{};
    final merged = <String, dynamic>{
      ...step1,
      ...raw,
    };

    final statusUpper = (merged['status'] ?? 'DRAFT').toString().toUpperCase();
    final isReleased = merged['isReleased'] == true ||
        (statusUpper != 'DRAFT' && statusUpper != 'UNRELEASED');

    final weightCategories = (merged['weightCategories'] is List)
        ? (merged['weightCategories'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList()
        : <Map<String, dynamic>>[
            {'id': 'wc-70', 'label': '70 kg', 'enabled': true, 'arm': 'BOTH'},
            {'id': 'wc-80', 'label': '80 kg', 'enabled': true, 'arm': 'BOTH'},
            {'id': 'wc-90', 'label': '90 kg', 'enabled': true, 'arm': 'RIGHT'},
            {'id': 'wc-open', 'label': 'Open', 'enabled': true, 'arm': 'RIGHT'},
          ];

    final int tableCount = ((merged['tableCount'] as num?)?.toInt() ?? 1).clamp(1, 12);
    final existingTables = (merged['tables'] is List)
        ? (merged['tables'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList()
        : <Map<String, dynamic>>[];

    final normalizedTables = <Map<String, dynamic>>[];
    for (int i = 1; i <= tableCount; i++) {
      final found = existingTables.where((t) => t['tableNumber'] == i).firstOrNull;
      normalizedTables.add({
        'tableNumber': i,
        'tableName': found?['tableName']?.toString() ?? 'Table $i',
        'assignedCategoryDivisionIds': found?['assignedCategoryDivisionIds'] is List
            ? List<String>.from(found!['assignedCategoryDivisionIds'] as List)
            : <String>[],
        'assignedRefereeIds': found?['assignedRefereeIds'] is List
            ? List<String>.from(found!['assignedRefereeIds'] as List)
            : (isReleased ? <String>['ref-pk-01', 'ref-pk-02'] : <String>[]),
      });
    }

    final feeCents = (merged['registrationFeeCents'] as num?)?.toInt();
    final entryFeePkr = merged['entryFeePkr'] ??
        (feeCents != null ? (feeCents / 100).round() : (isReleased ? 0 : null));
    final entryFeeConfigured =
        merged['entryFeeConfigured'] == true || isReleased || entryFeePkr != null;

    final awardsConfig = merged['awardsConfig'] is Map
        ? Map<String, dynamic>.from(merged['awardsConfig'] as Map)
        : <String, dynamic>{
            'isConfigured': isReleased,
            'rewardType': 'CASH_PKR',
            'winnerStructure': 'PER_CATEGORY_WINNERS',
            'topNCount': 3,
            'tiers': <Map<String, dynamic>>[
              {
                'position': 1,
                'label': '1st Place Winner',
                'cashAmountPkr': 25000,
                'awardTitle': 'Gold Medal',
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

    final spectatorGateConfig = merged['spectatorGateConfig'] is Map
        ? Map<String, dynamic>.from(merged['spectatorGateConfig'] as Map)
        : <String, dynamic>{
            'spectatorAccessMode': 'FREE', // 'FREE' | 'PAID'
            'spectatorFeePkr': 0,
            'allowedGuestsPerAthlete': 2, // 0, 2, 3, 4
            'entranceCheckInLog': <Map<String, dynamic>>[],
          };

    final normalizedBase = <String, dynamic>{
      ...merged,
      'id': (merged['id'] ?? 'draft_unknown').toString(),
      'organizerId': (merged['organizerId'] ?? operatorId).toString(),
      'name': (merged['name'] ?? '').toString(),
      'organizationName': (merged['organizationName'] ??
              (isReleased ? 'Sanctioned Federation Promotion' : ''))
          .toString(),
      'venue': (merged['venue'] ?? merged['city'] ?? '').toString(),
      'city': (merged['city'] ?? 'Lahore').toString(),
      'province': (merged['province'] ?? 'Punjab').toString(),
      'capacity': (merged['capacity'] as num?)?.toInt() ?? 64,
      'weightCategories': weightCategories,
      'formatCategory': (merged['formatCategory'] ??
              (isReleased ? 'ELIMINATION' : ''))
          .toString(),
      'eliminationSubFormat': (merged['eliminationSubFormat'] ??
              (isReleased ? 'DOUBLE_ELIMINATION' : ''))
          .toString(),
      'tableCount': tableCount,
      'tableAssignmentMode': (merged['tableAssignmentMode'] ??
              (tableCount == 1
                  ? 'SINGLE_TABLE_DEFAULT'
                  : (isReleased ? 'DYNAMIC_FREE_TABLE_QUEUE' : '')))
          .toString(),
      'tables': normalizedTables,
      'entryFeePkr': entryFeePkr,
      'entryFeeConfigured': entryFeeConfigured,
      'awardsConfig': awardsConfig,
      'spectatorGateConfig': spectatorGateConfig,
      'status': statusUpper,
      'isReleased': isReleased,
    };

    final existingAthletes = (merged['appliedAthletes'] is List)
        ? (merged['appliedAthletes'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];

    normalizedBase['appliedAthletes'] = existingAthletes.isNotEmpty
        ? existingAthletes
        : (isReleased
            ? _seedDefaultAppliedAthletes(normalizedBase)
            : <Map<String, dynamic>>[]);

    return normalizedBase;
  }

  List<Map<String, dynamic>> _seedDefaultAppliedAthletes(
    Map<String, dynamic> tournament,
  ) {
    final divisions = _expandSeparatedDivisions(tournament);
    final divLabels = divisions.isNotEmpty
        ? divisions.map((d) => d['label'] ?? '70 kg • Right Arm').toList()
        : <String>[
            '70 kg • Right Arm',
            '70 kg • Left Arm',
            '80 kg • Right Arm',
            '80 kg • Left Arm',
            '90 kg • Right Arm',
            'Open • Right Arm',
          ];

    String pickDiv(int idx) => divLabels[idx % divLabels.length];

    final templates = <Map<String, dynamic>>[
      // 5 athletes in pickDiv(0) (odd number -> demonstrates automatic/manual BYE handling!)
      {
        'id': 'reg-pk-101',
        'athleteId': 'ath-pk-101',
        'athleteName': 'Hamza Tariq',
        'clubName': 'Lahore Titans • Lahore',
        'categoryLabel': pickDiv(0),
        'eloRating': 1865,
        'prKg': 68.0,
        'maxLiftKg': 76.5,
        'lossesCount': 0,
        'weighInStatus': 'VERIFIED',
        'measuredWeightKg': 69.2,
      },
      {
        'id': 'reg-pk-102',
        'athleteId': 'ath-pk-102',
        'athleteName': 'Shahzaib Baloch',
        'clubName': 'Quetta Grizzlies • Quetta',
        'categoryLabel': pickDiv(0),
        'eloRating': 1795,
        'prKg': 65.5,
        'maxLiftKg': 73.0,
        'lossesCount': 0,
        'weighInStatus': 'VERIFIED',
        'measuredWeightKg': 68.8,
      },
      {
        'id': 'reg-pk-103',
        'athleteId': 'ath-pk-103',
        'athleteName': 'Zain Ul Abideen',
        'clubName': 'Islamabad Vipers • Islamabad',
        'categoryLabel': pickDiv(0),
        'eloRating': 1740,
        'prKg': 63.0,
        'maxLiftKg': 70.5,
        'lossesCount': 0,
        'weighInStatus': 'VERIFIED',
        'measuredWeightKg': 69.5,
      },
      {
        'id': 'reg-pk-104',
        'athleteId': 'ath-pk-104',
        'athleteName': 'Taimoor Jutt',
        'clubName': 'Gujranwala Lions • Gujranwala',
        'categoryLabel': pickDiv(0),
        'eloRating': 1690,
        'prKg': 61.0,
        'maxLiftKg': 68.0,
        'lossesCount': 0,
        'weighInStatus': 'VERIFIED',
        'measuredWeightKg': 69.0,
      },
      {
        'id': 'reg-pk-105',
        'athleteId': 'ath-pk-105',
        'athleteName': 'Babar Niazi',
        'clubName': 'Mianwali Hawks • Mianwali',
        'categoryLabel': pickDiv(0),
        'eloRating': 1635,
        'prKg': 58.5,
        'maxLiftKg': 65.0,
        'lossesCount': 0,
        'weighInStatus': 'VERIFIED',
        'measuredWeightKg': 67.9,
      },
      // Athletes in pickDiv(1) & pickDiv(2)
      {
        'id': 'reg-pk-106',
        'athleteId': 'ath-pk-106',
        'athleteName': 'Murtaza Afridi',
        'clubName': 'Khyber Iron Grip • Peshawar',
        'categoryLabel': pickDiv(1),
        'eloRating': 1760,
        'prKg': 64.0,
        'maxLiftKg': 72.0,
        'lossesCount': 0,
        'weighInStatus': 'VERIFIED',
        'measuredWeightKg': 69.4,
      },
      {
        'id': 'reg-pk-107',
        'athleteId': 'ath-pk-107',
        'athleteName': 'Daniyal Qureshi',
        'clubName': 'Karachi Wolves • Karachi',
        'categoryLabel': pickDiv(1),
        'eloRating': 1685,
        'prKg': 60.5,
        'maxLiftKg': 67.5,
        'lossesCount': 0,
        'weighInStatus': 'VERIFIED',
        'measuredWeightKg': 68.7,
      },
      {
        'id': 'reg-pk-108',
        'athleteId': 'ath-pk-108',
        'athleteName': 'Asadullah Khan',
        'clubName': 'Rawalpindi Forge • Rawalpindi',
        'categoryLabel': pickDiv(2),
        'eloRating': 1810,
        'prKg': 74.0,
        'maxLiftKg': 83.0,
        'lossesCount': 0,
        'weighInStatus': 'VERIFIED',
        'measuredWeightKg': 79.1,
      },
      {
        'id': 'reg-pk-109',
        'athleteId': 'ath-pk-109',
        'athleteName': 'Sikandar Hayat',
        'clubName': 'Multan Royals • Multan',
        'categoryLabel': pickDiv(2),
        'eloRating': 1725,
        'prKg': 71.0,
        'maxLiftKg': 79.5,
        'lossesCount': 0,
        'weighInStatus': 'VERIFIED',
        'measuredWeightKg': 78.6,
      },
      {
        'id': 'reg-pk-110',
        'athleteId': 'ath-pk-110',
        'athleteName': 'Farhan Gillani',
        'clubName': 'Faisalabad Bulls • Faisalabad',
        'categoryLabel': pickDiv(2),
        'eloRating': 1650,
        'prKg': 68.0,
        'maxLiftKg': 75.5,
        'lossesCount': 0,
        'weighInStatus': 'VERIFIED',
        'measuredWeightKg': 79.4,
      },
    ];

    return templates.map((t) {
      final cat = t['categoryLabel'].toString();
      final parts = cat.split('•');
      final wClass = parts.first.trim();
      final arm = parts.length > 1 ? parts.last.trim() : 'Right Arm';
      return <String, dynamic>{
        ...t,
        'registrationId': t['id'],
        'weightClass': wClass,
        'arm': arm,
        'qrCodePayload': 'ARMSPHERE-QR:${t['id']}:${t['athleteId']}:$cat',
        'applicationStatus': 'APPLIED',
        'unmatchResolution': 'NONE',
        'assignedOpponentId': null,
        'assignedOpponentName': null,
        'checkedInGuestsCount': 0,
        'entranceCheckedIn': false,
      };
    }).toList();
  }

  Future<void> _enqueueAndPersistHubAction({
    required Map<String, dynamic> updatedTournament,
    required String operatorId,
    required String actionType,
    required String endpoint,
    required Map<String, dynamic> syncPayload,
    required String bannerMessage,
  }) async {
    await _autoSaveTournamentRecord(
      updatedTournament,
      operatorId,
      customBanner: bannerMessage,
      skipDefaultQueue: true,
    );
    try {
      final hive = ref.read(hiveStorageProvider);
      await hive.enqueueAction(
        actionType: actionType,
        endpoint: '/sync/queue',
        payload: {
          ...syncPayload,
          'targetEndpoint': endpoint,
        },
        method: 'POST',
      );
      ref.read(offlineSyncManagerProvider).syncQueue();
    } catch (_) {
      // Offline queue or memory store already holds the state with zero data loss
    }
  }

  List<Map<String, String>> _expandSeparatedDivisions(Map<String, dynamic> record) {
    final cats = (record['weightCategories'] as List?) ?? const [];
    final result = <Map<String, String>>[];
    for (final raw in cats) {
      if (raw is! Map) continue;
      if (raw['enabled'] != true) continue;
      final id = raw['id']?.toString() ?? 'wc';
      final label = raw['label']?.toString().trim() ?? '';
      if (label.isEmpty) continue;
      final arm = (raw['arm']?.toString() ?? 'RIGHT').toUpperCase();
      if (arm == 'RIGHT' || arm == 'BOTH') {
        result.add({
          'divisionId': '${id}_RIGHT',
          'label': '$label • Right Arm',
        });
      }
      if (arm == 'LEFT' || arm == 'BOTH') {
        result.add({
          'divisionId': '${id}_LEFT',
          'label': '$label • Left Arm',
        });
      }
    }
    return result;
  }

  /// Validates all 7 mandatory sections in Card 1.
  Map<String, dynamic> _validateCard1(Map<String, dynamic> record) {
    final missing = <String>[];

    // 1. Basic Info
    final name = (record['name'] ?? '').toString().trim();
    final org = (record['organizationName'] ?? '').toString().trim();
    final venue = (record['venue'] ?? '').toString().trim();
    final startDate = (record['startDate'] ?? '').toString().trim();
    final maxAthletes = (record['capacity'] as num?)?.toInt() ?? 0;
    final basicValid = name.length >= 3 &&
        org.length >= 2 &&
        venue.length >= 2 &&
        startDate.isNotEmpty &&
        maxAthletes >= 2;
    if (!basicValid) {
      missing.add('Basic Info (Event Name, Schedule, Organization, Venue, Max Athletes)');
    }

    // 2. Weight Categories & Arm/Hand Support
    final separatedDivisions = _expandSeparatedDivisions(record);
    final weightsValid = separatedDivisions.isNotEmpty;
    if (!weightsValid) {
      missing.add('At least 1 Weight Category with Right Arm, Left Arm, or Both');
    }

    // 3. Mandatory Tournament / Match Format Type
    final formatCat = (record['formatCategory'] ?? '').toString();
    final elimSub = (record['eliminationSubFormat'] ?? '').toString();
    final formatValid = formatCat == 'SUPERFIGHTS' ||
        (formatCat == 'ELIMINATION' &&
            const {
              'SINGLE_ELIMINATION',
              'DOUBLE_ELIMINATION',
              'THREE_LOSS_ELIMINATION',
              'LAST_ONE_STANDING',
            }.contains(elimSub));
    if (!formatValid) {
      missing.add('Tournament / Match Format Type (Superfights or Elimination)');
    }

    // 4. Number of Tables & Mandatory Table Assignment Mode
    final tableCount = ((record['tableCount'] as num?)?.toInt() ?? 1).clamp(1, 12);
    final assignMode = (record['tableAssignmentMode'] ?? '').toString();
    final tables = (record['tables'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        <Map<String, dynamic>>[];

    bool tablesValid = tableCount >= 1;
    if (tableCount > 1) {
      if (!const {
        'CATEGORY_BY_TABLE',
        'RANDOM_BY_APP',
        'DYNAMIC_FREE_TABLE_QUEUE',
      }.contains(assignMode)) {
        tablesValid = false;
        missing.add('Table Assignment Mode for $tableCount tables');
      } else if (assignMode == 'CATEGORY_BY_TABLE') {
        for (final t in tables) {
          final cats = (t['assignedCategoryDivisionIds'] as List?) ?? const [];
          if (cats.isEmpty) {
            tablesValid = false;
            missing.add('Assign weight categories to ${t['tableName']}');
            break;
          }
        }
      }
    }

    // 5. Mandatory Referee Selection (min 2 referees per table)
    bool refereesValid = tables.isNotEmpty;
    for (final t in tables) {
      final refs = (t['assignedRefereeIds'] as List?) ?? const [];
      if (refs.length < 2) {
        refereesValid = false;
        missing.add('Select at least 2 referees for ${t['tableName']}');
        break;
      }
    }

    // 6. Mandatory Entry / Application Fee in PKR
    final entryFeeConfigured = record['entryFeeConfigured'] == true &&
        record['entryFeePkr'] != null &&
        ((record['entryFeePkr'] as num?)?.toDouble() ?? -1) >= 0;
    if (!entryFeeConfigured) {
      missing.add('Entry / Application Fee in PKR (0 for free or PKR amount)');
    }

    // 7. Separate Awards & Prizes Sub-Screen
    final awardsConfig = record['awardsConfig'] is Map
        ? Map<String, dynamic>.from(record['awardsConfig'] as Map)
        : <String, dynamic>{};
    final awardsValid = awardsConfig['isConfigured'] == true;
    if (!awardsValid) {
      missing.add('Awards & Prizes configuration (open sub-screen and save)');
    }

    final flags = [
      basicValid,
      weightsValid,
      formatValid,
      tablesValid,
      refereesValid,
      entryFeeConfigured,
      awardsValid,
    ];
    final doneCount = flags.where((f) => f).length;

    return {
      'isComplete': doneCount == flags.length,
      'doneCount': doneCount,
      'totalCount': flags.length,
      'basicValid': basicValid,
      'weightsValid': weightsValid,
      'formatValid': formatValid,
      'tablesValid': tablesValid,
      'refereesValid': refereesValid,
      'entryFeeValid': entryFeeConfigured,
      'awardsValid': awardsValid,
      'missing': missing,
    };
  }

  String _formatSummaryLabel(Map<String, dynamic> record) {
    final cat = (record['formatCategory'] ?? '').toString();
    final sub = (record['eliminationSubFormat'] ?? '').toString();
    if (cat == 'SUPERFIGHTS') return 'Superfights (Single Bouts)';
    if (cat == 'ELIMINATION') {
      switch (sub) {
        case 'SINGLE_ELIMINATION':
          return 'Single / One-Loss Elimination';
        case 'DOUBLE_ELIMINATION':
          return 'Double / Two-Loss Elimination';
        case 'THREE_LOSS_ELIMINATION':
          return 'Three-Loss Elimination';
        case 'LAST_ONE_STANDING':
          return 'Last-One-Standing';
      }
    }
    return 'Format Not Selected';
  }

  /// Auto-saves any change to a tournament draft locally (and queues background sync without blocking).
  Future<void> _autoSaveTournamentRecord(
    Map<String, dynamic> updated,
    String operatorId, {
    String? customBanner,
    bool skipDefaultQueue = false,
  }) async {
    final map = _loadOperatorLocalMap(operatorId);
    final int tableCount = ((updated['tableCount'] as num?)?.toInt() ?? 1).clamp(1, 12);
    final existingTables = (updated['tables'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        <Map<String, dynamic>>[];

    final syncedTables = <Map<String, dynamic>>[];
    for (int i = 1; i <= tableCount; i++) {
      final found = existingTables.where((t) => t['tableNumber'] == i).firstOrNull;
      final refIds = found?['assignedRefereeIds'] is List
          ? List<String>.from(found!['assignedRefereeIds'] as List)
          : <String>[];
      final refNames = refIds
          .map((id) =>
              _kDefaultRefereePool
                  .where((r) => r['id'] == id)
                  .map((r) => r['name']!)
                  .firstOrNull ??
              id)
          .toList();
      syncedTables.add({
        'tableNumber': i,
        'tableName': found?['tableName']?.toString() ?? 'Table $i',
        'assignedCategoryDivisionIds': found?['assignedCategoryDivisionIds'] is List
            ? List<String>.from(found!['assignedCategoryDivisionIds'] as List)
            : <String>[],
        'assignedRefereeIds': refIds,
        'assignedRefereeNames': refNames,
      });
    }

    final recordToSave = <String, dynamic>{
      ...updated,
      'organizerId': operatorId,
      'tableCount': tableCount,
      'tableAssignmentMode': tableCount == 1
          ? 'SINGLE_TABLE_DEFAULT'
          : (updated['tableAssignmentMode'] ?? '').toString(),
      'tables': syncedTables,
      // Strict Rule: Auto-saving Card 1 NEVER releases automatically
      'isReleased': updated['isReleased'] == true,
      'status': updated['isReleased'] == true
          ? ((updated['status']?.toString().toUpperCase() == 'DRAFT')
              ? 'REGISTRATION_OPEN'
              : (updated['status'] ?? 'REGISTRATION_OPEN'))
          : 'DRAFT',
      'syncState': 'SAVED_LOCAL',
      'updatedAt': DateTime.now().toIso8601String(),
    };

    final eventId = recordToSave['id'].toString();
    map[eventId] = recordToSave;
    await _persistOperatorLocalMap(operatorId);
    try {
      final hive = ref.read(hiveStorageProvider);
      if (recordToSave['isReleased'] == true) {
        await TournamentOfflineStore.upsertReleasedTournament(hive, recordToSave);
      }
      if (!skipDefaultQueue) {
        final actionType = recordToSave['isReleased'] == true
            ? 'UPDATE_RELEASED_TOURNAMENT'
            : 'SAVE_TOURNAMENT_DRAFT';
        await hive.enqueueAction(
          actionType: actionType,
          endpoint: '/sync/queue',
          payload: {
            'eventId': eventId,
            'organizerId': operatorId,
            'name': recordToSave['name'],
            'venue': recordToSave['venue'],
            'city': recordToSave['city'],
            'province': recordToSave['province'],
            'capacity': recordToSave['capacity'],
            'entryFeePkr': recordToSave['entryFeePkr'],
            'formatCategory': recordToSave['formatCategory'],
            'eliminationSubFormat': recordToSave['eliminationSubFormat'],
            'tableCount': recordToSave['tableCount'],
            'tableAssignmentMode': recordToSave['tableAssignmentMode'],
          },
          method: 'POST',
          idempotencyKey: 'idem_${actionType.toLowerCase()}_$eventId',
        );
        ref.read(offlineSyncManagerProvider).syncQueue();
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _autoSaveBannerText =
            customBanner ?? 'Saved / Done • Local Draft Protected';
      });
    }
  }

  /// Explicitly releases / schedules the tournament when Card 1 is 100% complete AND the operator clicks "Release / Schedule"
  /// (or saves permitted edits if the tournament is already released).
  Future<void> _handleReleaseTournament(
    Map<String, dynamic> record,
    String operatorId,
  ) async {
    final validation = _validateCard1(record);
    if (validation['isComplete'] != true) {
      final firstMissing = ((validation['missing'] as List?)?.firstOrNull ??
              'Please complete all mandatory fields in Card 1.')
          .toString();
      ScaffoldMessenger.of(context).showSnackBar(
        CrystalSnackBar(
          content: Text('Complete Card 1 before releasing: $firstMissing'),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    HapticFeedback.heavyImpact();
    final wasAlreadyReleased = record['isReleased'] == true;
    final now = DateTime.now();
    final existingApplied = (record['appliedAthletes'] is List)
        ? (record['appliedAthletes'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];

    final releasedRecord = <String, dynamic>{
      ...record,
      'appliedAthletes': existingApplied.isNotEmpty
          ? existingApplied
          : _seedDefaultAppliedAthletes(record),
      'isReleased': true,
      'status': wasAlreadyReleased
          ? ((record['status']?.toString().toUpperCase() == 'DRAFT')
              ? 'REGISTRATION_OPEN'
              : (record['status'] ?? 'REGISTRATION_OPEN'))
          : 'REGISTRATION_OPEN',
      'releasedAt': record['releasedAt'] ?? now.toIso8601String(),
      'syncState': 'SYNCED',
      'updatedAt': now.toIso8601String(),
    };

    await _autoSaveTournamentRecord(
      releasedRecord,
      operatorId,
      customBanner: wasAlreadyReleased
          ? 'Permitted Edits Saved & Synced • Released Tournament Updated!'
          : 'Released & Scheduled • Cards 2, 3 & 4 Unlocked!',
      skipDefaultQueue: true,
    );

    final eventId = releasedRecord['id'].toString();
    try {
      final hive = ref.read(hiveStorageProvider);
      final actionType =
          wasAlreadyReleased ? 'UPDATE_RELEASED_TOURNAMENT' : 'RELEASE_TOURNAMENT';
      await hive.enqueueAction(
        actionType: actionType,
        endpoint: '/sync/queue',
        payload: {
          'eventId': eventId,
          'organizerId': operatorId,
          'name': releasedRecord['name'],
          'organizationName': releasedRecord['organizationName'],
          'venue': releasedRecord['venue'],
          'city': releasedRecord['city'],
          'province': releasedRecord['province'],
          'capacity': releasedRecord['capacity'] ?? 64,
          'entryFeePkr': releasedRecord['entryFeePkr'] ?? 0,
          'status': releasedRecord['status'],
          'releasedAt': now.toUtc().toIso8601String(),
        },
        method: 'POST',
        idempotencyKey: 'idem_${actionType.toLowerCase()}_$eventId',
      );
      ref.read(offlineSyncManagerProvider).syncQueue();
    } catch (_) {}

    if (mounted) {
      setState(() {
        _activeView = _OperatorSubView.tournamentHub;
      });
    }

    // Queue/execute server sync in the background without ever blocking UI
    try {
      final feePkr = (releasedRecord['entryFeePkr'] as num?)?.toInt() ?? 0;
      final startDt = DateTime.tryParse(releasedRecord['startDate']?.toString() ?? '') ??
          now.add(const Duration(days: 14));
      final endDt = DateTime.tryParse(releasedRecord['endDate']?.toString() ?? '') ??
          startDt.add(const Duration(hours: 8));
      final regStart = now.subtract(const Duration(minutes: 5));
      final regEnd = startDt.subtract(const Duration(hours: 2));

      if (wasAlreadyReleased) {
        await ref.read(tournamentProvider.notifier).patchEvent(
              eventId: eventId,
              data: {
                'name': releasedRecord['name'],
                'province': releasedRecord['province'] ?? 'Punjab',
                'city': releasedRecord['city'] ?? 'Lahore',
                'venue': releasedRecord['venue'],
                'capacity': releasedRecord['capacity'] ?? 64,
                'registrationFeeCents': feePkr * 100,
                'startDate': startDt.toUtc().toIso8601String(),
                'endDate': endDt.toUtc().toIso8601String(),
                'step1Config': releasedRecord,
              },
            );
      } else {
        await ref.read(tournamentProvider.notifier).createEvent(
              data: {
                'name': releasedRecord['name'],
                'organizationName': releasedRecord['organizationName'],
                'organizerId': operatorId,
                'province': releasedRecord['province'] ?? 'Punjab',
                'city': releasedRecord['city'] ?? 'Lahore',
                'venue': releasedRecord['venue'],
                'capacity': releasedRecord['capacity'] ?? 64,
                'registrationFeeCents': feePkr * 100,
                'registrationStart': regStart.toUtc().toIso8601String(),
                'registrationEnd': regEnd.toUtc().toIso8601String(),
                'startDate': startDt.toUtc().toIso8601String(),
                'endDate': endDt.toUtc().toIso8601String(),
                'status': 'REGISTRATION_OPEN',
                'step1Config': releasedRecord,
              },
              publishImmediately: true,
            );
      }
    } catch (_) {
      // Offline outbox already queued or saved locally — never show a blocking error
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        CrystalSnackBar(
          content: Text(
            wasAlreadyReleased
                ? 'Permitted Edits Saved! Released tournament updated locally and queued for sync.'
                : 'Tournament Released & Scheduled! Cards 2, 3, and 4 are now UNLOCKED and athletes can apply.',
          ),
          backgroundColor: AppTheme.emerald,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatDateReadable(dynamic dateVal) {
    if (dateVal == null) return 'Schedule TBD';
    try {
      final dt = DateTime.parse(dateVal.toString());
      final months = const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month - 1]} ${dt.year} • $h:$m';
    } catch (_) {
      return dateVal.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tournamentsAsync = ref.watch(tournamentProvider);
    final authState = ref.watch(authProvider);
    final profile = authState.userProfile ?? {};
    final operatorId = _resolveOperatorId(profile);

    if (_lastUserId != operatorId) {
      _lastUserId = operatorId;
      _selectedTournamentId = null;
      _activeView = _OperatorSubView.mainList;
    }

    final operatorName =
        (profile['displayName'] ?? profile['name'] ?? 'Tournament Operator')
            .toString();

    return PopScope(
      canPop: _activeView == _OperatorSubView.mainList,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        setState(() {
          if (_activeView == _OperatorSubView.awardsPrizesSubScreen) {
            _activeView = _OperatorSubView.card1BasicDetails;
          } else if (_activeView == _OperatorSubView.card1BasicDetails ||
              _activeView == _OperatorSubView.card2AppliedAthletes ||
              _activeView == _OperatorSubView.card3MatchupsBrackets ||
              _activeView == _OperatorSubView.card4WeighInVerification ||
              _activeView == _OperatorSubView.spectatorEntranceQrGate) {
            _activeView = _OperatorSubView.tournamentHub;
          } else if (_activeView == _OperatorSubView.tournamentHub) {
            _activeView = _OperatorSubView.mainList;
          }
        });
      },
      child: Scaffold(
        backgroundColor: AppTheme.voidBackground,
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(context, operatorName, operatorId, profile),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const CrystalStageBackdrop(
              domain: ArmSphereStageDomain.arena,
              customImageOverride: ArmSphereAssets.stageArena,
            ),
            SafeArea(
              bottom: false,
              child: CrystalVaporDissolve(
                bottomMargin: MainShellScope.isInsideShell(context)
                    ? (kFloatingDockTotalHeight +
                        MediaQuery.paddingOf(context).bottom +
                        10.0)
                    : 12.0,
                child: tournamentsAsync.when(
                  loading: () => ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.space16,
                      16,
                      AppTheme.space16,
                      28,
                    ),
                    itemCount: 3,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppTheme.space16),
                    itemBuilder: (_, __) => const SkeletonPlaceholder(
                      height: 120,
                      borderRadius: AppTheme.radiusMedium,
                    ),
                  ),
                  error: (error, _) {
                    // Offline-first fallback: even if server errors, show local operator tournaments
                    final mergedList = _mergeServerAndLocalTournaments(
                      const [],
                      operatorId,
                      authState,
                      profile,
                    );
                    return _buildActiveSubView(
                      context,
                      mergedList,
                      operatorId,
                      profile,
                    );
                  },
                  data: (serverTournaments) {
                    final mergedList = _mergeServerAndLocalTournaments(
                      serverTournaments,
                      operatorId,
                      authState,
                      profile,
                    );
                    return _buildActiveSubView(
                      context,
                      mergedList,
                      operatorId,
                      profile,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _mergeServerAndLocalTournaments(
    List<Map<String, dynamic>> serverEvents,
    String operatorId,
    AuthState authState,
    Map<String, dynamic> profile,
  ) {
    final effectiveRole =
        authState.activeRole ?? profile['role']?.toString() ?? 'TOURNAMENT_OPERATOR';

    final permittedServer = serverEvents
        .where((t) => AdminPermissions.canOperateEvent(
              activeRole: effectiveRole,
              userProfile: profile,
              event: t,
            ))
        .toList();

    final localMap = _loadOperatorLocalMap(operatorId);
    final combinedById = <String, Map<String, dynamic>>{};

    for (final s in permittedServer) {
      final norm = _normalizeTournamentRecord(s, operatorId);
      combinedById[norm['id'].toString()] = norm;
    }

    // Overlay local offline drafts & edits so zero input is ever lost
    for (final entry in localMap.entries) {
      final norm = _normalizeTournamentRecord(entry.value, operatorId);
      combinedById[entry.key] = norm;
    }

    return combinedById.values.toList();
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    String operatorName,
    String operatorId,
    Map<String, dynamic> profile,
  ) {
    String subtitle = 'ARENA OPERATIONS COMMAND';
    if (_activeView == _OperatorSubView.tournamentHub) {
      subtitle = 'TOURNAMENT HUB • 4-STAGE CONTROL';
    } else if (_activeView == _OperatorSubView.card1BasicDetails) {
      subtitle = 'CARD 1 • BASIC & MANDATORY DETAILS';
    } else if (_activeView == _OperatorSubView.awardsPrizesSubScreen) {
      subtitle = 'CARD 1 SUB-SCREEN • AWARDS & PRIZES';
    } else if (_activeView == _OperatorSubView.card2AppliedAthletes) {
      subtitle = 'CARD 2 • APPLIED / REGISTERED ATHLETES';
    } else if (_activeView == _OperatorSubView.card3MatchupsBrackets) {
      subtitle = 'CARD 3 • MATCHUPS & BRACKETS ENGINE';
    } else if (_activeView == _OperatorSubView.card4WeighInVerification) {
      subtitle = 'CARD 4 • WEIGH-IN VERIFICATION DESK';
    } else if (_activeView == _OperatorSubView.spectatorEntranceQrGate) {
      subtitle = 'SPECTATOR & VENUE ENTRANCE QR GATE';
    }

    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: _activeView != _OperatorSubView.mainList
          ? IconButton(
              key: const ValueKey('operator_step1_back_button'),
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppTheme.goldPrimary, size: 18),
              tooltip: 'Back (Auto-Saved)',
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (_activeView == _OperatorSubView.awardsPrizesSubScreen) {
                    _activeView = _OperatorSubView.card1BasicDetails;
                  } else if (_activeView == _OperatorSubView.card1BasicDetails ||
                      _activeView == _OperatorSubView.card2AppliedAthletes ||
                      _activeView == _OperatorSubView.card3MatchupsBrackets ||
                      _activeView == _OperatorSubView.card4WeighInVerification ||
                      _activeView == _OperatorSubView.spectatorEntranceQrGate) {
                    _activeView = _OperatorSubView.tournamentHub;
                  } else {
                    _activeView = _OperatorSubView.mainList;
                  }
                });
              },
            )
          : CrystalBackButton.maybeForInnerScreen(context),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.goldPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 10,
                    letterSpacing: 0.9,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.goldPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            operatorName,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
      actions: [
        if (_activeView == _OperatorSubView.mainList)
          Center(
            child: CrystalHeaderActionPill(
              label: 'CREATE TOURNAMENT',
              icon: Icons.add,
              onTap: () => _startNewTournamentDraft(operatorId, profile),
            ),
          ),
        const SizedBox(width: 4),
        CrystalIconPillButton(
          icon: Icons.sync_rounded,
          iconColor: AppTheme.emerald,
          tooltip: 'Sync Offline Outbox & Refresh',
          onPressed: () {
            try {
              ref.read(offlineSyncManagerProvider).syncQueue();
            } catch (_) {}
            ref.invalidate(tournamentProvider);
          },
        ),
        CrystalIconPillButton(
          icon: Icons.shield_outlined,
          iconColor: AppTheme.textSecondary,
          tooltip: 'Account Roles',
          onPressed: () => context.push('/settings/roles'),
        ),
        if (!MainShellScope.isInsideShell(context)) const CrystalHomeButton(),
        const SizedBox(width: 6),
      ],
    );
  }

  Future<void> _startNewTournamentDraft(
    String operatorId,
    Map<String, dynamic> profile,
  ) async {
    HapticFeedback.mediumImpact();
    final draft = _createFreshDraft(operatorId, profile);
    await _autoSaveTournamentRecord(
      draft,
      operatorId,
      customBanner: 'New Unreleased Draft Created Locally',
    );
    if (!mounted) return;
    setState(() {
      _selectedTournamentId = draft['id'].toString();
      _activeView = _OperatorSubView.tournamentHub;
    });
  }

  Widget _buildActiveSubView(
    BuildContext context,
    List<Map<String, dynamic>> tournaments,
    String operatorId,
    Map<String, dynamic> profile,
  ) {
    if (_activeView == _OperatorSubView.mainList) {
      return _buildOperatorMainScreen(context, tournaments, operatorId, profile);
    }

    final current = tournaments
            .where((t) => t['id']?.toString() == _selectedTournamentId)
            .firstOrNull ??
        (tournaments.isNotEmpty ? tournaments.first : null);

    if (current == null) {
      return _buildOperatorMainScreen(context, tournaments, operatorId, profile);
    }

    if (_activeView == _OperatorSubView.tournamentHub) {
      return _buildTournamentHubScreen(context, current, operatorId);
    }
    if (_activeView == _OperatorSubView.card1BasicDetails) {
      return _Card1BasicDetailsView(
        key: ValueKey('card1_${current['id']}'),
        tournament: current,
        autoSaveBannerText: _autoSaveBannerText,
        validation: _validateCard1(current),
        separatedDivisions: _expandSeparatedDivisions(current),
        onChanged: (updated) => _autoSaveTournamentRecord(updated, operatorId),
        onOpenAwardsSubScreen: () {
          HapticFeedback.selectionClick();
          setState(() => _activeView = _OperatorSubView.awardsPrizesSubScreen);
        },
        onReleaseTournament: () => _handleReleaseTournament(current, operatorId),
        onBackToHub: () {
          HapticFeedback.selectionClick();
          setState(() => _activeView = _OperatorSubView.tournamentHub);
        },
      );
    }
    if (_activeView == _OperatorSubView.awardsPrizesSubScreen) {
      return _AwardsPrizesSubScreenView(
        key: ValueKey('awards_${current['id']}'),
        tournament: current,
        onSaveAwards: (updatedAwards) async {
          final updatedTournament = <String, dynamic>{
            ...current,
            'awardsConfig': {
              ...updatedAwards,
              'isConfigured': true,
            },
          };
          await _autoSaveTournamentRecord(
            updatedTournament,
            operatorId,
            customBanner: 'Awards & Prizes Saved (✓) • Draft Protected',
          );
          if (mounted) {
            setState(() => _activeView = _OperatorSubView.card1BasicDetails);
          }
        },
        onCancel: () {
          setState(() => _activeView = _OperatorSubView.card1BasicDetails);
        },
      );
    }

    final currentAthletes = (current['appliedAthletes'] is List)
        ? (current['appliedAthletes'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : _seedDefaultAppliedAthletes(current);

    if (_activeView == _OperatorSubView.card2AppliedAthletes) {
      return Card2AppliedAthletesView(
        key: ValueKey('card2_${current['id']}'),
        tournament: current,
        separatedDivisions: _expandSeparatedDivisions(current),
        appliedAthletes: currentAthletes,
        autoSaveBannerText: _autoSaveBannerText,
        onUpdateAthletes: (updatedAthletes) async {
          final updatedTournament = <String, dynamic>{
            ...current,
            'appliedAthletes': updatedAthletes,
          };
          await _enqueueAndPersistHubAction(
            updatedTournament: updatedTournament,
            operatorId: operatorId,
            actionType: 'SUBMIT_ATHLETE_APPLICATION',
            endpoint: '/tournaments/registrations',
            syncPayload: {
              'eventId': current['id'],
              'athleteCount': updatedAthletes.length,
            },
            bannerMessage: 'Saved / Done • Applied Athletes Roster Cached',
          );
        },
        onOpenWeighInForAthlete: (athleteId) {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedAthleteIdForWeighIn = athleteId;
            _activeView = _OperatorSubView.card4WeighInVerification;
          });
        },
        onBackToHub: () {
          HapticFeedback.selectionClick();
          setState(() => _activeView = _OperatorSubView.tournamentHub);
        },
      );
    }

    if (_activeView == _OperatorSubView.card3MatchupsBrackets) {
      return Card3MatchupsBracketsView(
        key: ValueKey('card3_${current['id']}'),
        tournament: current,
        separatedDivisions: _expandSeparatedDivisions(current),
        appliedAthletes: currentAthletes,
        autoSaveBannerText: _autoSaveBannerText,
        onCommitMatchupsAction: ({
          required updatedMatchupsState,
          required updatedAthletes,
          required actionType,
          required syncPayload,
          required bannerMessage,
        }) async {
          final updatedTournament = <String, dynamic>{
            ...current,
            'card3MatchupsState': updatedMatchupsState,
            'appliedAthletes': updatedAthletes,
          };
          await _enqueueAndPersistHubAction(
            updatedTournament: updatedTournament,
            operatorId: operatorId,
            actionType: actionType,
            endpoint: '/tournaments/matches/result',
            syncPayload: syncPayload,
            bannerMessage: bannerMessage,
          );
        },
        onBackToHub: () {
          HapticFeedback.selectionClick();
          setState(() => _activeView = _OperatorSubView.tournamentHub);
        },
      );
    }

    if (_activeView == _OperatorSubView.card4WeighInVerification) {
      return Card4WeighInVerificationView(
        key: ValueKey('card4_${current['id']}_${_selectedAthleteIdForWeighIn ?? "all"}'),
        tournament: current,
        separatedDivisions: _expandSeparatedDivisions(current),
        appliedAthletes: currentAthletes,
        initialSelectedAthleteId: _selectedAthleteIdForWeighIn,
        autoSaveBannerText: _autoSaveBannerText,
        onCommitWeighInAction: ({
          required updatedAthletes,
          required actionType,
          required syncPayload,
          required bannerMessage,
        }) async {
          final updatedTournament = <String, dynamic>{
            ...current,
            'appliedAthletes': updatedAthletes,
          };
          await _enqueueAndPersistHubAction(
            updatedTournament: updatedTournament,
            operatorId: operatorId,
            actionType: actionType,
            endpoint: '/tournaments/weighins',
            syncPayload: syncPayload,
            bannerMessage: bannerMessage,
          );
        },
        onBackToHub: () {
          HapticFeedback.selectionClick();
          setState(() => _activeView = _OperatorSubView.tournamentHub);
        },
      );
    }

    if (_activeView == _OperatorSubView.spectatorEntranceQrGate) {
      return SpectatorEntranceQrGateView(
        key: ValueKey('spectator_gate_${current['id']}'),
        tournament: current,
        appliedAthletes: currentAthletes,
        autoSaveBannerText: _autoSaveBannerText,
        onCommitGateAction: ({
          required updatedSpectatorConfig,
          required updatedAthletes,
          required actionType,
          required syncPayload,
          required bannerMessage,
        }) async {
          final updatedTournament = <String, dynamic>{
            ...current,
            'spectatorGateConfig': updatedSpectatorConfig,
            'appliedAthletes': updatedAthletes,
          };
          await _enqueueAndPersistHubAction(
            updatedTournament: updatedTournament,
            operatorId: operatorId,
            actionType: actionType,
            endpoint: '/events/${current['id']}/entrance/scan',
            syncPayload: syncPayload,
            bannerMessage: bannerMessage,
          );
        },
        onBackToHub: () {
          HapticFeedback.selectionClick();
          setState(() => _activeView = _OperatorSubView.tournamentHub);
        },
      );
    }

    return _buildOperatorMainScreen(context, tournaments, operatorId, profile);
  }

  // ===========================================================================
  // 1. OPERATOR MAIN SCREEN (Create Button + Top List & Bottom List)
  // ===========================================================================
  Widget _buildOperatorMainScreen(
    BuildContext context,
    List<Map<String, dynamic>> tournaments,
    String operatorId,
    Map<String, dynamic> profile,
  ) {
    final upcomingAndDrafts = <Map<String, dynamic>>[];
    final completedList = <Map<String, dynamic>>[];

    for (final t in tournaments) {
      final status = (t['status'] ?? 'DRAFT').toString().toUpperCase();
      if (status == 'COMPLETED') {
        completedList.add(t);
      } else {
        upcomingAndDrafts.add(t);
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space16,
        12,
        AppTheme.space16,
        36,
      ),
      children: [
        // Offline-First Sync Engine Status Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: [
              const Icon(Icons.offline_bolt_outlined,
                  size: 16, color: AppTheme.emerald),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'OFFLINE-FIRST OUTBOX ENGINE ACTIVE • $_autoSaveBannerText',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontMono,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.emerald,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Prominent "Create Tournament" CTA Button
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            key: const ValueKey('operator_create_tournament_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.goldPrimary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
            onPressed: () => _startNewTournamentDraft(operatorId, profile),
            icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
            label: const Text(
              'CREATE TOURNAMENT',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        if (tournaments.isEmpty) ...[
          AppEmptyState(
            icon: Icons.emoji_events_outlined,
            title: 'No Tournaments Created Yet',
            subtitle:
                'Tap "Create Tournament" above to start a tournament draft (works 100% offline with automatic draft protection).',
            bannerAsset: ArmSphereAssets.cardStandbyTable,
            bannerAlignment: Alignment.centerRight,
            ctaLabel: 'Create Tournament',
            onCtaTap: () => _startNewTournamentDraft(operatorId, profile),
          ),
          const SizedBox(height: 20),
        ],

        // TOP LIST: UPCOMING / ACTIVE & UNRELEASED DRAFTS
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'UPCOMING / ACTIVE TOURNAMENTS & DRAFTS',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppTheme.goldPrimary,
              ),
            ),
            StatusChip(
              label: '${upcomingAndDrafts.length}',
              type: StatusType.warning,
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Active registrations, ongoing live events, and unreleased operator drafts (hidden from athletes until released).',
          style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 10),
        if (upcomingAndDrafts.isEmpty)
          ElevatedActionCard(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: const Text(
              'No upcoming or active tournaments right now. Tap "Create Tournament" to start a new event or draft.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          )
        else
          for (final item in upcomingAndDrafts) ...[
            _buildTournamentListCard(context, item, isCompleted: false),
            const SizedBox(height: 10),
          ],

        const SizedBox(height: 22),

        // BOTTOM LIST: PREVIOUS COMPLETED TOURNAMENTS
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'PREVIOUS COMPLETED TOURNAMENTS',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppTheme.textSecondary,
              ),
            ),
            StatusChip(
              label: '${completedList.length}',
              type: StatusType.neutral,
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Archived completed tournaments, official results, and podium records.',
          style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 10),
        if (completedList.isEmpty)
          ElevatedActionCard(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: const Text(
              'No completed tournaments in history yet.',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          )
        else
          for (final item in completedList) ...[
            _buildTournamentListCard(context, item, isCompleted: true),
            const SizedBox(height: 10),
          ],
      ],
    );
  }

  Widget _buildTournamentListCard(
    BuildContext context,
    Map<String, dynamic> t, {
    required bool isCompleted,
  }) {
    final isReleased = t['isReleased'] == true;
    final validation = _validateCard1(t);
    final isCard1Complete = validation['isComplete'] == true;
    final doneCount = validation['doneCount'] as int;
    final totalCount = validation['totalCount'] as int;
    final displayName = (t['name']?.toString().trim().isNotEmpty == true)
        ? t['name'].toString()
        : 'Untitled Tournament Draft';

    return ElevatedActionCard(
      padding: const EdgeInsets.all(AppTheme.space16),
      borderColor: isCompleted
          ? AppTheme.borderSubtle
          : (isReleased
              ? AppTheme.emerald.withValues(alpha: 0.55)
              : AppTheme.goldPrimary.withValues(alpha: 0.55)),
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedTournamentId = t['id'].toString();
          _activeView = _OperatorSubView.tournamentHub;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  displayName,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(
                label: isCompleted
                    ? 'COMPLETED'
                    : (isReleased
                        ? 'RELEASED • OPEN'
                        : (isCard1Complete
                            ? 'DRAFT • READY TO RELEASE'
                            : 'UNRELEASED DRAFT ($doneCount/$totalCount)')),
                type: isCompleted
                    ? StatusType.neutral
                    : (isReleased ? StatusType.success : StatusType.warning),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 13, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${(t['venue']?.toString().trim().isNotEmpty == true) ? t['venue'] : 'Venue Pending'} • ${t['city'] ?? 'Lahore'}, ${t['province'] ?? 'Punjab'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDateReadable(t['startDate']),
                style: const TextStyle(
                  fontFamily: AppTheme.fontMono,
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
              Text(
                isReleased ? 'Open Hub (4 Cards Unlocked) →' : 'Open Hub (Cards 2-4 Locked) →',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isReleased ? AppTheme.emerald : AppTheme.goldPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. TOURNAMENT HUB SCREEN (4 Bold Dashboard Card Buttons + Strict Locking)
  // ===========================================================================
  Widget _buildTournamentHubScreen(
    BuildContext context,
    Map<String, dynamic> tournament,
    String operatorId,
  ) {
    final validation = _validateCard1(tournament);
    final isCard1Complete = validation['isComplete'] == true;
    final isReleased = tournament['isReleased'] == true;
    final areCards2To4Unlocked = isCard1Complete && isReleased;
    final doneCount = validation['doneCount'] as int;
    final totalCount = validation['totalCount'] as int;
    final divisionsCount = _expandSeparatedDivisions(tournament).length;
    final formatLabel = _formatSummaryLabel(tournament);
    final feePkr = tournament['entryFeePkr'];
    final feeText = (tournament['entryFeeConfigured'] == true && feePkr != null)
        ? ((feePkr as num) == 0 ? 'Free (0 PKR)' : 'PKR $feePkr')
        : 'Fee Pending';

    final displayName = (tournament['name']?.toString().trim().isNotEmpty == true)
        ? tournament['name'].toString()
        : 'Untitled Tournament Draft';

    final appliedAthletes = (tournament['appliedAthletes'] is List)
        ? (tournament['appliedAthletes'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];
    final verifiedWeighInCount = appliedAthletes
        .where((a) => a['weighInStatus'] == 'VERIFIED')
        .length;
    final unmatchWeighInCount = appliedAthletes
        .where((a) => a['weighInStatus'] == 'UNMATCH')
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space16,
        12,
        AppTheme.space16,
        36,
      ),
      children: [
        // Tournament Hub Header Card
        ElevatedActionCard(
          padding: const EdgeInsets.all(AppTheme.space16),
          borderColor: isReleased
              ? AppTheme.emerald.withValues(alpha: 0.6)
              : AppTheme.goldPrimary.withValues(alpha: 0.6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      displayName,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  StatusChip(
                    label: isReleased
                        ? 'RELEASED / SCHEDULED ✓'
                        : 'UNRELEASED DRAFT',
                    type: isReleased ? StatusType.success : StatusType.warning,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                isReleased
                    ? 'Published to athletes. All 4 Hub Cards are unlocked. You can still make permitted edits in Card 1.'
                    : 'Draft saved locally (hidden from athletes). Complete all mandatory details in Card 1 and tap "Release / Schedule" to unlock Cards 2, 3 & 4.',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              if (!isReleased)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    key: const ValueKey('hub_release_schedule_button'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCard1Complete
                          ? AppTheme.goldPrimary
                          : const Color(0x33FFFFFF),
                      foregroundColor:
                          isCard1Complete ? Colors.black : AppTheme.textSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                    ),
                    onPressed: () =>
                        _handleReleaseTournament(tournament, operatorId),
                    icon: Icon(
                      isCard1Complete
                          ? Icons.rocket_launch_rounded
                          : Icons.lock_clock_outlined,
                      size: 20,
                    ),
                    label: Text(
                      isCard1Complete
                          ? 'RELEASE / SCHEDULE TOURNAMENT (UNLOCK CARDS 2–4)'
                          : 'COMPLETE CARD 1 ($doneCount/$totalCount) TO RELEASE / SCHEDULE',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'TOURNAMENT HUB • 4 OPERATIONAL STAGES',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
            color: AppTheme.goldPrimary,
          ),
        ),
        const SizedBox(height: 10),

        // CARD 1: BASIC & MANDATORY DETAILS (Always Unlocked)
        _buildHubDashboardCardButton(
          key: const ValueKey('hub_card_1_basic_details'),
          cardNumber: 1,
          title: 'Basic & Mandatory Details',
          subtitle:
              'Schedule, Organization, Venue, R/L Weight Categories ($divisionsCount divisions), Format ($formatLabel), Tables (${tournament['tableCount']}), Referees, Fee ($feeText) & Awards ${(tournament['awardsConfig']?['isConfigured'] == true) ? "✓" : ""}',
          badgeText: isReleased
              ? 'RELEASED ✓ • EDITABLE'
              : (isCard1Complete
                  ? '100% FILLED • READY TO RELEASE'
                  : '$doneCount/$totalCount MANDATORY COMPLETED'),
          badgeColor: isReleased
              ? AppTheme.emerald
              : (isCard1Complete ? AppTheme.goldPrimary : AppTheme.warning),
          icon: Icons.tune_rounded,
          isLocked: false,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _activeView = _OperatorSubView.card1BasicDetails);
          },
        ),
        const SizedBox(height: 12),

        // CARD 2: APPLIED / REGISTERED ATHLETES (Locked until Card 1 complete + Released)
        _buildHubDashboardCardButton(
          key: const ValueKey('hub_card_2_applied_athletes'),
          cardNumber: 2,
          title: 'Applied / Registered Athletes',
          subtitle: areCards2To4Unlocked
              ? '${appliedAthletes.length} Applied Athletes • Horizontal Category Filter Bar ($divisionsCount R/L Categories) & Live Elo Ranking Carousel.'
              : 'LOCKED — Complete all mandatory fields in Card 1 and tap "Release / Schedule" to unlock.',
          badgeText: areCards2To4Unlocked
              ? 'UNLOCKED • ${appliedAthletes.length} APPLIED'
              : 'LOCKED 🔒',
          badgeColor:
              areCards2To4Unlocked ? AppTheme.cyan : AppTheme.textMuted,
          icon: Icons.groups_2_outlined,
          isLocked: !areCards2To4Unlocked,
          onTap: () {
            if (!areCards2To4Unlocked) {
              _showLockedCardToast();
              return;
            }
            HapticFeedback.selectionClick();
            setState(() => _activeView = _OperatorSubView.card2AppliedAthletes);
          },
        ),
        const SizedBox(height: 12),

        // CARD 3: MATCHUPS & BRACKETS (Locked until Card 1 complete + Released)
        _buildHubDashboardCardButton(
          key: const ValueKey('hub_card_3_matchups_brackets'),
          cardNumber: 3,
          title: 'Matchups & Brackets',
          subtitle: areCards2To4Unlocked
              ? 'Format: $formatLabel • ${tournament['tableCount']} Table(s) • Smart Random (Elo/PR/Lift), BYE, Free-Table Queue, Absent Skip & Auto 1st/2nd/3rd Podium.'
              : 'LOCKED — Format ($formatLabel) will configure bracket rules once released.',
          badgeText:
              areCards2To4Unlocked ? 'UNLOCKED • $formatLabel' : 'LOCKED 🔒',
          badgeColor:
              areCards2To4Unlocked ? AppTheme.goldPrimary : AppTheme.textMuted,
          icon: Icons.account_tree_outlined,
          isLocked: !areCards2To4Unlocked,
          onTap: () {
            if (!areCards2To4Unlocked) {
              _showLockedCardToast();
              return;
            }
            HapticFeedback.selectionClick();
            setState(() => _activeView = _OperatorSubView.card3MatchupsBrackets);
          },
        ),
        const SizedBox(height: 12),

        // CARD 4: WEIGH-IN VERIFICATION (Locked until Card 1 complete + Released)
        _buildHubDashboardCardButton(
          key: const ValueKey('hub_card_4_weigh_in'),
          cardNumber: 4,
          title: 'Weigh-In Verification',
          subtitle: areCards2To4Unlocked
              ? 'Official scale verification across $divisionsCount separated Left & Right Arm divisions ($verifiedWeighInCount Verified, $unmatchWeighInCount Unmatch).'
              : 'LOCKED — Complete Card 1 and click "Release / Schedule" to unlock Weigh-In Desk.',
          badgeText: areCards2To4Unlocked
              ? 'UNLOCKED • SCALE READY'
              : 'LOCKED 🔒',
          badgeColor:
              areCards2To4Unlocked ? AppTheme.emerald : AppTheme.textMuted,
          icon: Icons.scale_outlined,
          isLocked: !areCards2To4Unlocked,
          onTap: () {
            if (!areCards2To4Unlocked) {
              _showLockedCardToast();
              return;
            }
            HapticFeedback.selectionClick();
            setState(() {
              _selectedAthleteIdForWeighIn = null;
              _activeView = _OperatorSubView.card4WeighInVerification;
            });
          },
        ),
        const SizedBox(height: 18),

        const Text(
          'OPTIONAL VENUE ACCESS & SPECTATOR GATE',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
            color: AppTheme.cyan,
          ),
        ),
        const SizedBox(height: 10),

        // OPTIONAL FEATURE AREA: SPECTATOR ACCESS & VENUE ENTRANCE QR GATE
        ElevatedActionCard(
          key: const ValueKey('hub_spectator_entrance_qr_gate_card'),
          padding: const EdgeInsets.all(AppTheme.space16),
          borderColor: AppTheme.cyan.withValues(alpha: 0.65),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(
                () => _activeView = _OperatorSubView.spectatorEntranceQrGate);
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.cyan.withValues(alpha: 0.8),
                    width: 1.3,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    color: AppTheme.cyan,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'VENUE GATE & SPECTATOR PASSES',
                          style: TextStyle(
                            fontFamily: AppTheme.fontMono,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.cyan,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppTheme.cyan.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            '${(tournament['spectatorGateConfig']?['spectatorAccessMode'] ?? 'FREE')} • MAX ${tournament['spectatorGateConfig']?['allowedGuestsPerAthlete'] ?? 2} GUESTS',
                            style: const TextStyle(
                              fontFamily: AppTheme.fontMono,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.cyan,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Spectator Access & Venue Entrance QR Gate',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Configure Free/Paid Spectating (PKR), Athlete Friend/Guest allowance (0–4), and scan Athlete or Spectator QR passes at the venue entrance offline & online.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppTheme.cyan,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showLockedCardToast() {
    HapticFeedback.vibrate();
    ScaffoldMessenger.of(context).showSnackBar(
      CrystalSnackBar(
        content: const Text(
          'Card Locked: Complete all mandatory details in Card 1 AND click "Release / Schedule" first.',
        ),
        backgroundColor: AppTheme.warning,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildHubDashboardCardButton({
    required Key key,
    required int cardNumber,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required IconData icon,
    required bool isLocked,
    required VoidCallback onTap,
  }) {
    return Opacity(
      opacity: isLocked ? 0.62 : 1.0,
      child: ElevatedActionCard(
        key: key,
        padding: const EdgeInsets.all(AppTheme.space16),
        borderColor: isLocked
            ? const Color(0x28FFFFFF)
            : badgeColor.withValues(alpha: 0.65),
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isLocked
                      ? const Color(0x33FFFFFF)
                      : badgeColor.withValues(alpha: 0.8),
                  width: 1.3,
                ),
              ),
              child: Center(
                child: Icon(
                  isLocked ? Icons.lock_outline_rounded : icon,
                  color: isLocked ? AppTheme.textMuted : badgeColor,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'CARD $cardNumber',
                        style: TextStyle(
                          fontFamily: AppTheme.fontMono,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: isLocked ? AppTheme.textMuted : badgeColor,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: badgeColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontFamily: AppTheme.fontMono,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isLocked
                  ? Icons.lock_rounded
                  : Icons.arrow_forward_ios_rounded,
              size: 16,
              color: isLocked ? AppTheme.textMuted : badgeColor,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 3. CARD 1 — BASIC & MANDATORY DETAILS VIEW
// =============================================================================
class _Card1BasicDetailsView extends StatefulWidget {
  final Map<String, dynamic> tournament;
  final String autoSaveBannerText;
  final Map<String, dynamic> validation;
  final List<Map<String, String>> separatedDivisions;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final VoidCallback onOpenAwardsSubScreen;
  final VoidCallback onReleaseTournament;
  final VoidCallback onBackToHub;

  const _Card1BasicDetailsView({
    super.key,
    required this.tournament,
    required this.autoSaveBannerText,
    required this.validation,
    required this.separatedDivisions,
    required this.onChanged,
    required this.onOpenAwardsSubScreen,
    required this.onReleaseTournament,
    required this.onBackToHub,
  });

  @override
  State<_Card1BasicDetailsView> createState() => _Card1BasicDetailsViewState();
}

class _Card1BasicDetailsViewState extends State<_Card1BasicDetailsView> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _orgCtrl;
  late final TextEditingController _venueCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _maxAthletesCtrl;
  late final TextEditingController _entryFeeCtrl;
  late final TextEditingController _customWeightCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: (widget.tournament['name'] ?? '').toString(),
    );
    _orgCtrl = TextEditingController(
      text: (widget.tournament['organizationName'] ?? '').toString(),
    );
    _venueCtrl = TextEditingController(
      text: (widget.tournament['venue'] ?? '').toString(),
    );
    _cityCtrl = TextEditingController(
      text: (widget.tournament['city'] ?? 'Lahore').toString(),
    );
    _maxAthletesCtrl = TextEditingController(
      text: ((widget.tournament['capacity'] as num?)?.toInt() ?? 64).toString(),
    );
    final fee = widget.tournament['entryFeePkr'];
    _entryFeeCtrl = TextEditingController(
      text: (widget.tournament['entryFeeConfigured'] == true && fee != null)
          ? fee.toString()
          : '',
    );
    _customWeightCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _orgCtrl.dispose();
    _venueCtrl.dispose();
    _cityCtrl.dispose();
    _maxAthletesCtrl.dispose();
    _entryFeeCtrl.dispose();
    _customWeightCtrl.dispose();
    super.dispose();
  }

  void _emitPatch(Map<String, dynamic> patch) {
    final next = <String, dynamic>{
      ...widget.tournament,
      ...patch,
    };
    widget.onChanged(next);
  }

  Future<void> _pickScheduleDateTime() async {
    final initial =
        DateTime.tryParse(widget.tournament['startDate']?.toString() ?? '') ??
            DateTime.now().add(const Duration(days: 14));
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    final dt = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime?.hour ?? 10,
      pickedTime?.minute ?? 0,
    );
    _emitPatch({
      'startDate': dt.toIso8601String(),
      'endDate': dt.add(const Duration(hours: 8)).toIso8601String(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tournament;
    final v = widget.validation;
    final isComplete = v['isComplete'] == true;
    final isReleased = t['isReleased'] == true;
    final weightCategories = (t['weightCategories'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        <Map<String, dynamic>>[];
    final formatCat = (t['formatCategory'] ?? '').toString();
    final elimSub = (t['eliminationSubFormat'] ?? '').toString();
    final int tableCount = ((t['tableCount'] as num?)?.toInt() ?? 1).clamp(1, 12);
    final assignMode = (t['tableAssignmentMode'] ?? '').toString();
    final tables = (t['tables'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        <Map<String, dynamic>>[];
    final awardsConfig = t['awardsConfig'] is Map
        ? Map<String, dynamic>.from(t['awardsConfig'] as Map)
        : <String, dynamic>{};
    final isAwardsConfigured = awardsConfig['isConfigured'] == true;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space16,
        12,
        AppTheme.space16,
        40,
      ),
      children: [
        // Auto-save status banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(color: AppTheme.goldPrimary.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: [
              const Icon(Icons.cloud_done_outlined,
                  size: 16, color: AppTheme.goldPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AUTO-SAVING DRAFT • ${widget.autoSaveBannerText}',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontMono,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.goldPrimary,
                  ),
                ),
              ),
              Text(
                '${v['doneCount']}/${v['totalCount']} READY',
                style: const TextStyle(
                  fontFamily: AppTheme.fontMono,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.emerald,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // SECTION 1: BASIC INFO
        _buildSectionCard(
          stepLabel: '1. BASIC & MANDATORY INFO',
          isValid: v['basicValid'] == true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Event / Tournament Name *',
                  hintText: 'e.g. Punjab National Open Championship',
                  prefixIcon: Icon(Icons.emoji_events_outlined, size: 18),
                ),
                onChanged: (val) => _emitPatch({'name': val}),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _orgCtrl,
                decoration: const InputDecoration(
                  labelText: 'Organization Name *',
                  hintText: 'e.g. Pakistan Arm-Wrestling Federation',
                  prefixIcon: Icon(Icons.shield_outlined, size: 18),
                ),
                onChanged: (val) => _emitPatch({'organizationName': val}),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _kPakistanProvinces.contains(t['province'])
                          ? t['province'].toString()
                          : _kPakistanProvinces.first,
                      decoration: const InputDecoration(labelText: 'Province *'),
                      items: [
                        for (final p in _kPakistanProvinces)
                          DropdownMenuItem(value: p, child: Text(p)),
                      ],
                      onChanged: (val) {
                        if (val != null) _emitPatch({'province': val});
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _cityCtrl,
                      decoration: const InputDecoration(labelText: 'City *'),
                      onChanged: (val) => _emitPatch({'city': val}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _venueCtrl,
                decoration: const InputDecoration(
                  labelText: 'Venue Location *',
                  hintText: 'e.g. Nishtar Park Sports Complex Arena',
                  prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                ),
                onChanged: (val) => _emitPatch({'venue': val}),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: OutlinedButton.icon(
                      onPressed: _pickScheduleDateTime,
                      icon: const Icon(Icons.calendar_month_outlined, size: 16),
                      label: Text(
                        'Schedule: ${t['startDate']?.toString().substring(0, 16).replaceAll('T', ' ') ?? 'Select'}',
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _maxAthletesCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Max Athletes *',
                      ),
                      onChanged: (val) {
                        final parsed = int.tryParse(val.trim()) ?? 0;
                        _emitPatch({'capacity': parsed});
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // SECTION 2: WEIGHT CATEGORIES & ARM/HAND SUPPORT
        _buildSectionCard(
          stepLabel: '2. WEIGHT CATEGORIES & ARM DIVISION (R / L / BOTH)',
          isValid: v['weightsValid'] == true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Toggle weight categories and specify Right Arm, Left Arm, or Both (Left and Right divisions stay cleanly separated).',
                style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 10),
              for (int idx = 0; idx < weightCategories.length; idx++) ...[
                _buildWeightCategoryRow(weightCategories, idx),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customWeightCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Add Custom Weight Category (e.g. 65 kg, 100+ kg)',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      final label = _customWeightCtrl.text.trim();
                      if (label.isEmpty) return;
                      final updated = [
                        ...weightCategories,
                        {
                          'id': 'wc_${DateTime.now().millisecondsSinceEpoch}',
                          'label': label,
                          'enabled': true,
                          'arm': 'BOTH',
                        },
                      ];
                      _customWeightCtrl.clear();
                      _emitPatch({'weightCategories': updated});
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('ADD'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Active Separated Divisions (${widget.separatedDivisions.length}): ${widget.separatedDivisions.map((d) => d['label']).join('  |  ')}',
                style: const TextStyle(
                  fontFamily: AppTheme.fontMono,
                  fontSize: 10.5,
                  color: AppTheme.goldPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // SECTION 3: MANDATORY TOURNAMENT / MATCH FORMAT TYPE
        _buildSectionCard(
          stepLabel: '3. MANDATORY TOURNAMENT / MATCH FORMAT TYPE',
          isValid: v['formatValid'] == true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selecting the format here automatically controls which filters and bracket rules appear later on Card 3.',
                style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildSelectableFormatTile(
                      title: 'SUPERFIGHTS',
                      subtitle: 'Single Bouts / Vendetta Supermatches',
                      selected: formatCat == 'SUPERFIGHTS',
                      onTap: () => _emitPatch({
                        'formatCategory': 'SUPERFIGHTS',
                        'eliminationSubFormat': '',
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSelectableFormatTile(
                      title: 'ELIMINATION',
                      subtitle: 'Bracket Tournament Progression',
                      selected: formatCat == 'ELIMINATION',
                      onTap: () => _emitPatch({
                        'formatCategory': 'ELIMINATION',
                        'eliminationSubFormat': elimSub.isNotEmpty
                            ? elimSub
                            : 'DOUBLE_ELIMINATION',
                      }),
                    ),
                  ),
                ],
              ),
              if (formatCat == 'ELIMINATION') ...[
                const SizedBox(height: 12),
                const Text(
                  'SELECT ELIMINATION BRACKET FORMAT:',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.goldPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                for (final opt in const [
                  ('SINGLE_ELIMINATION', 'Single / One-Loss Elimination'),
                  ('DOUBLE_ELIMINATION', 'Double / Two-Loss Elimination'),
                  ('THREE_LOSS_ELIMINATION', 'Three-Loss Elimination'),
                  (
                    'LAST_ONE_STANDING',
                    'Last-One-Standing (Whoever lasts in category wins)'
                  ),
                ]) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _buildSelectableFormatTile(
                      title: opt.$2,
                      subtitle: 'Controls Card 3 bracket & elimination rules',
                      selected: elimSub == opt.$1,
                      onTap: () => _emitPatch({
                        'formatCategory': 'ELIMINATION',
                        'eliminationSubFormat': opt.$1,
                      }),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // SECTION 4: NUMBER OF TABLES & MANDATORY TABLE ASSIGNMENT MODE
        _buildSectionCard(
          stepLabel: '4. NO. OF TABLES & TABLE ASSIGNMENT MODE',
          isValid: v['tablesValid'] == true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'No. of Arena Tables',
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: tableCount > 1
                            ? () => _emitPatch({
                                  'tableCount': tableCount - 1,
                                  if (tableCount - 1 == 1)
                                    'tableAssignmentMode': 'SINGLE_TABLE_DEFAULT',
                                })
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        '$tableCount ${tableCount == 1 ? "TABLE" : "TABLES"}',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontMono,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.goldPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: tableCount < 10
                            ? () => _emitPatch({
                                  'tableCount': tableCount + 1,
                                  if (assignMode == 'SINGLE_TABLE_DEFAULT')
                                    'tableAssignmentMode': '',
                                })
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ],
              ),
              if (tableCount > 1) ...[
                const SizedBox(height: 10),
                const Text(
                  'MANDATORY TABLE ASSIGNMENT MODE (FOR > 1 TABLES):',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.goldPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                for (final mode in const [
                  (
                    'CATEGORY_BY_TABLE',
                    'Option 1: Category-by-Table',
                    'Table 1 is for specific weight categories, Table 2 (etc.) for other weight categories.'
                  ),
                  (
                    'RANDOM_BY_APP',
                    'Option 2: Random by App',
                    'Random categories/players distributed across Table 1, Table 2, etc. by the app.'
                  ),
                  (
                    'DYNAMIC_FREE_TABLE_QUEUE',
                    'Option 3: Dynamic Free-Table Queue',
                    'As matches finish and a referee submits the result, that table is freed and assigned the next matchup.'
                  ),
                ]) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _buildSelectableFormatTile(
                      title: mode.$2,
                      subtitle: mode.$3,
                      selected: assignMode == mode.$1,
                      onTap: () => _emitPatch({'tableAssignmentMode': mode.$1}),
                    ),
                  ),
                ],
                if (assignMode == 'CATEGORY_BY_TABLE') ...[
                  const SizedBox(height: 8),
                  for (int ti = 0; ti < tables.length; ti++) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0x33FFFFFF)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${tables[ti]['tableName']} — Assigned Weight Categories:',
                            style: const TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.goldPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final div in widget.separatedDivisions)
                                FilterChip(
                                  label: Text(
                                    div['label']!,
                                    style: const TextStyle(fontSize: 10.5),
                                  ),
                                  selected: ((tables[ti]
                                              ['assignedCategoryDivisionIds']
                                          as List?) ??
                                      const [])
                                      .contains(div['divisionId']),
                                  onSelected: (sel) {
                                    final nextTables = tables
                                        .map((e) => Map<String, dynamic>.from(e))
                                        .toList();
                                    final currentIds = List<String>.from(
                                      (nextTables[ti]
                                                  ['assignedCategoryDivisionIds']
                                              as List?) ??
                                          const [],
                                    );
                                    if (sel) {
                                      currentIds.add(div['divisionId']!);
                                    } else {
                                      currentIds.remove(div['divisionId']!);
                                    }
                                    nextTables[ti]
                                        ['assignedCategoryDivisionIds'] = currentIds;
                                    _emitPatch({'tables': nextTables});
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // SECTION 5: MANDATORY REFEREE SELECTION (Min 2 Referees per Table)
        _buildSectionCard(
          stepLabel: '5. MANDATORY REFEREE SELECTION (MIN 2 PER TABLE)',
          isValid: v['refereesValid'] == true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select certified referees for each table (minimum 2 referees per table required).',
                style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 10),
              for (int ti = 0; ti < tables.length; ti++) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (((tables[ti]['assignedRefereeIds'] as List?)
                                      ?.length ??
                                  0) >=
                              2)
                          ? AppTheme.emerald.withValues(alpha: 0.5)
                          : AppTheme.warning.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${tables[ti]['tableName']} Referees',
                            style: const TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            '${((tables[ti]['assignedRefereeIds'] as List?) ?? const []).length}/2+ Selected',
                            style: TextStyle(
                              fontFamily: AppTheme.fontMono,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: (((tables[ti]['assignedRefereeIds']
                                                  as List?)
                                              ?.length ??
                                          0) >=
                                      2)
                                  ? AppTheme.emerald
                                  : AppTheme.warning,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final refItem in _kDefaultRefereePool)
                            FilterChip(
                              label: Text(
                                refItem['name']!,
                                style: const TextStyle(fontSize: 11),
                              ),
                              selected: ((tables[ti]['assignedRefereeIds']
                                          as List?) ??
                                      const [])
                                  .contains(refItem['id']),
                              onSelected: (sel) {
                                final nextTables = tables
                                    .map((e) => Map<String, dynamic>.from(e))
                                    .toList();
                                final refIds = List<String>.from(
                                  (nextTables[ti]['assignedRefereeIds']
                                          as List?) ??
                                      const [],
                                );
                                if (sel) {
                                  refIds.add(refItem['id']!);
                                } else {
                                  refIds.remove(refItem['id']!);
                                }
                                nextTables[ti]['assignedRefereeIds'] = refIds;
                                _emitPatch({'tables': nextTables});
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // SECTION 6: MANDATORY ENTRY / APPLICATION FEE IN PKR
        _buildSectionCard(
          stepLabel: '6. MANDATORY ENTRY / APPLICATION FEE (PKR)',
          isValid: v['entryFeeValid'] == true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Specify cost for athletes to apply/submit in PKR (enter 0 for free entry, or any PKR amount).',
                style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final preset in const [0, 1000, 1500, 2500, 5000])
                    ChoiceChip(
                      label: Text(
                        preset == 0 ? '0 PKR (Free)' : 'PKR $preset',
                        style: const TextStyle(fontSize: 11),
                      ),
                      selected: t['entryFeeConfigured'] == true &&
                          t['entryFeePkr'] == preset,
                      onSelected: (_) {
                        _entryFeeCtrl.text = preset.toString();
                        _emitPatch({
                          'entryFeePkr': preset,
                          'entryFeeConfigured': true,
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _entryFeeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Entry / Application Fee in PKR *',
                  hintText: 'Enter 0 for Free, or e.g. 1500',
                  prefixIcon: Icon(Icons.payments_outlined, size: 18),
                ),
                onChanged: (val) {
                  final trimmed = val.trim();
                  if (trimmed.isEmpty) {
                    _emitPatch({
                      'entryFeePkr': null,
                      'entryFeeConfigured': false,
                    });
                    return;
                  }
                  final parsed = int.tryParse(trimmed);
                  if (parsed != null && parsed >= 0) {
                    _emitPatch({
                      'entryFeePkr': parsed,
                      'entryFeeConfigured': true,
                    });
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // SECTION 7: SEPARATE AWARDS & PRIZES SUB-SCREEN BUTTON (Inside Card 1)
        ElevatedActionCard(
          key: const ValueKey('card1_open_awards_subscreen_button'),
          padding: const EdgeInsets.all(AppTheme.space16),
          borderColor: isAwardsConfigured
              ? AppTheme.emerald.withValues(alpha: 0.7)
              : AppTheme.goldPrimary.withValues(alpha: 0.6),
          onTap: widget.onOpenAwardsSubScreen,
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isAwardsConfigured
                        ? AppTheme.emerald
                        : AppTheme.goldPrimary,
                  ),
                ),
                child: Icon(
                  isAwardsConfigured
                      ? Icons.check_circle_rounded
                      : Icons.emoji_events_outlined,
                  color: isAwardsConfigured
                      ? AppTheme.emerald
                      : AppTheme.goldPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '7. AWARDS & PRIZES SUB-SCREEN',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isAwardsConfigured)
                          const StatusChip(
                            label: 'CONFIGURED ✓',
                            type: StatusType.success,
                          )
                        else
                          const StatusChip(
                            label: 'REQUIRED',
                            type: StatusType.warning,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAwardsConfigured
                          ? '✓ Saved: ${awardsConfig['rewardType'] == 'CASH_PKR' ? 'Cash Prizes (PKR)' : (awardsConfig['rewardType'] == 'AWARDS' ? 'Medals & Trophies' : 'Cash (PKR) + Awards')} • ${awardsConfig['winnerStructure'] == 'OVERALL_WINNERS' ? 'Overall Tournament Winners' : 'Per-Category Winners'}'
                          : 'Tap to open dedicated sub-screen: configure Money/Cash (PKR) or Awards for Overall or Per-Category Winners.',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: AppTheme.goldPrimary),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // RELEASE / SCHEDULE BUTTON
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            key: const ValueKey('card1_release_schedule_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isComplete
                  ? AppTheme.goldPrimary
                  : const Color(0x33FFFFFF),
              foregroundColor: isComplete ? Colors.black : AppTheme.textSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
            onPressed: widget.onReleaseTournament,
            icon: Icon(
              isReleased
                  ? Icons.verified_rounded
                  : (isComplete
                      ? Icons.rocket_launch_rounded
                      : Icons.lock_clock_outlined),
            ),
            label: Text(
              isReleased
                  ? 'SAVE & UPDATE RELEASED TOURNAMENT'
                  : (isComplete
                      ? 'RELEASE / SCHEDULE (UNLOCK CARDS 2–4)'
                      : 'FILL ALL 7 SECTIONS TO RELEASE (${v['doneCount']}/${v['totalCount']})'),
              style: const TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeightCategoryRow(
    List<Map<String, dynamic>> categories,
    int index,
  ) {
    final item = categories[index];
    final enabled = item['enabled'] == true;
    final arm = (item['arm']?.toString() ?? 'BOTH').toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: enabled
              ? AppTheme.goldPrimary.withValues(alpha: 0.55)
              : const Color(0x22FFFFFF),
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: enabled,
            activeColor: AppTheme.goldPrimary,
            checkColor: Colors.black,
            onChanged: (v) {
              final next = categories
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList();
              next[index]['enabled'] = v ?? false;
              _emitPatch({'weightCategories': next});
            },
          ),
          Expanded(
            child: Text(
              item['label']?.toString() ?? '',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
                color: enabled ? AppTheme.textPrimary : AppTheme.textMuted,
              ),
            ),
          ),
          for (final armOpt in const [
            ('RIGHT', 'Right'),
            ('LEFT', 'Left'),
            ('BOTH', 'Both (R+L)'),
          ])
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: ChoiceChip(
                label: Text(
                  armOpt.$2,
                  style: const TextStyle(fontSize: 10.5),
                ),
                selected: enabled && arm == armOpt.$1,
                onSelected: enabled
                    ? (_) {
                        final next = categories
                            .map((e) => Map<String, dynamic>.from(e))
                            .toList();
                        next[index]['arm'] = armOpt.$1;
                        _emitPatch({'weightCategories': next});
                      }
                    : null,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectableFormatTile({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppTheme.goldPrimary : const Color(0x33FFFFFF),
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 18,
              color: selected ? AppTheme.goldPrimary : AppTheme.textMuted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: selected
                          ? AppTheme.goldPrimary
                          : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String stepLabel,
    required bool isValid,
    required Widget child,
  }) {
    return ElevatedActionCard(
      padding: const EdgeInsets.all(AppTheme.space16),
      borderColor: isValid
          ? AppTheme.emerald.withValues(alpha: 0.45)
          : AppTheme.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  stepLabel,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    color: AppTheme.goldPrimary,
                  ),
                ),
              ),
              StatusChip(
                label: isValid ? 'READY ✓' : 'REQUIRED',
                type: isValid ? StatusType.success : StatusType.warning,
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// =============================================================================
// 4. SEPARATE AWARDS & PRIZES SUB-SCREEN (Inside Card 1)
// =============================================================================
class _AwardsPrizesSubScreenView extends StatefulWidget {
  final Map<String, dynamic> tournament;
  final ValueChanged<Map<String, dynamic>> onSaveAwards;
  final VoidCallback onCancel;

  const _AwardsPrizesSubScreenView({
    super.key,
    required this.tournament,
    required this.onSaveAwards,
    required this.onCancel,
  });

  @override
  State<_AwardsPrizesSubScreenView> createState() =>
      _AwardsPrizesSubScreenViewState();
}

class _AwardsPrizesSubScreenViewState
    extends State<_AwardsPrizesSubScreenView> {
  late String _rewardType; // 'CASH_PKR' | 'AWARDS' | 'CASH_AND_AWARDS'
  late String _winnerStructure; // 'OVERALL_WINNERS' | 'PER_CATEGORY_WINNERS'
  late int _topNCount;
  late List<Map<String, dynamic>> _tiers;

  @override
  void initState() {
    super.initState();
    final cfg = widget.tournament['awardsConfig'] is Map
        ? Map<String, dynamic>.from(widget.tournament['awardsConfig'] as Map)
        : <String, dynamic>{};
    _rewardType = (cfg['rewardType'] ?? 'CASH_PKR').toString();
    _winnerStructure =
        (cfg['winnerStructure'] ?? 'PER_CATEGORY_WINNERS').toString();
    _topNCount = ((cfg['topNCount'] as num?)?.toInt() ?? 3).clamp(1, 5);
    final rawTiers = (cfg['tiers'] is List)
        ? (cfg['tiers'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList()
        : <Map<String, dynamic>>[];
    _tiers = _syncTiersCount(_topNCount, rawTiers);
  }

  List<Map<String, dynamic>> _syncTiersCount(
    int count,
    List<Map<String, dynamic>> existing,
  ) {
    final result = <Map<String, dynamic>>[];
    for (int pos = 1; pos <= count; pos++) {
      final found = existing.where((t) => t['position'] == pos).firstOrNull;
      result.add({
        'position': pos,
        'label': found?['label']?.toString() ??
            (pos == 1
                ? '1st Place Winner'
                : (pos == 2
                    ? '2nd Place Runner-Up'
                    : (pos == 3 ? '3rd Place Podium' : 'Top $pos Place'))),
        'cashAmountPkr': (found?['cashAmountPkr'] as num?)?.toInt() ??
            (pos == 1 ? 25000 : (pos == 2 ? 15000 : 5000)),
        'awardTitle': found?['awardTitle']?.toString() ??
            (pos == 1
                ? 'Gold Medal & Champion Trophy'
                : (pos == 2 ? 'Silver Medal' : 'Bronze Medal')),
      });
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space16,
        12,
        AppTheme.space16,
        40,
      ),
      children: [
        ElevatedActionCard(
          padding: const EdgeInsets.all(AppTheme.space16),
          borderColor: AppTheme.goldPrimary.withValues(alpha: 0.6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AWARDS & PRIZES CONFIGURATION',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.goldPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose whether prizes are Money/Cash (with exact PKR amounts) or Awards, and configure the winner structure (Overall Tournament Winners or Per-Category Winners).',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),

              // 1. Prize Type Selector
              const Text(
                '1. PRIZE / REWARD TYPE',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Money / Cash (PKR)'),
                    selected: _rewardType == 'CASH_PKR',
                    onSelected: (_) => setState(() => _rewardType = 'CASH_PKR'),
                  ),
                  ChoiceChip(
                    label: const Text('Awards (Medals / Trophies)'),
                    selected: _rewardType == 'AWARDS',
                    onSelected: (_) => setState(() => _rewardType = 'AWARDS'),
                  ),
                  ChoiceChip(
                    label: const Text('Both Cash (PKR) + Awards'),
                    selected: _rewardType == 'CASH_AND_AWARDS',
                    onSelected: (_) =>
                        setState(() => _rewardType = 'CASH_AND_AWARDS'),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 2. Winner Structure Selector
              const Text(
                '2. WINNER STRUCTURE',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Overall Tournament Winners (e.g. Top 3 Overall)'),
                    selected: _winnerStructure == 'OVERALL_WINNERS',
                    onSelected: (_) =>
                        setState(() => _winnerStructure = 'OVERALL_WINNERS'),
                  ),
                  ChoiceChip(
                    label: const Text('Per-Category Winners (1st, 2nd, 3rd in Each Category)'),
                    selected: _winnerStructure == 'PER_CATEGORY_WINNERS',
                    onSelected: (_) => setState(
                        () => _winnerStructure = 'PER_CATEGORY_WINNERS'),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 3. Number of Winning Positions (Top 1 / Top 3 / Top N)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '3. NUMBER OF WINNING POSITIONS (TOP N)',
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final n in const [1, 2, 3, 4, 5])
                        ChoiceChip(
                          label: Text('Top $n'),
                          selected: _topNCount == n,
                          onSelected: (_) {
                            setState(() {
                              _topNCount = n;
                              _tiers = _syncTiersCount(n, _tiers);
                            });
                          },
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 4. Position Amounts & Titles
              for (int i = 0; i < _tiers.length; i++) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0x33FFFFFF)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Position #${_tiers[i]['position']} — ${_tiers[i]['label']}',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppTheme.goldPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_rewardType == 'CASH_PKR' ||
                          _rewardType == 'CASH_AND_AWARDS') ...[
                        TextFormField(
                          initialValue:
                              _tiers[i]['cashAmountPkr']?.toString() ?? '0',
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Cash Prize Amount (PKR) *',
                            prefixIcon: Icon(Icons.payments_outlined, size: 18),
                          ),
                          onChanged: (val) {
                            _tiers[i]['cashAmountPkr'] =
                                int.tryParse(val.trim()) ?? 0;
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (_rewardType == 'AWARDS' ||
                          _rewardType == 'CASH_AND_AWARDS') ...[
                        TextFormField(
                          initialValue:
                              _tiers[i]['awardTitle']?.toString() ?? '',
                          decoration: const InputDecoration(
                            labelText: 'Award / Medal / Trophy Description *',
                            prefixIcon:
                                Icon(Icons.emoji_events_outlined, size: 18),
                          ),
                          onChanged: (val) {
                            _tiers[i]['awardTitle'] = val;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onCancel,
                      child: const Text('BACK TO CARD 1'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        key: const ValueKey('save_awards_prizes_button'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.goldPrimary,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          widget.onSaveAwards({
                            'isConfigured': true,
                            'rewardType': _rewardType,
                            'winnerStructure': _winnerStructure,
                            'topNCount': _topNCount,
                            'tiers': _tiers,
                          });
                        },
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: const Text(
                          'SAVE AWARDS & PRIZES (✓)',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
