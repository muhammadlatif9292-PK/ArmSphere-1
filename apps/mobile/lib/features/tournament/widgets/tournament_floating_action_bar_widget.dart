import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
class TournamentFloatingActionBarWidget extends StatelessWidget {
  final Map<String, dynamic> tournament;

  const TournamentFloatingActionBarWidget({
    Key? key,
    required this.tournament,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final status = (tournament['status'] ?? 'UPCOMING').toString().toUpperCase();
    final bool isRegistered = tournament['isRegistered'] == true || tournament['userRegistered'] == true;

    // Primary action selection logic (ONE primary action at all times)
    String buttonText = 'REGISTER FOR TOURNAMENT';
    IconData buttonIcon = Icons.how_to_reg_rounded;
    Color gradientStart = AppTheme.goldPrimary;
    Color gradientEnd = const Color(0xFFFFC107);
    Color textColor = Colors.black;

    if (status == 'COMPLETED' || status == 'FINISHED') {
      buttonText = 'VIEW CHAMPIONSHIP RESULTS';
      buttonIcon = Icons.emoji_events_rounded;
      gradientStart = AppTheme.goldPrimary;
      gradientEnd = const Color(0xFFFFC107);
      textColor = Colors.black;
    } else if (status == 'LIVE') {
      buttonText = 'WATCH LIVE BROADCAST';
      buttonIcon = Icons.live_tv_rounded;
      gradientStart = const Color(0xFFFF2A6D);
      gradientEnd = const Color(0xFFFF5252);
      textColor = Colors.white;
    } else if (status == 'IN_PROGRESS' || status == 'ONGOING') {
      buttonText = 'VIEW LIVE BRACKET';
      buttonIcon = Icons.account_tree_rounded;
      gradientStart = const Color(0xFF00E5FF);
      gradientEnd = const Color(0xFF00B0FF);
      textColor = Colors.black;
    } else if (isRegistered) {
      buttonText = 'MY REGISTRATION & PASS';
      buttonIcon = Icons.verified_user_rounded;
      gradientStart = const Color(0xFF00E676);
      gradientEnd = const Color(0xFF00C853);
      textColor = Colors.black;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Color(0xFF0F172A).withOpacity(0.92),
        border: Border(
          top: BorderSide(
            color: AppTheme.goldPrimary.withOpacity(0.3),
            width: 1.2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.8),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: TactilePressWrapper(
          onTap: () {
            HapticFeedback.heavyImpact();
            if (status == 'COMPLETED' || status == 'FINISHED') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✓ Opening Official Championship Results Modal...'), backgroundColor: AppTheme.goldPrimary),
              );
            } else if (status == 'LIVE') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✓ Tuning into PAFF ArmSphere TV HD Stream...'), backgroundColor: Color(0xFFFF2A6D)),
              );
            } else if (status == 'IN_PROGRESS' || status == 'ONGOING') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✓ Launching Interactive Bracket Tree...'), backgroundColor: Color(0xFF00E5FF)),
              );
            } else if (isRegistered) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✓ Opening Digital Weigh-In Pass & QR Code...'), backgroundColor: Color(0xFF00E676)),
              );
            } else {
              context.push('/events/${tournament['id']}/register', extra: tournament);
            }
          },
          child: Container(
            height: 52,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [gradientStart, gradientEnd],
              ),
              boxShadow: [
                BoxShadow(
                  color: gradientStart.withOpacity(0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(buttonIcon, size: 20, color: textColor),
                const SizedBox(width: 10),
                Text(
                  buttonText,
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// ============================================================================
// PART 17 — LOADING (Premium Glass Skeleton UI with Animated Shimmer)
// ============================================================================

