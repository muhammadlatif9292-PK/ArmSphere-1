import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/providers/state_providers.dart';
import '../../../core/providers/tournament_provider.dart';

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
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Could not load competitions', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text('$error', textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
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
class TournamentBracketsScreen extends StatefulWidget {
  final String tournamentId;

  const TournamentBracketsScreen({super.key, required this.tournamentId});

  @override
  State<TournamentBracketsScreen> createState() => _TournamentBracketsScreenState();
}

class _TournamentBracketsScreenState extends State<TournamentBracketsScreen> {
  @override
  Widget build(BuildContext context) {
    final matches = [
      {'round': 'Quarterfinals', 'p1': 'Zain Shah', 'p2': 'Farhan Ahmed', 'winner': 'Zain Shah'},
      {'round': 'Semifinals', 'p1': 'Zain Shah', 'p2': 'Haider Khan', 'winner': 'Pending'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournament Brackets'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: matches.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final m = matches[index];
          return GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m['round']!,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(m['p1']!, style: TextStyle(fontWeight: m['winner'] == m['p1'] ? FontWeight.bold : FontWeight.normal)),
                    const Text('vs'),
                    Text(m['p2']!, style: TextStyle(fontWeight: m['winner'] == m['p2'] ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
                const Divider(height: 20),
                Text(
                  'Winner: ${m['winner']}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
