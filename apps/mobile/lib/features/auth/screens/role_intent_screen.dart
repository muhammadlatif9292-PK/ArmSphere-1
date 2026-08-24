import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/step_header.dart';
import '../providers/auth_provider.dart';

/// Post-registration step where the user tells ArmSphere what they came to do.
///
/// The choice is a product preference only: every self-registered account is
/// provisioned as an athlete profile by the backend, and verified federation
/// roles are granted by staff — never by this selection.
class RoleIntentScreen extends ConsumerStatefulWidget {
  const RoleIntentScreen({super.key});

  @override
  ConsumerState<RoleIntentScreen> createState() => _RoleIntentScreenState();
}

class _RoleIntentScreenState extends ConsumerState<RoleIntentScreen> {
  String? _selected;

  static const _intents = <_IntentOption>[
    _IntentOption(
      value: 'athlete',
      icon: Icons.sports_kabaddi,
      title: 'Compete as an Athlete',
      subtitle: 'Build your profile, register for events and climb the rankings.',
    ),
    _IntentOption(
      value: 'referee',
      icon: Icons.gavel_outlined,
      title: 'Officiate Matches',
      subtitle: 'Judge matches at sanctioned tournaments as a certified referee.',
      requiresVerification: true,
    ),
    _IntentOption(
      value: 'organizer',
      icon: Icons.event_available_outlined,
      title: 'Organize Tournaments',
      subtitle: 'Create events, manage brackets and run weigh-ins.',
      requiresVerification: true,
    ),
    _IntentOption(
      value: 'organization_leader',
      icon: Icons.account_balance_outlined,
      title: 'Lead a Club or Federation',
      subtitle: 'Manage rosters and represent your organization on ArmSphere.',
      requiresVerification: true,
    ),
  ];

  Future<void> _continue() async {
    final intent = _selected;
    if (intent == null) return;

    final option = _intents.firstWhere((o) => o.value == intent);
    if (option.requiresVerification) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.elevatedSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            side: const BorderSide(color: AppTheme.glassBorder),
          ),
          title: Row(
            children: [
              const Icon(Icons.verified_user_outlined, color: AppTheme.goldPrimary),
              const SizedBox(width: 10),
              Expanded(child: Text('Official roles are verified', style: Theme.of(context).textTheme.titleLarge)),
            ],
          ),
          content: Text(
            'Referees, organizers and organization leaders are appointed through your '
            'provincial armwrestling federation.\n\n'
            'You can complete your athlete profile now — once the federation verifies '
            'your official position, your dashboard unlocks the extra tools automatically.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Pick another'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.goldPrimary, foregroundColor: Colors.black),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    await ref.read(authProvider.notifier).setRoleIntent(intent);
    if (mounted) context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set up your experience'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const StepHeader(
                    step: 1,
                    totalSteps: 2,
                    title: 'What brings you to ArmSphere?',
                    subtitle:
                        "Choose what you'd like to do first. You can always explore everything else later.",
                  ),
                  const SizedBox(height: 24),
                  ..._intents.map((option) {
                    final selected = _selected == option.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _IntentCard(
                        option: option,
                        selected: selected,
                        onTap: () => setState(() => _selected = option.value),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _selected == null ? null : _continue,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.goldPrimary,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: AppTheme.surface,
                      disabledForegroundColor: AppTheme.textMuted,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('Continue'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Verified roles (referee, organizer, federation) are granted by federation staff after review.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
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

class _IntentOption {
  final String value;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool requiresVerification;

  const _IntentOption({
    required this.value,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.requiresVerification = false,
  });
}

class _IntentCard extends StatelessWidget {
  final _IntentOption option;
  final bool selected;
  final VoidCallback onTap;

  const _IntentCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: AnimatedContainer(
          duration: AppTheme.animationNormal,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? const Color(0x1AD4AF37) : AppTheme.elevatedSurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: selected ? AppTheme.goldPrimary : AppTheme.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.goldGlow,
                  border: Border.all(color: AppTheme.glassBorder),
                ),
                child: Icon(option.icon, size: 24, color: AppTheme.goldLight),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            option.title,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (option.requiresVerification)
                          Tooltip(
                            message: 'Requires federation verification',
                            triggerMode: TooltipTriggerMode.tap,
                            child: Icon(Icons.workspace_premium_outlined,
                                size: 18, color: AppTheme.textMuted),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(option.subtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                color: selected ? AppTheme.goldPrimary : AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
