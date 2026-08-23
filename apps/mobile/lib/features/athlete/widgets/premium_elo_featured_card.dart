import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/count_up_text.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';

/// Premium Fintech-Inspired Featured ELO Rating Card
class PremiumEloFeaturedCard extends StatefulWidget {
  final int currentRating;
  final int previousRating;
  final int todaysChange;
  final int weeklyChange;
  final String leagueName;
  final String nextLeagueName;
  final int nextLeagueThreshold;

  const PremiumEloFeaturedCard({
    Key? key,
    this.currentRating = 2016,
    this.previousRating = 1988,
    this.todaysChange = 12,
    this.weeklyChange = 28,
    this.leagueName = 'PRO ELITE LEAGUE • TIER I',
    this.nextLeagueName = 'GRANDMASTER DIVISION',
    this.nextLeagueThreshold = 2200,
  }) : super(key: key);

  @override
  State<PremiumEloFeaturedCard> createState() => _PremiumEloFeaturedCardState();
}

class _PremiumEloFeaturedCardState extends State<PremiumEloFeaturedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  double get _progress {
    final start = widget.previousRating > 1800 ? 1800 : widget.previousRating;
    final totalRange = widget.nextLeagueThreshold - start;
    if (totalRange <= 0) return 1.0;
    final currentProgress = widget.currentRating - start;
    return (currentProgress / totalRange).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final glowAlpha = 0.25 + (_glowController.value * 0.20);
        final glowSpread = 2.0 + (_glowController.value * 4.0);

        return TactilePressWrapper(
          onTap: () {
            HapticFeedback.mediumImpact();
          },
          enableLift: true,
          liftDistance: -3,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.goldPrimary.withOpacity(glowAlpha * 0.8),
                  blurRadius: 28,
                  spreadRadius: glowSpread,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppTheme.info.withOpacity(glowAlpha * 0.4),
                  blurRadius: 32,
                  spreadRadius: -4,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.glassSurface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.goldPrimary.withOpacity(0.45),
                      width: 1.2,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.goldPrimary.withOpacity(0.12),
                        AppTheme.surface,
                        AppTheme.background,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Title & Fintech Trend Arrow Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: AppTheme.goldPrimary.withOpacity(0.18),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.goldPrimary.withOpacity(0.6),
                                    width: 1.0,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.insights_rounded,
                                  color: AppTheme.goldLight,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'CURRENT ELO RATING',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),

                          // Trend Arrow Pill
                          _buildTrendArrowBadge(),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Central Content Row: Large Rating Number + League Emblem
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Large ELO Rating Number
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CountUpText(
                                value: widget.currentRating,
                                duration: const Duration(milliseconds: 800),
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  height: 1.0,
                                  letterSpacing: -1.2,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: AppTheme.goldPrimary,
                                      blurRadius: 18,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.success,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.leagueName,
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.9,
                                      color: AppTheme.goldLight,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // League Emblem Icon with Multi-Layer Glow
                          _buildLeagueEmblem(),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Animated Progress Bar towards Next Division
                      _buildProgressBar(),

                      const SizedBox(height: 18),

                      const Divider(color: AppTheme.surface, height: 1),

                      const SizedBox(height: 16),

                      // Fintech Grid Metrics Row (Current, Previous, Today, Weekly)
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              label: 'CURRENT',
                              value: '${widget.currentRating}',
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          _buildVerticalDivider(),
                          Expanded(
                            child: _buildMetricTile(
                              label: 'PREVIOUS',
                              value: '${widget.previousRating}',
                              color: AppTheme.textMuted,
                            ),
                          ),
                          _buildVerticalDivider(),
                          Expanded(
                            child: _buildMetricTile(
                              label: "TODAY'S",
                              value: '+${widget.todaysChange}',
                              color: AppTheme.success,
                              showPlus: true,
                            ),
                          ),
                          _buildVerticalDivider(),
                          Expanded(
                            child: _buildMetricTile(
                              label: 'WEEKLY',
                              value: '+${widget.weeklyChange}',
                              color: AppTheme.info,
                              showPlus: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Fintech Trend Arrow Badge Pill
  Widget _buildTrendArrowBadge() {
    final isUp = widget.weeklyChange >= 0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (isUp ? AppTheme.success : AppTheme.error).withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isUp ? AppTheme.success : AppTheme.error).withOpacity(0.5),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: (isUp ? AppTheme.success : AppTheme.error).withOpacity(0.25),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 15,
            color: isUp ? AppTheme.success : AppTheme.error,
          ),
          const SizedBox(width: 4),
          Text(
            isUp ? '▲ +${widget.weeklyChange} PTS' : '▼ ${widget.weeklyChange} PTS',
            style: TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: isUp ? AppTheme.success : AppTheme.error,
            ),
          ),
        ],
      ),
    );
  }

  /// League Emblem Widget
  Widget _buildLeagueEmblem() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.goldLight,
            AppTheme.goldPrimary,
            AppTheme.goldDark,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldPrimary.withOpacity(0.5),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: EdgeInsets.all(2.5),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.background,
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Inner Shield Emblem Pattern
            Icon(
              Icons.shield_rounded,
              size: 38,
              color: AppTheme.goldPrimary.withOpacity(0.25),
            ),
            const Icon(
              Icons.military_tech_rounded,
              size: 32,
              color: AppTheme.goldLight,
            ),
          ],
        ),
      ),
    );
  }

  /// Animated Progress Bar towards Next Division
  Widget _buildProgressBar() {
    final progressPct = (_progress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'NEXT DIVISION: ${widget.nextLeagueName}',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppTheme.textMuted,
              ),
            ),
            Text(
              '$progressPct% ($widget.currentRating / $widget.nextLeagueThreshold ELO)',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                color: AppTheme.goldLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            // Background Track
            Container(
              height: 7,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // Animated Fill Track
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(begin: 0.0, end: _progress),
              builder: (context, value, child) {
                return FractionallySizedBox(
                  widthFactor: value,
                  child: Container(
                    height: 7,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.info,
                          AppTheme.goldPrimary,
                          AppTheme.goldLight,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.goldPrimary.withOpacity(0.8),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  /// Metric Tile for Details Row
  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
    bool showPlus = false,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 22,
      width: 1,
      color: AppTheme.surface,
    );
  }
}
