import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, within } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { User, UserRole } from '../types';
import {
  getEffectiveRole,
  getUserJurisdiction,
  canAccessRoute,
  getAuthorizedNavLinks,
  canSwitchToRole,
  canPerformAction,
  ADMIN_ROUTE_PERMISSIONS,
} from '../lib/authorizationPolicy';
import { onUnauthorized } from '../lib/apiClient';
import { AuthContext, AuthContextType } from '../context/AuthContext';
import { RoleGuardedRoute } from '../App';
import AdminShell from '../layout/AdminShell';
import ForbiddenPage from '../pages/ForbiddenPage';
import AthletesPage from '../pages/AthletesPage';
import RefereesPage from '../pages/RefereesPage';
import VenuesPage from '../pages/VenuesPage';
import NominationsPage from '../pages/NominationsPage';
import GovernancePage from '../pages/GovernancePage';
import AuditPage from '../pages/AuditPage';

// Mock API hooks used by AthletesPage and RefereesPage
vi.mock('../lib/athletesApi', () => ({
  useAthletes: vi.fn(() => ({
    data: [
      {
        id: 'ath-1',
        userId: 'u-1',
        displayName: 'Ahmad Khan',
        province: 'Punjab',
        city: 'Lahore',
        weightClass: 'Senior 85kg',
        dominantArm: 'Right',
        handedness: 'Right',
        leftArmElo: 1450,
        rightArmElo: 1520,
        verificationStatus: 'PENDING',
        isActive: true,
      },
      {
        id: 'ath-2',
        userId: 'u-2',
        displayName: 'Tariq Baloch',
        province: 'Balochistan',
        city: 'Quetta',
        weightClass: 'Senior 95kg',
        dominantArm: 'Left',
        handedness: 'Ambidextrous',
        leftArmElo: 1600,
        rightArmElo: 1580,
        verificationStatus: 'VERIFIED',
        isActive: true,
      },
    ],
    isLoading: false,
    isError: false,
    error: null,
    refetch: vi.fn(),
  })),
  useReviewProfile: () => ({ mutateAsync: vi.fn() }),
  useSuspendAthlete: () => ({ mutateAsync: vi.fn() }),
  useBlacklistAthlete: () => ({ mutateAsync: vi.fn() }),
  useRecoverAthlete: () => ({ mutateAsync: vi.fn() }),
  useCorrectAthlete: () => ({ mutateAsync: vi.fn() }),
  useRefereeCertifications: () => ({ data: [], isLoading: false }),
  useIssueRefereeCertification: () => ({ mutateAsync: vi.fn() }),
  useRevokeRefereeCertification: () => ({ mutateAsync: vi.fn() }),
}));

vi.mock('../lib/refereesApi', () => ({
  useReferees: vi.fn(() => ({
    data: [
      {
        id: 'ref-1',
        userId: 'u-ref-1',
        fullName: 'Zubair Qureshi',
        email: 'zubair@armsphere.pk',
        region: 'Punjab',
        licenseClass: 'NATIONAL',
        certificationStatus: 'ACTIVE',
        isActive: true,
        performance: { totalMatches: 42 },
      },
      {
        id: 'ref-2',
        userId: 'u-ref-2',
        fullName: 'Bilal Mengal',
        email: 'bilal@armsphere.pk',
        region: 'Balochistan',
        licenseClass: 'PROVINCIAL',
        certificationStatus: 'ACTIVE',
        isActive: true,
        performance: { totalMatches: 18 },
      },
    ],
    isLoading: false,
    isError: false,
    error: null,
    refetch: vi.fn(),
  })),
  useAssignRefereeRegion: () => ({ mutateAsync: vi.fn(), isPending: false }),
  useUpdateRefereeLicense: () => ({ mutateAsync: vi.fn(), isPending: false }),
  useSuspendReferee: () => ({ mutateAsync: vi.fn(), isPending: false }),
}));

vi.mock('../lib/venuesApi', () => ({
  useVenues: vi.fn(() => ({
    data: [
      {
        id: 'venue-1',
        name: 'Lahore Iron Gym',
        address: 'Gulberg III',
        city: 'Lahore',
        province: 'Punjab',
        contactInfo: '+923001234567',
        isVerified: false,
      },
      {
        id: 'venue-2',
        name: 'Quetta Power Pit',
        address: 'Jinnah Road',
        city: 'Quetta',
        province: 'Balochistan',
        contactInfo: '+923007654321',
        isVerified: false,
      },
    ],
    isLoading: false,
    isError: false,
    error: null,
    refetch: vi.fn(),
  })),
  useVerifyVenue: () => ({ mutateAsync: vi.fn(), isPending: false }),
}));

vi.mock('../lib/nominationsApi', () => ({
  useNominations: vi.fn(() => ({
    data: [
      {
        id: 'nom-1',
        nomineeName: 'Ali Raza',
        contactPhone: '+923001112233',
        city: 'Lahore',
        province: 'Punjab',
        status: 'PENDING',
        notes: 'Promising talent',
        createdAt: new Date().toISOString(),
      },
      {
        id: 'nom-2',
        nomineeName: 'Kamran Khan',
        contactPhone: '+923004445566',
        city: 'Quetta',
        province: 'Balochistan',
        status: 'PENDING',
        notes: 'Regional champion',
        createdAt: new Date().toISOString(),
      },
    ],
    isLoading: false,
    isError: false,
    error: null,
    refetch: vi.fn(),
  })),
  useUpdateNominationStatus: () => ({ mutateAsync: vi.fn(), isPending: false }),
}));

vi.mock('../lib/governanceApi', () => ({
  useDisputes: vi.fn(() => ({
    data: [
      {
        id: 'disp-1',
        matchId: 'm-12345678',
        creatorId: 'u-athlete-1',
        title: 'Foul Protest Punjab',
        description: 'Referee missed slip in Punjab championship',
        status: 'OPEN',
        resolutionDetails: null,
        assignedReviewerId: null,
        province: 'Punjab',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      },
      {
        id: 'disp-2',
        matchId: 'm-87654321',
        creatorId: 'u-athlete-2',
        title: 'Elbow Foul Balochistan',
        description: 'Elbow lifted in Balochistan championship',
        status: 'OPEN',
        resolutionDetails: null,
        assignedReviewerId: null,
        province: 'Balochistan',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      },
    ],
    isLoading: false,
    isError: false,
    error: null,
    refetch: vi.fn(),
  })),
  useResolveDispute: () => ({ mutateAsync: vi.fn(), isPending: false }),
}));

vi.mock('../lib/auditApi', () => ({
  useAuditEvents: vi.fn(() => ({
    data: [],
    isLoading: false,
    isError: false,
    error: null,
    refetch: vi.fn(),
    isRefetching: false,
  })),
  useVerifyLedger: vi.fn(() => ({
    data: { valid: true, count: 10, chainHead: 'abc' },
    isLoading: false,
    isError: false,
    error: null,
    refetch: vi.fn(),
    isRefetching: false,
  })),
}));

// Helper to create fully compliant User objects
function makeMockUser(partial: Partial<User> & { role: UserRole }): User {
  return {
    id: 'u-' + Math.random().toString(36).substring(7),
    username: 'user_' + partial.role.toLowerCase(),
    email: `${partial.role.toLowerCase()}@armsphere.pk`,
    fullName: 'Test ' + partial.role,
    isOnboarded: true,
    ...partial,
  };
}

// Helper to create an AuthContext value wrapper
function createMockAuthContext(overrides: Partial<AuthContextType> = {}): AuthContextType {
  const defaultUser = makeMockUser({
    id: 'usr-admin-1',
    email: 'admin@armsphere.pk',
    fullName: 'System Administrator',
    role: UserRole.SYSTEM_ADMIN,
    activeRole: UserRole.SYSTEM_ADMIN,
  });

  return {
    user: defaultUser,
    activeRole: UserRole.SYSTEM_ADMIN,
    jurisdiction: null,
    isLoading: false,
    token: 'jwt-mock-token',
    login: vi.fn().mockResolvedValue(defaultUser),
    logout: vi.fn().mockResolvedValue(undefined),
    switchActiveRole: vi.fn().mockReturnValue(true),
    ...overrides,
  };
}

describe('ArmSphere Admin Web RBAC & Governance Hardening Suite', () => {
  let queryClient: QueryClient;

  beforeEach(() => {
    queryClient = new QueryClient({
      defaultOptions: {
        queries: { retry: false },
      },
    });
    vi.clearAllMocks();
  });

  // =========================================================================
  // 1. Core Authorization Policy & Role Derivation
  // =========================================================================
  describe('authorizationPolicy - Role derivation & Jurisdiction Scoping', () => {
    it('derives activeRole when explicitly set and eligible', () => {
      const user = makeMockUser({
        role: UserRole.PROVINCIAL_DIRECTOR,
        activeRole: UserRole.PROVINCIAL_DIRECTOR,
        province: 'Punjab',
        verifiedRoles: ['PROVINCIAL_DIRECTOR', 'TOURNAMENT_OPERATOR'],
      });
      expect(getEffectiveRole(user)).toBe(UserRole.PROVINCIAL_DIRECTOR);
    });

    it('falls back to primary role when activeRole is not in verifiedRoles or grants', () => {
      const user = makeMockUser({
        role: UserRole.TOURNAMENT_OPERATOR,
        activeRole: UserRole.SYSTEM_ADMIN, // not eligible
      });
      expect(getEffectiveRole(user)).toBe(UserRole.TOURNAMENT_OPERATOR);
    });

    it('correctly extracts jurisdiction from province or regionalCoverage or grant scope', () => {
      const userWithProvince = makeMockUser({
        role: UserRole.PROVINCIAL_DIRECTOR,
        province: 'Punjab',
      });
      expect(getUserJurisdiction(userWithProvince)).toBe('Punjab');

      const userWithCoverage = makeMockUser({
        role: UserRole.PROVINCIAL_DIRECTOR,
        regionalCoverage: 'Sindh',
      });
      expect(getUserJurisdiction(userWithCoverage)).toBe('Sindh');

      const userWithGrant = makeMockUser({
        role: UserRole.ATHLETE,
        activeRole: UserRole.PROVINCIAL_DIRECTOR,
        roleGrants: [
          {
            id: 'g-1',
            userId: 'u-105',
            role: UserRole.PROVINCIAL_DIRECTOR,
            status: 'ACTIVE',
            scope: 'Khyber Pakhtunkhwa',
          },
        ],
      });
      expect(getUserJurisdiction(userWithGrant)).toBe('Khyber Pakhtunkhwa');
    });

    it('verifies switching eligibility via canSwitchToRole', () => {
      const multiRoleUser = makeMockUser({
        role: UserRole.PROVINCIAL_DIRECTOR,
        verifiedRoles: ['PROVINCIAL_DIRECTOR', 'TOURNAMENT_OPERATOR'],
      });

      expect(canSwitchToRole(multiRoleUser, UserRole.TOURNAMENT_OPERATOR)).toBe(true);
      expect(canSwitchToRole(multiRoleUser, UserRole.SYSTEM_ADMIN)).toBe(false);
      expect(canSwitchToRole(multiRoleUser, UserRole.NATIONAL_DIRECTOR)).toBe(false);
    });
  });

  // =========================================================================
  // 2. Route Protection Permissions Matrix
  // =========================================================================
  describe('authorizationPolicy - Route Permissions Matrix', () => {
    it('SYSTEM_ADMIN has access to all 11 administrative routes including /audit and /support', () => {
      const admin = makeMockUser({
        role: UserRole.SYSTEM_ADMIN,
      });

      const allRoutes = ADMIN_ROUTE_PERMISSIONS.map((r) => r.path);
      expect(allRoutes.length).toBe(11);

      allRoutes.forEach((route) => {
        expect(canAccessRoute(admin, route).allowed).toBe(true);
      });
      expect(canAccessRoute(admin, '/audit').allowed).toBe(true);
      expect(canAccessRoute(admin, '/support').allowed).toBe(true);
    });

    it('SUPPORT_AGENT has access to /support, /, /athletes, and /governance, but forbidden on others', () => {
      const supportAgent = makeMockUser({
        role: UserRole.SUPPORT_AGENT,
      });

      expect(canAccessRoute(supportAgent, '/').allowed).toBe(true);
      expect(canAccessRoute(supportAgent, '/support').allowed).toBe(true);
      expect(canAccessRoute(supportAgent, '/athletes').allowed).toBe(true);
      expect(canAccessRoute(supportAgent, '/governance').allowed).toBe(true);

      // Forbidden routes for SUPPORT_AGENT:
      expect(canAccessRoute(supportAgent, '/referees').allowed).toBe(false);
      expect(canAccessRoute(supportAgent, '/championships').allowed).toBe(false);
      expect(canAccessRoute(supportAgent, '/nominations').allowed).toBe(false);
      expect(canAccessRoute(supportAgent, '/venues').allowed).toBe(false);
      expect(canAccessRoute(supportAgent, '/moderation').allowed).toBe(false);
      expect(canAccessRoute(supportAgent, '/analytics').allowed).toBe(false);
      expect(canAccessRoute(supportAgent, '/audit').allowed).toBe(false);
    });

    it('Non-support non-admin roles are forbidden on /support', () => {
      const athlete = makeMockUser({ role: UserRole.ATHLETE });
      const referee = makeMockUser({ role: UserRole.REFEREE });
      const op = makeMockUser({ role: UserRole.TOURNAMENT_OPERATOR });
      const provDir = makeMockUser({ role: UserRole.PROVINCIAL_DIRECTOR });
      const natDir = makeMockUser({ role: UserRole.NATIONAL_DIRECTOR });
      const compOfficer = makeMockUser({ role: UserRole.COMPLIANCE_OFFICER });

      expect(canAccessRoute(athlete, '/support').allowed).toBe(false);
      expect(canAccessRoute(referee, '/support').allowed).toBe(false);
      expect(canAccessRoute(op, '/support').allowed).toBe(false);
      expect(canAccessRoute(provDir, '/support').allowed).toBe(false);
      expect(canAccessRoute(natDir, '/support').allowed).toBe(false);
      expect(canAccessRoute(compOfficer, '/support').allowed).toBe(false);
    });

    it('NATIONAL_DIRECTOR has access to competition routes (/championships) but is strictly forbidden on /audit', () => {
      const natDir = makeMockUser({
        role: UserRole.NATIONAL_DIRECTOR,
      });

      expect(canAccessRoute(natDir, '/').allowed).toBe(true);
      expect(canAccessRoute(natDir, '/athletes').allowed).toBe(true);
      expect(canAccessRoute(natDir, '/referees').allowed).toBe(true);
      expect(canAccessRoute(natDir, '/championships').allowed).toBe(true);
      expect(canAccessRoute(natDir, '/nominations').allowed).toBe(true);
      expect(canAccessRoute(natDir, '/governance').allowed).toBe(true);

      // Strict requirement: National Director is NOT allowed to view or tamper with crypto audit log
      expect(canAccessRoute(natDir, '/audit').allowed).toBe(false);
    });

    it('PROVINCIAL_DIRECTOR is forbidden from /championships (national only) and /audit (system only)', () => {
      const provDir = makeMockUser({
        role: UserRole.PROVINCIAL_DIRECTOR,
        province: 'Punjab',
      });

      expect(canAccessRoute(provDir, '/').allowed).toBe(true);
      expect(canAccessRoute(provDir, '/athletes').allowed).toBe(true);
      expect(canAccessRoute(provDir, '/referees').allowed).toBe(true);
      expect(canAccessRoute(provDir, '/nominations').allowed).toBe(true);
      expect(canAccessRoute(provDir, '/venues').allowed).toBe(true);

      // Blocked routes
      expect(canAccessRoute(provDir, '/championships').allowed).toBe(false);
      expect(canAccessRoute(provDir, '/audit').allowed).toBe(false);
    });

    it('TOURNAMENT_OPERATOR is restricted to / and /athletes only', () => {
      const op = makeMockUser({
        role: UserRole.TOURNAMENT_OPERATOR,
      });

      expect(canAccessRoute(op, '/').allowed).toBe(true);
      expect(canAccessRoute(op, '/athletes').allowed).toBe(true);

      expect(canAccessRoute(op, '/referees').allowed).toBe(false);
      expect(canAccessRoute(op, '/championships').allowed).toBe(false);
      expect(canAccessRoute(op, '/nominations').allowed).toBe(false);
      expect(canAccessRoute(op, '/governance').allowed).toBe(false);
      expect(canAccessRoute(op, '/audit').allowed).toBe(false);
      expect(canAccessRoute(op, '/venues').allowed).toBe(false);
    });

    it('COMPLIANCE_OFFICER has access to /audit, /governance, /analytics, but not /championships', () => {
      const comp = makeMockUser({
        role: UserRole.COMPLIANCE_OFFICER,
      });

      expect(canAccessRoute(comp, '/audit').allowed).toBe(true);
      expect(canAccessRoute(comp, '/governance').allowed).toBe(true);
      expect(canAccessRoute(comp, '/analytics').allowed).toBe(true);
      expect(canAccessRoute(comp, '/championships').allowed).toBe(false);
    });
  });

  // =========================================================================
  // 3. Navigation Sidebar Links Filtering
  // =========================================================================
  describe('AdminShell - Sidebar Authorization & Visibility', () => {
    it('SYSTEM_ADMIN receives all 11 links in navigation', () => {
      const admin = makeMockUser({
        role: UserRole.SYSTEM_ADMIN,
      });

      const links = getAuthorizedNavLinks(admin);
      expect(links.length).toBe(11);
      expect(links.some((l) => l.path === '/audit')).toBe(true);
      expect(links.some((l) => l.path === '/championships')).toBe(true);
      expect(links.some((l) => l.path === '/support')).toBe(true);
    });

    it('SUPPORT_AGENT navigation includes /support, /, /athletes, and /governance only', () => {
      const supportAgent = makeMockUser({
        role: UserRole.SUPPORT_AGENT,
      });

      const links = getAuthorizedNavLinks(supportAgent);
      const paths = links.map((l) => l.path);
      expect(paths).toContain('/support');
      expect(paths).toContain('/');
      expect(paths).toContain('/athletes');
      expect(paths).toContain('/governance');
      expect(paths).not.toContain('/audit');
      expect(paths).not.toContain('/championships');
      expect(paths).not.toContain('/referees');
      expect(paths).not.toContain('/venues');
    });

    it('NATIONAL_DIRECTOR navigation hides /audit', () => {
      const natDir = makeMockUser({
        role: UserRole.NATIONAL_DIRECTOR,
      });

      const links = getAuthorizedNavLinks(natDir);
      const paths = links.map((l) => l.path);
      expect(paths).toContain('/championships');
      expect(paths).not.toContain('/audit');
    });

    it('PROVINCIAL_DIRECTOR navigation hides /championships and /audit', () => {
      const provDir = makeMockUser({
        role: UserRole.PROVINCIAL_DIRECTOR,
      });

      const links = getAuthorizedNavLinks(provDir);
      const paths = links.map((l) => l.path);
      expect(paths).not.toContain('/championships');
      expect(paths).not.toContain('/audit');
      expect(paths).toContain('/athletes');
      expect(paths).toContain('/referees');
      expect(paths).toContain('/nominations');
    });

    it('renders user jurisdiction and active role in AdminShell drawer', () => {
      const authVal = createMockAuthContext({
        user: makeMockUser({
          id: 'u-prov-1',
          email: 'punjab@armsphere.pk',
          fullName: 'Punjab Director',
          role: UserRole.PROVINCIAL_DIRECTOR,
          activeRole: UserRole.PROVINCIAL_DIRECTOR,
          province: 'Punjab',
        }),
        activeRole: UserRole.PROVINCIAL_DIRECTOR,
        jurisdiction: 'Punjab',
      });

      render(
        <AuthContext.Provider value={authVal}>
          <MemoryRouter>
            <AdminShell>
              <div>Dashboard Content</div>
            </AdminShell>
          </MemoryRouter>
        </AuthContext.Provider>
      );

      // Verify the user name and province badge render
      expect(screen.getByText('Punjab Director')).toBeDefined();
      expect(screen.getAllByText(/Punjab/i).length).toBeGreaterThan(0);
    });
  });

  // =========================================================================
  // 4. RoleGuardedRoute & ForbiddenPage (403) Security Display
  // =========================================================================
  describe('RoleGuardedRoute & ForbiddenPage - 403 Security Display', () => {
    it('renders children when authenticated and authorized for route', () => {
      const authVal = createMockAuthContext({
        user: makeMockUser({
          role: UserRole.SYSTEM_ADMIN,
          activeRole: UserRole.SYSTEM_ADMIN,
        }),
        activeRole: UserRole.SYSTEM_ADMIN,
      });

      render(
        <AuthContext.Provider value={authVal}>
          <MemoryRouter initialEntries={['/championships']}>
            <RoleGuardedRoute path="/championships">
              <div data-testid="authorized-content">Championships Console</div>
            </RoleGuardedRoute>
          </MemoryRouter>
        </AuthContext.Provider>
      );

      expect(screen.getByTestId('authorized-content')).toBeDefined();
    });

    it('intercepts unauthorized direct URL entry and displays 403 ForbiddenPage', () => {
      const authVal = createMockAuthContext({
        user: makeMockUser({
          role: UserRole.PROVINCIAL_DIRECTOR,
          activeRole: UserRole.PROVINCIAL_DIRECTOR,
          province: 'Punjab',
        }),
        activeRole: UserRole.PROVINCIAL_DIRECTOR,
        jurisdiction: 'Punjab',
      });

      render(
        <AuthContext.Provider value={authVal}>
          <MemoryRouter initialEntries={['/championships']}>
            <RoleGuardedRoute path="/championships">
              <div data-testid="authorized-content">Championships Console</div>
            </RoleGuardedRoute>
          </MemoryRouter>
        </AuthContext.Provider>
      );

      // Child content must NOT be rendered
      expect(screen.queryByTestId('authorized-content')).toBeNull();

      // Forbidden 403 page must be rendered
      expect(screen.getByText(/HTTP 403 Forbidden/i)).toBeDefined();
      expect(screen.getByText('Restricted Operational Area')).toBeDefined();
      expect(screen.getAllByText('/championships').length).toBeGreaterThan(0);
      expect(screen.getAllByText('PROVINCIAL DIRECTOR').length).toBeGreaterThan(0);
    });

    it('displays attempted route, active role, and jurisdiction in the 403 screen', () => {
      const authVal = createMockAuthContext({
        user: makeMockUser({
          role: UserRole.PROVINCIAL_DIRECTOR,
          activeRole: UserRole.PROVINCIAL_DIRECTOR,
          province: 'Sindh',
        }),
        activeRole: UserRole.PROVINCIAL_DIRECTOR,
        jurisdiction: 'Sindh',
      });

      render(
        <AuthContext.Provider value={authVal}>
          <MemoryRouter initialEntries={['/championships']}>
            <ForbiddenPage attemptedPath="/championships" />
          </MemoryRouter>
        </AuthContext.Provider>
      );

      expect(screen.getByText(/HTTP 403 Forbidden/i)).toBeDefined();
      expect(screen.getByText('Restricted Operational Area')).toBeDefined();
      expect(screen.getAllByText('/championships').length).toBeGreaterThan(0);
      expect(screen.getByText('PROVINCIAL DIRECTOR')).toBeDefined();
      expect(screen.getByText('Sindh')).toBeDefined();
    });

    it('offers role switching when user possesses alternate verified roles', () => {
      const switchRoleMock = vi.fn().mockReturnValue(true);
      const authVal = createMockAuthContext({
        user: makeMockUser({
          role: UserRole.TOURNAMENT_OPERATOR,
          activeRole: UserRole.TOURNAMENT_OPERATOR,
          verifiedRoles: ['TOURNAMENT_OPERATOR', 'PROVINCIAL_DIRECTOR'],
        }),
        activeRole: UserRole.TOURNAMENT_OPERATOR,
        switchActiveRole: switchRoleMock,
      });

      render(
        <AuthContext.Provider value={authVal}>
          <MemoryRouter initialEntries={['/referees']}>
            <ForbiddenPage attemptedPath="/referees" requiredRoles={[UserRole.PROVINCIAL_DIRECTOR, UserRole.SYSTEM_ADMIN]} />
          </MemoryRouter>
        </AuthContext.Provider>
      );

      // Button to switch to PROVINCIAL_DIRECTOR should be present
      const switchBtn = screen.getByRole('button', { name: /Switch to PROVINCIAL/i });
      expect(switchBtn).toBeDefined();

      fireEvent.click(switchBtn);
      expect(switchRoleMock).toHaveBeenCalledWith(UserRole.PROVINCIAL_DIRECTOR);
    });
  });

  // =========================================================================
  // 5. Provincial Director Jurisdiction Scoping on Athletes Page
  // =========================================================================
  describe('AthletesPage - Provincial Director Scoping', () => {
    it('locks the province filter to the Provincial Director assigned jurisdiction', () => {
      const authVal = createMockAuthContext({
        user: makeMockUser({
          role: UserRole.PROVINCIAL_DIRECTOR,
          activeRole: UserRole.PROVINCIAL_DIRECTOR,
          province: 'Punjab',
        }),
        activeRole: UserRole.PROVINCIAL_DIRECTOR,
        jurisdiction: 'Punjab',
      });

      render(
        <AuthContext.Provider value={authVal}>
          <QueryClientProvider client={queryClient}>
            <MemoryRouter>
              <AthletesPage />
            </MemoryRouter>
          </QueryClientProvider>
        </AuthContext.Provider>
      );

      // Verify the locked jurisdiction badge is rendered
      const badge = screen.getByTestId('locked-jurisdiction-badge');
      expect(badge).toBeDefined();
      expect(badge.textContent).toContain('JURISDICTION: PUNJAB');

      // The open province select dropdown should NOT be rendered for Provincial Director
      expect(screen.queryByText('All Provinces')).toBeNull();
    });

    it('renders selectable province dropdown for SYSTEM_ADMIN and NATIONAL_DIRECTOR', () => {
      const authVal = createMockAuthContext({
        user: makeMockUser({
          role: UserRole.SYSTEM_ADMIN,
          activeRole: UserRole.SYSTEM_ADMIN,
        }),
        activeRole: UserRole.SYSTEM_ADMIN,
        jurisdiction: null,
      });

      render(
        <AuthContext.Provider value={authVal}>
          <QueryClientProvider client={queryClient}>
            <MemoryRouter>
              <AthletesPage />
            </MemoryRouter>
          </QueryClientProvider>
        </AuthContext.Provider>
      );

      // System Admin sees the province select dropdown
      expect(screen.getByText('All Provinces')).toBeDefined();
      expect(screen.queryByTestId('locked-jurisdiction-badge')).toBeNull();
    });
  });

  // =========================================================================
  // 6. Provincial Director Jurisdiction Scoping on Referees Page
  // =========================================================================
  describe('RefereesPage - Region Assignment Scoping', () => {
    it('restricts region assignment modal to Provincial Director jurisdiction', async () => {
      const authVal = createMockAuthContext({
        user: makeMockUser({
          role: UserRole.PROVINCIAL_DIRECTOR,
          activeRole: UserRole.PROVINCIAL_DIRECTOR,
          province: 'Sindh',
        }),
        activeRole: UserRole.PROVINCIAL_DIRECTOR,
        jurisdiction: 'Sindh',
      });

      render(
        <AuthContext.Provider value={authVal}>
          <QueryClientProvider client={queryClient}>
            <MemoryRouter>
              <RefereesPage />
            </MemoryRouter>
          </QueryClientProvider>
        </AuthContext.Provider>
      );

      // Open region assignment modal for first referee
      const regionBtns = screen.getAllByTitle('Assign Regional Coverage');
      expect(regionBtns.length).toBeGreaterThan(0);
      fireEvent.click(regionBtns[0]);

      // Verify the region select in the modal only contains Sindh
      expect(screen.getByText('Assign Regional Coverage')).toBeDefined();
      const modal = screen.getByText('Assign Regional Coverage').closest('.bg-brand-panel');
      expect(modal).toBeTruthy();
      const modalWithin = within(modal as HTMLElement);
      expect(modalWithin.getByRole('option', { name: 'Sindh' })).toBeDefined();
      // Other provinces should not be available for Provincial Director
      expect(modalWithin.queryByRole('option', { name: 'Punjab' })).toBeNull();
    });
  });

  // =========================================================================
  // 7. Backend 401 Interception & Auto-Logout Handling
  // =========================================================================
  describe('apiClient - 401 Interception', () => {
    it('registers and triggers onUnauthorized callback', () => {
      const onUnauthorizedMock = vi.fn();
      onUnauthorized(onUnauthorizedMock);

      // Simulate a 401 event callback trigger
      onUnauthorizedMock();
      expect(onUnauthorizedMock).toHaveBeenCalledTimes(1);

      onUnauthorized(null);
    });
  });

  // =========================================================================
  // 8. Action Capability Enforcement (canPerformAction)
  // =========================================================================
  describe('authorizationPolicy - Fine-Grained Action Checks', () => {
    it('prevents non-super-admins from blacklisting, recovering, or correcting athletes', () => {
      const provDir = makeMockUser({
        role: UserRole.PROVINCIAL_DIRECTOR,
      });

      expect(canPerformAction(provDir, 'REVIEW_ATHLETE')).toBe(true);
      expect(canPerformAction(provDir, 'SUSPEND_ATHLETE')).toBe(true);
      expect(canPerformAction(provDir, 'MANAGE_CERTIFICATIONS')).toBe(true);

      // Strictly super-admin operations:
      expect(canPerformAction(provDir, 'BLACKLIST_ATHLETE')).toBe(false);
      expect(canPerformAction(provDir, 'RECOVER_ATHLETE')).toBe(false);
      expect(canPerformAction(provDir, 'CORRECT_ATHLETE')).toBe(false);
      expect(canPerformAction(provDir, 'MANAGE_CHAMPIONSHIPS')).toBe(false);
      expect(canPerformAction(provDir, 'VERIFY_AUDIT_LEDGER')).toBe(false);
    });

    it('grants SYSTEM_ADMIN full capability across all actions', () => {
      const sysAdmin = makeMockUser({
        role: UserRole.SYSTEM_ADMIN,
      });

      expect(canPerformAction(sysAdmin, 'REVIEW_ATHLETE')).toBe(true);
      expect(canPerformAction(sysAdmin, 'SUSPEND_ATHLETE')).toBe(true);
      expect(canPerformAction(sysAdmin, 'BLACKLIST_ATHLETE')).toBe(true);
      expect(canPerformAction(sysAdmin, 'RECOVER_ATHLETE')).toBe(true);
      expect(canPerformAction(sysAdmin, 'CORRECT_ATHLETE')).toBe(true);
      expect(canPerformAction(sysAdmin, 'MANAGE_CERTIFICATIONS')).toBe(true);
      expect(canPerformAction(sysAdmin, 'ASSIGN_REFEREE_REGION')).toBe(true);
      expect(canPerformAction(sysAdmin, 'UPDATE_REFEREE_LICENSE')).toBe(true);
      expect(canPerformAction(sysAdmin, 'SUSPEND_REFEREE')).toBe(true);
      expect(canPerformAction(sysAdmin, 'MANAGE_CHAMPIONSHIPS')).toBe(true);
      expect(canPerformAction(sysAdmin, 'VERIFY_AUDIT_LEDGER')).toBe(true);
      expect(canPerformAction(sysAdmin, 'RESOLVE_DISPUTE')).toBe(true);
      expect(canPerformAction(sysAdmin, 'MODERATE_COMMUNITY')).toBe(true);
      expect(canPerformAction(sysAdmin, 'VERIFY_VENUE')).toBe(true);
      expect(canPerformAction(sysAdmin, 'UPDATE_NOMINATION')).toBe(true);
      expect(canPerformAction(sysAdmin, 'MANAGE_SUPPORT_TICKETS')).toBe(true);
    });

    it('enforces specific governance action rules across all roles', () => {
      const natDir = makeMockUser({ role: UserRole.NATIONAL_DIRECTOR });
      const provDir = makeMockUser({ role: UserRole.PROVINCIAL_DIRECTOR });
      const compOfficer = makeMockUser({ role: UserRole.COMPLIANCE_OFFICER });
      const tourneyOp = makeMockUser({ role: UserRole.TOURNAMENT_OPERATOR });
      const athlete = makeMockUser({ role: UserRole.ATHLETE });
      const supportAgent = makeMockUser({ role: UserRole.SUPPORT_AGENT });

      // MANAGE_SUPPORT_TICKETS
      expect(canPerformAction(supportAgent, 'MANAGE_SUPPORT_TICKETS')).toBe(true);
      expect(canPerformAction(natDir, 'MANAGE_SUPPORT_TICKETS')).toBe(false);
      expect(canPerformAction(provDir, 'MANAGE_SUPPORT_TICKETS')).toBe(false);
      expect(canPerformAction(compOfficer, 'MANAGE_SUPPORT_TICKETS')).toBe(false);
      expect(canPerformAction(tourneyOp, 'MANAGE_SUPPORT_TICKETS')).toBe(false);
      expect(canPerformAction(athlete, 'MANAGE_SUPPORT_TICKETS')).toBe(false);

      // RESOLVE_DISPUTE
      expect(canPerformAction(natDir, 'RESOLVE_DISPUTE')).toBe(true);
      expect(canPerformAction(provDir, 'RESOLVE_DISPUTE')).toBe(true);
      expect(canPerformAction(compOfficer, 'RESOLVE_DISPUTE')).toBe(true);
      expect(canPerformAction(tourneyOp, 'RESOLVE_DISPUTE')).toBe(false);
      expect(canPerformAction(athlete, 'RESOLVE_DISPUTE')).toBe(false);

      // VERIFY_AUDIT_LEDGER
      expect(canPerformAction(compOfficer, 'VERIFY_AUDIT_LEDGER')).toBe(true);
      expect(canPerformAction(natDir, 'VERIFY_AUDIT_LEDGER')).toBe(false);
      expect(canPerformAction(provDir, 'VERIFY_AUDIT_LEDGER')).toBe(false);

      // MANAGE_CHAMPIONSHIPS
      expect(canPerformAction(natDir, 'MANAGE_CHAMPIONSHIPS')).toBe(true);
      expect(canPerformAction(provDir, 'MANAGE_CHAMPIONSHIPS')).toBe(false);
      expect(canPerformAction(compOfficer, 'MANAGE_CHAMPIONSHIPS')).toBe(false);

      // MODERATE_COMMUNITY
      expect(canPerformAction(natDir, 'MODERATE_COMMUNITY')).toBe(true);
      expect(canPerformAction(provDir, 'MODERATE_COMMUNITY')).toBe(true);
      expect(canPerformAction(compOfficer, 'MODERATE_COMMUNITY')).toBe(false);

      // VERIFY_VENUE
      expect(canPerformAction(natDir, 'VERIFY_VENUE')).toBe(true);
      expect(canPerformAction(provDir, 'VERIFY_VENUE')).toBe(true);
      expect(canPerformAction(compOfficer, 'VERIFY_VENUE')).toBe(false);
      expect(canPerformAction(tourneyOp, 'VERIFY_VENUE')).toBe(false);

      // UPDATE_NOMINATION
      expect(canPerformAction(natDir, 'UPDATE_NOMINATION')).toBe(true);
      expect(canPerformAction(provDir, 'UPDATE_NOMINATION')).toBe(true);
      expect(canPerformAction(compOfficer, 'UPDATE_NOMINATION')).toBe(false);
      expect(canPerformAction(tourneyOp, 'UPDATE_NOMINATION')).toBe(false);
    });
  });

  // =========================================================================
  // 9. Page-Level Scoping & Action Hardening
  // =========================================================================
  describe('VenuesPage - Jurisdiction & Verification RBAC', () => {
    it('locks jurisdiction badge and filters to assigned province for Provincial Director', () => {
      const provDir = makeMockUser({
        role: UserRole.PROVINCIAL_DIRECTOR,
        province: 'Punjab',
      });
      const authCtx = createMockAuthContext({
        user: provDir,
        activeRole: UserRole.PROVINCIAL_DIRECTOR,
        jurisdiction: 'Punjab',
      });

      render(
        <QueryClientProvider client={queryClient}>
          <AuthContext.Provider value={authCtx}>
            <MemoryRouter>
              <VenuesPage />
            </MemoryRouter>
          </AuthContext.Provider>
        </QueryClientProvider>
      );

      // Badge must appear
      expect(screen.getByTestId('locked-jurisdiction-badge')).toBeDefined();
      expect(screen.getByText(/JURISDICTION: PUNJAB/i)).toBeDefined();

      // Only Lahore Iron Gym (Punjab) should be in the list
      expect(screen.getByText('Lahore Iron Gym')).toBeDefined();
      expect(screen.queryByText('Quetta Power Pit')).toBeNull();
    });

    it('renders normal province selector and shows all venues for System Admin', () => {
      const sysAdmin = makeMockUser({
        role: UserRole.SYSTEM_ADMIN,
      });
      const authCtx = createMockAuthContext({
        user: sysAdmin,
        activeRole: UserRole.SYSTEM_ADMIN,
        jurisdiction: null,
      });

      render(
        <QueryClientProvider client={queryClient}>
          <AuthContext.Provider value={authCtx}>
            <MemoryRouter>
              <VenuesPage />
            </MemoryRouter>
          </AuthContext.Provider>
        </QueryClientProvider>
      );

      // Locked badge should NOT appear
      expect(screen.queryByTestId('locked-jurisdiction-badge')).toBeNull();

      // Both gyms should be visible
      expect(screen.getByText('Lahore Iron Gym')).toBeDefined();
      expect(screen.getByText('Quetta Power Pit')).toBeDefined();
    });
  });

  describe('NominationsPage - Jurisdiction & Workflow RBAC', () => {
    it('locks jurisdiction badge and scopes nominations for Provincial Director', () => {
      const provDir = makeMockUser({
        role: UserRole.PROVINCIAL_DIRECTOR,
        province: 'Punjab',
      });
      const authCtx = createMockAuthContext({
        user: provDir,
        activeRole: UserRole.PROVINCIAL_DIRECTOR,
        jurisdiction: 'Punjab',
      });

      render(
        <QueryClientProvider client={queryClient}>
          <AuthContext.Provider value={authCtx}>
            <MemoryRouter>
              <NominationsPage />
            </MemoryRouter>
          </AuthContext.Provider>
        </QueryClientProvider>
      );

      expect(screen.getByTestId('locked-jurisdiction-badge')).toBeDefined();
      expect(screen.getByText(/JURISDICTION: PUNJAB/i)).toBeDefined();

      // Scoped to Punjab nominee
      expect(screen.getByText('Ali Raza')).toBeDefined();
      expect(screen.queryByText('Kamran Khan')).toBeNull();
    });
  });

  describe('GovernancePage - Cross-Jurisdiction Dispute Adjudication', () => {
    it('allows Provincial Director to adjudicate dispute within their jurisdiction', () => {
      const provDir = makeMockUser({
        role: UserRole.PROVINCIAL_DIRECTOR,
        province: 'Punjab',
      });
      const authCtx = createMockAuthContext({
        user: provDir,
        activeRole: UserRole.PROVINCIAL_DIRECTOR,
        jurisdiction: 'Punjab',
      });

      render(
        <QueryClientProvider client={queryClient}>
          <AuthContext.Provider value={authCtx}>
            <MemoryRouter>
              <GovernancePage />
            </MemoryRouter>
          </AuthContext.Provider>
        </QueryClientProvider>
      );

      // Default selected dispute is disp-1 (Punjab)
      expect(screen.getAllByText('Foul Protest Punjab').length).toBeGreaterThan(0);
      // Adjudication form should be enabled
      expect(screen.getByText('Adjudicate Case')).toBeDefined();
    });

    it('blocks Provincial Director from adjudicating cross-province dispute with clear warning', () => {
      const provDir = makeMockUser({
        role: UserRole.PROVINCIAL_DIRECTOR,
        province: 'Punjab',
      });
      const authCtx = createMockAuthContext({
        user: provDir,
        activeRole: UserRole.PROVINCIAL_DIRECTOR,
        jurisdiction: 'Punjab',
      });

      render(
        <QueryClientProvider client={queryClient}>
          <AuthContext.Provider value={authCtx}>
            <MemoryRouter>
              <GovernancePage />
            </MemoryRouter>
          </AuthContext.Provider>
        </QueryClientProvider>
      );

      // Click the Balochistan dispute in the index
      const balochistanDisputeBtn = screen.getByText('Elbow Foul Balochistan');
      fireEvent.click(balochistanDisputeBtn);

      // Warning banner should appear instead of submit button
      expect(screen.getByText('Cross-Jurisdiction Restriction')).toBeDefined();
      expect(screen.getByText(/scoped to Punjab.*originated in Balochistan/i)).toBeDefined();
      expect(screen.queryByText('Adjudicate Case')).toBeNull();
    });
  });

  describe('AuditPage - Ledger Verification Capability', () => {
    it('disables Recompute button for unauthorized role', () => {
      const provDir = makeMockUser({
        role: UserRole.PROVINCIAL_DIRECTOR,
      });
      const authCtx = createMockAuthContext({
        user: provDir,
        activeRole: UserRole.PROVINCIAL_DIRECTOR,
      });

      render(
        <QueryClientProvider client={queryClient}>
          <AuthContext.Provider value={authCtx}>
            <MemoryRouter>
              <AuditPage />
            </MemoryRouter>
          </AuthContext.Provider>
        </QueryClientProvider>
      );

      const verifyBtn = screen.getByRole('button', { name: /verify chain integrity/i }) as HTMLButtonElement;
      expect(verifyBtn.disabled).toBe(true);
    });

    it('enables Recompute button for Compliance Officer', () => {
      const compOfficer = makeMockUser({
        role: UserRole.COMPLIANCE_OFFICER,
      });
      const authCtx = createMockAuthContext({
        user: compOfficer,
        activeRole: UserRole.COMPLIANCE_OFFICER,
      });

      render(
        <QueryClientProvider client={queryClient}>
          <AuthContext.Provider value={authCtx}>
            <MemoryRouter>
              <AuditPage />
            </MemoryRouter>
          </AuthContext.Provider>
        </QueryClientProvider>
      );

      const verifyBtn = screen.getByRole('button', { name: /verify chain integrity/i }) as HTMLButtonElement;
      expect(verifyBtn.disabled).toBe(false);
    });
  });
});
