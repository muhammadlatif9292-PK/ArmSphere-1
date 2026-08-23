import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
class RulebookAccordionWidget extends StatefulWidget {
  final Map<String, dynamic> tournament;

  const RulebookAccordionWidget({
    Key? key,
    required this.tournament,
  }) : super(key: key);

  @override
  State<RulebookAccordionWidget> createState() => _RulebookAccordionWidgetState();
}

class _RulebookAccordionWidgetState extends State<RulebookAccordionWidget> {
  final Map<int, bool> _expandedState = {
    0: false, // Competition Rules
    1: false, // Equipment
    2: false, // Scoring
    3: false, // Fouls
    4: false, // Conduct
    5: false, // Anti-Doping
    6: false, // Disputes
  };

  final List<Map<String, dynamic>> _ruleSections = [
    {
      'title': 'Competition Rules',
      'icon': Icons.gavel_rounded,
      'badge': 'IFA / WAF STANDARDS',
      'accentColor': AppTheme.goldPrimary,
      'content': [
        '• Standard IFA / WAF double-elimination bracket format applied to all weight classes.',
        '• Matches are best-of-3 pins for Finals; single pin for preliminary qualifiers.',
        '• Competitors must line up wrists in center position with thumb knuckle visible.',
        '• Ready-Go signal by referee must be met without pre-pressure or false starts.',
        '• Strap match enforced automatically if competitors slip out without a foul.',
      ],
    },
    {
      'title': 'Equipment Specifications',
      'icon': Icons.straighten_rounded,
      'badge': 'PAFF CERTIFIED',
      'accentColor': const Color(0xFF00E5FF),
      'content': [
        '• Official PAFF Tournament Tables: 28-inch pin lines, 7x7 inch elbow pads.',
        '• Touch pad height 4 inches above table level; standard 1-inch diameter hand pegs.',
        '• Official competition wrist straps provided by referee at table.',
        '• Magnesium carbonate liquid chalk provided at athlete prep stations.',
      ],
    },
    {
      'title': 'Scoring System',
      'icon': Icons.scoreboard_rounded,
      'badge': 'PIN LINE VALIDATION',
      'accentColor': const Color(0xFF00E676),
      'content': [
        '• A pin occurs when any part of competitor\'s wrist or fingers breaks the pin pad plane.',
        '• Referee call is final; instant video replay panel available for contested finals.',
        '• Slipping under tension results in immediate strap application without foul.',
        '• Two warnings equal one official foul; two fouls equal loss of match.',
      ],
    },
    {
      'title': 'Fouls & Penalties',
      'icon': Icons.warning_amber_rounded,
      'badge': 'PENALTY CODES',
      'accentColor': const Color(0xFFFF2A6D),
      'content': [
        '• Elbow Foul: Lifting elbow completely off pad during match progression.',
        '• Intentional Slip: Deliberately breaking grip when in losing position.',
        '• Early Start: Moving before referee utters "GO" in Ready-Go command.',
        '• Dangerous Position: Turning head away from arm or dipping shoulder below table level.',
      ],
    },
    {
      'title': 'Athlete Conduct',
      'icon': Icons.verified_user_rounded,
      'badge': 'SPORTSMANSHIP CODE',
      'accentColor': Colors.purpleAccent,
      'content': [
        '• Respect for referees, table marshals, and opposing competitors is mandatory.',
        '• Unsportsmanlike conduct or aggressive verbal abuse leads to instant disqualification.',
        '• Uniform Code: Official team jersey or plain compression wear; athletic shoes mandatory.',
      ],
    },
    {
      'title': 'Anti-Doping Policy',
      'icon': Icons.health_and_safety_rounded,
      'badge': 'WADA COMPLIANT',
      'accentColor': Colors.lightBlueAccent,
      'content': [
        '• Strict compliance with WADA Prohibited List for competitive armwrestling.',
        '• Random urine sample testing conducted on podium medalists post-event.',
        '• Refusal to submit to testing leads to automatic 2-year PAFF suspension.',
      ],
    },
    {
      'title': 'Dispute Resolution',
      'icon': Icons.policy_rounded,
      'badge': 'APPEALS COMMITTEE',
      'accentColor': Colors.orangeAccent,
      'content': [
        '• Formal protest must be lodged within 15 minutes of match conclusion.',
        '• Protest Fee: PKR 5,000 / \$5\$10 USD refundable if appeal is upheld by jury panel.',
        '• Jury consists of Head Referee, PAFF Technical Delegate, and Neutral Official.',
      ],
    },
  ];

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
            // Header Title
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
                        Icons.menu_book_rounded,
                        color: AppTheme.goldPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'OFFICIAL RULEBOOK & GOVERNANCE',
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
                          '7 Interactive Regulations & Standards',
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
                    color: AppTheme.goldPrimary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.5)),
                  ),
                  child: const Text(
                    'IFA 2026',
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.goldPrimary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Accordion Cards List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _ruleSections.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final section = _ruleSections[index];
                final bool isExpanded = _expandedState[index] ?? false;
                final Color accent = section['accentColor'] as Color;

                return Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF1E2B47).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isExpanded ? accent : Colors.white12,
                      width: isExpanded ? 1.2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Tile Header Clickable Bar
                      InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _expandedState[index] = !isExpanded;
                          });
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Icon(section['icon'] as IconData, size: 18, color: accent),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  section['title'] as String,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: accent.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: accent.withOpacity(0.4)),
                                ),
                                child: Text(
                                  section['badge'] as String,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.w900,
                                    color: accent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              AnimatedRotation(
                                turns: isExpanded ? 0.5 : 0.0,
                                duration: const Duration(milliseconds: 250),
                                child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 20),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Expandable Smooth Animated Content
                      AnimatedCrossFade(
                        firstChild: const SizedBox(width: double.infinity),
                        secondChild: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(color: Colors.white10),
                              const SizedBox(height: 6),
                              ...(section['content'] as List<String>).map((line) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      line,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.white70,
                                        height: 1.35,
                                      ),
                                    ),
                                  )),
                            ],
                          ),
                        ),
                        crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 250),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 18),

            // Download Rulebook Button
            TactilePressWrapper(
              onTap: () {
                HapticFeedback.mediumImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✓ Downloading PAFF Official Tournament Rulebook 2026 (PDF - 2.4 MB)...'),
                    backgroundColor: AppTheme.goldPrimary,
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [AppTheme.goldPrimary, Color(0xFFFFC107)],
                  ),
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
                    Icon(Icons.file_download_rounded, size: 18, color: Colors.black),
                    SizedBox(width: 8),
                    Text(
                      'DOWNLOAD COMPLETE RULEBOOK (PDF)',
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
}


// ============================================================================
// PART 13 — DOCUMENTS (Premium Download Section with Material Animation)
// ============================================================================

