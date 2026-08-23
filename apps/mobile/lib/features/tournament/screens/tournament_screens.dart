import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/providers/state_providers.dart';

/// Tournaments List Screen
class TournamentsListScreen extends ConsumerWidget {
  const TournamentsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tournaments = [
      {
        'id': 't-1',
        'title': 'Pakistan Armwrestling Championship 2026',
        'location': 'Lahore, Pakistan',
        'date': 'Oct 12-14, 2026',
        'status': 'Open for Registration',
        'color': Colors.amber,
      },
      {
        'id': 't-2',
        'title': 'WAF Supermatch Series Islamabad',
        'location': 'Islamabad, Pakistan',
        'date': 'Nov 05, 2026',
        'status': 'Upcoming',
        'color': Colors.blue,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournaments'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: tournaments.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final t = tournaments[index];
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
                          color: (t['color'] as Color).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          t['status'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: t['color'] as Color,
                          ),
                        ),
                      ),
                      Text(
                        t['date'] as String,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t['title'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        t['location'] as String,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
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
  }
}

/// Tournament Detail Screen
class TournamentDetailScreen extends ConsumerWidget {
  final String tournamentId;

  const TournamentDetailScreen({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournament Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Pakistan Armwrestling Championship 2026',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The ultimate armwrestling battleground in Lahore. Features double-elimination brackets across all major heavyweight and lightweight divisions, fully sanctioned by the WAF.',
                    style: TextStyle(height: 1.5, fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Buttons for brackets and registration
            ElevatedButton(
              onPressed: () => context.push('/tournament/$tournamentId/register'),
              child: const Text('Register for Event'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.push('/tournament/$tournamentId/brackets'),
              child: const Text('View Match Brackets'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.push('/tournament/$tournamentId/operations'),
              child: const Text('Tournament Administration'),
            ),
          ],
        ),
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
