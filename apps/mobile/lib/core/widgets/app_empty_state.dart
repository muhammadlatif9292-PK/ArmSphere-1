import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'tactile_press_wrapper.dart';

/// Standardized Empty State Component
///
/// Upgraded to Canonical Stage 2 Specification (Slice 9 / [P1-04]):
/// - High-contrast combat sports iconography and Space Grotesk typography.
/// - Presets for Competitions, Matches, Search, Offline, and Notifications.
/// - Standardized 8dp buttons with tactile feedback.
class AppEmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? ctaLabel;
  final VoidCallback? onCtaTap;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.ctaLabel,
    this.onCtaTap,
  });

  const AppEmptyState.noCompetitions({
    super.key,
    this.title = 'No Competitions Found',
    this.subtitle = 'There are no sanctioned tournaments matching your current criteria.',
    this.ctaLabel = 'Refresh Events',
    this.onCtaTap,
  }) : icon = Icons.emoji_events_outlined;

  const AppEmptyState.noMatches({
    super.key,
    this.title = 'No Matches Recorded',
    this.subtitle = 'Compete in sanctioned tournaments or record table bouts to establish your rating.',
    this.ctaLabel,
    this.onCtaTap,
  }) : icon = Icons.sports_kabaddi;

  const AppEmptyState.noSearchResults({
    super.key,
    this.title = 'No Results Found',
    this.subtitle = 'Try refining your search terms or clearing active filters.',
    this.ctaLabel = 'Clear Search',
    this.onCtaTap,
  }) : icon = Icons.search_off_rounded;

  const AppEmptyState.offline({
    super.key,
    this.title = 'Offline Mode Active',
    this.subtitle = 'Cached data is accessible. Actions will sync automatically when connection restores.',
    this.ctaLabel = 'Retry Connection',
    this.onCtaTap,
  }) : icon = Icons.wifi_off_rounded;

  const AppEmptyState.noNotifications({
    super.key,
    this.title = 'All Caught Up',
    this.subtitle = 'You have no new alerts, match calls, or federation announcements.',
    this.ctaLabel,
    this.onCtaTap,
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
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.cardSurface,
                  border: Border.all(color: AppTheme.borderSubtle, width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    widget.icon,
                    size: 30,
                    color: AppTheme.goldPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  fontFamily: 'Space Grotesk',
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
              if (widget.ctaLabel != null && widget.onCtaTap != null) ...[
                const SizedBox(height: 20),
                TactilePressWrapper(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onCtaTap!();
                  },
                  semanticLabel: widget.ctaLabel,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.elevatedSurface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      border: Border.all(color: AppTheme.goldPrimary.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.ctaLabel!,
                          style: const TextStyle(
                            fontFamily: 'Space Grotesk',
                            color: AppTheme.goldPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
