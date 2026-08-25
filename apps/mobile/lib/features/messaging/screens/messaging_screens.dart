import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/messaging_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/skeleton_placeholder.dart';

/// Inbox — real conversations from GET /communication/conversations
/// with 10s background polling via conversationsProvider.
class ConversationsListScreen extends ConsumerWidget {
  const ConversationsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Inbox')),
      body: conversationsAsync.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, __) => const SkeletonPlaceholder(height: 72),
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
                  'Open an athlete\'s profile and tap Message to start a conversation.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(conversationsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: conversations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final c = conversations[index];
                final other =
                    c['otherParticipant'] is Map ? c['otherParticipant'] as Map : null;
                final name = other?['displayName']?.toString() ?? 'Unknown';
                final lastMessage =
                    c['lastMessage'] is Map ? c['lastMessage'] as Map : null;
                final snippet = lastMessage?['content']?.toString() ?? '';
                final unread = (c['unreadCount'] as num?)?.toInt() ?? 0;

                return GestureDetector(
                  onTap: () => context.push('/messages/${c['id']}'),
                  child: GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: other?['profilePhoto'] != null &&
                                other!['profilePhoto'].toString().isNotEmpty
                            ? NetworkImage(other['profilePhoto'].toString())
                            : null,
                        child: other?['profilePhoto'] == null ||
                                other!['profilePhoto'].toString().isEmpty
                            ? Text(name[0].toUpperCase())
                            : null,
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ),
                          if (unread > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                unread > 99 ? '99+' : '$unread',
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        snippet.isEmpty ? 'No messages yet' : snippet,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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

/// Chat thread — real messages from GET /communication/conversations/:id/messages
/// with 10s polling via messageThreadProvider; sends via POST.
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

    setState(() => _sending = true);
    try {
      final ok = await ref
          .read(messageThreadProvider(widget.conversationId).notifier)
          .sendMessage(text);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not send message'),
              backgroundColor: Colors.red),
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
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
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
                    subtitle: 'Say hello below.',
                  );
                }
                // Newest at the bottom; list is ordered by sequence ascending.
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final m =
                        messages[messages.length - 1 - index];
                    final isMine =
                        m['senderId']?.toString() == myUserId;
                    final content = m['isDeleted'] == true
                        ? 'Message deleted'
                        : m['content']?.toString() ?? '';

                    return Align(
                      alignment: isMine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: m['isDeleted'] == true
                              ? AppTheme.border
                              : isMine
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          content,
                          style: TextStyle(
                            color: isMine &&
                                    m['isDeleted'] != true
                                ? Colors.white
                                : null,
                            fontStyle: m['isDeleted'] == true
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                          hintText: 'Type your message...'),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send),
                    onPressed: _sending ? null : _send,
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
