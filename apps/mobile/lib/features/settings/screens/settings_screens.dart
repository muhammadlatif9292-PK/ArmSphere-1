import 'package:flutter/material.dart';
import '../../../core/widgets/glass_card.dart';

/// Blocked Users Screen
class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final blocked = [
      {'name': 'Toxic Puller ABC', 'reason': 'Spamming table requests'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Blocked Users')),
      body: blocked.isEmpty
          ? const Center(child: Text('No blocked users.'))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: blocked.length,
              itemBuilder: (context, index) {
                final user = blocked[index];
                return GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: ListTile(
                    title: Text(user['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Reason: ${user['reason']}'),
                    trailing: OutlinedButton(
                      onPressed: () {},
                      child: const Text('Unblock'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// My Tickets Screen
class MyTicketsScreen extends StatelessWidget {
  const MyTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tickets = [
      {'event': 'Pakistan Armwrestling Supermatch Series', 'seat': 'VIP Front-Row Table 4', 'date': 'Oct 12, 2026'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('My Tickets & Passes')),
      body: tickets.isEmpty
          ? const Center(child: Text('No purchased tickets.'))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                return GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(Icons.qr_code, size: 40, color: Colors.amber),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Paid VIP', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(ticket['event']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('Access Spec: ${ticket['seat']}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(ticket['date']!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
