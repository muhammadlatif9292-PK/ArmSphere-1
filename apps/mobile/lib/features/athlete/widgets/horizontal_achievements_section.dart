import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';

/// Achievement Badge Data Model
class AchievementBadge {
  final String title;
  final String category;
  final IconData icon;
  final String? emoji;
  final Color primaryColor;
  final Color secondaryColor;
  final String date;

  const AchievementBadge({
    required this.title,
    required this.category,
    required this.icon,
    this.emoji,
    required this.primaryColor,
    required this.secondaryColor,
    required this.date,
  });
}

/// Horizontal Scrolling Premium Achievements Badges Carousel
class HorizontalAchievementsSection extends StatefulWidget {
  const HorizontalAchievementsSection({Key? key}) : super(key: key);

  @override
  State<HorizontalAchievementsSection> createState() =>
      _HorizontalAchievementsSectionState();
}

class _HorizontalAchievementsSectionState
    extends State<HorizontalAchievementsSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _shineController;

  static List<AchievementBadge> _badges = [
    AchievementBadge(
      title: 'National Champion',
      category: 'GOLD TITLE',
      icon: Icons.emoji_events_rounded,
      primaryColor: AppTheme.secondaryAccent,
      secondaryColor: AppTheme.goldLight,
      date: '2025 • PK FED',
    ),
    AchievementBadge(
      title: 'Verified Athlete',
      category: 'PRO STATUS',
      icon: Icons.verified_rounded,
      primaryColor: AppTheme.info,
      secondaryColor: AppTheme.info.withOpacity(0.15),
      date: 'OFFICIAL',
    ),
    AchievementBadge(
      title: '10 Match Win Streak',
      category: 'UNDEFEATED',
      icon: Icons.local_fire_department_rounded,
      primaryColor: AppTheme.warning,
      secondaryColor: AppTheme.warning.withOpacity(0.15),
      date: 'ACTIVE STREAK',
    ),
    AchievementBadge(
      title: 'Elite Division',
      category: 'TIER I',
      icon: Icons.military_tech_rounded,
      primaryColor: AppTheme.highlightPurple,
      secondaryColor: AppTheme.highlightPurple.withOpacity(0.1),
      date: 'RANK 2000+ ELO',
    ),
    AchievementBadge(
      title: 'Gold League',
      category: 'PREMIER',
      icon: Icons.workspace_premium_rounded,
      primaryColor: AppTheme.goldLight,
      secondaryColor: AppTheme.goldLight,
      date: 'SEASON 2026',
    ),
    AchievementBadge(
      title: 'Top 10 Pakistan',
      category: 'NATIONAL RANK',
      icon: Icons.star_rounded,
      emoji: '🇵🇰',
      primaryColor: AppTheme.success,
      secondaryColor: AppTheme.success.withOpacity(0.15),
      date: 'RANK #3 PK',
    ),
    AchievementBadge(
      title: 'International Competitor',
      category: 'WORLD STAGE',
      icon: Icons.public_rounded,
      primaryColor: AppTheme.highlightPurple,
      secondaryColor: AppTheme.highlightPurple.withOpacity(0.15),
      date: 'GLOBAL FED',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
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
                    'PREMIUM ACHIEVEMENTS',
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
              Text(
                '${_badges.length} UNLOCKED',
                style: const TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppTheme.goldLight,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Horizontal Scrolling Badges List
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _badges.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final badge = _badges[index];
              return _3DBadgeCard(
                badge: badge,
                shineController: _shineController,
                staggerOffset: index * 0.15,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Individual 3D Glowing Achievement Badge Card
class _3DBadgeCard extends StatefulWidget {
  final AchievementBadge badge;
  final AnimationController shineController;
  final double staggerOffset;

  const _3DBadgeCard({
    Key? key,
    required this.badge,
    required this.shineController,
    required this.staggerOffset,
  }) : super(key: key);

  @override
  State<_3DBadgeCard> createState() => _3DBadgeCardState();
}

class _3DBadgeCardState extends State<_3DBadgeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2400 + (widget.staggerOffset * 1000).toInt()),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.badge;

    return AnimatedBuilder(
      animation: Listenable.merge([widget.shineController, _floatController]),
      builder: (context, child) {
        // Continuous 3D Floating Math
        final floatY = math.sin((_floatController.value + widget.staggerOffset) * math.pi * 2) * 3.0;

        // Gold Shine Sweep Animation Math
        final shineValue = (widget.shineController.value + widget.staggerOffset) % 1.0;
        final shineOffset = -1.5 + (shineValue * 3.0);

        return Transform.translate(
          offset: Offset(0, floatY),
          child: TactilePressWrapper(
            onTap: () {
              HapticFeedback.lightImpact();
            },
            enableLift: true,
            liftDistance: -3,
            child: Container(
              width: 130,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  // Soft Floating Shadow
                  BoxShadow(
                    color: Colors.black.withOpacity(0.55),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                  // Glow Shadow from Badge Accent
                  BoxShadow(
                    color: b.primaryColor.withOpacity(0.25),
                    blurRadius: 16,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.glassSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: b.primaryColor.withOpacity(0.4),
                        width: 1.1,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          b.primaryColor.withOpacity(0.18),
                          AppTheme.surface,
                          AppTheme.background,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Shimmering Gold/Accent Sweep Effect
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  begin: Alignment(shineOffset - 0.3, -1.0),
                                  end: Alignment(shineOffset + 0.3, 1.0),
                                  colors: [
                                    Colors.transparent,
                                    b.secondaryColor.withOpacity(0.25),
                                    Colors.white.withOpacity(0.35),
                                    b.secondaryColor.withOpacity(0.25),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Tiny Animated Sparkle Icon in Corner
                        Positioned(
                          top: 0,
                          right: 0,
                          child: _buildSparkle(shineValue, b.primaryColor),
                        ),

                        // Badge Main Content Column
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 3D Emblem Container
                            Container(
                              width: 52,
                              height: 52,
                              margin: EdgeInsets.only(top: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    b.secondaryColor,
                                    b.primaryColor,
                                    b.primaryColor.withOpacity(0.7),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: b.primaryColor.withOpacity(0.6),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.all(2),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.background,
                                  shape: BoxShape.circle,
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    if (b.emoji != null)
                                      Text(
                                        b.emoji!,
                                        style: TextStyle(fontSize: 22),
                                      )
                                    else
                                      Icon(
                                        b.icon,
                                        size: 26,
                                        color: b.secondaryColor,
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Badge Category Tag
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: b.primaryColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: b.primaryColor.withOpacity(0.4),
                                  width: 0.6,
                                ),
                              ),
                              child: Text(
                                b.category,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: b.primaryColor,
                                  letterSpacing: 0.6,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            const SizedBox(height: 4),

                            // Badge Title
                            Text(
                              b.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                                height: 1.1,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 4),

                            // Date / Subtitle
                            Text(
                              b.date,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textMuted,
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
          ),
        );
      },
    );
  }

  /// Tiny Sparkle animation widget
  Widget _buildSparkle(double shineVal, Color color) {
    final scale = 0.6 + (math.sin(shineVal * math.pi * 2).abs() * 0.5);

    return Transform.scale(
      scale: scale,
      child: Icon(
        Icons.auto_awesome_rounded,
        size: 13,
        color: Colors.white.withOpacity(0.85),
      ),
    );
  }
}
