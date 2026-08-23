import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
class MatchScheduleTimelineWidget extends StatefulWidget {
  final Map<String, dynamic> tournament;

  const MatchScheduleTimelineWidget({
    Key? key,
    required this.tournament,
  }) : super(key: key);

  @override
  State<MatchScheduleTimelineWidget> createState() => _MatchScheduleTimelineWidgetState();
}

class _MatchScheduleTimelineWidgetState extends State<MatchScheduleTimelineWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  int _activeFilter = 0; // 0: My Matches, 1: All Stage Matches, 2: Live & Next
  final Set<int> _reminderMatchIds = {};

  final List<Map<String, dynamic>> _mySchedule = [
    {
      'id': 101,
      'matchNumber': 'Match #12',
      'round': 'Round 1 (32-Draw)',
      'table': 'Table #1 • Stage A',
      'opponent': 'Bilal K. (Lahore)',
      'weightClass': 'Senior Men Right -80kg',
      'estimatedTime': '11:15 AM PST',
      'status': 'COMPLETED',
      'result': 'WON (2 - 0)',
      'resultColor': Color(0xFF00E676),
      'score': '2 - 0',
      'isUser': true,
    },
    {
      'id': 102,
      'matchNumber': 'Match #28',
      'round': 'Quarter-Finals',
      'table': 'Table #1 • Stage A',
      'opponent': 'Usman R. (Peshawar)',
      'weightClass': 'Senior Men Right -80kg',
      'estimatedTime': '01:45 PM PST',
      'status': 'COMPLETED',
      'result': 'WON (2 - 1)',
      'resultColor': Color(0xFF00E676),
      'score': '2 - 1',
      'isUser': true,
    },
    {
      'id': 103,
      'matchNumber': 'Match #42',
      'round': 'Semi-Finals',
      'table': 'Table #2 • Stage B',
      'opponent': 'Zain U. (Islamabad)',
      'weightClass': 'Senior Men Right -80kg',
      'estimatedTime': '03:30 PM PST (Live Now)',
      'status': 'LIVE',
      'result': 'IN PROGRESS',
      'resultColor': Color(0xFFFF2A6D),
      'score': '0 - 0',
      'isUser': true,
    },
    {
      'id': 104,
      'matchNumber': 'Match #54',
      'round': 'Grand Finals',
      'table': 'Main Arena Center Stage',
      'opponent': 'TBD (Semi 2 Winner)',
      'weightClass': 'Senior Men Right -80kg',
      'estimatedTime': '05:15 PM PST (Estimated)',
      'status': 'UPCOMING',
      'result': 'SCHEDULED',
      'resultColor': AppTheme.goldPrimary,
      'score': '- - -',
      'isUser': true,
    },
  ];

  final List<Map<String, dynamic>> _allSchedule = [
    {
      'id': 201,
      'matchNumber': 'Match #38',
      'round': 'Quarter-Finals',
      'table': 'Table #1 • Stage A',
      'opponent': 'Faisal M. vs. Ali N.',
      'weightClass': 'Senior Men Left -80kg',
      'estimatedTime': '02:45 PM PST',
      'status': 'COMPLETED',
      'result': 'FINISHED (2-1)',
      'resultColor': Color(0xFF00E676),
      'score': '2 - 1',
      'isUser': false,
    },
    {
      'id': 202,
      'matchNumber': 'Match #41',
      'round': 'Semi-Finals',
      'table': 'Table #1 • Stage A',
      'opponent': 'Hamza S. vs. Danish A.',
      'weightClass': 'Masters Men Right +100kg',
      'estimatedTime': '03:15 PM PST',
      'status': 'COMPLETED',
      'result': 'FINISHED (2-0)',
      'resultColor': Color(0xFF00E676),
      'score': '2 - 0',
      'isUser': false,
    },
    {
      'id': 103,
      'matchNumber': 'Match #42',
      'round': 'Semi-Finals',
      'table': 'Table #2 • Stage B',
      'opponent': 'Tariq Z. (YOU) vs. Zain U.',
      'weightClass': 'Senior Men Right -80kg',
      'estimatedTime': '03:30 PM PST (Live Now)',
      'status': 'LIVE',
      'result': 'IN PROGRESS',
      'resultColor': Color(0xFFFF2A6D),
      'score': '0 - 0',
      'isUser': true,
    },
    {
      'id': 204,
      'matchNumber': 'Match #43',
      'round': 'Semi-Finals',
      'table': 'Table #1 • Stage A',
      'opponent': 'Ahmad Y. vs. Asad K.',
      'weightClass': 'Senior Men Right -90kg',
      'estimatedTime': '04:00 PM PST',
      'status': 'UPCOMING',
      'result': 'NEXT MATCH',
      'resultColor': Color(0xFF00E5FF),
      'score': '- - -',
      'isUser': false,
    },
    {
      'id': 104,
      'matchNumber': 'Match #54',
      'round': 'Grand Finals',
      'table': 'Main Arena Center Stage',
      'opponent': 'TBD vs. TBD',
      'weightClass': 'Senior Men Right -80kg',
      'estimatedTime': '05:15 PM PST',
      'status': 'UPCOMING',
      'result': 'SCHEDULED',
      'resultColor': AppTheme.goldPrimary,
      'score': '- - -',
      'isUser': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredMatches {
    if (_activeFilter == 0) return _mySchedule;
    if (_activeFilter == 1) return _allSchedule;
    // Live & Next
    return _allSchedule
        .where((m) => m['status'] == 'LIVE' || m['result'] == 'NEXT MATCH')
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _filteredMatches;

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
              // Header Row
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
                          Icons.schedule_rounded,
                          color: AppTheme.goldPrimary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'MATCH SCHEDULE TIMELINE',
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
                            'Real-Time Stage Queue & Estimated Pull Times',
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
                      '${matches.length} MATCHES',
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

              const SizedBox(height: 14),

              // Filter Tabs Row
              Row(
                children: [
                  _buildFilterTab(0, 'MY TIMELINE'),
                  const SizedBox(width: 8),
                  _buildFilterTab(1, 'ALL MATCHES'),
                  const SizedBox(width: 8),
                  _buildFilterTab(2, 'LIVE & NEXT'),
                ],
              ),

              const SizedBox(height: 18),

              // Vertical Timeline Builder
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final match = matches[index];
                  final isLast = index == matches.length - 1;
                  return _buildTimelineItem(match, isLast);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTab(int index, String label) {
    final isSelected = _activeFilter == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _activeFilter = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.goldPrimary : Color(0xFF141E2F),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppTheme.goldPrimary : Colors.white12,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.goldPrimary.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 9.5,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? Colors.black : AppTheme.textMuted,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> match, bool isLast) {
    final status = match['status'] as String;
    final bool isLive = status == 'LIVE';
    final bool isCompleted = status == 'COMPLETED';
    final bool isUpcoming = status == 'UPCOMING';
    final bool isReminderSet = _reminderMatchIds.contains(match['id']);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Timeline Node & Vertical Connector Line
          SizedBox(
            width: 36,
            child: Column(
              children: [
                // Timeline Node Icon / Dot
                _buildTimelineNode(status),
                // Connecting vertical line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted
                          ? Color(0xFF00E676).withOpacity(0.3)
                          : isLive
                              ? Color(0xFFFF2A6D).withOpacity(0.5)
                              : Colors.white12,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Right Side: Match Detail Card
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 16.0),
              child: AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Color(0xFF0F172A).withOpacity(0.65) // Faded opacity for completed
                          : isLive
                              ? Color(0xFF1E1B4B) // Dark glowing background for live
                              : Color(0xFF141E2F), // Neutral dark for upcoming
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isCompleted
                            ? Color(0xFF00E676).withOpacity(0.3)
                            : isLive
                                ? Color(0xFFFF2A6D).withOpacity(_glowAnimation.value)
                                : Colors.white12,
                        width: isLive ? 1.6 : 1.0,
                      ),
                      boxShadow: isLive
                          ? [
                              BoxShadow(
                                color: Color(0xFFFF2A6D).withOpacity(0.35 * _glowAnimation.value),
                                blurRadius: 14,
                                spreadRadius: -1,
                              ),
                            ]
                          : [],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Card Top Bar: Round & Status Badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      match['matchNumber'],
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: isLive
                                            ? const Color(0xFFFF2A6D)
                                            : isCompleted
                                                ? AppTheme.textMuted
                                                : AppTheme.goldPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '• ${match['round']}',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        color: isCompleted ? AppTheme.textMuted : Colors.white,
                                      ),
                                    ),
                                  ],
                                ),

                                // Status Badge
                                _buildStatusBadge(status, match['result'], match['resultColor']),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Opponent / Competitors
                            Row(
                              children: [
                                Icon(
                                  Icons.sports_mma_rounded,
                                  size: 15,
                                  color: isLive
                                      ? const Color(0xFF00E5FF)
                                      : isCompleted
                                          ? AppTheme.textMuted
                                          : AppTheme.goldPrimary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    match['opponent'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontSize: 12.5,
                                      fontWeight: isLive ? FontWeight.w900 : FontWeight.w700,
                                      color: isCompleted ? Colors.white60 : Colors.white,
                                    ),
                                  ),
                                ),
                                if (match['score'] != '- - -') ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      match['score'],
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: isCompleted
                                            ? const Color(0xFF00E676)
                                            : const Color(0xFFFF2A6D),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Meta Row: Table & Estimated Time
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.tab_unselected_rounded,
                                        size: 12,
                                        color: AppTheme.textMuted,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          match['table'],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontFamily: AppTheme.fontDisplay,
                                            fontSize: 9.5,
                                            color: AppTheme.textMuted,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_filled_rounded,
                                      size: 12,
                                      color: isLive ? const Color(0xFFFF2A6D) : AppTheme.textMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      match['estimatedTime'],
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontSize: 9.5,
                                        fontWeight: isLive ? FontWeight.w900 : FontWeight.w600,
                                        color: isLive ? const Color(0xFFFF2A6D) : AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // Action Bar for Live / Upcoming
                            if (isLive || isUpcoming) ...[
                              const SizedBox(height: 10),
                              Container(height: 1, color: Colors.white12),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    match['weightClass'],
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontSize: 9,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                  if (isLive)
                                    TactilePressWrapper(
                                      onTap: () {
                                        HapticFeedback.heavyImpact();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('✓ Opening Live Stream for Table #2 Stage B'),
                                            backgroundColor: Color(0xFFFF2A6D),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF2A6D),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Icon(Icons.play_arrow_rounded, size: 12, color: Colors.white),
                                            SizedBox(width: 2),
                                            Text(
                                              'WATCH STREAM',
                                              style: TextStyle(
                                                fontFamily: AppTheme.fontDisplay,
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  if (isUpcoming)
                                    TactilePressWrapper(
                                      onTap: () {
                                        HapticFeedback.mediumImpact();
                                        setState(() {
                                          if (isReminderSet) {
                                            _reminderMatchIds.remove(match['id']);
                                          } else {
                                            _reminderMatchIds.add(match['id']);
                                          }
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              isReminderSet
                                                  ? 'Reminder removed for ${match['matchNumber']}'
                                                  : '✓ Push notification alert set for ${match['matchNumber']}',
                                            ),
                                            backgroundColor: isReminderSet ? Colors.grey[800] : AppTheme.goldPrimary,
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isReminderSet
                                              ? AppTheme.goldPrimary.withOpacity(0.2)
                                              : const Color(0xFF1E293B),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: isReminderSet ? AppTheme.goldPrimary : Colors.white12,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isReminderSet ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                                              size: 11,
                                              color: isReminderSet ? AppTheme.goldPrimary : AppTheme.textMuted,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isReminderSet ? 'REMINDER SET' : 'NOTIFY ME',
                                              style: TextStyle(
                                                fontFamily: AppTheme.fontDisplay,
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w900,
                                                color: isReminderSet ? AppTheme.goldPrimary : AppTheme.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineNode(String status) {
    if (status == 'COMPLETED') {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Color(0xFF00E676).withOpacity(0.18),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF00E676)),
        ),
        child: const Icon(
          Icons.check_rounded,
          size: 14,
          color: Color(0xFF00E676),
        ),
      );
    }

    if (status == 'LIVE') {
      return AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: Color(0xFFFF2A6D),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFFF2A6D).withOpacity(0.6 * _glowAnimation.value),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.sensors_rounded,
              size: 15,
              color: Colors.white,
            ),
          );
        },
      );
    }

    // UPCOMING
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Color(0xFF141E2F),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.6), width: 1.5),
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppTheme.goldPrimary,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, String resultText, Color badgeColor) {
    if (status == 'LIVE') {
      return AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Color(0xFFFF2A6D).withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Color(0xFFFF2A6D).withOpacity(_glowAnimation.value),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Color(0xFFFF2A6D).withOpacity(_glowAnimation.value),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'LIVE NOW',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFF2A6D),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withOpacity(0.4)),
      ),
      child: Text(
        resultText,
        style: TextStyle(
          fontFamily: AppTheme.fontDisplay,
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          color: badgeColor,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

