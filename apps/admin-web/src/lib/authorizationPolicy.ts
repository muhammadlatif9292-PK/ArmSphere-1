import { User, UserRole } from '../types';

export interface RoutePermission {
  path: string;
  label: string;
  category: 'Overview' | 'Competition' | 'Governance' | 'Platform';
  allowedRoles: UserRole[];
  isJurisdictionScoped?: boolean;
}

export type AdminAction =
  | 'MANAGE_CHAMPIONSHIPS'
  | 'UPDATE_REFEREE_LICENSE'
  | 'SUSPEND_REFEREE'
  | 'ASSIGN_REFEREE_REGION'
  | 'RESOLVE_DISPUTE'
  | 'VERIFY_AUDIT_LEDGER'
  | 'BLACKLIST_ATHLETE'
  | 'RECOVER_ATHLETE'
  | 'CORRECT_ATHLETE'
  | 'SUSPEND_ATHLETE'
  | 'REVIEW_ATHLETE'
  | 'MANAGE_CERTIFICATIONS'
  | 'MODERATE_COMMUNITY'
  | 'VERIFY_VENUE'
  | 'UPDATE_NOMINATION';

export const ADMIN_ROUTE_PERMISSIONS: RoutePermission[] = [
  {
    path: '/',
    label: 'Operations Center',
    category: 'Overview',
    allowedRoles: [
      UserRole.SYSTEM_ADMIN,
      UserRole.NATIONAL_DIRECTOR,
      UserRole.PROVINCIAL_DIRECTOR,
      UserRole.TOURNAMENT_OPERATOR,
      UserRole.COMPLIANCE_OFFICER,
      UserRole.SUPPORT_AGENT,
    ],
  },
  {
    path: '/athletes',
    label: 'Athletes',
    category: 'Competition',
    allowedRoles: [
      UserRole.SYSTEM_ADMIN,
      UserRole.NATIONAL_DIRECTOR,
      UserRole.PROVINCIAL_DIRECTOR,
      UserRole.TOURNAMENT_OPERATOR,
      UserRole.COMPLIANCE_OFFICER,
      UserRole.SUPPORT_AGENT,
    ],
    isJurisdictionScoped: true,
  },
  {
    path: '/referees',
    label: 'Referees',
    category: 'Competition',
    allowedRoles: [
      UserRole.SYSTEM_ADMIN,
      UserRole.NATIONAL_DIRECTOR,
      UserRole.PROVINCIAL_DIRECTOR,
      UserRole.COMPLIANCE_OFFICER,
    ],
    isJurisdictionScoped: true,
  },
  {
    path: '/championships',
    label: 'Championship Titles',
    category: 'Competition',
    allowedRoles: [UserRole.SYSTEM_ADMIN, UserRole.NATIONAL_DIRECTOR],
  },
  {
    path: '/nominations',
    label: 'Nominations',
    category: 'Competition',
    allowedRoles: [UserRole.SYSTEM_ADMIN, UserRole.NATIONAL_DIRECTOR, UserRole.PROVINCIAL_DIRECTOR],
    isJurisdictionScoped: true,
  },
  {
    path: '/analytics',
    label: 'Analytics',
    category: 'Competition',
    allowedRoles: [
      UserRole.SYSTEM_ADMIN,
      UserRole.NATIONAL_DIRECTOR,
      UserRole.PROVINCIAL_DIRECTOR,
      UserRole.COMPLIANCE_OFFICER,
    ],
  },
  {
    path: '/governance',
    label: 'Dispute Review',
    category: 'Governance',
    allowedRoles: [
      UserRole.SYSTEM_ADMIN,
      UserRole.NATIONAL_DIRECTOR,
      UserRole.PROVINCIAL_DIRECTOR,
      UserRole.COMPLIANCE_OFFICER,
      UserRole.SUPPORT_AGENT,
    ],
  },
  {
    path: '/moderation',
    label: 'Community Moderation',
    category: 'Governance',
    allowedRoles: [UserRole.SYSTEM_ADMIN, UserRole.NATIONAL_DIRECTOR, UserRole.PROVINCIAL_DIRECTOR],
  },
  {
    path: '/venues',
    label: 'Venues',
    category: 'Governance',
    allowedRoles: [UserRole.SYSTEM_ADMIN, UserRole.NATIONAL_DIRECTOR, UserRole.PROVINCIAL_DIRECTOR],
    isJurisdictionScoped: true,
  },
  {
    path: '/audit',
    label: 'Audit Ledger',
    category: 'Platform',
    allowedRoles: [UserRole.SYSTEM_ADMIN, UserRole.COMPLIANCE_OFFICER],
  },
];

export interface AccessEvaluation {
  allowed: boolean;
  reason?: 'UNAUTHENTICATED' | 'FORBIDDEN_ROLE' | 'FORBIDDEN_JURISDICTION' | 'UNKNOWN_ROUTE';
  requiredRoles?: UserRole[];
  userRole?: UserRole | null;
  userJurisdiction?: string | null;
}

/**
 * Resolves the user's active role. Falls back to user.role if activeRole is unset or ineligible.
 */
export function getEffectiveRole(user: User | null): UserRole | null {
  if (!user) return null;
  if (user.activeRole && canSwitchToRole(user, user.activeRole as UserRole)) {
    return user.activeRole as UserRole;
  }
  return (user.role as UserRole) || null;
}

/**
 * Resolves the user's assigned jurisdiction / province (for PROVINCIAL_DIRECTOR).
 */
export function getUserJurisdiction(user: User | null): string | null {
  if (!user) return null;
  if (user.province && user.province.trim().length > 0) {
    return user.province.trim();
  }
  if (user.regionalCoverage && user.regionalCoverage.trim().length > 0) {
    return user.regionalCoverage.trim();
  }
  if (user.roleGrants && Array.isArray(user.roleGrants)) {
    const grant = user.roleGrants.find(
      (g) => g.role === UserRole.PROVINCIAL_DIRECTOR && g.status === 'ACTIVE' && g.scope
    );
    if (grant?.scope && grant.scope.trim().length > 0) {
      return grant.scope.trim();
    }
  }
  return null;
}

/**
 * Evaluates whether a user can access a specific route.
 */
export function canAccessRoute(user: User | null, path: string): AccessEvaluation {
  if (!user) {
    return { allowed: false, reason: 'UNAUTHENTICATED' };
  }

  const normalizedPath = path === '' ? '/' : path.split('?')[0].replace(/\/+$/, '') || '/';
  const rule = ADMIN_ROUTE_PERMISSIONS.find((r) => r.path === normalizedPath);

  if (!rule) {
    return { allowed: false, reason: 'UNKNOWN_ROUTE' };
  }

  const effectiveRole = getEffectiveRole(user);
  if (!effectiveRole || !rule.allowedRoles.includes(effectiveRole)) {
    return {
      allowed: false,
      reason: 'FORBIDDEN_ROLE',
      requiredRoles: rule.allowedRoles,
      userRole: effectiveRole,
      userJurisdiction: getUserJurisdiction(user),
    };
  }

  return {
    allowed: true,
    userRole: effectiveRole,
    userJurisdiction: getUserJurisdiction(user),
  };
}

/**
 * Returns only the route permissions that the user is authorized to access.
 */
export function getAuthorizedNavLinks(user: User | null): RoutePermission[] {
  if (!user) return [];
  return ADMIN_ROUTE_PERMISSIONS.filter((rule) => {
    const evaluation = canAccessRoute(user, rule.path);
    return evaluation.allowed;
  });
}

/**
 * Checks whether a user can switch their active role to targetRole.
 */
export function canSwitchToRole(user: User | null, targetRole: UserRole): boolean {
  if (!user) return false;
  if (user.role === targetRole) return true;
  if (user.verifiedRoles && Array.isArray(user.verifiedRoles)) {
    return user.verifiedRoles.includes(targetRole);
  }
  if (user.roleGrants && Array.isArray(user.roleGrants)) {
    return user.roleGrants.some((g) => g.role === targetRole && g.status === 'ACTIVE');
  }
  return false;
}

/**
 * Checks action-level permissions mirroring backend requireRole policies.
 */
export function canPerformAction(user: User | null, action: AdminAction): boolean {
  const role = getEffectiveRole(user);
  if (!role) return false;

  switch (action) {
    case 'MANAGE_CHAMPIONSHIPS':
    case 'BLACKLIST_ATHLETE':
    case 'RECOVER_ATHLETE':
    case 'CORRECT_ATHLETE':
    case 'UPDATE_REFEREE_LICENSE':
    case 'SUSPEND_REFEREE':
      return role === UserRole.SYSTEM_ADMIN || role === UserRole.NATIONAL_DIRECTOR;

    case 'ASSIGN_REFEREE_REGION':
    case 'SUSPEND_ATHLETE':
    case 'REVIEW_ATHLETE':
    case 'MANAGE_CERTIFICATIONS':
    case 'MODERATE_COMMUNITY':
    case 'VERIFY_VENUE':
    case 'UPDATE_NOMINATION':
      return (
        role === UserRole.SYSTEM_ADMIN ||
        role === UserRole.NATIONAL_DIRECTOR ||
        role === UserRole.PROVINCIAL_DIRECTOR
      );

    case 'RESOLVE_DISPUTE':
      return (
        role === UserRole.SYSTEM_ADMIN ||
        role === UserRole.NATIONAL_DIRECTOR ||
        role === UserRole.PROVINCIAL_DIRECTOR ||
        role === UserRole.COMPLIANCE_OFFICER
      );

    case 'VERIFY_AUDIT_LEDGER':
      return role === UserRole.SYSTEM_ADMIN || role === UserRole.COMPLIANCE_OFFICER;

    default:
      return false;
  }
}
