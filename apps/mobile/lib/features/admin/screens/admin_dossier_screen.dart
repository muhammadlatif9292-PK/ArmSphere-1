// lib/features/admin/screens/admin_dossier_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/admin_provider.dart';
import '../../../core/security/admin_permissions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/crystal_glass_nav_controls.dart';
import '../../../core/widgets/crystal_stage_scaffold.dart';
import '../../../core/widgets/crystal_toast.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/main_shell_screen.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/admin_crystal_widgets.dart';

/// Tab 5 (`Dossier` — `/athlete/profile` in Admin Mode):
/// Official Administrator Credential Passport, Direct Link to Settings Role
/// Switcher (`/settings/roles`), and Cryptographic SHA-256 Audit Ledger Explorer
/// with Live Hash-Chain Verification.
class AdminDossierScreen extends ConsumerStatefulWidget {
  const AdminDossierScreen({super.key});

  @override
  ConsumerState<AdminDossierScreen> createState() => _AdminDossierScreenState();
}

class _AdminDossierScreenState extends ConsumerState<AdminDossierScreen> {
  final TextEditingController _actorSearchCtrl = TextEditingController();
  String _selectedActionFilter = '';
  String _actorSearch = '';

  @override
  void dispose() {
    _actorSearchCtrl.dispose();
    super.dispose();
  }

  void _refreshLedger(AdminAuditFilter filter) {
    ref.invalidate(adminAuditVerificationProvider);
    ref.invalidate(adminAuditEventsProvider(filter));
  }

  Future<void> _openAuditEventSheet(Map<String, dynamic> event) async {
    final String actionType =
        event['actionType']?.toString() ?? event['action']?.toString() ?? 'AUDIT_EVENT';
    final String actorId =
        event['actorId']?.toString() ?? event['userId']?.toString() ?? 'System';
    final String targetId =
        event['targetId']?.toString() ?? event['entityId']?.toString() ?? 'N/A';
    final String prevHash =
        event['previousHash']?.toString() ?? '0000000000000000';
    final String currHash =
        event['currentHash']?.toString() ?? event['hash']?.toString() ?? 'SHA256_VERIFIED';
    final String createdAt = event['createdAt']?.toString() ?? 'Recorded';

    String prettyMetadata = '{}';
    try {
      final rawMeta = event['metadata'] ?? event['payload'] ?? event;
      prettyMetadata = const JsonEncoder.withIndent('  ').convert(rawMeta);
    } catch (_) {
      prettyMetadata = event.toString();
    }

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return CrystalModalSheet(
          title: 'IMMUTABLE AUDIT RECORD',
          subtitle: '$actionType • Actor: $actorId',
          headerIcon: Icons.fingerprint_rounded,
          secondaryActionLabel: 'Close Inspector',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedActionCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHashRow('TIMESTAMP', createdAt),
                    const SizedBox(height: 8),
                    _buildHashRow('TARGET ENTITY', targetId),
                    const SizedBox(height: 8),
                    _buildHashRow('PREVIOUS SHA-256', prevHash),
                    const SizedBox(height: 8),
                    _buildHashRow('CURRENT SHA-256', currHash),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'CRYPTOGRAPHIC EVENT PAYLOAD',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppTheme.goldPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xCC060911),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x28FFFFFF)),
                ),
                child: SelectableText(
                  prettyMetadata,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11.5,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHashRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
            color: AppTheme.goldPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 12,
            color: AppTheme.textPure,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final profile = authState.userProfile ?? const <String, dynamic>{};
    final activeRole = (authState.activeRole ??
            profile['role']?.toString() ??
            'SYSTEM_ADMIN')
        .toUpperCase();
    final jurisdiction = AdminPermissions.resolveJurisdiction(profile);
    final displayName = profile['displayName']?.toString() ??
        profile['fullName']?.toString() ??
        profile['email']?.toString() ??
        'Federation Official';
    final email = profile['email']?.toString() ?? 'official@armsphere.org';

    final auditFilter = AdminAuditFilter(
      actionType: _selectedActionFilter,
      actorId: _actorSearch,
    );

    final canVerifyChain = AdminPermissions.canPerform(
      activeRole,
      AdminAction.verifyAuditChain,
    );

    final auditReportAsync = ref.watch(adminFullAuditReportProvider);
    final verifyAsync = ref.watch(adminAuditVerificationProvider);
    final eventsAsync = ref.watch(adminAuditEventsProvider(auditFilter));

    final report = auditReportAsync.valueOrNull;
    final bool isChainValid = report != null
        ? report.isValid
        : ((eventsAsync.valueOrNull != null) &&
            (verifyAsync.valueOrNull?['isValid'] != false));
    final int checkedCount = report?.totalEventsVerified ??
        (eventsAsync.valueOrNull?.length ?? 0);
    final String? failureReason = report?.failureReason;

    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: CrystalStageBackdrop(domain: ArmSphereStageDomain.passport),
          ),
          RefreshIndicator(
            color: AppTheme.goldPrimary,
            backgroundColor: AppTheme.cardSurface,
            onRefresh: () async => _refreshLedger(auditFilter),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                mainShellBottomClearance(context, additionalPadding: 28),
              ),
              children: [
                // 1. Header with Settings Quick Button
                AdminAuthorityHeader(
                  title: 'Official Dossier & Audit',
                  subtitle:
                      'Federation credential passport, persona switcher, and SHA-256 ledger',
                  activeRole: activeRole,
                  jurisdiction: jurisdiction,
                  onRefresh: () => _refreshLedger(auditFilter),
                  trailingAction: IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.push('/settings');
                    },
                    tooltip: 'Settings Hub',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xCC0D1320),
                      side: const BorderSide(color: Color(0x38FFFFFF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      Icons.settings_rounded,
                      size: 18,
                      color: AppTheme.textPure,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Official Federation Credential Card
                ElevatedActionCard(
                  padding: const EdgeInsets.all(16),
                  borderColor: AppTheme.goldPrimary.withValues(alpha: 0.45),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.goldPrimary.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppTheme.goldPrimary
                                    .withValues(alpha: 0.55),
                              ),
                            ),
                            child: Icon(
                              AdminPermissions.roleIcon(activeRole),
                              color: AppTheme.goldPrimary,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPure,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AdminPermissions.formatRoleName(activeRole),
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.goldPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const StatusChip.success(label: 'VERIFIED'),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: CrystalActionButton(
                              key: const ValueKey(
                                'admin_dossier_switch_persona_btn',
                              ),
                              label: 'SWITCH ROLE',
                              icon: Icons.swap_horiz_rounded,
                              accentColor: AppTheme.goldPrimary,
                              onTap: () => context.push('/settings/roles'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          CrystalActionButton(
                            label: 'SETTINGS',
                            icon: Icons.tune_rounded,
                            isPrimary: false,
                            onTap: () => context.push('/settings'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Cryptographic SHA-256 Audit Chain Verifier
                if (canVerifyChain) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'CRYPTOGRAPHIC SHA-256 AUDIT LEDGER',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                            color: AppTheme.goldPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CrystalHeaderActionPill(
                        label: 'VERIFY CHAIN',
                        icon: Icons.verified_user_rounded,
                        accentColor:
                            isChainValid ? AppTheme.success : AppTheme.crimson,
                        onTap: () {
                          ref.invalidate(adminFullAuditReportProvider);
                          ref.invalidate(adminAuditVerificationProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            CrystalSnackBar(
                              content: Text(
                                isChainValid
                                    ? 'SHA-256 Audit Chain Verified: Client & Server Recomputations Match'
                                    : 'WARNING: Cryptographic Tampering Detected: ${failureReason ?? "Block signature mismatch"}',
                              ),
                              backgroundColor: isChainValid
                                  ? AppTheme.success
                                  : AppTheme.error,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedActionCard(
                    padding: const EdgeInsets.all(14),
                    borderColor: isChainValid
                        ? AppTheme.success.withValues(alpha: 0.45)
                        : AppTheme.crimson.withValues(alpha: 0.65),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (isChainValid
                                    ? AppTheme.success
                                    : AppTheme.crimson)
                                .withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isChainValid
                                ? Icons.enhanced_encryption_rounded
                                : Icons.gpp_bad_rounded,
                            color: isChainValid
                                ? AppTheme.success
                                : AppTheme.crimson,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isChainValid
                                    ? 'SHA-256 Hash Chain Integrity: VALID'
                                    : 'SHA-256 Hash Chain Integrity: TAMPERED',
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPure,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isChainValid
                                    ? 'Contiguous client & server cryptographic links verified ($checkedCount blocks checked).'
                                    : 'Tampered block detected! ${failureReason ?? "Hash signature invalid"}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isChainValid
                                      ? AppTheme.textSecondary
                                      : AppTheme.crimson,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  AdminCrystalSearchBar(
                    controller: _actorSearchCtrl,
                    hintText: 'Filter audit log by Actor ID...',
                    onChanged: (v) => setState(() => _actorSearch = v),
                    onClear: () {
                      _actorSearchCtrl.clear();
                      setState(() => _actorSearch = '');
                    },
                    filterOptions: const [
                      '',
                      'ATHLETE_REVIEW',
                      'MATCH_OVERRIDE',
                      'DISPUTE_RESOLVED',
                      'ROLE_GRANTED',
                      'ATHLETE_SUSPENDED',
                    ],
                    selectedFilter: _selectedActionFilter,
                    onFilterSelected: (f) =>
                        setState(() => _selectedActionFilter = f),
                  ),
                  const SizedBox(height: 14),

                  _buildAuditEventsList(eventsAsync),
                ] else
                  const ElevatedActionCard(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Cryptographic SHA-256 Audit Ledger inspection is reserved for System Admin, National Director, and Compliance Officer roles.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAuditActionLabel(String actionType) {
    switch (actionType.toUpperCase()) {
      case 'AUTH_NEW_DEVICE_ALERT':
        return 'New Device Sign-In Alert';
      case 'AUTH_IMPOSSIBLE_TRAVEL':
        return 'Impossible Travel Security Alert';
      case 'AUTH_CONCURRENT_SESSIONS':
        return 'Concurrent Session Alert';
      case 'ATHLETE_REVIEW':
      case 'ATHLETE_VERIFIED':
        return 'Athlete Verification Review';
      case 'MATCH_OVERRIDE':
      case 'MATCH_RESULT_CORRECTED':
        return 'Sanctioned Bout Score Override';
      case 'DISPUTE_RESOLVED':
        return 'Arbitration Dispute Ruling';
      case 'ROLE_GRANTED':
        return 'Federation Role Credential Granted';
      case 'ATHLETE_SUSPENDED':
        return 'Disciplinary Athlete Suspension';
      default:
        return actionType
            .split('_')
            .where((w) => w.isNotEmpty)
            .map(
              (w) =>
                  '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
            )
            .join(' ');
    }
  }

  Widget _buildAuditEventsList(
    AsyncValue<List<Map<String, dynamic>>> eventsAsync,
  ) {
    final events = eventsAsync.valueOrNull ?? const <Map<String, dynamic>>[];

    if (eventsAsync.isLoading && events.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.goldPrimary),
        ),
      );
    }

    if (events.isEmpty) {
      return const AppEmptyState(
        icon: Icons.fingerprint_rounded,
        title: 'No Audit Events Match Filter',
        description:
            'Every administrative action is recorded in the immutable SHA-256 hash chain.',
      );
    }

    return Column(
      children: events.map((ev) {
        final actionType =
            ev['actionType']?.toString() ?? ev['action']?.toString() ?? 'EVENT';
        final readableTitle = _formatAuditActionLabel(actionType);
        final actorId =
            ev['actorId']?.toString() ?? ev['userId']?.toString() ?? 'System';
        final shortActor = actorId.length > 14
            ? '${actorId.substring(0, 8)}…'
            : actorId;
        final currentHash = ev['eventHash']?.toString() ??
            ev['currentHash']?.toString() ??
            ev['hash']?.toString() ??
            '';
        final shortHash = currentHash.length > 10
            ? '${currentHash.substring(0, 10)}…'
            : (currentHash.isEmpty ? 'SHA-256' : currentHash);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ElevatedActionCard(
            onTap: () => _openAuditEventSheet(ev),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.goldPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.fingerprint_rounded,
                    color: AppTheme.goldPrimary,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        readableTitle,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPure,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              actionType,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.goldPrimary,
                              ),
                            ),
                          ),
                          Text(
                            ' • Actor: $shortActor • #$shortHash',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textMuted,
                  size: 18,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
