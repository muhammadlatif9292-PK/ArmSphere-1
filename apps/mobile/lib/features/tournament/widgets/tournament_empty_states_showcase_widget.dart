import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
import 'empty_state_type.dart';
class TournamentEmptyStatesShowcaseWidget extends StatefulWidget {
  final Map<String, dynamic> tournament;

  const TournamentEmptyStatesShowcaseWidget({
    Key? key,
    required this.tournament,
  }) : super(key: key);

  @override
  State<TournamentEmptyStatesShowcaseWidget> createState() =>
      _TournamentEmptyStatesShowcaseWidgetState();
}

class _TournamentEmptyStatesShowcaseWidgetState
    extends State<TournamentEmptyStatesShowcaseWidget>
    with SingleTickerProviderStateMixin {
  EmptyStateType _selectedType = EmptyStateType.bracketNotReleased;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  final Map<EmptyStateType, Map<String, dynamic>> _emptyStateConfigs = {
    EmptyStateType.bracketNotReleased: {
      'tabLabel': 'Brackets',
      'title': 'Bracket Not Released',
      'subtitle':
          'Official seedings and bracket trees will be drawn live after official weigh-in closure.',
      'actionText': 'NOTIFY WHEN RELEASED',
      'primaryColor': AppTheme.goldPrimary,
      'secondaryColor': const Color(0xFFFFB703),
      'icon': Icons.account_tree_rounded,
      'badge': 'SEEDED DRAW',
      'toastMessage': '🔔 You will receive a push alert when brackets go live!',
    },
    EmptyStateType.schedulePending: {
      'tabLabel': 'Schedule',
      'title': 'Schedule Pending',
      'subtitle':
          'Match timetables and arena table assignments are being calibrated by head referees.',
      'actionText': 'VIEW EVENT TIMELINE',
      'primaryColor': const Color(0xFF00E5FF),
      'secondaryColor': const Color(0xFF00B0FF),
      'icon': Icons.more_time_rounded,
      'badge': 'CALIBRATING',
      'toastMessage': '📅 Opening preliminary milestone timeline...',
    },
    EmptyStateType.registrationClosed: {
      'tabLabel': 'Registration',
      'title': 'Registration Closed',
      'subtitle':
          'Roster capacity for this tournament has reached its official PAFF athlete cap.',
      'actionText': 'JOIN WAITING LIST',
      'primaryColor': const Color(0xFFFF2A6D),
      'secondaryColor': const Color(0xFFFF5252),
      'icon': Icons.no_accounts_rounded,
      'badge': 'CAP REACHED',
      'toastMessage': '📋 Added to priority athlete waiting list!',
    },
    EmptyStateType.noDocuments: {
      'tabLabel': 'Documents',
      'title': 'No Documents Uploaded',
      'subtitle':
          'Official rulebooks, liability waivers, and venue maps will be published here.',
      'actionText': 'REQUEST DOCUMENTATION',
      'primaryColor': const Color(0xFF00E5FF),
      'secondaryColor': const Color(0xFF00B0FF),
      'icon': Icons.folder_off_rounded,
      'badge': 'PENDING FILE',
      'toastMessage': '📩 Request sent to event organizer administration.',
    },
    EmptyStateType.medicalPending: {
      'tabLabel': 'Medical',
      'title': 'Medical Verification Pending',
      'subtitle':
          'Your physical fitness clearance form is currently under medical board verification.',
      'actionText': 'CHECK STATUS DETAILS',
      'primaryColor': const Color(0xFF00E676),
      'secondaryColor': const Color(0xFF69F0AE),
      'icon': Icons.health_and_safety_rounded,
      'badge': 'IN REVIEW',
      'toastMessage': '⚕️ Fetching live PAFF medical clearance status...',
    },
  };

  @override
  Widget build(BuildContext context) {
    final currentConfig = _emptyStateConfigs[_selectedType]!;
    final Color primaryColor = currentConfig['primaryColor'] as Color;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xFF0D1527).withOpacity(0.95),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.goldPrimary.withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldPrimary.withOpacity(0.1),
            blurRadius: 18,
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppTheme.goldPrimary.withOpacity(0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.goldPrimary.withOpacity(0.5),
                          ),
                        ),
                        child: const Icon(
                          Icons.inbox_rounded,
                          color: AppTheme.goldPrimary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'EMPTY STATE ILLUSTRATIONS',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Custom Glass Illustrations & Contextual Actions',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 10.5,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Text(
                      '5 STATES',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.goldPrimary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Interactive Selector Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: EmptyStateType.values.map((type) {
                    final isSelected = type == _selectedType;
                    final config = _emptyStateConfigs[type]!;
                    final Color tabColor = config['primaryColor'] as Color;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: TactilePressWrapper(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedType = type;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? tabColor.withOpacity(0.22)
                                : Color(0xFF141E2F).withOpacity(0.8),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? tabColor
                                  : Colors.white.withOpacity(0.12),
                              width: isSelected ? 1.4 : 1.0,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: tabColor.withOpacity(0.3),
                                  blurRadius: 10,
                                  spreadRadius: -1,
                                ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                config['icon'] as IconData,
                                size: 13,
                                color: isSelected ? tabColor : AppTheme.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                config['tabLabel'] as String,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w900
                                      : FontWeight.w700,
                                  color:
                                      isSelected ? Colors.white : AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              // Empty State Illustration Container Card
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Container(
                  key: ValueKey(_selectedType),
                  width: double.infinity,
                  padding: EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Color(0xFF141E2F).withOpacity(0.85),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.4),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.15),
                        blurRadius: 16,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Vector Glass Illustration Ring
                      _buildIllustrationVector(
                        icon: currentConfig['icon'] as IconData,
                        primaryColor: primaryColor,
                        secondaryColor:
                            currentConfig['secondaryColor'] as Color,
                        badgeText: currentConfig['badge'] as String,
                      ),

                      const SizedBox(height: 20),

                      // Title
                      Text(
                        currentConfig['title'] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        currentConfig['subtitle'] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 11.5,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Contextual Action Button
                      TactilePressWrapper(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                currentConfig['toastMessage'] as String,
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                              ),
                              backgroundColor: primaryColor,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                currentConfig['icon'] as IconData,
                                size: 16,
                                color: Colors.black,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                currentConfig['actionText'] as String,
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIllustrationVector({
    required IconData icon,
    required Color primaryColor,
    required Color secondaryColor,
    required String badgeText,
  }) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseValue = 0.85 + (_pulseController.value * 0.15);

        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer Glowing Radial Sphere
            Container(
              width: 110 * pulseValue,
              height: 110 * pulseValue,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primaryColor.withOpacity(0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // Middle Dashed Geometric Shield Box
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: Color(0xFF0F172A).withOpacity(0.8),
                shape: BoxShape.circle,
                border: Border.all(
                  color: primaryColor.withOpacity(0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.25),
                    blurRadius: 14,
                  ),
                ],
              ),
            ),

            // Inner Accent Glass Disk
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withOpacity(0.3),
                    secondaryColor.withOpacity(0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white24,
                  width: 1.0,
                ),
              ),
              child: Icon(
                icon,
                size: 30,
                color: primaryColor,
              ),
            ),

            // Top Status Badge Tag
            Positioned(
              bottom: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// PART 5 — LIVE ELIGIBILITY ENGINE (PREMIUM GLASS AUTOMATIC EVALUATOR)
// ============================================================================

