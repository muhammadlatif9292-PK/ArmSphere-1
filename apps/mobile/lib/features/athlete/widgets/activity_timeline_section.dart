import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';

enum TimelineEventType {
  recentMatch,
  tournamentRegistered,
  rankIncreased,
  achievementEarned,
  licenseRenewed,
  upcomingEvent,
}

class TimelineEventItem {
  final String title;
  final String subtitle;
  final String timestamp;
  final TimelineEventType type;
  final IconData icon;
  final Color glowColor;
  final String? badgeText;

  const TimelineEventItem({
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.type,
    required this.icon,
    required this.glowColor,
    this.badgeText,
  });
}

/// Activity Timeline Section with Glowing Dots & Modern Vertical Line
class ActivityTimelineSection extends StatefulWidget {
  const ActivityTimelineSection({Key? key}) : super(key: key);

  @override
  State<ActivityTimelineSection> createState() => _ActivityTimelineSectionState();
}

class _ActivityTimelineSectionState extends State<ActivityTimelineSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  static const List<TimelineEventItem> _events = [
    TimelineEventItem(
      title: 'Recent Match Victory',
      subtitle: 'Defeated Tariq Khan (3 - 0) in National Championship Semi-Finals',
      timestamp: '2 hours ago',
      type: TimelineEventType.recentMatch,
      icon: Icons.sports_mma_rounded,
      glowColor: AppTheme.success,
      badgeText: '+16 ELO',
    ),
    TimelineEventItem(
      title: 'Tournament Registered',
      subtitle: 'Confirmed entry in Rawalpindi Open Supermatch (-95kg Division)',
      timestamp: '1 day ago',
      type: TimelineEventType.tournamentRegistered,
      icon: Icons.how_to_reg_rounded,
      glowColor: AppTheme.info,
      badgeText: 'CONFIRMED',
    ),
    TimelineEventItem(
      title: 'Rank Increased',
      subtitle: 'Promoted to Rank #3 in National Heavyweight Division',
      timestamp: '3 days ago',
      type: TimelineEventType.rankIncreased,
      icon: Icons.trending_up_rounded,
      glowColor: AppTheme.goldPrimary,
      badgeText: 'RANK #3 PK',
    ),
    TimelineEventItem(
      title: 'Achievement Earned',
      subtitle: 'Unlocked "10 Match Win Streak" badge on ArmSphere Network',
      timestamp: '5 days ago',
      type: TimelineEventType.achievementEarned,
      icon: Icons.auto_awesome_rounded,
      glowColor: AppTheme.highlightPurple,
      badgeText: 'BADGE UNLOCKED',
    ),
    TimelineEventItem(
      title: 'License Renewed',
      subtitle: 'Pakistan Armwrestling Federation Pro Athlete License 2026-2027 Active',
      timestamp: '1 week ago',
      type: TimelineEventType.licenseRenewed,
      icon: Icons.verified_user_rounded,
      glowColor: AppTheme.success,
      badgeText: 'VERIFIED',
    ),
    TimelineEventItem(
      title: 'Upcoming Event',
      subtitle: 'Islamabad Grand Armwrestling Night (Main Event Bout)',
      timestamp: 'In 14 Days',
      type: TimelineEventType.upcomingEvent,
      icon: Icons.event_available_rounded,
      glowColor: AppTheme.warning,
      badgeText: 'MAIN EVENT',
    ),
  ];

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
                    'ACTIVITY TIMELINE',
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
              const Text(
                'LIVE LOGS',
                style: TextStyle(
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

        const SizedBox(height: 16),

        // Timeline Container
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final pulseVal = _pulseController.value;

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _events.length,
              itemBuilder: (context, index) {
                final event = _events[index];
                final isFirst = index == 0;
                final isLast = index == _events.length - 1;

                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 400 + (index * 120)),
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  builder: (context, animValue, child) {
                    return Transform.translate(
                      offset: Offset(0, (1.0 - animValue) * 20),
                      child: Opacity(
                        opacity: animValue,
                        child: _TimelineEventTile(
                          event: event,
                          isFirst: isFirst,
                          isLast: isLast,
                          pulseVal: pulseVal,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}

/// Single Event Tile with Modern Vertical Line & Glowing Dot
class _TimelineEventTile extends StatelessWidget {
  final TimelineEventItem event;
  final bool isFirst;
  final bool isLast;
  final double pulseVal;

  const _TimelineEventTile({
    Key? key,
    required this.event,
    required this.isFirst,
    required this.isLast,
    required this.pulseVal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Column: Vertical Line & Glowing Dot
          SizedBox(
            width: 38,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // Modern Vertical Line
                Positioned(
                  top: isFirst ? 18 : 0,
                  bottom: isLast ? 18 : 0,
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          event.glowColor.withOpacity(0.6),
                          AppTheme.surface,
                          event.glowColor.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                ),

                // Glowing Node Dot with Multi-Layer Glow
                Positioned(
                  top: 14,
                  child: TactilePressWrapper(
                    onTap: () {
                      HapticFeedback.lightImpact();
                    },
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.background,
                        border: Border.all(
                          color: event.glowColor,
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: event.glowColor.withOpacity(0.6 + (pulseVal * 0.3)),
                            blurRadius: 10 + (pulseVal * 6),
                            spreadRadius: 1 + (pulseVal * 2),
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
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

          const SizedBox(width: 8),

          // Right Column: Event Glass Tile Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: TactilePressWrapper(
                onTap: () {
                  HapticFeedback.selectionClick();
                },
                enableLift: true,
                liftDistance: -2,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: event.glowColor.withOpacity(0.12),
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
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.glassSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: event.glowColor.withOpacity(0.35),
                            width: 1.0,
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              event.glowColor.withOpacity(0.12),
                              AppTheme.surface,
                              AppTheme.background,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon Badge
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: event.glowColor.withOpacity(0.18),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: event.glowColor.withOpacity(0.5),
                                  width: 0.9,
                                ),
                              ),
                              child: Icon(
                                event.icon,
                                size: 16,
                                color: event.glowColor,
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Content Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          event.title,
                                          style: TextStyle(
                                            fontFamily: AppTheme.fontDisplay,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        event.timestamp,
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 3),

                                  Text(
                                    event.subtitle,
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textMuted,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                  if (event.badgeText != null) ...[
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: event.glowColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: event.glowColor.withOpacity(0.4),
                                          width: 0.6,
                                        ),
                                      ),
                                      child: Text(
                                        event.badgeText!,
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w900,
                                          color: event.glowColor,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
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
        ],
      ),
    );
  }
}
