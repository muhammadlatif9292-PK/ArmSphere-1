import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../core/widgets/pulse_indicator.dart';
class CompactBracketMatchCard extends StatelessWidget {
  final Map<String, dynamic> match;

  const CompactBracketMatchCard({
    Key? key,
    required this.match,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tableNo = (match['tableNumber'] ?? match['table'] ?? '1').toString();
    final p1 = (match['athleteAName'] ?? match['athleteA'] ?? 'TBD').toString();
    final p2 = (match['athleteBName'] ?? match['athleteB'] ?? 'TBD').toString();
    final score1 = match['scoreLine']?.toString().split('-').first ?? '0';
    final score2 = match['scoreLine']?.toString().split('-').last ?? '0';

    final statusStr = (match['status']?.toString().toUpperCase()) ?? 'SCHEDULED';
    final isLive = statusStr == 'LIVE' || statusStr == 'IN_PROGRESS';
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

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLive ? AppTheme.primaryAccent : AppTheme.border,
          width: isLive ? 1.5 : 1.0,
        ),
        boxShadow: isLive
            ? [
                BoxShadow(
                  color: AppTheme.primaryAccent.withOpacity(0.15),
                  blurRadius: 6,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppTheme.elevatedSurface,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      tableNo,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'T$tableNo',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (isLive)
                Semantics(
                  liveRegion: true,
                  label: 'Match is now live',
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PulseIndicator(size: 4.0, color: AppTheme.primaryAccent),
                        SizedBox(width: 4),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: AppTheme.primaryAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (isCompleted)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'FINAL',
                    style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 8),
                  ),
                )
              else
                Text(
                  statusStr,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 8, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const Divider(color: AppTheme.border, height: 6, thickness: 0.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  p1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isAWinner ? FontWeight.bold : FontWeight.normal,
                    color: isCompleted
                        ? (isAWinner ? AppTheme.textPrimary : AppTheme.textMuted)
                        : AppTheme.textPrimary,
                  ),
                ),
              ),
              if (isCompleted || match['scoreLine'] != null)
                Text(
                  score1,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isAWinner ? FontWeight.bold : FontWeight.normal,
                    color: isAWinner ? AppTheme.primaryAccent : AppTheme.textMuted,
                  ),
                ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  p2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isBWinner ? FontWeight.bold : FontWeight.normal,
                    color: isCompleted
                        ? (isBWinner ? AppTheme.textPrimary : AppTheme.textMuted)
                        : AppTheme.textPrimary,
                  ),
                ),
              ),
              if (isCompleted || match['scoreLine'] != null)
                Text(
                  score2,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isBWinner ? FontWeight.bold : FontWeight.normal,
                    color: isBWinner ? AppTheme.primaryAccent : AppTheme.textMuted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

