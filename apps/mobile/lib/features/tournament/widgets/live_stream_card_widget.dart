import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../core/widgets/pulse_indicator.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
class LiveStreamCardWidget extends StatefulWidget {
  final Map<String, dynamic> tournament;

  const LiveStreamCardWidget({
    Key? key,
    required this.tournament,
  }) : super(key: key);

  @override
  State<LiveStreamCardWidget> createState() => _LiveStreamCardWidgetState();
}

class _LiveStreamCardWidgetState extends State<LiveStreamCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLive = (widget.tournament['status'] ?? 'LIVE').toString().toUpperCase() == 'LIVE';

    if (!isLive) {
      return const SizedBox();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Color(0xFFFF2A6D).withOpacity(0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0xFFFF2A6D).withOpacity(0.12),
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
            // Top Section Header & LIVE Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFFFF2A6D).withOpacity(0.18),
                        shape: BoxShape.circle,
                        border: Border.all(color: Color(0xFFFF2A6D).withOpacity(0.6)),
                      ),
                      child: Icon(
                        Icons.live_tv_rounded,
                        color: Color(0xFFFF2A6D),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'OFFICIAL LIVE BROADCAST',
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
                          'PAFF ArmSphere TV HD Stream',
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

                // Live Indicator Pill
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Color(0xFFFF2A6D).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Color(0xFFFF2A6D).withOpacity(0.6 + 0.4 * _pulseController.value),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFFF2A6D).withOpacity(0.3 * _pulseController.value),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          PulseIndicator(size: 6.0, color: Color(0xFFFF2A6D)),
                          SizedBox(width: 6),
                          Text(
                            'LIVE NOW',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFF2A6D),
                              letterSpacing: 0.6,
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

            // Video Preview Frame Backdrop Card
            Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: const DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1517649763962-0c623266010b'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
                ),
                border: Border.all(color: Colors.white12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Center Play Overlay Icon
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFFF2A6D).withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFFF2A6D).withOpacity(0.5),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(Icons.play_arrow_rounded, size: 36, color: Colors.white),
                  ),

                  // Bottom Info Overlay Bar
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.sports_mma_rounded, color: AppTheme.goldPrimary, size: 14),
                              SizedBox(width: 6),
                              Text(
                                'Table 1: Usman Khan vs Zain Ul-Abidin',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Row(
                            children: const [
                              Icon(Icons.remove_red_eye_rounded, color: Color(0xFF00E5FF), size: 14),
                              SizedBox(width: 4),
                              Text(
                                '14,820',
                                style: TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Stream Status Subtitle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  '1080p 60FPS • PAFF Official Broadcast',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 10,
                    color: AppTheme.textMuted,
                  ),
                ),
                Text(
                  'PAFF YouTube Channel',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 10,
                    color: Color(0xFFFF2A6D),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Large Watch Live Button (Opens YouTube Live Stream)
            TactilePressWrapper(
              onTap: () => _openYouTubeLiveStream(context),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF2A6D), Color(0xFFFF0055)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFFF2A6D).withOpacity(0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.play_circle_fill_rounded, size: 20, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'WATCH LIVE ON YOUTUBE',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.8,
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
  }

  void _openYouTubeLiveStream(BuildContext context) {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.live_tv_rounded, color: Color(0xFFFF2A6D)),
              SizedBox(width: 8),
              Text('YouTube Live Stream', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Opening the official PAFF Championship live broadcast on YouTube.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
              SizedBox(height: 12),
              Text(
                '• Stream: Pakistan National Armwrestling Finals 2026\n• Resolution: 1080p60\n• Commentary: English & Urdu',
                style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF2A6D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✓ Redirecting to PAFF Official YouTube Channel Live Stream...'),
                    backgroundColor: Color(0xFFFF2A6D),
                  ),
                );
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('LAUNCH YOUTUBE', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}


// ============================================================================
// PART 12 — RULEBOOK (Accordion Cards with Smooth Expansion)
// ============================================================================

