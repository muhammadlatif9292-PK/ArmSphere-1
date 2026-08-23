import 'package:flutter/material.dart';
import '../../../core/widgets/glass_card.dart';

class InformalEventDetailScreen extends StatelessWidget {
  final String eventId;

  const InformalEventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Practice Sparring Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Lahore Gym Friday Night Sparring',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text('Model Town Gym, Lahore, Pakistan', style: TextStyle(color: Colors.grey)),
              const Divider(height: 32),
              const Text('Host Details:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Hosted by Haider Khan. Anyone is welcome, lightweight to heavy. WAF table on-site. Come share rises and techniques!', style: TextStyle(height: 1.5, fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Joined practice meetup! See you there!')),
                  );
                },
                child: const Text('Join Practice Meetup'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
