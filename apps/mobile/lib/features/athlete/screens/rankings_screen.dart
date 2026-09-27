import 'dart:async';
import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/providers/rankings_provider.dart';
import '../../../core/theme/app_theme.dart';

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
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(rankingsSearchQueryProvider.notifier).state = value.trim();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return AppTheme.goldPrimary;
      case 2:
        return const Color(0xFFCBD5E1); // Silver
      case 3:
        return const Color(0xFFD97706); // Bronze
      default:
        return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rankingsAsync = ref.watch(rankingsProvider);
    final arm = ref.watch(rankingsArmProvider);
    final province = ref.watch(rankingsProvinceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard & Rankings'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppTheme.space16, AppTheme.space12, AppTheme.space16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search athletes by ring or real name...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                        onPressed: () {
                          HapticFeedback.lightImpact();
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
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space10),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'RIGHT', label: Text('Right Arm')),
                      ButtonSegment(value: 'LEFT', label: Text('Left Arm')),
                    ],
                    selected: {arm},
                    onSelectionChanged: (selection) {
                      HapticFeedback.lightImpact();
                      ref.read(rankingsArmProvider.notifier).state = selection.first;
                    },
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      textStyle: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppTheme.space16, 0, AppTheme.space16, AppTheme.space8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12, vertical: AppTheme.space6),
                  decoration: BoxDecoration(
                    color: AppTheme.cardSurface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: province.isEmpty ? null : province,
                      hint: const Text('All Provinces', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      isDense: true,
                      dropdownColor: AppTheme.cardSurface,
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text('All Provinces', style: TextStyle(fontSize: 12)),
                        ),
                        for (final p in _provinces)
                          DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 12))),
                      ],
                      onChanged: (value) {
                        HapticFeedback.lightImpact();
                        ref.read(rankingsProvinceProvider.notifier).state = value ?? '';
                      },
                    ),
                  ),
                ),
                if (province.isNotEmpty) ...[
                  const SizedBox(width: AppTheme.space8),
                  InputChip(
                    label: Text(province, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    onDeleted: () {
                      HapticFeedback.lightImpact();
                      ref.read(rankingsProvinceProvider.notifier).state = '';
                    },
                    backgroundColor: AppTheme.primaryRed.withValues(alpha: 0.15),
                    deleteIconColor: AppTheme.primaryRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      side: BorderSide(color: AppTheme.primaryRed.withValues(alpha: 0.3)),
                    ),
                  ),
                ],
              ],
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
                              Icon(Icons.emoji_events_outlined, size: 48, color: AppTheme.textMuted),
                              SizedBox(height: 12),
                              Text(
                                'No ranked athletes match these filters',
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    key: const PageStorageKey<String>('rankings_list_view'),
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space8),
                    itemCount: rankings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppTheme.space10),
                    itemBuilder: (context, index) {
                      final athlete = rankings[index];
                      final rank = athlete['rank'] as int? ?? (index + 1);
                      final name = athlete['displayName'] as String? ?? 'Unknown Athlete';
                      final eloRating = athlete['eloRating'] as int? ?? 0;
                      final provinceValue = athlete['province'] as String?;
                      final weightClass = athlete['weightClass'] as String?;
                      final color = _rankColor(rank);

                      return RepaintBoundary(
                        child: ElevatedActionCard(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            final athleteId = athlete['athleteId'] as String? ?? '';
                            if (athleteId.isNotEmpty) {
                              context.push('/athlete/$athleteId');
                            }
                          },
                          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space14, vertical: AppTheme.space12),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                  border: Border.all(
                                    color: color.withValues(alpha: rank <= 3 ? 0.4 : 0.2),
                                    width: rank <= 3 ? 1.5 : 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '$rank',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: color,
                                      fontFeatures: const [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppTheme.space12),
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppTheme.primaryRed.withValues(alpha: 0.15),
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'A',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryRed),
                                ),
                              ),
                              const SizedBox(width: AppTheme.space12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: AppTheme.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: AppTheme.space4),
                                    Text(
                                      [
                                        if (weightClass != null && weightClass.isNotEmpty && weightClass != 'OPEN')
                                          weightClass,
                                        if (provinceValue != null && provinceValue.isNotEmpty) provinceValue,
                                      ].join(' • '),
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppTheme.space8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$eloRating',
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppTheme.goldPrimary,
                                      fontFeatures: [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                  Text(
                                    '$arm ELO',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textMuted,
                                      letterSpacing: 0.5,
                                    ),
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
                          const Icon(Icons.error_outline, size: 44, color: AppTheme.error),
                          const SizedBox(height: 12),
                          Text('Error loading rankings: $err',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppTheme.error)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              ref.invalidate(rankingsProvider);
                            },
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
