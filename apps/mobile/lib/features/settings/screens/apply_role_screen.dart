import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/providers/dependency_providers.dart';
import '../../auth/providers/auth_provider.dart';

class ApplyRoleScreen extends ConsumerStatefulWidget {
  const ApplyRoleScreen({super.key});

  @override
  ConsumerState<ApplyRoleScreen> createState() => _ApplyRoleScreenState();
}

class _ApplyRoleScreenState extends ConsumerState<ApplyRoleScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedRole = 'REFEREE';
  final _experienceController = TextEditingController();
  final _certificationController = TextEditingController();
  bool _isSubmitting = false;

  final List<Map<String, String>> _availableRoles = const [
    {
      'key': 'REFEREE',
      'label': 'Certified Referee',
      'description': 'Officiate standard and tournament matches, table scorepads, and referee reports.',
    },
    {
      'key': 'TOURNAMENT_OPERATOR',
      'label': 'Tournament Operator',
      'description': 'Manage weigh-ins, table assignments, and bracket operations for federation events.',
    },
    {
      'key': 'ORGANIZATION_LEADER',
      'label': 'Organization / Club Leader',
      'description': 'Manage official club rosters, affiliated teams, and club member athlete accounts.',
    },
  ];

  @override
  void dispose() {
    _experienceController.dispose();
    _certificationController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.lightImpact();
    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.applyForRole(
        role: _selectedRole,
        experienceDetails: _experienceController.text.trim(),
        certificationNumber: _certificationController.text.trim().isNotEmpty
            ? _certificationController.text.trim()
            : null,
      );

      await ref.read(authProvider.notifier).refreshUserRoles();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application submitted successfully for federation review.'),
            backgroundColor: AppTheme.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply for Federation Role'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.space16),
          children: [
            // Notice Card
            ElevatedActionCard(
              padding: const EdgeInsets.all(AppTheme.space14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.primaryGold, size: 22),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Server-Authoritative Role Review',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: AppTheme.space4),
                        Text(
                          'Applying for a role does not grant permissions. All federation roles require formal verification and review by authorized leadership.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space20),

            // Role Selection Dropdown / Radio Cards
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
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                      ),
                    ),
                    subtitle: Text(
                      roleInfo['description']!,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    value: roleInfo['key']!,
                    groupValue: _selectedRole,
                    activeColor: AppTheme.primaryGold,
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRole = val);
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppTheme.space20),

            // Certification Number (Optional or required for Referee)
            const Text(
              'CERTIFICATION OR LICENSE NUMBER (OPTIONAL)',
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
              decoration: InputDecoration(
                hintText: 'e.g. PAFF-REF-2026-081',
                filled: true,
                fillColor: AppTheme.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radius10),
                  borderSide: const BorderSide(color: AppTheme.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radius10),
                  borderSide: const BorderSide(color: AppTheme.cardBorder),
                ),
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
              decoration: InputDecoration(
                hintText: 'Describe your armwrestling officiating, organizing, or club background...',
                filled: true,
                fillColor: AppTheme.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radius10),
                  borderSide: const BorderSide(color: AppTheme.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radius10),
                  borderSide: const BorderSide(color: AppTheme.cardBorder),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().length < 10) {
                  return 'Please provide at least 10 characters detailing your experience.';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.space32),

            // Submit Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.space14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radius10),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit Application'),
            ),
          ],
        ),
      ),
    );
  }
}
