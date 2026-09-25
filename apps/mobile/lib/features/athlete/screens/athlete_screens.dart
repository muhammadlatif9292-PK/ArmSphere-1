import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
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

/// Athlete Dashboard Screen
class AthleteDashboardScreen extends ConsumerWidget {
  const AthleteDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final profile = authState.userProfile ?? {};
    final displayName = profile['displayName'] ?? 'Athlete';
    // Officials get a direct console entry on the home tab.
    final role = profile['role']?.toString().toUpperCase();
    const officialRoles = {'REFEREE', 'PROVINCIAL_DIRECTOR', 'NATIONAL_DIRECTOR', 'SYSTEM_ADMIN'};
    final isOfficial = role != null && officialRoles.contains(role);
    final profileAsync = ref.watch(athleteProfileProvider);
    // Match rows and PRs are keyed by the athlete PROFILE id, not the auth user id.
    final myProfileId = profileAsync.value?['id']?.toString() ?? profile['id']?.toString();
    final matchesAsync = ref.watch(liveMatchesProvider);
    final prsAsync = myProfileId == null
        ? const AsyncValue<List<Map<String, dynamic>>>.data([])
        : ref.watch(trainingLogPRsProvider(myProfileId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back,',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_none_outlined, color: AppTheme.textSecondary),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    context.push('/notifications');
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Rating specs Card — real per-arm ELO from the athlete profile API
            profileAsync.when(
              loading: () => const ElevatedActionCard(
                padding: EdgeInsets.all(20),
                child: SizedBox(
                  height: 100,
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
              data: (p) {
                final rightElo = (p['rightArmElo'] as num?)?.toInt() ?? 1200;
                final leftElo = (p['leftArmElo'] as num?)?.toInt() ?? 1200;
                final weightClass = p['weightClass']?.toString();
                final division = p['division']?.toString() ?? 'Senior';

                return ElevatedActionCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.military_tech_outlined, size: 16, color: AppTheme.goldPrimary),
                              SizedBox(width: 6),
                              Text(
                                'ELO RATING',
                                style: TextStyle(
                                  fontFamily: 'Space Grotesk',
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.elevatedSurface,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                              border: Border.all(color: AppTheme.goldPrimary.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              weightClass == null || weightClass.isEmpty
                                  ? '$division • Open Class'
                                  : '$division • $weightClass',
                              style: const TextStyle(
                                fontFamily: 'Space Grotesk',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.goldPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '$rightElo',
                                  style: const TextStyle(
                                    fontFamily: 'Space Grotesk',
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.goldPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Right Arm',
                                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          Container(height: 38, width: 1, color: AppTheme.borderSubtle),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '$leftElo',
                                  style: const TextStyle(
                                    fontFamily: 'Space Grotesk',
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Left Arm',
                                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 22),

            // Active Shortcuts Grid
            const Text(
              'QUICK SHORTCUTS',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
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
                  label: 'Competitions',
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

            // Recent verified matches
            const Text(
              'RECENT MATCHES',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            matchesAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
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
                    padding: EdgeInsets.all(16),
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
                return Column(
                  children: [
                    for (final m in recent)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ElevatedActionCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'vs ${m['opponentName'] ?? 'Unknown Competitor'}',
                                      style: const TextStyle(
                                        fontFamily: 'Space Grotesk',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: AppTheme.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      [
                                        m['arm']?.toString(),
                                        _fmtDate(m['verifiedAt'] ?? m['createdAt']),
                                      ].where((v) => v != null && v.isNotEmpty).join(' • '),
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              Builder(builder: (context) {
                                final winnerId = m['winnerId']?.toString();
                                final isWin = myProfileId != null && winnerId == myProfileId;
                                final decided = winnerId != null && winnerId.isNotEmpty;
                                if (!decided) {
                                  return const StatusChip.neutral(label: 'SCHEDULED');
                                }
                                return isWin
                                    ? const StatusChip.success(label: 'VICTORY')
                                    : const StatusChip.error(label: 'DEFEAT');
                              }),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 22),

            // Personal records
            prsAsync.maybeWhen(
              data: (prs) {
                if (prs.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PERSONAL RECORDS',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final pr in prs)
                          ElevatedActionCard(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                                    fontFamily: 'Space Grotesk',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.goldPrimary,
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
          ],
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

/// Helper Shortcut Button with ElevatedActionCard styling
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
                fontFamily: 'Space Grotesk',
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

/// Athlete Profile Tab Screen
/// Upgraded to Canonical Stage 2 Specification (Slice 7 / [P0-03]):
/// - 2px role-coded border ring around profile avatar.
/// - Dual-Role Persona Switcher toggle in header for certified officials.
/// - Elevated Space Grotesk 28sp ELO rating display badge.
/// - Normalized ElevatedActionCard components for biometrics and account settings.
class AthleteProfileScreen extends ConsumerWidget {
  const AthleteProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
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
        title: const Text(
          'Athlete Profile',
          style: TextStyle(fontFamily: 'Space Grotesk', fontWeight: FontWeight.w700),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Profile Header Row with 2px Role-Coded Avatar Ring
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
                    radius: 38,
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
                            size: 38,
                            color: isOfficial ? AppTheme.info : AppTheme.goldPrimary,
                          ),
                  ),
                ),
                const SizedBox(width: 16),
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
                                fontFamily: 'Space Grotesk',
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
                      const SizedBox(height: 4),
                      Text(
                        email.isEmpty ? 'Federation Member' : email,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
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
            const SizedBox(height: 18),

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

            // 3. Elevated ELO Rating Display Badge (Space Grotesk 28sp)
            profileAsync.when(
              loading: () => const ElevatedActionCard(
                padding: EdgeInsets.all(20),
                child: SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary)),
                ),
              ),
              error: (_, __) => _buildDefaultEloBadge(profile),
              data: (p) => _buildEloBadge(p),
            ),
            const SizedBox(height: 22),

            // 4. Biometrics & Specifications Card
            const Text(
              'BIOMETRICS & SPECIFICATIONS',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
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

            // 5. Account, Honor & Navigation Options
            const Text(
              'ACCOUNT & FEDERATION WORKSPACES',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
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
                  ListTile(
                    leading: const Icon(Icons.fitness_center, color: AppTheme.goldPrimary),
                    title: const Text(
                      'Training Log & PR Tracker',
                      style: TextStyle(fontFamily: 'Space Grotesk', fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: const Text('Cupping, pronation & rising personal records', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.push(myProfileId != null ? '/athlete/$myProfileId/training-log' : '/settings');
                    },
                  ),
                  const Divider(height: 1, color: AppTheme.borderSubtle),
                  ListTile(
                    leading: const Icon(Icons.military_tech_outlined, color: AppTheme.goldPrimary),
                    title: const Text(
                      'Athletic Honors & Achievements',
                      style: TextStyle(fontFamily: 'Space Grotesk', fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: const Text('Certified championship medals and trophies', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.push('/athlete/achievements');
                    },
                  ),
                  if (isOfficial) ...[
                    const Divider(height: 1, color: AppTheme.borderSubtle),
                    ListTile(
                      leading: const Icon(Icons.gavel_rounded, color: AppTheme.info),
                      title: const Text(
                        'Referee & Operations Console',
                        style: TextStyle(fontFamily: 'Space Grotesk', fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: const Text('Live table scorepad & event management', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                      trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        context.push('/referee/dashboard');
                      },
                    ),
                  ],
                  const Divider(height: 1, color: AppTheme.borderSubtle),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined, color: AppTheme.textSecondary),
                    title: const Text(
                      'Account & Security Settings',
                      style: TextStyle(fontFamily: 'Space Grotesk', fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: const Text('Security, notifications, payments and privacy', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.push('/settings');
                    },
                  ),
                  const Divider(height: 1, color: AppTheme.borderSubtle),
                  ListTile(
                    leading: const Icon(Icons.logout, color: AppTheme.error),
                    title: const Text(
                      'Log Out',
                      style: TextStyle(fontFamily: 'Space Grotesk', color: AppTheme.error, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
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

  Widget _buildEloBadge(Map<String, dynamic> p) {
    final rightElo = (p['rightArmElo'] as num?)?.toInt() ?? (p['eloRating'] as num?)?.toInt() ?? 1200;
    final leftElo = (p['leftArmElo'] as num?)?.toInt() ?? (p['eloRating'] as num?)?.toInt() ?? 1200;
    final weightClass = p['weightClass']?.toString();
    final division = p['division']?.toString() ?? 'Senior';

    return ElevatedActionCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.military_tech_outlined, size: 16, color: AppTheme.goldPrimary),
                  SizedBox(width: 6),
                  Text(
                    'COMPETITIVE ELO RATING',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.elevatedSurface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(color: AppTheme.goldPrimary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  weightClass == null || weightClass.isEmpty
                      ? '$division • Open'
                      : '$division • $weightClass',
                  style: const TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.goldPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$rightElo',
                      style: const TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.goldPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Right Arm Rating',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Container(height: 40, width: 1, color: AppTheme.borderSubtle),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$leftElo',
                      style: const TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Left Arm Rating',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultEloBadge(Map<String, dynamic> profile) {
    return _buildEloBadge({
      'rightArmElo': profile['rightArmElo'] ?? 1200,
      'leftArmElo': profile['leftArmElo'] ?? 1200,
      'weightClass': profile['weightClass'],
      'division': profile['division'],
    });
  }

  Widget _buildBiometricsCard(Map<String, dynamic> profile) {
    return ElevatedActionCard(
      padding: const EdgeInsets.all(16),
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
            fontFamily: 'Space Grotesk',
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppTheme.textPrimary,
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
