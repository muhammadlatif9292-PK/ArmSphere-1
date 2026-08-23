import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/glass_card.dart';

class InformalEventDirectoryScreen extends StatelessWidget {
  const InformalEventDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final events = [
      {'id': 'ie-1', 'title': 'Lahore Gym Friday Night Sparring', 'location': 'Model Town Gym', 'date': 'Friday, 8:00 PM'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice Meetups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => context.push('/informal-events/create'),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final e = events[index];
          return GestureDetector(
            onTap: () => context.push('/informal-events/${e['id']}'),
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(e['location']!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Text(
                    e['date']!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
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
