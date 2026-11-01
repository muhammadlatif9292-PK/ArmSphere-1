import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'crystal_glass_nav_controls.dart';

/// Standardized Empty State Component
///
/// Upgraded to ArmSphere Crystal Glassmorphism Design System:
/// - Frosted Crystal Glass emblem halo with optical blur and gold specular rim.
/// - Space Grotesk display typography and high-legibility subtitle prose.
/// - Frosted [CrystalActionButton] CTAs with gold and titanium specular rims.
class AppEmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? description;
  final String? ctaLabel;
  final VoidCallback? onCtaTap;
  final String? secondaryCtaLabel;
  final VoidCallback? onSecondaryCtaTap;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    String? subtitle,
    String? description,
    this.ctaLabel,
    this.onCtaTap,
    this.secondaryCtaLabel,
    this.onSecondaryCtaTap,
  })  : subtitle = subtitle ?? description ?? '',
        description = description ?? subtitle;

  const AppEmptyState.noCompetitions({
    super.key,
    this.title = 'No Competitions Found',
    this.subtitle =
        'There are no sanctioned tournaments matching your current criteria.',
    this.description =
        'There are no sanctioned tournaments matching your current criteria.',
    this.ctaLabel = 'Refresh Events',
    this.onCtaTap,
    this.secondaryCtaLabel,
    this.onSecondaryCtaTap,
  }) : icon = Icons.emoji_events_outlined;

  const AppEmptyState.noMatches({
    super.key,
    this.title = 'No Matches Recorded',
    this.subtitle =
        'Compete in sanctioned tournaments or record table bouts to establish your rating.',
    this.description =
        'Compete in sanctioned tournaments or record table bouts to establish your rating.',
    this.ctaLabel,
    this.onCtaTap,
    this.secondaryCtaLabel,
    this.onSecondaryCtaTap,
  }) : icon = Icons.sports_kabaddi;

  const AppEmptyState.noSearchResults({
    super.key,
    this.title = 'No Results Found',
    this.subtitle =
        'Try refining your search terms or clearing active filters.',
    this.description =
        'Try refining your search terms or clearing active filters.',
    this.ctaLabel = 'Clear Search',
    this.onCtaTap,
    this.secondaryCtaLabel,
    this.onSecondaryCtaTap,
  }) : icon = Icons.search_off_rounded;

  const AppEmptyState.offline({
    super.key,
    this.title = 'Offline Mode Active',
    this.subtitle =
        'Cached data is accessible. Actions will sync automatically when connection restores.',
    this.description =
        'Cached data is accessible. Actions will sync automatically when connection restores.',
    this.ctaLabel = 'Retry Connection',
    this.onCtaTap,
    this.secondaryCtaLabel,
    this.onSecondaryCtaTap,
  }) : icon = Icons.wifi_off_rounded;

  const AppEmptyState.noNotifications({
    super.key,
    this.title = 'All Caught Up',
    this.subtitle =
        'You have no new alerts, match calls, or federation announcements.',
    this.description =
        'You have no new alerts, match calls, or federation announcements.',
    this.ctaLabel,
    this.onCtaTap,
    this.secondaryCtaLabel,
    this.onSecondaryCtaTap,
  }) : icon = Icons.notifications_none_outlined;

  @override
  State<AppEmptyState> createState() => _AppEmptyStateState();
}

class _AppEmptyStateState extends State<AppEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    _slideAnimation = Tween<double>(begin: 10.0, end: 0.0).animate(curve);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Frosted Crystal Glass Emblem Capsule
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.48),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: AppTheme.goldPrimary.withValues(alpha: 0.18),
                      blurRadius: 16,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xBF0B101C),
                        border: Border.all(
                          color: AppTheme.goldPrimary.withValues(alpha: 0.48),
                          width: 1.2,
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: const [0.0, 0.5, 1.0],
                          colors: [
                            AppTheme.goldPrimary.withValues(alpha: 0.22),
                            const Color(0x16FFFFFF),
                            const Color(0x06FFFFFF),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          widget.icon,
                          size: 30,
                          color: AppTheme.goldPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textPure,
                  fontWeight: FontWeight.w700,
                  fontSize: 16.5,
                  fontFamily: AppTheme.fontDisplay,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ),
              if ((widget.ctaLabel != null && widget.onCtaTap != null) ||
                  (widget.secondaryCtaLabel != null &&
                      widget.onSecondaryCtaTap != null)) ...[
                const SizedBox(height: 22),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    if (widget.ctaLabel != null && widget.onCtaTap != null)
                      CrystalActionButton(
                        label: widget.ctaLabel!,
                        onTap: widget.onCtaTap,
                        accentColor: AppTheme.goldPrimary,
                        isPrimary: true,
                      ),
                    if (widget.secondaryCtaLabel != null &&
                        widget.onSecondaryCtaTap != null)
                      CrystalActionButton(
                        label: widget.secondaryCtaLabel!,
                        onTap: widget.onSecondaryCtaTap,
                        isPrimary: false,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
