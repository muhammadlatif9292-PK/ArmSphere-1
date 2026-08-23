/// ArmSphere Professional Client SDK
/// AUTOMATICALLY GENERATED FROM OPENAPI DEFINITION. DO NOT EDIT DIRECTLY.

import 'dart:convert';
import 'package:http/http.dart' as http;

class ArmSphereException implements Exception {
  final String title;
  final String detail;
  final int status;
  ArmSphereException(this.title, this.detail, this.status);

  @override
  String toString() => 'ArmSphereException: [$status] $title - $detail';
}

class ArmSphereClient {
  final String baseUrl;
  String? token;
  String? csrfToken;

  ArmSphereClient({this.baseUrl = 'http://localhost:3000', this.token, this.csrfToken});

  void setToken(String newToken) {
    token = newToken;
  }

  void setCsrfToken(String newToken) {
    csrfToken = newToken;
  }

  Future<Map<String, dynamic>> _request(String method, String path, {Map<String, dynamic>? body, Map<String, dynamic>? queryParams}) async {
    var uri = Uri.parse('$baseUrl$path');
    if (queryParams != null) {
      uri = uri.replace(queryParameters: queryParams.map((key, value) => MapEntry(key, value.toString())));
    }

    final headers = {
      'Content-Type': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (csrfToken != null) {
      headers['x-csrf-token'] = csrfToken!;
    }

    http.Response response;
    final bodyStr = body != null ? jsonEncode(body) : null;

    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(uri, headers: headers);
        break;
      case 'POST':
        response = await http.post(uri, headers: headers, body: bodyStr);
        break;
      case 'PUT':
        response = await http.put(uri, headers: headers, body: bodyStr);
        break;
      case 'PATCH':
        response = await http.patch(uri, headers: headers, body: bodyStr);
        break;
      case 'DELETE':
        response = await http.delete(uri, headers: headers, body: bodyStr);
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }

    if (response.statusCode >= 400) {
      try {
        final err = jsonDecode(response.body);
        throw ArmSphereException(err['title'] ?? 'HTTP Error', err['detail'] ?? '', response.statusCode);
      } catch (e) {
        if (e is ArmSphereException) rethrow;
        throw ArmSphereException('HTTP Error', response.reasonPhrase ?? '', response.statusCode);
      }
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Register a new user account
  /// Creates a new user profile with selected roles.
  Future<Map<String, dynamic>> registerANewUserAccount(Map<String, dynamic> body) async {
    return _request(
      'POST',
      '/api/v1/auth/register',
      body: body,
      ,
    );
  }

  /// Authenticate a user
  /// Validates credentials, checks for impossible travel/device changes, and prompts MFA if enabled.
  Future<Map<String, dynamic>> authenticateAUser(Map<String, dynamic> body) async {
    return _request(
      'POST',
      '/api/v1/auth/login',
      body: body,
      ,
    );
  }

  /// Initiate MFA Setup
  /// Generates a dynamic TOTP secret, a setup QR code, and backup recovery codes.
  Future<Map<String, dynamic>> initiateMfaSetup() async {
    return _request(
      'POST',
      '/api/v1/auth/mfa/setup',
      ,
      ,
    );
  }

  /// Verify and enable MFA or solve login challenge
  /// Validates a TOTP token code to activate MFA, or complete login flow when unauthenticated.
  Future<Map<String, dynamic>> verifyAndEnableMfaOrSolveLoginChallenge(Map<String, dynamic> body) async {
    return _request(
      'POST',
      '/api/v1/auth/mfa/verify',
      body: body,
      ,
    );
  }

  /// Recover account access via backup recovery code
  /// Allows a locked out user with active MFA to log in using one of their unused backup recovery codes.
  Future<Map<String, dynamic>> recoverAccountAccessViaBackupRecoveryCode(Map<String, dynamic> body) async {
    return _request(
      'POST',
      '/api/v1/auth/mfa/recovery',
      body: body,
      ,
    );
  }

  /// Google OAuth login initiator
  /// Redirects the client to Google OAuth Consent Page.
  Future<Map<String, dynamic>> googleOauthLoginInitiator(Map<String, dynamic>? queryParams) async {
    return _request(
      'GET',
      '/api/v1/auth/google',
      ,
      queryParams: queryParams,
    );
  }

  /// Apple OAuth login initiator
  /// Redirects the client to Apple Sign-In screen.
  Future<Map<String, dynamic>> appleOauthLoginInitiator(Map<String, dynamic>? queryParams) async {
    return _request(
      'GET',
      '/api/v1/auth/apple',
      ,
      queryParams: queryParams,
    );
  }

  /// Create athlete profile
  /// Creates an athlete profile linking weight classes, bio details, and club associations.
  Future<Map<String, dynamic>> createAthleteProfile(Map<String, dynamic> body) async {
    return _request(
      'POST',
      '/api/v1/athletes',
      body: body,
      ,
    );
  }

  /// Retrieve logged-in athlete details
  /// Gets the full authenticated user details and active athlete profile context.
  Future<Map<String, dynamic>> retrieveLoggedinAthleteDetails() async {
    return _request(
      'GET',
      '/api/v1/athletes/me',
      ,
      ,
    );
  }

  /// Search athletes directory
  /// Filter athletes by name, weight range, club, and verification status.
  Future<Map<String, dynamic>> searchAthletesDirectory(Map<String, dynamic>? queryParams) async {
    return _request(
      'GET',
      '/api/v1/athletes/search',
      ,
      queryParams: queryParams,
    );
  }

  /// Get registered armwrestling clubs
  /// Retrieves a listing of official clubs for team associations.
  Future<Map<String, dynamic>> getRegisteredArmwrestlingClubs() async {
    return _request(
      'GET',
      '/api/v1/athletes/clubs',
      ,
      ,
    );
  }

  /// Register a new official Club
  /// Creates a new club node. Requires Director-level credentials.
  Future<Map<String, dynamic>> registerANewOfficialClub(Map<String, dynamic> body) async {
    return _request(
      'POST',
      '/api/v1/athletes/clubs',
      body: body,
      ,
    );
  }

  /// Update biometrics records
  /// Submits current certified biometric statistics (height, wingspan, bicep size, forearm size).
  Future<Map<String, dynamic>> updateBiometricsRecords(Map<String, dynamic> body) async {
    return _request(
      'POST',
      '/api/v1/athletes/biometrics',
      body: body,
      ,
    );
  }

  /// Submit ID document for profile verification
  /// Submits government photo ID or provincial membership card for referee validation.
  Future<Map<String, dynamic>> submitIdDocumentForProfileVerification(Map<String, dynamic> body) async {
    return _request(
      'POST',
      '/api/v1/athletes/verification/document',
      body: body,
      ,
    );
  }

  /// Review profile verification document
  /// Approves or rejects a submitted profile document. Requires Admin or Director privileges.
  Future<Map<String, dynamic>> reviewProfileVerificationDocument(Map<String, dynamic> body) async {
    return _request(
      'POST',
      '/api/v1/athletes/verification/review',
      body: body,
      ,
    );
  }

  /// Submit a new match result
  /// Records an official match result between two athletes (pullers), specifying winner, match type, round details, and referee signatures.
  Future<Map<String, dynamic>> submitANewMatchResult(Map<String, dynamic> body) async {
    return _request(
      'POST',
      '/api/v1/matches',
      body: body,
      ,
    );
  }

  /// Get match details
  /// Gets detailed records of a match, including rounds and ELO updates.
  Future<Map<String, dynamic>> getMatchDetails(String id) async {
    return _request(
      'GET',
      '/api/v1/matches/$id',
      ,
      ,
    );
  }

  /// Verify match outcome
  /// Approved by referee or tournament directors to verify accuracy and cement ELO updates. Requires Referee/Director/Admin.
  Future<Map<String, dynamic>> verifyMatchOutcome(String id, Map<String, dynamic> body) async {
    return _request(
      'POST',
      '/api/v1/matches/$id/verify',
      body: body,
      ,
    );
  }

  /// Raise a dispute on match results
  /// Allows an athlete or club manager to contest a match outcome within the dispute window.
  Future<Map<String, dynamic>> raiseADisputeOnMatchResults(String id, Map<String, dynamic> body) async {
    return _request(
      'POST',
      '/api/v1/matches/$id/dispute',
      body: body,
      ,
    );
  }

  /// Void a match
  /// SRE and Director tool to void a match, rolling back ratings securely without breaking history sequences. Requires Director/Admin.
  Future<Map<String, dynamic>> voidAMatch(String id, Map<String, dynamic> body) async {
    return _request(
      'POST',
      '/api/v1/matches/$id/void',
      body: body,
      ,
    );
  }

  /// Get global ELO rankings leaderboard
  /// Retrieves top rated pullers filtered by weight class, division, gender, region, or club.
  Future<Map<String, dynamic>> getGlobalEloRankingsLeaderboard(Map<String, dynamic>? queryParams) async {
    return _request(
      'GET',
      '/api/v1/rankings/leaderboard',
      ,
      queryParams: queryParams,
    );
  }

  /// Trigger dynamic ELO snapshots
  /// Triggers a full system-wide snapshot of current ratings. Requires National Director or System Admin privileges.
  Future<Map<String, dynamic>> triggerDynamicEloSnapshots(Map<String, dynamic> body) async {
    return _request(
      'POST',
      '/api/v1/rankings/snapshots',
      body: body,
      ,
    );
  }

  /// Create tournament event
  /// Registers a new tournament event. Requires Director/Admin.
  Future<Map<String, dynamic>> createTournamentEvent(Map<String, dynamic> body) async {
    return _request(
      'POST',
      '/api/v1/tournaments/events',
      body: body,
      ,
    );
  }

  /// Register athlete for a tournament event
  /// Registers an athlete for a tournament event division.
  Future<Map<String, dynamic>> registerAthleteForATournamentEvent(Map<String, dynamic> body) async {
    return _request(
      'POST',
      '/api/v1/tournaments/registrations',
      body: body,
      ,
    );
  }

  /// Record athlete certified weigh-in
  /// Saves verified weight measurements during check-in window. Requires Referee/Director/Admin.
  Future<Map<String, dynamic>> recordAthleteCertifiedWeighin(Map<String, dynamic> body) async {
    return _request(
      'POST',
      '/api/v1/tournaments/weighins',
      body: body,
      ,
    );
  }

  /// Create double-elimination bracket structure
  /// Sets up brackets for an active division.
  Future<Map<String, dynamic>> createDoubleeliminationBracketStructure(Map<String, dynamic> body) async {
    return _request(
      'POST',
      '/api/v1/tournaments/brackets',
      body: body,
      ,
    );
  }

  /// Submit bracket match round result
  /// Submits referee-signed live match results. Requires Referee/Director/Admin.
  Future<Map<String, dynamic>> submitBracketMatchRoundResult(Map<String, dynamic> body) async {
    return _request(
      'POST',
      '/api/v1/tournaments/matches/result',
      body: body,
      ,
    );
  }

  /// Differential (pull) sync — fetch changes since a cursor
  /// Returns the authenticated athlete's own profile and match history changed since the `since` cursor, plus tombstones for any hard-deleted records they own. Omit `since` for a first full sync. The response's `serverTime` is the cursor to pass as `since` on the next call.
  Future<Map<String, dynamic>> differentialPullSyncFetchChangesSinceACursor(Map<String, dynamic>? queryParams) async {
    return _request(
      'GET',
      '/sync',
      ,
      queryParams: queryParams,
    );
  }

  /// Queue action for background synchronization
  /// Registers local client database mutations to be processed asynchronously by the PostgreSQL database on the server when connection is re-established.
  Future<Map<String, dynamic>> queueActionForBackgroundSynchronization(Map<String, dynamic> body) async {
    return _request(
      'POST',
      '/api/v1/sync/queue',
      body: body,
      ,
    );
  }

  /// Get actions synchronization history
  /// Gets historic synchronization logs to let clients align local status states.
  Future<Map<String, dynamic>> getActionsSynchronizationHistory() async {
    return _request(
      'GET',
      '/api/v1/sync/history',
      ,
      ,
    );
  }

  /// Get server sync queue metrics
  /// Returns general background queue metrics (pending counts, processed counts, fail ratios).
  Future<Map<String, dynamic>> getServerSyncQueueMetrics() async {
    return _request(
      'GET',
      '/api/v1/sync/metrics',
      ,
      ,
    );
  }

  /// Modify user system-wide roles
  /// Allows a System Administrator or National Director to elevate or demote roles. Requires Admin/Director.
  Future<Map<String, dynamic>> modifyUserSystemwideRoles(Map<String, dynamic> body) async {
    return _request(
      'POST',
      '/admin/users/roles',
      body: body,
      ,
    );
  }

  /// Rotate system JWT signing secrets
  /// Triggers active JWT keys rotation and invalidation chains. Requires System Admin.
  Future<Map<String, dynamic>> rotateSystemJwtSigningSecrets(Map<String, dynamic> body) async {
    return _request(
      'POST',
      '/admin/secrets/rotate-jwt',
      body: body,
      ,
    );
  }

  /// Verify client-side CAPTCHA tokens
  /// Authenticates Cloudflare Turnstile or Google reCAPTCHA v3 tokens from the client browser.
  Future<Map<String, dynamic>> verifyClientsideCaptchaTokens(Map<String, dynamic> body) async {
    return _request(
      'POST',
      '/api/v1/security/captcha/verify',
      body: body,
      ,
    );
  }

  /// Platform general health status check
  /// Checks if server is accepting requests.
  Future<Map<String, dynamic>> platformGeneralHealthStatusCheck() async {
    return _request(
      'GET',
      '/api/health',
      ,
      ,
    );
  }

  /// Database connectivity readiness probe
  /// Checks deep connection dependencies for database and caching servers.
  Future<Map<String, dynamic>> databaseConnectivityReadinessProbe() async {
    return _request(
      'GET',
      '/api/ready',
      ,
      ,
    );
  }

  /// Create community post
  /// Submit a new community feed post linked with previously uploaded media key.
  Future<Map<String, dynamic>> createCommunityPost(Map<String, dynamic> body) async {
    return _request(
      'POST',
      '/community/posts',
      body: body,
      ,
    );
  }

}
