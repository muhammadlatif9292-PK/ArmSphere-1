import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/providers/rankings_provider.dart';
import '../../../../core/theme/app_theme.dart';

class RankingsScreen extends ConsumerStatefulWidget {
  const RankingsScreen({super.key});

  @override
  ConsumerState<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends ConsumerState<RankingsScreen> {
  static const _provinces = <String>[
    'Punjab',
    'Sindh',
    'Khyber Pakhtunkhwa',
    'Balochistan',
    'Gilgit-Baltistan',
    'Azad Kashmir',
    'Islamabad Capital Territory',
  ];

  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(rankingsSearchQueryProvider);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    setState(() {});
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(rankingsSearchQueryProvider.notifier).state = value.trim();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rankingsAsync = ref.watch(rankingsProvider);
    final arm = ref.watch(rankingsArmProvider);
    final province = ref.watch(rankingsProvinceProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard & Rankings')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _debounce?.cancel();
                          ref.read(rankingsSearchQueryProvider.notifier).state = '';
                          setState(() {});
                        },
                      )
                    : null,
                isDense: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'RIGHT', label: Text('Right Arm')),
                      ButtonSegment(value: 'LEFT', label: Text('Left Arm')),
                    ],
                    selected: {arm},
                    onSelectionChanged: (selection) =>
                        ref.read(rankingsArmProvider.notifier).state = selection.first,
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: DropdownButton<String>(
                value: province.isEmpty ? null : province,
                hint: const Text('All provinces', style: TextStyle(fontSize: 13)),
                underline: const SizedBox.shrink(),
                isDense: true,
                items: [
                  for (final p in _provinces)
                    DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13))),
                ],
                onChanged: (value) => ref.read(rankingsProvinceProvider.notifier).state = value ?? '',
              ),
            ),
          ),
          if (province.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  label: Text('Province: $province', style: const TextStyle(fontSize: 11)),
                  onDeleted: () => ref.read(rankingsProvinceProvider.notifier).state = '',
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(rankingsProvider),
              child: rankingsAsync.when(
                data: (rankings) {
                  if (rankings.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.emoji_events_outlined, size: 48, color: Colors.grey),
                              SizedBox(height: 12),
                              Text('No ranked athletes match these filters',
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: rankings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final athlete = rankings[index];
                      final rank = athlete['rank'] as int? ?? (index + 1);
                      final name = athlete['displayName'] as String? ?? 'Unknown Athlete';
                      final eloRating = athlete['eloRating'] as int? ?? 0;
                      final provinceValue = athlete['province'] as String?;
                      final weightClass = athlete['weightClass'] as String?;

                      Color rankColor = Colors.grey;
                      if (rank == 1) {
                        rankColor = Colors.amber;
                      } else if (rank == 2) {
                        rankColor = Colors.grey.shade400;
                      } else if (rank == 3) {
                        rankColor = Colors.brown.shade400;
                      }

                      return GestureDetector(
                        onTap: () {
                          final athleteId = athlete['athleteId'] as String? ?? '';
                          if (athleteId.isNotEmpty) {
                            context.push('/athlete/$athleteId');
                          }
                        },
                        child: GlassCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: rankColor.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '$rank',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: rankColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                                child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'A'),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      [
                                        if (weightClass != null && weightClass.isNotEmpty && weightClass != 'OPEN')
                                          weightClass,
                                        if (provinceValue != null && provinceValue.isNotEmpty) provinceValue,
                                      ].join(' • '),
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$eloRating',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    '$arm ELO',
                                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                error: (err, stack) => ListView(
                  children: [
                    const SizedBox(height: 100),
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.error_outline, size: 44, color: AppTheme.error),
                          const SizedBox(height: 12),
                          Text('Error loading rankings: $err',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppTheme.error)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => ref.invalidate(rankingsProvider),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
