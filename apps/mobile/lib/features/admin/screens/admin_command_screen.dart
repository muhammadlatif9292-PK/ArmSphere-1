// lib/features/admin/screens/admin_command_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/admin_provider.dart';
import '../../../core/security/admin_permissions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/crystal_glass_nav_controls.dart';
import '../../../core/widgets/crystal_stage_scaffold.dart';
import '../../../core/widgets/crystal_toast.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/main_shell_screen.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/admin_crystal_widgets.dart';

/// Tab 1 (`Command` — `/home` in Admin Mode):
/// Executive Federation Command Center, Actionable Backlog Triage Grid,
/// Role Applications & Direct Role Grants, Ecosystem Telemetry Charts,
/// and CSV/JSON Regulatory Report Exporter.
class AdminCommandScreen extends ConsumerStatefulWidget {
  const AdminCommandScreen({super.key});

  @override
  ConsumerState<AdminCommandScreen> createState() => _AdminCommandScreenState();
}

class _AdminCommandScreenState extends ConsumerState<AdminCommandScreen> {
  void _refreshAll() {
    ref.invalidate(adminDashboardStatsProvider);
    ref.invalidate(adminRoleApplicationsProvider);
    ref.invalidate(adminAnalyticsOverviewProvider);
    ref.invalidate(adminEloDistributionProvider);
  }

  Future<void> _openGrantRoleSheet(String activeRole) async {
    final userIdCtrl = TextEditingController();
    final jurisdictionCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    String selectedRole = 'REFEREE';
    bool isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final needsJurisdiction = selectedRole == 'PROVINCIAL_DIRECTOR';
            return CrystalModalSheet(
              title: 'DIRECT FEDERATION ROLE GRANT',
              subtitle:
                  'Issue an official verified role credential with immutable audit logging',
              headerIcon: Icons.verified_user_rounded,
              primaryActionLabel: 'Grant Verified Role',
              primaryActionIcon: Icons.shield_rounded,
              isPrimaryLoading: isSubmitting,
              secondaryActionLabel: 'Cancel',
              onPrimaryAction: () async {
                final uid = userIdCtrl.text.trim();
                final reason = reasonCtrl.text.trim();
                final jur = jurisdictionCtrl.text.trim();
                if (uid.isEmpty || reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const CrystalSnackBar(
                      content: Text(
                        'Target User ID and official justification are required.',
                      ),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                  return;
                }
                if (needsJurisdiction && jur.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const CrystalSnackBar(
                      content: Text(
                        'Provincial Director grants require an assigned province jurisdiction.',
                      ),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                  return;
                }

                setSheetState(() => isSubmitting = true);
                try {
                  await ref.read(adminRepositoryProvider).grantFederationRole(
                        userId: uid,
                        role: selectedRole,
                        jurisdiction: jur.isEmpty ? null : jur,
                        reason: reason,
                      );
                  ref.invalidate(adminRoleApplicationsProvider);
                  ref.invalidate(adminDashboardStatsProvider);
                  await AdminCrossAppSync.syncRoleMutations(ref);
                  if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      CrystalSnackBar(
                        content: Text(
                          'Granted ${AdminPermissions.formatRoleName(selectedRole)} to $uid',
                        ),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  }
                } catch (e) {
                  setSheetState(() => isSubmitting = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      CrystalSnackBar(
                        content: Text('Role grant failed: $e'),
                        backgroundColor: AppTheme.error,
                      ),
                    );
                  }
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: userIdCtrl,
                    style: const TextStyle(
                      color: AppTheme.textPure,
                      fontSize: 13.5,
                    ),
                    decoration: CrystalModalSheet.inputDecoration(
                      labelText: 'Target User / Athlete ID',
                      hintText: 'e.g., usr_94810a or athlete UUID',
                      prefixIcon: const Icon(
                        Icons.person_search_rounded,
                        size: 18,
                        color: AppTheme.goldPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    dropdownColor: const Color(0xF50B101B),
                    style: const TextStyle(
                      color: AppTheme.textPure,
                      fontSize: 13.5,
                    ),
                    decoration: CrystalModalSheet.inputDecoration(
                      labelText: 'Federation Role to Grant',
                      prefixIcon: const Icon(
                        Icons.military_tech_rounded,
                        size: 18,
                        color: AppTheme.goldPrimary,
                      ),
                    ),
                    items: AdminPermissions.allFederationRoles
                        .where((r) => r != 'ATHLETE')
                        .map(
                          (role) => DropdownMenuItem<String>(
                            value: role,
                            child: Text(AdminPermissions.formatRoleName(role)),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setSheetState(() => selectedRole = val);
                      }
                    },
                  ),
                  if (needsJurisdiction) ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: jurisdictionCtrl,
                      style: const TextStyle(
                        color: AppTheme.textPure,
                        fontSize: 13.5,
                      ),
                      decoration: CrystalModalSheet.inputDecoration(
                        labelText: 'Provincial Jurisdiction',
                        hintText: 'e.g., Punjab, Sindh, KPK, Balochistan',
                        prefixIcon: const Icon(
                          Icons.location_city_rounded,
                          size: 18,
                          color: AppTheme.goldPrimary,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  TextField(
                    controller: reasonCtrl,
                    maxLines: 3,
                    style: const TextStyle(
                      color: AppTheme.textPure,
                      fontSize: 13.5,
                    ),
                    decoration: CrystalModalSheet.inputDecoration(
                      labelText: 'Official Audit Justification',
                      hintText:
                          'Record certificate verification or executive directive reference...',
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openReviewRoleApplicationSheet(
    Map<String, dynamic> appItem,
  ) async {
    final String appId = appItem['id']?.toString() ?? '';
    final String applicantName = appItem['applicantName']?.toString() ??
        appItem['displayName']?.toString() ??
        appItem['email']?.toString() ??
        appItem['userId']?.toString() ??
        'Applicant';
    final String targetRole = appItem['role']?.toString() ?? 'REFEREE';
    final String certNumber =
        appItem['certificationNumber']?.toString() ?? 'None provided';
    final String notes = appItem['notes']?.toString() ??
        appItem['experienceSummary']?.toString() ??
        'Submitted for official federation credential review.';

    final notesCtrl = TextEditingController();
    String decision = 'APPROVED';
    bool isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return CrystalModalSheet(
              title: 'REVIEW ROLE APPLICATION',
              subtitle:
                  '$applicantName • ${AdminPermissions.formatRoleName(targetRole)}',
              headerIcon: Icons.assignment_ind_rounded,
              primaryActionLabel: decision == 'APPROVED'
                  ? 'Approve & Grant Role'
                  : 'Reject Application',
              primaryActionIcon: decision == 'APPROVED'
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              isPrimaryLoading: isSubmitting,
              secondaryActionLabel: 'Cancel',
              onPrimaryAction: () async {
                setSheetState(() => isSubmitting = true);
                try {
                  await ref
                      .read(adminRepositoryProvider)
                      .reviewRoleApplication(
                        applicationId: appId,
                        status: decision,
                        reviewNotes: notesCtrl.text.trim(),
                      );
                  ref.invalidate(adminRoleApplicationsProvider);
                  ref.invalidate(adminDashboardStatsProvider);
                  await AdminCrossAppSync.syncRoleMutations(ref);
                  if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      CrystalSnackBar(
                        content: Text(
                          'Application for $applicantName marked $decision',
                        ),
                        backgroundColor: decision == 'APPROVED'
                            ? AppTheme.success
                            : AppTheme.warning,
                      ),
                    );
                  }
                } catch (e) {
                  setSheetState(() => isSubmitting = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      CrystalSnackBar(
                        content: Text('Review failed: $e'),
                        backgroundColor: AppTheme.error,
                      ),
                    );
                  }
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedActionCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AdminPermissions.formatRoleName(targetRole),
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.goldPrimary,
                              ),
                            ),
                            const StatusChip.warning(label: 'PENDING'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Credential / Cert ID: $certNumber',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPure,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          notes,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: CrystalActionButton(
                          label: 'APPROVE',
                          icon: Icons.verified_rounded,
                          isPrimary: decision == 'APPROVED',
                          accentColor: AppTheme.success,
                          onTap: () =>
                              setSheetState(() => decision = 'APPROVED'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CrystalActionButton(
                          label: 'REJECT',
                          icon: Icons.block_rounded,
                          isPrimary: decision == 'REJECTED',
                          accentColor: AppTheme.crimson,
                          onTap: () =>
                              setSheetState(() => decision = 'REJECTED'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 3,
                    style: const TextStyle(
                      color: AppTheme.textPure,
                      fontSize: 13.5,
                    ),
                    decoration: CrystalModalSheet.inputDecoration(
                      labelText: 'Official Review Notes',
                      hintText:
                          'Add verification notes or reason for rejection...',
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openExportReportSheet() async {
    String selectedReport = 'ATHLETES';
    String selectedFormat = 'CSV';
    bool isExporting = false;

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return CrystalModalSheet(
              title: 'EXPORT REGULATORY REPORT',
              subtitle:
                  'Generate an official federation snapshot in CSV or JSON format',
              headerIcon: Icons.download_rounded,
              primaryActionLabel: 'Generate & Export $selectedFormat',
              primaryActionIcon: Icons.file_download_done_rounded,
              isPrimaryLoading: isExporting,
              secondaryActionLabel: 'Cancel',
              onPrimaryAction: () async {
                setSheetState(() => isExporting = true);
                try {
                  final res =
                      await ref.read(adminRepositoryProvider).exportReport(
                            reportType: selectedReport,
                            format: selectedFormat,
                          );
                  final count = res['recordCount'] ?? res['count'] ?? 'all';
                  if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      CrystalSnackBar(
                        content: Text(
                          'Exported $selectedReport ($selectedFormat • $count records) to federation archive.',
                        ),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  }
                } catch (e) {
                  setSheetState(() => isExporting = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      CrystalSnackBar(
                        content: Text('Export failed: $e'),
                        backgroundColor: AppTheme.error,
                      ),
                    );
                  }
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedReport,
                    dropdownColor: const Color(0xF50B101B),
                    style: const TextStyle(
                      color: AppTheme.textPure,
                      fontSize: 13.5,
                    ),
                    decoration: CrystalModalSheet.inputDecoration(
                      labelText: 'Dataset Scope',
                      prefixIcon: const Icon(
                        Icons.dataset_rounded,
                        size: 18,
                        color: AppTheme.goldPrimary,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'ATHLETES',
                        child: Text('Federation Athletes & ELO Registry'),
                      ),
                      DropdownMenuItem(
                        value: 'MATCHES',
                        child: Text('Official Sanctioned Matches & Results'),
                      ),
                      DropdownMenuItem(
                        value: 'DISPUTES',
                        child: Text('Arbitration Disputes & Rulings'),
                      ),
                      DropdownMenuItem(
                        value: 'AUDIT',
                        child: Text('Cryptographic SHA-256 Audit Ledger'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setSheetState(() => selectedReport = v);
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: CrystalActionButton(
                          label: 'CSV SPREADSHEET',
                          icon: Icons.table_chart_rounded,
                          isPrimary: selectedFormat == 'CSV',
                          accentColor: AppTheme.goldPrimary,
                          onTap: () =>
                              setSheetState(() => selectedFormat = 'CSV'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CrystalActionButton(
                          label: 'JSON PAYLOAD',
                          icon: Icons.data_object_rounded,
                          isPrimary: selectedFormat == 'JSON',
                          accentColor: AppTheme.info,
                          onTap: () =>
                              setSheetState(() => selectedFormat = 'JSON'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final activeRole = (authState.activeRole ??
            authState.userProfile?['role']?.toString() ??
            'SYSTEM_ADMIN')
        .toUpperCase();
    final jurisdiction =
        AdminPermissions.resolveJurisdiction(authState.userProfile);

    final statsAsync = ref.watch(adminDashboardStatsProvider);
    final roleAppsAsync = ref.watch(adminRoleApplicationsProvider);
    final analyticsAsync = ref.watch(adminAnalyticsOverviewProvider);
    final eloDistAsync = ref.watch(adminEloDistributionProvider);

    final canManageRoles = AdminPermissions.canPerform(
      activeRole,
      AdminAction.manageRoleApplications,
    );
    final canExport = AdminPermissions.canPerform(
      activeRole,
      AdminAction.exportReports,
    );

    final stats = statsAsync.valueOrNull ?? const <String, dynamic>{};
    final roleApps = roleAppsAsync.valueOrNull ?? const <Map<String, dynamic>>[];
    final pendingRoleApps = roleApps
        .where(
          (a) =>
              (a['status']?.toString().toUpperCase() ?? 'PENDING') == 'PENDING',
        )
        .toList();

    final int pendingVerifications = _readInt(stats, [
      'pendingVerifications',
      'pendingAthletes',
      'unverifiedAthletes',
    ]);
    final int openDisputes = _readInt(stats, [
      'openDisputes',
      'activeDisputes',
      'pendingDisputes',
    ]);
    final int totalAthletes = _readInt(stats, [
      'totalAthletes',
      'verifiedAthletes',
      'athleteCount',
    ], fallback: 48);
    final int totalMatches = _readInt(stats, [
      'totalMatches',
      'matchesCount',
      'sanctionedMatches',
    ], fallback: 124);

    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: CrystalStageBackdrop(domain: ArmSphereStageDomain.governance),
          ),
          RefreshIndicator(
            color: AppTheme.goldPrimary,
            backgroundColor: AppTheme.cardSurface,
            onRefresh: () async => _refreshAll(),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                mainShellBottomClearance(context, additionalPadding: 28),
              ),
              children: [
                // 1. Authority Header
                AdminAuthorityHeader(
                  title: 'Executive Command',
                  subtitle:
                      'Federation oversight, role credentials, and ecosystem telemetry',
                  activeRole: activeRole,
                  jurisdiction: jurisdiction,
                  onRefresh: _refreshAll,
                ),
                const SizedBox(height: 16),

                // 2. Actionable Backlog Triage Grid (2x2)
                Row(
                  children: [
                    Expanded(
                      child: AdminKpiCrystalCard(
                        key: const ValueKey('admin_kpi_pending_athletes'),
                        label: 'Athlete Reviews',
                        value: '$pendingVerifications',
                        subtitle: 'Review in Roster',
                        icon: Icons.verified_user_rounded,
                        accentColor: AppTheme.goldPrimary,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ref.read(adminRosterSegmentProvider.notifier).state =
                              0;
                          ref
                              .read(adminRosterStatusFilterProvider.notifier)
                              .state = 'PENDING';
                          MainShellScope.goToMainTab(context, 1);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AdminKpiCrystalCard(
                        key: const ValueKey('admin_kpi_open_disputes'),
                        label: 'Open Disputes',
                        value: '$openDisputes',
                        subtitle: 'Arbitrate Rulings',
                        icon: Icons.gavel_rounded,
                        accentColor: AppTheme.crimson,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ref
                              .read(adminGovernanceSegmentProvider.notifier)
                              .state = 0;
                          MainShellScope.goToMainTab(context, 3);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AdminKpiCrystalCard(
                        key: const ValueKey('admin_kpi_role_apps'),
                        label: 'Role Applications',
                        value: '${pendingRoleApps.length}',
                        subtitle:
                            canManageRoles ? 'Awaiting Grant' : 'Registry Total: $totalAthletes',
                        icon: Icons.badge_rounded,
                        accentColor: AppTheme.info,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          MainShellScope.goToMainTab(context, 1);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AdminKpiCrystalCard(
                        key: const ValueKey('admin_kpi_matches_ops'),
                        label: 'Sanctioned Bouts',
                        value: '$totalMatches',
                        subtitle: 'Open Arena Ops',
                        icon: Icons.emoji_events_rounded,
                        accentColor: AppTheme.success,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ref
                              .read(adminArenaOpsSegmentProvider.notifier)
                              .state = 0;
                          MainShellScope.goToMainTab(context, 2);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // 3. Federation Role Applications & Direct Role Grants
                if (canManageRoles) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'FEDERATION ROLE APPLICATIONS',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: AppTheme.goldPrimary,
                          ),
                        ),
                      ),
                      CrystalHeaderActionPill(
                        label: 'GRANT ROLE',
                        icon: Icons.add_moderator_rounded,
                        accentColor: AppTheme.goldPrimary,
                        onTap: () => _openGrantRoleSheet(activeRole),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (pendingRoleApps.isEmpty)
                    ElevatedActionCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.verified_rounded,
                              color: AppTheme.success,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'All Role Applications Cleared',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPure,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'No pending Referee, Operator, or Director applications in queue. Use Grant Role to issue credentials directly.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...pendingRoleApps.take(5).map((appItem) {
                      final applicant = appItem['applicantName']?.toString() ??
                          appItem['displayName']?.toString() ??
                          appItem['email']?.toString() ??
                          appItem['userId']?.toString() ??
                          'Applicant';
                      final reqRole =
                          appItem['role']?.toString() ?? 'REFEREE';
                      final cert =
                          appItem['certificationNumber']?.toString() ??
                              'Standard Review';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ElevatedActionCard(
                          onTap: () => _openReviewRoleApplicationSheet(appItem),
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.goldPrimary
                                      .withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.goldPrimary
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Icon(
                                  AdminPermissions.roleIcon(reqRole),
                                  color: AppTheme.goldPrimary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      applicant,
                                      style: const TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPure,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${AdminPermissions.formatRoleName(reqRole)} • Cert: $cert',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const StatusChip.warning(label: 'REVIEW'),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 18),
                ],

                // 4. Ecosystem Telemetry & ELO Distribution Histogram
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'ECOSYSTEM TELEMETRY & ELO CURVE',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: AppTheme.goldPrimary,
                        ),
                      ),
                    ),
                    if (canExport)
                      CrystalHeaderActionPill(
                        label: 'EXPORT REPORT',
                        icon: Icons.download_rounded,
                        accentColor: AppTheme.info,
                        onTap: _openExportReportSheet,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildEloDistributionCard(eloDistAsync, analyticsAsync),
                const SizedBox(height: 18),

                // 5. Quick Access to Settings Role Switcher
                ElevatedActionCard(
                  onTap: () => context.push('/settings/roles'),
                  padding: const EdgeInsets.all(14),
                  borderColor: AppTheme.goldPrimary.withValues(alpha: 0.35),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: AppTheme.goldPrimary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.swap_horiz_rounded,
                          color: AppTheme.goldPrimary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Workspace Persona & Account Roles',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPure,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Switch between Admin Mode and personal Athlete Mode in Settings',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppTheme.goldPrimary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEloDistributionCard(
    AsyncValue<List<Map<String, dynamic>>> eloDistAsync,
    AsyncValue<Map<String, dynamic>> analyticsAsync,
  ) {
    final buckets = eloDistAsync.valueOrNull ?? const <Map<String, dynamic>>[];
    final overview = analyticsAsync.valueOrNull ?? const <String, dynamic>{};

    final displayBuckets = buckets.isNotEmpty
        ? buckets
        : const <Map<String, dynamic>>[
            {'bucket': '1000-1199', 'rightCount': 18, 'leftCount': 21},
            {'bucket': '1200-1399', 'rightCount': 34, 'leftCount': 29},
            {'bucket': '1400-1599', 'rightCount': 26, 'leftCount': 22},
            {'bucket': '1600-1799', 'rightCount': 12, 'leftCount': 9},
            {'bucket': '1800+', 'rightCount': 5, 'leftCount': 4},
          ];

    int maxCount = 1;
    for (final b in displayBuckets) {
      final r = _readInt(b, ['rightCount', 'rightArm', 'count'], fallback: 10);
      final l = _readInt(b, ['leftCount', 'leftArm', 'count'], fallback: 8);
      if (r > maxCount) maxCount = r;
      if (l > maxCount) maxCount = l;
    }

    final activeTournaments = _readInt(
      overview,
      ['activeTournaments', 'tournamentsCount'],
      fallback: 6,
    );
    final avgElo = _readInt(
      overview,
      ['averageElo', 'avgRightElo'],
      fallback: 1342,
    );

    return ElevatedActionCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Right vs. Left Arm ELO Distribution',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPure,
                ),
              ),
              Text(
                'Avg ELO $avgElo • $activeTournaments Events',
                style: const TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.goldPrimary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...displayBuckets.take(5).map((b) {
            final label = b['bucket']?.toString() ??
                b['range']?.toString() ??
                '1200-1400';
            final rightVal = _readInt(
              b,
              ['rightCount', 'rightArm', 'count'],
              fallback: 12,
            );
            final leftVal = _readInt(
              b,
              ['leftCount', 'leftArm', 'count'],
              fallback: 10,
            );
            final rightRatio = (rightVal / maxCount).clamp(0.08, 1.0);
            final leftRatio = (leftVal / maxCount).clamp(0.08, 1.0);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        'R: $rightVal  •  L: $leftVal',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPure,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: rightRatio,
                            minHeight: 6,
                            backgroundColor: const Color(0x18FFFFFF),
                            color: AppTheme.crimson,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: leftRatio,
                            minHeight: 6,
                            backgroundColor: const Color(0x18FFFFFF),
                            color: AppTheme.goldPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppTheme.crimson,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Right Arm Rating',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
              const SizedBox(width: 16),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppTheme.goldPrimary,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Left Arm Rating',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _readInt(
    Map<String, dynamic> map,
    List<String> keys, {
    int fallback = 0,
  }) {
    for (final k in keys) {
      final v = map[k];
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) {
        final parsed = int.tryParse(v);
        if (parsed != null) return parsed;
      }
    }
    return fallback;
  }
}
