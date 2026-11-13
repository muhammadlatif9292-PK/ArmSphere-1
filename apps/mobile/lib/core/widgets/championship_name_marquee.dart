import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'crystal_slash_painter.dart';

/// Smart Broadcast Nameplate & Auto-Gliding Ticker for Athlete Names.
///
/// - When [text] fits within the available horizontal constraints, renders a
///   crisp static [Text] widget with zero unnecessary animation overhead.
/// - When [text] overflows the available width (e.g., long athlete names such as
///   "Muhammad Hamad Latif"), smoothly glides horizontally back and forth with
///   pause-at-start and pause-at-end choreography and soft optical edge fades,
///   eliminating ugly "..." truncation.
class ChampionshipNameMarquee extends StatefulWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final double velocityPxPerSecond;
  final Duration startPause;
  final Duration endPause;

  ChampionshipNameMarquee({
    super.key,
    String? text,
    String? name,
    required this.style,
    this.textAlign = TextAlign.start,
    this.velocityPxPerSecond = 26.0,
    this.startPause = const Duration(milliseconds: 1800),
    this.endPause = const Duration(milliseconds: 1400),
  })  : text = text ?? name ?? '',
        assert(text != null || name != null, 'Either text or name must be provided');

  @override
  State<ChampionshipNameMarquee> createState() =>
      _ChampionshipNameMarqueeState();
}

class _ChampionshipNameMarqueeState extends State<ChampionshipNameMarquee> {
  final ScrollController _scrollController = ScrollController();
  Timer? _loopTimer;
  bool _isDisposed = false;
  double _lastMaxOverflow = 0.0;

  @override
  void didUpdateWidget(covariant ChampionshipNameMarquee oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _loopTimer?.cancel();
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0.0);
      }
      _lastMaxOverflow = 0.0;
    }
  }

  void _ensureGlideLoop(double overflowDistance) {
    if (_isDisposed || overflowDistance <= 2.0) {
      _loopTimer?.cancel();
      _loopTimer = null;
      return;
    }
    if ((_lastMaxOverflow - overflowDistance).abs() < 1.5 &&
        _loopTimer != null) {
      return;
    }
    _lastMaxOverflow = overflowDistance;
    _loopTimer?.cancel();
    _scheduleNextCycle(overflowDistance);
  }

  void _scheduleNextCycle(double overflowDistance) {
    if (_isDisposed) return;
    _loopTimer = Timer(widget.startPause, () async {
      if (_isDisposed || !mounted || !_scrollController.hasClients) return;
      final double maxExtent = _scrollController.position.maxScrollExtent;
      if (maxExtent <= 2.0) return;

      final int forwardMs =
          ((maxExtent / widget.velocityPxPerSecond) * 1000).round().clamp(
                900,
                9000,
              );
      try {
        await _scrollController.animateTo(
          maxExtent,
          duration: Duration(milliseconds: forwardMs),
          curve: Curves.easeInOutSine,
        );
      } catch (_) {
        return;
      }

      if (_isDisposed || !mounted) return;
      await Future<void>.delayed(widget.endPause);
      if (_isDisposed || !mounted || !_scrollController.hasClients) return;

      try {
        await _scrollController.animateTo(
          0.0,
          duration: Duration(milliseconds: (forwardMs * 0.85).round()),
          curve: Curves.easeInOutSine,
        );
      } catch (_) {
        return;
      }

      if (!_isDisposed && mounted) {
        _scheduleNextCycle(maxExtent);
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _loopTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth || constraints.maxWidth <= 0) {
          return Text(
            widget.text,
            style: widget.style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: widget.textAlign,
          );
        }

        final textScaler = MediaQuery.textScalerOf(context);
        final textDirection = Directionality.of(context);
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          maxLines: 1,
          textDirection: textDirection,
          textScaler: textScaler,
        )..layout();

        final double textWidth = painter.width;
        final double textHeight = painter.height;
        painter.dispose();

        final double availableWidth = constraints.maxWidth;
        final double overflow = textWidth - availableWidth;

        // Fits cleanly: render crisp static Text with zero scroll overhead.
        if (overflow <= 2.0) {
          _loopTimer?.cancel();
          _loopTimer = null;
          return SizedBox(
            width: availableWidth,
            child: Text(
              widget.text,
              style: widget.style,
              maxLines: 1,
              softWrap: false,
              textAlign: widget.textAlign,
            ),
          );
        }

        // Overflows: schedule smooth auto-glide ticker and apply subtle right/left optical fade.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _ensureGlideLoop(overflow + 10.0);
          }
        });

        return SizedBox(
          width: availableWidth,
          height: textHeight + 2.0,
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: <double>[0.0, 0.03, 0.92, 1.0],
                colors: <Color>[
                  Color(0xD9FFFFFF),
                  Color(0xFFFFFFFF),
                  Color(0xFFFFFFFF),
                  Color(0x00FFFFFF),
                ],
              ).createShader(bounds);
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.text,
                    style: widget.style,
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Data model for a single biometric or specification card in [BiometricsHorizontalCarousel].
class BiometricMetricSpec {
  final String tag;
  final String label;
  final String value;
  final String? unit;
  final IconData icon;
  final Color accentColor;
  final bool isWide;

  const BiometricMetricSpec({
    required this.tag,
    required this.label,
    required this.value,
    this.unit,
    required this.icon,
    this.accentColor = AppTheme.goldPrimary,
    this.isWide = false,
  });
}

/// Interactive Swipeable Horizontal Carousel for Athlete Biometrics & Specifications.
///
/// Replaces cramped single-row boxes with spacious Forged-Crystal Telemetry Cards
/// that the user can smoothly swipe across with their finger, complete with a
/// live progress track indicator and precision caliper graduation ticks.
class BiometricsHorizontalCarousel extends StatefulWidget {
  final Map<String, dynamic> profile;
  final VoidCallback? onEditTap;

  const BiometricsHorizontalCarousel({
    super.key,
    required this.profile,
    this.onEditTap,
  });

  @override
  State<BiometricsHorizontalCarousel> createState() =>
      _BiometricsHorizontalCarouselState();
}

class _BiometricsHorizontalCarouselState
    extends State<BiometricsHorizontalCarousel> {
  final ScrollController _scrollController = ScrollController();
  double _scrollFraction = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxExtent = _scrollController.position.maxScrollExtent;
    final nextFraction = maxExtent > 0
        ? (_scrollController.offset / maxExtent).clamp(0.0, 1.0)
        : 0.0;
    if ((nextFraction - _scrollFraction).abs() > 0.01 && mounted) {
      setState(() {
        _scrollFraction = nextFraction;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  List<BiometricMetricSpec> _buildMetricsList(Map<String, dynamic> profile) {
    final measurements = profile['measurements'] as Map<String, dynamic>?;
    final biometrics = profile['biometrics'] as Map<String, dynamic>?;

    final rawWeight =
        profile['weightKg'] ?? profile['weight'] ?? measurements?['weight'] ?? biometrics?['weightKg'];
    final rawHeight =
        profile['heightCm'] ?? profile['height'] ?? measurements?['height'] ?? biometrics?['heightCm'];
    final rawReach =
        profile['reachCm'] ?? profile['reach'] ?? measurements?['reach'] ?? biometrics?['reachCm'];
    final rawDominance = (profile['armDominance'] ??
            profile['dominantArm'] ??
            biometrics?['dominantArm'])
        ?.toString()
        .trim();
    final rawWeightClass = profile['weightClass']?.toString().trim();
    final rawDivision = profile['division']?.toString().trim();
    final rawForearm =
        profile['forearmCircumference'] ?? biometrics?['forearmCircumference'];
    final rawBicep =
        profile['bicepCircumference'] ?? biometrics?['bicepCircumference'];
    final rawHand = profile['handLength'] ??
        biometrics?['handLength'] ??
        biometrics?['handWidth'];

    String formatHandOfPlay(String? dom) {
      if (dom == null || dom.isEmpty) return 'RIGHT / LEFT';
      final upper = dom.toUpperCase();
      if (upper == 'BOTH' || upper == 'AMBIDEXTROUS') return 'AMBIDEXTROUS';
      if (upper == 'LEFT' || upper == 'LEFT ARM') return 'LEFT ARM';
      if (upper == 'RIGHT' || upper == 'RIGHT ARM') return 'RIGHT ARM';
      return upper;
    }

    final List<BiometricMetricSpec> items = [
      BiometricMetricSpec(
        tag: 'HAND OF PLAY',
        label: 'Arm Dominance',
        value: formatHandOfPlay(rawDominance),
        icon: Icons.front_hand_outlined,
        accentColor: AppTheme.goldPrimary,
        isWide: true,
      ),
      BiometricMetricSpec(
        tag: 'MASS',
        label: 'Body Weight',
        value: rawWeight != null && rawWeight.toString().isNotEmpty
            ? '$rawWeight'
            : '--',
        unit: rawWeight != null && rawWeight.toString().isNotEmpty ? 'kg' : null,
        icon: Icons.monitor_weight_outlined,
        accentColor: AppTheme.crimson,
      ),
      BiometricMetricSpec(
        tag: 'STATURE',
        label: 'Standing Height',
        value: rawHeight != null && rawHeight.toString().isNotEmpty
            ? '$rawHeight'
            : '--',
        unit: rawHeight != null && rawHeight.toString().isNotEmpty ? 'cm' : null,
        icon: Icons.height_rounded,
        accentColor: AppTheme.cyan,
      ),
      BiometricMetricSpec(
        tag: 'WINGSPAN',
        label: 'Arm Reach',
        value: rawReach != null && rawReach.toString().isNotEmpty
            ? '$rawReach'
            : '--',
        unit: rawReach != null && rawReach.toString().isNotEmpty ? 'cm' : null,
        icon: Icons.open_in_full_rounded,
        accentColor: AppTheme.goldPrimary,
      ),
      BiometricMetricSpec(
        tag: 'CATEGORY',
        label: rawDivision != null && rawDivision.isNotEmpty
            ? '$rawDivision Class'
            : 'Weight Class',
        value: rawWeightClass != null && rawWeightClass.isNotEmpty
            ? rawWeightClass.toUpperCase()
            : 'OPEN',
        icon: Icons.shield_outlined,
        accentColor: AppTheme.emerald,
      ),
      if (rawForearm != null && rawForearm.toString().isNotEmpty)
        BiometricMetricSpec(
          tag: 'LEVERAGE',
          label: 'Forearm Girth',
          value: '$rawForearm',
          unit: 'cm',
          icon: Icons.fitness_center_rounded,
          accentColor: AppTheme.crimson,
        ),
      if (rawBicep != null && rawBicep.toString().isNotEmpty)
        BiometricMetricSpec(
          tag: 'POWER',
          label: 'Bicep Girth',
          value: '$rawBicep',
          unit: 'cm',
          icon: Icons.bolt_rounded,
          accentColor: AppTheme.goldPrimary,
        ),
      if (rawHand != null && rawHand.toString().isNotEmpty)
        BiometricMetricSpec(
          tag: 'GRIP',
          label: 'Hand Span',
          value: '$rawHand',
          unit: 'cm',
          icon: Icons.pan_tool_alt_outlined,
          accentColor: AppTheme.cyan,
        ),
    ];

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _buildMetricsList(widget.profile);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 112,
          child: ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 2),
            itemCount: metrics.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final spec = metrics[index];
              return _BiometricCarouselCard(spec: spec);
            },
          ),
        ),
        const SizedBox(height: 10),
        // Subtle interactive swipe telemetry bar & hint
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const Icon(
                Icons.swipe_rounded,
                size: 12,
                color: AppTheme.textMuted,
              ),
              const SizedBox(width: 6),
              const Text(
                'SWIPE TELEMETRY',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double trackW = constraints.maxWidth;
                    final double thumbW = math.max(28.0, trackW * 0.32);
                    final double maxOffset = math.max(0.0, trackW - thumbW);
                    return Container(
                      height: 3.5,
                      decoration: BoxDecoration(
                        color: const Color(0x22FFFFFF),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Transform.translate(
                          offset: Offset(maxOffset * _scrollFraction, 0),
                          child: Container(
                            width: thumbW,
                            height: 3.5,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppTheme.crimson,
                                  AppTheme.goldPrimary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BiometricCarouselCard extends StatelessWidget {
  final BiometricMetricSpec spec;

  const _BiometricCarouselCard({required this.spec});

  @override
  Widget build(BuildContext context) {
    final double cardWidth = spec.isWide ? 168.0 : 132.0;

    return Container(
      width: cardWidth,
      decoration: BoxDecoration(
        color: const Color(0x4704060B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: spec.accentColor.withValues(alpha: 0.42),
          width: 1.0,
        ),
      ),
      child: CrystalSlashWrapper.crossedCard(
        borderRadius: BorderRadius.circular(16),
        accentColor: spec.accentColor,
        watermark: ForgedWatermarkType.caliperTicks,
        paintOpticalLens: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top row: micro tag + icon badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      spec.tag,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 9.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: spec.accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    spec.icon,
                    size: 14,
                    color: spec.accentColor.withValues(alpha: 0.9),
                  ),
                ],
              ),
              // Center row: primary metric value + optional unit
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            spec.value,
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontWeight: FontWeight.w800,
                              fontSize: spec.isWide ? 15.5 : 21.0,
                              letterSpacing: spec.isWide ? 0.3 : -0.3,
                              color: AppTheme.textPure,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                              shadows: AppTheme.crystalTextShadows,
                            ),
                          ),
                          if (spec.unit != null) ...[
                            const SizedBox(width: 3),
                            Text(
                              spec.unit!,
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.0,
                                color: spec.accentColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Bottom row: descriptive label above caliper ruler ticks
              Text(
                spec.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: AppTheme.fontBody,
                  fontSize: 11.0,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
