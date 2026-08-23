import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';

enum MatchOutcome { victory, loss, pending }

class MatchRecord {
  final String opponentName;
  final String opponentAvatar;
  final String tournament;
  final String score;
  final MatchOutcome outcome;
  final String date;
  final String leagueBadge;
  final int eloChange;
  final String weightClass;
  final String armUsed;

  const MatchRecord({
    required this.opponentName,
    required this.opponentAvatar,
    required this.tournament,
    required this.score,
    required this.outcome,
    required this.date,
    required this.leagueBadge,
    required this.eloChange,
    required this.weightClass,
    required this.armUsed,
  });
}

class LatestMatchesSection extends StatelessWidget {
  final VoidCallback? onViewAllTap;

  const LatestMatchesSection({
    Key? key,
    this.onViewAllTap,
  }) : super(key: key);

  static const List<MatchRecord> _matches = [
    MatchRecord(
      opponentName: 'Tariq Khan',
      opponentAvatar: '🇵🇰',
      tournament: 'National Armwrestling Championship',
      score: '3 - 0',
      outcome: MatchOutcome.victory,
      date: '24 Jul 2026',
      leagueBadge: 'PRO ELITE',
      eloChange: 16,
      weightClass: '-95kg Heavyweight',
      armUsed: 'Right Arm',
    ),
    MatchRecord(
      opponentName: 'Zubair Ahmad',
      opponentAvatar: '🇵🇰',
      tournament: 'Islamabad Pro Cup Finals',
      score: '3 - 1',
      outcome: MatchOutcome.victory,
      date: '18 Jul 2026',
      leagueBadge: 'NAT TITLE',
      eloChange: 12,
      weightClass: '-95kg Heavyweight',
      armUsed: 'Right Arm',
    ),
    MatchRecord(
      opponentName: 'Hamza Malik',
      opponentAvatar: '🇵🇰',
      tournament: 'Punjab Super League Round 4',
      score: '2 - 3',
      outcome: MatchOutcome.loss,
      date: '02 Jul 2026',
      leagueBadge: 'SUPER 8',
      eloChange: -8,
      weightClass: '-95kg Heavyweight',
      armUsed: 'Right Arm',
    ),
    MatchRecord(
      opponentName: 'Usman Riaz',
      opponentAvatar: '🇵🇰',
      tournament: 'Asia Armwrestling Championship',
      score: '3 - 0',
      outcome: MatchOutcome.victory,
      date: '15 Jun 2026',
      leagueBadge: 'ASIA CUP',
      eloChange: 18,
      weightClass: '-95kg Heavyweight',
      armUsed: 'Right Arm',
    ),
    MatchRecord(
      opponentName: 'Bilal Chaudhry',
      opponentAvatar: '🇵🇰',
      tournament: 'Rawalpindi Open Supermatch',
      score: '0 - 0',
      outcome: MatchOutcome.pending,
      date: '10 Aug 2026',
      leagueBadge: 'UPCOMING',
      eloChange: 0,
      weightClass: '-95kg Heavyweight',
      armUsed: 'Right Arm',
    ),
  ];

  void _showCompleteHistoryModal(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CompleteMatchHistorySheet(matches: _matches),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 3.5,
                    height: 15,
                    decoration: BoxDecoration(
                      color: AppTheme.goldPrimary,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.goldPrimary.withOpacity(0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'LATEST MATCHES',
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),

              // View All Button
              GestureDetector(
                onTap: () {
                  if (onViewAllTap != null) {
                    onViewAllTap!();
                  } else {
                    _showCompleteHistoryModal(context);
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.goldPrimary.withOpacity(0.3),
                      width: 0.8,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'SEE ALL HISTORY',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.goldLight,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: AppTheme.goldPrimary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // List of 5 Premium Match Cards
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _matches.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final match = _matches[index];
            return _MatchCardTile(
              match: match,
              onTap: () => _showCompleteHistoryModal(context),
            );
          },
        ),
      ],
    );
  }
}

/// Single Premium Match Card Tile
class _MatchCardTile extends StatelessWidget {
  final MatchRecord match;
  final VoidCallback onTap;

  const _MatchCardTile({
    Key? key,
    required this.match,
    required this.onTap,
  }) : super(key: key);

  Color get _statusColor {
    switch (match.outcome) {
      case MatchOutcome.victory:
        return AppTheme.success; // Green
      case MatchOutcome.loss:
        return AppTheme.error; // Red
      case MatchOutcome.pending:
        return AppTheme.textSecondary; // Gray
    }
  }

  IconData get _statusIcon {
    switch (match.outcome) {
      case MatchOutcome.victory:
        return Icons.emoji_events_rounded;
      case MatchOutcome.loss:
        return Icons.close_rounded;
      case MatchOutcome.pending:
        return Icons.hourglass_top_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TactilePressWrapper(
      onTap: onTap,
      enableLift: true,
      liftDistance: -2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: _statusColor.withOpacity(0.12),
              blurRadius: 16,
              spreadRadius: -2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.glassSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _statusColor.withOpacity(0.35),
                  width: 1.0,
                ),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    _statusColor.withOpacity(0.12),
                    AppTheme.surface,
                    AppTheme.background,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
              child: Row(
                children: [
                  // Outcome Left Badge Strip
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _statusColor.withOpacity(0.6),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _statusColor.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      _statusIcon,
                      color: _statusColor,
                      size: 18,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Middle Column: Opponent & Tournament
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'vs ${match.opponentName}',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              match.opponentAvatar,
                              style: TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 6),

                            // Small League Badge Pill
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.15),
                                  width: 0.6,
                                ),
                              ),
                              child: Text(
                                match.leagueBadge,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.goldLight,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 3),

                        Text(
                          match.tournament,
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 2),

                        Text(
                          match.date,
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Right Column: Score, ELO Change, & Status Badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Score display
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          match.score,
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),

                      const SizedBox(height: 4),

                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Tiny ELO change pill
                          if (match.outcome != MatchOutcome.pending)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: (match.eloChange >= 0
                                        ? AppTheme.success
                                        : AppTheme.error)
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                match.eloChange >= 0
                                    ? '+${match.eloChange} ELO'
                                    : '${match.eloChange} ELO',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  color: match.eloChange >= 0
                                      ? AppTheme.success
                                      : AppTheme.error,
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const Text(
                                'UPCOMING',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Complete Match History Bottom Sheet Modal
class _CompleteMatchHistorySheet extends StatelessWidget {
  final List<MatchRecord> matches;

  const _CompleteMatchHistorySheet({
    Key? key,
    required this.matches,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.8),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),

          // Drag Handle
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 16),

          // Sheet Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history_rounded, color: AppTheme.goldPrimary, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'COMPLETE MATCH HISTORY',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: AppTheme.surface, height: 20),

          // Match List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: matches.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final match = matches[index];
                return _MatchCardTile(
                  match: match,
                  onTap: () {},
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
