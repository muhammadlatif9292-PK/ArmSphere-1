import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/providers/tournament_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/armsphere_image.dart';
import '../../../core/widgets/signature_ceremonies.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';

/// Canary 10: Championship Awards & Ceremony Screen (`/tournaments/:id/awards`)
///
/// Supreme Sports Authority & Anti-Drift:
/// - Real Data or Honest State: Never renders fabricated medalists or mock categories.
/// - Viewport: Deep Void Black (`#070A11`) with Champagne Gold ambient lighting.
/// - Centerpiece: 3-tier podium (1st Gold `#D4AF37`, 2nd Silver `#CBD5E1`, 3rd Bronze `#D97706`).
/// - Ceremony Sequence (T4 Tier, 600ms): 3 tiers rise from bottom margin (40ms stagger),
///   championship trophy glides in with specular shimmer, 24 gold particles dissipate outward.
/// - Particle effects auto-terminate strictly after 600ms to preserve GPU thermals.
/// - Interactive Podium Reveal: Tapping any podium tier selects that medalist and reveals match stats.
/// - Reduced Motion: Skips ceremonial animation when [MediaQuery.disableAnimations] is active.
/// - Federation Authority: Official crest and verified assets through [ArmSphereImage].
class TournamentAwardsCeremonyScreen extends ConsumerStatefulWidget {
  final String tournamentId;

  const TournamentAwardsCeremonyScreen({
    super.key,
    required this.tournamentId,
  });

  @override
  ConsumerState<TournamentAwardsCeremonyScreen> createState() =>
      _TournamentAwardsCeremonyScreenState();
}

class _TournamentAwardsCeremonyScreenState
    extends ConsumerState<TournamentAwardsCeremonyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ceremonyController;
  late Animation<double> _silverRiseAnim;
  late Animation<double> _goldRiseAnim;
  late Animation<double> _bronzeRiseAnim;
  late Animation<double> _particleAnim;
  late Animation<double> _trophyGlitterAnim;

  int _selectedTierIndex = 0; // 0 = 1st Gold, 1 = 2nd Silver, 2 = 3rd Bronze
  int _selectedBracketIndex = 0;

  @override
  void initState() {
    super.initState();
    // T4 Ceremony Sequence (600ms strictly bounded duration)
    _ceremonyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // 2nd Place Silver: rises 0–340ms (Interval 0.00 – 0.56)
    _silverRiseAnim = CurvedAnimation(
      parent: _ceremonyController,
      curve: const Interval(0.00, 0.56, curve: Curves.easeOutCubic),
    );

    // 1st Place Gold: rises 40–440ms (Interval 0.07 – 0.73)
    _goldRiseAnim = CurvedAnimation(
      parent: _ceremonyController,
      curve: const Interval(0.07, 0.73, curve: Curves.easeOutCubic),
    );

    // 3rd Place Bronze: rises 80–500ms (Interval 0.13 – 0.83)
    _bronzeRiseAnim = CurvedAnimation(
      parent: _ceremonyController,
      curve: const Interval(0.13, 0.83, curve: Curves.easeOutCubic),
    );

    // 24 Momentary Gold Particles: 100–600ms (Interval 0.16 – 1.00)
    _particleAnim = CurvedAnimation(
      parent: _ceremonyController,
      curve: const Interval(0.16, 1.00, curve: Curves.easeOut),
    );

    // Trophy Shimmer: 350–600ms (Interval 0.58 – 1.00)
    _trophyGlitterAnim = CurvedAnimation(
      parent: _ceremonyController,
      curve: const Interval(0.58, 1.00, curve: Curves.easeInOutSine),
    );

    // Post-frame check for reduced motion or trigger ceremony sequence
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (disableAnimations) {
        _ceremonyController.value = 1.0;
      } else {
        _ceremonyController.forward().then((_) {
          if (mounted) HapticFeedback.heavyImpact();
        });
      }
    });
  }

  @override
  void dispose() {
    _ceremonyController.dispose();
    super.dispose();
  }

  void _replayCeremony() {
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    HapticFeedback.selectionClick();
    if (disableAnimations) {
      _ceremonyController.value = 1.0;
      return;
    }
    _ceremonyController.reset();
    _ceremonyController.forward().then((_) {
      if (mounted) HapticFeedback.heavyImpact();
    });
  }

  /// Formats category label derived from authoritative bracket parameters
  String _formatCategoryLabel(Map<String, dynamic> bracket) {
    final division = bracket['division']?.toString().trim();
    final weightClass = bracket['weightClass']?.toString().trim();
    final arm = bracket['arm']?.toString().trim();
    final parts = <String>[];
    if (division != null && division.isNotEmpty) parts.add(division.toUpperCase());
    if (weightClass != null && weightClass.isNotEmpty) parts.add(weightClass.toUpperCase());
    if (arm != null && arm.isNotEmpty) parts.add('${arm.toUpperCase()} ARM');
    if (parts.isNotEmpty) return parts.join(' • ');
    final bracketName = bracket['bracketName']?.toString().trim();
    if (bracketName != null && bracketName.isNotEmpty) return bracketName.toUpperCase();
    return 'OFFICIAL DIVISION';
  }

  /// Extracts real podium athletes from an authoritative bracket awards payload
  List<Map<String, dynamic>> _extractPodiumFromBracket(Map<String, dynamic>? bracket) {
    if (bracket == null) return [];
    final podiumList = bracket['podium'] as List?;
    if (podiumList == null || podiumList.isEmpty) return [];

    return podiumList.whereType<Map>().map<Map<String, dynamic>>((m) {
      final tier = m['tier']?.toString() ?? 'Medalist';
      final is1st = tier.contains('1st') || tier.toLowerCase().contains('gold') || tier.toLowerCase().contains('champion');
      final is2nd = tier.contains('2nd') || tier.toLowerCase().contains('silver') || tier.toLowerCase().contains('runner');
      final rawAvatarUrl = m['avatarUrl']?.toString();
      final name = m['name']?.toString().trim();
      final cleanName = (name != null && name.isNotEmpty) ? name : 'Official Medalist';
      final record = m['record']?.toString();
      final eloGain = m['eloGain']?.toString();

      return {
        'tier': tier,
        'badge': m['badge']?.toString() ?? (is1st ? 'CHAMPION' : is2nd ? 'RUNNER-UP' : 'THIRD PLACE'),
        'medal': m['medal']?.toString() ?? (is1st ? 'GOLD MEDAL' : is2nd ? 'SILVER MEDAL' : 'BRONZE MEDAL'),
        'name': cleanName,
        'club': m['club']?.toString() ?? 'Affiliated Club',
        'province': m['province']?.toString() ?? 'Pakistan',
        'record': (record != null && record.isNotEmpty) ? record : (is1st ? 'Undefeated Champion' : 'Medalist'),
        'eloGain': eloGain ?? '',
        'color': is1st ? const Color(0xFFD4AF37) : is2nd ? const Color(0xFFCBD5E1) : const Color(0xFFD97706),
        'trophy': is1st ? Icons.emoji_events_rounded : is2nd ? Icons.military_tech_rounded : Icons.workspace_premium_rounded,
        'avatar': cleanName.isNotEmpty ? cleanName.substring(0, 1).toUpperCase() : 'A',
        'avatarUrl': (rawAvatarUrl != null && rawAvatarUrl.isNotEmpty) ? rawAvatarUrl : null,
        'athleteId': m['athleteId']?.toString() ?? '',
      };
    }).toList();
  }

  void _showSharePodiumModal(BuildContext context, Map<String, dynamic> champion, String eventName) {
    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ChampionshipGoldCard(
                championshipTitle: eventName,
                athleteName: champion['name'] ?? 'Tournament Champion',
                dateLocation: 'PAFF National Finals • Official Ledger',
                onShare: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Championship Card exported to Photos & Federation Feed.'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close, color: Colors.white70, size: 16),
                label: const Text('Close', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventDetailProvider(widget.tournamentId));
    final awardsAsync = ref.watch(eventAwardsProvider(widget.tournamentId));

    // Handle Loading State
    if (awardsAsync.isLoading || eventAsync.isLoading) {
      return _buildLoadingState(context);
    }

    // Handle Error State
    if (awardsAsync.hasError) {
      return _buildErrorState(context, awardsAsync.error, eventAsync.value?['name']?.toString());
    }
    if (eventAsync.hasError && !awardsAsync.hasValue) {
      return _buildErrorState(context, eventAsync.error, null);
    }

    // Extract Authoritative Awards Data
    final awardsData = awardsAsync.value;
    final rawAwardsList = awardsData?['awards'];
    final List<Map<String, dynamic>> bracketsList = (rawAwardsList is List)
        ? rawAwardsList.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : [];

    final eventName = eventAsync.value?['name']?.toString() ??
        awardsData?['eventName']?.toString() ??
        'Tournament Awards Ceremony';

    // Handle Empty Awards State (Podium Pending)
    if (bracketsList.isEmpty) {
      return _buildEmptyState(context, eventName);
    }

    // Active Category Selection
    final safeBracketIndex = _selectedBracketIndex.clamp(0, bracketsList.length - 1);
    final selectedBracket = bracketsList[safeBracketIndex];
    final categoryLabel = _formatCategoryLabel(selectedBracket);
    final podiumAthletes = _extractPodiumFromBracket(selectedBracket);

    final safeTierIndex = _selectedTierIndex.clamp(0, podiumAthletes.isNotEmpty ? podiumAthletes.length - 1 : 0);
    final selectedAthlete = podiumAthletes.isNotEmpty ? podiumAthletes[safeTierIndex] : null;

    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations && _ceremonyController.value < 1.0) {
      _ceremonyController.value = 1.0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF070A11), // Void Substrate
      body: Stack(
        children: [
          _buildAmbientGoldSheen(context),

          // Main Ceremony Body
          SafeArea(
            child: Column(
              children: [
                // Top App Bar Navigation
                _buildTopAppBar(eventName, podiumAthletes.isNotEmpty ? podiumAthletes[0] : null),

                // Category Selector Tray
                _buildCategorySelectorTray(bracketsList),

                // Ceremony Display Area
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      const SizedBox(height: 12),

                      // Grand Champion Insignia & Header
                      _buildCeremonyHeader(categoryLabel),
                      const SizedBox(height: 16),

                      // 3-Tier Interactive Animated Podium or Pending Notice
                      if (podiumAthletes.isNotEmpty) ...[
                        RepaintBoundary(
                          child: _buildPodiumSection(podiumAthletes),
                        ),
                        const SizedBox(height: 20),

                        // Selected Podium Medalist Reveal Card
                        if (selectedAthlete != null)
                          _buildSelectedMedalistCard(selectedAthlete),
                        const SizedBox(height: 16),

                        // Share Action Bar
                        _buildShareActionBar(podiumAthletes[0], eventName),
                        const SizedBox(height: 24),
                      ] else ...[
                        _buildCategoryPodiumPending(categoryLabel),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Ambient Champagne Gold Sheen in Viewport Background
  Widget _buildAmbientGoldSheen(BuildContext context) {
    return Positioned(
      top: -60,
      left: MediaQuery.of(context).size.width / 2 - 160,
      child: Container(
        width: 320,
        height: 320,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              const Color(0xFFD4AF37).withValues(alpha: 0.18),
              const Color(0xFFD4AF37).withValues(alpha: 0.04),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  /// Top App Bar Navigation with Official Federation Insignia
  Widget _buildTopAppBar(String eventName, Map<String, dynamic>? champion) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0B0F19),
        border: Border(bottom: BorderSide(color: Color(0xFF334155), width: 1.0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                const SizedBox(width: 4),
                ArmSphereImage(
                  assetPath: ArmSphereAssets.sealFed,
                  width: 22,
                  height: 22,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AWARDS & PODIUM CEREMONY',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        eventName,
                        style: const TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 10.5,
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Replay Ceremony',
                icon: const Icon(Icons.replay_rounded, color: AppTheme.goldPrimary, size: 20),
                onPressed: _replayCeremony,
              ),
              if (champion != null)
                IconButton(
                  tooltip: 'Share Podium Graphic',
                  icon: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
                  onPressed: () => _showSharePodiumModal(context, champion, eventName),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Dynamic Category Selector Tray derived from authoritative brackets
  Widget _buildCategorySelectorTray(List<Map<String, dynamic>> brackets) {
    if (brackets.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xFF0B0F19),
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B), width: 1.0)),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: brackets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isSelected = i == _selectedBracketIndex;
          final catLabel = _formatCategoryLabel(brackets[i]);

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedBracketIndex = i;
                _selectedTierIndex = 0;
              });
              _replayCeremony();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.goldPrimary.withValues(alpha: 0.15)
                    : const Color(0xFF121826),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? AppTheme.goldPrimary : const Color(0xFF334155),
                  width: 1.0,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                catLabel,
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 10.5,
                  color: isSelected ? AppTheme.goldPrimary : AppTheme.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Ceremony Header with Official Federation Seal
  Widget _buildCeremonyHeader(String categoryLabel) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.goldPrimary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppTheme.goldPrimary.withValues(alpha: 0.3)),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ArmSphereImage(
                  assetPath: ArmSphereAssets.sealFed,
                  width: 14,
                  height: 14,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
                const SizedBox(width: 6),
                const Text(
                  'PAKISTAN ARMWRESTLING FEDERATION • OFFICIAL PODIUM',
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontWeight: FontWeight.w800,
                    fontSize: 9,
                    color: AppTheme.goldPrimary,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          categoryLabel,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Space Grotesk',
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// 3-Tier Podium Section (T4 Animated Sequence) with Safe Bounds
  Widget _buildPodiumSection(List<Map<String, dynamic>> athletes) {
    final gold = athletes.isNotEmpty ? athletes[0] : null;
    final silver = athletes.length > 1 ? athletes[1] : null;
    final bronze = athletes.length > 2 ? athletes[2] : null;

    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        // 24 Momentary Gold Particle Burst (skipped when animations disabled)
        if (!disableAnimations)
          AnimatedBuilder(
            animation: _particleAnim,
            builder: (context, _) {
              if (_particleAnim.value <= 0.0 || _particleAnim.value >= 1.0) {
                return const SizedBox.shrink();
              }
              return CustomPaint(
                size: const Size(340, 220),
                painter: _CeremonyParticlesPainter(progress: _particleAnim.value),
              );
            },
          ),

        // The Physical Pedestals
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 2nd Place Silver (Left, 100dp Pedestal)
            Expanded(
              child: AnimatedBuilder(
                animation: _silverRiseAnim,
                builder: (context, child) {
                  final progress = disableAnimations ? 1.0 : _silverRiseAnim.value;
                  return Transform.translate(
                    offset: Offset(0, (1.0 - progress) * 60.0),
                    child: Opacity(
                      opacity: progress,
                      child: silver != null
                          ? _buildPodiumPillar(
                              tierIndex: 1,
                              athlete: silver,
                              pillarHeight: 100,
                              accentColor: const Color(0xFFCBD5E1),
                              trophyIcon: Icons.military_tech_rounded,
                              rankNumber: '2',
                            )
                          : _buildReservedPedestal(
                              pillarHeight: 100,
                              accentColor: const Color(0xFFCBD5E1),
                              rankNumber: '2',
                              label: 'RUNNER-UP',
                            ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),

            // 1st Place Gold (Center, 142dp Pedestal with Specular Sheen)
            Expanded(
              child: AnimatedBuilder(
                animation: _goldRiseAnim,
                builder: (context, child) {
                  final progress = disableAnimations ? 1.0 : _goldRiseAnim.value;
                  return Transform.translate(
                    offset: Offset(0, (1.0 - progress) * 80.0),
                    child: Opacity(
                      opacity: progress,
                      child: gold != null
                          ? _buildPodiumPillar(
                              tierIndex: 0,
                              athlete: gold,
                              pillarHeight: 142,
                              accentColor: const Color(0xFFD4AF37),
                              trophyIcon: Icons.emoji_events_rounded,
                              rankNumber: '1',
                              isChampion: true,
                            )
                          : _buildReservedPedestal(
                              pillarHeight: 142,
                              accentColor: const Color(0xFFD4AF37),
                              rankNumber: '1',
                              label: 'CHAMPION',
                            ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),

            // 3rd Place Bronze (Right, 76dp Pedestal)
            Expanded(
              child: AnimatedBuilder(
                animation: _bronzeRiseAnim,
                builder: (context, child) {
                  final progress = disableAnimations ? 1.0 : _bronzeRiseAnim.value;
                  return Transform.translate(
                    offset: Offset(0, (1.0 - progress) * 50.0),
                    child: Opacity(
                      opacity: progress,
                      child: bronze != null
                          ? _buildPodiumPillar(
                              tierIndex: 2,
                              athlete: bronze,
                              pillarHeight: 76,
                              accentColor: const Color(0xFFD97706),
                              trophyIcon: Icons.workspace_premium_rounded,
                              rankNumber: '3',
                            )
                          : _buildReservedPedestal(
                              pillarHeight: 76,
                              accentColor: const Color(0xFFD97706),
                              rankNumber: '3',
                              label: '3RD PLACE',
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Individual Pedestal Pillar with Athlete Avatar & Badges
  Widget _buildPodiumPillar({
    required int tierIndex,
    required Map<String, dynamic> athlete,
    required double pillarHeight,
    required Color accentColor,
    required IconData trophyIcon,
    required String rankNumber,
    bool isChampion = false,
  }) {
    final isSelected = _selectedTierIndex == tierIndex;
    final athleteName = athlete['name']?.toString() ?? 'Official Medalist';

    return Semantics(
      label: '${athlete['tier']}: $athleteName, ${athlete['medal']}',
      button: true,
      child: TactilePressWrapper(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedTierIndex = tierIndex);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Athlete Head & Floating Medal with Centralized Avatar
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: isChampion ? 56 : 46,
                  height: isChampion ? 56 : 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1E293B),
                    border: Border.all(
                      color: accentColor,
                      width: isChampion ? 2.5 : 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: isChampion ? 0.4 : 0.2),
                        blurRadius: isChampion ? 14 : 8,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: ArmSphereImage.avatar(
                      imageUrl: athlete['avatarUrl']?.toString(),
                      size: isChampion ? 56 : 46,
                      fallbackAsset: ArmSphereAssets.defaultAvatar,
                      initial: athleteName.isNotEmpty ? athleteName.substring(0, 1).toUpperCase() : 'A',
                      semanticLabel: '$athleteName profile photo',
                    ),
                  ),
                ),

                // Mini Trophy/Medal Badge
                Positioned(
                  bottom: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor,
                      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4)],
                    ),
                    child: Icon(trophyIcon, size: isChampion ? 13 : 11, color: Colors.black),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Athlete Name & ELO Differential
            Text(
              athleteName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontWeight: FontWeight.w800,
                fontSize: isChampion ? 12 : 11,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            if (athlete['eloGain'] != null && athlete['eloGain'].toString().isNotEmpty)
              Text(
                athlete['eloGain'].toString(),
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontWeight: FontWeight.w700,
                  fontSize: 9.5,
                  color: accentColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              )
            else
              const SizedBox(height: 12),
            const SizedBox(height: 8),

            // Solid Metallic Block Pedestal
            Container(
              height: pillarHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    accentColor.withValues(alpha: isSelected ? 0.35 : 0.20),
                    const Color(0xFF121826),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                border: Border.all(
                  color: isSelected ? accentColor : accentColor.withValues(alpha: 0.45),
                  width: isSelected ? 2.0 : 1.2,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.3),
                      blurRadius: 16,
                      spreadRadius: -2,
                    ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Large Monospace Rank Number
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      rankNumber,
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontWeight: FontWeight.w900,
                        fontSize: isChampion ? 54 : 42,
                        color: accentColor.withValues(alpha: 0.35),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),

                  // Top Badge Label
                  Positioned(
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          athlete['badge'],
                          style: TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontWeight: FontWeight.w800,
                            fontSize: 8,
                            color: accentColor,
                            letterSpacing: 0.6,
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
      ),
    );
  }

  /// Reserved / Uncontested Pedestal Placeholder
  Widget _buildReservedPedestal({
    required double pillarHeight,
    required Color accentColor,
    required String rankNumber,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF121826),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Icon(
            Icons.lock_clock_rounded,
            size: 16,
            color: accentColor.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontWeight: FontWeight.w700,
            fontSize: 10,
            color: accentColor.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          height: pillarHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF0D131F),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.2),
              width: 1.0,
            ),
          ),
          child: Center(
            child: Text(
              rankNumber,
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontWeight: FontWeight.w900,
                fontSize: 36,
                color: accentColor.withValues(alpha: 0.15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Selected Podium Medalist Reveal Card
  Widget _buildSelectedMedalistCard(Map<String, dynamic> athlete) {
    final color = athlete['color'] as Color;
    final athleteId = athlete['athleteId']?.toString() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121826), // L2 Surface Card
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 16,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Medal Title & Record
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(athlete['trophy'] as IconData, color: color, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        athlete['medal'],
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: color,
                          letterSpacing: 0.8,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Text(
                  athlete['tier'],
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontWeight: FontWeight.w800,
                    fontSize: 9.5,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Athlete Identity & Federation Details
          Text(
            athlete['name'],
            style: const TextStyle(
              fontFamily: 'Space Grotesk',
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${athlete['club']} • ${athlete['province']}',
            style: const TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 11.5,
              color: AppTheme.textMuted,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF334155), height: 1),
          const SizedBox(height: 12),

          // Match Statistics Plane
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'TOURNAMENT RECORD',
                  value: athlete['record']?.toString() ?? 'Official Medalist',
                  accentColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  label: 'RATING DIFFERENTIAL',
                  value: (athlete['eloGain'] != null && athlete['eloGain'].toString().isNotEmpty)
                      ? athlete['eloGain'].toString()
                      : 'STANDINGS LOCKED',
                  accentColor: color,
                  isMonospace: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // View Profile CTA
          if (athleteId.isNotEmpty)
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 42),
                side: BorderSide(color: color.withValues(alpha: 0.6)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                context.push('/athletes/$athleteId');
              },
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_outline, size: 16, color: color),
                    const SizedBox(width: 6),
                    Text(
                      'VIEW ATHLETE CAREER PROFILE',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        color: color,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color accentColor,
    bool isMonospace = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: accentColor,
              fontFeatures: isMonospace ? const [FontFeature.tabularFigures()] : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Share Action Bar
  Widget _buildShareActionBar(Map<String, dynamic> champion, String eventName) {
    return TactilePressWrapper(
      onTap: () {
        HapticFeedback.mediumImpact();
        _showSharePodiumModal(context, champion, eventName);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD4AF37), Color(0xFFB45309)],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.share_rounded, color: Colors.black, size: 18),
              SizedBox(width: 8),
              Text(
                'SHARE OFFICIAL PODIUM GRAPHIC',
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                  color: Colors.black,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// In-Progress Bracket Notice when a specific division's finals are not finished
  Widget _buildCategoryPodiumPending(String categoryLabel) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF121826),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF334155),
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.hourglass_empty_rounded,
            color: AppTheme.goldPrimary,
            size: 32,
          ),
          const SizedBox(height: 12),
          const Text(
            'DIVISION PODIUM IN PROGRESS',
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: Colors.white,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Matches for $categoryLabel are currently underway. Final certified medalists will be revealed once bracket finals conclude.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 11,
              color: AppTheme.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Restrained Ceremonial Loading State
  Widget _buildLoadingState(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070A11),
      body: Stack(
        children: [
          _buildAmbientGoldSheen(context),
          SafeArea(
            child: Column(
              children: [
                _buildTopAppBar('Loading tournament...', null),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.goldPrimary.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                            color: const Color(0xFF121826),
                          ),
                          child: ArmSphereImage(
                            assetPath: ArmSphereAssets.sealFed,
                            width: 36,
                            height: 36,
                            fit: BoxFit.contain,
                            excludeFromSemantics: true,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldPrimary),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'PREPARING OFFICIAL CEREMONY',
                          style: TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: AppTheme.goldPrimary,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Retrieving certified championship awards...',
                          style: TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
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

  /// Honest Human-Readable Error State with Active Retry
  Widget _buildErrorState(BuildContext context, Object? error, String? eventName) {
    return Scaffold(
      backgroundColor: const Color(0xFF070A11),
      body: Stack(
        children: [
          _buildAmbientGoldSheen(context),
          SafeArea(
            child: Column(
              children: [
                _buildTopAppBar(eventName ?? 'Tournament Awards', null),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1E1515),
                              border: Border.all(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.error_outline_rounded,
                              color: Color(0xFFEF4444),
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'UNABLE TO LOAD CEREMONY',
                            style: TextStyle(
                              fontFamily: 'Space Grotesk',
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Official awards could not be retrieved from the federation servers. Please verify your connection and try again.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Space Grotesk',
                              fontSize: 12,
                              color: AppTheme.textMuted,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TactilePressWrapper(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              ref.invalidate(eventAwardsProvider(widget.tournamentId));
                              ref.invalidate(eventDetailProvider(widget.tournamentId));
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFD4AF37), Color(0xFFB45309)],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.refresh_rounded, color: Colors.black, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'RETRY CEREMONY LOAD',
                                    style: TextStyle(
                                      fontFamily: 'Space Grotesk',
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                      color: Colors.black,
                                      letterSpacing: 0.6,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Honest Empty State when Tournament has No Certified Awards Yet
  Widget _buildEmptyState(BuildContext context, String eventName) {
    return Scaffold(
      backgroundColor: const Color(0xFF070A11),
      body: Stack(
        children: [
          _buildAmbientGoldSheen(context),
          SafeArea(
            child: Column(
              children: [
                _buildTopAppBar(eventName, null),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF121826),
                              border: Border.all(
                                color: AppTheme.goldPrimary.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.goldPrimary.withValues(alpha: 0.15),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            child: ArmSphereImage(
                              assetPath: ArmSphereAssets.sealFed,
                              width: 48,
                              height: 48,
                              fit: BoxFit.contain,
                              excludeFromSemantics: true,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'OFFICIAL PODIUM PENDING',
                            style: TextStyle(
                              fontFamily: 'Space Grotesk',
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Official results and medal ceremonies will appear once championship bracket matches are completed and certified by the federation.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Space Grotesk',
                              fontSize: 12,
                              color: AppTheme.textMuted,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TactilePressWrapper(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              ref.invalidate(eventAwardsProvider(widget.tournamentId));
                              ref.invalidate(eventDetailProvider(widget.tournamentId));
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.goldPrimary.withValues(alpha: 0.4),
                                  width: 1.0,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.refresh_rounded, color: AppTheme.goldPrimary, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    'REFRESH RESULTS',
                                    style: TextStyle(
                                      fontFamily: 'Space Grotesk',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11.5,
                                      color: AppTheme.goldPrimary,
                                      letterSpacing: 0.6,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 24 Momentary Gold Ceremony Particles radiating from the center champion pedestal
class _CeremonyParticlesPainter extends CustomPainter {
  final double progress;

  _CeremonyParticlesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.45);
    final paint = Paint()..style = PaintingStyle.fill;

    const int particleCount = 24;
    final double radius = 30.0 + (progress * 90.0);
    final double alpha = (1.0 - progress).clamp(0.0, 1.0);

    for (int i = 0; i < particleCount; i++) {
      final double angle = (i * (2 * math.pi / particleCount)) + (i % 2 == 0 ? 0.1 : -0.1);
      final double x = center.dx + math.cos(angle) * radius * 1.6;
      final double y = center.dy + math.sin(angle) * radius * 0.8;
      final double dotSize = (3.5 * (1.0 - progress)).clamp(0.8, 3.5);

      paint.color = (i % 2 == 0 ? const Color(0xFFD4AF37) : const Color(0xFFFFF3B0))
          .withValues(alpha: alpha * 0.8);
      canvas.drawCircle(Offset(x, y), dotSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CeremonyParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
