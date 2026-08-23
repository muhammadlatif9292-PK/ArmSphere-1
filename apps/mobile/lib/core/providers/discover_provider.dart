import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state_providers.dart';

class DiscoverFeed {
  final List<Map<String, dynamic>> recentMatches;
  final List<Map<String, dynamic>> topRankings;
  final List<Map<String, dynamic>> latestAnnouncements;

  DiscoverFeed({
    required this.recentMatches,
    required this.topRankings,
    required this.latestAnnouncements,
  });
}

class DiscoverFeedNotifier extends AutoDisposeAsyncNotifier<DiscoverFeed> {
  @override
  Future<DiscoverFeed> build() async {
    final matchRepo = ref.watch(matchRepositoryProvider);
    final rankingsRepo = ref.watch(rankingsRepositoryProvider);
    final messagingRepo = ref.watch(messagingRepositoryProvider);

    final results = await Future.wait([
      matchRepo.getRecentMatches(limit: 10, offset: 0),
      rankingsRepo.getLeaderboards(),
      messagingRepo.getAnnouncements(limit: 3),
    ]);

    final recentMatches = List<Map<String, dynamic>>.from(results[0]);
    final allRankings = List<Map<String, dynamic>>.from(results[1]);
    final topRankings = allRankings.take(5).toList();
    final latestAnnouncements = List<Map<String, dynamic>>.from(results[2]);

    return DiscoverFeed(
      recentMatches: recentMatches,
      topRankings: topRankings,
      latestAnnouncements: latestAnnouncements,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    ref.invalidateSelf();
    await future;
  }
}

final discoverFeedProvider = AsyncNotifierProvider.autoDispose<DiscoverFeedNotifier, DiscoverFeed>(() {
  return DiscoverFeedNotifier();
});
