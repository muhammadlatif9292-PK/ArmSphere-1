import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/dependency_providers.dart';
import '../../../core/providers/organization_session_provider.dart';
import '../../../core/providers/tournament_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/crystal_toast.dart';
import '../../tournament/screens/tournament_operator_dashboard_screen.dart';

/// Standalone Autonomous Dockless Organization Deck Screen
///
/// The Organization Portal is a standalone, dockless operational workstation.
/// It contains ZERO bottom navigation buttons (no Arena, Discover, Events,
/// Community, or Passport tabs) and hosts the Tournament Operator 4-stage engine
/// scoped strictly to the authenticated Sanctioning Organization.
class OrganizationDeckScreen extends ConsumerWidget {
  const OrganizationDeckScreen({super.key});

  Future<void> _confirmExitWorkstation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0C101A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: AppTheme.goldPrimary.withValues(alpha: 0.45),
            width: 1.2,
          ),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.lock_outline_rounded,
              color: AppTheme.goldPrimary,
              size: 20,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'LOCK WORKSTATION',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Exit Organization Deck? This will lock the workstation.',
          style: TextStyle(
            fontFamily: AppTheme.fontBody,
            fontSize: 14,
            height: 1.45,
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.crimson,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.logout_rounded, size: 16),
            label: const Text(
              'LOCK & EXIT',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontWeight: FontWeight.w900,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(organizationSessionProvider.notifier).lockOrLogout();
      if (context.mounted) {
        context.go('/welcome');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(organizationSessionProvider);
    final orgName = (session.orgName != null && session.orgName!.trim().isNotEmpty)
        ? session.orgName!.trim()
        : 'Pakistan Armwrestling Federation (PAFF)';
    final orgId = session.orgId ?? 'org_paff_national';
    final jurisdiction = [
      if (session.city != null && session.city!.isNotEmpty) session.city,
      if (session.province != null && session.province!.isNotEmpty)
        session.province,
    ].join(', ');

    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
      // Explicitly null: ZERO bottom navigation buttons on the Organization Deck
      bottomNavigationBar: null,
      body: Column(
        children: [
          // Executive Broadcast Top Header
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.paddingOf(context).top + 10,
              16,
              12,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF121726),
                  Color(0xFF070A11),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.goldPrimary.withValues(alpha: 0.35),
                  width: 1.0,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Organization Crest Emblem
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0x38D4AF37),
                            Color(0xFF0B0F1A),
                          ],
                        ),
                        border: Border.all(
                          color: AppTheme.goldPrimary,
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.goldPrimary.withValues(alpha: 0.22),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_balance_rounded,
                        color: AppTheme.goldPrimary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Official Organization Name & Status Badges
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.goldPrimary.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppTheme.goldPrimary.withValues(alpha: 0.65),
                                    width: 0.9,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified_rounded,
                                      size: 11,
                                      color: AppTheme.goldPrimary,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'VERIFIED SANCTIONING BODY',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontSize: 9.0,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                        color: AppTheme.goldPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            orgName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Refresh Button
                    IconButton(
                      key: const ValueKey('org_deck_refresh_button'),
                      tooltip: 'Sync & Refresh Organization Events',
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF151C2C),
                        side: BorderSide(
                          color: AppTheme.emerald.withValues(alpha: 0.45),
                        ),
                      ),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        try {
                          ref.read(offlineSyncManagerProvider).syncQueue();
                        } catch (_) {}
                        ref.invalidate(tournamentProvider);
                        CrystalToast.info(
                          context,
                          'Synced federation tournament desk.',
                        );
                      },
                      icon: const Icon(
                        Icons.sync_rounded,
                        color: AppTheme.emerald,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Lock / Exit Workstation Button
                    IconButton(
                      key: const ValueKey('org_deck_lock_exit_button'),
                      tooltip: 'Lock & Exit Organization Deck',
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0x28EF4444),
                        side: BorderSide(
                          color: AppTheme.crimson.withValues(alpha: 0.65),
                        ),
                      ),
                      onPressed: () => _confirmExitWorkstation(context, ref),
                      icon: const Icon(
                        Icons.lock_outline_rounded,
                        color: AppTheme.crimson,
                        size: 19,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Workstation Indicator Strip
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.emerald.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppTheme.emerald.withValues(alpha: 0.45),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.terminal_rounded,
                            size: 11,
                            color: AppTheme.emerald,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'STAFF ACCESS (Floor Device)',
                            style: TextStyle(
                              fontFamily: AppTheme.fontMono,
                              fontSize: 10.0,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.emerald,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (jurisdiction.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: AppTheme.textSecondary.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          jurisdiction,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontBody,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Autonomous 4-Stage Tournament Operator Workstation Body
          Expanded(
            child: TournamentOperatorDashboardScreen(
              organizationId: orgId,
              organizationName: orgName,
              embeddedInOrganizationDeck: true,
            ),
          ),
        ],
      ),
    );
  }
}
