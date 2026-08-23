import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';

class DigitalPassportCard extends StatefulWidget {
  final Map<String, dynamic>? profileData;

  const DigitalPassportCard({
    Key? key,
    this.profileData,
  }) : super(key: key);

  static void showVerificationModal(BuildContext context, Map<String, dynamic> data) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: AppTheme.goldPrimary.withOpacity(0.4),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.goldPrimary.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Handle
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // WAF Official Header Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.goldPrimary.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.goldPrimary, width: 1),
                      ),
                      child: Icon(Icons.verified, color: AppTheme.goldLight, size: 24),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'WORLD ARMWRESTLING FEDERATION',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: AppTheme.goldLight,
                          ),
                        ),
                        Text(
                          'OFFICIAL DIGITAL PASSPORT & CREDENTIALS',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // QR Code Identity Box
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Simulated High Precision Security QR Code
                      CustomPaint(
                        size: const Size(140, 140),
                        painter: _QrCodePainter(),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        data['licenseNumber']?.toString() ?? 'AS-8821-PRO-WAF',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Credentials Detail Grid
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Column(
                    children: [
                      _buildModalInfoRow('Athlete Name', '${data['firstName'] ?? 'John'} ${data['lastName'] ?? 'Diesel'}'),
                      const Divider(color: AppTheme.surface, height: 16),
                      _buildModalInfoRow('Division / Weight', data['weightClass']?.toString() ?? '-95kg Senior Heavyweight'),
                      const Divider(color: AppTheme.surface, height: 16),
                      _buildModalInfoRow('Compliance Level', 'Level 3 (Drug Tested & Certified)'),
                      const Divider(color: AppTheme.surface, height: 16),
                      _buildModalInfoRow('Federation', data['federation']?.toString() ?? 'Pakistan Armwrestling Fed.'),
                      const Divider(color: AppTheme.surface, height: 16),
                      _buildModalInfoRow('Passport Expiry', '31 DEC 2028 (VALID)'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Dismiss Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldPrimary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'CLOSE CREDENTIAL PASS',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
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

  static Widget _buildModalInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppTheme.textMuted,
            letterSpacing: 0.8,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  @override
  State<DigitalPassportCard> createState() => _DigitalPassportCardState();
}

class _DigitalPassportCardState extends State<DigitalPassportCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.profileData ?? {};
    final fullName = '${data['firstName'] ?? 'John'} ${data['lastName'] ?? 'Diesel'}'.trim();
    final licenseNo = data['licenseNumber']?.toString() ?? 'AS-8821-PRO-WAF';

    return TactilePressWrapper(
      onTap: () => DigitalPassportCard.showVerificationModal(context, data),
      enableLift: true,
      liftDistance: -3,
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          final shimmerX = -1.0 + (_shimmerController.value * 3.0);

          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: AppTheme.goldPrimary.withOpacity(0.08),
                  blurRadius: 22,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  padding: EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.glassSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.goldPrimary.withOpacity(0.35),
                      width: 1.0,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment(shimmerX, -1.0),
                      end: Alignment(shimmerX + 0.5, 1.0),
                      colors: const [
                        AppTheme.surface,
                        AppTheme.surface, // Holographic metallic sweep
                        AppTheme.surface,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row with WAF Seal & Passport Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: AppTheme.goldPrimary.withOpacity(0.18),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.goldPrimary, width: 0.8),
                                ),
                                child: Icon(Icons.verified, size: 14, color: AppTheme.goldLight),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'WAF DIGITAL IDENTITY PASS',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  color: AppTheme.goldLight,
                                ),
                              ),
                            ],
                          ),

                          // QR Icon preview
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.qr_code_2_rounded, size: 14, color: AppTheme.goldPrimary),
                                SizedBox(width: 4),
                                Text(
                                  'SCAN',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.goldPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Main Pass Info Row
                      Row(
                        children: [
                          // Holographic Badge Chip
                          Container(
                            width: 52,
                            height: 62,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.goldPrimary,
                                  AppTheme.goldDark,
                                  AppTheme.surface,
                                ],
                              ),
                              border: Border.all(color: AppTheme.goldLight, width: 1),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.shield_outlined, color: Colors.white, size: 22),
                                SizedBox(height: 2),
                                Text(
                                  'PRO',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fullName,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.textPrimary,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  licenseNo,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.goldPrimary,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Compliance Pill Badge
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.success.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppTheme.success.withOpacity(0.4), width: 0.8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.check_circle, size: 10, color: AppTheme.success),
                                      SizedBox(width: 4),
                                      Text(
                                        'COMPLIANCE LEVEL 3 • VALIDATED',
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.success,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Simulated QR Code CustomPainter
class _QrCodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // Corner Finder Squares
    void drawFinder(double x, double y) {
      canvas.drawRect(Rect.fromLTWH(x, y, 32, 32), paint);
      canvas.drawRect(Rect.fromLTWH(x + 4, y + 4, 24, 24), Paint()..color = Colors.white);
      canvas.drawRect(Rect.fromLTWH(x + 8, y + 8, 16, 16), paint);
    }

    drawFinder(0, 0);
    drawFinder(size.width - 32, 0);
    drawFinder(0, size.height - 32);

    // Random QR Data Dot Grid
    final tileSize = 6.0;
    for (double i = 0; i < size.width; i += tileSize * 1.5) {
      for (double j = 0; j < size.height; j += tileSize * 1.5) {
        // Skip finder areas
        if ((i < 40 && j < 40) ||
            (i > size.width - 40 && j < 40) ||
            (i < 40 && j > size.height - 40)) {
          continue;
        }
        if ((i.toInt() + j.toInt()) % 7 != 0) {
          canvas.drawRect(Rect.fromLTWH(i, j, tileSize, tileSize), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
