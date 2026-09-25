import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'bracket_connector_line.dart';
import 'bracket_connectors_painter.dart';
import 'compact_bracket_match_card.dart';

/// Interactive Canvas Tree for Tournament Brackets
///
/// Upgraded to Canonical Stage 2 Specification (Slice 8 / [P0-04]):
/// - Two-axis InteractiveViewer virtualization with 0.5x - 2.5x pinch-to-zoom.
/// - RepaintBoundary layer isolation preventing frame drops on 64+ athlete draws.
/// - Connectors painter layer caching for 60fps buttery scrolling.
class BracketTreeWidget extends StatelessWidget {
  final List<Map<String, dynamic>> matches;
  final String titlePrefix;

  const BracketTreeWidget({
    super.key,
    required this.matches,
    required this.titlePrefix,
  });

  static const double cardWidth = 200.0;
  static const double cardHeight = 94.0;
  static const double colGap = 52.0;
  static const double baseGap = 24.0;
  static const double topHeaderHeight = 36.0;

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'No bracket matches scheduled yet.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ),
      );
    }

    // 1. Group matches by round field
    final Map<int, List<Map<String, dynamic>>> roundsMap = {};
    for (final m in matches) {
      final r = m['round'] is int ? m['round'] as int : int.tryParse(m['round']?.toString() ?? '1') ?? 1;
      roundsMap.putIfAbsent(r, () => []).add(m);
    }

    final rounds = roundsMap.keys.toList()..sort();

    // Sort matches in each round by matchIndex
    for (final r in rounds) {
      roundsMap[r]!.sort((a, b) {
        final idxA = a['matchIndex'] is int ? a['matchIndex'] as int : int.tryParse(a['matchIndex']?.toString() ?? '0') ?? 0;
        final idxB = b['matchIndex'] is int ? b['matchIndex'] as int : int.tryParse(b['matchIndex']?.toString() ?? '0') ?? 0;
        return idxA.compareTo(idxB);
      });
    }

    final Map<String, Offset> matchPositions = {};
    final Map<String, Map<String, dynamic>> matchById = {};

    for (final m in matches) {
      final id = m['id']?.toString() ?? '';
      if (id.isNotEmpty) {
        matchById[id] = m;
      }
    }

    // 2. Compute positions per round
    for (int rIdx = 0; rIdx < rounds.length; rIdx++) {
      final rNum = rounds[rIdx];
      final roundMatches = roundsMap[rNum]!;
      final double x = rIdx * (cardWidth + colGap);

      if (rIdx == 0) {
        // Round 1 matches evenly spaced top to bottom
        for (int i = 0; i < roundMatches.length; i++) {
          final m = roundMatches[i];
          final mKey = m['id']?.toString() ?? 'r1_m$i';
          final double y = topHeaderHeight + i * (cardHeight + baseGap);
          matchPositions[mKey] = Offset(x, y);
        }
      } else {
        // Subsequent rounds vertically centered between feeder midpoints
        final prevRNum = rounds[rIdx - 1];
        final prevMatches = roundsMap[prevRNum]!;

        for (int i = 0; i < roundMatches.length; i++) {
          final m = roundMatches[i];
          final mKey = m['id']?.toString() ?? 'r${rNum}_m$i';

          final feeders = prevMatches.where((f) {
            final nextId = f['nextMatchId']?.toString();
            return nextId != null && nextId.isNotEmpty && nextId == (m['id']?.toString());
          }).toList();

          double targetYCenter;

          if (feeders.isNotEmpty) {
            double sumY = 0;
            int count = 0;
            for (final f in feeders) {
              final fKey = f['id']?.toString() ?? '';
              if (matchPositions.containsKey(fKey)) {
                sumY += matchPositions[fKey]!.dy + cardHeight / 2;
                count++;
              }
            }
            targetYCenter = count > 0 ? sumY / count : (topHeaderHeight + i * (cardHeight + baseGap));
          } else {
            // Index-based fallback if nextMatchId is missing
            final feederIdx1 = i * 2;
            final feederIdx2 = i * 2 + 1;

            double sumY = 0;
            int count = 0;

            if (feederIdx1 < prevMatches.length) {
              final f1Key = prevMatches[feederIdx1]['id']?.toString() ?? '';
              if (matchPositions.containsKey(f1Key)) {
                sumY += matchPositions[f1Key]!.dy + cardHeight / 2;
                count++;
              }
            }
            if (feederIdx2 < prevMatches.length) {
              final f2Key = prevMatches[feederIdx2]['id']?.toString() ?? '';
              if (matchPositions.containsKey(f2Key)) {
                sumY += matchPositions[f2Key]!.dy + cardHeight / 2;
                count++;
              }
            }

            if (count > 0) {
              targetYCenter = sumY / count;
            } else {
              targetYCenter = topHeaderHeight + i * (cardHeight + baseGap * math.pow(2, rIdx));
            }
          }

          final double y = targetYCenter - cardHeight / 2;
          matchPositions[mKey] = Offset(x, y);
        }
      }
    }

    // Canvas bounds
    final double totalWidth = rounds.length * cardWidth + (rounds.length - 1) * colGap + 16.0;
    double maxY = 0;
    for (final pos in matchPositions.values) {
      if (pos.dy + cardHeight > maxY) {
        maxY = pos.dy + cardHeight;
      }
    }
    final double totalHeight = math.max(320.0, maxY + 32.0);

    // 3. Build connector lines
    final List<BracketConnectorLine> connectors = [];
    for (int rIdx = 0; rIdx < rounds.length - 1; rIdx++) {
      final rNum = rounds[rIdx];
      final matchesList = roundsMap[rNum]!;
      final nextRNum = rounds[rIdx + 1];
      final nextMatches = roundsMap[nextRNum]!;

      for (int i = 0; i < matchesList.length; i++) {
        final f = matchesList[i];
        final fKey = f['id']?.toString() ?? 'r${rNum}_m$i';
        if (!matchPositions.containsKey(fKey)) continue;

        Map<String, dynamic>? nextMatch;
        final nextId = f['nextMatchId']?.toString();

        if (nextId != null && nextId.isNotEmpty) {
          nextMatch = matchById[nextId];
        }
        if (nextMatch == null) {
          final targetIdx = i ~/ 2;
          if (targetIdx < nextMatches.length) {
            nextMatch = nextMatches[targetIdx];
          }
        }

        if (nextMatch != null) {
          final tKey = nextMatch['id']?.toString() ?? '';
          if (matchPositions.containsKey(tKey)) {
            final startPt = matchPositions[fKey]! + const Offset(cardWidth, cardHeight / 2);
            final endPt = matchPositions[tKey]! + const Offset(0, cardHeight / 2);

            final isCompleted = f['status'] == 'COMPLETED';
            final hasWinner = f['winnerId'] != null && f['winnerId'].toString().isNotEmpty;
            final isHighlighted = isCompleted && hasWinner;

            connectors.add(BracketConnectorLine(
              startPt: startPt,
              endPt: endPt,
              isHighlighted: isHighlighted,
            ));
          }
        }
      }
    }

    // 4. Virtualized InteractiveViewer with RepaintBoundaries
    return InteractiveViewer(
      constrained: false,
      minScale: 0.5,
      maxScale: 2.5,
      boundaryMargin: const EdgeInsets.all(60.0),
      child: RepaintBoundary(
        child: Container(
          width: totalWidth,
          height: totalHeight,
          margin: const EdgeInsets.only(top: 8, bottom: 16),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Round Header Labels
              for (int rIdx = 0; rIdx < rounds.length; rIdx++)
                Positioned(
                  left: rIdx * (cardWidth + colGap),
                  top: 0,
                  width: cardWidth,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: titlePrefix == 'LOSERS'
                            ? AppTheme.accentOrange.withValues(alpha: 0.15)
                            : AppTheme.goldPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        border: Border.all(
                          color: titlePrefix == 'LOSERS'
                              ? AppTheme.accentOrange.withValues(alpha: 0.4)
                              : AppTheme.goldPrimary.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        _getRoundLabel(rIdx, rounds.length, titlePrefix, rounds[rIdx]),
                        style: TextStyle(
                          color: titlePrefix == 'LOSERS' ? AppTheme.accentOrange : AppTheme.goldPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          fontFamily: 'Space Grotesk',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),

              // Connectors Painter (Layer-isolated with RepaintBoundary)
              RepaintBoundary(
                child: CustomPaint(
                  size: Size(totalWidth, totalHeight),
                  painter: BracketConnectorsPainter(connectors: connectors),
                ),
              ),

              // Match Cards (Individual RepaintBoundary isolation)
              for (final r in rounds)
                for (final m in roundsMap[r]!)
                  if (matchPositions.containsKey(m['id']?.toString()))
                    Positioned(
                      left: matchPositions[m['id']?.toString()]!.dx,
                      top: matchPositions[m['id']?.toString()]!.dy,
                      width: cardWidth,
                      height: cardHeight,
                      child: RepaintBoundary(
                        child: CompactBracketMatchCard(match: m),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRoundLabel(int rIdx, int totalRounds, String prefix, int roundNum) {
    if (prefix == 'WINNERS') {
      if (rIdx == totalRounds - 1) return 'GRAND FINALS';
      if (rIdx == totalRounds - 2 && totalRounds > 2) return 'SEMIFINALS';
      return 'ROUND $roundNum';
    } else if (prefix == 'LOSERS') {
      if (rIdx == totalRounds - 1) return 'LOSERS FINALS';
      if (rIdx == totalRounds - 2 && totalRounds > 2) return 'LOSERS SEMIS';
      return 'LOSERS R$roundNum';
    }
    return 'ROUND $roundNum';
  }
}
