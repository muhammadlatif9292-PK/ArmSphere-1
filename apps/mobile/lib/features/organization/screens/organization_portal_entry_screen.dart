import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/repositories.dart';
import '../../../core/providers/state_providers.dart';
import '../../../core/providers/organization_session_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/crystal_stage_scaffold.dart';
import '../../../core/widgets/crystal_toast.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';

class OrganizationPortalEntryScreen extends ConsumerStatefulWidget {
  const OrganizationPortalEntryScreen({super.key});

  @override
  ConsumerState<OrganizationPortalEntryScreen> createState() =>
      _OrganizationPortalEntryScreenState();
}

class _OrganizationPortalEntryScreenState
    extends ConsumerState<OrganizationPortalEntryScreen> {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _codeFocusNode = FocusNode();

  List<Map<String, dynamic>> _organizations = <Map<String, dynamic>>[];
  Map<String, dynamic>? _selectedOrganization;
  bool _isLoadingOrganizations = true;
  bool _isSubmitting = false;
  bool _obscureCode = true;
  bool _isCodeFocused = false;

  @override
  void initState() {
    super.initState();
    _codeFocusNode.addListener(_onFocusChange);
    _loadApprovedOrganizations();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isCodeFocused = _codeFocusNode.hasFocus;
      });
    }
  }

  @override
  void dispose() {
    _codeFocusNode.removeListener(_onFocusChange);
    _codeFocusNode.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadApprovedOrganizations() async {
    setState(() => _isLoadingOrganizations = true);
    try {
      final repo = ref.read(organizationRepositoryProvider);
      final list = await repo.getOrganizations();
      if (mounted) {
        setState(() {
          _organizations = list;
          _selectedOrganization = list.isNotEmpty ? list.first : null;
          _isLoadingOrganizations = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _organizations = const [];
          _selectedOrganization = null;
          _isLoadingOrganizations = false;
        });
      }
    }
  }

  Future<void> _openOrganizationPickerSheet() async {
    HapticFeedback.lightImpact();
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: const Color(0xFF070A11),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.68,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF070A11),
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              border: Border(
                top: BorderSide(color: Color(0x73D4AF37), width: 1.2),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0x4DFFFFFF),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 3.5,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppTheme.goldPrimary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'SELECT SANCTIONING FEDERATION',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 0.8,
                          color: AppTheme.goldPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppTheme.textSecondary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_organizations.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(Icons.shield_outlined, size: 40, color: AppTheme.textMuted),
                        const SizedBox(height: 12),
                        const Text(
                          'No Organizations Found',
                          style: TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.goldPrimary,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            context.push('/organizations/create');
                          },
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                          label: const Text('REGISTER NEW FEDERATION', style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Flexible(
                    child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _organizations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final org = _organizations[index];
                      final orgId = org['id']?.toString() ?? '';
                      final isSelected =
                          _selectedOrganization?['id']?.toString() == orgId;
                      final name =
                          (org['name'] ?? 'Sanctioning Organization').toString();
                      final province = (org['province'] ?? '').toString();
                      final city = (org['city'] ?? '').toString();
                      final locationLabel = [city, province]
                          .where((s) => s.trim().isNotEmpty)
                          .join(' • ');

                      return TactilePressWrapper(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(sheetContext).pop(org);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x4D04060B),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0x73D4AF37)
                                  : const Color(0x38FFFFFF),
                              width: isSelected ? 1.2 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.goldPrimary.withValues(alpha: 0.14)
                                      : const Color(0x26FFFFFF),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.goldPrimary.withValues(alpha: 0.5)
                                        : const Color(0x38FFFFFF),
                                  ),
                                ),
                                child: Icon(
                                  Icons.shield_outlined,
                                  size: 19,
                                  color: isSelected
                                      ? AppTheme.goldPrimary
                                      : AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontFamily: 'Space Grotesk',
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13.5,
                                        color: isSelected
                                            ? AppTheme.goldPrimary
                                            : AppTheme.textPrimary,
                                      ),
                                    ),
                                    if (locationLabel.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        locationLabel,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Icon(
                                isSelected
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_off_rounded,
                                color: isSelected
                                    ? AppTheme.goldPrimary
                                    : const Color(0x4DFFFFFF),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
            ),
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedOrganization = selected;
      });
    }
  }

  Future<void> _submitAccessCode() async {
    final selectedOrg = _selectedOrganization;
    final code = _codeController.text.trim().toUpperCase();

    if (selectedOrg == null) {
      HapticFeedback.heavyImpact();
      CrystalToast.error(context, 'Please select a sanctioning organization.');
      return;
    }

    if (code.length < 4) {
      HapticFeedback.heavyImpact();
      CrystalToast.error(
        context,
        'Enter a valid cryptographic organization access code.',
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);

    try {
      final orgId = (selectedOrg['id'] ?? '').toString();
      await ref.read(organizationSessionProvider.notifier).loginWithCode(
            organizationId: orgId,
            accessCode: code,
          );

      if (!mounted) return;
      final sessionState = ref.read(organizationSessionProvider);
      HapticFeedback.mediumImpact();
      if (!sessionState.isOnboarded) {
        context.go('/organization/onboarding');
      } else {
        context.go('/organization/deck');
      }
    } catch (_) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      CrystalToast.error(context, 'Invalid access code for this organization.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgName =
        (_selectedOrganization?['name'] ?? 'Select Approved Federation')
            .toString();
    final orgProvince = (_selectedOrganization?['province'] ?? '').toString();
    final orgCity = (_selectedOrganization?['city'] ?? '').toString();
    final orgSanction =
        (_selectedOrganization?['sanctioningBody'] ?? 'Approved Federation')
            .toString();
    final locationSubtitle = [orgCity, orgProvince]
        .where((s) => s.trim().isNotEmpty)
        .join(' • ');

    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: CrystalStageBackdrop(domain: ArmSphereStageDomain.authWalkout),
          ),
          SafeArea(
            child: Column(
              children: [
                // ── Top Forged-Crystal App Header ───────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      TactilePressWrapper(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/welcome');
                          }
                        },
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0x4D04060B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0x4DFFFFFF),
                              width: 1.0,
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.goldPrimary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0x73D4AF37),
                            width: 1.1,
                          ),
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: AppTheme.goldPrimary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ORGANIZATION PORTAL',
                              style: TextStyle(
                                fontFamily: 'Space Grotesk',
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                letterSpacing: 1.0,
                                color: AppTheme.goldPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'SANCTIONING BODIES & EXECUTIVE CONTROL DECK',
                              style: TextStyle(
                                fontFamily: 'Space Grotesk',
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                                letterSpacing: 0.7,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── 1. Approved Federation Selector Card ────────
                            Row(
                              children: [
                                Container(
                                  width: 3.5,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: AppTheme.goldPrimary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '1. APPROVED SANCTIONING FEDERATION',
                                  style: TextStyle(
                                    fontFamily: 'Space Grotesk',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TactilePressWrapper(
                              onTap: _isLoadingOrganizations
                                  ? null
                                  : _openOrganizationPickerSheet,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0x5904060B),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0x73D4AF37),
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppTheme.goldPrimary
                                            .withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppTheme.goldPrimary
                                              .withValues(alpha: 0.45),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.verified_user_outlined,
                                        color: AppTheme.goldPrimary,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: _isLoadingOrganizations
                                          ? const Text(
                                              'Loading verified federations...',
                                              style: TextStyle(
                                                fontFamily: 'Space Grotesk',
                                                fontSize: 13,
                                                color: AppTheme.textSecondary,
                                              ),
                                            )
                                          : Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  orgName,
                                                  style: const TextStyle(
                                                    fontFamily: 'Space Grotesk',
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 14.5,
                                                    color: AppTheme.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  locationSubtitle.isNotEmpty
                                                      ? '$locationSubtitle • $orgSanction'
                                                      : orgSanction,
                                                  style: const TextStyle(
                                                    fontSize: 11.5,
                                                    color:
                                                        AppTheme.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0x33D4AF37),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0x73D4AF37),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'CHANGE',
                                            style: TextStyle(
                                              fontFamily: 'Space Grotesk',
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.6,
                                              color: AppTheme.goldPrimary,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(
                                            Icons.expand_more_rounded,
                                            size: 15,
                                            color: AppTheme.goldPrimary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // ── 2. Cryptographic Access Code Field ──────────
                            Row(
                              children: [
                                Container(
                                  width: 3.5,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: AppTheme.goldPrimary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '2. CRYPTOGRAPHIC ACCESS CODE',
                                  style: TextStyle(
                                    fontFamily: 'Space Grotesk',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x5904060B),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _isCodeFocused
                                      ? AppTheme.goldPrimary
                                      : const Color(0x52FFFFFF),
                                  width: _isCodeFocused ? 1.5 : 1.1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.key_rounded,
                                    color: _isCodeFocused
                                        ? AppTheme.goldPrimary
                                        : AppTheme.textSecondary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: _codeController,
                                      focusNode: _codeFocusNode,
                                      obscureText: _obscureCode,
                                      textCapitalization:
                                          TextCapitalization.characters,
                                      autocorrect: false,
                                      enableSuggestions: false,
                                      onSubmitted: (_) => _submitAccessCode(),
                                      style: const TextStyle(
                                        fontFamily: 'JetBrains Mono',
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        letterSpacing: 1.6,
                                        color: AppTheme.goldPrimary,
                                      ),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        hintText: 'PAFF-2026-XXXX',
                                        hintStyle: TextStyle(
                                          fontFamily: 'JetBrains Mono',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          letterSpacing: 1.4,
                                          color: Color(0x66FFFFFF),
                                        ),
                                      ),
                                      inputFormatters: [
                                        TextInputFormatter.withFunction(
                                          (oldValue, newValue) =>
                                              newValue.copyWith(
                                            text: newValue.text.toUpperCase(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        _obscureCode = !_obscureCode;
                                      });
                                    },
                                    tooltip: _obscureCode
                                        ? 'Reveal Access Code'
                                        : 'Hide Access Code',
                                    icon: Icon(
                                      _obscureCode
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: AppTheme.goldPrimary,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 28),

                            // ── 3. Unlock Executive Deck CTA Button ─────────
                            TactilePressWrapper(
                              onTap: _isSubmitting ? null : _submitAccessCode,
                              child: Container(
                                height: 54,
                                decoration: BoxDecoration(
                                  color: const Color(0x26D4AF37),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppTheme.goldPrimary,
                                    width: 1.4,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.3,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            AppTheme.goldPrimary,
                                          ),
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.lock_open_rounded,
                                            size: 19,
                                            color: AppTheme.goldPrimary,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            'UNLOCK EXECUTIVE DECK',
                                            style: TextStyle(
                                              fontFamily: 'Space Grotesk',
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1.0,
                                              color: AppTheme.goldPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
            ),
          ),
        ],
      ),
    );
  }
}
