import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/athlete_provider.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/theme/app_theme.dart';

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
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
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
                            const Icon(Icons.error_outline, size: 44, color: AppTheme.error),
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
                          return const AppEmptyState(
                            icon: Icons.search_off_outlined,
                            title: 'No athletes match your search',
                            subtitle: 'Try searching by a different name, spelling, or weight class.',
                          );
                        }
                        return ListView.separated(
                          itemCount: rows.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final row = rows[index];
                            final id = row['id'] ?? row['athleteId'];
                            final name = _field(row, ['displayName', 'name']) ?? 'Unnamed athlete';
                            final avatar = _field(row, ['avatarUrl', 'avatar_url', 'photoUrl']);
                            final subtitle = [
                              _field(row, ['weightClass']),
                              _field(row, ['province']),
                            ].where((p) => p != null).join(' • ');

                            return ElevatedActionCard(
                              onTap: () {
                                if (id != null) context.push('/athlete/$id');
                              },
                              semanticLabel: 'View athlete profile of $name',
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                                    backgroundColor: AppTheme.elevatedSurface,
                                    child: avatar == null
                                        ? Text(
                                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                                            style: const TextStyle(
                                              fontFamily: AppTheme.fontDisplay,
                                              color: AppTheme.primaryAccent,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontFamily: AppTheme.fontBody,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimary,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (subtitle.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2.0),
                                            child: Text(
                                              subtitle,
                                              style: const TextStyle(
                                                fontFamily: AppTheme.fontBody,
                                                color: AppTheme.textSecondary,
                                                fontSize: 12,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 18),
                                ],
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
