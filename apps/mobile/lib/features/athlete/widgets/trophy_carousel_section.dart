import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';

/// Trophy Data Model
class TrophyItem {
  final String id;
  final String title;
  final String category;
  final String year;
  final String tournament;
  final String location;
  final String weightClass;
  final IconData icon;
  final List<Color> gradientColors;
  final Color glowColor;
  final String description;
  final String certificateId;

  const TrophyItem({
    required this.id,
    required this.title,
    required this.category,
    required this.year,
    required this.tournament,
    required this.location,
    required this.weightClass,
    required this.icon,
    required this.gradientColors,
    required this.glowColor,
    required this.description,
    required this.certificateId,
  });
}

/// Horizontal Trophy Showcase Carousel Component
class TrophyCarouselSection extends StatefulWidget {
  const TrophyCarouselSection({Key? key}) : super(key: key);

  @override
  State<TrophyCarouselSection> createState() => _TrophyCarouselSectionState();
}

class _TrophyCarouselSectionState extends State<TrophyCarouselSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _shineController;

  static List<TrophyItem> _trophies = [
    TrophyItem(
      id: 'tr_1',
      title: 'National Heavyweight Gold Cup',
      category: '1ST PLACE • GOLD',
      year: '2025',
      tournament: 'Pakistan Armwrestling Federation Championship',
      location: 'Islamabad Sports Complex',
      weightClass: '-95kg Heavyweight (Right Arm)',
      icon: Icons.emoji_events_rounded,
      gradientColors: [AppTheme.goldLight, AppTheme.secondaryAccent, AppTheme.goldDark],
      glowColor: AppTheme.secondaryAccent,
      description: 'Awarded for securing 1st rank in the National Heavyweight Championship with an undefeated 5-0 match streak.',
      certificateId: 'PK-FED-2025-GOLD-091',
    ),
    TrophyItem(
      id: 'tr_2',
      title: 'Asia Pro Elite Shield',
      category: 'CONTINENTAL CHAMPION',
      year: '2025',
      tournament: 'Asian Professional Armwrestling Cup',
      location: 'Lahore Expo Arena',
      weightClass: '-95kg Pro Tier',
      icon: Icons.military_tech_rounded,
      gradientColors: [AppTheme.info.withOpacity(0.15), AppTheme.info, AppTheme.info],
      glowColor: AppTheme.info,
      description: 'Continental champion shield awarded for defeating top seeded athletes across 8 Asian federation nations.',
      certificateId: 'ASIA-CUP-2025-SHIELD-104',
    ),
    TrophyItem(
      id: 'tr_3',
      title: 'Islamabad Open Supermatch Belt',
      category: 'SUPERMATCH TITLE',
      year: '2026',
      tournament: 'Islamabad Grand Armwrestling Night',
      location: 'Islamabad Arena',
      weightClass: 'Open Weight Division',
      icon: Icons.workspace_premium_rounded,
      gradientColors: [AppTheme.goldLight, AppTheme.goldLight, AppTheme.goldDark],
      glowColor: AppTheme.goldLight,
      description: 'Supermatch championship title belt won in a high-stakes 5-round main event showdown.',
      certificateId: 'ISB-SUPER-2026-BELT-012',
    ),
    TrophyItem(
      id: 'tr_4',
      title: 'Punjab Provincial Crown',
      category: 'PROVINCIAL CHAMP',
      year: '2024',
      tournament: 'Punjab Governor Cup',
      location: 'Rawalpindi Sports Stadium',
      weightClass: '-90kg Senior Division',
      icon: Icons.military_tech_outlined,
      gradientColors: [AppTheme.highlightPurple.withOpacity(0.1), AppTheme.highlightPurple, AppTheme.highlightPurple],
      glowColor: AppTheme.highlightPurple,
      description: 'Provincial crown for dominant performances across all qualifying rounds in Punjab state.',
      certificateId: 'PB-GOV-2024-CROWN-308',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  void _expandTrophyDetails(BuildContext context, TrophyItem item) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TrophyDetailsModal(trophy: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 3.5,
                    height: 15,
                    decoration: BoxDecoration(
                      color: AppTheme.goldPrimary,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.goldPrimary.withOpacity(0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'TROPHY CABINET',
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
              const Text(
                '4 TITLES WON',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppTheme.goldLight,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Horizontal Carousel
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _trophies.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final trophy = _trophies[index];
              return _TrophyCardItem(
                trophy: trophy,
                shineController: _shineController,
                index: index,
                onTap: () => _expandTrophyDetails(context, trophy),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Individual Trophy Card with Glass Stand & Ground Reflection
class _TrophyCardItem extends StatefulWidget {
  final TrophyItem trophy;
  final AnimationController shineController;
  final int index;
  final VoidCallback onTap;

  const _TrophyCardItem({
    Key? key,
    required this.trophy,
    required this.shineController,
    required this.index,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_TrophyCardItem> createState() => _TrophyCardItemState();
}

class _TrophyCardItemState extends State<_TrophyCardItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2200 + (widget.index * 300)),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.trophy;

    return AnimatedBuilder(
      animation: Listenable.merge([widget.shineController, _floatController]),
      builder: (context, child) {
        // Continuous subtle float
        final floatY = math.sin((_floatController.value + widget.index * 0.2) * math.pi * 2) * 2.5;

        // Gold Shine Sweep Math
        final shineVal = (widget.shineController.value + widget.index * 0.25) % 1.0;
        final shineOffset = -1.2 + (shineVal * 2.4);

        return Transform.translate(
          offset: Offset(0, floatY),
          child: TactilePressWrapper(
            onTap: widget.onTap,
            enableLift: true,
            liftDistance: -4,
            child: Container(
              width: 152,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: t.glowColor.withOpacity(0.22),
                    blurRadius: 20,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.glassSurface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: t.glowColor.withOpacity(0.4),
                        width: 1.1,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          t.glowColor.withOpacity(0.18),
                          AppTheme.surface,
                          AppTheme.background,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Shimmer Gold Shine Sweep
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                gradient: LinearGradient(
                                  begin: Alignment(shineOffset - 0.2, -1.0),
                                  end: Alignment(shineOffset + 0.2, 1.0),
                                  colors: [
                                    Colors.transparent,
                                    t.gradientColors.first.withOpacity(0.2),
                                    Colors.white.withOpacity(0.35),
                                    t.gradientColors.first.withOpacity(0.2),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Card Content
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Trophy Display Area with Glass Stand & Reflection
                            _buildTrophyWithGlassStand(t, shineVal),

                            const SizedBox(height: 8),

                            // Trophy Text Info
                            Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: t.glowColor.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: t.glowColor.withOpacity(0.4),
                                      width: 0.6,
                                    ),
                                  ),
                                  child: Text(
                                    t.category,
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.w900,
                                      color: t.glowColor,
                                      letterSpacing: 0.6,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  t.title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.1,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                const SizedBox(height: 2),

                                Text(
                                  '${t.year} • ${t.weightClass}',
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Trophy Visual Image + Pedestal Glass Stand + Reflection
  Widget _buildTrophyWithGlassStand(TrophyItem t, double shineVal) {
    return Column(
      children: [
        // Main Trophy Icon with Gold Gradient
        Container(
          height: 72,
          width: 72,
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background Radial Glow
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: t.glowColor.withOpacity(0.2),
                  boxShadow: [
                    BoxShadow(
                      color: t.glowColor.withOpacity(0.5),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),

              // Trophy Emblem
              ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: t.gradientColors,
                  ).createShader(bounds);
                },
                child: Icon(
                  t.icon,
                  size: 54,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Glass Stand / Pedestal Base
        Container(
          width: 80,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: t.glowColor.withOpacity(0.5),
              width: 0.9,
            ),
            boxShadow: [
              BoxShadow(
                color: t.glowColor.withOpacity(0.3),
                blurRadius: 8,
              ),
            ],
          ),
        ),

        // Reflection Effect Under Glass Stand
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..scale(1.0, -0.4),
          child: Opacity(
            opacity: 0.18,
            child: Container(
              height: 20,
              width: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    t.glowColor,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Trophy Details Modal Sheet
class _TrophyDetailsModal extends StatelessWidget {
  final TrophyItem trophy;

  const _TrophyDetailsModal({
    Key? key,
    required this.trophy,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.8),
            blurRadius: 32,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 20),

          // Large Trophy Display Icon
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: trophy.glowColor.withOpacity(0.18),
              border: Border.all(
                color: trophy.glowColor.withOpacity(0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: trophy.glowColor.withOpacity(0.4),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  colors: trophy.gradientColors,
                ).createShader(bounds);
              },
              child: Icon(
                trophy.icon,
                size: 52,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Title
          Text(
            trophy.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            '${trophy.category} • ${trophy.year}',
            style: TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: trophy.glowColor,
              letterSpacing: 0.8,
            ),
          ),

          const SizedBox(height: 16),

          Divider(color: AppTheme.surface),

          const SizedBox(height: 14),

          // Info Rows
          _buildDetailRow(Icons.emoji_events_outlined, 'TOURNAMENT', trophy.tournament),
          const SizedBox(height: 10),
          _buildDetailRow(Icons.location_on_outlined, 'LOCATION', trophy.location),
          const SizedBox(height: 10),
          _buildDetailRow(Icons.fitness_center_rounded, 'DIVISION', trophy.weightClass),
          const SizedBox(height: 10),
          _buildDetailRow(Icons.verified_outlined, 'CERTIFICATE ID', trophy.certificateId),

          const SizedBox(height: 16),

          // Description Box
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Text(
              trophy.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
                height: 1.35,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Close Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: trophy.glowColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
              ),
              child: const Text(
                'CLOSE TROPHY DETAILS',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.goldLight),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppTheme.textMuted,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
