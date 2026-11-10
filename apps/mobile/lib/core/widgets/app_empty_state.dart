import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/asset_paths.dart';
import '../theme/app_theme.dart';
import 'armsphere_image.dart';
import 'tactile_press_wrapper.dart';

/// Artwork-Backed Standby & Empty State Card ("Let the Art Speak")
///
/// Eliminates Pathology 3 (The "Generic Icon" Empty State Syndrome) by replacing
/// hollow circular outline icons with high-impact 16:9 standby visual cards
/// utilizing the 28 canonical artworks (`m1_card_standby_table.webp`,
/// `tournament_poster.webp`, `clip_fallback_sparring.webp`, `clip_fallback_match.webp`).
class AppEmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? description;
  final String? ctaLabel;
  final VoidCallback? onCtaTap;
  final String? secondaryCtaLabel;
  final VoidCallback? onSecondaryCtaTap;
  final String? bannerAsset;
  final Alignment bannerAlignment;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.description,
    this.ctaLabel,
    this.onCtaTap,
    this.secondaryCtaLabel,
    this.onSecondaryCtaTap,
    this.bannerAsset,
    this.bannerAlignment = Alignment.center,
  });

  const AppEmptyState.noCompetitions({
    super.key,
    this.title = 'Arena Standing By',
    this.subtitle = 'Sanctioned tournament brackets and event schedules are being locked.',
    this.description,
    this.ctaLabel = 'Refresh Events',
    this.onCtaTap,
    this.secondaryCtaLabel,
    this.onSecondaryCtaTap,
    this.bannerAsset = ArmSphereAssets.cardStandbyTable,
    this.bannerAlignment = Alignment.center,
  }) : icon = Icons.emoji_events_outlined;

  const AppEmptyState.noMatches({
    super.key,
    this.title = 'Arena Table Standing By',
    this.subtitle = 'Step to the pad in sanctioned bouts or pickup sparring to establish your ELO.',
    this.description,
    this.ctaLabel,
    this.onCtaTap,
    this.secondaryCtaLabel,
    this.onSecondaryCtaTap,
    this.bannerAsset = ArmSphereAssets.cardStandbyTable,
    this.bannerAlignment = Alignment.center,
  }) : icon = Icons.sports_kabaddi;

  const AppEmptyState.noSearchResults({
    super.key,
    this.title = 'No Matches on Radar',
    this.subtitle = 'Adjust your filter criteria or search by athlete, club, or division.',
    this.description,
    this.ctaLabel = 'Clear Search',
    this.onCtaTap,
    this.secondaryCtaLabel,
    this.onSecondaryCtaTap,
    this.bannerAsset = ArmSphereAssets.cardArenaRadar,
    this.bannerAlignment = ArmSphereAssets.stageTopFocal,
  }) : icon = Icons.search_off_rounded;

  const AppEmptyState.offline({
    super.key,
    this.title = 'Offline Vault Active',
    this.subtitle = 'Local ledger is accessible. Bouts and logs sync automatically on reconnect.',
    this.description,
    this.ctaLabel = 'Retry Sync',
    this.onCtaTap,
    this.secondaryCtaLabel,
    this.onSecondaryCtaTap,
    this.bannerAsset = ArmSphereAssets.cardStandbyTable,
    this.bannerAlignment = Alignment.center,
  }) : icon = Icons.wifi_off_rounded;

  const AppEmptyState.noNotifications({
    super.key,
    this.title = 'Radar Clear',
    this.subtitle = 'No pending table calls, referee summons, or federation dispatches.',
    this.description,
    this.ctaLabel,
    this.onCtaTap,
    this.secondaryCtaLabel,
    this.onSecondaryCtaTap,
    this.bannerAsset = ArmSphereAssets.cardArenaRadar,
    this.bannerAlignment = ArmSphereAssets.stageTopFocal,
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
      duration: const Duration(milliseconds: 260),
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    _slideAnimation = Tween<double>(begin: 8.0, end: 0.0).animate(curve);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _resolveArtwork() {
    if (widget.bannerAsset != null && widget.bannerAsset!.isNotEmpty) {
      return widget.bannerAsset!;
    }
    if (widget.icon == Icons.videocam_off_outlined ||
        widget.icon == Icons.play_circle_outline ||
        widget.icon == Icons.dynamic_feed_outlined ||
        widget.icon == Icons.forum_outlined) {
      return ArmSphereAssets.clipFallbackSparring;
    }
    if (widget.icon == Icons.emoji_events_outlined ||
        widget.icon == Icons.military_tech_outlined) {
      return ArmSphereAssets.tournamentPoster;
    }
    if (widget.icon == Icons.storefront_outlined ||
        widget.icon == Icons.location_on_outlined) {
      return ArmSphereAssets.bentoVenues;
    }
    return ArmSphereAssets.cardStandbyTable;
  }

  @override
  Widget build(BuildContext context) {
    final resolvedAsset = _resolveArtwork();

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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 150,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ArmSphereImage(
                          assetPath: resolvedAsset,
                          alignment: widget.bannerAlignment,
                          fit: BoxFit.cover,
                          fallbackAsset: ArmSphereAssets.cardStandbyTable,
                          excludeFromSemantics: true,
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: [0.0, 0.45, 1.0],
                              colors: [
                                Color(0x26070A11),
                                Color(0x66070A11),
                                Color(0xD9070A11),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.icon,
                                size: 14,
                                color: AppTheme.goldPrimary,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'STANDBY',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: AppTheme.goldPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          left: 14,
                          right: 14,
                          bottom: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                  fontFamily: AppTheme.fontDisplay,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 3),
                              if ((widget.subtitle ?? widget.description ?? '').isNotEmpty)
                                Text(
                                  widget.subtitle ?? widget.description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                    height: 1.35,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.ctaLabel != null && widget.onCtaTap != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TactilePressWrapper(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.onCtaTap!();
                      },
                      semanticLabel: widget.ctaLabel,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.ctaLabel!,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                color: AppTheme.goldPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 15,
                              color: AppTheme.goldPrimary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
