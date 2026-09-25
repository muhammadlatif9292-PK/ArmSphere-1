import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/theme/app_theme.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
class TournamentFinishedResultsWidget extends StatefulWidget {
  final Map<String, dynamic> tournament;

  const TournamentFinishedResultsWidget({
    super.key,
    required this.tournament,
  });

  @override
  State<TournamentFinishedResultsWidget> createState() =>
      _TournamentFinishedResultsWidgetState();
}

class _TournamentFinishedResultsWidgetState
    extends State<TournamentFinishedResultsWidget> {

  Map<String, Map<String, dynamic>> _resolvePodium() {
    final rawResults = widget.tournament['results'] ?? widget.tournament['podium'];
    if (rawResults is Map<String, dynamic> && rawResults.containsKey('champion')) {
      return {
        'champion': _normalizePodiumEntry(rawResults['champion'], '1st Place', 'CHAMPION', AppTheme.goldPrimary, 'GOLD MEDAL'),
        'runnerUp': _normalizePodiumEntry(rawResults['runnerUp'], '2nd Place', 'RUNNER UP', const Color(0xFFE2E8F0), 'SILVER MEDAL'),
        'thirdPlace': _normalizePodiumEntry(rawResults['thirdPlace'], '3rd Place', 'THIRD PLACE', const Color(0xFFCD7F32), 'BRONZE MEDAL'),
      };
    }
    if (rawResults is List && rawResults.isNotEmpty) {
      return {
        'champion': _normalizePodiumEntry(rawResults.isNotEmpty ? rawResults[0] : null, '1st Place', 'CHAMPION', AppTheme.goldPrimary, 'GOLD MEDAL'),
        'runnerUp': _normalizePodiumEntry(rawResults.length > 1 ? rawResults[1] : null, '2nd Place', 'RUNNER UP', const Color(0xFFE2E8F0), 'SILVER MEDAL'),
        'thirdPlace': _normalizePodiumEntry(rawResults.length > 2 ? rawResults[2] : null, '3rd Place', 'THIRD PLACE', const Color(0xFFCD7F32), 'BRONZE MEDAL'),
      };
    }
    return {};
  }

  Map<String, dynamic> _normalizePodiumEntry(
    dynamic raw,
    String place,
    String title,
    Color color,
    String badge,
  ) {
    if (raw is Map<String, dynamic>) {
      final athlete = raw['athlete'] is Map<String, dynamic> ? raw['athlete'] : raw;
      final name = athlete['fullName'] ?? athlete['name'] ?? raw['name'] ?? 'TBD';
      final club = athlete['club'] ?? athlete['clubName'] ?? raw['club'] ?? 'Independent';
      final province = athlete['province'] ?? raw['province'] ?? 'PAFF';
      final eloGain = raw['eloGain'] != null
          ? '+${raw['eloGain']} ELO'
          : (raw['points'] != null ? '+${raw['points']} Pts' : 'Ranked');
      final photoUrl = athlete['avatarUrl'] ?? athlete['photoUrl'] ?? raw['photoUrl'] ?? '';
      return {
        'place': place,
        'title': title,
        'name': name.toString(),
        'club': club.toString(),
        'province': province.toString(),
        'eloGain': eloGain.toString(),
        'photoUrl': photoUrl.toString(),
        'color': color,
        'badge': badge,
      };
    }
    return {
      'place': place,
      'title': title,
      'name': 'TBD',
      'club': '—',
      'province': '—',
      'eloGain': '—',
      'photoUrl': '',
      'color': color,
      'badge': badge,
    };
  }

  @override
  Widget build(BuildContext context) {
    final String actualStatus = (widget.tournament['status'] ?? '').toString().toUpperCase();
    final bool isFinished = actualStatus == 'COMPLETED' || actualStatus == 'FINISHED';

    if (!isFinished) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1527).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: const Row(
          children: [
            Icon(Icons.emoji_events_outlined, color: AppTheme.textMuted, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Final results locked until tournament finishes',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final podiumData = _resolvePodium();
    if (podiumData.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1527).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.goldPrimary.withValues(alpha: 0.3)),
        ),
        child: const Column(
          children: [
            Icon(Icons.military_tech_outlined, color: AppTheme.goldPrimary, size: 32),
            SizedBox(height: 8),
            Text(
              'Tournament Completed',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Official verified results are being compiled by PAFF council.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1527).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.goldPrimary.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldPrimary.withValues(alpha: 0.2),
            blurRadius: 24,
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
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
                        AppTheme.goldPrimary.withValues(alpha: 0.35),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Padding(
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
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppTheme.goldPrimary,
                                  Color(0xFFFFB703),
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.goldPrimary.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.emoji_events_rounded,
                              color: Colors.black,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.goldPrimary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.goldPrimary.withValues(alpha: 0.6),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
                          data: podiumData['runnerUp']!,
                          trophyIcon: Icons.military_tech_rounded,
                          heightPadding: 0,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 1st Place (Champion) - Center (Elevated with Gold Light)
                      Expanded(
                        child: _buildPodiumColumn(
                          data: podiumData['champion']!,
                          trophyIcon: Icons.emoji_events_rounded,
                          heightPadding: 16,
                          isChampion: true,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 3rd Place - Right
                      Expanded(
                        child: _buildPodiumColumn(
                          data: podiumData['thirdPlace']!,
                          trophyIcon: Icons.workspace_premium_rounded,
                          heightPadding: 0,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Post-Tournament Stats Row (Top Performer, Total Matches, Status)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141E2F).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.goldPrimary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildResultsStatTile(
                            'CHAMPION',
                            podiumData['champion']?['name'] ?? 'TBD',
                            podiumData['champion']?['club'] ?? 'Winner',
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
                            '${widget.tournament['matchCount'] ?? widget.tournament['matches']?.length ?? '—'} Bouts',
                            'Official Results',
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
                            'FEDERATION',
                            'PAFF CERTIFIED',
                            'Verified Record',
                            Icons.verified_rounded,
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
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.goldPrimary,
                            Color(0xFFFFB703),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.goldPrimary.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF141E2F).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: isChampion ? 0.9 : 0.4),
                width: isChampion ? 1.8 : 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: isChampion ? 0.3 : 0.1),
                  blurRadius: isChampion ? 14 : 8,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Column(
              children: [
                // Trophy Icon with Glow
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.6)),
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
                      backgroundColor: color.withValues(alpha: 0.2),
                      backgroundImage: (data['photoUrl'] as String).isNotEmpty
                          ? NetworkImage(data['photoUrl'] as String)
                          : null,
                      child: (data['photoUrl'] as String).isEmpty
                          ? Text(
                              (data['name'] as String).isNotEmpty
                                  ? (data['name'] as String)[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: isChampion ? 16 : 13,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
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
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 8.5,
                    color: AppTheme.textMuted,
                  ),
                ),

                const SizedBox(height: 6),

                // ELO Gain Tag
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
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
              const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.goldPrimary,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.goldPrimary.withValues(alpha: 0.35),
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
                        const Row(
                          children: [
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
                        Text(
                          '${(widget.tournament['name'] ?? 'TOURNAMENT').toString().toUpperCase()} STANDINGS',
                          style: const TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.goldPrimary,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 10),

                        ..._buildDynamicModalStandings(),

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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF141E2F),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
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

  List<Widget> _buildDynamicModalStandings() {
    final raw = widget.tournament['standings'] ?? widget.tournament['results'];
    if (raw is List && raw.isNotEmpty) {
      return raw.asMap().entries.map((entry) {
        final idx = entry.key;
        final item = entry.value is Map<String, dynamic>
            ? entry.value as Map<String, dynamic>
            : <String, dynamic>{};
        final rank = item['rank']?.toString() ??
            '${idx + 1}${idx == 0 ? "ST" : (idx == 1 ? "ND" : (idx == 2 ? "RD" : "TH"))}';
        final name = item['name'] ?? item['athleteName'] ?? item['fullName'] ?? 'Athlete';
        final club = item['club'] ?? item['clubName'] ?? 'PAFF Affiliate';
        final score = item['score'] ?? item['record'] ?? '${item['wins'] ?? 0}-${item['losses'] ?? 0} Bouts';
        final color = idx == 0
            ? AppTheme.goldPrimary
            : (idx == 1
                ? const Color(0xFFE2E8F0)
                : (idx == 2 ? const Color(0xFFCD7F32) : Colors.white54));
        final medal = idx == 0
            ? '🥇 GOLD'
            : (idx == 1 ? '🥈 SILVER' : (idx == 2 ? '🥉 BRONZE' : 'FINALIST'));

        return _buildModalStandingRow(
          rank: rank,
          name: name.toString(),
          club: club.toString(),
          score: score.toString(),
          color: color,
          medal: medal,
        );
      }).toList();
    }
    return [
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        alignment: Alignment.center,
        child: const Text(
          'Official bracket standings are currently being certified.',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 11,
            color: AppTheme.textMuted,
          ),
        ),
      ),
    ];
  }
}

