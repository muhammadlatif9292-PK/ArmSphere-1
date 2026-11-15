import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/asset_paths.dart';
import '../../../core/providers/state_providers.dart';
import '../../../core/providers/tournament_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/armsphere_image.dart';
import '../../../core/widgets/crystal_glass_nav_controls.dart';
import '../../../core/widgets/crystal_toast.dart';
import '../../../core/widgets/crystal_stage_scaffold.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/status_chip.dart';

/// User-Facing 4-Step Organization Submission Wizard (`/organizations/create`).
///
/// Allows promoters, club leaders, and regional federations to register a
/// sanctioning organization on ArmSphere.
class CreateOrganizationScreen extends ConsumerStatefulWidget {
  const CreateOrganizationScreen({super.key});

  @override
  ConsumerState<CreateOrganizationScreen> createState() =>
      _CreateOrganizationScreenState();
}

class _CreateOrganizationScreenState
    extends ConsumerState<CreateOrganizationScreen> {
  int _step = 0;
  bool _submitting = false;

  // Step 1: Identity & Jurisdiction
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _provinceCtrl = TextEditingController();
  String _country = 'PK';
  String _sanctioningBody = 'WAF / IFA Affiliated Promotion';

  // Step 2: Promoter & Official Contact
  final _promoterCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  // Step 3: Crest & Stage Backdrop
  String _selectedBackdrop = 'ARENA_COLOSSEUM';

  static const List<String> _countries = ['PK', 'TR', 'AE', 'BG', 'US', 'CA', 'GB', 'GE', 'KZ'];
  static const List<String> _affiliations = [
    'WAF / IFA Affiliated Promotion',
    'National Governing Federation',
    'Provincial Armwrestling Association',
    'Independent Pro Supermatch League',
    'Regional Club & Tournament Series',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _provinceCtrl.dispose();
    _promoterCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _websiteCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitOrganization() async {
    if (_nameCtrl.text.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        CrystalSnackBar(
          content: const Text('Please enter an official Organization Name (min 3 chars).'),
          backgroundColor: AppTheme.error,
        ),
      );
      setState(() => _step = 0);
      return;
    }

    setState(() => _submitting = true);
    HapticFeedback.mediumImpact();

    try {
      final orgRepo = ref.read(organizationRepositoryProvider);
      final authRepo = ref.read(authRepositoryProvider);

      final created = await orgRepo.createOrganization({
        'name': _nameCtrl.text.trim(),
        'country': _country,
        'province': _provinceCtrl.text.trim().isEmpty
            ? 'National'
            : _provinceCtrl.text.trim(),
        'city': _cityCtrl.text.trim().isEmpty ? 'HQ' : _cityCtrl.text.trim(),
        'promoterName': _promoterCtrl.text.trim().isEmpty
            ? 'Executive Promoter'
            : _promoterCtrl.text.trim(),
        'contactEmail': _emailCtrl.text.trim(),
        'contactPhone': _phoneCtrl.text.trim(),
        'websiteUrl': _websiteCtrl.text.trim(),
        'sanctioningBody': _sanctioningBody,
        'description': _descriptionCtrl.text.trim().isEmpty
            ? 'Official armwrestling tournament organization and championship promotion.'
            : _descriptionCtrl.text.trim(),
        'stageBackdrop': _selectedBackdrop,
      });

      // Also submit a role application for ORGANIZATION_LEADER / TOURNAMENT_OPERATOR
      try {
        await authRepo.applyForRole(
          role: 'TOURNAMENT_OPERATOR',
          experienceDetails:
              'Organization Submission: ${_nameCtrl.text.trim()} ($_sanctioningBody) [Jurisdiction: ${_provinceCtrl.text.trim().isEmpty ? _country : _provinceCtrl.text.trim()}]',
        );
      } catch (_) {}

      ref.invalidate(organizationsProvider);
      ref.invalidate(allOrganizationsProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        CrystalSnackBar(
          content: const Text(
            'Organization application submitted for federation verification.',
          ),
          backgroundColor: AppTheme.emerald,
        ),
      );

      final newId = created['id']?.toString() ?? 'org_paff_national';
      context.pushReplacement('/organizations/$newId');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        CrystalSnackBar(
          content: Text('Could not submit organization: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
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
          'Register Organization',
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
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 48),
              children: [
                // 4-Step Progress Bar
                Row(
                  children: List.generate(4, (idx) {
                    final active = idx <= _step;
                    final labels = [
                      '1. Identity',
                      '2. Promoter',
                      '3. Crest & Stage',
                      '4. Review',
                    ];
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _step = idx);
                        },
                        child: Padding(
                          padding: EdgeInsets.only(right: idx < 3 ? 6 : 0),
                          child: Column(
                            children: [
                              Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: active
                                      ? AppTheme.goldPrimary
                                      : const Color(0x33FFFFFF),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                labels[idx],
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: active
                                      ? AppTheme.goldPrimary
                                      : AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),

                ElevatedActionCard(
                  borderColor: AppTheme.goldPrimary.withValues(alpha: 0.4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_step == 0) _buildStep1Identity(),
                      if (_step == 1) _buildStep2Promoter(),
                      if (_step == 2) _buildStep3Branding(),
                      if (_step == 3) _buildStep4Review(),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          if (_step > 0) ...[
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _submitting
                                    ? null
                                    : () => setState(() => _step--),
                                child: const Text('BACK'),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.goldPrimary,
                                foregroundColor: Colors.black,
                                minimumSize: const Size.fromHeight(50),
                              ),
                              onPressed: _submitting
                                  ? null
                                  : () {
                                      if (_step < 3) {
                                        HapticFeedback.selectionClick();
                                        setState(() => _step++);
                                      } else {
                                        _submitOrganization();
                                      }
                                    },
                              icon: Icon(
                                _step < 3
                                    ? Icons.arrow_forward_rounded
                                    : Icons.verified_user_rounded,
                                size: 18,
                              ),
                              label: Text(
                                _step < 3
                                    ? 'CONTINUE TO STEP ${_step + 2}'
                                    : (_submitting
                                        ? 'SUBMITTING...'
                                        : 'SUBMIT FOR VERIFICATION'),
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1Identity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'STEP 1 · ORGANIZATION IDENTITY & JURISDICTION',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: AppTheme.goldPrimary,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _nameCtrl,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Official Organization / League Name *',
            hintText: 'e.g. Punjab Pro Armwrestling League',
            prefixIcon: Icon(Icons.shield_outlined),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _country,
          dropdownColor: const Color(0xFF0E1525),
          decoration: const InputDecoration(
            labelText: 'Country Code',
            prefixIcon: Icon(Icons.flag_outlined),
          ),
          items: _countries
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _country = v);
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _provinceCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Province / State',
                  hintText: 'e.g. Punjab',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _cityCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Headquarters City',
                  hintText: 'e.g. Lahore',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _sanctioningBody,
          isExpanded: true,
          dropdownColor: const Color(0xFF0E1525),
          decoration: const InputDecoration(
            labelText: 'Sanctioning Affiliation',
            prefixIcon: Icon(Icons.verified_outlined),
          ),
          items: _affiliations
              .map((a) => DropdownMenuItem(value: a, child: Text(a)))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _sanctioningBody = v);
          },
        ),
      ],
    );
  }

  Widget _buildStep2Promoter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'STEP 2 · PROMOTER & OFFICIAL CREDENTIALS',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: AppTheme.goldPrimary,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _promoterCtrl,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            labelText: 'President / Lead Promoter Full Name *',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Official Sanctioning Contact Email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Official Contact Phone / WhatsApp',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _websiteCtrl,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Website or Social Broadcast Channel',
            prefixIcon: Icon(Icons.language_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionCtrl,
          maxLines: 3,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Organization Charter & Mission',
            hintText: 'Describe your tournament series, ruleset, and regional scope...',
          ),
        ),
      ],
    );
  }

  Widget _buildStep3Branding() {
    final stages = [
      ('ARENA_COLOSSEUM', 'Championship Arena Stage', ArmSphereAssets.defaultTournament),
      ('GOVERNANCE_CHAMBER', 'Federation Council Stage', ArmSphereAssets.sealFed),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'STEP 3 · CREST & STAGE BACKDROP',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: AppTheme.goldPrimary,
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Container(
            width: 88,
            height: 88,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.goldPrimary, width: 1.6),
            ),
            child: const ArmSphereImage(
              assetPath: ArmSphereAssets.sealFed,
              fit: BoxFit.contain,
              semanticLabel: 'Organization Crest Preview',
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Select Default Dossier Stage Backdrop:',
          style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 10),
        for (final st in stages)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => setState(() => _selectedBackdrop = st.$1),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedBackdrop == st.$1
                        ? AppTheme.goldPrimary
                        : const Color(0x33FFFFFF),
                    width: _selectedBackdrop == st.$1 ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedBackdrop == st.$1
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: _selectedBackdrop == st.$1
                          ? AppTheme.goldPrimary
                          : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        st.$2,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStep4Review() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'STEP 4 · REVIEW & FEDERATION VERIFICATION',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: AppTheme.goldPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: AppTheme.recessedObsidianWellDecoration(radius: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _nameCtrl.text.trim().isEmpty
                          ? 'Unnamed Organization'
                          : _nameCtrl.text.trim(),
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const StatusChip(
                    label: 'PENDING REVIEW',
                    color: AppTheme.cyan,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Jurisdiction: ${_cityCtrl.text.trim()}, ${_provinceCtrl.text.trim()} ($_country)',
                style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                'Promoter: ${_promoterCtrl.text.trim().isEmpty ? "Executive Promoter" : _promoterCtrl.text.trim()}',
                style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                'Affiliation: $_sanctioningBody',
                style: const TextStyle(fontSize: 12.5, color: AppTheme.goldPrimary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Upon submission, your organization dossier will be created with PENDING status and queued for National Director / System Admin verification.',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
