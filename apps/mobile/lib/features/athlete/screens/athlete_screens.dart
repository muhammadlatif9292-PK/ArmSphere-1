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
    // Other arm's rating, shown only from the arm-specific field (never from
    // the generic eloRating fallback, which would read as arm-specific).
    final specificRightElo = (p['rightArmElo'] as num?)?.toInt();
    final specificLeftElo = (p['leftArmElo'] as num?)?.toInt();
    final otherArmElo = _isRightArm ? specificLeftElo : specificRightElo;
    final otherArmLabel = _isRightArm ? 'LEFT' : 'RIGHT';

    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
      body: Stack(
        children: [
          // Top Environmental Arena Backdrop & Stadium Spotlight
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 360,
            child: IgnorePointer(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Opacity(
                    opacity: 0.22,
                    child: ArmSphereImage(
                      assetPath: ArmSphereAssets.heroArena,
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                    ),
                  ),
                  Opacity(
                    opacity: 0.35,
                    child: ArmSphereImage(
                      assetPath: ArmSphereAssets.texChalk,
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0.0, -0.85),
                        radius: 1.1,
                        colors: [
                          Color(0x3338BDF8),
                          Color(0x1AE23B3B),
                          Color(0x00070A11),
                        ],
                        stops: [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x66070A11),
                          Color(0xCC070A11),
                          AppTheme.voidBackground,
                        ],
                        stops: [0.0, 0.65, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          RefreshIndicator(
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
                otherArmElo: otherArmElo,
                otherArmLabel: otherArmLabel,
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
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top Brand Header
  // ---------------------------------------------------------------------------
  Widget _buildBrandHeader(
      BuildContext context, Map<String, dynamic> profile, String displayName) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    // Embossed Gold Crest Insignia
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
                        border: Border.all(
                            color: AppTheme.goldPrimary.withValues(alpha: 0.45),
                            width: 1.0),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.goldPrimary.withValues(alpha: 0.18),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ArmSphereImage(
                              assetPath: ArmSphereAssets.iconGold,
                              fit: BoxFit.cover,
                              excludeFromSemantics: true,
                            ),
                            const Center(
                              child: Opacity(
                                opacity: 0.0,
                                child: Icon(
                                  Icons.sports_kabaddi,
                                  size: 19,
                                  color: AppTheme.crimson,
                                ),
                              ),
                            ),
                          ],
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
        ),
        const SizedBox(height: 6),
        // Optical stadium spotlight flare divider under brand header
        const SizedBox(
          height: 1.5,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0x00DAE2EB),
                  Color(0x3338BDF8),
                  Color(0x99FFFFFF),
                  Color(0x33E23B3B),
                  Color(0x00DAE2EB),
                ],
                stops: [0.0, 0.3, 0.5, 0.7, 1.0],
              ),
            ),
          ),
        ),
      ],
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
    final rankDigits = rank.replaceAll(RegExp(r'[^0-9]'), '');
    final rankInt = int.tryParse(rankDigits);
    final isPodium = hasRank && rankInt != null && rankInt >= 1 && rankInt <= 3;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppTheme.cinematicBannerGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderTitanium, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          // Per-card internal atmospheric imagery (arena grip clash + chalk dust + crimson/gold corner spotlights)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(19),
              child: IgnorePointer(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Opacity(
                      opacity: 0.16,
                      child: ArmSphereImage(
                        assetPath: ArmSphereAssets.heroGrip,
                        fit: BoxFit.cover,
                        excludeFromSemantics: true,
                      ),
                    ),
                    Opacity(
                      opacity: 0.42,
                      child: ArmSphereImage(
                        assetPath: ArmSphereAssets.texChalk,
                        fit: BoxFit.cover,
                        excludeFromSemantics: true,
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(-0.85, -0.25),
                          radius: 1.05,
                          colors: [
                            Color(0x38E23B3B),
                            Color(0x14E23B3B),
                            Color(0x000B0F17),
                          ],
                          stops: [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(0.85, -0.55),
                          radius: 0.95,
                          colors: [
                            Color(0x2238BDF8),
                            Color(0x14D4AF37),
                            Color(0x000B0F17),
                          ],
                          stops: [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0xB30B0F17),
                            Color(0xD9101722),
                            Color(0xE60B0F17),
                          ],
                          stops: [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Specular top hairline rim highlight
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0x00DAE2EB),
                    Color(0x40DAE2EB),
                    Color(0x00DAE2EB),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Background Rank Watermark (only if athlete has verified ranking)
          if (hasRank)
            Positioned(
              right: -4,
              bottom: -20,
              child: Text(
                rank,
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 115,
                  fontWeight: FontWeight.w900,
                  color: isPodium
                      ? AppTheme.goldPrimary.withValues(alpha: 0.04)
                      : Colors.white.withValues(alpha: 0.035),
                  height: 1.0,
                  letterSpacing: -4.0,
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
                            horizontal: 9, vertical: 4.5),
                        decoration: ShapeDecoration(
                          color: AppTheme.emerald.withValues(alpha: 0.09),
                          shape: BeveledRectangleBorder(
                            side: BorderSide(
                              color: AppTheme.emerald.withValues(alpha: 0.35),
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_outline_rounded,
                                  size: 11, color: AppTheme.emerald),
                              SizedBox(width: 4.5),
                              Text(
                                'VERIFIED',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: AppTheme.emerald,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4.5),
                        decoration: ShapeDecoration(
                          color: AppTheme.goldPrimary.withValues(alpha: 0.09),
                          shape: BeveledRectangleBorder(
                            side: BorderSide(
                              color:
                                  AppTheme.goldPrimary.withValues(alpha: 0.40),
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.workspace_premium_rounded,
                                  size: 12, color: AppTheme.goldPrimary),
                              SizedBox(width: 4.5),
                              Text(
                                'PAFF COMPETITOR',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
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
                          borderRadius: BorderRadius.circular(18),
                          gradient: const RadialGradient(
                            center: Alignment(-0.25, -0.35),
                            radius: 0.9,
                            colors: [Color(0xFF283850), Color(0xFF0B1018)],
                          ),
                          border: Border.all(
                              color: AppTheme.borderHighlight, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.55),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                            if (isPodium)
                              BoxShadow(
                                color: AppTheme.goldPrimary
                                    .withValues(alpha: 0.12),
                                blurRadius: 10,
                                spreadRadius: -2,
                              ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16.5),
                          child: ArmSphereImage.avatar(
                            imageUrl: (avatarUrl != null &&
                                    !avatarUrl.startsWith('assets/'))
                                ? avatarUrl
                                : null,
                            assetPath: (avatarUrl != null &&
                                    avatarUrl.startsWith('assets/'))
                                ? avatarUrl
                                : null,
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
                              letterSpacing: -0.4,
                              color: AppTheme.textPure,
                              height: 1.12,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 3,
                            children: [
                              if (country != null && country.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: AppTheme.borderSubtle,
                                        width: 1.0),
                                  ),
                                  child: Text(
                                    country,
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontSize: 10,
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                              ],
                              Text.rich(
                                TextSpan(
                                  children: [
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 3.5),
                                        child: Icon(
                                          Icons.shield_outlined,
                                          size: 11,
                                          color: AppTheme.crimson
                                              .withValues(alpha: 0.85),
                                        ),
                                      ),
                                    ),
                                    TextSpan(
                                      text: clubName,
                                      style: const TextStyle(
                                        fontFamily: AppTheme.fontBody,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.2,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
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
                  padding: const EdgeInsets.only(top: 13),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0x24D6DCE3), width: 1.0),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 16,
                      runSpacing: 10,
                      children: [
                        _buildBioStat('WORLD RANK', rank,
                            delta: rankDelta,
                            hasRank: hasRank,
                            isPodium: isPodium),
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
      {String? delta,
      bool isEmerald = false,
      bool hasRank = false,
      bool isPodium = false}) {
    final isRankStat = label == 'WORLD RANK';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 3.5),
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
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isEmerald
                      ? AppTheme.emerald
                      : (isRankStat && hasRank
                          ? (isPodium
                              ? AppTheme.goldLight
                              : AppTheme.textPrimary)
                          : AppTheme.textPrimary),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (delta != null) ...[
                const SizedBox(width: 3.5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 3.5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.emerald.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    delta,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.emerald,
                    ),
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
    int? otherArmElo,
    String otherArmLabel = 'LEFT',
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
                    decoration: ShapeDecoration(
                      color: Colors.black.withValues(alpha: 0.40),
                      shape: BeveledRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                                horizontal: 5, vertical: 3),
                            decoration: ShapeDecoration(
                              color: (eloDelta >= 0
                                      ? AppTheme.emerald
                                      : AppTheme.crimson)
                                  .withValues(alpha: 0.12),
                              shape: BeveledRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            // Icon (not a "▲" text glyph): renders identically
                            // on every device font.
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  eloDelta >= 0
                                      ? Icons.arrow_drop_up_rounded
                                      : Icons.arrow_drop_down_rounded,
                                  size: 14,
                                  color: eloDelta >= 0
                                      ? AppTheme.emerald
                                      : AppTheme.crimson,
                                ),
                                Text(
                                  '${eloDelta >= 0 ? '+' : ''}$eloDelta',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: eloDelta >= 0
                                        ? AppTheme.emerald
                                        : AppTheme.crimson,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: ShapeDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              shape: BeveledRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
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
                  // The former cyan "sparkline" was a hard-coded rising curve
                  // with no data behind it (it showed an upward trend for every
                  // athlete). Replaced with the other arm's real rating.
                  if (otherArmElo != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(top: 8),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0x1AFFFFFF), width: 1.0),
                        ),
                      ),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: otherArmLabel,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            TextSpan(
                              text: '  $otherArmElo',
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textSecondary,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
                              // At large text scales the ~50dp text column made
                              // "2 Logged" break mid-word ("Logge/d"); stack the
                              // icon above the text instead.
                              final stackRecovery =
                                  MediaQuery.textScalerOf(context).scale(12) /
                                          12 >=
                                      1.3;

                              return Flex(
                                direction: stackRecovery
                                    ? Axis.vertical
                                    : Axis.horizontal,
                                crossAxisAlignment: stackRecovery
                                    ? CrossAxisAlignment.start
                                    : CrossAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
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
                                  const SizedBox(width: 8, height: 8),
                                  Flexible(
                                    fit: FlexFit.loose,
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
          decoration: ShapeDecoration(
            color: isActive
                ? AppTheme.crimson.withValues(alpha: 0.12)
                : Colors.transparent,
            shape: BeveledRectangleBorder(
              side: BorderSide(
                color: isActive
                    ? AppTheme.crimson.withValues(alpha: 0.35)
                    : Colors.transparent,
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(6),
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
        final statusKey =
            (match['status']?.toString() ?? 'SCHEDULED').toUpperCase();
        final statusText = statusKey.replaceAll('_', ' ');

        // The headline reflects the real status instead of claiming "LIVE" for
        // a scheduled bout. Only in-progress / called bouts get the crimson
        // live treatment.
        final bool isHot = statusKey == 'IN_PROGRESS' || statusKey == 'CALLED';
        final String headline = switch (statusKey) {
          'IN_PROGRESS' => 'LIVE NOW',
          'CALLED' => 'CALLED TO TABLE',
          'READY' => 'READY',
          _ => 'UPCOMING BOUT',
        };
        final Color headlineColor =
            isHot ? AppTheme.crimson : AppTheme.textSecondary;

        // Table / tournament line: real values only. No fabricated "Table 1"
        // default, and no doubled "Table Table 1" when the value already says
        // "Table".
        String? tableLabel(Object? raw) {
          final text = raw?.toString().trim() ?? '';
          final number = text
              .replaceFirst(RegExp(r'^table\s*', caseSensitive: false), '')
              .trim();
          return number.isEmpty ? null : 'Table $number';
        }

        final table = tableLabel(match['tableNumber'] ?? match['tableName']);
        final tournamentRaw = match['tournamentName']?.toString().trim();
        final tournament = (tournamentRaw == null || tournamentRaw.isEmpty)
            ? null
            : tournamentRaw;
        final metaLine = [table, tournament].whereType<String>().join(' • ');

        void openBracket() {
          HapticFeedback.mediumImpact();
          context.push('/tournaments');
        }

        // Two fighter plates side by side; stacked at large text scales so
        // names stay fully readable instead of truncating.
        final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
        final stackFighters = textScale >= 1.3;

        Widget fighterPlate(String name, Color accent,
            {required bool alignEnd}) {
          final bar = Container(
            width: 3,
            height: 32,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          );
          final label = Expanded(
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: alignEnd ? TextAlign.end : TextAlign.start,
              style: const TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPure,
                height: 1.15,
              ),
            ),
          );
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: ShapeDecoration(
              color: const Color(0x66070A11),
              shape: BeveledRectangleBorder(
                side: const BorderSide(
                    color: AppTheme.borderTitanium, width: 1.0),
                borderRadius: BorderRadius.circular(7),
              ),
            ),
            child: Row(
              children: alignEnd
                  ? [label, const SizedBox(width: 8), bar]
                  : [bar, const SizedBox(width: 8), label],
            ),
          );
        }

        final vsBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: ShapeDecoration(
            color: AppTheme.silverPlane,
            shape: BeveledRectangleBorder(
              side:
                  const BorderSide(color: AppTheme.borderHighlight, width: 1.0),
              borderRadius: BorderRadius.circular(5),
            ),
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
        );

        final Widget fighters = stackFighters
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  fighterPlate(aName, AppTheme.crimson, alignEnd: false),
                  const SizedBox(height: 6),
                  Center(child: vsBadge),
                  const SizedBox(height: 6),
                  fighterPlate(bName, AppTheme.cyan, alignEnd: false),
                ],
              )
            : IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: fighterPlate(aName, AppTheme.crimson,
                          alignEnd: false),
                    ),
                    const SizedBox(width: 8),
                    Center(child: vsBadge),
                    const SizedBox(width: 8),
                    Expanded(
                      child: fighterPlate(bName, AppTheme.cyan, alignEnd: true),
                    ),
                  ],
                ),
              );

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
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Per-card internal fight-stage imagery (forearm clash + chalk particles + red/blue corner spotlights)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: IgnorePointer(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Opacity(
                          opacity: 0.20,
                          child: ArmSphereImage(
                            assetPath: ArmSphereAssets.heroGrip,
                            fit: BoxFit.cover,
                            excludeFromSemantics: true,
                          ),
                        ),
                        Opacity(
                          opacity: 0.35,
                          child: ArmSphereImage(
                            assetPath: ArmSphereAssets.texChalk,
                            fit: BoxFit.cover,
                            excludeFromSemantics: true,
                          ),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment(-0.85, 0.0),
                              radius: 0.95,
                              colors: [
                                Color(0x36E23B3B),
                                Color(0x00070A11),
                              ],
                            ),
                          ),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment(0.85, 0.0),
                              radius: 0.95,
                              colors: [
                                Color(0x3038BDF8),
                                Color(0x00070A11),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Specular top rim: same lighting language as the athlete banner.
              const Positioned(
                top: -15,
                left: -3,
                right: -3,
                height: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0x00DAE2EB),
                        Color(0x40DAE2EB),
                        Color(0x00DAE2EB),
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              // stretch + a full-width Wrap: without these the header chips
              // shrink-wrap and centre together instead of spreading to the
              // edges (confirmed in the Stage 2 baseline capture).
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(
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
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isHot
                                    ? AppTheme.crimson
                                    : AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              headline,
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: headlineColor,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: ShapeDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            shape: BeveledRectangleBorder(
                              side: const BorderSide(
                                  color: AppTheme.borderTitanium, width: 1.0),
                              borderRadius: BorderRadius.circular(4),
                            ),
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
                  ),
                  const SizedBox(height: 12),
                  fighters,
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.only(top: 10),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0x1AFFFFFF), width: 1.0),
                      ),
                    ),
                    child: Wrap(
                      alignment: metaLine.isEmpty
                          ? WrapAlignment.end
                          : WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (metaLine.isNotEmpty)
                          Text(
                            metaLine,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        Semantics(
                          button: true,
                          label: 'View bracket',
                          onTap: openBracket,
                          excludeSemantics: true,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: openBracket,
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 36),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              decoration: ShapeDecoration(
                                color: AppTheme.crimson,
                                shape: BeveledRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              child: const Center(
                                widthFactor: 1.0,
                                child: Text(
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
                          ),
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
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: IgnorePointer(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Opacity(
                      opacity: 0.18,
                      child: ArmSphereImage(
                        assetPath: ArmSphereAssets.defaultTournament,
                        fit: BoxFit.cover,
                        excludeFromSemantics: true,
                      ),
                    ),
                    Opacity(
                      opacity: 0.32,
                      child: ArmSphereImage(
                        assetPath: ArmSphereAssets.texChalk,
                        fit: BoxFit.cover,
                        excludeFromSemantics: true,
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0xE60B0F17),
                            Color(0xBF0B0F17),
                            Color(0x990B0F17),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Column(
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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Per-card internal chalk dust particle bokeh & corner ambient sheen
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: IgnorePointer(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Opacity(
                      opacity: 0.36,
                      child: ArmSphereImage(
                        assetPath: ArmSphereAssets.texChalk,
                        fit: BoxFit.cover,
                        excludeFromSemantics: true,
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(0.85, 0.85),
                          radius: 0.9,
                          colors: [
                            Color(0x2238BDF8),
                            Color(0x00151B24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Specular top rim: same lighting language as the banner and fight card.
          const Positioned(
            top: -16,
            left: -3,
            right: -3,
            height: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0x00DAE2EB),
                    Color(0x40DAE2EB),
                    Color(0x00DAE2EB),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          Column(
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
                            t['status']?.toString().toUpperCase() !=
                            'CANCELLED')
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
                              Text(
                                  'Upcoming sanctioned events will appear here.',
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
        ],
      ),
    );
  }

  Widget _buildTournamentRowItem(BuildContext context, Map<String, dynamic> t) {
    final name = t['name']?.toString() ?? 'Sanctioned Tournament';
    final rawDate = t['startDate'] ?? t['date'];
    final parsed = DateTime.tryParse(rawDate?.toString() ?? '');
    final date = _fmtDate(rawDate);
    final location = [t['city'], t['venue']]
        .where((v) => v != null && v.toString().isNotEmpty)
        .join(' • ');
    // With a real date the plate carries it; without one nothing is invented
    // and the subtitle falls back to the location alone.
    final subtitle = parsed != null
        ? location
        : [date, if (location.isNotEmpty) location]
            .where((s) => s.isNotEmpty)
            .join(' • ');

    void open() {
      HapticFeedback.selectionClick();
      context.push('/tournaments');
    }

    final datePlate = parsed == null
        ? null
        : Container(
            constraints: const BoxConstraints(minWidth: 40),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            decoration: ShapeDecoration(
              color: Colors.black.withValues(alpha: 0.30),
              shape: BeveledRectangleBorder(
                side: const BorderSide(
                    color: AppTheme.borderTitanium, width: 1.0),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  (_months[parsed.month] ?? '').toUpperCase(),
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppTheme.textMuted,
                  ),
                ),
                Text(
                  '${parsed.day}',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    color: AppTheme.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          );

    return Semantics(
      button: true,
      label: [
        name,
        if (date.isNotEmpty) date,
        if (location.isNotEmpty) location
      ].join(', '),
      onTap: open,
      excludeSemantics: true,
      child: InkWell(
        onTap: open,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              if (datePlate != null) ...[
                datePlate,
                const SizedBox(width: 12),
              ],
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                            fontSize: 9, color: AppTheme.textMuted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right,
                  size: 16, color: AppTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankingRowItem(Map<String, dynamic> r, int position) {
    final name =
        r['athleteName'] ?? r['displayName'] ?? r['fullName'] ?? 'Competitor';
    // Only real values are shown: no invented "Independent" club and no
    // "-- ELO" placeholder when the rating is missing.
    final clubRaw = (r['clubName'] ?? r['province'])?.toString().trim();
    final club = (clubRaw == null || clubRaw.isEmpty) ? null : clubRaw;
    final eloRaw = (r['eloRating'] ?? r['points'])?.toString().trim();
    final elo = (eloRaw == null || eloRaw.isEmpty) ? null : eloRaw;
    final Color badgeColor = position == 1
        ? AppTheme.goldPrimary
        : (position == 2 ? const Color(0xFF94A3B8) : const Color(0xFFB45309));
    final stackElo = MediaQuery.textScalerOf(context).scale(12) / 12 >= 1.3;

    Widget eloBlock(CrossAxisAlignment align) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: align,
          children: [
            Text(
              elo!,
              style: const TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const Text(
              'ELO',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        );

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: badgeColor.withValues(alpha: 0.18),
              border: Border.all(
                  color: badgeColor.withValues(alpha: 0.5), width: 1.0),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (club != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    club,
                    style:
                        const TextStyle(fontSize: 9, color: AppTheme.textMuted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (stackElo && elo != null) ...[
                  const SizedBox(height: 3),
                  eloBlock(CrossAxisAlignment.start),
                ],
              ],
            ),
          ),
          if (!stackElo && elo != null) ...[
            const SizedBox(width: 8),
            eloBlock(CrossAxisAlignment.end),
          ],
        ],
      ),
    );
    return Semantics(
      container: true,
      label: [
        'Rank $position',
        name.toString(),
        if (club != null) club,
        if (elo != null) '$elo Elo',
      ].join(', '),
      child: ExcludeSemantics(child: row),
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
    // Decided bouts show how they ended; pending ones show their real status
    // (instead of a generic "MATCH" placeholder). Nothing is invented.
    final method =
        match['winMethod']?.toString() ?? match['scoreLine']?.toString();
    final lead = isPendingOrActive ? status.replaceAll('_', ' ') : method;
    final subtitle = [lead, armLabel]
        .whereType<String>()
        .where((part) => part.trim().isNotEmpty)
        .join(' • ');

    final num? rawDelta = match['eloDelta'] as num?;
    final int? eloDelta = rawDelta?.toInt();
    final String? tag =
        eloDelta != null ? '${eloDelta >= 0 ? '+' : ''}$eloDelta ELO' : null;

    final outcome = isWin
        ? 'Win'
        : (isLoss ? 'Loss' : (isPendingOrActive ? 'Upcoming bout' : 'Bout'));
    return _buildIntelRowItem(
      symbol: symbol,
      accentColor: accentColor,
      title: 'vs $opponent',
      subtitle: subtitle,
      tag: tag,
      isTagPositive: (eloDelta ?? 0) >= 0,
      semanticsLabel: [
        '$outcome versus $opponent',
        if (tag != null) tag,
        if (subtitle.isNotEmpty) subtitle,
      ].join(', '),
    );
  }

  Widget _buildIntelRowItem({
    required String symbol,
    Color? accentColor,
    required String title,
    required String subtitle,
    String? tag,
    bool isTagPositive = true,
    String? semanticsLabel,
  }) {
    final effectiveAccent = accentColor ?? AppTheme.textMuted;
    // At large text sizes the right-hand ELO tag used to steal the width the
    // opponent name needs ("vs Denis Cypl..."): drop it under the subtitle.
    final stackTag = MediaQuery.textScalerOf(context).scale(12) / 12 >= 1.3;
    final Widget? tagText = tag == null
        ? null
        : Text(
            tag,
            style: TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: isTagPositive ? AppTheme.emerald : AppTheme.crimson,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          );

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: ShapeDecoration(
              color: effectiveAccent.withValues(alpha: 0.16),
              shape: BeveledRectangleBorder(
                side: BorderSide(
                  color: effectiveAccent.withValues(alpha: 0.35),
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppTheme.textMuted,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (stackTag && tagText != null) ...[
                  const SizedBox(height: 3),
                  tagText,
                ],
              ],
            ),
          ),
          if (!stackTag && tagText != null) ...[
            const SizedBox(width: 8),
            tagText,
          ],
        ],
      ),
    );
    if (semanticsLabel == null) return row;
    return Semantics(
      container: true,
      label: semanticsLabel,
      child: ExcludeSemantics(child: row),
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
          // Same active treatment as the verified navigation dock, now with the
          // bevelled plate shape used by the badges and the arm selector.
          decoration: ShapeDecoration(
            color: isSelected
                ? AppTheme.crimson.withValues(alpha: 0.12)
                : Colors.transparent,
            shape: BeveledRectangleBorder(
              side: BorderSide(
                color: isSelected
                    ? AppTheme.crimson.withValues(alpha: 0.35)
                    : const Color(0x1FFFFFFF),
                width: _borderWidth,
              ),
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          child: expand ? text : Center(widthFactor: 1.0, child: text),
        ),
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
    final authProfile = authState.userProfile ?? {};
    final profileAsync = ref.watch(athleteProfileProvider);
    final mergedProfile = <String, dynamic>{
      ...authProfile,
      if (profileAsync.value != null) ...profileAsync.value!,
    };

    final displayName = (mergedProfile['displayName']?.toString().isNotEmpty == true)
        ? mergedProfile['displayName'].toString()
        : (authProfile['fullName']?.toString() ?? 'Athlete');
    final email = authProfile['email']?.toString() ?? mergedProfile['email']?.toString() ?? '';
    final role = (authProfile['role'] ?? mergedProfile['role'] ?? 'ATHLETE')
        .toString()
        .toUpperCase();
    const officialRoles = {
      'REFEREE',
      'PROVINCIAL_DIRECTOR',
      'NATIONAL_DIRECTOR',
      'SYSTEM_ADMIN'
    };
    final isOfficial = officialRoles.contains(role);

    final myProfileId =
        profileAsync.value?['id']?.toString() ?? authProfile['id']?.toString();
    final clubName = mergedProfile['club'] is Map
        ? mergedProfile['club']['name']?.toString()
        : mergedProfile['clubName']?.toString();
    final location = [
      mergedProfile['city']?.toString(),
      mergedProfile['province']?.toString(),
    ].where((v) => v != null && v.isNotEmpty).join(', ');

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
          if (myProfileId != null && myProfileId.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppTheme.goldPrimary),
              tooltip: 'Edit Profile & Biometrics',
              onPressed: () {
                HapticFeedback.selectionClick();
                _showEditProfileSheet(context, ref, mergedProfile, myProfileId);
              },
            ),
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
          MainShellScope.isInsideShell(context)
              ? MainShellScope.bottomClearance(context, additionalPadding: 36)
              : kFloatingDockTotalHeight + MediaQuery.paddingOf(context).bottom + 36,
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
                          (mergedProfile['profilePhoto'] ?? mergedProfile['avatarUrl'])
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
                          [
                            if (clubName != null && clubName.isNotEmpty) clubName,
                            if (location.isNotEmpty) location,
                            if ((clubName == null || clubName.isEmpty) && location.isEmpty)
                              (email.isEmpty ? 'Federation Member' : email),
                          ].join(' • '),
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
                                      mergedProfile['weightKg'] ?? mergedProfile['weight'],
                                      mergedProfile['weightClass']?.toString()),
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
                                  : (mergedProfile['weightClass'] != null &&
                                          mergedProfile['weightClass'].toString().isNotEmpty
                                      ? 'Official PAFF • ${mergedProfile['weightClass']}'
                                      : 'Official PAFF Competitor'),
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

            // 2. Competitive ELO Rating with Arm-Switch Flip (SIG-4 & SIG-3)
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
              error: (_, __) => ArmSwitchEloCard(profileData: mergedProfile),
              data: (p) => ArmSwitchEloCard(profileData: p),
            ),
            const SizedBox(height: 22),

            // 4. Biometrics & Specifications (Unbundled Plane)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                if (myProfileId != null && myProfileId.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _showEditProfileSheet(context, ref, mergedProfile, myProfileId);
                    },
                    child: const Text(
                      'EDIT METRICS',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.goldPrimary,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
              ],
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
              error: (_, __) => _buildBiometricsCard(mergedProfile),
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
                  const Divider(height: 1, color: AppTheme.borderSubtle),
                  _WorkspaceTile(
                    icon: Icons.groups_outlined,
                    iconColor: AppTheme.cyan,
                    title: 'Teams & Club Affiliations',
                    subtitle: 'Federation clubs, rosters and team standings',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.push('/teams');
                    },
                  ),
                  const Divider(height: 1, color: AppTheme.borderSubtle),
                  _WorkspaceTile(
                    icon: Icons.emoji_events_outlined,
                    iconColor: AppTheme.goldPrimary,
                    title: 'National Championship Titles',
                    subtitle: 'Official division title holders and lineage',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.push('/championship/titles');
                    },
                  ),
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
    final measurements = profile['measurements'] as Map<String, dynamic>?;
    final biometrics = profile['biometrics'] as Map<String, dynamic>?;
    final weight = profile['weightKg'] ?? profile['weight'] ?? measurements?['weight'];
    final height = profile['heightCm'] ?? profile['height'] ?? measurements?['height'];
    final reach = profile['reachCm'] ?? profile['reach'] ?? measurements?['reach'];
    final dominance = profile['armDominance']?.toString() ??
        profile['dominantArm']?.toString();

    final forearm = biometrics?['forearmCircumference'];
    final bicep = biometrics?['bicepCircumference'];
    final handLength = biometrics?['handLength'] ?? biometrics?['handWidth'];
    final hasArmBiometrics = forearm != null || bicep != null || handLength != null;

    return ElevatedActionCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        children: [
          Row(
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
          if (hasArmBiometrics) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: AppTheme.borderSubtle),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SpecItem(
                    label: 'Forearm',
                    value: forearm != null ? '${forearm}cm' : '--'),
                _SpecItem(
                    label: 'Bicep',
                    value: bicep != null ? '${bicep}cm' : '--'),
                _SpecItem(
                    label: 'Hand Span',
                    value: handLength != null ? '${handLength}cm' : '--'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showEditProfileSheet(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> profile,
    String athleteId,
  ) async {
    final measurements = profile['measurements'] as Map<String, dynamic>?;
    final biometrics = profile['biometrics'] as Map<String, dynamic>?;

    final nameCtrl = TextEditingController(
      text: profile['displayName']?.toString() ?? '',
    );
    final bioCtrl = TextEditingController(
      text: profile['biography']?.toString() ?? '',
    );
    final weightCtrl = TextEditingController(
      text: (profile['weight'] ?? profile['weightKg'] ?? measurements?['weight'])?.toString() ?? '',
    );
    final heightCtrl = TextEditingController(
      text: (profile['height'] ?? profile['heightCm'] ?? measurements?['height'])?.toString() ?? '',
    );
    final reachCtrl = TextEditingController(
      text: (profile['reach'] ?? profile['reachCm'] ?? measurements?['reach'])?.toString() ?? '',
    );
    final forearmCtrl = TextEditingController(
      text: biometrics?['forearmCircumference']?.toString() ?? '',
    );
    final bicepCtrl = TextEditingController(
      text: biometrics?['bicepCircumference']?.toString() ?? '',
    );
    final handCtrl = TextEditingController(
      text: (biometrics?['handLength'] ?? biometrics?['handWidth'])?.toString() ?? '',
    );

    const weightClasses = ['65kg', '75kg', '85kg', '95kg', '105kg', '105kg+'];
    String selectedWeightClass = profile['weightClass']?.toString() ?? '85kg';
    if (!weightClasses.contains(selectedWeightClass)) {
      selectedWeightClass = '85kg';
    }

    const arms = ['RIGHT', 'LEFT', 'AMBIDEXTROUS'];
    String selectedArm = (profile['dominantArm']?.toString() ?? 'RIGHT').toUpperCase();
    if (!arms.contains(selectedArm)) {
      selectedArm = 'RIGHT';
    }

    bool saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'EDIT PROFILE & BIOMETRICS',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: AppTheme.goldPrimary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: AppTheme.textMuted),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Display Name',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedWeightClass,
                            dropdownColor: AppTheme.cardSurface,
                            decoration: const InputDecoration(
                              labelText: 'Weight Class',
                              isDense: true,
                            ),
                            items: weightClasses
                                .map((wc) => DropdownMenuItem(value: wc, child: Text(wc)))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setSheetState(() => selectedWeightClass = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedArm,
                            dropdownColor: AppTheme.cardSurface,
                            decoration: const InputDecoration(
                              labelText: 'Dominant Arm',
                              isDense: true,
                            ),
                            items: arms
                                .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setSheetState(() => selectedArm = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: weightCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Weight (kg)',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: heightCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Height (cm)',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: reachCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Reach (cm)',
                              isDense: true,
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
                            controller: forearmCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Forearm (cm)',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: bicepCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Bicep (cm)',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: handCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Hand Span (cm)',
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bioCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Athletic Bio',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: saving
                            ? null
                            : () async {
                                HapticFeedback.mediumImpact();
                                setSheetState(() => saving = true);
                                final profilePayload = <String, dynamic>{
                                  if (nameCtrl.text.trim().length >= 2)
                                    'displayName': nameCtrl.text.trim(),
                                  'weightClass': selectedWeightClass,
                                  'dominantArm': selectedArm,
                                  'handedness': selectedArm,
                                  'biography': bioCtrl.text.trim(),
                                };
                                final w = double.tryParse(weightCtrl.text.trim());
                                final h = double.tryParse(heightCtrl.text.trim());
                                final r = double.tryParse(reachCtrl.text.trim());
                                if (w != null && w > 0) profilePayload['weight'] = w;
                                if (h != null && h > 0) profilePayload['height'] = h;
                                if (r != null && r > 0) profilePayload['reach'] = r;

                                final bioPayload = <String, dynamic>{};
                                final fa = double.tryParse(forearmCtrl.text.trim());
                                final bi = double.tryParse(bicepCtrl.text.trim());
                                final hl = double.tryParse(handCtrl.text.trim());
                                if (fa != null && fa > 0) bioPayload['forearmCircumference'] = fa;
                                if (bi != null && bi > 0) bioPayload['bicepCircumference'] = bi;
                                if (hl != null && hl > 0) bioPayload['handLength'] = hl;

                                final ok = await ref
                                    .read(athleteProfileProvider.notifier)
                                    .updateProfileAndBiometrics(
                                      athleteId: athleteId,
                                      profileData: profilePayload,
                                      biometricsData: bioPayload,
                                    );
                                if (ctx.mounted) {
                                  Navigator.of(ctx).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        ok
                                            ? 'Profile & biometrics updated.'
                                            : 'Could not update profile.',
                                      ),
                                      backgroundColor:
                                          ok ? AppTheme.success : AppTheme.error,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                        child: saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
        1000;
    final leftElo = (p['leftArmElo'] as num?)?.toInt() ??
        (p['eloRating'] as num?)?.toInt() ??
        1000;
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
class AthleteAchievementsScreen extends ConsumerWidget {
  final String? athleteId;

  const AthleteAchievementsScreen({super.key, this.athleteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetId = (athleteId != null && athleteId!.trim().isNotEmpty)
        ? athleteId!.trim()
        : null;
    final profileAsync = targetId != null
        ? ref.watch(publicAthleteProfileProvider(targetId))
        : ref.watch(athleteProfileProvider);
    final athleteName = profileAsync.value?['displayName']?.toString();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          athleteName != null && athleteName.isNotEmpty && targetId != null
              ? '$athleteName • Athletic Honors'
              : 'Athletic Honors',
          style: const TextStyle(
              fontFamily: 'Space Grotesk', fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            AchievementsSection(athleteData: profileAsync.value),
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
