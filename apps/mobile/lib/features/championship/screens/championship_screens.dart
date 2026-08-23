import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/glass_card.dart';

class ChampionshipsListScreen extends StatelessWidget {
  const ChampionshipsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final championships = [
      {'id': 'C- Pakistan', 'title': 'National Armwrestling Super League', 'region': 'Pakistan National Division'},
      {'id': 'C- Asia', 'title': 'Asian Armwrestling Championship 2026', 'region': 'WAF Asia'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Championship Leagues'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: championships.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final c = championships[index];
          return GestureDetector(
            onTap: () => context.push('/championship/${c['id']}'),
            child: GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    c['title']!,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    c['region']!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
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

class ChampionshipDetailScreen extends StatelessWidget {
  final String championshipId;

  const ChampionshipDetailScreen({super.key, required this.championshipId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Championship Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: GlassCard(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'National Super League',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Official multi-city championship series designed to identify Pakistan\'s supreme armwrestlers. Competitors pull in monthly matches to earn official ranking ELO points and qualify for prestigious international Supermatches.',
                style: TextStyle(height: 1.5, fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {},
                child: const Text('View Current League Standings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
