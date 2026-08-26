import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/theme/app_theme.dart';

class MyNominationsScreen extends StatelessWidget {
  const MyNominationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nominations = [
      {'title': 'WAF Elite Master Referee Nomination', 'status': 'Pending Approval', 'date': 'Oct 1, 2026'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Nominations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.star_outline),
            onPressed: () => context.push('/nominate'),
          ),
        ],
      ),
      body: nominations.isEmpty
          ? const Center(child: Text('No active nominations.'))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: nominations.length,
              itemBuilder: (context, index) {
                final n = nominations[index];
                return GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(n['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Status: ${n['status']}', style: const TextStyle(color: AppTheme.secondaryAccent, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(n['date']!, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
