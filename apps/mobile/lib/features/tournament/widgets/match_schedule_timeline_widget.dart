import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
class MatchScheduleTimelineWidget extends StatefulWidget {
  final Map<String, dynamic> tournament;

  const MatchScheduleTimelineWidget({
    super.key,
    required this.tournament,
  });

  @override
  State<MatchScheduleTimelineWidget> createState() => _MatchScheduleTimelineWidgetState();
}

class _MatchScheduleTimelineWidgetState extends State<MatchScheduleTimelineWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  int _activeFilter = 0; // 0: My Matches, 1: All Stage Matches, 2: Live & Next
  final Set<int> _reminderMatchIds = {};

  List<Map<String, dynamic>> _resolveSchedule() {
    final raw = widget.tournament['matches'] ?? widget.tournament['schedule'];
    if (raw is List && raw.isNotEmpty) {
      return raw.map<Map<String, dynamic>>((m) {
        if (m is! Map<String, dynamic>) return <String, dynamic>{};
        final athlete1 = m['athlete1'] is Map ? m['athlete1'] : null;
        final athlete2 = m['athlete2'] is Map ? m['athlete2'] : null;
        final athlete1Name = athlete1?['fullName'] ?? athlete1?['name'] ?? m['athlete1Name'] ?? 'TBD';
        final athlete2Name = athlete2?['fullName'] ?? athlete2?['name'] ?? m['athlete2Name'] ?? 'TBD';
        final isUser = m['isUser'] == true || m['userMatch'] == true;
        final status = (m['status'] ?? 'UPCOMING').toString().toUpperCase();
        final result = m['result'] ??
            (status == 'LIVE'
                ? 'IN PROGRESS'
                : (status == 'COMPLETED' ? 'FINISHED' : 'SCHEDULED'));
        final resultColor = status == 'LIVE'
            ? const Color(0xFFFF2A6D)
            : (status == 'COMPLETED' ? const Color(0xFF00E676) : AppTheme.goldPrimary);

        final idVal = (m['id'] is num)
            ? (m['id'] as num).toInt()
            : (int.tryParse(m['id']?.toString() ?? '') ?? 0);

        return {
          'id': idVal,
          'matchNumber': m['matchNumber'] != null ? 'Match #${m['matchNumber']}' : 'Bout',
          'round': m['round'] ?? 'Bracket Round',
          'table': m['table'] ?? m['tableName'] ?? 'Main Arena Table',
          'opponent': '$athlete1Name vs. $athlete2Name',
          'weightClass': m['division'] != null && m['weightClass'] != null
              ? '${m['division']} ${m['weightClass']}'
              : (m['category'] ?? 'Open Category'),
          'estimatedTime': m['estimatedTime'] ?? m['time'] ?? 'TBD',
          'status': status,
          'result': result,
          'resultColor': resultColor,
          'score': m['score'] ?? (status == 'COMPLETED' ? 'Completed' : '- - -'),
          'isUser': isUser,
        };
      }).where((m) => m.isNotEmpty).toList();
    }
    return [];
  }

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
    final allSchedule = _resolveSchedule();
    if (_activeFilter == 0) {
      return allSchedule.where((m) => m['isUser'] == true).toList();
    }
    if (_activeFilter == 1) {
      return allSchedule;
    }
    // Live & Next
    return allSchedule
        .where((m) =>
            m['status'] == 'LIVE' ||
            m['result'] == 'NEXT MATCH' ||
            m['status'] == 'IN_PROGRESS')
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _filteredMatches;

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
              // Header Row
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
                          Icons.schedule_rounded,
                          color: AppTheme.goldPrimary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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

              // Vertical Timeline Builder or Empty State
              if (matches.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const Icon(Icons.event_busy_rounded, color: AppTheme.textMuted, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        _activeFilter == 0
                            ? 'No scheduled matches found for your registration.'
                            : (_activeFilter == 2
                                ? 'No matches are currently live or next on deck.'
                                : 'No matches scheduled yet for this event.'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
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
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.goldPrimary : const Color(0xFF141E2F),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppTheme.goldPrimary : Colors.white12,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.goldPrimary.withValues(alpha: 0.3),
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
                          ? const Color(0xFF00E676).withValues(alpha: 0.3)
                          : isLive
                              ? const Color(0xFFFF2A6D).withValues(alpha: 0.5)
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
              padding: const EdgeInsets.only(bottom: 16.0),
              child: AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? const Color(0xFF0F172A).withValues(alpha: 0.65) // Faded opacity for completed
                          : isLive
                              ? const Color(0xFF1E1B4B) // Dark glowing background for live
                              : const Color(0xFF141E2F), // Neutral dark for upcoming
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isCompleted
                            ? const Color(0xFF00E676).withValues(alpha: 0.3)
                            : isLive
                                ? const Color(0xFFFF2A6D).withValues(alpha: _glowAnimation.value)
                                : Colors.white12,
                        width: isLive ? 1.6 : 1.0,
                      ),
                      boxShadow: isLive
                          ? [
                              BoxShadow(
                                color: const Color(0xFFFF2A6D).withValues(alpha: 0.35 * _glowAnimation.value),
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
                                      const Icon(
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
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
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
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isReminderSet
                                              ? AppTheme.goldPrimary.withValues(alpha: 0.2)
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
          color: const Color(0xFF00E676).withValues(alpha: 0.18),
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
              color: const Color(0xFFFF2A6D),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF2A6D).withValues(alpha: 0.6 * _glowAnimation.value),
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
        color: const Color(0xFF141E2F),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.goldPrimary.withValues(alpha: 0.6), width: 1.5),
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFF2A6D).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFFFF2A6D).withValues(alpha: _glowAnimation.value),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF2A6D).withValues(alpha: _glowAnimation.value),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
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

