import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/providers/state_providers.dart';
import '../../../core/providers/tournament_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

/// Shared formatting helpers for event data (used by list, detail and
/// registration screens so every surface renders the same real values).
String formatEventDate(dynamic iso) {
  if (iso == null) return 'TBA';
  final d = DateTime.tryParse(iso.toString());
  if (d == null) return iso.toString();
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

String formatEventFee(dynamic registrationFeeCents) {
  final cents = (registrationFeeCents is num) ? registrationFeeCents.toInt() : int.tryParse('${registrationFeeCents ?? ''}') ?? 0;
  if (cents <= 0) return 'Free entry';
  return 'CAD \$${(cents / 100).toStringAsFixed(cents % 100 == 0 ? 0 : 2)}';
}

Color eventStatusColor(String status) {
  switch (status.toUpperCase()) {
    case 'PUBLISHED':
      return Colors.amber;
    case 'ONGOING':
      return Colors.greenAccent;
    case 'COMPLETED':
      return Colors.grey;
    case 'CANCELLED':
      return Colors.red;
    default:
      return Colors.blueGrey;
  }
}

/// Tournaments List Screen — real data from GET /tournaments/events.
class TournamentsListScreen extends ConsumerWidget {
  const TournamentsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tournamentsAsync = ref.watch(tournamentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Competitions'),
      ),
      body: tournamentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 12),
              Text('Could not load competitions', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text('$error', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(tournamentProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (events) {
          // Drafts are not public product surfaces; hide them here.
          final visible = events
              .where((e) => (e['status']?.toString().toUpperCase() ?? '') != 'DRAFT')
              .toList();
          if (visible.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => ref.refresh(tournamentProvider.future),
              child: ListView(
                children: const [
                  SizedBox(height: 120),
                  Icon(Icons.emoji_events_outlined, size: 56, color: Colors.grey),
                  SizedBox(height: 12),
                  Center(child: Text('No competitions published yet')),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(tournamentProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: visible.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final t = visible[index];
                final status = (t['status']?.toString() ?? 'UNKNOWN').toUpperCase();
                final color = eventStatusColor(status);
                final location = [
                  t['city']?.toString(),
                  t['province']?.toString(),
                ].where((part) => part != null && part.isNotEmpty).join(', ');

                return GestureDetector(
                  onTap: () => context.push('/tournament/${t['id']}'),
                  child: GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status == 'PUBLISHED' ? 'REGISTRATION OPEN' : status,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                            Text(
                              t['startDate'] != null ? formatEventDate(t['startDate']) : '',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          t['name']?.toString() ?? t['title']?.toString() ?? 'Untitled competition',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location.isEmpty ? 'Location TBA' : location,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                            Text(
                              formatEventFee(t['registrationFeeCents']),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
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

/// Tournament Detail Screen — real data from GET /tournaments/events/:id.
class TournamentDetailScreen extends ConsumerWidget {
  final String tournamentId;

  const TournamentDetailScreen({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final eventAsync = ref.watch(eventDetailProvider(tournamentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournament Details'),
      ),
      body: eventAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 12),
              Text('Could not load tournament', style: theme.textTheme.titleSmall),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(eventDetailProvider(tournamentId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (event) {
          final status = (event['status']?.toString() ?? '').toUpperCase();
          final canRegister = status == 'PUBLISHED';
          // Operations entry — visible to the event's organizer or to
          // director/admin roles only. The backend remains authoritative;
          // this merely avoids showing a door the viewer cannot walk through.
          final auth = ref.watch(authProvider);
          final role = auth.userProfile?['role']?.toString().toUpperCase();
          const operatorRoles = {'PROVINCIAL_DIRECTOR', 'NATIONAL_DIRECTOR', 'SYSTEM_ADMIN'};
          final canOperate = operatorRoles.contains(role) ||
              (event['organizerId'] != null &&
                  event['organizerId'].toString() == auth.userProfile?['id']?.toString());
          final location = [
            event['venueName']?.toString(),
            event['city']?.toString(),
            event['province']?.toString(),
          ].where((part) => part != null && part.isNotEmpty).join(', ');
          final dates = [
            formatEventDate(event['startDate']),
            formatEventDate(event['endDate']),
          ].toSet().join(' → ');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: eventStatusColor(status).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: eventStatusColor(status),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            formatEventFee(event['registrationFeeCents']),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        event['name']?.toString() ?? 'Untitled competition',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if ((event['description']?.toString() ?? '').isNotEmpty) ...[
                        Text(
                          event['description'].toString(),
                          style: const TextStyle(height: 1.5, fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _detailRow(Icons.calendar_today_outlined, dates),
                      if (location.isNotEmpty)
                        _detailRow(Icons.location_on_outlined, location),
                      if (event['capacity'] != null)
                        _detailRow(Icons.groups_outlined, 'Capacity: ${event['capacity']} athletes'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: canRegister ? () => context.push('/tournament/$tournamentId/register') : null,
                  child: Text(canRegister ? 'Register for Event' : 'Registration unavailable'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.push('/tournament/$tournamentId/brackets'),
                  child: const Text('View Match Brackets'),
                ),
                if (canOperate) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/tournament/$tournamentId/operations'),
                    icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                    label: const Text('Event Operations'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

/// Tournament Brackets Screen
class TournamentBracketsScreen extends ConsumerStatefulWidget {
  final String tournamentId;

  const TournamentBracketsScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<TournamentBracketsScreen> createState() => _TournamentBracketsScreenState();
}

class _TournamentBracketsScreenState extends ConsumerState<TournamentBracketsScreen> {
  String? _selectedBracketId;

  @override
  Widget build(BuildContext context) {
    final bracketsAsync = ref.watch(eventBracketsProvider(widget.tournamentId));

    return Scaffold(
      appBar: AppBar(title: const Text('Tournament Brackets')),
      body: bracketsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 80),
            Center(child: Icon(Icons.error_outline, size: 44, color: AppTheme.error)),
            const SizedBox(height: 12),
            Center(child: Text('Could not load brackets', style: Theme.of(context).textTheme.titleSmall)),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton(
                onPressed: () => ref.invalidate(eventBracketsProvider(widget.tournamentId)),
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
        data: (brackets) {
          if (brackets.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: const [
                SizedBox(height: 100),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.account_tree_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No brackets published yet.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            );
          }
          final selected = _selectedBracketId != null && brackets.any((b) => b['id']?.toString() == _selectedBracketId)
              ? _selectedBracketId!
              : brackets.first['id']?.toString();

          return Column(
            children: [
              // Bracket selector — one chip per category bracket.
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  children: [
                    for (final b in brackets)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            '${b['division'] ?? ''} ${b['weightClass'] ?? ''} ${b['arm'] ?? ''}'.trim(),
                            style: const TextStyle(fontSize: 11),
                          ),
                          selected: b['id']?.toString() == selected,
                          onSelected: (_) => setState(() => _selectedBracketId = b['id']?.toString()),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(child: _buildBracketMatches(selected)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBracketMatches(String? bracketId) {
    if (bracketId == null || bracketId.isEmpty) {
      return const Center(child: Text('Select a bracket.', style: TextStyle(color: Colors.grey)));
    }
    final detailAsync = ref.watch(bracketDetailsProvider(bracketId));
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(bracketDetailsProvider(bracketId)),
      child: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [Text('Could not load bracket: $e', textAlign: TextAlign.center)],
        ),
        data: (bracket) {
          final status = (bracket['status']?.toString() ?? '').toUpperCase();
          final matches = (bracket['matches'] as List?) ?? const [];
          if (matches.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                GlassCard(
                  child: ListTile(
                    leading: const Icon(Icons.hourglass_empty),
                    title: Text(status.isEmpty ? 'Bracket pending' : 'Status: $status'),
                    subtitle: const Text('Matchups appear once the organizer generates them.'),
                  ),
                ),
              ],
            );
          }

          // Group by round for honest round-by-round rendering.
          final rounds = <int, List<Map<String, dynamic>>>{};
          for (final raw in matches) {
            final m = Map<String, dynamic>.from(raw);
            final round = (m['round'] as num?)?.toInt() ?? 0;
            rounds.putIfAbsent(round, () => []).add(m);
          }
          final sortedRounds = rounds.keys.toList()..sort();

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: sortedRounds.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final round = sortedRounds[index];
              final roundMatches = rounds[round]!
                ..sort((a, b) => ((a['matchIndex'] as num?)?.toInt() ?? 0)
                    .compareTo((b['matchIndex'] as num?)?.toInt() ?? 0));
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bracket['format']?.toString() == 'DOUBLE_ELIMINATION'
                        ? 'Round $round (${_bracketTypeLabel(roundMatches.first)})'
                        : 'Round $round',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber),
                  ),
                  const SizedBox(height: 10),
                  for (final m in roundMatches)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _matchCard(m),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String _bracketTypeLabel(Map<String, dynamic> m) {
    switch ((m['bracketType']?.toString() ?? '').toUpperCase()) {
      case 'WINNERS':
        return 'Winners';
      case 'LOSERS':
        return 'Losers';
      case 'GRAND_FINAL':
        return 'Grand Final';
      default:
        return m['bracketType']?.toString() ?? '';
    }
  }

  Widget _matchCard(Map<String, dynamic> m) {
    final aName = m['athleteAName']?.toString() ?? 'TBD';
    final bName = m['athleteBName']?.toString() ?? 'TBD';
    final winnerId = m['winnerId']?.toString() ?? '';
    final aWins = winnerId.isNotEmpty && winnerId == (m['athleteAId']?.toString() ?? '');
    final bWins = winnerId.isNotEmpty && winnerId == (m['athleteBId']?.toString() ?? '');
    final scoreLine = m['scoreLine']?.toString() ?? '';

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(aName,
                    style: TextStyle(fontWeight: aWins ? FontWeight.bold : FontWeight.normal)),
              ),
              Text('vs', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Expanded(
                child: Text(bName,
                    textAlign: TextAlign.end,
                    style: TextStyle(fontWeight: bWins ? FontWeight.bold : FontWeight.normal)),
              ),
            ],
          ),
          if ((m['athleteAElo'] != null || m['athleteBElo'] != null))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'ELO ${(m['athleteAElo'] as num?)?.toInt() ?? '—'} : ${(m['athleteBElo'] as num?)?.toInt() ?? '—'}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          const Divider(height: 16),
          Row(
            children: [
              Icon(
                (m['status']?.toString().toUpperCase()) == 'COMPLETED'
                    ? Icons.check_circle_outline
                    : Icons.schedule,
                size: 14,
                color: Colors.grey,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  scoreLine.isNotEmpty
                      ? '${m['status'] ?? ''} • $scoreLine'
                      : '${m['status'] ?? 'SCHEDULED'}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
