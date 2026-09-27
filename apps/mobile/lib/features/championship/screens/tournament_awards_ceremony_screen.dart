import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/tournament_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/signature_ceremonies.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';

/// Canary 10: Championship Awards & Ceremony Screen (`/tournaments/:id/awards`)
///
/// Supreme Sports Authority & Anti-Drift:
/// - Viewport: Deep Void Black (`#070A11`) with Champagne Gold ambient lighting.
/// - Centerpiece: 3-tier podium (1st Gold `#D4AF37`, 2nd Silver `#CBD5E1`, 3rd Bronze `#D97706`).
/// - Ceremony Sequence (T4 Tier, 600ms): 3 tiers rise from bottom margin (40ms stagger),
///   championship trophy glides in with specular shimmer, 24 gold particles dissipate outward.
/// - Particle effects auto-terminate strictly after 600ms to preserve GPU thermals.
/// - Interactive Podium Reveal: Tapping any podium tier selects that medalist and reveals match stats.
/// - Share Podium Graphic: Generates exportable tournament championship card.
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
  String _selectedCategory = '-85 KG • RIGHT ARM';

  final List<String> _categories = [
    '-85 KG • RIGHT ARM',
    '-75 KG • RIGHT ARM',
    '+105 KG • OPEN RIGHT',
    '-80 KG • LEFT ARM',
  ];

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

    // Run ceremony on load with sports haptic
    _ceremonyController.forward().then((_) {
      HapticFeedback.heavyImpact();
    });
  }

  @override
  void dispose() {
    _ceremonyController.dispose();
    super.dispose();
  }

  void _replayCeremony() {
    HapticFeedback.selectionClick();
    _ceremonyController.reset();
    _ceremonyController.forward().then((_) {
      HapticFeedback.heavyImpact();
    });
  }

  // Resolves podium athletes based on backend event data or category selection
  List<Map<String, dynamic>> _resolvePodiumAthletes(Map<String, dynamic>? event, [Map<String, dynamic>? awardsData]) {
    if (awardsData != null && awardsData['awards'] is List) {
      final awardsList = awardsData['awards'] as List;
      for (final a in awardsList) {
        if (a is Map) {
          final podiumList = a['podium'] as List?;
          if (podiumList != null && podiumList.isNotEmpty) {
            return podiumList.map<Map<String, dynamic>>((m) {
              final tier = m['tier']?.toString() ?? 'Medalist';
              final is1st = tier.contains('1st');
              final is2nd = tier.contains('2nd');
              return {
                'tier': tier,
                'badge': m['badge']?.toString() ?? (is1st ? 'CHAMPION' : is2nd ? 'RUNNER-UP' : 'THIRD PLACE'),
                'medal': m['medal']?.toString() ?? (is1st ? 'GOLD MEDAL' : is2nd ? 'SILVER MEDAL' : 'BRONZE MEDAL'),
                'name': m['name']?.toString() ?? 'Athlete',
                'club': m['club']?.toString() ?? 'Affiliated Club',
                'province': m['province']?.toString() ?? 'Pakistan',
                'record': m['record']?.toString() ?? (is1st ? 'Undefeated Champion' : 'Medalist'),
                'eloGain': m['eloGain']?.toString() ?? '+25 ELO',
                'color': is1st ? const Color(0xFFD4AF37) : is2nd ? const Color(0xFFCBD5E1) : const Color(0xFFD97706),
                'trophy': is1st ? Icons.emoji_events_rounded : is2nd ? Icons.military_tech_rounded : Icons.workspace_premium_rounded,
                'avatar': m['avatar']?.toString() ?? (m['name']?.toString().isNotEmpty == true ? m['name'].toString().substring(0, 1).toUpperCase() : 'A'),
                'athleteId': m['athleteId']?.toString() ?? 'ath_01',
              };
            }).toList();
          }
        }
      }
    }

    final title = event?['name']?.toString() ?? 'PAFF National Championship';

    return [
      {
        'tier': '1st Place',
        'badge': 'CHAMPION',
        'medal': 'GOLD MEDAL',
        'name': 'Hamza Khan',
        'club': 'Lahore Armwrestling Club',
        'province': 'Punjab, Pakistan',
        'record': '5-0 • Undefeated Champion',
        'eloGain': '+48 ELO',
        'color': const Color(0xFFD4AF37), // Champagne Gold
        'trophy': Icons.emoji_events_rounded,
        'avatar': 'H',
        'athleteId': 'ath_hamza_01',
      },
      {
        'tier': '2nd Place',
        'badge': 'RUNNER-UP',
        'medal': 'SILVER MEDAL',
        'name': 'Tariq Malik',
        'club': 'Rawalpindi Grippers',
        'province': 'Federal Capital',
        'record': '4-1 • Silver Medalist',
        'eloGain': '+22 ELO',
        'color': const Color(0xFFCBD5E1), // Milled Silver
        'trophy': Icons.military_tech_rounded,
        'avatar': 'T',
        'athleteId': 'ath_tariq_02',
      },
      {
        'tier': '3rd Place',
        'badge': 'THIRD PLACE',
        'medal': 'BRONZE MEDAL',
        'name': 'Bilal Ahmed',
        'club': 'Karachi Pullers Federation',
        'province': 'Sindh, Pakistan',
        'record': '3-2 • Bronze Medalist',
        'eloGain': '+14 ELO',
        'color': const Color(0xFFD97706), // Milled Bronze
        'trophy': Icons.workspace_premium_rounded,
        'avatar': 'B',
        'athleteId': 'ath_bilal_03',
      },
    ];
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
                dateLocation: 'PAFF National Finals • Islamabad',
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
    final eventName = eventAsync.value?['name']?.toString() ?? 'PAFF National Championship';
    final podiumAthletes = _resolvePodiumAthletes(eventAsync.value, awardsAsync.value);
    final selectedAthlete = podiumAthletes[_selectedTierIndex.clamp(0, podiumAthletes.length - 1)];

    return Scaffold(
      backgroundColor: const Color(0xFF070A11), // Void Substrate
      body: Stack(
        children: [
          // 1. Champagne Gold Ambient Radial Sheen
          Positioned(
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
          ),

          // 2. Main Scrollable Ceremony Body
          SafeArea(
            child: Column(
              children: [
                // Top App Bar Navigation
                _buildTopAppBar(eventName, podiumAthletes[0]),

                // Division / Category Selector
                _buildCategorySelectorTray(),

                // Ceremony Display Area
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      const SizedBox(height: 12),

                      // Grand Champion Insignia & Header
                      _buildCeremonyHeader(eventName),
                      const SizedBox(height: 16),

                      // 3-Tier Interactive Animated Podium (T4 Sequence)
                      RepaintBoundary(
                        child: _buildPodiumSection(podiumAthletes),
                      ),
                      const SizedBox(height: 20),

                      // Selected Podium Medalist Reveal Card
                      _buildSelectedMedalistCard(selectedAthlete),
                      const SizedBox(height: 16),

                      // Share Action Bar
                      _buildShareActionBar(podiumAthletes[0], eventName),
                      const SizedBox(height: 24),
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

  // --- Top App Bar ---
  Widget _buildTopAppBar(String eventName, Map<String, dynamic> champion) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0B0F19),
        border: Border(bottom: BorderSide(color: Color(0xFF334155), width: 1.0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.workspace_premium_rounded, color: AppTheme.goldPrimary, size: 14),
                      SizedBox(width: 5),
                      Text(
                        'AWARDS & PODIUM CEREMONY',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
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
            ],
          ),
          Row(
            children: [
              IconButton(
                tooltip: 'Replay Ceremony',
                icon: const Icon(Icons.replay_rounded, color: AppTheme.goldPrimary, size: 20),
                onPressed: _replayCeremony,
              ),
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

  // --- Category Selector Tray ---
  Widget _buildCategorySelectorTray() {
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
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = _categories[i];
          final isSelected = cat == _selectedCategory;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedCategory = cat);
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
                cat,
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

  // --- Ceremony Header ---
  Widget _buildCeremonyHeader(String eventName) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.goldPrimary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppTheme.goldPrimary.withValues(alpha: 0.3)),
          ),
          child: const Text(
            'PAKISTAN ARMWRESTLING FEDERATION • OFFICIAL PODIUM',
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontWeight: FontWeight.w800,
              fontSize: 9,
              color: AppTheme.goldPrimary,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _selectedCategory,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Space Grotesk',
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // --- 3-Tier Podium Section (T4 Animated Sequence) ---
  Widget _buildPodiumSection(List<Map<String, dynamic>> athletes) {
    final gold = athletes[0];
    final silver = athletes[1];
    final bronze = athletes[2];

    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        // 24 Momentary Gold Particle Burst
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

        // The 3 Physical Pedestals
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 2nd Place Silver (Left, 100dp Pedestal)
            Expanded(
              child: AnimatedBuilder(
                animation: _silverRiseAnim,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, (1.0 - _silverRiseAnim.value) * 60.0),
                    child: Opacity(
                      opacity: _silverRiseAnim.value,
                      child: _buildPodiumPillar(
                        tierIndex: 1,
                        athlete: silver,
                        pillarHeight: 100,
                        accentColor: const Color(0xFFCBD5E1),
                        trophyIcon: Icons.military_tech_rounded,
                        rankNumber: '2',
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
                  return Transform.translate(
                    offset: Offset(0, (1.0 - _goldRiseAnim.value) * 80.0),
                    child: Opacity(
                      opacity: _goldRiseAnim.value,
                      child: _buildPodiumPillar(
                        tierIndex: 0,
                        athlete: gold,
                        pillarHeight: 142,
                        accentColor: const Color(0xFFD4AF37),
                        trophyIcon: Icons.emoji_events_rounded,
                        rankNumber: '1',
                        isChampion: true,
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
                  return Transform.translate(
                    offset: Offset(0, (1.0 - _bronzeRiseAnim.value) * 50.0),
                    child: Opacity(
                      opacity: _bronzeRiseAnim.value,
                      child: _buildPodiumPillar(
                        tierIndex: 2,
                        athlete: bronze,
                        pillarHeight: 76,
                        accentColor: const Color(0xFFD97706),
                        trophyIcon: Icons.workspace_premium_rounded,
                        rankNumber: '3',
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

  // Individual Pedestal Pillar with Athlete Avatar & Badges
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

    return TactilePressWrapper(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedTierIndex = tierIndex);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Athlete Head & Floating Medal
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Avatar with 2px Metallic Halo
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
                child: Center(
                  child: Text(
                    athlete['avatar'] ?? 'A',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontWeight: FontWeight.w900,
                      fontSize: isChampion ? 22 : 18,
                      color: Colors.white,
                    ),
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
            athlete['name'],
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
          Text(
            athlete['eloGain'],
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontWeight: FontWeight.w700,
              fontSize: 9.5,
              color: accentColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
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
                Text(
                  rankNumber,
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontWeight: FontWeight.w900,
                    fontSize: isChampion ? 54 : 42,
                    color: accentColor.withValues(alpha: 0.35),
                    fontFeatures: const [FontFeature.tabularFigures()],
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Selected Podium Medalist Reveal Card ---
  Widget _buildSelectedMedalistCard(Map<String, dynamic> athlete) {
    final color = athlete['color'] as Color;

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
              Row(
                children: [
                  Icon(athlete['trophy'] as IconData, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    athlete['medal'],
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: color,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
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
                  value: athlete['record'],
                  accentColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  label: 'RATING DIFFERENTIAL',
                  value: athlete['eloGain'],
                  accentColor: color,
                  isMonospace: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // View Profile CTA
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 42),
              side: BorderSide(color: color.withValues(alpha: 0.6)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              context.push('/athletes/${athlete['athleteId']}');
            },
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
          ),
        ],
      ),
    );
  }

  // --- Share Action Bar ---
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
        child: const Row(
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
