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
import '../../../core/providers/referee_provider.dart';
import '../../../core/providers/live_matches_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../widgets/live_scorepad_controller.dart';

const List<String> _kScoreOptions = ['3-0', '3-1', '3-2', '2-3', '1-3', '0-3'];

StatusType _resolveMatchStatusType(String status) {
  switch (status.toUpperCase()) {
    case 'COMPLETED':
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

/// Referee Dashboard — real assignments pulled from the event match board.
/// The referee picks an event, sees every match assigned to them and drives
/// the official flow: call to table, then submit the result.
class RefereeDashboardScreen extends ConsumerStatefulWidget {
  const RefereeDashboardScreen({super.key});

  @override
  ConsumerState<RefereeDashboardScreen> createState() => _RefereeDashboardScreenState();
}

class _RefereeDashboardScreenState extends ConsumerState<RefereeDashboardScreen> {
  String? _selectedEventId;
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, {String? successMessage}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted && successMessage != null) {
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
        const SnackBar(
          content: Text('No tables exist yet — ask the organizer to add tables first.'),
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
          const SnackBar(
            content: Text('Both athletes must be determined before a result can be submitted.'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);
    final myUserId = auth.userProfile?['id']?.toString();
    final eventsAsync = ref.watch(tournamentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Referee Panel'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'OFFICIAL ACTIONS',
              style: theme.textTheme.labelMedium?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.space12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppTheme.space12,
              crossAxisSpacing: AppTheme.space12,
              childAspectRatio: 1.45,
              children: [
                _RefCard(
                  icon: Icons.assignment_outlined,
                  label: 'Submit Scorepad',
                  onTap: () => context.push('/referee/submit-scorepad'),
                ),
                _RefCard(
                  icon: Icons.verified_outlined,
                  label: 'Certifications',
                  onTap: () => context.push('/referee/certifications'),
                ),
                _RefCard(
                  icon: Icons.search,
                  label: 'Search Athletes',
                  onTap: () => context.push('/referee/search-athletes'),
                ),
                _RefCard(
                  icon: Icons.cloud_upload_outlined,
                  label: 'Upload Evidence',
                  onTap: () => context.push('/referee/upload-evidence'),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space24),

            Text(
              'MY ASSIGNMENTS',
              style: theme.textTheme.labelMedium?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.space12),
            eventsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.space24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => ElevatedActionCard(
                padding: const EdgeInsets.all(AppTheme.space16),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.error, size: 24),
                    const SizedBox(width: AppTheme.space12),
                    Expanded(
                      child: Text(
                        'Could not load events: $e',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
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
        ),
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
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppTheme.space16),
          child: CircularProgressIndicator(),
        ),
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

    return ElevatedActionCard(
      padding: const EdgeInsets.all(AppTheme.space16),
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
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12, vertical: AppTheme.space14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space10),
            decoration: BoxDecoration(
              color: AppTheme.primaryRed.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: AppTheme.primaryRed.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Icon(icon, size: 24, color: AppTheme.primaryRed),
          ),
          const SizedBox(height: AppTheme.space10),
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
      appBar: AppBar(title: const Text('Certifications')),
      body: certsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space24),
            child: ElevatedActionCard(
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.space32),
                child: ElevatedActionCard(
                  padding: const EdgeInsets.all(AppTheme.space24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium_outlined, size: 48, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
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
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppTheme.space16),
            itemCount: certs.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppTheme.space12),
            itemBuilder: (context, index) {
              final c = certs[index];
              final status = c['status']?.toString() ?? 'UNKNOWN';
              final expires = c['expiresAt']?.toString();
              return RepaintBoundary(
                child: ElevatedActionCard(
                  padding: const EdgeInsets.all(AppTheme.space16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.space10),
                        decoration: BoxDecoration(
                          color: AppTheme.goldPrimary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          border: Border.all(
                            color: AppTheme.goldPrimary.withValues(alpha: 0.3),
                            width: 1,
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
  bool _isLoading = false;
  bool _isLiveScorepadMode = true;

  @override
  void initState() {
    super.initState();
    if (widget.match != null) {
      final m = widget.match!;
      final aId = m['athleteAId']?.toString();
      final aName = m['athleteAName']?.toString();
      final bId = m['athleteBId']?.toString();
      final bName = m['athleteBName']?.toString();

      if (aId != null || aName != null) {
        _challenger = {
          'id': aId ?? '',
          'displayName': aName ?? 'Challenger (Red)',
        };
      }
      if (bId != null || bName != null) {
        _opponent = {
          'id': bId ?? '',
          'displayName': bName ?? 'Opponent (White)',
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
      isScrollControlled: true,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
      ),
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
    final challengerId = _challenger?['id']?.toString();
    final opponentId = _opponent?['id']?.toString();
    if (challengerId == null || opponentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
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
      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Match submitted successfully!'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
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
      isDismissible: false,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events, color: AppTheme.goldPrimary, size: 28),
                const SizedBox(width: AppTheme.space8),
                Text(
                  'MATCH CONCLUDED',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.goldPrimary,
                    fontFamily: AppTheme.fontDisplay,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space12),
            Text(
              '$winnerName wins the bout with score line $scoreLine.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: AppTheme.space20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _submit();
              },
              child: const Text('SUBMIT OFFICIAL RESULT'),
            ),
            const SizedBox(height: AppTheme.space8),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('REVIEW / EDIT SCORE'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final challengerDisplayName = _challenger?['displayName']?.toString() ?? 'Corner Red (Select)';
    final opponentDisplayName = _opponent?['displayName']?.toString() ?? 'Corner White (Select)';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Referee Table Scorepad'),
        actions: [
          IconButton(
            tooltip: _isLiveScorepadMode ? 'Switch to Form View' : 'Switch to Table Scorepad',
            icon: Icon(_isLiveScorepadMode ? Icons.edit_note : Icons.sports),
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() => _isLiveScorepadMode = !_isLiveScorepadMode);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mode Toggle Bar
            Container(
              margin: const EdgeInsets.only(bottom: AppTheme.space16),
              child: SegmentedButton<bool>(
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
                  padding: const EdgeInsets.all(AppTheme.space24),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.space12),
                        decoration: BoxDecoration(
                          color: AppTheme.info.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.sports, size: 36, color: AppTheme.info),
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
                              onPressed: () => _pickAthlete(true),
                              child: Text(
                                _challenger?['displayName']?.toString() ?? '+ Red Corner',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.space12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _pickAthlete(false),
                              child: Text(
                                _opponent?['displayName']?.toString() ?? '+ White Corner',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
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
                  maxPoints: 3,
                  onMatchFinished: _handleLiveMatchFinished,
                ),
            ] else ...[
              // Standard Manual Result Form
              ElevatedActionCard(
                padding: const EdgeInsets.all(AppTheme.space20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _athleteTile(label: 'Challenger (Winner A-side)', athlete: _challenger, onTap: () => _pickAthlete(true)),
                    const SizedBox(height: AppTheme.space12),
                    _athleteTile(label: 'Opponent', athlete: _opponent, onTap: () => _pickAthlete(false)),
                    const SizedBox(height: AppTheme.space20),
                    SegmentedButton<String>(
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
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppTheme.space16),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Search athletes by name',
                    suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _search),
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
                  child: Text(_error!, style: const TextStyle(color: AppTheme.error, fontSize: 12)),
                ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space8),
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppTheme.space8),
                        itemBuilder: (context, index) {
                          final item = _results[index];
                          final id = item['id']?.toString();
                          if (widget.excludeId != null && widget.excludeId == id) return const SizedBox.shrink();
                          return RepaintBoundary(
                            child: ElevatedActionCard(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.of(context).pop(item);
                              },
                              padding: const EdgeInsets.all(AppTheme.space12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppTheme.primaryRed.withValues(alpha: 0.15),
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
      appBar: AppBar(title: const Text('Search Athletes')),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          children: [
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
              const Expanded(child: Center(child: CircularProgressIndicator()))
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
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppTheme.space10),
                        itemBuilder: (context, index) {
                          final item = _results[index];
                          final weightClass = item['weightClass']?.toString();
                          final province = item['province']?.toString();
                          return RepaintBoundary(
                            child: ElevatedActionCard(
                              padding: const EdgeInsets.all(AppTheme.space14),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppTheme.primaryRed.withValues(alpha: 0.15),
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
      appBar: AppBar(title: const Text('Evidence Upload')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space24),
          child: ElevatedActionCard(
            padding: const EdgeInsets.all(AppTheme.space28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.space16),
                  decoration: BoxDecoration(
                    color: AppTheme.info.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.videocam_off_outlined, size: 48, color: AppTheme.info),
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
        ),
      ),
    );
  }
}
