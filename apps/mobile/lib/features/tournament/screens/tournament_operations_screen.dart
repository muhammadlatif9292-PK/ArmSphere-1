import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/providers/tournament_provider.dart';
import 'tournament_screens.dart';

const List<String> _kDivisions = ['SENIOR', 'JUNIOR', 'FEMALE'];
const List<String> _kWeightClasses = ['-70kg', '-85kg', '-95kg', '+95kg'];
const List<String> _kArms = ['RIGHT', 'LEFT', 'BOTH'];

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
        return Colors.amber.sh700;
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
    final parts = combo.split('|');
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

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventDetailProvider(widget.tournamentId));
    final statsAsync = ref.watch(eventStatsProvider(widget.tournamentId));
    final regsAsync = ref.watch(eventRegistrationsProvider(widget.tournamentId));
    final bracketsAsync = ref.watch(eventBracketsProvider(widget.tournamentId));

    return Scaffold(
      appBar: AppBar(title: const Text('Event Operations')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(eventStatsProvider(widget.tournamentId));
          ref.invalidate(eventRegistrationsProvider(widget.tournamentId));
          ref.invalidate(eventBracketsProvider(widget.tournamentId));
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
}
