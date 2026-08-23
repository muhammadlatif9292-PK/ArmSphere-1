import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
class MyTournamentStatusCard extends StatefulWidget {
  final Map<String, dynamic> tournament;

  const MyTournamentStatusCard({
    Key? key,
    required this.tournament,
  }) : super(key: key);

  @override
  State<MyTournamentStatusCard> createState() => _MyTournamentStatusCardState();
}

class _MyTournamentStatusCardState extends State<MyTournamentStatusCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  
  // 0: Not Registered, 1: Eligible to Register, 2: Registration Pending, 3: Registered,
  // 4: Medical Pending, 5: Verification Pending, 6: Check-in Required, 7: Waiting for Bracket,
  // 8: Competing, 9: Completed
  int _selectedStatusIndex = 6; // Check-in Required default

  final List<String> _statusOptions = [
    'Not Registered',
    'Eligible to Register',
    'Registration Pending',
    'Registered',
    'Medical Pending',
    'Verification Pending',
    'Check-in Required',
    'Waiting for Bracket',
    'Competing',
    'Completed',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _getStatusDetails(int index) {
    switch (index) {
      case 0:
        return {
          'statusLabel': 'NOT REGISTERED',
          'accentColor': const Color(0xFFFF5252),
          'icon': Icons.app_registration_rounded,
          'explanation': 'You are currently not registered for this championship. Registration closes August 10, 2026.',
          'nextAction': 'Select your weight category and submit athlete registration form.',
          'ctaText': 'REGISTER FOR TOURNAMENT',
          'ctaIcon': Icons.how_to_reg_rounded,
          'textColor': Colors.black,
          'gradient': const [Color(0xFFFF5252), Color(0xFFFF1744)],
          'onCtaTap': (BuildContext ctx) => ctx.push('/events/${widget.tournament['id']}/register', extra: widget.tournament),
        };
      case 1:
        return {
          'statusLabel': 'ELIGIBLE TO REGISTER',
          'accentColor': const Color(0xFF00E5FF),
          'icon': Icons.verified_rounded,
          'explanation': 'Your PAFF Pro License #PK-8842 is verified & active. You are eligible for Senior Men (-80kg).',
          'nextAction': 'Proceed to official category registration and confirm payment method.',
          'ctaText': 'PROCEED TO REGISTRATION',
          'ctaIcon': Icons.arrow_forward_rounded,
          'textColor': Colors.black,
          'gradient': const [Color(0xFF00E5FF), Color(0xFF00B0FF)],
          'onCtaTap': (BuildContext ctx) => ctx.push('/events/${widget.tournament['id']}/register', extra: widget.tournament),
        };
      case 2:
        return {
          'statusLabel': 'REGISTRATION PENDING',
          'accentColor': const Color(0xFFFFB300),
          'icon': Icons.hourglass_top_rounded,
          'explanation': 'Registration submitted! Payment proof uploaded and awaiting organizer sign-off.',
          'nextAction': 'Verification in progress by PAFF Council. Usually confirmed within 2-4 hours.',
          'ctaText': 'VIEW REGISTRATION RECEIPT',
          'ctaIcon': Icons.receipt_long_rounded,
          'textColor': Colors.black,
          'gradient': const [Color(0xFFFFB300), Color(0xFFFF8F00)],
          'onCtaTap': (BuildContext ctx) => _showModal(ctx, 'REGISTRATION PENDING RECEIPT', 'Payment Reference #PAY-99824 under review by PAFF Finance Team.'),
        };
      case 3:
        return {
          'statusLabel': 'REGISTERED',
          'accentColor': const Color(0xFF00E676),
          'icon': Icons.check_circle_rounded,
          'explanation': 'Registration confirmed! Senior Right -80kg Category • Athlete ID #ATH-9921.',
          'nextAction': 'Complete your annual medical fitness clearance certificate prior to weigh-in.',
          'ctaText': 'COMPLETE MEDICAL VERIFICATION',
          'ctaIcon': Icons.medical_services_rounded,
          'textColor': Colors.black,
          'gradient': const [Color(0xFF00E676), Color(0xFF00C853)],
          'onCtaTap': (BuildContext ctx) => _showMedicalModal(ctx),
        };
      case 4:
        return {
          'statusLabel': 'MEDICAL PENDING',
          'accentColor': const Color(0xFFB388FF),
          'icon': Icons.medical_information_rounded,
          'explanation': 'Registration active, but medical clearance form is required prior to official weigh-in.',
          'nextAction': 'Upload signed medical fitness certificate from certified doctor.',
          'ctaText': 'UPLOAD MEDICAL CERTIFICATE',
          'ctaIcon': Icons.upload_file_rounded,
          'textColor': Colors.black,
          'gradient': const [Color(0xFFB388FF), Color(0xFF7C4DFF)],
          'onCtaTap': (BuildContext ctx) => _showMedicalModal(ctx),
        };
      case 5:
        return {
          'statusLabel': 'VERIFICATION PENDING',
          'accentColor': const Color(0xFFFFAB40),
          'icon': Icons.fact_check_rounded,
          'explanation': 'Identity & category weight limits are currently being audited by head referee desk.',
          'nextAction': 'Ensure CNIC/Passport and official weigh-in slip are ready.',
          'ctaText': 'COMPLETE VERIFICATION',
          'ctaIcon': Icons.badge_rounded,
          'textColor': Colors.black,
          'gradient': const [Color(0xFFFFAB40), Color(0xFFFF9100)],
          'onCtaTap': (BuildContext ctx) => _showModal(ctx, 'ATHLETE VERIFICATION', 'Present your CNIC/Passport & PAFF Digital License ID to Referee Desk Station #1.'),
        };
      case 6:
        return {
          'statusLabel': 'CHECK-IN REQUIRED',
          'accentColor': const Color(0xFF64FFDA),
          'icon': Icons.how_to_reg_rounded,
          'explanation': 'Weigh-in complete (78.4 kg). Digital check-in required at Stage A holding area.',
          'nextAction': 'Check in to Stage A to receive table call push notifications.',
          'ctaText': 'CHECK IN TO STAGE A',
          'ctaIcon': Icons.location_on_rounded,
          'textColor': Colors.black,
          'gradient': const [Color(0xFF64FFDA), Color(0xFF00BFA5)],
          'onCtaTap': (BuildContext ctx) {
            HapticFeedback.mediumImpact();
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(
                content: Text('✓ Checked In to Stage A Holding Area! Notification active.'),
                backgroundColor: Color(0xFF00BFA5),
              ),
            );
          },
        };
      case 7:
        return {
          'statusLabel': 'WAITING FOR BRACKET',
          'accentColor': const Color(0xFF00B0FF),
          'icon': Icons.account_tree_rounded,
          'explanation': 'Checked in & verified! Double elimination seeding in progress by Tournament Director.',
          'nextAction': 'Stand by for official bracket release and table assignment.',
          'ctaText': 'VIEW BRACKET PREVIEW',
          'ctaIcon': Icons.account_tree_outlined,
          'textColor': Colors.black,
          'gradient': const [Color(0xFF00B0FF), Color(0xFF0091EA)],
          'onCtaTap': (BuildContext ctx) => _showBracketModal(ctx),
        };
      case 8:
        return {
          'statusLabel': 'COMPETING (LIVE)',
          'accentColor': const Color(0xFFFF2A6D),
          'icon': Icons.sports_mma_rounded,
          'explanation': 'MATCH #42 CALLED! Table #2 (Stage A). Opponent: Zain Ul-Abidin (Senior Right -80kg).',
          'nextAction': 'Report immediately to Table #2. Referees preparing grip call.',
          'ctaText': 'WATCH LIVE STREAM',
          'ctaIcon': Icons.live_tv_rounded,
          'textColor': Colors.white,
          'gradient': const [Color(0xFFFF2A6D), Color(0xFFFF0055)],
          'onCtaTap': (BuildContext ctx) => _showLiveStreamDialog(ctx),
        };
      case 9:
      default:
        return {
          'statusLabel': 'COMPLETED',
          'accentColor': const Color(0xFFFFD700),
          'icon': Icons.emoji_events_rounded,
          'explanation': 'Championship Finished! Final Standing: 2nd Place Silver Medalist (-80kg Right Arm).',
          'nextAction': 'Download verified digital medal certificate & view full standings.',
          'ctaText': 'VIEW RESULTS & CERTIFICATE',
          'ctaIcon': Icons.card_membership_rounded,
          'textColor': Colors.black,
          'gradient': const [Color(0xFFFFD700), Color(0xFFFF8F00)],
          'onCtaTap': (BuildContext ctx) => _showCertificateModal(ctx),
        };
    }
  }

  void _showModal(BuildContext context, String title, String body) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline_rounded, size: 38, color: Color(0xFF00E5FF)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('DISMISS', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showMedicalModal(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.medical_services_rounded, size: 40, color: Color(0xFFB388FF)),
            const SizedBox(height: 12),
            const Text(
              'MEDICAL FITNESS VERIFICATION',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload doctor clearance certifying cardiovascular & arm musculoskeletal health for competitive armwrestling.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB388FF),
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✓ Medical certificate uploaded successfully. Approved by Medical Desk.'),
                    backgroundColor: Color(0xFFB388FF),
                  ),
                );
              },
              icon: const Icon(Icons.upload_file_rounded, size: 18),
              label: const Text('UPLOAD PDF / IMAGE', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showBracketModal(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.6,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                const Text(
                  'LIVE DOUBLE ELIMINATION BRACKET',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(color: Colors.white12),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.account_tree_rounded, size: 48, color: Color(0xFF00E5FF)),
                    SizedBox(height: 12),
                    Text(
                      'Double Elimination Bracket • Senior Right -80kg',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '16 Athletes • Winners Quarter-Finals Table #2',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  void _showCertificateModal(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.workspace_premium_rounded, size: 44, color: Color(0xFFFFD700)),
            const SizedBox(height: 12),
            const Text(
              'OFFICIAL PAFF DIGITAL CERTIFICATE',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Silver Medalist • Senior Right -80kg Class\nVerified Digital Certificate #PAFF-2026-8821',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✓ Official Certificate downloaded to device.'),
                    backgroundColor: Color(0xFFFFD700),
                  ),
                );
              },
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('DOWNLOAD PDF CERTIFICATE', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showLiveStreamDialog(BuildContext context) {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.live_tv, color: Color(0xFFFF2A6D)),
              SizedBox(width: 8),
              Text('Live Broadcast', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Official PAFF Live Stream is broadcasting live on YouTube & ArmSphere TV.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF2A6D)),
              onPressed: () => Navigator.pop(context),
              child: const Text('Open Stream', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusData = _getStatusDetails(_selectedStatusIndex);
    final Color accentColor = statusData['accentColor'] as Color;
    final IconData iconData = statusData['icon'] as IconData;
    final String statusLabel = statusData['statusLabel'] as String;
    final String explanation = statusData['explanation'] as String;
    final String nextAction = statusData['nextAction'] as String;
    final String ctaText = statusData['ctaText'] as String;
    final IconData ctaIcon = statusData['ctaIcon'] as IconData;
    final Color textColor = statusData['textColor'] as Color;
    final List<Color> gradient = statusData['gradient'] as List<Color>;
    final Function(BuildContext) onCtaTap = statusData['onCtaTap'] as Function(BuildContext);

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseVal = _pulseController.value;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: accentColor.withOpacity(0.35 + (0.25 * pulseVal)),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.12 * pulseVal + 0.05),
                blurRadius: 20,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Title, Subtitle & Interactive Status Switcher Menu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.18),
                            shape: BoxShape.circle,
                            border: Border.all(color: accentColor.withOpacity(0.5)),
                          ),
                          child: Icon(
                            iconData,
                            color: accentColor,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'SMART ATHLETE STATUS',
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
                              'Athlete ID: #ATH-9921 • Category: -80kg R',
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

                    // Dropdown Status Selector (Allows previewing all 10 states easily)
                    Container(
                      height: 28,
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: accentColor.withOpacity(0.5)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedStatusIndex,
                          dropdownColor: const Color(0xFF0F172A),
                          icon: Icon(Icons.arrow_drop_down, color: accentColor, size: 18),
                          items: List.generate(_statusOptions.length, (idx) {
                            return DropdownMenuItem<int>(
                              value: idx,
                              child: Text(
                                _statusOptions[idx].toUpperCase(),
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: idx == _selectedStatusIndex ? accentColor : Colors.white70,
                                ),
                              ),
                            );
                          }),
                          onChanged: (newIdx) {
                            if (newIdx != null) {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _selectedStatusIndex = newIdx;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Large Status Hero Glass Header Box
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Color(0xFF0B111E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: accentColor.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      // Large Animated Icon Box
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor.withOpacity(0.18),
                          border: Border.all(color: accentColor.withOpacity(0.5), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withOpacity(0.3 * pulseVal + 0.1),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(
                          iconData,
                          size: 26,
                          color: accentColor,
                        ),
                      ),

                      const SizedBox(width: 14),

                      // Status Title & Short Explanation
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: accentColor,
                                    boxShadow: [
                                      BoxShadow(color: accentColor, blurRadius: 6),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    statusLabel,
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: accentColor,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              explanation,
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 11,
                                color: Colors.white,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Recommended Next Action Highlight Box
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Color(0xFF162032).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates_outlined,
                        size: 16,
                        color: AppTheme.goldPrimary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'RECOMMENDED NEXT ACTION',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.goldPrimary,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              nextAction,
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 10.5,
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ONLY ONE Primary Action CTA Button (Clear & Unambiguous)
                TactilePressWrapper(
                  onTap: () => onCtaTap(context),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(colors: gradient),
                      boxShadow: [
                        BoxShadow(
                          color: gradient.first.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(ctaIcon, size: 18, color: textColor),
                        const SizedBox(width: 8),
                        Text(
                          ctaText,
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

