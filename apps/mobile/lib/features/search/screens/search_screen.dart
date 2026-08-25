import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/athlete_provider.dart';
import '../../../core/widgets/glass_card.dart';

/// Real global search over athletes via GET /athletes/search.
/// Other entity types (events/clubs/venues) surface through their own
/// Discover sections until dedicated backend search endpoints exist.
class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onQueryChanged);
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(athleteSearchQueryProvider.notifier).state =
          _searchController.text.trim();
    });
  }

  String? _field(Map<String, dynamic> row, List<String> keys) {
    for (final k in keys) {
      final v = row[k];
      if (v != null && v.toString().isNotEmpty) return v.toString();
    }
    return null;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onQueryChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(athleteSearchProvider);
    final hasQuery = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Discover ArmSphere')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search athletes...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: Icon(Icons.person_search_outlined),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: !hasQuery
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.travel_explore, size: 48, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('Type a name to find athletes',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : resultsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 44, color: Colors.red),
                            const SizedBox(height: 12),
                            Text('Search failed', style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 4),
                            Text('$error',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => ref.invalidate(athleteSearchProvider),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                      data: (rows) {
                        if (rows.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.search_off, size: 48, color: Colors.grey),
                                SizedBox(height: 12),
                                Text('No athletes match your search',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          );
                        }
                        return ListView.separated(
                          itemCount: rows.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final row = rows[index];
                            final name = _field(row, ['displayName', 'name']) ?? 'Unnamed athlete';
                            final avatar = _field(row, ['avatarUrl', 'avatar_url', 'photoUrl']);
                            final subtitle = [
                              _field(row, ['weightClass']),
                              _field(row, ['province']),
                            ].where((p) => p != null).join(' • ');

                            return GestureDetector(
                              onTap: () => context.push('/athlete/${row['id']}'),
                              child: GlassCard(
                                padding: const EdgeInsets.all(12),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                                    child: avatar == null
                                        ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?')
                                        : null,
                                  ),
                                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: subtitle.isNotEmpty ? Text(subtitle, fontSize: 12) : null,
                                  trailing: const Icon(Icons.chevron_right),
                                ),
                              ),
                            );
                          },
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
