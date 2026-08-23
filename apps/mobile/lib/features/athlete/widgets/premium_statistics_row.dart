import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/count_up_text.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';

/// Premium Athlete Statistics Row Widget with Animated Counters & Glassmorphism
class PremiumStatisticsRow extends StatelessWidget {
  final int followersCount;
  final int followingCount;
  final int profileViewsCount;
  final int reputationScore;
  final double sportsmanshipRating;
  final bool isVerified;

  const PremiumStatisticsRow({
    Key? key,
    this.followersCount = 14280,
    this.followingCount = 385,
    this.profileViewsCount = 98400,
    this.reputationScore = 992,
    this.sportsmanshipRating = 4.95,
    this.isVerified = true,
  }) : super(key: key);

  String _formatK(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
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
                    'ATHLETE METRICS & STATUS',
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
              if (isVerified)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.info.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.info.withOpacity(0.5),
                      width: 0.8,
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_rounded, size: 12, color: AppTheme.info),
                      SizedBox(width: 4),
                      Text(
                        'VERIFIED ATHLETE',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.info,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 2x3 Grid of Premium Statistic Glass Tiles
        Column(
          children: [
            // First Row: Followers, Following, Profile Views
            Row(
              children: [
                Expanded(
                  child: _StatGlassCard(
                    label: 'FOLLOWERS',
                    valueWidget: CountUpText(
                      value: followersCount,
                      formatter: (val) => _formatK(val.round()),
                      duration: const Duration(milliseconds: 900),
                      style: _statValueStyle(AppTheme.info),
                    ),
                    icon: Icons.people_alt_rounded,
                    accentColor: AppTheme.info,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatGlassCard(
                    label: 'FOLLOWING',
                    valueWidget: CountUpText(
                      value: followingCount,
                      duration: const Duration(milliseconds: 900),
                      style: _statValueStyle(AppTheme.textPrimary),
                    ),
                    icon: Icons.person_add_alt_1_rounded,
                    accentColor: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatGlassCard(
                    label: 'PROFILE VIEWS',
                    valueWidget: CountUpText(
                      value: profileViewsCount,
                      formatter: (val) => _formatK(val.round()),
                      duration: const Duration(milliseconds: 900),
                      style: _statValueStyle(AppTheme.goldLight),
                    ),
                    icon: Icons.visibility_rounded,
                    accentColor: AppTheme.goldPrimary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Second Row: Reputation Score, Sportsmanship Rating, Verified Status
            Row(
              children: [
                Expanded(
                  child: _StatGlassCard(
                    label: 'REPUTATION',
                    valueWidget: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CountUpText(
                          value: reputationScore,
                          duration: const Duration(milliseconds: 900),
                          style: _statValueStyle(AppTheme.highlightPurple),
                        ),
                        const SizedBox(width: 2),
                        const Text(
                          '/1000',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    icon: Icons.verified_user_rounded,
                    accentColor: AppTheme.highlightPurple,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatGlassCard(
                    label: 'SPORTSMANSHIP',
                    valueWidget: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          sportsmanshipRating.toStringAsFixed(2),
                          style: _statValueStyle(AppTheme.success),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: AppTheme.success,
                        ),
                      ],
                    ),
                    icon: Icons.handshake_rounded,
                    accentColor: AppTheme.success,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatGlassCard(
                    label: 'VERIFIED STATUS',
                    valueWidget: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isVerified ? Icons.verified_rounded : Icons.pending_rounded,
                          size: 16,
                          color: isVerified ? AppTheme.info : AppTheme.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isVerified ? 'VERIFIED' : 'PENDING',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: isVerified ? AppTheme.info : AppTheme.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    icon: Icons.shield_rounded,
                    accentColor: isVerified ? AppTheme.info : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static TextStyle _statValueStyle(Color color) {
    return TextStyle(
      fontFamily: AppTheme.fontDisplay,
      fontSize: 16,
      fontWeight: FontWeight.w900,
      color: color,
      letterSpacing: -0.3,
    );
  }
}

/// Individual Glass Tile Card
class _StatGlassCard extends StatelessWidget {
  final String label;
  final Widget valueWidget;
  final IconData icon;
  final Color accentColor;

  const _StatGlassCard({
    Key? key,
    required this.label,
    required this.valueWidget,
    required this.icon,
    required this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TactilePressWrapper(
      onTap: () {
        HapticFeedback.selectionClick();
      },
      enableLift: true,
      liftDistance: -2,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: accentColor.withOpacity(0.12),
              blurRadius: 14,
              spreadRadius: -2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.glassSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: accentColor.withOpacity(0.35),
                  width: 1.0,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accentColor.withOpacity(0.14),
                    AppTheme.surface,
                    AppTheme.background,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
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
                      Icon(
                        icon,
                        size: 13,
                        color: accentColor.withOpacity(0.85),
                      ),
                    ],
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: valueWidget,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
