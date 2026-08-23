import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';

class PersonalRecordsCard extends StatelessWidget {
  final String athleteId;

  const PersonalRecordsCard({
    Key? key,
    required this.athleteId,
  }) : super(key: key);

  static const List<Map<String, dynamic>> _prs = [
    {
      'exercise': 'WRIST FLEXION (CUP)',
      'weight': '72.0 KG',
      'reps': '1 Rep Max',
      'date': '12 MAY 2026',
      'icon': Icons.fitness_center,
      'isRecord': true,
    },
    {
      'exercise': 'PRONATION ROLLER',
      'weight': '48.5 KG',
      'reps': '3 Reps',
      'date': '04 JUL 2026',
      'icon': Icons.rotate_right_rounded,
      'isRecord': true,
    },
    {
      'exercise': 'BACKPRESSURE (STRAP)',
      'weight': '58.0 KG',
      'reps': '1 Rep Max',
      'date': '18 JUN 2026',
      'icon': Icons.arrow_back_rounded,
      'isRecord': false,
    },
    {
      'exercise': 'SIDE PRESSURE LIFT',
      'weight': '64.0 KG',
      'reps': '1 Rep Max',
      'date': '01 JUL 2026',
      'icon': Icons.double_arrow_rounded,
      'isRecord': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppTheme.goldPrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'VERIFIED PERSONAL RECORDS (PRs)',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),

            // View Log Button
            GestureDetector(
              onTap: () {
                context.push('/athlete/${athleteId.isEmpty ? '1' : athleteId}/training-log');
              },
              child: Row(
                children: const [
                  Text(
                    'FULL LOG',
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.goldPrimary,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right, color: AppTheme.goldPrimary, size: 14),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // PR Items List
        Column(
          children: _prs.map((pr) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TactilePressWrapper(
                onTap: () {
                  context.push('/athlete/${athleteId.isEmpty ? '1' : athleteId}/training-log');
                },
                enableLift: true,
                liftDistance: -2,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: pr['isRecord'] as bool
                          ? AppTheme.goldPrimary.withOpacity(0.35)
                          : Colors.white.withOpacity(0.06),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: pr['isRecord'] as bool
                              ? AppTheme.goldPrimary.withOpacity(0.18)
                              : Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          pr['icon'] as IconData,
                          color: pr['isRecord'] as bool
                              ? AppTheme.goldLight
                              : AppTheme.textSecondary,
                          size: 16,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  pr['exercise'] as String,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                if (pr['isRecord'] as bool) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.goldPrimary.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'RECORD',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.goldLight,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${pr['reps']} • ${pr['date']}',
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 9.5,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Text(
                        pr['weight'] as String,
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: pr['isRecord'] as bool
                              ? AppTheme.goldLight
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
