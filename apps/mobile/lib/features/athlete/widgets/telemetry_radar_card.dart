import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

/// Telemetry metric data point
class TelemetryStat {
  final String label;
  final double value; // 0.0 to 1.0
  final String formattedValue; // e.g. '94%' or '94'
  final String description;

  const TelemetryStat({
    required this.label,
    required this.value,
    required this.formattedValue,
    this.description = 'Top Tier Performance Metric',
  });
}

/// CustomPainter for 6-Axis Interactive Radar Chart with Neon Blue Lines
class _NeonRadarChartPainter extends CustomPainter {
  final List<TelemetryStat> stats;
  final double animationProgress;
  final int? selectedIndex;

  _NeonRadarChartPainter({
    required this.stats,
    required this.animationProgress,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (stats.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2 - 32;
    final count = stats.length;

    // Neon Cyan / Blue Theme Colors
    const neonBluePrimary = AppTheme.info; // Electric Sky / Cyan
    const neonBlueGlow = AppTheme.info; // Bright Cyan Neon
    final darkGlassFill = AppTheme.info.withOpacity(0.2);

    // 1. Draw Concentric 6-Axis Radar Grid Rings
    final gridPaint = Paint()
      ..color = AppTheme.info.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int ring = 1; ring <= 4; ring++) {
      final r = (maxRadius / 4) * ring;
      final ringPath = Path();
      for (int i = 0; i < count; i++) {
        final angle = (i * 2 * math.pi / count) - (math.pi / 2);
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        if (i == 0) {
          ringPath.moveTo(x, y);
        } else {
          ringPath.lineTo(x, y);
        }
      }
      ringPath.close();
      canvas.drawPath(ringPath, gridPaint);
    }

    // 2. Draw Radial Spokes
    final spokePaint = Paint()
      ..color = AppTheme.info.withOpacity(0.18)
      ..strokeWidth = 1.1;

    for (int i = 0; i < count; i++) {
      final angle = (i * 2 * math.pi / count) - (math.pi / 2);
      final x = center.dx + maxRadius * math.cos(angle);
      final y = center.dy + maxRadius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), spokePaint);
    }

    // 3. Draw Animated Filled Polygon
    final dataPath = Path();
    final dataPoints = <Offset>[];

    for (int i = 0; i < count; i++) {
      final angle = (i * 2 * math.pi / count) - (math.pi / 2);
      final statValue = (stats[i].value * animationProgress).clamp(0.0, 1.0);
      final r = maxRadius * statValue;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      dataPoints.add(Offset(x, y));

      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();

    // Polygon Area Gradient
    final polyFillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        center: Alignment.center,
        colors: [
          neonBlueGlow.withOpacity(0.35),
          neonBluePrimary.withOpacity(0.12),
          darkGlassFill.withOpacity(0.02),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));

    canvas.drawPath(dataPath, polyFillPaint);

    // Outer Neon Glow Shader Line
    final polyGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = neonBlueGlow.withOpacity(0.65)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawPath(dataPath, polyGlowPaint);

    // Primary Crisp Neon Line
    final polyLinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = neonBlueGlow;

    canvas.drawPath(dataPath, polyLinePaint);

    // 4. Vertex Points & Category Labels
    final dotPaint = Paint()..color = Colors.white;
    final dotGlowPaint = Paint()
      ..color = neonBlueGlow
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    for (int i = 0; i < dataPoints.length; i++) {
      final p = dataPoints[i];
      final isSelected = selectedIndex == i;

      if (isSelected) {
        // Highlighted Pulse Ring for Selected Vertex
        final selectedRingPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = neonBlueGlow;

        canvas.drawCircle(p, 9.0, selectedRingPaint);
        canvas.drawCircle(p, 6.0, dotGlowPaint);
        canvas.drawCircle(p, 4.0, dotPaint);
      } else {
        canvas.drawCircle(p, 5.0, dotGlowPaint);
        canvas.drawCircle(p, 3.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NeonRadarChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.stats != stats ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}

/// Telemetry Radar & Biometrics Overview Card
class TelemetryRadarCard extends StatefulWidget {
  const TelemetryRadarCard({Key? key}) : super(key: key);

  @override
  State<TelemetryRadarCard> createState() => _TelemetryRadarCardState();
}

class _TelemetryRadarCardState extends State<TelemetryRadarCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  int _selectedTab = 0; // 0 = Radar Analytics, 1 = Biometrics Grid
  int? _selectedCategoryIndex = 0; // Default selected category

  final List<TelemetryStat> _radarCategories = const [
    TelemetryStat(
      label: 'Strength',
      value: 0.94,
      formattedValue: '94%',
      description: 'Peak pronation, wrist flexion, & backpressure output',
    ),
    TelemetryStat(
      label: 'Technique',
      value: 0.88,
      formattedValue: '88%',
      description: 'Toproll velocity, hook transition, & strap mastery',
    ),
    TelemetryStat(
      label: 'Endurance',
      value: 0.82,
      formattedValue: '82%',
      description: 'Ischemic stamina & multi-round recovery rate',
    ),
    TelemetryStat(
      label: 'Experience',
      value: 0.90,
      formattedValue: '90%',
      description: '100+ Pro matches & high-pressure arena resilience',
    ),
    TelemetryStat(
      label: 'Activity',
      value: 0.85,
      formattedValue: '85%',
      description: 'Active tournament participation & monthly bouts',
    ),
    TelemetryStat(
      label: 'Consistency',
      value: 0.96,
      formattedValue: '96%',
      description: 'Undefeated in 10 consecutive regional matches',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    // Draw radar itself on load
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _triggerRedraw() {
    _animController.reset();
    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 3.5,
                  height: 15,
                  decoration: BoxDecoration(
                    color: AppTheme.info,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.info.withOpacity(0.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'SPORTS ANALYTICS RADAR',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),

            // Tab Selector
            Row(
              children: ['Radar', 'Biometrics'].asMap().entries.map((entry) {
                final idx = entry.key;
                final title = entry.value;
                final isSelected = idx == _selectedTab;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedTab = idx;
                    });
                    if (idx == 0) {
                      _triggerRedraw();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(left: 6),
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.info.withOpacity(0.2)
                          : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.info.withOpacity(0.6)
                            : Colors.transparent,
                        width: 0.9,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.info.withOpacity(0.25),
                                blurRadius: 8,
                              ),
                            ]
                          : [],
                    ),
                    child: Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                        color: isSelected ? AppTheme.info : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Dark Glassmorphic Container
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.glassSurface, // Dark Onyx Glass
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppTheme.info.withOpacity(0.35),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.info.withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: -2,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.55),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.surface,
                    AppTheme.glassSurface,
                    AppTheme.background,
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
              child: AnimatedCrossFade(
                duration: const Duration(milliseconds: 280),
                crossFadeState: _selectedTab == 0
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: _buildRadarView(),
                secondChild: _buildBiometricsGrid(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRadarView() {
    final activeStat = _selectedCategoryIndex != null
        ? _radarCategories[_selectedCategoryIndex!]
        : _radarCategories.first;

    return Column(
      children: [
        // Interactive Neon Blue Self-Drawing Radar Display
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _selectedCategoryIndex =
                  ((_selectedCategoryIndex ?? 0) + 1) % _radarCategories.length;
            });
          },
          child: SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    final curvedProgress = CurvedAnimation(
                      parent: _animController,
                      curve: Curves.easeOutCubic,
                    ).value;

                    return CustomPaint(
                      size: const Size(240, 200),
                      painter: _NeonRadarChartPainter(
                        stats: _radarCategories,
                        animationProgress: curvedProgress,
                        selectedIndex: _selectedCategoryIndex,
                      ),
                    );
                  },
                ),

                // Center Neon Pulse Indicator
                GestureDetector(
                  onTap: _triggerRedraw,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.info,
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.info.withOpacity(0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.refresh_rounded,
                      color: AppTheme.info,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Selected Category Detail Banner
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppTheme.info.withOpacity(0.35),
              width: 0.9,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.info.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: AppTheme.info,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          activeStat.label.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.9,
                            color: AppTheme.info,
                          ),
                        ),
                        Text(
                          activeStat.formattedValue,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activeStat.description,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Interactive Categories Chip Selector Grid
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: _radarCategories.asMap().entries.map((entry) {
            final idx = entry.key;
            final stat = entry.value;
            final isSelected = _selectedCategoryIndex == idx;

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedCategoryIndex = idx;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.info.withOpacity(0.22)
                      : AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.info.withOpacity(0.7)
                        : Colors.white.withOpacity(0.08),
                    width: isSelected ? 1.1 : 0.8,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.info.withOpacity(0.3),
                            blurRadius: 8,
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppTheme.info
                            : AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      stat.label,
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      stat.formattedValue,
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? AppTheme.info : AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBiometricsGrid() {
    final biometrics = const [
      {'title': 'HAND LENGTH', 'val': '21.5 cm', 'icon': Icons.pan_tool_outlined},
      {'title': 'FOREARM GIRTH', 'val': '42.5 cm', 'icon': Icons.fitness_center_outlined},
      {'title': 'WRIST FLEXION', 'val': '72.0 kg', 'icon': Icons.fitness_center},
      {'title': 'PRONATION PR', 'val': '48.5 kg', 'icon': Icons.rotate_right_rounded},
      {'title': 'BACKPRESSURE', 'val': '58.0 kg', 'icon': Icons.arrow_back_rounded},
      {'title': 'REACTION VELOCITY', 'val': '182 ms', 'icon': Icons.speed_rounded},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: biometrics.length,
      itemBuilder: (context, index) {
        final item = biometrics[index];
        return Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.goldPrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  item['icon'] as IconData,
                  color: AppTheme.goldLight,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item['title'] as String,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['val'] as String,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
