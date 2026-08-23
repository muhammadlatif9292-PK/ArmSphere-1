import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'count_up_text.dart';

/// Data model representing a single statistic item
class StatItemData {
  final String title;
  final num value;
  final String? prefix;
  final String? suffix;
  final String? deltaText;
  final bool isPositiveDelta;
  final IconData icon;
  final Color accentColor;

  const StatItemData({
    required this.title,
    required this.value,
    this.prefix,
    this.suffix,
    this.deltaText,
    this.isPositiveDelta = true,
    required this.icon,
    this.accentColor = AppTheme.goldPrimary,
  });
}

/// Individual luxury floating glass card for a single stat metric
class GlassStatCard extends StatefulWidget {
  final StatItemData data;
  final Duration animationDelay;
  final VoidCallback? onTap;

  const GlassStatCard({
    Key? key,
    required this.data,
    this.animationDelay = Duration.zero,
    this.onTap,
  }) : super(key: key);

  @override
  State<GlassStatCard> createState() => _GlassStatCardState();
}

class _GlassStatCardState extends State<GlassStatCard> with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _floatController;
  late AnimationController _pressController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scalePressAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Staggered entry animation controller
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );

    // 2. Continuous subtle floating animation
    _floatController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2500 + (widget.animationDelay.inMilliseconds % 800)),
    )..repeat(reverse: true);

    // 3. Tactile press controller
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );

    _scalePressAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic),
    );

    // Trigger staggered entry after delay
    Future.delayed(widget.animationDelay, () {
      if (mounted) {
        _entryController.forward();
      }
    });
  }

  @override
  void didUpdateWidget(covariant GlassStatCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.value != widget.data.value) {
      _entryController.reset();
      _entryController.forward();
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _floatController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    HapticFeedback.selectionClick();
    _pressController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _pressController.reverse();
    if (widget.onTap != null) widget.onTap!();
  }

  void _onTapCancel() {
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: AnimatedBuilder(
          animation: Listenable.merge([_floatController, _pressController]),
          builder: (context, child) {
            final floatY = math.sin(_floatController.value * math.pi * 2) * 2.5;
            final pressScale = _scalePressAnimation.value;

            return Transform.translate(
              offset: Offset(0, floatY),
              child: Transform.scale(
                scale: pressScale,
                child: child,
              ),
            );
          },
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.45),
                    blurRadius: 16.0,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: d.accentColor.withOpacity(0.18),
                    blurRadius: 20.0,
                    spreadRadius: -2.0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      color: const Color(0xEE121622), // Premium Onyx glass
                      borderRadius: BorderRadius.circular(18.0),
                      border: Border.all(
                        color: d.accentColor.withOpacity(0.35),
                        width: 1.1,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          d.accentColor.withOpacity(0.15),
                          const Color(0xEE121622),
                          const Color(0xEE0B0D14),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top Header: Title & Micro-Icon Glow Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                d.title.toUpperCase(),
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                  color: AppTheme.textSecondary.withOpacity(0.9),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Micro Tinted Icon Badge with Soft Glow
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: d.accentColor.withOpacity(0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: d.accentColor.withOpacity(0.4),
                                  width: 0.9,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: d.accentColor.withOpacity(0.25),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Icon(
                                d.icon,
                                size: 14,
                                color: d.accentColor,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Bottom Row: Large Upward Count-Up Animated Value & Delta Badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: CountUpText(
                                  key: ValueKey('${d.title}_${d.value}'),
                                  value: d.value,
                                  prefix: d.prefix,
                                  suffix: d.suffix,
                                  duration: const Duration(milliseconds: 650),
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.textPrimary,
                                    height: 1.0,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                            ),

                            if (d.deltaText != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (d.isPositiveDelta ? AppTheme.success : AppTheme.error).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: (d.isPositiveDelta ? AppTheme.success : AppTheme.error).withOpacity(0.4),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      d.isPositiveDelta ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                                      size: 13,
                                      color: d.isPositiveDelta ? AppTheme.success : AppTheme.error,
                                    ),
                                    Text(
                                      d.deltaText!,
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: d.isPositiveDelta ? AppTheme.success : AppTheme.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full Statistics Overview Section Component with 6 Premium Floating Cards
class StatsOverviewSection extends StatefulWidget {
  final Map<String, dynamic>? profileData;
  final String currentPeriod;
  final ValueChanged<String>? onPeriodChanged;

  const StatsOverviewSection({
    Key? key,
    this.profileData,
    this.currentPeriod = 'This Season',
    this.onPeriodChanged,
  }) : super(key: key);

  @override
  State<StatsOverviewSection> createState() => _StatsOverviewSectionState();
}

class _StatsOverviewSectionState extends State<StatsOverviewSection> {
  @override
  Widget build(BuildContext context) {
    final p = widget.profileData ?? {};

    // Extract values with exact fallbacks matching user requirements
    final winsVal = num.tryParse(p['wins']?.toString() ?? '42') ?? 42;
    final lossesVal = num.tryParse(p['losses']?.toString() ?? '11') ?? 11;
    final winRateVal = num.tryParse(p['winRate']?.toString().replaceAll('%', '') ?? '79') ?? 79;
    final eloVal = num.tryParse(p['elo']?.toString() ?? p['currentElo']?.toString() ?? '2016') ?? 2016;
    final pkRankVal = num.tryParse(p['pakistanRank']?.toString().replaceAll('#', '') ?? '3') ?? 3;
    final worldRankVal = num.tryParse(p['worldRank']?.toString().replaceAll('#', '') ?? '23') ?? 23;

    final statsList = [
      StatItemData(
        title: 'Wins',
        value: winsVal,
        deltaText: '+3',
        isPositiveDelta: true,
        icon: Icons.check_circle_outline_rounded,
        accentColor: AppTheme.success,
      ),
      StatItemData(
        title: 'Losses',
        value: lossesVal,
        icon: Icons.highlight_off_rounded,
        accentColor: const Color(0xFF94A3B8),
      ),
      StatItemData(
        title: 'Win %',
        value: winRateVal,
        suffix: '%',
        deltaText: '2.4%',
        isPositiveDelta: true,
        icon: Icons.pie_chart_outline_rounded,
        accentColor: AppTheme.goldPrimary,
      ),
      StatItemData(
        title: 'Current ELO',
        value: eloVal,
        deltaText: '+28',
        isPositiveDelta: true,
        icon: Icons.trending_up_rounded,
        accentColor: const Color(0xFF38BDF8),
      ),
      StatItemData(
        title: 'Pakistan Rank',
        value: pkRankVal,
        prefix: '#',
        deltaText: 'TOP 3',
        isPositiveDelta: true,
        icon: Icons.flag_outlined,
        accentColor: const Color(0xFFA7F3D0),
      ),
      StatItemData(
        title: 'World Rank',
        value: worldRankVal,
        prefix: '#',
        deltaText: 'TOP 25',
        isPositiveDelta: true,
        icon: Icons.public_rounded,
        accentColor: const Color(0xFFF59E0B),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 3.5,
                  height: 15,
                  decoration: BoxDecoration(
                    color: AppTheme.goldPrimary,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.goldPrimary.withOpacity(0.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'PREMIUM STATISTICS',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),

            // Timeframe Filter Pill
            PopupMenuButton<String>(
              initialValue: widget.currentPeriod,
              onSelected: (val) {
                if (widget.onPeriodChanged != null) {
                  widget.onPeriodChanged!(val);
                }
              },
              color: const Color(0xFF161A26),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3)),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.goldPrimary.withOpacity(0.3),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.currentPeriod,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontBody,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.goldLight,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 15,
                      color: AppTheme.goldPrimary,
                    ),
                  ],
                ),
              ),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'This Month',
                  child: Text('This Month', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                ),
                const PopupMenuItem(
                  value: 'This Season',
                  child: Text('This Season', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                ),
                const PopupMenuItem(
                  value: 'All Time',
                  child: Text('All Time', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Grid of 6 Luxury Floating Stat Cards (2 columns x 3 rows with smooth spacing)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: statsList.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.85,
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 10.0,
          ),
          itemBuilder: (context, index) {
            final statData = statsList[index];
            return GlassStatCard(
              data: statData,
              animationDelay: Duration(milliseconds: 70 * index),
            );
          },
        ),
      ],
    );
  }
}

