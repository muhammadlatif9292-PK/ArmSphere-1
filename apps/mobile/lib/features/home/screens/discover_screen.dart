// lib/features/home/screens/discover_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/providers/athlete_provider.dart';
import '../../../core/providers/discover_provider.dart';
import '../../../core/providers/tournament_provider.dart';
import '../../../core/providers/venue_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/armsphere_image.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/main_shell_screen.dart';
import '../../../core/widgets/pulse_indicator.dart';
import '../../../core/widgets/skeleton_placeholder.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
import '../../../core/providers/visual_preferences_provider.dart';
import '../../../core/widgets/crystal_slash_painter.dart';
import '../../../core/widgets/crystal_stage_scaffold.dart';

/// Federation Discovery Segment Categories
enum DiscoverCategory {
  all('ALL', Icons.grid_view_rounded, 'Complete Federation Overview'),
  tournaments('TOURNAMENTS', Icons.emoji_events_outlined, 'Sanctioned Brackets & Events'),
  athletes('ATHLETES', Icons.person_outline, 'National ELO Standings & Roster'),
  clubsAndVenues('CLUBS & VENUES', Icons.storefront_outlined, 'Verified Training Tables & Gyms'),
  announcements('ANNOUNCEMENTS', Icons.campaign_outlined, 'Official Federation Bulletins');

  final String label;
  final IconData icon;
  final String description;
  const DiscoverCategory(this.label, this.icon, this.description);
}

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _activeQuery = '';
  DiscoverCategory _selectedCategory = DiscoverCategory.all;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final text = _searchController.text.trim();
    if (text == _activeQuery) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _activeQuery = text;
      });
      ref.read(athleteSearchQueryProvider.notifier).state = text;
    });
  }

  void _clearSearch() {
    HapticFeedback.selectionClick();
    _debounceTimer?.cancel();
    _searchController.clear();
    setState(() {
      _activeQuery = '';
    });
    ref.read(athleteSearchQueryProvider.notifier).state = '';
  }

  void _selectCategory(DiscoverCategory category) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedCategory = category;
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.lightImpact();
    ref.invalidate(discoverFeedProvider);
    ref.invalidate(tournamentProvider);
    ref.invalidate(venueListProvider);
    await ref.read(discoverFeedProvider.notifier).refresh();
  }

  void _showDirectoryQuickDrawer(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppTheme.elevatedSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
        side: BorderSide(color: AppTheme.border, width: 1),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.borderHighlight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0x80E23B3B),
                          width: 1.0,
                        ),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: AppTheme.primaryAccent,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Directory Navigator',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: AppTheme.border, height: 1),
                const SizedBox(height: 14),
                const Text(
                  'DISCOVER VIEW FOCUS',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMuted,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                ...DiscoverCategory.values.map((category) {
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _selectCategory(category);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0x80E23B3B)
                                : const Color(0x2EFFFFFF),
                            width: isSelected ? 1.2 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              category.icon,
                              size: 18,
                              color: isSelected ? AppTheme.primaryAccent : AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                category.label,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                  color: isSelected
                                      ? AppTheme.textPrimary
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppTheme.primaryAccent,
                                size: 18,
                              )
                            else
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppTheme.textMuted,
                                size: 18,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 10),
                const Text(
                  'DIRECT FEDERATION PORTALS',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMuted,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildDrawerQuickAction(
                        sheetContext,
                        icon: Icons.leaderboard_outlined,
                        label: 'Standings',
                        route: '/rankings',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDrawerQuickAction(
                        sheetContext,
                        icon: Icons.emoji_events_outlined,
                        label: 'Tournaments',
                        route: '/tournaments',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDrawerQuickAction(
                        sheetContext,
                        icon: Icons.storefront_outlined,
                        label: 'Venues',
                        route: '/venues',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDrawerQuickAction(
                        sheetContext,
                        icon: Icons.handshake_outlined,
                        label: 'Meetups',
                        route: '/informal-events',
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
  }

  Widget _buildDrawerQuickAction(
    BuildContext sheetContext, {
    required IconData icon,
    required String label,
    required String route,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      onTap: () {
        Navigator.of(sheetContext).pop();
        context.push(route);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(color: const Color(0x38FFFFFF), width: 1.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: AppTheme.secondaryAccent),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final discoverAsync = ref.watch(discoverFeedProvider);
    final tournamentsAsync = ref.watch(tournamentProvider);
    final venuesAsync = ref.watch(venueListProvider);
    final athleteSearchResults = ref.watch(athleteSearchProvider);

    final bool insideRootShell = MainShellScope.isInsideShell(context);
    final double bottomDockGap = insideRootShell
        ? (kFloatingDockTotalHeight + MediaQuery.paddingOf(context).bottom + 10.0)
        : 12.0;

    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: CrystalStageBackdrop(domain: ArmSphereStageDomain.discover),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Fixed Unified Top Search & Action Bar (48px height, padded 12px from top, 16px horizontal)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: _buildTopSearchAndActionBar(context),
                ),
                // Scrollable Body wrapped in 3D Vapor Dissolve & bounded 10px above Floating Bottom Nav Pill
                Expanded(
                  child: CrystalVaporDissolve(
                    bottomMargin: bottomDockGap,
                    child: RefreshIndicator(
                      color: AppTheme.primaryAccent,
                      backgroundColor: AppTheme.elevatedSurface,
                      onRefresh: _handleRefresh,
                      child: CustomScrollView(
                        key: const ValueKey<String>('discover_scroll_view'),
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: _buildFilterChips(),
                            ),
                          ),
                          // 90px open 3D stage showcase window above Federation Hub
                          if (_activeQuery.isEmpty)
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 90),
                            ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(
                              AppTheme.space16,
                              AppTheme.space12,
                              AppTheme.space16,
                              28.0,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: _activeQuery.isNotEmpty
                                  ? _buildSearchResults(
                                      context,
                                      athleteSearchResults,
                                      tournamentsAsync,
                                      venuesAsync,
                                    )
                                  : discoverAsync.when(
                                      data: (feed) => _buildFeedContent(
                                        context,
                                        feed,
                                        tournamentsAsync,
                                        venuesAsync,
                                      ),
                                      loading: () => _buildLoadingState(),
                                      error: (err, stack) =>
                                          _buildErrorState(err, _handleRefresh),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSearchAndActionBar(BuildContext context) {
    final BorderRadius searchRadius = BorderRadius.circular(24);
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          // 1. Expanded Crystal Search Bar (height: 48px, radius: 24, diagonal crimson/obsidian slash inside)
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: searchRadius,
                border: Border.all(
                  color: _activeQuery.isNotEmpty
                      ? const Color(0x99E23B3B)
                      : const Color(0x45FFFFFF),
                  width: 1.0,
                ),
                boxShadow: const [],
              ),
              child: CrystalSlashWrapper.sequentialRow(
                rowIndex: 0,
                intensity: 0.85,
                borderRadius: searchRadius,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontBody,
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    shadows: AppTheme.crystalTextShadows,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search athletes, tournaments, clubs...',
                    hintStyle: const TextStyle(
                      fontFamily: AppTheme.fontBody,
                      color: Color(0xFFCBD5E1),
                      fontSize: 12.5,
                      shadows: AppTheme.crystalTextShadows,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFFF1F5F9),
                      size: 19,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppTheme.textSecondary,
                              size: 16,
                            ),
                            onPressed: _clearSearch,
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 2. Circular Filter Icon Button (42x42)
          _buildTopCircleActionButton(
            icon: Icons.tune_rounded,
            tooltip: 'Directory Navigator',
            onTap: () => _showDirectoryQuickDrawer(context),
          ),
          const SizedBox(width: 8),
          // 3. Circular Notification Bell Icon Button (42x42, with crimson notification dot)
          _buildTopCircleActionButton(
            icon: Icons.notifications_outlined,
            tooltip: 'Notifications',
            showCrimsonDot: true,
            onTap: () => context.push('/notifications'),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCircleActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool showCrimsonDot = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: TactilePressWrapper(
        onTap: onTap,
        semanticLabel: tooltip,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0x45FFFFFF),
              width: 1.0,
            ),
            boxShadow: const [],
          ),
          child: CrystalSlashWrapper.sequentialRow(
            rowIndex: showCrimsonDot ? 2 : 1,
            intensity: 0.75,
            borderRadius: BorderRadius.circular(21),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: const Color(0xFFF1F5F9),
                  shadows: const [
                    Shadow(
                      color: Color(0xFF000000),
                      blurRadius: 6,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                if (showCrimsonDot)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 7.5,
                      height: 7.5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE23B3B),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF05070C),
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(AppTheme.space16, 2, AppTheme.space16, 8),
        itemCount: DiscoverCategory.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppTheme.space8),
        itemBuilder: (context, index) {
          final category = DiscoverCategory.values[index];
          final isSelected = _selectedCategory == category;
          final chipRadius = BorderRadius.circular(AppTheme.radiusSmall);

          return InkWell(
            onTap: () => _selectCategory(category),
            borderRadius: chipRadius,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: chipRadius,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFE23B3B)
                      : const Color(0x38FFFFFF),
                  width: isSelected ? 1.2 : 1.0,
                ),
              ),
              child: CrystalSlashWrapper.sequentialRow(
                rowIndex: index,
                intensity: isSelected ? 0.95 : 0.55,
                borderRadius: chipRadius,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSelected ? 11.8 : 12.0,
                    vertical: isSelected ? 4.8 : 5.0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        category.icon,
                        size: 13,
                        color: isSelected
                            ? const Color(0xFFD4AF37)
                            : const Color(0xFFF1F5F9),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        category.label,
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 11,
                          color: isSelected
                              ? AppTheme.textPure
                              : const Color(0xFFF1F5F9),
                          letterSpacing: 0.3,
                          shadows: AppTheme.crystalTextShadows,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchResults(
    BuildContext context,
    AsyncValue<List<Map<String, dynamic>>> athleteSearchResults,
    AsyncValue<List<Map<String, dynamic>>> tournamentsAsync,
    AsyncValue<List<Map<String, dynamic>>> venuesAsync,
  ) {
    final query = _activeQuery.toLowerCase();

    final allTournaments = tournamentsAsync.value ?? [];
    final matchingTournaments = allTournaments.where((t) {
      final name = (t['name'] ?? '').toString().toLowerCase();
      final location = (t['location'] ?? '').toString().toLowerCase();
      final city = (t['city'] ?? '').toString().toLowerCase();
      return name.contains(query) || location.contains(query) || city.contains(query);
    }).toList();

    final allVenues = venuesAsync.value ?? [];
    final matchingVenues = allVenues.where((v) {
      final name = (v['name'] ?? '').toString().toLowerCase();
      final city = (v['city'] ?? '').toString().toLowerCase();
      final address = (v['address'] ?? '').toString().toLowerCase();
      return name.contains(query) || city.contains(query) || address.contains(query);
    }).toList();

    return athleteSearchResults.when(
      data: (athletes) {
        final totalResults =
            athletes.length + matchingTournaments.length + matchingVenues.length;

        if (totalResults == 0) {
          return _FramedDirectorySection(
            title: 'Search Directory',
            subtitle: 'Query: "$_activeQuery"',
            icon: Icons.search_off_outlined,
            accentColor: AppTheme.primaryAccent,
            actionLabel: 'Clear Search',
            onActionTap: _clearSearch,
            child: _CompactEmptyBanner(
              icon: Icons.search_off_outlined,
              accentColor: AppTheme.primaryAccent,
              title: 'No matches for "$_activeQuery"',
              subtitle: 'Try searching by athlete name, city, or tournament title.',
              actionLabel: 'Reset',
              onAction: _clearSearch,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: AppTheme.space16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(color: const Color(0x38FFFFFF), width: 1.0),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.manage_search_rounded,
                    color: AppTheme.primaryAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Found $totalResults result${totalResults == 1 ? '' : 's'} for "$_activeQuery"',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _clearSearch,
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (athletes.isNotEmpty) ...[
              _FramedDirectorySection(
                title: 'Matching Athletes',
                subtitle: '${athletes.length} registered competitor${athletes.length == 1 ? '' : 's'}',
                icon: Icons.person_outline,
                accentColor: AppTheme.secondaryAccent,
                child: Column(
                  children: athletes
                      .map((athlete) => _buildAthleteSearchCard(context, athlete))
                      .toList(),
                ),
              ),
              const SizedBox(height: AppTheme.space16),
            ],
            if (matchingTournaments.isNotEmpty) ...[
              _FramedDirectorySection(
                title: 'Matching Tournaments',
                subtitle: '${matchingTournaments.length} sanctioned event${matchingTournaments.length == 1 ? '' : 's'}',
                icon: Icons.emoji_events_outlined,
                accentColor: AppTheme.primaryAccent,
                child: Column(
                  children: matchingTournaments
                      .map((t) => _buildTournamentCard(context, t))
                      .toList(),
                ),
              ),
              const SizedBox(height: AppTheme.space16),
            ],
            if (matchingVenues.isNotEmpty) ...[
              _FramedDirectorySection(
                title: 'Matching Venues & Gyms',
                subtitle: '${matchingVenues.length} verified table location${matchingVenues.length == 1 ? '' : 's'}',
                icon: Icons.storefront_outlined,
                accentColor: AppTheme.success,
                child: Column(
                  children: matchingVenues
                      .map((v) => _buildVenueCard(context, v))
                      .toList(),
                ),
              ),
            ],
          ],
        );
      },
      loading: () => _buildLoadingState(),
      error: (err, _) => Center(
        child: Text(
          'Search error: $err',
          style: const TextStyle(color: AppTheme.error),
        ),
      ),
    );
  }

  Widget _buildAthleteSearchCard(BuildContext context, Map<String, dynamic> athlete) {
    final id = athlete['id'] ?? athlete['athleteId'];
    final name = athlete['displayName'] ?? athlete['fullName'] ?? 'Athlete';
    final elo = athlete['eloRating'] ?? athlete['rating'];
    final division = athlete['division'] ?? athlete['weightClass'];
    final club = athlete['clubName'] ?? athlete['club'];

    return ElevatedActionCard(
      margin: const EdgeInsets.only(bottom: 8),
      slashVariant: const CrystalSlashVariant.sequentialRow(0),
      onTap: () {
        if (id != null) context.push('/athlete/$id');
      },
      semanticLabel: 'View profile of $name',
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x38FFFFFF), width: 1.0),
            ),
            child: const Icon(Icons.person, color: AppTheme.textSecondary, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toString(),
                  style: const TextStyle(
                    fontFamily: AppTheme.fontBody,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (division != null || club != null)
                  Text(
                    [division, club].where((e) => e != null).join(' • '),
                    style: const TextStyle(
                      fontFamily: AppTheme.fontBody,
                      color: AppTheme.textSecondary,
                      fontSize: 11.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (elo != null) ...[
            const SizedBox(width: 8),
            StatusChip(
              label: '$elo ELO',
              type: StatusType.info,
            ),
          ],
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 18),
        ],
      ),
    );
  }

  Widget _buildFeedContent(
    BuildContext context,
    dynamic feed,
    AsyncValue<List<Map<String, dynamic>>> tournamentsAsync,
    AsyncValue<List<Map<String, dynamic>>> venuesAsync,
  ) {
    final liveMatches = (feed['liveMatches'] as List?) ?? [];
    final announcements = (feed['announcements'] as List?) ?? [];
    final topAthletes = (feed['topAthletes'] as List?) ?? [];
    final recentMatches = (feed['recentCompletedMatches'] as List?) ?? [];

    final feedTournaments = (feed['upcomingTournaments'] as List?) ?? [];
    final providerTournaments = tournamentsAsync.value ?? [];
    final tournaments =
        feedTournaments.isNotEmpty ? feedTournaments : providerTournaments;

    final venues = venuesAsync.value ?? [];

    switch (_selectedCategory) {
      case DiscoverCategory.tournaments:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (liveMatches.isNotEmpty) ...[
              _buildLiveMatchesSection(context, liveMatches),
              const SizedBox(height: AppTheme.space16),
            ],
            _buildUpcomingTournamentsSection(
              context,
              tournaments,
              showAll: true,
            ),
            const SizedBox(height: AppTheme.space16),
            _buildRecentMatchesSection(context, recentMatches),
          ],
        );

      case DiscoverCategory.athletes:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopAthletesSection(context, topAthletes, showAll: true),
            const SizedBox(height: AppTheme.space16),
            _buildRecentMatchesSection(context, recentMatches),
          ],
        );

      case DiscoverCategory.clubsAndVenues:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVenuesSection(context, venues, showAll: true),
          ],
        );

      case DiscoverCategory.announcements:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnnouncementsSection(context, announcements, showAll: true),
          ],
        );

      case DiscoverCategory.all:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Fixed 2x2 Bento Grid (all 4 federation portals visible simultaneously)
            _buildFederationHubSection(context),
            const SizedBox(height: AppTheme.space16),

            // 2. Live Sanctioned Matches (only when live tables are active)
            if (liveMatches.isNotEmpty) ...[
              _buildLiveMatchesSection(context, liveMatches),
              const SizedBox(height: AppTheme.space16),
            ],

            // 3. Top Rankings Leaderboard (active populated data prioritized above empty modules)
            _buildTopAthletesSection(context, topAthletes, showAll: false),
            const SizedBox(height: AppTheme.space16),

            // 4. Sanctioned Tournaments Directory
            _buildUpcomingTournamentsSection(
              context,
              tournaments,
              showAll: false,
            ),
            const SizedBox(height: AppTheme.space16),

            // 5. Grassroots Training Venues Directory
            _buildVenuesSection(context, venues, showAll: false),
            const SizedBox(height: AppTheme.space16),

            // 6. Federation Bulletins
            _buildAnnouncementsSection(context, announcements, showAll: false),

            // 7. Recent Completed Matches (shown when match history exists)
            if (recentMatches.isNotEmpty) ...[
              const SizedBox(height: AppTheme.space16),
              _buildRecentMatchesSection(context, recentMatches),
            ],
          ],
        );
    }
  }

  /// Fixed 2x2 Bento Grid replacing the horizontally clipped carousel
  Widget _buildFederationHubSection(BuildContext context) {
    final hubItems = [
      _HubItem(
        title: 'Training Venues',
        subtitle: 'Verified clubs & tables',
        tag: 'DIRECTORY',
        icon: Icons.storefront_outlined,
        color: AppTheme.secondaryAccent,
        route: '/venues',
        bgAsset: ArmSphereAssets.resolveSemanticAsset(
          ArmSphereAssets.semanticDiscoverHubVenuesTile,
        ),
        bgAlignment: const Alignment(0.35, 0.0),
      ),
      _HubItem(
        title: 'Pickup Meetups',
        subtitle: 'Sparring & roll calls',
        tag: 'SPARRING',
        icon: Icons.handshake_outlined,
        color: AppTheme.success,
        route: '/informal-events',
        bgAsset: ArmSphereAssets.resolveSemanticAsset(
          ArmSphereAssets.semanticDiscoverHubPickupMeetupsTile,
        ),
        bgAlignment: const Alignment(0.30, -0.15),
      ),
      _HubItem(
        title: 'Community Feed',
        subtitle: 'Technique clips & chats',
        tag: 'SOCIAL',
        icon: Icons.forum_outlined,
        color: AppTheme.info,
        route: '/community',
        bgAsset: ArmSphereAssets.resolveSemanticAsset(
          ArmSphereAssets.semanticDiscoverHubCommunityFeedTile,
        ),
        bgAlignment: const Alignment(0.30, -0.15),
      ),
      _HubItem(
        title: 'ELO Rankings',
        subtitle: 'National leaderboards',
        tag: 'STANDINGS',
        icon: Icons.leaderboard_outlined,
        color: AppTheme.warning,
        route: '/rankings',
        bgAsset: ArmSphereAssets.resolveSemanticAsset(
          ArmSphereAssets.semanticDiscoverHubEloRankingsTile,
        ),
        bgAlignment: const Alignment(0.35, -0.10),
      ),
    ];

    // Unbundled 2x2 Bento Grid rendered directly on the stage with 14px spacing
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, right: 2, bottom: 10),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Federation Hub',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              InkWell(
                onTap: () => _showDirectoryQuickDrawer(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(color: const Color(0x73D4AF37), width: 1.0),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'All Portals',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: AppTheme.goldPrimary,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: AppTheme.goldPrimary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(child: _buildBentoPortalTile(context, hubItems[0])),
            const SizedBox(width: 14),
            Expanded(child: _buildBentoPortalTile(context, hubItems[1])),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildBentoPortalTile(context, hubItems[2])),
            const SizedBox(width: 14),
            Expanded(child: _buildBentoPortalTile(context, hubItems[3])),
          ],
        ),
      ],
    );
  }

  Widget _buildBentoPortalTile(BuildContext context, _HubItem item) {
    return TactilePressWrapper(
      onTap: () => context.push(item.route),
      semanticLabel: item.title,
      child: Container(
        height: 132,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0x38FFFFFF),
            width: 1.0,
          ),
          boxShadow: const [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              // Per-tile 100% crystal-clear artwork & compact bottom-third readability gradient (y: 0.62 to 1.0)
              Positioned.fill(
                child: IgnorePointer(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ArmSphereImage(
                        assetPath: item.bgAsset,
                        fit: BoxFit.cover,
                        alignment: item.bgAlignment,
                        excludeFromSemantics: true,
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0.0, 0.62, 1.0],
                            colors: [
                              Color(0x00000000),
                              Color(0x00000000),
                              Color(0x99000000),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Specular top-edge hairline
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0x00DAE2EB),
                        Color(0x40DAE2EB),
                        Color(0x00DAE2EB),
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              // Clean bold title ONLY — zero category pills, zero subtexts, zero extra icons
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: AppTheme.textPure,
                    letterSpacing: -0.1,
                    shadows: AppTheme.crystalTextShadows,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveMatchesSection(BuildContext context, List<dynamic> liveMatches) {
    return _FramedDirectorySection(
      title: 'Live Matches',
      icon: Icons.sensors_rounded,
      accentColor: AppTheme.primaryAccent,
      leadingBadge: const PulseIndicator(size: 8.0),
      child: Column(
        children: liveMatches.map((m) {
          final match = m as Map<String, dynamic>;
          final matchId = match['id'];
          final status = match['status'] ?? 'LIVE';
          final athleteA = match['athleteAName'] ?? 'Athlete A';
          final athleteB = match['athleteBName'] ?? 'Athlete B';
          final scoreA = match['scoreA'] ?? 0;
          final scoreB = match['scoreB'] ?? 0;
          final tableNumber = match['tableNumber'];

          return ElevatedActionCard(
            margin: const EdgeInsets.only(bottom: 8),
            onTap: () {
              if (matchId != null) {
                context.push('/matches/$matchId/live');
              }
            },
            semanticLabel:
                'Live match: $athleteA versus $athleteB, score $scoreA to $scoreB',
            borderColor: AppTheme.primaryAccent.withValues(alpha: 0.4),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StatusChip.live(
                      label: status.toString(),
                    ),
                    if (tableNumber != null)
                      Text(
                        'Table $tableNumber',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        athleteA.toString(),
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        border: Border.all(color: const Color(0x38FFFFFF), width: 1.0),
                      ),
                      child: Text(
                        '$scoreA  -  $scoreB',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          color: AppTheme.secondaryAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        athleteB.toString(),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAnnouncementsSection(
    BuildContext context,
    List<dynamic> announcements, {
    required bool showAll,
  }) {
    final displayed =
        showAll ? announcements : announcements.take(3).toList();

    return _FramedDirectorySection(
      title: 'Bulletins',
      icon: Icons.campaign_outlined,
      accentColor: AppTheme.secondaryAccent,
      actionLabel: showAll ? 'Notifications' : 'View All',
      onActionTap: () {
        if (showAll) {
          context.push('/notifications');
        } else {
          _selectCategory(DiscoverCategory.announcements);
        }
      },
      child: displayed.isEmpty
          ? _CompactEmptyBanner(
              icon: Icons.campaign_outlined,
              accentColor: AppTheme.secondaryAccent,
              title: 'No bulletins yet',
              actionLabel: 'Bulletins',
              onAction: () => context.push('/notifications'),
            )
          : Column(
              children: displayed.map((a) {
                final ann = a as Map<String, dynamic>;
                final isPinned = ann['isPinned'] == true;
                final title = ann['title'] ?? 'Announcement';
                final body = ann['body'] ?? '';

                return ElevatedActionCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  onTap: () => _showAnnouncementDetailModal(context, ann),
                  semanticLabel: 'Bulletin: $title',
                  borderColor: isPinned
                      ? AppTheme.secondaryAccent.withValues(alpha: 0.4)
                      : AppTheme.border,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isPinned ? Icons.push_pin : Icons.campaign_outlined,
                            color: isPinned
                                ? AppTheme.secondaryAccent
                                : AppTheme.primaryAccent,
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              title.toString(),
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isPinned)
                            const StatusChip.warning(
                              label: 'PINNED',
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        body.toString(),
                        style: const TextStyle(
                          fontFamily: AppTheme.fontBody,
                          color: AppTheme.textSecondary,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                        maxLines: showAll ? 5 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  void _showAnnouncementDetailModal(
      BuildContext context, Map<String, dynamic> ann) {
    final title = ann['title'] ?? 'Federation Bulletin';
    final body = ann['body'] ?? '';
    final isPinned = ann['isPinned'] == true;

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CrystalModalSheet(
        title: title.toString(),
        headerIcon: isPinned ? Icons.push_pin_rounded : Icons.campaign_outlined,
        primaryActionLabel: 'Close Bulletin',
        onPrimaryAction: () => Navigator.of(ctx).pop(),
        child: Text(
          body.toString(),
          style: const TextStyle(
            fontFamily: AppTheme.fontBody,
            color: AppTheme.textSecondary,
            fontSize: 13.5,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingTournamentsSection(
    BuildContext context,
    List<dynamic> tournaments, {
    required bool showAll,
  }) {
    final displayed =
        showAll ? tournaments : tournaments.take(3).toList();

    return _FramedDirectorySection(
      title: 'Tournaments',
      icon: Icons.emoji_events_outlined,
      accentColor: AppTheme.primaryAccent,
      actionLabel: 'All Events',
      onActionTap: () => context.push('/tournaments'),
      child: displayed.isEmpty
          ? _CompactEmptyBanner(
              icon: Icons.emoji_events_outlined,
              accentColor: AppTheme.secondaryAccent,
              title: 'No tournaments scheduled',
              actionLabel: 'Explore',
              onAction: () => context.push('/tournaments'),
            )
          : Column(
              children: displayed
                  .map((t) =>
                      _buildTournamentCard(context, t as Map<String, dynamic>))
                  .toList(),
            ),
    );
  }

  Widget _buildTournamentCard(
      BuildContext context, Map<String, dynamic> tournament) {
    final id = tournament['id'];
    final name = tournament['name'] ?? 'Tournament';
    final status = tournament['status'] ?? 'UPCOMING';
    final location =
        tournament['location'] ?? tournament['city'] ?? 'Pakistan';
    final startDate = tournament['startDate'] != null
        ? tournament['startDate'].toString().split('T').first
        : null;

    return ElevatedActionCard(
      margin: const EdgeInsets.only(bottom: 8),
      slashVariant: const CrystalSlashVariant.sequentialRow(1),
      onTap: () {
        if (id != null) {
          context.push('/tournaments/$id');
        } else {
          context.push('/tournaments');
        }
      },
      semanticLabel: 'Tournament: $name in $location',
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0x80E23B3B), width: 1.0),
            ),
            child: const Icon(
              Icons.emoji_events_outlined,
              color: AppTheme.primaryAccent,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toString(),
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  startDate != null ? '$location • $startDate' : '$location',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontBody,
                    color: AppTheme.textSecondary,
                    fontSize: 11.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusChip(
            label: status.toString(),
            type: (status == 'LIVE' || status == 'ACTIVE')
                ? StatusType.live
                : StatusType.info,
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 18),
        ],
      ),
    );
  }

  Widget _buildVenuesSection(
    BuildContext context,
    List<Map<String, dynamic>> venues, {
    required bool showAll,
  }) {
    final displayed = showAll ? venues : venues.take(3).toList();

    return _FramedDirectorySection(
      title: 'Training Venues',
      icon: Icons.storefront_outlined,
      accentColor: AppTheme.success,
      actionLabel: 'Directory',
      onActionTap: () => context.push('/venues'),
      child: displayed.isEmpty
          ? _CompactEmptyBanner(
              icon: Icons.storefront_outlined,
              accentColor: AppTheme.secondaryAccent,
              title: 'No venues listed yet',
              actionLabel: 'Venues',
              onAction: () => context.push('/venues'),
            )
          : Column(
              children: displayed
                  .map((v) => _buildVenueCard(context, v))
                  .toList(),
            ),
    );
  }

  Widget _buildVenueCard(BuildContext context, Map<String, dynamic> venue) {
    final id = venue['id'];
    final name = venue['name'] ?? 'Training Venue';
    final city = venue['city'] ?? 'Pakistan';
    final tableCount = venue['tableCount'] ?? venue['tablesCount'] ?? 1;
    final isVerified = venue['isVerified'] == true;

    return ElevatedActionCard(
      margin: const EdgeInsets.only(bottom: 8),
      slashVariant: const CrystalSlashVariant.sequentialRow(2),
      onTap: () {
        if (id != null) {
          context.push('/venues/$id');
        } else {
          context.push('/venues');
        }
      },
      semanticLabel: 'Venue: $name in $city',
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0x73D4AF37), width: 1.0),
            ),
            child: const Icon(
              Icons.storefront_outlined,
              color: AppTheme.secondaryAccent,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name.toString(),
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.verified,
                        color: AppTheme.secondaryAccent,
                        size: 14,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '$city • $tableCount Table${tableCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontBody,
                    color: AppTheme.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 18),
        ],
      ),
    );
  }

  Widget _buildTopAthletesSection(
    BuildContext context,
    List<dynamic> topAthletes, {
    required bool showAll,
  }) {
    final displayed =
        showAll ? topAthletes : topAthletes.take(5).toList();

    return _FramedDirectorySection(
      title: 'Top Rankings',
      icon: Icons.leaderboard_outlined,
      accentColor: AppTheme.secondaryAccent,
      actionLabel: 'Full Rankings',
      onActionTap: () => context.push('/rankings'),
      child: displayed.isEmpty
          ? _CompactEmptyBanner(
              icon: Icons.leaderboard_outlined,
              accentColor: AppTheme.secondaryAccent,
              title: 'Rankings initializing',
              actionLabel: 'Standings',
              onAction: () => context.push('/rankings'),
            )
          : Column(
              children: List.generate(displayed.length, (idx) {
                final athlete = displayed[idx] as Map<String, dynamic>;
                final athleteId = athlete['athleteId'] ?? athlete['id'];
                final rank = athlete['rank'] ?? (idx + 1);
                final name = athlete['displayName'] ?? 'Athlete';
                final division =
                    athlete['division'] ?? athlete['weightClass'] ?? 'Open';
                final elo = athlete['eloRating'] ?? 1200;
                final isLast = idx == displayed.length - 1;

                return ElevatedActionCard(
                  margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
                  backgroundColor: Colors.transparent,
                  borderRadius: 14,
                  slashVariant: CrystalSlashVariant.sequentialRow(idx),
                  borderColor: idx == 0
                      ? const Color(0x73D4AF37)
                      : const Color(0x38FFFFFF),
                  boxShadow: const [],
                  onTap: () {
                    if (athleteId != null) {
                      context.push('/athlete/$athleteId');
                    } else {
                      context.push('/rankings');
                    }
                  },
                  semanticLabel:
                      'Rank $rank: $name, $division division, $elo ELO',
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: idx < 3
                                ? const Color(0x73D4AF37)
                                : const Color(0x38FFFFFF),
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          '#$rank',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            color: idx < 3
                                ? AppTheme.secondaryAccent
                                : AppTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.toString(),
                              style: const TextStyle(
                                fontFamily: AppTheme.fontBody,
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              division.toString().toUpperCase(),
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                color: AppTheme.textSecondary,
                                fontSize: 10.5,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusChip(
                        label: '$elo ELO',
                        type: StatusType.info,
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.chevron_right,
                        color: AppTheme.textMuted,
                        size: 16,
                      ),
                    ],
                  ),
                );
              }),
            ),
    );
  }

  Widget _buildRecentMatchesSection(
      BuildContext context, List<dynamic> recentMatches) {
    return _FramedDirectorySection(
      title: 'Recent Matches',
      icon: Icons.history_rounded,
      accentColor: AppTheme.success,
      child: recentMatches.isEmpty
          ? const _CompactEmptyBanner(
              icon: Icons.history_rounded,
              accentColor: AppTheme.textSecondary,
              title: 'No recent match results',
            )
          : Column(
              children: recentMatches.map((m) {
                final match = m as Map<String, dynamic>;
                final matchId = match['id'];
                final athleteA = match['athleteAName'] ?? 'Athlete A';
                final athleteB = match['athleteBName'] ?? 'Athlete B';
                final scoreLine = match['scoreLine'] ?? '3-0';

                return ElevatedActionCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  onTap: () {
                    if (matchId != null) {
                      context.push('/matches/$matchId/live');
                    }
                  },
                  semanticLabel:
                      'Completed match: $athleteA versus $athleteB, scoreline $scoreLine',
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '$athleteA vs $athleteB',
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const StatusChip.success(
                            label: 'FINAL',
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Scoreline',
                            style: TextStyle(
                              fontFamily: AppTheme.fontBody,
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            scoreLine.toString(),
                            style: const TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              color: AppTheme.success,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonPlaceholder(height: 180),
          const SizedBox(height: AppTheme.space16),
          const SkeletonPlaceholder(height: 150),
          const SizedBox(height: AppTheme.space16),
          ...List.generate(
            3,
            (idx) => const Padding(
              padding: EdgeInsets.only(bottom: AppTheme.space8),
              child: SkeletonPlaceholder(height: 72),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error, VoidCallback onRetry) {
    return _FramedDirectorySection(
      title: 'Connection Interrupted',
      icon: Icons.error_outline,
      accentColor: AppTheme.primaryAccent,
      actionLabel: 'Retry',
      onActionTap: onRetry,
      child: _CompactEmptyBanner(
        icon: Icons.wifi_off_rounded,
        accentColor: AppTheme.primaryAccent,
        title: 'Failed to load Discover Feed',
        actionLabel: 'Retry',
        onAction: onRetry,
      ),
    );
  }
}

/// Framed container card that visually separates each Discover section
/// with a distinct border, elevated header bar, and internal padding.
class _FramedDirectorySection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color accentColor;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final Widget? leadingBadge;
  final Widget child;

  const _FramedDirectorySection({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.accentColor,
    this.actionLabel,
    this.onActionTap,
    this.leadingBadge,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.machinedTitaniumDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header Bar (Clean single-line heading, no verbose subtitle)
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 11),
            decoration: const BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(17),
              ),
              border: Border(
                bottom: BorderSide(color: Color(0x22FFFFFF), width: 1.0),
              ),
            ),
            child: Row(
              children: [
                if (leadingBadge != null) ...[
                  leadingBadge!,
                  const SizedBox(width: 8),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.55),
                        width: 1.0,
                      ),
                    ),
                    child: Icon(icon, size: 15, color: accentColor),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                if (actionLabel != null && onActionTap != null) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onActionTap,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        border: Border.all(
                          color: accentColor == AppTheme.secondaryAccent
                              ? const Color(0x73D4AF37)
                              : accentColor.withValues(alpha: 0.55),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            actionLabel!,
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 10,
                            color: accentColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Section Content Body
          Padding(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Compact empty-state row (single-line heading + optional action pill, zero verbose filler text)
class _CompactEmptyBanner extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _CompactEmptyBanner({
    required this.icon,
    required this.accentColor,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius bannerRadius = BorderRadius.circular(14);
    return Container(
      width: double.infinity,
      decoration: AppTheme.recessedObsidianWellDecoration(radius: 14),
      child: CrystalSlashWrapper.sequentialRow(
        rowIndex: title.hashCode % 4,
        borderRadius: bannerRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.45),
                    width: 1.0,
                  ),
                ),
                child: Icon(icon, color: accentColor, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                    shadows: AppTheme.crystalTextShadows,
                  ),
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: onAction,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.55),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          actionLabel!,
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 9,
                          color: accentColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper model for Federation Hub quick portal tiles
class _HubItem {
  final String title;
  final String subtitle;
  final String tag;
  final IconData icon;
  final Color color;
  final String route;
  final String bgAsset;
  final Alignment bgAlignment;

  _HubItem({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.icon,
    required this.color,
    required this.route,
    required this.bgAsset,
    this.bgAlignment = Alignment.center,
  });
}
