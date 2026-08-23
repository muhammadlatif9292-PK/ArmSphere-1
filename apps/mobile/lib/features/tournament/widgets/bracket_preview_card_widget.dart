import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../core/widgets/pulse_indicator.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
class BracketPreviewCardWidget extends StatelessWidget {
  final Map<String, dynamic> tournament;

  const BracketPreviewCardWidget({
    Key? key,
    required this.tournament,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool hasBrackets = tournament['hasBrackets'] ?? true;

    if (!hasBrackets) {
      return const SizedBox();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Color(0xFF00E5FF).withOpacity(0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0xFF00E5FF).withOpacity(0.08),
            blurRadius: 22,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20.0),
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
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF00E5FF).withOpacity(0.18),
                        shape: BoxShape.circle,
                        border: Border.all(color: Color(0xFF00E5FF).withOpacity(0.5)),
                      ),
                      child: Icon(
                        Icons.account_tree_rounded,
                        color: Color(0xFF00E5FF),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'LIVE BRACKET PREVIEW',
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
                          'Senior Men -80kg Right Arm Division',
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
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFF00E676).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(0xFF00E676).withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      PulseIndicator(size: 5.0, color: Color(0xFF00E676)),
                      SizedBox(width: 4),
                      Text(
                        'SEEDED',
                        style: TextStyle(
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
                    value: 'Semi Finals',
                    icon: Icons.sports_mma_rounded,
                    accentColor: AppTheme.goldPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSummaryBox(
                    label: 'REMAINING MATCHES',
                    value: '3 Matches',
                    icon: Icons.timer_outlined,
                    accentColor: const Color(0xFFFF2A6D),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSummaryBox(
                    label: 'YOUR POSITION',
                    value: 'Match #42',
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
                child: Column(
                  children: [
                    _buildMiniMatchRow('1. Usman Khan (Seed #1)', '2', 'Zain Ul-Abidin (Seed #2)', '1', isLive: true),
                    const Divider(color: Colors.white12, height: 16),
                    _buildMiniMatchRow('3. Bilal Butt (Seed #3)', '2', 'Hamza Tariq (Seed #4)', '0', isLive: false),
                  ],
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
                padding: EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF00B0FF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF00E5FF).withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
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

  Widget _buildSummaryBox({
    required String label,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Color(0xFF1E293B).withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.3)),
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
                  Text(p1, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(s1, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(p2, style: TextStyle(fontSize: 10.5, color: Colors.white70)),
                  Text(s2, style: TextStyle(fontSize: 10.5, color: Colors.white70)),
                ],
              ),
            ],
          ),
        ),
        if (isLive) ...[
          const SizedBox(width: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Color(0xFFFF2A6D).withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFF2A6D)),
            ),
            child: const Text('LIVE NOW', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFFFF2A6D))),
          ),
        ],
      ],
    );
  }

  void _showFullLiveBracketModal(BuildContext context) {
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
                Row(
                  children: const [
                    Icon(Icons.account_tree_rounded, color: Color(0xFF00E5FF)),
                    SizedBox(width: 8),
                    Text(
                      'SCREEN 6 — LIVE TOURNAMENT BRACKET',
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
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text(
                            'DOUBLE ELIMINATION BRACKET (SENIOR MEN -80KG)',
                            style: TextStyle(color: AppTheme.goldPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _buildBracketColumn('QUARTER FINALS', ['Usman Khan vs Saad Ahmed', 'Zain Ul-Abidin vs Tariq Mahmud', 'Bilal Butt vs Raza Ali', 'Hamza Tariq vs Imran Shah']),
                              const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 30),
                              _buildBracketColumn('SEMI FINALS', ['Usman Khan vs Zain Ul-Abidin', 'Bilal Butt vs Hamza Tariq']),
                              const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 30),
                              _buildBracketColumn('GOLD FINAL', ['Usman Khan vs TBD']),
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

