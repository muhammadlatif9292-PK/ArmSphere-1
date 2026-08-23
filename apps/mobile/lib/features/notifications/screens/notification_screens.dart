import 'package:flutter/material.dart';
import '../../../core/widgets/glass_card.dart';

class NotificationsListScreen extends StatelessWidget {
  const NotificationsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        'title': 'ELO Recalculated!',
        'body': 'Your Right Arm ELO increased by +32 points following victory against Zain Shah.',
        'time': '2 hours ago',
        'icon': Icons.trending_up,
        'color': Colors.green,
      },
      {
        'title': 'Match Confirmed',
        'body': 'Referee Zain Shah certified your victory in Round 5. View your updated scorepad.',
        'time': '1 day ago',
        'icon': Icons.verified_outlined,
        'color': Colors.blue,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final n = notifications[index];
          return GlassCard(
            padding: const EdgeInsets.all(12),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (n['color'] as Color).withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(n['icon'] as IconData, color: n['color'] as Color),
              ),
              title: Text(n['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(n['body'] as String, style: const TextStyle(fontSize: 12)),
              trailing: Text(
                n['time'] as String,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          );
        },
      ),
    );
  }
}
