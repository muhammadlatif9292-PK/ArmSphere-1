// lib/core/providers/admin_provider.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/dio_client.dart';
import '../api/repositories.dart';
import '../security/audit_chain_verifier.dart';
import 'athlete_provider.dart';
import 'championship_provider.dart';
import 'community_provider.dart';
import 'dependency_providers.dart';
import 'discover_provider.dart';
import 'dispute_provider.dart';
import 'live_matches_provider.dart';
import 'nomination_provider.dart';
import 'rankings_provider.dart';
import 'referee_provider.dart';
import 'support_provider.dart';
import 'tournament_provider.dart';
import 'venue_provider.dart';

/// Filter state for the Admin Athletes Registry (`Roster -> Athletes`).
class AdminAthleteFilter {
  final String search;
  final String status;
  final String province;

  const AdminAthleteFilter({
    this.search = '',
    this.status = '',
    this.province = '',
  });

  AdminAthleteFilter copyWith({
    String? search,
    String? status,
    String? province,
  }) {
    return AdminAthleteFilter(
      search: search ?? this.search,
      status: status ?? this.status,
      province: province ?? this.province,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminAthleteFilter &&
          search == other.search &&
          status == other.status &&
          province == other.province;

  @override
  int get hashCode => Object.hash(search, status, province);
}

/// Filter state for the Admin Audit Ledger (`Dossier -> Audit Ledger`).
class AdminAuditFilter {
  final String actionType;
  final String actorId;

  const AdminAuditFilter({
    this.actionType = '',
    this.actorId = '',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminAuditFilter &&
          actionType == other.actionType &&
          actorId == other.actorId;

  @override
  int get hashCode => Object.hash(actionType, actorId);
}

/// Filter state for the Admin Support Helpdesk (`Governance -> Helpdesk`).
class AdminSupportFilter {
  final String status;
  final String category;
  final bool myTicketsOnly;
  final String? currentUserId;

  const AdminSupportFilter({
    this.status = 'ALL',
    this.category = 'ALL',
    this.myTicketsOnly = false,
    this.currentUserId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminSupportFilter &&
          status == other.status &&
          category == other.category &&
          myTicketsOnly == other.myTicketsOnly &&
          currentUserId == other.currentUserId;

  @override
  int get hashCode =>
      Object.hash(status, category, myTicketsOnly, currentUserId);
}

/// Comprehensive Repository for all Federation Administrative & Regulatory APIs.
///
/// Connects directly to the real backend endpoints in `apps/api/src/routes/`
/// (`/admin/*`, `/analytics/*`, `/championships/*`, `/community/*`, `/venues/*`,
/// `/nominations/*`, `/support/*`, `/governance/*`, `/referees/*`).
class AdminRepository extends BaseRepository {
  AdminRepository({required super.dioClient, required super.hiveStorage});

  Map<String, dynamic> _unwrapMap(dynamic raw) {
    if (raw is Map && raw['data'] is Map) {
      return Map<String, dynamic>.from(raw['data'] as Map);
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _unwrapList(dynamic raw, {String? nestedKey}) {
    dynamic target = raw;
    if (raw is Map && raw.containsKey('data')) {
      target = raw['data'];
    }
    if (nestedKey != null && target is Map && target.containsKey(nestedKey)) {
      target = target[nestedKey];
    }
    if (target is List) {
      return target
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  // ===========================================================================
  // 1. EXECUTIVE COMMAND, ROLE APPLICATIONS & ANALYTICS
  // ===========================================================================

  Future<Map<String, dynamic>> getDashboardStats({CancelToken? cancelToken}) {
    return executeRequest(
      cacheKey: 'admin_dashboard_stats',
      cancelToken: cancelToken,
      request: (token) =>
          dioClient.dio.get('/admin/dashboard/stats', cancelToken: token),
      parse: _unwrapMap,
    );
  }

  Future<List<Map<String, dynamic>>> getRoleApplications({
    String? status,
    CancelToken? cancelToken,
  }) {
    return executeRequest(
      cacheKey: 'admin_role_applications_${status ?? "all"}',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get(
        '/admin/roles/applications',
        queryParameters: {
          if (status != null && status.isNotEmpty) 'status': status,
        },
        cancelToken: token,
      ),
      parse: (data) => _unwrapList(data, nestedKey: 'applications'),
    );
  }

  Future<Map<String, dynamic>> reviewRoleApplication({
    required String applicationId,
    required String status, // 'APPROVED' | 'REJECTED'
    String? reviewNotes,
  }) {
    return executeRequest(
      cacheKey:
          'admin_review_role_app_${applicationId}_${DateTime.now().millisecondsSinceEpoch}',
      isMutation: true,
      request: (token) => dioClient.dio.post(
        '/admin/roles/applications/$applicationId/review',
        data: {
          'decision': status,
          if (reviewNotes != null && reviewNotes.trim().isNotEmpty)
            'notes': reviewNotes.trim(),
        },
        cancelToken: token,
      ),
      parse: _unwrapMap,
    );
  }

  Future<Map<String, dynamic>> grantFederationRole({
    required String userId,
    required String role,
    Map<String, dynamic>? metadata,
    String? jurisdiction,
    String? reason,
  }) {
    final meta = metadata ?? <String, dynamic>{};
    if (jurisdiction != null && jurisdiction.trim().isNotEmpty) {
      meta['jurisdiction'] = jurisdiction.trim();
    }
    if (reason != null && reason.trim().isNotEmpty) {
      meta['reason'] = reason.trim();
    }

    return executeRequest(
      cacheKey:
          'admin_grant_role_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      isMutation: true,
      request: (token) => dioClient.dio.post(
        '/admin/roles/grant',
        data: {
          'userId': userId.trim(),
          'role': role.trim().toUpperCase(),
          if (meta.isNotEmpty) 'metadata': meta,
        },
        cancelToken: token,
      ),
      parse: _unwrapMap,
    );
  }

  Future<Map<String, dynamic>> getAnalyticsOverview({CancelToken? cancelToken}) {
    return executeRequest(
      cacheKey: 'admin_analytics_overview',
      cancelToken: cancelToken,
      request: (token) =>
          dioClient.dio.get('/analytics/overview', cancelToken: token),
      parse: _unwrapMap,
    );
  }

  Future<List<Map<String, dynamic>>> getEloDistribution({
    CancelToken? cancelToken,
  }) {
    return executeRequest(
      cacheKey: 'admin_analytics_elo_distribution',
      cancelToken: cancelToken,
      request: (token) =>
          dioClient.dio.get('/analytics/elo-distribution', cancelToken: token),
      parse: _unwrapList,
    );
  }

  Future<Map<String, dynamic>> triggerWorker({
    required String workerName,
  }) {
    return executeRequest(
      cacheKey:
          'admin_trigger_worker_${workerName}_${DateTime.now().millisecondsSinceEpoch}',
      isMutation: true,
      request: (token) => dioClient.dio.post(
        '/admin/workers/trigger',
        data: {'workerName': workerName},
        cancelToken: token,
      ),
      parse: _unwrapMap,
    );
  }

  Future<Map<String, dynamic>> runScheduledJobs() {
    return executeRequest(
      cacheKey:
          'admin_run_jobs_${DateTime.now().millisecondsSinceEpoch}',
      isMutation: true,
      request: (token) => dioClient.dio.post(
        '/admin/jobs/run-due',
        cancelToken: token,
      ),
      parse: _unwrapMap,
    );
  }

  Future<Map<String, dynamic>> exportReport({
    required String reportType, // 'athletes' | 'referees' | 'matches' | 'financial' | 'governance'
    required String format, // 'csv' | 'xlsx' | 'pdf'
  }) {
    return executeRequest(
      cacheKey:
          'admin_export_report_${reportType}_${DateTime.now().millisecondsSinceEpoch}',
      isMutation: true,
      request: (token) => dioClient.dio.post(
        '/admin/reports/export',
        data: {
          'reportType': reportType.toLowerCase(),
          'format': format.toLowerCase(),
        },
        options: Options(responseType: ResponseType.plain),
        cancelToken: token,
      ),
      parse: (data) {
        if (data is String) {
          return {
            'success': true,
            'format': format.toLowerCase(),
            'reportType': reportType.toLowerCase(),
            'rawContent': data,
          };
        }
        return _unwrapMap(data);
      },
    );
  }

  // ===========================================================================
  // 2. ROSTER: ATHLETES, REFEREES & TALENT SCOUTING
  // ===========================================================================

  Future<List<Map<String, dynamic>>> getAthletes({
    String? search,
    String? status,
    String? province,
    CancelToken? cancelToken,
  }) {
    final normalizedStatus = status?.trim().toUpperCase() ?? '';
    final isPendingFilter = normalizedStatus == 'PENDING';
    return executeRequest(
      cacheKey:
          'admin_athletes_${search ?? ""}_${normalizedStatus}_${province ?? ""}',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get(
        '/admin/athletes',
        queryParameters: {
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
          if (normalizedStatus.isNotEmpty && !isPendingFilter)
            'status': normalizedStatus,
          if (province != null && province.trim().isNotEmpty)
            'province': province.trim(),
        },
        cancelToken: token,
      ),
      parse: (data) {
        final list = _unwrapList(data, nestedKey: 'athletes');
        if (isPendingFilter) {
          return list.where((a) {
            final s = (a['verificationStatus'] ?? a['status'] ?? 'UNVERIFIED')
                .toString()
                .toUpperCase();
            return s == 'PENDING' || s == 'UNVERIFIED';
          }).toList();
        }
        return list;
      },
    );
  }

  Future<Map<String, dynamic>> reviewAthlete({
    required String athleteId,
    required String status, // 'VERIFIED' | 'REJECTED'
    String? reason,
  }) {
    return executeRequest(
      cacheKey:
          'admin_review_athlete_${athleteId}_${DateTime.now().millisecondsSinceEpoch}',
      isMutation: true,
      request: (token) => dioClient.dio.post(
        '/admin/athletes/$athleteId/review',
        data: {
          'status': status,
          if (reason != null && reason.trim().isNotEmpty)
            'reason': reason.trim(),
        },
        cancelToken: token,
      ),
      parse: _unwrapMap,
    );
  }

  Future<Map<String, dynamic>> suspendAthlete({
    required String athleteId,
    required String reason,
    int? durationDays,
  }) {
    return executeRequest(
      cacheKey:
          'admin_suspend_athlete_${athleteId}_${DateTime.now().millisecondsSinceEpoch}',
      isMutation: true,
      request: (token) => dioClient.dio.post(
        '/admin/athletes/$athleteId/suspend',
        data: {
          'reason': reason.trim(),
          if (durationDays != null) 'durationDays': durationDays,
        },
        cancelToken: token,
      ),
      parse: _unwrapMap,
    );
  }

  Future<Map<String, dynamic>> blacklistAthlete({
    required String athleteId,
    required String reason,
  }) {
    return executeRequest(
      cacheKey:
          'admin_blacklist_athlete_${athleteId}_${DateTime.now().millisecondsSinceEpoch}',
      isMutation: true,
      request: (token) => dioClient.dio.post(
        '/admin/athletes/$athleteId/blacklist',
        data: {'reason': reason.trim()},
        cancelToken: token,
      ),
      parse: _unwrapMap,
    );
  }

  Future<Map<String, dynamic>> recoverAthlete({
    required String athleteId,
    String? reason,
  }) {
    return executeRequest(
      cacheKey:
          'admin_recover_athlete_${athleteId}_${DateTime.now().millisecondsSinceEpoch}',
      isMutation: true,
      request: (token) => dioClient.dio.post(
        '/admin/athletes/$athleteId/recover',
        data: {
          if (reason != null && reason.trim().isNotEmpty)
            'reason': reason.trim(),
        },
        cancelToken: token,
      ),
      parse: _unwrapMap,
    );
  }

  Future<Map<String, dynamic>> correctAthleteProfile({
    required String athleteId,
    String? displayName,
    String? weightClass,
    String? province,
    String? city,
    int? rightArmElo,
    int? leftArmElo,
    String? reason,
  }) {
    return executeRequest(
      cacheKey:
          'admin_correct_athlete_${athleteId}_${DateTime.now().millisecondsSinceEpoch}',
      isMutation: true,
      request: (token) => dioClient.dio.post(
        '/admin/athletes/$athleteId/correct',
        data: {
          if (displayName != null && displayName.trim().isNotEmpty)
            'displayName': displayName.trim(),
          if (weightClass != null && weightClass.trim().isNotEmpty)
            'weightClass': weightClass.trim(),
          if (province != null && province.trim().isNotEmpty)
            'province': province.trim(),
          if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
          if (rightArmElo != null) 'rightArmElo': rightArmElo,
          if (leftArmElo != null) 'leftArmElo': leftArmElo,
        },
        cancelToken: token,
      ),
      parse: _unwrapMap,
    );
  }

  Future<List<Map<String, dynamic>>> getAthleteCertifications(
    String athleteUserId, {
    CancelToken? cancelToken,
  }) {
    return executeRequest(
      cacheKey: 'admin_athlete_certs_$athleteUserId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get(
        '/referees/$athleteUserId/certifications',
        cancelToken: token,
      ),
      parse: _unwrapList,
    );
  }

  Future<Map<String, dynamic>> issueRefereeCertification({
    required String athleteUserId,
    required String certificationLevel,
    required String issuingAuthority,
    required String issuedAt,
    String? expiresAt,
  }) {
    return executeRequest(
      cacheKey:
          'admin_issue_cert_${athleteUserId}_${DateTime.now().millisecondsSinceEpoch}',
      isMutation: true,
      request: (token) => dioClient.dio.post(
        '/referees/$athleteUserId/certifications',
        data: {
          'certificationLevel': certificationLevel,
          'issuedAt': issuedAt,
          if (expiresAt != null && expiresAt.isNotEmpty) 'expiresAt': expiresAt,
          'issuingBody': issuingAuthority.trim(),
        },
        cancelToken: token,
      ),
      parse: _unwrapMap,
    );
  }

  Future<Map<String, dynamic>> revokeRefereeCertification(
    String certificationId,
  ) {
    return executeRequest(
      cacheKey:
          'admin_revoke_cert_${certificationId}_${DateTime.now().millisecondsSinceEpoch}',
      isMutation: true,
      request: (token) => dioClient.dio.patch(
        '/referees/certifications/$certificationId/revoke',
        cancelToken: token,
      ),
      parse: _unwrapMap,
    );
  }

  Future<List<Map<String, dynamic>>> getReferees({CancelToken? cancelToken}) {
    return executeRequest(
      cacheKey: 'admin_referees_list',
      cancelToken: cancelToken,
      request: (token) =>
          dioClient.dio.get('/admin/referees', cancelToken: token),
      parse: (data) => _unwrapList(data, nestedKey: 'referees'),
    );
  }

  Future<Map<String, dynamic>> updateRefereeLicense({
    required String refereeId,
    required String certification,
    required String status,
  }) {
    return executeRequest(
      cacheKey:
          'admin_ref_license_${refereeId}_${DateTime.now().millisecondsSinceEpoch}',
      isMutation: true,
      request: (token) => dioClient.dio.post(
        '/admin/referees/$refereeId/license',
        data: {
          'certification': certification.trim(),
          'status': status.trim(),
        },
        cancelToken: token,
      ),
      parse: _unwrapMap,
    );
  }

  Future<Map<String, dynamic>> updateRefereeRegion({
    required String refereeId,
    required String regionalCoverage,
  }) {
    return executeRequest(
      cacheKey:
          'admin_ref_region_${refereeId}_${DateTime.now().millisecondsSinceEpoch}',
      isMutation: true,
      request: (token) => dioClient.dio.post(
        '/admin/referees/$refereeId/region',
        data: {'region': regionalCoverage.trim()},
        cancelToken: token,
      ),
      parse: _unwrapMap,
    );
  }

  Future<Map<String, dynamic>> suspendReferee({
    required String refereeId,
    required String reason,
  }) {
    return executeRequest(
      cacheKey:
          'admin_ref_suspend_${refereeId}_${DateTime.now().millisecondsSinceEpoch}',
      isMutation: true,
      request: (token) => dioClient.dio.post(
        '/admin/referees/$refereeId/suspend',
        data: {'reason': reason.trim()},
        cancelToken: token,
      ),
      parse: _unwrapMap,
    );
  }

  Future<List<Map<String, dynamic>>> getAllNominations({
    CancelToken? cancelToken,
  }) {
    return executeRequest(
      cacheKey: 'admin_nominations_all',
      cancelToken: cancelToken,
      request: (token) =>
          dioClient.dio.get('/nominations', cancelToken: token),
      parse: _unwrapList,
    );
  }

  Future<Map<String, dynamic>> updateNominationStatus({
    required String nominationId,
    required String status, // 'PENDING' | 'CONTACTED' | 'REGISTERED' | 'DECLINED'
  }) {
    return executeRequest(
      cacheKey:
          'admin_update_nom_${nominationId}_${DateTime.now().millisecondsSinceEpoch}',
      isMutation: true,
      request: (token) => dioClient.dio.patch(
        '/nominations/$nominationId/status',
        data: {'status': status},
        cancelToken: token,
      ),
      parse: _unwrapMap,
    );
  }

  // ===========================================================================
  // 3. ARENA OPS: MATCH OVERSIGHT, WEIGH-IN & CHAMPIONSHIPS
  // ===========================================================================

  Future<List<Map<String, dynamic>>> getAdminMatches({
    CancelToken? cancelToken,
  }) {
    return executeRequest(
      cacheKey: 'admin_matches_list',
      cancelToken: cancelToken,
      request: (token) =>
          dioClient.dio.get('/admin/matches', cancelToken: token),
      parse: (data) => _unwrapList(data, nestedKey: 'matches'),
    );
  }

  Future<Map<String, dynamic>> inspectMatch(String matchId) {
    return executeRequest(
      cacheKey: 'admin_inspect_match_$matchId',
      request: (token) =>
          dioClient.dio.get('/admin/matches/$matchId', cancelToken: token),
      parse: _unwrapMap,
    );
  }

  Future<Map<String, dynamic>> correctMatchResult({
    required String matchId,
    required String winnerId,
    required int scoreA,
    required int scoreB,
    String? reason,
  }) {
    return executeRequest(
      cacheKey:
          'admin_correct_match_${matchId}_${DateTime.now().millisecondsSinceEpoch}',
      isMutation: true,
      request: (token) => dioClient.dio.post(
        '/admin/matches/$matchId/correct',
        data: {
          'winnerId': winnerId,
          'scoreLine': '$scoreA-$scoreB',
        },
        cancelToken: token,
      ),
      parse: _unwrapMap,
    );
  }

  Future<Map<String, dynamic>> voidMatch({
    required String matchId,
    required String reason,
  }) {
    return executeRequest(
      cacheKey:
          'admin_void_match_${matchId}_${DateTime.now().millisecondsSinceEpoch}',
      isMutation: true,
      request: (token) => dioClient.dio.post(
        '/admin/matches/$matchId/void',
        data: {'reason': reason.trim()},
        cancelToken: token,
      ),
      parse: _unwrapMap,
    );
  }

  Future<Map<String, dynamic>> manageWeighIn({
    required String registrationId,
    required double weight,
    required String status, // 'PASSED' | 'FAILED'
  }) {
    return executeRequest(
      cacheKey:
          'admin_weighin_${registrationId}_${DateTime.now().millisecondsSinceEpoch}',
      isMutation: true,
      request: (token) => dioClient.dio.post(
        '/admin/events/weighin',
        data: {
          'registrationId': registrationId,
          'weight': weight,
          'status': status,
        },
        cancelToken: token,
      ),
      parse: _unwrapMap,
    );
  }

  Future<List<Map<String, dynamic>>> getChampionshipTitles({
    CancelToken? cancelToken,
  }) {
    return executeRequest(
      cacheKey: 'admin_championship_titles',
      cancelToken: cancelToken,
      request: (token) =>
          dioClient.dio.get('/championships/titles', cancelToken: token),
      parse: _unwrapList,
    );
  }

  Future<Map<String, dynamic>> createChampionshipTitle({
    required String name,
    required String arm, // 'RIGHT' | 'LEFT'
    required String division, // 'SENIOR' | 'JUNIOR' | 'FEMALE'
    required String weightClass,
  }) {
    return executeRequest(
      cacheKey:
          'admin_create_title_${DateTime.now().millisecondsSinceEpoch}',
      isMutation: true,
      request: (token) => dioClient.dio.post(
        '/championships/titles',
        data: {
          'name': name.trim(),
          'arm': arm,
          'division': division,
          'weightClass': weightClass.trim(),
        },
        cancelToken: token,
      ),
      parse: _unwrapMap,
    );
  }

  Future<Map<String, dynamic>> manageChampionshipTitle({
    required String titleId,
    required String action, // 'ASSIGN' | 'VACATE' | 'RECALCULATE'
    String? athleteId,
  }) {
    return executeRequest(
      cacheKey:
          'admin_manage_title_${titleId}_${action}_${DateTime.now().millisecondsSinceEpoch}',
      isMutation: true,
      request: (token) => dioClient.dio.post(
        '/admin/championships/titles/$titleId',
        data: {
          'action': action,
          if (athleteId != null && athleteId.isNotEmpty) 'athleteId': athleteId,
        },
        cancelToken: token,
      ),
      parse: _unwrapMap,
    );
  }

  Future<Map<String, dynamic>> vacateChampionshipTitle({
    required String titleId,
    required String reason, // 'VACATED' | 'STRIPPED'
  }) {
    return executeRequest(
      cacheKey:
          'admin_vacate_title_${titleId}_${DateTime.now().millisecondsSinceEpoch}',
      isMutation: true,
      request: (token) => dioClient.dio.post(
        '/championships/vacate',
        data: {
          'titleId': titleId,
          'reason': reason,
        },
        cancelToken: token,
      ),
      parse: _unwrapMap,
    );
  }

  Future<Map<String, dynamic>> defendChampionshipTitle({
    required String titleId,
    required String winnerId,
    required String matchId,
  }) {
    return executeRequest(
      cacheKey:
          'admin_defend_title_${titleId}_${DateTime.now().millisecondsSinceEpoch}',
      isMutation: true,
      request: (token) => dioClient.dio.post(
        '/championships/defend',
        data: {
          'titleId': titleId,
          'winnerId': winnerId,
          'matchId': matchId,
        },
        cancelToken: token,
      ),
      parse: _unwrapMap,
    );
  }

  Future<Map<String, dynamic>> recomputePrestigeScores() {
    return executeRequest(
      cacheKey:
          'admin_recompute_prestige_${DateTime.now().millisecondsSinceEpoch}',
      isMutation: true,
      request: (token) => dioClient.dio.post(
        '/championships/prestige/recompute',
        cancelToken: token,
      ),
      parse: _unwrapMap,
    );
  }

  Future<List<Map<String, dynamic>>> getTitleLineage(
    String titleId, {
    CancelToken? cancelToken,
  }) {
    return executeRequest(
      cacheKey: 'admin_title_lineage_$titleId',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get(
        '/championships/titles/$titleId/lineage',
        cancelToken: token,
      ),
      parse: _unwrapList,
    );
  }

  Future<List<Map<String, dynamic>>> getPendingChallenges({
    CancelToken? cancelToken,
  }) {
    return executeRequest(
      cacheKey: 'admin_pending_challenges',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get(
        '/championships/challenges',
        queryParameters: const {'status': 'PENDING'},
        cancelToken: token,
      ),
      parse: _unwrapList,
    );
  }

  Future<Map<String, dynamic>> respondToChallenge({
    required String challengeId,
    required bool accept,
  }) {
    final action = accept ? 'accept' : 'decline';
    return executeRequest(
      cacheKey:
          'admin_challenge_${challengeId}_${action}_${DateTime.now().millisecondsSinceEpoch}',
      isMutation: true,
      request: (token) => dioClient.dio.post(
        '/championships/challenges/$challengeId/$action',
        cancelToken: token,
      ),
      parse: _unwrapMap,
    );
  }

  // ===========================================================================
  // 4. GOVERNANCE: DISPUTES, COMMUNITY MODERATION, GYMS & HELPDESK
  // ===========================================================================

  Future<List<Map<String, dynamic>>> getAdminDisputes({
    CancelToken? cancelToken,
  }) {
    return executeRequest(
      cacheKey: 'admin_disputes_all',
      cancelToken: cancelToken,
      request: (token) =>
          dioClient.dio.get('/admin/disputes', cancelToken: token),
      parse: (data) => _unwrapList(data, nestedKey: 'disputes'),
    );
  }

  Future<Map<String, dynamic>> resolveDispute({
    required String disputeId,
    required String status, // 'RESOLVED_UPHELD' | 'RESOLVED_OVERTURNED' | 'RESOLVED' | 'REJECTED'
    required String resolutionNotes,
  }) {
    final decision = (status.contains('REJECTED') || status == 'REJECTED')
        ? 'REJECTED'
        : 'RESOLVED';

    return executeRequest(
      cacheKey:
          'admin_resolve_dispute_${disputeId}_${DateTime.now().millisecondsSinceEpoch}',
      isMutation: true,
      request: (token) => dioClient.dio.post(
        '/admin/disputes/$disputeId/resolve',
        data: {
          'decision': decision,
          'resolutionDetails': resolutionNotes.trim(),
        },
        cancelToken: token,
      ),
      parse: _unwrapMap,
    );
  }

  Future<Map<String, dynamic>> closeDispute(String disputeId) {
    return executeRequest(
      cacheKey:
          'admin_close_dispute_${disputeId}_${DateTime.now().millisecondsSinceEpoch}',
      isMutation: true,
      request: (token) => dioClient.dio.post(
        '/governance/disputes/$disputeId/close',
        cancelToken: token,
      ),
      parse: _unwrapMap,
    );
  }

  Future<List<Map<String, dynamic>>> getPendingCommunityLinks({
    CancelToken? cancelToken,
  }) {
    return executeRequest(
      cacheKey: 'admin_pending_community_links',
      cancelToken: cancelToken,
      request: (token) =>
          dioClient.dio.get('/community/links/pending', cancelToken: token),
      parse: _unwrapList,
    );
  }

  Future<Map<String, dynamic>> moderateCommunityLink({
    required String postId,
    required String decision, // 'APPROVED' | 'REJECTED'
  }) {
    return executeRequest(
      cacheKey:
          'admin_moderate_link_${postId}_${DateTime.now().millisecondsSinceEpoch}',
      isMutation: true,
      request: (token) => dioClient.dio.post(
        '/community/links/$postId/moderate',
        data: {'decision': decision},
        cancelToken: token,
      ),
      parse: _unwrapMap,
    );
  }

  Future<List<Map<String, dynamic>>> getAllVenues({CancelToken? cancelToken}) {
    return executeRequest(
      cacheKey: 'admin_venues_all',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get('/venues', cancelToken: token),
      parse: _unwrapList,
    );
  }

  Future<Map<String, dynamic>> verifyVenue(String venueId) {
    return executeRequest(
      cacheKey:
          'admin_verify_venue_${venueId}_${DateTime.now().millisecondsSinceEpoch}',
      isMutation: true,
      request: (token) => dioClient.dio.post(
        '/venues/$venueId/verify',
        cancelToken: token,
      ),
      parse: _unwrapMap,
    );
  }

  Future<List<Map<String, dynamic>>> getSupportTickets({
    String? status,
    String? category,
    String? assignedAgentId,
    CancelToken? cancelToken,
  }) {
    return executeRequest(
      cacheKey:
          'admin_support_tickets_${status ?? "ALL"}_${category ?? "ALL"}_${assignedAgentId ?? "ALL"}',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get(
        '/support/tickets',
        queryParameters: {
          if (status != null && status.isNotEmpty && status != 'ALL')
            'status': status,
          if (category != null && category.isNotEmpty && category != 'ALL')
            'category': category,
          if (assignedAgentId != null && assignedAgentId.isNotEmpty)
            'assignedAgentId': assignedAgentId,
        },
        cancelToken: token,
      ),
      parse: _unwrapList,
    );
  }

  Future<Map<String, dynamic>> getSupportTicketDetail(
    String ticketId, {
    CancelToken? cancelToken,
  }) {
    return executeRequest(
      cacheKey: 'admin_support_ticket_detail_$ticketId',
      cancelToken: cancelToken,
      request: (token) =>
          dioClient.dio.get('/support/tickets/$ticketId', cancelToken: token),
      parse: _unwrapMap,
    );
  }

  Future<Map<String, dynamic>> assignSupportTicket({
    required String ticketId,
    required String? agentId,
  }) {
    return executeRequest(
      cacheKey:
          'admin_assign_ticket_${ticketId}_${DateTime.now().millisecondsSinceEpoch}',
      isMutation: true,
      request: (token) => dioClient.dio.post(
        '/support/tickets/$ticketId/assign',
        data: {
          'agentId': agentId,
          'assignedAgentId': agentId,
        },
        cancelToken: token,
      ),
      parse: _unwrapMap,
    );
  }

  Future<Map<String, dynamic>> updateSupportTicketStatus({
    required String ticketId,
    required String status, // 'OPEN' | 'IN_PROGRESS' | 'RESOLVED' | 'CLOSED'
    String? resolutionNotes,
  }) {
    return executeRequest(
      cacheKey:
          'admin_ticket_status_${ticketId}_${DateTime.now().millisecondsSinceEpoch}',
      isMutation: true,
      request: (token) => dioClient.dio.patch(
        '/support/tickets/$ticketId/status',
        data: {
          'status': status,
          if (resolutionNotes != null && resolutionNotes.trim().isNotEmpty)
            'resolutionNotes': resolutionNotes.trim(),
        },
        cancelToken: token,
      ),
      parse: _unwrapMap,
    );
  }

  Future<Map<String, dynamic>> addSupportTicketMessage({
    required String ticketId,
    required String message,
    bool isInternal = false,
  }) {
    return executeRequest(
      cacheKey:
          'admin_ticket_msg_${ticketId}_${DateTime.now().millisecondsSinceEpoch}',
      isMutation: true,
      request: (token) => dioClient.dio.post(
        '/support/tickets/$ticketId/messages',
        data: {
          'message': message.trim(),
          'content': message.trim(),
          'isInternal': isInternal,
        },
        cancelToken: token,
      ),
      parse: _unwrapMap,
    );
  }

  // ===========================================================================
  // 5. DOSSIER: CRYPTOGRAPHIC SHA-256 AUDIT LEDGER
  // ===========================================================================

  Future<List<Map<String, dynamic>>> getAuditEvents({
    String? actionType,
    String? actorId,
    int limit = 50,
    CancelToken? cancelToken,
  }) {
    return executeRequest(
      cacheKey:
          'admin_audit_events_${actionType ?? ""}_${actorId ?? ""}_$limit',
      cancelToken: cancelToken,
      request: (token) => dioClient.dio.get(
        '/admin/audit/events',
        queryParameters: {
          'limit': limit,
          if (actionType != null && actionType.trim().isNotEmpty)
            'actionType': actionType.trim(),
          if (actorId != null && actorId.trim().isNotEmpty)
            'actorId': actorId.trim(),
        },
        cancelToken: token,
      ),
      parse: (data) => _unwrapList(data, nestedKey: 'events'),
    );
  }

  Future<Map<String, dynamic>> verifyAuditHashChain({
    CancelToken? cancelToken,
  }) {
    return executeRequest(
      cacheKey:
          'admin_audit_verify_${DateTime.now().millisecondsSinceEpoch ~/ 5000}',
      cancelToken: cancelToken,
      request: (token) =>
          dioClient.dio.get('/admin/audit/verify', cancelToken: token),
      parse: _unwrapMap,
    );
  }
}

// =============================================================================
// CROSS-APPLICATION STATE SYNCHRONIZATION COORDINATOR
// =============================================================================

/// Coordinates real-time provider invalidation and Hive cache eviction whenever
/// an administrator executes any mutation. This guarantees that user-facing
/// screens (Athlete Passport, Rankings Leaderboard, Community Feed, Venues, etc.)
/// immediately reflect changes without app restart or stale cache display.
class AdminCrossAppSync {
  const AdminCrossAppSync._();

  static Future<void> syncAthleteMutations(WidgetRef ref) async {
    final hive = ref.read(hiveStorageProvider);
    await hive.evictByPrefix('athlete_');
    await hive.evictByPrefix('rankings_');
    await hive.evictByPrefix('discover_');
    await hive.evictByPrefix('admin_athletes_');
    await hive.evictCache('admin_dashboard_stats');

    ref.invalidate(athleteProfileProvider);
    ref.invalidate(rankingsProvider);
    ref.invalidate(discoverFeedProvider);
    ref.invalidate(adminDashboardStatsProvider);
  }

  static Future<void> syncRefereeMutations(WidgetRef ref) async {
    final hive = ref.read(hiveStorageProvider);
    await hive.evictByPrefix('admin_referees_');
    await hive.evictByPrefix('admin_athlete_certs_');
    await hive.evictCache('admin_dashboard_stats');

    ref.invalidate(refereeProvider);
    ref.invalidate(refereeDirectoryProvider);
    ref.invalidate(refereeCertificationsProvider);
    ref.invalidate(adminRefereesProvider);
    ref.invalidate(adminDashboardStatsProvider);
  }

  static Future<void> syncMatchMutations(WidgetRef ref) async {
    final hive = ref.read(hiveStorageProvider);
    await hive.evictByPrefix('admin_matches_');
    await hive.evictByPrefix('matches_');
    await hive.evictByPrefix('rankings_');
    await hive.evictByPrefix('discover_');
    await hive.evictCache('admin_dashboard_stats');

    ref.invalidate(liveMatchesProvider);
    ref.invalidate(rankingsProvider);
    ref.invalidate(discoverFeedProvider);
    ref.invalidate(tournamentProvider);
    ref.invalidate(bracketsListProvider);
    ref.invalidate(adminMatchesProvider);
    ref.invalidate(adminDashboardStatsProvider);
  }

  static Future<void> syncChampionshipMutations(WidgetRef ref) async {
    final hive = ref.read(hiveStorageProvider);
    await hive.evictByPrefix('admin_championship_');
    await hive.evictByPrefix('admin_pending_challenges');
    await hive.evictByPrefix('admin_title_lineage_');
    await hive.evictByPrefix('championship_');
    await hive.evictByPrefix('rankings_');
    await hive.evictCache('admin_dashboard_stats');

    ref.invalidate(championshipProvider);
    ref.invalidate(rankingsProvider);
    ref.invalidate(discoverFeedProvider);
    ref.invalidate(adminChampionshipTitlesProvider);
    ref.invalidate(adminPendingChallengesProvider);
    ref.invalidate(adminDashboardStatsProvider);
  }

  static Future<void> syncDisputeMutations(WidgetRef ref) async {
    final hive = ref.read(hiveStorageProvider);
    await hive.evictByPrefix('admin_disputes_');
    await hive.evictByPrefix('disputes_');
    await hive.evictCache('admin_dashboard_stats');

    ref.invalidate(disputeProvider);
    ref.invalidate(adminDisputesProvider);
    ref.invalidate(adminDashboardStatsProvider);
  }

  static Future<void> syncCommunityMutations(WidgetRef ref) async {
    final hive = ref.read(hiveStorageProvider);
    await hive.evictByPrefix('admin_pending_community_links');
    await hive.evictByPrefix('community_');

    ref.invalidate(communityFeedProvider);
    ref.invalidate(adminPendingCommunityLinksProvider);
  }

  static Future<void> syncVenueMutations(WidgetRef ref) async {
    final hive = ref.read(hiveStorageProvider);
    await hive.evictByPrefix('admin_venues_');
    await hive.evictByPrefix('venues_');

    ref.invalidate(venueListProvider);
    ref.invalidate(adminVenuesProvider);
  }

  static Future<void> syncNominationMutations(WidgetRef ref) async {
    final hive = ref.read(hiveStorageProvider);
    await hive.evictByPrefix('admin_nominations_');
    await hive.evictByPrefix('nominations_');

    ref.invalidate(nominationListProvider);
    ref.invalidate(adminNominationsProvider);
  }

  static Future<void> syncSupportMutations(WidgetRef ref) async {
    final hive = ref.read(hiveStorageProvider);
    await hive.evictByPrefix('admin_support_');
    await hive.evictByPrefix('support_');

    ref.invalidate(supportTicketsProvider(null));
    ref.invalidate(adminSupportTicketsProvider);
  }

  static Future<void> syncRoleMutations(WidgetRef ref) async {
    final hive = ref.read(hiveStorageProvider);
    await hive.evictByPrefix('admin_role_applications_');
    await hive.evictByPrefix('athlete_');
    await hive.evictCache('admin_dashboard_stats');

    ref.invalidate(athleteProfileProvider);
    ref.invalidate(adminRoleApplicationsProvider);
    ref.invalidate(adminDashboardStatsProvider);
  }
}

// =============================================================================
// RIVERPOD PROVIDERS
// =============================================================================

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final hiveStorage = ref.watch(hiveStorageProvider);
  return AdminRepository(dioClient: dioClient, hiveStorage: hiveStorage);
});

/// Navigation sub-segment state providers so tapping a backlog card on the
/// `Command` tab can deep-link directly to a specific sub-segment & filter!
final adminRosterSegmentProvider = StateProvider<int>((ref) => 0);
final adminRosterStatusFilterProvider = StateProvider<String>((ref) => '');
final adminArenaOpsSegmentProvider = StateProvider<int>((ref) => 0);
final adminGovernanceSegmentProvider = StateProvider<int>((ref) => 0);

// Tab 1: Command & Analytics
final adminDashboardStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.watch(adminRepositoryProvider).getDashboardStats();
});

final adminRoleApplicationsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminRepositoryProvider).getRoleApplications();
});

final adminAnalyticsOverviewProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.watch(adminRepositoryProvider).getAnalyticsOverview();
});

final adminEloDistributionProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminRepositoryProvider).getEloDistribution();
});

// Tab 2: Roster (Athletes, Referees, Nominations)
final adminAthletesProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, AdminAthleteFilter>((ref, filter) async {
  return ref.watch(adminRepositoryProvider).getAthletes(
        search: filter.search,
        status: filter.status,
        province: filter.province,
      );
});

final adminAthleteCertificationsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, athleteUserId) async {
  return ref.watch(adminRepositoryProvider).getAthleteCertifications(athleteUserId);
});

final adminRefereesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminRepositoryProvider).getReferees();
});

final adminNominationsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminRepositoryProvider).getAllNominations();
});

// Tab 3: Arena Ops (Matches, Championships, Challenges)
final adminMatchesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminRepositoryProvider).getAdminMatches();
});

final adminChampionshipTitlesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminRepositoryProvider).getChampionshipTitles();
});

final adminPendingChallengesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminRepositoryProvider).getPendingChallenges();
});

final adminTitleLineageProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, titleId) async {
  return ref.watch(adminRepositoryProvider).getTitleLineage(titleId);
});

// Tab 4: Governance (Disputes, Moderation, Venues, Support)
final adminDisputesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminRepositoryProvider).getAdminDisputes();
});

final adminPendingCommunityLinksProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminRepositoryProvider).getPendingCommunityLinks();
});

final adminVenuesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminRepositoryProvider).getAllVenues();
});

final adminSupportTicketsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, AdminSupportFilter>((ref, filter) async {
  return ref.watch(adminRepositoryProvider).getSupportTickets(
        status: filter.status,
        category: filter.category,
        assignedAgentId: filter.myTicketsOnly ? filter.currentUserId : null,
      );
});

final adminSupportTicketDetailProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, ticketId) async {
  return ref.watch(adminRepositoryProvider).getSupportTicketDetail(ticketId);
});

// Tab 5: Dossier & Cryptographic SHA-256 Audit Ledger
final adminAuditEventsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, AdminAuditFilter>((ref, filter) async {
  return ref.watch(adminRepositoryProvider).getAuditEvents(
        actionType: filter.actionType,
        actorId: filter.actorId,
      );
});

final adminAuditVerificationProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.watch(adminRepositoryProvider).verifyAuditHashChain();
});

/// Comprehensive Dual Client + Server Cryptographic Ledger Verification Provider.
final adminFullAuditReportProvider =
    FutureProvider.autoDispose<AuditChainVerificationReport>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final events = await repo.getAuditEvents(limit: 100);
  Map<String, dynamic>? serverResult;
  try {
    serverResult = await repo.verifyAuditHashChain();
  } catch (_) {
    // If server check fails or network error occurs, client still validates chain
  }
  return AuditChainVerifier.verifyChain(
    rawEvents: events,
    serverVerificationResponse: serverResult,
  );
});
