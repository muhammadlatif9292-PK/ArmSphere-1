import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/crystal_glass_nav_controls.dart';
import '../../../core/widgets/crystal_stage_scaffold.dart';
import '../../../core/widgets/crystal_slash_painter.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/main_shell_screen.dart';
import '../../../core/widgets/skeleton_placeholder.dart';
import '../../../core/providers/dependency_providers.dart';
import '../../../core/providers/state_providers.dart';
import '../../../core/providers/tournament_provider.dart';
import '../../../core/providers/referee_provider.dart';
import '../../../core/providers/admin_provider.dart';
import '../../../core/providers/athlete_provider.dart';
import '../../../core/providers/live_matches_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/providers/rankings_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../tournament/services/tournament_offline_store.dart';
import '../widgets/live_scorepad_controller.dart';
import '../../../core/widgets/crystal_toast.dart';

const List<String> _kScoreOptions = ['3-0', '3-1', '3-2', '2-3', '1-3', '0-3'];

StatusType _resolveMatchStatusType(String status) {
  switch (status.toUpperCase()) {
    case 'COMPLETED':
    case 'DONE':
      return StatusType.success;
    case 'CALLED':
      return StatusType.info;
    case 'READY':
      return StatusType.warning;
    case 'BYE':
    default:
      return StatusType.neutral;
  }
}

StatusType _resolveCertStatusType(String status) {
  switch (status.toUpperCase()) {
    case 'ACTIVE':
      return StatusType.success;
    case 'REVOKED':
      return StatusType.error;
    default:
      return StatusType.neutral;
  }
}

/// Referee Dashboard — Offline-First Table Assignment Cards, Strict 4-Point
/// Green-Light Pre-Match Validation, Normal Win/Loss + Win by Forfeit/Injury,
/// and Single-Tap Locked Zero-Error Offline Result Submission.
class RefereeDashboardScreen extends ConsumerStatefulWidget {
  const RefereeDashboardScreen({super.key});

  @override
  ConsumerState<RefereeDashboardScreen> createState() => _RefereeDashboardScreenState();
}

class _RefereeDashboardScreenState extends ConsumerState<RefereeDashboardScreen> {
  String? _selectedEventId;
  bool _busy = false;

  // Referee Assignment & Table Console State
  Map<String, dynamic>? _activeAssignment;
  final TextEditingController _athleteQueryCtrl = TextEditingController();
  final TextEditingController _opponentQueryCtrl = TextEditingController();
  RefereePreMatchValidationResult? _validationResult;
  String _selectedWinSide = 'A';
  bool _isWalkoverForfeit = false;
  String _forfeitReason = 'Injury / Medical Withdrawal';
  String _scoreLine = '3-0';
  final Set<String> _localSubmittedMatchLocks = <String>{};
  String? _lastConfirmedSubmissionMessage;

  @override
  void dispose() {
    _athleteQueryCtrl.dispose();
    _opponentQueryCtrl.dispose();
    super.dispose();
  }

  void _runPreMatchCheck(List<Map<String, dynamic>> serverEvents) {
    final assignment = _activeAssignment;
    if (assignment == null) return;
    final hive = ref.read(hiveStorageProvider);
    final tId = (assignment['tournamentId'] ?? '').toString();
    final tableNumber = (assignment['assignedTableNumber'] as num?)?.toInt() ?? 1;

    final tournament = TournamentOfflineStore.getReleasedTournamentById(
          hive: hive,
          tournamentId: tId,
          serverEvents: serverEvents,
        ) ??
        Map<String, dynamic>.from(assignment['tournament'] as Map? ?? {});

    final res = TournamentOfflineStore.validatePreMatchForReferee(
      tournament: tournament,
      assignedTableNumber: tableNumber,
      primaryInput: _athleteQueryCtrl.text,
      secondaryInput: _opponentQueryCtrl.text,
    );

    setState(() {
      _validationResult = res;
      if (res.matchedBout != null) {
        final mId = (res.matchedBout!['id'] ?? '').toString();
        if (TournamentOfflineStore.isMatchSubmissionLocked(hive, tId, mId)) {
          _localSubmittedMatchLocks.add('$tId::$mId');
        }
      }
    });
  }

  Future<void> _openQrScannerSimulationModal(
    BuildContext context,
    Map<String, dynamic> tournament,
    int assignedTableNumber,
    List<Map<String, dynamic>> serverEvents,
  ) async {
    HapticFeedback.mediumImpact();
    final matchups = (tournament['matchups'] is List)
        ? (tournament['matchups'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];
    final applied = (tournament['appliedAthletes'] is List)
        ? (tournament['appliedAthletes'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];

    final qrTextCtrl = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            18,
            18,
            MediaQuery.viewInsetsOf(ctx).bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.goldPrimary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.goldPrimary.withValues(alpha: 0.5)),
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: AppTheme.goldPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SCAN ATHLETE QR CODE',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'Table $assignedTableNumber • Scans Settings QR, Tournament QR Card, or Printed Player Badge',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: qrTextCtrl,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Paste / Scan Raw QR Payload or Athlete ID',
                    hintText: 'ARMSPHERE-ATHLETE-QR:ath-pk-01:Malik Sherbaz',
                    prefixIcon: const Icon(Icons.qr_code_2_rounded, color: AppTheme.goldPrimary),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.check_circle_rounded, color: AppTheme.emerald),
                      onPressed: () {
                        if (qrTextCtrl.text.trim().isNotEmpty) {
                          _athleteQueryCtrl.text = qrTextCtrl.text.trim();
                          Navigator.of(ctx).pop();
                          _runPreMatchCheck(serverEvents);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'QUICK-SCAN SIMULATION (SELECT ATHLETE / MATCHUP QR)',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppTheme.goldPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                for (final m in matchups.where((m) => m['isBye'] != true)) ...[
                  Builder(
                    builder: (_) {
                      final mTable = (m['tableNumber'] as num?)?.toInt() ?? 1;
                      final status = (m['status'] ?? 'PENDING').toString().toUpperCase();
                      final p1 = (m['player1Name'] ?? 'Athlete 1').toString();
                      final p1Id = (m['player1Id'] ?? '').toString();
                      final p2 = (m['player2Name'] ?? 'Athlete 2').toString();
                      final p2Id = (m['player2Id'] ?? '').toString();
                      final isThisTable = mTable == assignedTableNumber;
                      final isPending = status != 'DONE' && status != 'COMPLETED';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.obsidian,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (isThisTable && isPending)
                                ? AppTheme.emerald.withValues(alpha: 0.55)
                                : const Color(0x33FFFFFF),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                StatusChip(
                                  label: 'TABLE $mTable',
                                  color: isThisTable ? AppTheme.emerald : AppTheme.warning,
                                ),
                                const SizedBox(width: 6),
                                StatusChip(
                                  label: status,
                                  color: isPending ? AppTheme.cyan : AppTheme.textMuted,
                                ),
                                const Spacer(),
                                Text(
                                  (m['categoryLabel'] ?? '').toString(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$p1 vs $p2',
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.emerald,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    minimumSize: Size.zero,
                                  ),
                                  onPressed: () {
                                    _athleteQueryCtrl.text =
                                        'ARMSPHERE-ATHLETE-QR:$p1Id:$p1';
                                    _opponentQueryCtrl.text =
                                        'ARMSPHERE-ATHLETE-QR:$p2Id:$p2';
                                    Navigator.of(ctx).pop();
                                    _runPreMatchCheck(serverEvents);
                                  },
                                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 15),
                                  label: const Text(
                                    'Scan Both Opponents QR',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.goldPrimary,
                                    side: BorderSide(color: AppTheme.goldPrimary.withValues(alpha: 0.5)),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    minimumSize: Size.zero,
                                  ),
                                  onPressed: () {
                                    _athleteQueryCtrl.text =
                                        'ARMSPHERE-ATHLETE-QR:$p1Id:$p1';
                                    _opponentQueryCtrl.clear();
                                    Navigator.of(ctx).pop();
                                    _runPreMatchCheck(serverEvents);
                                  },
                                  icon: const Icon(Icons.person_pin_rounded, size: 15),
                                  label: Text(
                                    'Scan $p1 QR',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
                if (applied.length >= 2) ...[
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.crimson,
                      side: BorderSide(color: AppTheme.crimson.withValues(alpha: 0.6)),
                    ),
                    onPressed: () {
                      // Test mismatched opponent validation
                      final first = applied.first;
                      _athleteQueryCtrl.text = (first['athleteName'] ?? 'Malik Sherbaz').toString();
                      _opponentQueryCtrl.text = 'Unmatched Wrong Opponent';
                      Navigator.of(ctx).pop();
                      _runPreMatchCheck(serverEvents);
                    },
                    icon: const Icon(Icons.warning_amber_rounded, size: 16),
                    label: const Text(
                      'Test Wrongly Matched Opponent Scan (Red Warning)',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleOfflineSafeRefereeSubmit({
    required Map<String, dynamic> assignment,
    required Map<String, dynamic> bout,
    required List<Map<String, dynamic>> serverEvents,
  }) async {
    final tId = (assignment['tournamentId'] ?? '').toString();
    final mId = (bout['id'] ?? '').toString();
    final lockKey = '$tId::$mId';
    final hive = ref.read(hiveStorageProvider);

    // Single-Tap Lock: immediately block duplicate taps
    if (_localSubmittedMatchLocks.contains(lockKey) ||
        TournamentOfflineStore.isMatchSubmissionLocked(hive, tId, mId)) {
      return;
    }

    setState(() {
      _localSubmittedMatchLocks.add(lockKey);
    });
    HapticFeedback.heavyImpact();

    final winnerId = _selectedWinSide == 'A'
        ? (bout['player1Id'] ?? '').toString()
        : (bout['player2Id'] ?? '').toString();
    final winnerName = _selectedWinSide == 'A'
        ? (bout['player1Name'] ?? 'Athlete 1').toString()
        : (bout['player2Name'] ?? 'Athlete 2').toString();

    OfflineSyncManager? syncManager;
    try {
      syncManager = ref.read(offlineSyncManagerProvider);
    } catch (_) {}

    final result = await TournamentOfflineStore.submitRefereeMatchResultOfflineSafe(
      hive: hive,
      syncManager: syncManager,
      tournamentId: tId,
      matchupId: mId,
      winnerId: winnerId,
      winnerName: winnerName,
      winMethod: _isWalkoverForfeit ? 'FORFEIT_INJURY' : 'NORMAL',
      forfeitReason: _isWalkoverForfeit ? _forfeitReason : null,
      scoreLine: _isWalkoverForfeit ? 'W/O (Forfeit/Injury)' : _scoreLine,
      refereeId: (assignment['refereeId'] ?? 'ref-pk-01').toString(),
      refereeName: (assignment['refereeName'] ?? 'Official Referee').toString(),
      assignedTableNumber: (assignment['assignedTableNumber'] as num?)?.toInt() ?? 1,
    );

    // Update active assignment snapshot and re-run validation so the match shows Done / Sent
    final refreshedAssignments = TournamentOfflineStore.getRefereeAssignments(
      hive: hive,
      userProfile: ref.read(authProvider).userProfile,
      serverEvents: serverEvents,
    );
    final updatedAssignment = refreshedAssignments
        .where((a) =>
            a['tournamentId'] == tId &&
            a['assignedTableNumber'] == assignment['assignedTableNumber'])
        .firstOrNull;

    if (mounted) {
      setState(() {
        if (updatedAssignment != null) {
          _activeAssignment = updatedAssignment;
        } else if (result['tournament'] is Map) {
          _activeAssignment = {
            ...assignment,
            'tournament': result['tournament'],
          };
        }
        _lastConfirmedSubmissionMessage =
            'DONE / SENT ✓ • Winner: $winnerName (${_isWalkoverForfeit ? "Win by Forfeit / Injury Walkover" : "Normal $_scoreLine"}) • Table ${assignment['assignedTableNumber']} Freed for Next Matchup';
        _runPreMatchCheck(serverEvents);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        CrystalSnackBar(
          content: Text(
            'Done / Sent ✓ • $winnerName recorded (${_isWalkoverForfeit ? "Forfeit/Injury Walkover" : _scoreLine}). Table ${assignment['assignedTableNumber']} freed & synced offline-first.',
          ),
          backgroundColor: AppTheme.emerald,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _run(Future<void> Function() action, {String? successMessage}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted && successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          CrystalSnackBar(
            content: Text(successMessage),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CrystalSnackBar(
            content: Text(e.detail),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CrystalSnackBar(
            content: Text('Action saved to offline queue: $e'),
            backgroundColor: AppTheme.emerald,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refreshBoard() async {
    final eventId = _selectedEventId;
    if (eventId != null) ref.invalidate(eventMatchesProvider(eventId));
    ref.invalidate(matchTablesProvider);
  }

  Future<void> _callToTable(Map<String, dynamic> match) async {
    final tables = await ref.read(matchTablesProvider.future);
    if (!mounted) return;
    if (tables.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        CrystalSnackBar(
          content: const Text('No tables exist yet — ask the organizer to add tables first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    String? tableId = tables.first['id']?.toString();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            side: const BorderSide(color: AppTheme.cardBorder),
          ),
          title: const Text('Call Match to Table', style: TextStyle(fontFamily: AppTheme.fontDisplay)),
          content: DropdownButtonFormField<String>(
            initialValue: tableId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Select Assigned Table'),
            items: [
              for (final t in tables)
                DropdownMenuItem(
                  value: t['id']?.toString(),
                  child: Text('${t['name'] ?? 'Table'} (${t['status'] ?? ''})', overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => setDialogState(() => tableId = v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Call Match'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || tableId == null) return;
    await _run(() async {
      await ref.read(tournamentRepositoryProvider).callMatchToTable(
            matchId: match['id'].toString(),
            tableId: tableId!,
          );
      await _refreshBoard();
    }, successMessage: 'Match successfully called to table.');
  }

  Future<void> _submitResult(Map<String, dynamic> match) async {
    final aName = match['athleteAName']?.toString() ?? 'Athlete A';
    final bName = match['athleteBName']?.toString() ?? 'Athlete B';
    String winnerSide = 'A';
    String scoreLine = _kScoreOptions.first;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            side: const BorderSide(color: AppTheme.cardBorder),
          ),
          title: const Text('Submit Official Result', style: TextStyle(fontFamily: AppTheme.fontDisplay)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                value: 'A',
                groupValue: winnerSide,
                activeColor: AppTheme.primaryRed,
                title: Text(aName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Red Corner (Athlete A)', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                onChanged: (v) => setDialogState(() => winnerSide = v ?? 'A'),
              ),
              RadioListTile<String>(
                value: 'B',
                groupValue: winnerSide,
                activeColor: AppTheme.primaryRed,
                title: Text(bName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('White Corner (Athlete B)', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                onChanged: (v) => setDialogState(() => winnerSide = v ?? 'B'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: scoreLine,
                decoration: const InputDecoration(labelText: 'Score line (wins-pulls format)'),
                items: [
                  for (final s in _kScoreOptions)
                    DropdownMenuItem(
                      value: s,
                      child: Text(
                        s,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontWeight: FontWeight.bold,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                ],
                onChanged: (v) => setDialogState(() => scoreLine = v ?? scoreLine),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Submit Result'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    final winnerId = (winnerSide == 'A' ? match['athleteAId'] : match['athleteBId'])?.toString();
    if (winnerId == null || winnerId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CrystalSnackBar(
            content: const Text('Both athletes must be determined before a result can be submitted.'),
            backgroundColor: AppTheme.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    await _run(() async {
      await ref.read(tournamentRepositoryProvider).submitTournamentResult(
            matchId: match['id'].toString(),
            winnerId: winnerId,
            scoreLine: scoreLine,
          );
      await _refreshBoard();
    }, successMessage: 'Official match result recorded.');
  }

  Widget _buildRefereeTableConsole(
    BuildContext context,
    Map<String, dynamic> assignment,
    List<Map<String, dynamic>> serverEvents,
  ) {
    final hive = ref.read(hiveStorageProvider);
    final tId = (assignment['tournamentId'] ?? '').toString();
    final tableNumber = (assignment['assignedTableNumber'] as num?)?.toInt() ?? 1;
    final totalTables = (assignment['tableCount'] as num?)?.toInt() ?? 1;

    final tournament = TournamentOfflineStore.getReleasedTournamentById(
          hive: hive,
          tournamentId: tId,
          serverEvents: serverEvents,
        ) ??
        Map<String, dynamic>.from(assignment['tournament'] as Map? ?? {});

    final matchups = (tournament['matchups'] is List)
        ? (tournament['matchups'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .where((m) => m['isBye'] != true)
            .toList()
        : <Map<String, dynamic>>[];

    final myTablePending = matchups
        .where((m) =>
            ((m['tableNumber'] as num?)?.toInt() ?? 1) == tableNumber &&
            (m['status'] ?? 'PENDING').toString().toUpperCase() != 'DONE' &&
            (m['status'] ?? 'PENDING').toString().toUpperCase() != 'COMPLETED')
        .toList();

    final validation = _validationResult;
    final validatedBout = validation?.matchedBout;
    final validatedBoutId = (validatedBout?['id'] ?? '').toString();
    final isLocked = validatedBoutId.isNotEmpty &&
        (_localSubmittedMatchLocks.contains('$tId::$validatedBoutId') ||
            TournamentOfflineStore.isMatchSubmissionLocked(
              hive,
              tId,
              validatedBoutId,
            ) ||
            (validatedBout?['status'] ?? '').toString().toUpperCase() == 'DONE');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Navigation Back to Assignment Cards List
        ElevatedActionCard(
          padding: const EdgeInsets.all(16),
          borderColor: AppTheme.goldPrimary.withValues(alpha: 0.55),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _activeAssignment = null;
                        _validationResult = null;
                        _lastConfirmedSubmissionMessage = null;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.goldPrimary.withValues(alpha: 0.5)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back_ios_new_rounded, size: 12, color: AppTheme.goldPrimary),
                          SizedBox(width: 4),
                          Text(
                            'ALL ASSIGNMENTS',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.goldPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  StatusChip(
                    label: totalTables > 1
                        ? 'ASSIGNED: TABLE $tableNumber OF $totalTables'
                        : 'ASSIGNED: MAIN TABLE 1',
                    color: AppTheme.goldPrimary,
                    icon: Icons.table_restaurant_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                (tournament['name'] ?? assignment['tournamentName'] ?? 'Sanctioned Tournament').toString(),
                style: const TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${tournament['organizationName'] ?? assignment['organizationName'] ?? ''} • ${tournament['venue'] ?? assignment['venue'] ?? ''}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  StatusChip(
                    label: 'REFEREE: ${(assignment['refereeName'] ?? 'Official').toString().toUpperCase()}',
                    color: AppTheme.emerald,
                    icon: Icons.verified_user_rounded,
                  ),
                  StatusChip(
                    label: '${myTablePending.length} PENDING ON TABLE $tableNumber',
                    color: AppTheme.cyan,
                    icon: Icons.sports_kabaddi_rounded,
                  ),
                  const StatusChip(
                    label: 'OFFLINE-SAFE OUTBOX ACTIVE',
                    color: AppTheme.emerald,
                    icon: Icons.offline_bolt_rounded,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Large Thumb-Friendly Scan QR Button + Athlete Name/ID Search Fields
        ElevatedActionCard(
          padding: const EdgeInsets.all(16),
          borderColor: AppTheme.emerald.withValues(alpha: 0.45),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.qr_code_scanner_rounded, color: AppTheme.goldPrimary, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'STRICT PRE-MATCH IDENTITY & GREEN-LIGHT CHECK',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.7,
                        color: AppTheme.goldPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Scan the athlete\'s QR code (from Settings, Mobile App, Saved Card, or Printed Badge) or type their Name / ID to verify table & opponent clearance.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.35),
              ),
              const SizedBox(height: 14),

              // Large Thumb-Friendly "Scan QR" Button
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  key: const ValueKey('referee_large_scan_qr_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.goldPrimary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => _openQrScannerSimulationModal(
                    context,
                    tournament,
                    tableNumber,
                    serverEvents,
                  ),
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 24),
                  label: const Text(
                    'SCAN QR (ATHLETE / SETTINGS / CARD)',
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Athlete Name / ID typing/search field
              TextField(
                key: const ValueKey('referee_athlete_name_search_field'),
                controller: _athleteQueryCtrl,
                onChanged: (_) => _runPreMatchCheck(serverEvents),
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13.5),
                decoration: InputDecoration(
                  labelText: 'Athlete 1 Name, ID Number, or QR Payload',
                  hintText: 'Type athlete name (e.g. Malik Sherbaz) or ID (ath-pk-01)...',
                  prefixIcon: const Icon(Icons.person_search_rounded, color: AppTheme.goldPrimary),
                  suffixIcon: _athleteQueryCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _athleteQueryCtrl.clear();
                            _runPreMatchCheck(serverEvents);
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const ValueKey('referee_opponent_name_search_field'),
                controller: _opponentQueryCtrl,
                onChanged: (_) => _runPreMatchCheck(serverEvents),
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13.5),
                decoration: InputDecoration(
                  labelText: 'Opponent Name, ID, or QR (Optional 2-Player Verification)',
                  hintText: 'Verify exact matched opponent (blocks wrongly paired players)...',
                  prefixIcon: const Icon(Icons.people_alt_outlined, color: AppTheme.cyan),
                  suffixIcon: _opponentQueryCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _opponentQueryCtrl.clear();
                            _runPreMatchCheck(serverEvents);
                          },
                        )
                      : null,
                ),
              ),

              if (myTablePending.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'TABLE QUEUE QUICK-VERIFY:',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final m in myTablePending)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            backgroundColor: AppTheme.obsidian,
                            side: BorderSide(color: AppTheme.emerald.withValues(alpha: 0.5)),
                            avatar: const Icon(Icons.verified_rounded, size: 15, color: AppTheme.emerald),
                            label: Text(
                              '${m['player1Name']} vs ${m['player2Name']}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              _athleteQueryCtrl.text = (m['player1Name'] ?? '').toString();
                              _opponentQueryCtrl.text = (m['player2Name'] ?? '').toString();
                              _runPreMatchCheck(serverEvents);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Strict Pre-Match Validation Result (Green-Light vs Red Warning)
        if (validation != null) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: validation.allowedToPlay
                  ? AppTheme.emerald.withValues(alpha: 0.14)
                  : AppTheme.crimson.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: validation.allowedToPlay ? AppTheme.emerald : AppTheme.crimson,
                width: 1.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      validation.allowedToPlay
                          ? Icons.check_circle_rounded
                          : Icons.gpp_bad_rounded,
                      color: validation.allowedToPlay ? AppTheme.emerald : AppTheme.crimson,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            validation.headline,
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: validation.allowedToPlay
                                  ? AppTheme.emerald
                                  : AppTheme.crimson,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            validation.detail,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.textPrimary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0x22FFFFFF)),
                const SizedBox(height: 10),
                _buildCheckRow(
                  'a) Active match in this tournament & active round',
                  validation.checkAActiveMatchInRound,
                ),
                _buildCheckRow(
                  'b) Exact matched opponents (blocks wrong pairings)',
                  validation.checkBExactMatchedOpponents,
                ),
                _buildCheckRow(
                  'c) Match status is Pending (blocks already Done matches)',
                  validation.checkCMatchStillPending,
                ),
                _buildCheckRow(
                  'd) Assigned to THIS referee\'s Table $tableNumber',
                  validation.checkDBelongsToAssignedTable,
                ),

                // Result Submission Form (Only unlocked when Green-Light Allowed to Play OR showing Done lock state)
                if (validatedBout != null && (validation.allowedToPlay || isLocked)) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: AppTheme.recessedObsidianWellDecoration(radius: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'OFFICIAL RESULT SUBMISSION • TABLE $tableNumber',
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontWeight: FontWeight.w900,
                                fontSize: 11.5,
                                color: AppTheme.goldPrimary,
                                letterSpacing: 0.6,
                              ),
                            ),
                            StatusChip(
                              label: isLocked ? 'DONE / SENT ✓' : 'ALLOWED TO PLAY',
                              color: AppTheme.emerald,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${validatedBout['categoryLabel'] ?? 'Category'} • Round ${validatedBout['roundNumber'] ?? 1}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 10),

                        // Winner Selection Cards
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: isLocked
                                    ? null
                                    : () {
                                        HapticFeedback.selectionClick();
                                        setState(() => _selectedWinSide = 'A');
                                      },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _selectedWinSide == 'A'
                                        ? AppTheme.emerald.withValues(alpha: 0.18)
                                        : AppTheme.cardSurface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _selectedWinSide == 'A'
                                          ? AppTheme.emerald
                                          : const Color(0x33FFFFFF),
                                      width: _selectedWinSide == 'A' ? 1.6 : 1.0,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'WINNER • CORNER A',
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.emerald,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        (validatedBout['player1Name'] ?? 'Athlete 1').toString(),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13.5,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: isLocked
                                    ? null
                                    : () {
                                        HapticFeedback.selectionClick();
                                        setState(() => _selectedWinSide = 'B');
                                      },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _selectedWinSide == 'B'
                                        ? AppTheme.emerald.withValues(alpha: 0.18)
                                        : AppTheme.cardSurface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _selectedWinSide == 'B'
                                          ? AppTheme.emerald
                                          : const Color(0x33FFFFFF),
                                      width: _selectedWinSide == 'B' ? 1.6 : 1.0,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'WINNER • CORNER B',
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.emerald,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        (validatedBout['player2Name'] ?? 'Athlete 2').toString(),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13.5,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Normal Win/Loss vs Win by Forfeit / Injury (Walkover)
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                selected: !_isWalkoverForfeit,
                                selectedColor: AppTheme.emerald.withValues(alpha: 0.25),
                                label: const Text(
                                  'Normal Win / Loss',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                                ),
                                onSelected: isLocked
                                    ? null
                                    : (v) {
                                        if (v) setState(() => _isWalkoverForfeit = false);
                                      },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ChoiceChip(
                                selected: _isWalkoverForfeit,
                                selectedColor: AppTheme.goldPrimary.withValues(alpha: 0.25),
                                label: const Text(
                                  'Win by Forfeit / Injury',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                                ),
                                onSelected: isLocked
                                    ? null
                                    : (v) {
                                        if (v) setState(() => _isWalkoverForfeit = true);
                                      },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        if (!_isWalkoverForfeit)
                          DropdownButtonFormField<String>(
                            initialValue: _scoreLine,
                            decoration: const InputDecoration(
                              labelText: 'Match Score Line',
                              prefixIcon: Icon(Icons.scoreboard_outlined, size: 18),
                            ),
                            items: [
                              for (final s in _kScoreOptions)
                                DropdownMenuItem(value: s, child: Text(s)),
                            ],
                            onChanged: isLocked
                                ? null
                                : (v) => setState(() => _scoreLine = v ?? '3-0'),
                          )
                        else
                          DropdownButtonFormField<String>(
                            initialValue: _forfeitReason,
                            decoration: const InputDecoration(
                              labelText: 'Walkover / Forfeit / Injury Reason',
                              prefixIcon: Icon(Icons.medical_services_outlined, size: 18),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Injury / Medical Withdrawal',
                                child: Text('Injury / Medical Withdrawal (Walkover)'),
                              ),
                              DropdownMenuItem(
                                value: 'Opponent Forfeit / Did Not Report to Table',
                                child: Text('Opponent Forfeit / No-Show Walkover'),
                              ),
                              DropdownMenuItem(
                                value: 'Referee Foul / Disqualification',
                                child: Text('Referee Foul / Disqualification'),
                              ),
                            ],
                            onChanged: isLocked
                                ? null
                                : (v) => setState(
                                    () => _forfeitReason = v ?? 'Injury / Medical Withdrawal'),
                          ),

                        const SizedBox(height: 14),

                        // Single-Tap Locked Submit Button
                        SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            key: const ValueKey('referee_single_tap_submit_result_button'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isLocked ? AppTheme.obsidian : AppTheme.emerald,
                              foregroundColor:
                                  isLocked ? AppTheme.emerald : Colors.black,
                              side: isLocked
                                  ? const BorderSide(color: AppTheme.emerald, width: 1.4)
                                  : null,
                            ),
                            onPressed: isLocked
                                ? null
                                : () => _handleOfflineSafeRefereeSubmit(
                                      assignment: assignment,
                                      bout: validatedBout,
                                      serverEvents: serverEvents,
                                    ),
                            icon: Icon(
                              isLocked
                                  ? Icons.lock_clock_rounded
                                  : Icons.send_and_archive_rounded,
                              size: 20,
                            ),
                            label: Text(
                              isLocked
                                  ? 'DONE / SENT ✓ (SINGLE-TAP LOCKED)'
                                  : (_isWalkoverForfeit
                                      ? 'SUBMIT WIN BY FORFEIT / INJURY (WALKOVER)'
                                      : 'SUBMIT OFFICIAL MATCH RESULT (OFFLINE-SAFE)'),
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontWeight: FontWeight.w900,
                                fontSize: 12.5,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        if (_lastConfirmedSubmissionMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.emerald.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.emerald),
            ),
            child: Row(
              children: [
                const Icon(Icons.cloud_done_rounded, color: AppTheme.emerald, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _lastConfirmedSubmissionMessage!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // All Matchups on This Referee's Table
        ElevatedActionCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TABLE $tableNumber MATCHUP QUEUE (${matchups.where((m) => ((m['tableNumber'] as num?)?.toInt() ?? 1) == tableNumber).length} BOUTS)',
                style: const TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: AppTheme.goldPrimary,
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(height: 10),
              for (final m in matchups.where(
                  (m) => ((m['tableNumber'] as num?)?.toInt() ?? 1) == tableNumber))
                Builder(
                  builder: (_) {
                    final status = (m['status'] ?? 'PENDING').toString().toUpperCase();
                    final isDone = status == 'DONE' || status == 'COMPLETED';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.obsidian,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDone
                              ? AppTheme.textMuted.withValues(alpha: 0.3)
                              : AppTheme.emerald.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${m['player1Name']} vs ${m['player2Name']}',
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${m['categoryLabel'] ?? ''} • Round ${m['roundNumber'] ?? 1}${isDone ? ' • Winner: ${m['winnerName'] ?? ''} (${m['scoreLine'] ?? 'Done'})' : ''}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isDone)
                            const StatusChip(
                              label: 'DONE / SENT ✓',
                              color: AppTheme.emerald,
                            )
                          else
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.emerald,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                              ),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                _athleteQueryCtrl.text = (m['player1Name'] ?? '').toString();
                                _opponentQueryCtrl.text = (m['player2Name'] ?? '').toString();
                                _runPreMatchCheck(serverEvents);
                              },
                              child: const Text(
                                'VERIFY & SCORE',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckRow(String label, bool passed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 16,
            color: passed ? AppTheme.emerald : AppTheme.crimson,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: passed ? FontWeight.w700 : FontWeight.w800,
                color: passed ? AppTheme.textPrimary : AppTheme.crimson,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);
    final myUserId = auth.userProfile?['id']?.toString();
    final eventsAsync = ref.watch(tournamentProvider);
    final hive = ref.watch(hiveStorageProvider);
    final serverEvents = eventsAsync.valueOrNull ?? const <Map<String, dynamic>>[];

    final refereeAssignments = TournamentOfflineStore.getRefereeAssignments(
      hive: hive,
      userProfile: auth.userProfile,
      serverEvents: serverEvents,
    );

    final bool insideRootShell = MainShellScope.isInsideShell(context);
    final double bottomDockGap = insideRootShell
        ? (kFloatingDockTotalHeight + MediaQuery.paddingOf(context).bottom + 10.0)
        : 12.0;

    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: _activeAssignment != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.goldPrimary, size: 18),
                onPressed: () => setState(() {
                  _activeAssignment = null;
                  _validationResult = null;
                }),
              )
            : CrystalBackButton.maybeForInnerScreen(context),
        title: Text(_activeAssignment != null ? 'Referee Table Console' : 'Referee Panel'),
        actions: [
          CrystalIconPillButton(
            icon: Icons.sync_rounded,
            iconColor: AppTheme.emerald,
            tooltip: 'Sync Offline Referee Outbox',
            onPressed: () {
              try {
                ref.read(offlineSyncManagerProvider).syncQueue();
              } catch (_) {}
              setState(() {});
            },
          ),
          if (!MainShellScope.isInsideShell(context)) const CrystalHomeButton(),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: CrystalStageBackdrop(domain: ArmSphereStageDomain.referee),
          ),
          SafeArea(
            bottom: false,
            child: CrystalVaporDissolve(
              bottomMargin: bottomDockGap,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.space16,
                  kToolbarHeight + 8,
                  AppTheme.space16,
                  28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 155px open 3D Referee Control Console stage showcase spacer
                    const SizedBox(height: 155),
                    if (_activeAssignment != null)
                      _buildRefereeTableConsole(
                        context,
                        _activeAssignment!,
                        serverEvents,
                      )
                    else ...[
                      Text(
                        'MY TABLE ASSIGNMENTS (OFFLINE-READY)',
                        style: theme.textTheme.labelMedium?.copyWith(
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.goldPrimary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space12),
                      for (final assignment in refereeAssignments)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ElevatedActionCard(
                            key: ValueKey(
                              'referee_assignment_card_${assignment['tournamentId']}_table_${assignment['assignedTableNumber']}',
                            ),
                            borderColor: AppTheme.goldPrimary.withValues(alpha: 0.55),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _activeAssignment = assignment;
                                _athleteQueryCtrl.clear();
                                _opponentQueryCtrl.clear();
                                _validationResult = null;
                                _lastConfirmedSubmissionMessage = null;
                              });
                            },
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    StatusChip(
                                      label: ((assignment['tableCount'] as num?)?.toInt() ?? 1) > 1
                                          ? 'ASSIGNED: TABLE ${assignment['assignedTableNumber']}'
                                          : 'ASSIGNED: TABLE 1',
                                      color: AppTheme.goldPrimary,
                                      icon: Icons.table_restaurant_rounded,
                                    ),
                                    const SizedBox(width: 8),
                                    StatusChip(
                                      label: '${assignment['pendingOnTableCount']} PENDING',
                                      color: AppTheme.emerald,
                                    ),
                                    const Spacer(),
                                    const StatusChip(
                                      label: 'CACHED OFFLINE',
                                      color: AppTheme.cyan,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  (assignment['tournamentName'] ?? 'Sanctioned Tournament').toString(),
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16.5,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${assignment['organizationName'] ?? ''} • ${assignment['venue'] ?? ''}, ${assignment['city'] ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Referee: ${assignment['refereeName']} • Tap to open Scan QR & Green-Light Matchup Validator',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: AppTheme.emerald,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                      color: AppTheme.goldPrimary,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: AppTheme.space16),
                      Text(
                        'OFFICIAL ACTIONS',
                        style: theme.textTheme.labelMedium?.copyWith(
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space12),
                      _RefereeScorepadHeroCard(
                        onTap: () => context.push('/referee/submit-scorepad'),
                      ),
                      const SizedBox(height: AppTheme.space12),
                      Row(
                        children: [
                          Expanded(
                            child: _RefCard(
                              icon: Icons.verified_outlined,
                              label: 'Certifications',
                              onTap: () => context.push('/referee/certifications'),
                            ),
                          ),
                          const SizedBox(width: AppTheme.space8),
                          Expanded(
                            child: _RefCard(
                              icon: Icons.search,
                              label: 'Search Athletes',
                              onTap: () => context.push('/referee/search-athletes'),
                            ),
                          ),
                          const SizedBox(width: AppTheme.space8),
                          Expanded(
                            child: _RefCard(
                              icon: Icons.cloud_upload_outlined,
                              label: 'Upload Evidence',
                              onTap: () => context.push('/referee/upload-evidence'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space24),
                      Text(
                        'LIVE EVENT BOARD',
                        style: theme.textTheme.labelMedium?.copyWith(
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space12),
                      eventsAsync.when(
                        loading: () => const Column(
                          children: [
                            SkeletonPlaceholder(height: 84),
                            SizedBox(height: AppTheme.space12),
                            SkeletonPlaceholder(height: 112),
                          ],
                        ),
                        error: (e, _) => ElevatedActionCard(
                          padding: const EdgeInsets.all(AppTheme.space16),
                          child: Row(
                            children: [
                              const Icon(Icons.offline_bolt_rounded, color: AppTheme.emerald, size: 24),
                              const SizedBox(width: AppTheme.space12),
                              const Expanded(
                                child: Text(
                                  'Offline Mode Active — Use your cached Table Assignment Cards above to scan QR codes and submit results without internet.',
                                  style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                                ),
                              ),
                              TextButton(
                                onPressed: () => ref.invalidate(tournamentProvider),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                        data: (events) {
                          final selectable = events
                              .where((e) => !['DRAFT', 'CANCELLED'].contains(e['status']?.toString().toUpperCase()))
                              .toList();
                          if (_selectedEventId == null ||
                              !selectable.any((e) => e['id']?.toString() == _selectedEventId)) {
                            _selectedEventId = selectable.isNotEmpty ? selectable.first['id']?.toString() : null;
                          }
                          if (selectable.isEmpty) {
                            return const ElevatedActionCard(
                              padding: EdgeInsets.all(AppTheme.space20),
                              child: Center(
                                child: Text(
                                  'No published events available yet.',
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                                ),
                              ),
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              DropdownButtonFormField<String>(
                                initialValue: _selectedEventId,
                                isExpanded: true,
                                decoration: const InputDecoration(labelText: 'Active Competition Event'),
                                items: [
                                  for (final e in selectable)
                                    DropdownMenuItem(
                                      value: e['id']?.toString(),
                                      child: Text(e['name']?.toString() ?? 'Event', overflow: TextOverflow.ellipsis),
                                    ),
                                ],
                                onChanged: (v) => setState(() => _selectedEventId = v),
                              ),
                              const SizedBox(height: AppTheme.space16),
                              _AssignmentsBody(
                                eventId: _selectedEventId!,
                                myUserId: myUserId,
                                busy: _busy,
                                onCall: _callToTable,
                                onResult: _submitResult,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentsBody extends ConsumerWidget {
  final String eventId;
  final String? myUserId;
  final bool busy;
  final Future<void> Function(Map<String, dynamic>) onCall;
  final Future<void> Function(Map<String, dynamic>) onResult;

  const _AssignmentsBody({
    required this.eventId,
    required this.myUserId,
    required this.busy,
    required this.onCall,
    required this.onResult,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(eventMatchesProvider(eventId));
    return matchesAsync.when(
      loading: () => const Column(
        children: [
          SkeletonPlaceholder(height: 112),
          SizedBox(height: AppTheme.space12),
          SkeletonPlaceholder(height: 112),
        ],
      ),
      error: (e, _) => ElevatedActionCard(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.error, size: 24),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Text(
                'Could not load matches: $e',
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(eventMatchesProvider(eventId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (all) {
        final mine = all
            .where((m) => m['refereeId']?.toString() == myUserId)
            .toList()
          ..sort((a, b) {
            final ra = (a['round'] as num?)?.toInt() ?? 0;
            final rb = (b['round'] as num?)?.toInt() ?? 0;
            final ia = (a['matchIndex'] as num?)?.toInt() ?? 0;
            final ib = (b['matchIndex'] as num?)?.toInt() ?? 0;
            return ra != rb ? ra.compareTo(rb) : ia.compareTo(ib);
          });
        if (mine.isEmpty) {
          return const ElevatedActionCard(
            padding: EdgeInsets.all(AppTheme.space20),
            child: Center(
              child: Text(
                'No matches assigned to you in this event yet.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
            ),
          );
        }
        return Column(
          children: [
            for (final m in mine) ...[
              RepaintBoundary(
                child: _AssignmentCard(match: m, busy: busy, onCall: onCall, onResult: onResult),
              ),
              const SizedBox(height: AppTheme.space12),
            ],
          ],
        );
      },
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final Map<String, dynamic> match;
  final bool busy;
  final Future<void> Function(Map<String, dynamic>) onCall;
  final Future<void> Function(Map<String, dynamic>) onResult;

  const _AssignmentCard({
    required this.match,
    required this.busy,
    required this.onCall,
    required this.onResult,
  });

  @override
  Widget build(BuildContext context) {
    final status = (match['status']?.toString() ?? '').toUpperCase();
    final aName = match['athleteAName']?.toString() ?? 'TBD';
    final bName = match['athleteBName']?.toString() ?? 'TBD';
    final roundNumber = (match['round'] as num?)?.toInt();
    final matchIndex = (match['matchIndex'] as num?)?.toInt();

    final category = [
      match['division']?.toString(),
      match['weightClass']?.toString(),
      match['arm']?.toString(),
    ].where((p) => p != null && p.isNotEmpty).join(' • ');

    final isCalled = status == 'CALLED';

    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: AppTheme.machinedTitaniumDecoration(
        radius: 18,
        borderColor: isCalled
            ? const Color(0x4DD4AF37)
            : const Color(0x26FFFFFF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          if (roundNumber != null) ...[
                            Text(
                              'R$roundNumber-M${(matchIndex ?? 0) + 1} • ',
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.goldPrimary,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                          Flexible(
                            child: Text(
                              category.toUpperCase(),
                              style: const TextStyle(
                                fontFamily: AppTheme.fontBody,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                                letterSpacing: 0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusChip(
                      label: status,
                      type: _resolveMatchStatusType(status),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space10),
                Text(
                  '$aName  vs  $bName',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if ((match['scoreLine']?.toString() ?? '').isNotEmpty) ...[
                  const SizedBox(height: AppTheme.space6),
                  Row(
                    children: [
                      const Icon(Icons.scoreboard_outlined, size: 14, color: AppTheme.success),
                      const SizedBox(width: AppTheme.space6),
                      Text(
                        'Final Score: ${match['scoreLine']}',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppTheme.success,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppTheme.space12),
                if (status == 'CALLED')
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: busy
                                ? null
                                : () {
                                    HapticFeedback.lightImpact();
                                    context.push('/referee/submit-scorepad', extra: match);
                                  },
                            icon: const Icon(Icons.touch_app, size: 18),
                            label: const Text('OPEN SCOREPAD'),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.space8),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: busy
                                ? null
                                : () {
                                    HapticFeedback.lightImpact();
                                    onResult(match);
                                  },
                            child: const Text('Quick Entry', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ),
                    ],
                  )
                else if (status == 'READY')
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: busy
                          ? null
                          : () {
                              HapticFeedback.lightImpact();
                              onCall(match);
                            },
                      icon: const Icon(Icons.table_restaurant, size: 18),
                      label: const Text('CALL TO TABLE'),
                    ),
                  ),
              ],
            ),
    );
  }
}

typedef _MatchItemCard = _AssignmentCard;

class _RefereeScorepadHeroCard extends StatelessWidget {
  final VoidCallback onTap;

  const _RefereeScorepadHeroCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedActionCard(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      borderColor: AppTheme.primaryRed.withValues(alpha: 0.45),
      watermark: ForgedWatermarkType.refereeStrap,
      padding: const EdgeInsets.all(AppTheme.space16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0x80E23B3B),
                width: 1.0,
              ),
              boxShadow: const [],
            ),
            child: const Icon(
              Icons.sports_score_rounded,
              size: 26,
              color: AppTheme.primaryRed,
            ),
          ),
          const SizedBox(width: AppTheme.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'Live Table Scorepad',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          letterSpacing: 0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppTheme.space8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: const Color(0x80E23B3B),
                          width: 1.0,
                        ),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryRed,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _RefCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _RefCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedActionCard(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: 18,
      borderColor: const Color(0x38FFFFFF),
      watermark: ForgedWatermarkType.refereeStrap,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: AppTheme.space12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space8),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0x80E23B3B),
                width: 1.0,
              ),
            ),
            child: Icon(icon, size: 22, color: AppTheme.primaryRed),
          ),
          const SizedBox(height: AppTheme.space8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Referee Certifications — real records from GET /referees/:userId/certifications.
class RefereeCertificationsScreen extends ConsumerWidget {
  const RefereeCertificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final certsAsync = ref.watch(refereeCertificationsProvider);

    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const CrystalBackButton(),
        title: const Text('Certifications'),
        actions: const [CrystalHomeButton()],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: CrystalStageBackdrop(domain: ArmSphereStageDomain.referee),
          ),
          SafeArea(
            bottom: false,
            child: CrystalVaporDissolve(
              bottomMargin: 12.0,
              child: certsAsync.when(
                loading: () => const CrystalScreenLoadingView(
                  itemCount: 3,
                  cardHeight: 96,
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.space24),
                    child: ElevatedActionCard(
                      slashVariant: const CrystalSlashVariant.crossedCard(),
                      padding: const EdgeInsets.all(AppTheme.space24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 40, color: AppTheme.error),
                          const SizedBox(height: AppTheme.space12),
                          Text('Could not load certifications', style: theme.textTheme.titleSmall),
                          const SizedBox(height: AppTheme.space16),
                          ElevatedButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              ref.invalidate(refereeCertificationsProvider);
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                data: (certs) {
                  if (certs.isEmpty) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.space24,
                        kToolbarHeight + 8,
                        AppTheme.space24,
                        120,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 155),
                          ElevatedActionCard(
                            slashVariant: const CrystalSlashVariant.crossedCard(),
                            padding: const EdgeInsets.all(AppTheme.space24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0x80E23B3B),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.workspace_premium_outlined,
                                    size: 36,
                                    color: Color(0xFFD4AF37),
                                  ),
                                ),
                                const SizedBox(height: AppTheme.space12),
                                const Text(
                                  'No certifications on file.',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.space8),
                                const Text(
                                  'Official licenses and credentials are confirmed and issued directly by national federation administrators.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.space16,
                      kToolbarHeight + 163,
                      AppTheme.space16,
                      120,
                    ),
                    itemCount: certs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppTheme.space12),
                    itemBuilder: (context, index) {
                      final c = certs[index];
                      final status = c['status']?.toString() ?? 'UNKNOWN';
                      final expires = c['expiresAt']?.toString();
                      return RepaintBoundary(
                        child: ElevatedActionCard(
                          slashVariant: index == 0
                              ? const CrystalSlashVariant.crossedCard()
                              : CrystalSlashVariant.sequentialRow(index),
                          padding: const EdgeInsets.all(AppTheme.space16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppTheme.space10),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0x73D4AF37),
                                    width: 1.0,
                                  ),
                                ),
                                child: const Icon(Icons.verified, size: 24, color: AppTheme.goldPrimary),
                              ),
                              const SizedBox(width: AppTheme.space14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c['certificationLevel']?.toString() ?? 'Certification',
                                      style: const TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: AppTheme.space4),
                                    Text(
                                      c['issuingBody']?.toString() ?? 'Federation Official Board',
                                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                    ),
                                    const SizedBox(height: AppTheme.space8),
                                    Row(
                                      children: [
                                        const Icon(Icons.event_outlined, size: 13, color: AppTheme.textMuted),
                                        const SizedBox(width: AppTheme.space4),
                                        Text(
                                          expires == null || expires.isEmpty || expires == 'null'
                                              ? 'Permanent License'
                                              : 'Expires ${expires.split('T').first}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textMuted,
                                            fontFeatures: [FontFeature.tabularFigures()],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              StatusChip(
                                label: status.toUpperCase(),
                                type: _resolveCertStatusType(status),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Match Submission (Scorepad) Screen — supports both live table-side scoring
/// (with 64dp hit targets & 400ms pin hold) and direct manual result ingestion.
class MatchSubmissionScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? match;

  const MatchSubmissionScreen({super.key, this.match});

  @override
  ConsumerState<MatchSubmissionScreen> createState() => _MatchSubmissionScreenState();
}

class _MatchSubmissionScreenState extends ConsumerState<MatchSubmissionScreen> {
  Map<String, dynamic>? _challenger;
  Map<String, dynamic>? _opponent;
  String _arm = 'RIGHT';
  String _winnerSide = 'challenger';
  String _score = '3-0';
  int _formatRounds = 5;
  bool _isLoading = false;
  bool _isLiveScorepadMode = true;

  int get _targetWins => _formatRounds >= 99 ? 999 : (_formatRounds ~/ 2) + 1;

  @override
  void initState() {
    super.initState();
    if (widget.match != null) {
      final m = widget.match!;
      final aId = m['athleteAId']?.toString();
      final aName = m['athleteAName']?.toString();
      final bId = m['athleteBId']?.toString();
      final bName = m['athleteBName']?.toString();

      if ((aId != null && aId.isNotEmpty) || (aName != null && aName.isNotEmpty)) {
        _challenger = {
          'id': aId ?? '',
          'displayName': (aName != null && aName.isNotEmpty) ? aName : 'Challenger (Red)',
        };
      }
      if ((bId != null && bId.isNotEmpty) || (bName != null && bName.isNotEmpty)) {
        _opponent = {
          'id': bId ?? '',
          'displayName': (bName != null && bName.isNotEmpty) ? bName : 'Opponent (White)',
        };
      }
      if (m['arm'] != null && m['arm'].toString().isNotEmpty) {
        _arm = m['arm'].toString().toUpperCase();
      }
    }
  }

  Future<void> _pickAthlete(bool forChallenger) async {
    HapticFeedback.lightImpact();
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AthleteSearchSheet(
        excludeId: (forChallenger ? _opponent : _challenger)?['id']?.toString(),
      ),
    );
    if (selected == null) return;
    setState(() {
      if (forChallenger) {
        _challenger = selected;
      } else {
        _opponent = selected;
      }
    });
  }

  Future<void> _submit() async {
    if (_isLoading) return;

    final challengerId = _challenger?['id']?.toString();
    final opponentId = _opponent?['id']?.toString();
    if (challengerId == null || opponentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        CrystalSnackBar(
          content: Text('Select both the challenger and the opponent.'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final winnerId = _winnerSide == 'challenger' ? challengerId : opponentId;

    setState(() => _isLoading = true);
    try {
      if (widget.match != null && widget.match!['id'] != null) {
        await ref.read(tournamentRepositoryProvider).submitTournamentResult(
              matchId: widget.match!['id'].toString(),
              winnerId: winnerId,
              scoreLine: _score,
            );
      } else {
        await ref.read(liveMatchesProvider.notifier).submitMatchOptimistic({
          'challengerId': challengerId,
          'opponentId': opponentId,
          'arm': _arm,
          'winnerId': winnerId,
          'scoreLine': _score,
        });
      }
      ref.invalidate(adminMatchesProvider);
      ref.invalidate(refereeProvider);
      ref.invalidate(liveMatchesProvider);
      ref.invalidate(tournamentProvider);
      ref.invalidate(athleteProfileProvider);
      ref.invalidate(publicAthleteProfileProvider(challengerId));
      ref.invalidate(publicAthleteProfileProvider(opponentId));
      ref.invalidate(athleteMatchesProvider(challengerId));
      ref.invalidate(athleteMatchesProvider(opponentId));
      ref.invalidate(rankingsProvider);
      ref.invalidate(notificationProvider);
      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          CrystalSnackBar(
            content: Text('Match result confirmed by server.'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).maybePop();
      }
    } on OfflineException catch (e) {
      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          CrystalSnackBar(
            content: Text('Result saved on this device and queued to sync when connection returns.'),
            backgroundColor: Color(0xFFF59E0B),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).maybePop();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CrystalSnackBar(
            content: Text(e.detail),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CrystalSnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleLiveMatchFinished({
    required int challengerScore,
    required int opponentScore,
    required String winnerSide,
    required String scoreLine,
  }) {
    HapticFeedback.heavyImpact();
    setState(() {
      _winnerSide = winnerSide;
      _score = scoreLine;
    });

    final winnerName = winnerSide == 'challenger'
        ? (_challenger?['displayName'] ?? 'Corner Red')
        : (_opponent?['displayName'] ?? 'Corner White');

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isDismissible: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CrystalModalSheet(
        title: 'MATCH CONCLUDED',
        subtitle: 'Official Bout Scorepad Verification',
        headerIcon: Icons.emoji_events_rounded,
        secondaryActionLabel: 'Review Score',
        onSecondaryAction: () => Navigator.of(ctx).pop(),
        primaryActionLabel: 'SUBMIT OFFICIAL RESULT',
        primaryActionIcon: Icons.verified_rounded,
        isPrimaryLoading: _isLoading,
        onPrimaryAction: _isLoading
            ? null
            : () {
                Navigator.of(ctx).pop();
                _submit();
              },
        child: Text(
          '$winnerName wins the bout with score line $scoreLine.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final challengerDisplayName = _challenger?['displayName']?.toString() ?? 'Corner Red (Select)';
    final opponentDisplayName = _opponent?['displayName']?.toString() ?? 'Corner White (Select)';

    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const CrystalBackButton(),
        titleSpacing: 8,
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Referee Table Scorepad',
            maxLines: 1,
          ),
        ),
        actions: [
          CrystalIconPillButton(
            tooltip: _isLiveScorepadMode ? 'Switch to Form View' : 'Switch to Table Scorepad',
            icon: _isLiveScorepadMode ? Icons.edit_note : Icons.sports,
            onPressed: () {
              setState(() => _isLiveScorepadMode = !_isLiveScorepadMode);
            },
          ),
          const CrystalHomeButton(),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: CrystalStageBackdrop(domain: ArmSphereStageDomain.referee),
          ),
          SafeArea(
            bottom: false,
            child: CrystalVaporDissolve(
              bottomMargin: 12.0,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.space16,
                  kToolbarHeight + 8,
                  AppTheme.space16,
                  120,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 155px open 3D Referee Control Console stage showcase spacer
                    const SizedBox(height: 155),
                    // Mode Toggle Bar with Competition Crimson (#E23B3B) active border and transparent interior
                    Container(
                      margin: const EdgeInsets.only(bottom: AppTheme.space16),
                      child: SegmentedButton<bool>(
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(Colors.transparent),
                          foregroundColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return Colors.white;
                            }
                            return const Color(0xFFCBD5E1);
                          }),
                          iconColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return const Color(0xFFD4AF37);
                            }
                            return const Color(0xFFCBD5E1);
                          }),
                          side: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return const BorderSide(color: Color(0x80E23B3B), width: 1.2);
                            }
                            return const BorderSide(color: Color(0x2EFFFFFF), width: 1.0);
                          }),
                        ),
                        segments: const [
                          ButtonSegment(
                            value: true,
                            label: Text('Table Scorepad'),
                            icon: Icon(Icons.touch_app, size: 16),
                          ),
                          ButtonSegment(
                            value: false,
                            label: Text('Quick Entry'),
                            icon: Icon(Icons.list_alt, size: 16),
                          ),
                        ],
                        selected: {_isLiveScorepadMode},
                        onSelectionChanged: (v) {
                          HapticFeedback.lightImpact();
                          setState(() => _isLiveScorepadMode = v.first);
                        },
                      ),
                    ),

                    if (_isLiveScorepadMode) ...[
                      // Live Scorepad View
                      if (_challenger == null || _opponent == null)
                        ElevatedActionCard(
                          watermark: ForgedWatermarkType.refereeStrap,
                          slashVariant: const CrystalSlashVariant.crossedCard(
                            watermark: ForgedWatermarkType.refereeStrap,
                          ),
                          padding: const EdgeInsets.all(AppTheme.space24),
                          child: Column(
                    children: [
                      // 100% transparent crystal wireframe icon badge bordered in 1px crimson with Gold icon
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0x80E23B3B),
                            width: 1.0,
                          ),
                        ),
                        child: const Icon(
                          Icons.sports,
                          size: 36,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                      const SizedBox(height: AppTheme.space16),
                      const Text(
                        'Select Table Competitors',
                        style: TextStyle(fontFamily: AppTheme.fontDisplay, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: AppTheme.space8),
                      const Text(
                        'Select athletes for Corner Red and Corner White to unlock the live interactive scorepad.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: AppTheme.space20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                side: const BorderSide(color: Color(0x66E23B3B)),
                              ),
                              onPressed: () => _pickAthlete(true),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _challenger?['displayName']?.toString() ?? '+ Red Corner',
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.space12),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                side: const BorderSide(color: Color(0x4DD4AF37)),
                              ),
                              onPressed: () => _pickAthlete(false),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _opponent?['displayName']?.toString() ?? '+ White Corner',
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space16),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'PRE-BOUT FORMAT & ARM CONFIGURATION',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final (int rounds, String label) in const [
                            (1, 'Best of 1'),
                            (3, 'Best of 3'),
                            (5, 'Best of 5'),
                            (7, 'Best of 7'),
                            (99, 'Supermatch Custom'),
                          ])
                            ChoiceChip(
                              label: Text(
                                label,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _formatRounds == rounds
                                      ? AppTheme.goldPrimary
                                      : AppTheme.textSecondary,
                                ),
                              ),
                              selected: _formatRounds == rounds,
                              selectedColor: const Color(0x26D4AF37),
                              backgroundColor: Colors.transparent,
                              side: BorderSide(
                                color: _formatRounds == rounds
                                    ? AppTheme.goldPrimary
                                    : const Color(0x38FFFFFF),
                              ),
                              onSelected: (_) {
                                HapticFeedback.selectionClick();
                                setState(() => _formatRounds = rounds);
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                )
              else
                LiveScorepadController(
                  challengerName: challengerDisplayName,
                  opponentName: opponentDisplayName,
                  arm: _arm,
                  maxPoints: _targetWins,
                  initialFormatRounds: _formatRounds,
                  onFormatChanged: (r) => setState(() => _formatRounds = r),
                  onMatchFinished: _handleLiveMatchFinished,
                ),
            ] else ...[
              // Standard Manual Result Form
              ElevatedActionCard(
                watermark: ForgedWatermarkType.refereeStrap,
                slashVariant: const CrystalSlashVariant.crossedCard(
                  watermark: ForgedWatermarkType.refereeStrap,
                ),
                padding: const EdgeInsets.all(AppTheme.space20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _athleteTile(label: 'Challenger (Winner A-side)', athlete: _challenger, onTap: () => _pickAthlete(true)),
                    const SizedBox(height: AppTheme.space12),
                    _athleteTile(label: 'Opponent', athlete: _opponent, onTap: () => _pickAthlete(false)),
                    const SizedBox(height: AppTheme.space20),
                    SegmentedButton<String>(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(Colors.transparent),
                        foregroundColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.white;
                          }
                          return const Color(0xFFCBD5E1);
                        }),
                        side: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return const BorderSide(color: Color(0x80E23B3B), width: 1.2);
                          }
                          return const BorderSide(color: Color(0x2EFFFFFF), width: 1.0);
                        }),
                      ),
                      segments: const [
                        ButtonSegment(value: 'RIGHT', label: Text('Right Arm')),
                        ButtonSegment(value: 'LEFT', label: Text('Left Arm')),
                      ],
                      selected: {_arm},
                      onSelectionChanged: (v) {
                        HapticFeedback.lightImpact();
                        setState(() => _arm = v.first);
                      },
                    ),
                    const SizedBox(height: AppTheme.space16),
                    SegmentedButton<String>(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(Colors.transparent),
                        foregroundColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.white;
                          }
                          return const Color(0xFFCBD5E1);
                        }),
                        side: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return const BorderSide(color: Color(0x80E23B3B), width: 1.2);
                          }
                          return const BorderSide(color: Color(0x2EFFFFFF), width: 1.0);
                        }),
                      ),
                      segments: [
                        ButtonSegment(value: 'challenger', label: Text(_challenger?['displayName']?.toString() ?? 'Challenger wins')),
                        ButtonSegment(value: 'opponent', label: Text(_opponent?['displayName']?.toString() ?? 'Opponent wins')),
                      ],
                      selected: {_winnerSide},
                      onSelectionChanged: (v) {
                        HapticFeedback.lightImpact();
                        setState(() => _winnerSide = v.first);
                      },
                    ),
                    const SizedBox(height: AppTheme.space16),
                    DropdownButtonFormField<String>(
                      initialValue: _score,
                      decoration: const InputDecoration(labelText: 'Outcome Score'),
                      items: [
                        for (final s in _kScoreOptions)
                          DropdownMenuItem(
                            value: s,
                            child: Text(
                              s,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontWeight: FontWeight.bold,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _score = val);
                      },
                    ),
                    const SizedBox(height: AppTheme.space24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading ? const CircularProgressIndicator() : const Text('SUBMIT OFFICIAL RESULT'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _athleteTile({required String label, required Map<String, dynamic>? athlete, required VoidCallback onTap}) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.person_search, color: AppTheme.textSecondary),
        ),
        child: Text(
          athlete?['displayName']?.toString() ?? 'Tap to search athletes',
          style: TextStyle(
            color: athlete == null ? AppTheme.textMuted : AppTheme.textPrimary,
            fontWeight: athlete != null ? FontWeight.w600 : FontWeight.normal,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// Bottom-sheet athlete picker backed by the real search endpoint.
class _AthleteSearchSheet extends ConsumerStatefulWidget {
  final String? excludeId;

  const _AthleteSearchSheet({this.excludeId});

  @override
  ConsumerState<_AthleteSearchSheet> createState() => _AthleteSearchSheetState();
}

class _AthleteSearchSheetState extends ConsumerState<_AthleteSearchSheet> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await ref.read(athleteRepositoryProvider).searchAthletes(query);
      setState(() => _results = list);
    } catch (e) {
      setState(() => _error = 'Search failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CrystalModalSheet(
      title: 'SELECT TABLE COMPETITOR',
      subtitle: 'Search Federation Athletes by Name',
      headerIcon: Icons.person_search_rounded,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.55,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              onTapOutside: (_) => CrystalModalSheet.unfocusActiveInput(context),
              decoration: CrystalModalSheet.inputDecoration(
                labelText: 'Search athletes by name',
                prefixIcon: Icons.search_rounded,
              ).copyWith(
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded, color: AppTheme.goldPrimary),
                  onPressed: () {
                    CrystalModalSheet.unfocusActiveInput(context);
                    _search();
                  },
                ),
              ),
              onSubmitted: (_) {
                CrystalModalSheet.unfocusActiveInput(context);
                _search();
              },
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, style: const TextStyle(color: AppTheme.error, fontSize: 12)),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.space8),
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppTheme.space8),
                        itemBuilder: (context, index) {
                          final item = _results[index];
                          final id = item['id']?.toString();
                          if (widget.excludeId != null && widget.excludeId == id) return const SizedBox.shrink();
                          return RepaintBoundary(
                            child: ElevatedActionCard(
                              slashVariant: CrystalSlashVariant.sequentialRow(index),
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.of(context).pop(item);
                              },
                              padding: const EdgeInsets.all(AppTheme.space12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0x80E23B3B),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Text(
                                      (item['displayName']?.toString() ?? 'A').substring(0, 1).toUpperCase(),
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryRed),
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.space12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['displayName']?.toString() ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        const SizedBox(height: AppTheme.space2),
                                        Text(
                                          [
                                            item['weightClass']?.toString(),
                                            item['province']?.toString(),
                                          ].where((p) => p != null && p.isNotEmpty).join(' • '),
                                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.add_circle_outline, color: AppTheme.primaryRed),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Athlete Search Screen for Officials
class AthleteSearchScreen extends ConsumerStatefulWidget {
  const AthleteSearchScreen({super.key});

  @override
  ConsumerState<AthleteSearchScreen> createState() => _AthleteSearchScreenState();
}

class _AthleteSearchScreenState extends ConsumerState<AthleteSearchScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final repo = ref.read(athleteRepositoryProvider);
      final list = await repo.searchAthletes(query);
      setState(() {
        _results = list;
      });
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const CrystalBackButton(),
        title: const Text('Search Athletes'),
        actions: const [CrystalHomeButton()],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: CrystalStageBackdrop(domain: ArmSphereStageDomain.referee),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.space16,
                kToolbarHeight + 8,
                AppTheme.space16,
                24,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 155),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Enter Ring / Real Name',
                      suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _search),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                  const SizedBox(height: AppTheme.space16),
                  if (_isLoading)
                    const Expanded(
                      child: CrystalScreenLoadingView(
                        itemCount: 4,
                        cardHeight: 74,
                        padding: EdgeInsets.zero,
                      ),
                    )
                  else
                    Expanded(
                      child: _results.isEmpty
                          ? Center(
                              child: Text(
                                _searchController.text.isEmpty
                                    ? 'Enter athlete name to verify roster eligibility.'
                                    : 'No matching athletes found.',
                                style: const TextStyle(color: AppTheme.textSecondary),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.only(bottom: 120),
                              itemCount: _results.length,
                              separatorBuilder: (_, __) => const SizedBox(height: AppTheme.space10),
                              itemBuilder: (context, index) {
                                final item = _results[index];
                                final weightClass = item['weightClass']?.toString();
                                final province = item['province']?.toString();
                                return RepaintBoundary(
                                  child: ElevatedActionCard(
                                    slashVariant: CrystalSlashVariant.sequentialRow(index),
                                    padding: const EdgeInsets.all(AppTheme.space14),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: Colors.transparent,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: const Color(0x80E23B3B),
                                              width: 1.0,
                                            ),
                                          ),
                                          child: Text(
                                            (item['displayName']?.toString() ?? 'A').substring(0, 1).toUpperCase(),
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryRed),
                                          ),
                                        ),
                                        const SizedBox(width: AppTheme.space14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['displayName'] ?? '',
                                                style: const TextStyle(
                                                  fontFamily: AppTheme.fontDisplay,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: AppTheme.space4),
                                              Text(
                                                [weightClass, province].where((p) => p != null && p.isNotEmpty).join(' • '),
                                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Evidence Upload Screen — the backend presign contract currently supports
/// AVATAR and DOCUMENT types only, so video evidence cannot be uploaded yet.
/// The screen says so instead of pretending.
class EvidenceUploadScreen extends StatelessWidget {
  const EvidenceUploadScreen({super.key});

  Future<void> _explainUnsupported(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          side: const BorderSide(color: AppTheme.cardBorder),
        ),
        title: const Text('Direct Evidence Protocol', style: TextStyle(fontFamily: AppTheme.fontDisplay)),
        content: const Text(
          'Video evidence upload requires federation high-bandwidth storage tiers that have '
          'not been enabled for this competition level yet. Document and scorepad evidence can be '
          'attached directly through official match dispute submissions.',
          style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const CrystalBackButton(),
        title: const Text('Evidence Upload'),
        actions: const [CrystalHomeButton()],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: CrystalStageBackdrop(domain: ArmSphereStageDomain.referee),
          ),
          SafeArea(
            bottom: false,
            child: CrystalVaporDissolve(
              bottomMargin: 12.0,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.space24,
                  kToolbarHeight + 8,
                  AppTheme.space24,
                  120,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 155),
                    ElevatedActionCard(
                      slashVariant: const CrystalSlashVariant.crossedCard(),
                      padding: const EdgeInsets.all(AppTheme.space28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 100% transparent crystal wireframe icon badge bordered in 1px crimson with Crimson icon
                          Container(
                            padding: const EdgeInsets.all(AppTheme.space16),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0x80E23B3B),
                                width: 1.0,
                              ),
                            ),
                            child: const Icon(
                              Icons.videocam_off_outlined,
                              size: 44,
                              color: Color(0xFFE23B3B),
                            ),
                          ),
                          const SizedBox(height: AppTheme.space20),
                          const Text(
                            'Video Evidence Upload',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppTheme.space8),
                          const Text(
                            'High-bandwidth match video ingest is currently restricted to federation head tables and broadcast feeds.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                          ),
                          const SizedBox(height: AppTheme.space24),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.info_outline, size: 18),
                            label: const Text('Storage Policy & Protocol'),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _explainUnsupported(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
