import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/achievements_section.dart';
import '../../../core/widgets/ambient_particle_background.dart';
import '../../../core/widgets/main_shell_screen.dart';
import '../../../core/widgets/performance_graph_card.dart';
import '../../../core/widgets/premium_floating_nav_bar.dart';
import '../../../core/widgets/skeleton_placeholder.dart';
import '../../../core/widgets/stats_overview_section.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
import '../../../core/providers/athlete_provider.dart';
import '../widgets/activity_timeline_section.dart';
import '../widgets/daily_insights_section.dart';
import '../widgets/digital_passport_card.dart';
import '../widgets/floating_glass_header_bar.dart';
import '../widgets/horizontal_achievements_section.dart';
import '../widgets/latest_matches_section.dart';
import '../widgets/personal_records_card.dart';
import '../widgets/premium_elo_featured_card.dart';
import '../widgets/premium_statistics_row.dart';
import '../widgets/prestige_hero_section.dart';
import '../widgets/season_xp_progress_card.dart';
import '../widgets/sticky_profile_bottom_actions.dart';
import '../widgets/telemetry_radar_card.dart';
import '../widgets/trophy_carousel_section.dart';

/// Flagship Digital Identity Profile Screen for ArmSphere Professional Athlete
class AthleteProfileScreen extends ConsumerWidget {
  const AthleteProfileScreen({Key? key}) : super(key: key);

  void _shareProfile(BuildContext context, String name) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E2332),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.4)),
        ),
        content: Row(
          children: [
            const Icon(Icons.share_rounded, color: AppTheme.goldLight, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Digital Passport for $name copied to clipboard.',
                style: const TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onNavTabTap(BuildContext context, int index) {
    HapticFeedback.selectionClick();
    switch (index) {
      case 0:
        context.go('/discover');
        break;
      case 1:
        context.go('/discover');
        break;
      case 2:
        context.push('/informal-events');
        break;
      case 3:
        context.go('/informal-events');
        break;
      case 4:
        // Already on Profile
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(athleteProfileProvider);
    final userMap = ref.watch(authProvider).userProfile ?? {};

    return Scaffold(
      backgroundColor: AppTheme.background,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const StickyProfileBottomActions(),
          PremiumFloatingNavBar(
            currentIndex: 4, // Profile Selected
            onTapTab: (index) => _onNavTabTap(context, index),
            onCenterActionTap: () => context.push('/informal-events'),
          ),
        ],
      ),
      body: AmbientParticleBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async => ref.invalidate(athleteProfileProvider),
            color: AppTheme.goldPrimary,
            backgroundColor: const Color(0xFF121622),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: profileAsync.when(
                data: (profile) => _buildProfileContent(context, profile, userMap),
                loading: () => _buildProfileSkeleton(),
                error: (err, stack) => _buildProfileError(context, ref, err),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    Map<String, dynamic> profile,
    Map<String, dynamic> userMap,
  ) {
    final firstName = profile['firstName'] ?? userMap['firstName'] ?? 'John';
    final lastName = profile['lastName'] ?? userMap['lastName'] ?? 'Diesel';
    final fullName = '$firstName $lastName'.trim();
    final athleteId = profile['id']?.toString() ?? '1';
    final eloRating = int.tryParse(profile['eloRating']?.toString() ?? profile['rating']?.toString() ?? '') ?? 2016;
    final federation = profile['federation']?.toString() ?? 'Pakistan Armwrestling Fed.';
    final weightClass = profile['weightClass']?.toString() ?? '-95kg Heavyweight';
    final avatarUrl = profile['avatarUrl']?.toString() ??
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=400';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Floating Glass Navigation Header Bar
        FloatingGlassHeaderBar(
          profileData: profile,
          onShareTap: () => _shareProfile(context, fullName),
        ),

        const SizedBox(height: 16),

        // 1. Prestige Hero Section (Top 30% Digital Identity Hero)
        PrestigeHeroSection(
          name: fullName,
          username: profile['username']?.toString() ?? '@ahmad_arm',
          isVerified: profile['isVerified'] ?? true,
          licenseNumber: profile['licenseNumber']?.toString() ?? 'PK-2026-001248',
          memberSince: profile['memberSince']?.toString() ?? 'JAN 2024',
          status: 'ACTIVE',
          federation: federation,
          weightClass: weightClass,
          countryFlag: '🇵🇰',
          country: profile['country']?.toString() ?? 'Pakistan',
          province: profile['province']?.toString() ?? 'Islamabad',
          club: profile['club']?.toString() ?? 'Islamabad Club',
          displayWeight: profile['weight']?.toString() ?? '90 kg',
          preferredArm: profile['dominantArm']?.toString() ?? 'Right Arm',
          age: profile['age']?.toString() != null ? '${profile['age']} Years' : '24 Years',
          height: profile['height']?.toString() != null ? '${profile['height']} cm' : '182 cm',
          armPreference: profile['dominantArm']?.toString() ?? 'Right Arm Peak',
          licenseStatus: profile['licenseNumber']?.toString() ?? 'PRO LICENSE #8821',
          rankTier: profile['tier']?.toString() ?? 'Elite',
          currentElo: eloRating,
          eloGain: 28,
          worldRank: 23,
          winRate: 0.792,
          profileImageUrl: avatarUrl,
        ),

        const SizedBox(height: 20),

        // 2. Holographic Digital Passport & Credential Pass
        DigitalPassportCard(profileData: profile),

        const SizedBox(height: 20),

        // 3. Premium Fintech Featured ELO Card
        PremiumEloFeaturedCard(
          currentRating: eloRating,
          previousRating: 1988,
          todaysChange: 12,
          weeklyChange: 28,
          leagueName: 'PRO ELITE LEAGUE • TIER I',
          nextLeagueName: 'GRANDMASTER DIVISION',
          nextLeagueThreshold: 2200,
        ),

        const SizedBox(height: 20),

        // 4. Premium Season XP & League Progress Card
        const SeasonXpProgressCard(
          currentXp: 14850,
          targetXp: 18000,
          currentLeague: 'Master Tier I',
          nextLeague: 'Grandmaster Division',
          estimatedPromotion: '14 Days (3 Matches)',
        ),

        const SizedBox(height: 20),

        // Premium Athlete Statistics Row (Followers, Following, Views, Reputation, Sportsmanship, Verified)
        const PremiumStatisticsRow(),

        const SizedBox(height: 20),

        // 4. Stats Overview Cards (Wins, Losses, Win %, Current ELO, Pakistan Rank, World Rank)
        StatsOverviewSection(profileData: profile),

        const SizedBox(height: 20),

        // 5. Horizontal Scrolling Achievements Carousel
        const HorizontalAchievementsSection(),

        const SizedBox(height: 20),

        // 6. Horizontal Trophy Showcase Carousel (Glass stand & reflection)
        const TrophyCarouselSection(),

        const SizedBox(height: 20),

        // 8. Latest Five Matches Cards
        const LatestMatchesSection(),

        const SizedBox(height: 20),

        // 9. Activity Timeline Logs
        const ActivityTimelineSection(),

        const SizedBox(height: 20),

        // 10. Daily Insights & Readiness
        const DailyInsightsSection(),

        const SizedBox(height: 20),

        // 7. Armwrestling Telemetry & Biometrics Radar
        const TelemetryRadarCard(),

        const SizedBox(height: 20),

        // 5. Performance & ELO Progression Sparkline Graph
        const PerformanceGraphCard(),

        const SizedBox(height: 20),

        // 6. Verified Personal Records (PRs) List
        PersonalRecordsCard(athleteId: athleteId),

        const SizedBox(height: 20),

        // 7. Olympic-Style Medal & Achievements Cabinet
        const AchievementsSection(),

        const SizedBox(height: 20),

        // 8. Referee / Official Credentials Card (if referee role)
        if (userMap['role']?.toString().toUpperCase() == 'REFEREE' || true) ...[
          _buildRefereeBadgeCard(context),
          const SizedBox(height: 20),
        ],

        // Bottom Spacing for Floating Nav Bar
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildRefereeBadgeCard(BuildContext context) {
    return TactilePressWrapper(
      onTap: () => context.push('/referee/certifications'),
      enableLift: true,
      liftDistance: -3,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF121622),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppTheme.secondaryAccent.withOpacity(0.4),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.secondaryAccent.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.secondaryAccent.withOpacity(0.18),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.secondaryAccent, width: 1.0),
              ),
              child: const Icon(Icons.stars_rounded, color: AppTheme.secondaryAccent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'WAF MASTER REFEREE BADGE',
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Level 2 Certified • 34 Matches Officiated',
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 10,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.secondaryAccent, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSkeleton() {
    return Column(
      children: const [
        SizedBox(height: 12),
        SkeletonPlaceholder(width: double.infinity, height: 50, borderRadius: 16),
        SizedBox(height: 16),
        SkeletonPlaceholder(width: double.infinity, height: 260, borderRadius: 24),
        SizedBox(height: 16),
        SkeletonPlaceholder(width: double.infinity, height: 120, borderRadius: 20),
        SizedBox(height: 16),
        SkeletonPlaceholder(width: double.infinity, height: 180, borderRadius: 20),
      ],
    );
  }

  Widget _buildProfileError(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load athlete profile: $error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTheme.fontDisplay,
                color: AppTheme.error,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(athleteProfileProvider),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('RETRY'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldPrimary,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
