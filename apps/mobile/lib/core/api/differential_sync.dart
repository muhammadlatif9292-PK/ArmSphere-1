import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dio_client.dart';
import '../storage/hive_storage.dart';

/// Local-first differential ("pull") sync.
///
/// Complements [OfflineSyncManager] (which pushes locally-queued offline
/// actions up to the server): this class pulls the server's authoritative
/// state back down — the athlete's own profile and match history — using a
/// `since` cursor so only what changed is transferred, per
/// `GET /sync?since=<cursor>` on the backend.
///
/// Per the project's authority model, this cache is read-only from the UI's
/// perspective: the phone never treats it as the source of truth for
/// official data, it's just what's shown while offline or while waiting for
/// a fresh pull.
class DifferentialSyncManager {
  static const String _cursorKey = 'sync_cursor';
  static const String _profileCacheKey = 'cached_athlete_profile';
  static const String _matchesCacheKey = 'cached_matches_by_id';

  final DioClient dioClient;
  final HiveStorage hiveStorage;
  bool _isSyncing = false;
  StreamSubscription? _connectivitySubscription;

  DifferentialSyncManager({required this.dioClient, required this.hiveStorage});

  /// Starts listening to connectivity changes and pulls the latest delta
  /// whenever the device comes back online.
  void startListening() {
    _connectivitySubscription = dioClient.connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        pullDelta();
      }
    });
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  /// Fetches everything that changed since the last successful pull and
  /// merges it into the local cache. Safe to call repeatedly (e.g. on pull
  /// to refresh, app resume, or connectivity regained) — a failed or offline
  /// attempt simply leaves the existing cache untouched, to be retried later.
  Future<void> pullDelta() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final String? since = hiveStorage.getCachedData(_cursorKey) as String?;

      final response = await dioClient.dio.get(
        '/sync',
        queryParameters: since != null ? {'since': since} : null,
      );

      final body = response.data;
      if (body is! Map || body['success'] != true) {
        return;
      }
      final data = body['data'] as Map<String, dynamic>?;
      if (data == null) {
        return;
      }

      // 1. Merge profile (a single row, just overwrite if present)
      final profile = data['profile'] as Map<String, dynamic>?;
      if (profile != null) {
        await hiveStorage.cacheData(_profileCacheKey, profile);
      }

      // 2. Merge matches by id into the existing cached map
      final existingMatchesRaw = hiveStorage.getCachedData(_matchesCacheKey);
      final Map<String, dynamic> matchesById = existingMatchesRaw is Map
          ? Map<String, dynamic>.from(existingMatchesRaw)
          : <String, dynamic>{};

      final incomingMatches = data['matches'] as List<dynamic>? ?? [];
      for (final rawMatch in incomingMatches) {
        if (rawMatch is Map<String, dynamic> && rawMatch['id'] != null) {
          matchesById[rawMatch['id'].toString()] = rawMatch;
        }
      }

      // 3. Apply any tombstoned deletions the server reported for this user
      final deletions = data['deletions'] as List<dynamic>? ?? [];
      for (final rawDeletion in deletions) {
        if (rawDeletion is Map<String, dynamic>) {
          final table = rawDeletion['table']?.toString();
          final recordId = rawDeletion['recordId']?.toString();
          if (table == 'matches' && recordId != null) {
            matchesById.remove(recordId);
          }
        }
      }

      await hiveStorage.cacheData(_matchesCacheKey, matchesById);

      // 4. Advance the cursor to the server's own clock, not the client's,
      //    to avoid clock-skew gaps or duplicate re-fetches next time.
      final serverTime = data['serverTime']?.toString();
      if (serverTime != null) {
        await hiveStorage.cacheData(_cursorKey, serverTime);
      }
    } catch (_) {
      // Offline, request failed, or malformed response: leave the existing
      // cache as-is. The next connectivity change will retry automatically.
    } finally {
      _isSyncing = false;
    }
  }

  /// Returns the last locally-cached profile, or null if never synced.
  Map<String, dynamic>? getCachedProfile() {
    final raw = hiveStorage.getCachedData(_profileCacheKey);
    return raw is Map ? Map<String, dynamic>.from(raw) : null;
  }

  /// Returns the last locally-cached match history, most recently created first.
  List<Map<String, dynamic>> getCachedMatches() {
    final raw = hiveStorage.getCachedData(_matchesCacheKey);
    if (raw is! Map) return [];

    final matches = raw.values
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();

    matches.sort((a, b) {
      final aCreated = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime(0);
      final bCreated = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime(0);
      return bCreated.compareTo(aCreated);
    });

    return matches;
  }

  /// Clears the local cache and cursor entirely, forcing a full re-sync on
  /// the next [pullDelta] call. Useful on logout.
  Future<void> resetCache() async {
    await hiveStorage.evictCache(_cursorKey);
    await hiveStorage.evictCache(_profileCacheKey);
    await hiveStorage.evictCache(_matchesCacheKey);
  }
}
