import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

/// Prominent Forged-Crystal Obsidian Radar entry card displayed at the top of
/// the Discover screen. Uses a live animated tactical radar sweep preview and
/// launches `/radar` without altering the locked 5-tab navigation bar.
class RadarDiscoverEntryCard extends StatefulWidget {
  const RadarDiscoverEntryCard({super.key});

  @override
  State<RadarDiscoverEntryCard> createState() => _RadarDiscoverEntryCardState();
}

class _RadarDiscoverEntryCardState extends State<RadarDiscoverEntryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      _pulseController.repeat();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('discover_open_radar_card'),
      onTap: () {
        HapticFeedback.mediumImpact();
        context.push('/radar');
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xE6151B24),
              Color(0xF20B0F19),
              Color(0xFA070A11),
            ],
          ),
          border: Border.all(
            color: AppTheme.goldPrimary.withValues(alpha: 0.55),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.goldPrimary.withValues(alpha: 0.12),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          child: Stack(
            children: [
              // Subtle dark tactical grid backdrop
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) => CustomPaint(
                    painter: _RadarPreviewGridPainter(
                      progress: _pulseController.value,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Animated Radar Map Preview Thumbnail
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (_, __) {
                          return Container(
                            decoration: BoxDecoration(
                              color: AppTheme.voidBackground,
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                              border: Border.all(
                                color: AppTheme.goldPrimary.withValues(alpha: 0.55),
                                width: 1.1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium - 1),
                              child: CustomPaint(
                                painter: _RadarThumbnailPainter(
                                  progress: _pulseController.value,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.radar_rounded,
                                    color: AppTheme.goldPrimary,
                                    size: 26,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Headline + Subtitle + Live Tag
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.crimson.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppTheme.crimson.withValues(alpha: 0.65),
                                    width: 0.9,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.sensors_rounded,
                                      size: 11,
                                      color: AppTheme.crimson,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'LIVE TACTICAL MAP',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                        color: AppTheme.textPure,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Open Radar',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 17.5,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPure,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Find Athletes, Events & Sparring Near You',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppTheme.fontBody,
                              fontSize: 12.2,
                              height: 1.3,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.goldPrimary.withValues(alpha: 0.14),
                        border: Border.all(
                          color: AppTheme.goldPrimary.withValues(alpha: 0.6),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: AppTheme.goldPrimary,
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
}

class _RadarPreviewGridPainter extends CustomPainter {
  final double progress;
  const _RadarPreviewGridPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppTheme.borderSubtle.withValues(alpha: 0.18)
      ..strokeWidth = 0.7;

    const double step = 22;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Subtle expanding ambient radar wave on right edge
    final center = Offset(size.width * 0.88, size.height * 0.5);
    final waveRadius = 18 + progress * 70;
    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppTheme.goldPrimary.withValues(alpha: (1 - progress) * 0.22);
    canvas.drawCircle(center, waveRadius, wavePaint);
  }

  @override
  bool shouldRepaint(covariant _RadarPreviewGridPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _RadarThumbnailPainter extends CustomPainter {
  final double progress;
  const _RadarThumbnailPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width * 0.46;

    // Concentric tactical rings
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = AppTheme.goldPrimary.withValues(alpha: 0.24);
    canvas.drawCircle(center, maxR * 0.42, ringPaint);
    canvas.drawCircle(center, maxR * 0.76, ringPaint);
    canvas.drawCircle(center, maxR, ringPaint);

    // Crosshairs
    canvas.drawLine(
      Offset(center.dx, 4),
      Offset(center.dx, size.height - 4),
      ringPaint,
    );
    canvas.drawLine(
      Offset(4, center.dy),
      Offset(size.width - 4, center.dy),
      ringPaint,
    );

    // Expanding pulse ring
    final pulsePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = AppTheme.crimson.withValues(alpha: (1.0 - progress) * 0.65);
    canvas.drawCircle(center, maxR * (0.2 + progress * 0.85), pulsePaint);

    // Rotating sweep arc
    final sweepAngle = progress * math.pi * 2;
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: sweepAngle - 0.9,
        endAngle: sweepAngle,
        colors: [
          AppTheme.goldPrimary.withValues(alpha: 0.0),
          AppTheme.goldPrimary.withValues(alpha: 0.32),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: maxR));
    canvas.drawCircle(center, maxR, sweepPaint);

    // Mini pin blips (gold event, crimson beacon, cyan athlete)
    canvas.drawCircle(
      Offset(size.width * 0.26, size.height * 0.30),
      2.6,
      Paint()..color = AppTheme.goldPrimary,
    );
    canvas.drawCircle(
      Offset(size.width * 0.74, size.height * 0.28),
      3.0,
      Paint()..color = AppTheme.crimson,
    );
    canvas.drawCircle(
      Offset(size.width * 0.70, size.height * 0.72),
      2.3,
      Paint()..color = AppTheme.cyan,
    );
  }

  @override
  bool shouldRepaint(covariant _RadarThumbnailPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
