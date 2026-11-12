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
import '../../../core/providers/state_providers.dart';
import '../../../core/providers/tournament_provider.dart';
import '../../../core/providers/referee_provider.dart';
import '../../../core/providers/live_matches_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../widgets/live_scorepad_controller.dart';
import '../../../core/widgets/crystal_toast.dart';

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
        CrystalSnackBar(
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
          CrystalSnackBar(
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
        leading: CrystalBackButton.maybeForInnerScreen(context),
        title: const Text('Referee Panel'),
        actions: [
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
              'MY ASSIGNMENTS',
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
