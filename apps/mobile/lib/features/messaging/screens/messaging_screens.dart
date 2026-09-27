import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/messaging_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/skeleton_placeholder.dart';
import '../../../core/widgets/status_chip.dart';

/// Domain 8 / Stage 6 Convergence: Conversations List Screen (Inbox)
///
/// Implements Athlete Direct Messaging & Coordination Hub:
/// - Real conversations from GET /communication/conversations with 10s background polling.
/// - Unbundled conversation card with participant avatar, snippet, unread counter pill, and Space Grotesk typography.
/// - Eradication of nested `GlassCard` inside `ListView` in compliance with Audit Rule Item 2.2.
/// - Full `RepaintBoundary` raster isolation for smooth 60fps scrolling.
class ConversationsListScreen extends ConsumerWidget {
  const ConversationsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardSurface,
        elevation: 0,
        title: const Text(
          'Athlete Inbox',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: conversationsAsync.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(AppTheme.space16),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(height: AppTheme.space12),
          itemBuilder: (_, __) => const SkeletonPlaceholder(
            height: 76,
            borderRadius: AppTheme.radiusMedium,
          ),
        ),
        error: (error, _) => AppEmptyState(
          icon: Icons.error_outline,
          title: 'Could not load inbox',
          subtitle: error.toString(),
          ctaLabel: 'Retry',
          onCtaTap: () => ref.invalidate(conversationsProvider),
        ),
        data: (conversations) {
          if (conversations.isEmpty) {
            return const AppEmptyState(
              icon: Icons.forum_outlined,
              title: 'No conversations yet',
              subtitle:
                  'Open an athlete\'s profile and tap Message to coordinate sparring or discuss matchups.',
            );
          }
          return RefreshIndicator(
            color: AppTheme.goldPrimary,
            backgroundColor: AppTheme.cardSurface,
            onRefresh: () async => ref.invalidate(conversationsProvider),
            child: ListView.separated(
              key: const PageStorageKey<String>('conversations_list_view'),
              padding: const EdgeInsets.all(AppTheme.space16),
              itemCount: conversations.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppTheme.space12),
              itemBuilder: (context, index) {
                final c = conversations[index];
                final other =
                    c['otherParticipant'] is Map ? c['otherParticipant'] as Map : null;
                final name = other?['displayName']?.toString() ?? 'Athlete';
                final photo = other?['profilePhoto']?.toString() ?? '';
                final lastMessage =
                    c['lastMessage'] is Map ? c['lastMessage'] as Map : null;
                final snippet = lastMessage?['content']?.toString() ?? '';
                final unread = (c['unreadCount'] as num?)?.toInt() ?? 0;

                return RepaintBoundary(
                  child: ElevatedActionCard(
                    padding: const EdgeInsets.all(AppTheme.space14),
                    onTap: () => context.push('/messages/${c['id']}'),
                    child: Row(
                      children: [
                        // Avatar with 2px Ring
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: unread > 0 ? AppTheme.goldPrimary : AppTheme.border,
                              width: unread > 0 ? 2.0 : 1.0,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: AppTheme.elevatedSurface,
                            backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                            child: photo.isEmpty
                                ? Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: AppTheme.space12),
                        // Snippet Column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontWeight: unread > 0 ? FontWeight.bold : FontWeight.w600,
                                        fontSize: 15,
                                        color: AppTheme.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (unread > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.goldPrimary,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        unread > 99 ? '99+' : '$unread',
                                        style: const TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.voidBackground,
                                          fontFeatures: [FontFeature.tabularFigures()],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                snippet.isEmpty ? 'No messages yet' : snippet,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: unread > 0 ? AppTheme.textPrimary : AppTheme.textSecondary,
                                  fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: AppTheme.textMuted,
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
    );
  }
}

/// Domain 8 / Stage 6 Convergence: Chat Screen
///
/// Implements Real-time Athlete Match & Sparring Chat:
/// - Real messages from GET /communication/conversations/:id/messages with 10s polling.
/// - Unbundled tactical message bubbles with distinct red/blue/gold and cardSurface styles.
/// - Dark input composer adhering to InputDecorationTheme with tactile haptic impulse.
class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;

    HapticFeedback.lightImpact();
    setState(() => _sending = true);
    try {
      final ok = await ref
          .read(messageThreadProvider(widget.conversationId).notifier)
          .sendMessage(text);
      if (!ok && mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not send message. Please verify connection.'),
            backgroundColor: AppTheme.error,
          ),
        );
      } else if (mounted) {
        _messageController.clear();
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync =
        ref.watch(messageThreadProvider(widget.conversationId));
    final myUserId =
        ref.watch(authProvider).userProfile?['id']?.toString();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardSurface,
        elevation: 0,
        title: const Text(
          'Match Discussion',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.goldPrimary),
              ),
              error: (error, _) => AppEmptyState(
                icon: Icons.error_outline,
                title: 'Could not load messages',
                subtitle: error.toString(),
                ctaLabel: 'Retry',
                onCtaTap: () =>
                    ref.invalidate(messageThreadProvider(widget.conversationId)),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: 'No messages yet',
                    subtitle: 'Initiate match discussion or table arrangements below.',
                  );
                }
                // Newest at the bottom; list is ordered by sequence ascending.
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(AppTheme.space16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final m = messages[messages.length - 1 - index];
                    final isMine = m['senderId']?.toString() == myUserId;
                    final isDeleted = m['isDeleted'] == true;
                    final content = isDeleted
                        ? 'Message deleted by author'
                        : m['content']?.toString() ?? '';
                    final rawDate = m['createdAt']?.toString() ?? '';
                    final timeStr = rawDate.contains('T')
                        ? rawDate.split('T').last.substring(0, 5)
                        : '';

                    return Align(
                      alignment: isMine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.78,
                        ),
                        decoration: BoxDecoration(
                          color: isDeleted
                              ? AppTheme.elevatedSurface
                              : isMine
                                  ? AppTheme.goldPrimary.withValues(alpha: 0.18)
                                  : AppTheme.cardSurface,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(AppTheme.radiusMedium),
                            topRight: const Radius.circular(AppTheme.radiusMedium),
                            bottomLeft: Radius.circular(isMine ? AppTheme.radiusMedium : 4),
                            bottomRight: Radius.circular(isMine ? 4 : AppTheme.radiusMedium),
                          ),
                          border: Border.all(
                            color: isMine
                                ? AppTheme.goldPrimary.withValues(alpha: 0.4)
                                : AppTheme.border,
                            width: 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: isMine
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              content,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: isDeleted
                                    ? AppTheme.textMuted
                                    : AppTheme.textPrimary,
                                fontStyle: isDeleted
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                            ),
                            if (timeStr.isNotEmpty && !isDeleted) ...[
                              const SizedBox(height: 4),
                              Text(
                                timeStr,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textMuted,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Composer Bar
          Container(
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: const BoxDecoration(
              color: AppTheme.cardSurface,
              border: Border(top: BorderSide(color: AppTheme.border, width: 1.0)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: const TextStyle(color: AppTheme.textMuted),
                        filled: true,
                        fillColor: AppTheme.elevatedSurface,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          borderSide: const BorderSide(color: AppTheme.goldPrimary),
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.goldPrimary,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: IconButton(
                      icon: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.voidBackground,
                              ),
                            )
                          : const Icon(Icons.send, color: AppTheme.voidBackground, size: 20),
                      onPressed: _sending ? null : _send,
                    ),
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
