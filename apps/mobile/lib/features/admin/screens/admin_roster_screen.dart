// lib/features/admin/screens/admin_roster_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/admin_provider.dart';
import '../../../core/security/admin_permissions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/crystal_glass_nav_controls.dart';
import '../../../core/widgets/crystal_slash_painter.dart';
import '../../../core/widgets/crystal_stage_scaffold.dart';
import '../../../core/widgets/crystal_toast.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/main_shell_screen.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/admin_crystal_widgets.dart';

/// Tab 2 (`Roster` — `/discover` in Admin Mode):
/// Unified Federation Personnel & Talent Registry with 3 segments:
/// 0. `Athletes` (Identity Verification, Manual ELO/Profile Override, Referee Certifications, Suspend/Blacklist/Recover)
/// 1. `Referees` (License Level Upgrade/Downgrade, Regional Coverage Assignment, Referee Suspension)
/// 2. `Scouting` (Talent Nominations Pipeline: Pending -> Contacted -> Registered / Declined)
class AdminRosterScreen extends ConsumerStatefulWidget {
  const AdminRosterScreen({super.key});

  @override
  ConsumerState<AdminRosterScreen> createState() => _AdminRosterScreenState();
}

class _AdminRosterScreenState extends ConsumerState<AdminRosterScreen> {
  final TextEditingController _athleteSearchCtrl = TextEditingController();
  final TextEditingController _refereeSearchCtrl = TextEditingController();
  final TextEditingController _nominationSearchCtrl = TextEditingController();

  String _athleteSearch = '';
  String _refereeSearch = '';
  String _refereeLicenseFilter = '';
  String _nominationSearch = '';
  String _nominationStatusFilter = '';

  @override
  void dispose() {
    _athleteSearchCtrl.dispose();
    _refereeSearchCtrl.dispose();
    _nominationSearchCtrl.dispose();
    super.dispose();
  }

  void _refreshCurrentSegment(int segment, AdminAthleteFilter athleteFilter) {
    if (segment == 0) {
      ref.invalidate(adminAthletesProvider(athleteFilter));
    } else if (segment == 1) {
      ref.invalidate(adminRefereesProvider);
    } else {
      ref.invalidate(adminNominationsProvider);
    }
  }

  // ===========================================================================
  // ATHLETE REGULATORY DOSSIER BOTTOM SHEET
  // ===========================================================================
  Future<void> _openAthleteDossierSheet({
    required Map<String, dynamic> athlete,
    required String activeRole,
    required String? jurisdiction,
    required AdminAthleteFilter currentFilter,
  }) async {
    final String athleteId = athlete['id']?.toString() ?? '';
    final String displayName = athlete['displayName']?.toString() ??
        athlete['fullName']?.toString() ??
        athlete['name']?.toString() ??
        'Athlete';
    final String athleteProvince = athlete['province']?.toString() ?? '';
    final String currentStatus =
        (athlete['verificationStatus'] ?? athlete['status'] ?? 'PENDING')
            .toString()
            .toUpperCase();

    final bool canReview = AdminPermissions.canPerform(
      activeRole,
      AdminAction.reviewAthlete,
      jurisdiction: jurisdiction,
      targetProvince: athleteProvince,
    );
    final bool canCorrect = AdminPermissions.canPerform(
      activeRole,
      AdminAction.correctAthlete,
    );
    final bool canDiscipline = AdminPermissions.canPerform(
      activeRole,
      AdminAction.suspendAthlete,
    );
    final bool canManageCerts = AdminPermissions.canPerform(
      activeRole,
      AdminAction.manageReferees,
      jurisdiction: jurisdiction,
      targetProvince: athleteProvince,
    );

    final nameCtrl = TextEditingController(text: displayName);
    final weightCtrl = TextEditingController(
      text: athlete['weightClass']?.toString() ?? '85kg',
    );
    final provCtrl = TextEditingController(text: athleteProvince);
    final cityCtrl = TextEditingController(
      text: athlete['city']?.toString() ?? '',
    );
    final rightEloCtrl = TextEditingController(
      text: (athlete['rightArmElo'] ?? athlete['rightElo'] ?? 1200).toString(),
    );
    final leftEloCtrl = TextEditingController(
      text: (athlete['leftArmElo'] ?? athlete['leftElo'] ?? 1200).toString(),
    );
    final reasonCtrl = TextEditingController();
    final suspendDaysCtrl = TextEditingController(text: '30');

    final certAuthorityCtrl = TextEditingController(
      text: 'Pakistan Armwrestling Federation (PAF)',
    );
    final certExpiryCtrl = TextEditingController(text: '2027-12-31');
    final certNotesCtrl = TextEditingController();
    String selectedCertLevel = 'PROVINCIAL';

    int activeActionTab = 0; // 0: Review, 1: Override, 2: Certs, 3: Discipline
    bool isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Consumer(
          builder: (ctx, sheetRef, _) {
            final certsAsync =
                sheetRef.watch(adminAthleteCertificationsProvider(athleteId));
            final certs =
                certsAsync.valueOrNull ?? const <Map<String, dynamic>>[];

            return StatefulBuilder(
              builder: (sCtx, setSheetState) {
                Future<void> runMutation(
                  Future<void> Function() call,
                  String successMsg,
                ) async {
                  setSheetState(() => isSubmitting = true);
                  try {
                    await call();
                    await AdminCrossAppSync.syncAthleteMutations(ref);
                    ref.invalidate(adminAthletesProvider(currentFilter));
                    ref.invalidate(adminDashboardStatsProvider);
                    ref.invalidate(
                      adminAthleteCertificationsProvider(athleteId),
                    );
                    if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        CrystalSnackBar(
                          content: Text(successMsg),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                    }
                  } catch (e) {
                    setSheetState(() => isSubmitting = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        CrystalSnackBar(
                          content: Text('Action failed: $e'),
                          backgroundColor: AppTheme.error,
                        ),
                      );
                    }
                  }
                }

                return CrystalModalSheet(
                  title: 'ATHLETE REGULATORY DOSSIER',
                  subtitle:
                      '$displayName • ${athleteProvince.isEmpty ? "National" : athleteProvince} • $currentStatus',
                  headerIcon: Icons.badge_rounded,
                  secondaryActionLabel: 'Close Dossier',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Sub-navigation inside dossier sheet
                      AdminSegmentedDeck(
                        selectedIndex: activeActionTab,
                        onChanged: (idx) =>
                            setSheetState(() => activeActionTab = idx),
                        segments: const [
                          AdminSegmentItem(
                            label: 'Verify',
                            icon: Icons.verified_user_rounded,
                          ),
                          AdminSegmentItem(
                            label: 'Override',
                            icon: Icons.tune_rounded,
                          ),
                          AdminSegmentItem(
                            label: 'Certs',
                            icon: Icons.workspace_premium_rounded,
                          ),
                          AdminSegmentItem(
                            label: 'Sanction',
                            icon: Icons.gavel_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // TAB 0: IDENTITY VERIFICATION REVIEW
                      if (activeActionTab == 0) ...[
                        ElevatedActionCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Status: $currentStatus',
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.goldPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Weight Class: ${weightCtrl.text} • Right ELO: ${rightEloCtrl.text} • Left ELO: ${leftEloCtrl.text}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: reasonCtrl,
                          maxLines: 2,
                          style: const TextStyle(
                            color: AppTheme.textPure,
                            fontSize: 13.5,
                          ),
                          decoration: CrystalModalSheet.inputDecoration(
                            labelText: 'Verification / Review Note',
                            hintText:
                                'CNIC / passport verified or reason for rejection...',
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (!canReview)
                          const Text(
                            'Your role or provincial jurisdiction does not permit reviewing this athlete.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.warning,
                            ),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: CrystalActionButton(
                                  label: 'APPROVE (VERIFY)',
                                  icon: Icons.verified_rounded,
                                  accentColor: AppTheme.success,
                                  isLoading: isSubmitting,
                                  onTap: () => runMutation(
                                    () => ref
                                        .read(adminRepositoryProvider)
                                        .reviewAthlete(
                                          athleteId: athleteId,
                                          status: 'VERIFIED',
                                          reason: reasonCtrl.text.trim(),
                                        ),
                                    'Verified athlete $displayName',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: CrystalActionButton(
                                  label: 'REJECT',
                                  icon: Icons.cancel_rounded,
                                  accentColor: AppTheme.crimson,
                                  isLoading: isSubmitting,
                                  onTap: () => runMutation(
                                    () => ref
                                        .read(adminRepositoryProvider)
                                        .reviewAthlete(
                                          athleteId: athleteId,
                                          status: 'REJECTED',
                                          reason: reasonCtrl.text.trim().isEmpty
                                              ? 'Identity documents incomplete'
                                              : reasonCtrl.text.trim(),
                                        ),
                                    'Rejected athlete $displayName',
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],

                      // TAB 1: PROFILE & ELO MANUAL OVERRIDE
                      if (activeActionTab == 1) ...[
                        TextField(
                          controller: nameCtrl,
                          style: const TextStyle(
                            color: AppTheme.textPure,
                            fontSize: 13.5,
                          ),
                          decoration: CrystalModalSheet.inputDecoration(
                            labelText: 'Official Display Name',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: weightCtrl,
                                style: const TextStyle(
                                  color: AppTheme.textPure,
                                  fontSize: 13.5,
                                ),
                                decoration: CrystalModalSheet.inputDecoration(
                                  labelText: 'Weight Class',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: provCtrl,
                                style: const TextStyle(
                                  color: AppTheme.textPure,
                                  fontSize: 13.5,
                                ),
                                decoration: CrystalModalSheet.inputDecoration(
                                  labelText: 'Province',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: rightEloCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  color: AppTheme.textPure,
                                  fontSize: 13.5,
                                ),
                                decoration: CrystalModalSheet.inputDecoration(
                                  labelText: 'Right Arm ELO',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: leftEloCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  color: AppTheme.textPure,
                                  fontSize: 13.5,
                                ),
                                decoration: CrystalModalSheet.inputDecoration(
                                  labelText: 'Left Arm ELO',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: reasonCtrl,
                          maxLines: 2,
                          style: const TextStyle(
                            color: AppTheme.textPure,
                            fontSize: 13.5,
                          ),
                          decoration: CrystalModalSheet.inputDecoration(
                            labelText: 'Mandatory Audit Reason for Correction',
                            hintText:
                                'State official weigh-in or rating audit reason...',
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (!canCorrect)
                          const Text(
                            'Only System Admin and National Director can manually override ELO ratings and biometric profiles.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.warning,
                            ),
                          )
                        else
                          CrystalActionButton(
                            label: 'SAVE PROFILE & ELO OVERRIDE',
                            icon: Icons.save_rounded,
                            fullWidth: true,
                            isLoading: isSubmitting,
                            accentColor: AppTheme.goldPrimary,
                            onTap: () {
                              if (reasonCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  CrystalSnackBar(
                                    content: const Text(
                                      'An audit reason is required to override athlete records.',
                                    ),
                                    backgroundColor: AppTheme.error,
                                  ),
                                );
                                return;
                              }
                              runMutation(
                                () => ref
                                    .read(adminRepositoryProvider)
                                    .correctAthleteProfile(
                                      athleteId: athleteId,
                                      displayName: nameCtrl.text.trim(),
                                      weightClass: weightCtrl.text.trim(),
                                      province: provCtrl.text.trim(),
                                      city: cityCtrl.text.trim(),
                                      rightArmElo:
                                          int.tryParse(rightEloCtrl.text.trim()),
                                      leftArmElo:
                                          int.tryParse(leftEloCtrl.text.trim()),
                                      reason: reasonCtrl.text.trim(),
                                    ),
                                'Updated profile & ELO for $displayName',
                              );
                            },
                          ),
                      ],

                      // TAB 2: REFEREE CERTIFICATIONS
                      if (activeActionTab == 2) ...[
                        const Text(
                          'ACTIVE REFEREE CERTIFICATIONS',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppTheme.goldPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (certs.isEmpty)
                          const ElevatedActionCard(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'No referee certifications issued for this athlete yet.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          )
                        else
                          ...certs.map((c) {
                            final certId = c['id']?.toString() ?? '';
                            final level =
                                c['certificationLevel']?.toString() ??
                                    c['level']?.toString() ??
                                    'PROVINCIAL';
                            final authority =
                                c['issuingAuthority']?.toString() ?? 'PAF';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ElevatedActionCard(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.workspace_premium_rounded,
                                      color: AppTheme.goldPrimary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$level REFEREE LICENSE',
                                            style: const TextStyle(
                                              fontFamily: AppTheme.fontDisplay,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.textPure,
                                            ),
                                          ),
                                          Text(
                                            authority,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (canManageCerts && certId.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: AppTheme.crimson,
                                          size: 19,
                                        ),
                                        tooltip: 'Revoke Certification',
                                        onPressed: () => runMutation(
                                          () => ref
                                              .read(adminRepositoryProvider)
                                              .revokeRefereeCertification(
                                                certId,
                                              ),
                                          'Revoked certification $level',
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        const SizedBox(height: 14),
                        if (canManageCerts) ...[
                          const Text(
                            'ISSUE NEW CERTIFICATION',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppTheme.goldPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: selectedCertLevel,
                            dropdownColor: const Color(0xF50B101B),
                            style: const TextStyle(
                              color: AppTheme.textPure,
                              fontSize: 13.5,
                            ),
                            decoration: CrystalModalSheet.inputDecoration(
                              labelText: 'Certification Grade',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'PROVINCIAL',
                                child: Text('Provincial Referee (Grade C)'),
                              ),
                              DropdownMenuItem(
                                value: 'NATIONAL',
                                child: Text('National Referee (Grade B)'),
                              ),
                              DropdownMenuItem(
                                value: 'INTERNATIONAL',
                                child: Text('WAF International Master (Grade A)'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setSheetState(() => selectedCertLevel = v);
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: certAuthorityCtrl,
                            style: const TextStyle(
                              color: AppTheme.textPure,
                              fontSize: 13.5,
                            ),
                            decoration: CrystalModalSheet.inputDecoration(
                              labelText: 'Issuing Authority',
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: certExpiryCtrl,
                            style: const TextStyle(
                              color: AppTheme.textPure,
                              fontSize: 13.5,
                            ),
                            decoration: CrystalModalSheet.inputDecoration(
                              labelText: 'Expiration Date (YYYY-MM-DD)',
                            ),
                          ),
                          const SizedBox(height: 12),
                          CrystalActionButton(
                            label: 'ISSUE REFEREE CERTIFICATION',
                            icon: Icons.verified_rounded,
                            fullWidth: true,
                            isLoading: isSubmitting,
                            accentColor: AppTheme.goldPrimary,
                            onTap: () => runMutation(
                              () => ref
                                  .read(adminRepositoryProvider)
                                  .issueRefereeCertification(
                                    athleteUserId: athleteId,
                                    certificationLevel: selectedCertLevel,
                                    issuingAuthority:
                                        certAuthorityCtrl.text.trim().isEmpty
                                            ? 'Pakistan Armwrestling Federation'
                                            : certAuthorityCtrl.text.trim(),
                                    issuedAt: DateTime.now().toUtc().toIso8601String(),
                                    expiresAt: certExpiryCtrl.text.trim().isEmpty
                                        ? null
                                        : certExpiryCtrl.text.trim(),
                                  ),
                              'Issued $selectedCertLevel certification to $displayName',
                            ),
                          ),
                        ],
                      ],

                      // TAB 3: DISCIPLINARY SANCTIONS (SUSPEND / BLACKLIST / RECOVER)
                      if (activeActionTab == 3) ...[
                        TextField(
                          controller: suspendDaysCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            color: AppTheme.textPure,
                            fontSize: 13.5,
                          ),
                          decoration: CrystalModalSheet.inputDecoration(
                            labelText: 'Suspension Duration (Days)',
                            hintText: 'e.g., 30, 90, 365',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: reasonCtrl,
                          maxLines: 3,
                          style: const TextStyle(
                            color: AppTheme.textPure,
                            fontSize: 13.5,
                          ),
                          decoration: CrystalModalSheet.inputDecoration(
                            labelText:
                                'Mandatory Disciplinary / Reinstatement Reason',
                            hintText:
                                'Cite rulebook article or executive ruling...',
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (!canDiscipline)
                          const Text(
                            'Disciplinary suspensions and blacklisting require National Director or System Admin authority.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.warning,
                            ),
                          )
                        else ...[
                          Row(
                            children: [
                              Expanded(
                                child: CrystalActionButton(
                                  label: 'SUSPEND',
                                  icon: Icons.pause_circle_filled_rounded,
                                  accentColor: AppTheme.warning,
                                  isLoading: isSubmitting,
                                  onTap: () {
                                    if (reasonCtrl.text.trim().isEmpty) return;
                                    runMutation(
                                      () => ref
                                          .read(adminRepositoryProvider)
                                          .suspendAthlete(
                                            athleteId: athleteId,
                                            reason: reasonCtrl.text.trim(),
                                            durationDays: int.tryParse(
                                              suspendDaysCtrl.text.trim(),
                                            ),
                                          ),
                                      'Suspended $displayName',
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: CrystalActionButton(
                                  label: 'BLACKLIST',
                                  icon: Icons.gavel_rounded,
                                  accentColor: AppTheme.crimson,
                                  isLoading: isSubmitting,
                                  onTap: () {
                                    if (reasonCtrl.text.trim().isEmpty) return;
                                    runMutation(
                                      () => ref
                                          .read(adminRepositoryProvider)
                                          .blacklistAthlete(
                                            athleteId: athleteId,
                                            reason: reasonCtrl.text.trim(),
                                          ),
                                      'Blacklisted $displayName',
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          CrystalActionButton(
                            label: 'REINSTATE / RECOVER STANDING',
                            icon: Icons.restore_rounded,
                            fullWidth: true,
                            accentColor: AppTheme.success,
                            isLoading: isSubmitting,
                            onTap: () {
                              if (reasonCtrl.text.trim().isEmpty) return;
                              runMutation(
                                () => ref
                                    .read(adminRepositoryProvider)
                                    .recoverAthlete(
                                      athleteId: athleteId,
                                      reason: reasonCtrl.text.trim(),
                                    ),
                                'Reinstated $displayName to good standing',
                              );
                            },
                          ),
                        ],
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // REFEREE LICENSE & REGION BOTTOM SHEET
  // ===========================================================================
  Future<void> _openRefereeSheet({
    required Map<String, dynamic> referee,
    required String activeRole,
    required String? jurisdiction,
  }) async {
    final String refereeId = referee['id']?.toString() ?? '';
    final String name = referee['displayName']?.toString() ??
        referee['name']?.toString() ??
        'Certified Referee';
    String selectedLevel = (referee['licenseLevel'] ??
            referee['certificationLevel'] ??
            'PROVINCIAL')
        .toString()
        .toUpperCase();
    if (!const {'PROVINCIAL', 'NATIONAL', 'INTERNATIONAL'}
        .contains(selectedLevel)) {
      selectedLevel = 'PROVINCIAL';
    }
    final regionCtrl = TextEditingController(
      text: referee['regionalCoverage']?.toString() ??
          referee['province']?.toString() ??
          (jurisdiction ?? 'National'),
    );
    final suspendReasonCtrl = TextEditingController();
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
              title: 'REFEREE LICENSE & JURISDICTION',
              subtitle: '$name • Official Federation Officiating Credential',
              headerIcon: Icons.sports_rounded,
              primaryActionLabel: 'Save License & Region',
              primaryActionIcon: Icons.verified_rounded,
              isPrimaryLoading: isSubmitting,
              secondaryActionLabel: 'Cancel',
              onPrimaryAction: () async {
                setSheetState(() => isSubmitting = true);
                try {
                  await ref.read(adminRepositoryProvider).updateRefereeLicense(
                        refereeId: refereeId,
                        certification: selectedLevel,
                        status: 'ACTIVE',
                      );
                  if (regionCtrl.text.trim().isNotEmpty) {
                    await ref.read(adminRepositoryProvider).updateRefereeRegion(
                          refereeId: refereeId,
                          regionalCoverage: regionCtrl.text.trim(),
                        );
                  }
                  await AdminCrossAppSync.syncRefereeMutations(ref);
                  ref.invalidate(adminRefereesProvider);
                  if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      CrystalSnackBar(
                        content: Text(
                          'Updated $name to $selectedLevel (${regionCtrl.text.trim()})',
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
                        content: Text('Failed to update referee: $e'),
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
                    initialValue: selectedLevel,
                    dropdownColor: const Color(0xF50B101B),
                    style: const TextStyle(
                      color: AppTheme.textPure,
                      fontSize: 13.5,
                    ),
                    decoration: CrystalModalSheet.inputDecoration(
                      labelText: 'Officiating License Grade',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'PROVINCIAL',
                        child: Text('PROVINCIAL LICENSE'),
                      ),
                      DropdownMenuItem(
                        value: 'NATIONAL',
                        child: Text('NATIONAL LICENSE'),
                      ),
                      DropdownMenuItem(
                        value: 'INTERNATIONAL',
                        child: Text('INTERNATIONAL MASTER LICENSE'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setSheetState(() => selectedLevel = v);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: regionCtrl,
                    style: const TextStyle(
                      color: AppTheme.textPure,
                      fontSize: 13.5,
                    ),
                    decoration: CrystalModalSheet.inputDecoration(
                      labelText: 'Regional Officiating Coverage',
                      hintText: 'e.g., Punjab, Sindh, National',
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Divider(color: Color(0x24FFFFFF)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: suspendReasonCtrl,
                    style: const TextStyle(
                      color: AppTheme.textPure,
                      fontSize: 13.5,
                    ),
                    decoration: CrystalModalSheet.inputDecoration(
                      labelText: 'Disciplinary Suspension Reason (Optional)',
                      hintText: 'Enter reason to suspend officiating license...',
                    ),
                  ),
                  const SizedBox(height: 10),
                  CrystalActionButton(
                    label: 'SUSPEND REFEREE LICENSE',
                    icon: Icons.gavel_rounded,
                    accentColor: AppTheme.crimson,
                    isLoading: isSubmitting,
                    onTap: () async {
                      if (suspendReasonCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          CrystalSnackBar(
                            content: const Text(
                              'Enter a disciplinary reason before suspending a referee.',
                            ),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                        return;
                      }
                      setSheetState(() => isSubmitting = true);
                      try {
                        await ref.read(adminRepositoryProvider).suspendReferee(
                              refereeId: refereeId,
                              reason: suspendReasonCtrl.text.trim(),
                            );
                        await AdminCrossAppSync.syncRefereeMutations(ref);
                        ref.invalidate(adminRefereesProvider);
                        if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            CrystalSnackBar(
                              content: Text('Suspended referee $name'),
                              backgroundColor: AppTheme.warning,
                            ),
                          );
                        }
                      } catch (e) {
                        setSheetState(() => isSubmitting = false);
                      }
                    },
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
    final bool isProvincial = activeRole == 'PROVINCIAL_DIRECTOR';

    final selectedSegment = ref.watch(adminRosterSegmentProvider);
    final statusFilter = ref.watch(adminRosterStatusFilterProvider);

    final effectiveProvince =
        isProvincial && jurisdiction != null ? jurisdiction : '';

    final athleteFilter = AdminAthleteFilter(
      search: _athleteSearch,
      status: statusFilter,
      province: effectiveProvince,
    );

    final athletesAsync = ref.watch(adminAthletesProvider(athleteFilter));
    final refereesAsync = ref.watch(adminRefereesProvider);
    final nominationsAsync = ref.watch(adminNominationsProvider);

    final bool insideRootShell = MainShellScope.isInsideShell(context);
    final double bottomDockGap = insideRootShell
        ? (kFloatingDockTotalHeight + MediaQuery.paddingOf(context).bottom + 10.0)
        : 12.0;

    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: CrystalStageBackdrop(domain: ArmSphereStageDomain.governance),
          ),
          SafeArea(
            bottom: false,
            child: CrystalVaporDissolve(
              bottomMargin: bottomDockGap,
              child: RefreshIndicator(
                color: AppTheme.goldPrimary,
                backgroundColor: AppTheme.cardSurface,
                onRefresh: () async =>
                    _refreshCurrentSegment(selectedSegment, athleteFilter),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    115,
                    16,
                    28,
                  ),
                  children: [
                    AdminAuthorityHeader(
                      title: 'Federation Roster',
                      subtitle:
                          'Athlete verification, referee licensing, and talent scouting pipeline',
                      activeRole: activeRole,
                      jurisdiction: jurisdiction,
                      onRefresh: () =>
                          _refreshCurrentSegment(selectedSegment, athleteFilter),
                    ),
                    const SizedBox(height: 14),

                    AdminSegmentedDeck(
                      selectedIndex: selectedSegment,
                      onChanged: (idx) =>
                          ref.read(adminRosterSegmentProvider.notifier).state = idx,
                      segments: [
                        AdminSegmentItem(
                          label: 'Athletes',
                          icon: Icons.people_alt_rounded,
                          count: athletesAsync.valueOrNull?.length,
                        ),
                        AdminSegmentItem(
                          label: 'Referees',
                          icon: Icons.sports_rounded,
                          count: refereesAsync.valueOrNull?.length,
                        ),
                        AdminSegmentItem(
                          label: 'Scouting',
                          icon: Icons.auto_awesome_rounded,
                          count: nominationsAsync.valueOrNull?.length,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (selectedSegment == 0)
                      _buildAthletesSegment(
                        athletesAsync: athletesAsync,
                        activeRole: activeRole,
                        jurisdiction: jurisdiction,
                        statusFilter: statusFilter,
                        athleteFilter: athleteFilter,
                      )
                    else if (selectedSegment == 1)
                      _buildRefereesSegment(
                        refereesAsync: refereesAsync,
                        activeRole: activeRole,
                        jurisdiction: jurisdiction,
                      )
                    else
                      _buildScoutingSegment(
                        nominationsAsync: nominationsAsync,
                        activeRole: activeRole,
                        jurisdiction: jurisdiction,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAthletesSegment({
    required AsyncValue<List<Map<String, dynamic>>> athletesAsync,
    required String activeRole,
    required String? jurisdiction,
    required String statusFilter,
    required AdminAthleteFilter athleteFilter,
  }) {
    final list = athletesAsync.valueOrNull ?? const <Map<String, dynamic>>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminCrystalSearchBar(
          controller: _athleteSearchCtrl,
          hintText: 'Search athletes by name, city, or weight class...',
          onChanged: (v) => setState(() => _athleteSearch = v),
          onClear: () {
            _athleteSearchCtrl.clear();
            setState(() => _athleteSearch = '');
          },
          filterOptions: const [
            '',
            'PENDING',
            'VERIFIED',
            'REJECTED',
            'SUSPENDED',
            'BLACKLISTED',
          ],
          selectedFilter: statusFilter,
          onFilterSelected: (f) =>
              ref.read(adminRosterStatusFilterProvider.notifier).state = f,
        ),
        const SizedBox(height: 14),
        if (athletesAsync.isLoading && list.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 42),
            child: Center(
              child: CircularProgressIndicator(color: AppTheme.goldPrimary),
            ),
          )
        else if (list.isEmpty)
          const AppEmptyState(
            icon: Icons.person_search_rounded,
            title: 'No Athletes Match Filter',
            description:
                'Clear your search query or switch verification status chips to inspect all registered athletes.',
          )
        else
          ...list.asMap().entries.map((entry) {
            final idx = entry.key;
            final athlete = entry.value;
            final name = athlete['displayName']?.toString() ??
                athlete['fullName']?.toString() ??
                athlete['name']?.toString() ??
                'Registered Athlete';
            final province = athlete['province']?.toString() ?? 'National';
            final weight = athlete['weightClass']?.toString() ?? 'Open';
            final rightElo =
                athlete['rightArmElo'] ?? athlete['rightElo'] ?? 1200;
            final leftElo = athlete['leftArmElo'] ?? athlete['leftElo'] ?? 1200;
            final status =
                (athlete['verificationStatus'] ?? athlete['status'] ?? 'PENDING')
                    .toString()
                    .toUpperCase();

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ElevatedActionCard(
                slashVariant: CrystalSlashVariant.sequentialRow(idx),
                onTap: () => _openAthleteDossierSheet(
                  athlete: athlete,
                  activeRole: activeRole,
                  jurisdiction: jurisdiction,
                  currentFilter: athleteFilter,
                ),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0x73D4AF37),
                          width: 1.0,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'A',
                          style: const TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.goldPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPure,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$province • $weight • R:$rightElo / L:$leftElo',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(status),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.textMuted,
                      size: 18,
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildRefereesSegment({
    required AsyncValue<List<Map<String, dynamic>>> refereesAsync,
    required String activeRole,
    required String? jurisdiction,
  }) {
    final allReferees =
        refereesAsync.valueOrNull ?? const <Map<String, dynamic>>[];
    final filtered = allReferees.where((r) {
      final name =
          (r['displayName'] ?? r['name'] ?? '').toString().toLowerCase();
      final region =
          (r['regionalCoverage'] ?? r['province'] ?? '').toString().toLowerCase();
      final level = (r['licenseLevel'] ?? r['certificationLevel'] ?? '')
          .toString()
          .toUpperCase();
      final matchesSearch = _refereeSearch.isEmpty ||
          name.contains(_refereeSearch.toLowerCase()) ||
          region.contains(_refereeSearch.toLowerCase());
      final matchesLevel =
          _refereeLicenseFilter.isEmpty || level == _refereeLicenseFilter;
      return matchesSearch && matchesLevel;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminCrystalSearchBar(
          controller: _refereeSearchCtrl,
          hintText: 'Search referees by name or regional coverage...',
          onChanged: (v) => setState(() => _refereeSearch = v),
          onClear: () {
            _refereeSearchCtrl.clear();
            setState(() => _refereeSearch = '');
          },
          filterOptions: const [
            '',
            'PROVINCIAL',
            'NATIONAL',
            'INTERNATIONAL',
          ],
          selectedFilter: _refereeLicenseFilter,
          onFilterSelected: (f) => setState(() => _refereeLicenseFilter = f),
        ),
        const SizedBox(height: 14),
        if (filtered.isEmpty)
          const AppEmptyState(
            icon: Icons.sports_rounded,
            title: 'No Certified Referees Found',
            description:
                'Referees appear here once granted officiating credentials or certifications.',
          )
        else
          ...filtered.map((referee) {
            final name = referee['displayName']?.toString() ??
                referee['name']?.toString() ??
                'Official Referee';
            final level = (referee['licenseLevel'] ??
                    referee['certificationLevel'] ??
                    'PROVINCIAL')
                .toString()
                .toUpperCase();
            final region = referee['regionalCoverage']?.toString() ??
                referee['province']?.toString() ??
                'National';

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ElevatedActionCard(
                onTap: () => _openRefereeSheet(
                  referee: referee,
                  activeRole: activeRole,
                  jurisdiction: jurisdiction,
                ),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0x73D4AF37),
                          width: 1.0,
                        ),
                      ),
                      child: const Icon(
                        Icons.sports_rounded,
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
                            name,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPure,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Coverage: $region',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusChip.info(label: level),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.textMuted,
                      size: 18,
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildScoutingSegment({
    required AsyncValue<List<Map<String, dynamic>>> nominationsAsync,
    required String activeRole,
    required String? jurisdiction,
  }) {
    final allNominations =
        nominationsAsync.valueOrNull ?? const <Map<String, dynamic>>[];

    final filtered = allNominations.where((n) {
      final nominee =
          (n['nomineeName'] ?? n['athleteName'] ?? '').toString().toLowerCase();
      final city = (n['city'] ?? n['province'] ?? '').toString().toLowerCase();
      final status = (n['status'] ?? 'PENDING').toString().toUpperCase();
      final matchesSearch = _nominationSearch.isEmpty ||
          nominee.contains(_nominationSearch.toLowerCase()) ||
          city.contains(_nominationSearch.toLowerCase());
      final matchesStatus =
          _nominationStatusFilter.isEmpty || status == _nominationStatusFilter;
      return matchesSearch && matchesStatus;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminCrystalSearchBar(
          controller: _nominationSearchCtrl,
          hintText: 'Search scouted talent by nominee name or city...',
          onChanged: (v) => setState(() => _nominationSearch = v),
          onClear: () {
            _nominationSearchCtrl.clear();
            setState(() => _nominationSearch = '');
          },
          filterOptions: const [
            '',
            'PENDING',
            'CONTACTED',
            'REGISTERED',
            'DECLINED',
          ],
          selectedFilter: _nominationStatusFilter,
          onFilterSelected: (f) => setState(() => _nominationStatusFilter = f),
        ),
        const SizedBox(height: 14),
        if (filtered.isEmpty)
          const AppEmptyState(
            icon: Icons.person_add_alt_1_rounded,
            title: 'No Talent Nominations in Queue',
            description:
                'Community talent scouting nominations will appear here for outreach progression.',
          )
        else
          ...filtered.map((nom) {
            final nomId = nom['id']?.toString() ?? '';
            final nominee = nom['nomineeName']?.toString() ??
                nom['athleteName']?.toString() ??
                'Prospect';
            final province = nom['province']?.toString() ?? '';
            final city = nom['city']?.toString() ?? 'Unknown City';
            final status =
                (nom['status'] ?? 'PENDING').toString().toUpperCase();
            final reason = nom['reason']?.toString() ??
                nom['notes']?.toString() ??
                'Scouted regional arm-wrestling prospect.';

            final canUpdate = AdminPermissions.canPerform(
              activeRole,
              AdminAction.updateNomination,
              jurisdiction: jurisdiction,
              targetProvince: province,
            );

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ElevatedActionCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            nominee,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPure,
                            ),
                          ),
                        ),
                        _buildStatusChip(status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$city${province.isNotEmpty ? ", $province" : ""}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.goldPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      reason,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (canUpdate && nomId.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (status == 'PENDING')
                            CrystalHeaderActionPill(
                              label: 'MARK CONTACTED',
                              icon: Icons.phone_in_talk_rounded,
                              accentColor: AppTheme.info,
                              onTap: () =>
                                  _updateNomination(nomId, 'CONTACTED'),
                            ),
                          if (status == 'PENDING' || status == 'CONTACTED')
                            CrystalHeaderActionPill(
                              label: 'MARK REGISTERED',
                              icon: Icons.how_to_reg_rounded,
                              accentColor: AppTheme.success,
                              onTap: () =>
                                  _updateNomination(nomId, 'REGISTERED'),
                            ),
                          if (status != 'DECLINED')
                            CrystalHeaderActionPill(
                              label: 'DECLINE',
                              icon: Icons.close_rounded,
                              accentColor: AppTheme.crimson,
                              onTap: () => _updateNomination(nomId, 'DECLINED'),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Future<void> _updateNomination(String nominationId, String nextStatus) async {
    try {
      await ref.read(adminRepositoryProvider).updateNominationStatus(
            nominationId: nominationId,
            status: nextStatus,
          );
      ref.invalidate(adminNominationsProvider);
      await AdminCrossAppSync.syncNominationMutations(ref);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CrystalSnackBar(
            content: Text('Nomination updated to $nextStatus'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CrystalSnackBar(
            content: Text('Failed to update nomination: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Widget _buildStatusChip(String status) {
    switch (status) {
      case 'VERIFIED':
      case 'REGISTERED':
      case 'ACTIVE':
        return StatusChip.success(label: status);
      case 'PENDING':
      case 'UNVERIFIED':
      case 'CONTACTED':
        return StatusChip.warning(label: status);
      case 'REJECTED':
      case 'SUSPENDED':
      case 'BLACKLISTED':
      case 'DECLINED':
        return StatusChip.error(label: status);
      default:
        return StatusChip.info(label: status);
    }
  }
}
