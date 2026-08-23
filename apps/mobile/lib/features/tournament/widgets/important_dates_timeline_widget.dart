import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
class ImportantDatesTimelineWidget extends StatefulWidget {
  final Map<String, dynamic> tournament;

  const ImportantDatesTimelineWidget({
    Key? key,
    required this.tournament,
  }) : super(key: key);

  @override
  State<ImportantDatesTimelineWidget> createState() => _ImportantDatesTimelineWidgetState();
}

class _ImportantDatesTimelineWidgetState extends State<ImportantDatesTimelineWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<Map<String, dynamic>> _timelineEvents = [
    {
      'id': 'evt_1',
      'title': 'Registration Close',
      'date': 'Aug 10, 2026',
      'time': '11:59 PM PKT',
      'status': 'COMPLETED',
      'icon': Icons.how_to_reg_rounded,
      'accentColor': const Color(0xFF00E676),
      'description': 'Final online athlete registration & weight class locking.',
    },
    {
      'id': 'evt_2',
      'title': 'Medical Submission',
      'date': 'Aug 12, 2026',
      'time': '05:00 PM PKT',
      'status': 'COMPLETED',
      'icon': Icons.health_and_safety_rounded,
      'accentColor': const Color(0xFF00E676),
      'description': 'PAFF physical clearance certificate & anti-doping forms.',
    },
    {
      'id': 'evt_3',
      'title': 'Weigh-In Verification',
      'date': 'Aug 14, 2026',
      'time': '09:00 AM - 06:00 PM',
      'status': 'IN_PROGRESS',
      'icon': Icons.scale_rounded,
      'accentColor': AppTheme.goldPrimary,
      'description': 'Official digital scale check & referee ID badge issuance.',
    },
    {
      'id': 'evt_4',
      'title': 'Athlete Check-In',
      'date': 'Aug 15, 2026',
      'time': '08:00 AM PKT',
      'status': 'UPCOMING',
      'icon': Icons.fact_check_rounded,
      'accentColor': const Color(0xFF00E5FF),
      'description': 'Stage 1 arena staging, warm-up table allocation.',
    },
    {
      'id': 'evt_5',
      'title': 'Competition Start',
      'date': 'Aug 15, 2026',
      'time': '10:00 AM PKT',
      'status': 'UPCOMING',
      'icon': Icons.sports_mma_rounded,
      'accentColor': const Color(0xFFFF2A6D),
      'description': 'Main bracket pull rounds across 4 official tables.',
    },
    {
      'id': 'evt_6',
      'title': 'Awards Ceremony',
      'date': 'Aug 16, 2026',
      'time': '06:00 PM PKT',
      'status': 'UPCOMING',
      'icon': Icons.workspace_premium_rounded,
      'accentColor': AppTheme.goldPrimary,
      'description': 'Podium medal presentation, ELO points distribution.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xFF0D1527).withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.goldPrimary.withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldPrimary.withOpacity(0.12),
            blurRadius: 18,
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppTheme.goldPrimary.withOpacity(0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.goldPrimary.withOpacity(0.5),
                          ),
                        ),
                        child: const Icon(
                          Icons.event_note_rounded,
                          color: AppTheme.goldPrimary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'IMPORTANT DATES',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Official Deadlines & Schedule Milestones',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 10.5,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Text(
                      '6 MILESTONES',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.goldPrimary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Vertical Timeline List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _timelineEvents.length,
                itemBuilder: (context, index) {
                  final event = _timelineEvents[index];
                  final bool isLast = index == _timelineEvents.length - 1;
                  return _buildTimelineNode(event, index, isLast);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineNode(Map<String, dynamic> event, int index, bool isLast) {
    final String status = event['status'] as String;
    final Color accentColor = event['accentColor'] as Color;
    final bool isCompleted = status == 'COMPLETED';
    final bool isInProgress = status == 'IN_PROGRESS';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Node Indicator & Connecting Vertical Line
          SizedBox(
            width: 38,
            child: Column(
              children: [
                // Glowing Node Circle
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    final double pulseValue = isInProgress || !isCompleted
                        ? 0.7 + (_pulseAnimation.value * 0.3)
                        : 1.0;

                    return Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? accentColor
                            : (isInProgress
                                ? accentColor.withOpacity(0.25)
                                : Color(0xFF1E293B)),
                        border: Border.all(
                          color: accentColor.withOpacity(isCompleted ? 1.0 : 0.8),
                          width: isCompleted ? 2.0 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(
                              isCompleted ? 0.6 : (isInProgress ? 0.4 * pulseValue : 0.15),
                            ),
                            blurRadius: isCompleted ? 10 : (isInProgress ? 12 * pulseValue : 6),
                            spreadRadius: isCompleted ? 2 : (isInProgress ? 2 * pulseValue : 0),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          isCompleted
                              ? Icons.check_rounded
                              : (isInProgress ? Icons.bolt_rounded : event['icon'] as IconData),
                          size: 14,
                          color: isCompleted
                              ? Colors.black
                              : (isInProgress ? accentColor : Colors.white70),
                        ),
                      ),
                    );
                  },
                ),

                // Vertical Line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            accentColor.withOpacity(isCompleted ? 0.8 : 0.4),
                            (_timelineEvents[index + 1]['accentColor'] as Color).withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Right Glass Event Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: TactilePressWrapper(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('📅 ${event['title']}: ${event['date']} • ${event['time']}'),
                      backgroundColor: accentColor,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF141E2F).withOpacity(0.85),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isInProgress
                          ? accentColor
                          : accentColor.withOpacity(isCompleted ? 0.35 : 0.2),
                      width: isInProgress ? 1.4 : 1.0,
                    ),
                    boxShadow: [
                      if (isInProgress)
                        BoxShadow(
                          color: accentColor.withOpacity(0.2),
                          blurRadius: 12,
                          spreadRadius: -1,
                        ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Title & Status Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              event['title'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _buildStatusBadge(status, accentColor),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Date & Time Row
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 11,
                            color: accentColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            event['date'],
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '•',
                            style: TextStyle(color: Colors.white24, fontSize: 10),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.access_time_rounded,
                            size: 11,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            event['time'],
                            style: const TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 10,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Event Description
                      Text(
                        event['description'],
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 10.5,
                          color: Colors.white70,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color accentColor) {
    if (status == 'COMPLETED') {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Color(0xFF00E676).withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Color(0xFF00E676).withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle_rounded, size: 10, color: Color(0xFF00E676)),
            SizedBox(width: 3),
            Text(
              'PASSED',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: Color(0xFF00E676),
              ),
            ),
          ],
        ),
      );
    } else if (status == 'IN_PROGRESS') {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.goldPrimary.withOpacity(0.25),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppTheme.goldPrimary.withOpacity(0.6 + (_pulseAnimation.value * 0.4)),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.bolt_rounded, size: 10, color: AppTheme.goldPrimary),
                SizedBox(width: 3),
                Text(
                  'NOW LIVE',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.goldPrimary,
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white12),
        ),
        child: Text(
          'UPCOMING',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 8,
            fontWeight: FontWeight.w800,
            color: accentColor.withOpacity(0.9),
          ),
        ),
      );
    }
  }
}

