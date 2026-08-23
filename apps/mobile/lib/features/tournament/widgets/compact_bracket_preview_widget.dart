import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
import 'bracket_lines_painter.dart';
import 'bracket_match_data.dart';
import 'full_interactive_bracket_modal.dart';
class CompactBracketPreviewWidget extends StatefulWidget {
  final Map<String, dynamic> tournament;

  const CompactBracketPreviewWidget({
    Key? key,
    required this.tournament,
  }) : super(key: key);

  @override
  State<CompactBracketPreviewWidget> createState() => _CompactBracketPreviewWidgetState();
}

class _CompactBracketPreviewWidgetState extends State<CompactBracketPreviewWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _lineAnimationController;
  late Animation<double> _linePulse;

  @override
  void initState() {
    super.initState();
    _lineAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _linePulse = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _lineAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _lineAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tourneyId = widget.tournament['id'] ?? 'tourney_default';

    return Hero(
      tag: 'tournament_bracket_preview_hero_$tourneyId',
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Color(0xFF0D1527).withOpacity(0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Color(0xFF00E5FF).withOpacity(0.4),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF00E5FF).withOpacity(0.12),
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
                              color: Color(0xFF00E5FF).withOpacity(0.18),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Color(0xFF00E5FF).withOpacity(0.5),
                              ),
                            ),
                            child: Icon(
                              Icons.account_tree_rounded,
                              color: Color(0xFF00E5FF),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'BRACKET PREVIEW',
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
                                'Senior Men Right -80kg • Double Elimination',
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
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                            Icon(Icons.stars_rounded, size: 12, color: AppTheme.goldPrimary),
                            SizedBox(width: 4),
                            Text(
                              'MATCH #42 NEXT',
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

                  const SizedBox(height: 14),

                  // User Highlighted Next Match Alert Banner
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.goldPrimary.withOpacity(0.25),
                          Color(0xFF00E5FF).withOpacity(0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.goldPrimary.withOpacity(0.6),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: AppTheme.goldPrimary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_pin_circle_rounded,
                            size: 14,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'YOUR POSITION HIGHLIGHTED',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.goldPrimary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Tariq Z. (YOU) vs. Zain U. (OPPONENT) • Semi-Finals',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Horizontal Bracket Stages Columns with Animated Line Painter
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _openFullBracketModal(context);
                    },
                    child: AnimatedBuilder(
                      animation: _linePulse,
                      builder: (context, child) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            child: CustomPaint(
                              foregroundPainter: BracketLinesPainter(
                                pulseValue: _linePulse.value,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Quarter Finals Stage Column
                                  _buildStageColumn(
                                    stageTitle: 'QUARTER FINALS',
                                    matches: [
                                      BracketMatchData(
                                        p1: 'Tariq Z. (YOU)',
                                        s1: '2',
                                        p2: 'Bilal K.',
                                        s2: '0',
                                        isUserMatch: true,
                                        isOpponentMatch: false,
                                        isFinished: true,
                                      ),
                                      BracketMatchData(
                                        p1: 'Zain U.',
                                        s1: '2',
                                        p2: 'Hamza S.',
                                        s2: '1',
                                        isUserMatch: false,
                                        isOpponentMatch: true,
                                        isFinished: true,
                                      ),
                                      BracketMatchData(
                                        p1: 'Usman R.',
                                        s1: '2',
                                        p2: 'Faisal M.',
                                        s2: '0',
                                        isUserMatch: false,
                                        isOpponentMatch: false,
                                        isFinished: true,
                                      ),
                                      BracketMatchData(
                                        p1: 'Ali N.',
                                        s1: '2',
                                        p2: 'Danish A.',
                                        s2: '1',
                                        isUserMatch: false,
                                        isOpponentMatch: false,
                                        isFinished: true,
                                      ),
                                    ],
                                  ),

                                  const SizedBox(width: 32),

                                  // Semi Finals Stage Column
                                  _buildStageColumn(
                                    stageTitle: 'SEMI FINALS',
                                    matches: [
                                      BracketMatchData(
                                        p1: 'Tariq Z. (YOU)',
                                        s1: '-',
                                        p2: 'Zain U. (OPPONENT)',
                                        s2: '-',
                                        isUserMatch: true,
                                        isOpponentMatch: true,
                                        isLiveNext: true,
                                      ),
                                      BracketMatchData(
                                        p1: 'Usman R.',
                                        s1: '-',
                                        p2: 'Ali N.',
                                        s2: '-',
                                        isUserMatch: false,
                                        isOpponentMatch: false,
                                        isUpcoming: true,
                                      ),
                                    ],
                                  ),

                                  const SizedBox(width: 32),

                                  // Final Stage Column
                                  _buildStageColumn(
                                    stageTitle: 'FINAL',
                                    matches: [
                                      BracketMatchData(
                                        p1: 'TBD (Semi 1 Winner)',
                                        s1: '-',
                                        p2: 'TBD (Semi 2 Winner)',
                                        s2: '-',
                                        isUserMatch: false,
                                        isOpponentMatch: false,
                                        isTbd: true,
                                      ),
                                    ],
                                  ),

                                  const SizedBox(width: 32),

                                  // Champion Slot Column
                                  _buildChampionSlotColumn(),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Open Full Bracket Interactive Button
                  TactilePressWrapper(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _openFullBracketModal(context);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 11, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Color(0xFF00E5FF).withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.zoom_in_rounded, size: 16, color: Color(0xFF00E5FF)),
                          SizedBox(width: 8),
                          Text(
                            'OPEN FULL INTERACTIVE BRACKET',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF00E5FF),
                              letterSpacing: 0.6,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Color(0xFF00E5FF)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStageColumn({
    required String stageTitle,
    required List<BracketMatchData> matches,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF162032),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white12),
          ),
          child: Text(
            stageTitle,
            style: const TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              color: AppTheme.textMuted,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Column(
          children: matches.map((match) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: _buildCompactMatchCard(match),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCompactMatchCard(BracketMatchData match) {
    Color cardBg = const Color(0xFF141E2F);
    Color borderColor = Colors.white12;
    double borderWidth = 1.0;

    if (match.isLiveNext) {
      cardBg = const Color(0xFF1F2937);
      borderColor = AppTheme.goldPrimary;
      borderWidth = 1.5;
    } else if (match.isUserMatch) {
      borderColor = Color(0xFF00E5FF).withOpacity(0.8);
    } else if (match.isOpponentMatch) {
      borderColor = Color(0xFFFF2A6D).withOpacity(0.8);
    }

    return Container(
      width: 155,
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: match.isLiveNext
            ? [
                BoxShadow(
                  color: AppTheme.goldPrimary.withOpacity(0.2),
                  blurRadius: 8,
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Player 1 Slot
          _buildPlayerSlot(
            name: match.p1,
            score: match.s1,
            isUser: match.p1.contains('YOU'),
            isOpponent: match.p1.contains('OPPONENT'),
          ),
          const SizedBox(height: 4),
          Container(height: 1, color: Colors.white12),
          const SizedBox(height: 4),
          // Player 2 Slot
          _buildPlayerSlot(
            name: match.p2,
            score: match.s2,
            isUser: match.p2.contains('YOU'),
            isOpponent: match.p2.contains('OPPONENT'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerSlot({
    required String name,
    required String score,
    required bool isUser,
    required bool isOpponent,
  }) {
    Color textColor = Colors.white;
    FontWeight fontWeight = FontWeight.w600;

    if (isUser) {
      textColor = AppTheme.goldPrimary;
      fontWeight = FontWeight.w900;
    } else if (isOpponent) {
      textColor = const Color(0xFF00E5FF);
      fontWeight = FontWeight.w800;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              if (isUser) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.goldPrimary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'YOU',
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 7.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 9.5,
                    fontWeight: fontWeight,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        Text(
          score,
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: isUser ? AppTheme.goldPrimary : AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildChampionSlotColumn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.goldPrimary.withOpacity(0.18),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.5)),
          ),
          child: const Text(
            'CHAMPION',
            style: TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              color: AppTheme.goldPrimary,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 120,
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.goldPrimary, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppTheme.goldPrimary.withOpacity(0.3),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: const [
              Icon(Icons.emoji_events_rounded, size: 28, color: AppTheme.goldPrimary),
              SizedBox(height: 6),
              Text(
                'GOLD MEDAL',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.goldPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'TBD',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openFullBracketModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => FullInteractiveBracketModal(tournament: widget.tournament),
    );
  }
}

