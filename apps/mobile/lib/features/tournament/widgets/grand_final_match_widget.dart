import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import 'bracket_connector_line.dart';
import 'bracket_connectors_painter.dart';
import 'compact_bracket_match_card.dart';
class GrandFinalMatchWidget extends StatelessWidget {
  final Map<String, dynamic> grandFinalMatch;
  final Map<String, dynamic>? lastWinnerMatch;
  final Map<String, dynamic>? lastLoserMatch;

  const GrandFinalMatchWidget({
    Key? key,
    required this.grandFinalMatch,
    this.lastWinnerMatch,
    this.lastLoserMatch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double baseWidth = 200.0;
    const double baseHeight = 94.0;
    const double scaleFactor = 1.3;

    final winnerDone = lastWinnerMatch != null && lastWinnerMatch!['status'] == 'COMPLETED';
    final loserDone = lastLoserMatch != null && lastLoserMatch!['status'] == 'COMPLETED';

    final winnerHighlight = winnerDone && lastWinnerMatch!['winnerId'] != null;
    final loserHighlight = loserDone && lastLoserMatch!['winnerId'] != null;

    final connectors = [
      BracketConnectorLine(
        startPt: const Offset(40, 10),
        endPt: const Offset(160, 36),
        isHighlighted: winnerHighlight,
      ),
      BracketConnectorLine(
        startPt: const Offset(280, 10),
        endPt: const Offset(160, 36),
        isHighlighted: loserHighlight,
      ),
    ];

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Trophy Icon & Championship Header
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAccent.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryAccent.withOpacity(0.4)),
                ),
                child: const Icon(Icons.emoji_events, color: AppTheme.primaryAccent, size: 22),
              ),
              const SizedBox(width: 8),
              const Text(
                'CHAMPIONSHIP MATCH',
                style: TextStyle(
                  color: AppTheme.primaryAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  fontFamily: 'JetBrains Mono',
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Feeder Connectors Visual above Card
          SizedBox(
            width: 320,
            height: 40,
            child: CustomPaint(
              painter: BracketConnectorsPainter(connectors: connectors),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Text(
                      'WINNERS CHAMP',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: winnerHighlight ? AppTheme.primaryAccent : AppTheme.textMuted,
                        fontFamily: 'JetBrains Mono',
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Text(
                      'LOSERS CHAMP',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: loserHighlight ? AppTheme.primaryAccent : AppTheme.textMuted,
                        fontFamily: 'JetBrains Mono',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 1.3x Scaled Match Card (Lays out at 200x94, paints scaled to 260x122)
          const SizedBox(height: 16),
          Transform.scale(
            scale: scaleFactor,
            child: SizedBox(
              width: baseWidth,
              height: baseHeight,
              child: CompactBracketMatchCard(match: grandFinalMatch),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

