import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/crystal_toast.dart';
import '../providers/radar_provider.dart';

/// Safe turn-by-turn Google Maps navigation launcher with browser fallback.
class RadarDirectionsHelper {
  RadarDirectionsHelper._();

  static Future<void> openDirections(
    BuildContext context, {
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    HapticFeedback.selectionClick();
    final Uri mapsUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude',
    );
    try {
      final launchedExternal = await launchUrl(
        mapsUri,
        mode: LaunchMode.externalApplication,
      );
      if (launchedExternal) return;

      final launchedBrowser = await launchUrl(
        mapsUri,
        mode: LaunchMode.platformDefault,
      );
      if (launchedBrowser) return;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CrystalSnackBar(
            content: Text(
              'Could not open directions${label != null ? ' for $label' : ''}.',
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CrystalSnackBar(
            content: const Text('Unable to launch maps or browser on this device.'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}

/// Compact Forged-Crystal Obsidian card docked in the bottom Radar carousel.
class RadarCarouselCard extends StatelessWidget {
  final RadarPin pin;
  final bool isSelected;
  final bool isOwned;
  final LatLng? referenceCenter;
  final VoidCallback onTapCard;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onDirections;
  final VoidCallback? onDeleteBeacon;

  const RadarCarouselCard({
    super.key,
    required this.pin,
    required this.isSelected,
    required this.isOwned,
    this.referenceCenter,
    required this.onTapCard,
    this.onPrimaryAction,
    this.onDirections,
    this.onDeleteBeacon,
  });

  Color get _accentColor {
    switch (pin.pinType) {
      case RadarPinType.event:
        return AppTheme.goldPrimary;
      case RadarPinType.venue:
      case RadarPinType.club:
        return AppTheme.textSecondary;
      case RadarPinType.informalEvent:
        return AppTheme.highlightPurple;
      case RadarPinType.athlete:
        return AppTheme.cyan;
      case RadarPinType.beacon:
        return AppTheme.crimson;
    }
  }

  IconData get _typeIcon {
    switch (pin.pinType) {
      case RadarPinType.event:
        return Icons.emoji_events_rounded;
      case RadarPinType.venue:
        return Icons.storefront_rounded;
      case RadarPinType.club:
        return Icons.fitness_center_rounded;
      case RadarPinType.informalEvent:
        return Icons.sports_martial_arts_rounded;
      case RadarPinType.athlete:
        return Icons.person_rounded;
      case RadarPinType.beacon:
        return (pin.beaconType ?? '').toUpperCase().contains('TRAVEL')
            ? Icons.flight_takeoff_rounded
            : Icons.local_fire_department_rounded;
    }
  }

  String get _typeBadgeLabel {
    switch (pin.pinType) {
      case RadarPinType.event:
        return 'TOURNAMENT';
      case RadarPinType.venue:
        return pin.isVerified ? 'VERIFIED VENUE' : 'VENUE';
      case RadarPinType.club:
        return 'CLUB / GYM';
      case RadarPinType.informalEvent:
        return 'SPARRING MEETUP';
      case RadarPinType.athlete:
        return 'ATHLETE • ~1 KM AREA';
      case RadarPinType.beacon:
        return (pin.beaconType ?? '').toUpperCase().contains('TRAVEL')
            ? 'TRAVELING PULLER'
            : 'PICKUP SPARRING';
    }
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final m = months[(local.month - 1).clamp(0, 11)];
    return '$m ${local.day}, ${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor;
    final distanceLabel = referenceCenter != null
        ? '${pin.distanceKmFrom(referenceCenter!).toStringAsFixed(1)} km'
        : null;

    final metaChips = <String>[];
    if (pin.pinType == RadarPinType.event && pin.startDate != null) {
      metaChips.add(_formatDate(pin.startDate!));
    }
    if (pin.pinType == RadarPinType.informalEvent && pin.scheduledAt != null) {
      metaChips.add(_formatDate(pin.scheduledAt!));
    }
    if (pin.weightClass != null && pin.weightClass!.isNotEmpty) {
      metaChips.add(pin.weightClass!);
    }
    if (pin.armPreference != null && pin.armPreference!.isNotEmpty) {
      metaChips.add('${pin.armPreference!.toUpperCase()} ARM');
    }
    if (pin.pinType == RadarPinType.beacon && pin.expiryRemainingLabel != null) {
      metaChips.add(pin.expiryRemainingLabel!);
    }
    if (pin.isPendingOffline) {
      metaChips.add('SYNCING');
    }

    return GestureDetector(
      onTap: onTapCard,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xEB0B0F19),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: isSelected
                ? accent.withValues(alpha: 0.85)
                : AppTheme.border,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.58),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Type Badge + Distance
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.5),
                      width: 0.9,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_typeIcon, size: 12, color: accent),
                      const SizedBox(width: 5),
                      Text(
                        _typeBadgeLabel,
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                          color: accent == AppTheme.textSecondary
                              ? AppTheme.textPrimary
                              : accent,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (distanceLabel != null)
                  Text(
                    distanceLabel,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontMono,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Title & Subtitle
            Text(
              pin.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPure,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              pin.subtitle.isNotEmpty
                  ? pin.subtitle
                  : (pin.address ?? pin.venue ?? pin.city ?? 'ArmSphere Location'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppTheme.fontBody,
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),

            if (metaChips.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: metaChips.take(3).map((chip) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: AppTheme.titanium,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Text(
                      chip,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontMono,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 10),

            // Context Action Row
            Row(
              children: _buildActions(context),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    switch (pin.pinType) {
      case RadarPinType.event:
        return [
          Expanded(
            child: _PrimaryMiniButton(
              label: 'View Details',
              icon: Icons.open_in_new_rounded,
              color: AppTheme.goldPrimary,
              textColor: AppTheme.voidBackground,
              onPressed: onPrimaryAction,
            ),
          ),
          const SizedBox(width: 8),
          _SecondaryMiniButton(
            label: 'Directions',
            icon: Icons.directions_rounded,
            onPressed: onDirections,
          ),
        ];

      case RadarPinType.venue:
        return [
          Expanded(
            child: _PrimaryMiniButton(
              label: 'Get Directions',
              icon: Icons.directions_rounded,
              color: AppTheme.goldPrimary,
              textColor: AppTheme.voidBackground,
              onPressed: onDirections,
            ),
          ),
          if (onPrimaryAction != null) ...[
            const SizedBox(width: 8),
            _SecondaryMiniButton(
              label: 'Details',
              icon: Icons.info_outline_rounded,
              onPressed: onPrimaryAction,
            ),
          ],
        ];

      case RadarPinType.club:
        return [
          Expanded(
            child: _PrimaryMiniButton(
              label: 'Get Directions',
              icon: Icons.directions_rounded,
              color: AppTheme.goldPrimary,
              textColor: AppTheme.voidBackground,
              onPressed: onDirections,
            ),
          ),
        ];

      case RadarPinType.informalEvent:
        return [
          Expanded(
            child: _PrimaryMiniButton(
              label: 'View Meetup',
              icon: Icons.sports_martial_arts_rounded,
              color: AppTheme.goldPrimary,
              textColor: AppTheme.voidBackground,
              onPressed: onPrimaryAction,
            ),
          ),
          const SizedBox(width: 8),
          _SecondaryMiniButton(
            label: 'Directions',
            icon: Icons.directions_rounded,
            onPressed: onDirections,
          ),
        ];

      case RadarPinType.athlete:
        return [
          Expanded(
            child: _PrimaryMiniButton(
              label: 'View Profile',
              icon: Icons.person_outline_rounded,
              color: AppTheme.goldPrimary,
              textColor: AppTheme.voidBackground,
              onPressed: onPrimaryAction,
            ),
          ),
        ];

      case RadarPinType.beacon:
        if (isOwned) {
          return [
            Expanded(
              child: _PrimaryMiniButton(
                label: 'Delete Beacon',
                icon: Icons.delete_outline_rounded,
                color: AppTheme.crimson,
                textColor: AppTheme.textPure,
                onPressed: onDeleteBeacon,
              ),
            ),
            const SizedBox(width: 8),
            _SecondaryMiniButton(
              label: 'Directions',
              icon: Icons.directions_rounded,
              onPressed: onDirections,
            ),
          ];
        }
        return [
          Expanded(
            child: _PrimaryMiniButton(
              label: 'Message',
              icon: Icons.chat_bubble_outline_rounded,
              color: AppTheme.crimson,
              textColor: AppTheme.textPure,
              onPressed: onPrimaryAction,
            ),
          ),
          const SizedBox(width: 8),
          _SecondaryMiniButton(
            label: 'Directions',
            icon: Icons.directions_rounded,
            onPressed: onDirections,
          ),
        ];
    }
  }
}

class _PrimaryMiniButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback? onPressed;

  const _PrimaryMiniButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 15),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          textStyle: const TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SecondaryMiniButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const _SecondaryMiniButton({
    required this.label,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 15, color: AppTheme.goldPrimary),
        label: Text(
          label,
          style: const TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppTheme.goldPrimary.withValues(alpha: 0.45)),
          backgroundColor: AppTheme.titanium,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
        ),
      ),
    );
  }
}

/// Subtle empty-beacon prompt card displayed in the carousel when the user
/// has no active beacon yet.
class RadarEmptyBeaconPromptCard extends StatelessWidget {
  final VoidCallback onDropBeacon;

  const RadarEmptyBeaconPromptCard({
    super.key,
    required this.onDropBeacon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xEB0B0F19),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppTheme.crimson.withValues(alpha: 0.48),
          width: 1.1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.crimson.withValues(alpha: 0.16),
              border: Border.all(
                color: AppTheme.crimson.withValues(alpha: 0.55),
              ),
            ),
            child: const Icon(
              Icons.podcasts_rounded,
              color: AppTheme.crimson,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LOOKING FOR A TABLE?',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppTheme.crimson,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  "Drop a Beacon to let nearby athletes know you're looking for a match.",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.fontBody,
                    fontSize: 12.2,
                    height: 1.3,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              onDropBeacon();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.crimson,
              foregroundColor: AppTheme.textPure,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
            ),
            child: const Text(
              'Drop',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
