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
import '../../../core/widgets/main_shell_screen.dart';
import '../../../core/providers/athlete_provider.dart';
import '../../../core/providers/live_matches_provider.dart';
import '../../../core/providers/tournament_provider.dart';
import '../../../core/providers/rankings_provider.dart';

const Map<int, String> _months = {
  1: 'Jan',
  2: 'Feb',
  3: 'Mar',
  4: 'Apr',
  5: 'May',
  6: 'Jun',
  7: 'Jul',
  8: 'Aug',
  9: 'Sep',
  10: 'Oct',
  11: 'Nov',
  12: 'Dec',
};

String _fmtDate(dynamic iso) {
  final d = DateTime.tryParse(iso?.toString() ?? '');
  if (d == null) return '';
  return '${d.day} ${_months[d.month] ?? ''} ${d.year}';
}

String _getDivisionBadge(dynamic weightVal, dynamic weightClassStr) {
  final cls = weightClassStr?.toString().toLowerCase() ?? '';
  if (cls.contains('heavy') || cls.contains('open') || cls.contains('+'))
    return ArmSphereAssets.badgeHeavy;
  if (cls.contains('light')) return ArmSphereAssets.badgeLight;
  if (cls.contains('junior')) return ArmSphereAssets.badgeJunior;
  if (cls.contains('master')) return ArmSphereAssets.badgeMasters;
  final w = (weightVal is num)
      ? weightVal.toDouble()
      : double.tryParse(weightVal?.toString() ?? '') ?? 85.0;
  if (w >= 95) return ArmSphereAssets.badgeHeavy;
  if (w >= 75) return ArmSphereAssets.badgeMiddle;
  return ArmSphereAssets.badgeLight;
}

/// Athlete Dashboard Screen (Canary 2 Specification)
///
/// Grounded in:
/// - `docs/design/69_CANARY_IMPLEMENTATION_SPEC.md#canary-2`
/// - `docs/design/66_ARMSPHERE_SIGNATURE_INTERACTIONS.md` (SIG-3, SIG-4, SIG-7)
/// - `docs/design/68_PREMIUM_EXPERIENCE_CONVERGENCE.md` (Unbundled Surface Architecture)
/// - `docs/design/71_ARMSPHERE_DREAM_GOAL_AND_ANTI_DRIFT_CONSTITUTION.md`
class AthleteDashboardScreen extends ConsumerStatefulWidget {
  const AthleteDashboardScreen({super.key});

  @override
  ConsumerState<AthleteDashboardScreen> createState() =>
      _AthleteDashboardScreenState();
}

class _AthleteDashboardScreenState
    extends ConsumerState<AthleteDashboardScreen> {
  bool _isRightArm = true;
  int _intelDeckTab = 0; // 0: Recent Bouts, 1: Tournaments, 2: Global Top 3

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final profile = authState.userProfile ?? {};
    final rawName = profile['displayName'] ??
        profile['name'] ??
        profile['fullName'] ??
        profile['email']?.toString().split('@').first;
    final displayName =
        (rawName != null && rawName.toString().trim().isNotEmpty)
            ? rawName.toString().trim()
            : 'Athlete';
    final role = profile['role']?.toString().toUpperCase();
    const officialRoles = {
      'REFEREE',
      'PROVINCIAL_DIRECTOR',
      'NATIONAL_DIRECTOR',
      'SYSTEM_ADMIN'
    };
    final isOfficial = role != null && officialRoles.contains(role);
    final profileAsync = ref.watch(athleteProfileProvider);
    final p = profileAsync.value ?? profile;
    final myProfileId =
        profileAsync.value?['id']?.toString() ?? profile['id']?.toString();
    final matchesAsync = ref.watch(liveMatchesProvider);
    final tournamentsAsync = ref.watch(tournamentProvider);
    final rankingsAsync = ref.watch(rankingsProvider);
    final trainingLogsAsync = myProfileId == null
        ? const AsyncValue<List<Map<String, dynamic>>>.data([])
        : ref.watch(trainingLogProvider(myProfileId));
    final prsAsync = myProfileId == null
        ? const AsyncValue<List<Map<String, dynamic>>>.data([])
        : ref.watch(trainingLogPRsProvider(myProfileId));

    // Resolved athlete telemetry metrics (truthful, no fabrication)
    final rawRank = p['rank']?.toString().trim();
    final hasRank = rawRank != null && rawRank.isNotEmpty;
    final rank = hasRank ? '#$rawRank' : 'Unranked';
    final rawDelta = p['rankDelta']?.toString().trim();
    final rankDelta =
        (rawDelta != null && rawDelta.isNotEmpty) ? '↑ $rawDelta' : null;

    final weightVal = p['weightKg'] ?? p['weight'];
    final weightKg = (weightVal is num) ? weightVal.toStringAsFixed(1) : null;

    final winRateVal = p['winRate'];
    final winRate = (winRateVal is num) ? winRateVal.toStringAsFixed(1) : null;

    final rawArm = p['armDominance']?.toString().trim() ??
        p['dominantArm']?.toString().trim();
    final dominantArm = (rawArm != null && rawArm.isNotEmpty) ? rawArm : null;

    final rawClub =
        p['club']?.toString().trim() ?? p['clubName']?.toString().trim();
    final clubName = (rawClub != null && rawClub.isNotEmpty)
        ? rawClub
        : 'No club registered';

    final rawCountry = p['country']?.toString().trim();
    final country =
        (rawCountry != null && rawCountry.isNotEmpty) ? rawCountry : null;

    final rawRightElo = (p['rightArmElo'] as num?)?.toInt() ??
        (p['eloRating'] as num?)?.toInt();
    final rawLeftElo =
        (p['leftArmElo'] as num?)?.toInt() ?? (p['eloRating'] as num?)?.toInt();
    final currentElo = _isRightArm ? rawRightElo : rawLeftElo;
    final eloDelta = (p['eloDelta'] as num?)?.toInt();

    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
      body: RefreshIndicator(
        color: AppTheme.crimson,
        backgroundColor: AppTheme.cardSurface,
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          ref.invalidate(athleteProfileProvider);
          ref.invalidate(liveMatchesProvider);
          ref.invalidate(tournamentProvider);
          ref.invalidate(rankingsProvider);
          if (myProfileId != null) {
            ref.invalidate(trainingLogProvider(myProfileId));
            ref.invalidate(trainingLogPRsProvider(myProfileId));
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MainShellScope.bottomClearance(context, additionalPadding: 20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ========================================================
              // TOP MINIMAL BRAND HEADER (TITANIUM LUXE)
              // ========================================================
              _buildBrandHeader(context, profile, displayName),
              const SizedBox(height: AppTheme.space16),

              // ========================================================
              // SANCTIONED ARENA RADAR (ENVIRONMENTAL ANCHOR)
              // ========================================================
              _buildSanctionedArenaRadar(context),
              const SizedBox(height: AppTheme.space16),

              // ========================================================
              // 1. IMMERSIVE ATHLETE CINEMATIC STAGE BANNER
              // ========================================================
              _buildAthleteCinematicBanner(
                context: context,
                displayName: displayName,
                rank: rank,
                rankDelta: rankDelta,
                hasRank: hasRank,
                weightKg: weightKg,
                winRate: winRate,
                dominantArm: dominantArm,
                clubName: clubName,
                country: country,
                avatarUrl: (p['profilePhoto'] ??
                        p['avatarUrl'] ??
                        profile['avatarUrl'])
                    ?.toString(),
              ),
              const SizedBox(height: AppTheme.space16),

              // ========================================================
              // 2. DUAL-ARM ELO & COMBAT READINESS TELEMETRY RAIL
              // ========================================================
              const Text(
                'COMPETITIVE STANDING',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  fontSize: 10.5,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              _buildCombatTelemetryDual(
                context: context,
                currentElo: currentElo,
                eloDelta: eloDelta,
                trainingLogsAsync: trainingLogsAsync,
                myProfileId: myProfileId,
              ),
              const SizedBox(height: AppTheme.space16),

              // ========================================================
              // 3. BROADCAST FIGHT CARD (UPCOMING SUPERMATCH)
              // ========================================================
              _buildUpcomingSupermatchCard(
                context: context,
                matchesAsync: matchesAsync,
                athleteName: displayName,
                athleteElo: currentElo,
              ),
              const SizedBox(height: AppTheme.space16),

              // ========================================================
              // 4. UNIFIED INTELLIGENCE DECK (RECENT BOUTS & INTEL)
              // ========================================================
              _buildIntelligenceDeck(
                context: context,
                matchesAsync: matchesAsync,
                tournamentsAsync: tournamentsAsync,
                rankingsAsync: rankingsAsync,
                myProfileId: myProfileId,
              ),
              const SizedBox(height: AppTheme.space24),

              // ========================================================
              // 5. QUICK COMMAND ACTIONS (TACTILE TITANIUM GRID)
              // ========================================================
              const Text(
                'QUICK COMMANDS',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  fontSize: 10.5,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              _buildQuickCommandsGrid(context, isOfficial, myProfileId),
              const SizedBox(height: AppTheme.space24),

              // ========================================================
              // 6. PERSONAL RECORDS & LIFTS (TABULAR NUMBERS)
              // ========================================================
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
                          fontSize: 10.5,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final pr in prs)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: AppTheme.machinedTitaniumDecoration(
                                radius: 10,
                                borderColor: AppTheme.borderTitanium,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _prettyExercise(
                                        pr['exerciseType']?.toString()),
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontBody,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${(pr['weightKg'] as num?)?.toInt() ?? '—'} kg',
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.goldPrimary,
                                      fontFeatures: [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top Brand Header
  // ---------------------------------------------------------------------------
  Widget _buildBrandHeader(
      BuildContext context, Map<String, dynamic> profile, String displayName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                // Crest Insignia
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    ),
                    border:
                        Border.all(color: AppTheme.borderHighlight, width: 1.0),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.sports_kabaddi,
                      size: 19,
                      color: AppTheme.crimson,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'ARMSPHERE',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.4,
                            color: AppTheme.textPure,
                            height: 1.0,
                          ),
                        ),
                      ),
                      SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'PRO COMBAT OPERATING SYSTEM',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: AppTheme.textMuted,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGlassIconChip(
                icon: Icons.notifications_none_rounded,
                hasBadge: true,
                tooltip: 'Notifications',
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.push('/notifications');
                },
              ),
              const SizedBox(width: 8),
              _buildGlassIconChip(
                icon: Icons.search_rounded,
                hasBadge: false,
                tooltip: 'Discover & Search',
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.push('/discover');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassIconChip({
    required IconData icon,
    required bool hasBadge,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    // Visual chip stays 34dp; the hit area is 40dp and the control is exposed
    // to assistive tech (the tooltip text was previously unused).
    return Semantics(
      button: true,
      label: tooltip,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xB3151B24),
                border: Border.all(color: AppTheme.borderTitanium, width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(icon, size: 17, color: AppTheme.textPrimary),
                  if (hasBadge)
                    Positioned(
                      top: 7,
                      right: 7,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.crimson,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sanctioned Arena Environmental Anchor (Titanium Luxe Glass)
  // ---------------------------------------------------------------------------
  Widget _buildSanctionedArenaRadar(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
    final isStacked = textScale >= 1.45;

    final exploreButton = TactilePressWrapper(
      onTap: () {
        HapticFeedback.selectionClick();
        context.push('/tournaments');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: AppTheme.machinedTitaniumDecoration(
          radius: 10,
          borderColor: AppTheme.borderTitanium,
        ),
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
            Icon(Icons.arrow_forward_ios, size: 9, color: AppTheme.goldPrimary),
          ],
        ),
      ),
    );

    return Container(
      // minHeight (not a fixed height) so the card grows with text scale
      // instead of overflowing at 1.4x.
      constraints: const BoxConstraints(minHeight: 96),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderTitanium,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Arena Background fills the full dynamic bounds of the expanded card
            Positioned.fill(
              child: ArmSphereImage(
                assetPath: ArmSphereAssets.heroArena,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
              ),
            ),
            // Text-protection gradient scrim (Machined Titanium / Obsidian Glass)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xF50B0F17),
                      Color(0xCC0B0F17),
                      Color(0x550B0F17),
                    ],
                    stops: [0.0, 0.65, 1.0],
                  ),
                ),
              ),
            ),
            // Content overlay (non-positioned: it sizes the card)
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: isStacked
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
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
                              const Flexible(
                                child: Text(
                                  'SANCTIONED ARENA RADAR',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    letterSpacing: 0.8,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 9.5,
                                    color: AppTheme.goldPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Championship Arena Active',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPure,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Official tournament brackets & table calls',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: exploreButton,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
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
                                    const Flexible(
                                      child: Text(
                                        'SANCTIONED ARENA RADAR',
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          letterSpacing: 0.8,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 9.5,
                                          color: AppTheme.goldPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                const Text(
                                  'Championship Arena Active',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPure,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Official tournament brackets & table calls',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          exploreButton,
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Immersive Athlete Cinematic Stage Banner
  // ---------------------------------------------------------------------------
  Widget _buildAthleteCinematicBanner({
    required BuildContext context,
    required String displayName,
    required String rank,
    required String? rankDelta,
    required bool hasRank,
    required String? weightKg,
    required String? winRate,
    required String? dominantArm,
    required String clubName,
    required String? country,
    String? avatarUrl,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppTheme.cinematicBannerGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderTitanium, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          // Background Rank Watermark (only if athlete has verified ranking)
          if (hasRank)
            Positioned(
              right: -6,
              bottom: -24,
              child: Text(
                rank,
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 120,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.035),
                  height: 1.0,
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Badges Row (wraps instead of overflowing at large text)
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.emerald.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppTheme.emerald.withValues(alpha: 0.45),
                              width: 1.0),
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check,
                                  size: 10, color: AppTheme.emerald),
                              SizedBox(width: 4),
                              Text(
                                'VERIFIED',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: AppTheme.emerald,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.goldPrimary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color:
                                  AppTheme.goldPrimary.withValues(alpha: 0.45),
                              width: 1.0),
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.workspace_premium_rounded,
                                  size: 11, color: AppTheme.goldPrimary),
                              SizedBox(width: 4),
                              Text(
                                'PAFF COMPETITOR',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: AppTheme.goldPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Athlete Identity Stage
                Row(
                  children: [
                    // Avatar Portrait Frame
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        context.push('/athlete/profile');
                      },
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const RadialGradient(
                            center: Alignment(-0.2, -0.4),
                            colors: [Color(0xFF223046), Color(0xFF080D15)],
                          ),
                          border: Border.all(
                              color: AppTheme.borderHighlight, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(19),
                          child: ArmSphereImage.avatar(
                            imageUrl: avatarUrl,
                            initial: displayName,
                            size: 72,
                            fallbackAsset: ArmSphereAssets.defaultAvatar,
                            semanticLabel: 'Athlete Avatar: $displayName',
                          ),
                        ),
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
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: AppTheme.textPure,
                              height: 1.1,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 5,
                            runSpacing: 2,
                            children: [
                              if (country != null && country.isNotEmpty) ...[
                                Text(
                                  country,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Text('•',
                                    style:
                                        TextStyle(color: AppTheme.textMuted)),
                              ],
                              Text(
                                clubName,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.crimson,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Biometric Horizontal Quick Ribbon
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0x1AFFFFFF), width: 1.0),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 16,
                      runSpacing: 10,
                      children: [
                        _buildBioStat('WORLD RANK', rank, delta: rankDelta),
                        _buildBioStat(
                            'WEIGHT', weightKg != null ? '$weightKg kg' : '--'),
                        _buildBioStat(
                            'WIN RATE', winRate != null ? '$winRate%' : '--',
                            isEmerald: winRate != null),
                        _buildBioStat(
                            'DISCIPLINE',
                            dominantArm != null
                                ? _disciplineLabel(dominantArm)
                                : '--'),
                      ],
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

  Widget _buildBioStat(String label, String value,
      {String? delta, bool isEmerald = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: isEmerald ? AppTheme.emerald : AppTheme.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (delta != null) ...[
                const SizedBox(width: 3),
                Text(
                  delta,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.emerald,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Dual-Arm ELO & Combat Readiness Telemetry Rail
  // ---------------------------------------------------------------------------
  Widget _buildCombatTelemetryDual({
    required BuildContext context,
    required int? currentElo,
    required int? eloDelta,
    required AsyncValue<List<Map<String, dynamic>>> trainingLogsAsync,
    required String? myProfileId,
  }) {
    void onRecoveryTap() {
      HapticFeedback.selectionClick();
      if (myProfileId != null) {
        context.push('/athlete/$myProfileId/training-log');
      } else {
        context.push('/athlete/profile');
      }
    }

    final String recoverySemanticsLabel = trainingLogsAsync.maybeWhen(
      data: (logs) {
        if (logs.isEmpty) {
          return 'Recovery data unavailable. Tap to log training.';
        }
        final latest = logs.first;
        final dateStr = latest['date'] ?? latest['createdAt'];
        final parsedDate = DateTime.tryParse(dateStr?.toString() ?? '');
        final daysAgo = parsedDate != null
            ? DateTime.now().difference(parsedDate).inDays
            : null;
        final sessionsCount = logs.length;
        final lastActivity = daysAgo == null
            ? 'Activity tracked.'
            : (daysAgo == 0 ? 'Today.' : '${daysAgo}d ago.');
        return 'Recovery status: $sessionsCount Logged. Last activity: $lastActivity Tap to view training log.';
      },
      orElse: () => 'Recovery data unavailable. Tap to log training.',
    );

    // IntrinsicHeight + stretch keeps both cards the same height now that the
    // arm selector lives inside the ELO card.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Dynamic ELO Card (1.2fr)
          Expanded(
            flex: 6,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: AppTheme.machinedTitaniumDecoration(
                radius: 16,
                borderColor: AppTheme.borderTitanium,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DYNAMIC ELO',
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Arm selector: full-width segmented control with 34dp segments
                  // (was ~17dp tall pills in the header row).
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.40),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildArmPill(
                              'RIGHT', 'Right arm', _isRightArm, () {
                            if (!_isRightArm) {
                              HapticFeedback.selectionClick();
                              setState(() => _isRightArm = true);
                            }
                          }),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: _buildArmPill('LEFT', 'Left arm', !_isRightArm,
                              () {
                            if (_isRightArm) {
                              HapticFeedback.selectionClick();
                              setState(() => _isRightArm = false);
                            }
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Wrap (not Row) so the delta badge drops below the rating at
                  // very large text scales instead of overflowing.
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Text(
                          currentElo != null ? '$currentElo' : '--',
                          style: const TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 29,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                            color: AppTheme.textPure,
                            height: 1.0,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        if (eloDelta != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: (eloDelta >= 0
                                      ? AppTheme.emerald
                                      : AppTheme.crimson)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${eloDelta >= 0 ? '▲ +' : '▼ '}$eloDelta',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: eloDelta >= 0
                                    ? AppTheme.emerald
                                    : AppTheme.crimson,
                              ),
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'PROVISIONAL',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Electric Cyan Sparkline Wire
                  const SizedBox(
                    width: double.infinity,
                    height: 22,
                    child: CustomPaint(
                      painter: _SparklineWirePainter(color: AppTheme.cyan),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Truthful Readiness / Training Recovery Card (0.8fr)
          Expanded(
            flex: 4,
            child: Semantics(
              container: true,
              button: true,
              label: recoverySemanticsLabel,
              onTap: onRecoveryTap,
              excludeSemantics: true,
              child: GestureDetector(
                onTap: onRecoveryTap,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: AppTheme.machinedTitaniumDecoration(
                    radius: 16,
                    borderColor: AppTheme.borderTitanium,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              'RECOVERY STATUS',
                              textScaler: MediaQuery.textScalerOf(context)
                                  .clamp(maxScaleFactor: 1.4),
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Icon(
                              Icons.fitness_center_outlined,
                              size: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: trainingLogsAsync.when(
                            loading: () => const SizedBox(
                              height: 44,
                              child: Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: AppTheme.cyan),
                                ),
                              ),
                            ),
                            error: (_, __) => _buildNeutralRecoveryView(),
                            data: (logs) {
                              if (logs.isEmpty) {
                                return _buildNeutralRecoveryView();
                              }
                              final latest = logs.first;
                              final dateStr =
                                  latest['date'] ?? latest['createdAt'];
                              final parsedDate =
                                  DateTime.tryParse(dateStr?.toString() ?? '');
                              final daysAgo = parsedDate != null
                                  ? DateTime.now().difference(parsedDate).inDays
                                  : null;
                              final sessionsCount = logs.length;

                              return Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppTheme.emerald
                                          .withValues(alpha: 0.12),
                                      border: Border.all(
                                          color: AppTheme.emerald
                                              .withValues(alpha: 0.4),
                                          width: 1.0),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.fitness_center,
                                          size: 18, color: AppTheme.emerald),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '$sessionsCount Logged',
                                          style: const TextStyle(
                                            fontFamily: AppTheme.fontDisplay,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.textPure,
                                            height: 1.1,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          daysAgo != null
                                              ? (daysAgo == 0
                                                  ? 'Last: Today'
                                                  : 'Last: ${daysAgo}d ago')
                                              : 'Activity tracked',
                                          style: const TextStyle(
                                            fontSize: 9,
                                            color: AppTheme.textMuted,
                                            height: 1.1,
                                          ),
                                          maxLines: 2,
                                          softWrap: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeutralRecoveryView() {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: AppTheme.borderTitanium, width: 1.0),
          ),
          child: const Center(
            child: Icon(Icons.add, size: 18, color: AppTheme.cyan),
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'No Data',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Tap to log',
                style: TextStyle(
                  fontSize: 9,
                  color: AppTheme.textMuted,
                  height: 1.1,
                ),
                maxLines: 2,
                softWrap: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildArmPill(
      String label, String semanticsLabel, bool isActive, VoidCallback onTap) {
    // Active state mirrors the verified dock/deck standard: crimson tint +
    // crimson hairline, titanium-white label (cyan text is no longer used for
    // selection).
    return Semantics(
      button: true,
      selected: isActive,
      label: semanticsLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 34),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.crimson.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? AppTheme.crimson.withValues(alpha: 0.35)
                  : Colors.transparent,
              width: 1.0,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: isActive ? AppTheme.textPrimary : AppTheme.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingSupermatchCard({
    required BuildContext context,
    required AsyncValue<List<Map<String, dynamic>>> matchesAsync,
    required String athleteName,
    required int? athleteElo,
  }) {
    return matchesAsync.when(
      loading: () => Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppTheme.glassSurfaceHeavy,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.borderTitanium, width: 1.0),
        ),
        child: const Center(
          child: CircularProgressIndicator(
              color: AppTheme.crimson, strokeWidth: 2),
        ),
      ),
      error: (_, __) => _buildNoUpcomingBoutsCard(context),
      data: (matches) {
        final upcomingMatches = matches.where((m) {
          final s = m['status']?.toString().toUpperCase() ?? '';
          return s == 'IN_PROGRESS' ||
              s == 'CALLED' ||
              s == 'READY' ||
              s == 'SCHEDULED';
        }).toList();

        if (upcomingMatches.isEmpty) {
          return _buildNoUpcomingBoutsCard(context);
        }

        final match = upcomingMatches.first;
        final aName = match['athleteAName']?.toString() ?? athleteName;
        final bName = match['athleteBName']?.toString() ?? 'Opponent';
        final tableNum = match['tableNumber']?.toString() ??
            match['tableName']?.toString() ??
            '1';
        final tournamentTitle =
            match['tournamentName']?.toString() ?? 'Sanctioned Tournament';
        final statusText =
            (match['status']?.toString() ?? 'SCHEDULED').toUpperCase();

        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: AppTheme.upcomingMatchGradient,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: AppTheme.crimson.withValues(alpha: 0.28), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.32),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.crimson,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'LIVE ARENA BOUT',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppTheme.crimson,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: AppTheme.borderTitanium, width: 1.0),
                    ),
                    child: Text(
                      statusText,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPure,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0x66070A11),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                            color: AppTheme.borderTitanium, width: 1.0),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 3,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppTheme.crimson,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              aName,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPure,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.silverPlane,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppTheme.borderHighlight, width: 1.0),
                    ),
                    child: const Text(
                      'VS',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPure,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0x66070A11),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                            color: AppTheme.borderTitanium, width: 1.0),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              bName,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPure,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 3,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppTheme.cyan,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.only(top: 10),
                decoration: const BoxDecoration(
                  border: Border(
                      top: BorderSide(color: Color(0x1AFFFFFF), width: 1.0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Table $tableNum • $tournamentTitle',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        context.push('/tournaments');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.crimson,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'VIEW BRACKET',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoUpcomingBoutsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.glassSurfaceHeavy,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderTitanium, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 14, color: AppTheme.goldPrimary),
                      SizedBox(width: 6),
                      Text(
                        'ARENA SCHEDULE',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppTheme.goldPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: AppTheme.borderTitanium, width: 1.0),
                  ),
                  child: const Text(
                    'STANDBY',
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'NO UPCOMING BOUTS SCHEDULED',
            style: TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPure,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Register for sanctioned tournaments to compete in official brackets.',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textMuted,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                context.push('/tournaments');
              },
              icon: const Icon(Icons.emoji_events_outlined,
                  size: 16, color: Colors.black),
              label: const Text(
                'BROWSE TOURNAMENTS',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: Colors.black,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Unified Intelligence Deck (Functional, Truthful Tabs)
  // ---------------------------------------------------------------------------
  Widget _buildIntelligenceDeck({
    required BuildContext context,
    required AsyncValue<List<Map<String, dynamic>>> matchesAsync,
    required AsyncValue<List<Map<String, dynamic>>> tournamentsAsync,
    required AsyncValue<List<Map<String, dynamic>>> rankingsAsync,
    required String? myProfileId,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.machinedTitaniumDecoration(
        radius: 18,
        borderColor: AppTheme.borderTitanium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Deck Navigation Tabs (adaptive: single row when it fits, wraps otherwise)
          IntelligenceDeckTabBar(
            labels: const ['Recent Bouts', 'Tournaments', 'Global Top 3'],
            selectedIndex: _intelDeckTab,
            onSelected: (index) {
              HapticFeedback.selectionClick();
              setState(() => _intelDeckTab = index);
            },
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0x14FFFFFF)),
          const SizedBox(height: 8),

          // Deck Tab Content
          if (_intelDeckTab == 0) ...[
            matchesAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                      color: AppTheme.crimson, strokeWidth: 2),
                ),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('Could not load bouts: $err',
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 11)),
              ),
              data: (matches) {
                if (matches.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Column(
                        children: const [
                          Icon(Icons.sports_kabaddi_outlined,
                              color: AppTheme.textMuted, size: 24),
                          SizedBox(height: 6),
                          Text('No verified bouts yet',
                              style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                  fontSize: 12)),
                          SizedBox(height: 2),
                          Text(
                              'Compete in sanctioned bouts to build verified records.',
                              style: TextStyle(
                                  color: AppTheme.textMuted, fontSize: 10)),
                        ],
                      ),
                    ),
                  );
                }
                final recent = matches.take(3).toList();
                return Column(
                  children: [
                    for (int i = 0; i < recent.length; i++) ...[
                      if (i > 0)
                        const Divider(height: 1, color: Color(0x0FFFFFFF)),
                      _buildDynamicIntelRow(recent[i], myProfileId),
                    ],
                  ],
                );
              },
            ),
          ] else if (_intelDeckTab == 1) ...[
            tournamentsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                      color: AppTheme.goldPrimary, strokeWidth: 2),
                ),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('Could not load tournaments: $err',
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 11)),
              ),
              data: (tournaments) {
                final list = tournaments
                    .where((t) =>
                        t['status']?.toString().toUpperCase() != 'CANCELLED')
                    .take(3)
                    .toList();
                if (list.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Column(
                        children: const [
                          Icon(Icons.emoji_events_outlined,
                              color: AppTheme.textMuted, size: 24),
                          SizedBox(height: 6),
                          Text('No tournaments scheduled',
                              style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                  fontSize: 12)),
                          SizedBox(height: 2),
                          Text('Upcoming sanctioned events will appear here.',
                              style: TextStyle(
                                  color: AppTheme.textMuted, fontSize: 10)),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (int i = 0; i < list.length; i++) ...[
                      if (i > 0)
                        const Divider(height: 1, color: Color(0x0FFFFFFF)),
                      _buildTournamentRowItem(context, list[i]),
                    ],
                  ],
                );
              },
            ),
          ] else if (_intelDeckTab == 2) ...[
            rankingsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                      color: AppTheme.cyan, strokeWidth: 2),
                ),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('Could not load rankings: $err',
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 11)),
              ),
              data: (rankings) {
                final top3 = rankings.take(3).toList();
                if (top3.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Column(
                        children: const [
                          Icon(Icons.leaderboard_outlined,
                              color: AppTheme.textMuted, size: 24),
                          SizedBox(height: 6),
                          Text('Rankings data unavailable',
                              style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                  fontSize: 12)),
                          SizedBox(height: 2),
                          Text(
                              'Standings update as sanctioned events conclude.',
                              style: TextStyle(
                                  color: AppTheme.textMuted, fontSize: 10)),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (int i = 0; i < top3.length; i++) ...[
                      if (i > 0)
                        const Divider(height: 1, color: Color(0x0FFFFFFF)),
                      _buildRankingRowItem(top3[i], i + 1),
                    ],
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTournamentRowItem(BuildContext context, Map<String, dynamic> t) {
    final name = t['name']?.toString() ?? 'Sanctioned Tournament';
    final date = _fmtDate(t['startDate'] ?? t['date']);
    final location = [t['city'], t['venue']]
        .where((v) => v != null && v.toString().isNotEmpty)
        .join(' • ');

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        context.push('/tournaments');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [date, if (location.isNotEmpty) location]
                        .where((s) => s.isNotEmpty)
                        .join(' • '),
                    style:
                        const TextStyle(fontSize: 9, color: AppTheme.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 16, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingRowItem(Map<String, dynamic> r, int position) {
    final name =
        r['athleteName'] ?? r['displayName'] ?? r['fullName'] ?? 'Competitor';
    final club = r['clubName'] ?? r['province'] ?? 'Independent';
    final elo = r['eloRating'] ?? r['points'] ?? '--';
    final Color badgeColor = position == 1
        ? AppTheme.goldPrimary
        : (position == 2 ? const Color(0xFF94A3B8) : const Color(0xFFB45309));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: badgeColor.withValues(alpha: 0.15),
                    border: Border.all(
                        color: badgeColor.withValues(alpha: 0.4), width: 1.0),
                  ),
                  child: Center(
                    child: Text(
                      '#$position',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.toString(),
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        club.toString(),
                        style: const TextStyle(
                            fontSize: 9, color: AppTheme.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$elo ELO',
            style: const TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicIntelRow(
      Map<String, dynamic> match, String? myProfileId) {
    final winnerId = match['winnerId']?.toString();
    final status = match['status']?.toString().toUpperCase() ?? '';
    final isPendingOrActive = status == 'SCHEDULED' ||
        status == 'CONFIRMED' ||
        status == 'CALLED' ||
        status == 'READY' ||
        status == 'IN_PROGRESS';
    final isDecided =
        !isPendingOrActive && winnerId != null && winnerId.isNotEmpty;
    final isWin = isDecided && myProfileId != null && winnerId == myProfileId;
    final isLoss = isDecided && myProfileId != null && winnerId != myProfileId;
    final symbol = isWin ? 'W' : (isLoss ? 'L' : '–');
    final accentColor = isWin
        ? AppTheme.emerald
        : (isLoss ? AppTheme.crimson : AppTheme.textMuted);

    final opponent = match['opponentName'] ??
        (myProfileId != null && match['athleteAId']?.toString() == myProfileId
            ? match['athleteBName']
            : match['athleteAName']) ??
        'Competitor';

    final rawArm = match['arm']?.toString();
    final armLabel = _normalizeArmDiscipline(rawArm);
    final method = match['winMethod']?.toString() ??
        match['scoreLine']?.toString() ??
        'MATCH';
    final subtitle = armLabel != null ? '$method • $armLabel' : method;

    final num? rawDelta = match['eloDelta'] as num?;
    final int? eloDelta = rawDelta?.toInt();
    final String? tag =
        eloDelta != null ? '${eloDelta >= 0 ? '+' : ''}$eloDelta ELO' : null;

    return _buildIntelRowItem(
      symbol: symbol,
      accentColor: accentColor,
      title: 'vs $opponent',
      subtitle: subtitle,
      tag: tag,
      isTagPositive: (eloDelta ?? 0) >= 0,
    );
  }

  Widget _buildIntelRowItem({
    required String symbol,
    Color? accentColor,
    required String title,
    required String subtitle,
    String? tag,
    bool isTagPositive = true,
  }) {
    final effectiveAccent = accentColor ?? AppTheme.textMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: effectiveAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      symbol,
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: effectiveAccent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppTheme.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (tag != null) ...[
            const SizedBox(width: 8),
            Text(
              tag,
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isTagPositive ? AppTheme.emerald : AppTheme.crimson,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Quick Commands Grid
  // ---------------------------------------------------------------------------
  Widget _buildQuickCommandsGrid(
      BuildContext context, bool isOfficial, String? myProfileId) {
    // When text scaling is >= 1.35x, adapt to a deliberate single-column layout
    // so command labels have ample horizontal space without clipping or hyphenation.
    // At nominal text scales (< 1.35x), retain the 2-column tactical grid.
    final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
    final isSingleColumn = textScale >= 1.35;
    final crossAxisCount = isSingleColumn ? 1 : 2;
    // Remove the artificial 2.0x ceiling; height scales smoothly with content.
    final tileExtent = isSingleColumn
        ? (56.0 + 16.0 * (textScale - 1.0))
        : (68.0 + 22.0 * (textScale - 1.0));

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: tileExtent,
      ),
      children: [
        if (isOfficial)
          _ShortcutButton(
            icon: Icons.sports,
            label: 'Referee Console',
            color: AppTheme.cyan,
            onTap: () {
              HapticFeedback.selectionClick();
              context.push('/referee/dashboard');
            },
          ),
        _ShortcutButton(
          icon: Icons.sports_kabaddi,
          label: 'Scorepad Entry',
          color: AppTheme.crimson,
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
          color: AppTheme.emerald,
          onTap: () {
            HapticFeedback.selectionClick();
            context.push(myProfileId != null
                ? '/athlete/$myProfileId/training-log'
                : '/athlete/profile');
          },
        ),
        _ShortcutButton(
          icon: Icons.group_outlined,
          label: 'Clubs & Teams',
          color: AppTheme.cyan,
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
    );
  }

  /// Normalizes raw arm discipline representations to Title Case ('Right Arm' / 'Left Arm').
  /// Returns null if the discipline is null or empty, preventing fabricated disciplines.
  static String? _normalizeArmDiscipline(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final lower = trimmed.toLowerCase();
    if (lower == 'r' || lower == 'right' || lower == 'right arm') {
      return 'Right Arm';
    }
    if (lower == 'l' || lower == 'left' || lower == 'left arm') {
      return 'Left Arm';
    }
    if (lower.endsWith('arm')) {
      final prefix = trimmed.substring(0, trimmed.length - 3).trim();
      if (prefix.isEmpty) return 'Arm';
      final capitalizedPrefix =
          prefix[0].toUpperCase() + prefix.substring(1).toLowerCase();
      return '$capitalizedPrefix Arm';
    }
    final capitalized =
        trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
    return '$capitalized Arm';
  }

  static String _disciplineLabel(String arm) {
    return _normalizeArmDiscipline(arm) ?? arm;
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

/// Tab switcher for the athlete intelligence deck.
///
/// The baseline put three content-sized pills (14dp side padding, 14dp gaps)
/// in one `Row`, which needs ~347dp inside the 296dp available at 360dp phone
/// width and grows with text scale. This widget measures the real labels with
/// the active [TextScaler] and picks a layout that cannot overflow:
///
/// * labels fit in equal thirds -> one row of equal-width segments;
/// * otherwise -> a [Wrap] of content-sized pills, so every tab stays visible,
///   at full size, honoring system text scaling (no clipping, scrolling,
///   shrinking or ellipsis). A pill wider than the row wraps its own text.
///
/// Label weight is the same for every state so selecting a tab never changes
/// widths (and therefore never re-flows the wrap).
class IntelligenceDeckTabBar extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const IntelligenceDeckTabBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  static const double _segmentGap = 6.0;
  static const double _wrapGap = 8.0;
  static const double _segmentPadding = 6.0; // minimum per side, one-row mode
  static const double _pillPadding = 14.0; // per side, wrap mode
  static const double _borderWidth = 1.0;
  static const double _minTouchHeight = 40.0;

  static const TextStyle _labelStyle = TextStyle(
    fontFamily: AppTheme.fontDisplay,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScaler = MediaQuery.textScalerOf(context);
        final direction = Directionality.of(context);

        var widestLabel = 0.0;
        for (final label in labels) {
          final painter = TextPainter(
            text: TextSpan(text: label, style: _labelStyle),
            textDirection: direction,
            textScaler: textScaler,
            maxLines: 1,
          )..layout();
          widestLabel = math.max(widestLabel, painter.width);
          painter.dispose();
        }

        final count = labels.length;
        final segmentWidth =
            (constraints.maxWidth - _segmentGap * (count - 1)) / count;
        final fitsInOneRow = constraints.hasBoundedWidth &&
            widestLabel + 2 * (_segmentPadding + _borderWidth) <= segmentWidth;

        if (fitsInOneRow) {
          return Row(
            children: [
              for (var i = 0; i < count; i++) ...[
                if (i > 0) const SizedBox(width: _segmentGap),
                Expanded(child: _buildTab(i, expand: true)),
              ],
            ],
          );
        }
        return Wrap(
          spacing: _wrapGap,
          runSpacing: _wrapGap,
          children: [
            for (var i = 0; i < count; i++) _buildTab(i, expand: false),
          ],
        );
      },
    );
  }

  Widget _buildTab(int index, {required bool expand}) {
    final label = labels[index];
    final isSelected = index == selectedIndex;
    final text = Text(
      label,
      textAlign: TextAlign.center,
      style: _labelStyle.copyWith(
        color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
      ),
    );

    return Semantics(
      container: true,
      button: true,
      selected: isSelected,
      label: label,
      onTap: () => onSelected(index),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: _minTouchHeight),
          alignment: expand ? Alignment.center : null,
          padding: EdgeInsets.symmetric(
            horizontal: expand ? _segmentPadding : _pillPadding,
            vertical: 6,
          ),
          // Same active treatment as the verified navigation dock.
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.crimson.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppTheme.crimson.withValues(alpha: 0.35)
                  : const Color(0x1FFFFFFF),
              width: _borderWidth,
            ),
          ),
          child: expand ? text : Center(widthFactor: 1.0, child: text),
        ),
      ),
    );
  }
}

/// Custom Electric Cyan Sparkline Wire Painter
class _SparklineWirePainter extends CustomPainter {
  final Color color;
  const _SparklineWirePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.75);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.65,
        size.width * 0.40, size.height * 0.35);
    path.quadraticBezierTo(size.width * 0.65, size.height * 0.52,
        size.width * 0.85, size.height * 0.30);
    path.quadraticBezierTo(
        size.width * 0.95, size.height * 0.18, size.width, size.height * 0.12);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklineWirePainter oldDelegate) =>
      oldDelegate.color != color;
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
              maxLines: 2,
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
              child: const Icon(Icons.verified_user_outlined,
                  size: 16, color: AppTheme.goldPrimary),
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
                style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.goldPrimary,
                    fontWeight: FontWeight.bold),
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
                  color: !isOfficialActive
                      ? AppTheme.elevatedSurface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: !isOfficialActive
                      ? Border.all(
                          color: AppTheme.goldPrimary.withValues(alpha: 0.5),
                          width: 1)
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
                      color: !isOfficialActive
                          ? AppTheme.goldPrimary
                          : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Athlete Mode',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 12,
                        fontWeight: !isOfficialActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: !isOfficialActive
                            ? AppTheme.goldPrimary
                            : AppTheme.textMuted,
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
                  color: isOfficialActive
                      ? AppTheme.elevatedSurface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: isOfficialActive
                      ? Border.all(
                          color: AppTheme.info.withValues(alpha: 0.5), width: 1)
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
                      color:
                          isOfficialActive ? AppTheme.info : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Official Mode',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 12,
                        fontWeight: isOfficialActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isOfficialActive
                            ? AppTheme.info
                            : AppTheme.textMuted,
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
    const officialRoles = {
      'REFEREE',
      'PROVINCIAL_DIRECTOR',
      'NATIONAL_DIRECTOR',
      'SYSTEM_ADMIN'
    };
    final isOfficial = officialRoles.contains(role);

    final profileAsync = ref.watch(athleteProfileProvider);
    final myProfileId =
        profileAsync.value?['id']?.toString() ?? profile['id']?.toString();

    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
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
            icon: const Icon(Icons.settings_outlined,
                color: AppTheme.textSecondary),
            tooltip: 'Settings',
            onPressed: () {
              HapticFeedback.selectionClick();
              context.push('/settings');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          18,
          16,
          MainShellScope.bottomClearance(context, additionalPadding: 20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Athlete Identity Header with Smoked Titanium Glass Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.glassSurfaceHeavy,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderTitanium, width: 1.0),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0x1AFFFFFF),
                    Color(0xB3151B24),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isOfficial ? AppTheme.cyan : AppTheme.goldPrimary,
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isOfficial
                                  ? AppTheme.cyan
                                  : AppTheme.goldPrimary)
                              .withValues(alpha: 0.25),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ArmSphereImage.avatar(
                      imageUrl:
                          (profile['profilePhoto'] ?? profile['avatarUrl'])
                              ?.toString(),
                      initial: displayName,
                      size: 72,
                      fallbackAsset: ArmSphereAssets.defaultAvatar,
                      semanticLabel: 'Athlete Avatar for $displayName',
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
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            ArmSphereImage(
                              assetPath: isOfficial
                                  ? ArmSphereAssets.refNat
                                  : _getDivisionBadge(
                                      profile['weightKg'] ?? profile['weight'],
                                      profile['weightClass']),
                              width: 20,
                              height: 20,
                              semanticLabel: isOfficial
                                  ? 'Certified Referee Insignia'
                                  : 'Division Category Badge',
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isOfficial
                                  ? 'Certified Federation Official'
                                  : 'Official PAFF Competitor',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isOfficial
                                    ? AppTheme.cyan
                                    : AppTheme.goldPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
              onSelectOfficial: () async {
                HapticFeedback.lightImpact();
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppTheme.cardSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      side: const BorderSide(color: AppTheme.cardBorder),
                    ),
                    title: const Row(
                      children: [
                        Icon(Icons.gavel_rounded,
                            color: AppTheme.info, size: 24),
                        SizedBox(width: AppTheme.space8),
                        Text(
                          'Switch to Official Mode?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: AppTheme.fontDisplay,
                          ),
                        ),
                      ],
                    ),
                    content: const Text(
                      'This will switch your active operational view to the Referee Console and table officiating tools.',
                      style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          height: 1.4),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.goldPrimary,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Switch Role'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  context.push('/referee/dashboard');
                }
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
                  child: Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.goldPrimary)),
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
                child: SizedBox(
                    height: 50,
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.goldPrimary))),
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
                      context.push(myProfileId != null
                          ? '/athlete/$myProfileId/training-log'
                          : '/settings');
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
                    onTap: () async {
                      HapticFeedback.heavyImpact();
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
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
    final weight = profile['weightKg'] ?? profile['weight'];
    final height = profile['heightCm'] ?? profile['height'];
    final reach = profile['reachCm'] ?? profile['reach'];
    final dominance = profile['armDominance']?.toString() ??
        profile['dominantArm']?.toString();

    return ElevatedActionCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SpecItem(
              label: 'Weight', value: weight != null ? '${weight}kg' : '--'),
          _SpecItem(
              label: 'Height', value: height != null ? '${height}cm' : '--'),
          _SpecItem(label: 'Reach', value: reach != null ? '${reach}cm' : '--'),
          _SpecItem(
              label: 'Dominance',
              value: dominance != null && dominance.isNotEmpty
                  ? dominance.toUpperCase()
                  : '--'),
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
    final dominant =
        widget.profileData['armDominance']?.toString().toUpperCase() ??
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
    final rightElo = (p['rightArmElo'] as num?)?.toInt() ??
        (p['eloRating'] as num?)?.toInt() ??
        1200;
    final leftElo = (p['leftArmElo'] as num?)?.toInt() ??
        (p['eloRating'] as num?)?.toInt() ??
        1200;
    final weightClass = p['weightClass']?.toString();
    final division = p['division']?.toString() ?? 'Senior';

    final activeElo = _isRightArm ? rightElo : leftElo;
    final alternateElo = _isRightArm ? leftElo : rightElo;
    final activeArmLabel = _isRightArm ? 'RIGHT ARM' : 'LEFT ARM';
    final alternateArmLabel = _isRightArm ? 'LEFT ARM' : 'RIGHT ARM';
    final activeAccentColor =
        _isRightArm ? AppTheme.goldPrimary : AppTheme.info;

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                        color:
                            _isRightArm ? AppTheme.info : AppTheme.goldPrimary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Switch to $alternateArmLabel',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isRightArm
                              ? AppTheme.info
                              : AppTheme.goldPrimary,
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
          color: isSelected
              ? activeColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isSelected
              ? Border.all(color: activeColor.withValues(alpha: 0.5), width: 1)
              : null,
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
                color: isDestructive
                    ? AppTheme.error.withValues(alpha: 0.1)
                    : AppTheme.elevatedSurface,
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
                      color:
                          isDestructive ? AppTheme.error : AppTheme.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDestructive
                  ? AppTheme.error.withValues(alpha: 0.6)
                  : AppTheme.textMuted,
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
          style: TextStyle(
              fontFamily: 'Space Grotesk', fontWeight: FontWeight.w700),
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
                      Icon(Icons.verified_outlined,
                          size: 18, color: AppTheme.goldPrimary),
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
                    style: TextStyle(
                        height: 1.5,
                        fontSize: 13,
                        color: AppTheme.textSecondary),
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
