import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/widgets/armsphere_image.dart';
import '../../../core/providers/athlete_provider.dart';
import '../../../core/providers/state_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/crystal_glass_nav_controls.dart';
import '../../../core/widgets/crystal_stage_scaffold.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';

/// Canary 5: Head-to-Head Comparison Screen (`/matches/head-to-head`)
///
/// Supreme Sports Authority & Anti-Drift:
/// - Tale of the Tape: Direct physical, tactical, and statistical comparison between two armwrestlers.
/// - 15° Diagonal Shear Divider in Champagne Gold (`#D4AF37`) with glowing laser bloom.
/// - Left Competitor: Red Corner (`#EF4444` ambient hue & corner badge).
/// - Right Competitor: Blue Corner (`#38BDF8` ambient hue & corner badge).
/// - Walkout Entry Animation (SIG-1, 500ms): Panels slide in from left/right (200ms `Curves.easeOutCubic`),
///   center laser divider slices down (150ms `Curves.easeInOutCubic`), VS locks with heavy haptic (350ms).
/// - Center Axis Metric Bar Growth (350ms `Curves.easeOutCubic`): Comparative bilateral bars
///   expanding outward from center for Forearm, Bicep, Hand Size, Reach, Body Weight, Win Rate, and ELO.
/// - Arm Toggle: Synchronized 3D perspective flip (SIG-4) switching between Right Arm and Left Arm metrics.
/// - Tabular monospace figures (`FontFeature.tabularFigures()`) to eradicate layout jitter.
class HeadToHeadScreen extends ConsumerStatefulWidget {
  final String? matchId;
  final String? athleteId1;
  final String? athleteId2;
  final Map<String, dynamic>? initialMatchData;

  const HeadToHeadScreen({
    super.key,
    this.matchId,
    this.athleteId1,
    this.athleteId2,
    this.initialMatchData,
  });

  @override
  ConsumerState<HeadToHeadScreen> createState() => _HeadToHeadScreenState();
}

class _HeadToHeadScreenState extends ConsumerState<HeadToHeadScreen>
    with TickerProviderStateMixin {
  // SIG-1 Walkout Animation Controller (500ms total sequence)
  late AnimationController _walkoutController;
  late Animation<double> _redSlideAnim;
  late Animation<double> _blueSlideAnim;
  late Animation<double> _laserLineAnim;
  late Animation<double> _vsLockAnim;
  late Animation<double> _barsGrowthAnim;

  // SIG-4 3D Flip Controller for Arm Toggle (240ms duration)
  late AnimationController _armFlipController;
  late Animation<double> _flipRotationAnim;

  bool _isRightArm = true;
  String? _selectedAthleteId1;
  String? _selectedAthleteId2;

  @override
  void initState() {
    super.initState();
    _selectedAthleteId1 = widget.athleteId1;
    _selectedAthleteId2 = widget.athleteId2;

    // 1. SIG-1 Walkout Entrance Sequence (500ms)
    _walkoutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Stage 1 (0–200ms): Red Corner slides in from left (-100% to 0%)
    _redSlideAnim = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _walkoutController,
        curve: const Interval(0.0, 0.40, curve: Curves.easeOutCubic),
      ),
    );

    // Stage 1 (0–200ms): Blue Corner slides in from right (+100% to 0%)
    _blueSlideAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _walkoutController,
        curve: const Interval(0.0, 0.40, curve: Curves.easeOutCubic),
      ),
    );

    // Stage 2 (200–350ms): Gold laser line cuts down 15° shear line
    _laserLineAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _walkoutController,
        curve: const Interval(0.40, 0.70, curve: Curves.easeInOutCubic),
      ),
    );

    // Stage 3 (350–500ms): Central VS crest slam and lock
    _vsLockAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _walkoutController,
        curve: const Interval(0.65, 1.00, curve: Curves.easeOutBack),
      ),
    );

    // Stage 3 (350–500ms): Metric bars expand from center axis
    _barsGrowthAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _walkoutController,
        curve: const Interval(0.50, 1.00, curve: Curves.easeOutCubic),
      ),
    );

    // 2. SIG-4 3D Card Flip (240ms)
    _armFlipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );

    _flipRotationAnim = Tween<double>(begin: 0.0, end: math.pi).animate(
      CurvedAnimation(parent: _armFlipController, curve: Curves.easeInOutCubic),
    );

    // Run walkout entrance sequence with tactile checkpoints
    _walkoutController.forward();

    // Haptic checkpoint at 200ms (laser slice)
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) HapticFeedback.mediumImpact();
    });

    // Haptic checkpoint at 350ms (VS lock)
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) HapticFeedback.heavyImpact();
    });
  }

  @override
  void didUpdateWidget(covariant HeadToHeadScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.athleteId1 != oldWidget.athleteId1 && widget.athleteId1 != null) {
      _selectedAthleteId1 = widget.athleteId1;
    }
    if (widget.athleteId2 != oldWidget.athleteId2 && widget.athleteId2 != null) {
      _selectedAthleteId2 = widget.athleteId2;
    }
  }

  @override
  void dispose() {
    _walkoutController.dispose();
    _armFlipController.dispose();
    super.dispose();
  }

  void _toggleArm() {
    HapticFeedback.selectionClick();
    if (_armFlipController.isAnimating) return;

    if (_isRightArm) {
      _armFlipController.forward().then((_) {
        setState(() => _isRightArm = false);
      });
    } else {
      _armFlipController.reverse().then((_) {
        setState(() => _isRightArm = true);
      });
    }
  }

  Map<String, dynamic> _extractAthleteMetrics(
    Map<String, dynamic> a, {
    required String? fallbackId,
    required String defaultName,
    required String defaultNickname,
    required String defaultRank,
    required String defaultInitial,
  }) {
    final measurements = a['measurements'] as Map<String, dynamic>?;
    final biometrics = a['biometrics'] as Map<String, dynamic>?;
    final baseElo = (a['eloRating'] as num?)?.toInt() ?? 1000;
    final eloRight = (a['rightArmElo'] as num?)?.toInt() ?? baseElo;
    final eloLeft = (a['leftArmElo'] as num?)?.toInt() ?? baseElo;

    final wins = (a['wins'] as num?)?.toInt() ?? 0;
    final losses = (a['losses'] as num?)?.toInt() ?? 0;
    final careerRate = (wins + losses) > 0 ? (wins / (wins + losses)) * 100.0 : 0.0;
    final winRateRight = (a['winRateRight'] as num?)?.toDouble() ?? careerRate;
    final winRateLeft = (a['winRateLeft'] as num?)?.toDouble() ?? careerRate;

    final forearmCm = (biometrics?['forearmCircumference'] as num?)?.toDouble() ??
        (measurements?['forearmCircumference'] as num?)?.toDouble() ??
        0.0;
    final bicepCm = (biometrics?['bicepCircumference'] as num?)?.toDouble() ??
        (measurements?['bicepCircumference'] as num?)?.toDouble() ??
        0.0;
    final handSpanCm = (biometrics?['handLength'] as num?)?.toDouble() ??
        (biometrics?['handWidth'] as num?)?.toDouble() ??
        (measurements?['handSpan'] as num?)?.toDouble() ??
        0.0;
    final reachCm = (a['reachCm'] as num?)?.toDouble() ??
        (a['reach'] as num?)?.toDouble() ??
        (measurements?['reach'] as num?)?.toDouble() ??
        (biometrics?['armSpan'] as num?)?.toDouble() ??
        0.0;
    final weightKg = (a['weightKg'] as num?)?.toDouble() ??
        (a['weight'] as num?)?.toDouble() ??
        (measurements?['weight'] as num?)?.toDouble() ??
        0.0;

    final name = a['displayName']?.toString() ?? defaultName;
    final dominant = (a['dominantArm']?.toString() ?? 'RIGHT').toUpperCase();

    return {
      'id': a['id']?.toString() ?? a['athleteId']?.toString() ?? fallbackId,
      'userId': a['userId']?.toString(),
      'name': name,
      'nickname': defaultNickname,
      'club': a['clubName']?.toString() ??
          (a['club'] is Map ? a['club']['name']?.toString() : null) ??
          'Independent',
      'province': a['province']?.toString() ?? 'Pakistan',
      'countryCode': 'PK',
      'rank': defaultRank,
      'weightClass': a['weightClass']?.toString() ?? 'OPEN',
      'avatar': (a['avatarUrl']?.toString().isNotEmpty == true)
          ? a['avatarUrl']
          : (name.isNotEmpty ? name[0].toUpperCase() : defaultInitial),
      'avatarUrl': (a['avatarUrl'] ?? a['profilePhoto'])?.toString(),
      'eloRight': eloRight,
      'eloLeft': eloLeft,
      'winRateRight': winRateRight,
      'winRateLeft': winRateLeft,
      'forearmCm': forearmCm,
      'bicepCm': bicepCm,
      'handSpanCm': handSpanCm,
      'reachCm': reachCm,
      'weightKg': weightKg,
      'pullStyle': dominant == 'LEFT'
          ? 'OUTSIDE TOP-ROLL (LEFT)'
          : (dominant == 'AMBIDEXTROUS' ? 'VERSATILE DUAL-ARM' : 'INSIDE HOOK & TOP-ROLL'),
    };
  }

  // --- Dynamic Athlete Profiles ---
  Map<String, dynamic> _resolveRedAthlete([
    Map<String, dynamic>? comparisonData,
    Map<String, dynamic>? redCornerProfile,
  ]) {
    if (comparisonData != null && comparisonData['athlete1'] is Map) {
      return _extractAthleteMetrics(
        Map<String, dynamic>.from(comparisonData['athlete1'] as Map),
        fallbackId: _selectedAthleteId1 ?? widget.athleteId1,
        defaultName: 'Athlete 1',
        defaultNickname: 'CONTENDER',
        defaultRank: 'RED CORNER',
        defaultInitial: 'R',
      );
    }
    if (redCornerProfile != null && redCornerProfile.isNotEmpty) {
      return _extractAthleteMetrics(
        redCornerProfile,
        fallbackId: redCornerProfile['id']?.toString() ?? _selectedAthleteId1,
        defaultName: 'Red Corner Contender',
        defaultNickname: 'RED CORNER',
        defaultRank: 'RED CORNER',
        defaultInitial: 'R',
      );
    }
    return {
      'id': _selectedAthleteId1 ?? widget.athleteId1,
      'name': 'Red Corner Contender',
      'nickname': 'RED CORNER',
      'club': 'Tap to Select Athlete',
      'province': 'Pakistan',
      'countryCode': 'PK',
      'rank': 'CONTENDER',
      'weightClass': 'OPEN',
      'avatar': 'R',
      'avatarUrl': null,
      'eloRight': 1500,
      'eloLeft': 1500,
      'winRateRight': 0.0,
      'winRateLeft': 0.0,
      'forearmCm': 0.0,
      'bicepCm': 0.0,
      'handSpanCm': 0.0,
      'reachCm': 0.0,
      'weightKg': 0.0,
      'pullStyle': 'UNSPECIFIED',
    };
  }

  Map<String, dynamic> _resolveBlueAthlete([
    Map<String, dynamic>? comparisonData,
    Map<String, dynamic>? blueCornerProfile,
  ]) {
    if (comparisonData != null && comparisonData['athlete2'] is Map) {
      return _extractAthleteMetrics(
        Map<String, dynamic>.from(comparisonData['athlete2'] as Map),
        fallbackId: _selectedAthleteId2 ?? widget.athleteId2,
        defaultName: 'Athlete 2',
        defaultNickname: 'RIVAL',
        defaultRank: 'BLUE CORNER',
        defaultInitial: 'B',
      );
    }
    if (blueCornerProfile != null && blueCornerProfile.isNotEmpty) {
      return _extractAthleteMetrics(
        blueCornerProfile,
        fallbackId: blueCornerProfile['id']?.toString() ?? _selectedAthleteId2,
        defaultName: 'Blue Corner Contender',
        defaultNickname: 'BLUE CORNER',
        defaultRank: 'BLUE CORNER',
        defaultInitial: 'B',
      );
    }
    return {
      'id': _selectedAthleteId2 ?? widget.athleteId2,
      'name': 'Blue Corner Contender',
      'nickname': 'BLUE CORNER',
      'club': 'Tap to Select Opponent',
      'province': 'Pakistan',
      'countryCode': 'PK',
      'rank': 'CONTENDER',
      'weightClass': 'OPEN',
      'avatar': 'B',
      'avatarUrl': null,
      'eloRight': 1500,
      'eloLeft': 1500,
      'winRateRight': 0.0,
      'winRateLeft': 0.0,
      'forearmCm': 0.0,
      'bicepCm': 0.0,
      'handSpanCm': 0.0,
      'reachCm': 0.0,
      'weightKg': 0.0,
      'pullStyle': 'UNSPECIFIED',
    };
  }

  @override
  Widget build(BuildContext context) {
    final selfProfile = ref.watch(athleteProfileProvider).value;
    final effectiveId1 = _selectedAthleteId1 ??
        widget.athleteId1 ??
        selfProfile?['id']?.toString();
    final effectiveId2 = _selectedAthleteId2 ?? widget.athleteId2;

    final comparisonAsync = (effectiveId1 != null &&
            effectiveId1.isNotEmpty &&
            effectiveId2 != null &&
            effectiveId2.isNotEmpty)
        ? ref.watch(athleteComparisonProvider(
            (athlete1Id: effectiveId1, athlete2Id: effectiveId2)))
        : null;
    final singleRedProfile = (comparisonAsync?.value == null &&
            effectiveId1 != null &&
            effectiveId1.isNotEmpty &&
            effectiveId1 != selfProfile?['id']?.toString())
        ? ref.watch(publicAthleteProfileProvider(effectiveId1)).value
        : selfProfile;
    final singleBlueProfile = (comparisonAsync?.value == null &&
            effectiveId2 != null &&
            effectiveId2.isNotEmpty)
        ? ref.watch(publicAthleteProfileProvider(effectiveId2)).value
        : null;
    final red = _resolveRedAthlete(comparisonAsync?.value, singleRedProfile);
    final blue = _resolveBlueAthlete(comparisonAsync?.value, singleBlueProfile);
    final headToHead = comparisonAsync?.value?['headToHead'] as Map<String, dynamic>?;

    final redElo = (_isRightArm ? red['eloRight'] : red['eloLeft']) as int;
    final blueElo = (_isRightArm ? blue['eloRight'] : blue['eloLeft']) as int;
    final redWinRate = (_isRightArm ? red['winRateRight'] : red['winRateLeft']) as double;
    final blueWinRate = (_isRightArm ? blue['winRateRight'] : blue['winRateLeft']) as double;
    final eloDiff = (redElo - blueElo).abs();
    final redFavored = redElo >= blueElo;

    return Scaffold(
      backgroundColor: Colors.transparent, // Crystal Stage
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const CrystalBackButton(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                ArmSphereImage(
                  assetPath: ArmSphereAssets.sealFed,
                  width: 16,
                  height: 16,
                  semanticLabel: 'Official Federation Sanctioned Match',
                ),
                SizedBox(width: 6),
                Text(
                  'TALE OF THE TAPE',
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            Text(
              '${red['weightClass']} • ${_isRightArm ? 'RIGHT ARM' : 'LEFT ARM'} DIVISION',
              style: const TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 11,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          // Arm Switch Dual-Pill Container (ISSUE-P3-01: 90% opacity, gold border on active arm)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Semantics(
                button: true,
                label: 'Switch arm comparison. Currently ${_isRightArm ? "Right Arm" : "Left Arm"} selected.',
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF334155),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Right Arm Segment
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          if (!_isRightArm) _toggleArm();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isRightArm
                                ? const Color(0xFF1E293B)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _isRightArm
                                  ? AppTheme.goldPrimary
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                            boxShadow: _isRightArm
                                ? [
                                    BoxShadow(
                                      color: AppTheme.goldPrimary.withValues(alpha: 0.35),
                                      blurRadius: 4,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.pan_tool_alt_rounded,
                                size: 12,
                                color: _isRightArm
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'RIGHT',
                                style: TextStyle(
                                  fontFamily: 'Space Grotesk',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: _isRightArm
                                      ? Colors.white
                                      : const Color(0xFF94A3B8),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      // Left Arm Segment
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          if (_isRightArm) _toggleArm();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: !_isRightArm
                                ? const Color(0xFF1E293B)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: !_isRightArm
                                  ? AppTheme.goldPrimary
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                            boxShadow: !_isRightArm
                                ? [
                                    BoxShadow(
                                      color: AppTheme.goldPrimary.withValues(alpha: 0.35),
                                      blurRadius: 4,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.pan_tool_alt_rounded,
                                size: 12,
                                color: !_isRightArm
                                    ? const Color(0xFF38BDF8)
                                    : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'LEFT',
                                style: TextStyle(
                                  fontFamily: 'Space Grotesk',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: !_isRightArm
                                      ? Colors.white
                                      : const Color(0xFF94A3B8),
                                  letterSpacing: 0.5,
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
            ),
          ),
          const CrystalHomeButton(),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: CrystalStageBackdrop(domain: ArmSphereStageDomain.arena),
          ),
          (comparisonAsync != null && comparisonAsync.isLoading)
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.goldPrimary),
                  SizedBox(height: 16),
                  Text(
                    'LOADING OFFICIAL MATCHUP DATA...',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            )
          : (comparisonAsync != null && comparisonAsync.hasError)
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
                        const SizedBox(height: 12),
                        const Text(
                          'FAILED TO LOAD MATCHUP',
                          style: TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          comparisonAsync.error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.goldPrimary,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () => ref.invalidate(athleteComparisonProvider),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('RETRY'),
                        ),
                      ],
                    ),
                  ),
                )
              : RepaintBoundary(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      if (effectiveId1 == null || effectiveId2 == null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          color: const Color(0xFF141824),
                          child: Row(
                            children: [
                              const Icon(Icons.sports_mma_outlined, size: 16, color: AppTheme.goldPrimary),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Select contenders to load live federation Tale of the Tape metrics.',
                                  style: TextStyle(
                                    fontFamily: 'Space Grotesk',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.goldPrimary,
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: () => _showAthletePickerSheet(isRedCorner: effectiveId1 == null),
                                icon: const Icon(Icons.person_search_outlined, size: 15),
                                label: const Text(
                                  'PICK OPPONENT',
                                  style: TextStyle(
                                    fontFamily: 'Space Grotesk',
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // 1. Walkout Hero Stage with 15° Diagonal Shear Divider
                      _buildWalkoutHeroStage(red, blue, redElo, blueElo, redFavored, eloDiff),

                      // 2. Tactical Arm Toggle & Favorability Banner
                      _buildTacticalMatchBanner(red, blue, redFavored, eloDiff),

                      const SizedBox(height: 16),

                      // 3. Center Axis Comparative Biometric Bars
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildBiometricsComparisonPlane(
                          red: red,
                          blue: blue,
                          redWinRate: redWinRate,
                          blueWinRate: blueWinRate,
                          redElo: redElo,
                          blueElo: blueElo,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 4. Tactical Pulling Styles Comparison
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildTacticalStyleCard(red, blue),
                      ),

                      const SizedBox(height: 16),

                      // 5. Head-to-Head Series & Matchup Actions
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildSeriesAndActionsCard(red, blue, headToHead),
                      ),

                      const SizedBox(height: 28),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  // --- 1. Walkout Hero Stage with 15° Diagonal Shear Divider ---
  Widget _buildWalkoutHeroStage(
    Map<String, dynamic> red,
    Map<String, dynamic> blue,
    int redElo,
    int blueElo,
    bool redFavored,
    int eloDiff,
  ) {
    const double heroHeight = 260.0;

    return SizedBox(
      height: heroHeight,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Red Corner Panel (Left Side with 15° Shear Angle)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _redSlideAnim,
              builder: (context, _) {
                return Transform.translate(
                  offset: Offset(_redSlideAnim.value * MediaQuery.of(context).size.width, 0),
                  child: ClipPath(
                    clipper: _LeftDiagonalClipper(),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF3F0B0B), // Deep Red Corner Hue
                            Color(0xFF1E0A0A),
                            Color(0xFF0F172A),
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20, top: 20, right: 60),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Corner Badge
                            _buildCornerPill('RED CORNER', const Color(0xFFEF4444)),
                            const SizedBox(height: 12),

                            // Clickable Avatar with Red Ring (ISSUE-P3-01: Direct passport navigation)
                            TactilePressWrapper(
                              onTap: () {
                                final athleteId = red['id']?.toString() ?? widget.athleteId1;
                                if (athleteId != null && athleteId.isNotEmpty) {
                                  context.push('/athlete/$athleteId');
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Athlete passport unavailable in preview mode.'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              child: Tooltip(
                                message: 'View ${red['name']} Passport',
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFEF4444), width: 2.2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                                        blurRadius: 12,
                                      ),
                                    ],
                                  ),
                                  child: ArmSphereImage.avatar(
                                    imageUrl: red['avatarUrl']?.toString(),
                                    initial: red['avatar']?.toString() ?? (red['name']?.toString().isNotEmpty == true ? red['name']![0] : 'R'),
                                    size: 52,
                                    fallbackAsset: ArmSphereAssets.defaultAvatar,
                                    semanticLabel: 'Red corner competitor avatar for ${red['name']}',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Athlete Name & Rank
                            Text(
                              red['name'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Space Grotesk',
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: Colors.white,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${red['rank']} • ${red['province']}',
                              style: const TextStyle(
                                fontFamily: 'Space Grotesk',
                                fontSize: 10,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$redElo ELO',
                              style: const TextStyle(
                                fontFamily: 'Space Grotesk',
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: Color(0xFFEF4444),
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Blue Corner Panel (Right Side with 15° Shear Angle)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _blueSlideAnim,
              builder: (context, _) {
                return Transform.translate(
                  offset: Offset(_blueSlideAnim.value * MediaQuery.of(context).size.width, 0),
                  child: ClipPath(
                    clipper: _RightDiagonalClipper(),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [
                            Color(0xFF0C2744), // Deep Blue Corner Hue
                            Color(0xFF09192C),
                            Color(0xFF0F172A),
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20, top: 20, left: 60),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Corner Badge
                            _buildCornerPill('BLUE CORNER', const Color(0xFF38BDF8)),
                            const SizedBox(height: 12),

                            // Clickable Avatar with Blue Ring (ISSUE-P3-01: Direct passport navigation)
                            TactilePressWrapper(
                              onTap: () {
                                final athleteId = blue['id']?.toString() ?? widget.athleteId2;
                                if (athleteId != null && athleteId.isNotEmpty) {
                                  context.push('/athlete/$athleteId');
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Athlete passport unavailable in preview mode.'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              child: Tooltip(
                                message: 'View ${blue['name']} Passport',
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF38BDF8), width: 2.2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                                        blurRadius: 12,
                                      ),
                                    ],
                                  ),
                                  child: ArmSphereImage.avatar(
                                    imageUrl: blue['avatarUrl']?.toString(),
                                    initial: blue['avatar']?.toString() ?? (blue['name']?.toString().isNotEmpty == true ? blue['name']![0] : 'B'),
                                    size: 52,
                                    fallbackAsset: ArmSphereAssets.defaultAvatar,
                                    semanticLabel: 'Blue corner competitor avatar for ${blue['name']}',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Athlete Name & Rank
                            Text(
                              blue['name'],
                              textAlign: TextAlign.right,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Space Grotesk',
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: Colors.white,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${blue['rank']} • ${blue['province']}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontFamily: 'Space Grotesk',
                                fontSize: 10,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$blueElo ELO',
                              style: const TextStyle(
                                fontFamily: 'Space Grotesk',
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: Color(0xFF38BDF8),
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Laser Divider Line (Stage 2: 15° Champagne Gold Beam)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _laserLineAnim,
              builder: (context, _) {
                if (_laserLineAnim.value <= 0.0) return const SizedBox.shrink();
                return CustomPaint(
                  painter: _LaserDividerPainter(
                    progress: _laserLineAnim.value,
                    laserColor: AppTheme.goldPrimary,
                  ),
                );
              },
            ),
          ),

          // Central "VS" Medallion (Stage 3 Lock)
          Center(
            child: AnimatedBuilder(
              animation: _vsLockAnim,
              builder: (context, child) {
                final scale = _vsLockAnim.value.clamp(0.0, 1.0);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF070A11),
                      border: Border.all(color: AppTheme.goldPrimary, width: 2.0),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.goldPrimary.withValues(alpha: 0.5),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'VS',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: AppTheme.goldPrimary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Space Grotesk',
          fontWeight: FontWeight.w900,
          fontSize: 8.5,
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // --- 2. Tactical Match Banner ---
  Widget _buildTacticalMatchBanner(
    Map<String, dynamic> red,
    Map<String, dynamic> blue,
    bool redFavored,
    int eloDiff,
  ) {
    final favoredColor = redFavored ? const Color(0xFFEF4444) : const Color(0xFF38BDF8);
    final favoredName = redFavored ? red['name'] : blue['name'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.glassSurface,
        gradient: AppTheme.brushedSteelGradient,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderTitanium),
        boxShadow: [AppTheme.titaniumShadow()],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, size: 16, color: AppTheme.goldPrimary),
              const SizedBox(width: 6),
              const Text(
                'FEDERATION FAVORABILITY:',
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontWeight: FontWeight.w800,
                  fontSize: 9.5,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                favoredName.split(' ')[0],
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  color: favoredColor,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.goldPrimary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '+$eloDiff PTS FAVOR',
              style: const TextStyle(
                fontFamily: 'Space Grotesk',
                fontWeight: FontWeight.w900,
                fontSize: 9,
                color: AppTheme.goldPrimary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Center Axis Comparative Biometric Bars ---
  Widget _buildBiometricsComparisonPlane({
    required Map<String, dynamic> red,
    required Map<String, dynamic> blue,
    required double redWinRate,
    required double blueWinRate,
    required int redElo,
    required int blueElo,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.glassSurface,
        gradient: AppTheme.machinedTitaniumGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderTitanium),
        boxShadow: [AppTheme.titaniumShadow()],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RED CORNER',
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  color: Color(0xFFEF4444),
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                'BIOMETRICS COMPARISON',
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontWeight: FontWeight.w900,
                  fontSize: 10.5,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                'BLUE CORNER',
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  color: Color(0xFF38BDF8),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFF334155), height: 1),
          const SizedBox(height: 12),

          // 1. Forearm Circumference
          _buildBilateralBar(
            label: 'FOREARM',
            redVal: red['forearmCm'] as double,
            blueVal: blue['forearmCm'] as double,
            unit: 'cm',
            maxExpected: 50.0,
          ),
          const SizedBox(height: 12),

          // 2. Bicep Measurement
          _buildBilateralBar(
            label: 'BICEP',
            redVal: red['bicepCm'] as double,
            blueVal: blue['bicepCm'] as double,
            unit: 'cm',
            maxExpected: 52.0,
          ),
          const SizedBox(height: 12),

          // 3. Hand Span / Palm Length
          _buildBilateralBar(
            label: 'HAND SPAN',
            redVal: red['handSpanCm'] as double,
            blueVal: blue['handSpanCm'] as double,
            unit: 'cm',
            maxExpected: 26.0,
          ),
          const SizedBox(height: 12),

          // 4. Reach
          _buildBilateralBar(
            label: 'REACH',
            redVal: red['reachCm'] as double,
            blueVal: blue['reachCm'] as double,
            unit: 'cm',
            maxExpected: 200.0,
          ),
          const SizedBox(height: 12),

          // 5. Official Weighed Weight
          _buildBilateralBar(
            label: 'WEIGHT',
            redVal: red['weightKg'] as double,
            blueVal: blue['weightKg'] as double,
            unit: 'kg',
            maxExpected: 100.0,
          ),
          const SizedBox(height: 12),

          // 6. Career Win Rate
          _buildBilateralBar(
            label: 'WIN RATE',
            redVal: redWinRate,
            blueVal: blueWinRate,
            unit: '%',
            maxExpected: 100.0,
          ),
          const SizedBox(height: 12),

          // 7. Official ELO Rating
          _buildBilateralBar(
            label: 'ELO SCORE',
            redVal: redElo.toDouble(),
            blueVal: blueElo.toDouble(),
            unit: 'pts',
            maxExpected: 2200.0,
            isInteger: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBilateralBar({
    required String label,
    required double redVal,
    required double blueVal,
    required String unit,
    required double maxExpected,
    bool isInteger = false,
  }) {
    final redRatio = (redVal / maxExpected).clamp(0.0, 1.0);
    final blueRatio = (blueVal / maxExpected).clamp(0.0, 1.0);
    final redLeads = redVal >= blueVal;
    final isPhysical = unit == 'cm' || unit == 'kg';

    final redStr = (isPhysical && redVal <= 0.0)
        ? '—'
        : (isInteger ? '${redVal.toInt()} $unit' : '${redVal.toStringAsFixed(1)} $unit');
    final blueStr = (isPhysical && blueVal <= 0.0)
        ? '—'
        : (isInteger ? '${blueVal.toInt()} $unit' : '${blueVal.toStringAsFixed(1)} $unit');

    return AnimatedBuilder(
      animation: _barsGrowthAnim,
      builder: (context, _) {
        final animatedRedRatio = redRatio * _barsGrowthAnim.value;
        final animatedBlueRatio = blueRatio * _barsGrowthAnim.value;

        return Column(
          children: [
            // Values and Label Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  redStr,
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontWeight: redLeads ? FontWeight.w900 : FontWeight.w600,
                    fontSize: 12,
                    color: redLeads ? const Color(0xFFEF4444) : Colors.white70,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  blueStr,
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontWeight: !redLeads ? FontWeight.w900 : FontWeight.w600,
                    fontSize: 12,
                    color: !redLeads ? const Color(0xFF38BDF8) : Colors.white70,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),

            // Bilateral Growing Horizontal Bars
            Row(
              children: [
                // Red Bar (Grows left-to-right toward center)
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FractionallySizedBox(
                      widthFactor: animatedRedRatio.clamp(0.01, 1.0),
                      child: Container(
                        height: 7,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(3)),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF991B1B), Color(0xFFEF4444)],
                          ),
                          boxShadow: redLeads
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),

                // Center Axis Tick Mark
                Container(
                  width: 2,
                  height: 12,
                  color: AppTheme.goldPrimary,
                ),

                // Blue Bar (Grows center toward right)
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: animatedBlueRatio.clamp(0.01, 1.0),
                      child: Container(
                        height: 7,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                          ),
                          boxShadow: !redLeads
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // --- 4. Tactical Pulling Styles Comparison ---
  Widget _buildTacticalStyleCard(Map<String, dynamic> red, Map<String, dynamic> blue) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.glassSurface,
        gradient: AppTheme.brushedSteelGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderTitanium),
        boxShadow: [AppTheme.titaniumShadow()],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology_outlined, size: 16, color: AppTheme.goldPrimary),
              SizedBox(width: 8),
              Text(
                'TACTICAL COMBAT ANALYSIS',
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: AppTheme.goldPrimary,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RED STRATEGY',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      red['pullStyle'],
                      style: const TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'BLUE STRATEGY',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF38BDF8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      blue['pullStyle'],
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                        color: Colors.white,
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
  }

  // --- 5. Head-to-Head Official Series & Matchup Actions ---
  Widget _buildSeriesAndActionsCard(
    Map<String, dynamic> red,
    Map<String, dynamic> blue,
    Map<String, dynamic>? headToHead,
  ) {
    final totalEncounters = (headToHead?['totalEncounters'] as num?)?.toInt() ?? 0;
    final redWins = (headToHead?['athlete1Wins'] as num?)?.toInt() ?? 0;
    final blueWins = (headToHead?['athlete2Wins'] as num?)?.toInt() ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.glassSurface,
        gradient: AppTheme.machinedTitaniumGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderTitanium),
        boxShadow: [AppTheme.titaniumShadow()],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.history_edu_outlined, size: 16, color: AppTheme.goldPrimary),
                  SizedBox(width: 8),
                  Text(
                    'OFFICIAL SERIES LEDGER',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      color: AppTheme.goldPrimary,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              Text(
                '$totalEncounters ENCOUNTER${totalEncounters == 1 ? '' : 'S'}',
                style: const TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMuted,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$redWins WINS',
                style: const TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFEF4444),
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                totalEncounters == 0 ? 'FIRST ENCOUNTER' : 'SERIES RECORD',
                style: const TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                '$blueWins WINS',
                style: const TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF38BDF8),
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFF334155), height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: BorderSide(color: const Color(0xFFEF4444).withValues(alpha: 0.45)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () => _showAthletePickerSheet(isRedCorner: true),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 15),
                  label: const Text(
                    'SWAP RED',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF38BDF8),
                    side: BorderSide(color: const Color(0xFF38BDF8).withValues(alpha: 0.45)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () => _showAthletePickerSheet(isRedCorner: false),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 15),
                  label: const Text(
                    'SWAP BLUE',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showAthletePickerSheet({required bool isRedCorner}) async {
    HapticFeedback.selectionClick();
    final searchCtrl = TextEditingController();
    List<Map<String, dynamic>> results = [];
    bool loading = true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111318),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            Future<void> runSearch(String query) async {
              setSheetState(() => loading = true);
              try {
                final list = await ref
                    .read(athleteRepositoryProvider)
                    .searchAthletes(query.trim());
                if (ctx.mounted) {
                  setSheetState(() {
                    results = list;
                    loading = false;
                  });
                }
              } catch (_) {
                if (ctx.mounted) {
                  setSheetState(() => loading = false);
                }
              }
            }

            if (loading && results.isEmpty && searchCtrl.text.isEmpty) {
              Future.microtask(() => runSearch(''));
            }

            final cornerLabel = isRedCorner ? 'RED CORNER' : 'BLUE CORNER';
            final cornerColor = isRedCorner
                ? const Color(0xFFEF4444)
                : const Color(0xFF38BDF8);

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SizedBox(
                height: 420,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SELECT $cornerLabel CONTENDER',
                          style: TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: cornerColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: AppTheme.textMuted),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: searchCtrl,
                      onChanged: (v) => runSearch(v),
                      decoration: const InputDecoration(
                        hintText: 'Search federation athletes by name...',
                        prefixIcon: Icon(Icons.search, size: 18),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: loading
                          ? const Center(
                              child: CircularProgressIndicator(color: AppTheme.goldPrimary),
                            )
                          : results.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No matching athletes found',
                                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: results.length,
                                  separatorBuilder: (_, __) => const Divider(
                                    height: 1,
                                    color: AppTheme.borderSubtle,
                                  ),
                                  itemBuilder: (_, idx) {
                                    final item = results[idx];
                                    final id = item['id']?.toString() ??
                                        item['athleteId']?.toString() ??
                                        '';
                                    final name = item['displayName']?.toString() ?? 'Athlete';
                                    final wc = item['weightClass']?.toString() ?? 'Open';
                                    final prov = item['province']?.toString() ?? '';
                                    final rElo = (item['rightArmElo'] as num?)?.toInt() ??
                                        (item['eloRating'] as num?)?.toInt() ??
                                        1000;
                                    return ListTile(
                                      dense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                                      leading: ArmSphereImage.avatar(
                                        imageUrl: (item['profilePhoto'] ?? item['avatarUrl'])?.toString(),
                                        initial: name,
                                        size: 36,
                                        fallbackAsset: ArmSphereAssets.defaultAvatar,
                                        semanticLabel: name,
                                      ),
                                      title: Text(
                                        name,
                                        style: const TextStyle(
                                          fontFamily: 'Space Grotesk',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13.5,
                                          color: Colors.white,
                                        ),
                                      ),
                                      subtitle: Text(
                                        [wc, if (prov.isNotEmpty) prov].join(' • '),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      trailing: Text(
                                        '$rElo ELO',
                                        style: TextStyle(
                                          fontFamily: 'Space Grotesk',
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                          color: cornerColor,
                                          fontFeatures: const [FontFeature.tabularFigures()],
                                        ),
                                      ),
                                      onTap: () {
                                        if (id.isEmpty) return;
                                        final selfId = ref.read(athleteProfileProvider).value?['id']?.toString();
                                        final oppositeCornerId = isRedCorner
                                            ? (_selectedAthleteId2 ?? widget.athleteId2)
                                            : (_selectedAthleteId1 ?? widget.athleteId1 ?? selfId);
                                        if (oppositeCornerId != null && oppositeCornerId == id) {
                                          HapticFeedback.heavyImpact();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Select a different athlete than the opposite corner contender.'),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                          return;
                                        }
                                        HapticFeedback.mediumImpact();
                                        setState(() {
                                          if (isRedCorner) {
                                            _selectedAthleteId1 = id;
                                          } else {
                                            _selectedAthleteId2 = id;
                                          }
                                        });
                                        Navigator.of(ctx).pop();
                                      },
                                    );
                                  },
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

// --- 15° Diagonal Clippers for Red & Blue Corner Panels ---

/// Left / Red corner diagonal polygon (15° cut from top-right to bottom-center)
class _LeftDiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width * 0.58, 0); // 15° shear angle offset
    path.lineTo(size.width * 0.42, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Right / Blue corner diagonal polygon (15° cut)
class _RightDiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width * 0.58, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width * 0.42, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// 15° Diagonal Laser Line Divider with Glowing Bloom
class _LaserDividerPainter extends CustomPainter {
  final double progress;
  final Color laserColor;

  _LaserDividerPainter({required this.progress, required this.laserColor});

  @override
  void paint(Canvas canvas, Size size) {
    final start = Offset(size.width * 0.58, 0);
    final end = Offset(size.width * 0.42, size.height);

    final currentEnd = Offset(
      start.dx + (end.dx - start.dx) * progress,
      start.dy + (end.dy - start.dy) * progress,
    );

    // Outer bloom
    final bloomPaint = Paint()
      ..color = laserColor.withValues(alpha: 0.45)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(start, currentEnd, bloomPaint);

    // Inner bright beam
    final corePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(start, currentEnd, corePaint);
  }

  @override
  bool shouldRepaint(covariant _LaserDividerPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
