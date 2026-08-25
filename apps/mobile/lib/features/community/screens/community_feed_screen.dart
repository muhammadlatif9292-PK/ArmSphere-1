import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/community_provider.dart';
import '../../../core/utils/embed_url_builder.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/skeleton_placeholder.dart';
import 'video_player_modal.dart';

/// Community feed — real approved video-link posts from GET /community/feed.
class CommunityFeedScreen extends ConsumerWidget {
  const CommunityFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(communityFeedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_link),
            tooltip: 'Share a video link',
            onPressed: () => context.push('/community/post/create'),
          ),
        ],
      ),
      body: feedAsync.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (_, __) => const SkeletonPlaceholder(height: 180),
        ),
        error: (error, _) => AppEmptyState(
          icon: Icons.error_outline,
          title: 'Could not load feed',
          subtitle: error.toString(),
          ctaLabel: 'Retry',
          onCtaTap: () => ref.invalidate(communityFeedProvider),
        ),
        data: (posts) {
          if (posts.isEmpty) {
            return AppEmptyState(
              icon: Icons.videocam_off_outlined,
              title: 'No posts yet',
              subtitle:
                  'Be the first to share a training or match video from YouTube, TikTok or Facebook.',
              ctaLabel: 'Share a video',
              onCtaTap: () => context.push('/community/post/create'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              try {
                await ref.read(communityFeedProvider.notifier).refresh();
              } catch (_) {
                // refresh() already set the error state; surfaced by rebuild.
              }
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollInfo) {
                if (scrollInfo.metrics.pixels >=
                    scrollInfo.metrics.maxScrollExtent - 400) {
                  // loadMore failures surface as SnackBar below via unhandled
                  // async errors; guard with ignore to avoid crash dialogs.
                  ref
                      .read(communityFeedProvider.notifier)
                      .loadMore()
                      .catchError((_) {});
                }
                return false;
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: posts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final post = posts[index];
                  final athlete =
                      post['athlete'] is Map ? post['athlete'] as Map : null;
                  final athleteName =
                      athlete?['displayName']?.toString() ?? '';
                  final athletePhoto =
                      athlete?['profilePhoto']?.toString() ?? '';
                  final platform = post['platform']?.toString() ?? '';
                  final embedUrl =
                      EmbedUrlBuilder.getEmbedUrl(
                          post['externalUrl']?.toString() ?? '', platform) ??
                      post['externalUrl']?.toString() ??
                      '';

                  return GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundImage: athletePhoto.isNotEmpty
                                      ? NetworkImage(athletePhoto)
                                      : null,
                              child: athletePhoto.isEmpty
                                      ? Text(_initial(athleteName))
                                      : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    athlete?['displayName']?.toString() ??
                                        'Athlete',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    post['createdAt']?.toString().split('T').first ??
                                        '',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            if (post['category'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  post['category'].toString(),
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5),
                                ),
                              ),
                          ],
                        ),
                        if ((post['caption'] as String?)?.isNotEmpty ==
                            true) ...[
                          const SizedBox(height: 12),
                          Text(post['caption'].toString(),
                              style:
                                  const TextStyle(height: 1.4, fontSize: 13)),
                        ],
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => VideoPlayerModal.show(
                            context,
                            embedUrl: embedUrl,
                            platform: platform,
                            caption: post['caption']?.toString(),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  height: 170,
                                  width: double.infinity,
                                  color:
                                      Theme.of(context).colorScheme.surface,
                                  child: const Center(
                                    child: Icon(Icons.play_circle_fill,
                                        size: 48),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            _LikeButton(postId: post['id'].toString()),
                            const SizedBox(width: 24),
                            GestureDetector(
                              onTap: () => context.push(
                                  '/community/posts/${post['id']}/comments'),
                              child: Row(
                                children: [
                                  const Icon(Icons.chat_bubble_outline,
                                      size: 20),
                                  const SizedBox(width: 6),
                                  Text('Comments',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

String _initial(String? name) {
  final n = (name ?? '').trim();
  return n.isEmpty ? '?' : n[0].toUpperCase();
}

class _LikeButton extends ConsumerWidget {
  final String postId;

  const _LikeButton({required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likedAsync = ref.watch(postLikeProvider(postId));

    return GestureDetector(
      onTap: () async {
        try {
          await ref.read(postLikeProvider(postId).notifier).toggleLike();
        } catch (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not update like'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Row(
        children: [
          Icon(
            likedAsync.valueOrNull == true
                ? Icons.favorite
                : Icons.favorite_border,
            size: 20,
            color: likedAsync.valueOrNull == true ? Colors.redAccent : null,
          ),
          const SizedBox(width: 6),
          Text(likedAsync.valueOrNull == true ? 'Liked' : 'Like',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
