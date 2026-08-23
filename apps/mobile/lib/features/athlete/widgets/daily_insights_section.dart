import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';

/// Data model for Daily Performance Insights & Conditions
class DailyInsightsData {
  final int? trainingStreakDays;
  final String? motivationalQuote;
  final String? quoteAuthor;
  final String? coachMessage;
  final String? coachName;
  final DateTime? tournamentTargetDate;
  final String? tournamentName;
  final String? weatherGreeting;
  final String? weatherTemp;
  final int? caloriesCurrent;
  final int? caloriesTarget;
  final double? hydrationCurrentLiters;
  final double? hydrationTargetLiters;
  final String? dailyChallengeTitle;
  final String? dailyChallengeReward;
  final bool isChallengeCompleted;

  const DailyInsightsData({
    this.trainingStreakDays = 18,
    this.motivationalQuote = 'To defeat the armwrestling table, first conquer the tension in your mind.',
    this.quoteAuthor = 'John Brzenk',
    this.coachMessage = 'Great work on yesterday\'s backpressure holds. Focus on heavy pronation riser density today before evening table sparring.',
    this.coachName = 'Coach Rustam',
    this.tournamentTargetDate, // We will initialize in widget if needed
    this.tournamentName = 'Islamabad Grand Supermatch',
    this.weatherGreeting = 'Islamabad • Clear Skies, Great for Grip Training',
    this.weatherTemp = '29°C',
    this.caloriesCurrent = 2850,
    this.caloriesTarget = 3200,
    this.hydrationCurrentLiters = 3.2,
    this.hydrationTargetLiters = 4.0,
    this.dailyChallengeTitle = '3x20 High-Riser Wrist Curls @ 35kg',
    this.dailyChallengeReward = '+150 XP',
    this.isChallengeCompleted = false,
  });
}

class DailyInsightsSection extends StatefulWidget {
  final DailyInsightsData? data;

  const DailyInsightsSection({
    Key? key,
    this.data = const DailyInsightsData(),
  }) : super(key: key);

  @override
  State<DailyInsightsSection> createState() => _DailyInsightsSectionState();
}

class _DailyInsightsSectionState extends State<DailyInsightsSection> {
  late DateTime _targetDate;
  late Timer _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _targetDate = widget.data?.tournamentTargetDate ??
        DateTime.now().add(const Duration(days: 14, hours: 6, minutes: 22));
    _updateCountdown();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown();
    });
  }

  void _updateCountdown() {
    final now = DateTime.now();
    if (_targetDate.isAfter(now)) {
      setState(() {
        _timeLeft = _targetDate.difference(now);
      });
    } else {
      setState(() {
        _timeLeft = Duration.zero;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;

    if (d == null) return const SizedBox.shrink();

    // Check if any metric exists
    final hasStreak = d.trainingStreakDays != null && d.trainingStreakDays! > 0;
    final hasQuote = d.motivationalQuote != null && d.motivationalQuote!.isNotEmpty;
    final hasCoach = d.coachMessage != null && d.coachMessage!.isNotEmpty;
    final hasTournament = d.tournamentName != null && d.tournamentName!.isNotEmpty;
    final hasWeather = d.weatherGreeting != null && d.weatherGreeting!.isNotEmpty;
    final hasCalories = d.caloriesCurrent != null && d.caloriesTarget != null;
    final hasHydration = d.hydrationCurrentLiters != null && d.hydrationTargetLiters != null;
    final hasChallenge = d.dailyChallengeTitle != null && d.dailyChallengeTitle!.isNotEmpty;

    // If no data exists at all, collapse elegantly
    if (!hasStreak &&
        !hasQuote &&
        !hasCoach &&
        !hasTournament &&
        !hasWeather &&
        !hasCalories &&
        !hasHydration &&
        !hasChallenge) {
      return const SizedBox.shrink();
    }

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
                    'DAILY INSIGHTS & READINESS',
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
              if (hasStreak)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.warning.withOpacity(0.5),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.local_fire_department_rounded,
                          size: 13, color: AppTheme.warning),
                      const SizedBox(width: 4),
                      Text(
                        '${d.trainingStreakDays} DAY STREAK',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.warning,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Stacked Glass Insight Cards
        Column(
          children: [
            // 1. Weather Greeting
            if (hasWeather) ...[
              _buildGlassTile(
                icon: Icons.wb_sunny_rounded,
                iconColor: AppTheme.goldLight,
                title: 'WEATHER & ATHLETE ENVIRONMENT',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        d.weatherGreeting!,
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (d.weatherTemp != null)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.goldLight.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          d.weatherTemp!,
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.goldLight,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // 2. Upcoming Tournament Countdown
            if (hasTournament) ...[
              _buildGlassTile(
                icon: Icons.timer_outlined,
                iconColor: AppTheme.info,
                title: 'UPCOMING TOURNAMENT COUNTDOWN',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.tournamentName!,
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildCountBlock(_timeLeft.inDays.toString().padLeft(2, '0'), 'DAYS'),
                        _buildCountBlock((_timeLeft.inHours % 24).toString().padLeft(2, '0'), 'HOURS'),
                        _buildCountBlock((_timeLeft.inMinutes % 60).toString().padLeft(2, '0'), 'MINS'),
                        _buildCountBlock((_timeLeft.inSeconds % 60).toString().padLeft(2, '0'), 'SECS'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // 3. Motivational Quote
            if (hasQuote) ...[
              _buildGlassTile(
                icon: Icons.format_quote_rounded,
                iconColor: AppTheme.goldLight,
                title: 'DAILY MOTIVATIONAL MENTORSHIP',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '"${d.motivationalQuote!}"',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    if (d.quoteAuthor != null) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '— ${d.quoteAuthor!}',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.goldLight,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // 4. Coach Message
            if (hasCoach) ...[
              _buildGlassTile(
                icon: Icons.record_voice_over_rounded,
                iconColor: AppTheme.highlightPurple,
                title: 'COACH DIRECTIVE (${d.coachName ?? "HEAD COACH"})',
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.highlightPurple.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.sports_rounded,
                        color: AppTheme.highlightPurple,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        d.coachMessage!,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // 5. Macro Metrics Row: Calories & Hydration
            if (hasCalories || hasHydration) ...[
              Row(
                children: [
                  if (hasCalories)
                    Expanded(
                      child: _buildMacroPill(
                        icon: Icons.local_fire_department_outlined,
                        color: AppTheme.warning,
                        label: 'TODAY\'S CALORIES',
                        value: '${d.caloriesCurrent} / ${d.caloriesTarget} kcal',
                        progress: (d.caloriesCurrent! / d.caloriesTarget!).clamp(0.0, 1.0),
                      ),
                    ),
                  if (hasCalories && hasHydration) const SizedBox(width: 10),
                  if (hasHydration)
                    Expanded(
                      child: _buildMacroPill(
                        icon: Icons.water_drop_outlined,
                        color: AppTheme.info,
                        label: 'HYDRATION INTAKE',
                        value: '${d.hydrationCurrentLiters}L / ${d.hydrationTargetLiters}L',
                        progress: (d.hydrationCurrentLiters! / d.hydrationTargetLiters!).clamp(0.0, 1.0),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
            ],

            // 6. Daily Challenge
            if (hasChallenge) ...[
              _buildGlassTile(
                icon: Icons.task_alt_rounded,
                iconColor: AppTheme.success,
                title: 'DAILY ATHLETE CHALLENGE',
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.dailyChallengeTitle!,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          if (d.dailyChallengeReward != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Reward: ${d.dailyChallengeReward!}',
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.success,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Daily challenge completed! +150 XP claimed.'),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success.withOpacity(0.2),
                        foregroundColor: AppTheme.success,
                        side: const BorderSide(color: AppTheme.success, width: 0.9),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'CLAIM XP',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildGlassTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return TactilePressWrapper(
      onTap: () {
        HapticFeedback.selectionClick();
      },
      enableLift: true,
      liftDistance: -2,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: iconColor.withOpacity(0.12),
              blurRadius: 14,
              spreadRadius: -2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.glassSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: iconColor.withOpacity(0.35),
                  width: 1.0,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    iconColor.withOpacity(0.12),
                    AppTheme.surface,
                    AppTheme.background,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 14, color: iconColor),
                      const SizedBox(width: 6),
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: iconColor,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountBlock(String val, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Text(
            val,
            style: const TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 7.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroPill({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required double progress,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.glassSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.35),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.surface,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
