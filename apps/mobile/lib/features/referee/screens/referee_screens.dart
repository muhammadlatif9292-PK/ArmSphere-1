import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/providers/state_providers.dart';
import '../../../core/providers/tournament_provider.dart';
import '../../../core/providers/referee_provider.dart';
import '../../../core/providers/live_matches_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../widgets/live_scorepad_controller.dart';

const List<String> _kScoreOptions = ['3-0', '3-1', '3-2', '2-3', '1-3', '0-3'];

Color _matchStatusColor(String status) {
  switch (status.toUpperCase()) {
    case 'COMPLETED':
      return AppTheme.success;
    case 'CALLED':
      return AppTheme.info;
    case 'READY':
      return AppTheme.secondaryAccent;
    case 'BYE':
      return AppTheme.textMuted;
    default:
      return AppTheme.textMuted;
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
        const SnackBar(content: Text('No tables exist yet — ask the organizer to add tables first.')),
      );
      return;
    }
    String? tableId = tables.first['id']?.toString();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Call to Table'),
          content: DropdownButtonFormField<String>(
            initialValue: tableId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Table'),
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
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Call Match')),
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
    }, successMessage: 'Match called to table.');
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
          title: const Text('Submit Official Result'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioGroup<String>(
                groupValue: winnerSide,
                onChanged: (v) => setDialogState(() => winnerSide = v ?? 'A'),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      value: 'A',
                      title: Text(aName, overflow: TextOverflow.ellipsis),
                    ),
                    RadioListTile<String>(
                      value: 'B',
                      title: Text(bName, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: scoreLine,
                decoration: const InputDecoration(labelText: 'Score line (wins-pulls format)'),
                items: [
                  for (final s in _kScoreOptions) DropdownMenuItem(value: s, child: Text(s)),
                ],
                onChanged: (v) => setDialogState(() => scoreLine = v ?? scoreLine),
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
    if (confirmed != true) return;
    final winnerId = (winnerSide == 'A' ? match['athleteAId'] : match['athleteBId'])?.toString();
    if (winnerId == null || winnerId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Both athletes must be determined before a result can be submitted.')),
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
    }, successMessage: 'Result recorded.');
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
            icon: const Icon(Icons.logout),
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'OFFICIAL ACTIONS',
              style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 1.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
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
            const SizedBox(height: 24),

            Text(
              'MY ASSIGNMENTS',
              style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 1.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            eventsAsync.when(
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )),
              error: (e, _) => GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(child: Text('Could not load events: $e', style: const TextStyle(fontSize: 13))),
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
                  return const GlassCard(
                    padding: EdgeInsets.all(16),
                    child: Text('No published events available yet.'),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedEventId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Event'),
                      items: [
                        for (final e in selectable)
                          DropdownMenuItem(
                            value: e['id']?.toString(),
                            child: Text(e['name']?.toString() ?? 'Event', overflow: TextOverflow.ellipsis),
                          ),
                      ],
                      onChanged: (v) => setState(() => _selectedEventId = v),
                    ),
                    const SizedBox(height: 12),
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
      loading: () => const Center(child: Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      )),
      error: (e, _) => GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: Text('Could not load matches: $e', style: const TextStyle(fontSize: 13))),
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
          return const GlassCard(
            padding: EdgeInsets.all(16),
            child: Text('No matches assigned to you in this event yet.'),
          );
        }
        return Column(
          children: [
            for (final m in mine) ...[
              _AssignmentCard(match: m, busy: busy, onCall: onCall, onResult: onResult),
              const SizedBox(height: 10),
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

  const _AssignmentCard({required this.match, required this.busy, required this.onCall, required this.onResult});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = (match['status']?.toString() ?? '').toUpperCase();
    final aName = match['athleteAName']?.toString() ?? 'TBD';
    final bName = match['athleteBName']?.toString() ?? 'TBD';
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
              StatusChip(
                label: status,
                type: status == 'COMPLETED'
                    ? StatusType.success
                    : (status == 'CALLED'
                        ? StatusType.info
                        : (status == 'READY' ? StatusType.warning : StatusType.neutral)),
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
            Text(
              'Final Score: ${match['scoreLine']}',
              style: const TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppTheme.success,
              ),
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
                      onPressed: busy ? null : () => onResult(match),
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
                onPressed: busy ? null : () => onCall(match),
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
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Referee Certifications — real records from GET /referees/:userId/certifications.
class RefereeCertificationsScreen extends ConsumerWidget {
  const RefereeCertificationsScreen({super.key});

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return Colors.green;
      case 'REVOKED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final certsAsync = ref.watch(refereeCertificationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Certifications')),
      body: certsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Could not load certifications', style: theme.textTheme.titleSmall),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(refereeCertificationsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (certs) {
          if (certs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.workspace_premium_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text(
                      'No certifications on file.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Certifications are issued by federation administrators.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: certs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final c = certs[index];
              final status = c['status']?.toString() ?? 'UNKNOWN';
              final expires = c['expiresAt']?.toString();
              return GlassCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c['certificationLevel']?.toString() ?? 'Certification',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(c['issuingBody']?.toString() ?? '',
                              style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 8),
                          Text(
                            expires == null || expires.isEmpty || expires == 'null'
                                ? 'No expiry'
                                : 'Expires ${expires.split('T').first}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(fontWeight: FontWeight.bold, color: _statusColor(status), fontSize: 12),
                      ),
                    ),
                  ],
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
        const SnackBar(content: Text('Select both the challenger and the opponent.'), backgroundColor: AppTheme.error),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match submitted successfully!'), backgroundColor: AppTheme.success),
        );
        context.pop();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.detail), backgroundColor: AppTheme.error),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
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
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.goldPrimary),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space12),
            Text(
              '$winnerName wins the bout with score line $scoreLine.',
              style: Theme.of(context).textTheme.bodyLarge,
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
            onPressed: () => setState(() => _isLiveScorepadMode = !_isLiveScorepadMode),
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
                onSelectionChanged: (v) => setState(() => _isLiveScorepadMode = v.first),
              ),
            ),

            if (_isLiveScorepadMode) ...[
              // Live Scorepad View
              if (_challenger == null || _opponent == null)
                ElevatedActionCard(
                  child: Column(
                    children: [
                      const Icon(Icons.sports, size: 40, color: AppTheme.info),
                      const SizedBox(height: AppTheme.space12),
                      const Text(
                        'Select Table Competitors',
                        style: TextStyle(fontFamily: AppTheme.fontDisplay, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: AppTheme.space8),
                      const Text(
                        'Select athletes for Corner Red and Corner White to unlock the live scorepad.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: AppTheme.space16),
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
                          const SizedBox(width: AppTheme.space8),
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
                      onSelectionChanged: (v) => setState(() => _arm = v.first),
                    ),
                    const SizedBox(height: AppTheme.space16),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(value: 'challenger', label: Text(_challenger?['displayName']?.toString() ?? 'Challenger wins')),
                        ButtonSegment(value: 'opponent', label: Text(_opponent?['displayName']?.toString() ?? 'Opponent wins')),
                      ],
                      selected: {_winnerSide},
                      onSelectionChanged: (v) => setState(() => _winnerSide = v.first),
                    ),
                    const SizedBox(height: AppTheme.space16),
                    DropdownButtonFormField<String>(
                      initialValue: _score,
                      decoration: const InputDecoration(labelText: 'Outcome Score'),
                      items: [
                        for (final s in _kScoreOptions) DropdownMenuItem(value: s, child: Text(s)),
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
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        child: Text(
          athlete?['displayName']?.toString() ?? 'Tap to search athletes',
          style: TextStyle(color: athlete == null ? AppTheme.textMuted : null),
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
                padding: const EdgeInsets.all(16),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final item = _results[index];
                          final id = item['id']?.toString();
                          if (widget.excludeId != null && widget.excludeId == id) return const SizedBox.shrink();
                          return ListTile(
                            title: Text(item['displayName']?.toString() ?? ''),
                            subtitle: Text([
                              item['weightClass']?.toString(),
                              item['province']?.toString(),
                            ].where((p) => p != null && p.isNotEmpty).join(' • ')),
                            trailing: const Icon(Icons.check_circle_outline),
                            onTap: () => Navigator.of(context).pop(item),
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
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Athletes')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : Expanded(
                    child: ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final item = _results[index];
                        return Card(
                          child: ListTile(
                            title: Text(item['displayName'] ?? ''),
                            subtitle: Text(item['weightClass'] ?? ''),
                            trailing: const Icon(Icons.chevron_right),
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
        title: const Text('Not available yet'),
        content: const Text(
          'Video evidence upload requires federation storage support that has '
          'not been enabled for this competition yet. Document evidence can be '
          'attached through dispute submissions.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Understood')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evidence Upload')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('Video Evidence Upload', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text(
              'Not enabled for this competition yet',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              icon: const Icon(Icons.info_outline),
              label: const Text('Why?'),
              onPressed: () => _explainUnsupported(context),
            ),
          ],
        ),
      ),
    );
  }
}
