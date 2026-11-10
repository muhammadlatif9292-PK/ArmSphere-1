// lib/core/security/admin_permissions.dart
import 'package:flutter/material.dart';

/// Canonical Federation & Administrative Actions mirrored directly from
/// `apps/api/src/routes/admin.ts`, `apps/api/src/controllers/administration.ts`,
/// and domain controllers.
enum AdminAction {
  viewDashboard,
  triggerWorker,
  runScheduledJobs,
  exportReports,
  reviewAthlete,
  suspendAthlete,
  blacklistAthlete,
  recoverAthlete,
  correctAthlete,
  updateRefereeLicense,
  assignRefereeRegion,
  suspendReferee,
  manageRefereeCertifications,
  manageChampionships,
  updateNomination,
  resolveDispute,
  closeDispute,
  inspectMatch,
  overrideMatch,
  manageWeighIn,
  moderateCommunity,
  verifyVenue,
  verifyAuditChain,
  manageSupport,
  reviewRoleApplications,
  manageRoleApplications,
  grantFederationRole,
  manageReferees,
}

/// Central RBAC and Provincial Jurisdiction Policy for ArmSphere Flutter.
///
/// Server authorization is always authoritative; this policy governs client
/// workspace presentation, bottom navigation dock mode, and action gating.
class AdminPermissions {
  const AdminPermissions._();

  /// Roles that activate the 5-Tab Native Admin Workspace Dock (`Admin Mode`).
  static const Set<String> adminWorkspaceRoles = <String>{
    'SYSTEM_ADMIN',
    'NATIONAL_DIRECTOR',
    'PROVINCIAL_DIRECTOR',
    'COMPLIANCE_OFFICER',
    'SUPPORT_AGENT',
  };

  /// All 9 canonical roles in the ArmSphere Federation ecosystem.
  static const List<String> allFederationRoles = <String>[
    'ATHLETE',
    'REFEREE',
    'TOURNAMENT_OPERATOR',
    'ORGANIZATION_LEADER',
    'SUPPORT_AGENT',
    'COMPLIANCE_OFFICER',
    'PROVINCIAL_DIRECTOR',
    'NATIONAL_DIRECTOR',
    'SYSTEM_ADMIN',
  ];

  /// Returns `true` when [role] should present the 5-tab Native Admin Workspace
  /// (`Command`, `Roster`, `Arena Ops`, `Governance`, `Dossier`).
  static bool isAdminWorkspaceRole(String? role) {
    if (role == null || role.trim().isEmpty) return false;
    return adminWorkspaceRoles.contains(role.trim().toUpperCase());
  }

  /// Resolves the assigned provincial jurisdiction for a `PROVINCIAL_DIRECTOR`
  /// from their profile (`roleGrants`, `regionalCoverage`, or `province`).
  static String? resolveJurisdiction(Map<String, dynamic>? userProfile) {
    if (userProfile == null) return null;

    // 1. Check explicit roleGrants array if present
    final grants = userProfile['roleGrants'];
    if (grants is List) {
      for (final g in grants) {
        if (g is Map) {
          final role = g['role']?.toString().toUpperCase();
          final isActive = g['isActive'] != false;
          final jur = g['jurisdiction']?.toString().trim();
          if (role == 'PROVINCIAL_DIRECTOR' &&
              isActive &&
              jur != null &&
              jur.isNotEmpty) {
            return jur;
          }
        }
      }
    }

    // 2. Check regionalCoverage or explicit jurisdiction field
    final coverage = userProfile['jurisdiction']?.toString().trim() ??
        userProfile['regionalCoverage']?.toString().trim();
    if (coverage != null && coverage.isNotEmpty) {
      return coverage;
    }

    // 3. Fallback to profile province
    final nestedProfile = userProfile['profile'];
    final province = userProfile['province']?.toString().trim() ??
        (nestedProfile is Map
            ? nestedProfile['province']?.toString().trim()
            : null);
    if (province != null && province.isNotEmpty) {
      return province;
    }
    return null;
  }

  /// Checks whether [role] is authorized to perform [action].
  ///
  /// Strictly mirrors `requireRole(...)` guards in `apps/api/src/routes/admin.ts`
  /// and domain route files.
  /// When [role] is `PROVINCIAL_DIRECTOR` and [targetProvince] is supplied for
  /// a province-scoped mutation, verifies that [targetProvince] matches [jurisdiction].
  static bool canPerform(
    String? role,
    AdminAction action, {
    String? jurisdiction,
    String? targetProvince,
  }) {
    if (role == null || role.trim().isEmpty) return false;
    final r = role.trim().toUpperCase();

    final bool hasRolePermission = switch (action) {
      AdminAction.viewDashboard => adminWorkspaceRoles.contains(r),
      AdminAction.triggerWorker => r == 'SYSTEM_ADMIN',
      AdminAction.runScheduledJobs => r == 'SYSTEM_ADMIN',
      AdminAction.exportReports => const {
          'SYSTEM_ADMIN',
          'NATIONAL_DIRECTOR',
          'PROVINCIAL_DIRECTOR',
          'COMPLIANCE_OFFICER',
        }.contains(r),
      AdminAction.reviewAthlete => const {
          'SYSTEM_ADMIN',
          'NATIONAL_DIRECTOR',
          'PROVINCIAL_DIRECTOR',
          'COMPLIANCE_OFFICER',
        }.contains(r),
      AdminAction.suspendAthlete => const {
          'SYSTEM_ADMIN',
          'NATIONAL_DIRECTOR',
          'PROVINCIAL_DIRECTOR',
        }.contains(r),
      AdminAction.blacklistAthlete => const {
          'SYSTEM_ADMIN',
          'NATIONAL_DIRECTOR',
        }.contains(r),
      AdminAction.recoverAthlete => const {
          'SYSTEM_ADMIN',
          'NATIONAL_DIRECTOR',
        }.contains(r),
      AdminAction.correctAthlete => const {
          'SYSTEM_ADMIN',
          'NATIONAL_DIRECTOR',
        }.contains(r),
      AdminAction.updateRefereeLicense => const {
          'SYSTEM_ADMIN',
          'NATIONAL_DIRECTOR',
        }.contains(r),
      AdminAction.assignRefereeRegion => const {
          'SYSTEM_ADMIN',
          'NATIONAL_DIRECTOR',
          'PROVINCIAL_DIRECTOR',
        }.contains(r),
      AdminAction.suspendReferee => const {
          'SYSTEM_ADMIN',
          'NATIONAL_DIRECTOR',
        }.contains(r),
      AdminAction.manageRefereeCertifications => const {
          'SYSTEM_ADMIN',
          'NATIONAL_DIRECTOR',
          'PROVINCIAL_DIRECTOR',
        }.contains(r),
      AdminAction.manageReferees => const {
          'SYSTEM_ADMIN',
          'NATIONAL_DIRECTOR',
          'PROVINCIAL_DIRECTOR',
        }.contains(r),
      AdminAction.manageChampionships => const {
          'SYSTEM_ADMIN',
          'NATIONAL_DIRECTOR',
        }.contains(r),
      AdminAction.updateNomination => const {
          'SYSTEM_ADMIN',
          'NATIONAL_DIRECTOR',
          'PROVINCIAL_DIRECTOR',
        }.contains(r),
      AdminAction.resolveDispute => const {
          'SYSTEM_ADMIN',
          'NATIONAL_DIRECTOR',
          'PROVINCIAL_DIRECTOR',
          'COMPLIANCE_OFFICER',
        }.contains(r),
      AdminAction.closeDispute => const {
          'SYSTEM_ADMIN',
          'NATIONAL_DIRECTOR',
          'PROVINCIAL_DIRECTOR',
          'COMPLIANCE_OFFICER',
        }.contains(r),
      AdminAction.inspectMatch => const {
          'SYSTEM_ADMIN',
          'NATIONAL_DIRECTOR',
          'PROVINCIAL_DIRECTOR',
          'COMPLIANCE_OFFICER',
          'REFEREE',
        }.contains(r),
      AdminAction.overrideMatch => const {
          'SYSTEM_ADMIN',
          'NATIONAL_DIRECTOR',
        }.contains(r),
      AdminAction.manageWeighIn => const {
          'SYSTEM_ADMIN',
          'NATIONAL_DIRECTOR',
          'PROVINCIAL_DIRECTOR',
          'REFEREE',
        }.contains(r),
      AdminAction.moderateCommunity => const {
          'SYSTEM_ADMIN',
          'NATIONAL_DIRECTOR',
          'PROVINCIAL_DIRECTOR',
        }.contains(r),
      AdminAction.verifyVenue => const {
          'SYSTEM_ADMIN',
          'NATIONAL_DIRECTOR',
          'PROVINCIAL_DIRECTOR',
        }.contains(r),
      AdminAction.verifyAuditChain => const {
          'SYSTEM_ADMIN',
          'COMPLIANCE_OFFICER',
        }.contains(r),
      AdminAction.manageSupport => const {
          'SYSTEM_ADMIN',
          'SUPPORT_AGENT',
        }.contains(r),
      AdminAction.reviewRoleApplications => const {
          'SYSTEM_ADMIN',
          'NATIONAL_DIRECTOR',
          'PROVINCIAL_DIRECTOR',
        }.contains(r),
      AdminAction.manageRoleApplications => const {
          'SYSTEM_ADMIN',
          'NATIONAL_DIRECTOR',
          'PROVINCIAL_DIRECTOR',
        }.contains(r),
      AdminAction.grantFederationRole => const {
          'SYSTEM_ADMIN',
          'NATIONAL_DIRECTOR',
        }.contains(r),
    };

    if (!hasRolePermission) return false;

    // Enforce Provincial Director jurisdiction scoping when targetProvince is provided
    if (r == 'PROVINCIAL_DIRECTOR' &&
        targetProvince != null &&
        targetProvince.trim().isNotEmpty &&
        jurisdiction != null &&
        jurisdiction.trim().isNotEmpty) {
      const provinceScopedActions = <AdminAction>{
        AdminAction.reviewAthlete,
        AdminAction.suspendAthlete,
        AdminAction.assignRefereeRegion,
        AdminAction.manageRefereeCertifications,
        AdminAction.manageReferees,
        AdminAction.updateNomination,
        AdminAction.resolveDispute,
        AdminAction.closeDispute,
        AdminAction.inspectMatch,
        AdminAction.verifyVenue,
      };
      if (provinceScopedActions.contains(action)) {
        return targetProvince.trim().toLowerCase() ==
            jurisdiction.trim().toLowerCase();
      }
    }

    return true;
  }

  /// Human-readable display title for any federation role.
  static String formatRoleName(String? role) {
    switch (role?.trim().toUpperCase()) {
      case 'ATHLETE':
        return 'Athlete';
      case 'REFEREE':
        return 'Certified Referee';
      case 'TOURNAMENT_OPERATOR':
        return 'Tournament Operator';
      case 'ORGANIZATION_LEADER':
        return 'Club / Organization Leader';
      case 'SUPPORT_AGENT':
        return 'Federation Support Agent';
      case 'COMPLIANCE_OFFICER':
        return 'Compliance & Integrity Officer';
      case 'PROVINCIAL_DIRECTOR':
        return 'Provincial Director';
      case 'NATIONAL_DIRECTOR':
        return 'National Director';
      case 'SYSTEM_ADMIN':
        return 'System Administrator';
      default:
        return role?.replaceAll('_', ' ') ?? 'Athlete';
    }
  }

  /// Short badge label for compact chips.
  static String shortRoleBadge(String? role) {
    switch (role?.trim().toUpperCase()) {
      case 'SYSTEM_ADMIN':
        return 'SYS ADMIN';
      case 'NATIONAL_DIRECTOR':
        return 'NATIONAL DIR';
      case 'PROVINCIAL_DIRECTOR':
        return 'PROVINCIAL DIR';
      case 'COMPLIANCE_OFFICER':
        return 'COMPLIANCE';
      case 'SUPPORT_AGENT':
        return 'SUPPORT OPS';
      case 'TOURNAMENT_OPERATOR':
        return 'OPERATOR';
      case 'ORGANIZATION_LEADER':
        return 'CLUB LEADER';
      case 'REFEREE':
        return 'REFEREE';
      case 'ATHLETE':
      default:
        return 'ATHLETE';
    }
  }

  /// Detailed workspace description shown in `Settings -> Account Roles & Persona`.
  static String roleContextDescription(String? role) {
    switch (role?.trim().toUpperCase()) {
      case 'ATHLETE':
        return 'Switches your workspace and bottom navigation bar to Athlete Mode (Arena, Discover, Events, Community, Passport) for personal competition, PR logs, and ELO progression.';
      case 'REFEREE':
        return 'Switches your workspace to the certified referee console, live table scorepads, foul tracking, and bout evidence submission.';
      case 'TOURNAMENT_OPERATOR':
        return 'Switches your workspace to Tournament Operations, double-elimination brackets, weigh-in locks, and podium awards ceremonies.';
      case 'ORGANIZATION_LEADER':
        return 'Switches your workspace to Club & Team leadership, roster management, and inter-club sparring invitations.';
      case 'SUPPORT_AGENT':
        return 'Switches your bottom navigation bar to Admin Mode with full access to the Member Support Helpdesk queue, ticket assignment, internal notes, and resolutions.';
      case 'COMPLIANCE_OFFICER':
        return 'Switches your bottom navigation bar to Admin Mode focused on Dispute Arbitration rulings, match evidence review, and Cryptographic SHA-256 Audit Ledger verification.';
      case 'PROVINCIAL_DIRECTOR':
        return 'Switches your bottom navigation bar to Admin Mode scoped to your assigned province for Athlete Verification, Referee Licensing, Partner Gym Certification, and Scouting.';
      case 'NATIONAL_DIRECTOR':
        return 'Switches your bottom navigation bar to Admin Mode with nationwide executive authority over Athletes, Referees, Championship Belts, Disputes, Moderation, and Role Grants.';
      case 'SYSTEM_ADMIN':
        return 'Switches your bottom navigation bar to Admin Mode with full Federation Command authority across all 5 Admin tabs (Command, Roster, Arena Ops, Governance, Dossier).';
      default:
        return 'Switches your client navigation and operational permissions to this verified federation persona.';
    }
  }

  /// Canonical icon for each federation role.
  static IconData roleIcon(String? role) {
    switch (role?.trim().toUpperCase()) {
      case 'ATHLETE':
        return Icons.fitness_center_rounded;
      case 'REFEREE':
        return Icons.sports_rounded;
      case 'TOURNAMENT_OPERATOR':
        return Icons.account_tree_rounded;
      case 'ORGANIZATION_LEADER':
        return Icons.groups_rounded;
      case 'SUPPORT_AGENT':
        return Icons.support_agent_rounded;
      case 'COMPLIANCE_OFFICER':
        return Icons.policy_rounded;
      case 'PROVINCIAL_DIRECTOR':
        return Icons.location_city_rounded;
      case 'NATIONAL_DIRECTOR':
        return Icons.military_tech_rounded;
      case 'SYSTEM_ADMIN':
        return Icons.admin_panel_settings_rounded;
      default:
        return Icons.badge_outlined;
    }
  }
}
