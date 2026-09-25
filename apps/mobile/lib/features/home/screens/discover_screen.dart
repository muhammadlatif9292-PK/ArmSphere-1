import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/athlete_provider.dart';
import '../../../core/providers/discover_provider.dart';
import '../../../core/providers/tournament_provider.dart';
import '../../../core/providers/venue_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/pulse_indicator.dart';
import '../../../core/widgets/skeleton_placeholder.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';

/// Federation Discovery Segment Categories
enum DiscoverCategory {
  all('ALL', Icons.explore_outlined),
  tournaments('TOURNAMENTS', Icons.emoji_events_outlined),
  athletes('ATHLETES', Icons.person_outline),
  clubsAndVenues('CLUBS & VENUES', Icons.storefront_outlined),
  announcements('ANNOUNCEMENTS', Icons.campaign_outlined);

  final String label;
  final IconData icon;
  const DiscoverCategory(this.label, this.icon);
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

  @override
  Widget build(BuildContext context) {
    final discoverAsync = ref.watch(discoverFeedProvider);
    final tournamentsAsync = ref.watch(tournamentProvider);
    final venuesAsync = ref.watch(venueListProvider);
    final athleteSearchResults = ref.watch(athleteSearchProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(
                  color: AppTheme.primaryAccent.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.explore_outlined,
                color: AppTheme.primaryAccent,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ArmSphere Discover',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'Sanctioned Federation Hub',
                  style: TextStyle(
                    fontFamily: AppTheme.fontBody,
                    fontSize: 10,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: AppTheme.elevatedSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppTheme.textSecondary),
            tooltip: 'Notifications',
            onPressed: () => context.push('/notifications'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryAccent,
        backgroundColor: AppTheme.elevatedSurface,
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickySearchHeaderDelegate(
                searchBar: _buildSearchBar(),
                filterChips: _buildFilterChips(),
                height: 104.0,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(AppTheme.space16),
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
                        error: (err, stack) => _buildErrorState(err, _handleRefresh),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: 6.0),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(
            color: _activeQuery.isNotEmpty ? AppTheme.primaryAccent : AppTheme.border,
            width: 1.0,
          ),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(
            fontFamily: AppTheme.fontBody,
            color: AppTheme.textPrimary,
            fontSize: 13,
          ),
          decoration: InputDecoration(
            hintText: 'Search athletes, tournaments, clubs...',
            hintStyle: const TextStyle(
              fontFamily: AppTheme.fontBody,
              color: AppTheme.textMuted,
              fontSize: 12.5,
            ),
            prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary, size: 18),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 16),
                    onPressed: _clearSearch,
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: 4.0),
        itemCount: DiscoverCategory.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppTheme.space8),
        itemBuilder: (context, index) {
          final category = DiscoverCategory.values[index];
          final isSelected = _selectedCategory == category;

          return InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedCategory = category;
              });
            },
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryAccent : AppTheme.cardSurface,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryAccent : AppTheme.border,
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category.icon,
                    size: 13,
                    color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    category.label,
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 11,
                      color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                      letterSpacing: 0.3,
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

  Widget _buildSearchResults(
    BuildContext context,
    AsyncValue<List<Map<String, dynamic>>> athleteSearchResults,
    AsyncValue<List<Map<String, dynamic>>> tournamentsAsync,
    AsyncValue<List<Map<String, dynamic>>> venuesAsync,
  ) {
    final query = _activeQuery.toLowerCase();

    // Filter tournaments matching query
    final allTournaments = tournamentsAsync.value ?? [];
    final matchingTournaments = allTournaments.where((t) {
      final name = (t['name'] ?? '').toString().toLowerCase();
      final location = (t['location'] ?? '').toString().toLowerCase();
      final city = (t['city'] ?? '').toString().toLowerCase();
      return name.contains(query) || location.contains(query) || city.contains(query);
    }).toList();

    // Filter venues matching query
    final allVenues = venuesAsync.value ?? [];
    final matchingVenues = allVenues.where((v) {
      final name = (v['name'] ?? '').toString().toLowerCase();
      final city = (v['city'] ?? '').toString().toLowerCase();
      final address = (v['address'] ?? '').toString().toLowerCase();
      return name.contains(query) || city.contains(query) || address.contains(query);
    }).toList();

    return athleteSearchResults.when(
      data: (athletes) {
        final totalResults = athletes.length + matchingTournaments.length + matchingVenues.length;

        if (totalResults == 0) {
          return AppEmptyState(
            icon: Icons.search_off_outlined,
            title: 'No results for "$_activeQuery"',
            subtitle: 'Try searching by athlete name, city, or tournament title.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.space12),
              child: Text(
                'Found $totalResults result${totalResults == 1 ? '' : 's'} for "$_activeQuery"',
                style: const TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            if (athletes.isNotEmpty) ...[
              _buildSearchSectionHeader('Athletes (${athletes.length})', Icons.person_outline),
              ...athletes.map((athlete) => _buildAthleteSearchCard(context, athlete)),
              const SizedBox(height: AppTheme.space16),
            ],
            if (matchingTournaments.isNotEmpty) ...[
              _buildSearchSectionHeader('Tournaments (${matchingTournaments.length})', Icons.emoji_events_outlined),
              ...matchingTournaments.map((t) => _buildTournamentCard(context, t)),
              const SizedBox(height: AppTheme.space16),
            ],
            if (matchingVenues.isNotEmpty) ...[
              _buildSearchSectionHeader('Venues & Gyms (${matchingVenues.length})', Icons.storefront_outlined),
              ...matchingVenues.map((v) => _buildVenueCard(context, v)),
              const SizedBox(height: AppTheme.space16),
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

  Widget _buildSearchSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppTheme.primaryAccent),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ],
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
      onTap: () {
        if (id != null) context.push('/athlete/$id');
      },
      semanticLabel: 'View profile of $name',
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 17,
            backgroundColor: AppTheme.elevatedSurface,
            child: Icon(Icons.person, color: AppTheme.textSecondary, size: 19),
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
                      color: AppTheme.textMuted,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (elo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.elevatedSurface,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(color: AppTheme.border, width: 1.0),
              ),
              child: Text(
                '$elo ELO',
                style: const TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  color: AppTheme.goldPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, size: 16, color: AppTheme.textMuted),
        ],
      ),
    );
  }

  Widget _buildFeedContent(
    BuildContext context,
    DiscoverFeed feed,
    AsyncValue<List<Map<String, dynamic>>> tournamentsAsync,
    AsyncValue<List<Map<String, dynamic>>> venuesAsync,
  ) {
    switch (_selectedCategory) {
      case DiscoverCategory.tournaments:
        return _buildTournamentsSection(context, tournamentsAsync, isExpanded: true);
      case DiscoverCategory.athletes:
        return _buildRankingsSection(context, feed.topRankings, isExpanded: true);
      case DiscoverCategory.clubsAndVenues:
        return _buildVenuesSection(context, venuesAsync, isExpanded: true);
      case DiscoverCategory.announcements:
        return _buildAnnouncementsSection(context, feed.latestAnnouncements, isExpanded: true);
      case DiscoverCategory.all:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Federation Quick Hub Portals
            _buildFederationHubSection(context),
            const SizedBox(height: AppTheme.space24),

            // Announcements Section
            _buildAnnouncementsSection(context, feed.latestAnnouncements),
            const SizedBox(height: AppTheme.space24),

            // Active & Upcoming Tournaments Section
            _buildTournamentsSection(context, tournamentsAsync),
            const SizedBox(height: AppTheme.space24),

            // Top Rankings Leaderboard Section
            _buildRankingsSection(context, feed.topRankings),
            const SizedBox(height: AppTheme.space24),

            // Grassroots Venues Section
            _buildVenuesSection(context, venuesAsync),
            const SizedBox(height: AppTheme.space24),

            // Recent Completed Matches Section
            _buildRecentMatchesSection(context, feed.recentMatches),
            const SizedBox(height: AppTheme.space24),
          ],
        );
    }
  }

  Widget _buildFederationHubSection(BuildContext context) {
    final hubItems = [
      _HubItem(
        title: 'Training Venues',
        subtitle: 'Verified clubs & tables',
        tag: 'DIRECTORY',
        icon: Icons.storefront_outlined,
        color: AppTheme.secondaryAccent,
        route: '/venues',
      ),
      _HubItem(
        title: 'Pickup Meetups',
        subtitle: 'Sparring & roll calls',
        tag: 'SPARRING',
        icon: Icons.handshake_outlined,
        color: AppTheme.success,
        route: '/informal-events',
      ),
      _HubItem(
        title: 'Community Feed',
        subtitle: 'Technique clips & chats',
        tag: 'SOCIAL',
        icon: Icons.forum_outlined,
        color: AppTheme.info,
        route: '/community/feed',
      ),
      _HubItem(
        title: 'ELO Rankings',
        subtitle: 'National leaderboards',
        tag: 'STANDINGS',
        icon: Icons.leaderboard_outlined,
        color: AppTheme.goldPrimary,
        route: '/rankings',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Federation Hub',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              '4 Quick Portals',
              style: TextStyle(
                fontFamily: AppTheme.fontBody,
                fontSize: 11,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 98,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: hubItems.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = hubItems[index];
              return SizedBox(
                width: 175,
                child: ElevatedActionCard(
                  padding: const EdgeInsets.all(12),
                  borderRadius: AppTheme.radiusSmall,
                  onTap: () => context.push(item.route),
                  semanticLabel: 'Navigate to ${item.title}',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: item.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            ),
                            child: Icon(item.icon, size: 16, color: item.color),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.elevatedSurface,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                              border: Border.all(color: AppTheme.border, width: 0.8),
                            ),
                            child: Text(
                              item.tag,
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                color: item.color,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            item.subtitle,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontBody,
                              color: AppTheme.textSecondary,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementsSection(
    BuildContext context,
    List<Map<String, dynamic>> announcements, {
    bool isExpanded = false,
  }) {
    final items = isExpanded ? announcements : announcements.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Federation Bulletins',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/announcements'),
              child: const Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      fontFamily: AppTheme.fontBody,
                      color: AppTheme.primaryAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.primaryAccent),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (announcements.isEmpty)
          const AppEmptyState(
            icon: Icons.campaign_outlined,
            title: 'No announcements yet',
            subtitle: 'Official federation news, rule changes, and tournament bulletins will be posted here.',
          )
        else
          ...items.map((ann) {
            final isPinned = ann['isPinned'] == true;
            return ElevatedActionCard(
              margin: const EdgeInsets.only(bottom: 10),
              onTap: () => context.push('/announcements'),
              semanticLabel: 'View announcement: ${ann['title'] ?? 'Notice'}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isPinned) ...[
                        StatusChip.warning(
                          label: 'PINNED',
                          icon: Icons.push_pin,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          ann['title'] ?? 'Official Notice',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontBody,
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 16),
                    ],
                  ),
                  if ((ann['content'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      ann['content'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontBody,
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildTournamentsSection(
    BuildContext context,
    AsyncValue<List<Map<String, dynamic>>> tournamentsAsync, {
    bool isExpanded = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Sanctioned Tournaments',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/tournaments'),
              child: const Row(
                children: [
                  Text(
                    'All Events',
                    style: TextStyle(
                      fontFamily: AppTheme.fontBody,
                      color: AppTheme.primaryAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.primaryAccent),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        tournamentsAsync.when(
          data: (tournaments) {
            if (tournaments.isEmpty) {
              return AppEmptyState(
                icon: Icons.emoji_events_outlined,
                title: 'No tournaments scheduled',
                subtitle: 'Check back soon for upcoming sanctioned events or visit the tournament hub.',
                ctaLabel: 'Explore Tournaments',
                onCtaTap: () => context.push('/tournaments'),
              );
            }
            final items = isExpanded ? tournaments : tournaments.take(4).toList();
            return Column(
              children: items.map((t) => _buildTournamentCard(context, t)).toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: SkeletonPlaceholder(height: 90),
          ),
          error: (err, stack) => Text(
            'Error loading tournaments: $err',
            style: const TextStyle(fontFamily: AppTheme.fontBody, color: AppTheme.primaryAccent),
          ),
        ),
      ],
    );
  }

  Widget _buildTournamentCard(BuildContext context, Map<String, dynamic> t) {
    final id = t['id']?.toString() ?? '';
    final name = t['name'] ?? 'Tournament Event';
    final location = t['location'] ?? 'Location TBA';
    final city = t['city'] ?? 'Pakistan';
    final dateStr = t['startDate']?.toString().split('T').first ?? 'Upcoming';
    final status = t['status']?.toString().toUpperCase() ?? 'UPCOMING';
    final feeCents = t['registrationFeeCents'] as int?;
    final feeStr = feeCents != null ? '\$${(feeCents / 100).toStringAsFixed(2)}' : 'Free Entry';
    final isLive = status == 'LIVE';

    return ElevatedActionCard(
      margin: const EdgeInsets.only(bottom: 10),
      borderColor: isLive ? AppTheme.primaryAccent : AppTheme.border,
      onTap: () => context.push('/tournament/$id', extra: t),
      semanticLabel: 'View tournament: $name',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isLive)
                Row(
                  children: [
                    StatusChip.error(
                      label: 'LIVE NOW',
                      icon: Icons.fiber_manual_record,
                    ),
                    const SizedBox(width: 8),
                    const PulseIndicator(color: AppTheme.primaryAccent, size: 8.0),
                  ],
                )
              else
                StatusChip.info(
                  label: status,
                  icon: Icons.calendar_month,
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.elevatedSurface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(color: AppTheme.border, width: 1.0),
                ),
                child: Text(
                  feeStr,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    color: AppTheme.primaryAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(
              fontFamily: AppTheme.fontBody,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 13, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '$location, $city',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontBody,
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.calendar_today_outlined, size: 12, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Text(
                dateStr,
                style: const TextStyle(
                  fontFamily: AppTheme.fontBody,
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankingsSection(
    BuildContext context,
    List<Map<String, dynamic>> rankings, {
    bool isExpanded = false,
  }) {
    final items = isExpanded ? rankings : rankings.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Top Rankings Leaderboard',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/rankings'),
              child: const Row(
                children: [
                  Text(
                    'Full Rankings',
                    style: TextStyle(
                      fontFamily: AppTheme.fontBody,
                      color: AppTheme.goldPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.goldPrimary),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (rankings.isEmpty)
          const AppEmptyState(
            icon: Icons.leaderboard_outlined,
            title: 'No Rankings Recorded Yet',
            subtitle: 'Official leaderboard standings will populate as tournament brackets and supermatches conclude.',
          )
        else
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final athlete = entry.value;
            final id = athlete['athleteId'] ?? athlete['id'];

            return ElevatedActionCard(
              margin: const EdgeInsets.only(bottom: 8),
              onTap: () {
                if (id != null) context.push('/athlete/$id');
              },
              semanticLabel: 'View athlete profile of ${athlete['displayName'] ?? 'Athlete'}',
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: index == 0
                          ? AppTheme.goldPrimary.withValues(alpha: 0.15)
                          : (index == 1
                              ? AppTheme.textSecondary.withValues(alpha: 0.15)
                              : (index == 2
                                  ? AppTheme.secondaryAccent.withValues(alpha: 0.15)
                                  : AppTheme.elevatedSurface)),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      border: Border.all(
                        color: index == 0
                            ? AppTheme.goldPrimary
                            : (index == 1
                                ? AppTheme.textSecondary
                                : (index == 2 ? AppTheme.secondaryAccent : AppTheme.border)),
                        width: 1.2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '#${index + 1}',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        color: index == 0
                            ? AppTheme.goldPrimary
                            : (index == 1
                                ? AppTheme.textPrimary
                                : (index == 2 ? AppTheme.secondaryAccent : AppTheme.textSecondary)),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          athlete['displayName'] ?? 'Unknown Athlete',
                          style: const TextStyle(
                            fontFamily: AppTheme.fontBody,
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (athlete['division'] != null || athlete['club'] != null)
                          Text(
                            [athlete['division'], athlete['club']].where((e) => e != null).join(' • '),
                            style: const TextStyle(
                              fontFamily: AppTheme.fontBody,
                              color: AppTheme.textMuted,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.elevatedSurface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      border: Border.all(color: AppTheme.border, width: 1.0),
                    ),
                    child: Text(
                      athlete['eloRating'] != null ? '${athlete['eloRating']} ELO' : 'Unrated',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        color: AppTheme.goldPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right, size: 16, color: AppTheme.textMuted),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildVenuesSection(
    BuildContext context,
    AsyncValue<List<Map<String, dynamic>>> venuesAsync, {
    bool isExpanded = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Grassroots Training Venues',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/venues'),
              child: const Row(
                children: [
                  Text(
                    'Directory',
                    style: TextStyle(
                      fontFamily: AppTheme.fontBody,
                      color: AppTheme.secondaryAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.secondaryAccent),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        venuesAsync.when(
          data: (venues) {
            if (venues.isEmpty) {
              return AppEmptyState(
                icon: Icons.storefront_outlined,
                title: 'No training venues registered',
                subtitle: 'Check back soon or submit your local gym as a verified training location.',
                ctaLabel: 'Submit a Venue',
                onCtaTap: () => context.push('/venues/submit'),
              );
            }
            final displayVenues = isExpanded ? venues : venues.take(3).toList();
            return Column(
              children: displayVenues.map((v) => _buildVenueCard(context, v)).toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: SkeletonPlaceholder(height: 70),
          ),
          error: (err, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildVenueCard(BuildContext context, Map<String, dynamic> venue) {
    final id = venue['id']?.toString() ?? '';
    final name = venue['name'] ?? 'Training Space';
    final city = venue['city'] ?? 'Pakistan';
    final tables = venue['tableCount'] ?? venue['tablesCount'];
    final isVerified = venue['isVerified'] == true;

    return ElevatedActionCard(
      margin: const EdgeInsets.only(bottom: 10),
      onTap: () {
        if (id.isNotEmpty) {
          context.push('/venues/$id');
        } else {
          context.push('/venues');
        }
      },
      semanticLabel: 'View venue: $name',
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.secondaryAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(
                color: AppTheme.secondaryAccent.withValues(alpha: 0.3),
                width: 1.0,
              ),
            ),
            child: const Icon(
              Icons.storefront_outlined,
              color: AppTheme.secondaryAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontBody,
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, size: 14, color: AppTheme.secondaryAccent),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$city${tables != null ? ' • $tables Table${tables == 1 ? '' : 's'}' : ''}',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontBody,
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 18),
        ],
      ),
    );
  }

  Widget _buildRecentMatchesSection(BuildContext context, List<Map<String, dynamic>> matches) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Completed Matches',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        if (matches.isEmpty)
          const AppEmptyState(
            icon: Icons.history_outlined,
            title: 'No recent verified matches',
            subtitle: 'Recent sanctioned match scorepads and verified pull logs will appear here once submitted.',
          )
        else
          ...matches.map((match) {
            final challengerId = match['challengerId'];
            final opponentId = match['opponentId'];
            final winnerId = match['winnerId'];

            final challengerWin = winnerId == challengerId;
            final opponentWin = winnerId == opponentId;
            final isRightArm = (match['arm']?.toString().toUpperCase() ?? 'RIGHT') != 'LEFT';

            return ElevatedActionCard(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(AppTheme.space16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Challenger Info
                      Expanded(
                        child: TactilePressWrapper(
                          onTap: () {
                            if (challengerId != null) {
                              context.push('/athlete/$challengerId');
                            }
                          },
                          semanticLabel: 'View profile of ${match['challengerName'] ?? 'Challenger'}',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                match['challengerName'] ?? 'Unknown Challenger',
                                textAlign: TextAlign.left,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontBody,
                                  color: challengerWin ? AppTheme.primaryAccent : AppTheme.textPrimary,
                                  fontWeight: challengerWin ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              if (challengerWin)
                                const Padding(
                                padding: EdgeInsets.only(top: 2.0),
                                child: Text(
                                  'WINNER',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    color: AppTheme.primaryAccent,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Arm details pill
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ArmIndicatorPill(isRightArm: isRightArm),
                      ),

                      // Opponent Info
                      Expanded(
                        child: TactilePressWrapper(
                          onTap: () {
                            if (opponentId != null) {
                              context.push('/athlete/$opponentId');
                            }
                          },
                          semanticLabel: 'View profile of ${match['opponentName'] ?? 'Opponent'}',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                match['opponentName'] ?? 'Unknown Opponent',
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontBody,
                                  color: opponentWin ? AppTheme.primaryAccent : AppTheme.textPrimary,
                                  fontWeight: opponentWin ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              if (opponentWin)
                                const Padding(
                                  padding: EdgeInsets.only(top: 2.0),
                                  child: Text(
                                    'WINNER',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      color: AppTheme.primaryAccent,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: AppTheme.border, height: 18),
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
                        match['scoreLine'] ?? '3-0',
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
          }),
      ],
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonPlaceholder(width: 180, height: 22),
          const SizedBox(height: AppTheme.space12),
          const SkeletonPlaceholder(height: 80),
          const SizedBox(height: AppTheme.space24),
          const SkeletonPlaceholder(width: 220, height: 22),
          const SizedBox(height: AppTheme.space12),
          const SkeletonPlaceholder(height: 100),
          const SizedBox(height: AppTheme.space24),
          const SkeletonPlaceholder(width: 160, height: 22),
          const SizedBox(height: AppTheme.space12),
          ...List.generate(
            3,
            (idx) => const Padding(
              padding: EdgeInsets.only(bottom: AppTheme.space8),
              child: SkeletonPlaceholder(height: 60),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.primaryAccent, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Failed to load Discover Feed',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTheme.fontBody,
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryAccent,
                foregroundColor: AppTheme.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
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

  _HubItem({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.icon,
    required this.color,
    required this.route,
  });
}

/// Sticky search bar + filter chips delegate for DiscoverScreen
class _StickySearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget searchBar;
  final Widget filterChips;
  final double height;

  _StickySearchHeaderDelegate({
    required this.searchBar,
    required this.filterChips,
    this.height = 104.0,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppTheme.background,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          searchBar,
          filterChips,
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickySearchHeaderDelegate oldDelegate) {
    return oldDelegate.height != height ||
        oldDelegate.searchBar != searchBar ||
        oldDelegate.filterChips != filterChips;
  }
}
