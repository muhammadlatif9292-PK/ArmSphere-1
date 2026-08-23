import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/discover_provider.dart';
import '../../../core/providers/tournament_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
import '../../../core/widgets/pulse_indicator.dart';
import '../../../core/widgets/skeleton_placeholder.dart';
import '../../../core/widgets/app_empty_state.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discoverAsync = ref.watch(discoverFeedProvider);
    final tournamentsAsync = ref.watch(tournamentProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'ArmSphere Discover',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: AppTheme.elevatedSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront_outlined, color: AppTheme.secondaryAccent),
            tooltip: 'Venue Partners',
            onPressed: () => context.push('/venues'),
          ),
          IconButton(
            icon: const Icon(Icons.handshake_outlined, color: AppTheme.success),
            tooltip: 'Pickup Meetups',
            onPressed: () => context.push('/informal-events'),
          ),
          IconButton(
            icon: const Icon(Icons.people_outline, color: AppTheme.info),
            tooltip: 'Community Feed',
            onPressed: () => context.push('/community/feed'),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: AppTheme.success),
            tooltip: 'Search Athletes',
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.dashboard_customize, color: AppTheme.primaryAccent),
            tooltip: 'Go to Athlete Dashboard',
            onPressed: () => context.go('/athlete/dashboard'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryAccent,
        backgroundColor: AppTheme.elevatedSurface,
        onRefresh: () => ref.read(discoverFeedProvider.notifier).refresh(),
        child: discoverAsync.when(
          data: (feed) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Announcements Section
                    _buildAnnouncementsSection(context, feed.latestAnnouncements),
                    const SizedBox(height: AppTheme.space24),

                    // Active & Upcoming Tournaments Section
                    _buildTournamentsSection(context, tournamentsAsync),
                    const SizedBox(height: AppTheme.space24),

                    // Top Rankings Section
                    _buildRankingsSection(context, feed.topRankings),
                    const SizedBox(height: AppTheme.space24),

                    // Recent Matches Section
                    _buildRecentMatchesSection(context, feed.recentMatches),
                    const SizedBox(height: AppTheme.space24),
                  ],
                ),
              ),
            );
          },
          loading: () => _buildLoadingState(),
          error: (err, stack) => _buildErrorState(err, () {
            ref.invalidate(discoverFeedProvider);
          }),
        ),
      ),
    );
  }

  Widget _buildAnnouncementsSection(BuildContext context, List<Map<String, dynamic>> announcements) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Latest Announcements',
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
        const SizedBox(height: AppTheme.space8),
        if (announcements.isEmpty)
          const AppEmptyState(
            icon: Icons.campaign_outlined,
            title: 'No announcements yet',
            subtitle: 'Official federation news, rule changes, and tournament bulletins will be posted here.',
          )
        else
          ...announcements.map((ann) {
            final isPinned = ann['isPinned'] == true;
            return TactilePressWrapper(
              onTap: () => context.push('/announcements'),
              semanticLabel: 'View announcement: ${ann['title'] ?? 'Notice'}',
              child: Card(
                color: AppTheme.surface,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  side: const BorderSide(color: AppTheme.border, width: 1.0),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space8),
                  title: Row(
                    children: [
                      if (isPinned) ...[
                        const Icon(Icons.push_pin, size: 14, color: AppTheme.secondaryAccent),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          ann['title'] ?? 'Notice',
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
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      ann['content'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontBody,
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                ),
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildRankingsSection(BuildContext context, List<Map<String, dynamic>> rankings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(height: 12),
        if (rankings.isEmpty)
          const AppEmptyState(
            icon: Icons.leaderboard_outlined,
            title: 'Rankings coming soon',
            subtitle: 'Official leaderboard standings will populate as tournament brackets and supermatches conclude.',
          )
        else
          ...rankings.asMap().entries.map((entry) {
            final index = entry.key;
            final athlete = entry.value;
            final id = athlete['athleteId'] ?? athlete['id'];

            return TactilePressWrapper(
              onTap: () {
                if (id != null) {
                  context.push('/athlete/$id');
                }
              },
              semanticLabel: 'View athlete profile of ${athlete['displayName'] ?? 'Athlete'}',
              child: Card(
                color: AppTheme.surface,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  side: const BorderSide(color: AppTheme.border, width: 1.0),
                ),
                child: ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: index == 0
                          ? AppTheme.secondaryAccent.withOpacity(0.2)
                          : (index == 1
                              ? AppTheme.textSecondary.withOpacity(0.2)
                              : (index == 2 ? AppTheme.textSecondary.withOpacity(0.2) : AppTheme.elevatedSurface)),
                      shape: BoxShape.circle,
                      border: index == 0
                          ? Border.all(color: AppTheme.secondaryAccent, width: 1.5)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '#${index + 1}',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        color: index == 0
                            ? AppTheme.secondaryAccent
                            : (index == 1 ? AppTheme.textPrimary : (index == 2 ? AppTheme.textSecondary : AppTheme.textSecondary)),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  title: Text(
                    athlete['displayName'] ?? 'Unknown Athlete',
                    style: const TextStyle(
                      fontFamily: AppTheme.fontBody,
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  trailing: Text(
                    athlete['eloRating'] != null ? '${athlete['eloRating']} ELO' : 'Unrated',
                    style: const TextStyle(
                      fontFamily: AppTheme.fontDisplay, // Hard mandate: ALL stats use Space Grotesk
                      color: AppTheme.secondaryAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
      ],
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
        const SizedBox(height: 12),
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

            return Card(
              color: AppTheme.surface,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                side: const BorderSide(color: AppTheme.border, width: 1.0),
              ),
              child: Padding(
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
                                    fontWeight: challengerWin ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 14,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppTheme.textMuted.withOpacity(0.5),
                                  ),
                                ),
                                if (challengerWin)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2.0),
                                    child: Text(
                                      'WINNER',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontBody,
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
                        
                        // Arm details
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.elevatedSurface,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            border: Border.all(color: AppTheme.border, width: 1.0),
                          ),
                          child: Text(
                            match['arm']?.toString().toUpperCase() ?? 'RIGHT',
                            style: const TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              color: AppTheme.secondaryAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                                    fontWeight: opponentWin ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 14,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppTheme.textMuted.withOpacity(0.5),
                                  ),
                                ),
                                if (opponentWin)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2.0),
                                    child: Text(
                                      'WINNER',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontBody,
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
                    const Divider(color: AppTheme.border, height: 20),
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
                            fontFamily: AppTheme.fontDisplay, // Score stats are space grotesk
                            color: AppTheme.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.space16),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentsSection(BuildContext context, AsyncValue<List<Map<String, dynamic>>> tournamentsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Active & Upcoming Tournaments',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        tournamentsAsync.when(
          data: (tournaments) {
            if (tournaments.isEmpty) {
              return AppEmptyState(
                icon: Icons.emoji_events_outlined,
                title: 'No tournaments scheduled',
                subtitle: 'Check back soon for upcoming sanctioned events or visit the tournament hub.',
                ctaLabel: 'Explore Tournaments',
                onCtaTap: () => context.push('/tournament/dashboard'),
              );
            }
            return Column(
              children: tournaments.map((t) {
                final id = t['id']?.toString() ?? '';
                final name = t['name'] ?? 'Tournament Event';
                final location = t['location'] ?? 'Ryerson';
                final city = t['city'] ?? 'Toronto';
                final dateStr = t['startDate']?.toString().split('T').first ?? 'Upcoming';
                final status = t['status']?.toString().toUpperCase() ?? 'UPCOMING';
                final feeCents = t['registrationFeeCents'] as int?;
                final feeStr = feeCents != null ? '\$${(feeCents / 100).toStringAsFixed(2)}' : 'Free Entry';
                final isLive = status == 'LIVE';

                return TactilePressWrapper(
                  onTap: () {
                    context.push('/events/$id/register', extra: t);
                  },
                  semanticLabel: 'Register for tournament: $name',
                  child: Card(
                    color: AppTheme.surface,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      side: BorderSide(
                        color: isLive ? AppTheme.primaryAccent : AppTheme.border,
                        width: isLive ? 1.5 : 1.0,
                      ),
                    ),
                    shadowColor: isLive ? AppTheme.primaryAccent.withOpacity(0.2) : AppTheme.background,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space8),
                      leading: isLive 
                          ? Semantics(
                              liveRegion: true,
                              label: 'Match is now live',
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4.0),
                                child: PulseIndicator(color: AppTheme.primaryAccent, size: 10.0),
                              ),
                            )
                          : CircleAvatar(
                              backgroundColor: AppTheme.info.withOpacity(0.15),
                              child: const Icon(
                                Icons.calendar_month,
                                color: AppTheme.info,
                              ),
                            ),
                      title: Text(
                        name,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontBody,
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '$location, $city • $dateStr',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontBody,
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryAccent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            ),
                            child: Text(
                              feeStr,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay, // Price stats are Space Grotesk
                                color: AppTheme.primaryAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 16),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: CircularProgressIndicator(color: AppTheme.primaryAccent),
            ),
          ),
          error: (err, stack) => Text(
            'Error loading tournaments: $err',
            style: const TextStyle(fontFamily: AppTheme.fontBody, color: AppTheme.primaryAccent),
          ),
        ),
      ],
    );
  }
}
