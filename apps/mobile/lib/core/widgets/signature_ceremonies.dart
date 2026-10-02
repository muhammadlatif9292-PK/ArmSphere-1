import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'count_up_text.dart';
import 'tactile_press_wrapper.dart';
import '../services/sensory_feedback_service.dart';

/// Signature Athletic Ceremonies
///
/// Grounded in:
/// - `docs/design/38_PREMIUM_MOMENT_CATALOG.md` (Moments 1, 2, and 5)
/// - `docs/design/39_DESIGN_DEBT_MAP.md` (Slice 12)
/// - `docs/design/00_DESIGN_AUTHORITY.md`
///
/// Contains:
/// 1. `EloSurgeModal` — Bout win celebratory ELO count-up & resonant bell.
/// 2. `ChampionshipGoldCard` — 45-degree sweeping gold border sheen & medallion drop.
/// 3. `WeighInClearanceStamp` — Physical rubber stamp clearance (140ms easeInQuad + heavy impact).

// ── 1. Bout Win & ELO Surge Modal ──────────────────────────────────────
class EloSurgeModal extends StatefulWidget {
  final String winnerName;
  final String division;
  final num previousElo;
  final num newElo;
  final VoidCallback? onDismiss;

  const EloSurgeModal({
    super.key,
    required this.winnerName,
    required this.division,
    required this.previousElo,
    required this.newElo,
    this.onDismiss,
  });

  static void show(
    BuildContext context, {
    required String winnerName,
    required String division,
    required num previousElo,
    required num newElo,
    VoidCallback? onDismiss,
  }) {
    SensoryFeedbackService.instance.playSensoryCeremony(
      audioEvent: ArmSphereAudioEvent.matchWon,
      hapticType: HapticFeedbackType.ceremonialTriple,
    );

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss ELO Surge',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, _, __) => EloSurgeModal(
        winnerName: winnerName,
        division: division,
        previousElo: previousElo,
        newElo: newElo,
        onDismiss: onDismiss,
      ),
      transitionBuilder: (context, anim, _, child) {
        final scale = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic).value;
        return Transform.scale(
          scale: scale.clamp(0.0, 1.0),
          child: Opacity(opacity: anim.value, child: child),
        );
      },
    );
  }

  @override
  State<EloSurgeModal> createState() => _EloSurgeModalState();
}

class _EloSurgeModalState extends State<EloSurgeModal> {
  bool _countedUp = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _countedUp = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final diff = (widget.newElo - widget.previousElo).toInt();
    final isGain = diff >= 0;

    return Center(
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.cardSurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(color: AppTheme.goldPrimary.withValues(alpha: 0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppTheme.goldPrimary.withValues(alpha: 0.25),
                blurRadius: 24,
                spreadRadius: 2,
              ),
              const BoxShadow(
                color: Colors.black87,
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gold Trophy Icon
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.goldPrimary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.goldPrimary.withValues(alpha: 0.4)),
                ),
                child: const Icon(
                  Icons.sports_kabaddi,
                  color: AppTheme.goldPrimary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'OFFICIAL BOUT VICTORY',
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 1.0,
                  color: AppTheme.goldPrimary,
                ),
              ),
              const SizedBox(height: 6),

              Text(
                widget.winnerName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),

              Text(
                widget.division,
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 20),

              // ELO Counter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.elevatedSurface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Column(
                  children: [
                    const Text(
                      'UPDATED ELO RATING',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        CountUpText(
                          value: widget.newElo,
                          duration: const Duration(milliseconds: 600),
                          style: TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontWeight: FontWeight.w800,
                            fontSize: 40,
                            color: _countedUp ? AppTheme.success : AppTheme.goldPrimary,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${isGain ? '+' : ''}$diff ELO',
                          style: TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: isGain ? AppTheme.success : AppTheme.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Dismiss CTA
              TactilePressWrapper(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).pop();
                  if (widget.onDismiss != null) widget.onDismiss!();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.goldPrimary,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'VIEW UPDATED BRACKET',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Colors.black,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 2. Championship Gold Border Sheen Card ─────────────────────────────
class ChampionshipGoldCard extends StatefulWidget {
  final String championshipTitle;
  final String athleteName;
  final String dateLocation;
  final VoidCallback? onShare;

  const ChampionshipGoldCard({
    super.key,
    required this.championshipTitle,
    required this.athleteName,
    required this.dateLocation,
    this.onShare,
  });

  @override
  State<ChampionshipGoldCard> createState() => _ChampionshipGoldCardState();
}

class _ChampionshipGoldCardState extends State<ChampionshipGoldCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _shimmerAnim = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (context, child) {
        final val = _shimmerAnim.value;
        return Container(
          padding: const EdgeInsets.all(2.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            gradient: LinearGradient(
              begin: const Alignment(-1.0, -1.0),
              end: const Alignment(1.0, 1.0),
              colors: const [
                Color(0xFFD4AF37), // Pure Championship Gold
                Color(0xFFFFF3B0), // Gold Luster Sheen
                Color(0xFFAA7C11), // Deep Milled Bronze Gold
                Color(0xFFD4AF37),
              ],
              stops: [
                (val - 0.3).clamp(0.0, 1.0),
                val.clamp(0.0, 1.0),
                (val + 0.3).clamp(0.0, 1.0),
                1.0,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.goldPrimary.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardSurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium - 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Gold Medallion
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFFFFF3B0), Color(0xFFD4AF37)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.goldPrimary.withValues(alpha: 0.5),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.emoji_events, color: Colors.black87, size: 32),
                  ),
                ),
                const SizedBox(height: 14),

                Text(
                  widget.championshipTitle.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppTheme.goldPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),

                Text(
                  widget.athleteName,
                  style: const TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),

                Text(
                  widget.dateLocation,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                if (widget.onShare != null) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      widget.onShare!();
                    },
                    icon: const Icon(Icons.share_outlined, size: 16),
                    label: const Text('Share Championship Card'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.goldPrimary,
                      side: const BorderSide(color: AppTheme.goldPrimary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── 3. Weigh-In Physical Rubber Clearance Stamp (SIG-5) ───────────────
class WeighInClearanceStamp extends StatefulWidget {
  final bool isApproved;
  final String clearanceText;
  final String? subText;
  final double size;

  const WeighInClearanceStamp({
    super.key,
    required this.isApproved,
    this.clearanceText = 'OFFICIALLY CLEARED',
    this.subText,
    this.size = 1.0,
  });

  @override
  State<WeighInClearanceStamp> createState() => _WeighInClearanceStampState();
}

class _WeighInClearanceStampState extends State<WeighInClearanceStamp>
    with TickerProviderStateMixin {
  late AnimationController _stampController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late AnimationController _shockwaveController;
  late Animation<double> _shockwaveAnim;

  @override
  void initState() {
    super.initState();
    // SIG-5 Stage 1: 150ms descent from Scale 2.50 to 1.00 at -12° rotation
    _stampController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(begin: 2.5, end: 1.0).animate(
      CurvedAnimation(parent: _stampController, curve: Curves.easeInQuad),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _stampController, curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );

    // SIG-5 Stage 2: 120ms chalk dust particle shockwave
    _shockwaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _shockwaveAnim = CurvedAnimation(
      parent: _shockwaveController,
      curve: Curves.easeOut,
    );

    if (widget.isApproved) {
      _triggerStamp();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations && widget.isApproved) {
      _stampController.value = 1.0;
      _shockwaveController.value = 0.0;
    }
  }

  void _triggerStamp() {
    final disableAnimations = (mounted && context.mounted)
        ? (MediaQuery.maybeOf(context)?.disableAnimations ?? false)
        : false;
    if (disableAnimations) {
      _stampController.value = 1.0;
      _shockwaveController.value = 0.0;
      return;
    }
    _stampController.forward(from: 0.0).then((_) {
      // Impact at 150ms: Heavy haptic shockwave
      HapticFeedback.heavyImpact();
      if (mounted) {
        _shockwaveController.forward(from: 0.0);
      }
    });
  }

  @override
  void didUpdateWidget(WeighInClearanceStamp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isApproved && widget.isApproved) {
      _triggerStamp();
    }
  }

  @override
  void dispose() {
    _stampController.dispose();
    _shockwaveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isApproved) return const SizedBox.shrink();

    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    const stampAngle = -12.0 * (math.pi / 180.0); // Exactly -12 degrees

    return Semantics(
      container: true,
      label: 'Athlete weigh-in clearance seal: ${widget.clearanceText}. ${widget.subText ?? ''}',
      child: RepaintBoundary(
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // 8-particle chalk shockwave expanding and fading (skipped if reduced motion)
            if (!disableAnimations)
              AnimatedBuilder(
                animation: _shockwaveAnim,
                builder: (context, _) {
                  if (_shockwaveAnim.value <= 0.0 || _shockwaveAnim.value >= 1.0) {
                    return const SizedBox.shrink();
                  }
                  return CustomPaint(
                    size: Size(180 * widget.size, 80 * widget.size),
                    painter: _ChalkShockwavePainter(
                      progress: _shockwaveAnim.value,
                      particleColor: const Color(0xFF10B981),
                    ),
                  );
                },
              ),

            // Technical Rubber Stamp
            AnimatedBuilder(
              animation: _stampController,
              builder: (context, child) {
                final effectiveScale = disableAnimations
                    ? 1.0 * widget.size
                    : _scaleAnimation.value * widget.size;
                final effectiveOpacity = disableAnimations
                    ? 1.0
                    : _opacityAnimation.value;

                return Transform.rotate(
                  angle: stampAngle,
                  child: Transform.scale(
                    scale: effectiveScale,
                    child: Opacity(
                      opacity: effectiveOpacity,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF10B981),
                          width: 2.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.25),
                            blurRadius: 10,
                            spreadRadius: -1,
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.65),
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified_rounded,
                                  color: Color(0xFF10B981),
                                  size: 14,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  widget.clearanceText.toUpperCase(),
                                  style: const TextStyle(
                                    fontFamily: 'Space Grotesk',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    color: Color(0xFF10B981),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            if (widget.subText != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.subText!.toUpperCase(),
                                style: TextStyle(
                                  fontFamily: 'Space Grotesk',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 8.5,
                                  color: const Color(0xFF10B981).withValues(alpha: 0.85),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}
}

/// 8 micro-particles radiating outwards from stamp impact
class _ChalkShockwavePainter extends CustomPainter {
  final double progress;
  final Color particleColor;

  _ChalkShockwavePainter({required this.progress, required this.particleColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = particleColor.withValues(alpha: (1.0 - progress) * 0.75)
      ..style = PaintingStyle.fill;

    const int particleCount = 8;
    final double radius = 24.0 + (progress * 38.0);

    for (int i = 0; i < particleCount; i++) {
      final double angle = (i * (2 * math.pi / particleCount)) + 0.2;
      final double x = center.dx + math.cos(angle) * radius * 1.5;
      final double y = center.dy + math.sin(angle) * radius * 0.9;
      final double dotSize = (3.0 * (1.0 - progress)).clamp(0.5, 3.0);
      canvas.drawCircle(Offset(x, y), dotSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChalkShockwavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
