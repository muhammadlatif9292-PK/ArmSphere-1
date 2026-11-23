import 'dart:async';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/providers/dependency_providers.dart';
import '../../../core/providers/state_providers.dart';
import '../../auth/providers/auth_provider.dart';

/// Canonical pin categories returned by `GET /api/radar/nearby`.
enum RadarPinType {
  event('EVENT', 'Event'),
  venue('VENUE', 'Venue'),
  club('CLUB', 'Club'),
  informalEvent('INFORMAL_EVENT', 'Sparring'),
  athlete('ATHLETE', 'Athlete'),
  beacon('BEACON', 'Beacon');

  final String apiValue;
  final String displayLabel;
  const RadarPinType(this.apiValue, this.displayLabel);

  static RadarPinType fromApi(String? raw) {
    switch ((raw ?? '').trim().toUpperCase()) {
      case 'EVENT':
        return RadarPinType.event;
      case 'VENUE':
        return RadarPinType.venue;
      case 'CLUB':
        return RadarPinType.club;
      case 'INFORMAL_EVENT':
        return RadarPinType.informalEvent;
      case 'BEACON':
        return RadarPinType.beacon;
      case 'ATHLETE':
      default:
        return RadarPinType.athlete;
    }
  }
}

/// Immutable tactical map pin returned from `/api/radar/nearby` or optimistically queued.
class RadarPin {
  final String id;
  final String? userId;
  final RadarPinType pinType;
  final String? beaconType;
  final String title;
  final String subtitle;
  final double latitude;
  final double longitude;
  final String? city;
  final String? province;
  final String? address;
  final String? venue;
  final String? status;
  final String? weightClass;
  final String? armPreference;
  final DateTime? startDate;
  final DateTime? scheduledAt;
  final DateTime? expiresAt;
  final String? athleteName;
  final int? rightArmElo;
  final int? leftArmElo;
  final bool isVerified;
  final bool isFuzzed;
  final bool isPendingOffline;

  const RadarPin({
    required this.id,
    this.userId,
    required this.pinType,
    this.beaconType,
    required this.title,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
    this.city,
    this.province,
    this.address,
    this.venue,
    this.status,
    this.weightClass,
    this.armPreference,
    this.startDate,
    this.scheduledAt,
    this.expiresAt,
    this.athleteName,
    this.rightArmElo,
    this.leftArmElo,
    this.isVerified = false,
    this.isFuzzed = false,
    this.isPendingOffline = false,
  });

  LatLng get latLng => LatLng(latitude, longitude);

  bool get isExpired {
    if (pinType != RadarPinType.beacon || expiresAt == null) return false;
    return expiresAt!.isBefore(DateTime.now().toUtc());
  }

  bool isOwnedBy(String? currentUserId) {
    if (currentUserId == null || currentUserId.isEmpty || userId == null) {
      return false;
    }
    return userId == currentUserId;
  }

  /// Human-readable countdown until beacon expiry.
  String? get expiryRemainingLabel {
    if (expiresAt == null) return null;
    final diff = expiresAt!.toUtc().difference(DateTime.now().toUtc());
    if (diff.isNegative) return 'Expired';
    if (diff.inDays >= 1) {
      final remHours = diff.inHours % 24;
      return remHours > 0 ? '${diff.inDays}d ${remHours}h left' : '${diff.inDays}d left';
    }
    if (diff.inHours >= 1) {
      final remMins = diff.inMinutes % 60;
      return remMins > 0 ? '${diff.inHours}h ${remMins}m left' : '${diff.inHours}h left';
    }
    final mins = math.max(1, diff.inMinutes);
    return '${mins}m left';
  }

  /// Great-circle Haversine distance in kilometers from [origin].
  double distanceKmFrom(LatLng origin) {
    const double earthRadiusKm = 6371.0;
    final dLat = _degToRad(latitude - origin.latitude);
    final dLng = _degToRad(longitude - origin.longitude);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(origin.latitude)) *
            math.cos(_degToRad(latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);

  factory RadarPin.fromMap(Map<String, dynamic> map) {
    final type = RadarPinType.fromApi(map['pinType']?.toString());
    final lat = (map['latitude'] as num?)?.toDouble() ?? 0.0;
    final lng = (map['longitude'] as num?)?.toDouble() ?? 0.0;
    return RadarPin(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString(),
      pinType: type,
      beaconType: map['beaconType']?.toString(),
      title: map['title']?.toString() ?? 'ArmSphere Pin',
      subtitle: map['subtitle']?.toString() ?? '',
      latitude: lat,
      longitude: lng,
      city: map['city']?.toString(),
      province: map['province']?.toString(),
      address: map['address']?.toString(),
      venue: map['venue']?.toString(),
      status: map['status']?.toString(),
      weightClass: map['weightClass']?.toString(),
      armPreference: (map['armPreference'] ?? map['dominantArm'])?.toString(),
      startDate: map['startDate'] != null
          ? DateTime.tryParse(map['startDate'].toString())
          : null,
      scheduledAt: map['scheduledAt'] != null
          ? DateTime.tryParse(map['scheduledAt'].toString())
          : null,
      expiresAt: map['expiresAt'] != null
          ? DateTime.tryParse(map['expiresAt'].toString())
          : null,
      athleteName: map['athleteName']?.toString(),
      rightArmElo: (map['rightArmElo'] as num?)?.toInt(),
      leftArmElo: (map['leftArmElo'] as num?)?.toInt(),
      isVerified: map['isVerified'] == true,
      isFuzzed: map['isFuzzed'] == true,
      isPendingOffline: map['isPendingOffline'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      if (userId != null) 'userId': userId,
      'pinType': pinType.apiValue,
      if (beaconType != null) 'beaconType': beaconType,
      'title': title,
      'subtitle': subtitle,
      'latitude': latitude,
      'longitude': longitude,
      if (city != null) 'city': city,
      if (province != null) 'province': province,
      if (address != null) 'address': address,
      if (venue != null) 'venue': venue,
      if (status != null) 'status': status,
      if (weightClass != null) 'weightClass': weightClass,
      if (armPreference != null) 'armPreference': armPreference,
      if (startDate != null) 'startDate': startDate!.toUtc().toIso8601String(),
      if (scheduledAt != null) 'scheduledAt': scheduledAt!.toUtc().toIso8601String(),
      if (expiresAt != null) 'expiresAt': expiresAt!.toUtc().toIso8601String(),
      if (athleteName != null) 'athleteName': athleteName,
      if (rightArmElo != null) 'rightArmElo': rightArmElo,
      if (leftArmElo != null) 'leftArmElo': leftArmElo,
      'isVerified': isVerified,
      'isFuzzed': isFuzzed,
      'isPendingOffline': isPendingOffline,
    };
  }
}

/// Active filter configuration for the Tactical Radar view.
class RadarFilterState {
  final bool showEvents;
  final bool showVenues;
  final bool showAthletes;
  final bool showBeacons;
  final bool showInformalEvents;
  final String? weightClass;
  final String? armPreference;
  final double? maxDistanceKm;

  const RadarFilterState({
    this.showEvents = true,
    this.showVenues = true,
    this.showAthletes = true,
    this.showBeacons = true,
    this.showInformalEvents = true,
    this.weightClass,
    this.armPreference,
    this.maxDistanceKm,
  });

  bool get hasActiveFilters =>
      !showEvents ||
      !showVenues ||
      !showAthletes ||
      !showBeacons ||
      !showInformalEvents ||
      (weightClass != null && weightClass!.isNotEmpty) ||
      (armPreference != null && armPreference!.isNotEmpty) ||
      maxDistanceKm != null;

  RadarFilterState copyWith({
    bool? showEvents,
    bool? showVenues,
    bool? showAthletes,
    bool? showBeacons,
    bool? showInformalEvents,
    String? weightClass,
    bool clearWeightClass = false,
    String? armPreference,
    bool clearArmPreference = false,
    double? maxDistanceKm,
    bool clearMaxDistance = false,
  }) {
    return RadarFilterState(
      showEvents: showEvents ?? this.showEvents,
      showVenues: showVenues ?? this.showVenues,
      showAthletes: showAthletes ?? this.showAthletes,
      showBeacons: showBeacons ?? this.showBeacons,
      showInformalEvents: showInformalEvents ?? this.showInformalEvents,
      weightClass: clearWeightClass ? null : (weightClass ?? this.weightClass),
      armPreference: clearArmPreference ? null : (armPreference ?? this.armPreference),
      maxDistanceKm: clearMaxDistance ? null : (maxDistanceKm ?? this.maxDistanceKm),
    );
  }
}

class RadarState {
  final List<RadarPin> allPins;
  final List<RadarPin> visiblePins;
  final RadarFilterState filter;
  final bool isLoading;
  final bool isFromCache;
  final bool isOfflineNoCache;
  final DateTime? lastUpdatedAt;
  final String? errorMessage;
  final String? selectedPinId;
  final LatLng? referenceCenter;

  const RadarState({
    this.allPins = const [],
    this.visiblePins = const [],
    this.filter = const RadarFilterState(),
    this.isLoading = false,
    this.isFromCache = false,
    this.isOfflineNoCache = false,
    this.lastUpdatedAt,
    this.errorMessage,
    this.selectedPinId,
    this.referenceCenter,
  });

  bool hasOwnActiveBeacon(String? currentUserId) {
    if (currentUserId == null || currentUserId.isEmpty) return false;
    return allPins.any(
      (p) =>
          p.pinType == RadarPinType.beacon &&
          !p.isExpired &&
          p.isOwnedBy(currentUserId),
    );
  }

  String get cacheAgeLabel {
    if (lastUpdatedAt == null) return 'Cached';
    final mins = DateTime.now().difference(lastUpdatedAt!).inMinutes;
    if (mins < 1) return 'Cached — Updated just now';
    if (mins == 1) return 'Cached — Last updated 1 minute ago';
    if (mins < 60) return 'Cached — Last updated $mins minutes ago';
    final hours = mins ~/ 60;
    return hours == 1
        ? 'Cached — Last updated 1 hour ago'
        : 'Cached — Last updated $hours hours ago';
  }

  RadarState copyWith({
    List<RadarPin>? allPins,
    List<RadarPin>? visiblePins,
    RadarFilterState? filter,
    bool? isLoading,
    bool? isFromCache,
    bool? isOfflineNoCache,
    DateTime? lastUpdatedAt,
    String? errorMessage,
    bool clearError = false,
    String? selectedPinId,
    bool clearSelection = false,
    LatLng? referenceCenter,
  }) {
    return RadarState(
      allPins: allPins ?? this.allPins,
      visiblePins: visiblePins ?? this.visiblePins,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      isFromCache: isFromCache ?? this.isFromCache,
      isOfflineNoCache: isOfflineNoCache ?? this.isOfflineNoCache,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedPinId: clearSelection ? null : (selectedPinId ?? this.selectedPinId),
      referenceCenter: referenceCenter ?? this.referenceCenter,
    );
  }
}

class RadarNotifier extends AutoDisposeNotifier<RadarState> {
  static const String _lastNearbyCacheKey = 'radar_last_nearby_pins_v1';
  static const String _lastNearbyTsKey = 'radar_last_nearby_ts_v1';
  static const String _pendingBeaconsKey = 'radar_pending_beacons_v1';

  Timer? _debounceTimer;
  Timer? _expiryTimer;
  CancelToken? _activeCancelToken;
  LatLngBounds? _lastBounds;

  @override
  RadarState build() {
    ref.onDispose(() {
      _debounceTimer?.cancel();
      _expiryTimer?.cancel();
      _activeCancelToken?.cancel('disposed');
    });

    // Client-side safety net: prune expired beacons every 60 seconds automatically.
    _expiryTimer?.cancel();
    _expiryTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      pruneExpiredBeacons();
    });

    return const RadarState();
  }

  /// Debounced viewport fetch (~500ms) triggered on map pan/zoom.
  void scheduleViewportFetch(
    LatLngBounds bounds, {
    LatLng? referenceCenter,
    bool immediate = false,
  }) {
    _lastBounds = bounds;
    if (referenceCenter != null) {
      state = state.copyWith(referenceCenter: referenceCenter);
    }
    _debounceTimer?.cancel();
    if (immediate) {
      _fetchViewportNow(bounds);
    } else {
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        _fetchViewportNow(bounds);
      });
    }
  }

  Future<void> refreshCurrentViewport() async {
    if (_lastBounds != null) {
      await _fetchViewportNow(_lastBounds!);
    }
  }

  Future<void> _fetchViewportNow(LatLngBounds bounds) async {
    _activeCancelToken?.cancel('superseded');
    final cancelToken = CancelToken();
    _activeCancelToken = cancelToken;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repo = ref.read(radarRepositoryProvider);
      final response = await repo.getNearby(
        north: bounds.north,
        south: bounds.south,
        east: bounds.east,
        west: bounds.west,
        weightClass: state.filter.weightClass,
        armPreference: state.filter.armPreference,
        cancelToken: cancelToken,
      );

      if (cancelToken.isCancelled) return;

      final rawPins = (response['pins'] as List?) ?? const [];
      final serverPins = rawPins
          .whereType<Map>()
          .map((m) => RadarPin.fromMap(Map<String, dynamic>.from(m)))
          .where((p) => !p.isExpired)
          .toList();

      final pending = _loadPendingBeacons();
      final merged = _mergePins(serverPins, pending);
      final now = DateTime.now();

      // Persist last successful Radar response for offline resilience.
      final hive = ref.read(hiveStorageProvider);
      await hive.cacheData(
        _lastNearbyCacheKey,
        merged.map((p) => p.toMap()).toList(),
      );
      await hive.cacheData(_lastNearbyTsKey, now.millisecondsSinceEpoch);

      state = state.copyWith(
        allPins: merged,
        visiblePins: _applyFilters(merged, state.filter, state.referenceCenter),
        isLoading: false,
        isFromCache: false,
        isOfflineNoCache: false,
        lastUpdatedAt: now,
        clearError: true,
      );
    } on OfflineException {
      if (cancelToken.isCancelled) return;
      _hydrateFromCacheOrShowOffline();
    } catch (e) {
      if (cancelToken.isCancelled) return;
      final isCancelled = e.toString().toLowerCase().contains('cancelled');
      if (isCancelled) return;

      // Fallback cleanly to cached Radar snapshot if available.
      final hydrated = _hydrateFromCacheOrShowOffline();
      if (!hydrated) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Unable to load Radar data right now.',
        );
      }
    }
  }

  bool _hydrateFromCacheOrShowOffline() {
    final hive = ref.read(hiveStorageProvider);
    final rawCached = hive.getCachedData(_lastNearbyCacheKey);
    final rawTs = hive.getCachedData(_lastNearbyTsKey);
    final pending = _loadPendingBeacons();

    final cachedPins = <RadarPin>[];
    if (rawCached is List) {
      for (final item in rawCached) {
        if (item is Map) {
          final pin = RadarPin.fromMap(Map<String, dynamic>.from(item));
          if (!pin.isExpired) {
            cachedPins.add(pin);
          }
        }
      }
    }

    final merged = _mergePins(cachedPins, pending);
    if (merged.isNotEmpty || rawTs != null) {
      final ts = rawTs is num
          ? DateTime.fromMillisecondsSinceEpoch(rawTs.toInt())
          : DateTime.now();
      state = state.copyWith(
        allPins: merged,
        visiblePins: _applyFilters(merged, state.filter, state.referenceCenter),
        isLoading: false,
        isFromCache: true,
        isOfflineNoCache: false,
        lastUpdatedAt: ts,
        clearError: true,
      );
      return true;
    }

    state = state.copyWith(
      allPins: const [],
      visiblePins: const [],
      isLoading: false,
      isFromCache: false,
      isOfflineNoCache: true,
      clearError: true,
    );
    return false;
  }

  void updateFilter(RadarFilterState newFilter) {
    final needsServerRefetch = newFilter.weightClass != state.filter.weightClass ||
        newFilter.armPreference != state.filter.armPreference;
    state = state.copyWith(
      filter: newFilter,
      visiblePins: _applyFilters(state.allPins, newFilter, state.referenceCenter),
    );
    if (needsServerRefetch && _lastBounds != null) {
      scheduleViewportFetch(_lastBounds!, immediate: true);
    }
  }

  void selectPin(String? pinId) {
    state = state.copyWith(
      selectedPinId: pinId,
      clearSelection: pinId == null,
    );
  }

  void pruneExpiredBeacons() {
    final active = state.allPins.where((p) => !p.isExpired).toList();
    if (active.length != state.allPins.length) {
      state = state.copyWith(
        allPins: active,
        visiblePins: _applyFilters(active, state.filter, state.referenceCenter),
      );
    }
  }

  /// Drops a temporary Radar beacon with optimistic UI + offline outbox support.
  Future<({RadarPin pin, bool queuedOffline})> dropBeacon({
    required String beaconType,
    required String title,
    required double latitude,
    required double longitude,
    String? weightClass,
    String? armPreference,
    required int durationHours,
  }) async {
    final auth = ref.read(authProvider);
    final profile = auth.userProfile;
    final currentUserId =
        (profile?['id'] ?? profile?['userId'] ?? '').toString().trim();
    final athleteName =
        (profile?['displayName'] ?? profile?['fullName'] ?? 'You').toString();

    final expiresAt = DateTime.now().toUtc().add(Duration(hours: durationHours));
    final tempId = 'local_beacon_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticPin = RadarPin(
      id: tempId,
      userId: currentUserId.isNotEmpty ? currentUserId : null,
      pinType: RadarPinType.beacon,
      beaconType: beaconType.toUpperCase(),
      title: title.trim(),
      subtitle: athleteName,
      latitude: latitude,
      longitude: longitude,
      weightClass: weightClass,
      armPreference: armPreference,
      expiresAt: expiresAt,
      athleteName: athleteName,
      isFuzzed: false,
      isPendingOffline: true,
    );

    // 1. Optimistically drop the live pulsing crimson pin onto the map immediately.
    final optimisticAll = <RadarPin>[optimisticPin, ...state.allPins];
    state = state.copyWith(
      allPins: optimisticAll,
      visiblePins: _applyFilters(optimisticAll, state.filter, state.referenceCenter),
      selectedPinId: optimisticPin.id,
      isOfflineNoCache: false,
    );

    try {
      final repo = ref.read(radarRepositoryProvider);
      final created = await repo.createBeacon(
        beaconType: beaconType,
        title: title,
        latitude: latitude,
        longitude: longitude,
        weightClass: weightClass,
        armPreference: armPreference,
        durationHours: durationHours,
      );

      final serverPin = RadarPin(
        id: created['id']?.toString() ?? tempId,
        userId: created['userId']?.toString() ?? optimisticPin.userId,
        pinType: RadarPinType.beacon,
        beaconType: created['beaconType']?.toString() ?? beaconType.toUpperCase(),
        title: created['title']?.toString() ?? title.trim(),
        subtitle: athleteName,
        latitude: (created['latitude'] as num?)?.toDouble() ?? latitude,
        longitude: (created['longitude'] as num?)?.toDouble() ?? longitude,
        weightClass: created['weightClass']?.toString() ?? weightClass,
        armPreference: created['armPreference']?.toString() ?? armPreference,
        expiresAt: created['expiresAt'] != null
            ? DateTime.tryParse(created['expiresAt'].toString()) ?? expiresAt
            : expiresAt,
        athleteName: athleteName,
        isFuzzed: false,
        isPendingOffline: false,
      );

      final replaced = state.allPins
          .map((p) => p.id == tempId ? serverPin : p)
          .toList();
      state = state.copyWith(
        allPins: replaced,
        visiblePins: _applyFilters(replaced, state.filter, state.referenceCenter),
        selectedPinId: serverPin.id,
      );
      return (pin: serverPin, queuedOffline: false);
    } on OfflineException {
      // Queue cleanly into OfflineSyncManager outbox + local Hive pending list.
      await ref.read(offlineSyncManagerProvider).enqueueSpatialMutation(
        actionType: 'CREATE_RADAR_BEACON',
        endpoint: '/radar/beacons',
        method: 'POST',
        latitude: latitude,
        longitude: longitude,
        payload: <String, dynamic>{
          'beaconType': beaconType.trim().toUpperCase(),
          'title': title.trim(),
          if (weightClass != null && weightClass.trim().isNotEmpty)
            'weightClass': weightClass.trim(),
          if (armPreference != null && armPreference.trim().isNotEmpty)
            'armPreference': armPreference.trim().toUpperCase(),
          'durationHours': durationHours,
          'expiresAt': expiresAt.toIso8601String(),
        },
      );
      await _savePendingBeacon(optimisticPin);
      return (pin: optimisticPin, queuedOffline: true);
    } catch (_) {
      // Network/transient fallback: keep beacon queued offline so user never loses it.
      await ref.read(offlineSyncManagerProvider).enqueueSpatialMutation(
        actionType: 'CREATE_RADAR_BEACON',
        endpoint: '/radar/beacons',
        method: 'POST',
        latitude: latitude,
        longitude: longitude,
        payload: <String, dynamic>{
          'beaconType': beaconType.trim().toUpperCase(),
          'title': title.trim(),
          if (weightClass != null && weightClass.trim().isNotEmpty)
            'weightClass': weightClass.trim(),
          if (armPreference != null && armPreference.trim().isNotEmpty)
            'armPreference': armPreference.trim().toUpperCase(),
          'durationHours': durationHours,
          'expiresAt': expiresAt.toIso8601String(),
        },
      );
      await _savePendingBeacon(optimisticPin);
      return (pin: optimisticPin, queuedOffline: true);
    }
  }

  /// Deletes an owned active beacon immediately and syncs deletion to the API.
  Future<bool> deleteBeacon(String beaconId) async {
    final previousAll = state.allPins;
    final remaining = previousAll.where((p) => p.id != beaconId).toList();
    state = state.copyWith(
      allPins: remaining,
      visiblePins: _applyFilters(remaining, state.filter, state.referenceCenter),
      clearSelection: state.selectedPinId == beaconId,
    );

    if (beaconId.startsWith('local_beacon_')) {
      await _removePendingBeacon(beaconId);
      return true;
    }

    try {
      await ref.read(radarRepositoryProvider).deleteBeacon(beaconId);
      return true;
    } on OfflineException {
      await ref.read(hiveStorageProvider).enqueueAction(
        actionType: 'DELETE_RADAR_BEACON',
        endpoint: '/radar/beacons/$beaconId',
        method: 'DELETE',
        payload: <String, dynamic>{'id': beaconId},
      );
      return true;
    } catch (_) {
      // Restore on hard authorization / server failure.
      state = state.copyWith(
        allPins: previousAll,
        visiblePins: _applyFilters(previousAll, state.filter, state.referenceCenter),
      );
      return false;
    }
  }

  List<RadarPin> _loadPendingBeacons() {
    try {
      final raw = ref.read(hiveStorageProvider).getCachedData(_pendingBeaconsKey);
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((m) => RadarPin.fromMap(Map<String, dynamic>.from(m)))
            .where((p) => !p.isExpired)
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  Future<void> _savePendingBeacon(RadarPin pin) async {
    final existing = _loadPendingBeacons();
    final updated = [pin, ...existing.where((p) => p.id != pin.id)];
    await ref.read(hiveStorageProvider).cacheData(
      _pendingBeaconsKey,
      updated.map((p) => p.toMap()).toList(),
    );
  }

  Future<void> _removePendingBeacon(String beaconId) async {
    final existing = _loadPendingBeacons();
    final updated = existing.where((p) => p.id != beaconId).toList();
    await ref.read(hiveStorageProvider).cacheData(
      _pendingBeaconsKey,
      updated.map((p) => p.toMap()).toList(),
    );
  }

  List<RadarPin> _mergePins(List<RadarPin> primary, List<RadarPin> pending) {
    final byId = <String, RadarPin>{};
    for (final p in pending) {
      if (!p.isExpired) byId[p.id] = p;
    }
    for (final p in primary) {
      if (!p.isExpired) byId[p.id] = p;
    }
    return byId.values.toList();
  }

  List<RadarPin> _applyFilters(
    List<RadarPin> pins,
    RadarFilterState filter,
    LatLng? referenceCenter,
  ) {
    return pins.where((pin) {
      if (pin.isExpired) return false;
      switch (pin.pinType) {
        case RadarPinType.event:
          if (!filter.showEvents) return false;
          // Defensive client-side guard: never show DRAFT or CANCELLED tournaments
          final st = (pin.status ?? '').toUpperCase();
          if (st == 'DRAFT' || st == 'CANCELLED') return false;
          break;
        case RadarPinType.venue:
        case RadarPinType.club:
          if (!filter.showVenues) return false;
          break;
        case RadarPinType.informalEvent:
          if (!filter.showInformalEvents) return false;
          break;
        case RadarPinType.athlete:
          if (!filter.showAthletes) return false;
          break;
        case RadarPinType.beacon:
          if (!filter.showBeacons) return false;
          break;
      }

      if (filter.weightClass != null &&
          filter.weightClass!.trim().isNotEmpty &&
          (pin.pinType == RadarPinType.athlete || pin.pinType == RadarPinType.beacon)) {
        final pinWeight = (pin.weightClass ?? '').trim().toLowerCase();
        if (pinWeight != filter.weightClass!.trim().toLowerCase()) {
          return false;
        }
      }

      if (filter.armPreference != null &&
          filter.armPreference!.trim().isNotEmpty &&
          filter.armPreference!.toUpperCase() != 'BOTH' &&
          (pin.pinType == RadarPinType.athlete || pin.pinType == RadarPinType.beacon)) {
        final target = filter.armPreference!.trim().toUpperCase();
        final pinArm = (pin.armPreference ?? '').trim().toUpperCase();
        if (pinArm.isNotEmpty && pinArm != target && pinArm != 'AMBIDEXTROUS' && pinArm != 'BOTH') {
          return false;
        }
      }

      if (filter.maxDistanceKm != null && referenceCenter != null) {
        if (pin.distanceKmFrom(referenceCenter) > filter.maxDistanceKm!) {
          return false;
        }
      }

      return true;
    }).toList();
  }
}

final radarProvider =
    NotifierProvider.autoDispose<RadarNotifier, RadarState>(RadarNotifier.new);
