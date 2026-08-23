import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';

/// Sticky Floating Bottom Action Bar with Large Glass Gradient Buttons & Ripple Feedback
class StickyProfileBottomActions extends StatelessWidget {
  final VoidCallback? onRegisterTournament;
  final VoidCallback? onShareProfile;
  final VoidCallback? onEditProfile;

  const StickyProfileBottomActions({
    Key? key,
    this.onRegisterTournament,
    this.onShareProfile,
    this.onEditProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: AppTheme.background.withOpacity(0.85),
        border: Border(
          top: BorderSide(
            color: AppTheme.goldPrimary.withOpacity(0.25),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
          BoxShadow(
            color: AppTheme.goldPrimary.withOpacity(0.08),
            blurRadius: 25,
            spreadRadius: -2,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                // 1. Primary Action: Register Tournament
                Expanded(
                  flex: 4,
                  child: _buildGradientGlassButton(
                    context: context,
                    label: 'REGISTER TOURNAMENT',
                    icon: Icons.emoji_events_rounded,
                    gradient: const LinearGradient(
                      colors: [
                        AppTheme.secondaryAccent,
                        AppTheme.goldDark,
                        AppTheme.goldDark,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    glowColor: AppTheme.goldPrimary,
                    textColor: Colors.black,
                    iconColor: Colors.black,
                    isPrimary: true,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      if (onRegisterTournament != null) {
                        onRegisterTournament!();
                      } else {
                        _showRegisterDialog(context);
                      }
                    },
                  ),
                ),

                const SizedBox(width: 8),

                // 2. Secondary Action: Share Profile
                Expanded(
                  flex: 3,
                  child: _buildGradientGlassButton(
                    context: context,
                    label: 'SHARE PROFILE',
                    icon: Icons.share_rounded,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.info.withOpacity(0.25),
                        AppTheme.info.withOpacity(0.35),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderColor: AppTheme.info.withOpacity(0.5),
                    glowColor: AppTheme.info,
                    textColor: AppTheme.info,
                    iconColor: AppTheme.info,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (onShareProfile != null) {
                        onShareProfile!();
                      } else {
                        _showShareToast(context);
                      }
                    },
                  ),
                ),

                const SizedBox(width: 8),

                // 3. Third Action: Edit Profile
                Expanded(
                  flex: 3,
                  child: _buildGradientGlassButton(
                    context: context,
                    label: 'EDIT PROFILE',
                    icon: Icons.edit_note_rounded,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.highlightPurple.withOpacity(0.25),
                        AppTheme.highlightPurple.withOpacity(0.35),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderColor: AppTheme.highlightPurple.withOpacity(0.5),
                    glowColor: AppTheme.highlightPurple,
                    textColor: AppTheme.highlightPurple.withOpacity(0.2),
                    iconColor: AppTheme.highlightPurple,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (onEditProfile != null) {
                        onEditProfile!();
                      } else {
                        _showEditPrompt(context);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientGlassButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Gradient gradient,
    required Color glowColor,
    required Color textColor,
    required Color iconColor,
    Color? borderColor,
    bool isPrimary = false,
    required VoidCallback onTap,
  }) {
    return TactilePressWrapper(
      onTap: onTap,
      enableLift: true,
      liftDistance: -3,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: glowColor.withOpacity(isPrimary ? 0.35 : 0.18),
              blurRadius: isPrimary ? 16 : 10,
              spreadRadius: isPrimary ? 1 : 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            splashColor: (isPrimary ? Colors.white : glowColor).withOpacity(0.3),
            highlightColor: (isPrimary ? Colors.white : glowColor).withOpacity(0.15),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: borderColor ?? glowColor.withOpacity(0.6),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: iconColor,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: isPrimary ? 10.5 : 9.5,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        letterSpacing: 0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showRegisterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.glassSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'AVAILABLE TOURNAMENTS',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTournamentOption(
              title: 'Islamabad Grand Supermatch 2026',
              division: '-95kg Right Arm Heavyweight',
              date: 'AUG 10, 2026',
              fee: 'PKR 2,500',
              ctx: ctx,
            ),
            const SizedBox(height: 10),
            _buildTournamentOption(
              title: 'Rawalpindi Open Armwrestling Championship',
              division: 'Open Weight Class Left Arm',
              date: 'SEP 04, 2026',
              fee: 'PKR 3,000',
              ctx: ctx,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentOption({
    required String title,
    required String division,
    required String date,
    required String fee,
    required BuildContext ctx,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$division • $date',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 10,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  backgroundColor: AppTheme.success,
                  content: Text('Registered for $title successfully!'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.goldPrimary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'REGISTER',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showShareToast(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppTheme.info.withOpacity(0.5)),
        ),
        content: const Row(
          children: [
            Icon(Icons.share_rounded, color: AppTheme.info, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Digital Passport link & QR Code copied to clipboard.',
                style: TextStyle(
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

  void _showEditPrompt(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.glassSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppTheme.highlightPurple.withOpacity(0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'EDIT ATHLETE PROFILE',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.badge_rounded, color: AppTheme.highlightPurple),
              title: const Text('Update Bio & Federation Credentials', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile edit mode enabled.')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.fitness_center_rounded, color: AppTheme.info),
              title: const Text('Update Weight Class & Dominant Arm', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Weight class options updated.')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded, color: AppTheme.goldPrimary),
              title: const Text('Change Passport Avatar Photo', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avatar editor opened.')));
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
