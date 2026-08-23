import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../core/widgets/pulse_indicator.dart';
class _TournamentTimelineWidget extends StatefulWidget {
  final Map<String, dynamic> tournament;

  const _TournamentTimelineWidget({
    Key? key,
    required this.tournament,
  }) : super(key: key);

  @override
  State<_TournamentTimelineWidget> createState() => _TournamentTimelineWidgetState();
}

class _TournamentTimelineWidgetState extends State<_TournamentTimelineWidget>
    with SingleTickerProviderStateMixin {
  int _currentEventIndex = 8; // Default current active event: Semi Finals
  late AnimationController _pulseController;

  final List<Map<String, dynamic>> _timelineEvents = [
    {
      'title': 'Registration Opens',
      'date': 'June 1, 2026',
      'time': '09:00 AM PST',
      'location': 'Online Portal & PAFF Office',
      'details': 'Early bird competitor registration opened for all provincial qualifiers.',
      'icon': Icons.app_registration_rounded,
    },
    {
      'title': 'Registration Closes',
      'date': 'August 10, 2026',
      'time': '11:59 PM PST',
      'location': 'Digital Systems Lockdown',
      'details': 'Final slot confirmation and category capacity enforcement.',
      'icon': Icons.timer_off_rounded,
    },
    {
      'title': 'Medical Verification',
      'date': 'August 14, 2026',
      'time': '08:00 AM - 10:00 AM',
      'location': 'Nishtar Sports Complex Medical Wing',
      'details': 'Doctor clearance, skin check, blood pressure & joint mobility check.',
      'icon': Icons.health_and_safety_rounded,
    },
    {
      'title': 'Weigh-in',
      'date': 'August 14, 2026',
      'time': '10:00 AM - 01:00 PM',
      'location': 'Main Calibrated Scale Station A',
      'details': 'Official weight lock & weight class eligibility certification.',
      'icon': Icons.scale_rounded,
    },
    {
      'title': 'Check-in',
      'date': 'August 15, 2026',
      'time': '08:00 AM - 09:00 AM',
      'location': 'Athlete Holding Zone & Arena Gate 2',
      'details': 'Digital QR pass scanning, wristband distribution & warmup entry.',
      'icon': Icons.how_to_reg_rounded,
    },
    {
      'title': 'Opening Ceremony',
      'date': 'August 15, 2026',
      'time': '09:30 AM - 10:15 AM',
      'location': 'Center Arena Stage',
      'details': 'PAFF Executive Council address, referee oath & national anthem.',
      'icon': Icons.stars_rounded,
    },
    {
      'title': 'Qualification',
      'date': 'August 15, 2026',
      'time': '10:30 AM - 01:30 PM',
      'location': 'Arena Tables 1, 2 & 3',
      'details': 'Double elimination preliminary rounds across all men division classes.',
      'icon': Icons.sports_kabaddi_rounded,
    },
    {
      'title': 'Quarter Finals',
      'date': 'August 15, 2026',
      'time': '02:00 PM - 03:30 PM',
      'location': 'Main Broadcast Tables A & B',
      'details': 'Top 8 athletes per weight class battle for semifinal spots.',
      'icon': Icons.workspace_premium_rounded,
    },
    {
      'title': 'Semi Finals',
      'date': 'August 15, 2026',
      'time': '04:00 PM - 05:30 PM',
      'location': 'Main Broadcast Table A',
      'details': 'High stakes clashes for championship final qualification.',
      'icon': Icons.bolt_rounded,
    },
    {
      'title': 'Finals',
      'date': 'August 15, 2026',
      'time': '06:00 PM - 07:15 PM',
      'location': 'Center Arena Elevated Stage Table',
      'details': 'Gold & Silver title matches live on national television.',
      'icon': Icons.emoji_events_rounded,
    },
    {
      'title': 'Award Ceremony',
      'date': 'August 15, 2026',
      'time': '07:30 PM - 08:30 PM',
      'location': 'Main Podium Stage',
      'details': 'Medal presentation, trophy awards & PKR 500,000 cash prizes.',
      'icon': Icons.military_tech_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
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
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.goldPrimary.withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20.0),
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
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.goldPrimary.withOpacity(0.18),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.5)),
                      ),
                      child: Icon(
                        Icons.timeline_rounded,
                        color: AppTheme.goldPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'TOURNAMENT TIMELINE',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '11 Official Championship Stages',
                          style: TextStyle(
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
                  padding: EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFFFF2A6D).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(0xFFFF2A6D).withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PulseIndicator(size: 5.0, color: Color(0xFFFF2A6D)),
                      const SizedBox(width: 5),
                      Text(
                        'STAGE ${_currentEventIndex + 1} OF 11',
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
                    onPressed: _currentEventIndex < _timelineEvents.length - 1
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
              itemCount: _timelineEvents.length,
              itemBuilder: (context, index) {
                final item = _timelineEvents[index];
                final isPast = index < _currentEventIndex;
                final isCurrent = index == _currentEventIndex;
                final isLast = index == _timelineEvents.length - 1;

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
                                        : (isPast ? Color(0xFF00E676).withOpacity(0.2) : Color(0xFF1E293B)),
                                    border: Border.all(
                                      color: isCurrent
                                          ? Colors.white
                                          : (isPast ? Color(0xFF00E676) : Colors.white24),
                                      width: isCurrent ? 2 : 1,
                                    ),
                                    boxShadow: isCurrent
                                        ? [
                                            BoxShadow(
                                              color: AppTheme.goldPrimary.withOpacity(0.4 + 0.3 * _pulseController.value),
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
                                  margin: EdgeInsets.symmetric(vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        isPast
                                            ? Color(0xFF00E676).withOpacity(0.6)
                                            : (isCurrent ? AppTheme.goldPrimary : Colors.white12),
                                        (index + 1 < _currentEventIndex)
                                            ? Color(0xFF00E676).withOpacity(0.6)
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
                            margin: EdgeInsets.only(bottom: 14),
                            padding: EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? Color(0xFF1E2B47)
                                  : (isPast ? Color(0xFF0D1424) : Color(0xFF131D33)),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isCurrent
                                    ? AppTheme.goldPrimary
                                    : (isPast ? Color(0xFF00E676).withOpacity(0.2) : Colors.white12),
                                width: isCurrent ? 1.5 : 1.0,
                              ),
                              boxShadow: isCurrent
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.goldPrimary.withOpacity(0.18),
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
                                                : (isPast ? Color(0xFF00E676) : Colors.white60),
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
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isPast
                                            ? Color(0xFF00E676).withOpacity(0.15)
                                            : (isCurrent
                                                ? AppTheme.goldPrimary.withOpacity(0.2)
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

