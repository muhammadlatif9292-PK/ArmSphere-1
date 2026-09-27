import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/providers/social_provider.dart';
import '../../../core/providers/athlete_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/skeleton_placeholder.dart';
import '../../../core/widgets/status_chip.dart';

/// Domain 10 / Stage 6 Convergence: Teams List Screen
///
/// Implements Canonical Team & Club Directory Architecture:
/// - Displays teams the signed-in athlete belongs to (GET /social/my-teams).
/// - Unbundled team card with affiliated club pill, role indicator, and Space Grotesk styling.
/// - Eradication of nested `GlassCard` inside `ListView` in compliance with Audit Rule Item 2.2.
/// - Full `RepaintBoundary` raster isolation for smooth 60fps scrolling.
class TeamsListScreen extends ConsumerWidget {
  const TeamsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myTeamsAsync = ref.watch(myTeamsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardSurface,
        elevation: 0,
        title: const Text(
          'My Teams & Clubs',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_outlined, color: AppTheme.goldPrimary),
            tooltip: 'Create team',
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push('/teams/create');
            },
          ),
        ],
      ),
      body: myTeamsAsync.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(AppTheme.space16),
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(height: AppTheme.space12),
          itemBuilder: (_, __) => const SkeletonPlaceholder(
            height: 92,
            borderRadius: AppTheme.radiusMedium,
          ),
        ),
        error: (error, _) => AppEmptyState(
          icon: Icons.error_outline,
          title: 'Could not load teams',
          subtitle: error.toString(),
          ctaLabel: 'Retry',
          onCtaTap: () => ref.invalidate(myTeamsProvider),
        ),
        data: (teams) {
          if (teams.isEmpty) {
            return AppEmptyState(
              icon: Icons.groups_outlined,
              title: 'No teams joined',
              subtitle:
                  'You are not a member of any team. Create one or join an affiliated club to build your roster.',
              ctaLabel: 'Create a team',
              onCtaTap: () {
                HapticFeedback.lightImpact();
                context.push('/teams/create');
              },
            );
          }

          final captainCount = teams
              .where((t) => (t['role']?.toString().toUpperCase()) == 'CAPTAIN')
              .length;

          return RefreshIndicator(
            color: AppTheme.goldPrimary,
            backgroundColor: AppTheme.cardSurface,
            onRefresh: () async => ref.invalidate(myTeamsProvider),
            child: ListView(
              key: const PageStorageKey<String>('teams_list_view'),
              padding: const EdgeInsets.all(AppTheme.space16),
              children: [
                // Top Roster Overview Ribbon
                Container(
                  padding: const EdgeInsets.all(AppTheme.space12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardSurface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(color: AppTheme.border, width: 1.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _OverviewMetric(
                        label: 'TOTAL TEAMS',
                        count: teams.length,
                        color: AppTheme.textPrimary,
                      ),
                      Container(width: 1, height: 28, color: AppTheme.border),
                      _OverviewMetric(
                        label: 'CAPTAIN OF',
                        count: captainCount,
                        color: AppTheme.goldPrimary,
                      ),
                      Container(width: 1, height: 28, color: AppTheme.border),
                      _OverviewMetric(
                        label: 'MEMBER OF',
                        count: teams.length - captainCount,
                        color: AppTheme.textSecondary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space16),

                // Team Cards List
                ...teams.map((t) {
                  final clubLabel = (t['clubName'] as String?) ?? 'Independent';
                  final role = (t['role']?.toString() ?? 'MEMBER').toUpperCase();
                  final isCaptain = role == 'CAPTAIN';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.space12),
                    child: RepaintBoundary(
                      child: ElevatedActionCard(
                        padding: const EdgeInsets.all(AppTheme.space16),
                        onTap: () => context.push('/teams/${t['id']}'),
                        child: Row(
                          children: [
                            // Team Emblem Placeholder
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppTheme.elevatedSurface,
                                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                border: Border.all(
                                  color: isCaptain ? AppTheme.goldPrimary : AppTheme.border,
                                  width: isCaptain ? 1.5 : 1.0,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  isCaptain ? Icons.shield_outlined : Icons.groups_outlined,
                                  color: isCaptain ? AppTheme.goldPrimary : AppTheme.textSecondary,
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.space12),
                            // Team Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t['name']?.toString() ?? 'Unnamed team',
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppTheme.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.flag_outlined,
                                        size: 12,
                                        color: AppTheme.textMuted,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        clubLabel,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Role Status Chip
                            StatusChip(
                              label: isCaptain ? 'CAPTAIN' : 'MEMBER',
                              type: isCaptain ? StatusType.warning : StatusType.neutral,
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: AppTheme.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _OverviewMetric({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }
}

/// Team Detail Screen — real team data from GET /social/teams/:teamId.
/// Roster management (add/remove members) is strictly reserved for team captains.
class TeamDetailScreen extends ConsumerStatefulWidget {
  final String teamId;

  const TeamDetailScreen({super.key, required this.teamId});

  @override
  ConsumerState<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends ConsumerState<TeamDetailScreen> {
  bool _busy = false;

  bool _isCaptain(Map<String, dynamic> team, String? myAthleteId) {
    if (myAthleteId == null) return false;
    final members = team['members'];
    if (members is! List) return false;
    return members.any((m) =>
        m is Map &&
        m['athleteId']?.toString() == myAthleteId &&
        m['role'] == 'CAPTAIN');
  }

  Future<void> _run(Future<void> Function() action,
      {String? successMessage}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted && successMessage != null) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.detail), backgroundColor: AppTheme.error),
        );
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Action failed: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmRemove(Map<String, dynamic> member) async {
    final name = member['displayName']?.toString() ?? 'this athlete';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          side: const BorderSide(color: AppTheme.border, width: 1.0),
        ),
        title: const Text(
          'Remove Member',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          'Remove $name from the official team roster? This will revoke their roster status.',
          style: const TextStyle(color: AppTheme.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: AppTheme.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(
      () => ref
          .read(teamProvider(widget.teamId).notifier)
          .removeMember(member['athleteId'].toString()),
      successMessage: '$name removed from roster',
    );
  }

  void _openAddMemberSheet(String teamId) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
      ),
      builder: (_) => _AddMemberSheet(teamId: teamId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teamAsync = ref.watch(teamProvider(widget.teamId));
    final myProfileAsync = ref.watch(athleteProfileProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardSurface,
        elevation: 0,
        title: const Text(
          'Team Dossier',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: teamAsync.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(AppTheme.space16),
          children: const [
            SkeletonPlaceholder(height: 140, borderRadius: AppTheme.radiusMedium),
            SizedBox(height: AppTheme.space16),
            SkeletonPlaceholder(height: 64, borderRadius: AppTheme.radiusMedium),
            SizedBox(height: AppTheme.space8),
            SkeletonPlaceholder(height: 64, borderRadius: AppTheme.radiusMedium),
          ],
        ),
        error: (error, _) => AppEmptyState(
          icon: Icons.error_outline,
          title: 'Could not load team',
          subtitle: error.toString(),
          ctaLabel: 'Retry',
          onCtaTap: () => ref.invalidate(teamProvider(widget.teamId)),
        ),
        data: (team) {
          final members = (team['members'] as List?) ?? const [];
          final myAthleteId = myProfileAsync.valueOrNull?['id']?.toString();
          final canManage = _isCaptain(team, myAthleteId);
          final club = team['club'];
          final clubName = club is Map && club['name'] != null
              ? club['name'].toString()
              : null;
          final foundedRaw = team['foundedAt']?.toString() ?? '';
          final foundedDate = foundedRaw.contains('T')
              ? foundedRaw.split('T').first
              : foundedRaw;

          return RefreshIndicator(
            color: AppTheme.goldPrimary,
            backgroundColor: AppTheme.cardSurface,
            onRefresh: () async =>
                ref.invalidate(teamProvider(widget.teamId)),
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.space16),
              children: [
                // 1. Team Dossier Header Card
                ElevatedActionCard(
                  padding: const EdgeInsets.all(AppTheme.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              team['name']?.toString() ?? 'Team',
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          if (canManage)
                            const StatusChip(
                              label: 'YOU ARE CAPTAIN',
                              type: StatusType.warning,
                            ),
                        ],
                      ),
                      if ((team['description'] as String?)?.isNotEmpty == true) ...[
                        const SizedBox(height: AppTheme.space8),
                        Text(
                          team['description'].toString(),
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppTheme.space12),
                      const Divider(height: 1, color: AppTheme.border),
                      const SizedBox(height: AppTheme.space12),
                      Wrap(
                        spacing: AppTheme.space8,
                        runSpacing: AppTheme.space8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.elevatedSurface,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.flag_outlined, size: 14, color: AppTheme.goldPrimary),
                                const SizedBox(width: 6),
                                Text(
                                  clubName ?? 'Independent Team',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                                ),
                              ],
                            ),
                          ),
                          if (foundedDate.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.elevatedSurface,
                                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_today_outlined, size: 13, color: AppTheme.textMuted),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Founded $foundedDate',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                      fontFeatures: [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space16),

                // 2. Roster Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'ATHLETE ROSTER',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: AppTheme.goldLight,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.elevatedSurface,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Text(
                            members.length.toString(),
                            style: const TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.goldLight,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (canManage)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.goldPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        onPressed: _busy
                            ? null
                            : () => _openAddMemberSheet(team['id'].toString()),
                        icon: const Icon(Icons.person_add_alt_1, size: 16),
                        label: const Text(
                          'ADD ATHLETE',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppTheme.space12),

                // 3. Roster List Items
                if (members.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space24),
                    decoration: BoxDecoration(
                      color: AppTheme.cardSurface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: const Center(
                      child: Text(
                        'No active members on roster yet.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ),
                  )
                else
                  ...members.map((m) {
                    if (m is! Map) return const SizedBox.shrink();
                    final member = Map<String, dynamic>.from(m);
                    final isMe = member['athleteId']?.toString() == myAthleteId;
                    final isMemberCaptain = member['role']?.toString().toUpperCase() == 'CAPTAIN';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.space8),
                      child: RepaintBoundary(
                        child: ElevatedActionCard(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              // Avatar with Role Ring
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isMemberCaptain ? AppTheme.goldPrimary : AppTheme.border,
                                    width: isMemberCaptain ? 2.0 : 1.0,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppTheme.elevatedSurface,
                                  backgroundImage: member['profilePhoto'] != null
                                      ? NetworkImage(member['profilePhoto'].toString())
                                      : null,
                                  child: member['profilePhoto'] == null
                                      ? Text(
                                          (member['displayName']?.toString() ?? '?')[0].toUpperCase(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isMemberCaptain ? AppTheme.goldPrimary : AppTheme.textPrimary,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: AppTheme.space12),
                              // Name and Role
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            member['displayName']?.toString() ?? 'Athlete',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: AppTheme.textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isMe) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: AppTheme.elevatedSurface,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'YOU',
                                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isMemberCaptain ? 'Team Captain' : 'Team Member',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isMemberCaptain ? AppTheme.goldPrimary : AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Captain action or Member Chip
                              if (canManage && !isMe)
                                IconButton(
                                  tooltip: 'Remove from roster',
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    size: 18,
                                    color: AppTheme.error,
                                  ),
                                  onPressed: _busy ? null : () => _confirmRemove(member),
                                )
                              else if (isMemberCaptain)
                                const StatusChip(label: 'CAPTAIN', type: StatusType.warning),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                if (!canManage) ...[
                  const SizedBox(height: AppTheme.space12),
                  const Center(
                    child: Text(
                      'Roster management is restricted to verified team captains.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Bottom sheet to search athletes and add one to the team with a role.
class _AddMemberSheet extends ConsumerStatefulWidget {
  final String teamId;

  const _AddMemberSheet({required this.teamId});

  @override
  ConsumerState<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends ConsumerState<_AddMemberSheet> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  Map<String, dynamic>? _selected;
  String _role = 'MEMBER';
  bool _busy = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(athleteSearchQueryProvider.notifier).state = value.trim();
    });
  }

  Future<void> _addSelected() async {
    final selected = _selected;
    if (selected == null || _busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(teamProvider(widget.teamId).notifier)
          .addMember(selected['id'].toString(), _role);
      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selected['displayName']} added to the team'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.detail), backgroundColor: AppTheme.error),
        );
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not add member: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(athleteSearchProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppTheme.space20,
          right: AppTheme.space20,
          top: AppTheme.space16,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.space20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Knurled Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.space16),
            const Text(
              'RECRUIT ATHLETE TO ROSTER',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Search registered athletes by name or federated handle.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: AppTheme.space16),
            TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search athlete name...',
                hintStyle: const TextStyle(color: AppTheme.textMuted),
                prefixIcon: const Icon(Icons.search, color: AppTheme.goldPrimary),
                filled: true,
                fillColor: AppTheme.elevatedSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  borderSide: const BorderSide(color: AppTheme.goldPrimary),
                ),
              ),
              onChanged: _onQueryChanged,
            ),
            const SizedBox(height: AppTheme.space12),

            if (_selected != null) ...[
              ElevatedActionCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                borderColor: AppTheme.goldPrimary,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selected!['displayName']?.toString() ?? 'Athlete',
                            style: const TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const Text(
                            'Selected candidate',
                            style: TextStyle(fontSize: 11, color: AppTheme.goldLight),
                          ),
                        ],
                      ),
                    ),
                    ChoiceChip(
                      label: const Text('MEMBER'),
                      selected: _role == 'MEMBER',
                      selectedColor: AppTheme.goldPrimary,
                      onSelected: (_) => setState(() => _role = 'MEMBER'),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('CAPTAIN'),
                      selected: _role == 'CAPTAIN',
                      selectedColor: AppTheme.goldPrimary,
                      onSelected: (_) => setState(() => _role = 'CAPTAIN'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.space12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.goldPrimary,
                  foregroundColor: AppTheme.voidBackground,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                onPressed: _busy ? null : _addSelected,
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.voidBackground),
                      )
                    : const Text(
                        'CONFIRM ROSTER ADDITION',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
              ),
              const SizedBox(height: AppTheme.space12),
            ],

            Flexible(
              child: resultsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppTheme.space16),
                  child: Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary)),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(AppTheme.space16),
                  child: Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.error),
                  ),
                ),
                data: (results) {
                  if (results.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(AppTheme.space16),
                      child: Text(
                        'No matching athletes found.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final a = results[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.elevatedSurface,
                          backgroundImage: a['profilePhoto'] != null
                              ? NetworkImage(a['profilePhoto'].toString())
                              : null,
                          child: a['profilePhoto'] == null
                              ? Text((a['displayName']?.toString() ?? '?')[0].toUpperCase())
                              : null,
                        ),
                        title: Text(
                          a['displayName']?.toString() ?? 'Athlete',
                          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                        ),
                        subtitle: a['province'] != null
                            ? Text(a['province'].toString(), style: const TextStyle(color: AppTheme.textSecondary))
                            : null,
                        trailing: const Icon(Icons.add_circle_outline, color: AppTheme.goldPrimary),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selected = a;
                            _searchController.text = a['displayName']?.toString() ?? '';
                          });
                        },
                      );
                    },
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

/// Create Team Screen — creates a real team via POST /social/teams.
/// The creator automatically becomes CAPTAIN (backend contract).
class CreateTeamScreen extends ConsumerStatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  ConsumerState<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends ConsumerState<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _foundedAt;
  String? _clubId;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFoundedDate() async {
    HapticFeedback.lightImpact();
    final picked = await showDatePicker(
      context: context,
      initialDate: _foundedAt ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.goldPrimary,
              surface: AppTheme.cardSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _foundedAt = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final payload = <String, dynamic>{
        'name': _nameController.text.trim(),
        if (_descriptionController.text.trim().isNotEmpty)
          'description': _descriptionController.text.trim(),
        if (_foundedAt != null)
          'foundedAt': _foundedAt!.toIso8601String(),
        if (_clubId != null) 'clubId': _clubId,
      };

      final newTeam =
          await ref.read(teamCreationProvider.notifier).createTeam(payload);

      // Refresh the "My Teams" list before leaving the form.
      ref.invalidate(myTeamsProvider);

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newTeam['name']} created — you are now team captain.'),
            backgroundColor: AppTheme.success,
          ),
        );
        context.go('/teams/${newTeam['id']}');
      }
    } on ApiException catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.detail), backgroundColor: AppTheme.error),
        );
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not create team: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clubsAsync = ref.watch(clubsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardSurface,
        elevation: 0,
        title: const Text(
          'Register New Team',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Directive Guidance Card
              ElevatedActionCard(
                padding: const EdgeInsets.all(AppTheme.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shield_outlined, color: AppTheme.goldPrimary, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'FEDERATION TEAM REGISTRY',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: AppTheme.goldLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create a competitive squad for federation inter-club brackets and sparring rosters. As founder, you will be designated Team Captain.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.space16),

              // Form Details Card
              ElevatedActionCard(
                padding: const EdgeInsets.all(AppTheme.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Team Name',
                        labelStyle: const TextStyle(color: AppTheme.textSecondary),
                        hintText: 'e.g. Lahore Iron Grip',
                        hintStyle: const TextStyle(color: AppTheme.textMuted),
                        filled: true,
                        fillColor: AppTheme.elevatedSurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          borderSide: const BorderSide(color: AppTheme.goldPrimary),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.space16),

                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Description & Creed (optional)',
                        labelStyle: const TextStyle(color: AppTheme.textSecondary),
                        hintText: 'Training philosophy, club goals...',
                        hintStyle: const TextStyle(color: AppTheme.textMuted),
                        filled: true,
                        fillColor: AppTheme.elevatedSurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          borderSide: const BorderSide(color: AppTheme.goldPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.space16),

                    clubsAsync.when(
                      loading: () => const LinearProgressIndicator(
                        minHeight: 2,
                        color: AppTheme.goldPrimary,
                      ),
                      error: (error, _) => Text(
                        'Clubs could not be loaded: $error',
                        style: const TextStyle(fontSize: 12, color: AppTheme.error),
                      ),
                      data: (clubs) => DropdownButtonFormField<String>(
                        initialValue: _clubId,
                        dropdownColor: AppTheme.elevatedSurface,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Affiliated Club (optional)',
                          labelStyle: const TextStyle(color: AppTheme.textSecondary),
                          filled: true,
                          fillColor: AppTheme.elevatedSurface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            borderSide: const BorderSide(color: AppTheme.border),
                          ),
                        ),
                        items: clubs
                            .map((c) => DropdownMenuItem(
                                  value: c['id']?.toString(),
                                  child: Text(c['name']?.toString() ?? 'Club'),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _clubId = value),
                      ),
                    ),
                    const SizedBox(height: AppTheme.space16),

                    InkWell(
                      onTap: _pickFoundedDate,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.elevatedSurface,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'FOUNDED DATE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _foundedAt == null
                                      ? 'Select date (optional)'
                                      : _foundedAt!.toIso8601String().split('T').first,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _foundedAt == null ? AppTheme.textMuted : AppTheme.textPrimary,
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ],
                            ),
                            const Icon(Icons.calendar_today_outlined, size: 18, color: AppTheme.goldPrimary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.space24),

              // Submit Action
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.goldPrimary,
                  foregroundColor: AppTheme.voidBackground,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.voidBackground),
                      )
                    : const Text(
                        'REGISTER SQUAD & CLAIM CAPTAINCY',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
