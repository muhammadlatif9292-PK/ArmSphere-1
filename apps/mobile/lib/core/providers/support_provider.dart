import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state_providers.dart';

/// Notifier to list and create support tickets (optionally filtered by status).
class SupportTicketsNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<Map<String, dynamic>>, String?> {
  @override
  Future<List<Map<String, dynamic>>> build(String? arg) async {
    final repo = ref.watch(supportRepositoryProvider);
    return repo.listTickets(status: arg);
  }

  Future<Map<String, dynamic>> createTicket({
    required String subject,
    required String description,
    String category = 'GENERAL',
    String priority = 'MEDIUM',
  }) async {
    final repo = ref.read(supportRepositoryProvider);
    final created = await repo.createTicket(
      subject: subject,
      description: description,
      category: category,
      priority: priority,
    );
    ref.invalidateSelf();
    return created;
  }
}

final supportTicketsProvider = AsyncNotifierProvider.autoDispose
    .family<SupportTicketsNotifier, List<Map<String, dynamic>>, String?>(() {
  return SupportTicketsNotifier();
});

/// Notifier to view and mutate a single support ticket thread.
class SupportTicketDetailNotifier
    extends AutoDisposeFamilyAsyncNotifier<Map<String, dynamic>, String> {
  @override
  Future<Map<String, dynamic>> build(String arg) async {
    final repo = ref.watch(supportRepositoryProvider);
    return repo.getTicket(arg);
  }

  Future<Map<String, dynamic>> addMessage(
    String content, {
    bool isInternal = false,
  }) async {
    final repo = ref.read(supportRepositoryProvider);
    final msg = await repo.addTicketMessage(
      arg,
      content,
      isInternal: isInternal,
    );
    ref.invalidateSelf();
    ref.invalidate(supportTicketsProvider(null));
    return msg;
  }

  Future<Map<String, dynamic>> updateStatus(
    String status, {
    String? resolutionNotes,
  }) async {
    final repo = ref.read(supportRepositoryProvider);
    final updated = await repo.updateTicketStatus(
      arg,
      status,
      resolutionNotes: resolutionNotes,
    );
    ref.invalidateSelf();
    ref.invalidate(supportTicketsProvider(null));
    return updated;
  }

  Future<Map<String, dynamic>> assignTicket(String assignedAgentId) async {
    final repo = ref.read(supportRepositoryProvider);
    final updated = await repo.assignTicket(arg, assignedAgentId);
    ref.invalidateSelf();
    ref.invalidate(supportTicketsProvider(null));
    return updated;
  }
}

final supportTicketDetailProvider = AsyncNotifierProvider.autoDispose
    .family<SupportTicketDetailNotifier, Map<String, dynamic>, String>(() {
  return SupportTicketDetailNotifier();
});
