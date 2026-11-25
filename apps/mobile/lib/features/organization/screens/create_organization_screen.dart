import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/asset_paths.dart';
import '../../../core/providers/state_providers.dart';
import '../../../core/providers/tournament_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/crystal_glass_nav_controls.dart';
import '../../../core/widgets/crystal_toast.dart';
import '../../../core/widgets/crystal_stage_scaffold.dart';
import '../../../core/widgets/elevated_action_card.dart';

/// Streamlined Organization Creation & Provisioning Screen (`/organizations/create`).
///
/// Provisions a new sanctioning organization on ArmSphere with an organization name
/// and designated entrance access code. Once provisioned, the organization appears
/// immediately at the portal entrance (`/organization/portal`). On first-time entry
/// with the access code, the founder or staff completes official federation onboarding.
class CreateOrganizationScreen extends ConsumerStatefulWidget {
  const CreateOrganizationScreen({super.key});

  @override
  ConsumerState<CreateOrganizationScreen> createState() =>
      _CreateOrganizationScreenState();
}

class _CreateOrganizationScreenState
    extends ConsumerState<CreateOrganizationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  String _selectedProvince = 'Islamabad';
  bool _submitting = false;

  static const List<String> _kProvinces = [
    'Islamabad',
    'Punjab',
    'Sindh',
    'KPK',
    'Balochistan',
    'Gilgit-Baltistan',
    'Azad Kashmir',
    'National',
  ];

  @override
  void initState() {
    super.initState();
    _generateSuggestedCode();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  void _generateSuggestedCode() {
    final name = _nameCtrl.text.trim();
    final prefix = name.length >= 3
        ? name.substring(0, min(4, name.length)).replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase()
        : 'ORG';
    final randomSuffix = (Random().nextInt(9000) + 1000).toString();
    setState(() {
      _codeCtrl.text = '$prefix-2026-$randomSuffix';
    });
  }

  Future<void> _submitOrganization() async {
    if (!_formKey.currentState!.validate()) return;

    final orgName = _nameCtrl.text.trim();
    final customCode = _codeCtrl.text.trim().toUpperCase();

    if (orgName.length < 3) {
      CrystalToast.error(context, 'Please enter an official Organization Name (min 3 chars).');
      return;
    }

    if (customCode.length < 4) {
      CrystalToast.error(context, 'Access code must be at least 4 characters.');
      return;
    }

    setState(() => _submitting = true);
    HapticFeedback.mediumImpact();

    try {
      final orgRepo = ref.read(organizationRepositoryProvider);
      final authRepo = ref.read(authRepositoryProvider);

      final created = await orgRepo.createOrganization({
        'name': orgName,
        'accessCode': customCode,
        'country': 'PK',
        'province': _selectedProvince,
        'city': _cityCtrl.text.trim().isEmpty ? _selectedProvince : _cityCtrl.text.trim(),
        'sanctioningBody': 'ArmSphere Verified',
      });

      // Submit role application
      try {
        await authRepo.applyForRole(
          role: 'TOURNAMENT_OPERATOR',
          experienceDetails: 'Organization Provisioning: $orgName [Jurisdiction: $_selectedProvince]',
        );
      } catch (_) {}

      ref.invalidate(organizationsProvider);
      ref.invalidate(allOrganizationsProvider);

      if (!mounted) return;

      final newId = created['id']?.toString() ?? 'org_custom';
      final accessCode = (created['plainAccessCode'] ?? created['accessCode'] ?? customCode).toString();

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF0C101A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: AppTheme.goldPrimary.withValues(alpha: 0.6),
              width: 1.4,
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.goldPrimary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_rounded, color: AppTheme.goldPrimary, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'ORGANIZATION CREATED',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Congratulations! "$orgName" is now registered and visible at the Organization Entrance.',
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 16),
              const Text(
                'DESIGNATED ENTRANCE ACCESS CODE:',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.goldPrimary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF151C2C),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.goldPrimary.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        accessCode,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontMono,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.goldPrimary,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: AppTheme.goldPrimary, size: 18),
                      tooltip: 'Copy Code',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: accessCode));
                        CrystalToast.info(dialogContext, 'Access code copied to clipboard!');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Give this code to the organization founder/owner. When they enter the portal for the first time, they will be prompted to complete their official details.',
                style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted, height: 1.35),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.pushReplacement('/organizations/$newId');
              },
              child: const Text('VIEW IN DIRECTORY', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.goldPrimary,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.pushReplacement('/organization/portal');
              },
              icon: const Icon(Icons.login_rounded, size: 16),
              label: const Text(
                'GO TO ENTRANCE PORTAL',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      CrystalToast.error(context, 'Could not create organization: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: const CrystalBackButton(),
        title: const Text(
          'Create Organization',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: const [
          CrystalHomeButton(),
          SizedBox(width: 8),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: CrystalStageBackdrop(domain: ArmSphereStageDomain.governance),
          ),
          SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 48),
                children: [
                  // Info Card
                  ElevatedActionCard(
                    borderColor: AppTheme.goldPrimary.withValues(alpha: 0.4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.goldPrimary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.goldPrimary.withValues(alpha: 0.4)),
                          ),
                          child: const Icon(
                            Icons.shield_outlined,
                            color: AppTheme.goldPrimary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ORGANIZATION PROVISIONING',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  color: AppTheme.goldPrimary,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Create an organization with its official name and entrance access code. It will immediately show at the portal entrance for the founder to sign in and set up.',
                                style: TextStyle(
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

                  const SizedBox(height: 24),

                  // 1. Organization Name
                  const Text(
                    'ORGANIZATION NAME *',
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.goldPrimary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'e.g. Regional Armwrestling League',
                      hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0x33000000),
                      prefixIcon: const Icon(Icons.account_balance_rounded, color: AppTheme.goldPrimary, size: 20),
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
                    ),
                    onChanged: (val) {
                      if (_codeCtrl.text.isEmpty || _codeCtrl.text.startsWith('ORG-')) {
                        _generateSuggestedCode();
                      }
                    },
                    validator: (val) {
                      if (val == null || val.trim().length < 3) {
                        return 'Organization name must be at least 3 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // 2. Entrance Access Code
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ENTRANCE ACCESS CODE *',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.goldPrimary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: _generateSuggestedCode,
                        icon: const Icon(Icons.autorenew_rounded, size: 14, color: AppTheme.goldPrimary),
                        label: const Text(
                          'Generate',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.goldPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontMono,
                      color: AppTheme.goldPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. ORG-2026 or CUSTOM_CODE',
                      hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0x33000000),
                      prefixIcon: const Icon(Icons.key_rounded, color: AppTheme.goldPrimary, size: 20),
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
                    ),
                    validator: (val) {
                      if (val == null || val.trim().length < 4) {
                        return 'Access code must be at least 4 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'The founder will type this exact code to enter their Organization Workstation.',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),

                  const SizedBox(height: 20),

                  // 3. Provincial Jurisdiction
                  const Text(
                    'PROVINCE / JURISDICTION',
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.goldPrimary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedProvince,
                    dropdownColor: const Color(0xFF0C101A),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0x33000000),
                      prefixIcon: const Icon(Icons.map_outlined, color: AppTheme.goldPrimary, size: 20),
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
                    ),
                    items: _kProvinces.map((prov) {
                      return DropdownMenuItem(
                        value: prov,
                        child: Text(prov),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedProvince = val);
                    },
                  ),

                  const SizedBox(height: 20),

                  // 4. City (Optional)
                  const Text(
                    'HEADQUARTERS CITY (OPTIONAL)',
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.goldPrimary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _cityCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'e.g. Islamabad, Lahore, Peshawar',
                      hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0x33000000),
                      prefixIcon: const Icon(Icons.location_city_outlined, color: AppTheme.goldPrimary, size: 20),
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
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.goldPrimary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _submitting ? null : _submitOrganization,
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Icon(Icons.add_business_rounded, size: 20),
                      label: Text(
                        _submitting ? 'CREATING...' : 'CREATE & PROVISION ORGANIZATION',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
