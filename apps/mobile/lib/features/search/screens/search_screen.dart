import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/athlete_provider.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/skeleton_placeholder.dart';
import '../../../core/theme/app_theme.dart';

/// Domain 2 / Stage 6 Convergence: Global Search Screen
///
/// Implements Canonical Search & Discover Architecture:
/// - 300ms Riverpod debouncing with automatic query synchronization.
/// - Tactical search input with clear button ('X'), inline micro-spinner, and Champagne Gold focus ring.
/// - Standardized 15-degree skeleton shimmer loading states (`SkeletonPlaceholder`).
/// - Tabular monospace figures (`FontFeature.tabularFigures()`) across weight classes and rankings.
/// - RepaintBoundary raster isolation across all search result cards.
/// - Tactile haptic feedback on clear and result selection.
class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onQueryChanged);
  }

  void _onQueryChanged() {
    final text = _searchController.text;
    final hasNow = text.trim().isNotEmpty;
    if (hasNow != _hasText) {
      setState(() {
        _hasText = hasNow;
      });
    }

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        ref.read(athleteSearchQueryProvider.notifier).state = text.trim();
      }
    });
  }

  void _clearSearch() {
    HapticFeedback.selectionClick();
    _debounce?.cancel();
    _searchController.clear();
    setState(() {
      _hasText = false;
    });
    ref.read(athleteSearchQueryProvider.notifier).state = '';
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
    final isLoading = resultsAsync.isLoading;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: const Text(
          'SEARCH ATHLETES',
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            // ── Tactical Search Input Bar ────────────────────────────────────
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.cardSurface,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(color: AppTheme.borderSubtle, width: 1.0),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search by athlete name or weight...',
                  hintStyle: const TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 13,
                    color: AppTheme.textMuted,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppTheme.goldPrimary,
                    size: 20,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.8,
                              color: AppTheme.goldPrimary,
                            ),
                          ),
                        ),
                      if (_hasText)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textMuted),
                          tooltip: 'Clear search',
                          onPressed: _clearSearch,
                        ),
                    ],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Search State Viewport ────────────────────────────────────────
            Expanded(
              child: !hasQuery
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.elevatedSurface,
                              border: Border.all(
                                color: AppTheme.goldPrimary.withValues(alpha: 0.3),
                                width: 1.2,
                              ),
                            ),
                            child: const Icon(
                              Icons.travel_explore_rounded,
                              size: 32,
                              color: AppTheme.goldPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'FIND FEDERATION ATHLETES',
                            style: TextStyle(
                              fontFamily: 'Space Grotesk',
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              letterSpacing: 0.6,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Search by first name, last name, province, or weight class.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    )
                  : resultsAsync.when(
                      loading: () => ListView.separated(
                        itemCount: 5,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, __) => const RepaintBoundary(
                          child: SkeletonPlaceholder(
                            height: 72,
                            borderRadius: AppTheme.radiusSmall,
                          ),
                        ),
                      ),
                      error: (error, _) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 44, color: AppTheme.error),
                            const SizedBox(height: 12),
                            Text(
                              'Search query failed',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontFamily: 'Space Grotesk',
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$error',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.goldPrimary,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                ),
                              ),
                              onPressed: () => ref.invalidate(athleteSearchProvider),
                              child: const Text(
                                'Retry Search',
                                style: TextStyle(
                                  fontFamily: 'Space Grotesk',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      data: (rows) {
                        if (rows.isEmpty) {
                          return const AppEmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'No athletes match your query',
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
                            final weightClass = _field(row, ['weightClass']) ?? '';
                            final province = _field(row, ['province']) ?? '';

                            return RepaintBoundary(
                              child: ElevatedActionCard(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  if (id != null) context.push('/athlete/$id');
                                },
                                semanticLabel: 'View athlete profile of $name',
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: Row(
                                  children: [
                                    // Role Ring Avatar
                                    Container(
                                      padding: const EdgeInsets.all(1.5),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppTheme.goldPrimary.withValues(alpha: 0.6),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 20,
                                        backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                                        backgroundColor: AppTheme.elevatedSurface,
                                        child: avatar == null
                                            ? Text(
                                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                                style: const TextStyle(
                                                  fontFamily: 'Space Grotesk',
                                                  color: AppTheme.goldPrimary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              fontFamily: 'Space Grotesk',
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.textPrimary,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              if (weightClass.isNotEmpty)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 6, vertical: 1.5),
                                                  margin: const EdgeInsets.only(right: 6),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.elevatedSurface,
                                                    borderRadius: BorderRadius.circular(3),
                                                    border: Border.all(
                                                      color: AppTheme.borderSubtle,
                                                      width: 0.6,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    weightClass,
                                                    style: const TextStyle(
                                                      fontFamily: 'Space Grotesk',
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      fontFeatures: [FontFeature.tabularFigures()],
                                                      color: AppTheme.goldPrimary,
                                                    ),
                                                  ),
                                                ),
                                              if (province.isNotEmpty)
                                                Text(
                                                  province,
                                                  style: const TextStyle(
                                                    fontFamily: 'Inter',
                                                    color: AppTheme.textMuted,
                                                    fontSize: 11.5,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppTheme.textMuted,
                                      size: 20,
                                    ),
                                  ],
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
