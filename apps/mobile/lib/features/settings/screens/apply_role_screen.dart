import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/display_formatters.dart';
import '../../../core/widgets/crystal_modal_sheet.dart';
import '../../../core/widgets/crystal_stage_scaffold.dart';
import '../../../core/widgets/crystal_glass_nav_controls.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/sticky_form_scaffold.dart';
import '../../../core/providers/state_providers.dart';
import '../../../core/providers/tournament_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/widgets/crystal_toast.dart';

class ApplyRoleScreen extends ConsumerStatefulWidget {
  const ApplyRoleScreen({super.key});

  @override
  ConsumerState<ApplyRoleScreen> createState() => _ApplyRoleScreenState();
}

class _ApplyRoleScreenState extends ConsumerState<ApplyRoleScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedRole = 'REFEREE';
  String? _selectedOrgId;
  String? _selectedOrgName;
  final _experienceController = TextEditingController();
  final _certificationController = TextEditingController();
  bool _isSubmitting = false;

  final List<Map<String, String>> _availableRoles = const [
    {
      'key': 'REFEREE',
      'label': 'Certified Referee',
      'description':
          'Apply to a registered ArmSphere organization for official referee certification.',
    },
    {
      'key': 'TOURNAMENT_OPERATOR',
      'label': 'Tournament / Club Operator',
      'description':
          'Manage weigh-ins, table assignments, bracket operations, and club rosters.',
    },
    {
      'key': 'ORGANIZATION_LEADER',
      'label': 'Organization / Club Leader',
      'description':
          'Register official clubs, lead team rosters, and coordinate inter-team sparring invites.',
    },
    {
      'key': 'SUPPORT_AGENT',
      'label': 'Support Agent',
      'description':
          'Assist athletes and officials via the ArmSphere Helpdesk ticket system.',
    },
  ];

  @override
  void dispose() {
    _experienceController.dispose();
    _certificationController.dispose();
    super.dispose();
  }

  Future<void> _openOrganizationPicker(
      List<Map<String, dynamic>> organizations) async {
    HapticFeedback.selectionClick();
    final picked = await CrystalModalSheet.show<Map<String, dynamic>>(
      context: context,
      title: 'SELECT CERTIFYING ORGANIZATION',
      subtitle:
          'Your referee certification request will be routed directly to this organization.',
      icon: Icons.account_balance_rounded,
      accentColor: AppTheme.goldPrimary,
      builder: (sheetCtx) {
        if (organizations.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No registered organizations are currently available. Please check back soon.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: organizations.map((org) {
            final id = (org['id'] ?? '').toString();
            final name = ArmSphereFormatters.formatOrganizationName(
              org['name']?.toString(),
              fallback: 'Organization',
            );
            final loc = ArmSphereFormatters.formatCleanAddress([
              org['city']?.toString(),
              org['province']?.toString(),
            ]);
            final isSelected = _selectedOrgId == id;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.of(sheetCtx).pop(org),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.goldPrimary.withValues(alpha: 0.14)
                        : const Color(0xFF141B29),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.goldPrimary
                          : const Color(0x28FFFFFF),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_outlined,
                        color: AppTheme.goldPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: AppTheme.textPure,
                              ),
                            ),
                            if (loc.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                loc,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.goldPrimary,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedOrgId = picked['id']?.toString();
        _selectedOrgName = ArmSphereFormatters.formatOrganizationName(
          picked['name']?.toString(),
          fallback: 'Selected Organization',
        );
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRole == 'REFEREE' &&
        (_selectedOrgId == null || _selectedOrgId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        CrystalSnackBar(
          content: const Text(
            'Please select a registered ArmSphere organization to apply for Referee certification.',
          ),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.applyForRole(
        role: _selectedRole,
        targetOrganizationId:
            _selectedRole == 'REFEREE' ? _selectedOrgId : null,
        experienceDetails: _experienceController.text.trim(),
        certificationNumber: _certificationController.text.trim().isNotEmpty
            ? _certificationController.text.trim()
            : null,
      );

      await ref.read(authProvider.notifier).refreshUserRoles();

      if (mounted) {
        final msg = _selectedRole == 'REFEREE' && _selectedOrgName != null
            ? 'Referee certification request sent to $_selectedOrgName.'
            : 'Application submitted successfully for review.';
        ScaffoldMessenger.of(context).showSnackBar(
          CrystalSnackBar(
            content: Text(msg),
            backgroundColor: AppTheme.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CrystalSnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgsAsync = ref.watch(organizationsProvider);

    return StickyFormScaffold(
      stageDomain: ArmSphereStageDomain.passport,
      appBar: AppBar(
        leading: const CrystalBackButton(fallbackRoute: '/settings/roles'),
        title: const Text('Role Application'),
      ),
      primaryActionLabel: 'Submit Application',
      primaryActionIcon: Icons.badge_outlined,
      isLoading: _isSubmitting,
      onPrimaryAction: _isSubmitting ? null : _handleSubmit,
      formKey: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Notice Card
          ElevatedActionCard(
            padding: const EdgeInsets.all(AppTheme.space14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    color: AppTheme.goldPrimary, size: 22),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Verified Organization & Role Review',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space4),
                      Text(
                        _selectedRole == 'REFEREE'
                            ? 'Referee certifications are issued directly by registered ArmSphere organizations. Select the organization you are applying to below.'
                            : 'Applying for a role does not grant permissions immediately. All roles require verification and review by authorized leadership.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space20),

          // Role Selection Radio Cards
          const Text(
            'SELECT ROLE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.space10),

          ElevatedActionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: _availableRoles.map((roleInfo) {
                final isSelected = _selectedRole == roleInfo['key'];
                return RadioListTile<String>(
                  title: Text(
                    roleInfo['label']!,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                  ),
                  subtitle: Text(
                    roleInfo['description']!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  value: roleInfo['key']!,
                  groupValue: _selectedRole,
                  activeColor: AppTheme.goldPrimary,
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedRole = val);
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppTheme.space20),

          // Required Organization Picker for REFEREE
          if (_selectedRole == 'REFEREE') ...[
            const Text(
              'CERTIFYING ORGANIZATION *',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: AppTheme.goldPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.space8),
            orgsAsync.when(
              loading: () => const ElevatedActionCard(
                padding: EdgeInsets.all(14),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.goldPrimary,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Loading registered organizations...',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              error: (_, __) => ElevatedActionCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppTheme.crimson, size: 18),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Unable to load organizations. Tap to retry.',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref.invalidate(organizationsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (organizations) {
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _openOrganizationPicker(organizations),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0x990D121D),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _selectedOrgId != null
                            ? AppTheme.goldPrimary
                            : const Color(0x38FFFFFF),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.account_balance_rounded,
                          color: AppTheme.goldPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedOrgName ??
                                'Choose a registered ArmSphere organization',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: _selectedOrgName != null
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: _selectedOrgName != null
                                  ? AppTheme.textPure
                                  : AppTheme.textMuted,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppTheme.space20),
          ],

          // Certification Number (Optional)
          const Text(
            'EXISTING LICENSE OR REFERENCE NUMBER (OPTIONAL)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          TextFormField(
            controller: _certificationController,
            scrollPadding: const EdgeInsets.only(bottom: 140),
            decoration: const InputDecoration(
              hintText: 'e.g. ORG-REF-2026-081',
            ),
          ),
          const SizedBox(height: AppTheme.space20),

          // Experience Details
          const Text(
            'EXPERIENCE & QUALIFICATIONS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          TextFormField(
            controller: _experienceController,
            maxLines: 4,
            scrollPadding: const EdgeInsets.only(bottom: 140),
            decoration: const InputDecoration(
              hintText:
                  'Describe your armwrestling officiating, organizing, or club background...',
            ),
            validator: (value) {
              if (value == null || value.trim().length < 10) {
                return 'Please provide at least 10 characters detailing your experience.';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
