import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';
import '../../../core/widgets/pulse_indicator.dart';

/// Compact Match Card inside Tournament Bracket Trees
///
/// Upgraded to Canonical Stage 2 Specification (Slice 8 / [P0-04]):
/// - RepaintBoundary isolation for 60fps panning virtualization.
/// - Luminous cyan pulsing glow (`#38BDF8` / `AppTheme.info`) on active table bouts.
/// - Space Grotesk numeric score and athlete name typography.
class CompactBracketMatchCard extends StatelessWidget {
  final Map<String, dynamic> match;

  const CompactBracketMatchCard({
    super.key,
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    final tableNo = (match['tableNumber'] ?? match['table'] ?? '1').toString();
    final p1 = (match['athleteAName'] ?? match['athleteA'] ?? 'TBD').toString();
    final p2 = (match['athleteBName'] ?? match['athleteB'] ?? 'TBD').toString();
    final score1 = match['scoreLine']?.toString().split('-').first ?? '0';
    final score2 = match['scoreLine']?.toString().split('-').last ?? '0';

    final statusStr = (match['status']?.toString().toUpperCase()) ?? 'SCHEDULED';
    final isLive = statusStr == 'LIVE' || statusStr == 'IN_PROGRESS' || statusStr == 'CALL_TO_TABLE';
    final isCompleted = statusStr == 'COMPLETED';

    final winnerId = match['winnerId']?.toString();
    final athleteAId = match['athleteAId']?.toString();
    final athleteBId = match['athleteBId']?.toString();

    bool isAWinner = false;
    bool isBWinner = false;

    if (isCompleted && winnerId != null && winnerId.isNotEmpty) {
      if (winnerId == athleteAId || match['winnerName'] == p1) {
        isAWinner = true;
      } else if (winnerId == athleteBId || match['winnerName'] == p2) {
        isBWinner = true;
      }
    }

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(
            color: isLive ? AppTheme.info : AppTheme.borderSubtle,
            width: isLive ? 1.5 : 1.0,
          ),
          boxShadow: isLive
              ? [
                  BoxShadow(
                    color: AppTheme.info.withValues(alpha: 0.35),
                    blurRadius: 10,
                    spreadRadius: 1.5,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header Row: Table Number & Status Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isLive ? AppTheme.info.withValues(alpha: 0.2) : AppTheme.elevatedSurface,
                        shape: BoxShape.circle,
                        border: isLive ? Border.all(color: AppTheme.info, width: 1) : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        tableNo,
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          color: isLive ? AppTheme.info : AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'TABLE $tableNo',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        color: isLive ? AppTheme.info : AppTheme.textMuted,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (isLive)
                  Semantics(
                    liveRegion: true,
                    label: 'Match is live on table $tableNo',
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.info.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.info.withValues(alpha: 0.5)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PulseIndicator(size: 4.0, color: AppTheme.info),
                          SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              fontFamily: 'Space Grotesk',
                              color: AppTheme.info,
                              fontWeight: FontWeight.bold,
                              fontSize: 8.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'FINAL',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        color: AppTheme.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 8,
                      ),
                    ),
                  )
                else
                  Text(
                    statusStr,
                    style: const TextStyle(
                      fontFamily: 'Space Grotesk',
                      color: AppTheme.textMuted,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const Divider(color: AppTheme.borderSubtle, height: 8, thickness: 0.5),

            // Competitor 1 Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    p1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 11,
                      fontWeight: isAWinner ? FontWeight.w800 : FontWeight.w500,
                      color: isCompleted
                          ? (isAWinner ? AppTheme.goldPrimary : AppTheme.textMuted)
                          : AppTheme.textPrimary,
                    ),
                  ),
                ),
                if (isCompleted || match['scoreLine'] != null)
                  Text(
                    score1,
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 11,
                      fontWeight: isAWinner ? FontWeight.w800 : FontWeight.w600,
                      color: isAWinner ? AppTheme.goldPrimary : AppTheme.textMuted,
                    ),
                  ),
              ],
            ),

            // Competitor 2 Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    p2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 11,
                      fontWeight: isBWinner ? FontWeight.w800 : FontWeight.w500,
                      color: isCompleted
                          ? (isBWinner ? AppTheme.goldPrimary : AppTheme.textMuted)
                          : AppTheme.textPrimary,
                    ),
                  ),
                ),
                if (isCompleted || match['scoreLine'] != null)
                  Text(
                    score2,
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 11,
                      fontWeight: isBWinner ? FontWeight.w800 : FontWeight.w600,
                      color: isBWinner ? AppTheme.goldPrimary : AppTheme.textMuted,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
