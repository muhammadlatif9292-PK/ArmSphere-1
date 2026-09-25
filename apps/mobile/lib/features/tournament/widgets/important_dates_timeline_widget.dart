import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/theme/app_theme.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
class ImportantDatesTimelineWidget extends StatefulWidget {
  final Map<String, dynamic> tournament;

  const ImportantDatesTimelineWidget({
    super.key,
    required this.tournament,
  });

  @override
  State<ImportantDatesTimelineWidget> createState() => _ImportantDatesTimelineWidgetState();
}

class _ImportantDatesTimelineWidgetState extends State<ImportantDatesTimelineWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  List<Map<String, dynamic>> _resolveTimelineEvents() {
    final raw = widget.tournament['importantDates'] ?? widget.tournament['dates'];
    if (raw is List && raw.isNotEmpty) {
      return raw.map<Map<String, dynamic>>((e) {
        if (e is! Map<String, dynamic>) return <String, dynamic>{};
        final dt = e['date'] != null ? DateTime.tryParse(e['date'].toString()) : null;
        final status = e['status'] ?? (dt != null ? _calcStatus(dt, DateTime.now()) : 'UPCOMING');
        return {
          'id': e['id']?.toString() ?? 'evt_${DateTime.now().millisecondsSinceEpoch}',
          'title': e['title'] ?? 'Tournament Event',
          'date': dt != null ? _formatDate(dt) : (e['date']?.toString() ?? 'TBD'),
          'time': e['time']?.toString() ?? 'Schedule TBD',
          'status': status,
          'icon': _resolveEventIcon(e['title']?.toString() ?? ''),
          'accentColor': _calcColor(status.toString()),
          'description': e['description']?.toString() ?? 'Official schedule milestone.',
        };
      }).where((e) => e.isNotEmpty).toList();
    }

    final now = DateTime.now();
    final events = <Map<String, dynamic>>[];

    final regStart = widget.tournament['registrationStart'] != null
        ? DateTime.tryParse(widget.tournament['registrationStart'].toString())
        : null;
    final regEnd = widget.tournament['registrationEnd'] != null
        ? DateTime.tryParse(widget.tournament['registrationEnd'].toString())
        : null;
    final startDate = widget.tournament['startDate'] != null
        ? DateTime.tryParse(widget.tournament['startDate'].toString())
        : null;
    final endDate = widget.tournament['endDate'] != null
        ? DateTime.tryParse(widget.tournament['endDate'].toString())
        : null;

    if (regStart != null) {
      final status = _calcStatus(regStart, now);
      events.add({
        'id': 'evt_reg_start',
        'title': 'Registration Opens',
        'date': _formatDate(regStart),
        'time': '09:00 AM PKT',
        'status': status,
        'icon': Icons.app_registration_rounded,
        'accentColor': _calcColor(status),
        'description': 'Online registration opens for verified competitors.',
      });
    }

    if (regEnd != null) {
      final status = _calcStatus(regEnd, now);
      events.add({
        'id': 'evt_reg_end',
        'title': 'Registration Closes',
        'date': _formatDate(regEnd),
        'time': '11:59 PM PKT',
        'status': status,
        'icon': Icons.how_to_reg_rounded,
        'accentColor': _calcColor(status),
        'description': 'Final online athlete registration and weight locking.',
      });
    }

    if (startDate != null) {
      final weighInDate = startDate.subtract(const Duration(hours: 4));
      final weighInStatus = _calcStatus(weighInDate, now);
      events.add({
        'id': 'evt_weigh_in',
        'title': 'Weigh-In Verification',
        'date': _formatDate(weighInDate),
        'time': '08:00 AM - 10:00 AM PKT',
        'status': weighInStatus,
        'icon': Icons.scale_rounded,
        'accentColor': _calcColor(weighInStatus),
        'description': 'Official scale check and referee ID badge issuance.',
      });

      final startStatus = _calcStatus(startDate, now);
      events.add({
        'id': 'evt_comp_start',
        'title': 'Competition Start',
        'date': _formatDate(startDate),
        'time': '10:30 AM PKT',
        'status': startStatus,
        'icon': Icons.sports_mma_rounded,
        'accentColor': _calcColor(startStatus),
        'description': 'Main bracket pull rounds across competition tables.',
      });
    }

    if (endDate != null) {
      final endStatus = _calcStatus(endDate, now);
      events.add({
        'id': 'evt_awards',
        'title': 'Finals & Awards Ceremony',
        'date': _formatDate(endDate),
        'time': '06:00 PM PKT',
        'status': endStatus,
        'icon': Icons.workspace_premium_rounded,
        'accentColor': _calcColor(endStatus),
        'description': 'Championship title bouts, podium medals, and ranking points.',
      });
    }

    return events;
  }

  static String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  static String _calcStatus(DateTime dt, DateTime now) {
    if (now.isAfter(dt.add(const Duration(days: 1)))) return 'COMPLETED';
    if (now.year == dt.year && now.month == dt.month && now.day == dt.day) return 'IN_PROGRESS';
    return 'UPCOMING';
  }

  static Color _calcColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return const Color(0xFF00E676);
      case 'IN_PROGRESS':
        return AppTheme.goldPrimary;
      default:
        return const Color(0xFF00E5FF);
    }
  }

  static IconData _resolveEventIcon(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('reg')) return Icons.how_to_reg_rounded;
    if (lower.contains('weigh') || lower.contains('scale')) return Icons.scale_rounded;
    if (lower.contains('award') || lower.contains('podium')) return Icons.workspace_premium_rounded;
    if (lower.contains('medical')) return Icons.health_and_safety_rounded;
    return Icons.sports_mma_rounded;
  }

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
    final timelineEvents = _resolveTimelineEvents();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1527).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.goldPrimary.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldPrimary.withValues(alpha: 0.12),
            blurRadius: 18,
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
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
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppTheme.goldPrimary.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.goldPrimary.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Icon(
                          Icons.event_note_rounded,
                          color: AppTheme.goldPrimary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'IMPORTANT DATES & DEADLINES',
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
                    child: Text(
                      '${timelineEvents.length} MILESTONES',
                      style: const TextStyle(
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

              // Vertical Timeline List or Empty State
              if (timelineEvents.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  alignment: Alignment.center,
                  child: const Column(
                    children: [
                      Icon(Icons.event_note_rounded, size: 32, color: AppTheme.textMuted),
                      SizedBox(height: 8),
                      Text(
                        'Important dates and schedule milestones have not been posted yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: timelineEvents.length,
                  itemBuilder: (context, index) {
                    final event = timelineEvents[index];
                    final bool isLast = index == timelineEvents.length - 1;
                    return _buildTimelineNode(timelineEvents, event, index, isLast);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineNode(List<Map<String, dynamic>> allEvents, Map<String, dynamic> event, int index, bool isLast) {
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
            width: 32,
            child: Column(
              children: [
                // Glowing/Pulsing Dot or Check Icon
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    final pulseScale = isInProgress ? 1.0 + (0.15 * _pulseAnimation.value) : 1.0;
                    return Transform.scale(
                      scale: pulseScale,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF141E2F),
                          border: Border.all(
                            color: accentColor,
                            width: isInProgress ? 2.0 : 1.5,
                          ),
                          boxShadow: isInProgress
                              ? [
                                  BoxShadow(
                                    color: accentColor.withValues(alpha: 0.45 * _pulseAnimation.value),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [],
                        ),
                        child: Center(
                          child: Icon(
                            isCompleted ? Icons.check_rounded : event['icon'] as IconData,
                            size: 13,
                            color: accentColor,
                          ),
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
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            accentColor.withValues(alpha: isCompleted ? 0.8 : 0.4),
                            (allEvents[index + 1]['accentColor'] as Color).withValues(alpha: 0.3),
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141E2F).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isInProgress
                          ? accentColor
                          : accentColor.withValues(alpha: isCompleted ? 0.35 : 0.2),
                      width: isInProgress ? 1.4 : 1.0,
                    ),
                    boxShadow: [
                      if (isInProgress)
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.2),
                          blurRadius: 12,
                          spreadRadius: -1,
                        ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
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
                          const Icon(
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF00E676).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.5)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.goldPrimary.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppTheme.goldPrimary.withValues(alpha: 0.6 + (_pulseAnimation.value * 0.4)),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white12),
        ),
        child: Text(
          'UPCOMING',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 8,
            fontWeight: FontWeight.w800,
            color: accentColor.withValues(alpha: 0.9),
          ),
        ),
      );
    }
  }
}

