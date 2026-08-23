import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../core/widgets/pulse_indicator.dart';
import 'floating_particles_painter.dart';
class TournamentDetailsHeroWidget extends StatefulWidget {
  final Map<String, dynamic> tournament;

  const TournamentDetailsHeroWidget({
    Key? key,
    required this.tournament,
  }) : super(key: key);

  @override
  State<TournamentDetailsHeroWidget> createState() => _TournamentDetailsHeroWidgetState();
}

class _TournamentDetailsHeroWidgetState extends State<TournamentDetailsHeroWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tournament;
    final name = t['name'] ?? 'Pakistan National Armwrestling Championship 2026';
    final organizer = t['organizer'] ?? t['organizerName'] ?? 'PAFF Executive Council';
    final province = t['province'] ?? 'Punjab';
    final venue = t['venue'] ?? t['location'] ?? 'Nishtar Sports Complex, Lahore';
    final status = (t['status'] ?? 'UPCOMING').toString().toUpperCase();
    final categories = t['categories'] ?? t['weightCategories'] ?? '70kg, 80kg, 90kg, 100kg+ • L & R';
    final prizePool = t['prizePool'] ?? t['prizePoolPkr'] ?? 'PKR 500,000 PRIZE';
    final regCount = t['registeredCount'] ?? 84;
    final capacity = t['capacity'] ?? 100;
    final regStatus = t['registrationStatus'] ?? 'REGISTRATION OPEN ($regCount/$capacity SLOTS)';
    final countdown = t['countdownText'] ?? '04d : 12h : 30m';

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final animVal = _animController.value;
        final gradientAngle = animVal * 3.14159 * 2;

        return Container(
          height: 235,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppTheme.goldPrimary.withOpacity(0.18 * animVal + 0.12),
                blurRadius: 24,
                spreadRadius: -4,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                // 1. Moving Championship Gradients Background
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(
                          -1.0 + math.cos(gradientAngle) * 0.4,
                          -1.0 + math.sin(gradientAngle) * 0.4,
                        ),
                        end: Alignment(
                          1.0 - math.cos(gradientAngle) * 0.4,
                          1.0 - math.sin(gradientAngle) * 0.4,
                        ),
                        colors: [
                          Color(0xFF0D1424),
                          Color.lerp(
                            Color(0xFF131D33),
                            Color(0xFF1E2B47),
                            animVal,
                          )!,
                          Color(0xFF090D18),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. Gold Ambient Lighting Radial Glows
                Positioned(
                  top: -50 + (math.sin(gradientAngle) * 15),
                  right: -40 + (math.cos(gradientAngle) * 15),
                  width: 220,
                  height: 220,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.goldPrimary.withOpacity(0.25 + (0.1 * animVal)),
                          AppTheme.goldPrimary.withOpacity(0.08),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  bottom: -60,
                  left: -50,
                  width: 200,
                  height: 200,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color(0xFF00E5FF).withOpacity(0.18),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Tiny Floating Particles Effect
                Positioned.fill(
                  child: CustomPaint(
                    painter: FloatingParticlesPainter(progress: animVal),
                  ),
                ),

                // 4. Soft Animated Reflection Shimmer Overlay
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: -150 + (animVal * 600),
                  width: 100,
                  child: Transform.rotate(
                    angle: -0.4,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(0.04),
                            Colors.white.withOpacity(0.08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 5. Glass Container Border Shimmer
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Color.lerp(
                          AppTheme.goldPrimary.withOpacity(0.4),
                          Color(0xFF00E5FF).withOpacity(0.4),
                          animVal,
                        )!,
                        width: 1.2,
                      ),
                    ),
                  ),
                ),

                // 6. Foreground Layout Content
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                  child: Row(
                    children: [
                      // Left Content Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Top Row: Official Badge & Status / Countdown
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.goldPrimary.withOpacity(0.25),
                                        Color(0xFFFFB300).withOpacity(0.15),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: AppTheme.goldPrimary.withOpacity(0.6),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.verified_rounded,
                                        size: 11,
                                        color: AppTheme.goldPrimary,
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'PAFF OFFICIAL',
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.goldPrimary,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 6),

                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    color: status == 'LIVE'
                                        ? Color(0xFFFF2A6D).withOpacity(0.2)
                                        : Color(0xFF00E5FF).withOpacity(0.18),
                                    border: Border.all(
                                      color: status == 'LIVE'
                                          ? Color(0xFFFF2A6D).withOpacity(0.6)
                                          : Color(0xFF00E5FF).withOpacity(0.5),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (status == 'LIVE') ...[
                                        const PulseIndicator(size: 5.0, color: Color(0xFFFF2A6D)),
                                        const SizedBox(width: 4),
                                      ] else ...[
                                        Icon(
                                          Icons.circle,
                                          size: 5,
                                          color: Color(0xFF00E5FF),
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(
                                        status,
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w900,
                                          color: status == 'LIVE'
                                              ? Color(0xFFFF2A6D)
                                              : Color(0xFF00E5FF),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Tournament Name
                            Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.15,
                                letterSpacing: 0.2,
                              ),
                            ),

                            // Organizer, Province, Venue
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 12,
                                  color: Color(0xFF00E5FF),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '$organizer • $province • $venue',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Weight Categories & Prize Badge
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      color: Colors.black.withOpacity(0.35),
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.fitness_center_rounded, size: 10, color: Colors.white70),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            categories,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: AppTheme.fontDisplay,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 6),

                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    color: AppTheme.goldPrimary.withOpacity(0.2),
                                    border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.6)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.emoji_events_rounded,
                                        size: 11,
                                        color: AppTheme.goldPrimary,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        prizePool,
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.goldPrimary,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Bottom Row: Registration Status & Countdown
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.how_to_reg_rounded,
                                      size: 12,
                                      color: Color(0xFF00E676),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      regStatus,
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF00E676),
                                      ),
                                    ),
                                  ],
                                ),

                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    color: Color(0xFFFFB300).withOpacity(0.15),
                                    border: Border.all(color: Color(0xFFFFB300).withOpacity(0.4)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.timer_outlined,
                                        size: 10,
                                        color: Color(0xFFFFB300),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        countdown,
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFFFFB300),
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

                      const SizedBox(width: 12),

                      // Right Side: Trophy Illustration Graphics
                      Container(
                        width: 80,
                        height: 180,
                        alignment: Alignment.center,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.goldPrimary.withOpacity(0.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.goldPrimary.withOpacity(0.4 * animVal + 0.2),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Transform.translate(
                                  offset: Offset(0, math.sin(gradientAngle) * 3),
                                  child: ShaderMask(
                                    shaderCallback: (bounds) => LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0xFFFFF176),
                                        AppTheme.goldPrimary,
                                        Color(0xFFE65100),
                                      ],
                                    ).createShader(bounds),
                                    child: Icon(
                                      Icons.emoji_events_rounded,
                                      size: 56,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: Colors.black.withOpacity(0.6),
                                    border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.5)),
                                  ),
                                  child: const Text(
                                    'GOLD TITLE',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.goldPrimary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
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

