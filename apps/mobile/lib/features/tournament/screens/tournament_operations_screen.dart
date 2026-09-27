import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/providers/state_providers.dart';
import '../../../core/providers/tournament_provider.dart';
import 'tournament_screens.dart';

const List<String> _kDivisions = ['SENIOR', 'JUNIOR', 'FEMALE'];
const List<String> _kWeightClasses = ['-70kg', '-85kg', '-95kg', '+95kg'];
const List<String> _kScoreOptions = ['3-0', '3-1', '3-2', '2-3', '1-3', '0-3'];

StatusType _resolveOperationStatusType(String status) {
  switch (status.toUpperCase()) {
    case 'APPROVED':
    case 'PASSED':
    case 'COMPLETED':
      return StatusType.success;
    case 'PENDING':
    case 'READY':
    case 'SEEDED':
      return StatusType.warning;
    case 'CALLED':
    case 'ACTIVE':
      return StatusType.info;
    case 'WAITLISTED':
    case 'PENDING_PAYMENT':
      return StatusType.warning;
    case 'FAILED':
    case 'REJECTED':
      return StatusType.error;
    default:
      return StatusType.neutral;
  }
}

/// Live operator console for one event: registration approvals, manual
/// payment confirmation, weigh-ins and bracket production. Every action
/// calls the real backend and surfaces its errors verbatim.
class TournamentOperationsScreen extends ConsumerStatefulWidget {
  final String tournamentId;

  const TournamentOperationsScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<TournamentOperationsScreen> createState() => _TournamentOperationsScreenState();
}

class _TournamentOperationsScreenState extends ConsumerState<TournamentOperationsScreen> {
  bool _busy = false;

  Future<void> _run(String eventId, Future<Map<String, dynamic>> Function() action,
      {String? successMessage}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(tournamentProvider.notifier).runLifecycleAction(
            eventId: eventId,
            action: action,
          );
      if (mounted && successMessage != null) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.detail),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Action failed: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _weighInDialog(Map<String, dynamic> reg) async {
    HapticFeedback.selectionClick();
    final regId = reg['id']?.toString() ?? '';
    context.push('/tournament/${widget.tournamentId}/weigh-in?registrationId=$regId');
  }

  Future<void> _reassignDialog(Map<String, dynamic> reg) async {
    HapticFeedback.lightImpact();
    String division = reg['division']?.toString() ?? _kDivisions.first;
    String weightClass = reg['weightClass']?.toString() ?? _kWeightClasses.first;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            side: const BorderSide(color: AppTheme.cardBorder),
          ),
          title: Text(
            'Reassign — ${reg['athleteName'] ?? 'Athlete'}',
            style: const TextStyle(fontFamily: AppTheme.fontDisplay),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: division,
                items: [for (final d in _kDivisions) DropdownMenuItem(value: d, child: Text(d))],
                onChanged: (v) => setDialogState(() => division = v ?? division),
                decoration: const InputDecoration(labelText: 'Division'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: weightClass,
                items: [for (final w in _kWeightClasses) DropdownMenuItem(value: w, child: Text(w))],
                onChanged: (v) => setDialogState(() => weightClass = v ?? weightClass),
                decoration: const InputDecoration(labelText: 'Weight class'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Reassign')),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(
      widget.tournamentId,
      () => ref.read(tournamentRepositoryProvider).reassignRegistration(
            registrationId: reg['id'].toString(),
            newDivision: division,
            newWeightClass: weightClass,
          ),
      successMessage: 'Registration reassigned.',
    );
  }

  Future<void> _createBracketDialog(List<Map<String, dynamic>> registrations) async {
    HapticFeedback.lightImpact();
    final available = <String>{};
    for (final r in registrations) {
      if ((r['status']?.toString().toUpperCase()) == 'APPROVED') {
        available.add('${r['division']}|${r['weightClass']}|${r['arm']}');
      }
    }
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No approved registrations yet — approve entries first.'),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    String combo = available.first;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            side: const BorderSide(color: AppTheme.cardBorder),
          ),
          title: const Text('Create Official Bracket', style: TextStyle(fontFamily: AppTheme.fontDisplay)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: combo,
                isExpanded: true,
                items: [
                  for (final c in available)
                    DropdownMenuItem(
                      value: c,
                      child: Text(c.split('|').join(' • '), overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setDialogState(() => combo = v ?? combo),
                decoration: const InputDecoration(labelText: 'Division • Weight • Arm'),
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Format: Double Elimination Bracket Engine', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Create')),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    final p = combo.split('|');
    await _run(
      widget.tournamentId,
      () => ref.read(tournamentRepositoryProvider).createBracket(
            eventId: widget.tournamentId,
            name: '${p[0]} ${p[1]} ${p[2]}'.trim(),
            format: 'SINGLE_ELIMINATION',
            division: p[0],
            weightClass: p[1],
            arm: p[2],
          ),
      successMessage: 'Bracket created — generate seeds next.',
    );
  }

  Future<void> _createTableDialog() async {
    HapticFeedback.lightImpact();
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          side: const BorderSide(color: AppTheme.cardBorder),
        ),
        title: const Text('Add Official Match Table', style: TextStyle(fontFamily: AppTheme.fontDisplay)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Table Designation (e.g. Table 1, Table A)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Add Table')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final name = controller.text.trim();
    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Table name needs at least 2 characters.'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await _run(
      widget.tournamentId,
      () => ref.read(tournamentRepositoryProvider).createTable(name: name),
      successMessage: 'Official match table added.',
    );
  }

  Future<void> _assignRefereeDialog(Map<String, dynamic> match) async {
    HapticFeedback.lightImpact();
    List<Map<String, dynamic>> referees;
    try {
      referees = await ref.read(refereeDirectoryProvider.future);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load referee directory: $e'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!mounted) return;
    if (referees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No certified referees registered in the federation directory yet.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    String refereeId = match['refereeId']?.toString() ?? '';
    final validCurrent = referees.any((r) => r['id']?.toString() == refereeId);
    if (!validCurrent) refereeId = referees.first['id'].toString();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            side: const BorderSide(color: AppTheme.cardBorder),
          ),
          title: Text(
            'Assign Referee — R${match['round']} M${match['matchIndex']}',
            style: const TextStyle(fontFamily: AppTheme.fontDisplay),
          ),
          content: DropdownButtonFormField<String>(
            initialValue: refereeId,
            isExpanded: true,
            items: [
              for (final r in referees)
                DropdownMenuItem(
                  value: r['id'].toString(),
                  child: Text(r['fullName']?.toString() ?? r['email']?.toString() ?? 'Referee',
                      overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => setDialogState(() => refereeId = v ?? refereeId),
            decoration: const InputDecoration(labelText: 'Certified referee'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Assign')),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(
      widget.tournamentId,
      () => ref.read(tournamentRepositoryProvider).assignReferee(matchId: match['id'].toString(), refereeId: refereeId),
      successMessage: 'Referee assigned.',
    );
  }

  Future<void> _callToTableDialog(Map<String, dynamic> match) async {
    HapticFeedback.lightImpact();
    List<Map<String, dynamic>> tables;
    try {
      tables = await ref.read(matchTablesProvider.future);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load tables: $e'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final idle = tables.where((t) => (t['status']?.toString().toUpperCase()) == 'IDLE').toList();
    if (!mounted) return;
    if (idle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No idle tables available. Add a table or free one up first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    String tableId = idle.first['id'].toString();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            side: const BorderSide(color: AppTheme.cardBorder),
          ),
          title: Text(
            'Call to Table — R${match['round']} M${match['matchIndex']}',
            style: const TextStyle(fontFamily: AppTheme.fontDisplay),
          ),
          content: DropdownButtonFormField<String>(
            initialValue: tableId,
            isExpanded: true,
            items: [
              for (final t in idle)
                DropdownMenuItem(
                  value: t['id'].toString(),
                  child: Text(t['name']?.toString() ?? 'Table', overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => setDialogState(() => tableId = v ?? tableId),
            decoration: const InputDecoration(labelText: 'Idle table'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Call Match')),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(
      widget.tournamentId,
      () => ref.read(tournamentRepositoryProvider).callMatchToTable(matchId: match['id'].toString(), tableId: tableId),
      successMessage: 'Match called to table.',
    );
  }

  Future<void> _submitResultDialog(Map<String, dynamic> match) async {
    HapticFeedback.lightImpact();
    final athleteAId = match['athleteAId']?.toString() ?? '';
    final athleteBId = match['athleteBId']?.toString() ?? '';
    final nameA = match['athleteAName']?.toString() ?? 'Athlete A';
    final nameB = match['athleteBName']?.toString() ?? 'Athlete B';
    if (athleteAId.isEmpty || athleteBId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Both competitor slots must be filled before a result can be recorded.'),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    String winnerId = athleteAId;
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
          title: Text(
            'Record Result — R${match['round']} M${match['matchIndex']}',
            style: const TextStyle(fontFamily: AppTheme.fontDisplay),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: winnerId,
                isExpanded: true,
                items: [
                  DropdownMenuItem(value: athleteAId, child: Text(nameA, overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: athleteBId, child: Text(nameB, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setDialogState(() => winnerId = v ?? winnerId),
                decoration: const InputDecoration(labelText: 'Bout Winner'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: scoreLine,
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
                decoration: const InputDecoration(labelText: 'Score (winner perspective)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Submit')),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(
      widget.tournamentId,
      () => ref.read(tournamentRepositoryProvider).submitTournamentResult(
            matchId: match['id'].toString(),
            winnerId: winnerId,
            scoreLine: scoreLine,
          ),
      successMessage: 'Result recorded — bracket progression updated.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventDetailProvider(widget.tournamentId));
    final statsAsync = ref.watch(eventStatsProvider(widget.tournamentId));
    final regsAsync = ref.watch(eventRegistrationsProvider(widget.tournamentId));
    final bracketsAsync = ref.watch(eventBracketsProvider(widget.tournamentId));
    final tablesAsync = ref.watch(matchTablesProvider);
    final matchesAsync = ref.watch(eventMatchesProvider(widget.tournamentId));
    final refereesAsync = ref.watch(refereeDirectoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Event Operations Desk')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(eventStatsProvider(widget.tournamentId));
          ref.invalidate(eventRegistrationsProvider(widget.tournamentId));
          ref.invalidate(eventBracketsProvider(widget.tournamentId));
          ref.invalidate(matchTablesProvider);
          ref.invalidate(eventMatchesProvider(widget.tournamentId));
          ref.invalidate(refereeDirectoryProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.space16),
          children: [
            // --- Event header ---
            eventAsync.when(
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(AppTheme.space16),
                child: CircularProgressIndicator(),
              )),
              error: (e, _) => ElevatedActionCard(
                padding: const EdgeInsets.all(AppTheme.space16),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.error),
                    const SizedBox(width: AppTheme.space12),
                    Expanded(child: Text('Event unavailable: $e', style: const TextStyle(fontSize: 13))),
                  ],
                ),
              ),
              data: (event) {
                final status = (event['status']?.toString() ?? 'UNKNOWN').toUpperCase();
                return ElevatedActionCard(
                  padding: const EdgeInsets.all(AppTheme.space16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event['name']?.toString() ?? 'Event',
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppTheme.space4),
                            Text(
                              'Fee: ${formatEventFee(event['registrationFeeCents'])}'
                              ' • Payment: ${event['paymentMethod']?.toString() ?? 'N/A'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusChip(
                        label: status,
                        type: _resolveOperationStatusType(status),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppTheme.space14),

            // --- Stats ---
            statsAsync.maybeWhen(
              loading: () => const SizedBox(),
              orElse: () => const SizedBox(),
              data: (s) => ElevatedActionCard(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.space12, horizontal: AppTheme.space8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statCell('Total', s['totalRegistrations']),
                    _statCell('Pending', s['pending']),
                    _statCell('Approved', s['approved']),
                    _statCell('Waitlist', s['waitlisted']),
                    _statCell('Weighed ✓', s['passedWeighins']),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.space14),

            // --- Official Weigh-In Desk Quick Action (Canary 9) ---
            ElevatedActionCard(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space10),
                    decoration: BoxDecoration(
                      color: AppTheme.goldPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      border: Border.all(color: AppTheme.goldPrimary.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.scale_rounded, color: AppTheme.goldPrimary, size: 24),
                  ),
                  const SizedBox(width: AppTheme.space14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OFFICIAL WEIGH-IN DESK',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            color: AppTheme.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Calibrated digital scale, passport & rubber stamp clearance',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTheme.space8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldPrimary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      context.push('/tournament/${widget.tournamentId}/weigh-in');
                    },
                    child: const Text(
                      'OPEN DESK',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space12),

            // --- Awards & Podium Ceremony Console (Canary 10) ---
            ElevatedActionCard(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space10),
                    decoration: BoxDecoration(
                      color: AppTheme.goldPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      border: Border.all(color: AppTheme.goldPrimary.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.emoji_events_rounded, color: AppTheme.goldPrimary, size: 24),
                  ),
                  const SizedBox(width: AppTheme.space14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AWARDS & PODIUM CEREMONY',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            color: AppTheme.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'T4 ceremony sequence, medal awards & social export',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTheme.space8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.elevatedSurface,
                      foregroundColor: AppTheme.goldPrimary,
                      side: const BorderSide(color: AppTheme.goldPrimary),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      context.push('/tournament/${widget.tournamentId}/awards');
                    },
                    child: const Text(
                      'CEREMONY',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space20),

            // --- Registrations ---
            Text(
              'REGISTRATIONS',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: AppTheme.space10),
            regsAsync.when(
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(AppTheme.space16),
                child: CircularProgressIndicator(),
              )),
              error: (e, _) => ElevatedActionCard(
                padding: const EdgeInsets.all(AppTheme.space16),
                child: Text('Could not load registrations: $e', style: const TextStyle(color: AppTheme.error)),
              ),
              data: (regs) {
                if (regs.isEmpty) {
                  return const ElevatedActionCard(
                    padding: EdgeInsets.all(AppTheme.space20),
                    child: Center(
                      child: Text('No registrations registered for this competition yet.', style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                  );
                }
                return Column(
                  children: [for (final reg in regs) RepaintBoundary(child: _registrationCard(reg))],
                );
              },
            ),
            const SizedBox(height: AppTheme.space24),

            // --- Brackets ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'BRACKETS',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                      ),
                ),
                TextButton.icon(
                  onPressed: _busy || regsAsync.value == null
                      ? null
                      : () => _createBracketDialog(regsAsync.value!),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create Bracket'),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space10),
            bracketsAsync.when(
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(AppTheme.space16),
                child: CircularProgressIndicator(),
              )),
              error: (e, _) => ElevatedActionCard(
                padding: const EdgeInsets.all(AppTheme.space16),
                child: Text('Could not load brackets: $e', style: const TextStyle(color: AppTheme.error)),
              ),
              data: (brackets) {
                if (brackets.isEmpty) {
                  return const ElevatedActionCard(
                    padding: EdgeInsets.all(AppTheme.space20),
                    child: Center(
                      child: Text('No brackets generated yet. Create one from approved registrations.', style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                  );
                }
                return Column(children: [for (final b in brackets) RepaintBoundary(child: _bracketCard(b))]);
              },
            ),
            const SizedBox(height: AppTheme.space24),

            // --- Match-day tables ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'MATCH TABLES',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                      ),
                ),
                TextButton.icon(
                  onPressed: _busy ? null : _createTableDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Table'),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space10),
            tablesAsync.when(
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(AppTheme.space16),
                child: CircularProgressIndicator(),
              )),
              error: (e, _) => ElevatedActionCard(
                padding: const EdgeInsets.all(AppTheme.space16),
                child: Text('Could not load tables: $e', style: const TextStyle(color: AppTheme.error)),
              ),
              data: (tables) {
                if (tables.isEmpty) {
                  return const ElevatedActionCard(
                    padding: EdgeInsets.all(AppTheme.space20),
                    child: Center(
                      child: Text('No tables registered yet. Add one to start calling matches.', style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                  );
                }
                return Column(children: [for (final t in tables) RepaintBoundary(child: _tableTile(t))]);
              },
            ),
            const SizedBox(height: AppTheme.space24),

            // --- Match-day board ---
            Text(
              'MATCH-DAY BOARD',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: AppTheme.space10),
            matchesAsync.when(
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(AppTheme.space16),
                child: CircularProgressIndicator(),
              )),
              error: (e, _) => ElevatedActionCard(
                padding: const EdgeInsets.all(AppTheme.space16),
                child: Row(
                  children: [
                    Expanded(child: Text('Could not load matches: $e', style: const TextStyle(color: AppTheme.error))),
                    TextButton(
                      onPressed: () => ref.invalidate(eventMatchesProvider(widget.tournamentId)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (matches) {
                if (matches.isEmpty) {
                  return const ElevatedActionCard(
                    padding: EdgeInsets.all(AppTheme.space20),
                    child: Center(
                      child: Text('No matches generated yet. Generate matches from a locked bracket above.', style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                  );
                }
                return Column(children: [
                  for (final m in matches)
                    RepaintBoundary(child: _matchDayCard(m, refereesAsync.value ?? const [])),
                ]);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCell(String label, dynamic value) {
    return Column(
      children: [
        Text(
          '${(value as num?)?.toInt() ?? 0}',
          style: const TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: AppTheme.textPrimary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _registrationCard(Map<String, dynamic> reg) {
    final status = (reg['status']?.toString() ?? '').toUpperCase();
    final paid = reg['paymentConfirmedByOrganizer'] == true;
    final category =
        '${reg['division'] ?? ''} • ${reg['weightClass'] ?? ''} • ${reg['arm'] ?? ''}';
    final regId = reg['id']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space10),
      child: ElevatedActionCard(
        padding: const EdgeInsets.all(AppTheme.space14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    reg['athleteName']?.toString() ?? 'Athlete',
                    style: const TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                StatusChip(
                  label: status.isEmpty ? 'UNKNOWN' : status,
                  type: _resolveOperationStatusType(status),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$category${paid ? '  •  payment confirmed' : ''}',
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (status == 'PENDING_PAYMENT')
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _run(widget.tournamentId,
                            () => ref.read(tournamentRepositoryProvider).confirmManualPayment(registrationId: regId),
                            successMessage: 'Payment confirmed.'),
                    child: const Text('Confirm Payment'),
                  ),
                if (status == 'PENDING')
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _run(widget.tournamentId,
                            () => ref.read(tournamentRepositoryProvider).approveRegistration(registrationId: regId),
                            successMessage: 'Registration approved.'),
                    child: const Text('Approve'),
                  ),
                if (status == 'APPROVED' || status == 'WAITLISTED') ...[
                  OutlinedButton(
                    onPressed: _busy ? null : () => _weighInDialog(reg),
                    child: const Text('Weigh-In'),
                  ),
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _run(widget.tournamentId,
                            () => ref.read(tournamentRepositoryProvider).certifyWeighIn(registrationId: regId),
                            successMessage: 'Weigh-in certified & locked.'),
                    child: const Text('Certify'),
                  ),
                  OutlinedButton(
                    onPressed: _busy ? null : () => _reassignDialog(reg),
                    child: const Text('Reassign'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bracketCard(Map<String, dynamic> b) {
    final status = (b['status']?.toString() ?? 'DRAFT').toUpperCase();
    final locked = b['seedingLocked'] == true;
    final bracketId = b['id']?.toString() ?? '';
    final category = '${b['division'] ?? ''} • ${b['weightClass'] ?? ''} • ${b['arm'] ?? ''}';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space10),
      child: ElevatedActionCard(
        padding: const EdgeInsets.all(AppTheme.space14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    b['name']?.toString() ?? 'Bracket',
                    style: const TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                StatusChip(
                  label: status,
                  type: _resolveOperationStatusType(status),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(category, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!locked && status != 'ACTIVE' && status != 'COMPLETED')
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _run(
                              widget.tournamentId,
                              () async {
                                final seeds = await ref
                                    .read(tournamentRepositoryProvider)
                                    .generateSeeds(bracketId: bracketId);
                                return {'seeded': seeds.length};
                              },
                              successMessage: 'Seeds generated.',
                            ),
                    child: const Text('Generate Seeds'),
                  ),
                if (status == 'SEEDED' && !locked)
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _run(widget.tournamentId,
                            () => ref.read(tournamentRepositoryProvider).lockSeeds(bracketId: bracketId),
                            successMessage: 'Seeds locked.'),
                    child: const Text('Lock Seeds'),
                  ),
                if (status == 'SEEDED' && locked)
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _run(widget.tournamentId,
                            () => ref.read(tournamentRepositoryProvider).generateBracketMatches(bracketId: bracketId),
                            successMessage: 'Matches generated.'),
                    child: const Text('Generate Matches'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableTile(Map<String, dynamic> t) {
    final status = (t['status']?.toString() ?? 'IDLE').toUpperCase();
    final isBusy = status == 'ACTIVE';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space8),
      child: ElevatedActionCard(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space8, horizontal: AppTheme.space12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space8),
              decoration: BoxDecoration(
                color: (isBusy ? AppTheme.warning : AppTheme.success).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Icon(
                isBusy ? Icons.sports : Icons.table_restaurant,
                color: isBusy ? AppTheme.warning : AppTheme.success,
                size: 20,
              ),
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t['name']?.toString() ?? 'Table',
                    style: const TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (isBusy)
                    const Text('Bout in progress', style: TextStyle(fontSize: 11, color: AppTheme.warning)),
                ],
              ),
            ),
            StatusChip(
              label: status,
              type: isBusy ? StatusType.warning : StatusType.success,
            ),
          ],
        ),
      ),
    );
  }

  Widget _matchDayCard(Map<String, dynamic> m, List<Map<String, dynamic>> referees) {
    final status = (m['status']?.toString() ?? '').toUpperCase();
    final isBye = status == 'BYE';
    final completed = status == 'COMPLETED';
    final nameA = m['athleteAName']?.toString() ?? 'TBD';
    final nameB = m['athleteBName']?.toString() ?? 'TBD';
    final category =
        '${m['division'] ?? ''} • ${m['weightClass'] ?? ''} • ${m['arm'] ?? ''}';
    final refereeId = m['refereeId']?.toString();
    final refereeName = refereeId == null || refereeId.isEmpty
        ? null
        : referees
            .where((r) => r['id']?.toString() == refereeId)
            .map((r) => r['fullName']?.toString() ?? r['email']?.toString() ?? 'Referee')
            .firstOrNull;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space10),
      child: ElevatedActionCard(
        padding: const EdgeInsets.all(AppTheme.space14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        'R${m['round']} • M${m['matchIndex']}  ',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppTheme.goldPrimary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      Flexible(
                        child: Text(
                          m['bracketName'] ?? 'Bracket',
                          style: const TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusChip(
                  label: status.isEmpty ? 'UNKNOWN' : status,
                  type: _resolveOperationStatusType(status),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(category, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            Text(
              isBye ? '$nameA — BYE (advances)' : '$nameA  vs  $nameB',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            if (completed && m['scoreLine'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Final score: ${m['scoreLine']}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.success,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            if (refereeName != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Referee: $refereeName',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ),
            if (!isBye && !completed) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: _busy ? null : () => _assignRefereeDialog(m),
                    child: Text(refereeName == null ? 'Assign Referee' : 'Change Referee'),
                  ),
                  if (status == 'READY')
                    OutlinedButton(
                      onPressed: _busy ? null : () => _callToTableDialog(m),
                      child: const Text('Call to Table'),
                    ),
                  OutlinedButton(
                    onPressed: _busy ? null : () => _submitResultDialog(m),
                    child: const Text('Record Result'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
