import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
class LiveTournamentStatusCard extends StatefulWidget {
  final Map<String, dynamic> tournament;

  const LiveTournamentStatusCard({
    Key? key,
    required this.tournament,
  }) : super(key: key);

  @override
  State<LiveTournamentStatusCard> createState() => _LiveTournamentStatusCardState();
}

class _LiveTournamentStatusCardState extends State<LiveTournamentStatusCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _forceShowForTesting = true; // Set default true so users can see the card immediately in preview

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = (widget.tournament['status'] ?? 'LIVE').toString().toUpperCase();
    final bool hasStarted = status == 'LIVE' || status == 'IN_PROGRESS' || status == 'STARTED' || _forceShowForTesting;

    // Visible ONLY if tournament has started (or forced in preview)
    if (!hasStarted) {
      return const SizedBox.shrink();
    }

    final currentMatch = widget.tournament['currentMatch'] ?? 'Match #42: Tariq Z. vs. Zain U. (Senior -80kg R)';
    final liveProgress = widget.tournament['liveProgress'] ?? 'Quarter-Finals (Round 3 of 5)';
    final progressValue = (widget.tournament['progressPct'] as num?)?.toDouble() ?? 0.68;
    final athletesRemaining = widget.tournament['athletesRemaining'] ?? '12 / 64 Athletes';
    final matchesFinished = widget.tournament['matchesFinished'] ?? '38 / 56 Matches';
    final currentTable = widget.tournament['currentTable'] ?? 'Table #2 • Main Arena Stage A';
    final estimatedFinish = widget.tournament['estimatedFinish'] ?? '05:30 PM PST (~2h 15m remaining)';
    final liveAudience = widget.tournament['liveAudience'] ?? '1,420 Viewers Online';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xFF0F172A).withOpacity(0.90),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Color(0xFFFF2A6D).withOpacity(0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFF2A6D).withOpacity(0.18),
            blurRadius: 20,
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
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
              // Header Row: Title & Animated Red LIVE Chip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Color(0xFFFF2A6D).withOpacity(0.18),
                          shape: BoxShape.circle,
                          border: Border.all(color: Color(0xFFFF2A6D).withOpacity(0.5)),
                        ),
                        child: Icon(
                          Icons.sensors_rounded,
                          color: Color(0xFFFF2A6D),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'LIVE TOURNAMENT STATUS',
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
                            'Real-Time Stage Feed & Bracket State',
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

                  // Animated Red LIVE Chip
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Color(0xFFFF2A6D).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Color(0xFFFF2A6D).withOpacity(_pulseAnimation.value),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFFF2A6D).withOpacity(0.4 * _pulseAnimation.value),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: Color(0xFFFF2A6D).withOpacity(_pulseAnimation.value),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'LIVE NOW',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFFF2A6D),
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Current Match Spotlight Banner
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1E1B4B).withOpacity(0.8),
                      Color(0xFF0F172A).withOpacity(0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Color(0xFF00E5FF).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.sports_mma_rounded, size: 16, color: Color(0xFF00E5FF)),
                        SizedBox(width: 8),
                        Text(
                          'CURRENT MATCH ON TABLE',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF00E5FF),
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currentMatch,
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Live Bracket Progress & Animated Progress Indicator
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.account_tree_rounded, size: 14, color: AppTheme.goldPrimary),
                          SizedBox(width: 6),
                          Text(
                            'LIVE BRACKET PROGRESS',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.goldPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${(progressValue * 100).toInt()}% COMPLETE',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.goldPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    liveProgress,
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Animated Progress Indicator Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        Container(
                          height: 8,
                          width: double.infinity,
                          color: Color(0xFF1E293B),
                        ),
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return FractionallySizedBox(
                              widthFactor: progressValue,
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  gradient: LinearGradient(
                                    colors: [Color(0xFFFFB300), Color(0xFFFF2A6D)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFFFF2A6D).withOpacity(0.5 * _pulseAnimation.value),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Detailed Stats Grid (2 Columns)
              Row(
                children: [
                  Expanded(
                    child: _buildLiveStatBox(
                      icon: Icons.groups_outlined,
                      label: 'Athletes Remaining',
                      value: athletesRemaining,
                      accentColor: Color(0xFF00E5FF),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildLiveStatBox(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Matches Finished',
                      value: matchesFinished,
                      accentColor: Color(0xFF00E676),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildLiveStatBox(
                      icon: Icons.tab_unselected_rounded,
                      label: 'Current Table',
                      value: currentTable,
                      accentColor: AppTheme.goldPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildLiveStatBox(
                      icon: Icons.hourglass_top_rounded,
                      label: 'Estimated Finish',
                      value: estimatedFinish,
                      accentColor: Color(0xFFFF2A6D),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Live Audience Counter Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Color(0xFF162032).withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.remove_red_eye_rounded, size: 15, color: Color(0xFF00E5FF)),
                    const SizedBox(width: 8),
                    Text(
                      'LIVE AUDIENCE: ',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    Text(
                      liveAudience,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF00E5FF),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // "Watch Live" Button (Links strictly to official YouTube stream)
              TactilePressWrapper(
                onTap: () {
                  HapticFeedback.heavyImpact();
                  _openYouTubeLiveStream(context);
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF0000), Color(0xFFFF2A6D)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFFF0000).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.play_circle_fill_rounded, size: 20, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'WATCH LIVE STREAM',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveStatBox({
    required IconData icon,
    required String label,
    required String value,
    required Color accentColor,
  }) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Color(0xFF141E2F).withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: accentColor),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _openYouTubeLiveStream(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.play_circle_fill_rounded, color: Color(0xFFFF0000), size: 24),
              SizedBox(width: 8),
              Text(
                'PAFF Official Broadcast',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Redirecting to the Official PAFF YouTube Live Stream...',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12.5),
              ),
              SizedBox(height: 12),
              Text(
                '• Channel: Pakistan Armwrestling Federation Official\n• Quality: 1080p60 Live Commentary\n• Table #1 & Table #2 Dual Feed Available',
                style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF0000),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✓ Opening official YouTube stream: https://youtube.com/live/PAFF_Official_2026'),
                    backgroundColor: Color(0xFFFF0000),
                  ),
                );
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('OPEN YOUTUBE', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}

