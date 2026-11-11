// lib/features/admin/screens/admin_arena_ops_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/admin_provider.dart';
import '../../../core/providers/tournament_provider.dart';
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

/// Tab 3 (`Arena Ops` — `/tournaments` in Admin Mode):
/// Competition Integrity, Championship Belts, and Tournament Operations with 3 segments:
/// 0. `Match Oversight` (Official Score Correction & Match Voiding with ELO Recalculation)
/// 1. `Belt Titles` (Create Championship Belt, Lineage Timeline, Vacate/Strip Belt, Pending Challenges)
/// 2. `Tournaments` (Direct Operational Console Launch for Weigh-Ins, Brackets & Podium Ceremonies)
class AdminArenaOpsScreen extends ConsumerStatefulWidget {
  const AdminArenaOpsScreen({super.key});

  @override
  ConsumerState<AdminArenaOpsScreen> createState() =>
      _AdminArenaOpsScreenState();
}

class _AdminArenaOpsScreenState extends ConsumerState<AdminArenaOpsScreen> {
  final TextEditingController _matchSearchCtrl = TextEditingController();
  String _matchSearch = '';
  String _matchStatusFilter = '';

  @override
  void dispose() {
    _matchSearchCtrl.dispose();
    super.dispose();
  }

  void _refreshSegment(int segment) {
    if (segment == 0) {
      ref.invalidate(adminMatchesProvider);
    } else if (segment == 1) {
      ref.invalidate(adminChampionshipTitlesProvider);
      ref.invalidate(adminPendingChallengesProvider);
    } else {
      ref.invalidate(tournamentProvider);
    }
  }

  // ===========================================================================
  // MATCH SCORE OVERRIDE & VOID BOTTOM SHEET
  // ===========================================================================
  Future<void> _openMatchOverrideSheet({
    required Map<String, dynamic> match,
    required String activeRole,
    required String? jurisdiction,
  }) async {
    final String matchId = match['id']?.toString() ?? '';
    final String athleteAId = match['athleteAId']?.toString() ?? 'athlete_a';
    final String athleteBId = match['athleteBId']?.toString() ?? 'athlete_b';
    final String athleteAName = match['athleteAName']?.toString() ??
        (match['athleteA'] is Map
            ? match['athleteA']['displayName']?.toString()
            : null) ??
        'Red Corner Athlete';
    final String athleteBName = match['athleteBName']?.toString() ??
        (match['athleteB'] is Map
            ? match['athleteB']['displayName']?.toString()
            : null) ??
        'Blue Corner Athlete';

    final scoreACtrl = TextEditingController(
      text: (match['scoreA'] ?? 0).toString(),
    );
    final scoreBCtrl = TextEditingController(
      text: (match['scoreB'] ?? 0).toString(),
    );
    final reasonCtrl = TextEditingController();
    final weighInRegIdCtrl = TextEditingController(
      text: match['registrationId']?.toString() ?? athleteAId,
    );
    final weighInKgCtrl = TextEditingController(
      text: (match['weighInKg'] ?? '85.0').toString(),
    );
    String weighInStatus = 'PASSED';
    String? inspectedSummary;
    String selectedWinnerId =
        match['winnerId']?.toString() ?? athleteAId;
    if (selectedWinnerId != athleteAId && selectedWinnerId != athleteBId) {
      selectedWinnerId = athleteAId;
    }

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
              title: 'MATCH INTEGRITY & SCORE OVERRIDE',
              subtitle: '$athleteAName vs. $athleteBName',
              headerIcon: Icons.tune_rounded,
              primaryActionLabel: 'Commit Score Correction',
              primaryActionIcon: Icons.check_circle_rounded,
              isPrimaryLoading: isSubmitting,
              secondaryActionLabel: 'Cancel',
              onPrimaryAction: () async {
                final reason = reasonCtrl.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    CrystalSnackBar(
                      content: const Text(
                        'An official audit reason is mandatory to override match results.',
                      ),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                  return;
                }
                setSheetState(() => isSubmitting = true);
                try {
                  await ref.read(adminRepositoryProvider).correctMatchResult(
                        matchId: matchId,
                        winnerId: selectedWinnerId,
                        scoreA: int.tryParse(scoreACtrl.text.trim()) ?? 0,
                        scoreB: int.tryParse(scoreBCtrl.text.trim()) ?? 0,
                        reason: reason,
                      );
                  ref.invalidate(adminMatchesProvider);
                  await AdminCrossAppSync.syncMatchMutations(ref);
                  if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      CrystalSnackBar(
                        content: const Text(
                          'Official match score corrected and ELO ratings recalculated.',
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
                        content: Text('Match override failed: $e'),
                        backgroundColor: AppTheme.error,
                      ),
                    );
                  }
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'SELECT OFFICIAL WINNER',
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppTheme.goldPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: CrystalActionButton(
                          label: athleteAName,
                          icon: Icons.emoji_events_rounded,
                          isPrimary: selectedWinnerId == athleteAId,
                          accentColor: AppTheme.goldPrimary,
                          onTap: () => setSheetState(
                            () => selectedWinnerId = athleteAId,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CrystalActionButton(
                          label: athleteBName,
                          icon: Icons.emoji_events_rounded,
                          isPrimary: selectedWinnerId == athleteBId,
                          accentColor: AppTheme.goldPrimary,
                          onTap: () => setSheetState(
                            () => selectedWinnerId = athleteBId,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: scoreACtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            color: AppTheme.textPure,
                            fontSize: 14,
                          ),
                          decoration: CrystalModalSheet.inputDecoration(
                            labelText: '$athleteAName Score',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: scoreBCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            color: AppTheme.textPure,
                            fontSize: 14,
                          ),
                          decoration: CrystalModalSheet.inputDecoration(
                            labelText: '$athleteBName Score',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: reasonCtrl,
                    maxLines: 3,
                    style: const TextStyle(
                      color: AppTheme.textPure,
                      fontSize: 13.5,
                    ),
                    decoration: CrystalModalSheet.inputDecoration(
                      labelText: 'Mandatory Audit Reason',
                      hintText:
                          'Cite video replay review, referee scorepad error, or arbitration ruling...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0x24FFFFFF)),
                  const SizedBox(height: 10),
                  CrystalActionButton(
                    label: 'VOID MATCH & REVERT ELO IMPACT',
                    icon: Icons.cancel_rounded,
                    fullWidth: true,
                    accentColor: AppTheme.crimson,
                    isLoading: isSubmitting,
                    onTap: () async {
                      final reason = reasonCtrl.text.trim();
                      if (reason.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          CrystalSnackBar(
                            content: const Text(
                              'Enter an official audit reason before voiding a sanctioned match.',
                            ),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                        return;
                      }
                      setSheetState(() => isSubmitting = true);
                      try {
                        await ref.read(adminRepositoryProvider).voidMatch(
                              matchId: matchId,
                              reason: reason,
                            );
                        ref.invalidate(adminMatchesProvider);
                        await AdminCrossAppSync.syncMatchMutations(ref);
                        if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            CrystalSnackBar(
                              content: const Text(
                                'Match voided and ELO rating changes reverted.',
                              ),
                              backgroundColor: AppTheme.warning,
                            ),
                          );
                        }
                        } catch (e) {
                          setSheetState(() => isSubmitting = false);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0x24FFFFFF)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'OFFICIAL WEIGH-IN & LEDGER OVERRIDE',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppTheme.goldPrimary,
                          ),
                        ),
                        CrystalHeaderActionPill(
                          label: 'INSPECT BOUT',
                          icon: Icons.fact_check_rounded,
                          accentColor: AppTheme.info,
                          onTap: () async {
                            try {
                              final data = await ref
                                  .read(adminRepositoryProvider)
                                  .inspectMatch(matchId);
                              setSheetState(() {
                                inspectedSummary =
                                    'Verified Bout #${matchId.length > 6 ? matchId.substring(0, 6) : matchId} • Status: ${data['status'] ?? match['status'] ?? 'VERIFIED'}';
                              });
                            } catch (_) {
                              setSheetState(() {
                                inspectedSummary =
                                    'Bout #${matchId.length > 6 ? matchId.substring(0, 6) : matchId} • Status: ${match['status'] ?? 'COMPLETED'}';
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    if (inspectedSummary != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        inspectedSummary!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.info,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: weighInRegIdCtrl,
                            style: const TextStyle(
                              color: AppTheme.textPure,
                              fontSize: 13,
                            ),
                            decoration: CrystalModalSheet.inputDecoration(
                              labelText: 'Registration / Athlete ID',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: weighInKgCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: const TextStyle(
                              color: AppTheme.textPure,
                              fontSize: 13,
                            ),
                            decoration: CrystalModalSheet.inputDecoration(
                              labelText: 'Weight (kg)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: CrystalActionButton(
                            label: 'WEIGH-IN PASS',
                            icon: Icons.check_circle_outline_rounded,
                            isPrimary: weighInStatus == 'PASSED',
                            accentColor: AppTheme.success,
                            onTap: () async {
                              setSheetState(() {
                                weighInStatus = 'PASSED';
                                isSubmitting = true;
                              });
                              try {
                                await ref
                                    .read(adminRepositoryProvider)
                                    .manageWeighIn(
                                      registrationId:
                                          weighInRegIdCtrl.text.trim(),
                                      weight: double.tryParse(
                                            weighInKgCtrl.text.trim(),
                                          ) ??
                                          85.0,
                                      status: 'PASSED',
                                    );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    CrystalSnackBar(
                                      content: const Text(
                                        'Official weigh-in recorded as PASSED.',
                                      ),
                                      backgroundColor: AppTheme.success,
                                    ),
                                  );
                                }
                              } catch (_) {} finally {
                                setSheetState(() => isSubmitting = false);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CrystalActionButton(
                            label: 'WEIGH-IN FAIL',
                            icon: Icons.warning_amber_rounded,
                            isPrimary: weighInStatus == 'FAILED',
                            accentColor: AppTheme.warning,
                            onTap: () async {
                              setSheetState(() {
                                weighInStatus = 'FAILED';
                                isSubmitting = true;
                              });
                              try {
                                await ref
                                    .read(adminRepositoryProvider)
                                    .manageWeighIn(
                                      registrationId:
                                          weighInRegIdCtrl.text.trim(),
                                      weight: double.tryParse(
                                            weighInKgCtrl.text.trim(),
                                          ) ??
                                          85.0,
                                      status: 'FAILED',
                                    );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    CrystalSnackBar(
                                      content: const Text(
                                        'Official weigh-in marked as FAILED.',
                                      ),
                                      backgroundColor: AppTheme.warning,
                                    ),
                                  );
                                }
                              } catch (_) {} finally {
                                setSheetState(() => isSubmitting = false);
                              }
                            },
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

  // ===========================================================================
  // CREATE CHAMPIONSHIP BELT BOTTOM SHEET
  // ===========================================================================
  Future<void> _openCreateBeltSheet() async {
    final nameCtrl = TextEditingController();
    final weightCtrl = TextEditingController(text: '95kg');
    String selectedArm = 'RIGHT';
    String selectedDivision = 'SENIOR';
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
              title: 'ESTABLISH CHAMPIONSHIP BELT',
              subtitle:
                  'Create an official national or divisional championship title',
              headerIcon: Icons.workspace_premium_rounded,
              primaryActionLabel: 'Create Championship Title',
              primaryActionIcon: Icons.emoji_events_rounded,
              isPrimaryLoading: isSubmitting,
              secondaryActionLabel: 'Cancel',
              onPrimaryAction: () async {
                if (nameCtrl.text.trim().isEmpty ||
                    weightCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    CrystalSnackBar(
                      content: const Text(
                        'Title name and weight class are required.',
                      ),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                  return;
                }
                setSheetState(() => isSubmitting = true);
                try {
                  await ref
                      .read(adminRepositoryProvider)
                      .createChampionshipTitle(
                        name: nameCtrl.text.trim(),
                        arm: selectedArm,
                        division: selectedDivision,
                        weightClass: weightCtrl.text.trim(),
                      );
                  ref.invalidate(adminChampionshipTitlesProvider);
                  await AdminCrossAppSync.syncChampionshipMutations(ref);
                  if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      CrystalSnackBar(
                        content: Text(
                          'Created championship belt "${nameCtrl.text.trim()}"',
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
                        content: Text('Failed to create belt: $e'),
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
                    controller: nameCtrl,
                    style: const TextStyle(
                      color: AppTheme.textPure,
                      fontSize: 13.5,
                    ),
                    decoration: CrystalModalSheet.inputDecoration(
                      labelText: 'Championship Belt Title',
                      hintText:
                          'e.g., Pakistan National Heavyweight Right Arm Title',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedArm,
                          dropdownColor: const Color(0xF50B101B),
                          style: const TextStyle(
                            color: AppTheme.textPure,
                            fontSize: 13.5,
                          ),
                          decoration: CrystalModalSheet.inputDecoration(
                            labelText: 'Arm Category',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'RIGHT',
                              child: Text('RIGHT ARM'),
                            ),
                            DropdownMenuItem(
                              value: 'LEFT',
                              child: Text('LEFT ARM'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) setSheetState(() => selectedArm = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedDivision,
                          dropdownColor: const Color(0xF50B101B),
                          style: const TextStyle(
                            color: AppTheme.textPure,
                            fontSize: 13.5,
                          ),
                          decoration: CrystalModalSheet.inputDecoration(
                            labelText: 'Division',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'SENIOR',
                              child: Text('SENIOR PRO'),
                            ),
                            DropdownMenuItem(
                              value: 'JUNIOR',
                              child: Text('JUNIOR U21'),
                            ),
                            DropdownMenuItem(
                              value: 'FEMALE',
                              child: Text('WOMEN OPEN'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setSheetState(() => selectedDivision = v);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: weightCtrl,
                    style: const TextStyle(
                      color: AppTheme.textPure,
                      fontSize: 13.5,
                    ),
                    decoration: CrystalModalSheet.inputDecoration(
                      labelText: 'Weight Class',
                      hintText: 'e.g., 75kg, 85kg, 95kg, 105kg, +105kg',
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

  // ===========================================================================
  // BELT LINEAGE & VACATE/STRIP SHEET
  // ===========================================================================
  Future<void> _openBeltDetailSheet({
    required Map<String, dynamic> belt,
    required bool canManageChampionships,
  }) async {
    final String titleId = belt['id']?.toString() ?? '';
    final String titleName =
        belt['name']?.toString() ?? 'Championship Title';
    final String holderName = belt['currentHolderName']?.toString() ??
        (belt['currentHolder'] is Map
            ? belt['currentHolder']['displayName']?.toString()
            : null) ??
        'VACANT';
    final holderIdCtrl = TextEditingController(
      text: belt['currentHolderId']?.toString() ?? '',
    );
    final defenseMatchIdCtrl = TextEditingController();
    bool isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Consumer(
          builder: (ctx, sheetRef, _) {
            final lineageAsync =
                sheetRef.watch(adminTitleLineageProvider(titleId));
            final lineage =
                lineageAsync.valueOrNull ?? const <Map<String, dynamic>>[];

            return StatefulBuilder(
              builder: (sCtx, setSheetState) {
                Future<void> vacateOrStrip(String reasonCode) async {
                  setSheetState(() => isSubmitting = true);
                  try {
                    await ref
                        .read(adminRepositoryProvider)
                        .vacateChampionshipTitle(
                          titleId: titleId,
                          reason: reasonCode,
                        );
                    ref.invalidate(adminChampionshipTitlesProvider);
                    ref.invalidate(adminTitleLineageProvider(titleId));
                    await AdminCrossAppSync.syncChampionshipMutations(ref);
                    if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        CrystalSnackBar(
                          content: Text(
                            'Title "$titleName" marked $reasonCode',
                          ),
                          backgroundColor: AppTheme.warning,
                        ),
                      );
                    }
                  } catch (e) {
                    setSheetState(() => isSubmitting = false);
                  }
                }

                return CrystalModalSheet(
                  title: 'CHAMPIONSHIP LINEAGE & STATUS',
                  subtitle: '$titleName • Reigning: $holderName',
                  headerIcon: Icons.emoji_events_rounded,
                  secondaryActionLabel: 'Close',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (canManageChampionships) ...[
                        const Text(
                          'CHAMPIONSHIP REIGN MANAGEMENT',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppTheme.goldPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: holderIdCtrl,
                                style: const TextStyle(
                                  color: AppTheme.textPure,
                                  fontSize: 13,
                                ),
                                decoration: CrystalModalSheet.inputDecoration(
                                  labelText: 'Champion Athlete ID',
                                  hintText: 'Assign or defend holder ID',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: defenseMatchIdCtrl,
                                style: const TextStyle(
                                  color: AppTheme.textPure,
                                  fontSize: 13,
                                ),
                                decoration: CrystalModalSheet.inputDecoration(
                                  labelText: 'Defense Match ID',
                                  hintText: 'Optional bout ID',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: CrystalActionButton(
                                label: 'ASSIGN HOLDER',
                                icon: Icons.workspace_premium_rounded,
                                accentColor: AppTheme.goldPrimary,
                                isLoading: isSubmitting,
                                onTap: () async {
                                  final targetAthleteId =
                                      holderIdCtrl.text.trim();
                                  if (targetAthleteId.isEmpty) return;
                                  setSheetState(() => isSubmitting = true);
                                  try {
                                    await ref
                                        .read(adminRepositoryProvider)
                                        .manageChampionshipTitle(
                                          titleId: titleId,
                                          action: 'ASSIGN',
                                          athleteId: targetAthleteId,
                                        );
                                    ref.invalidate(
                                      adminChampionshipTitlesProvider,
                                    );
                                    ref.invalidate(
                                      adminTitleLineageProvider(titleId),
                                    );
                                    await AdminCrossAppSync
                                        .syncChampionshipMutations(ref);
                                    if (sheetCtx.mounted) {
                                      Navigator.of(sheetCtx).pop();
                                    }
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        CrystalSnackBar(
                                          content: Text(
                                            'Assigned holder for "$titleName".',
                                          ),
                                          backgroundColor: AppTheme.success,
                                        ),
                                      );
                                    }
                                  } catch (_) {
                                    setSheetState(() => isSubmitting = false);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: CrystalActionButton(
                                label: 'LOG DEFENSE',
                                icon: Icons.shield_rounded,
                                accentColor: AppTheme.success,
                                isLoading: isSubmitting,
                                onTap: () async {
                                  final winnerId = holderIdCtrl.text.trim();
                                  if (winnerId.isEmpty) return;
                                  final matchId =
                                      defenseMatchIdCtrl.text.trim().isNotEmpty
                                          ? defenseMatchIdCtrl.text.trim()
                                          : '00000000-0000-0000-0000-000000000001';
                                  setSheetState(() => isSubmitting = true);
                                  try {
                                    await ref
                                        .read(adminRepositoryProvider)
                                        .defendChampionshipTitle(
                                          titleId: titleId,
                                          winnerId: winnerId,
                                          matchId: matchId,
                                        );
                                    ref.invalidate(
                                      adminChampionshipTitlesProvider,
                                    );
                                    ref.invalidate(
                                      adminTitleLineageProvider(titleId),
                                    );
                                    await AdminCrossAppSync
                                        .syncChampionshipMutations(ref);
                                    if (sheetCtx.mounted) {
                                      Navigator.of(sheetCtx).pop();
                                    }
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        CrystalSnackBar(
                                          content: Text(
                                            'Recorded official title defense for "$titleName".',
                                          ),
                                          backgroundColor: AppTheme.success,
                                        ),
                                      );
                                    }
                                  } catch (_) {
                                    setSheetState(() => isSubmitting = false);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (canManageChampionships &&
                          holderName.toUpperCase() != 'VACANT') ...[
                        Row(
                          children: [
                            Expanded(
                              child: CrystalActionButton(
                                label: 'VACATE BELT',
                                icon: Icons.remove_moderator_rounded,
                                accentColor: AppTheme.warning,
                                isLoading: isSubmitting,
                                onTap: () => vacateOrStrip('VACATED'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: CrystalActionButton(
                                label: 'STRIP TITLE',
                                icon: Icons.gavel_rounded,
                                accentColor: AppTheme.crimson,
                                isLoading: isSubmitting,
                                onTap: () => vacateOrStrip('STRIPPED'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      const Text(
                        'HISTORICAL TITLE LINEAGE',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppTheme.goldPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (lineage.isEmpty)
                        const ElevatedActionCard(
                          padding: EdgeInsets.all(14),
                          child: Text(
                            'No historical title defenses recorded for this belt yet.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        )
                      else
                        ...lineage.map((entry) {
                          final champ = entry['holderName']?.toString() ??
                              entry['athleteName']?.toString() ??
                              'Champion';
                          final defenses = entry['defensesCount'] ??
                              entry['defenses'] ??
                              0;
                          final wonAt = entry['wonAt']?.toString() ??
                              entry['startDate']?.toString() ??
                              'Official Reign';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ElevatedActionCard(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.military_tech_rounded,
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
                                          champ,
                                          style: const TextStyle(
                                            fontFamily: AppTheme.fontDisplay,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.textPure,
                                          ),
                                        ),
                                        Text(
                                          'Reign started: $wonAt',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  StatusChip.info(label: '$defenses DEFENSES'),
                                ],
                              ),
                            ),
                          );
                        }),
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final activeRole = (authState.activeRole ??
            authState.userProfile?['role']?.toString() ??
            'SYSTEM_ADMIN')
        .toUpperCase();
    final jurisdiction =
        AdminPermissions.resolveJurisdiction(authState.userProfile);

    final selectedSegment = ref.watch(adminArenaOpsSegmentProvider);
    final matchesAsync = ref.watch(adminMatchesProvider);
    final titlesAsync = ref.watch(adminChampionshipTitlesProvider);
    final challengesAsync = ref.watch(adminPendingChallengesProvider);
    final tournamentsAsync = ref.watch(tournamentProvider);

    final canManageChampionships = AdminPermissions.canPerform(
      activeRole,
      AdminAction.manageChampionships,
    );

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
            onRefresh: () async => _refreshSegment(selectedSegment),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                mainShellBottomClearance(context, additionalPadding: 28),
              ),
              children: [
                AdminAuthorityHeader(
                  title: 'Arena Operations',
                  subtitle:
                      'Sanctioned bout score overrides, championship belts, and tournament desks',
                  activeRole: activeRole,
                  jurisdiction: jurisdiction,
                  onRefresh: () => _refreshSegment(selectedSegment),
                ),
                const SizedBox(height: 14),

                AdminSegmentedDeck(
                  selectedIndex: selectedSegment,
                  onChanged: (idx) =>
                      ref.read(adminArenaOpsSegmentProvider.notifier).state =
                          idx,
                  segments: [
                    AdminSegmentItem(
                      label: 'Match Oversight',
                      icon: Icons.sports_mma_rounded,
                      count: matchesAsync.valueOrNull?.length,
                    ),
                    AdminSegmentItem(
                      label: 'Belt Titles',
                      icon: Icons.workspace_premium_rounded,
                      count: titlesAsync.valueOrNull?.length,
                    ),
                    AdminSegmentItem(
                      label: 'Tournaments',
                      icon: Icons.emoji_events_rounded,
                      count: tournamentsAsync.valueOrNull?.length,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                if (selectedSegment == 0)
                  _buildMatchOversightSegment(
                    matchesAsync: matchesAsync,
                    activeRole: activeRole,
                    jurisdiction: jurisdiction,
                  )
                else if (selectedSegment == 1)
                  _buildBeltTitlesSegment(
                    titlesAsync: titlesAsync,
                    challengesAsync: challengesAsync,
                    canManageChampionships: canManageChampionships,
                  )
                else
                  _buildTournamentsSegment(tournamentsAsync: tournamentsAsync),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchOversightSegment({
    required AsyncValue<List<Map<String, dynamic>>> matchesAsync,
    required String activeRole,
    required String? jurisdiction,
  }) {
    final allMatches =
        matchesAsync.valueOrNull ?? const <Map<String, dynamic>>[];
    final filtered = allMatches.where((m) {
      final aName = (m['athleteAName'] ??
              (m['athleteA'] is Map ? m['athleteA']['displayName'] : '') ??
              '')
          .toString()
          .toLowerCase();
      final bName = (m['athleteBName'] ??
              (m['athleteB'] is Map ? m['athleteB']['displayName'] : '') ??
              '')
          .toString()
          .toLowerCase();
      final status = (m['status'] ?? 'COMPLETED').toString().toUpperCase();
      final matchesSearch = _matchSearch.isEmpty ||
          aName.contains(_matchSearch.toLowerCase()) ||
          bName.contains(_matchSearch.toLowerCase());
      final matchesStatus =
          _matchStatusFilter.isEmpty || status == _matchStatusFilter;
      return matchesSearch && matchesStatus;
    }).toList();

    final canOverride = AdminPermissions.canPerform(
      activeRole,
      AdminAction.overrideMatch,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminCrystalSearchBar(
          controller: _matchSearchCtrl,
          hintText: 'Search sanctioned bouts by athlete name...',
          onChanged: (v) => setState(() => _matchSearch = v),
          onClear: () {
            _matchSearchCtrl.clear();
            setState(() => _matchSearch = '');
          },
          filterOptions: const [
            '',
            'COMPLETED',
            'IN_PROGRESS',
            'DISPUTED',
            'VOIDED',
          ],
          selectedFilter: _matchStatusFilter,
          onFilterSelected: (f) => setState(() => _matchStatusFilter = f),
        ),
        const SizedBox(height: 14),
        if (filtered.isEmpty)
          const AppEmptyState(
            icon: Icons.sports_kabaddi_rounded,
            title: 'No Sanctioned Matches Found',
            description:
                'Official tournament and supermatch bouts appear here for score verification and ELO auditing.',
          )
        else
          ...filtered.map((match) {
            final aName = match['athleteAName']?.toString() ??
                (match['athleteA'] is Map
                    ? match['athleteA']['displayName']?.toString()
                    : null) ??
                'Red Corner';
            final bName = match['athleteBName']?.toString() ??
                (match['athleteB'] is Map
                    ? match['athleteB']['displayName']?.toString()
                    : null) ??
                'Blue Corner';
            final scoreA = match['scoreA'] ?? 0;
            final scoreB = match['scoreB'] ?? 0;
            final arm = match['arm']?.toString() ?? 'RIGHT';
            final weight = match['weightClass']?.toString() ?? 'Open';
            final status =
                (match['status'] ?? 'COMPLETED').toString().toUpperCase();

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ElevatedActionCard(
                onTap: canOverride
                    ? () => _openMatchOverrideSheet(
                          match: match,
                          activeRole: activeRole,
                          jurisdiction: jurisdiction,
                        )
                    : null,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$arm ARM • $weight',
                          style: const TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.goldPrimary,
                            letterSpacing: 0.6,
                          ),
                        ),
                        status == 'VOIDED'
                            ? const StatusChip.error(label: 'VOIDED')
                            : StatusChip.info(label: status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            aName,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPure,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.crimson.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.crimson.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Text(
                            '$scoreA  —  $scoreB',
                            style: const TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPure,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            bName,
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPure,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (canOverride) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Tap to correct official score or void match result',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
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

  Widget _buildBeltTitlesSegment({
    required AsyncValue<List<Map<String, dynamic>>> titlesAsync,
    required AsyncValue<List<Map<String, dynamic>>> challengesAsync,
    required bool canManageChampionships,
  }) {
    final titles = titlesAsync.valueOrNull ?? const <Map<String, dynamic>>[];
    final challenges =
        challengesAsync.valueOrNull ?? const <Map<String, dynamic>>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'OFFICIAL CHAMPIONSHIP BELTS',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: AppTheme.goldPrimary,
                ),
              ),
            ),
            if (canManageChampionships)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CrystalHeaderActionPill(
                    label: 'SYNC PRESTIGE',
                    icon: Icons.auto_fix_high_rounded,
                    accentColor: AppTheme.info,
                    onTap: () async {
                      try {
                        await ref
                            .read(adminRepositoryProvider)
                            .recomputePrestigeScores();
                        await AdminCrossAppSync.syncChampionshipMutations(ref);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            CrystalSnackBar(
                              content: const Text(
                                'Pound-for-pound championship prestige scores recalculated.',
                              ),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            CrystalSnackBar(
                              content: Text('Prestige sync failed: $e'),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  CrystalHeaderActionPill(
                    label: 'CREATE BELT',
                    icon: Icons.add_rounded,
                    accentColor: AppTheme.goldPrimary,
                    onTap: _openCreateBeltSheet,
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (titles.isEmpty)
          const AppEmptyState(
            icon: Icons.workspace_premium_rounded,
            title: 'No Championship Belts Established',
            description:
                'Create national or divisional championship belts to track title holders and defenses.',
          )
        else
          ...titles.map((belt) {
            final name = belt['name']?.toString() ?? 'Championship Belt';
            final arm = belt['arm']?.toString() ?? 'RIGHT';
            final div = belt['division']?.toString() ?? 'SENIOR';
            final weight = belt['weightClass']?.toString() ?? 'Open';
            final holder = belt['currentHolderName']?.toString() ??
                (belt['currentHolder'] is Map
                    ? belt['currentHolder']['displayName']?.toString()
                    : null) ??
                'VACANT';

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ElevatedActionCard(
                onTap: () => _openBeltDetailSheet(
                  belt: belt,
                  canManageChampionships: canManageChampionships,
                ),
                padding: const EdgeInsets.all(14),
                borderColor: AppTheme.goldPrimary.withValues(alpha: 0.4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.goldPrimary.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: AppTheme.goldPrimary,
                        size: 22,
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
                            '$div • $arm ARM • $weight • Holder: $holder',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    holder.toUpperCase() == 'VACANT'
                        ? const StatusChip.warning(label: 'VACANT')
                        : const StatusChip.success(label: 'ACTIVE'),
                  ],
                ),
              ),
            );
          }),

        if (challenges.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'PENDING TITLE CHALLENGES',
            style: TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: AppTheme.goldPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...challenges.map((ch) {
            final chId = ch['id']?.toString() ?? '';
            final challenger = ch['challengerName']?.toString() ?? 'Challenger';
            final titleName = ch['titleName']?.toString() ?? 'Title Match';
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ElevatedActionCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$challenger challenges for $titleName',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPure,
                      ),
                    ),
                    if (canManageChampionships && chId.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          CrystalHeaderActionPill(
                            label: 'SANCTION CHALLENGE',
                            icon: Icons.check_rounded,
                            accentColor: AppTheme.success,
                            onTap: () async {
                              await ref
                                  .read(adminRepositoryProvider)
                                  .respondToChallenge(
                                    challengeId: chId,
                                    accept: true,
                                  );
                              ref.invalidate(adminPendingChallengesProvider);
                              await AdminCrossAppSync.syncChampionshipMutations(ref);
                            },
                          ),
                          const SizedBox(width: 8),
                          CrystalHeaderActionPill(
                            label: 'DECLINE',
                            icon: Icons.close_rounded,
                            accentColor: AppTheme.crimson,
                            onTap: () async {
                              await ref
                                  .read(adminRepositoryProvider)
                                  .respondToChallenge(
                                    challengeId: chId,
                                    accept: false,
                                  );
                              ref.invalidate(adminPendingChallengesProvider);
                              await AdminCrossAppSync.syncChampionshipMutations(ref);
                            },
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
      ],
    );
  }

  Widget _buildTournamentsSegment({
    required AsyncValue<List<Map<String, dynamic>>> tournamentsAsync,
  }) {
    final events =
        tournamentsAsync.valueOrNull ?? const <Map<String, dynamic>>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (events.isEmpty)
          const AppEmptyState(
            icon: Icons.emoji_events_outlined,
            title: 'No Sanctioned Tournaments Found',
            description:
                'Scheduled federation tournaments appear here with direct access to Weigh-Ins, Brackets, and Awards.',
          )
        else
          ...events.map((ev) {
            final id = ev['id']?.toString() ?? '';
            final title = ev['name']?.toString() ??
                ev['title']?.toString() ??
                'Sanctioned Tournament';
            final city = ev['city']?.toString() ??
                ev['location']?.toString() ??
                'National Arena';
            final status =
                (ev['status'] ?? 'UPCOMING').toString().toUpperCase();

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedActionCard(
                onTap: id.isEmpty
                    ? null
                    : () => context.push('/tournament/$id/operations'),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPure,
                            ),
                          ),
                        ),
                        StatusChip.info(label: status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      city,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (id.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          CrystalHeaderActionPill(
                            label: 'OPS CONSOLE',
                            icon: Icons.dashboard_customize_rounded,
                            accentColor: AppTheme.goldPrimary,
                            onTap: () =>
                                context.push('/tournament/$id/operations'),
                          ),
                          CrystalHeaderActionPill(
                            label: 'WEIGH-IN DESK',
                            icon: Icons.monitor_weight_rounded,
                            accentColor: AppTheme.info,
                            onTap: () =>
                                context.push('/tournament/$id/weigh-in'),
                          ),
                          CrystalHeaderActionPill(
                            label: 'BRACKETS',
                            icon: Icons.account_tree_rounded,
                            accentColor: AppTheme.crimson,
                            onTap: () =>
                                context.push('/tournament/$id/brackets'),
                          ),
                          CrystalHeaderActionPill(
                            label: 'PODIUM AWARDS',
                            icon: Icons.emoji_events_rounded,
                            accentColor: AppTheme.success,
                            onTap: () => context.push('/tournament/$id/awards'),
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
}
