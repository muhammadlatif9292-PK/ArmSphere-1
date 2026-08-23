import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Achievement model representing a prestigious athletic award / Olympic-style medal
class AchievementItemData {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String category; // e.g. 'National', 'Circuit', 'Mastery'
  final String medalTier; // 'Gold', 'Silver', 'Bronze', 'Diamond'
  final IconData icon;
  final bool isUnlocked;
  final double progress; // 0.0 to 1.0
  final String dateUnlocked;
  final bool isRecent;

  const AchievementItemData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.category,
    required this.medalTier,
    required this.icon,
    this.isUnlocked = true,
    this.progress = 1.0,
    required this.dateUnlocked,
    this.isRecent = false,
  });
}

/// Custom Painter for Olympic Medal Ribbon & Metallic Rim
class _OlympicMedalPainter extends CustomPainter {
  final String tier;
  final bool isUnlocked;
  final double pulseValue;

  _OlympicMedalPainter({
    required this.tier,
    required this.isUnlocked,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 6);
    final radius = (size.width / 2) - 8;

    // 1. Draw Olympic-style Satin Ribbon hanging at top
    final ribbonPath = Path()
      ..moveTo(size.width / 2 - 12, 0)
      ..lineTo(size.width / 2 + 12, 0)
      ..lineTo(size.width / 2 + 8, center.dy - radius + 2)
      ..lineTo(size.width / 2 - 8, center.dy - radius + 2)
      ..close();

    final ribbonPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF8B0000), // Crimson Red Satin Ribbon
          Color(0xFFD32F2F),
          Color(0xFF5C0000),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 24));

    canvas.drawPath(ribbonPath, ribbonPaint);

    // 2. Pulse Glow Halo for recent achievements
    if (pulseValue > 0) {
      final pulseRadius = radius + (pulseValue * 8.0);
      final pulsePaint = Paint()
        ..color = AppTheme.goldPrimary.withOpacity(0.35 * (1.0 - pulseValue))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, pulseRadius, pulsePaint);
    }

    // 3. Metallic Colors definition
    List<Color> metalColors;
    if (!isUnlocked) {
      metalColors = [
        const Color(0xFF333842),
        const Color(0xFF1F232B),
        const Color(0xFF14171D),
      ];
    } else {
      switch (tier.toLowerCase()) {
        case 'diamond':
          metalColors = const [
            Color(0xFFE0F7FA),
            Color(0xFF80DEEA),
            Color(0xFF00ACC1),
          ];
          break;
        case 'silver':
          metalColors = const [
            Color(0xFFF5F5F5),
            Color(0xFFBDBDBD),
            Color(0xFF616161),
          ];
          break;
        case 'bronze':
          metalColors = const [
            Color(0xFFFFCC80),
            Color(0xFFD7CCC8),
            Color(0xFF8D6E63),
          ];
          break;
        case 'gold':
        default:
          metalColors = const [
            AppTheme.goldLight,
            AppTheme.goldPrimary,
            AppTheme.goldDark,
          ];
          break;
      }
    }

    // 4. Outer Metallic Rim & Laurel Wreath Base Circle
    final outerRimPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = SweepGradient(
        colors: metalColors,
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, outerRimPaint);

    // 5. Inset Inner Matte Circle
    final innerCirclePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = isUnlocked ? const Color(0xFF121622) : const Color(0xFF0D0F18);

    canvas.drawCircle(center, radius - 4.5, innerCirclePaint);

    // 6. Fine Gold Laurel Ring Border
    final innerRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = isUnlocked
          ? AppTheme.goldPrimary.withOpacity(0.6)
          : Colors.white.withOpacity(0.1);

    canvas.drawCircle(center, radius - 4.5, innerRingPaint);
  }

  @override
  bool shouldRepaint(covariant _OlympicMedalPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue ||
        oldDelegate.isUnlocked != isUnlocked ||
        oldDelegate.tier != tier;
  }
}

/// Single Medal Widget with subtle pulse, lock state, and tap response
class OlympicMedalBadge extends StatefulWidget {
  final AchievementItemData item;
  final VoidCallback onTap;

  const OlympicMedalBadge({
    Key? key,
    required this.item,
    required this.onTap,
  }) : super(key: key);

  @override
  State<OlympicMedalBadge> createState() => _OlympicMedalBadgeState();
}

class _OlympicMedalBadgeState extends State<OlympicMedalBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    if (widget.item.isRecent) {
      _pulseController.repeat(reverse: false);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xDD121622),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.isRecent
                ? AppTheme.goldPrimary.withOpacity(0.5)
                : AppTheme.goldPrimary.withOpacity(0.15),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            if (item.isRecent)
              BoxShadow(
                color: AppTheme.goldPrimary.withOpacity(0.15),
                blurRadius: 14,
                spreadRadius: -2,
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Olympic Medal Icon with Canvas Wreath & Ribbon
            SizedBox(
              width: 58,
              height: 64,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _OlympicMedalPainter(
                      tier: item.medalTier,
                      isUnlocked: item.isUnlocked,
                      pulseValue: item.isRecent ? _pulseController.value : 0.0,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Icon(
                          item.isUnlocked ? item.icon : Icons.lock_outline,
                          size: 22,
                          color: item.isUnlocked
                              ? AppTheme.goldLight
                              : AppTheme.textMuted,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Award Title
            Text(
              item.title,
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: item.isUnlocked
                    ? AppTheme.textPrimary
                    : AppTheme.textMuted,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 2),

            // Tier/Category Subtitle
            Text(
              item.isUnlocked
                  ? item.medalTier.toUpperCase()
                  : '${(item.progress * 100).toInt()}% LOCK',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: item.isUnlocked
                    ? AppTheme.goldPrimary
                    : AppTheme.textMuted.withOpacity(0.7),
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Achievements Section Widget
class AchievementsSection extends StatefulWidget {
  final Map<String, dynamic>? athleteData;

  const AchievementsSection({
    Key? key,
    this.athleteData,
  }) : super(key: key);

  @override
  State<AchievementsSection> createState() => _AchievementsSectionState();
}

class _AchievementsSectionState extends State<AchievementsSection> {
  late List<AchievementItemData> _achievements;

  @override
  void initState() {
    super.initState();

    _achievements = const [
      AchievementItemData(
        id: '1',
        title: 'SUPERMATCH MASTER',
        subtitle: 'Defeated top 10 ranked opponent in official Supermatch circuit',
        description:
            'Awarded by the World Armwrestling Federation for outstanding victory in a 6-round official Supermatch.',
        category: 'Official Circuit',
        medalTier: 'Gold',
        icon: Icons.emoji_events_rounded,
        isUnlocked: true,
        progress: 1.0,
        dateUnlocked: 'MAY 10, 2026',
        isRecent: true,
      ),
      AchievementItemData(
        id: '2',
        title: '2000 ELO CLUB',
        subtitle: 'Crossed 2000 official ELO rating milestone',
        description:
            'Elite rank recognition for maintaining an ELO rating exceeding 2000 points in national division.',
        category: 'Rating Milestone',
        medalTier: 'Diamond',
        icon: Icons.workspace_premium_rounded,
        isUnlocked: true,
        progress: 1.0,
        dateUnlocked: 'APR 24, 2026',
        isRecent: false,
      ),
      AchievementItemData(
        id: '3',
        title: 'NATIONAL CHAMPION',
        subtitle: 'First place in -95kg National Championship',
        description:
            'Gold medal placement in the Pakistan National Armwrestling Championship 2025.',
        category: 'National Title',
        medalTier: 'Gold',
        icon: Icons.military_tech_rounded,
        isUnlocked: true,
        progress: 1.0,
        dateUnlocked: 'DEC 18, 2025',
        isRecent: false,
      ),
      AchievementItemData(
        id: '4',
        title: '10 STREAK VICTOR',
        subtitle: 'Win 10 consecutive official tournament matches',
        description:
            'Undefeated streak in sanctioned federation events. Currently at 7/10 matches.',
        category: 'Match Streak',
        medalTier: 'Silver',
        icon: Icons.local_fire_department_rounded,
        isUnlocked: false,
        progress: 0.70,
        dateUnlocked: 'Locked',
        isRecent: false,
      ),
    ];
  }

  void _showAchievementModal(AchievementItemData item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF121622),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: AppTheme.goldPrimary.withOpacity(0.3),
                width: 1.0,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Handle Bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // Large Olympic Medal Render
                SizedBox(
                  width: 80,
                  height: 90,
                  child: CustomPaint(
                    painter: _OlympicMedalPainter(
                      tier: item.medalTier,
                      isUnlocked: item.isUnlocked,
                      pulseValue: 0.0,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: Icon(
                          item.isUnlocked ? item.icon : Icons.lock_outline,
                          size: 32,
                          color: item.isUnlocked
                              ? AppTheme.goldLight
                              : AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Title & Category
                Text(
                  item.title,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.2,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 4),

                Text(
                  '${item.medalTier.toUpperCase()} MEDAL • ${item.category.toUpperCase()}',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.goldPrimary,
                    letterSpacing: 1.0,
                  ),
                ),

                const SizedBox(height: 16),

                // Description Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B202D),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.06),
                    ),
                  ),
                  child: Text(
                    item.description,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontBody,
                      fontSize: 13,
                      height: 1.5,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 16),

                // Progress or Unlocked Date Info Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.isUnlocked ? 'DATE CONFERRED' : 'PROGRESS',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    Text(
                      item.isUnlocked
                          ? item.dateUnlocked
                          : '${(item.progress * 100).toInt()}% COMPLETED',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.goldLight,
                      ),
                    ),
                  ],
                ),

                if (!item.isUnlocked) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 6,
                      child: LinearProgressIndicator(
                        value: item.progress,
                        backgroundColor: const Color(0xFF1B202D),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.goldPrimary),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldPrimary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'CLOSE HONORS',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final unlockedCount = _achievements.where((a) => a.isUnlocked).length;
    final totalCount = _achievements.length;
    final overallRatio = unlockedCount / totalCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppTheme.goldPrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'HONORS & ACHIEVEMENTS',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            Text(
              '$unlockedCount / $totalCount UNLOCKED',
              style: const TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: AppTheme.goldPrimary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Overall Completion Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 4,
            child: LinearProgressIndicator(
              value: overallRatio,
              backgroundColor: const Color(0xFF1B202D),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.goldPrimary),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Horizontal List of Collectible Olympic Medals
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _achievements.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final item = _achievements[index];
              return OlympicMedalBadge(
                item: item,
                onTap: () => _showAchievementModal(item),
              );
            },
          ),
        ),
      ],
    );
  }
}
