import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/theme/app_theme.dart';
import '../../../core/widgets/pulse_indicator.dart';
class TournamentTimelineWidget extends StatefulWidget {
  final Map<String, dynamic> tournament;

  const TournamentTimelineWidget({
    super.key,
    required this.tournament,
  });

  @override
  State<TournamentTimelineWidget> createState() => _TournamentTimelineWidgetState();
}

class _TournamentTimelineWidgetState extends State<TournamentTimelineWidget>
    with SingleTickerProviderStateMixin {
  int _currentEventIndex = 0;
  late AnimationController _pulseController;

  List<Map<String, dynamic>> _resolveTimelineEvents() {
    final raw = widget.tournament['timeline'] ?? widget.tournament['stages'];
    if (raw is List && raw.isNotEmpty) {
      return raw.map<Map<String, dynamic>>((e) {
        if (e is! Map<String, dynamic>) return <String, dynamic>{};
        final title = e['title'] ?? e['name'] ?? 'Tournament Stage';
        return {
          'title': title.toString(),
          'date': e['date']?.toString() ?? 'TBD',
          'time': e['time']?.toString() ?? 'TBD',
          'location': e['location']?.toString() ?? widget.tournament['venue']?.toString() ?? 'Main Arena',
          'details': e['details']?.toString() ?? e['description']?.toString() ?? 'Official tournament stage.',
          'icon': _resolveTimelineIcon(title.toString()),
        };
      }).where((e) => e.isNotEmpty).toList();
    }

    final venue = widget.tournament['venue']?.toString() ?? 'Main Arena';
    final regStart = widget.tournament['registrationStart'] != null ? DateTime.tryParse(widget.tournament['registrationStart'].toString()) : null;
    final regEnd = widget.tournament['registrationEnd'] != null ? DateTime.tryParse(widget.tournament['registrationEnd'].toString()) : null;
    final startDate = widget.tournament['startDate'] != null ? DateTime.tryParse(widget.tournament['startDate'].toString()) : null;
    final endDate = widget.tournament['endDate'] != null ? DateTime.tryParse(widget.tournament['endDate'].toString()) : null;

    final events = <Map<String, dynamic>>[];
    if (regStart != null) {
      events.add({
        'title': 'Registration Opens',
        'date': '${regStart.month}/${regStart.day}/${regStart.year}',
        'time': '09:00 AM PKT',
        'location': 'ArmSphere Digital Portal',
        'details': 'Online competitor registration opened.',
        'icon': Icons.app_registration_rounded,
      });
    }
    if (regEnd != null) {
      events.add({
        'title': 'Registration Closes',
        'date': '${regEnd.month}/${regEnd.day}/${regEnd.year}',
        'time': '11:59 PM PKT',
        'location': 'Digital Systems Lockdown',
        'details': 'Final slot confirmation and category capacity enforcement.',
        'icon': Icons.timer_off_rounded,
      });
    }
    if (startDate != null) {
      events.add({
        'title': 'Weigh-in & Verification',
        'date': '${startDate.month}/${startDate.day}/${startDate.year}',
        'time': '08:00 AM - 10:00 AM PKT',
        'location': '$venue • Weigh-in Desk',
        'details': 'Official weight lock & weight class eligibility certification.',
        'icon': Icons.scale_rounded,
      });
      events.add({
        'title': 'Opening Ceremony',
        'date': '${startDate.month}/${startDate.day}/${startDate.year}',
        'time': '10:00 AM - 10:30 AM PKT',
        'location': '$venue • Center Arena',
        'details': 'Referee oath, athlete assembly & rules briefing.',
        'icon': Icons.stars_rounded,
      });
      events.add({
        'title': 'Competition Bouts',
        'date': '${startDate.month}/${startDate.day}/${startDate.year}',
        'time': '10:30 AM - 05:00 PM PKT',
        'location': '$venue • Official Tables',
        'details': 'Double elimination tournament brackets across active tables.',
        'icon': Icons.sports_mma_rounded,
      });
    }
    if (endDate != null) {
      events.add({
        'title': 'Championship Finals',
        'date': '${endDate.month}/${endDate.day}/${endDate.year}',
        'time': '05:30 PM - 07:00 PM PKT',
        'location': '$venue • Elevated Main Table',
        'details': 'Title bouts for gold, silver, and bronze podium positions.',
        'icon': Icons.emoji_events_rounded,
      });
      events.add({
        'title': 'Awards Ceremony',
        'date': '${endDate.month}/${endDate.day}/${endDate.year}',
        'time': '07:30 PM PKT',
        'location': '$venue • Main Podium',
        'details': 'Medal presentation and official ELO ranking points distribution.',
        'icon': Icons.military_tech_rounded,
      });
    }

    return events;
  }

  static IconData _resolveTimelineIcon(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('reg')) return Icons.app_registration_rounded;
    if (lower.contains('weigh') || lower.contains('scale')) return Icons.scale_rounded;
    if (lower.contains('final') || lower.contains('award') || lower.contains('ceremony')) return Icons.emoji_events_rounded;
    if (lower.contains('ceremony') || lower.contains('opening')) return Icons.stars_rounded;
    return Icons.sports_mma_rounded;
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    final events = _resolveTimelineEvents();
    final status = (widget.tournament['status'] ?? '').toString().toUpperCase();
    if (status == 'COMPLETED' || status == 'FINISHED') {
      _currentEventIndex = (events.length - 1).clamp(0, events.length > 0 ? events.length - 1 : 0);
    } else if (status == 'LIVE' || status == 'IN_PROGRESS') {
      _currentEventIndex = (events.length ~/ 2).clamp(0, events.length > 0 ? events.length - 1 : 0);
    } else {
      _currentEventIndex = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timelineEvents = _resolveTimelineEvents();

    if (timelineEvents.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white12,
            width: 1.2,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timeline_rounded, color: Colors.white38, size: 36),
              SizedBox(height: 10),
              Text(
                'No Timeline Stages Published',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Official timeline stages will appear once scheduled.',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final totalStages = timelineEvents.length;
    final currentStage = (_currentEventIndex + 1).clamp(1, totalStages);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.goldPrimary.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section Header & Timeline Control Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.goldPrimary.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.goldPrimary.withValues(alpha: 0.5)),
                      ),
                      child: const Icon(
                        Icons.timeline_rounded,
                        color: AppTheme.goldPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOURNAMENT TIMELINE',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$totalStages Official Championship Stages',
                          style: const TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 10,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Active Stage Counter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF2A6D).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFF2A6D).withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PulseIndicator(size: 5.0, color: Color(0xFFFF2A6D)),
                      const SizedBox(width: 5),
                      Text(
                        'STAGE $currentStage OF $totalStages',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFF2A6D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Interactive Stage Progress Step Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 36),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _currentEventIndex > 0
                        ? () {
                            HapticFeedback.selectionClick();
                            setState(() => _currentEventIndex--);
                          }
                        : null,
                    icon: const Icon(Icons.chevron_left_rounded, size: 18),
                    label: const Text('PREVIOUS STAGE', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldPrimary,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(0, 36),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _currentEventIndex < totalStages - 1
                        ? () {
                            HapticFeedback.selectionClick();
                            setState(() => _currentEventIndex++);
                          }
                        : null,
                    icon: const Icon(Icons.chevron_right_rounded, size: 18),
                    label: const Text('NEXT STAGE', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 18),

            // VERTICAL TIMELINE RENDERING
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: timelineEvents.length,
              itemBuilder: (context, index) {
                final item = timelineEvents[index];
                final isPast = index < _currentEventIndex;
                final isCurrent = index == _currentEventIndex;
                final isLast = index == totalStages - 1;

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vertical Line & Node Bullet Column
                      SizedBox(
                        width: 32,
                        child: Column(
                          children: [
                            // Node Bullet / Icon
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Container(
                                  width: isCurrent ? 28 : 22,
                                  height: isCurrent ? 28 : 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isCurrent
                                        ? AppTheme.goldPrimary
                                        : (isPast ? const Color(0xFF00E676).withValues(alpha: 0.2) : const Color(0xFF1E293B)),
                                    border: Border.all(
                                      color: isCurrent
                                          ? Colors.white
                                          : (isPast ? const Color(0xFF00E676) : Colors.white24),
                                      width: isCurrent ? 2 : 1,
                                    ),
                                    boxShadow: isCurrent
                                        ? [
                                            BoxShadow(
                                              color: AppTheme.goldPrimary.withValues(alpha: 0.4 + 0.3 * _pulseController.value),
                                              blurRadius: 10 + 6 * _pulseController.value,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: isPast
                                        ? const Icon(Icons.check_rounded, size: 12, color: Color(0xFF00E676))
                                        : (isCurrent
                                            ? const Icon(Icons.bolt_rounded, size: 16, color: Colors.black)
                                            : Container(
                                                width: 6,
                                                height: 6,
                                                decoration: const BoxDecoration(
                                                  color: Colors.white38,
                                                  shape: BoxShape.circle,
                                                ),
                                              )),
                                  ),
                                );
                              },
                            ),

                            // Animated Vertical Line Segment
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
                                        isPast
                                            ? const Color(0xFF00E676).withValues(alpha: 0.6)
                                            : (isCurrent ? AppTheme.goldPrimary : Colors.white12),
                                        (index + 1 < _currentEventIndex)
                                            ? const Color(0xFF00E676).withValues(alpha: 0.6)
                                            : ((index + 1 == _currentEventIndex)
                                                ? AppTheme.goldPrimary
                                                : Colors.white12),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Event Item Card Content Column
                      Expanded(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: isPast ? 0.55 : (isCurrent ? 1.0 : 0.75),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? const Color(0xFF1E2B47)
                                  : (isPast ? const Color(0xFF0D1424) : const Color(0xFF131D33)),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isCurrent
                                    ? AppTheme.goldPrimary
                                    : (isPast ? const Color(0xFF00E676).withValues(alpha: 0.2) : Colors.white12),
                                width: isCurrent ? 1.5 : 1.0,
                              ),
                              boxShadow: isCurrent
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.goldPrimary.withValues(alpha: 0.18),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title & Status Badge
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(
                                            item['icon'] as IconData,
                                            size: 16,
                                            color: isCurrent
                                                ? AppTheme.goldPrimary
                                                : (isPast ? const Color(0xFF00E676) : Colors.white60),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              item['title'] as String,
                                              style: TextStyle(
                                                fontFamily: AppTheme.fontDisplay,
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w900,
                                                color: isCurrent ? AppTheme.goldPrimary : Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isPast
                                            ? const Color(0xFF00E676).withValues(alpha: 0.15)
                                            : (isCurrent
                                                ? AppTheme.goldPrimary.withValues(alpha: 0.2)
                                                : Colors.white10),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isPast ? 'COMPLETED' : (isCurrent ? 'LIVE NOW' : 'UPCOMING'),
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w900,
                                          color: isPast
                                              ? const Color(0xFF00E676)
                                              : (isCurrent ? AppTheme.goldPrimary : Colors.white38),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 6),

                                // Date & Time Row
                                Row(
                                  children: [
                                    const Icon(Icons.access_time_rounded, size: 12, color: AppTheme.textMuted),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${item['date']} • ${item['time']}',
                                      style: const TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 4),

                                // Location Row
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF00E5FF)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        item['location'] as String,
                                        style: const TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          fontSize: 10,
                                          color: Color(0xFF00E5FF),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 6),

                                // Event Details Description
                                Text(
                                  item['details'] as String,
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontSize: 10,
                                    color: Colors.white70,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// PART 9 — PARTICIPANTS (Premium Carousel & Search/Filter Matrix)
// ============================================================================

