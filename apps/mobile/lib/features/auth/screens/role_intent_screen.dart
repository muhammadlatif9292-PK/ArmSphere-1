import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/step_header.dart';
import '../../../core/widgets/sticky_bottom_action_bar.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
import '../providers/auth_provider.dart';

/// Post-registration step where the user tells ArmSphere what they came to do.
///
/// Grounded in:
/// - docs/design/20_ROLE_BASED_UX.md
/// - docs/design/22_SCREEN_BY_SCREEN_SPEC.md
/// - docs/design/24_ANTI_SLOP_RULES.md
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
  String? _selected = 'athlete';
  bool _isLoading = false;

  static const _intents = <_IntentOption>[
    _IntentOption(
      value: 'athlete',
      icon: Icons.sports_kabaddi,
      title: 'Compete as an Athlete',
      subtitle: 'Build your profile, register for events, and climb the rankings.',
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
      subtitle: 'Create events, manage brackets, and run official weigh-ins.',
      requiresVerification: true,
    ),
    _IntentOption(
      value: 'organization_leader',
      icon: Icons.account_balance_outlined,
      title: 'Lead a Club or Federation',
      subtitle: 'Manage rosters and represent your armwrestling organization.',
      requiresVerification: true,
    ),
  ];

  Future<void> _continue() async {
    final intent = _selected;
    if (intent == null) return;

    final option = _intents.firstWhere((o) => o.value == intent);
    if (option.requiresVerification) {
      HapticFeedback.lightImpact();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            side: const BorderSide(color: AppTheme.border, width: 1.2),
          ),
          title: const Row(
            children: [
              Icon(Icons.verified_user_outlined, color: AppTheme.goldPrimary, size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Official Roles Verified',
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Referees, organizers, and club leaders are certified and appointed through official federation governance.\n\n'
            'You will complete your athlete competition profile first. Once federation credentials are confirmed by directors, your official console unlocks automatically.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop(false);
              },
              child: const Text(
                'Pick Another',
                style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w600),
              ),
            ),
            FilledButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.goldPrimary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
              ),
              child: const Text(
                'Continue to Setup',
                style: TextStyle(fontFamily: 'Space Grotesk', fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
    try {
      await ref.read(authProvider.notifier).setRoleIntent(intent);
      if (mounted) context.go('/onboarding');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Set Up Your Experience',
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontWeight: FontWeight.w700,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () async {
              HapticFeedback.lightImpact();
              await ref.read(authProvider.notifier).skipOnboarding();
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Skip to Tour',
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    color: AppTheme.goldPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: AppTheme.goldPrimary,
                ),
                SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                        "Choose what you'd like to do first. You can always explore other roles later.",
                  ),
                  const SizedBox(height: 20),
                  ..._intents.map((option) {
                    final selected = _selected == option.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _IntentCard(
                        option: option,
                        selected: selected,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selected = option.value);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: StickyBottomActionBar(
        primaryActionLabel: 'Continue to Profile',
        primaryActionIcon: Icons.arrow_forward,
        isLoading: _isLoading,
        onPrimaryAction: _selected == null || _isLoading ? null : _continue,
        disclaimerText:
            'Verified official roles are validated by provincial federation directors.',
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
    return TactilePressWrapper(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.animationNormal,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0x1AD4AF37) : AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: selected ? AppTheme.goldPrimary : AppTheme.border,
            width: selected ? 1.6 : 1.0,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.goldPrimary.withValues(alpha: 0.16),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? AppTheme.goldPrimary.withValues(alpha: 0.2)
                    : AppTheme.elevatedSurface,
                border: Border.all(
                  color: selected
                      ? AppTheme.goldPrimary
                      : AppTheme.goldPrimary.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                option.icon,
                size: 22,
                color: selected ? AppTheme.goldPrimary : AppTheme.goldLight,
              ),
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
                          style: TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: selected ? AppTheme.goldPrimary : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      if (option.requiresVerification)
                        const Tooltip(
                          message: 'Requires federation verification',
                          triggerMode: TooltipTriggerMode.tap,
                          child: Icon(
                            Icons.workspace_premium_outlined,
                            size: 16,
                            color: AppTheme.textMuted,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    option.subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
              color: selected ? AppTheme.goldPrimary : AppTheme.border,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
