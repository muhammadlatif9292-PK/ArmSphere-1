import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/providers/community_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/armsphere_image.dart';
import '../../../core/widgets/elevated_action_card.dart';

/// Post comments — real GET/POST /community/posts/:id/comments.
class PostCommentsScreen extends ConsumerStatefulWidget {
  final String postId;

  const PostCommentsScreen({super.key, required this.postId});

  @override
  ConsumerState<PostCommentsScreen> createState() => _PostCommentsScreenState();
}

class _PostCommentsScreenState extends ConsumerState<PostCommentsScreen> {
  final _commentController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _sending) return;

    HapticFeedback.lightImpact();
    setState(() => _sending = true);
    try {
      await ref
          .read(postCommentsProvider(widget.postId).notifier)
          .addComment(text);
      if (mounted) _commentController.clear();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.detail),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not add comment: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(postCommentsProvider(widget.postId));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            ArmSphereImage(
              assetPath: ArmSphereAssets.sealFed,
              width: 18,
              height: 18,
              fit: BoxFit.contain,
              semanticLabel: 'Official Federation Seal',
            ),
            SizedBox(width: 8),
            Text('Community Discussion'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: commentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => AppEmptyState(
                icon: Icons.error_outline,
                title: 'Could not load comments',
                subtitle: error.toString(),
                ctaLabel: 'Retry',
                onCtaTap: () =>
                    ref.invalidate(postCommentsProvider(widget.postId)),
              ),
              data: (comments) {
                if (comments.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: 'No comments yet',
                    subtitle: 'Start the conversation below with athletic feedback or analysis.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(postCommentsProvider(widget.postId)),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    itemCount: comments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppTheme.space10),
                    itemBuilder: (context, index) {
                      final c = comments[index];
                      final athlete =
                          c['athlete'] is Map ? c['athlete'] as Map : null;
                      final name =
                          athlete?['displayName']?.toString() ?? 'Athlete';
                      final photo = athlete?['profilePhoto']?.toString() ?? '';
                      final createdAt = c['createdAt']?.toString().split('T').first ?? '';

                      return RepaintBoundary(
                        child: ElevatedActionCard(
                          padding: const EdgeInsets.all(AppTheme.space12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ArmSphereImage.avatar(
                                imageUrl: photo.isNotEmpty ? photo : null,
                                initial: name,
                                size: 36,
                                fallbackAsset: ArmSphereAssets.defaultAvatar,
                                cacheWidth: 108,
                                cacheHeight: 108,
                                semanticLabel: 'Profile photo for $name',
                              ),
                              const SizedBox(width: AppTheme.space12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontFamily: AppTheme.fontDisplay,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        if (createdAt.isNotEmpty)
                                          Text(
                                            createdAt,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.textMuted,
                                              fontFeatures: [FontFeature.tabularFigures()],
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: AppTheme.space4),
                                    Text(
                                      c['body']?.toString() ?? '',
                                      style: const TextStyle(fontSize: 13, height: 1.35, color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space12),
              decoration: const BoxDecoration(
                color: AppTheme.background,
                border: Border(top: BorderSide(color: AppTheme.cardBorder, width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: 'Add an athletic analysis or comment...',
                        isDense: true,
                      ),
                      onSubmitted: (_) => _addComment(),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space8),
                  IconButton(
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send, color: AppTheme.primaryRed),
                    onPressed: _sending ? null : _addComment,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
