import 'package:flutter/material.dart';
import '../../../core/widgets/glass_card.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _searchController = TextEditingController();
  List<String> _results = [];

  void _onSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _results = [];
      });
      return;
    }

    // Basic local query filter mockup
    final mockItems = [
      'Pakistan National Championship 2026',
      'Lahore Iron Grip Club',
      'Zain "The Zephyr" Shah',
      'Arsalan "Apex" Malik',
    ];

    setState(() {
      _results = mockItems
          .where((item) => item.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discover ArmSphere')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search matches, athletes, teams...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _onSearch,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _results.isEmpty
                  ? Center(
                      child: Text(
                        _searchController.text.isEmpty ? 'Type to search...' : 'No results found',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return GlassCard(
                          padding: const EdgeInsets.all(12),
                          child: ListTile(
                            title: Text(_results[index], style: const TextStyle(fontWeight: FontWeight.bold)),
                            trailing: const Icon(Icons.chevron_right),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
