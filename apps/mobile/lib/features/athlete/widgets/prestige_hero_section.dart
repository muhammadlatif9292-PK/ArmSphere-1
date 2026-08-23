import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/count_up_text.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
import 'athlete_bio_chips_section.dart';

/// Supported Prestige Athlete League Tiers
enum LeagueTier {
  bronze,
  silver,
  gold,
  diamond,
  elite,
  nationalChampion,
  worldChampion,
}

/// Visual styling configuration for each League Tier
class LeagueTierTheme {
  final String title;
  final String badgeText;
  final Color primaryColor;
  final Color darkColor;
  final Color lightColor;
  final Color glowColor;
  final IconData badgeIcon;
  final List<Color> ringGradient;

  const LeagueTierTheme({
    required this.title,
    required this.badgeText,
    required this.primaryColor,
    required this.darkColor,
    required this.lightColor,
    required this.glowColor,
    required this.badgeIcon,
    required this.ringGradient,
  });

  static LeagueTierTheme fromString(String tierStr) {
    final clean = tierStr.toLowerCase().replaceAll(' ', '');
    if (clean.contains('world') || clean.contains('champ')) {
      return worldChampion;
    } else if (clean.contains('national')) {
      return nationalChampion;
    } else if (clean.contains('elite')) {
      return elite;
    } else if (clean.contains('diamond')) {
      return diamond;
    } else if (clean.contains('gold')) {
      return gold;
    } else if (clean.contains('silver')) {
      return silver;
    } else {
      return bronze;
    }
  }

  static final bronze = LeagueTierTheme(
    title: 'Bronze League',
    badgeText: 'BRONZE',
    primaryColor: AppTheme.goldDark,
    darkColor: AppTheme.goldDark,
    lightColor: AppTheme.goldLight,
    glowColor: AppTheme.goldDark.withOpacity(0.4),
    badgeIcon: Icons.shield_outlined,
    ringGradient: [
      AppTheme.goldLight,
      AppTheme.goldDark,
      AppTheme.goldDark,
      AppTheme.goldLight,
    ],
  );

  static final silver = LeagueTierTheme(
    title: 'Silver League',
    badgeText: 'SILVER',
    primaryColor: AppTheme.textSecondary,
    darkColor: AppTheme.textMuted,
    lightColor: AppTheme.textPrimary,
    glowColor: AppTheme.textSecondary.withOpacity(0.4),
    badgeIcon: Icons.shield_outlined,
    ringGradient: [
      AppTheme.textPrimary,
      AppTheme.textSecondary,
      AppTheme.textMuted,
      AppTheme.textPrimary,
    ],
  );

  static final gold = LeagueTierTheme(
    title: 'Gold League',
    badgeText: 'GOLD',
    primaryColor: AppTheme.goldPrimary,
    darkColor: AppTheme.goldDark,
    lightColor: AppTheme.goldLight,
    glowColor: AppTheme.goldPrimary.withOpacity(0.4),
    badgeIcon: Icons.workspace_premium,
    ringGradient: [
      AppTheme.goldLight,
      AppTheme.goldPrimary,
      AppTheme.goldDark,
      AppTheme.goldLight,
    ],
  );

  static final diamond = LeagueTierTheme(
    title: 'Diamond League',
    badgeText: 'DIAMOND',
    primaryColor: AppTheme.info,
    darkColor: AppTheme.info,
    lightColor: AppTheme.info.withOpacity(0.15),
    glowColor: AppTheme.info.withOpacity(0.4),
    badgeIcon: Icons.diamond_outlined,
    ringGradient: [
      AppTheme.info.withOpacity(0.15),
      AppTheme.info,
      AppTheme.info,
      AppTheme.info.withOpacity(0.15),
    ],
  );

  static final elite = LeagueTierTheme(
    title: 'Elite League',
    badgeText: 'ELITE PRO',
    primaryColor: AppTheme.primaryAccent,
    darkColor: AppTheme.primaryAccent,
    lightColor: AppTheme.primaryAccent.withOpacity(0.3),
    glowColor: AppTheme.primaryAccent.withOpacity(0.4),
    badgeIcon: Icons.local_fire_department_rounded,
    ringGradient: [
      AppTheme.primaryAccent.withOpacity(0.3),
      AppTheme.primaryAccent,
      AppTheme.primaryAccent,
      AppTheme.primaryAccent.withOpacity(0.3),
    ],
  );

  static final nationalChampion = LeagueTierTheme(
    title: 'National Champion',
    badgeText: 'NATIONAL CHAMP',
    primaryColor: AppTheme.success,
    darkColor: AppTheme.success,
    lightColor: AppTheme.success.withOpacity(0.2),
    glowColor: AppTheme.success.withOpacity(0.4),
    badgeIcon: Icons.emoji_events_rounded,
    ringGradient: [
      AppTheme.success.withOpacity(0.2),
      AppTheme.success,
      AppTheme.success,
      AppTheme.goldPrimary,
    ],
  );

  static final worldChampion = LeagueTierTheme(
    title: 'World Champion',
    badgeText: 'WORLD CHAMPION',
    primaryColor: AppTheme.secondaryAccent,
    darkColor: AppTheme.goldDark,
    lightColor: AppTheme.goldLight.withOpacity(0.2),
    glowColor: AppTheme.secondaryAccent.withOpacity(0.53),
    badgeIcon: Icons.military_tech_rounded,
    ringGradient: [
      AppTheme.textPrimary,
      AppTheme.goldLight,
      AppTheme.secondaryAccent,
      AppTheme.goldDark,
      AppTheme.textPrimary,
    ],
  );
}

/// CustomPainter for background mesh gradient, moving light streaks, and floating particles
class _HeroBackgroundPainter extends CustomPainter {
  final double animValue;
  final Color auraColor;

  _HeroBackgroundPainter({
    required this.animValue,
    required this.auraColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Moving Mesh Gradient
    final cx = size.width * (0.5 + 0.25 * math.sin(animValue * 2 * math.pi));
    final cy = size.height * (0.4 + 0.2 * math.cos(animValue * 2 * math.pi));

    final meshShader = RadialGradient(
      center: Alignment(
        (cx / size.width) * 2 - 1,
        (cy / size.height) * 2 - 1,
      ),
      radius: 1.1,
      colors: [
        auraColor.withOpacity(0.18),
        AppTheme.surface,
        AppTheme.background,
      ],
      stops: const [0.0, 0.55, 1.0],
    ).createShader(rect);

    canvas.drawRect(rect, Paint()..shader = meshShader);

    // 2. Soft Glow directly behind Center Athlete Profile
    final centerOffset = Offset(size.width / 2, size.height * 0.38);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          auraColor.withOpacity(0.35),
          auraColor.withOpacity(0.10),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: centerOffset, radius: 120));

    canvas.drawCircle(centerOffset, 120, glowPaint);

    // 3. Moving Light Streaks across top header
    final streakPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    for (int i = 0; i < 3; i++) {
      final progress = (animValue + (i * 0.33)) % 1.0;
      final xStart = -size.width * 0.5 + (progress * size.width * 2.0);
      final yStart = size.height * 0.1 + (i * 35.0);

      final path = Path()
        ..moveTo(xStart, yStart)
        ..lineTo(xStart + 160, yStart - 40);

      streakPaint.shader = LinearGradient(
        colors: [
          Colors.transparent,
          auraColor.withOpacity(0.25),
          Colors.white.withOpacity(0.4),
          auraColor.withOpacity(0.25),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(xStart, yStart - 40, 160, 40));

      canvas.drawPath(path, streakPaint);
    }

    // 4. Floating Particles
    final particlePaint = Paint()..style = PaintingStyle.fill;
    final rand = math.Random(42); // deterministic seed for smooth position calculations

    for (int p = 0; p < 18; p++) {
      final basePx = rand.nextDouble();
      final basePy = rand.nextDouble();
      final pSize = 1.0 + rand.nextDouble() * 2.2;
      final speed = 0.05 + rand.nextDouble() * 0.1;

      final px = basePx * size.width;
      final py = ((basePy - (animValue * speed)) % 1.0) * size.height;
      final alpha = (0.2 + 0.4 * math.sin((animValue + basePx) * 2 * math.pi)).clamp(0.05, 0.6);

      particlePaint.color = auraColor.withOpacity(alpha);
      canvas.drawCircle(Offset(px, py), pSize, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HeroBackgroundPainter oldDelegate) {
    return true;
  }
}

/// CustomPainter for Specular Light Reflection Sweep over the Profile Ring
class _RingReflectionPainter extends CustomPainter {
  final double sweepProgress;

  _RingReflectionPainter({required this.sweepProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final sweepX = -size.width + (sweepProgress * size.width * 3.0);

    final reflectionPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.55),
          Colors.white.withOpacity(0.0),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
      ).createShader(Rect.fromLTWH(sweepX, 0, size.width, size.height));

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      reflectionPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingReflectionPainter oldDelegate) {
    return oldDelegate.sweepProgress != sweepProgress;
  }
}

/// Flagship Prestige Hero Section occupying top 30% of screen
class PrestigeHeroSection extends StatefulWidget {
  final String name;
  final String username;
  final bool isVerified;
  final String licenseNumber;
  final String memberSince;
  final String status;
  final String federation;
  final String weightClass;
  final String countryFlag;
  final String country;
  final String province;
  final String club;
  final String displayWeight;
  final String preferredArm;
  final String age;
  final String height;
  final String rankTier;
  final int currentElo;
  final int eloGain;
  final int worldRank;
  final double winRate;
  final String profileImageUrl;
  final String licenseStatus;
  final String armPreference;

  const PrestigeHeroSection({
    Key? key,
    this.name = 'Ahmad Khan',
    this.username = '@ahmad_arm',
    this.isVerified = true,
    this.licenseNumber = 'PK-2026-001248',
    this.memberSince = 'JAN 2024',
    this.status = 'ACTIVE',
    this.federation = 'Pakistan Armwrestling Fed.',
    this.weightClass = '-95kg Heavyweight',
    this.countryFlag = '🇵🇰',
    this.country = 'Pakistan',
    this.province = 'Islamabad',
    this.club = 'Islamabad Club',
    this.displayWeight = '90 kg',
    this.preferredArm = 'Right Arm',
    this.age = '24 Years',
    this.height = '182 cm',
    this.rankTier = 'Elite',
    this.currentElo = 2016,
    this.eloGain = 28,
    this.worldRank = 23,
    this.winRate = 0.792,
    this.profileImageUrl = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=400',
    this.licenseStatus = 'PRO LICENSE #8821',
    this.armPreference = 'Right Hand Peak',
  }) : super(key: key);

  @override
  State<PrestigeHeroSection> createState() => _PrestigeHeroSectionState();
}

class _PrestigeHeroSectionState extends State<PrestigeHeroSection>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _breathingController;
  late AnimationController _reflectionController;

  late LeagueTierTheme _activeTheme;
  int _tierIndex = 4; // Defaults to Elite

  static final List<LeagueTierTheme> _allTiers = [
    LeagueTierTheme.bronze,
    LeagueTierTheme.silver,
    LeagueTierTheme.gold,
    LeagueTierTheme.diamond,
    LeagueTierTheme.elite,
    LeagueTierTheme.nationalChampion,
    LeagueTierTheme.worldChampion,
  ];

  @override
  void initState() {
    super.initState();

    _activeTheme = LeagueTierTheme.fromString(widget.rankTier);

    // 1. Ambient Background Loop
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // 2. Breathing Avatar Ring Pulse (sine wave breathing)
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    // 3. Specular Light Reflection Sweep
    _reflectionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _breathingController.dispose();
    _reflectionController.dispose();
    super.dispose();
  }

  void _cycleNextTier() {
    HapticFeedback.mediumImpact();
    setState(() {
      _tierIndex = (_tierIndex + 1) % _allTiers.length;
      _activeTheme = _allTiers[_tierIndex];
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.surface,
        duration: const Duration(milliseconds: 1400),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _activeTheme.primaryColor, width: 1.2),
        ),
        content: Row(
          children: [
            Icon(_activeTheme.badgeIcon, color: _activeTheme.primaryColor, size: 20),
            const SizedBox(width: 10),
            Text(
              'League Aura: ${_activeTheme.title}',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: _activeTheme.primaryColor.withOpacity(0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: _activeTheme.glowColor,
                blurRadius: 28,
                spreadRadius: -4,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Stack(
                children: [
                  // Animated Background Painter
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _HeroBackgroundPainter(
                        animValue: _backgroundController.value,
                        auraColor: _activeTheme.primaryColor,
                      ),
                    ),
                  ),

                  // Main Content Layout
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                    child: Column(
                      children: [
                        // Center Circular Profile Photo with Animated Glowing Ring & Specular Reflection
                        _buildBreathingProfileAvatar(),

                        const SizedBox(height: 14),

                        // Full Name with Country Flag & Blue Glowing Verification Icon
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              widget.name,
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.countryFlag,
                              style: TextStyle(fontSize: 18),
                            ),
                            if (widget.isVerified) ...[
                              const SizedBox(width: 8),
                              // Glowing Blue Verified Athlete Badge Icon
                              Container(
                                padding: EdgeInsets.all(3.5),
                                decoration: BoxDecoration(
                                  color: AppTheme.info.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.info,
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.info.withOpacity(0.65),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.verified_rounded,
                                  color: AppTheme.info,
                                  size: 15,
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 3),

                        // Username Handle (@ahmad_arm)
                        Text(
                          widget.username.startsWith('@') ? widget.username : '@${widget.username}',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.goldLight,
                            letterSpacing: 0.4,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Federation & Division Subtitle
                        Text(
                          '${widget.federation} • ${widget.weightClass}',
                          style: TextStyle(
                            fontFamily: AppTheme.fontBody,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 10),

                        // License Number, Member Since & Active Status Glass Bar
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // License Number
                              Row(
                                children: [
                                  Icon(Icons.badge_outlined, size: 12, color: AppTheme.textMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.licenseNumber,
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),

                              // Divider
                              Container(
                                height: 11,
                                width: 1,
                                margin: EdgeInsets.symmetric(horizontal: 8),
                                color: Colors.white.withOpacity(0.15),
                              ),

                              // Member Since
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_outlined, size: 10, color: AppTheme.textMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    'MEMBER SINCE ${widget.memberSince}',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textSecondary,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),

                              // Divider
                              Container(
                                height: 11,
                                width: 1,
                                margin: EdgeInsets.symmetric(horizontal: 8),
                                color: Colors.white.withOpacity(0.15),
                              ),

                              // Active Status Badge
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.success.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppTheme.success.withOpacity(0.5), width: 0.8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.success.withOpacity(0.3),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: const BoxDecoration(
                                        color: AppTheme.success,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.status.toUpperCase(),
                                      style: const TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.success,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Elegant Glass Bio Chips Grid
                        AthleteBioChipsSection(
                          countryFlag: widget.countryFlag,
                          country: widget.country,
                          province: widget.province,
                          club: widget.club,
                          weightClass: widget.displayWeight,
                          preferredArm: widget.preferredArm,
                          age: widget.age,
                          height: widget.height,
                        ),

                        const SizedBox(height: 16),

                        // Central ELO & World Rank Stats Bay
                        _buildCentralMetricsBay(),

                        const SizedBox(height: 14),

                        // Footer Badges Bar
                        _buildFooterBadges(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Center circular avatar with breathing animation, glowing ring & light reflection
  Widget _buildBreathingProfileAvatar() {
    return AnimatedBuilder(
      animation: _breathingController,
      builder: (context, child) {
        final breathScale = 1.0 + (math.sin(_breathingController.value * math.pi) * 0.04);
        final glowSpread = 8.0 + (math.sin(_breathingController.value * math.pi) * 8.0);

        return Transform.scale(
          scale: breathScale,
          child: TactilePressWrapper(
            onTap: _cycleNextTier,
            enableLift: false,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer Breathing Glowing Aura Ring
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: _activeTheme.ringGradient,
                      transform: GradientRotation(_backgroundController.value * 2 * math.pi),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _activeTheme.primaryColor.withOpacity(0.6),
                        blurRadius: glowSpread,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),

                // Dark Inner Border Ring
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: AppTheme.background,
                    shape: BoxShape.circle,
                  ),
                ),

                // Avatar Image with Hero Animation
                Hero(
                  tag: 'hero_athlete_profile_avatar',
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: AppTheme.surface,
                    backgroundImage: NetworkImage(widget.profileImageUrl),
                  ),
                ),

                // Specular Light Reflection Sweep Painter
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _reflectionController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _RingReflectionPainter(
                          sweepProgress: _reflectionController.value,
                        ),
                      );
                    },
                  ),
                ),

                // League Badge Tag at Bottom Center with Slowly Rotating Emblem Icon
                Positioned(
                  bottom: -2,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _activeTheme.primaryColor,
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RotationTransition(
                          turns: Tween(begin: 0.0, end: 1.0).animate(_backgroundController),
                          child: Icon(
                            _activeTheme.badgeIcon,
                            size: 11,
                            color: _activeTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _activeTheme.badgeText,
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: _activeTheme.lightColor,
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
      },
    );
  }

  /// Glass Inset Bay for ELO, Delta & World Rank
  Widget _buildCentralMetricsBay() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.background.withOpacity(0.8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _activeTheme.primaryColor.withOpacity(0.2),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Current ELO Column
          Column(
            children: [
              const Text(
                'OFFICIAL ELO',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CountUpText(
                    value: widget.currentElo,
                    duration: const Duration(milliseconds: 350),
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '+${widget.eloGain}',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.success,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Divider
          Container(
            height: 32,
            width: 1,
            color: Colors.white.withOpacity(0.08),
          ),

          // World Rank Column
          Column(
            children: [
              const Text(
                'WORLD RANK',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '#${widget.worldRank}',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: _activeTheme.primaryColor,
                ),
              ),
            ],
          ),

          // Divider
          Container(
            height: 32,
            width: 1,
            color: Colors.white.withOpacity(0.08),
          ),

          // Win Rate Column
          Column(
            children: [
              const Text(
                'WIN RATE',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(widget.winRate * 100).toInt()}%',
                style: const TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Footer Badges
  Widget _buildFooterBadges() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPillTag(Icons.verified, 'WAF CERTIFIED'),
        const SizedBox(width: 8),
        _buildPillTag(Icons.back_hand_outlined, widget.armPreference),
        const SizedBox(width: 8),
        _buildPillTag(Icons.shield_outlined, widget.licenseStatus),
      ],
    );
  }

  Widget _buildPillTag(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
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
          Icon(icon, size: 11, color: AppTheme.goldLight),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppTheme.fontBody,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
