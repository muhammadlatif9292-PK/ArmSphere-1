import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'count_up_text.dart';
import 'tactile_press_wrapper.dart';

class CelebrationOverlay extends StatefulWidget {
  final String title;
  final String subtitle;
  final num score;
  final String? scorePrefix;
  final String? scoreSuffix;
  final int decimalPlaces;
  final VoidCallback? onDismiss;

  const CelebrationOverlay({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.score,
    this.scorePrefix,
    this.scoreSuffix,
    this.decimalPlaces = 0,
    this.onDismiss,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required num score,
    String? scorePrefix,
    String? scoreSuffix,
    int decimalPlaces = 0,
    VoidCallback? onDismiss,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Celebration',
      barrierColor: AppTheme.background.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return CelebrationOverlay(
          title: title,
          subtitle: subtitle,
          score: score,
          scorePrefix: scorePrefix,
          scoreSuffix: scoreSuffix,
          decimalPlaces: decimalPlaces,
          onDismiss: onDismiss,
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final scaleValue = CurvedAnimation(parent: anim1, curve: Curves.elasticOut).value;
        return Transform.scale(
          scale: scaleValue.clamp(0.0, 1.0),
          child: Opacity(
            opacity: anim1.value,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _radialController;

  @override
  void initState() {
    super.initState();
    _radialController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _radialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => true,
      child: Semantics(
        label: 'Celebration: ${widget.title}. ${widget.subtitle}',
        focused: true,
        explicitChildNodes: true,
        child: Center(
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24.0),
            elevation: 0,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Branded radial burst animation
                AnimatedBuilder(
                  animation: _radialController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _radialController.value * 2 * pi,
                      child: Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              AppTheme.primaryAccent.withOpacity(0.0),
                              AppTheme.primaryAccent.withOpacity(0.4),
                              AppTheme.secondaryAccent.withOpacity(0.4),
                              AppTheme.primaryAccent.withOpacity(0.0),
                            ],
                            stops: const [0.0, 0.35, 0.65, 1.0],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Main visual card
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 320),
                  padding: const EdgeInsets.all(AppTheme.space24),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    border: Border.all(color: AppTheme.primaryAccent.withOpacity(0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryAccent.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Golden Fire Icon
                      Container(
                        padding: const EdgeInsets.all(AppTheme.space12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAccent.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_fire_department,
                          color: AppTheme.primaryAccent,
                          size: 40.0,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space16),
                      // Title (Space Grotesk)
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontWeight: FontWeight.w700,
                          fontSize: 26,
                          color: AppTheme.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space8),
                      // Subtitle
                      Text(
                        widget.subtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space24),
                      // Score CountUpText (Space Grotesk)
                      CountUpText(
                        value: widget.score,
                        prefix: widget.scorePrefix,
                        suffix: widget.scoreSuffix,
                        decimalPlaces: widget.decimalPlaces,
                        duration: const Duration(milliseconds: 1000),
                        style: const TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontWeight: FontWeight.bold,
                          fontSize: 48,
                          color: AppTheme.secondaryAccent,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space32),
                      // Dismiss Button
                      TactilePressWrapper(
                        onTap: () {
                          Navigator.of(context).pop();
                          if (widget.onDismiss != null) {
                            widget.onDismiss!();
                          }
                        },
                        semanticLabel: 'Claim record and dismiss',
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: AppTheme.space12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryAccent,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'CLAIM RECORD',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                              letterSpacing: 1.0,
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
      ),
    );
  }
}
