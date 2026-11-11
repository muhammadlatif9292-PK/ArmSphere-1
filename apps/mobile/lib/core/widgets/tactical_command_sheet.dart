import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../constants/asset_paths.dart';
import '../theme/app_theme.dart';
import 'armsphere_image.dart';
import 'pulse_indicator.dart';
import 'tactile_press_wrapper.dart';

/// 1-Tap Tactical Command & Role Switcher Sheet ("Void & Titanium" Luxury System)
///
/// Provides instant 1-tap access from anywhere in the Flutter application to:
/// 1. Active Persona & Role Switching (Athlete, Referee Official, Tournament Ops, Governance)
/// 2. Arena & Matchups (Head-to-Head Compare, Championship Belts, Awards Ceremony, Official Scorepad)
/// 3. Officiating & Operations (Tournament Weigh-In, Brackets, Evidence Upload, Certifications)
/// 4. Federation & Governance (Governance Console, File Dispute, Bulletins, Talent Nominations)
/// 5. Ecosystem & Vault (Teams & Clubs, Verified Venues, Pickup Sparring, ELO Rankings, Inbox, Vault)
class TacticalCommandSheet extends ConsumerWidget {
  const TacticalCommandSheet({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (_) => const TacticalCommandSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final activeRole = (authState.activeRole ??
            authState.userProfile?['role']?.toString() ??
            'ATHLETE')
        .toUpperCase();
    final verifiedRoles = authState.verifiedRoles
        .map((r) => r.toUpperCase())
        .toSet();

    return DraggableScrollableSheet(
      initialChildSize: 0.86,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xF0090D16),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(
                  color: AppTheme.goldPrimary.withValues(alpha: 0.25),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.65),
                    blurRadius: 28,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag Handle & Header Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
                    child: Column(
                      children: [
                        Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.goldPrimary.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppTheme.goldPrimary.withValues(alpha: 0.35),
                                ),
                              ),
                              child: const Icon(
                                Icons.grid_view_rounded,
                                size: 18,
                                color: AppTheme.goldPrimary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'TACTICAL COMMAND HUB',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      letterSpacing: 0.6,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const PulseIndicator(
                                        color: AppTheme.goldPrimary,
                                        size: 6.0,
                                        semanticLabel: 'Active persona status',
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          'ACTIVE MODE · $activeRole',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontFamily: AppTheme.fontDisplay,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                            color: AppTheme.goldPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Global Search',
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                Navigator.of(context).pop();
                                context.push('/search');
                              },
                              icon: const Icon(
                                Icons.search_rounded,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Close Command Hub',
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                Navigator.of(context).pop();
                              },
                              icon: const Icon(
                                Icons.close_rounded,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppTheme.obsidianRimBorder),
                  // Scrollable Command Matrix
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
                      children: [
                        // 1. Persona & Role Switcher Strip
                        _buildSectionHeader(
                          title: 'PERSONA & ROLE SWITCHER',
                          badge: 'INSTANT DISPATCH',
                          actionLabel: 'Manage Roles',
                          onActionTap: () {
                            Navigator.of(context).pop();
                            context.push('/settings/roles');
                          },
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _PersonaChip(
                                label: 'Athlete Hub',
                                roleKey: 'ATHLETE',
                                icon: Icons.fitness_center_rounded,
                                isActive: activeRole == 'ATHLETE',
                                isVerified: verifiedRoles.contains('ATHLETE') ||
                                    verifiedRoles.isEmpty,
                                onTap: () => _handleRoleSwitch(
                                  context,
                                  ref,
                                  roleKey: 'ATHLETE',
                                  targetRoute: '/athlete/dashboard',
                                  isVerified: verifiedRoles.contains('ATHLETE'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _PersonaChip(
                                label: 'Referee Official',
                                roleKey: 'REFEREE',
                                icon: Icons.sports_rounded,
                                isActive: activeRole == 'REFEREE',
                                isVerified: verifiedRoles.contains('REFEREE'),
                                onTap: () => _handleRoleSwitch(
                                  context,
                                  ref,
                                  roleKey: 'REFEREE',
                                  targetRoute: '/referee/dashboard',
                                  isVerified: verifiedRoles.contains('REFEREE'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _PersonaChip(
                                label: 'Tournament Ops',
                                roleKey: 'TOURNAMENT_OPERATOR',
                                icon: Icons.event_available_rounded,
                                isActive: activeRole == 'TOURNAMENT_OPERATOR',
                                isVerified: verifiedRoles.contains('TOURNAMENT_OPERATOR'),
                                onTap: () => _handleRoleSwitch(
                                  context,
                                  ref,
                                  roleKey: 'TOURNAMENT_OPERATOR',
                                  targetRoute: '/governance',
                                  isVerified:
                                      verifiedRoles.contains('TOURNAMENT_OPERATOR'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _PersonaChip(
                                label: 'Federation Admin',
                                roleKey: 'SYSTEM_ADMIN',
                                icon: Icons.shield_outlined,
                                isActive: activeRole == 'SYSTEM_ADMIN' ||
                                    activeRole == 'NATIONAL_DIRECTOR' ||
                                    activeRole == 'PROVINCIAL_DIRECTOR',
                                isVerified: verifiedRoles.contains('SYSTEM_ADMIN') ||
                                    verifiedRoles.contains('NATIONAL_DIRECTOR') ||
                                    verifiedRoles.contains('PROVINCIAL_DIRECTOR'),
                                onTap: () => _handleRoleSwitch(
                                  context,
                                  ref,
                                  roleKey: 'SYSTEM_ADMIN',
                                  targetRoute: '/governance',
                                  isVerified: verifiedRoles.contains('SYSTEM_ADMIN'),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        // 2. Arena & Matchups
                        _buildSectionHeader(
                          title: 'ARENA & SUPERMATCHES',
                          badge: 'LIVE COMBAT TELEMETRY',
                        ),
                        const SizedBox(height: 10),
                        _buildCommandGrid(
                          context,
                          items: const [
                            _CommandTileSpec(
                              title: 'Head-to-Head VS',
                              kicker: 'TALE OF THE TAPE · ODDS',
                              route: '/matches/head-to-head',
                              assetPath: ArmSphereAssets.cardSupermatchVs,
                              focal: Alignment.center,
                              accentColor: AppTheme.primaryAccent,
                              isLive: true,
                            ),
                            _CommandTileSpec(
                              title: 'Championship Belts',
                              kicker: 'LINEAL TITLES · HOLDERS',
                              route: '/championship/titles',
                              assetPath: ArmSphereAssets.stageChampionshipBelts9x16,
                              focal: ArmSphereAssets.stageTopFocal,
                              accentColor: AppTheme.goldPrimary,
                            ),
                            _CommandTileSpec(
                              title: 'Awards Podium',
                              kicker: 'CEREMONY · MEDALISTS',
                              route: '/awards',
                              assetPath: ArmSphereAssets.stageChampionshipBelts9x16,
                              focal: Alignment.center,
                              accentColor: AppTheme.goldPrimary,
                            ),
                            _CommandTileSpec(
                              title: 'Official Scorepad',
                              kicker: 'TABLE CONTROL · FOULS',
                              route: '/referee/scorepad',
                              assetPath: ArmSphereAssets.stageReferee9x16,
                              focal: ArmSphereAssets.walkoutFocal,
                              accentColor: AppTheme.cyanAccent,
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),

                        // 3. Officiating & Tournament Operations
                        _buildSectionHeader(
                          title: 'TOURNAMENT & TABLE OPS',
                          badge: 'DIRECTOR & REFEREE TOOLS',
                        ),
                        const SizedBox(height: 10),
                        _buildCommandGrid(
                          context,
                          items: const [
                            _CommandTileSpec(
                              title: 'Weigh-In Console',
                              kicker: 'SCALE CLEARANCE · CLASSES',
                              route: '/weigh-in',
                              assetPath: ArmSphereAssets.stageArena9x16,
                              focal: ArmSphereAssets.stageTopFocal,
                              accentColor: AppTheme.goldPrimary,
                            ),
                            _CommandTileSpec(
                              title: 'Event Brackets',
                              kicker: 'LIVE TREES · REGISTRATIONS',
                              route: '/tournaments',
                              assetPath: ArmSphereAssets.tournamentPoster,
                              focal: ArmSphereAssets.posterTopFocal,
                              accentColor: AppTheme.primaryAccent,
                            ),
                            _CommandTileSpec(
                              title: 'Evidence Vault',
                              kicker: 'VIDEO · SCOREPAD PROOF',
                              route: '/referee/upload-evidence',
                              assetPath: ArmSphereAssets.clipFallbackMatch,
                              focal: Alignment.center,
                              accentColor: AppTheme.cyanAccent,
                            ),
                            _CommandTileSpec(
                              title: 'Certifications',
                              kicker: 'REFEREE GRADE · BADGES',
                              route: '/referee/certifications',
                              assetPath: ArmSphereAssets.stagePassportVault9x16,
                              focal: ArmSphereAssets.stageTopFocal,
                              accentColor: AppTheme.goldPrimary,
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),

                        // 4. Federation Governance & Scouting
                        _buildSectionHeader(
                          title: 'FEDERATION & GOVERNANCE',
                          badge: 'COMPLIANCE & SCOUTING',
                        ),
                        const SizedBox(height: 10),
                        _buildCommandGrid(
                          context,
                          items: const [
                            _CommandTileSpec(
                              title: 'Governance Hub',
                              kicker: 'DISPUTES · AUDIT LEDGER',
                              route: '/governance',
                              assetPath: ArmSphereAssets.stageAdminGovernance9x16,
                              focal: ArmSphereAssets.stageTopFocal,
                              accentColor: AppTheme.goldPrimary,
                            ),
                            _CommandTileSpec(
                              title: 'File Official Protest',
                              kicker: 'TRIBUNAL · MATCH REVIEW',
                              route: '/governance/submit-complaint',
                              assetPath: ArmSphereAssets.cardStandbyTable,
                              focal: Alignment.center,
                              accentColor: AppTheme.primaryAccent,
                            ),
                            _CommandTileSpec(
                              title: 'Official Bulletins',
                              kicker: 'CIRCULARS · RULEBOOK',
                              route: '/announcements',
                              assetPath: ArmSphereAssets.cardLiveBroadcast,
                              focal: Alignment.center,
                              accentColor: AppTheme.cyanAccent,
                            ),
                            _CommandTileSpec(
                              title: 'Talent Nominations',
                              kicker: 'GRASSROOTS · SCOUTING',
                              route: '/nominations/my',
                              assetPath: ArmSphereAssets.bentoEloRankings,
                              focal: ArmSphereAssets.bentoRankingsFocal,
                              accentColor: AppTheme.goldPrimary,
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),

                        // 5. Ecosystem, Clubs & Security Vault
                        _buildSectionHeader(
                          title: 'ECOSYSTEM & ATHLETE VAULT',
                          badge: 'CLUBS · VENUES · SECURITY',
                        ),
                        const SizedBox(height: 10),
                        _buildCommandGrid(
                          context,
                          items: const [
                            _CommandTileSpec(
                              title: 'Teams & Factions',
                              kicker: 'CLUB ROSTERS · CAPTAINS',
                              route: '/teams',
                              assetPath: ArmSphereAssets.stageTeams9x16,
                              focal: ArmSphereAssets.stageTopFocal,
                              accentColor: AppTheme.goldPrimary,
                            ),
                            _CommandTileSpec(
                              title: 'Verified Venues',
                              kicker: 'GYM TABLES · RADAR',
                              route: '/venues',
                              assetPath: ArmSphereAssets.bentoVenues,
                              focal: Alignment.center,
                              accentColor: AppTheme.cyanAccent,
                            ),
                            _CommandTileSpec(
                              title: 'Pickup Sparring',
                              kicker: 'OPEN TABLES · RSVP',
                              route: '/informal-events',
                              assetPath: ArmSphereAssets.bentoPickupSparring,
                              focal: Alignment.center,
                              accentColor: AppTheme.primaryAccent,
                            ),
                            _CommandTileSpec(
                              title: 'ELO Leaderboard',
                              kicker: 'PROVINCIAL · NATIONAL',
                              route: '/rankings',
                              assetPath: ArmSphereAssets.bentoEloRankings,
                              focal: ArmSphereAssets.bentoRankingsFocal,
                              accentColor: AppTheme.goldPrimary,
                            ),
                            _CommandTileSpec(
                              title: 'Athlete Inbox',
                              kicker: 'DIRECT CHAT · SPARRING',
                              route: '/messages',
                              assetPath: ArmSphereAssets.bentoCommunityFeed,
                              focal: Alignment.center,
                              accentColor: AppTheme.cyanAccent,
                            ),
                            _CommandTileSpec(
                              title: 'Security & Vault',
                              kicker: 'SESSIONS · ROLES & KEYS',
                              route: '/settings',
                              assetPath: ArmSphereAssets.stagePassportVault9x16,
                              focal: ArmSphereAssets.stageTopFocal,
                              accentColor: AppTheme.goldPrimary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleRoleSwitch(
    BuildContext context,
    WidgetRef ref, {
    required String roleKey,
    required String targetRoute,
    required bool isVerified,
  }) async {
    HapticFeedback.selectionClick();
    if (isVerified) {
      try {
        await ref.read(authProvider.notifier).switchActiveRole(roleKey);
      } catch (_) {}
    }
    if (context.mounted) {
      Navigator.of(context).pop();
      context.push(targetRoute);
    }
  }

  Widget _buildSectionHeader({
    required String title,
    required String badge,
    String? actionLabel,
    VoidCallback? onActionTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        if (actionLabel != null && onActionTap != null)
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onActionTap();
            },
            child: Text(
              actionLabel,
              style: const TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.goldPrimary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCommandGrid(
    BuildContext context, {
    required List<_CommandTileSpec> items,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.72,
      ),
      itemBuilder: (context, index) {
        final spec = items[index];
        return _CommandBentoTile(
          spec: spec,
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).pop();
            context.push(spec.route);
          },
        );
      },
    );
  }
}

class _PersonaChip extends StatelessWidget {
  final String label;
  final String roleKey;
  final IconData icon;
  final bool isActive;
  final bool isVerified;
  final VoidCallback onTap;

  const _PersonaChip({
    required this.label,
    required this.roleKey,
    required this.icon,
    required this.isActive,
    required this.isVerified,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TactilePressWrapper(
      onTap: onTap,
      semanticLabel: 'Switch to $label mode',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? AppTheme.goldPrimary
                : const Color(0x38FFFFFF),
            width: isActive ? 1.3 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? AppTheme.goldPrimary : AppTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 12.5,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive ? AppTheme.goldPrimary : AppTheme.textPrimary,
              ),
            ),
            if (isVerified) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.verified_rounded,
                size: 13,
                color: isActive ? AppTheme.goldPrimary : AppTheme.cyanAccent,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CommandTileSpec {
  final String title;
  final String kicker;
  final String route;
  final String assetPath;
  final Alignment focal;
  final Color accentColor;
  final bool isLive;

  const _CommandTileSpec({
    required this.title,
    required this.kicker,
    required this.route,
    required this.assetPath,
    required this.focal,
    required this.accentColor,
    this.isLive = false,
  });
}

class _CommandBentoTile extends StatelessWidget {
  final _CommandTileSpec spec;
  final VoidCallback onTap;

  const _CommandBentoTile({
    required this.spec,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TactilePressWrapper(
      onTap: onTap,
      semanticLabel: spec.title,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0x38FFFFFF),
            width: 1.0,
          ),
          boxShadow: const [],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: ArmSphereImage(
                assetPath: spec.assetPath,
                alignment: spec.focal,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
                showLoadingIndicator: false,
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.52, 1.0],
                    colors: [
                      Color(0x00000000),
                      Color(0x40000000),
                      Color(0xB3000000),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          spec.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: AppTheme.textPrimary,
                            shadows: AppTheme.crystalTextShadows,
                          ),
                        ),
                      ),
                      if (spec.isLive) ...[
                        const SizedBox(width: 6),
                        const PulseIndicator(
                          color: AppTheme.primaryAccent,
                          size: 6.0,
                          semanticLabel: 'Live matchup telemetry',
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
