import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
class _RegistrationPanelWidget extends StatefulWidget {
  final Map<String, dynamic> tournament;

  const _RegistrationPanelWidget({
    Key? key,
    required this.tournament,
  }) : super(key: key);

  @override
  State<_RegistrationPanelWidget> createState() => _RegistrationPanelWidgetState();
}

class _RegistrationPanelWidgetState extends State<_RegistrationPanelWidget> {
  bool _isRegistered = false; // Adaptive toggle state
  bool _termsAccepted = true;
  bool _docLicense = true;
  bool _docCnic = true;
  bool _docMedical = true;

  String _selectedCategory = 'Senior Men -80kg Right Arm';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _isRegistered
              ? Color(0xFF00E676).withOpacity(0.5)
              : AppTheme.goldPrimary.withOpacity(0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: _isRegistered
                ? Color(0xFF00E676).withOpacity(0.08)
                : AppTheme.goldPrimary.withOpacity(0.08),
            blurRadius: 24,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section Header & Adaptive Simulator Toggle Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isRegistered
                            ? Color(0xFF00E676).withOpacity(0.18)
                            : AppTheme.goldPrimary.withOpacity(0.18),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isRegistered
                              ? Color(0xFF00E676).withOpacity(0.6)
                              : AppTheme.goldPrimary.withOpacity(0.6),
                        ),
                      ),
                      child: Icon(
                        _isRegistered ? Icons.verified_rounded : Icons.app_registration_rounded,
                        color: _isRegistered ? const Color(0xFF00E676) : AppTheme.goldPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'REGISTRATION PANEL',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isRegistered ? 'Official Athlete Credentials & Tournament Pass' : 'Select Category & Confirm Entry Requirements',
                          style: const TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 10,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Interactive Simulator Switcher Badge
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _isRegistered = !_isRegistered;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _isRegistered
                          ? Color(0xFF00E676).withOpacity(0.15)
                          : Color(0xFF00E5FF).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _isRegistered
                            ? Color(0xFF00E676).withOpacity(0.5)
                            : Color(0xFF00E5FF).withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.swap_horiz_rounded,
                          size: 14,
                          color: _isRegistered ? Color(0xFF00E676) : Color(0xFF00E5FF),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isRegistered ? 'REGISTERED' : 'NOT REGISTERED',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            color: _isRegistered ? Color(0xFF00E676) : Color(0xFF00E5FF),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),
            Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 18),

            // ADAPTIVE BODY CONTENT:
            if (!_isRegistered) ...[
              // ==========================================
              // STATE A: ATHLETE NOT REGISTERED
              // ==========================================
              
              // Category & Entry Fee Info Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Color(0xFF1E293B).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'SELECTED COMPETITION CLASS',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.goldPrimary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.5)),
                          ),
                          child: const Text(
                            'PKR 2,500 (\$1\$50 USD)',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.goldPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        dropdownColor: const Color(0xFF0F172A),
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'Senior Men -80kg Right Arm', child: Text('Senior Men -80kg Right Arm')),
                          DropdownMenuItem(value: 'Senior Men -80kg Left Arm', child: Text('Senior Men -80kg Left Arm')),
                          DropdownMenuItem(value: 'Senior Men -90kg Right Arm', child: Text('Senior Men -90kg Right Arm')),
                          DropdownMenuItem(value: 'Masters Men -85kg Right Arm', child: Text('Masters Men -85kg Right Arm')),
                          DropdownMenuItem(value: 'Junior Boys -75kg Right Arm', child: Text('Junior Boys -75kg Right Arm')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCategory = val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Required Documents List
              const Text(
                'REQUIRED REGISTRATION DOCUMENTS',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 10),

              _buildDocRequirementRow(
                title: 'Official PAFF Pro License',
                sub: 'PK-2026-0891 • Verified Active',
                isChecked: _docLicense,
                onChanged: (val) => setState(() => _docLicense = val ?? true),
              ),
              const SizedBox(height: 8),
              _buildDocRequirementRow(
                title: 'CNIC / Passport Identity Verification',
                sub: 'Government Issued Photo ID Matched',
                isChecked: _docCnic,
                onChanged: (val) => setState(() => _docCnic = val ?? true),
              ),
              const SizedBox(height: 8),
              _buildDocRequirementRow(
                title: 'Medical Fitness Certificate',
                sub: 'Dr. Clearance for High-Impact Armwrestling',
                isChecked: _docMedical,
                onChanged: (val) => setState(() => _docMedical = val ?? true),
              ),

              const SizedBox(height: 16),

              // Terms Acknowledgement Checkbox
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF131D33),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: _termsAccepted,
                        activeColor: AppTheme.goldPrimary,
                        checkColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (val) => setState(() => _termsAccepted = val ?? true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'I acknowledge & agree to PAFF Anti-Doping Regulations, Competition Safety Waiver & Athlete Code of Conduct.',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 10,
                          color: Colors.white70,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Large Register CTA Button
              TactilePressWrapper(
                onTap: () {
                  if (!_termsAccepted || !_docLicense || !_docCnic || !_docMedical) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please upload all required documents and accept terms.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  HapticFeedback.heavyImpact();
                  setState(() {
                    _isRegistered = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✓ REGISTRATION CONFIRMED for $_selectedCategory! Digital Pass Generated.'),
                      backgroundColor: const Color(0xFF00E676),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: [AppTheme.goldPrimary, Color(0xFFFF8F00)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.goldPrimary.withOpacity(0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.how_to_reg_rounded, size: 20, color: Colors.black),
                      SizedBox(width: 8),
                      Text(
                        'REGISTER FOR CHAMPIONSHIP',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // ==========================================
              // STATE B: ATHLETE ALREADY REGISTERED
              // ==========================================
              
              // 6-Grid Realtime Registration & Pass Matrix
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusMatrixTile(
                          icon: Icons.assignment_turned_in_rounded,
                          title: 'REGISTRATION STATUS',
                          status: 'CONFIRMED',
                          sub: 'Ref #REG-2026-9912',
                          accentColor: Color(0xFF00E676),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStatusMatrixTile(
                          icon: Icons.verified_user_rounded,
                          title: 'VERIFICATION',
                          status: 'VERIFIED',
                          sub: 'CNIC & Biometric Passed',
                          accentColor: Color(0xFF00E5FF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusMatrixTile(
                          icon: Icons.medical_services_rounded,
                          title: 'MEDICAL CLEARANCE',
                          status: 'APPROVED',
                          sub: 'Signed Dr. Kamran Akram',
                          accentColor: Color(0xFF00E676),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStatusMatrixTile(
                          icon: Icons.monetization_on_rounded,
                          title: 'PAYMENT',
                          status: 'PAID • PKR 2,500',
                          sub: 'Stripe Gateway #PAY-88219',
                          accentColor: AppTheme.goldPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusMatrixTile(
                          icon: Icons.how_to_reg_rounded,
                          title: 'CHECK-IN',
                          status: 'CHECKED IN',
                          sub: 'Stage A Holding Zone',
                          accentColor: Color(0xFF00E676),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStatusMatrixTile(
                          icon: Icons.qr_code_2_rounded,
                          title: 'QR PASS',
                          status: 'ACTIVE PASS',
                          sub: 'Tap to Expand Pass',
                          accentColor: Color(0xFFFF2A6D),
                          onTap: () => _showDigitalPassModal(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Digital Tournament Pass Quick Banner Button
              TactilePressWrapper(
                onTap: () => _showDigitalPassModal(context),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: [Color(0xFF1E2B47), Color(0xFF0D1527)],
                    ),
                    border: Border.all(color: Color(0xFFFF2A6D).withOpacity(0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFFF2A6D).withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color(0xFFFF2A6D).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.qr_code_rounded, color: Color(0xFFFF2A6D), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'DIGITAL TOURNAMENT PASS',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Official Arena Scanner & Scale Access Barcode',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 9.5,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFFF2A6D)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDocRequirementRow({
    required String title,
    required String sub,
    required bool isChecked,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Color(0xFF1E293B).withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isChecked ? Color(0xFF00E676).withOpacity(0.4) : Colors.white12),
      ),
      child: Row(
        children: [
          Icon(
            isChecked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 18,
            color: isChecked ? const Color(0xFF00E676) : Colors.white38,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  sub,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 9.5,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            isChecked ? 'VERIFIED' : 'PENDING',
            style: TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              color: isChecked ? const Color(0xFF00E676) : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMatrixTile({
    required IconData icon,
    required String title,
    required String status,
    required String sub,
    required Color accentColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(0xFF1E293B).withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withOpacity(0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: accentColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textMuted,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              status,
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 9,
                color: Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDigitalPassModal(BuildContext context) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),

            // Official Header Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_rounded, color: AppTheme.goldPrimary, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'PAFF DIGITAL TOURNAMENT PASS',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.goldPrimary,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Card Pass Preview
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E2B47), Color(0xFF0D1424)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.6), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.goldPrimary.withOpacity(0.2),
                    blurRadius: 18,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'ARMWRESTLING ATHLETE',
                            style: TextStyle(fontSize: 9, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Usman "Iron" Khan',
                            style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w900),
                          ),
                          Text(
                            'Senior Men -80kg Right Arm',
                            style: TextStyle(fontSize: 11, color: AppTheme.goldPrimary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.goldPrimary),
                        ),
                        child: const Icon(Icons.person_rounded, size: 28, color: AppTheme.goldPrimary),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 16),

                  // Mock Barcode / QR Code Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.qr_code_2_rounded, size: 90, color: Colors.black),
                        const SizedBox(height: 4),
                        const Text(
                          'PAFF-2026-9912-X88',
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldPrimary,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✓ Digital Pass saved to Apple / Google Wallet & Photos!'),
                    backgroundColor: AppTheme.goldPrimary,
                  ),
                );
              },
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text(
                'DOWNLOAD PASS TO WALLET',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ============================================================================
// PART 8 — TOURNAMENT TIMELINE (Interactive Vertical Event Timeline)
// ============================================================================

