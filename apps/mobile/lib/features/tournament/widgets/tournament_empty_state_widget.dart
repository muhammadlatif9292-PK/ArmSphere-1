import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
import 'tournament_empty_state_type.dart';
class TournamentEmptyStateWidget extends StatelessWidget {
  final TournamentEmptyStateType type;
  final VoidCallback? onAction;
  final String? title;
  final String? description;
  final String? customActionLabel;

  const TournamentEmptyStateWidget({
    Key? key,
    required this.type,
    this.onAction,
    this.title,
    this.description,
    this.customActionLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color accentColor;
    String title;
    String description;
    String buttonText;

    switch (type) {
      case TournamentEmptyStateType.noParticipants:
        icon = Icons.people_outline_rounded;
        accentColor = AppTheme.goldPrimary;
        title = 'No Athletes Registered Yet';
        description = 'Be the first armwrestler to claim your spot on the official roster and secure seed #1 for your weight class.';
        buttonText = 'BE THE FIRST TO REGISTER';
        break;
      case TournamentEmptyStateType.registrationClosed:
        icon = Icons.no_accounts_rounded;
        accentColor = const Color(0xFFFF2A6D);
        title = 'Registration Window Closed';
        description = 'Roster capacity has been reached or the official weigh-in deadline has passed. Join the spectator waitlist.';
        buttonText = 'NOTIFY ME ON RE-OPENING';
        break;
      case TournamentEmptyStateType.bracketNotGenerated:
        icon = Icons.account_tree_outlined;
        accentColor = const Color(0xFF00E5FF);
        title = 'Matchup Bracket Being Drawn';
        description = 'Official seeding, double-elimination trees, and table assignments are being finalized by technical delegates.';
        buttonText = 'REFRESH MATCHUP BRACKET';
        break;
      case TournamentEmptyStateType.noDocuments:
        icon = Icons.folder_off_outlined;
        accentColor = const Color(0xFFFF9800);
        title = 'No Documents Uploaded';
        description = 'Official rulebooks, waiver forms, and medical clearance certificates will be published shortly by event marshals.';
        buttonText = 'REQUEST OFFICIAL DOCUMENTS';
        break;
      case TournamentEmptyStateType.noLiveStream:
        icon = Icons.portable_wifi_off_rounded;
        accentColor = const Color(0xFF9C27B0);
        title = 'Broadcast Currently Offline';
        description = 'The ArmSphere TV HD multi-camera stream feed will begin streaming 15 minutes prior to the first referee call.';
        buttonText = 'SET LIVESTREAM REMINDER';
        break;
      case TournamentEmptyStateType.matchesNotScheduled:
        icon = Icons.schedule_rounded;
        accentColor = const Color(0xFF00E676);
        title = 'Match Schedule Not Yet Published';
        description = 'Table assignments and bout order are being finalized by technical delegates and will be published shortly.';
        buttonText = 'REFRESH SCHEDULE';
        break;
    }

    if (this.title != null) title = this.title!;
    if (this.description != null) description = this.description!;
    if (customActionLabel != null) buttonText = customActionLabel!;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Color(0xFF0F172A).withOpacity(0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: accentColor.withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: accentColor.withOpacity(0.08),
            blurRadius: 24,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated Glowing Icon Frame
          Container(
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: accentColor.withOpacity(0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.25),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, size: 36, color: accentColor),
          ),

          const SizedBox(height: 18),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.6,
            ),
          ),

          const SizedBox(height: 8),

          // Description
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.5,
              color: Colors.white70,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 22),

          // Single Action Button
          TactilePressWrapper(
            onTap: () {
              HapticFeedback.mediumImpact();
              if (onAction != null) {
                onAction!();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✓ Action triggered for: $title'),
                    backgroundColor: accentColor,
                  ),
                );
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    accentColor,
                    accentColor.withOpacity(0.85),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    buttonText,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.black),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ============================================================================
// PART 19 — MICROINTERACTIONS (Smooth GPU-Accelerated Tactile & Motion Cards)
// ============================================================================

