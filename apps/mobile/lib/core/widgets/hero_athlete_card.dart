import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'count_up_text.dart';

/// Particle model for the subtle ambient background dust
class _Particle {
  double x;
  double y;
  double radius;
  double speed;
  double alpha;

  _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.alpha,
  });
}

/// CustomPainter to render tiny floating gold particles inside the Hero Card background
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double animationValue;

  _ParticlePainter({required this.particles, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var p in particles) {
      // Calculate updated Y based on animation value
      final currentY = (p.y - (animationValue * p.speed)) % size.height;
      final opacity = (p.alpha * (0.4 + 0.6 * math.sin(animationValue * math.pi * 2 + p.x * 10))).clamp(0.05, 0.35);

      paint.color = AppTheme.goldPrimary.withOpacity(opacity);
      canvas.drawCircle(Offset(p.x * size.width, currentY), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}

/// Ultra-Premium Signature Hero Athlete Card for ArmSphere (Concept 2 - Glass Morphism Luxury)
class HeroAthleteCard extends StatefulWidget {
  final String name;
  final String federation;
  final String weightClass;
  final String countryFlag;
  final String armPreference;
  final String licenseStatus;
  final bool isVerified;
  final String rankTier; // e.g. "Elite", "Pro", "Master"
  final int currentElo;
  final int eloGain;
  final int worldRank;
  final double progressToNextRank; // 0.0 to 1.0
  final double winRate;
  final String profileImageUrl;
  final String activeStatus; // e.g. "Online / Training"
  final String currentSeason;
  final VoidCallback? onTap;

  const HeroAthleteCard({
    Key? key,
    this.name = 'John Diesel',
    this.federation = 'Pakistan Armwrestling Federation',
    this.weightClass = '-95kg Heavyweight',
    this.countryFlag = '🇵🇰',
    this.armPreference = 'Right Hand',
    this.licenseStatus = 'PRO LICENSE #8821',
    this.isVerified = true,
    this.rankTier = 'Elite',
    this.currentElo = 2016,
    this.eloGain = 24,
    this.worldRank = 23,
    this.progressToNextRank = 0.84,
    this.winRate = 0.78,
    this.profileImageUrl = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=400',
    this.activeStatus = 'Active Circuit',
    this.currentSeason = '2026 Season',
    this.onTap,
  }) : super(key: key);

  @override
  State<HeroAthleteCard> createState() => _HeroAthleteCardState();
}

class _HeroAthleteCardState extends State<HeroAthleteCard> with TickerProviderStateMixin {
  late AnimationController _ambientController;
  late AnimationController _floatController;
  late AnimationController _touchController;
  late Animation<double> _scaleAnimation;
  late List<_Particle> _particles;

  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    // 1. Continuous ambient background lighting & particle ticker (8s loop)
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // 2. Subtle floating profile avatar translation (-3px to +3px, 3s sine wave)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    // 3. Tactile touch press/lift animation
    _touchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.982).animate(
      CurvedAnimation(parent: _touchController, curve: Curves.easeOutCubic),
    );

    // Generate 10 subtle gold dust particles
    _particles = List.generate(10, (index) {
      return _Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble() * 300,
        radius: 1.2 + _random.nextDouble() * 1.8,
        speed: 40 + _random.nextDouble() * 50,
        alpha: 0.2 + _random.nextDouble() * 0.3,
      );
    });
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _floatController.dispose();
    _touchController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    HapticFeedback.selectionClick();
    _touchController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _touchController.reverse();
    if (widget.onTap != null) widget.onTap!();
  }

  double _tiltX = 0.0;
  double _tiltY = 0.0;

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    final dx = details.localPosition.dx - (size.width / 2);
    final dy = details.localPosition.dy - (size.height / 2);
    setState(() {
      _tiltY = (dx / (size.width / 2)).clamp(-1.0, 1.0) * 0.06;
      _tiltX = (-dy / (size.height / 2)).clamp(-1.0, 1.0) * 0.06;
    });
  }

  void _onPanEnd([DragEndDetails? details]) {
    setState(() {
      _tiltX = 0.0;
      _tiltY = 0.0;
    });
    _touchController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          constraints.hasBoundedWidth ? constraints.maxWidth : 340,
          constraints.hasBoundedHeight ? constraints.maxHeight : 240,
        );

        return AnimatedBuilder(
          animation: _touchController,
          builder: (context, child) {
            final scaleVal = _scaleAnimation.value;
            final transform = Matrix4.identity()
              ..setEntry(3, 2, 0.001) // Perspective
              ..rotateX(_tiltX)
              ..rotateY(_tiltY)
              ..scale(scaleVal);

            return Transform(
              transform: transform,
              alignment: Alignment.center,
              child: child,
            );
          },
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onPanEnd,
            onPanUpdate: (d) => _onPanUpdate(d, size),
            onPanEnd: _onPanEnd,
            child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.0),
            boxShadow: [
              BoxShadow(
                color: const Color(0x38D4AF37), // 22% gold ambient glow
                blurRadius: 24.0,
                spreadRadius: -4.0,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 20.0,
                spreadRadius: 2.0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
              child: AnimatedBuilder(
                animation: _ambientController,
                builder: (context, child) {
                  final animVal = _ambientController.value;
                  return Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(
                        color: AppTheme.goldPrimary.withOpacity(0.25),
                        width: 1.2,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment(
                          math.sin(animVal * math.pi * 2) * 0.8 - 0.5,
                          -1.0,
                        ),
                        end: Alignment(
                          math.cos(animVal * math.pi * 2) * 0.8 + 0.5,
                          1.0,
                        ),
                        colors: const [
                          Color(0xFF1E2332), // Deep satin titanium
                          Color(0xFF121622), // Onyx core
                          Color(0xFF0D0F18), // Void black base
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Background floating gold particles
                        Positioned.fill(
                          child: CustomPainterWidget(
                            painter: _ParticlePainter(
                              particles: _particles,
                              animationValue: animVal,
                            ),
                          ),
                        ),

                        // Subtle top-right radial sheen highlight
                        Positioned(
                          top: -60,
                          right: -60,
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppTheme.goldPrimary.withOpacity(0.12),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Main Content Column
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Top Athlete Bar (Avatar, Name, Badges, Status)
                            _buildAthleteHeader(),

                            const SizedBox(height: 16),

                            // 2. Central ELO & World Rank Glass Bay
                            _buildEloRankBay(),

                            const SizedBox(height: 16),

                            // 3. Footer Metrics Pill Bar (Arm, License, Win Rate)
                            _buildFooterMetricsRow(),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  },
);
  }

  /// 1. Top Athlete Header with floating profile photo, name, verification & federation
  Widget _buildAthleteHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Floating Avatar Container with Shared Element Hero Tag
        Hero(
          tag: 'athlete_avatar_${widget.name}',
          child: AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              final floatY = math.sin(_floatController.value * math.pi) * 3.0 - 1.5;
              return Transform.translate(
                offset: Offset(0, floatY),
                child: child,
              );
            },
            child: Stack(
            children: [
              // Outer Gold Ring
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      AppTheme.goldLight,
                      AppTheme.goldPrimary,
                      AppTheme.goldDark,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.goldPrimary.withOpacity(0.35),
                      blurRadius: 10.0,
                      spreadRadius: 1.0,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: AppTheme.elevatedSurface,
                  backgroundImage: NetworkImage(widget.profileImageUrl),
                ),
              ),

              // Verified Shield Badge at bottom right of avatar
              if (widget.isVerified)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Color(0xFF121622),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified,
                      size: 16,
                      color: AppTheme.goldPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),

        const SizedBox(width: 14),

        // Athlete Info Column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting & Elite Rank Tier Badge
              Row(
                children: [
                  Text(
                    'GOOD MORNING,',
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppTheme.textMuted.withOpacity(0.8),
                    ),
                  ),
                  const Spacer(),
                  // Tier Badge Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.goldPrimary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.goldPrimary.withOpacity(0.4),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.military_tech,
                          size: 12,
                          color: AppTheme.goldPrimary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          widget.rankTier.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.goldPrimary,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 2),

              // Name & Country Flag
              Row(
                children: [
                  Flexible(
                    child: Text(
                      widget.name,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.countryFlag,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),

              const SizedBox(height: 2),

              // Federation & Weight Class
              Text(
                '${widget.federation} • ${widget.weightClass}',
                style: const TextStyle(
                  fontFamily: AppTheme.fontBody,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 2. Central ELO & World Rank Glass Bay (Matching Concept 2 with Golden Arm Emblem)
  Widget _buildEloRankBay() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xCC0E111A), // Deep matte glass inset
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(
          color: AppTheme.goldPrimary.withOpacity(0.18),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ELO & Rank Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label
                    Text(
                      'CURRENT ELO',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        color: AppTheme.textSecondary.withOpacity(0.7),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Elo Number & Delta Pill
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        CountUpText(
                          value: widget.currentElo,
                          duration: const Duration(milliseconds: 350),
                          style: const TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Delta Badge Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppTheme.success.withOpacity(0.4),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.arrow_drop_up,
                                size: 14,
                                color: AppTheme.success,
                              ),
                              Text(
                                '${widget.eloGain}',
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // World Rank
                    Row(
                      children: [
                        Text(
                          'WORLD RANK',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: AppTheme.textMuted.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '#${widget.worldRank}',
                          style: const TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.goldPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Right side: Golden Arm Wrestling Trophy Emblem
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.goldPrimary.withOpacity(0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.workspace_premium,
                        size: 48,
                        color: AppTheme.goldPrimary.withOpacity(0.9),
                      ),
                      Positioned(
                        child: Icon(
                          Icons.fitness_center,
                          size: 20,
                          color: Colors.black.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Progress Bar to next rank
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progress to next rank',
                    style: TextStyle(
                      fontFamily: AppTheme.fontBody,
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    '${(widget.progressToNextRank * 100).toInt()}%',
                    style: const TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.goldLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 5,
                  child: LinearProgressIndicator(
                    value: widget.progressToNextRank,
                    backgroundColor: const Color(0xFF1E2330),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.goldPrimary),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 3. Footer Metrics Pill Row (Arm Preference, License, Win Rate, Season)
  Widget _buildFooterMetricsRow() {
    return Row(
      children: [
        // Arm Preference Tag
        _buildMetricChip(
          icon: Icons.back_hand_outlined,
          label: widget.armPreference,
        ),

        const SizedBox(width: 8),

        // License Status
        _buildMetricChip(
          icon: Icons.shield_outlined,
          label: widget.licenseStatus,
        ),

        const Spacer(),

        // Win Rate Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0x1AD4AF37),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.goldPrimary.withOpacity(0.3),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.bolt,
                size: 13,
                color: AppTheme.goldPrimary,
              ),
              const SizedBox(width: 4),
              Text(
                '${(widget.winRate * 100).toInt()}% WIN',
                style: const TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.goldPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppTheme.fontBody,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper wrapper for CustomPainter
class CustomPainterWidget extends StatelessWidget {
  final CustomPainter painter;

  const CustomPainterWidget({Key? key, required this.painter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: painter,
      size: Size.infinite,
    );
  }
}
