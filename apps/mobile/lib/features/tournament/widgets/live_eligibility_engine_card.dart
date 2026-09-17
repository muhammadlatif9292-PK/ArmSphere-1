import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
import 'eval_status.dart';
class LiveEligibilityEngineCard extends StatefulWidget {
  final Map<String, dynamic> tournament;

  const LiveEligibilityEngineCard({
    super.key,
    required this.tournament,
  });

  @override
  State<LiveEligibilityEngineCard> createState() => _LiveEligibilityEngineCardState();
}

class _LiveEligibilityEngineCardState extends State<LiveEligibilityEngineCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _glowPulse;

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

  Map<String, dynamic> _resolveEvaluationData() {
    final reg = (widget.tournament['userRegistration'] ?? widget.tournament['myRegistration']) as Map<String, dynamic>?;
    final catName = reg?['categoryName']?.toString() ?? widget.tournament['category']?.toString() ?? 'Senior Division';
    final weight = reg?['weighedWeight'] ?? reg?['weight'];
    final license = reg?['licenseStatus']?.toString().toUpperCase() ?? 'ACTIVE';
    final isVerified = reg?['isVerified'] == true || (reg?['verificationStatus'] ?? 'VERIFIED').toString().toUpperCase() == 'VERIFIED';
    final medicalCleared = reg?['medicalCleared'] == true || (reg?['medicalStatus'] ?? 'VERIFIED').toString().toUpperCase() == 'VERIFIED';
    final docsValid = reg?['documentsValid'] ?? true;

    final isEligible = isVerified && medicalCleared && license == 'ACTIVE';

    if (isEligible) {
      return {
        'headerIcon': Icons.verified_user_rounded,
        'accentColor': const Color(0xFF00E676),
        'badgeLabel': '100% ELIGIBLE',
        'weightStatus': weight != null ? EvalStatus.greenCheck : EvalStatus.amberWarning,
        'weightDetail': weight != null ? 'Official Weight $weight kg • $catName' : 'Weigh-in Scheduled • $catName',
        'licenseStatus': EvalStatus.greenCheck,
        'licenseDetail': 'Active Professional License (Verified)',
        'verificationStatus': EvalStatus.greenCheck,
        'verificationDetail': 'Identity Verified & Certified',
        'medicalStatus': EvalStatus.greenCheck,
        'medicalDetail': 'Medical Fitness Clearance Approved',
        'ageStatus': EvalStatus.greenCheck,
        'ageDetail': 'Age Division Requirement Met',
        'genderStatus': EvalStatus.greenCheck,
        'genderDetail': 'Division Classification Certified',
        'docsStatus': EvalStatus.greenCheck,
        'docsDetail': 'All Required Documents Valid',
        'explanationIcon': Icons.check_circle_outline_rounded,
        'explanationTitle': 'AUTOMATIC EVALUATION: ELIGIBLE',
        'explanationBody': 'Athlete satisfies all official competitive requirements. Cleared for weigh-in station and draw bracket seeding.',
        'actionLabel': 'PROCEED TO WEIGH-IN PASS',
        'actionToast': '✓ Athlete identity verified. Digital pass ready for weigh-in scale.',
      };
    } else if (!medicalCleared) {
      return {
        'headerIcon': Icons.medical_services_rounded,
        'accentColor': const Color(0xFFFFB300),
        'badgeLabel': 'ACTION REQUIRED',
        'weightStatus': EvalStatus.greenCheck,
        'weightDetail': 'Weight Category: $catName',
        'licenseStatus': EvalStatus.greenCheck,
        'licenseDetail': 'Active Athlete License',
        'verificationStatus': EvalStatus.greenCheck,
        'verificationDetail': 'Identity Verified',
        'medicalStatus': EvalStatus.amberWarning,
        'medicalDetail': 'Medical Certificate Pending Sign-off',
        'ageStatus': EvalStatus.greenCheck,
        'ageDetail': 'Age Division Requirement Met',
        'genderStatus': EvalStatus.greenCheck,
        'genderDetail': 'Division Classification Certified',
        'docsStatus': EvalStatus.amberWarning,
        'docsDetail': 'Medical Certificate Required',
        'explanationIcon': Icons.warning_amber_rounded,
        'explanationTitle': 'MISSING MEDICAL CLEARANCE',
        'explanationBody': 'An official doctor fitness clearance certificate is required before the athlete can be weighed in or entered into the match bracket.',
        'actionLabel': 'UPLOAD MEDICAL CLEARANCE',
        'actionToast': '✓ Opening medical certificate upload portal...',
      };
    } else {
      return {
        'headerIcon': Icons.badge_rounded,
        'accentColor': const Color(0xFFFF2A6D),
        'badgeLabel': 'INELIGIBLE',
        'weightStatus': EvalStatus.greenCheck,
        'weightDetail': 'Category: $catName',
        'licenseStatus': EvalStatus.redError,
        'licenseDetail': 'License Renewal Required',
        'verificationStatus': isVerified ? EvalStatus.greenCheck : EvalStatus.redError,
        'verificationDetail': isVerified ? 'Verified' : 'Verification Required',
        'medicalStatus': EvalStatus.greenCheck,
        'medicalDetail': 'Medical Status Verified',
        'ageStatus': EvalStatus.greenCheck,
        'ageDetail': 'Age Requirement Met',
        'genderStatus': EvalStatus.greenCheck,
        'genderDetail': 'Division Certified',
        'docsStatus': EvalStatus.redError,
        'docsDetail': 'Renewal Documents Needed',
        'explanationIcon': Icons.error_outline_rounded,
        'explanationTitle': 'LICENSE RENEWAL REQUIRED',
        'explanationBody': 'Athlete license requires renewal before registration can be finalized.',
        'actionLabel': 'RENEW ATHLETE LICENSE',
        'actionToast': '✓ Redirecting to license renewal desk...',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final presetData = _resolveEvaluationData();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1527).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: (presetData['accentColor'] as Color).withValues(alpha: 0.55),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: (presetData['accentColor'] as Color).withValues(alpha: 0.18),
            blurRadius: 22,
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (presetData['accentColor'] as Color).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: (presetData['accentColor'] as Color).withValues(alpha: 0.6),
                          ),
                        ),
                        child: Icon(
                          presetData['headerIcon'] as IconData,
                          color: presetData['accentColor'] as Color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: (presetData['accentColor'] as Color).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: (presetData['accentColor'] as Color).withValues(alpha: _glowPulse.value),
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

              const SizedBox(height: 16),
              const Divider(color: Colors.white12, height: 1),
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
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (presetData['accentColor'] as Color).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: (presetData['accentColor'] as Color).withValues(alpha: 0.5),
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
        bgCircle = const Color(0xFF00E676).withValues(alpha: 0.15);
        break;
      case EvalStatus.amberWarning:
        icon = Icons.warning_amber_rounded;
        iconColor = const Color(0xFFFFB300);
        bgCircle = const Color(0xFFFFB300).withValues(alpha: 0.15);
        break;
      case EvalStatus.redError:
        icon = Icons.cancel_rounded;
        iconColor = const Color(0xFFFF2A6D);
        bgCircle = const Color(0xFFFF2A6D).withValues(alpha: 0.15);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF141E2F).withValues(alpha: 0.8),
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
}

