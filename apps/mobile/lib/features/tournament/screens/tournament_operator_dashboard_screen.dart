import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/providers/dependency_providers.dart';
import '../../../core/storage/hive_storage.dart';
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
  {
    'id': 'ath-pk-101',
    'name': 'Hamza Tariq',
    'club': 'Lahore Titans • Lahore',
    'elo': '1865',
    'badge': 'Athlete & Certified Referee • Lahore Titans',
  },
  {
    'id': 'ath-pk-102',
    'name': 'Shahzaib Baloch',
    'club': 'Quetta Grizzlies • Quetta',
    'elo': '1795',
    'badge': 'Athlete & Certified Referee • Quetta Grizzlies',
  },
  {
    'id': 'ath-pk-103',
    'name': 'Zain Ul Abideen',
    'club': 'Islamabad Vipers • Islamabad',
    'elo': '1740',
    'badge': 'Athlete & Certified Referee • Islamabad Vipers',
  },
  {
    'id': 'ath-pk-106',
    'name': 'Murtaza Afridi',
    'club': 'Khyber Iron Grip • Peshawar',
    'elo': '1760',
    'badge': 'Athlete & Certified Referee • Khyber Iron Grip',
  },
  {
    'id': 'ath-pk-108',
    'name': 'Asadullah Khan',
    'club': 'Rawalpindi Forge • Rawalpindi',
    'elo': '1810',
    'badge': 'Athlete & Certified Referee • Rawalpindi Forge',
  },
  {
    'id': 'ath-pk-109',
    'name': 'Sikandar Hayat',
    'club': 'Multan Royals • Multan',
    'elo': '1725',
    'badge': 'Athlete & Certified Referee • Multan Royals',
  },
  {
    'id': 'ath-pk-104',
    'name': 'Taimoor Jutt',
    'club': 'Gujranwala Lions • Gujranwala',
    'elo': '1690',
    'badge': 'Athlete & Certified Referee • Gujranwala Lions',
  },
  {
    'id': 'ath-pk-107',
    'name': 'Daniyal Qureshi',
    'club': 'Karachi Wolves • Karachi',
    'elo': '1685',
    'badge': 'Athlete & Certified Referee • Karachi Wolves',
  },
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
        'rewardType': 'CASH_PKR',
        'winnerStructure': 'PER_CATEGORY_WINNERS', // 'OVERALL_WINNERS' | 'PER_CATEGORY_WINNERS'
        'topNCount': 3,
        'tiers': <Map<String, dynamic>>[
          {
            'position': 1,
            'label': '1st Place Winner',
            'cashAmountPkr': 25000,
            'awardTitle': 'Cash Prize',
          },
          {
            'position': 2,
            'label': '2nd Place Runner-Up',
            'cashAmountPkr': 15000,
            'awardTitle': 'Cash Prize',
          },
          {
            'position': 3,
            'label': '3rd Place Podium',
            'cashAmountPkr': 7500,
            'awardTitle': 'Cash Prize',
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
            : (isReleased ? <String>['ath-pk-101', 'ath-pk-102'] : <String>[]),
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
                'awardTitle': 'Cash Prize',
              },
              {
                'position': 2,
                'label': '2nd Place Runner-Up',
                'cashAmountPkr': 15000,
                'awardTitle': 'Cash Prize',
              },
              {
                'position': 3,
                'label': '3rd Place Podium',
                'cashAmountPkr': 7500,
                'awardTitle': 'Cash Prize',
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
        'isReferee': true,
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
        'isReferee': true,
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
        'isReferee': true,
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
        'isReferee': true,
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
        'isReferee': false,
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
        'isReferee': true,
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
        'isReferee': true,
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
        'isReferee': true,
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
        'isReferee': true,
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
        'isReferee': false,
      },
    ];

    return templates.map((t) {
      final cat = t['categoryLabel'].toString();
      final parts = cat.split('•');
      final wClass = parts.first.trim();
      final arm = parts.length > 1 ? parts.last.trim() : 'Right Arm';
      final qr = 'ARMSPHERE-QR:${t['id']}:${t['athleteId']}:$cat';
      return <String, dynamic>{
        ...t,
        'registrationId': t['id'],
        'name': t['athleteName'],
        'club': t['clubName'],
        'elo': t['eloRating'],
        'weightClass': wClass,
        'registeredWeightLabel': wClass,
        'arm': arm,
        'registeredArm': arm,
        'qrCode': qr,
        'qrCodePayload': qr,
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
    if (cat == 'SUPERFIGHTS') return 'Superfights';
    if (cat == 'ELIMINATION') {
      switch (sub) {
        case 'SINGLE_ELIMINATION':
          return 'Single Elim';
        case 'DOUBLE_ELIMINATION':
          return 'Double Elim';
        case 'THREE_LOSS_ELIMINATION':
          return 'Triple Elim';
        case 'LAST_ONE_STANDING':
          return 'Last Standing';
      }
    }
    return 'Double Elim';
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

    final mergedForHeader = _mergeServerAndLocalTournaments(
      tournamentsAsync.valueOrNull ?? const [],
      operatorId,
      authState,
      profile,
    );
    final currentTournament = mergedForHeader
            .where((t) => t['id']?.toString() == _selectedTournamentId)
            .firstOrNull ??
        (mergedForHeader.isNotEmpty ? mergedForHeader.first : null);

    return PopScope(
      canPop: _activeView == _OperatorSubView.mainList,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        FocusManager.instance.primaryFocus?.unfocus();
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
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          backgroundColor: AppTheme.voidBackground,
          extendBodyBehindAppBar: true,
          appBar: _buildAppBar(
            context,
            operatorName,
            operatorId,
            profile,
            currentTournament,
          ),
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

    // Overlay local offline drafts & edits so zero input is ever lost,
    // and sync latest referee match results from TournamentOfflineStore for released events.
    HiveStorage? hive;
    try {
      hive = ref.read(hiveStorageProvider);
    } catch (_) {}

    for (final entry in localMap.entries) {
      var norm = _normalizeTournamentRecord(entry.value, operatorId);
      if (norm['isReleased'] == true) {
        final storeCopy = TournamentOfflineStore.getReleasedTournamentById(
          hive: hive,
          tournamentId: entry.key,
        );
        if (storeCopy != null) {
          norm = <String, dynamic>{
            ...norm,
            if (storeCopy['card3MatchupsState'] != null)
              'card3MatchupsState': storeCopy['card3MatchupsState'],
            if (storeCopy['appliedAthletes'] != null)
              'appliedAthletes': storeCopy['appliedAthletes'],
            if (storeCopy['matchups'] != null)
              'matchups': storeCopy['matchups'],
          };
          localMap[entry.key] = norm;
        }
      }
      combinedById[entry.key] = norm;
    }

    return combinedById.values.toList();
  }

  Widget _buildSingleBackNavButton(BuildContext context) {
    return IconButton(
      key: const ValueKey('operator_step1_back_button'),
      icon: const Icon(
        Icons.arrow_back_ios_new_rounded,
        color: AppTheme.goldPrimary,
        size: 18,
      ),
      tooltip: 'Back',
      onPressed: () {
        FocusManager.instance.primaryFocus?.unfocus();
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
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    String operatorName,
    String operatorId,
    Map<String, dynamic> profile,
    Map<String, dynamic>? currentTournament,
  ) {
    // Stage 1: ONLY show the back navigation button and the text "Event & Division Setup"
    if (_activeView == _OperatorSubView.card1BasicDetails) {
      return AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: _buildSingleBackNavButton(context),
        titleSpacing: 4,
        title: const HoldToInspectText(
          title: 'Stage 01 Header',
          fullText: 'Event & Division Setup',
          child: Text(
            'Event & Division Setup',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        actions: const [],
      );
    }

    // Stage 1 Awards Sub-Screen: ONLY show back button and "Cash Prize Setup"
    if (_activeView == _OperatorSubView.awardsPrizesSubScreen) {
      return AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: _buildSingleBackNavButton(context),
        titleSpacing: 4,
        title: const HoldToInspectText(
          title: 'Cash Prize Setup',
          fullText: 'Cash Prize Setup (PKR)',
          child: Text(
            'Cash Prize Setup',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        actions: const [],
      );
    }

    // Stage 2: ONLY show one back button, "+ Athlete" button on top-left, and "Athlete Registry" text
    if (_activeView == _OperatorSubView.card2AppliedAthletes) {
      return AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: _buildSingleBackNavButton(context),
        titleSpacing: 0,
        title: Row(
          children: [
            if (currentTournament != null) ...[
              HoldToInspectText(
                title: 'Add Athlete',
                fullText: 'Register a new athlete into this tournament',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: const ValueKey('card2_register_athlete_button'),
                    onTap: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      HapticFeedback.selectionClick();
                      final currentAthletes =
                          (currentTournament['appliedAthletes'] is List)
                              ? (currentTournament['appliedAthletes'] as List)
                                  .whereType<Map>()
                                  .map((e) => Map<String, dynamic>.from(e))
                                  .toList()
                              : _seedDefaultAppliedAthletes(currentTournament);
                      Card2AppliedAthletesView.showRegisterAthleteModal(
                        context: context,
                        tournament: currentTournament,
                        separatedDivisions:
                            _expandSeparatedDivisions(currentTournament),
                        appliedAthletes: currentAthletes,
                        onUpdateAthletes: (updatedAthletes) async {
                          final updatedTournament = <String, dynamic>{
                            ...currentTournament,
                            'appliedAthletes': updatedAthletes,
                          };
                          await _enqueueAndPersistHubAction(
                            updatedTournament: updatedTournament,
                            operatorId: operatorId,
                            actionType: 'SUBMIT_ATHLETE_APPLICATION',
                            endpoint: '/tournaments/registrations',
                            syncPayload: {
                              'eventId': currentTournament['id'],
                              'athleteCount': updatedAthletes.length,
                            },
                            bannerMessage:
                                'Saved / Done • Applied Athletes Roster Cached',
                          );
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0x38D4AF37),
                            Color(0xE6070A11),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.goldPrimary,
                          width: 1.2,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_add_alt_1_rounded,
                            size: 14,
                            color: AppTheme.goldPrimary,
                          ),
                          SizedBox(width: 5),
                          Text(
                            '+ Athlete',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            const Expanded(
              child: HoldToInspectText(
                title: 'Stage 02 Header',
                fullText: 'Athlete Registry',
                child: Text(
                  'Athlete Registry',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 17.5,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: const [],
      );
    }

    // Stage 4: ONLY show one back button and the text "Weigh-In Verification"
    if (_activeView == _OperatorSubView.card4WeighInVerification) {
      return AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: _buildSingleBackNavButton(context),
        titleSpacing: 4,
        title: const HoldToInspectText(
          title: 'Stage 04 Header',
          fullText: 'Weigh-In Verification',
          child: Text(
            'Weigh-In Verification',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        actions: const [],
      );
    }

    // Stage 3 & Spectator Gate: Clean single back button + title
    if (_activeView == _OperatorSubView.card3MatchupsBrackets ||
        _activeView == _OperatorSubView.spectatorEntranceQrGate) {
      final titleText = _activeView == _OperatorSubView.card3MatchupsBrackets
          ? 'Matchups & Brackets'
          : 'Spectator & Venue Gate';
      return AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: _buildSingleBackNavButton(context),
        titleSpacing: 4,
        title: HoldToInspectText(
          title: titleText,
          fullText: titleText,
          child: Text(
            titleText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        actions: const [],
      );
    }

    String subtitle = 'ARENA OPERATIONS';
    if (_activeView == _OperatorSubView.tournamentHub) {
      subtitle = 'TOURNAMENT HUB • 4-STAGE DECK';
    }

    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: _activeView != _OperatorSubView.mainList
          ? _buildSingleBackNavButton(context)
          : CrystalBackButton.maybeForInnerScreen(context),
      title: HoldToInspectText(
        title: subtitle,
        fullText: '$subtitle\n$operatorName',
        child: Column(
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 10.5,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.goldPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              operatorName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 17.5,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
      actions: [
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
            customBanner: 'Cash Prizes Saved (✓) • Draft Protected',
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
        onUpdateAthletes: (updatedAthletes) async {
          final updatedTournament = <String, dynamic>{
            ...current,
            'appliedAthletes': updatedAthletes,
          };
          await _enqueueAndPersistHubAction(
            updatedTournament: updatedTournament,
            operatorId: operatorId,
            actionType: 'VERIFY_WEIGH_IN',
            endpoint: '/tournaments/weighins',
            syncPayload: {
              'eventId': current['id'],
              'verifiedCount': updatedAthletes
                  .where((a) => a['weighInStatus'] == 'VERIFIED')
                  .length,
            },
            bannerMessage: 'Saved / Done • Weigh-In Verified & Saved',
          );
        },
        onSwitchCategoryAndPairInMatchups: ({
          required athlete,
          required newWeightLabel,
          required newArm,
          required newCategoryLabel,
          required autoPairInNewCategory,
        }) async {
          final id = athlete['id']?.toString();
          final updatedList = currentAthletes.map((a) {
            if (a['id']?.toString() != id) return a;
            return <String, dynamic>{
              ...a,
              'weightClass': newWeightLabel,
              'registeredWeightLabel': newWeightLabel,
              'arm': newArm,
              'registeredArm': newArm,
              'categoryLabel': newCategoryLabel,
              'weighInStatus': 'VERIFIED',
              'reassignedFromUnmatch': true,
            };
          }).toList();
          final updatedTournament = <String, dynamic>{
            ...current,
            'appliedAthletes': updatedList,
          };
          await _enqueueAndPersistHubAction(
            updatedTournament: updatedTournament,
            operatorId: operatorId,
            actionType: 'RECLASSIFY_ATHLETE_CATEGORY',
            endpoint: '/tournaments/registrations/category',
            syncPayload: {
              'eventId': current['id'],
              'athleteId': id,
              'newCategoryLabel': newCategoryLabel,
              'autoPair': autoPairInNewCategory,
            },
            bannerMessage: 'Saved / Done • Category Reclassified',
          );
        },
        onBackToHub: () {
          HapticFeedback.selectionClick();
          setState(() => _activeView = _OperatorSubView.tournamentHub);
        },
      );
    }

    if (_activeView == _OperatorSubView.spectatorEntranceQrGate) {
      final spectatorPasses = (current['spectatorPasses'] is List)
          ? (current['spectatorPasses'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];

      return SpectatorEntranceQrGateView(
        key: ValueKey('spectator_gate_${current['id']}'),
        tournament: current,
        appliedAthletes: currentAthletes,
        spectatorPasses: spectatorPasses,
        autoSaveBannerText: _autoSaveBannerText,
        onUpdateSpectatorConfig: ({
          required bool spectatorEnabled,
          required String spectatorMode,
          required int spectatorTicketPricePkr,
          required int athleteGuestPassAllowance,
        }) async {
          final updatedTournament = <String, dynamic>{
            ...current,
            'spectatorEnabled': spectatorEnabled,
            'spectatorMode': spectatorMode,
            'spectatorTicketPricePkr': spectatorTicketPricePkr,
            'athleteGuestPassAllowance': athleteGuestPassAllowance,
          };
          await _enqueueAndPersistHubAction(
            updatedTournament: updatedTournament,
            operatorId: operatorId,
            actionType: 'UPDATE_SPECTATOR_CONFIG',
            endpoint: '/tournaments/spectator-config',
            syncPayload: {
              'eventId': current['id'],
              'spectatorEnabled': spectatorEnabled,
              'spectatorMode': spectatorMode,
              'spectatorTicketPricePkr': spectatorTicketPricePkr,
              'athleteGuestPassAllowance': athleteGuestPassAllowance,
            },
            bannerMessage: 'Saved / Done • Spectator Gate Rules Synced',
          );
        },
        onUpdateSpectatorPasses: (updatedPasses) async {
          final updatedTournament = <String, dynamic>{
            ...current,
            'spectatorPasses': updatedPasses,
          };
          await _enqueueAndPersistHubAction(
            updatedTournament: updatedTournament,
            operatorId: operatorId,
            actionType: 'UPDATE_SPECTATOR_PASSES',
            endpoint: '/tournaments/spectator-passes',
            syncPayload: {
              'eventId': current['id'],
              'passCount': updatedPasses.length,
            },
            bannerMessage: 'Saved / Done • Spectator Pass Recorded',
          );
        },
        onUpdateAthletes: (updatedAthletes) async {
          final updatedTournament = <String, dynamic>{
            ...current,
            'appliedAthletes': updatedAthletes,
          };
          await _enqueueAndPersistHubAction(
            updatedTournament: updatedTournament,
            operatorId: operatorId,
            actionType: 'UPDATE_ATHLETES_GUEST_COUNT',
            endpoint: '/tournaments/registrations',
            syncPayload: {
              'eventId': current['id'],
              'athleteCount': updatedAthletes.length,
            },
            bannerMessage: 'Saved / Done • Guest Entitlement Updated',
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
  // 1. OPERATOR MAIN SCREEN (Forged Crystal Event Banners & Zero Clutter)
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
        10,
        AppTheme.space16,
        36,
      ),
      children: [
        // Prominent Forged 24k Gold & Crimson-Obsidian Crystal Button
        _ForgedGoldCrystalButton(
          key: const ValueKey('operator_create_tournament_button'),
          label: 'CREATE TOURNAMENT',
          icon: Icons.add_circle_outline_rounded,
          height: 54,
          onTap: () => _startNewTournamentDraft(operatorId, profile),
        ),
        const SizedBox(height: 22),

        if (tournaments.isEmpty) ...[
          AppEmptyState(
            icon: Icons.emoji_events_outlined,
            title: 'No Tournaments Created Yet',
            subtitle: 'Tap "Create Tournament" above to initialize an event deck.',
            bannerAsset: ArmSphereAssets.cardStandbyTable,
            bannerAlignment: Alignment.centerRight,
            ctaLabel: 'Create Tournament',
            onCtaTap: () => _startNewTournamentDraft(operatorId, profile),
          ),
          const SizedBox(height: 20),
        ],

        // TOP LIST: UPCOMING & ACTIVE
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'UPCOMING & ACTIVE',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
                color: AppTheme.goldPrimary,
              ),
            ),
            StatusChip(
              label: '${upcomingAndDrafts.length}',
              type: StatusType.warning,
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (upcomingAndDrafts.isEmpty)
          ElevatedActionCard(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: const Text(
              'No active tournaments. Tap "Create Tournament" above.',
              style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
            ),
          )
        else
          for (final item in upcomingAndDrafts) ...[
            _buildTournamentListCard(context, item, isCompleted: false),
            const SizedBox(height: 12),
          ],

        const SizedBox(height: 20),

        // BOTTOM LIST: COMPLETED ARCHIVE
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'COMPLETED ARCHIVE',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
                color: AppTheme.textSecondary,
              ),
            ),
            StatusChip(
              label: '${completedList.length}',
              type: StatusType.neutral,
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (completedList.isEmpty)
          ElevatedActionCard(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: const Text(
              'No completed tournaments in archive.',
              style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
            ),
          )
        else
          for (final item in completedList) ...[
            _buildTournamentListCard(context, item, isCompleted: true),
            const SizedBox(height: 12),
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

    final appliedCount = (t['appliedAthletes'] is List)
        ? (t['appliedAthletes'] as List).length
        : _seedDefaultAppliedAthletes(t).length;
    final cityText = (t['city']?.toString().trim().isNotEmpty == true)
        ? t['city'].toString()
        : 'Lahore';
    final provinceText = (t['province']?.toString().trim().isNotEmpty == true)
        ? t['province'].toString()
        : 'Punjab';
    final dateText = _formatDateReadable(t['startDate']).split(' • ').first;

    final Color accentColor = isCompleted
        ? AppTheme.textSecondary
        : (isReleased ? AppTheme.emerald : AppTheme.goldPrimary);
    final String badgeLabel = isCompleted
        ? 'COMPLETED'
        : (isReleased ? 'RELEASED • LIVE' : 'DRAFT • LOCKED');
    final String stagesText = (isReleased && isCard1Complete)
        ? '4/4 Stages Unlocked'
        : '1/4 Stages Unlocked • $doneCount/$totalCount Ready';

    return HoldToInspectText(
      title: displayName,
      fullText:
          '$displayName\nStatus: $badgeLabel\nLocation: $cityText, $provinceText\nDate: $dateText\nAthletes: $appliedCount\nProgress: $stagesText',
      child: ElevatedActionCard(
        padding: const EdgeInsets.all(AppTheme.space16),
        borderColor: isCompleted
            ? AppTheme.borderSubtle
            : (isReleased
                ? AppTheme.emerald.withValues(alpha: 0.65)
                : AppTheme.goldPrimary.withValues(alpha: 0.65)),
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          HapticFeedback.selectionClick();
          setState(() {
            _selectedTournamentId = t['id'].toString();
            _activeView = _OperatorSubView.tournamentHub;
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Bold 17sp white tournament title + compact status badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.65),
                      width: 1.1,
                    ),
                  ),
                  child: Text(
                    badgeLabel,
                    style: TextStyle(
                      fontFamily: AppTheme.fontMono,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Middle Row (8px below): Compact icon-pill metadata row
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildTelemetryMiniPill(
                  icon: Icons.location_on_outlined,
                  label: '$cityText, $provinceText',
                  color: AppTheme.textSecondary,
                ),
                _buildTelemetryMiniPill(
                  icon: Icons.calendar_today_outlined,
                  label: dateText,
                  color: AppTheme.textSecondary,
                ),
                _buildTelemetryMiniPill(
                  icon: Icons.groups_2_outlined,
                  label: '$appliedCount Athletes',
                  color: AppTheme.cyan,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Bottom Action Strip (10px below): Full-width crystal action bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.14),
                    const Color(0xCC070A11),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.42),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      stagesText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontMono,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Manage Hub →',
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: accentColor,
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

  // ===========================================================================
  // 2. TOURNAMENT HUB SCREEN (Visual Telemetry Bento Cards)
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
    final tableCount = ((tournament['tableCount'] as num?)?.toInt() ?? 1).clamp(1, 12);

    final shortFormatLabel = _formatSummaryLabel(tournament);

    final feePkr = tournament['entryFeePkr'];
    final shortFeeLabel =
        (tournament['entryFeeConfigured'] == true && feePkr != null)
            ? '$feePkr PKR'
            : '0 PKR';

    final displayName = (tournament['name']?.toString().trim().isNotEmpty == true)
        ? tournament['name'].toString()
        : 'Untitled Tournament Draft';
    final venueName = (tournament['venue']?.toString().trim().isNotEmpty == true)
        ? tournament['venue'].toString()
        : 'Arena Venue';
    final cityName = (tournament['city']?.toString().trim().isNotEmpty == true)
        ? tournament['city'].toString()
        : 'Lahore';
    final dateShort = _formatDateReadable(tournament['startDate']);

    final appliedAthletes = (tournament['appliedAthletes'] is List)
        ? (tournament['appliedAthletes'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : _seedDefaultAppliedAthletes(tournament);
    final verifiedWeighInCount = appliedAthletes
        .where((a) => a['weighInStatus'] == 'VERIFIED')
        .length;
    final unmatchWeighInCount = appliedAthletes
        .where((a) => a['weighInStatus'] == 'UNMATCH')
        .length;

    int topElo = 1000;
    for (final a in appliedAthletes) {
      final elo = (a['elo'] as num?)?.toInt() ??
          (a['eloRating'] as num?)?.toInt() ??
          1000;
      if (elo > topElo) topElo = elo;
    }

    final gateMode = (tournament['spectatorGateConfig']?['spectatorAccessMode'] ?? 'FREE')
        .toString()
        .toUpperCase();
    final maxGuests =
        (tournament['spectatorGateConfig']?['allowedGuestsPerAthlete'] ?? 2)
            .toString();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space16,
        10,
        AppTheme.space16,
        36,
      ),
      children: [
        // Compact Tournament Summary Header Card
        HoldToInspectText(
          title: displayName,
          fullText: '$displayName\nVenue: $venueName, $cityName\nSchedule: $dateShort',
          child: ElevatedActionCard(
            padding: const EdgeInsets.all(AppTheme.space16),
            borderColor: isReleased
                ? AppTheme.emerald.withValues(alpha: 0.65)
                : AppTheme.goldPrimary.withValues(alpha: 0.65),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: (isReleased ? AppTheme.emerald : AppTheme.goldPrimary)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (isReleased ? AppTheme.emerald : AppTheme.goldPrimary)
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      child: Text(
                        isReleased ? 'RELEASED ✓' : 'DRAFT',
                        style: TextStyle(
                          fontFamily: AppTheme.fontMono,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: isReleased ? AppTheme.emerald : AppTheme.goldPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppTheme.goldPrimary,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '$venueName, $cityName  •  $dateShort',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!isReleased) ...[
                  const SizedBox(height: 12),
                  _ForgedGoldCrystalButton(
                    key: const ValueKey('hub_release_schedule_button'),
                    label: isCard1Complete
                        ? 'RELEASE & PUBLISH TOURNAMENT'
                        : 'COMPLETE STAGE 01 ($doneCount/$totalCount) TO RELEASE',
                    icon: isCard1Complete
                        ? Icons.rocket_launch_rounded
                        : Icons.lock_clock_outlined,
                    height: 52,
                    isDimmed: !isCard1Complete,
                    onTap: () => _handleReleaseTournament(tournament, operatorId),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        const Text(
          '4 OPERATIONAL STAGES',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            color: AppTheme.goldPrimary,
          ),
        ),
        const SizedBox(height: 10),

        // STAGE 01: EVENT & DIVISION SETUP
        _buildHubDashboardCardButton(
          key: const ValueKey('hub_card_1_basic_details'),
          stageTag: 'STAGE 01',
          title: 'Event & Division Setup',
          statusPillText: isCard1Complete ? 'READY ✓' : '$doneCount/$totalCount READY',
          accentColor: isReleased
              ? AppTheme.emerald
              : (isCard1Complete ? AppTheme.goldPrimary : AppTheme.warning),
          icon: Icons.tune_rounded,
          isLocked: false,
          telemetryPills: [
            '$divisionsCount Divisions',
            shortFormatLabel,
            '$tableCount ${tableCount == 1 ? 'Table' : 'Tables'}',
            shortFeeLabel,
          ],
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _activeView = _OperatorSubView.card1BasicDetails);
          },
        ),
        const SizedBox(height: 12),

        // STAGE 02: REGISTERED ATHLETES
        _buildHubDashboardCardButton(
          key: const ValueKey('hub_card_2_applied_athletes'),
          stageTag: 'STAGE 02',
          title: 'Registered Athletes',
          statusPillText: areCards2To4Unlocked
              ? '${appliedAthletes.length} APPLIED'
              : 'LOCKED',
          accentColor:
              areCards2To4Unlocked ? AppTheme.cyan : AppTheme.textMuted,
          icon: Icons.groups_2_outlined,
          isLocked: !areCards2To4Unlocked,
          telemetryPills: [
            '${appliedAthletes.length} Athletes',
            '$divisionsCount Categories',
            'Top ELO $topElo',
          ],
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

        // STAGE 03: MATCHUPS & BRACKETS
        _buildHubDashboardCardButton(
          key: const ValueKey('hub_card_3_matchups_brackets'),
          stageTag: 'STAGE 03',
          title: 'Matchups & Brackets',
          statusPillText: areCards2To4Unlocked ? 'ACTIVE' : 'LOCKED',
          accentColor:
              areCards2To4Unlocked ? AppTheme.goldPrimary : AppTheme.textMuted,
          icon: Icons.account_tree_outlined,
          isLocked: !areCards2To4Unlocked,
          telemetryPills: [
            shortFormatLabel,
            '$tableCount ${tableCount == 1 ? 'Table' : 'Tables'}',
            'Auto-BYE',
          ],
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

        // STAGE 04: WEIGH-IN VERIFICATION
        _buildHubDashboardCardButton(
          key: const ValueKey('hub_card_4_weigh_in'),
          stageTag: 'STAGE 04',
          title: 'Weigh-In Verification',
          statusPillText: areCards2To4Unlocked ? 'SCALE READY' : 'LOCKED',
          accentColor:
              areCards2To4Unlocked ? AppTheme.emerald : AppTheme.textMuted,
          icon: Icons.scale_outlined,
          isLocked: !areCards2To4Unlocked,
          telemetryPills: [
            '$verifiedWeighInCount Verified',
            '$unmatchWeighInCount Unmatched',
            'QR Ready',
          ],
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
          'VENUE ACCESS & SPECTATOR GATE',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            color: AppTheme.cyan,
          ),
        ),
        const SizedBox(height: 10),

        // VENUE GATE: SPECTATOR & GATE QR
        _buildHubDashboardCardButton(
          key: const ValueKey('hub_spectator_entrance_qr_gate_card'),
          stageTag: 'VENUE GATE',
          title: 'Spectator & Gate QR',
          statusPillText: '$gateMode • $maxGuests GUESTS',
          accentColor: AppTheme.cyan,
          icon: Icons.qr_code_scanner_rounded,
          isLocked: false,
          telemetryPills: [
            gateMode == 'FREE' ? 'Free Entry' : 'Paid Pass',
            'Max $maxGuests Guests',
            'Gate Scanner',
          ],
          onTap: () {
            HapticFeedback.selectionClick();
            setState(
                () => _activeView = _OperatorSubView.spectatorEntranceQrGate);
          },
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
    required String stageTag,
    required String title,
    required String statusPillText,
    required Color accentColor,
    required IconData icon,
    required bool isLocked,
    required List<String> telemetryPills,
    required VoidCallback onTap,
  }) {
    final effectiveColor = isLocked ? AppTheme.textMuted : accentColor;
    return HoldToInspectText(
      title: '$stageTag • $title',
      fullText:
          '$stageTag: $title ($statusPillText)\nDetails: ${telemetryPills.join(" • ")}',
      child: Opacity(
        opacity: isLocked ? 0.65 : 1.0,
        child: ElevatedActionCard(
          key: key,
          padding: const EdgeInsets.all(AppTheme.space16),
          borderColor: isLocked
              ? const Color(0x28FFFFFF)
              : accentColor.withValues(alpha: 0.65),
          onTap: onTap,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: 48x48 Forged Crystal Icon Box
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      effectiveColor.withValues(alpha: 0.22),
                      const Color(0xE6070A11),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: isLocked
                        ? const Color(0x33FFFFFF)
                        : effectiveColor.withValues(alpha: 0.85),
                    width: 1.35,
                  ),
                ),
                child: Center(
                  child: Icon(
                    isLocked ? Icons.lock_outline_rounded : icon,
                    color: effectiveColor,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Center (Expanded): 3-Row Telemetry Layout
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Stage tag + short status pill
                    Row(
                      children: [
                        Text(
                          stageTag,
                          style: TextStyle(
                            fontFamily: AppTheme.fontMono,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                            color: effectiveColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: effectiveColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: effectiveColor.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              statusPillText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTheme.fontMono,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: effectiveColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Row 2: Bold 17sp white title
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Row 3: 3 to 4 crisp scannable mini-pills
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final pill in telemetryPills)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xCC0B101B),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0x2EFFFFFF),
                              ),
                            ),
                            child: Text(
                              pill,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontMono,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Right (width: 28px): Dedicated column for chevron or lock icon
              SizedBox(
                width: 28,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    isLocked
                        ? Icons.lock_rounded
                        : Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: effectiveColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTelemetryMiniPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return HoldToInspectText(
      title: 'Tournament Detail',
      fullText: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xCC0B101B),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: const Color(0x28FFFFFF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12.5, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: AppTheme.fontMono,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// REUSABLE FORGED 24K GOLD CRYSTAL BUTTON
// =============================================================================
class _ForgedGoldCrystalButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final double height;
  final bool isDimmed;

  const _ForgedGoldCrystalButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.height = 54,
    this.isDimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    return HoldToInspectText(
      title: 'Action Button',
      fullText: label,
      child: Opacity(
        opacity: isDimmed ? 0.72 : 1.0,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              height: height,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0x40D4AF37),
                    Color(0x18D4AF37),
                    Color(0xE6070A11),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFD4AF37),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // 2px L-shaped corner brackets
                  Positioned(
                    top: 4,
                    left: 4,
                    child: _buildCornerBracket(isTop: true, isLeft: true),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: _buildCornerBracket(isTop: true, isLeft: false),
                  ),
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: _buildCornerBracket(isTop: false, isLeft: true),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: _buildCornerBracket(isTop: false, isLeft: false),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 20,
                            color: const Color(0xFFD4AF37),
                          ),
                          const SizedBox(width: 9),
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.7,
                                color: Color(0xFFFFFFFF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCornerBracket({required bool isTop, required bool isLeft}) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: Color(0xFFD4AF37), width: 2.0)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: Color(0xFFD4AF37), width: 2.0)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: Color(0xFFD4AF37), width: 2.0)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: Color(0xFFD4AF37), width: 2.0)
              : BorderSide.none,
        ),
      ),
    );
  }
}

// =============================================================================
// 3. CARD 1 — EVENT & DIVISION SETUP (Quick-Jump Bar & Tactile Controls)
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

  // Per-table referee search state
  final Map<int, TextEditingController> _refSearchCtrls = {};
  final Set<int> _openRefereeSearchTables = <int>{};

  final List<GlobalKey> _stepKeys = List.generate(7, (_) => GlobalKey());

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
    for (final ctrl in _refSearchCtrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  TextEditingController _refSearchControllerFor(int tableIndex) {
    return _refSearchCtrls.putIfAbsent(
      tableIndex,
      () => TextEditingController(),
    );
  }

  void _emitPatch(Map<String, dynamic> patch) {
    final next = <String, dynamic>{
      ...widget.tournament,
      ...patch,
    };
    widget.onChanged(next);
  }

  void _scrollToSection(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.selectionClick();
    final ctx = _stepKeys[index].currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _pickScheduleDateTime() async {
    FocusManager.instance.primaryFocus?.unfocus();
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

  /// Builds the searchable pool of athletes who are certified referees in our data.
  List<Map<String, String>> _buildAthleteRefereePool() {
    final byId = <String, Map<String, String>>{};
    for (final r in _kDefaultRefereePool) {
      final id = (r['id'] ?? '').trim();
      if (id.isNotEmpty) {
        byId[id] = Map<String, String>.from(r);
      }
    }

    final applied = (widget.tournament['appliedAthletes'] is List)
        ? (widget.tournament['appliedAthletes'] as List).whereType<Map>()
        : const <Map>[];
    for (final raw in applied) {
      final isRef = raw['isReferee'] == true ||
          raw['role']?.toString().toUpperCase() == 'REFEREE';
      if (!isRef) continue;
      final id = (raw['athleteId'] ?? raw['id'] ?? '').toString().trim();
      final name = (raw['athleteName'] ?? raw['name'] ?? '').toString().trim();
      if (id.isEmpty || name.isEmpty) continue;
      final club =
          (raw['clubName'] ?? raw['club'] ?? 'ArmSphere Club').toString();
      final elo = (raw['eloRating'] ?? raw['elo'] ?? 1700).toString();
      byId[id] = {
        'id': id,
        'name': name,
        'club': club,
        'elo': elo,
        'badge': 'Athlete & Certified Referee • $club',
      };
    }

    return byId.values.toList();
  }

  Map<String, String> _resolveRefereeById(
    String refId,
    List<Map<String, String>> pool,
  ) {
    final found = pool.where((r) => r['id'] == refId).firstOrNull;
    if (found != null) return found;
    return {
      'id': refId,
      'name': refId.replaceAll('ref-pk-', 'Official #').replaceAll('ath-pk-', 'Athlete #'),
      'club': 'ArmSphere Certified Referee',
      'elo': '1700',
      'badge': 'Certified Athlete-Referee',
    };
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
    final int tableCount =
        ((t['tableCount'] as num?)?.toInt() ?? 1).clamp(1, 12);
    final assignMode = (t['tableAssignmentMode'] ?? '').toString();
    final tables = (t['tables'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        <Map<String, dynamic>>[];
    final awardsConfig = t['awardsConfig'] is Map
        ? Map<String, dynamic>.from(t['awardsConfig'] as Map)
        : <String, dynamic>{};
    final isAwardsConfigured = awardsConfig['isConfigured'] == true;

    final stepPills = <(String, bool, String)>[
      ('1. Info', v['basicValid'] == true, '01. Event & Venue Information'),
      ('2. Divisions', v['weightsValid'] == true, '02. Weight Categories & Arm Divisions'),
      ('3. Format', v['formatValid'] == true, '03. Match Format & Bracket System'),
      ('4. Tables', v['tablesValid'] == true, '04. Arena Tables & Queue Mode'),
      ('5. Referees', v['refereesValid'] == true, '05. Certified Athlete-Referees (Min 2 per Table)'),
      ('6. Entry Fee', v['entryFeeValid'] == true, '06. Entry / Application Fee (PKR)'),
      ('7. Cash Prizes', isAwardsConfigured, '07. Mandatory Cash Prizes (PKR)'),
    ];

    final rawTiers = (awardsConfig['tiers'] is List)
        ? (awardsConfig['tiers'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];
    final int p1 = (rawTiers.isNotEmpty
            ? (rawTiers[0]['cashAmountPkr'] as num?)?.toInt()
            : null) ??
        25000;
    final int p2 = (rawTiers.length > 1
            ? (rawTiers[1]['cashAmountPkr'] as num?)?.toInt()
            : null) ??
        15000;
    final int p3 = (rawTiers.length > 2
            ? (rawTiers[2]['cashAmountPkr'] as num?)?.toInt()
            : null) ??
        7500;

    // Default weights that can be quickly restored if deleted
    final existingLabelsUpper = weightCategories
        .map((c) => (c['label'] ?? '').toString().trim().toUpperCase())
        .toSet();
    final missingDefaultWeights = const ['70 KG', '80 KG', '90 KG', 'OPEN']
        .where((w) => !existingLabelsUpper.contains(w))
        .toList();

    return Column(
      children: [
        // Horizontal 7-Step Quick-Jump Bar (Offline status card removed from UI as requested)
        Container(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.space16,
            8,
            AppTheme.space16,
            10,
          ),
          decoration: const BoxDecoration(
            color: Color(0xF2060911),
            border: Border(
              bottom: BorderSide(color: Color(0x26FFFFFF)),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < stepPills.length; i++) ...[
                  HoldToInspectText(
                    title: stepPills[i].$1,
                    fullText:
                        '${stepPills[i].$3} — ${stepPills[i].$2 ? "Ready ✓" : "Required"}',
                    child: GestureDetector(
                      onTap: () => _scrollToSection(i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: stepPills[i].$2
                                ? [
                                    AppTheme.emerald.withValues(alpha: 0.22),
                                    const Color(0xE6070A11),
                                  ]
                                : [
                                    AppTheme.goldPrimary.withValues(alpha: 0.16),
                                    const Color(0xE6070A11),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: stepPills[i].$2
                                ? AppTheme.emerald.withValues(alpha: 0.65)
                                : AppTheme.goldPrimary.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          '${stepPills[i].$1} ${stepPills[i].$2 ? "✓" : "•"}',
                          style: TextStyle(
                            fontFamily: AppTheme.fontMono,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: stepPills[i].$2
                                ? AppTheme.emerald
                                : AppTheme.goldPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (i < stepPills.length - 1) const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ),

        // Scrollable 7-Section Setup Form
        Expanded(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space16,
              14,
              AppTheme.space16,
              40,
            ),
            children: [
              // SECTION 1: EVENT & VENUE INFO
              Container(
                key: _stepKeys[0],
                child: _buildSectionCard(
                  stepLabel: '01. EVENT & VENUE INFO',
                  isValid: v['basicValid'] == true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _nameCtrl,
                        onTapOutside: (_) =>
                            FocusManager.instance.primaryFocus?.unfocus(),
                        style: const TextStyle(fontSize: 14.5),
                        decoration: const InputDecoration(
                          labelText: 'Event Name *',
                          hintText: 'e.g. Punjab National Open Championship',
                          prefixIcon:
                              Icon(Icons.emoji_events_outlined, size: 18),
                        ),
                        onChanged: (val) => _emitPatch({'name': val}),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _orgCtrl,
                        onTapOutside: (_) =>
                            FocusManager.instance.primaryFocus?.unfocus(),
                        style: const TextStyle(fontSize: 14.5),
                        decoration: const InputDecoration(
                          labelText: 'Organization *',
                          hintText: 'e.g. Pakistan Arm-Wrestling Federation',
                          prefixIcon: Icon(Icons.shield_outlined, size: 18),
                        ),
                        onChanged: (val) =>
                            _emitPatch({'organizationName': val}),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue:
                                  _kPakistanProvinces.contains(t['province'])
                                      ? t['province'].toString()
                                      : _kPakistanProvinces.first,
                              style: const TextStyle(
                                fontSize: 14.5,
                                color: AppTheme.textPrimary,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Province *',
                              ),
                              items: [
                                for (final p in _kPakistanProvinces)
                                  DropdownMenuItem(value: p, child: Text(p)),
                              ],
                              onChanged: (val) {
                                FocusManager.instance.primaryFocus?.unfocus();
                                if (val != null) _emitPatch({'province': val});
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _cityCtrl,
                              onTapOutside: (_) =>
                                  FocusManager.instance.primaryFocus?.unfocus(),
                              style: const TextStyle(fontSize: 14.5),
                              decoration:
                                  const InputDecoration(labelText: 'City *'),
                              onChanged: (val) => _emitPatch({'city': val}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _venueCtrl,
                        onTapOutside: (_) =>
                            FocusManager.instance.primaryFocus?.unfocus(),
                        style: const TextStyle(fontSize: 14.5),
                        decoration: const InputDecoration(
                          labelText: 'Venue Location *',
                          hintText: 'e.g. Nishtar Park Sports Complex Arena',
                          prefixIcon:
                              Icon(Icons.location_on_outlined, size: 18),
                        ),
                        onChanged: (val) => _emitPatch({'venue': val}),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: HoldToInspectText(
                              title: 'Event Schedule Date & Time',
                              fullText: t['startDate']
                                      ?.toString()
                                      .substring(0, 16)
                                      .replaceAll('T', ' ') ??
                                  'Schedule Date/Time',
                              child: SizedBox(
                                height: 50,
                                child: OutlinedButton.icon(
                                  onPressed: _pickScheduleDateTime,
                                  icon: const Icon(
                                    Icons.calendar_month_outlined,
                                    size: 16,
                                    color: AppTheme.goldPrimary,
                                  ),
                                  label: Text(
                                    t['startDate']
                                            ?.toString()
                                            .substring(0, 16)
                                            .replaceAll('T', ' ') ??
                                        'Schedule Date/Time',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontMono,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 5,
                            child: HoldToInspectText(
                              title: 'Maximum Athletes Capacity',
                              fullText:
                                  'Max Athletes Capacity: ${_maxAthletesCtrl.text}',
                              child: TextField(
                                controller: _maxAthletesCtrl,
                                onTapOutside: (_) => FocusManager
                                    .instance.primaryFocus
                                    ?.unfocus(),
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontSize: 14.5),
                                decoration: const InputDecoration(
                                  labelText: 'Max Athletes *',
                                  isDense: true,
                                ),
                                onChanged: (val) {
                                  final parsed = int.tryParse(val.trim()) ?? 0;
                                  _emitPatch({'capacity': parsed});
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // SECTION 2: WEIGHT CATEGORIES & ARM DIVISION (With Cross ✕ Delete Button)
              Container(
                key: _stepKeys[1],
                child: _buildSectionCard(
                  stepLabel: '02. WEIGHT CATEGORIES & ARMS',
                  isValid: v['weightsValid'] == true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (weightCategories.isEmpty)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xCC0B101B),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.warning.withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Text(
                            'All weight categories were removed. Add a custom weight or tap a preset below.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.warning,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      for (int idx = 0;
                          idx < weightCategories.length;
                          idx++) ...[
                        _buildWeightCategoryRow(weightCategories, idx),
                        const SizedBox(height: 8),
                      ],
                      if (missingDefaultWeights.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final presetLabel in missingDefaultWeights)
                              ActionChip(
                                avatar: const Icon(
                                  Icons.add_rounded,
                                  size: 14,
                                  color: AppTheme.goldPrimary,
                                ),
                                label: Text(
                                  presetLabel,
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontMono,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  final updated = [
                                    ...weightCategories,
                                    {
                                      'id':
                                          'wc_${presetLabel.toLowerCase().replaceAll(" ", "_")}_${DateTime.now().millisecondsSinceEpoch}',
                                      'label': presetLabel,
                                      'enabled': true,
                                      'arm': 'BOTH',
                                    },
                                  ];
                                  _emitPatch({'weightCategories': updated});
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _customWeightCtrl,
                              onTapOutside: (_) =>
                                  FocusManager.instance.primaryFocus?.unfocus(),
                              style: const TextStyle(fontSize: 14),
                              decoration: const InputDecoration(
                                hintText: 'Add Weight (e.g. 65 kg, 100+ kg)',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                FocusManager.instance.primaryFocus?.unfocus();
                                final label = _customWeightCtrl.text.trim();
                                if (label.isEmpty) return;
                                final updated = [
                                  ...weightCategories,
                                  {
                                    'id':
                                        'wc_${DateTime.now().millisecondsSinceEpoch}',
                                    'label': label.toUpperCase(),
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
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // SECTION 3: MATCH FORMAT (2x2 Visual Bracket Grid)
              Container(
                key: _stepKeys[2],
                child: _buildSectionCard(
                  stepLabel: '03. MATCH FORMAT & BRACKET SYSTEM',
                  isValid: v['formatValid'] == true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildSelectableFormatTile(
                              title: 'SUPERFIGHTS',
                              subtitle: 'Single Bouts / Vendetta',
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
                              subtitle: 'Tournament Bracket',
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
                        Row(
                          children: [
                            Expanded(
                              child: _buildBracketGridCard(
                                codeBadge: '1L',
                                title: 'Single Elimination',
                                subtitle: '1 Loss Knockout',
                                selected: elimSub == 'SINGLE_ELIMINATION',
                                onTap: () => _emitPatch({
                                  'formatCategory': 'ELIMINATION',
                                  'eliminationSubFormat': 'SINGLE_ELIMINATION',
                                }),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildBracketGridCard(
                                codeBadge: '2L',
                                title: 'Double Elimination',
                                subtitle: '2 Losses to Eliminate',
                                selected: elimSub == 'DOUBLE_ELIMINATION',
                                onTap: () => _emitPatch({
                                  'formatCategory': 'ELIMINATION',
                                  'eliminationSubFormat': 'DOUBLE_ELIMINATION',
                                }),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildBracketGridCard(
                                codeBadge: '3L',
                                title: 'Triple Elimination',
                                subtitle: '3 Losses to Eliminate',
                                selected: elimSub == 'THREE_LOSS_ELIMINATION',
                                onTap: () => _emitPatch({
                                  'formatCategory': 'ELIMINATION',
                                  'eliminationSubFormat':
                                      'THREE_LOSS_ELIMINATION',
                                }),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildBracketGridCard(
                                codeBadge: '∞',
                                title: 'Last-One-Standing',
                                subtitle: 'Undefeated Survival',
                                selected: elimSub == 'LAST_ONE_STANDING',
                                onTap: () => _emitPatch({
                                  'formatCategory': 'ELIMINATION',
                                  'eliminationSubFormat': 'LAST_ONE_STANDING',
                                }),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // SECTION 4: ARENA TABLES & QUEUE MODE
              Container(
                key: _stepKeys[3],
                child: _buildSectionCard(
                  stepLabel: '04. ARENA TABLES & QUEUE MODE',
                  isValid: v['tablesValid'] == true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xCC0B101B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.goldPrimary.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'ACTIVE ARENA TABLES',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
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
                                              'tableAssignmentMode':
                                                  'SINGLE_TABLE_DEFAULT',
                                          })
                                      : null,
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  child: Text(
                                    '$tableCount ${tableCount == 1 ? "TABLE" : "TABLES"}',
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontMono,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.goldPrimary,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: tableCount < 10
                                      ? () => _emitPatch({
                                            'tableCount': tableCount + 1,
                                            if (assignMode ==
                                                'SINGLE_TABLE_DEFAULT')
                                              'tableAssignmentMode': '',
                                          })
                                      : null,
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (tableCount > 1) ...[
                        const SizedBox(height: 10),
                        for (final mode in const [
                          (
                            'CATEGORY_BY_TABLE',
                            'Category-by-Table',
                            'Dedicated weight classes per table'
                          ),
                          (
                            'RANDOM_BY_APP',
                            'Random Distribution',
                            'Balanced automatic table assignment'
                          ),
                          (
                            'DYNAMIC_FREE_TABLE_QUEUE',
                            'Dynamic Free-Table Queue',
                            'Next ready bout auto-assigns to freed table'
                          ),
                        ]) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildSelectableFormatTile(
                              title: mode.$2,
                              subtitle: mode.$3,
                              selected: assignMode == mode.$1,
                              onTap: () =>
                                  _emitPatch({'tableAssignmentMode': mode.$1}),
                            ),
                          ),
                        ],
                        if (assignMode == 'CATEGORY_BY_TABLE') ...[
                          const SizedBox(height: 4),
                          for (int ti = 0; ti < tables.length; ti++) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: const Color(0x33FFFFFF)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${tables[ti]['tableName']} Divisions',
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.goldPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      for (final div
                                          in widget.separatedDivisions)
                                        FilterChip(
                                          label: Text(
                                            div['label']!,
                                            style:
                                                const TextStyle(fontSize: 10.5),
                                          ),
                                          selected: ((tables[ti][
                                                      'assignedCategoryDivisionIds']
                                                  as List?) ??
                                              const [])
                                              .contains(div['divisionId']),
                                          onSelected: (sel) {
                                            final nextTables = tables
                                                .map((e) =>
                                                    Map<String, dynamic>.from(
                                                        e))
                                                .toList();
                                            final currentIds =
                                                List<String>.from(
                                              (nextTables[ti][
                                                          'assignedCategoryDivisionIds']
                                                      as List?) ??
                                                  const [],
                                            );
                                            if (sel) {
                                              currentIds
                                                  .add(div['divisionId']!);
                                            } else {
                                              currentIds
                                                  .remove(div['divisionId']!);
                                            }
                                            nextTables[ti][
                                                    'assignedCategoryDivisionIds'] =
                                                currentIds;
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
              ),
              const SizedBox(height: 14),

              // SECTION 5: CERTIFIED REFEREES (Search Athlete-Referees & Show Selected Only)
              Container(
                key: _stepKeys[4],
                child: _buildSectionCard(
                  stepLabel: '05. CERTIFIED REFEREES (MIN 2 / TABLE)',
                  isValid: v['refereesValid'] == true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int ti = 0; ti < tables.length; ti++) ...[
                        _buildSearchableRefereeTableCard(tables, ti),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // SECTION 6: ENTRY FEE (PKR)
              Container(
                key: _stepKeys[5],
                child: _buildSectionCard(
                  stepLabel: '06. ENTRY FEE (PKR)',
                  isValid: v['entryFeeValid'] == true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final preset in const [
                            (0, 'Free'),
                            (1000, 'PKR 1,000'),
                            (1500, 'PKR 1,500'),
                            (2500, 'PKR 2,500'),
                            (5000, 'PKR 5,000'),
                          ])
                            ChoiceChip(
                              label: Text(
                                preset.$2,
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontMono,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              selected: t['entryFeeConfigured'] == true &&
                                  t['entryFeePkr'] == preset.$1,
                              onSelected: (_) {
                                FocusManager.instance.primaryFocus?.unfocus();
                                _entryFeeCtrl.text = preset.$1.toString();
                                _emitPatch({
                                  'entryFeePkr': preset.$1,
                                  'entryFeeConfigured': true,
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _entryFeeCtrl,
                        onTapOutside: (_) =>
                            FocusManager.instance.primaryFocus?.unfocus(),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 14.5),
                        decoration: const InputDecoration(
                          labelText: 'Custom Entry Fee (PKR) *',
                          hintText: '0 for Free or amount in PKR',
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
              ),
              const SizedBox(height: 14),

              // SECTION 7: CASH PRIZES (PKR) SUMMARY CARD
              Container(
                key: _stepKeys[6],
                child: HoldToInspectText(
                  title: '07. Cash Prizes (PKR)',
                  fullText:
                      '07. Cash Prizes (PKR)\n1st Place: PKR $p1\n2nd Place: PKR $p2\n3rd Place: PKR $p3',
                  child: ElevatedActionCard(
                    key: const ValueKey('card1_open_awards_subscreen_button'),
                    padding: const EdgeInsets.all(AppTheme.space16),
                    borderColor: isAwardsConfigured
                        ? AppTheme.emerald.withValues(alpha: 0.7)
                        : AppTheme.goldPrimary.withValues(alpha: 0.65),
                    onTap: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      widget.onOpenAwardsSubScreen();
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isAwardsConfigured
                                  ? AppTheme.emerald
                                  : AppTheme.goldPrimary,
                            ),
                          ),
                          child: Icon(
                            Icons.payments_rounded,
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Flexible(
                                    child: Text(
                                      '07. CASH PRIZES (PKR)',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.goldPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  StatusChip(
                                    label: isAwardsConfigured
                                        ? 'CONFIGURED ✓'
                                        : 'REQUIRED',
                                    type: isAwardsConfigured
                                        ? StatusType.success
                                        : StatusType.warning,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '1st: PKR $p1  •  2nd: PKR $p2  •  3rd: PKR $p3',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontMono,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          width: 28,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: AppTheme.goldPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // FORGED 24K GOLD CRYSTAL RELEASE / UPDATE BUTTON
              _ForgedGoldCrystalButton(
                key: const ValueKey('card1_release_schedule_button'),
                label: isReleased
                    ? 'SAVE & UPDATE RELEASED TOURNAMENT'
                    : (isComplete
                        ? 'RELEASE & PUBLISH TOURNAMENT'
                        : 'COMPLETE 7/7 SECTIONS TO RELEASE (${v['doneCount']}/${v['totalCount']})'),
                icon: isReleased
                    ? Icons.verified_rounded
                    : (isComplete
                        ? Icons.rocket_launch_rounded
                        : Icons.lock_clock_outlined),
                height: 54,
                isDimmed: !isComplete && !isReleased,
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  widget.onReleaseTournament();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Compact Horizontal Division Plate (height: 58px) with single-line weight, 3-segment switcher & Cross (✕) Delete Button
  Widget _buildWeightCategoryRow(
    List<Map<String, dynamic>> categories,
    int index,
  ) {
    final item = categories[index];
    final enabled = item['enabled'] == true;
    final arm = (item['arm']?.toString() ?? 'BOTH').toUpperCase();
    final rawLabel = (item['label']?.toString() ?? '').toUpperCase();
    final armDisplay = arm == 'BOTH'
        ? 'Both Right & Left Arms'
        : (arm == 'RIGHT' ? 'Right Arm Only' : 'Left Arm Only');

    return HoldToInspectText(
      title: 'Weight Category: $rawLabel',
      fullText:
          'Weight Category: $rawLabel\nArm Division: $armDisplay\nStatus: ${enabled ? "Enabled ✓" : "Disabled"}',
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: enabled ? const Color(0xCC0D1322) : const Color(0x80070A11),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled
                ? AppTheme.goldPrimary.withValues(alpha: 0.65)
                : const Color(0x24FFFFFF),
            width: enabled ? 1.3 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // Left Side: Checkbox/toggle + bold single-line weight label
            SizedBox(
              width: 30,
              child: Checkbox(
                value: enabled,
                activeColor: AppTheme.goldPrimary,
                checkColor: Colors.black,
                visualDensity: VisualDensity.compact,
                onChanged: (v) {
                  final next = categories
                      .map((e) => Map<String, dynamic>.from(e))
                      .toList();
                  next[index]['enabled'] = v ?? false;
                  _emitPatch({'weightCategories': next});
                },
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                rawLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: enabled ? AppTheme.textPrimary : AppTheme.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Center-Right: Compact 3-segment crystal pill switcher ([ Right ] | [ Left ] | [ Both R+L ])
            Container(
              height: 34,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: const Color(0xE605080F),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: const Color(0x2EFFFFFF)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final armOpt in const [
                    ('RIGHT', 'Right'),
                    ('LEFT', 'Left'),
                    ('BOTH', 'Both R+L'),
                  ])
                    GestureDetector(
                      onTap: enabled
                          ? () {
                              HapticFeedback.selectionClick();
                              final next = categories
                                  .map((e) => Map<String, dynamic>.from(e))
                                  .toList();
                              next[index]['arm'] = armOpt.$1;
                              _emitPatch({'weightCategories': next});
                            }
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: (enabled && arm == armOpt.$1)
                              ? const LinearGradient(
                                  colors: [
                                    Color(0x45D4AF37),
                                    Color(0x20D4AF37),
                                  ],
                                )
                              : null,
                          borderRadius: BorderRadius.circular(7),
                          border: (enabled && arm == armOpt.$1)
                              ? Border.all(
                                  color: AppTheme.goldPrimary,
                                  width: 1.1,
                                )
                              : null,
                        ),
                        child: Text(
                          armOpt.$2,
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: AppTheme.fontMono,
                            fontSize: 10,
                            fontWeight: (enabled && arm == armOpt.$1)
                                ? FontWeight.w900
                                : FontWeight.w600,
                            color: (enabled && arm == armOpt.$1)
                                ? AppTheme.textPrimary
                                : AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),

            // Right Side: Cross (✕) Delete Button to remove this weight category
            Material(
              color: Colors.transparent,
              child: InkWell(
                key: ValueKey('delete_weight_category_$index'),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  final next = categories
                      .map((e) => Map<String, dynamic>.from(e))
                      .toList();
                  next.removeAt(index);
                  _emitPatch({'weightCategories': next});
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppTheme.crimsonPrimary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.crimsonPrimary.withValues(alpha: 0.55),
                    ),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppTheme.crimsonPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBracketGridCard({
    required String codeBadge,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return HoldToInspectText(
      title: title,
      fullText: '$title ($codeBadge) — $subtitle',
      child: GestureDetector(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0x38D4AF37),
                      Color(0xE6070A11),
                    ],
                  )
                : const LinearGradient(
                    colors: [
                      Color(0xCC0B101B),
                      Color(0xE6070A11),
                    ],
                  ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppTheme.goldPrimary : const Color(0x2EFFFFFF),
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.goldPrimary.withValues(alpha: 0.22)
                          : const Color(0x1FFFFFFF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: selected
                            ? AppTheme.goldPrimary
                            : const Color(0x33FFFFFF),
                      ),
                    ),
                    child: Text(
                      codeBadge,
                      style: TextStyle(
                        fontFamily: AppTheme.fontMono,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: selected
                            ? AppTheme.goldPrimary
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    size: 16,
                    color: selected ? AppTheme.goldPrimary : AppTheme.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color:
                      selected ? AppTheme.textPrimary : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Searchable Athlete-Referee selector per table:
  /// - Shows a "Search Referee" button & live search field to search referees from athletes who are referees in our data.
  /// - Displays ONLY the selected referees on the card (with a cross ✕ button to remove).
  Widget _buildSearchableRefereeTableCard(
    List<Map<String, dynamic>> tables,
    int tableIndex,
  ) {
    final pool = _buildAthleteRefereePool();
    final assignedIds = List<String>.from(
      (tables[tableIndex]['assignedRefereeIds'] as List?) ?? const [],
    );
    final isReady = assignedIds.length >= 2;
    final searchCtrl = _refSearchControllerFor(tableIndex);
    final query = searchCtrl.text.trim().toLowerCase();
    final isSearchOpen =
        _openRefereeSearchTables.contains(tableIndex) || query.isNotEmpty;

    final matchingReferees = pool.where((r) {
      if (assignedIds.contains(r['id'])) return false;
      if (query.isEmpty) return true;
      final name = (r['name'] ?? '').toLowerCase();
      final club = (r['club'] ?? '').toLowerCase();
      final badge = (r['badge'] ?? '').toLowerCase();
      return name.contains(query) ||
          club.contains(query) ||
          badge.contains(query);
    }).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xCC090D16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isReady
              ? AppTheme.emerald.withValues(alpha: 0.55)
              : AppTheme.warning.withValues(alpha: 0.55),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Table name + Assigned count + Search Referee toggle button
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tables[tableIndex]['tableName']} Officials',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${assignedIds.length}/2+ Athlete-Referees Selected',
                      style: TextStyle(
                        fontFamily: AppTheme.fontMono,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: isReady ? AppTheme.emerald : AppTheme.warning,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                key: ValueKey('search_referee_toggle_btn_$tableIndex'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isSearchOpen
                        ? AppTheme.cyan
                        : AppTheme.goldPrimary.withValues(alpha: 0.8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: const Size(0, 36),
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (_openRefereeSearchTables.contains(tableIndex)) {
                      _openRefereeSearchTables.remove(tableIndex);
                      searchCtrl.clear();
                      FocusManager.instance.primaryFocus?.unfocus();
                    } else {
                      _openRefereeSearchTables.add(tableIndex);
                    }
                  });
                },
                icon: Icon(
                  isSearchOpen ? Icons.expand_less_rounded : Icons.search_rounded,
                  size: 15,
                  color: isSearchOpen ? AppTheme.cyan : AppTheme.goldPrimary,
                ),
                label: Text(
                  isSearchOpen ? 'HIDE SEARCH' : 'SEARCH REFEREE',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: isSearchOpen ? AppTheme.cyan : AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),

          // Search Input & Athlete-Referee Search Results (when Search Referee is active)
          if (isSearchOpen) ...[
            const SizedBox(height: 10),
            TextField(
              controller: searchCtrl,
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              style: const TextStyle(fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Search athlete-referee by name, club, or city...',
                prefixIcon: const Icon(
                  Icons.person_search_rounded,
                  size: 18,
                  color: AppTheme.goldPrimary,
                ),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: () => setState(() => searchCtrl.clear()),
                      )
                    : null,
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            if (matchingReferees.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xCC070A11),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: const Color(0x24FFFFFF)),
                ),
                child: const Text(
                  'No matching unselected athlete-referees found.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppTheme.textSecondary,
                  ),
                ),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 210),
                decoration: BoxDecoration(
                  color: const Color(0xE605080F),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x2EFFFFFF)),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(6),
                  itemCount: matchingReferees.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, idx) {
                    final refAthlete = matchingReferees[idx];
                    return HoldToInspectText(
                      title: refAthlete['name'] ?? 'Athlete-Referee',
                      fullText:
                          '${refAthlete['name']}\n${refAthlete['badge']}\nELO: ${refAthlete['elo'] ?? "1750"}',
                      child: InkWell(
                        onTap: () {
                          _toggleRefereeSelection(
                            tables,
                            tableIndex,
                            refAthlete['id']!,
                            true,
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xCC0D1322),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.goldPrimary.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.verified_user_outlined,
                                size: 16,
                                color: AppTheme.goldPrimary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      refAthlete['name'] ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '${refAthlete['club'] ?? "Certified Referee"} • ELO ${refAthlete['elo'] ?? "1750"}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.emerald.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppTheme.emerald),
                                ),
                                child: const Text(
                                  '+ SELECT',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontMono,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.emerald,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],

          const SizedBox(height: 10),

          // Display ONLY Selected Referees for this Table
          if (assignedIds.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0x80070A11),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: const Color(0x24FFFFFF)),
              ),
              child: const Text(
                'No referees selected yet. Tap "SEARCH REFEREE" above to search and select at least 2 athlete-referees.',
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppTheme.textSecondary,
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SELECTED TABLE REFEREES:',
                  style: TextStyle(
                    fontFamily: AppTheme.fontMono,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.emerald,
                  ),
                ),
                const SizedBox(height: 6),
                for (final refId in assignedIds) ...[
                  Builder(
                    builder: (context) {
                      final refInfo = _resolveRefereeById(refId, pool);
                      return HoldToInspectText(
                        title: 'Selected Referee',
                        fullText:
                            '${refInfo['name']}\n${refInfo['badge'] ?? refInfo['club']}',
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.emerald.withValues(alpha: 0.2),
                                const Color(0xE6070A11),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.emerald.withValues(alpha: 0.75),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.verified_user_rounded,
                                size: 16,
                                color: AppTheme.emerald,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      refInfo['name'] ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      refInfo['badge'] ??
                                          refInfo['club'] ??
                                          'Certified Athlete-Referee',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => _toggleRefereeSelection(
                                  tables,
                                  tableIndex,
                                  refId,
                                  false,
                                ),
                                borderRadius: BorderRadius.circular(7),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: AppTheme.crimsonPrimary
                                        .withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(7),
                                    border: Border.all(
                                      color: AppTheme.crimsonPrimary
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 15,
                                    color: AppTheme.crimsonPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  void _toggleRefereeSelection(
    List<Map<String, dynamic>> tables,
    int tableIndex,
    String refId,
    bool select,
  ) {
    HapticFeedback.selectionClick();
    final nextTables =
        tables.map((e) => Map<String, dynamic>.from(e)).toList();
    final refIds = List<String>.from(
      (nextTables[tableIndex]['assignedRefereeIds'] as List?) ?? const [],
    );
    if (select) {
      if (!refIds.contains(refId)) refIds.add(refId);
    } else {
      refIds.remove(refId);
    }
    nextTables[tableIndex]['assignedRefereeIds'] = refIds;
    _emitPatch({'tables': nextTables});
  }

  Widget _buildSelectableFormatTile({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return HoldToInspectText(
      title: title,
      fullText: '$title — $subtitle',
      child: GestureDetector(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [
                      Color(0x33D4AF37),
                      Color(0xE6070A11),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(11),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5,
                        color: selected
                            ? AppTheme.goldPrimary
                            : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
          HoldToInspectText(
            title: 'Stage 01 Section',
            fullText: '$stepLabel (${isValid ? "Ready ✓" : "Required"})',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    stepLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                      color: AppTheme.goldPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                StatusChip(
                  label: isValid ? 'READY ✓' : 'REQUIRED',
                  type: isValid ? StatusType.success : StatusType.warning,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// =============================================================================
// 4. CASH PRIZE SETUP SUB-SCREEN (Clear Cash Prize Purse Only — Custom PKR Input)
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
  late String _winnerStructure; // 'OVERALL_WINNERS' | 'PER_CATEGORY_WINNERS'
  late int _topNCount;
  late List<Map<String, dynamic>> _tiers;
  final Map<int, TextEditingController> _cashCtrls = {};

  @override
  void initState() {
    super.initState();
    final cfg = widget.tournament['awardsConfig'] is Map
        ? Map<String, dynamic>.from(widget.tournament['awardsConfig'] as Map)
        : <String, dynamic>{};
    _winnerStructure =
        (cfg['winnerStructure'] ?? 'PER_CATEGORY_WINNERS').toString();
    _topNCount = ((cfg['topNCount'] as num?)?.toInt() ?? 3).clamp(1, 3);
    final rawTiers = (cfg['tiers'] is List)
        ? (cfg['tiers'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList()
        : <Map<String, dynamic>>[];
    _tiers = _syncTiersCount(_topNCount, rawTiers);
    _rebuildControllers();
  }

  void _rebuildControllers() {
    for (final i in List<int>.generate(_tiers.length, (idx) => idx)) {
      final cashText = (_tiers[i]['cashAmountPkr'] ?? 0).toString();
      if (_cashCtrls.containsKey(i)) {
        _cashCtrls[i]!.text = cashText;
      } else {
        _cashCtrls[i] = TextEditingController(text: cashText);
      }
    }
  }

  @override
  void dispose() {
    for (final c in _cashCtrls.values) {
      c.dispose();
    }
    super.dispose();
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
                ? '1st Place Champion'
                : (pos == 2 ? '2nd Place Runner-Up' : '3rd Place Podium')),
        'cashAmountPkr': (found?['cashAmountPkr'] as num?)?.toInt() ??
            (pos == 1 ? 25000 : (pos == 2 ? 15000 : 7500)),
        'awardTitle': 'Cash Prize',
      });
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space16,
              12,
              AppTheme.space16,
              24,
            ),
            children: [
              ElevatedActionCard(
                padding: const EdgeInsets.all(AppTheme.space16),
                borderColor: AppTheme.goldPrimary.withValues(alpha: 0.65),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. WINNER STRUCTURE (Clear Cash Prize Pool Scope)
                    const Text(
                      '1. CASH PRIZE DISTRIBUTION',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: AppTheme.goldPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildWinnerStructureCard(
                      title: 'Overall Tournament Champions',
                      subtitle: 'Single cash prize pool across all divisions',
                      selected: _winnerStructure == 'OVERALL_WINNERS',
                      onTap: () => setState(
                          () => _winnerStructure = 'OVERALL_WINNERS'),
                    ),
                    const SizedBox(height: 8),
                    _buildWinnerStructureCard(
                      title: 'Per-Category Champions',
                      subtitle:
                          'Separate 1st, 2nd, 3rd cash prizes in each weight class',
                      selected: _winnerStructure == 'PER_CATEGORY_WINNERS',
                      onTap: () => setState(
                          () => _winnerStructure = 'PER_CATEGORY_WINNERS'),
                    ),
                    const SizedBox(height: 18),

                    // 2. PODIUM POSITIONS PAID (1st, 1st-2nd, or 1st-3rd)
                    const Text(
                      '2. PAID PODIUM POSITIONS',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: AppTheme.goldPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (final depthOpt in const [
                          (1, '1st Only', 'Top 1 (1st Place Champion Only)'),
                          (2, 'Top 2 (1st–2nd)', 'Top 2 (1st & 2nd Place)'),
                          (3, 'Top 3 (1st–3rd)', 'Top 3 (1st, 2nd & 3rd Place)'),
                        ]) ...[
                          Expanded(
                            child: _buildEqualColumnSegment(
                              label: depthOpt.$2,
                              fullDescription: depthOpt.$3,
                              selected: _topNCount == depthOpt.$1,
                              onTap: () {
                                FocusManager.instance.primaryFocus?.unfocus();
                                setState(() {
                                  _topNCount = depthOpt.$1;
                                  _tiers =
                                      _syncTiersCount(depthOpt.$1, _tiers);
                                  _rebuildControllers();
                                });
                              },
                            ),
                          ),
                          if (depthOpt.$1 != 3) const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Custom Cash Prize (PKR) Cards for Each Podium Position
              for (int i = 0; i < _tiers.length; i++) ...[
                _buildPodiumPurseCard(i),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),

        // Fixed Bottom Save Bar
        Container(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.space16,
            10,
            AppTheme.space16,
            16,
          ),
          decoration: const BoxDecoration(
            color: Color(0xF5060911),
            border: Border(
              top: BorderSide(color: Color(0x2EFFFFFF)),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 96,
                height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0x45FFFFFF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    widget.onCancel();
                  },
                  child: const Text(
                    '< Back',
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ForgedGoldCrystalButton(
                  key: const ValueKey('save_awards_prizes_button'),
                  label: '✓ SAVE CASH PRIZES',
                  icon: Icons.payments_rounded,
                  height: 52,
                  onTap: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    HapticFeedback.mediumImpact();
                    widget.onSaveAwards({
                      'isConfigured': true,
                      'rewardType': 'CASH_PKR',
                      'winnerStructure': _winnerStructure,
                      'topNCount': _topNCount,
                      'tiers': _tiers,
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEqualColumnSegment({
    required String label,
    required String fullDescription,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return HoldToInspectText(
      title: 'Podium Depth',
      fullText: fullDescription,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          height: 42,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [
                      Color(0x40D4AF37),
                      Color(0x18D4AF37),
                    ],
                  )
                : const LinearGradient(
                    colors: [
                      Color(0xCC0B101B),
                      Color(0xE6070A11),
                    ],
                  ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppTheme.goldPrimary : const Color(0x2EFFFFFF),
              width: selected ? 1.4 : 1.0,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              color: selected ? AppTheme.textPrimary : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWinnerStructureCard({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return HoldToInspectText(
      title: title,
      fullText: '$title — $subtitle',
      child: GestureDetector(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [
                      Color(0x36D4AF37),
                      Color(0xE6070A11),
                    ],
                  )
                : const LinearGradient(
                    colors: [
                      Color(0xCC0B101B),
                      Color(0xE6070A11),
                    ],
                  ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppTheme.goldPrimary : const Color(0x2EFFFFFF),
              width: selected ? 1.4 : 1.0,
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
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: selected
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPodiumPurseCard(int index) {
    final pos = (_tiers[index]['position'] as int?) ?? (index + 1);
    final Color metalColor = pos == 1
        ? const Color(0xFFD4AF37) // 24k Champagne Gold
        : (pos == 2
            ? const Color(0xFFE2E8F0) // Brushed Platinum Silver
            : const Color(0xFFCD7F32)); // Championship Bronze
    final String posTitle = pos == 1
        ? '1ST PLACE CHAMPION • CASH PRIZE'
        : (pos == 2
            ? '2ND PLACE RUNNER-UP • CASH PRIZE'
            : '3RD PLACE PODIUM • CASH PRIZE');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            metalColor.withValues(alpha: 0.16),
            const Color(0xEB070A11),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: metalColor.withValues(alpha: 0.8),
          width: 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HoldToInspectText(
            title: posTitle,
            fullText:
                '$posTitle: PKR ${_tiers[index]['cashAmountPkr'] ?? 0}',
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: metalColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: metalColor),
                  ),
                  child: Icon(
                    Icons.payments_rounded,
                    color: metalColor,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    posTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: metalColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cashCtrls[index],
            onTapOutside: (_) =>
                FocusManager.instance.primaryFocus?.unfocus(),
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontFamily: AppTheme.fontMono,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              labelText: 'Custom Cash Prize Amount (PKR) *',
              hintText: 'Enter custom PKR amount (e.g. 25000)',
              prefixIcon: Icon(
                Icons.currency_exchange_rounded,
                size: 18,
                color: metalColor,
              ),
              suffixText: 'PKR',
            ),
            onChanged: (val) {
              setState(() {
                _tiers[index]['cashAmountPkr'] =
                    int.tryParse(val.trim()) ?? 0;
              });
            },
          ),
        ],
      ),
    );
  }
}

