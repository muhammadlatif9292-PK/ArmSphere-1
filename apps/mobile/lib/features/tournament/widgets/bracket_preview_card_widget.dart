import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/theme/app_theme.dart';
import '../../../core/widgets/pulse_indicator.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
class BracketPreviewCardWidget extends StatelessWidget {
  final Map<String, dynamic> tournament;

  const BracketPreviewCardWidget({
    super.key,
    required this.tournament,
  });

  @override
  Widget build(BuildContext context) {
    final hasBrackets = tournament['bracket'] != null ||
        tournament['matches'] != null ||
        (tournament['hasBrackets'] == true);

    if (!hasBrackets && (tournament['status'] ?? '').toString().toUpperCase() != 'LIVE') {
      return const SizedBox();
    }

    final division = tournament['category'] ?? tournament['division'] ?? 'Official Championship Division';
    final currentRound = tournament['currentRound']?.toString() ?? 'Tournament Draw';
    final remaining = tournament['remainingMatches']?.toString() ??
        (tournament['totalMatches'] != null ? '${tournament['totalMatches']} Matches' : 'Bouts In Progress');
    final position = tournament['userMatchPosition']?.toString() ??
        (tournament['userRegistration']?['athleteNumber'] != null ? 'Athlete #${tournament['userRegistration']['athleteNumber']}' : 'Official Draw');

    final miniMatches = _resolveMiniMatches();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.08),
            blurRadius: 22,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.5)),
                      ),
                      child: const Icon(
                        Icons.account_tree_rounded,
                        color: Color(0xFF00E5FF),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'LIVE BRACKET PREVIEW',
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
                          division,
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PulseIndicator(size: 5.0, color: Color(0xFF00E676)),
                      const SizedBox(width: 4),
                      Text(
                        miniMatches.isNotEmpty ? 'ACTIVE' : 'SEEDED',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF00E676),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Bracket Summary Quick Stats
            Row(
              children: [
                Expanded(
                  child: _buildSummaryBox(
                    label: 'CURRENT ROUND',
                    value: currentRound,
                    icon: Icons.sports_mma_rounded,
                    accentColor: AppTheme.goldPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSummaryBox(
                    label: 'MATCH STATUS',
                    value: remaining,
                    icon: Icons.timer_outlined,
                    accentColor: const Color(0xFFFF2A6D),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSummaryBox(
                    label: 'YOUR POSITION',
                    value: position,
                    icon: Icons.person_pin_circle_rounded,
                    accentColor: const Color(0xFF00E676),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Mini Bracket Graphic Box
            Hero(
              tag: 'tournament_bracket_preview',
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF131D33),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: miniMatches.isNotEmpty
                    ? Column(
                        children: [
                          for (int i = 0; i < miniMatches.length; i++) ...[
                            if (i > 0) const Divider(color: Colors.white12, height: 16),
                            _buildMiniMatchRow(
                              miniMatches[i]['p1'] as String,
                              miniMatches[i]['s1'] as String,
                              miniMatches[i]['p2'] as String,
                              miniMatches[i]['s2'] as String,
                              isLive: miniMatches[i]['isLive'] as bool,
                            ),
                          ],
                        ],
                      )
                    : const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.account_tree_outlined, color: Colors.white24, size: 28),
                              SizedBox(height: 6),
                              Text(
                                'Official bracket pairings will populate after weigh-in lock.',
                                style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 18),

            // Tap to open full screen live brackets
            TactilePressWrapper(
              onTap: () {
                HapticFeedback.mediumImpact();
                _showFullLiveBracketModal(context);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF00B0FF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.account_tree_rounded, size: 18, color: Colors.black),
                    SizedBox(width: 8),
                    Text(
                      'OPEN FULL INTERACTIVE BRACKETS',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _resolveMiniMatches() {
    final matches = tournament['matches'] ?? tournament['featuredMatches'];
    if (matches is List && matches.isNotEmpty) {
      return matches.take(3).map<Map<String, dynamic>>((m) {
        if (m is! Map) return <String, dynamic>{};
        final p1 = m['participant1Name'] ?? m['athlete1'] ?? m['p1Name'] ?? 'Contender 1';
        final p2 = m['participant2Name'] ?? m['athlete2'] ?? m['p2Name'] ?? 'Contender 2';
        final s1 = (m['score1'] ?? m['scoreP1'] ?? '-').toString();
        final s2 = (m['score2'] ?? m['scoreP2'] ?? '-').toString();
        final isLive = (m['status'] ?? '').toString().toUpperCase() == 'LIVE' ||
            (m['status'] ?? '').toString().toUpperCase() == 'IN_PROGRESS';
        return {
          'p1': p1.toString(),
          's1': s1,
          'p2': p2.toString(),
          's2': s2,
          'isLive': isLive,
        };
      }).where((m) => m.isNotEmpty).toList();
    }
    return [];
  }

  Widget _buildSummaryBox({
    required String label,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: accentColor),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 7.5,
              fontWeight: FontWeight.w800,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMatchRow(
    String p1,
    String s1,
    String p2,
    String s2, {
    required bool isLive,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(p1, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(s1, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(p2, style: const TextStyle(fontSize: 10.5, color: Colors.white70)),
                  Text(s2, style: const TextStyle(fontSize: 10.5, color: Colors.white70)),
                ],
              ),
            ],
          ),
        ),
        if (isLive) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFF2A6D).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFF2A6D)),
            ),
            child: const Text('LIVE NOW', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFFFF2A6D))),
          ),
        ],
      ],
    );
  }

  Map<String, List<String>> _resolveBracketColumns() {
    final bracket = tournament['bracket'];
    if (bracket is Map) {
      final result = <String, List<String>>{};
      bracket.forEach((key, val) {
        if (val is List) {
          result[key.toString().toUpperCase()] = val.map((m) {
            if (m is Map) {
              final p1 = m['participant1Name'] ?? m['athlete1'] ?? m['p1'] ?? 'TBD';
              final p2 = m['participant2Name'] ?? m['athlete2'] ?? m['p2'] ?? 'TBD';
              return '$p1 vs $p2';
            }
            return m.toString();
          }).toList();
        }
      });
      if (result.isNotEmpty) return result;
    }

    final matches = tournament['matches'];
    if (matches is List && matches.isNotEmpty) {
      final rounds = <String, List<String>>{};
      for (final m in matches) {
        if (m is! Map) continue;
        final roundName = (m['round'] ?? m['stage'] ?? 'ROUND 1').toString().toUpperCase();
        final p1 = m['participant1Name'] ?? m['athlete1'] ?? 'TBD';
        final p2 = m['participant2Name'] ?? m['athlete2'] ?? 'TBD';
        rounds.putIfAbsent(roundName, () => []).add('$p1 vs $p2');
      }
      if (rounds.isNotEmpty) return rounds;
    }

    return {};
  }

  void _showFullLiveBracketModal(BuildContext context) {
    final bracketColumns = _resolveBracketColumns();
    final divisionTitle = (tournament['category'] ?? tournament['division'] ?? 'CHAMPIONSHIP BRACKET').toString().toUpperCase();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.82,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.account_tree_rounded, color: Color(0xFF00E5FF)),
                    SizedBox(width: 8),
                    Text(
                      'LIVE TOURNAMENT BRACKET',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(color: Colors.white12),
            Expanded(
              child: bracketColumns.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_tree_outlined, size: 48, color: Colors.white24),
                          SizedBox(height: 12),
                          Text(
                            'Interactive Bracket Pending Official Seeding',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Matchups will appear here as soon as bracket draws are published.',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    )
                  : Center(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text(
                                  divisionTitle,
                                  style: const TextStyle(color: AppTheme.goldPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    for (int i = 0; i < bracketColumns.entries.length; i++) ...[
                                      if (i > 0)
                                        const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 30),
                                      _buildBracketColumn(
                                        bracketColumns.entries.elementAt(i).key,
                                        bracketColumns.entries.elementAt(i).value,
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBracketColumn(String title, List<String> matches) {
    return Container(
      width: 180,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.textMuted)),
          const SizedBox(height: 8),
          ...matches.map((m) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(m, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
              )),
        ],
      ),
    );
  }
}


// ============================================================================
// PART 11 — LIVE STREAM (Official YouTube Live Broadcast Module)
// ============================================================================

