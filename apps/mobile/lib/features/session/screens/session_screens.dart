import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/providers/state_providers.dart';

/// Active Sessions List Screen
class ActiveSessionsListScreen extends ConsumerWidget {
  const ActiveSessionsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sessions = [
      {'id': 'S-01', 'title': 'Heavy Table Pulling Session', 'location': 'Lahore Arm Club', 'attendees': '8 pullers'},
      {'id': 'S-02', 'title': 'Hook Training & Strap Practice', 'location': 'Rawalpindi Table', 'attendees': '4 pullers'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Pulling Sessions'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: sessions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final s = sessions[index];
          return GestureDetector(
            onTap: () => context.push('/athlete/session/${s['id']}'),
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(s['location']!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Text(s['attendees']!, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Active Session Control Screen
class ActiveSessionControlScreen extends StatefulWidget {
  final String sessionId;

  const ActiveSessionControlScreen({super.key, required this.sessionId});

  @override
  State<ActiveSessionControlScreen> createState() => _ActiveSessionControlScreenState();
}

class _ActiveSessionControlScreenState extends State<ActiveSessionControlScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Session ${widget.sessionId}'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer_outlined, size: 64, color: Colors.teal),
              const SizedBox(height: 16),
              const Text('Session In Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 8),
              const Text('Timer: 00:45:12', style: TextStyle(fontFamily: 'monospace', fontSize: 16)),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.stop),
                label: const Text('Stop Table Session'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
