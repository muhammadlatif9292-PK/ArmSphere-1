import 'package:flutter/material.dart';
import '../../../core/widgets/glass_card.dart';

class VenueDetailScreen extends StatelessWidget {
  final String venueId;

  const VenueDetailScreen({super.key, required this.venueId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Venue Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Lahore Iron Grip Club',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text('12 Gulberg, Lahore, Pakistan', style: TextStyle(color: Colors.grey)),
              const Divider(height: 32),
              const Text('Amenities:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('• 4 Official WAF Steel Tables\n• Strap Training Hooks\n• Rising & Pronation Weight Stacks\n• High-Frame Rate Video Recording Rig', style: TextStyle(height: 1.6, fontSize: 13)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Directions opened in Maps app')),
                  );
                },
                child: const Text('Get Directions'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
