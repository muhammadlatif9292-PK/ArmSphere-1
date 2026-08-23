import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/providers/rankings_provider.dart';

class RankingsScreen extends ConsumerWidget {
  const RankingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingsAsync = ref.watch(rankingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard & Rankings'),
      ),
      body: rankingsAsync.when(
        data: (rankings) {
          if (rankings.isEmpty) {
            return const Center(
              child: Text(
                'No ranking data available',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: rankings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final athlete = rankings[index];
              final rank = athlete['rank'] as int? ?? (index + 1);
              final name = athlete['name'] as String? ?? 'Unknown Athlete';
              final nickname = athlete['nickname'] as String? ?? '';
              final rating = athlete['eloRating'] as int? ?? athlete['rating'] as int? ?? 1000;
              final weightClass = athlete['weightClass'] as String? ?? 'N/A';
              final wins = athlete['wins'] as int? ?? 0;
              final losses = athlete['losses'] as int? ?? 0;
              final avatarUrl = athlete['avatarUrl'] as String? ?? '';

              // Special styling for top 3 ranks
              Color rankColor = Colors.grey;
              if (rank == 1) {
                rankColor = Colors.amber;
              } else if (rank == 2) {
                rankColor = Colors.grey.shade400;
              } else if (rank == 3) {
                rankColor = Colors.brown.shade400;
              }

              return GestureDetector(
                onTap: () {
                  final athleteId = athlete['id'] as String? ?? '';
                  if (athleteId.isNotEmpty) {
                    context.push('/athlete/$athleteId');
                  }
                },
                child: GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Rank position
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: rankColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$rank',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: rankColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Avatar
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                        backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl.isEmpty
                            ? Text(name.isNotEmpty ? name[0] : 'A')
                            : null,
                      ),
                      const SizedBox(width: 12),

                      // Athlete info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            if (nickname.isNotEmpty)
                              Text(
                                '"$nickname"',
                                style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              '$weightClass • $wins W - $losses L',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),

                      // Rating ELO
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$rating',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const Text(
                            'ELO',
                            style: TextStyle(fontSize: 9, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'Error loading rankings: $err',
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
