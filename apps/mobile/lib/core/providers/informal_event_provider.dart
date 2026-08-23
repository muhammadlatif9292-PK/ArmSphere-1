import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state_providers.dart';

// 1. Filter state model
class InformalEventFilter {
  final String city;
  final String startDate;
  final String endDate;

  const InformalEventFilter({
    this.city = '',
    this.startDate = '',
    this.endDate = '',
  });

  InformalEventFilter copyWith({
    String? city,
    String? startDate,
    String? endDate,
  }) {
    return InformalEventFilter(
      city: city ?? this.city,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

// Filter Provider
final informalEventFilterProvider = StateProvider.autoDispose<InformalEventFilter>((ref) {
  return const InformalEventFilter();
});

// 2. Notifier to manage the informal events list
class InformalEventListNotifier extends AutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final filter = ref.watch(informalEventFilterProvider);
    final repo = ref.watch(informalEventRepositoryProvider);
    return repo.getEvents(
      city: filter.city.isEmpty ? null : filter.city,
      startDate: filter.startDate.isEmpty ? null : filter.startDate,
      endDate: filter.endDate.isEmpty ? null : filter.endDate,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final filter = ref.read(informalEventFilterProvider);
      final repo = ref.read(informalEventRepositoryProvider);
      final events = await repo.getEvents(
        city: filter.city.isEmpty ? null : filter.city,
        startDate: filter.startDate.isEmpty ? null : filter.startDate,
        endDate: filter.endDate.isEmpty ? null : filter.endDate,
      );
      state = AsyncValue.data(events);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final informalEventListProvider = AsyncNotifierProvider.autoDispose<InformalEventListNotifier, List<Map<String, dynamic>>>(() {
  return InformalEventListNotifier();
});

// 3. Notifier for individual informal event detail view
class InformalEventDetailNotifier extends AutoDisposeFamilyAsyncNotifier<Map<String, dynamic>, String> {
  @override
  Future<Map<String, dynamic>> build(String arg) async {
    final repo = ref.watch(informalEventRepositoryProvider);
    return repo.getEventById(arg);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(informalEventRepositoryProvider);
      final detail = await repo.getEventById(arg);
      state = AsyncValue.data(detail);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> join() async {
    final repo = ref.read(informalEventRepositoryProvider);
    await repo.joinEvent(arg);
    // Refresh detail and invalid list
    await refresh();
    ref.invalidate(informalEventListProvider);
  }

  Future<void> leave() async {
    final repo = ref.read(informalEventRepositoryProvider);
    await repo.leaveEvent(arg);
    // Refresh detail and invalid list
    await refresh();
    ref.invalidate(informalEventListProvider);
  }

  Future<void> cancel() async {
    final repo = ref.read(informalEventRepositoryProvider);
    await repo.deleteEvent(arg);
    ref.invalidate(informalEventListProvider);
  }
}

final informalEventDetailProvider = AsyncNotifierProvider.autoDispose.family<InformalEventDetailNotifier, Map<String, dynamic>, String>(() {
  return InformalEventDetailNotifier();
});

// 4. Notifier for creating a new informal event
class InformalEventCreationNotifier extends AutoDisposeAsyncNotifier<Map<String, dynamic>?> {
  @override
  Future<Map<String, dynamic>?> build() async {
    return null;
  }

  Future<void> create({
    required String title,
    required String description,
    required String city,
    String? province,
    required String scheduledAt,
    int? maxParticipants,
    bool isPublic = true,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(informalEventRepositoryProvider);
      final newEvent = await repo.createEvent(
        title: title,
        description: description,
        city: city,
        province: province,
        scheduledAt: scheduledAt,
        maxParticipants: maxParticipants,
        isPublic: isPublic,
      );
      state = AsyncValue.data(newEvent);
      ref.invalidate(informalEventListProvider);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}

final informalEventCreationProvider = AsyncNotifierProvider.autoDispose<InformalEventCreationNotifier, Map<String, dynamic>?>(() {
  return InformalEventCreationNotifier();
});
