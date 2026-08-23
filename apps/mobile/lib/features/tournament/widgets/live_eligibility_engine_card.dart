import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
import 'eval_status.dart';
class _LiveEligibilityEngineCard extends StatefulWidget {
  const _LiveEligibilityEngineCard({
    Key? key,
  }) : super(key: key);

  @override
  State<_LiveEligibilityEngineCard> createState() => _LiveEligibilityEngineCardState();
}

class _LiveEligibilityEngineCardState extends State<_LiveEligibilityEngineCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _glowPulse;

  // 0: Eligible, 1: Missing Medical Verification, 2: License Expired, 3: Weight Class Not Eligible
  int _evaluationPreset = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _glowPulse = Tween<double>(begin: 0.35, end: 0.95).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final presetData = _getPresetDetails(_evaluationPreset);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xFF0D1527).withOpacity(0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: (presetData['accentColor'] as Color).withOpacity(0.55),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: (presetData['accentColor'] as Color).withOpacity(0.18),
            blurRadius: 22,
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Title, Auto-Evaluation Chip & Preset Tester
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (presetData['accentColor'] as Color).withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: (presetData['accentColor'] as Color).withOpacity(0.6),
                          ),
                        ),
                        child: Icon(
                          presetData['headerIcon'] as IconData,
                          color: presetData['accentColor'] as Color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'LIVE ELIGIBILITY ENGINE',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Automated Multi-Factor Athlete Evaluation',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 10,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Animated System Status Tag
                  AnimatedBuilder(
                    animation: _glowPulse,
                    builder: (context, child) {
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: (presetData['accentColor'] as Color).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: (presetData['accentColor'] as Color).withOpacity(_glowPulse.value),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: presetData['accentColor'] as Color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              presetData['badgeLabel'] as String,
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: presetData['accentColor'] as Color,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Interactive Preset Switcher Bar for Live Evaluation Demo
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Color(0xFF141E30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPresetChip(0, 'Eligible', AppTheme.goldPrimary),
                      const SizedBox(width: 6),
                      _buildPresetChip(1, 'Missing Medical', Color(0xFFFFB300)),
                      const SizedBox(width: 6),
                      _buildPresetChip(2, 'License Expired', Color(0xFFFF2A6D)),
                      const SizedBox(width: 6),
                      _buildPresetChip(3, 'Weight Limit Exceeded', Color(0xFFFF2A6D)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 16),

              // 7 Core Automatic Evaluation Requirements Grid
              Column(
                children: [
                  _buildRequirementRow(
                    title: 'Weight Class',
                    detail: presetData['weightDetail'] as String,
                    status: presetData['weightStatus'] as EvalStatus,
                  ),
                  const SizedBox(height: 10),
                  _buildRequirementRow(
                    title: 'License Status',
                    detail: presetData['licenseDetail'] as String,
                    status: presetData['licenseStatus'] as EvalStatus,
                  ),
                  const SizedBox(height: 10),
                  _buildRequirementRow(
                    title: 'Verification',
                    detail: presetData['verificationDetail'] as String,
                    status: presetData['verificationStatus'] as EvalStatus,
                  ),
                  const SizedBox(height: 10),
                  _buildRequirementRow(
                    title: 'Medical Clearance',
                    detail: presetData['medicalDetail'] as String,
                    status: presetData['medicalStatus'] as EvalStatus,
                  ),
                  const SizedBox(height: 10),
                  _buildRequirementRow(
                    title: 'Age Eligibility',
                    detail: presetData['ageDetail'] as String,
                    status: presetData['ageStatus'] as EvalStatus,
                  ),
                  const SizedBox(height: 10),
                  _buildRequirementRow(
                    title: 'Gender Division',
                    detail: presetData['genderDetail'] as String,
                    status: presetData['genderStatus'] as EvalStatus,
                  ),
                  const SizedBox(height: 10),
                  _buildRequirementRow(
                    title: 'Required Documents',
                    detail: presetData['docsDetail'] as String,
                    status: presetData['docsStatus'] as EvalStatus,
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Bottom Large Explanation Banner
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (presetData['accentColor'] as Color).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: (presetData['accentColor'] as Color).withOpacity(0.5),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          presetData['explanationIcon'] as IconData,
                          size: 18,
                          color: presetData['accentColor'] as Color,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          presetData['explanationTitle'] as String,
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: presetData['accentColor'] as Color,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      presetData['explanationBody'] as String,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 11,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Action Button on bottom of explanation
                    TactilePressWrapper(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(presetData['actionToast'] as String),
                            backgroundColor: presetData['accentColor'] as Color,
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: presetData['accentColor'] as Color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            presetData['actionLabel'] as String,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(int index, String label, Color color) {
    final isSelected = _evaluationPreset == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _evaluationPreset = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.white12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 9.5,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            color: isSelected ? Colors.black : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementRow({
    required String title,
    required String detail,
    required EvalStatus status,
  }) {
    IconData icon;
    Color iconColor;
    Color bgCircle;

    switch (status) {
      case EvalStatus.greenCheck:
        icon = Icons.check_circle_rounded;
        iconColor = const Color(0xFF00E676);
        bgCircle = Color(0xFF00E676).withOpacity(0.15);
        break;
      case EvalStatus.amberWarning:
        icon = Icons.warning_amber_rounded;
        iconColor = const Color(0xFFFFB300);
        bgCircle = Color(0xFFFFB300).withOpacity(0.15);
        break;
      case EvalStatus.redError:
        icon = Icons.cancel_rounded;
        iconColor = const Color(0xFFFF2A6D);
        bgCircle = Color(0xFFFF2A6D).withOpacity(0.15);
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Color(0xFF141E2F).withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: bgCircle,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getPresetDetails(int index) {
    switch (index) {
      case 0: // Eligible
        return {
          'headerIcon': Icons.verified_user_rounded,
          'accentColor': const Color(0xFF00E676),
          'badgeLabel': '100% ELIGIBLE',
          'weightStatus': EvalStatus.greenCheck,
          'weightDetail': 'Official Weight 78.8 kg • Fits Senior Men -80kg',
          'licenseStatus': EvalStatus.greenCheck,
          'licenseDetail': 'Active Pro License #PAFF-PK-8842 (Valid thru Dec 2026)',
          'verificationStatus': EvalStatus.greenCheck,
          'verificationDetail': 'CNIC Verified & Biometric Matched',
          'medicalStatus': EvalStatus.greenCheck,
          'medicalDetail': 'Doctor Clearance Signed (Dr. Kamran Akram)',
          'ageStatus': EvalStatus.greenCheck,
          'ageDetail': 'Age 24 • Eligible for Senior Division',
          'genderStatus': EvalStatus.greenCheck,
          'genderDetail': 'Male Division Certified',
          'docsStatus': EvalStatus.greenCheck,
          'docsDetail': '3/3 Documents Valid (CNIC, Scale Slip, Medical)',
          'explanationIcon': Icons.check_circle_outline_rounded,
          'explanationTitle': 'AUTOMATIC EVALUATION: ELIGIBLE',
          'explanationBody': 'Athlete Tariq Z. satisfies all 7 PAFF competitive requirements. Cleared for weigh-in station and draw bracket seeding.',
          'actionLabel': 'PROCEED TO WEIGH-IN PASS',
          'actionToast': '✓ Athlete identity verified. Digital QR Pass generated for weigh-in scale.',
        };
      case 1: // Missing Medical Verification
        return {
          'headerIcon': Icons.medical_services_rounded,
          'accentColor': const Color(0xFFFFB300),
          'badgeLabel': 'ACTION REQUIRED',
          'weightStatus': EvalStatus.greenCheck,
          'weightDetail': 'Weight 78.8 kg • Senior Men -80kg',
          'licenseStatus': EvalStatus.greenCheck,
          'licenseDetail': 'Active Pro License #PAFF-PK-8842',
          'verificationStatus': EvalStatus.greenCheck,
          'verificationDetail': 'CNIC Verified & Biometric Matched',
          'medicalStatus': EvalStatus.amberWarning,
          'medicalDetail': 'Medical Certificate Pending Doctor Sign-off',
          'ageStatus': EvalStatus.greenCheck,
          'ageDetail': 'Age 24 • Eligible for Senior Division',
          'genderStatus': EvalStatus.greenCheck,
          'genderDetail': 'Male Division Certified',
          'docsStatus': EvalStatus.amberWarning,
          'docsDetail': '2/3 Documents Approved (Medical Certificate Missing)',
          'explanationIcon': Icons.warning_amber_rounded,
          'explanationTitle': 'MISSING MEDICAL VERIFICATION',
          'explanationBody': 'An official doctor fitness clearance certificate is required before the athlete can be weighed in or entered into the match bracket.',
          'actionLabel': 'UPLOAD MEDICAL CERTIFICATE (PDF/JPG)',
          'actionToast': '✓ Opening medical certificate upload portal...',
        };
      case 2: // License Expired
        return {
          'headerIcon': Icons.badge_rounded,
          'accentColor': const Color(0xFFFF2A6D),
          'badgeLabel': 'INELIGIBLE',
          'weightStatus': EvalStatus.greenCheck,
          'weightDetail': 'Weight 78.8 kg • Senior Men -80kg',
          'licenseStatus': EvalStatus.redError,
          'licenseDetail': 'PAFF License Expired Dec 31, 2025',
          'verificationStatus': EvalStatus.greenCheck,
          'verificationDetail': 'CNIC Verified & Biometric Matched',
          'medicalStatus': EvalStatus.greenCheck,
          'medicalDetail': 'Doctor Clearance Signed',
          'ageStatus': EvalStatus.greenCheck,
          'ageDetail': 'Age 24 • Eligible for Senior Division',
          'genderStatus': EvalStatus.greenCheck,
          'genderDetail': 'Male Division Certified',
          'docsStatus': EvalStatus.redError,
          'docsDetail': 'License Renewal Needed',
          'explanationIcon': Icons.error_outline_rounded,
          'explanationTitle': 'PAFF LICENSE EXPIRED',
          'explanationBody': 'Athlete professional license #PAFF-PK-8842 expired. Annual renewal is required by PAFF Executive Council regulations.',
          'actionLabel': 'RENEW PAFF ATHLETE LICENSE NOW',
          'actionToast': '✓ Redirecting to PAFF License Renewal Desk...',
        };
      case 3: // Weight Class Not Eligible
      default:
        return {
          'headerIcon': Icons.scale_rounded,
          'accentColor': const Color(0xFFFF2A6D),
          'badgeLabel': 'OVERWEIGHT',
          'weightStatus': EvalStatus.redError,
          'weightDetail': 'Scale Weight 83.2 kg • Exceeds -80kg Ceiling by 3.2 kg',
          'licenseStatus': EvalStatus.greenCheck,
          'licenseDetail': 'Active Pro License #PAFF-PK-8842',
          'verificationStatus': EvalStatus.greenCheck,
          'verificationDetail': 'CNIC Verified & Biometric Matched',
          'medicalStatus': EvalStatus.greenCheck,
          'medicalDetail': 'Doctor Clearance Signed',
          'ageStatus': EvalStatus.greenCheck,
          'ageDetail': 'Age 24 • Eligible for Senior Division',
          'genderStatus': EvalStatus.greenCheck,
          'genderDetail': 'Male Division Certified',
          'docsStatus': EvalStatus.greenCheck,
          'docsDetail': '3/3 Documents Valid',
          'explanationIcon': Icons.error_outline_rounded,
          'explanationTitle': 'WEIGHT CLASS NOT ELIGIBLE',
          'explanationBody': 'Scale weight 83.2 kg exceeds the -80kg maximum class limit. Athlete must either cut to 80.0kg before scale deadline or move to -90kg category.',
          'actionLabel': 'TRANSFER TO SENIOR MEN -90KG CATEGORY',
          'actionToast': '✓ Weight class transfer request sent to Chief Referee.',
        };
    }
  }
}

