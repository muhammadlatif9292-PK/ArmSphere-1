import 'package:flutter/material.dart';
import '../../../core/widgets/glass_card.dart';

class AnnouncementsListScreen extends StatelessWidget {
  const AnnouncementsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final announcements = [
      {
        'title': 'New Anti-Doping Regulations 2026',
        'details': 'Please review the updated WAF certified substances list before October tournament registrations.',
        'date': 'Yesterday',
      },
      {
        'title': 'Referee Seminar Lahore',
        'details': 'WAF Master Seminar in Lahore is now open for registration. Re-certification courses included.',
        'date': '3 days ago',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Federation Announcements')),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: announcements.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final item = announcements[index];
          return GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  item['title']!,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  item['details']!,
                  style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    item['date']!,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
