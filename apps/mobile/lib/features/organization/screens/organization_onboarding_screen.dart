import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/organization_session_provider.dart';
import '../../../core/providers/state_providers.dart';
import '../../../core/providers/tournament_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/display_formatters.dart';
import '../../../core/widgets/crystal_glass_nav_controls.dart';
import '../../../core/widgets/crystal_toast.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/sticky_form_scaffold.dart';

const List<String> _kProvinces = [
  'Punjab',
  'Sindh',
  'KPK',
  'Balochistan',
  'Islamabad',
  'Gilgit-Baltistan',
  'Azad Kashmir',
  'International',
];

class OrganizationOnboardingScreen extends ConsumerStatefulWidget {
  const OrganizationOnboardingScreen({super.key});

  @override
  ConsumerState<OrganizationOnboardingScreen> createState() => _OrganizationOnboardingScreenState();
}

class _OrganizationOnboardingScreenState extends ConsumerState<OrganizationOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _presidentNameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  DateTime? _foundationDate;
  String _selectedProvince = 'Punjab';
  final String _sanctioningBody = 'WAF / IFA Affiliated';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final session = ref.read(organizationSessionProvider);
    if (session.province != null && _kProvinces.contains(session.province)) {
      _selectedProvince = session.province!;
    }
    if (session.city != null) {
      _cityCtrl.text = session.city!;
    }
    if (session.presidentName != null) {
      _presidentNameCtrl.text = session.presidentName!;
    }
  }

  @override
  void dispose() {
    _presidentNameCtrl.dispose();
    _cityCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFoundationDate() async {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _foundationDate ?? DateTime(2015, 1, 1),
      firstDate: DateTime(1950),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.goldPrimary,
              onPrimary: Colors.black,
              surface: Color(0xFF0C101A),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF0C101A),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _foundationDate = picked;
      });
    }
  }

  Future<void> _submitOnboarding() async {
    if (!_formKey.currentState!.validate()) return;
    if (_foundationDate == null) {
      CrystalToast.error(context, 'Please select your organization foundation date.');
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    final session = ref.read(organizationSessionProvider);
    final orgId = session.orgId ?? '';
    final token = session.token;

    try {
      final repo = ref.read(organizationRepositoryProvider);
      await repo.completeOnboarding(
        organizationId: orgId,
        token: token,
        data: {
          'presidentName': _presidentNameCtrl.text.trim(),
          'foundationDate': _foundationDate!.toIso8601String(),
          'province': _selectedProvince,
          'city': _cityCtrl.text.trim(),
          'contactEmail': _emailCtrl.text.trim(),
          'contactPhone': _phoneCtrl.text.trim(),
          'sanctioningBody': _sanctioningBody,
        },
      );

      await ref.read(organizationSessionProvider.notifier).markOnboarded(
        presidentName: _presidentNameCtrl.text.trim(),
        province: _selectedProvince,
        city: _cityCtrl.text.trim(),
      );

      if (mounted) {
        CrystalToast.success(context, 'Federation profile activated successfully!');
        context.go('/organization/deck');
      }
    } catch (e) {
      if (mounted) {
        CrystalToast.error(context, 'Failed to complete onboarding: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(organizationSessionProvider);
    final orgName = ArmSphereFormatters.formatOrganizationName(
      session.orgName,
      fallback: 'Sanctioning Organization',
    );

    return StickyFormScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const CrystalBackButton(),
        title: const Text(
          'FEDERATION ONBOARDING',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: const [
          CrystalHomeButton(),
          SizedBox(width: 8),
        ],
      ),
      primaryActionLabel: 'ACTIVATE & OPEN DECK',
      primaryActionIcon: Icons.verified_outlined,
      isLoading: _isSubmitting,
      onPrimaryAction: _submitOnboarding,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Organization Identity Banner
            ElevatedActionCard(
              borderColor: AppTheme.goldPrimary.withValues(alpha: 0.45),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.goldPrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.goldPrimary.withValues(alpha: 0.5)),
                    ),
                    child: const Icon(
                      Icons.account_balance_rounded,
                      color: AppTheme.goldPrimary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orgName.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: AppTheme.goldPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'OFFICIAL GOVERNING BODY PROFILE SETUP',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. Section Header: Leadership
            _buildSectionHeader('EXECUTIVE LEADERSHIP', Icons.person_outline),
            const SizedBox(height: 12),

            TextFormField(
              controller: _presidentNameCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: _buildInputDecoration(
                label: 'President / Director Full Name',
                hint: 'e.g. Qaiser Khan',
                icon: Icons.person_outline,
              ),
              validator: (val) {
                if (val == null || val.trim().length < 2) {
                  return 'Please enter president / director full name';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Foundation Date Selector
            InkWell(
              onTap: _pickFoundationDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                decoration: BoxDecoration(
                  color: const Color(0x4D04060B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _foundationDate != null ? AppTheme.goldPrimary.withValues(alpha: 0.6) : const Color(0x38FFFFFF),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, color: AppTheme.goldPrimary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _foundationDate == null
                            ? 'Select Date of Foundation'
                            : 'Founded: ${DateFormat('MMMM d, yyyy').format(_foundationDate!)}',
                        style: TextStyle(
                          color: _foundationDate == null ? AppTheme.textSecondary : Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(Icons.edit_calendar_outlined, color: AppTheme.goldPrimary, size: 18),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 3. Section Header: Jurisdiction
            _buildSectionHeader('JURISDICTION & HEADQUARTERS', Icons.location_on_outlined),
            const SizedBox(height: 12),

            // Province Dropdown
            DropdownButtonFormField<String>(
              value: _selectedProvince,
              dropdownColor: const Color(0xFF0C101A),
              borderRadius: BorderRadius.circular(14),
              elevation: 16,
              iconEnabledColor: AppTheme.goldPrimary,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              decoration: _buildInputDecoration(
                label: 'Provincial Jurisdiction',
                hint: 'Select Province',
                icon: Icons.map_outlined,
              ).copyWith(
                fillColor: const Color(0xFF0C101A),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.goldPrimary.withValues(alpha: 0.35),
                    width: 1.1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.goldPrimary,
                    width: 1.6,
                  ),
                ),
              ),
              selectedItemBuilder: (context) => _kProvinces
                  .map(
                    (prov) => Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        prov,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              items: [
                for (int idx = 0; idx < _kProvinces.length; idx++)
                  DropdownMenuItem(
                    value: _kProvinces[idx],
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: idx < _kProvinces.length - 1
                            ? Border(
                                bottom: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  width: 0.8,
                                ),
                              )
                            : null,
                      ),
                      child: Text(
                        _kProvinces[idx],
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedProvince = val);
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _cityCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: _buildInputDecoration(
                label: 'Headquarters City',
                hint: 'e.g. Islamabad, Lahore, Peshawar',
                icon: Icons.location_city_outlined,
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Headquarters city is required';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // 4. Section Header: Official Communications
            _buildSectionHeader('OFFICIAL COMMUNICATIONS', Icons.contact_mail_outlined),
            const SizedBox(height: 12),

            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: _buildInputDecoration(
                label: 'Official Contact Email',
                hint: 'e.g. sanctions@paff.org.pk',
                icon: Icons.email_outlined,
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: _buildInputDecoration(
                label: 'Official Contact Phone',
                hint: 'e.g. +92 51 8904410',
                icon: Icons.phone_outlined,
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.goldPrimary, size: 16),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: AppTheme.goldPrimary,
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
      hintStyle: const TextStyle(color: Color(0x55FFFFFF), fontSize: 12),
      prefixIcon: Icon(icon, color: AppTheme.goldPrimary, size: 20),
      filled: true,
      fillColor: const Color(0x4D04060B),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x38FFFFFF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x38FFFFFF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.goldPrimary, width: 1.5),
      ),
    );
  }
}
