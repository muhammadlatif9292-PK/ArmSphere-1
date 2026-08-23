import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/glass_card.dart';

class VenueDirectoryScreen extends StatelessWidget {
  const VenueDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final venues = [
      {'id': 'v-1', 'name': 'Lahore Iron Grip Club', 'address': '12 Gulberg, Lahore, Pakistan', 'distance': '2.4 km away'},
      {'id': 'v-2', 'name': 'Pindi Pullers Training Ground', 'address': 'Saddar, Rawalpindi, Pakistan', 'distance': '15.8 km away'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Armwrestling Venues'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt_outlined),
            onPressed: () => context.push('/venues/submit'),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: venues.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final v = venues[index];
          return GestureDetector(
            onTap: () => context.push('/venues/${v['id']}'),
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(v['address']!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Text(
                    v['distance']!,
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
