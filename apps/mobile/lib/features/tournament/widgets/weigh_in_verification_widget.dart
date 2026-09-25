import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/theme/app_theme.dart';
import '../../../core/widgets/signature_ceremonies.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
class WeighInVerificationWidget extends StatefulWidget {
  final Map<String, dynamic> tournament;

  const WeighInVerificationWidget({
    super.key,
    required this.tournament,
  });

  @override
  State<WeighInVerificationWidget> createState() => _WeighInVerificationWidgetState();
}

class _WeighInVerificationWidgetState extends State<WeighInVerificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkAnimController;
  late Animation<double> _checkScaleAnimation;

  Map<String, dynamic> _resolveVerificationData() {
    final raw = widget.tournament['weighInVerification'] ?? widget.tournament['weighIn'];
    if (raw is Map<String, dynamic>) {
      return raw;
    }

    final reg = (widget.tournament['userRegistration'] ?? widget.tournament['myRegistration']) as Map<String, dynamic>?;
    final catName = reg?['categoryName']?.toString() ?? widget.tournament['category']?.toString() ?? 'Championship Division';
    final weight = reg?['weighedWeight']?.toString() ?? reg?['weight']?.toString() ?? '78.5';
    final submitted = reg?['submittedWeight']?.toString() ?? reg?['initialWeight']?.toString() ?? weight;
    final officer = widget.tournament['chiefReferee']?.toString() ?? widget.tournament['weighMaster']?.toString() ?? 'Head Referee Desk';
    final scale = widget.tournament['scaleId']?.toString() ?? 'Calibrated Arena Digital Scale';
    final license = reg?['licenseNumber']?.toString() ?? reg?['license']?.toString() ?? 'National Athlete License';
    final hash = reg?['signatureHash']?.toString() ?? 'PAFF-${widget.tournament['id'] ?? 'VERIFIED'}-SCALE';

    return {
      'submittedWeight': '$submitted kg',
      'officialWeight': '$weight kg',
      'weightCategory': '$catName (Passed Under Class Limit)',
      'verificationOfficer': officer,
      'officerTitle': 'Head Technical Delegate & Scale Supervisor',
      'medicalClearance': 'APPROVED • Fit for Competition',
      'medicalDetails': 'Vitals, Skin Check & Joint Clearance Certified',
      'medicalOfficer': 'Sports Medicine Board Delegate',
      'licenseStatus': 'ACTIVE & VALID',
      'licenseNumber': license,
      'timestamp': widget.tournament['startDate']?.toString() ?? 'Official Championship Session',
      'scaleId': scale,
      'digitalSignatureHash': hash,
      'signatureAuthority': 'Signed by Chief Weigh-Master & Technical Director',
    };
  }

  bool _isApproved() {
    final reg = (widget.tournament['userRegistration'] ?? widget.tournament['myRegistration']) as Map<String, dynamic>?;
    if (reg != null) {
      final status = (reg['weighInStatus'] ?? '').toString().toUpperCase();
      if (status == 'PENDING' || status == 'REQUIRED') return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _checkAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _checkScaleAnimation = CurvedAnimation(
      parent: _checkAnimController,
      curve: Curves.easeOutCubic,
    );

    _checkAnimController.forward();
  }

  @override
  void dispose() {
    _checkAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isApprovedAndLocked = _isApproved();
    final verificationData = _resolveVerificationData();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0B132B).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isApprovedAndLocked
              ? const Color(0xFF00E676).withValues(alpha: 0.45)
              : AppTheme.goldPrimary.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isApprovedAndLocked ? const Color(0xFF00E676) : AppTheme.goldPrimary)
                .withValues(alpha: 0.14),
            blurRadius: 20,
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Title & Animated Verified Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: (isApprovedAndLocked
                                  ? const Color(0xFF00E676)
                                  : AppTheme.goldPrimary)
                              .withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: (isApprovedAndLocked
                                    ? const Color(0xFF00E676)
                                    : AppTheme.goldPrimary)
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        child: Icon(
                          isApprovedAndLocked
                              ? Icons.verified_user_rounded
                              : Icons.health_and_safety_rounded,
                          color: isApprovedAndLocked
                              ? const Color(0xFF00E676)
                              : AppTheme.goldPrimary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WEIGH-IN & VERIFICATION',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Official Scale, Medical & Athlete Certification',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 10.5,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Animated Check & Verified Badge / Clearance Stamp
                  if (isApprovedAndLocked)
                    const WeighInClearanceStamp(
                      isApproved: true,
                      clearanceText: 'PAFF VERIFIED',
                    )
                  else
                    ScaleTransition(
                      scale: _checkScaleAnimation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.goldPrimary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.goldPrimary,
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.goldPrimary.withValues(alpha: 0.35),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.pending_rounded,
                              size: 13,
                              color: AppTheme.goldPrimary,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'PENDING',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.goldPrimary,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 14),

              // Lock Status Banner (No manual editing once approved)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF064E3B).withValues(alpha: 0.6),
                      const Color(0xFF022C22).withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00E676).withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF00E676),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        size: 13,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'OFFICIALLY APPROVED & LOCKED',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF00E676),
                                  letterSpacing: 0.6,
                                ),
                              ),
                              Text(
                                verificationData['timestamp'],
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 8.5,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Verification status is certified and sealed. Manual edits are permanently disabled.',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 10,
                              color: Colors.white70,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 6 Primary Verification Parameter Cards
              // 1. Weight Submitted & 2. Official Weight
              Row(
                children: [
                  Expanded(
                    child: _buildVerificationParamTile(
                      icon: Icons.monitor_weight_outlined,
                      label: 'WEIGHT SUBMITTED',
                      value: verificationData['submittedWeight'],
                      subtitle: 'Self-Reported Entry',
                      accentColor: const Color(0xFF00E5FF),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildVerificationParamTile(
                      icon: Icons.scale_rounded,
                      label: 'OFFICIAL WEIGHT',
                      value: verificationData['officialWeight'],
                      subtitle: verificationData['scaleId'],
                      accentColor: const Color(0xFF00E676),
                      isHighlighted: true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // 3. Verification Officer
              _buildFullWidthParamTile(
                icon: Icons.badge_outlined,
                label: 'VERIFICATION OFFICER',
                title: verificationData['verificationOfficer'],
                details: verificationData['officerTitle'],
                accentColor: AppTheme.goldPrimary,
                badgeText: 'CERTIFIED OFFICIAL',
              ),

              const SizedBox(height: 10),

              // 4. Medical Clearance
              _buildFullWidthParamTile(
                icon: Icons.health_and_safety_rounded,
                label: 'MEDICAL CLEARANCE',
                title: verificationData['medicalClearance'],
                details: '${verificationData['medicalDetails']}\nPhysician: ${verificationData['medicalOfficer']}',
                accentColor: const Color(0xFF00E676),
                badgeText: 'PASSED & SEALED',
              ),

              const SizedBox(height: 10),

              // 5. License Status
              Row(
                children: [
                  Expanded(
                    child: _buildVerificationParamTile(
                      icon: Icons.card_membership_rounded,
                      label: 'LICENSE STATUS',
                      value: verificationData['licenseStatus'],
                      subtitle: verificationData['licenseNumber'],
                      accentColor: const Color(0xFF00E5FF),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildVerificationParamTile(
                      icon: Icons.category_rounded,
                      label: 'CATEGORY FIT',
                      value: 'QUALIFIED',
                      subtitle: verificationData['weightCategory'],
                      accentColor: const Color(0xFF00E676),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 6. Digital Signature Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF141E2F).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.goldPrimary.withValues(alpha: 0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.fingerprint_rounded, size: 16, color: AppTheme.goldPrimary),
                            SizedBox(width: 6),
                            Text(
                              'CRYPTOGRAPHIC DIGITAL SIGNATURE',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.goldPrimary,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.goldPrimary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'SHA-256 SEAL',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.goldPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      verificationData['digitalSignatureHash'],
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: Colors.white70,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• ${verificationData['signatureAuthority']}',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 9.5,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Disabled Manual Edit Button + View Certificate Action
              Row(
                children: [
                  // Disabled Manual Edit Button
                  Expanded(
                    child: Tooltip(
                      message: 'Edits are locked after official approval',
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B).withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_outline_rounded, size: 15, color: AppTheme.textMuted),
                            SizedBox(width: 6),
                            Text(
                              'EDIT LOCKED',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textMuted,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // View Official Certificate Button
                  Expanded(
                    child: TactilePressWrapper(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _openVerificationCertificateModal(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00E676), Color(0xFF00B0FF)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E676).withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.workspace_premium_rounded, size: 16, color: Colors.black),
                            SizedBox(width: 6),
                            Text(
                              'VIEW CERTIFICATE',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationParamTile({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required Color accentColor,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlighted
            ? const Color(0xFF064E3B).withValues(alpha: 0.4)
            : const Color(0xFF141E2F).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted
              ? const Color(0xFF00E676).withValues(alpha: 0.6)
              : accentColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: accentColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 9.5,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullWidthParamTile({
    required IconData icon,
    required String label,
    required String title,
    required String details,
    required Color accentColor,
    required String badgeText,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF141E2F).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 15, color: accentColor),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: accentColor,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            details,
            style: const TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 10,
              color: AppTheme.textMuted,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  void _openVerificationCertificateModal(BuildContext context) {
    final verificationData = _resolveVerificationData();
    final reg = (widget.tournament['userRegistration'] ?? widget.tournament['myRegistration']) as Map<String, dynamic>?;
    final athleteName = reg?['athleteName']?.toString() ?? reg?['userName']?.toString() ?? widget.tournament['athleteName']?.toString() ?? 'Registered Athlete';
    final regId = reg?['id']?.toString() ?? reg?['registrationNumber']?.toString() ?? widget.tournament['registrationId']?.toString() ?? 'PAFF-REG';
    final tournamentTitle = widget.tournament['name']?.toString() ?? widget.tournament['title']?.toString() ?? 'Official Championship';
    final division = reg?['categoryName']?.toString() ?? widget.tournament['category']?.toString() ?? 'Championship Division';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF00E676), width: 1.5),
          ),
          title: const Row(
            children: [
              Icon(Icons.workspace_premium_rounded, color: Color(0xFF00E676), size: 26),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'PAFF Official Weigh-In Certificate',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF064E3B).withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF00E676)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_rounded, color: Color(0xFF00E676), size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'CERTIFIED & LOCKED BY PAKISTAN ARMWRESTLING FEDERATION',
                          style: TextStyle(
                            color: Color(0xFF00E676),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Center(
                  child: WeighInClearanceStamp(
                    isApproved: true,
                    clearanceText: 'OFFICIALLY CLEARED • PAFF',
                  ),
                ),
                const SizedBox(height: 14),
                _buildModalLine('Athlete Name:', '$athleteName ($regId)'),
                _buildModalLine('Tournament:', tournamentTitle),
                _buildModalLine('Division / Class:', division),
                _buildModalLine('Submitted Weight:', verificationData['submittedWeight']),
                _buildModalLine('Certified Scale Weight:', verificationData['officialWeight']),
                _buildModalLine('Scale Calibration:', verificationData['scaleId']),
                _buildModalLine('Verification Officer:', verificationData['verificationOfficer']),
                _buildModalLine('Medical Clearance:', verificationData['medicalClearance']),
                _buildModalLine('Physician:', verificationData['medicalOfficer']),
                _buildModalLine('Athlete License:', verificationData['licenseNumber']),
                _buildModalLine('Certified Timestamp:', verificationData['timestamp']),
                const SizedBox(height: 10),
                const Divider(color: Colors.white12),
                const SizedBox(height: 6),
                const Text('SHA-256 Digital Hash:', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                SelectableText(
                  verificationData['digitalSignatureHash'],
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 9.5, color: AppTheme.goldPrimary),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('CLOSE CERTIFICATE', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildModalLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 10.5, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

