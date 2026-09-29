import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/app_empty_state.dart';
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
    switch (role) {
      case 'ATHLETE':
        return 'Athlete';
      case 'REFEREE':
        return 'Certified Referee';
      case 'TOURNAMENT_OPERATOR':
        return 'Tournament Operator';
      case 'SYSTEM_ADMIN':
        return 'System Administrator';
      default:
        return role;
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'ATHLETE':
        return Icons.fitness_center;
      case 'REFEREE':
        return Icons.sports;
      case 'TOURNAMENT_OPERATOR':
        return Icons.table_chart;
      case 'SYSTEM_ADMIN':
        return Icons.security;
      default:
        return Icons.badge_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final verifiedRoles = authState.verifiedRoles;
    final activeRole = authState.activeRole ?? (verifiedRoles.isNotEmpty ? verifiedRoles.first : 'ATHLETE');
    final pendingApplications = authState.pendingRoleApplications;

    return Scaffold(
      appBar: AppBar(
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
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(authProvider.notifier).refreshUserRoles();
        },
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.space16),
          children: [
            // Current Active Persona Callout
            ElevatedActionCard(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.space10),
                        decoration: BoxDecoration(
                          color: AppTheme.goldPrimary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
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
                            const Text(
                              'Active Client Persona',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
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
                          ],
                        ),
                      ),
                      const StatusChip.success(
                        label: 'Active',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space12),
                  const Text(
                    'Your active persona determines which workspace and navigation dashboard is presented. Server authorization is strictly authoritative and never trusts client claims.',
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
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.cardBorder),
                  itemBuilder: (context, index) {
                    final role = verifiedRoles[index];
                    final isCurrentActive = role == activeRole;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space16,
                        vertical: AppTheme.space4,
                      ),
                      leading: Icon(
                        _roleIcon(role),
                        color: isCurrentActive ? AppTheme.goldPrimary : AppTheme.textSecondary,
                      ),
                      title: Text(
                        _formatRoleName(role),
                        style: TextStyle(
                          fontWeight: isCurrentActive ? FontWeight.bold : FontWeight.w600,
                          color: isCurrentActive ? AppTheme.textPrimary : AppTheme.textSecondary,
                        ),
                      ),
                      subtitle: Text(
                        isCurrentActive ? 'Current Active Persona' : 'Verified federation grant',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      trailing: isCurrentActive
                          ? const Icon(Icons.check_circle, color: AppTheme.success, size: 22)
                          : TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () async {
                                      HapticFeedback.lightImpact();
                                      setState(() => _isLoading = true);
                                      try {
                                        await ref.read(authProvider.notifier).switchActiveRole(role);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Switched persona to ${_formatRoleName(role)}'),
                                              backgroundColor: AppTheme.goldPrimary,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(e.toString()),
                                              backgroundColor: AppTheme.error,
                                            ),
                                          );
                                        }
                                      } finally {
                                        if (mounted) setState(() => _isLoading = false);
                                      }
                                    },
                              child: const Text('Switch'),
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
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              )
            else
              ElevatedActionCard(
                padding: EdgeInsets.zero,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pendingApplications.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.cardBorder),
                  itemBuilder: (context, index) {
                    final app = pendingApplications[index];
                    final appRole = app['role']?.toString() ?? 'ROLE';
                    final certNum = app['certificationNumber']?.toString();

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space16,
                        vertical: AppTheme.space4,
                      ),
                      leading: const Icon(Icons.pending_actions, color: AppTheme.warning),
                      title: Text(
                        _formatRoleName(appRole),
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                      ),
                      subtitle: Text(
                        certNum != null && certNum.isNotEmpty
                            ? 'Cert: $certNum'
                            : 'Submitted for federation review',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      trailing: const StatusChip.warning(
                        label: 'PENDING',
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: AppTheme.space32),

            // Action: Apply for Role
            ElevatedButton.icon(
              onPressed: () => context.push('/settings/roles/apply'),
              icon: const Icon(Icons.add_moderator),
              label: const Text('Apply for Federation Role'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.space14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.space16),
          ],
        ),
      ),
    );
  }
}
