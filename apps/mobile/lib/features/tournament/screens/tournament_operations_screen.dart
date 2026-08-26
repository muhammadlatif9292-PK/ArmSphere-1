import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/providers/state_providers.dart';
import '../../../core/providers/tournament_provider.dart';
import 'tournament_screens.dart';

const List<String> _kDivisions = ['SENIOR', 'JUNIOR', 'FEMALE'];
const List<String> _kWeightClasses = ['-70kg', '-85kg', '-95kg', '+95kg'];
const List<String> _kScoreOptions = ['3-0', '3-1', '3-2', '2-3', '1-3', '0-3'];

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage), backgroundColor: Colors.green),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.detail), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
      case 'PASSED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'PENDING_PAYMENT':
        return Colors.amber.shade700;
      case 'WAITLISTED':
        return Colors.purple;
      case 'FAILED':
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  Future<void> _weighInDialog(Map<String, dynamic> reg) async {
    final controller = TextEditingController();
    final limitHint = reg['weightClass']?.toString() ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Weigh-in — ${reg['athleteName'] ?? 'Athlete'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Category limit: $limitHint', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Measured weight (kg)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Record')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final weight = double.tryParse(controller.text.trim());
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid weight in kilograms.'), backgroundColor: Colors.red),
      );
      return;
    }
    await _run(
      widget.tournamentId,
      () => ref.read(tournamentRepositoryProvider).recordWeighIn(
            registrationId: reg['id'].toString(),
            weightKg: weight,
          ),
      successMessage: 'Weigh-in recorded.',
    );
  }

  Future<void> _reassignDialog(Map<String, dynamic> reg) async {
    String division = reg['division']?.toString() ?? _kDivisions.first;
    String weightClass = reg['weightClass']?.toString() ?? _kWeightClasses.first;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Reassign — ${reg['athleteName'] ?? 'Athlete'}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: division,
                items: [for (final d in _kDivisions) DropdownMenuItem(value: d, child: Text(d))],
                onChanged: (v) => setDialogState(() => division = v ?? division),
                decoration: const InputDecoration(labelText: 'Division'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: weightClass,
                items: [for (final w in _kWeightClasses) DropdownMenuItem(value: w, child: Text(w))],
                onChanged: (v) => setDialogState(() => weightClass = v ?? weightClass),
                decoration: const InputDecoration(labelText: 'Weight class'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Reassign')),
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
    // Only categories that actually have APPROVED athletes are offered.
    final available = <String>{};
    for (final r in registrations) {
      if ((r['status']?.toString().toUpperCase()) == 'APPROVED') {
        available.add('${r['division']}|${r['weightClass']}|${r['arm']}');
      }
    }
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No approved registrations yet — approve entries first.')),
      );
      return;
    }
    String combo = available.first;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create Bracket'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: combo,
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
                child: Text('Format: Single Elimination', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Create')),
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
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Match Table'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Table name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Add')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final name = controller.text.trim();
    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Table name needs at least 2 characters.'), backgroundColor: Colors.red),
      );
      return;
    }
    await _run(
      widget.tournamentId,
      () => ref.read(tournamentRepositoryProvider).createTable(name: name),
      successMessage: 'Table added.',
    );
  }

  Future<void> _assignRefereeDialog(Map<String, dynamic> match) async {
    List<Map<String, dynamic>> referees;
    try {
      referees = await ref.read(refereeDirectoryProvider.future);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load referee directory: $e'), backgroundColor: Colors.red),
      );
      return;
    }
    if (!mounted) return;
    if (referees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No certified referees registered in the federation directory yet.')),
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
          title: Text('Assign Referee — R${match['round']} M${match['matchIndex']}'),
          content: DropdownButtonFormField<String>(
            value: refereeId,
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
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Assign')),
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
    List<Map<String, dynamic>> tables;
    try {
      tables = await ref.read(matchTablesProvider.future);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load tables: $e'), backgroundColor: Colors.red),
      );
      return;
    }
    final idle = tables.where((t) => (t['status']?.toString().toUpperCase()) == 'IDLE').toList();
    if (!mounted) return;
    if (idle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No idle tables available. Add a table or free one up first.')),
      );
      return;
    }
    String tableId = idle.first['id'].toString();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Call to Table — R${match['round']} M${match['matchIndex']}'),
          content: DropdownButtonFormField<String>(
            value: tableId,
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
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Call')),
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
    final athleteAId = match['athleteAId']?.toString() ?? '';
    final athleteBId = match['athleteBId']?.toString() ?? '';
    final nameA = match['athleteAName']?.toString() ?? 'Athlete A';
    final nameB = match['athleteBName']?.toString() ?? 'Athlete B';
    if (athleteAId.isEmpty || athleteBId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Both slots must be filled before a result can be recorded.')),
      );
      return;
    }
    String winnerId = athleteAId;
    String scoreLine = _kScoreOptions.first;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Record Result — R${match['round']} M${match['matchIndex']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: winnerId,
                isExpanded: true,
                items: [
                  DropdownMenuItem(value: athleteAId, child: Text(nameA, overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: athleteBId, child: Text(nameB, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setDialogState(() => winnerId = v ?? winnerId),
                decoration: const InputDecoration(labelText: 'Winner'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: scoreLine,
                items: [for (final s in _kScoreOptions) DropdownMenuItem(value: s, child: Text(s))],
                onChanged: (v) => setDialogState(() => scoreLine = v ?? scoreLine),
                decoration: const InputDecoration(labelText: 'Score (winner perspective)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Submit')),
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
      appBar: AppBar(title: const Text('Event Operations')),
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
          padding: const EdgeInsets.all(20),
          children: [
            // --- Event header ---
            eventAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => GlassCard(
                child: ListTile(leading: const Icon(Icons.error_outline), title: Text('Event unavailable: $e')),
              ),
              data: (event) => GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event['name']?.toString() ?? 'Event',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(
                            'Fee: ${formatEventFee(event['registrationFeeCents'])}'
                            ' • Payment: ${event['paymentMethod']?.toString() ?? 'N/A'}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(event['status']?.toString() ?? 'UNKNOWN',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      backgroundColor: _statusColor(event['status']?.toString() ?? '').withOpacity(0.15),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- Stats ---
            statsAsync.maybeWhen(
              loading: () => const SizedBox(),
              orElse: () => const SizedBox(),
              data: (s) => GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
            const SizedBox(height: 24),

            // --- Registrations ---
            Text('REGISTRATIONS',
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(letterSpacing: 1.0, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            regsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => GlassCard(child: ListTile(title: Text('Could not load registrations: $e'))),
              data: (regs) {
                if (regs.isEmpty) {
                  return const GlassCard(child: ListTile(title: Text('No registrations yet.')));
                }
                return Column(
                  children: [for (final reg in regs) _registrationCard(reg)],
                );
              },
            ),
            const SizedBox(height: 24),

            // --- Brackets ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('BRACKETS',
                    style: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(letterSpacing: 1.0, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _busy || regsAsync.value == null
                      ? null
                      : () => _createBracketDialog(regsAsync.value!),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            bracketsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => GlassCard(child: ListTile(title: Text('Could not load brackets: $e'))),
              data: (brackets) {
                if (brackets.isEmpty) {
                  return const GlassCard(
                      child: ListTile(title: Text('No brackets yet. Create one from approved registrations.')));
                }
                return Column(children: [for (final b in brackets) _bracketCard(b)]);
              },
            ),
            const SizedBox(height: 24),

            // --- Match-day tables ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('MATCH TABLES',
                    style: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(letterSpacing: 1.0, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _busy ? null : _createTableDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            tablesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => GlassCard(child: ListTile(title: Text('Could not load tables: $e'))),
              data: (tables) {
                if (tables.isEmpty) {
                  return const GlassCard(child: ListTile(title: Text('No tables registered yet. Add one to start calling matches.')));
                }
                return Column(children: [for (final t in tables) _tableTile(t)]);
              },
            ),
            const SizedBox(height: 24),

            // --- Match-day board ---
            Text('MATCH-DAY BOARD',
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(letterSpacing: 1.0, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            matchesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => GlassCard(
                child: ListTile(
                  title: Text('Could not load matches: $e'),
                  trailing: TextButton(
                    onPressed: () => ref.invalidate(eventMatchesProvider(widget.tournamentId)),
                    child: const Text('Retry'),
                  ),
                ),
              ),
              data: (matches) {
                if (matches.isEmpty) {
                  return const GlassCard(
                      child: ListTile(title: Text('No matches generated yet. Generate matches from a locked bracket above.')));
                }
                return Column(children: [for (final m in matches) _matchDayCard(m, refereesAsync.value ?? const [])]);
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
        Text('${(value as num?)?.toInt() ?? 0}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(reg['athleteName']?.toString() ?? 'Athlete',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                Chip(
                  label: Text(status.isEmpty ? 'UNKNOWN' : status,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  backgroundColor: _statusColor(status).withOpacity(0.15),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('$category${paid ? '  •  payment confirmed' : ''}',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(b['name']?.toString() ?? 'Bracket',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                Chip(
                  label: Text(status, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  backgroundColor: _statusColor(status).withOpacity(0.15),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(category, style: const TextStyle(fontSize: 11, color: Colors.grey)),
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

  Color _matchStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return Colors.green;
      case 'CALLED':
        return Colors.blue;
      case 'READY':
        return Colors.orange;
      default:
        return Colors.blueGrey; // BYE and unknowns
    }
  }

  Widget _tableTile(Map<String, dynamic> t) {
    final status = (t['status']?.toString() ?? 'IDLE').toUpperCase();
    final busy = status == 'ACTIVE';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: ListTile(
          leading: Icon(busy ? Icons.sports : Icons.table_restaurant,
              color: busy ? Colors.orange : Colors.green, size: 22),
          title: Text(t['name']?.toString() ?? 'Table',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: busy ? const Text('Match in progress', style: TextStyle(fontSize: 11)) : null,
          trailing: Chip(
            label: Text(status,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            backgroundColor:
                (busy ? Colors.orange : Colors.green).withOpacity(0.15),
          ),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'R${m['round']} • M${m['matchIndex']} — ${m['bracketName'] ?? 'Bracket'}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Chip(
                  label: Text(status.isEmpty ? 'UNKNOWN' : status,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  backgroundColor: _matchStatusColor(status).withOpacity(0.15),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(category, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(isBye ? '$nameA — BYE (advances)' : '$nameA  vs  $nameB',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            if (completed && m['scoreLine'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Final score: ${m['scoreLine']}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ),
            if (refereeName != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('Referee: $refereeName',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
