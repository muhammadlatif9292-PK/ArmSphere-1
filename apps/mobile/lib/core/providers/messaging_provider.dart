import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state_providers.dart';

class ConversationsNotifier extends AutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  Timer? _pollingTimer;
  bool _isPolling = false;

  @override
  Future<List<Map<String, dynamic>>> build() async {
    final repo = ref.watch(messagingRepositoryProvider);

    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _pollConversations();
    });

    ref.onDispose(() {
      _pollingTimer?.cancel();
      _pollingTimer = null;
    });

    return repo.getConversations();
  }

  Future<void> _pollConversations() async {
    if (_isPolling) return;
    _isPolling = true;
    try {
      final repo = ref.read(messagingRepositoryProvider);
      final updatedList = await repo.getConversations();
      if (state.hasValue && state.value != null) {
        if (_hasListChanged(state.value!, updatedList)) {
          state = AsyncValue.data(updatedList);
        }
      } else {
        state = AsyncValue.data(updatedList);
      }
    } catch (_) {
      // Silently ignore network errors during periodic background polling
    } finally {
      _isPolling = false;
    }
  }

  bool _hasListChanged(List<Map<String, dynamic>> oldList, List<Map<String, dynamic>> newList) {
    if (oldList.length != newList.length) return true;
    for (int i = 0; i < oldList.length; i++) {
      if (oldList[i]['id'] != newList[i]['id'] ||
          oldList[i]['unreadCount'] != newList[i]['unreadCount'] ||
          oldList[i]['lastMessage']?['id'] != newList[i]['lastMessage']?['id'] ||
          oldList[i]['lastMessage']?['content'] != newList[i]['lastMessage']?['content']) {
        return true;
      }
    }
    return false;
  }

  Future<Map<String, dynamic>?> getOrCreateConversation(String participantId) async {
    try {
      final repo = ref.read(messagingRepositoryProvider);
      final res = await repo.getOrCreateConversation(participantId);
      ref.invalidateSelf();
      return res;
    } catch (_) {
      return null;
    }
  }
}

final conversationsProvider = AsyncNotifierProvider.autoDispose<ConversationsNotifier, List<Map<String, dynamic>>>(() {
  return ConversationsNotifier();
});

class MessageThreadNotifier extends AutoDisposeFamilyAsyncNotifier<List<Map<String, dynamic>>, String> {
  Timer? _pollingTimer;
  bool _isPolling = false;

  @override
  Future<List<Map<String, dynamic>>> build(String arg) async {
    final repo = ref.watch(messagingRepositoryProvider);
    try {
      await repo.markConversationAsRead(arg);
    } catch (_) {}

    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _pollMessages();
    });

    ref.onDispose(() {
      _pollingTimer?.cancel();
      _pollingTimer = null;
    });

    return repo.getConversationMessages(arg);
  }

  Future<void> _pollMessages() async {
    if (_isPolling) return;
    _isPolling = true;
    try {
      final repo = ref.read(messagingRepositoryProvider);
      final newMessages = await repo.getConversationMessages(arg);
      if (state.hasValue && state.value != null) {
        if (_hasMessagesChanged(state.value!, newMessages)) {
          state = AsyncValue.data(newMessages);
          try {
            await repo.markConversationAsRead(arg);
          } catch (_) {}
        }
      } else {
        state = AsyncValue.data(newMessages);
      }
    } catch (_) {
      // Silently ignore network errors during periodic background polling
    } finally {
      _isPolling = false;
    }
  }

  bool _hasMessagesChanged(List<Map<String, dynamic>> oldList, List<Map<String, dynamic>> newList) {
    if (oldList.length != newList.length) return true;
    for (int i = 0; i < oldList.length; i++) {
      if (oldList[i]['id'] != newList[i]['id'] ||
          oldList[i]['content'] != newList[i]['content'] ||
          oldList[i]['isEdited'] != newList[i]['isEdited'] ||
          oldList[i]['isDeleted'] != newList[i]['isDeleted']) {
        return true;
      }
    }
    return false;
  }

  Future<bool> sendMessage(String content) async {
    try {
      final repo = ref.read(messagingRepositoryProvider);
      await repo.sendMessage(arg, content);
      final newMessages = await repo.getConversationMessages(arg);
      state = AsyncValue.data(newMessages);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> editMessage(String messageId, String content) async {
    try {
      final repo = ref.read(messagingRepositoryProvider);
      await repo.editMessage(messageId, content);
      final newMessages = await repo.getConversationMessages(arg);
      state = AsyncValue.data(newMessages);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteMessage(String messageId) async {
    try {
      final repo = ref.read(messagingRepositoryProvider);
      await repo.deleteMessage(messageId);
      final newMessages = await repo.getConversationMessages(arg);
      state = AsyncValue.data(newMessages);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final messageThreadProvider = AsyncNotifierProvider.autoDispose.family<MessageThreadNotifier, List<Map<String, dynamic>>, String>(() {
  return MessageThreadNotifier();
});
