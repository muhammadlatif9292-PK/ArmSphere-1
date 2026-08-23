import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
class WeighInVerificationWidget extends StatefulWidget {
  final Map<String, dynamic> tournament;

  const WeighInVerificationWidget({
    Key? key,
    required this.tournament,
  }) : super(key: key);

  @override
  State<WeighInVerificationWidget> createState() => _WeighInVerificationWidgetState();
}

class _WeighInVerificationWidgetState extends State<WeighInVerificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkAnimController;
  late Animation<double> _checkScaleAnimation;

  final bool _isApprovedAndLocked = true; // Default approved & locked as per requirements

  final Map<String, dynamic> _verificationData = {
    'submittedWeight': '79.2 kg (174.6 lbs)',
    'officialWeight': '78.8 kg (173.7 lbs)',
    'weightCategory': 'Senior Men Right -80kg (Pass • 1.2kg under limit)',
    'verificationOfficer': 'Chief Referee Master Tariq Mahmood (Cert #PAFF-882)',
    'officerTitle': 'PAFF Head Technical Delegate & Scale Supervisor',
    'medicalClearance': 'APPROVED • Fit for High-Impact Competition',
    'medicalDetails': 'BP 120/80, HR 68 bpm, Skin Check Passed, Grip & Joint Clearance OK',
    'medicalOfficer': 'Dr. Kamran Akram (PAFF Sports Medicine Board)',
    'licenseStatus': 'ACTIVE & VALID',
    'licenseNumber': 'PK-2026-0891 (National Professional Athlete License)',
    'timestamp': 'July 29, 2026 at 08:45 AM PST',
    'scaleId': 'Calibrated Digital Scale #PAFF-SCALE-04',
    'digitalSignatureHash': '0x9F8B2C41D80E31A7B5F092E41288C9A321F09A8B',
    'signatureAuthority': 'Signed by Chief Weigh-Master & Technical Director',
  };

  @override
  void initState() {
    super.initState();
    _checkAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _checkScaleAnimation = CurvedAnimation(
      parent: _checkAnimController,
      curve: Curves.elasticOut,
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xFF0B132B).withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isApprovedAndLocked
              ? Color(0xFF00E676).withOpacity(0.45)
              : AppTheme.goldPrimary.withOpacity(0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (_isApprovedAndLocked ? Color(0xFF00E676) : AppTheme.goldPrimary)
                .withOpacity(0.14),
            blurRadius: 20,
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.55),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.all(18.0),
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
                        padding: EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: (_isApprovedAndLocked
                                  ? Color(0xFF00E676)
                                  : AppTheme.goldPrimary)
                              .withOpacity(0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: (_isApprovedAndLocked
                                    ? Color(0xFF00E676)
                                    : AppTheme.goldPrimary)
                                .withOpacity(0.5),
                          ),
                        ),
                        child: Icon(
                          _isApprovedAndLocked
                              ? Icons.verified_user_rounded
                              : Icons.health_and_safety_rounded,
                          color: _isApprovedAndLocked
                              ? Color(0xFF00E676)
                              : AppTheme.goldPrimary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
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

                  // Animated Check & Verified Badge
                  ScaleTransition(
                    scale: _checkScaleAnimation,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: (_isApprovedAndLocked
                                ? Color(0xFF00E676)
                                : AppTheme.goldPrimary)
                            .withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isApprovedAndLocked
                              ? Color(0xFF00E676)
                              : AppTheme.goldPrimary,
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_isApprovedAndLocked
                                    ? Color(0xFF00E676)
                                    : AppTheme.goldPrimary)
                                .withOpacity(0.35),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isApprovedAndLocked
                                ? Icons.check_circle_rounded
                                : Icons.pending_rounded,
                            size: 13,
                            color: _isApprovedAndLocked
                                ? Color(0xFF00E676)
                                : AppTheme.goldPrimary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _isApprovedAndLocked ? 'VERIFIED' : 'PENDING',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              color: _isApprovedAndLocked
                                  ? Color(0xFF00E676)
                                  : AppTheme.goldPrimary,
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
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF064E3B).withOpacity(0.6),
                      Color(0xFF022C22).withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Color(0xFF00E676).withOpacity(0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Color(0xFF00E676),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
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
                                _verificationData['timestamp'],
                                style: TextStyle(
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
                      value: _verificationData['submittedWeight'],
                      subtitle: 'Self-Reported Entry',
                      accentColor: Color(0xFF00E5FF),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildVerificationParamTile(
                      icon: Icons.scale_rounded,
                      label: 'OFFICIAL WEIGHT',
                      value: _verificationData['officialWeight'],
                      subtitle: _verificationData['scaleId'],
                      accentColor: Color(0xFF00E676),
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
                title: _verificationData['verificationOfficer'],
                details: _verificationData['officerTitle'],
                accentColor: AppTheme.goldPrimary,
                badgeText: 'CERTIFIED OFFICIAL',
              ),

              const SizedBox(height: 10),

              // 4. Medical Clearance
              _buildFullWidthParamTile(
                icon: Icons.health_and_safety_rounded,
                label: 'MEDICAL CLEARANCE',
                title: _verificationData['medicalClearance'],
                details: '${_verificationData['medicalDetails']}\nPhysician: ${_verificationData['medicalOfficer']}',
                accentColor: Color(0xFF00E676),
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
                      value: _verificationData['licenseStatus'],
                      subtitle: _verificationData['licenseNumber'],
                      accentColor: Color(0xFF00E5FF),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildVerificationParamTile(
                      icon: Icons.category_rounded,
                      label: 'CATEGORY FIT',
                      value: 'PASS (-80kg)',
                      subtitle: _verificationData['weightCategory'],
                      accentColor: Color(0xFF00E676),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 6. Digital Signature Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF141E2F).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
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
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.goldPrimary.withOpacity(0.2),
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
                      _verificationData['digitalSignatureHash'],
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: Colors.white70,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• ${_verificationData['signatureAuthority']}',
                      style: TextStyle(
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
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Color(0xFF1E293B).withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
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
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [Color(0xFF00E676), Color(0xFF00B0FF)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF00E676).withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
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
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlighted
            ? Color(0xFF064E3B).withOpacity(0.4)
            : Color(0xFF141E2F).withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted
              ? Color(0xFF00E676).withOpacity(0.6)
              : accentColor.withOpacity(0.25),
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
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF141E2F).withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.3)),
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
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: accentColor.withOpacity(0.4)),
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Color(0xFF00E676), width: 1.5),
          ),
          title: Row(
            children: const [
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
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF064E3B).withOpacity(0.4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF00E676)),
                  ),
                  child: Row(
                    children: const [
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
                _buildModalLine('Athlete Name:', 'Tariq Z. (National Reg #8821)'),
                _buildModalLine('Tournament:', 'Pakistan National Armwrestling Championship 2026'),
                _buildModalLine('Division / Class:', 'Senior Men Right Arm -80kg'),
                _buildModalLine('Submitted Weight:', _verificationData['submittedWeight']),
                _buildModalLine('Certified Scale Weight:', _verificationData['officialWeight']),
                _buildModalLine('Scale Calibration:', _verificationData['scaleId']),
                _buildModalLine('Verification Officer:', _verificationData['verificationOfficer']),
                _buildModalLine('Medical Clearance:', _verificationData['medicalClearance']),
                _buildModalLine('Physician:', _verificationData['medicalOfficer']),
                _buildModalLine('Athlete License:', _verificationData['licenseNumber']),
                _buildModalLine('Certified Timestamp:', _verificationData['timestamp']),
                const SizedBox(height: 10),
                const Divider(color: Colors.white12),
                const SizedBox(height: 6),
                const Text('SHA-256 Digital Hash:', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                SelectableText(
                  _verificationData['digitalSignatureHash'],
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

