import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
class TournamentStatisticsWidget extends StatefulWidget {
  final Map<String, dynamic> tournament;

  const TournamentStatisticsWidget({
    Key? key,
    required this.tournament,
  }) : super(key: key);

  @override
  State<TournamentStatisticsWidget> createState() => _TournamentStatisticsWidgetState();
}

class _TournamentStatisticsWidgetState extends State<TournamentStatisticsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _numAnimController;
  late Animation<double> _animation;

  final List<Map<String, dynamic>> _statsData = [
    {
      'id': 'registered_athletes',
      'label': 'Registered Athletes',
      'targetValue': 128,
      'prefix': '',
      'suffix': '',
      'icon': Icons.people_alt_rounded,
      'accentColor': const Color(0xFF00E5FF),
      'subtitle': 'Max Capacity: 128',
    },
    {
      'id': 'verified_athletes',
      'label': 'Verified Athletes',
      'targetValue': 114,
      'prefix': '',
      'suffix': '',
      'icon': Icons.verified_user_rounded,
      'accentColor': const Color(0xFF00E676),
      'subtitle': '89% Weight Cleared',
    },
    {
      'id': 'matches',
      'label': 'Matches',
      'targetValue': 64,
      'prefix': '',
      'suffix': ' Pulls',
      'icon': Icons.sports_mma_rounded,
      'accentColor': const Color(0xFFFF2A6D),
      'subtitle': '32 Elimination Bouts',
    },
    {
      'id': 'tables',
      'label': 'Tables',
      'targetValue': 4,
      'prefix': 'Stage ',
      'suffix': ' Arenas',
      'icon': Icons.tab_unselected_rounded,
      'accentColor': AppTheme.goldPrimary,
      'subtitle': 'Active Stage Queues',
    },
    {
      'id': 'referees',
      'label': 'Referees',
      'targetValue': 12,
      'prefix': '',
      'suffix': ' Officials',
      'icon': Icons.gavel_rounded,
      'accentColor': const Color(0xFFA855F7),
      'subtitle': 'Certified PAFF Masters',
    },
    {
      'id': 'prize_pool',
      'label': 'Prize Pool',
      'targetValue': 500000,
      'prefix': 'Rs. ',
      'suffix': '',
      'isCurrency': true,
      'icon': Icons.workspace_premium_rounded,
      'accentColor': const Color(0xFFFFB703),
      'subtitle': 'Cash & Medals Pool',
    },
  ];

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
              // Header Row with Replay Counter Button
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
                          Icons.query_stats_rounded,
                          color: AppTheme.goldPrimary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
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
                itemCount: _statsData.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.5,
                ),
                itemBuilder: (context, index) {
                  final stat = _statsData[index];
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
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF141E2F).withOpacity(0.85),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: accentColor.withOpacity(0.35),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.12),
                  blurRadius: 10,
                  spreadRadius: -2,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Icon & Category Label
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: accentColor.withOpacity(0.3)),
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
                          style: TextStyle(
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
                    color: accentColor.withOpacity(0.9),
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

