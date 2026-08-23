import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
class TournamentFinishedResultsWidget extends StatefulWidget {
  final Map<String, dynamic> tournament;

  const TournamentFinishedResultsWidget({
    Key? key,
    required this.tournament,
  }) : super(key: key);

  @override
  State<TournamentFinishedResultsWidget> createState() =>
      _TournamentFinishedResultsWidgetState();
}

class _TournamentFinishedResultsWidgetState
    extends State<TournamentFinishedResultsWidget> {
  // Toggle for testing/previewing finished status
  bool _forceFinishedView = true;

  final Map<String, dynamic> _podiumData = {
    'champion': {
      'place': '1st Place',
      'title': 'CHAMPION',
      'name': 'Tariq Zafar',
      'club': 'Lahore Iron Grip',
      'province': 'Punjab',
      'eloGain': '+85 ELO',
      'photoUrl':
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=300',
      'color': AppTheme.goldPrimary,
      'badge': 'GOLD MEDAL',
    },
    'runnerUp': {
      'place': '2nd Place',
      'title': 'RUNNER UP',
      'name': 'Bilal Khan',
      'club': 'Peshawar Titans',
      'province': 'KPK',
      'eloGain': '+52 ELO',
      'photoUrl':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=300',
      'color': const Color(0xFFE2E8F0),
      'badge': 'SILVER MEDAL',
    },
    'thirdPlace': {
      'place': '3rd Place',
      'title': 'THIRD PLACE',
      'name': 'Usman Raza',
      'club': 'Capital Power',
      'province': 'Islamabad',
      'eloGain': '+34 ELO',
      'photoUrl':
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&q=80&w=300',
      'color': const Color(0xFFCD7F32),
      'badge': 'BRONZE MEDAL',
    },
  };

  @override
  Widget build(BuildContext context) {
    final String actualStatus = widget.tournament['status'] ?? 'COMPLETED';
    final bool isFinished = actualStatus == 'COMPLETED' || _forceFinishedView;

    if (!isFinished) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Color(0xFF0D1527).withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(Icons.emoji_events_outlined, color: AppTheme.textMuted, size: 18),
                SizedBox(width: 8),
                Text(
                  'Final results locked until tournament finishes',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _forceFinishedView = true;
                });
              },
              child: const Text(
                'PREVIEW',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.goldPrimary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xFF0D1527).withOpacity(0.95),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.goldPrimary.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldPrimary.withOpacity(0.2),
            blurRadius: 24,
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Gold Shimmer Lighting Effect at Top Center
            Positioned(
              top: -50,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 180,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.goldPrimary.withOpacity(0.35),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Padding(
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
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.goldPrimary,
                                  Color(0xFFFFB703),
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.goldPrimary.withOpacity(0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.emoji_events_rounded,
                              color: Colors.black,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'OFFICIAL FINAL RESULTS',
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
                                'PAFF Certified Podium & Final Rankings',
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

                      // Status Badge
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.goldPrimary.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.goldPrimary.withOpacity(0.6),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.workspace_premium_rounded,
                              size: 12,
                              color: AppTheme.goldPrimary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'FINISHED',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.goldPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Trophy Podium Layout (Runner-Up 2nd, Champion 1st, 3rd Place)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // 2nd Place (Runner Up) - Left
                      Expanded(
                        child: _buildPodiumColumn(
                          data: _podiumData['runnerUp']!,
                          trophyIcon: Icons.military_tech_rounded,
                          heightPadding: 0,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 1st Place (Champion) - Center (Elevated with Gold Light)
                      Expanded(
                        child: _buildPodiumColumn(
                          data: _podiumData['champion']!,
                          trophyIcon: Icons.emoji_events_rounded,
                          heightPadding: 16,
                          isChampion: true,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 3rd Place - Right
                      Expanded(
                        child: _buildPodiumColumn(
                          data: _podiumData['thirdPlace']!,
                          trophyIcon: Icons.workspace_premium_rounded,
                          heightPadding: 0,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Post-Tournament Stats Row (Top ELO Gain, Total Matches, Avg Duration)
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF141E2F).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.goldPrimary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildResultsStatTile(
                            'TOP ELO GAIN',
                            '+85 ELO',
                            'Tariq Zafar',
                            Icons.bolt_rounded,
                            AppTheme.goldPrimary,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.white12,
                        ),
                        Expanded(
                          child: _buildResultsStatTile(
                            'TOTAL MATCHES',
                            '64 Bouts',
                            '32 Bracket Ties',
                            Icons.sports_mma_rounded,
                            const Color(0xFF00E5FF),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.white12,
                        ),
                        Expanded(
                          child: _buildResultsStatTile(
                            'AVG DURATION',
                            '18.4s',
                            'per match',
                            Icons.timer_rounded,
                            const Color(0xFF00E676),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // View Complete Results Button
                  TactilePressWrapper(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _showCompleteResultsModal(context);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.goldPrimary,
                            Color(0xFFFFB703),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.goldPrimary.withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.leaderboard_rounded,
                            color: Colors.black,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'VIEW COMPLETE RESULTS',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodiumColumn({
    required Map<String, dynamic> data,
    required IconData trophyIcon,
    required double heightPadding,
    bool isChampion = false,
  }) {
    final Color color = data['color'] as Color;

    return Column(
      children: [
        SizedBox(height: isChampion ? 0 : 16),
        TactilePressWrapper(
          onTap: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '🏆 ${data['place']}: ${data['name']} (${data['club']}) - ${data['eloGain']}',
                ),
                backgroundColor: color,
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color(0xFF141E2F).withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withOpacity(isChampion ? 0.9 : 0.4),
                width: isChampion ? 1.8 : 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(isChampion ? 0.3 : 0.1),
                  blurRadius: isChampion ? 14 : 8,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Column(
              children: [
                // Trophy Icon with Glow
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withOpacity(0.6)),
                  ),
                  child: Icon(
                    trophyIcon,
                    size: isChampion ? 22 : 18,
                    color: color,
                  ),
                ),

                const SizedBox(height: 8),

                // Athlete Image Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: isChampion ? 24 : 20,
                      backgroundImage: NetworkImage(data['photoUrl']),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.star_rounded,
                          size: 10,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Title & Name
                Text(
                  data['title'],
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data['name'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: isChampion ? 12 : 10.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  data['club'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 8.5,
                    color: AppTheme.textMuted,
                  ),
                ),

                const SizedBox(height: 6),

                // ELO Gain Tag
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Text(
                    data['eloGain'],
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsStatTile(
      String label, String value, String sub, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 7.5,
            fontWeight: FontWeight.w800,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  void _showCompleteResultsModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.goldPrimary,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.goldPrimary.withOpacity(0.35),
                  blurRadius: 24,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Modal Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E293B),
                      border: Border(
                        bottom: BorderSide(color: Colors.white12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.emoji_events_rounded,
                              color: AppTheme.goldPrimary,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'OFFICIAL BRACKET STANDINGS',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Modal Content - Medal Tally & Class Standings
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SENIOR -80KG DIVISION STANDINGS',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.goldPrimary,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 10),

                        _buildModalStandingRow(
                          rank: '1ST',
                          name: 'Tariq Zafar',
                          club: 'Lahore Iron Grip',
                          score: '5-0 Bouts',
                          color: AppTheme.goldPrimary,
                          medal: '🥇 GOLD',
                        ),
                        _buildModalStandingRow(
                          rank: '2ND',
                          name: 'Bilal Khan',
                          club: 'Peshawar Titans',
                          score: '4-1 Bouts',
                          color: const Color(0xFFE2E8F0),
                          medal: '🥈 SILVER',
                        ),
                        _buildModalStandingRow(
                          rank: '3RD',
                          name: 'Usman Raza',
                          club: 'Capital Power Gym',
                          score: '4-2 Bouts',
                          color: const Color(0xFFCD7F32),
                          medal: '🥉 BRONZE',
                        ),
                        _buildModalStandingRow(
                          rank: '4TH',
                          name: 'Zain Ul-Abedin',
                          club: 'Steel Arm Academy',
                          score: '3-2 Bouts',
                          color: Colors.white54,
                          medal: 'SEMI FINAL',
                        ),

                        const SizedBox(height: 18),

                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.goldPrimary,
                            foregroundColor: Colors.black,
                            minimumSize: const Size(double.infinity, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('📄 Exporting Official PDF Standings Certificate...'),
                                backgroundColor: AppTheme.goldPrimary,
                              ),
                            );
                          },
                          icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                          label: const Text(
                            'EXPORT OFFICIAL CERTIFICATES',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontWeight: FontWeight.w900,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalStandingRow({
    required String rank,
    required String name,
    required String club,
    required String score,
    required Color color,
    required String medal,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Color(0xFF141E2F),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              rank,
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text(
                  club,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 9.5,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                medal,
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              Text(
                score,
                style: const TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 8.5,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

