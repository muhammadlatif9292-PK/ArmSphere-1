import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/count_up_text.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';

/// Premium Season XP & League Progress Card with Glowing Edge
class SeasonXpProgressCard extends StatefulWidget {
  final int currentXp;
  final int targetXp;
  final String currentLeague;
  final String nextLeague;
  final String estimatedPromotion;

  const SeasonXpProgressCard({
    Key? key,
    this.currentXp = 14850,
    this.targetXp = 18000,
    this.currentLeague = 'Master Tier I',
    this.nextLeague = 'Grandmaster Division',
    this.estimatedPromotion = '14 Days (3 Matches)',
  }) : super(key: key);

  @override
  State<SeasonXpProgressCard> createState() => _SeasonXpProgressCardState();
}

class _SeasonXpProgressCardState extends State<SeasonXpProgressCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  double get _progress => (widget.currentXp / widget.targetXp).clamp(0.0, 1.0);
  int get _pointsRemaining => (widget.targetXp - widget.currentXp).clamp(0, widget.targetXp);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final glowIntensity = 0.2 + (_pulseController.value * 0.15);

        return TactilePressWrapper(
          onTap: () {
            HapticFeedback.lightImpact();
          },
          enableLift: true,
          liftDistance: -2,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.secondaryAccent.withOpacity(glowIntensity * 0.7),
                  blurRadius: 24,
                  spreadRadius: -2,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.glassSurface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppTheme.secondaryAccent.withOpacity(0.35),
                      width: 1.1,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.secondaryAccent.withOpacity(0.12),
                        AppTheme.surface,
                        AppTheme.background,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: AppTheme.secondaryAccent.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.secondaryAccent.withOpacity(0.6),
                                    width: 1.0,
                                  ),
                                ),
                                child: Icon(
                                  Icons.bolt_rounded,
                                  color: AppTheme.secondaryAccent,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'CURRENT SEASON XP',
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

                          // Season Badge
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.goldPrimary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.goldPrimary.withOpacity(0.4),
                                width: 0.8,
                              ),
                            ),
                            child: const Text(
                              'SEASON 2026',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.goldLight,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Large XP Display Number
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          CountUpText(
                            value: widget.currentXp,
                            suffix: ' XP',
                            duration: const Duration(milliseconds: 900),
                            style: const TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                              shadows: [
                                Shadow(
                                  color: AppTheme.secondaryAccent,
                                  blurRadius: 14,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '/ ${widget.targetXp} XP',
                            style: const TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Animated Progress Bar with Glowing Edge
                      _buildGlowingProgressBar(),

                      const SizedBox(height: 20),

                      const Divider(color: AppTheme.surface, height: 1),

                      const SizedBox(height: 16),

                      // Information Grid: Next League, Points Remaining, Estimated Promotion
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoColumn(
                              icon: Icons.military_tech_outlined,
                              label: 'NEXT LEAGUE',
                              value: widget.nextLeague,
                              valueColor: AppTheme.goldLight,
                            ),
                          ),
                          _buildDivider(),
                          Expanded(
                            child: _buildInfoColumn(
                              icon: Icons.track_changes_rounded,
                              label: 'POINTS REMAINING',
                              value: '$_pointsRemaining XP',
                              valueColor: AppTheme.info,
                            ),
                          ),
                          _buildDivider(),
                          Expanded(
                            child: _buildInfoColumn(
                              icon: Icons.timer_outlined,
                              label: 'EST. PROMOTION',
                              value: widget.estimatedPromotion,
                              valueColor: AppTheme.success,
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

  /// Animated Progress Bar with Glowing Progress Edge
  Widget _buildGlowingProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Background Track
            Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withOpacity(0.06),
                  width: 0.8,
                ),
              ),
            ),

            // Animated Fill Track with Glowing Leading Edge
            LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth;

                return TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(begin: 0.0, end: _progress),
                  builder: (context, value, child) {
                    final currentWidth = maxWidth * value;

                    return Stack(
                      children: [
                        // Gradient Progress Track
                        Container(
                          height: 10,
                          width: currentWidth,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.secondaryAccent,
                                AppTheme.secondaryAccent,
                                AppTheme.warning,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.secondaryAccent.withOpacity(0.6),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),

                        // Glowing Leading Tip Edge Indicator
                        if (currentWidth > 12)
                          Positioned(
                            left: (currentWidth - 8).clamp(0.0, maxWidth - 8),
                            top: -3,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.secondaryAccent,
                                    blurRadius: 12,
                                    spreadRadius: 3,
                                  ),
                                  BoxShadow(
                                    color: Colors.white,
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Bottom Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(_progress * 100).toStringAsFixed(1)}% COMPLETE',
              style: const TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                color: AppTheme.secondaryAccent,
                letterSpacing: 0.6,
              ),
            ),
            Text(
              'Target: ${widget.targetXp} XP',
              style: const TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoColumn({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: AppTheme.textMuted),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.6,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
            color: valueColor,
            letterSpacing: 0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 24,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: AppTheme.surface,
    );
  }
}
