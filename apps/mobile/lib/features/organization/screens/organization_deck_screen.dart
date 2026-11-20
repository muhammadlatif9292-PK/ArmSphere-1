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
class OrganizationDeckScreen extends ConsumerStatefulWidget {
  const OrganizationDeckScreen({super.key});

  @override
  ConsumerState<OrganizationDeckScreen> createState() =>
      _OrganizationDeckScreenState();
}

class _OrganizationDeckScreenState
    extends ConsumerState<OrganizationDeckScreen> {
  bool _isSubViewActive = false;

  Future<void> _confirmExitWorkstation(BuildContext context) async {
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
  Widget build(BuildContext context) {
    final session = ref.watch(organizationSessionProvider);
    final orgName = (session.orgName != null && session.orgName!.trim().isNotEmpty)
        ? session.orgName!.trim()
        : 'Sanctioning Organization';
    final orgId = session.orgId ?? '';
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
          // Streamlined Executive Header: ONLY rendered on the main list screen!
          // Hidden completely on all sub-screens (Card 1 setup, Hub, Brackets, Weigh-ins, etc.)
          if (!_isSubViewActive)
            _buildMinimalTopHeader(context, session, orgName, orgId, jurisdiction),

          // Autonomous 4-Stage Tournament Operator Workstation Body
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: !_isSubViewActive,
              child: TournamentOperatorDashboardScreen(
                organizationId: orgId,
                organizationName: orgName,
                embeddedInOrganizationDeck: true,
                onSubViewChanged: (isSub) {
                  if (_isSubViewActive != isSub) {
                    setState(() {
                      _isSubViewActive = isSub;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalTopHeader(
    BuildContext context,
    OrganizationSessionState session,
    String orgName,
    String orgId,
    String jurisdiction,
  ) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      padding: EdgeInsets.fromLTRB(16, topPadding + 6, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0C101A),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.goldPrimary.withValues(alpha: 0.25),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Compact Organization Emblem (34x34)
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF141A28),
              border: Border.all(
                color: AppTheme.goldPrimary.withValues(alpha: 0.75),
                width: 1.2,
              ),
            ),
            child: const Icon(
              Icons.account_balance_rounded,
              color: AppTheme.goldPrimary,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),

          // Organization Name & Status subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  orgName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      size: 11,
                      color: AppTheme.goldPrimary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        jurisdiction.isNotEmpty
                            ? '$jurisdiction • Sanctioning Body'
                            : 'Verified Sanctioning Body',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTheme.fontBody,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Compact Sync / Refresh Action
          IconButton(
            key: const ValueKey('org_deck_refresh_button'),
            tooltip: 'Sync & Refresh Events',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF131A29),
              side: BorderSide(
                color: AppTheme.emerald.withValues(alpha: 0.4),
                width: 0.9,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
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
              size: 17,
            ),
          ),
          const SizedBox(width: 6),

          // Compact Lock / Exit Action
          IconButton(
            key: const ValueKey('org_deck_lock_exit_button'),
            tooltip: 'Lock & Exit Workstation',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0x22EF4444),
              side: BorderSide(
                color: AppTheme.crimson.withValues(alpha: 0.5),
                width: 0.9,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => _confirmExitWorkstation(context),
            icon: const Icon(
              Icons.lock_outline_rounded,
              color: AppTheme.crimson,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}
