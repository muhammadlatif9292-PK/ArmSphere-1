import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state_providers.dart';

// 1. Filter state model
class VenueFilter {
  final String city;
  final String province;

  const VenueFilter({this.city = '', this.province = ''});

  VenueFilter copyWith({String? city, String? province}) {
    return VenueFilter(
      city: city ?? this.city,
      province: province ?? this.province,
    );
  }
}

// Filter Provider
final venueFilterProvider = StateProvider.autoDispose<VenueFilter>((ref) {
  return const VenueFilter();
});

// 2. Notifier to manage the venues directory list
class VenueListNotifier extends AutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final filter = ref.watch(venueFilterProvider);
    final repo = ref.watch(venueRepositoryProvider);
    return repo.getVenues(
      city: filter.city.isEmpty ? null : filter.city,
      province: filter.province.isEmpty ? null : filter.province,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final filter = ref.read(venueFilterProvider);
      final repo = ref.read(venueRepositoryProvider);
      final venues = await repo.getVenues(
        city: filter.city.isEmpty ? null : filter.city,
        province: filter.province.isEmpty ? null : filter.province,
      );
      state = AsyncValue.data(venues);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final venueListProvider = AsyncNotifierProvider.autoDispose<VenueListNotifier, List<Map<String, dynamic>>>(() {
  return VenueListNotifier();
});

// 3. Notifier for individual Venue detail view
class VenueDetailNotifier extends AutoDisposeFamilyAsyncNotifier<Map<String, dynamic>, String> {
  @override
  Future<Map<String, dynamic>> build(String arg) async {
    final repo = ref.watch(venueRepositoryProvider);
    return repo.getVenueById(arg);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(venueRepositoryProvider);
      final detail = await repo.getVenueById(arg);
      state = AsyncValue.data(detail);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final venueDetailProvider = AsyncNotifierProvider.autoDispose.family<VenueDetailNotifier, Map<String, dynamic>, String>(() {
  return VenueDetailNotifier();
});

// 4. Notifier for Submitting a new Venue
class VenueSubmissionNotifier extends AutoDisposeAsyncNotifier<Map<String, dynamic>?> {
  @override
  Future<Map<String, dynamic>?> build() async {
    return null;
  }

  Future<void> submit({
    required String name,
    required String city,
    required String province,
    required String address,
    String? contactInfo,
    String? description,
    String? logoUrl,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(venueRepositoryProvider);
      final newVenue = await repo.submitVenue(
        name: name,
        city: city,
        province: province,
        address: address,
        contactInfo: contactInfo,
        description: description,
        logoUrl: logoUrl,
      );
      state = AsyncValue.data(newVenue);
      
      // Invalidate the venue list so it re-fetches with the new entry
      ref.invalidate(venueListProvider);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}

final venueSubmissionProvider = AsyncNotifierProvider.autoDispose<VenueSubmissionNotifier, Map<String, dynamic>?>(() {
  return VenueSubmissionNotifier();
});
