import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
import 'digital_passport_card.dart';

/// Specular Animated Light Sweep Painter for the QR Verification Glass Button
class _QrScanGlowPainter extends CustomPainter {
  final double progress;

  _QrScanGlowPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final sweepX = -size.width + (progress * size.width * 3.0);

    final sweepPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          AppTheme.goldPrimary.withOpacity(0.0),
          AppTheme.goldLight.withOpacity(0.65),
          AppTheme.goldPrimary.withOpacity(0.0),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
      ).createShader(Rect.fromLTWH(sweepX, 0, size.width, size.height));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(16),
      ),
      sweepPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _QrScanGlowPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Floating Glass Navigation & Action Header Bar
class FloatingGlassHeaderBar extends StatefulWidget {
  final Map<String, dynamic> profileData;
  final int unreadCount;
  final VoidCallback? onShareTap;

  const FloatingGlassHeaderBar({
    Key? key,
    required this.profileData,
    this.unreadCount = 3,
    this.onShareTap,
  }) : super(key: key);

  @override
  State<FloatingGlassHeaderBar> createState() => _FloatingGlassHeaderBarState();
}

class _FloatingGlassHeaderBarState extends State<FloatingGlassHeaderBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanGlowController;

  @override
  void initState() {
    super.initState();
    _scanGlowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _scanGlowController.dispose();
    super.dispose();
  }

  void _showNotificationSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: AppTheme.goldPrimary.withOpacity(0.3),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.goldPrimary.withOpacity(0.15),
                  blurRadius: 28,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.notifications_active_rounded, color: AppTheme.goldLight, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'ATHLETE NOTIFICATIONS',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primaryAccent, width: 0.8),
                      ),
                      child: Text(
                        '${widget.unreadCount} NEW',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildNotificationItem(
                  icon: Icons.verified_rounded,
                  iconColor: AppTheme.success,
                  title: 'WAF License Verification Completed',
                  time: '12m ago',
                  desc: 'Your Pro License #8821 has passed anti-doping & compliance checks.',
                ),
                const Divider(color: AppTheme.surface, height: 20),
                _buildNotificationItem(
                  icon: Icons.emoji_events_rounded,
                  iconColor: AppTheme.goldPrimary,
                  title: 'Tournament Invitation: Asian Cup 2026',
                  time: '2h ago',
                  desc: 'Official seed invitation for -95kg Senior Right Hand division.',
                ),
                const Divider(color: AppTheme.surface, height: 20),
                _buildNotificationItem(
                  icon: Icons.sports_kabaddi_rounded,
                  iconColor: AppTheme.secondaryAccent,
                  title: 'SuperMatch Challenge Received',
                  time: '1d ago',
                  desc: 'Tariq "Thunder" Usman issued a 5-round SuperMatch challenge.',
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String time,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: iconColor.withOpacity(0.5), width: 1),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    time,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 9.5,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                desc,
                style: const TextStyle(
                  fontFamily: AppTheme.fontBody,
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Top Left: Settings Floating Glass Button
        _buildSettingsGlassButton(context),

        // Top Right: Actions Row (Share, Notification & QR Verification Glass Buttons)
        Row(
          children: [
            // Share Profile Glass Button
            if (widget.onShareTap != null) ...[
              _buildShareGlassButton(context),
              const SizedBox(width: 10),
            ],

            // QR Verification Button with Animated Scan Glow
            _buildQrVerificationButton(context),

            const SizedBox(width: 10),

            // Notification Glass Button with Premium Glowing Unread Badge
            _buildNotificationGlassButton(context),
          ],
        ),
      ],
    );
  }

  /// Top Left Settings Button
  Widget _buildSettingsGlassButton(BuildContext context) {
    return TactilePressWrapper(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/settings');
      },
      enableLift: true,
      liftDistance: -2,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.glassSurface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.settings_outlined,
              color: AppTheme.textPrimary,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  /// Top Right Share Profile Glass Button
  Widget _buildShareGlassButton(BuildContext context) {
    return TactilePressWrapper(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onShareTap?.call();
      },
      enableLift: true,
      liftDistance: -2,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.glassSurface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.share_rounded,
              color: AppTheme.textPrimary,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  /// Top Right Notification Glass Button with Glowing Unread Badge
  Widget _buildNotificationGlassButton(BuildContext context) {
    return TactilePressWrapper(
      onTap: () => _showNotificationSheet(context),
      enableLift: true,
      liftDistance: -2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.glassSurface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: AppTheme.textPrimary,
                  size: 20,
                ),
              ),
            ),
          ),

          // Premium Glowing Unread Badge
          if (widget.unreadCount > 0)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAccent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.surface, width: 1.8),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryAccent.withOpacity(0.85),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Text(
                  '${widget.unreadCount}',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Top Right QR Verification Button with Animated Scan Glow
  Widget _buildQrVerificationButton(BuildContext context) {
    return TactilePressWrapper(
      onTap: () {
        DigitalPassportCard.showVerificationModal(context, widget.profileData);
      },
      enableLift: true,
      liftDistance: -2,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.glassSurface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.goldPrimary.withOpacity(0.4),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.goldPrimary.withOpacity(0.2),
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Scan Sweep Shader
                AnimatedBuilder(
                  animation: _scanGlowController,
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(80, 24),
                      painter: _QrScanGlowPainter(
                        progress: _scanGlowController.value,
                      ),
                    );
                  },
                ),

                // Button Content
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppTheme.goldPrimary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: AppTheme.goldLight,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'VERIFY',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: AppTheme.goldLight,
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
  }
}
