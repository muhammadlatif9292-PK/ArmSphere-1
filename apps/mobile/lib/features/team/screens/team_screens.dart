import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/providers/social_provider.dart';
import '../../../core/providers/athlete_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/skeleton_placeholder.dart';

/// Teams List Screen — shows the teams the signed-in athlete belongs to,
/// backed by GET /social/my-teams.
class TeamsListScreen extends ConsumerWidget {
  const TeamsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myTeamsAsync = ref.watch(myTeamsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Teams'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create team',
            onPressed: () => context.push('/teams/create'),
          ),
        ],
      ),
      body: myTeamsAsync.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (_, __) => const SkeletonPlaceholder(height: 88),
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
              icon: Icons.groups,
              title: 'No teams yet',
              subtitle:
                  'You are not a member of any team. Create one and start building your roster.',
              ctaLabel: 'Create a team',
              onCtaTap: () => context.push('/teams/create'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myTeamsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: teams.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final t = teams[index];
                final clubLabel =
                    (t['clubName'] as String?) ?? 'Independent';
                return GestureDetector(
                  onTap: () => context.push('/teams/${t['id']}'),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t['name']?.toString() ?? 'Unnamed team',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                clubLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: t['role'] == 'CAPTAIN'
                                ? AppTheme.goldGlow
                                : AppTheme.border,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            t['role']?.toString() ?? 'MEMBER',
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Team Detail Screen — real team data from GET /social/teams/:teamId.
/// Roster management (add/remove members) is only offered to team captains,
/// mirroring the backend authorization rules.
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

  Future<void> _confirmRemove(Map<String, dynamic> member) async {
    final name = member['displayName']?.toString() ?? 'this athlete';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove member'),
        content: Text('Remove $name from this team?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(
      () => ref
          .read(teamProvider(widget.teamId).notifier)
          .removeMember(member['athleteId'].toString()),
      successMessage: 'Member removed',
    );
  }

  void _openAddMemberSheet(String teamId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddMemberSheet(teamId: teamId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teamAsync = ref.watch(teamProvider(widget.teamId));
    final myProfileAsync = ref.watch(athleteProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Team Details')),
      body: teamAsync.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(20),
          children: const [
            SkeletonPlaceholder(height: 140),
            SizedBox(height: 16),
            SkeletonPlaceholder(height: 64),
            SizedBox(height: 8),
            SkeletonPlaceholder(height: 64),
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

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(teamProvider(widget.teamId)),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team['name']?.toString() ?? 'Team',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if ((team['description'] as String?)?.isNotEmpty ==
                          true) ...[
                        const SizedBox(height: 8),
                        Text(
                          team['description'].toString(),
                          style: TextStyle(
                            height: 1.5,
                            fontSize: 13,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const Divider(height: 24),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Chip(
                            avatar: const Icon(Icons.flag_outlined, size: 16),
                            label: Text(clubName ?? 'Independent'),
                            visualDensity: VisualDensity.compact,
                          ),
                          if (team['foundedAt'] != null)
                            Chip(
                              avatar:
                                  const Icon(Icons.calendar_today, size: 14),
                              label: Text(
                                  'Founded ${team['foundedAt'].toString().split('T').first}'),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Roster (${members.length})',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (canManage)
                      TextButton.icon(
                        onPressed:
                            _busy ? null : () => _openAddMemberSheet(team['id'].toString()),
                        icon: const Icon(Icons.person_add_alt_1, size: 18),
                        label: const Text('Add'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (members.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No active members yet.',
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ...members.map((m) {
                    if (m is! Map) return const SizedBox.shrink();
                    final member = Map<String, dynamic>.from(m);
                    final isMe =
                        member['athleteId']?.toString() == myAthleteId;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundImage:
                                  member['profilePhoto'] != null
                                      ? NetworkImage(
                                          member['profilePhoto'].toString())
                                      : null,
                              child: member['profilePhoto'] == null
                                  ? Text(
                                      (member['displayName']
                                              ?.toString() ??
                                          '?')[0]
                                          .toUpperCase(),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member['displayName']?.toString() ??
                                        'Athlete',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    member['role']?.toString() ?? 'MEMBER',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (canManage && !isMe)
                              IconButton(
                                tooltip: 'Remove member',
                                icon: const Icon(Icons.remove_circle_outline,
                                    size: 20),
                                onPressed: _busy
                                    ? null
                                    : () => _confirmRemove(member),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                if (!canManage) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Only team captains can manage this roster.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    _debounce = Timer(const Duration(milliseconds: 400), () {
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
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selected['displayName']} added to the team'),
            backgroundColor: Colors.green,
          ),
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
          SnackBar(
              content: Text('Could not add member: $e'),
              backgroundColor: Colors.red),
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
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add member',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Search athletes by name',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _onQueryChanged,
            ),
            const SizedBox(height: 12),
            if (_selected != null) ...[
              GlassCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selected!['displayName']?.toString() ?? 'Athlete',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ChoiceChip(
                      label: const Text('MEMBER'),
                      selected: _role == 'MEMBER',
                      onSelected: (_) => setState(() => _role = 'MEMBER'),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('CAPTAIN'),
                      selected: _role == 'CAPTAIN',
                      onSelected: (_) => setState(() => _role = 'CAPTAIN'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _busy ? null : _addSelected,
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add to team'),
              ),
              const SizedBox(height: 12),
            ],
            Flexible(
              child: resultsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                  ),
                ),
                data: (results) {
                  if (results.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No athletes found.',
                        textAlign: TextAlign.center,
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
                          backgroundImage: a['profilePhoto'] != null
                              ? NetworkImage(a['profilePhoto'].toString())
                              : null,
                          child: a['profilePhoto'] == null
                              ? Text((a['displayName']?.toString() ?? '?')[0]
                                  .toUpperCase())
                              : null,
                        ),
                        title: Text(a['displayName']?.toString() ?? 'Athlete'),
                        subtitle: a['province'] != null
                            ? Text(a['province'].toString())
                            : null,
                        onTap: () => setState(() {
                          _selected = a;
                          _searchController.text =
                              a['displayName']?.toString() ?? '';
                        }),
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
/// The creator automatically becomes CAPTAIN (backend behavior).
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
    final picked = await showDatePicker(
      context: context,
      initialDate: _foundedAt ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newTeam['name']} created — you are the captain.'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/teams/${newTeam['id']}');
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
          SnackBar(content: Text('Could not create team: $e'), backgroundColor: Colors.red),
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
      appBar: AppBar(title: const Text('Create Team')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: GlassCard(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                      labelText: 'Team Name', hintText: 'e.g. Lahore Iron Grip'),
                  validator: (value) {
                    if (value == null || value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'Description (optional)'),
                ),
                const SizedBox(height: 16),
                clubsAsync.when(
                  loading: () => const LinearProgressIndicator(minHeight: 2),
                  error: (error, _) => Text(
                    'Clubs could not be loaded: $error',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.error),
                  ),
                  data: (clubs) => DropdownButtonFormField<String>(
                    value: _clubId,
                    decoration: const InputDecoration(
                        labelText: 'Affiliated Club (optional)'),
                    items: clubs
                        .map((c) => DropdownMenuItem(
                              value: c['id']?.toString(),
                              child: Text(c['name']?.toString() ?? 'Club'),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _clubId = value),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickFoundedDate,
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration:
                        const InputDecoration(labelText: 'Founded On (optional)'),
                    child: Text(
                      _foundedAt == null
                          ? 'Select date'
                          : _foundedAt!.toIso8601String().split('T').first,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Team'),
                ),
                const SizedBox(height: 12),
                Text(
                  'You will be registered as the team captain.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
