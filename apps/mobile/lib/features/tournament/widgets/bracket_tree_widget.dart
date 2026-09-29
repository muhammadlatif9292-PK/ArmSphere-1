import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'bracket_connector_line.dart';
import 'bracket_connectors_painter.dart';
import 'bracket_minimap_hud.dart';
import 'compact_bracket_match_card.dart';

/// Interactive Spatial Tree Canvas for Tournament Brackets
///
/// Complies with Canary 8 (Tournament Bracket) specification:
/// - 2D spatial pan/zoom using Flutter InteractiveViewer (0.5x - 2.5x).
/// - SIG-6: Bracket Advance Lightning Line (250ms Curves.easeInOutCubic vector pulse,
///   bloom + core gold stroke, medium impact haptic on arrival, reduced-motion fallback).
/// - 88dp x 64dp bottom-right floating radar viewport indicator (BracketMinimapHud).
/// - Support for double-elimination partition switching (WINNERS / LOSERS / GRAND_FINAL).
/// - 60fps RepaintBoundary virtualization and isolated connector redraws.
class BracketTreeWidget extends StatefulWidget {
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
  State<BracketTreeWidget> createState() => _BracketTreeWidgetState();
}

class _BracketTreeWidgetState extends State<BracketTreeWidget>
    with SingleTickerProviderStateMixin {
  late final TransformationController _transformationController;
  late final AnimationController _sig6Controller;
  late final Animation<double> _sig6Animation;
  String _selectedBracketType = 'ALL';

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _sig6Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _sig6Animation = CurvedAnimation(
      parent: _sig6Controller,
      curve: Curves.easeInOutCubic,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (disableAnimations) {
        _sig6Controller.value = 1.0;
      } else {
        _sig6Controller.forward().then((_) {
          if (mounted) HapticFeedback.mediumImpact();
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant BracketTreeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.matches != widget.matches) {
      final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (disableAnimations) {
        _sig6Controller.value = 1.0;
      } else {
        _sig6Controller.reset();
        _sig6Controller.forward().then((_) {
          if (mounted) HapticFeedback.mediumImpact();
        });
      }
    }
  }

  @override
  void dispose() {
    _sig6Controller.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.matches.isEmpty) {
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

    final availableTypes = widget.matches
        .map((m) => (m['bracketType']?.toString().toUpperCase() ?? ''))
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();

    List<Map<String, dynamic>> activeMatches = widget.matches;
    if (availableTypes.length > 1 && _selectedBracketType != 'ALL') {
      final filtered = widget.matches
          .where((m) => (m['bracketType']?.toString().toUpperCase() ?? '') == _selectedBracketType)
          .toList();
      if (filtered.isNotEmpty) {
        activeMatches = filtered;
      }
    }

    final effectivePrefix = (_selectedBracketType != 'ALL')
        ? _selectedBracketType
        : widget.titlePrefix;

    // 1. Group matches by round field
    final Map<int, List<Map<String, dynamic>>> roundsMap = {};
    for (final m in activeMatches) {
      final r = m['round'] is int
          ? m['round'] as int
          : int.tryParse(m['round']?.toString() ?? '1') ?? 1;
      roundsMap.putIfAbsent(r, () => []).add(m);
    }

    final rounds = roundsMap.keys.toList()..sort();

    // Sort matches in each round by matchIndex
    for (final r in rounds) {
      roundsMap[r]!.sort((a, b) {
        final idxA = a['matchIndex'] is int
            ? a['matchIndex'] as int
            : int.tryParse(a['matchIndex']?.toString() ?? '0') ?? 0;
        final idxB = b['matchIndex'] is int
            ? b['matchIndex'] as int
            : int.tryParse(b['matchIndex']?.toString() ?? '0') ?? 0;
        return idxA.compareTo(idxB);
      });
    }

    final Map<String, Offset> matchPositions = {};
    final Map<String, Map<String, dynamic>> matchById = {};

    for (final m in activeMatches) {
      final id = m['id']?.toString() ?? '';
      if (id.isNotEmpty) {
        matchById[id] = m;
      }
    }

    // 2. Compute positions per round
    for (int rIdx = 0; rIdx < rounds.length; rIdx++) {
      final rNum = rounds[rIdx];
      final roundMatches = roundsMap[rNum]!;
      final double x = rIdx * (BracketTreeWidget.cardWidth + BracketTreeWidget.colGap);

      if (rIdx == 0) {
        // Round 1 matches evenly spaced top to bottom
        for (int i = 0; i < roundMatches.length; i++) {
          final m = roundMatches[i];
          final mKey = m['id']?.toString() ?? 'r1_m$i';
          final double y = BracketTreeWidget.topHeaderHeight +
              i * (BracketTreeWidget.cardHeight + BracketTreeWidget.baseGap);
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
                sumY += matchPositions[fKey]!.dy + BracketTreeWidget.cardHeight / 2;
                count++;
              }
            }
            targetYCenter = count > 0
                ? sumY / count
                : (BracketTreeWidget.topHeaderHeight +
                    i * (BracketTreeWidget.cardHeight + BracketTreeWidget.baseGap));
          } else {
            // Index-based fallback if nextMatchId is missing
            final feederIdx1 = i * 2;
            final feederIdx2 = i * 2 + 1;

            double sumY = 0;
            int count = 0;

            if (feederIdx1 < prevMatches.length) {
              final f1Key = prevMatches[feederIdx1]['id']?.toString() ?? '';
              if (matchPositions.containsKey(f1Key)) {
                sumY += matchPositions[f1Key]!.dy + BracketTreeWidget.cardHeight / 2;
                count++;
              }
            }
            if (feederIdx2 < prevMatches.length) {
              final f2Key = prevMatches[feederIdx2]['id']?.toString() ?? '';
              if (matchPositions.containsKey(f2Key)) {
                sumY += matchPositions[f2Key]!.dy + BracketTreeWidget.cardHeight / 2;
                count++;
              }
            }

            if (count > 0) {
              targetYCenter = sumY / count;
            } else {
              targetYCenter = BracketTreeWidget.topHeaderHeight +
                  i * (BracketTreeWidget.cardHeight +
                      BracketTreeWidget.baseGap * math.pow(2, rIdx));
            }
          }

          final double y = targetYCenter - BracketTreeWidget.cardHeight / 2;
          matchPositions[mKey] = Offset(x, y);
        }
      }
    }

    // Canvas bounds
    final double totalWidth = math.max(
      360.0,
      rounds.length * BracketTreeWidget.cardWidth +
          (rounds.length - 1) * BracketTreeWidget.colGap +
          32.0,
    );
    double maxY = 0;
    for (final pos in matchPositions.values) {
      if (pos.dy + BracketTreeWidget.cardHeight > maxY) {
        maxY = pos.dy + BracketTreeWidget.cardHeight;
      }
    }
    final double totalHeight = math.max(360.0, maxY + 48.0);

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
            final startPt = matchPositions[fKey]! +
                const Offset(BracketTreeWidget.cardWidth, BracketTreeWidget.cardHeight / 2);
            final endPt =
                matchPositions[tKey]! + const Offset(0, BracketTreeWidget.cardHeight / 2);

            final isCompleted = f['status'] == 'COMPLETED';
            final hasWinner =
                f['winnerId'] != null && f['winnerId'].toString().isNotEmpty;
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

    // 4. Virtualized Layout with InteractiveViewer, Animated Connectors, & Radar Mini-Map
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);

        return Stack(
          children: [
            // 2D Spatial Interactive Canvas
            InteractiveViewer(
              transformationController: _transformationController,
              constrained: false,
              minScale: 0.5,
              maxScale: 2.5,
              boundaryMargin: const EdgeInsets.all(80.0),
              child: RepaintBoundary(
                child: Container(
                  width: totalWidth,
                  height: totalHeight,
                  margin: EdgeInsets.only(
                    top: availableTypes.length > 1 ? 52 : 8,
                    bottom: 24,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Round Header Labels
                      for (int rIdx = 0; rIdx < rounds.length; rIdx++)
                        Positioned(
                          left: rIdx * (BracketTreeWidget.cardWidth + BracketTreeWidget.colGap),
                          top: 0,
                          width: BracketTreeWidget.cardWidth,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: effectivePrefix == 'LOSERS'
                                    ? AppTheme.accentOrange.withValues(alpha: 0.15)
                                    : AppTheme.goldPrimary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                border: Border.all(
                                  color: effectivePrefix == 'LOSERS'
                                      ? AppTheme.accentOrange.withValues(alpha: 0.4)
                                      : AppTheme.goldPrimary.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                _getRoundLabel(rIdx, rounds.length, effectivePrefix, rounds[rIdx]),
                                style: TextStyle(
                                  color: effectivePrefix == 'LOSERS'
                                      ? AppTheme.accentOrange
                                      : AppTheme.goldPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  fontFamily: 'Space Grotesk',
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // SIG-6 Animated Connectors Painter (Layer-isolated with RepaintBoundary)
                      RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: _sig6Animation,
                          builder: (context, _) {
                            return CustomPaint(
                              size: Size(totalWidth, totalHeight),
                              painter: BracketConnectorsPainter(
                                connectors: connectors,
                                progress: _sig6Animation.value,
                              ),
                            );
                          },
                        ),
                      ),

                      // Match Cards (Individual RepaintBoundary isolation)
                      for (final r in rounds)
                        for (final m in roundsMap[r]!)
                          if (matchPositions.containsKey(m['id']?.toString()))
                            Positioned(
                              left: matchPositions[m['id']?.toString()]!.dx,
                              top: matchPositions[m['id']?.toString()]!.dy,
                              width: BracketTreeWidget.cardWidth,
                              height: BracketTreeWidget.cardHeight,
                              child: RepaintBoundary(
                                child: CompactBracketMatchCard(match: m),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),

            // Top Filter Chips (for double-elimination brackets with WINNERS / LOSERS)
            if (availableTypes.length > 1)
              Positioned(
                top: 8,
                left: 16,
                right: 16,
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.cardSurface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(color: AppTheme.borderSubtle, width: 0.8),
                  ),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    children: [
                      _buildPartitionChip('ALL', 'Full Draw'),
                      if (availableTypes.contains('WINNERS'))
                        _buildPartitionChip('WINNERS', 'Winners'),
                      if (availableTypes.contains('LOSERS'))
                        _buildPartitionChip('LOSERS', 'Elimination'),
                      if (availableTypes.contains('GRAND_FINAL'))
                        _buildPartitionChip('GRAND_FINAL', 'Grand Final'),
                    ],
                  ),
                ),
              ),

            // Bottom-Right Floating Radar Mini-Map HUD (88dp x 64dp)
            Positioned(
              right: 16,
              bottom: 16,
              child: BracketMinimapHud(
                controller: _transformationController,
                canvasSize: Size(totalWidth, totalHeight),
                matchOffsets: matchPositions.values.toList(),
                cardSize: const Size(BracketTreeWidget.cardWidth, BracketTreeWidget.cardHeight),
                viewportSize: viewportSize,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPartitionChip(String key, String label) {
    final isSelected = _selectedBracketType == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppTheme.goldPrimary : AppTheme.textMuted,
          ),
        ),
        selected: isSelected,
        selectedColor: AppTheme.goldPrimary.withValues(alpha: 0.2),
        backgroundColor: Colors.transparent,
        side: BorderSide(
          color: isSelected ? AppTheme.goldPrimary : AppTheme.borderSubtle,
        ),
        onSelected: (_) {
          HapticFeedback.selectionClick();
          setState(() => _selectedBracketType = key);
        },
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
