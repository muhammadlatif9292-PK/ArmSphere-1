import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/armsphere_image.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
import '../../../core/widgets/achievements_section.dart';
import '../../../core/providers/athlete_provider.dart';
import '../../../core/providers/live_matches_provider.dart';

const Map<int, String> _months = {
  1: 'Jan', 2: 'Feb', 3: 'Mar', 4: 'Apr', 5: 'May', 6: 'Jun',
  7: 'Jul', 8: 'Aug', 9: 'Sep', 10: 'Oct', 11: 'Nov', 12: 'Dec',
};

String _fmtDate(dynamic iso) {
  final d = DateTime.tryParse(iso?.toString() ?? '');
  if (d == null) return '';
  return '${d.day} ${_months[d.month] ?? ''} ${d.year}';
}

/// Athlete Dashboard Screen (Canary 2 Specification)
///
/// Grounded in:
/// - `docs/design/69_CANARY_IMPLEMENTATION_SPEC.md#canary-2`
/// - `docs/design/66_ARMSPHERE_SIGNATURE_INTERACTIONS.md` (SIG-3, SIG-4, SIG-7)
/// - `docs/design/68_PREMIUM_EXPERIENCE_CONVERGENCE.md` (Unbundled Surface Architecture)
/// - `docs/design/71_ARMSPHERE_DREAM_GOAL_AND_ANTI_DRIFT_CONSTITUTION.md`
class AthleteDashboardScreen extends ConsumerWidget {
  const AthleteDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profile = authState.userProfile ?? {};
    final displayName = profile['displayName'] ?? 'Athlete';
    final role = profile['role']?.toString().toUpperCase();
    const officialRoles = {'REFEREE', 'PROVINCIAL_DIRECTOR', 'NATIONAL_DIRECTOR', 'SYSTEM_ADMIN'};
    final isOfficial = role != null && officialRoles.contains(role);
    final profileAsync = ref.watch(athleteProfileProvider);
    final myProfileId = profileAsync.value?['id']?.toString() ?? profile['id']?.toString();
    final matchesAsync = ref.watch(liveMatchesProvider);
    final prsAsync = myProfileId == null
        ? const AsyncValue<List<Map<String, dynamic>>>.data([])
        : ref.watch(trainingLogPRsProvider(myProfileId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        color: AppTheme.goldPrimary,
        backgroundColor: AppTheme.cardSurface,
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          ref.invalidate(athleteProfileProvider);
          ref.invalidate(liveMatchesProvider);
          if (myProfileId != null) {
            ref.invalidate(trainingLogPRsProvider(myProfileId));
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Central Command Header with Live Sync Indicator & Athlete Identity
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.success,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'FEDERATION CENTRAL COMMAND',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none_outlined, color: AppTheme.textSecondary),
                        tooltip: 'Notifications',
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          context.push('/notifications');
                        },
                      ),
                      const SizedBox(width: 4),
                      ArmSphereImage.avatar(
                        imageUrl: profile['avatarUrl']?.toString(),
                        initial: displayName,
                        size: 34,
                        fallbackAsset: ArmSphereAssets.defaultAvatar,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          context.push('/athlete/profile');
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Sanctioned Arena Environmental Anchor (M1-HERO-ARENA)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                child: Container(
                  height: 110,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(
                      color: AppTheme.borderSubtle,
                      width: 1.0,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Arena Background
                      Positioned.fill(
                        child: ArmSphereImage(
                          assetPath: ArmSphereAssets.heroArena,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 110,
                          excludeFromSemantics: true,
                        ),
                      ),
                      // Text-protection gradient scrim
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Color(0xF2070A11), // 95% obsidian under text
                                Color(0xAA070A11),
                                Color(0x33070A11),
                              ],
                              stops: [0.0, 0.6, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // Content overlay
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppTheme.goldPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          'SANCTIONED ARENA RADAR',
                                          style: TextStyle(
                                            fontFamily: AppTheme.fontDisplay,
                                            letterSpacing: 0.8,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 9.5,
                                            color: AppTheme.goldPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Championship Arena Active',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Official tournament brackets & table calls',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedActionCard(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  context.push('/tournaments');
                                },
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Explore',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                        color: AppTheme.goldPrimary,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(Icons.arrow_forward_ios, size: 10, color: AppTheme.goldPrimary),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // 2. Competitive ELO Rating with Arm-Switch Flip (SIG-4 & SIG-3)
              const Text(
                'COMPETITIVE STANDING',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              profileAsync.when(
                loading: () => const ElevatedActionCard(
                  padding: EdgeInsets.all(20),
                  child: SizedBox(
                    height: 120,
                    child: Center(
                      child: CircularProgressIndicator(color: AppTheme.goldPrimary),
                    ),
                  ),
                ),
                error: (err, _) => ElevatedActionCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'Could not load your rating',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => ref.invalidate(athleteProfileProvider),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (p) => ArmSwitchEloCard(profileData: p),
              ),
              const SizedBox(height: 22),

              // 3. Quick Action Commands (Tactile Grid)
              const Text(
                'QUICK COMMANDS',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.3,
                children: [
                  if (isOfficial)
                    _ShortcutButton(
                      icon: Icons.sports,
                      label: 'Referee Console',
                      color: AppTheme.info,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        context.push('/referee/dashboard');
                      },
                    ),
                  _ShortcutButton(
                    icon: Icons.sports_kabaddi,
                    label: 'Scorepad Entry',
                    color: AppTheme.goldPrimary,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.push('/referee/submit-scorepad');
                    },
                  ),
                  _ShortcutButton(
                    icon: Icons.emoji_events_outlined,
                    label: 'Tournaments',
                    color: AppTheme.goldPrimary,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.push('/tournaments');
                    },
                  ),
                  _ShortcutButton(
                    icon: Icons.fitness_center,
                    label: 'Training Log',
                    color: AppTheme.success,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.push(myProfileId != null ? '/athlete/$myProfileId/training-log' : '/athlete/profile');
                    },
                  ),
                  _ShortcutButton(
                    icon: Icons.group_outlined,
                    label: 'Clubs & Teams',
                    color: AppTheme.info,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.push('/teams');
                    },
                  ),
                  _ShortcutButton(
                    icon: Icons.inbox_outlined,
                    label: 'Messages',
                    color: AppTheme.textSecondary,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.push('/messages');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // 4. Recent Verified Matches (Unbundled Editorial Plane)
              const Text(
                'RECENT VERIFIED MATCHES',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              matchesAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: AppTheme.goldPrimary),
                  ),
                ),
                error: (err, _) => Column(
                  children: [
                    const Text('Could not load matches', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.invalidate(liveMatchesProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
                data: (matches) {
                  if (matches.isEmpty) {
                    return const ElevatedActionCard(
                      padding: EdgeInsets.all(18),
                      child: Center(
                        child: Text(
                          'No verified matches yet — compete in sanctioned events to record results.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  final recent = matches.take(5).toList();
                  return ElevatedActionCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (int i = 0; i < recent.length; i++) ...[
                          if (i > 0) const Divider(height: 1, color: AppTheme.borderSubtle),
                          _DashboardMatchRow(
                            match: recent[i],
                            myProfileId: myProfileId,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 22),

              // 5. Personal Records (Tabular Numbers)
              prsAsync.maybeWhen(
                data: (prs) {
                  if (prs.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PERSONAL RECORDS & LIFTS',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final pr in prs)
                            ElevatedActionCard(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _prettyExercise(pr['exerciseType']?.toString()),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${(pr['weightKg'] as num?)?.toInt() ?? '—'} kg',
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.goldPrimary,
                                      fontFeatures: [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  static String _prettyExercise(String? raw) {
    if (raw == null || raw.isEmpty) return 'Exercise';
    return raw
        .toLowerCase()
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

/// Unbundled Editorial Match Row for Dashboard
class _DashboardMatchRow extends StatelessWidget {
  final Map<String, dynamic> match;
  final String? myProfileId;

  const _DashboardMatchRow({
    required this.match,
    required this.myProfileId,
  });

  @override
  Widget build(BuildContext context) {
    final winnerId = match['winnerId']?.toString();
    final isWin = myProfileId != null && winnerId == myProfileId;
    final decided = winnerId != null && winnerId.isNotEmpty;
    final arm = match['arm']?.toString().toUpperCase() ?? 'RIGHT';
    final dateStr = _fmtDate(match['verifiedAt'] ?? match['createdAt']);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: arm == 'LEFT'
                  ? AppTheme.info.withValues(alpha: 0.12)
                  : AppTheme.goldPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.sports_kabaddi,
              size: 16,
              color: arm == 'LEFT' ? AppTheme.info : AppTheme.goldPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'vs ${match['opponentName'] ?? 'Unknown Competitor'}',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    '$arm ARM',
                    if (dateStr.isNotEmpty) dateStr,
                  ].join(' • '),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!decided)
            const StatusChip.neutral(label: 'SCHEDULED')
          else if (isWin)
            const StatusChip.success(label: 'VICTORY')
          else
            const StatusChip.error(label: 'DEFEAT'),
        ],
      ),
    );
  }
}

/// Helper Shortcut Button with ElevatedActionCard styling & Tactile Feedback
class _ShortcutButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShortcutButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedActionCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dual-Role Persona Switcher Component
///
/// Grounded in:
/// - `docs/design/27_UI_UX_IMPLEMENTATION_BACKLOG.md` ([P0-03])
/// - `docs/design/31_ACTION_CHOREOGRAPHY.md` (Surface 9)
/// - `docs/design/39_DESIGN_DEBT_MAP.md` (Domain 5)
class DualRolePersonaSwitcher extends StatelessWidget {
  final bool isOfficial;
  final String role;
  final VoidCallback onSelectOfficial;
  final VoidCallback onSelectAthlete;
  final bool isOfficialActive;

  const DualRolePersonaSwitcher({
    super.key,
    required this.isOfficial,
    required this.role,
    required this.onSelectOfficial,
    required this.onSelectAthlete,
    this.isOfficialActive = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOfficial) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.goldPrimary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_user_outlined, size: 16, color: AppTheme.goldPrimary),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Certified National Competitor',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'Sanctioned Armwrestling Athlete Profile',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                context.push('/governance');
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Get Certified',
                style: TextStyle(fontSize: 11, color: AppTheme.goldPrimary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.voidBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        children: [
          // 1. Athlete Mode Pill
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                onSelectAthlete();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: !isOfficialActive ? AppTheme.elevatedSurface : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: !isOfficialActive
                      ? Border.all(color: AppTheme.goldPrimary.withValues(alpha: 0.5), width: 1)
                      : null,
                  boxShadow: !isOfficialActive
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 15,
                      color: !isOfficialActive ? AppTheme.goldPrimary : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Athlete Mode',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 12,
                        fontWeight: !isOfficialActive ? FontWeight.w700 : FontWeight.w500,
                        color: !isOfficialActive ? AppTheme.goldPrimary : AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),

          // 2. Official / Referee Mode Pill
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                onSelectOfficial();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isOfficialActive ? AppTheme.elevatedSurface : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: isOfficialActive
                      ? Border.all(color: AppTheme.info.withValues(alpha: 0.5), width: 1)
                      : null,
                  boxShadow: isOfficialActive
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.gavel_rounded,
                      size: 15,
                      color: isOfficialActive ? AppTheme.info : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Official Mode',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 12,
                        fontWeight: isOfficialActive ? FontWeight.w700 : FontWeight.w500,
                        color: isOfficialActive ? AppTheme.info : AppTheme.textMuted,
                      ),
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
}

/// Athlete Profile Tab Screen (Canary 3 Specification)
///
/// Grounded in:
/// - `docs/design/69_CANARY_IMPLEMENTATION_SPEC.md#canary-3`
/// - `docs/design/66_ARMSPHERE_SIGNATURE_INTERACTIONS.md` (SIG-3 & SIG-4)
/// - `docs/design/68_PREMIUM_EXPERIENCE_CONVERGENCE.md` (Unbundled Surface Architecture)
/// - `docs/design/71_ARMSPHERE_DREAM_GOAL_AND_ANTI_DRIFT_CONSTITUTION.md`
class AthleteProfileScreen extends ConsumerWidget {
  const AthleteProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profile = authState.userProfile ?? {};
    final displayName = profile['displayName'] ?? 'Athlete';
    final email = profile['email'] ?? '';
    final role = profile['role']?.toString().toUpperCase() ?? 'ATHLETE';
    const officialRoles = {'REFEREE', 'PROVINCIAL_DIRECTOR', 'NATIONAL_DIRECTOR', 'SYSTEM_ADMIN'};
    final isOfficial = officialRoles.contains(role);

    final profileAsync = ref.watch(athleteProfileProvider);
    final myProfileId = profileAsync.value?['id']?.toString() ?? profile['id']?.toString();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.voidBackground,
        elevation: 0,
        title: const Text(
          'Athlete Profile',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.textSecondary),
            tooltip: 'Settings',
            onPressed: () {
              HapticFeedback.selectionClick();
              context.push('/settings');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Athlete Identity Header with 2px Role-Coded Ring
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isOfficial ? AppTheme.info : AppTheme.goldPrimary,
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isOfficial ? AppTheme.info : AppTheme.goldPrimary).withValues(alpha: 0.25),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: AppTheme.elevatedSurface,
                    backgroundImage: (profile['profilePhoto'] != null && profile['profilePhoto'].toString().isNotEmpty)
                        ? NetworkImage(profile['profilePhoto'].toString())
                        : null,
                    onBackgroundImageError: (profile['profilePhoto'] != null && profile['profilePhoto'].toString().isNotEmpty)
                        ? (_, __) {}
                        : null,
                    child: (profile['profilePhoto'] != null && profile['profilePhoto'].toString().isNotEmpty)
                        ? null
                        : Icon(
                            Icons.person,
                            size: 36,
                            color: isOfficial ? AppTheme.info : AppTheme.goldPrimary,
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          StatusChip.info(label: role),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        email.isEmpty ? 'Federation Member' : email,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.verified,
                            size: 14,
                            color: isOfficial ? AppTheme.info : AppTheme.goldPrimary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOfficial ? 'Certified Federation Official' : 'Official PAFF Competitor',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isOfficial ? AppTheme.info : AppTheme.goldPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. Dual-Role Persona Switcher Toggle
            DualRolePersonaSwitcher(
              isOfficial: isOfficial,
              role: role,
              isOfficialActive: false,
              onSelectAthlete: () {
                // Already in Athlete profile
              },
              onSelectOfficial: () {
                context.push('/referee/dashboard');
              },
            ),
            const SizedBox(height: 20),

            // 3. Competitive ELO Rating with Arm-Switch Flip (SIG-4 & SIG-3)
            const Text(
              'COMPETITIVE ELO RATING',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 10),
            profileAsync.when(
              loading: () => const ElevatedActionCard(
                padding: EdgeInsets.all(20),
                child: SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary)),
                ),
              ),
              error: (_, __) => ArmSwitchEloCard(profileData: profile),
              data: (p) => ArmSwitchEloCard(profileData: p),
            ),
            const SizedBox(height: 22),

            // 4. Biometrics & Specifications (Unbundled Plane)
            const Text(
              'BIOMETRICS & SPECIFICATIONS',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 10),
            profileAsync.when(
              loading: () => const ElevatedActionCard(
                padding: EdgeInsets.all(16),
                child: SizedBox(height: 50, child: Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary))),
              ),
              error: (_, __) => _buildBiometricsCard(profile),
              data: (p) => _buildBiometricsCard(p),
            ),
            const SizedBox(height: 22),

            // 5. Account & Federation Workspaces
            const Text(
              'ACCOUNT & FEDERATION WORKSPACES',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedActionCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _WorkspaceTile(
                    icon: Icons.fitness_center,
                    iconColor: AppTheme.goldPrimary,
                    title: 'Training Log & PR Tracker',
                    subtitle: 'Cupping, pronation & rising personal records',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.push(myProfileId != null ? '/athlete/$myProfileId/training-log' : '/settings');
                    },
                  ),
                  const Divider(height: 1, color: AppTheme.borderSubtle),
                  _WorkspaceTile(
                    icon: Icons.military_tech_outlined,
                    iconColor: AppTheme.goldPrimary,
                    title: 'Athletic Honors & Achievements',
                    subtitle: 'Certified championship medals and trophies',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.push('/athlete/achievements');
                    },
                  ),
                  if (isOfficial) ...[
                    const Divider(height: 1, color: AppTheme.borderSubtle),
                    _WorkspaceTile(
                      icon: Icons.gavel_rounded,
                      iconColor: AppTheme.info,
                      title: 'Referee & Operations Console',
                      subtitle: 'Live table scorepad & event management',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        context.push('/referee/dashboard');
                      },
                    ),
                  ],
                  const Divider(height: 1, color: AppTheme.borderSubtle),
                  _WorkspaceTile(
                    icon: Icons.settings_outlined,
                    iconColor: AppTheme.textSecondary,
                    title: 'Account & Security Settings',
                    subtitle: 'Security, notifications, payments and privacy',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.push('/settings');
                    },
                  ),
                  const Divider(height: 1, color: AppTheme.borderSubtle),
                  _WorkspaceTile(
                    icon: Icons.logout,
                    iconColor: AppTheme.error,
                    title: 'Log Out',
                    subtitle: null,
                    isDestructive: true,
                    onTap: () {
                      HapticFeedback.heavyImpact();
                      ref.read(authProvider.notifier).logout();
                      context.go('/login');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBiometricsCard(Map<String, dynamic> profile) {
    return ElevatedActionCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SpecItem(label: 'Weight', value: '${(profile['weightKg'] ?? profile['weight'] ?? 85).toString()}kg'),
          _SpecItem(label: 'Height', value: '${(profile['heightCm'] ?? profile['height'] ?? 182).toString()}cm'),
          _SpecItem(label: 'Reach', value: '${(profile['reachCm'] ?? profile['reach'] ?? 180).toString()}cm'),
          _SpecItem(label: 'Dominance', value: profile['armDominance']?.toString() ?? profile['dominantArm']?.toString() ?? 'RIGHT'),
        ],
      ),
    );
  }
}

/// Arm-Switch Interactive ELO Card (SIG-4 & SIG-3)
///
/// Implements:
/// - 3D Perspective Card Flip (240ms duration)
/// - Tabular monospace figures (zero jitter)
/// - Arm-specific ELO, division rank, and secondary arm status
/// - RepaintBoundary GPU isolation
class ArmSwitchEloCard extends StatefulWidget {
  final Map<String, dynamic> profileData;

  const ArmSwitchEloCard({super.key, required this.profileData});

  @override
  State<ArmSwitchEloCard> createState() => _ArmSwitchEloCardState();
}

class _ArmSwitchEloCardState extends State<ArmSwitchEloCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isRightArm = true;

  @override
  void initState() {
    super.initState();
    // Default to right arm or dominant arm
    final dominant = widget.profileData['armDominance']?.toString().toUpperCase() ??
        widget.profileData['dominantArm']?.toString().toUpperCase() ??
        'RIGHT';
    _isRightArm = !dominant.contains('LEFT');

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );

    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _flipController,
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggleArm(bool selectRight) {
    if (_isRightArm == selectRight) return;
    HapticFeedback.selectionClick();
    if (_flipController.isAnimating) return;

    if (_flipController.isCompleted) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }

    setState(() {
      _isRightArm = selectRight;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profileData;
    final rightElo = (p['rightArmElo'] as num?)?.toInt() ?? (p['eloRating'] as num?)?.toInt() ?? 1200;
    final leftElo = (p['leftArmElo'] as num?)?.toInt() ?? (p['eloRating'] as num?)?.toInt() ?? 1200;
    final weightClass = p['weightClass']?.toString();
    final division = p['division']?.toString() ?? 'Senior';

    final activeElo = _isRightArm ? rightElo : leftElo;
    final alternateElo = _isRightArm ? leftElo : rightElo;
    final activeArmLabel = _isRightArm ? 'RIGHT ARM' : 'LEFT ARM';
    final alternateArmLabel = _isRightArm ? 'LEFT ARM' : 'RIGHT ARM';
    final activeAccentColor = _isRightArm ? AppTheme.goldPrimary : AppTheme.info;

    return RepaintBoundary(
      child: ElevatedActionCard(
        padding: const EdgeInsets.all(18),
        borderColor: activeAccentColor.withValues(alpha: 0.35),
        child: Column(
          children: [
            // Top Row: Division Chip + Tactical Arm Switch Pills
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.elevatedSurface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    weightClass == null || weightClass.isEmpty
                        ? '$division • Open'
                        : '$division • $weightClass',
                    style: const TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                // Arm Switch Selector (SIG-4)
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.voidBackground,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ArmSelectorTab(
                        label: 'RIGHT',
                        isSelected: _isRightArm,
                        activeColor: AppTheme.goldPrimary,
                        onTap: () => _toggleArm(true),
                      ),
                      _ArmSelectorTab(
                        label: 'LEFT',
                        isSelected: !_isRightArm,
                        activeColor: AppTheme.info,
                        onTap: () => _toggleArm(false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Active ELO Display with 3D Flip Transform (SIG-4 & SIG-3)
            AnimatedBuilder(
              animation: _flipAnimation,
              builder: (context, child) {
                final angle = _flipAnimation.value * math.pi;
                // Avoid rendering reversed mirror text during flip
                final isUnder = angle > (math.pi / 2);

                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0015)
                    ..rotateY(angle),
                  alignment: Alignment.center,
                  child: isUnder
                      ? Transform(
                          transform: Matrix4.identity()..rotateY(math.pi),
                          alignment: Alignment.center,
                          child: _buildEloDisplayContent(
                            activeElo,
                            activeArmLabel,
                            activeAccentColor,
                          ),
                        )
                      : _buildEloDisplayContent(
                          activeElo,
                          activeArmLabel,
                          activeAccentColor,
                        ),
                );
              },
            ),
            const SizedBox(height: 14),

            // 1px Hairline Structural Divider
            const Divider(height: 1, color: AppTheme.borderSubtle),
            const SizedBox(height: 10),

            // Secondary Arm Fast-Affordance Strip
            TactilePressWrapper(
              onTap: () => _toggleArm(!_isRightArm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.swap_horiz,
                        size: 15,
                        color: _isRightArm ? AppTheme.info : AppTheme.goldPrimary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Switch to $alternateArmLabel',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isRightArm ? AppTheme.info : AppTheme.goldPrimary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$alternateElo pts',
                    style: const TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMuted,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEloDisplayContent(int elo, String armLabel, Color accentColor) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$elo',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: accentColor,
                letterSpacing: -0.5,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'ELO',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Official $armLabel Competitive Rating',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ArmSelectorTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _ArmSelectorTab({
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isSelected ? Border.all(color: activeColor.withValues(alpha: 0.5), width: 1) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? activeColor : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }
}

class _SpecItem extends StatelessWidget {
  final String label;
  final String value;

  const _SpecItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppTheme.textPrimary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
        ),
      ],
    );
  }
}

class _WorkspaceTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _WorkspaceTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return TactilePressWrapper(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDestructive ? AppTheme.error.withValues(alpha: 0.1) : AppTheme.elevatedSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDestructive ? AppTheme.error : AppTheme.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDestructive ? AppTheme.error.withValues(alpha: 0.6) : AppTheme.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Athlete Achievements Details Screen
class AthleteAchievementsScreen extends StatelessWidget {
  final String? athleteId;

  const AthleteAchievementsScreen({super.key, this.athleteId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Athletic Honors',
          style: TextStyle(fontFamily: 'Space Grotesk', fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            const AchievementsSection(),
            const SizedBox(height: 24),
            ElevatedActionCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.verified_outlined, size: 18, color: AppTheme.goldPrimary),
                      SizedBox(width: 8),
                      Text(
                        'Certified Honors Verification',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Achievements in ArmSphere are conferred automatically based on certified tournament reports, referee scorepads, and official ELO rating recalculations. Medals are secured cryptographically using SHA-256 state hashing to prevent tampering.',
                    style: TextStyle(height: 1.5, fontSize: 13, color: AppTheme.textSecondary),
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
