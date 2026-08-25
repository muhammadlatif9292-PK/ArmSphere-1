import 'dart:async';
import 'package:dio/dio.dart';
import 'dio_client.dart';
import '../storage/hive_storage.dart';

/// Base Repository with support for retries, cancellation, and offline fallback
abstract class BaseRepository {
  final DioClient dioClient;
  final HiveStorage hiveStorage;

  BaseRepository({required this.dioClient, required this.hiveStorage});

  /// Executes a request with retry logic, cancellation support, and offline fallback.
  Future<T> executeRequest<T>({
    required Future<Response> Function(CancelToken? cancelToken) request,
    required T Function(dynamic data) parse,
    required String cacheKey,
    CancelToken? cancelToken,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        attempts++;
        final response = await request(cancelToken);
        
        // Success - cache the response data and return parsed object
        if (response.statusCode == 200 || response.statusCode == 201) {
          await hiveStorage.cacheData(cacheKey, response.data);
          return parse(response.data);
        }
      } on DioException catch (e) {
        final isNetworkError = e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.error is OfflineException;

        // If it's a structural 4xx or 5xx API exception, handle it or rethrow
        if (e.error is ApiException) {
          final apiException = e.error as ApiException;
          // RFC-7807 error is bubble-raised directly to user interface
          throw apiException;
        }

        // If network error and we have offline cached fallback, return cache
        if (isNetworkError) {
          final cached = hiveStorage.getCachedData(cacheKey);
          if (cached != null) {
            return parse(cached);
          }
          if (attempts >= maxRetries) {
            throw OfflineException('No connection. No offline cache available.');
          }
        }

        // If cancelled, throw immediate error
        if (e.type == DioExceptionType.cancel) {
          throw Exception('Request cancelled by user.');
        }

        // Wait before retrying
        if (attempts < maxRetries && isNetworkError) {
          await Future.delayed(retryDelay * attempts);
          continue;
        }

        rethrow;
      } catch (e) {
        if (attempts >= maxRetries) {
          rethrow;
        }
      }
    }
    throw Exception('Request execution failed after $maxRetries retries.');
  }
}

class AuthRepository extends BaseRepository {
  AuthRepository({required super.dioClient, required super.hiveStorage});

  /// Unwraps the `{ success, data: ... }` envelope used by the auth API.
  Map<String, dynamic> _unwrap(dynamic data) {
    if (data is Map && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  /// Surfaces interceptor-produced exceptions as-is so the UI shows the
  /// real problem (invalid credentials, offline, session expired).
  Never _rethrowAuthError(DioException e) {
    final inner = e.error;
    if (inner is ApiException) throw inner;
    if (inner is OfflineException) throw inner;
    throw e;
  }

  /// Credential flows never go through [BaseRepository.executeRequest]:
  /// that helper caches successful payloads into plaintext Hive, which must
  /// never hold bearer tokens. Session persistence is owned by AuthNotifier.
  Future<Map<String, dynamic>> register(String email, String password, String fullName, {CancelToken? cancelToken}) async {
    final username = email.split('@').first.trim();
    try {
      final response = await dioClient.dio.post('/auth/register', data: {
        'email': email,
        'username': username,
        'password': password,
        'fullName': fullName,
      }, cancelToken: cancelToken);
      return _unwrap(response.data);
    } on DioException catch (e) {
      _rethrowAuthError(e);
    }
  }

  Future<Map<String, dynamic>> login(String email, String password, {CancelToken? cancelToken}) async {
    try {
      final response = await dioClient.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      }, cancelToken: cancelToken);
      return _unwrap(response.data);
    } on DioException catch (e) {
      _rethrowAuthError(e);
    }
  }

  Future<Map<String, dynamic>> verifyMfa(String code, {required String userId, CancelToken? cancelToken}) async {
    try {
      final response = await dioClient.dio.post('/auth/mfa/verify', data: {
        'userId': userId,
        'code': code,
      }, cancelToken: cancelToken);
      return _unwrap(response.data);
    } on DioException catch (e) {
      _rethrowAuthError(e);
    }
  }

  Future<void> logout({CancelToken? cancelToken}) async {
    try {
      await dioClient.dio.post('/auth/logout', cancelToken: cancelToken);
    } finally {
      await dioClient.secureStorage.clearSession();
      await hiveStorage.evictCache('auth_session_user');
    }
  }
}

class AthleteRepository extends BaseRepository {
  AthleteRepository({required super.dioClient, required super.hiveStorage});

  Future<Map<String, dynamic>> getProfile(String athleteId, {CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'athlete_profile_$athleteId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get('/athletes/$athleteId', cancelToken: token),
      parse: (data) => Map<String, dynamic>.from(data),
    );
  }

  Future<Map<String, dynamic>> submitOnboarding(Map<String, dynamic> data, {CancelToken? cancelToken}) async {
    final weight = (data['weightKg'] as num?)?.toDouble() ?? 75.0;
    final arm = (data['armDominance']?.toString() ?? 'RIGHT').toUpperCase();
    final handedness = arm == 'AMBIDEXTROUS' ? 'AMBIDEXTROUS' : (arm == 'LEFT' ? 'LEFT' : 'RIGHT');
    final dominantArm = (arm == 'LEFT') ? 'LEFT' : 'RIGHT';

    final mappedPayload = {
      'displayName': data['displayName'] ?? 'Athlete',
      'biography': 'Professional Athlete',
      'province': data['province'] ?? 'Punjab',
      'city': data['city'] ?? 'Lahore',
      'handedness': handedness,
      'dominantArm': dominantArm,
      'dateOfBirth': data['dateOfBirth'] ?? '2000-01-01T00:00:00.000Z',
      'gender': (data['gender']?.toString() ?? 'MALE').toUpperCase(),
      'weightClass': '${weight.toInt()}kg',
      'height': (data['heightCm'] as num?)?.toDouble() ?? 175.0,
      'weight': weight,
      'reach': (data['reachCm'] as num?)?.toDouble() ?? 175.0,
    };

    return executeRequest(
      cacheKey: 'athlete_profile_self',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.post('/athletes', data: mappedPayload, cancelToken: token),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        return Map<String, dynamic>.from(payload);
      },
    );
  }

  Future<List<Map<String, dynamic>>> searchAthletes(String query, {CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'athlete_search_$query',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get('/athletes/search', queryParameters: {'displayName': query}, cancelToken: token),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        if (payload is List) {
          return payload.map((e) => Map<String, dynamic>.from(e)).toList();
        }
        return [];
      },
    );
  }

  Future<List<Map<String, dynamic>>> getClubs({CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'athlete_clubs',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get('/athletes/clubs', cancelToken: token),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        if (payload is List) {
          return payload.map((e) => Map<String, dynamic>.from(e)).toList();
        }
        return [];
      },
    );
  }

  Future<Map<String, dynamic>> updateBiometrics(String athleteId, double weight, {CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'athlete_biometrics_$athleteId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.post('/athletes/biometrics', data: {
        'athleteId': athleteId,
        'weight': weight,
      }, cancelToken: token),
      parse: (data) => Map<String, dynamic>.from(data),
    );
  }

  Future<Map<String, dynamic>> updateVisibility(String profileVisibility, bool isSearchable, {CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'athlete_profile_self',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.patch('/athletes/me/visibility', data: {
        'profileVisibility': profileVisibility,
        'isSearchable': isSearchable,
      }, cancelToken: token),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        return Map<String, dynamic>.from(payload);
      },
    );
  }

  Future<List<Map<String, dynamic>>> getTrainingLog(String athleteId, {String? exerciseType, CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'training_log_${athleteId}_${exerciseType ?? ''}',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get(
        '/athletes/$athleteId/training-log',
        queryParameters: {
          if (exerciseType != null) 'exerciseType': exerciseType,
        },
        cancelToken: token,
      ),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        if (payload is List) {
          return payload.map((e) => Map<String, dynamic>.from(e)).toList();
        }
        return [];
      },
    );
  }

  Future<List<Map<String, dynamic>>> getTrainingLogPRs(String athleteId, {CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'training_log_prs_$athleteId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get(
        '/athletes/$athleteId/training-log/prs',
        cancelToken: token,
      ),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        if (payload is List) {
          return payload.map((e) => Map<String, dynamic>.from(e)).toList();
        }
        return [];
      },
    );
  }
}

class MatchRepository extends BaseRepository {
  MatchRepository({required super.dioClient, required super.hiveStorage});

  Future<List<Map<String, dynamic>>> getMatchHistory(String athleteId, {CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'match_history_$athleteId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get('/athletes/$athleteId/matches', cancelToken: token),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        if (payload is List) {
          return payload.map((e) => Map<String, dynamic>.from(e)).toList();
        }
        return [];
      },
    );
  }

  Future<List<Map<String, dynamic>>> getRecentMatches({int? limit, int? offset, CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'recent_matches_${limit ?? 20}_${offset ?? 0}',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get(
        '/matches/recent',
        queryParameters: {
          if (limit != null) 'limit': limit,
          if (offset != null) 'offset': offset,
        },
        cancelToken: token,
      ),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        if (payload is List) {
          return payload.map((e) => Map<String, dynamic>.from(e)).toList();
        }
        return [];
      },
    );
  }

  Future<Map<String, dynamic>> submitMatchResult(Map<String, dynamic> payload, {CancelToken? cancelToken}) async {
    // If offline, enqueue transaction to offline sync manager
    try {
      final response = await dioClient.dio.post('/matches', data: payload, cancelToken: cancelToken);
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      if (e.error is OfflineException || e.type == DioExceptionType.connectionError) {
        await hiveStorage.enqueueAction(
          actionType: 'MATCH_SUBMISSION',
          endpoint: '/matches',
          payload: payload,
          method: 'POST',
         );
        throw OfflineException('Submission queued offline. Will sync automatically when back online.');
      }
      rethrow;
    }
  }
}

class TournamentRepository extends BaseRepository {
  TournamentRepository({required super.dioClient, required super.hiveStorage});

  Future<List<Map<String, dynamic>>> getTournaments({CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'tournaments_list',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get('/tournaments/events', cancelToken: token),
      parse: (data) => (data as List).map((e) => Map<String, dynamic>.from(e)).toList(),
    );
  }

  Future<Map<String, dynamic>> getEventById({
    required String eventId,
    CancelToken? cancelToken,
  }) async {
    return executeRequest(
      cacheKey: 'event_detail_$eventId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get('/tournaments/events/$eventId', cancelToken: token),
      parse: (data) => Map<String, dynamic>.from(data),
    );
  }

  Future<Map<String, dynamic>> registerAthlete({
    required String eventId,
    required String athleteId,
    required String division,
    required String weightClass,
    required String arm,
    String? notes,
    CancelToken? cancelToken,
  }) async {
    return executeRequest(
      cacheKey: 'tournament_reg_$eventId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.post('/tournaments/registrations', data: {
        'eventId': eventId,
        'athleteId': athleteId,
        'division': division,
        'weightClass': weightClass,
        'arm': arm,
        if (notes != null) 'notes': notes,
      }, cancelToken: token),
      parse: (data) => Map<String, dynamic>.from(data),
    );
  }

  Future<Map<String, dynamic>> getBracket(String bracketId, {CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'bracket_detail_$bracketId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get('/tournaments/brackets/$bracketId', cancelToken: token),
      parse: (data) => Map<String, dynamic>.from(data),
    );
  }

  Future<List<Map<String, dynamic>>> listBrackets({CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'brackets_list',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get('/tournaments/brackets', cancelToken: token),
      parse: (data) => (data as List).map((e) => Map<String, dynamic>.from(e)).toList(),
    );
  }

  Future<Map<String, dynamic>> patchEvent({
    required String eventId,
    required Map<String, dynamic> data,
    CancelToken? cancelToken,
  }) async {
    return executeRequest(
      cacheKey: 'event_patch_$eventId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.patch('/tournaments/events/$eventId', data: data, cancelToken: token),
      parse: (data) => Map<String, dynamic>.from(data),
    );
  }

  Future<Map<String, dynamic>> confirmManualPayment({
    required String registrationId,
    CancelToken? cancelToken,
  }) async {
    return executeRequest(
      cacheKey: 'confirm_manual_payment_$registrationId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.post('/tournaments/registrations/$registrationId/confirm-manual-payment', cancelToken: token),
      parse: (data) => Map<String, dynamic>.from(data),
    );
  }

  Future<List<Map<String, dynamic>>> getEventRegistrations({
    required String eventId,
    CancelToken? cancelToken,
  }) async {
    return executeRequest(
      cacheKey: 'event_regs_$eventId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get('/tournaments/events/$eventId/registrations', cancelToken: token),
      parse: (data) => (data as List).map((e) => Map<String, dynamic>.from(e)).toList(),
    );
  }

  Future<Map<String, dynamic>> getEventStats({
    required String eventId,
    CancelToken? cancelToken,
  }) async {
    return executeRequest(
      cacheKey: 'event_stats_$eventId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get('/tournaments/events/$eventId/stats', cancelToken: token),
      parse: (data) => Map<String, dynamic>.from(data),
    );
  }

  Future<Map<String, dynamic>> approveRegistration({
    required String registrationId,
    CancelToken? cancelToken,
  }) async {
    return executeRequest(
      cacheKey: 'approve_reg_$registrationId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.post('/tournaments/registrations/$registrationId/approve', cancelToken: token),
      parse: (data) => Map<String, dynamic>.from(data),
    );
  }

  Future<Map<String, dynamic>> recordWeighIn({
    required String registrationId,
    required double weightKg,
    CancelToken? cancelToken,
  }) async {
    return executeRequest(
      cacheKey: 'weighin_$registrationId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.post('/tournaments/weighins', data: {
        'registrationId': registrationId,
        'weight': weightKg,
      }, cancelToken: token),
      parse: (data) => Map<String, dynamic>.from(data),
    );
  }

  Future<Map<String, dynamic>> certifyWeighIn({
    required String registrationId,
    CancelToken? cancelToken,
  }) async {
    return executeRequest(
      cacheKey: 'certify_weighin_$registrationId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.post('/tournaments/registrations/$registrationId/certify', cancelToken: token),
      parse: (data) => Map<String, dynamic>.from(data),
    );
  }

  Future<Map<String, dynamic>> reassignRegistration({
    required String registrationId,
    required String newDivision,
    required String newWeightClass,
    CancelToken? cancelToken,
  }) async {
    return executeRequest(
      cacheKey: 'reassign_$registrationId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.post('/tournaments/registrations/reassign', data: {
        'registrationId': registrationId,
        'newDivision': newDivision,
        'newWeightClass': newWeightClass,
      }, cancelToken: token),
      parse: (data) => Map<String, dynamic>.from(data),
    );
  }

  Future<Map<String, dynamic>> createBracket({
    required String eventId,
    required String name,
    required String format,
    required String division,
    required String weightClass,
    required String arm,
    CancelToken? cancelToken,
  }) async {
    return executeRequest(
      cacheKey: 'create_bracket_$eventId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.post('/tournaments/brackets', data: {
        'eventId': eventId,
        'name': name,
        'format': format,
        'division': division,
        'weightClass': weightClass,
        'arm': arm,
      }, cancelToken: token),
      parse: (data) => Map<String, dynamic>.from(data),
    );
  }

  /// Returns the generated seed rows: [{bracketId, athleteId, seedPosition, isManualOverride}]
  Future<List<Map<String, dynamic>>> generateSeeds({
    required String bracketId,
    CancelToken? cancelToken,
  }) async {
    return executeRequest(
      cacheKey: 'generate_seeds_$bracketId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.post('/tournaments/brackets/$bracketId/seeds', cancelToken: token),
      parse: (data) => (data as List).map((e) => Map<String, dynamic>.from(e)).toList(),
    );
  }

  Future<Map<String, dynamic>> lockSeeds({
    required String bracketId,
    CancelToken? cancelToken,
  }) async {
    return executeRequest(
      cacheKey: 'lock_seeds_$bracketId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.post('/tournaments/brackets/$bracketId/seeds/lock', cancelToken: token),
      parse: (data) => Map<String, dynamic>.from(data),
    );
  }

  Future<Map<String, dynamic>> generateBracketMatches({
    required String bracketId,
    CancelToken? cancelToken,
  }) async {
    return executeRequest(
      cacheKey: 'gen_matches_$bracketId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.post('/tournaments/brackets/$bracketId/generate', cancelToken: token),
      parse: (data) => Map<String, dynamic>.from(data),
    );
  }

  // --- Match-day operations (Phase 5: officials) ---

  /// Every bracket match in one event, with athlete names and referee/table ids.
  Future<List<Map<String, dynamic>>> getEventMatches({
    required String eventId,
    CancelToken? cancelToken,
  }) async {
    return executeRequest(
      cacheKey: 'event_matches_$eventId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get('/tournaments/events/$eventId/matches', cancelToken: token),
      parse: (data) => (data as List).map((e) => Map<String, dynamic>.from(e)).toList(),
    );
  }

  Future<List<Map<String, dynamic>>> listTables({CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'match_tables',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get('/tournaments/tables', cancelToken: token),
      parse: (data) => (data as List).map((e) => Map<String, dynamic>.from(e)).toList(),
    );
  }

  Future<Map<String, dynamic>> createTable({
    required String name,
    CancelToken? cancelToken,
  }) async {
    return executeRequest(
      cacheKey: 'create_table',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.post('/tournaments/tables', data: {'name': name}, cancelToken: token),
      parse: (data) => Map<String, dynamic>.from(data),
    );
  }

  /// Referee directory from the admin surface (director roles only).
  Future<List<Map<String, dynamic>>> listReferees({CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'referee_directory',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get('/admin/referees', cancelToken: token),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        if (payload is List) {
          return payload.map((e) => Map<String, dynamic>.from(e)).toList();
        }
        return [];
      },
    );
  }

  Future<Map<String, dynamic>> assignReferee({
    required String matchId,
    required String refereeId,
    CancelToken? cancelToken,
  }) async {
    return executeRequest(
      cacheKey: 'assign_referee_$matchId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.post('/tournaments/matches/referee', data: {
        'matchId': matchId,
        'refereeId': refereeId,
      }, cancelToken: token),
      parse: (data) => Map<String, dynamic>.from(data),
    );
  }

  Future<Map<String, dynamic>> callMatchToTable({
    required String matchId,
    required String tableId,
    CancelToken? cancelToken,
  }) async {
    return executeRequest(
      cacheKey: 'call_match_$matchId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.post('/tournaments/matches/call', data: {
        'matchId': matchId,
        'tableId': tableId,
      }, cancelToken: token),
      parse: (data) => Map<String, dynamic>.from(data),
    );
  }

  Future<Map<String, dynamic>> submitTournamentResult({
    required String matchId,
    required String winnerId,
    required String scoreLine,
    CancelToken? cancelToken,
  }) async {
    return executeRequest(
      cacheKey: 'match_result_$matchId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.post('/tournaments/matches/result', data: {
        'matchId': matchId,
        'winnerId': winnerId,
        'scoreLine': scoreLine,
      }, cancelToken: token),
      parse: (data) => Map<String, dynamic>.from(data),
    );
  }

  Future<List<Map<String, dynamic>>> getTicketTypes({
    required String eventId,
    CancelToken? cancelToken,
  }) async {
    return executeRequest(
      cacheKey: 'ticket_types_$eventId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get('/events/$eventId/ticket-types', cancelToken: token),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        if (payload is List) {
          return payload.map((e) => Map<String, dynamic>.from(e)).toList();
        }
        return [];
      },
    );
  }

  Future<Map<String, dynamic>> purchaseTicket({
    required String ticketTypeId,
    CancelToken? cancelToken,
  }) async {
    return executeRequest(
      cacheKey: 'purchase_ticket_$ticketTypeId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.post('/ticket-types/$ticketTypeId/purchase', cancelToken: token),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        return Map<String, dynamic>.from(payload);
      },
    );
  }

  Future<List<Map<String, dynamic>>> getMyTickets({
    CancelToken? cancelToken,
  }) async {
    return executeRequest(
      cacheKey: 'my_tickets_list',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get('/tickets/mine', cancelToken: token),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        if (payload is List) {
          return payload.map((e) => Map<String, dynamic>.from(e)).toList();
        }
        return [];
      },
    );
  }
}

class RankingsRepository extends BaseRepository {
  RankingsRepository({required super.dioClient, required super.hiveStorage});

  Future<List<Map<String, dynamic>>> getLeaderboards({
    String arm = 'RIGHT',
    String? province,
    String? search,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    return executeRequest(
      cacheKey: 'leaderboards_${arm}_${province ?? 'all'}_${search ?? ''}_$limit',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get(
        '/rankings/leaderboard',
        queryParameters: {
          'arm': arm,
          'limit': limit,
          if (province != null && province.isNotEmpty) 'province': province,
          if (search != null && search.isNotEmpty) 'search': search,
        },
        cancelToken: token,
      ),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        if (payload is Map && payload.containsKey('items')) {
          final items = payload['items'];
          if (items is List) {
            return items.map((e) => Map<String, dynamic>.from(e)).toList();
          }
        }
        if (payload is List) {
          return payload.map((e) => Map<String, dynamic>.from(e)).toList();
        }
        return [];
      },
    );
  }
}

class DisputeRepository extends BaseRepository {
  DisputeRepository({required super.dioClient, required super.hiveStorage});

  Future<List<Map<String, dynamic>>> getDisputes({CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'disputes_list',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get('/governance/disputes', cancelToken: token),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        if (payload is List) {
          return payload.map((e) => Map<String, dynamic>.from(e)).toList();
        }
        return [];
      },
    );
  }

  Future<Map<String, dynamic>> submitDispute(Map<String, dynamic> payload, {CancelToken? cancelToken}) async {
    final Map<String, dynamic> adaptedPayload = Map<String, dynamic>.from(payload);
    // Align payload with backend createDisputeSchema validation: title (>=5 chars), description (>=10 chars)
    if (!adaptedPayload.containsKey('title') && adaptedPayload.containsKey('reason')) {
      final String reason = adaptedPayload['reason'] ?? '';
      adaptedPayload['title'] = reason.length >= 5 ? reason : 'Match Dispute Submission';
    }
    if (!adaptedPayload.containsKey('description') && adaptedPayload.containsKey('reason')) {
      final String reason = adaptedPayload['reason'] ?? '';
      adaptedPayload['description'] = reason.length >= 10 ? reason : 'Detailed match dispute: $reason';
    }

    try {
      final response = await dioClient.dio.post('/governance/disputes', data: adaptedPayload, cancelToken: cancelToken);
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      if (e.error is OfflineException || e.type == DioExceptionType.connectionError) {
        await hiveStorage.enqueueAction(
          actionType: 'DISPUTE_SUBMISSION',
          endpoint: '/governance/disputes',
          payload: adaptedPayload,
          method: 'POST',
        );
        throw OfflineException('Dispute queued offline. Will sync automatically when back online.');
      }
      rethrow;
    }
  }
}

class NotificationRepository extends BaseRepository {
  NotificationRepository({required super.dioClient, required super.hiveStorage});

  Future<List<Map<String, dynamic>>> getNotifications({CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'notifications_list',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get('/communication/notifications', cancelToken: token),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        if (payload is List) {
          return payload.map((e) => Map<String, dynamic>.from(e)).toList();
        }
        return [];
      },
    );
  }

  Future<void> markAsRead(String notificationId, {CancelToken? cancelToken}) async {
    try {
      await dioClient.dio.post('/communication/notifications/$notificationId/read', cancelToken: cancelToken);
    } catch (_) {
      await hiveStorage.enqueueAction(
        actionType: 'MARK_NOTIFICATION_READ',
        endpoint: '/communication/notifications/$notificationId/read',
        payload: {},
        method: 'POST',
      );
    }
  }

  Future<void> markAllAsRead({CancelToken? cancelToken}) async {
    await dioClient.dio.post('/communication/notifications/read-all', cancelToken: cancelToken);
  }

  Future<Map<String, dynamic>> registerDevice({
    required String deviceId,
    required String platform,
    required String fcmToken,
    String? apnsToken,
    required String appVersion,
    required String locale,
    required String timezone,
    bool pushEnabled = true,
    CancelToken? cancelToken,
  }) async {
    final payload = {
      'deviceId': deviceId,
      'platform': platform,
      'fcmToken': fcmToken,
      if (apnsToken != null) 'apnsToken': apnsToken,
      'appVersion': appVersion,
      'locale': locale,
      'timezone': timezone,
      'pushEnabled': pushEnabled,
    };
    try {
      final response = await dioClient.dio.post(
        '/communication/devices',
        data: payload,
        cancelToken: cancelToken,
      );
      final data = response.data;
      if (data is Map && data.containsKey('data')) {
        return Map<String, dynamic>.from(data['data']);
      }
      return Map<String, dynamic>.from(data);
    } catch (_) {
      await hiveStorage.enqueueAction(
        actionType: 'REGISTER_DEVICE',
        endpoint: '/communication/devices',
        payload: payload,
        method: 'POST',
      );
      return {'success': false, 'cached': true};
    }
  }

  Future<void> deregisterDevice(String deviceId, {CancelToken? cancelToken}) async {
    try {
      await dioClient.dio.delete(
        '/communication/devices/$deviceId',
        cancelToken: cancelToken,
      );
    } catch (_) {
      await hiveStorage.enqueueAction(
        actionType: 'DEREGISTER_DEVICE',
        endpoint: '/communication/devices/$deviceId',
        payload: {},
        method: 'DELETE',
      );
    }
  }
}

class AdministrationRepository extends BaseRepository {
  AdministrationRepository({required super.dioClient, required super.hiveStorage});

  Future<Map<String, dynamic>> getSystemStatus({CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'system_status',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get('/admin/status', cancelToken: token),
      parse: (data) => Map<String, dynamic>.from(data),
    );
  }
}

class ChampionshipRepository extends BaseRepository {
  ChampionshipRepository({required super.dioClient, required super.hiveStorage});

  Future<List<Map<String, dynamic>>> getActiveTitles({CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'active_titles_list',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get('/championships/titles', cancelToken: token),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        if (payload is List) {
          return payload.map((e) => Map<String, dynamic>.from(e)).toList();
        }
        return [];
      },
    );
  }

  Future<List<Map<String, dynamic>>> getBeltLineage(String titleId, {CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'belt_lineage_$titleId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get('/championships/titles/$titleId/lineage', cancelToken: token),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        if (payload is List) {
          return payload.map((e) => Map<String, dynamic>.from(e)).toList();
        }
        return [];
      },
    );
  }

  Future<List<Map<String, dynamic>>> getChallenges({CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'championship_challenges_list',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get('/championships/challenges', cancelToken: token),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        if (payload is List) {
          return payload.map((e) => Map<String, dynamic>.from(e)).toList();
        }
        return [];
      },
    );
  }
}

class MessagingRepository extends BaseRepository {
  MessagingRepository({required super.dioClient, required super.hiveStorage});

  Future<List<Map<String, dynamic>>> getConversations({bool refresh = true, CancelToken? cancelToken}) async {
    if (!refresh) {
      final cached = hiveStorage.getCachedData('local_conversations_list');
      if (cached is List) {
        return cached.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    }
    try {
      return await executeRequest(
        cacheKey: 'local_conversations_list',
        cancelToken: cancelToken,
        request: (token) => dioClient.dio.get('/communication/conversations', cancelToken: token),
        parse: (data) {
          final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
          if (payload is List) {
            return payload.map((e) => Map<String, dynamic>.from(e)).toList();
          }
          return [];
        },
      );
    } catch (_) {
      final cached = hiveStorage.getCachedData('local_conversations_list');
      if (cached is List) {
        return cached.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    }
  }

  Future<void> saveConversation(Map<String, dynamic> conversation) async {
    final list = await getConversations(refresh: false);
    final idx = list.indexWhere((element) => element['id'] == conversation['id']);
    if (idx != -1) {
      list[idx] = conversation;
    } else {
      list.add(conversation);
    }
    await hiveStorage.cacheData('local_conversations_list', list);
  }

  Future<Map<String, dynamic>> getOrCreateConversation(String participantId, {String type = 'DIRECT', CancelToken? cancelToken}) async {
    final response = await dioClient.dio.post(
      '/communication/conversations',
      data: {
        'participantId': participantId,
        'type': type,
      },
      cancelToken: cancelToken,
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    final payload = data['data'] ?? data;
    
    if (payload is Map && payload.containsKey('conversation')) {
      final conv = Map<String, dynamic>.from(payload['conversation'] as Map);
      conv['participantId'] = participantId;
      await saveConversation(conv);
    }
    
    return Map<String, dynamic>.from(payload as Map);
  }

  Future<List<Map<String, dynamic>>> getConversationMessages(String conversationId, {int? limit, int? offset, CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'messages_$conversationId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get(
        '/communication/conversations/$conversationId/messages',
        queryParameters: {
          if (limit != null) 'limit': limit,
          if (offset != null) 'offset': offset,
        },
        cancelToken: token,
      ),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        if (payload is List) {
          return payload.map((e) => Map<String, dynamic>.from(e)).toList();
        }
        return [];
      },
    );
  }

  Future<Map<String, dynamic>> sendMessage(String conversationId, String content, {List<Map<String, dynamic>>? attachments, CancelToken? cancelToken}) async {
    final payload = {
      'content': content,
      if (attachments != null) 'attachments': attachments,
    };
    try {
      final response = await dioClient.dio.post(
        '/communication/conversations/$conversationId/messages',
        data: payload,
        cancelToken: cancelToken,
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      final res = data['data'] ?? data;
      return Map<String, dynamic>.from(res as Map);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError || e.error is OfflineException) {
        await hiveStorage.enqueueAction(
          actionType: 'SEND_MESSAGE',
          endpoint: '/communication/conversations/$conversationId/messages',
          payload: payload,
          method: 'POST',
        );
        throw OfflineException('Message queued. Will send automatically when online.');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> editMessage(String messageId, String content, {CancelToken? cancelToken}) async {
    final response = await dioClient.dio.put(
      '/communication/messages/$messageId',
      data: {'content': content},
      cancelToken: cancelToken,
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    final res = data['data'] ?? data;
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> deleteMessage(String messageId, {CancelToken? cancelToken}) async {
    final response = await dioClient.dio.delete(
      '/communication/messages/$messageId',
      cancelToken: cancelToken,
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    final res = data['data'] ?? data;
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> setTypingIndicator(String conversationId, bool isTyping, {CancelToken? cancelToken}) async {
    final response = await dioClient.dio.post(
      '/communication/conversations/$conversationId/typing',
      data: {'isTyping': isTyping},
      cancelToken: cancelToken,
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    final res = data['data'] ?? data;
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> setPresence(bool isOnline, {CancelToken? cancelToken}) async {
    final response = await dioClient.dio.post(
      '/communication/presence',
      data: {'isOnline': isOnline},
      cancelToken: cancelToken,
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    final res = data['data'] ?? data;
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> getUnreadCounts({CancelToken? cancelToken}) async {
    final response = await dioClient.dio.get(
      '/communication/unread-counts',
      cancelToken: cancelToken,
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    final res = data['data'] ?? data;
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> markConversationAsRead(String conversationId, {CancelToken? cancelToken}) async {
    final response = await dioClient.dio.post(
      '/communication/conversations/$conversationId/read',
      cancelToken: cancelToken,
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    final res = data['data'] ?? data;
    return Map<String, dynamic>.from(res as Map);
  }

  Future<List<Map<String, dynamic>>> getAnnouncements({
    String? scope,
    String? scopeId,
    bool? includeArchived,
    int? limit,
    int? offset,
    CancelToken? cancelToken,
  }) async {
    return executeRequest(
      cacheKey: 'announcements_list_${scope ?? "all"}_${scopeId ?? "all"}',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get(
        '/communication/announcements',
        queryParameters: {
          if (scope != null) 'scope': scope,
          if (scopeId != null) 'scopeId': scopeId,
          if (includeArchived != null) 'includeArchived': includeArchived.toString(),
          if (limit != null) 'limit': limit,
          if (offset != null) 'offset': offset,
        },
        cancelToken: token,
      ),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        if (payload is List) {
          return payload.map((e) => Map<String, dynamic>.from(e)).toList();
        }
        return [];
      },
    );
  }

  Future<Map<String, dynamic>> getPreferences({CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'user_communication_preferences',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get(
        '/communication/preferences',
        cancelToken: token,
      ),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        if (payload is Map) {
          return Map<String, dynamic>.from(payload);
        }
        return <String, dynamic>{};
      },
    );
  }

  Future<Map<String, dynamic>> updatePreferences(Map<String, dynamic> updates, {CancelToken? cancelToken}) async {
    final response = await dioClient.dio.put(
      '/communication/preferences',
      data: updates,
      cancelToken: cancelToken,
    );
    final data = Map<String, dynamic>.from(response.data);
    final payload = data['data'] ?? data;
    await hiveStorage.cacheData('user_communication_preferences', data);
    return Map<String, dynamic>.from(payload);
  }
}

class SocialRepository extends BaseRepository {
  SocialRepository({required super.dioClient, required super.hiveStorage});

  Future<Map<String, dynamic>> followAthlete(String followingId, {CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'follow_athlete_$followingId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.post(
        '/social/follow',
        data: {'followingId': followingId},
        cancelToken: token,
      ),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        return Map<String, dynamic>.from(payload);
      },
    );
  }

  Future<Map<String, dynamic>> unfollowAthlete(String followingId, {CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'unfollow_athlete_$followingId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.delete(
        '/social/follow/$followingId',
        cancelToken: token,
      ),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        return Map<String, dynamic>.from(payload);
      },
    );
  }

  Future<List<Map<String, dynamic>>> getFollowers(String athleteId, {int? limit, int? offset, CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'followers_${athleteId}_${limit ?? 50}_${offset ?? 0}',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get(
        '/social/followers/$athleteId',
        queryParameters: {
          if (limit != null) 'limit': limit,
          if (offset != null) 'offset': offset,
        },
        cancelToken: token,
      ),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        if (payload is List) {
          return payload.map((e) => Map<String, dynamic>.from(e)).toList();
        }
        return [];
      },
    );
  }

  Future<List<Map<String, dynamic>>> getFollowing(String athleteId, {int? limit, int? offset, CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'following_${athleteId}_${limit ?? 50}_${offset ?? 0}',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get(
        '/social/following/$athleteId',
        queryParameters: {
          if (limit != null) 'limit': limit,
          if (offset != null) 'offset': offset,
        },
        cancelToken: token,
      ),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        if (payload is List) {
          return payload.map((e) => Map<String, dynamic>.from(e)).toList();
        }
        return [];
      },
    );
  }

  Future<Map<String, dynamic>> createTeam(Map<String, dynamic> payload, {CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'create_team_${payload['name']}',
      cancelToken: cancelToken,
      maxRetries: 1,
      request: (token) => dioClient.dio.post(
        '/social/teams',
        data: payload,
        cancelToken: token,
      ),
      parse: (data) {
        final payloadData = (data is Map && data.containsKey('data')) ? data['data'] : data;
        return Map<String, dynamic>.from(payloadData);
      },
    );
  }

  Future<Map<String, dynamic>> addTeamMember(String teamId, String athleteId, String role, {CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'add_team_member_${teamId}_$athleteId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.post(
        '/social/teams/$teamId/members',
        data: {
          'athleteId': athleteId,
          'role': role,
        },
        cancelToken: token,
      ),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        return Map<String, dynamic>.from(payload);
      },
    );
  }

  Future<Map<String, dynamic>> removeTeamMember(String teamId, String athleteId, {CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'remove_team_member_${teamId}_$athleteId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.delete(
        '/social/teams/$teamId/members/$athleteId',
        cancelToken: token,
      ),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        return Map<String, dynamic>.from(payload);
      },
    );
  }

  Future<Map<String, dynamic>> getTeam(String teamId, {CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'team_$teamId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get(
        '/social/teams/$teamId',
        cancelToken: token,
      ),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        return Map<String, dynamic>.from(payload);
      },
    );
  }

  Future<List<Map<String, dynamic>>> getMyTeams({CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'my_teams',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get(
        '/social/my-teams',
        cancelToken: token,
      ),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        if (payload is List) {
          return payload.map((e) => Map<String, dynamic>.from(e)).toList();
        }
        return [];
      },
    );
  }

  Future<bool> checkFollowStatus(String followingId, {CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'follow_status_$followingId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get(
        '/social/follow-status/$followingId',
        cancelToken: token,
      ),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        if (payload is Map && payload.containsKey('isFollowing')) {
          return payload['isFollowing'] as bool;
        }
        return false;
      },
    );
  }

  Future<Map<String, dynamic>> blockUser(String athleteId, {CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'block_user_$athleteId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.post(
        '/social/block/$athleteId',
        cancelToken: token,
      ),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        return Map<String, dynamic>.from(payload);
      },
    );
  }

  Future<Map<String, dynamic>> unblockUser(String athleteId, {CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'unblock_user_$athleteId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.delete(
        '/social/block/$athleteId',
        cancelToken: token,
      ),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        return Map<String, dynamic>.from(payload);
      },
    );
  }

  Future<List<Map<String, dynamic>>> getBlockedUsers({CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'blocked_users_list',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get(
        '/social/blocked',
        cancelToken: token,
      ),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        if (payload is List) {
          return payload.map((e) => Map<String, dynamic>.from(e)).toList();
        }
        return [];
      },
    );
  }
}

class CommunityRepository extends BaseRepository {
  CommunityRepository({required super.dioClient, required super.hiveStorage});

  Future<List<Map<String, dynamic>>> getFeed({int? limit, String? cursor, CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'community_feed_${limit ?? 20}_${cursor ?? "none"}',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get(
        '/community/feed',
        queryParameters: {
          if (limit != null) 'limit': limit,
          if (cursor != null) 'cursor': cursor,
        },
        cancelToken: token,
      ),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        if (payload is List) {
          return payload.map((e) {
            final map = Map<String, dynamic>.from(e);
            map['likedByViewer'] = map['likedByViewer'] as bool? ?? false;
            return map;
          }).toList();
        }
        return [];
      },
    );
  }

  Future<Map<String, dynamic>> likePost(String postId, {CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'like_post_$postId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.post(
        '/community/posts/$postId/like',
        cancelToken: token,
      ),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        return Map<String, dynamic>.from(payload);
      },
    );
  }

  Future<Map<String, dynamic>> unlikePost(String postId, {CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'unlike_post_$postId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.delete(
        '/community/posts/$postId/like',
        cancelToken: token,
      ),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        return Map<String, dynamic>.from(payload);
      },
    );
  }

  Future<Map<String, dynamic>> addComment(String postId, String body, {CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'add_comment_${postId}_${DateTime.now().millisecondsSinceEpoch}',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.post(
        '/community/posts/$postId/comments',
        data: {'body': body},
        cancelToken: token,
      ),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        return Map<String, dynamic>.from(payload);
      },
    );
  }

  Future<List<Map<String, dynamic>>> getComments(String postId, {CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'post_comments_$postId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get(
        '/community/posts/$postId/comments',
        cancelToken: token,
      ),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        if (payload is List) {
          return payload.map((e) => Map<String, dynamic>.from(e)).toList();
        }
        return [];
      },
    );
  }

  Future<Map<String, dynamic>> deletePost(String postId, {CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'delete_post_$postId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.delete(
        '/community/posts/$postId',
        cancelToken: token,
      ),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        return Map<String, dynamic>.from(payload);
      },
    );
  }

  Future<Map<String, dynamic>> submitLink(
    String externalUrl,
    String? category,
    String? caption, {
    String? exerciseType,
    double? weightKg,
    int? reps,
    String? matchId,
    CancelToken? cancelToken,
  }) async {
    return executeRequest(
      cacheKey: 'community_submit_link_${DateTime.now().millisecondsSinceEpoch}',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.post(
        '/community/links',
        data: {
          'externalUrl': externalUrl,
          if (category != null) 'category': category,
          if (caption != null) 'caption': caption,
          if (exerciseType != null) 'exerciseType': exerciseType,
          if (weightKg != null) 'weightKg': weightKg,
          if (reps != null) 'reps': reps,
          if (matchId != null) 'matchId': matchId,
        },
        cancelToken: token,
      ),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        return Map<String, dynamic>.from(payload);
      },
    );
  }
}

class VenueRepository extends BaseRepository {
  VenueRepository({required super.dioClient, required super.hiveStorage});

  Future<List<Map<String, dynamic>>> getVenues({String? city, String? province, CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'venues_${city ?? ''}_${province ?? ''}',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get(
        '/venues',
        queryParameters: {
          if (city != null && city.isNotEmpty) 'city': city,
          if (province != null && province.isNotEmpty) 'province': province,
        },
        cancelToken: token,
      ),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        if (payload is List) {
          return payload.map((e) => Map<String, dynamic>.from(e)).toList();
        }
        return [];
      },
    );
  }

  Future<Map<String, dynamic>> getVenueById(String id, {CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'venue_detail_$id',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get(
        '/venues/$id',
        cancelToken: token,
      ),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        return Map<String, dynamic>.from(payload);
      },
    );
  }

  Future<Map<String, dynamic>> submitVenue({
    required String name,
    required String city,
    required String province,
    required String address,
    String? contactInfo,
    String? description,
    String? logoUrl,
    CancelToken? cancelToken,
  }) async {
    return executeRequest(
      cacheKey: 'submit_venue_${DateTime.now().millisecondsSinceEpoch}',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.post(
        '/venues',
        data: {
          'name': name,
          'city': city,
          'province': province,
          'address': address,
          if (contactInfo != null) 'contactInfo': contactInfo,
          if (description != null) 'description': description,
          if (logoUrl != null) 'logoUrl': logoUrl,
        },
        cancelToken: token,
      ),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        return Map<String, dynamic>.from(payload);
      },
    );
  }
}

class NominationRepository extends BaseRepository {
  NominationRepository({required super.dioClient, required super.hiveStorage});

  Future<List<Map<String, dynamic>>> getOwnNominations({CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'my_nominations_${DateTime.now().millisecondsSinceEpoch ~/ 10000}',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get(
        '/nominations/mine',
        cancelToken: token,
      ),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        if (payload is List) {
          return payload.map((e) => Map<String, dynamic>.from(e)).toList();
        }
        return [];
      },
    );
  }

  Future<Map<String, dynamic>> submitNomination({
    required String nomineeName,
    required String city,
    required String province,
    String? nomineeContact,
    String? notes,
    CancelToken? cancelToken,
  }) async {
    return executeRequest(
      cacheKey: 'submit_nomination_${DateTime.now().millisecondsSinceEpoch}',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.post(
        '/nominations',
        data: {
          'nomineeName': nomineeName,
          'city': city,
          'province': province,
          if (nomineeContact != null) 'nomineeContact': nomineeContact,
          if (notes != null) 'notes': notes,
        },
        cancelToken: token,
      ),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        return Map<String, dynamic>.from(payload);
      },
    );
  }
}

class InformalEventRepository extends BaseRepository {
  InformalEventRepository({required super.dioClient, required super.hiveStorage});

  Future<List<Map<String, dynamic>>> getEvents({
    String? city,
    String? startDate,
    String? endDate,
    CancelToken? cancelToken,
  }) async {
    return executeRequest(
      cacheKey: 'informal_events_${city ?? ''}_${startDate ?? ''}_${endDate ?? ''}',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get(
        '/informal-events',
        queryParameters: {
          if (city != null && city.isNotEmpty) 'city': city,
          if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
          if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
        },
        cancelToken: token,
      ),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        if (payload is List) {
          return payload.map((e) => Map<String, dynamic>.from(e)).toList();
        }
        return [];
      },
    );
  }

  Future<Map<String, dynamic>> getEventById(String id, {CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'informal_event_detail_$id',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get(
        '/informal-events/$id',
        cancelToken: token,
      ),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        return Map<String, dynamic>.from(payload);
      },
    );
  }

  Future<Map<String, dynamic>> createEvent({
    required String title,
    required String description,
    required String city,
    String? province,
    required String scheduledAt,
    int? maxParticipants,
    bool isPublic = true,
    CancelToken? cancelToken,
  }) async {
    return executeRequest(
      cacheKey: 'create_informal_event_${DateTime.now().millisecondsSinceEpoch}',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.post(
        '/informal-events',
        data: {
          'title': title,
          'description': description,
          'city': city,
          if (province != null) 'province': province,
          'scheduledAt': scheduledAt,
          if (maxParticipants != null) 'maxParticipants': maxParticipants,
          'isPublic': isPublic,
        },
        cancelToken: token,
      ),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        return Map<String, dynamic>.from(payload);
      },
    );
  }

  Future<Map<String, dynamic>> joinEvent(String id, {CancelToken? cancelToken}) async {
    return executeRequest(
      cacheKey: 'join_informal_event_${id}_${DateTime.now().millisecondsSinceEpoch}',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.post(
        '/informal-events/$id/join',
        cancelToken: token,
      ),
      parse: (data) {
        final payload = (data is Map && data.containsKey('data')) ? data['data'] : data;
        return Map<String, dynamic>.from(payload);
      },
    );
  }

  Future<void> leaveEvent(String id, {CancelToken? cancelToken}) async {
    await dioClient.dio.delete(
      '/informal-events/$id/leave',
      cancelToken: cancelToken,
    );
  }

  Future<void> deleteEvent(String id, {CancelToken? cancelToken}) async {
    await dioClient.dio.delete(
      '/informal-events/$id',
      cancelToken: cancelToken,
    );
  }
}


