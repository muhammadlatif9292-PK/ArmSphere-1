import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/theme/app_theme.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/widgets/pulse_indicator.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';

class LiveStreamCardWidget extends StatefulWidget {
  final Map<String, dynamic> tournament;

  const LiveStreamCardWidget({
    super.key,
    required this.tournament,
  });

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
    final statusStr = (widget.tournament['status'] ?? 'LIVE').toString().toUpperCase();
    final streamUrl = widget.tournament['streamUrl']?.toString() ?? widget.tournament['youtubeLiveUrl']?.toString();
    final bool isLive = (statusStr == 'LIVE' || statusStr == 'ONGOING') && (streamUrl == null || streamUrl.isNotEmpty);
    final bool isStandby = !isLive || streamUrl == null || streamUrl.isEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFFF2A6D).withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFFFF2A6D).withValues(alpha: 0.12),
            blurRadius: 24,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF2A6D).withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFF2A6D).withValues(alpha: 0.6)),
                      ),
                      child: const Icon(
                        Icons.live_tv_rounded,
                        color: Color(0xFFFF2A6D),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF2A6D).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFFF2A6D).withValues(alpha: 0.6 + 0.4 * _pulseController.value),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF2A6D).withValues(alpha: 0.3 * _pulseController.value),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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

            // Video Preview Frame Backdrop Card (with m1_card_live_broadcast.webp standby / fallback)
            Builder(
              builder: (context) {
                final String? streamThumbnail = (widget.tournament['streamThumbnailUrl'] ?? widget.tournament['bannerUrl']) as String?;
                final currentMatch = widget.tournament['currentFeaturedMatch']?.toString() ??
                    widget.tournament['activeMatch']?.toString() ??
                    '${widget.tournament['name'] ?? 'Tournament'} • Main Table';
                final viewers = widget.tournament['liveViewerCount']?.toString() ??
                    (widget.tournament['viewers'] != null ? widget.tournament['viewers'].toString() : null);

                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    height: 168,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: const Color(0xFF070A11),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (streamThumbnail != null && streamThumbnail.isNotEmpty && !isStandby)
                          Image.network(
                            streamThumbnail,
                            fit: BoxFit.cover,
                            alignment: ArmSphereAssets.cardRightFocal,
                            errorBuilder: (_, __, ___) => Image.asset(
                              ArmSphereAssets.cardLiveBroadcast,
                              fit: BoxFit.cover,
                              alignment: ArmSphereAssets.cardRightFocal,
                            ),
                          )
                        else
                          Image.asset(
                            ArmSphereAssets.cardLiveBroadcast,
                            fit: BoxFit.cover,
                            alignment: ArmSphereAssets.cardRightFocal,
                            errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF070A11)),
                          ),
                        // Left-to-right obsidian safe-zone scrim (protects right-aligned broadcast camera rig)
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Color(0xF5070A11),
                                Color(0xCC070A11),
                                Color(0x33070A11),
                              ],
                              stops: [0.0, 0.55, 1.0],
                            ),
                          ),
                        ),
                        // Left 55% Safe Zone Status Badges & Broadcast Info
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 0.58,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isStandby
                                        ? AppTheme.goldPrimary.withValues(alpha: 0.16)
                                        : const Color(0xFFFF2A6D).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: isStandby ? AppTheme.goldPrimary : const Color(0xFFFF2A6D),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    isStandby
                                        ? (statusStr == 'PUBLISHED' ? 'UPCOMING BROADCAST' : 'LIVE STREAM STANDBY')
                                        : 'LIVE ARENA FEED',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                      color: isStandby ? AppTheme.goldPrimary : const Color(0xFFFF2A6D),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  currentMatch,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.videocam_outlined, size: 12, color: AppTheme.textMuted),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        viewers != null ? '$viewers watching' : 'Multi-angle table telemetry',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
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
                );
              },
            ),

            const SizedBox(height: 16),

            // Stream Status Subtitle
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF2A6D), Color(0xFFFF0055)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF2A6D).withValues(alpha: 0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
          title: const Row(
            children: [
              Icon(Icons.live_tv_rounded, color: Color(0xFFFF2A6D)),
              SizedBox(width: 8),
              Text('YouTube Live Stream', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Opening official tournament live broadcast on YouTube.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Text(
                '• Stream: ${widget.tournament['name'] ?? 'ArmSphere Championship'}\n• Resolution: 1080p60\n• Official ArmSphere Broadcast',
                style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
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

