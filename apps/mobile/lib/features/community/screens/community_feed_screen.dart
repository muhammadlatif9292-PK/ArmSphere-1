import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/widgets/armsphere_image.dart';
import '../../../core/providers/community_provider.dart';
import '../../../core/providers/messaging_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/embed_url_builder.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/pulse_indicator.dart';
import '../../../core/widgets/skeleton_placeholder.dart';
import '../../../core/widgets/main_shell_screen.dart';
import '../../../core/providers/visual_preferences_provider.dart';
import '../../../core/widgets/crystal_glass_nav_controls.dart';
import '../../../core/widgets/crystal_stage_scaffold.dart';
import '../../auth/providers/auth_provider.dart';
import 'video_player_modal.dart';
import '../../../core/widgets/crystal_toast.dart';
import '../../../core/widgets/crystal_slash_painter.dart';
import '../../../core/widgets/championship_name_marquee.dart';

/// Opens or creates a private 1-on-1 direct message thread with the athlete who posted [post].
Future<void> _openDirectMessageWithAthlete(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> post,
) async {
  HapticFeedback.lightImpact();
  final athlete = post['athlete'] is Map ? post['athlete'] as Map : null;
  final athleteId = athlete?['id']?.toString() ?? post['athleteId']?.toString() ?? '';
  final targetUserId = athlete?['userId']?.toString() ??
      post['userId']?.toString() ??
      athleteId;

  if (targetUserId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      CrystalSnackBar(
        content: const Text('This athlete cannot be messaged yet'),
        backgroundColor: AppTheme.warning,
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  final myUserId = ref.read(authProvider).userProfile?['id']?.toString() ?? '';
  if (myUserId.isNotEmpty && targetUserId == myUserId) {
    context.push('/messages');
    return;
  }

  try {
    final conversation = await ref
        .read(conversationsProvider.notifier)
        .getOrCreateConversation(targetUserId);
    if (!context.mounted) return;
    final convId = conversation?['id']?.toString() ?? '';
    if (convId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        CrystalSnackBar(
          content: const Text('Could not start private conversation'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    context.push('/messages/$convId');
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        CrystalSnackBar(
          content: const Text('Could not start private conversation'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// Canary 6: Community Media & Clip Feed Screen (`/community`)
class CommunityFeedScreen extends ConsumerStatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  ConsumerState<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends ConsumerState<CommunityFeedScreen> {
  String _selectedCategory = 'ALL';
  bool _isVerticalClipsMode = false;
  final ValueNotifier<String?> _activeVideoPostId = ValueNotifier<String?>(null);

  final List<String> _categories = const [
    'ALL',
    'TECHNIQUE',
    'SPARRING',
    'TOURNAMENTS',
    'PODCASTS',
    'REFEREE',
  ];

  @override
  void dispose() {
    _activeVideoPostId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(communityFeedProvider);
    final bool insideRootShell = MainShellScope.isInsideShell(context);
    final double bottomDockGap = insideRootShell
        ? (kFloatingDockTotalHeight +
            MediaQuery.paddingOf(context).bottom +
            10.0)
        : 12.0;

    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: CrystalStageBackdrop(domain: ArmSphereStageDomain.community),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ========================================================
                // TOP MINIMAL BRAND HEADER + CATEGORY STRIP (FIXED ABOVE VAPOR SCROLL VIEWPORT)
                // ========================================================
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0x73D4AF37),
                            width: 1.0,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Image.asset(
                            ArmSphereAssets.teamCrestDefault,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.high,
                            semanticLabel:
                                'Official Federation Community Arena',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'COMMUNITY ARENA',
                                maxLines: 1,
                                style: TextStyle(
                                  fontFamily: 'Space Grotesk',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const PulseIndicator(
                                    size: 5.0, color: AppTheme.goldPrimary),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    'LIVE FEED',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Space Grotesk',
                                      color: AppTheme.goldPrimary
                                          .withValues(alpha: 0.95),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 9.5,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Direct 1-on-1 Messages Inbox shortcut
                      CrystalIconPillButton(
                        tooltip: 'Direct 1-on-1 Messages',
                        icon: Icons.forum_outlined,
                        iconColor: AppTheme.goldPrimary,
                        iconSize: 18,
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          context.push('/messages');
                        },
                      ),
                      // Mode Toggle: Stream vs Vertical Clips inside 38x38 circular smoked-crystal pill
                      CrystalIconPillButton(
                        tooltip: _isVerticalClipsMode
                            ? 'Stream Card View'
                            : 'Vertical Clip Reels',
                        icon: _isVerticalClipsMode
                            ? Icons.view_agenda_outlined
                            : Icons.play_lesson_outlined,
                        iconColor: _isVerticalClipsMode
                            ? AppTheme.goldPrimary
                            : AppTheme.textPure,
                        iconSize: 18,
                        onPressed: () {
                          _activeVideoPostId.value = null;
                          setState(() {
                            _isVerticalClipsMode = !_isVerticalClipsMode;
                          });
                        },
                      ),
                      const SizedBox(width: 2),
                      CrystalHeaderActionPill(
                        label: 'POST CLIP',
                        icon: Icons.add,
                        onTap: () => context.push('/community/post/create'),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 3),
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = cat == _selectedCategory;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _activeVideoPostId.value = null;
                          setState(() {
                            _selectedCategory = cat;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0x1FD4AF37)
                                : Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSmall),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0x73D4AF37)
                                  : const Color(0x2EFFFFFF),
                              width: isSelected ? 1.2 : 1.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontFamily: 'Space Grotesk',
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected
                                  ? AppTheme.goldPrimary
                                  : const Color(0xFFCBD5E1),
                              letterSpacing: 0.5,
                              shadows: AppTheme.crystalTextShadows,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 4),
                // ========================================================
                // VAPOR-DISSOLVE SCROLL VIEWPORT (TOP & BOTTOM SCROLL HIDING BORDERS)
                // ========================================================
                Expanded(
                  child: _isVerticalClipsMode
                      ? feedAsync.when(
                          loading: () => const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.goldPrimary,
                            ),
                          ),
                          error: (error, _) => AppErrorView(
                            error: error,
                            title: 'Could not load feed',
                            onRetry: () =>
                                ref.invalidate(communityFeedProvider),
                            showSecondaryAction: false,
                            onSessionExpired: () =>
                                ref.read(authProvider.notifier).logout(),
                          ),
                          data: (allPosts) {
                            final posts = _selectedCategory == 'ALL'
                                ? allPosts
                                : allPosts.where((p) {
                                    final cat = p['category']
                                            ?.toString()
                                            .toUpperCase() ??
                                        '';
                                    return cat.contains(_selectedCategory);
                                  }).toList();
                            if (posts.isEmpty) {
                              return Center(
                                child: AppEmptyState(
                                  icon: Icons.videocam_off_outlined,
                                  title: 'No clips found',
                                  subtitle: _selectedCategory == 'ALL'
                                      ? 'Be the first to share a training or match video.'
                                      : 'No clips currently tagged with $_selectedCategory.',
                                  ctaLabel: 'Share a video',
                                  onCtaTap: () =>
                                      context.push('/community/post/create'),
                                ),
                              );
                            }
                            return _VerticalClipsFeed(
                              posts: posts,
                              activeVideoPostId: _activeVideoPostId,
                              onRefresh: () => ref
                                  .read(communityFeedProvider.notifier)
                                  .refresh(),
                              onLoadMore: () => ref
                                  .read(communityFeedProvider.notifier)
                                  .loadMore(),
                            );
                          },
                        )
                      : CrystalVaporDissolve(
                          bottomMargin: bottomDockGap,
                          child: feedAsync.when(
                            loading: () => ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 10, 16, 28),
                              itemCount: 4,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (_, __) => const RepaintBoundary(
                                child: SkeletonPlaceholder(height: 280),
                              ),
                            ),
                            error: (error, _) => AppErrorView(
                              error: error,
                              title: 'Could not load feed',
                              onRetry: () =>
                                  ref.invalidate(communityFeedProvider),
                              showSecondaryAction: false,
                              onSessionExpired: () =>
                                  ref.read(authProvider.notifier).logout(),
                            ),
                            data: (allPosts) {
                              final posts = _selectedCategory == 'ALL'
                                  ? allPosts
                                  : allPosts.where((p) {
                                      final cat = p['category']
                                              ?.toString()
                                              .toUpperCase() ??
                                          '';
                                      return cat.contains(_selectedCategory);
                                    }).toList();

                              if (posts.isEmpty) {
                                return SingleChildScrollView(
                                  padding: const EdgeInsets.fromLTRB(
                                      8, 24, 8, 28),
                                  child: AppEmptyState(
                                    icon: Icons.videocam_off_outlined,
                                    title: 'No clips found',
                                    subtitle: _selectedCategory == 'ALL'
                                        ? 'Be the first to share a training or match video from YouTube, TikTok, or Facebook.'
                                        : 'No clips currently tagged with $_selectedCategory. Check back soon or upload one!',
                                    ctaLabel: 'Share a video',
                                    onCtaTap: () => context
                                        .push('/community/post/create'),
                                  ),
                                );
                              }

                              return RefreshIndicator(
                                color: AppTheme.goldPrimary,
                                backgroundColor: AppTheme.cardSurface,
                                onRefresh: () async {
                                  _activeVideoPostId.value = null;
                                  try {
                                    await ref
                                        .read(communityFeedProvider.notifier)
                                        .refresh();
                                  } catch (_) {}
                                },
                                child:
                                    NotificationListener<ScrollNotification>(
                                  onNotification: (scrollInfo) {
                                    if (scrollInfo.metrics.pixels >=
                                        scrollInfo.metrics.maxScrollExtent -
                                            400) {
                                      ref
                                          .read(communityFeedProvider.notifier)
                                          .loadMore()
                                          .catchError((_) {});
                                    }
                                    return false;
                                  },
                                  child: ListView.separated(
                                    key: const PageStorageKey<String>(
                                        'community_feed_list_view'),
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 10, 16, 28),
                                    itemCount: posts.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 16),
                                    itemBuilder: (context, index) {
                                      final post = posts[index];
                                      return _TacticalFeedCard(
                                        post: post,
                                        activeVideoPostId: _activeVideoPostId,
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
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
}

/// Tactical Feed Card for Stream View (Canary 6 specification)
class _TacticalFeedCard extends ConsumerWidget {
  final Map<String, dynamic> post;
  final ValueNotifier<String?> activeVideoPostId;

  const _TacticalFeedCard({
    required this.post,
    required this.activeVideoPostId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final athlete = post['athlete'] is Map ? post['athlete'] as Map : null;
    final athleteId = athlete?['id']?.toString() ?? post['athleteId']?.toString() ?? '';
    final athleteName = athlete?['displayName']?.toString() ?? 'Athlete';
    final athletePhoto = athlete?['profilePhoto']?.toString() ?? '';
    final country = athlete?['country']?.toString() ?? 'PAK';
    final platform = (post['platform']?.toString() ?? 'YOUTUBE').toUpperCase();
    final rawUrl = post['externalUrl']?.toString() ?? '';
    final embedUrl = EmbedUrlBuilder.getEmbedUrl(rawUrl, platform) ?? rawUrl;
    final category = (post['category']?.toString() ?? 'TECHNIQUE').toUpperCase();
    final caption = post['caption']?.toString() ?? '';
    final rawDate = post['createdAt']?.toString() ?? '';
    final dateDisplay = rawDate.isNotEmpty ? rawDate.split('T').first : '';
    final postId = post['id']?.toString() ?? '';
    final ytId = EmbedUrlBuilder.extractYouTubeId(rawUrl);
    final thumbnailUrl = ytId != null ? 'https://img.youtube.com/vi/$ytId/hqdefault.jpg' : null;
    final fallbackCombatAsset = (category == 'SPARRING' || category == 'TECHNIQUE')
        ? ArmSphereAssets.clipFallbackSparring
        : ArmSphereAssets.clipFallbackMatch;

    return RepaintBoundary(
      child: Container(
        decoration: AppTheme.machinedTitaniumDecoration(radius: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Top Row: Athlete Identity + Category Pill
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: athleteId.isEmpty
                          ? null
                          : () {
                              HapticFeedback.selectionClick();
                              context.push('/athlete/public/$athleteId');
                            },
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        children: [
                          // Athlete Avatar with 1.5px Gold Ring
                          Container(
                            padding: const EdgeInsets.all(1.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.goldPrimary, width: 1.5),
                            ),
                            child: ArmSphereImage.avatar(
                              imageUrl: athletePhoto.isNotEmpty ? athletePhoto : null,
                              initial: athleteName,
                              size: 36,
                              fallbackAsset: ArmSphereAssets.defaultAvatar,
                              cacheWidth: 108,
                              cacheHeight: 108,
                              semanticLabel: 'Profile photo for $athleteName',
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Athlete Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: ChampionshipNameMarquee(
                                        name: athleteName,
                                        style: const TextStyle(
                                          fontFamily: 'Space Grotesk',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(3),
                                        border: Border.all(color: const Color(0x26FFFFFF), width: 1.0),
                                      ),
                                      child: Text(
                                        country,
                                        style: const TextStyle(
                                          fontFamily: 'Space Grotesk',
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dateDisplay,
                                  style: const TextStyle(
                                    fontFamily: 'Space Grotesk',
                                    fontSize: 10.5,
                                    fontFeatures: [FontFeature.tabularFigures()],
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Tactical Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _getCategoryColor(category).withValues(alpha: 0.65),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getCategoryColor(category),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          category,
                          style: TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: _getCategoryColor(category),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Caption Section
            if (caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Text(
                  caption,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // Tactical Inline Video Player (16:9 Aspect Ratio — plays directly inside card)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: InlineCombatVideoPlayer(
                postId: postId,
                embedUrl: embedUrl,
                rawUrl: rawUrl,
                platform: platform,
                caption: caption,
                thumbnailUrl: thumbnailUrl,
                fallbackAsset: fallbackCombatAsset,
                activePostIdNotifier: activeVideoPostId,
              ),
            ),

            const SizedBox(height: 8),

            // Card Bottom Action Bar: Direct 1-on-1 Athlete Message, Athlete Profile & Share Clip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Direct 1-on-1 Message Athlete Button
                      InkWell(
                        onTap: () => _openDirectMessageWithAthlete(context, ref, post),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0x1AD4AF37),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0x73D4AF37), width: 1.0),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.send_rounded,
                                size: 15,
                                color: AppTheme.goldPrimary,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'MESSAGE ATHLETE',
                                style: TextStyle(
                                  fontFamily: 'Space Grotesk',
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.goldPrimary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (athleteId.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            context.push('/athlete/public/$athleteId');
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person_outline_rounded,
                                  size: 17,
                                  color: AppTheme.textSecondary,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'DOSSIER',
                                  style: TextStyle(
                                    fontFamily: 'Space Grotesk',
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textSecondary,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Share Button
                  IconButton(
                    icon: const Icon(
                      Icons.share_outlined,
                      size: 18,
                      color: AppTheme.textMuted,
                    ),
                    tooltip: 'Share Clip',
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      if (rawUrl.isNotEmpty) {
                        Clipboard.setData(ClipboardData(text: rawUrl));
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        CrystalSnackBar(
                          content: const Text('Clip link copied to clipboard'),
                          duration: const Duration(seconds: 2),
                          backgroundColor: AppTheme.elevatedSurface,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fullscreen Vertical Snapping Clip Reels Mode (9:16 Canary 6 Spec)
class _VerticalClipsFeed extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> posts;
  final ValueNotifier<String?> activeVideoPostId;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoadMore;

  const _VerticalClipsFeed({
    required this.posts,
    required this.activeVideoPostId,
    required this.onRefresh,
    required this.onLoadMore,
  });

  @override
  ConsumerState<_VerticalClipsFeed> createState() => _VerticalClipsFeedState();
}

class _VerticalClipsFeedState extends ConsumerState<_VerticalClipsFeed> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      physics: const PageScrollPhysics(),
      itemCount: widget.posts.length,
      onPageChanged: (index) {
        widget.activeVideoPostId.value = null;
        if (index >= widget.posts.length - 2) {
          widget.onLoadMore();
        }
      },
      itemBuilder: (context, index) {
        final post = widget.posts[index];
        final athlete = post['athlete'] is Map ? post['athlete'] as Map : null;
        final athleteId = athlete?['id']?.toString() ?? post['athleteId']?.toString() ?? '';
        final athleteName = athlete?['displayName']?.toString() ?? 'Athlete';
        final athletePhoto = athlete?['profilePhoto']?.toString() ?? '';
        final platform = (post['platform']?.toString() ?? 'YOUTUBE').toUpperCase();
        final rawUrl = post['externalUrl']?.toString() ?? '';
        final embedUrl = EmbedUrlBuilder.getEmbedUrl(rawUrl, platform) ?? rawUrl;
        final category = (post['category']?.toString() ?? 'TECHNIQUE').toUpperCase();
        final caption = post['caption']?.toString() ?? '';
        final postId = post['id']?.toString() ?? '';
        final ytId = EmbedUrlBuilder.extractYouTubeId(rawUrl);
        final thumbnailUrl = ytId != null ? 'https://img.youtube.com/vi/$ytId/hqdefault.jpg' : null;
        final fallbackCombatAsset = (category == 'SPARRING' || category == 'TECHNIQUE')
            ? ArmSphereAssets.heroGrip
            : ArmSphereAssets.heroArena;

        return RepaintBoundary(
          child: Container(
            color: const Color(0xFF000000),
            child: Stack(
              children: [
                // Inline Video Player Center
                Positioned.fill(
                  child: InlineCombatVideoPlayer(
                    postId: postId,
                    embedUrl: embedUrl,
                    rawUrl: rawUrl,
                    platform: platform,
                    caption: caption,
                    thumbnailUrl: thumbnailUrl,
                    fallbackAsset: fallbackCombatAsset,
                    activePostIdNotifier: widget.activeVideoPostId,
                    isVerticalReel: true,
                  ),
                ),

                // Right Translucent Action Dock (Direct 1-on-1 Message, Dossier, Share)
                Positioned(
                  right: 20,
                  bottom: MainShellScope.bottomClearance(context, additionalPadding: 86),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0x38FFFFFF),
                        width: 1.0,
                      ),
                      boxShadow: const [],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Direct 1-on-1 Message
                        IconButton(
                          icon: const Icon(Icons.send_rounded, color: AppTheme.goldPrimary, size: 26),
                          tooltip: 'Message Athlete',
                          onPressed: () => _openDirectMessageWithAthlete(context, ref, post),
                        ),
                        const Text(
                          'MESSAGE',
                          style: TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.goldPrimary,
                          ),
                        ),
                        if (athleteId.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          IconButton(
                            icon: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 28),
                            tooltip: 'Athlete Dossier',
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              context.push('/athlete/public/$athleteId');
                            },
                          ),
                          const Text(
                            'DOSSIER',
                            style: TextStyle(
                              fontFamily: 'Space Grotesk',
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        // Share
                        IconButton(
                          icon: const Icon(Icons.share_outlined, color: Colors.white, size: 26),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            if (rawUrl.isNotEmpty) {
                              Clipboard.setData(ClipboardData(text: rawUrl));
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              CrystalSnackBar(
                                content: const Text('Clip link copied to clipboard'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                        const Text(
                          'SHARE',
                          style: TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Athlete & Technical HUD Overlay
                Positioned(
                  left: 16,
                  right: 86,
                  bottom: MainShellScope.bottomClearance(context, additionalPadding: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(1.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.goldPrimary, width: 1.5),
                            ),
                            child: ArmSphereImage.avatar(
                              imageUrl: athletePhoto.isNotEmpty ? athletePhoto : null,
                              initial: athleteName,
                              size: 32,
                              fallbackAsset: ArmSphereAssets.defaultAvatar,
                              cacheWidth: 96,
                              cacheHeight: 96,
                              semanticLabel: 'Profile photo for $athleteName',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              athleteName,
                              style: const TextStyle(
                                fontFamily: 'Space Grotesk',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: _getCategoryColor(category), width: 1.0),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                fontFamily: 'Space Grotesk',
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: _getCategoryColor(category),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (caption.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          caption,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Color _getCategoryColor(String cat) {
  switch (cat) {
    case 'HOOK':
      return AppTheme.goldPrimary;
    case 'TOPROLL':
      return AppTheme.info;
    case 'PRESS':
      return AppTheme.error;
    case 'SPARRING':
      return AppTheme.warning;
    case 'REFEREE':
      return AppTheme.success;
    default:
      return AppTheme.goldPrimary;
  }
}

String _initial(String? name) {
  final n = (name ?? '').trim();
  return n.isEmpty ? '?' : n[0].toUpperCase();
}

