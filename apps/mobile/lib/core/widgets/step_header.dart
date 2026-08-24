import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Progress indicator + heading used by guided setup flows (role intent,
/// athlete onboarding) so every wizard step looks and behaves identically.
class StepHeader extends StatelessWidget {
  final int step;
  final int totalSteps;
  final String title;
  final String subtitle;

  const StepHeader({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(totalSteps, (index) {
            final active = index < step;
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 6),
                decoration: BoxDecoration(
                  color: active ? AppTheme.goldPrimary : AppTheme.border,
                  borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        Text(title, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary, height: 1.4)),
      ],
    );
  }
}
