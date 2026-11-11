// lib/features/settings/screens/account_roles_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/security/admin_permissions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/crystal_glass_nav_controls.dart';
import '../../../core/widgets/crystal_stage_scaffold.dart';
import '../../../core/widgets/crystal_toast.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/main_shell_screen.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/providers/auth_provider.dart';

class AccountRolesScreen extends ConsumerStatefulWidget {
  const AccountRolesScreen({super.key});

  @override
  ConsumerState<AccountRolesScreen> createState() => _AccountRolesScreenState();
}

class _AccountRolesScreenState extends ConsumerState<AccountRolesScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).refreshUserRoles();
    });
  }

  String _formatRoleName(String role) {
    return AdminPermissions.formatRoleName(role);
  }

  String _roleContextDescription(String role) {
    return AdminPermissions.roleContextDescription(role);
  }

  IconData _roleIcon(String role) {
    return AdminPermissions.roleIcon(role);
  }

  Future<void> _confirmAndSwitchRole(
    String targetRole,
    String currentActiveRole,
  ) async {
    if (targetRole == currentActiveRole) return;
    if (_isLoading) return;

    HapticFeedback.lightImpact();
    final bool isTargetAdmin = AdminPermissions.isAdminWorkspaceRole(targetRole);

    final confirm = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CrystalModalSheet(
        title: 'Switch to ${_formatRoleName(targetRole)}?',
        subtitle: isTargetAdmin
            ? 'Activates 5-Tab Native Admin Dock (Command, Roster, Arena Ops, Governance, Dossier)'
            : 'Activates Standard Athlete Workspace & Navigation Dock',
        headerIcon: _roleIcon(targetRole),
        primaryActionLabel: 'Switch Role',
        primaryActionIcon: Icons.swap_horiz_rounded,
        secondaryActionLabel: 'Cancel',
        onPrimaryAction: () => Navigator.of(ctx).pop(true),
        onSecondaryAction: () => Navigator.of(ctx).pop(false),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _roleContextDescription(targetRole),
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppTheme.space12),
            Container(
              padding: const EdgeInsets.all(AppTheme.space12),
              decoration: BoxDecoration(
                color: AppTheme.elevatedSurface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppTheme.goldPrimary,
                  ),
                  const SizedBox(width: AppTheme.space8),
                  Expanded(
                    child: Text(
                      'Currently active: ${_formatRoleName(currentActiveRole)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).switchActiveRole(targetRole);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CrystalSnackBar(
            content: Text('Switched persona to ${_formatRoleName(targetRole)}'),
            backgroundColor: AppTheme.goldPrimary,
          ),
        );
        // Navigate cleanly to the home root tab so the newly selected Athlete
        // or Admin 5-tab workspace is immediately visible starting at the top.
        final router = GoRouter.maybeOf(context);
        if (router != null) {
          router.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CrystalSnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final rawVerified = authState.verifiedRoles;
    final bool hasAthleteEligibility = rawVerified.contains('ATHLETE') ||
        authState.userProfile?['isOnboarded'] == true ||
        authState.userProfile?['profile'] != null;

    final List<String> verifiedRoles = rawVerified.isEmpty
        ? (hasAthleteEligibility ? const <String>['ATHLETE'] : const <String>[])
        : (rawVerified.contains('ATHLETE') || !hasAthleteEligibility
            ? rawVerified
            : <String>['ATHLETE', ...rawVerified]);

    final activeRole = authState.activeRole ??
        (verifiedRoles.isNotEmpty ? verifiedRoles.first : 'ATHLETE');
    final pendingApplications = authState.pendingRoleApplications;
    final bool isInAdminMode = AdminPermissions.isAdminWorkspaceRole(activeRole);
    final String? jurisdiction =
        AdminPermissions.resolveJurisdiction(authState.userProfile);

    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        flexibleSpace:
            const CrystalHeaderStageBar(domain: ArmSphereStageDomain.passport),
        leading: const CrystalBackButton(),
        title: const Text('Account Roles & Persona'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              HapticFeedback.lightImpact();
              await ref.read(authProvider.notifier).refreshUserRoles();
            },
            tooltip: 'Refresh Roles',
          ),
          const CrystalHomeButton(),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: CrystalStageBackdrop(domain: ArmSphereStageDomain.passport),
          ),
          RefreshIndicator(
            onRefresh: () async {
              await ref.read(authProvider.notifier).refreshUserRoles();
            },
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                AppTheme.space16,
                MediaQuery.paddingOf(context).top + kToolbarHeight + AppTheme.space16,
                AppTheme.space16,
                MainShellScope.isInsideShell(context)
                    ? MainShellScope.bottomClearance(
                        context,
                        additionalPadding: 36,
                      )
                    : kFloatingDockTotalHeight +
                        MediaQuery.paddingOf(context).bottom +
                        36,
              ),
              children: [
                // Current Active Persona Callout
                ElevatedActionCard(
                  padding: const EdgeInsets.all(AppTheme.space16),
                  borderColor: isInAdminMode
                      ? const Color(0x80E23B3B)
                      : const Color(0x73D4AF37),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppTheme.space10),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0x73D4AF37),
                                width: 1.0,
                              ),
                            ),
                            child: Icon(
                              _roleIcon(activeRole),
                              color: AppTheme.goldPrimary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppTheme.space12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isInAdminMode
                                      ? 'Active Client Persona • ADMIN MODE'
                                      : 'Active Client Persona • ATHLETE MODE',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.goldPrimary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatRoleName(activeRole),
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                if (jurisdiction != null &&
                                    activeRole.toUpperCase() ==
                                        'PROVINCIAL_DIRECTOR') ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Assigned Province: $jurisdiction',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.goldLight,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const StatusChip.success(label: 'Active'),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space12),
                      const Text(
                        'Your active persona determines whether the 5-tab bottom navigation bar presents Athlete Mode (Arena, Discover, Events, Community, Passport) or Admin Mode (Command, Roster, Arena Ops, Governance, Dossier). Server authorization is strictly authoritative.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space24),

                // Section: Verified Roles
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'VERIFIED ROLES (${verifiedRoles.length})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space10),

                if (verifiedRoles.isEmpty)
                  const ElevatedActionCard(
                    padding: EdgeInsets.all(AppTheme.space16),
                    child: Text(
                      'No verified roles found for this account.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  )
                else
                  ElevatedActionCard(
                    padding: EdgeInsets.zero,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: verifiedRoles.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, thickness: 1, color: Color(0x22FFFFFF)),
                      itemBuilder: (context, index) {
                        final role = verifiedRoles[index];
                        final isCurrentActive =
                            role.toUpperCase() == activeRole.toUpperCase();
                        final isAdminRole =
                            AdminPermissions.isAdminWorkspaceRole(role);

                        return Material(
                          type: MaterialType.transparency,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.space16,
                              vertical: AppTheme.space4,
                            ),
                            onTap: (isCurrentActive || _isLoading)
                                ? null
                                : () =>
                                    _confirmAndSwitchRole(role, activeRole),
                            leading: Icon(
                              _roleIcon(role),
                              color: isCurrentActive
                                  ? AppTheme.goldPrimary
                                  : AppTheme.textSecondary,
                            ),
                            title: Text(
                              _formatRoleName(role),
                              style: TextStyle(
                                fontWeight: isCurrentActive
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: isCurrentActive
                                    ? AppTheme.textPrimary
                                    : AppTheme.textSecondary,
                              ),
                            ),
                            subtitle: Text(
                              isCurrentActive
                                  ? 'Current Active Persona'
                                  : (isAdminRole
                                      ? 'Admin Workspace Mode (5 Admin Tabs)'
                                      : 'Verified federation grant'),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            trailing: isCurrentActive
                                ? const Icon(
                                    Icons.check_circle,
                                    color: AppTheme.success,
                                    size: 22,
                                  )
                                : TextButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () => _confirmAndSwitchRole(
                                              role,
                                              activeRole,
                                            ),
                                    child: const Text('Switch'),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: AppTheme.space24),

                // Section: Pending Role Applications
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PENDING APPLICATIONS (${pendingApplications.length})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space10),

                if (pendingApplications.isEmpty)
                  const ElevatedActionCard(
                    padding: EdgeInsets.all(AppTheme.space16),
                    child: Text(
                      'No pending role applications.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  )
                else
                  ElevatedActionCard(
                    padding: EdgeInsets.zero,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pendingApplications.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, thickness: 1, color: Color(0x22FFFFFF)),
                      itemBuilder: (context, index) {
                        final app = pendingApplications[index];
                        final appRole = app['role']?.toString() ?? 'ROLE';
                        final certNum =
                            app['certificationNumber']?.toString();

                        return Material(
                          type: MaterialType.transparency,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.space16,
                              vertical: AppTheme.space4,
                            ),
                            leading: const Icon(
                              Icons.pending_actions,
                              color: AppTheme.warning,
                            ),
                            title: Text(
                              _formatRoleName(appRole),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              certNum != null && certNum.isNotEmpty
                                  ? 'Cert: $certNum'
                                  : 'Submitted for federation review',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            trailing: const StatusChip.warning(
                              label: 'PENDING',
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: AppTheme.space32),

                // Action: Apply for Role
                CrystalActionButton(
                  label: 'Apply for Federation Role',
                  icon: Icons.add_moderator_rounded,
                  fullWidth: true,
                  accentColor: AppTheme.goldPrimary,
                  onTap: () => context.push('/settings/roles/apply'),
                ),
                const SizedBox(height: AppTheme.space16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
