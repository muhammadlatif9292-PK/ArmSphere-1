import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/theme/app_theme.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
class TournamentStatisticsWidget extends StatefulWidget {
  final Map<String, dynamic> tournament;

  const TournamentStatisticsWidget({
    super.key,
    required this.tournament,
  });

  @override
  State<TournamentStatisticsWidget> createState() => _TournamentStatisticsWidgetState();
}

class _TournamentStatisticsWidgetState extends State<TournamentStatisticsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _numAnimController;
  late Animation<double> _animation;

  List<Map<String, dynamic>> _resolveStatsData() {
    final t = widget.tournament;
    final capacity = (t['capacity'] is num) ? (t['capacity'] as num).toInt() : 0;
    final registered = (t['registeredAthletesCount'] is num)
        ? (t['registeredAthletesCount'] as num).toInt()
        : ((t['registeredCount'] is num)
            ? (t['registeredCount'] as num).toInt()
            : ((t['participants'] is List) ? (t['participants'] as List).length : 0));
    final verified = (t['verifiedAthletesCount'] is num)
        ? (t['verifiedAthletesCount'] as num).toInt()
        : ((t['verifiedCount'] is num) ? (t['verifiedCount'] as num).toInt() : 0);
    final matches = (t['matchCount'] is num)
        ? (t['matchCount'] as num).toInt()
        : ((t['matches'] is List) ? (t['matches'] as List).length : 0);
    final tables = (t['tablesCount'] is num)
        ? (t['tablesCount'] as num).toInt()
        : ((t['tables'] is List) ? (t['tables'] as List).length : 1);
    final referees = (t['refereesCount'] is num)
        ? (t['refereesCount'] as num).toInt()
        : ((t['referees'] is List) ? (t['referees'] as List).length : 0);
    final prizePool = (t['prizePool'] is num)
        ? (t['prizePool'] as num).toInt()
        : ((t['prizePoolPkr'] is num)
            ? (t['prizePoolPkr'] as num).toInt()
            : ((t['registrationFeeCents'] is num)
                ? ((t['registrationFeeCents'] as num).toInt() * registered ~/ 100)
                : 0));

    return [
      {
        'id': 'registered_athletes',
        'label': 'Registered Athletes',
        'targetValue': registered,
        'prefix': '',
        'suffix': '',
        'icon': Icons.people_alt_rounded,
        'accentColor': const Color(0xFF00E5FF),
        'subtitle': capacity > 0 ? 'Max Capacity: $capacity' : 'Total Registered',
      },
      {
        'id': 'verified_athletes',
        'label': 'Verified Athletes',
        'targetValue': verified,
        'prefix': '',
        'suffix': '',
        'icon': Icons.verified_user_rounded,
        'accentColor': const Color(0xFF00E676),
        'subtitle': registered > 0
            ? '${((verified / registered) * 100).toInt()}% Weigh-Ins Cleared'
            : 'Official Weigh-Ins',
      },
      {
        'id': 'matches',
        'label': 'Matches',
        'targetValue': matches,
        'prefix': '',
        'suffix': ' Pulls',
        'icon': Icons.sports_mma_rounded,
        'accentColor': const Color(0xFFFF2A6D),
        'subtitle': matches > 0 ? 'Bracket Bouts' : 'Pending Draw',
      },
      {
        'id': 'tables',
        'label': 'Tables',
        'targetValue': tables,
        'prefix': 'Stage ',
        'suffix': ' Arenas',
        'icon': Icons.tab_unselected_rounded,
        'accentColor': AppTheme.goldPrimary,
        'subtitle': 'Active Stage Tables',
      },
      {
        'id': 'referees',
        'label': 'Referees',
        'targetValue': referees,
        'prefix': '',
        'suffix': ' Officials',
        'icon': Icons.gavel_rounded,
        'accentColor': const Color(0xFFA855F7),
        'subtitle': 'Certified PAFF Officials',
      },
      {
        'id': 'prize_pool',
        'label': 'Prize Pool',
        'targetValue': prizePool,
        'prefix': 'Rs. ',
        'suffix': '',
        'isCurrency': true,
        'icon': Icons.workspace_premium_rounded,
        'accentColor': const Color(0xFFFFB703),
        'subtitle': prizePool > 0 ? 'Cash & Awards Pool' : 'Official Certificates',
      },
    ];
  }

  @override
  void initState() {
    super.initState();
    _numAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _animation = CurvedAnimation(
      parent: _numAnimController,
      curve: Curves.easeOutCubic,
    );

    _numAnimController.forward();
  }

  @override
  void dispose() {
    _numAnimController.dispose();
    super.dispose();
  }

  void _replayAnimation() {
    HapticFeedback.lightImpact();
    _numAnimController.reset();
    _numAnimController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final statsData = _resolveStatsData();

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
              // Header Row with Replay Counter Button
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
                          Icons.query_stats_rounded,
                          color: AppTheme.goldPrimary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOURNAMENT STATISTICS',
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
                            'Live Official Competition Analytics',
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

                  // Replay / Refresh Animation Button
                  TactilePressWrapper(
                    onTap: _replayAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            size: 12,
                            color: AppTheme.goldPrimary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'REPLAY',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.goldPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 6 Animated Glass Statistic Cards (2 Columns x 3 Rows Equal Grid)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: statsData.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.5,
                ),
                itemBuilder: (context, index) {
                  final stat = statsData[index];
                  return _buildGlassStatCard(stat);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassStatCard(Map<String, dynamic> stat) {
    final Color accentColor = stat['accentColor'] as Color;
    final int target = stat['targetValue'] as int;
    final bool isCurrency = stat['isCurrency'] == true;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final double currentValue = _animation.value * target;
        final String displayValue = isCurrency
            ? _formatCurrency(currentValue.round())
            : '${stat['prefix']}${currentValue.round()}${stat['suffix']}';

        return TactilePressWrapper(
          onTap: () {
            HapticFeedback.selectionClick();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✓ ${stat['label']}: ${stat['subtitle']}'),
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
                color: accentColor.withValues(alpha: 0.35),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.12),
                  blurRadius: 10,
                  spreadRadius: -2,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Icon & Category Label
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                          ),
                          child: Icon(
                            stat['icon'] as IconData,
                            size: 13,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          stat['label'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textMuted,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Center: Animated Number Count
                Text(
                  displayValue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: isCurrency ? 14 : 17,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),

                // Bottom: Subtitle / Context Note
                Text(
                  stat['subtitle'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 8.5,
                    color: accentColor.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatCurrency(int amount) {
    if (amount >= 100000) {
      return 'Rs. ${(amount / 1000).toStringAsFixed(0)}K';
    }
    return 'Rs. $amount';
  }
}

