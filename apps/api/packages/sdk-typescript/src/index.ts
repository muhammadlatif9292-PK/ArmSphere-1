/**
 * ArmSphere Professional Client SDK
 * AUTOMATICALLY GENERATED FROM OPENAPI DEFINITION. DO NOT EDIT DIRECTLY.
 */

export interface SdkConfig {
  baseUrl?: string;
  token?: string;
  csrfToken?: string;
}

export class ArmSphereClient {
  private baseUrl: string;
  private token?: string;
  private csrfToken?: string;

  constructor(config: SdkConfig = {}) {
    this.baseUrl = config.baseUrl || "http://localhost:3000";
    this.token = config.token;
    this.csrfToken = config.csrfToken;
  }

  setToken(token: string) {
    this.token = token;
  }

  setCsrfToken(token: string) {
    this.csrfToken = token;
  }

  private async request<T>(method: string, path: string, body?: any, params?: any): Promise<T> {
    const url = new URL(path, this.baseUrl);
    if (params) {
      Object.keys(params).forEach(key => {
        if (params[key] !== undefined) {
          url.searchParams.append(key, String(params[key]));
        }
      });
    }

    const headers: Record<string, string> = {
      "Content-Type": "application/json",
    };

    if (this.token) {
      headers["Authorization"] = `Bearer ${this.token}`;
    }

    if (this.csrfToken) {
      headers["x-csrf-token"] = this.csrfToken;
    }

    const response = await fetch(url.toString(), {
      method,
      headers,
      body: body ? JSON.stringify(body) : undefined,
    });

    if (!response.ok) {
      let errorData;
      try {
        errorData = await response.json();
      } catch {
        errorData = { title: "HTTP Error", detail: response.statusText, status: response.status };
      }
      throw errorData;
    }

    return response.json() as Promise<T>;
  }

  /**
   * Register a new user account
   * Creates a new user profile with selected roles.
   */
  async registerANewUserAccount(body: any): Promise<any> {
    return this.request<any>(
      "POST",
      `/api/v1/auth/register`,
      body,
      undefined
    );
  }

  /**
   * Authenticate a user
   * Validates credentials, checks for impossible travel/device changes, and prompts MFA if enabled.
   */
  async authenticateAUser(body: any): Promise<any> {
    return this.request<any>(
      "POST",
      `/api/v1/auth/login`,
      body,
      undefined
    );
  }

  /**
   * Initiate MFA Setup
   * Generates a dynamic TOTP secret, a setup QR code, and backup recovery codes.
   */
  async initiateMfaSetup(): Promise<any> {
    return this.request<any>(
      "POST",
      `/api/v1/auth/mfa/setup`,
      undefined,
      undefined
    );
  }

  /**
   * Verify and enable MFA or solve login challenge
   * Validates a TOTP token code to activate MFA, or complete login flow when unauthenticated.
   */
  async verifyAndEnableMfaOrSolveLoginChallenge(body: any): Promise<any> {
    return this.request<any>(
      "POST",
      `/api/v1/auth/mfa/verify`,
      body,
      undefined
    );
  }

  /**
   * Recover account access via backup recovery code
   * Allows a locked out user with active MFA to log in using one of their unused backup recovery codes.
   */
  async recoverAccountAccessViaBackupRecoveryCode(body: any): Promise<any> {
    return this.request<any>(
      "POST",
      `/api/v1/auth/mfa/recovery`,
      body,
      undefined
    );
  }

  /**
   * Google OAuth login initiator
   * Redirects the client to Google OAuth Consent Page.
   */
  async googleOauthLoginInitiator(queryParams?: any): Promise<any> {
    return this.request<any>(
      "GET",
      `/api/v1/auth/google`,
      undefined,
      queryParams
    );
  }

  /**
   * Apple OAuth login initiator
   * Redirects the client to Apple Sign-In screen.
   */
  async appleOauthLoginInitiator(queryParams?: any): Promise<any> {
    return this.request<any>(
      "GET",
      `/api/v1/auth/apple`,
      undefined,
      queryParams
    );
  }

  /**
   * Create athlete profile
   * Creates an athlete profile linking weight classes, bio details, and club associations.
   */
  async createAthleteProfile(body: any): Promise<any> {
    return this.request<any>(
      "POST",
      `/api/v1/athletes`,
      body,
      undefined
    );
  }

  /**
   * Retrieve logged-in athlete details
   * Gets the full authenticated user details and active athlete profile context.
   */
  async retrieveLoggedinAthleteDetails(): Promise<any> {
    return this.request<any>(
      "GET",
      `/api/v1/athletes/me`,
      undefined,
      undefined
    );
  }

  /**
   * Search athletes directory
   * Filter athletes by name, weight range, club, and verification status.
   */
  async searchAthletesDirectory(queryParams?: any): Promise<any> {
    return this.request<any>(
      "GET",
      `/api/v1/athletes/search`,
      undefined,
      queryParams
    );
  }

  /**
   * Get registered armwrestling clubs
   * Retrieves a listing of official clubs for team associations.
   */
  async getRegisteredArmwrestlingClubs(): Promise<any> {
    return this.request<any>(
      "GET",
      `/api/v1/athletes/clubs`,
      undefined,
      undefined
    );
  }

  /**
   * Register a new official Club
   * Creates a new club node. Requires Director-level credentials.
   */
  async registerANewOfficialClub(body: any): Promise<any> {
    return this.request<any>(
      "POST",
      `/api/v1/athletes/clubs`,
      body,
      undefined
    );
  }

  /**
   * Update biometrics records
   * Submits current certified biometric statistics (height, wingspan, bicep size, forearm size).
   */
  async updateBiometricsRecords(body: any): Promise<any> {
    return this.request<any>(
      "POST",
      `/api/v1/athletes/biometrics`,
      body,
      undefined
    );
  }

  /**
   * Submit ID document for profile verification
   * Submits government photo ID or provincial membership card for referee validation.
   */
  async submitIdDocumentForProfileVerification(body: any): Promise<any> {
    return this.request<any>(
      "POST",
      `/api/v1/athletes/verification/document`,
      body,
      undefined
    );
  }

  /**
   * Review profile verification document
   * Approves or rejects a submitted profile document. Requires Admin or Director privileges.
   */
  async reviewProfileVerificationDocument(body: any): Promise<any> {
    return this.request<any>(
      "POST",
      `/api/v1/athletes/verification/review`,
      body,
      undefined
    );
  }

  /**
   * Submit a new match result
   * Records an official match result between two athletes (pullers), specifying winner, match type, round details, and referee signatures.
   */
  async submitANewMatchResult(body: any): Promise<any> {
    return this.request<any>(
      "POST",
      `/api/v1/matches`,
      body,
      undefined
    );
  }

  /**
   * Get match details
   * Gets detailed records of a match, including rounds and ELO updates.
   */
  async getMatchDetails(id: string): Promise<any> {
    return this.request<any>(
      "GET",
      `/api/v1/matches/${id}`,
      undefined,
      undefined
    );
  }

  /**
   * Verify match outcome
   * Approved by referee or tournament directors to verify accuracy and cement ELO updates. Requires Referee/Director/Admin.
   */
  async verifyMatchOutcome(id: string, body: any): Promise<any> {
    return this.request<any>(
      "POST",
      `/api/v1/matches/${id}/verify`,
      body,
      undefined
    );
  }

  /**
   * Raise a dispute on match results
   * Allows an athlete or club manager to contest a match outcome within the dispute window.
   */
  async raiseADisputeOnMatchResults(id: string, body: any): Promise<any> {
    return this.request<any>(
      "POST",
      `/api/v1/matches/${id}/dispute`,
      body,
      undefined
    );
  }

  /**
   * Void a match
   * SRE and Director tool to void a match, rolling back ratings securely without breaking history sequences. Requires Director/Admin.
   */
  async voidAMatch(id: string, body: any): Promise<any> {
    return this.request<any>(
      "POST",
      `/api/v1/matches/${id}/void`,
      body,
      undefined
    );
  }

  /**
   * Get global ELO rankings leaderboard
   * Retrieves top rated pullers filtered by weight class, division, gender, region, or club.
   */
  async getGlobalEloRankingsLeaderboard(queryParams?: any): Promise<any> {
    return this.request<any>(
      "GET",
      `/api/v1/rankings/leaderboard`,
      undefined,
      queryParams
    );
  }

  /**
   * Trigger dynamic ELO snapshots
   * Triggers a full system-wide snapshot of current ratings. Requires National Director or System Admin privileges.
   */
  async triggerDynamicEloSnapshots(body: any): Promise<any> {
    return this.request<any>(
      "POST",
      `/api/v1/rankings/snapshots`,
      body,
      undefined
    );
  }

  /**
   * Create tournament event
   * Registers a new tournament event. Requires Director/Admin.
   */
  async createTournamentEvent(body: any): Promise<any> {
    return this.request<any>(
      "POST",
      `/api/v1/tournaments/events`,
      body,
      undefined
    );
  }

  /**
   * Register athlete for a tournament event
   * Registers an athlete for a tournament event division.
   */
  async registerAthleteForATournamentEvent(body: any): Promise<any> {
    return this.request<any>(
      "POST",
      `/api/v1/tournaments/registrations`,
      body,
      undefined
    );
  }

  /**
   * Record athlete certified weigh-in
   * Saves verified weight measurements during check-in window. Requires Referee/Director/Admin.
   */
  async recordAthleteCertifiedWeighin(body: any): Promise<any> {
    return this.request<any>(
      "POST",
      `/api/v1/tournaments/weighins`,
      body,
      undefined
    );
  }

  /**
   * Create double-elimination bracket structure
   * Sets up brackets for an active division.
   */
  async createDoubleeliminationBracketStructure(body: any): Promise<any> {
    return this.request<any>(
      "POST",
      `/api/v1/tournaments/brackets`,
      body,
      undefined
    );
  }

  /**
   * Submit bracket match round result
   * Submits referee-signed live match results. Requires Referee/Director/Admin.
   */
  async submitBracketMatchRoundResult(body: any): Promise<any> {
    return this.request<any>(
      "POST",
      `/api/v1/tournaments/matches/result`,
      body,
      undefined
    );
  }

  /**
   * Differential (pull) sync — fetch changes since a cursor
   * Returns the authenticated athlete's own profile and match history changed since the `since` cursor, plus tombstones for any hard-deleted records they own. Omit `since` for a first full sync. The response's `serverTime` is the cursor to pass as `since` on the next call.
   */
  async differentialPullSyncFetchChangesSinceACursor(queryParams?: any): Promise<any> {
    return this.request<any>(
      "GET",
      `/sync`,
      undefined,
      queryParams
    );
  }

  /**
   * Queue action for background synchronization
   * Registers local client database mutations to be processed asynchronously by the PostgreSQL database on the server when connection is re-established.
   */
  async queueActionForBackgroundSynchronization(body: any): Promise<any> {
    return this.request<any>(
      "POST",
      `/api/v1/sync/queue`,
      body,
      undefined
    );
  }

  /**
   * Get actions synchronization history
   * Gets historic synchronization logs to let clients align local status states.
   */
  async getActionsSynchronizationHistory(): Promise<any> {
    return this.request<any>(
      "GET",
      `/api/v1/sync/history`,
      undefined,
      undefined
    );
  }

  /**
   * Get server sync queue metrics
   * Returns general background queue metrics (pending counts, processed counts, fail ratios).
   */
  async getServerSyncQueueMetrics(): Promise<any> {
    return this.request<any>(
      "GET",
      `/api/v1/sync/metrics`,
      undefined,
      undefined
    );
  }

  /**
   * Modify user system-wide roles
   * Allows a System Administrator or National Director to elevate or demote roles. Requires Admin/Director.
   */
  async modifyUserSystemwideRoles(body: any): Promise<any> {
    return this.request<any>(
      "POST",
      `/admin/users/roles`,
      body,
      undefined
    );
  }

  /**
   * Rotate system JWT signing secrets
   * Triggers active JWT keys rotation and invalidation chains. Requires System Admin.
   */
  async rotateSystemJwtSigningSecrets(body: any): Promise<any> {
    return this.request<any>(
      "POST",
      `/admin/secrets/rotate-jwt`,
      body,
      undefined
    );
  }

  /**
   * Verify client-side CAPTCHA tokens
   * Authenticates Cloudflare Turnstile or Google reCAPTCHA v3 tokens from the client browser.
   */
  async verifyClientsideCaptchaTokens(body: any): Promise<any> {
    return this.request<any>(
      "POST",
      `/api/v1/security/captcha/verify`,
      body,
      undefined
    );
  }

  /**
   * Platform general health status check
   * Checks if server is accepting requests.
   */
  async platformGeneralHealthStatusCheck(): Promise<any> {
    return this.request<any>(
      "GET",
      `/api/health`,
      undefined,
      undefined
    );
  }

  /**
   * Database connectivity readiness probe
   * Checks deep connection dependencies for database and caching servers.
   */
  async databaseConnectivityReadinessProbe(): Promise<any> {
    return this.request<any>(
      "GET",
      `/api/ready`,
      undefined,
      undefined
    );
  }

  /**
   * Create community post
   * Submit a new community feed post linked with previously uploaded media key.
   */
  async createCommunityPost(body: any): Promise<any> {
    return this.request<any>(
      "POST",
      `/community/posts`,
      body,
      undefined
    );
  }

}
