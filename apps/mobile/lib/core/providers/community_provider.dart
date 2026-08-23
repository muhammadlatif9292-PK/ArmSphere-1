import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state_providers.dart';
import 'athlete_provider.dart';

/// Notifier to fetch and manage the cursor-paginated community feed.
class CommunityFeedNotifier extends AutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final repo = ref.watch(communityRepositoryProvider);
    return repo.getFeed(limit: 20);
  }

  /// Fetch the next page of posts using cursor-based pagination
  Future<void> loadMore() async {
    final currentList = state.value;
    if (currentList == null || currentList.isEmpty) return;

    final lastItem = currentList.last;
    final lastCreatedAt = lastItem['createdAt']?.toString();
    if (lastCreatedAt == null) return;

    try {
      final repo = ref.read(communityRepositoryProvider);
      final nextItems = await repo.getFeed(limit: 20, cursor: lastCreatedAt);
      if (nextItems.isNotEmpty) {
        state = AsyncValue.data([...currentList, ...nextItems]);
      }
    } catch (e) {
      // Propagate the error up so the UI can display a SnackBar, leaving current state intact.
      rethrow;
    }
  }

  /// Refresh the feed from scratch
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(communityRepositoryProvider);
      final feed = await repo.getFeed(limit: 20);
      state = AsyncValue.data(feed);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// Delete a post
  Future<void> deletePost(String postId) async {
    try {
      final repo = ref.read(communityRepositoryProvider);
      await repo.deletePost(postId);
      
      final currentList = state.value;
      if (currentList != null) {
        state = AsyncValue.data(
          currentList.where((post) => post['id'] != postId).toList(),
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider for CommunityFeedNotifier.
final communityFeedProvider = AsyncNotifierProvider.autoDispose<CommunityFeedNotifier, List<Map<String, dynamic>>>(() {
  return CommunityFeedNotifier();
});

/// Notifier to track and toggle the like state of a post.
class PostLikeNotifier extends AutoDisposeFamilyAsyncNotifier<bool, String> {
  @override
  Future<bool> build(String arg) async {
    final feedAsync = ref.watch(communityFeedProvider);
    return feedAsync.maybeWhen(
      data: (feed) {
        final post = feed.firstWhere(
          (p) => p['id']?.toString() == arg,
          orElse: () => <String, dynamic>{},
        );
        return post['likedByViewer'] as bool? ?? false;
      },
      orElse: () => false,
    );
  }

  /// Toggle like status
  Future<void> toggleLike() async {
    final isCurrentlyLiked = state.value ?? false;
    final repo = ref.read(communityRepositoryProvider);
    
    // Optimistic update
    state = AsyncValue.data(!isCurrentlyLiked);

    try {
      if (isCurrentlyLiked) {
        await repo.unlikePost(arg);
      } else {
        await repo.likePost(arg);
      }
    } catch (e) {
      // Rollback on failure
      state = AsyncValue.data(isCurrentlyLiked);
      rethrow;
    }
  }
}

/// Provider for PostLikeNotifier family.
final postLikeProvider = AsyncNotifierProvider.autoDispose.family<PostLikeNotifier, bool, String>(() {
  return PostLikeNotifier();
});

/// Notifier to fetch and add comments of a specific post.
class PostCommentsNotifier extends AutoDisposeFamilyAsyncNotifier<List<Map<String, dynamic>>, String> {
  @override
  Future<List<Map<String, dynamic>>> build(String arg) async {
    final repo = ref.watch(communityRepositoryProvider);
    return repo.getComments(arg);
  }

  /// Add a new comment
  Future<void> addComment(String body) async {
    try {
      final repo = ref.read(communityRepositoryProvider);
      final newComment = await repo.addComment(arg, body);
      
      // Retrieve current athlete profile to populate nested 'athlete' field
      final profile = await ref.read(athleteProfileProvider.future);
      
      final fullComment = {
        ...newComment,
        'athlete': {
          'id': profile['id'],
          'displayName': '${profile['firstName'] ?? ""} ${profile['lastName'] ?? ""}'.trim(),
          'profilePhoto': profile['profilePhoto'],
        }
      };

      final currentComments = state.value ?? [];
      state = AsyncValue.data([...currentComments, fullComment]);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}

/// Provider for PostCommentsNotifier family.
final postCommentsProvider = AsyncNotifierProvider.autoDispose.family<PostCommentsNotifier, List<Map<String, dynamic>>, String>(() {
  return PostCommentsNotifier();
});
