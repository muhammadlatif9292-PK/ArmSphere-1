import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/map_config.dart';
import '../../../core/providers/venue_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/display_formatters.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/crystal_glass_nav_controls.dart';
import '../../../core/widgets/crystal_stage_scaffold.dart';
import '../../../core/widgets/crystal_toast.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/main_shell_screen.dart';
import '../../../core/widgets/skeleton_placeholder.dart';
import '../../../core/widgets/status_chip.dart';
import '../../radar/widgets/radar_carousel_card.dart';

/// Domain 9 / Stage 6 Convergence: Venue Detail Screen (`Venue Dossier`)
///
/// Displays real stored venue attributes from `GET /venues/:venueId`:
/// - Venue name, verification status, table count, clean address
/// - Interactive 2D mini-map & coordinates preview (`flutter_map`)
/// - Primary `Directions (Google Maps)` CTA button
/// - Opening / sparring notes, facility specs, and contact coordination
class VenueDetailScreen extends ConsumerWidget {
  final String venueId;

  const VenueDetailScreen({super.key, required this.venueId});

  Future<void> _openGoogleMapsDirections(
    BuildContext context, {
    required String name,
    required String addressLine,
    double? latitude,
    double? longitude,
  }) async {
    if (latitude != null &&
        longitude != null &&
        latitude.isFinite &&
        longitude.isFinite) {
      await RadarDirectionsHelper.openDirections(
        context,
        latitude: latitude,
        longitude: longitude,
        label: name,
      );
      return;
    }

    HapticFeedback.selectionClick();
    final query = Uri.encodeComponent(
      addressLine.isNotEmpty ? '$name, $addressLine' : name,
    );
    final mapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
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
            content: Text('Could not open Google Maps for $name.'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CrystalSnackBar(
            content: Text('Could not open Google Maps for $name.'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  int? _resolveTableCount(Map<String, dynamic> venue) {
    final raw = venue['tableCount'] ?? venue['tablesCount'] ?? venue['tables'];
    if (raw is num && raw.toInt() > 0) return raw.toInt();
    if (raw is String) {
      final parsed = int.tryParse(raw.trim());
      if (parsed != null && parsed > 0) return parsed;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venueAsync = ref.watch(venueDetailProvider(venueId));

    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace:
            const CrystalHeaderStageBar(domain: ArmSphereStageDomain.venues),
        elevation: 0,
        leading: const CrystalBackButton(fallbackRoute: '/venues'),
        title: const Text(
          'Venue Dossier',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: const [CrystalHomeButton()],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: CrystalStageBackdrop(domain: ArmSphereStageDomain.venues),
          ),
          RefreshIndicator(
            color: AppTheme.goldPrimary,
            backgroundColor: AppTheme.cardSurface,
            onRefresh: () async => ref.invalidate(venueDetailProvider(venueId)),
            child: venueAsync.when(
              loading: () => ListView(
                padding: const EdgeInsets.all(AppTheme.space16),
                children: const [
                  SkeletonPlaceholder(
                      height: 150, borderRadius: AppTheme.radiusMedium),
                  SizedBox(height: AppTheme.space16),
                  SkeletonPlaceholder(
                      height: 180, borderRadius: AppTheme.radiusMedium),
                  SizedBox(height: AppTheme.space16),
                  SkeletonPlaceholder(
                      height: 110, borderRadius: AppTheme.radiusMedium),
                ],
              ),
              error: (e, _) => AppEmptyState(
                icon: Icons.error_outline,
                title: 'Could not load venue dossier',
                subtitle: e.toString(),
                ctaLabel: 'Retry',
                onCtaTap: () => ref.invalidate(venueDetailProvider(venueId)),
              ),
              data: (venue) {
                final name = venue['name']?.toString().trim().isNotEmpty == true
                    ? venue['name'].toString().trim()
                    : 'Training Venue';
                final rawAddress = venue['address']?.toString().trim() ?? '';
                final city = venue['city']?.toString().trim() ?? '';
                final province = venue['province']?.toString().trim() ?? '';

                final cleanAddress = ArmSphereFormatters.formatCleanAddress([
                  rawAddress,
                  city,
                  province,
                ]);
                final cleanRegion = ArmSphereFormatters.formatCleanAddress([
                  city,
                  province,
                ]);

                final description =
                    venue['description']?.toString().trim() ?? '';
                final openingHours = (venue['openingHours'] ??
                        venue['sparringSchedule'] ??
                        venue['schedule'] ??
                        venue['sparringNotes'])
                    ?.toString()
                    .trim();
                final contactInfo =
                    venue['contactInfo']?.toString().trim() ?? '';
                final tableCount = _resolveTableCount(venue);

                final lat = (venue['latitude'] as num?)?.toDouble();
                final lng = (venue['longitude'] as num?)?.toDouble();
                final hasCoordinates = lat != null &&
                    lng != null &&
                    lat.isFinite &&
                    lng.isFinite;

                final verificationStatus =
                    (venue['verificationStatus']?.toString() ?? '').toUpperCase();
                final isVerified = venue['isVerified'] == true ||
                    verificationStatus == 'VERIFIED';

                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    AppTheme.space16,
                    AppTheme.space16,
                    AppTheme.space16,
                    MainShellScope.bottomClearance(
                      context,
                      additionalPadding: 44,
                    ),
                  ),
                  children: [
                    // 1. Venue Header & Quick Specs Dossier Card
                    ElevatedActionCard(
                      padding: const EdgeInsets.all(AppTheme.space16),
                      borderColor: isVerified
                          ? AppTheme.goldPrimary.withValues(alpha: 0.45)
                          : AppTheme.border,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isVerified
                                        ? const Color(0x73D4AF37)
                                        : const Color(0x38FFFFFF),
                                    width: 1.0,
                                  ),
                                ),
                                child: Icon(
                                  Icons.storefront_outlined,
                                  color: isVerified
                                      ? AppTheme.goldPrimary
                                      : AppTheme.textSecondary,
                                  size: 22,
                                ),
                              ),
                              StatusChip(
                                label: isVerified
                                    ? 'CERTIFIED TABLES'
                                    : 'VERIFICATION PENDING',
                                type: isVerified
                                    ? StatusType.success
                                    : StatusType.warning,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.space12),
                          Text(
                            name,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPure,
                            ),
                          ),
                          if (cleanAddress.isNotEmpty) ...[
                            const SizedBox(height: AppTheme.space8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.place_outlined,
                                    size: 15,
                                    color: AppTheme.goldPrimary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    cleanAddress,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: AppTheme.space12),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0x22FFFFFF),
                          ),
                          const SizedBox(height: AppTheme.space12),
                          // Key Facility Specs Row (Table Count + Region + GPS Status)
                          Row(
                            children: [
                              Expanded(
                                child: _VenueSpecCell(
                                  icon: Icons.table_restaurant_rounded,
                                  label: 'TABLES',
                                  value: tableCount != null
                                      ? ArmSphereFormatters.formatProTables(tableCount)
                                      : (isVerified
                                          ? 'Verified Table'
                                          : 'Standard Setup'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _VenueSpecCell(
                                  icon: Icons.location_city_rounded,
                                  label: 'REGION',
                                  value: cleanRegion.isNotEmpty
                                      ? cleanRegion
                                      : 'Pakistan',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.space16),
                          // Primary Directions CTA (Google Maps)
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () => _openGoogleMapsDirections(
                                context,
                                name: name,
                                addressLine: cleanAddress,
                                latitude: lat,
                                longitude: lng,
                              ),
                              style: AppTheme.primaryGoldButtonStyle,
                              icon: const Icon(
                                Icons.directions_rounded,
                                size: 18,
                              ),
                              label: const Text('Directions (Google Maps)'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.space16),

                    // 2. Interactive Mini-Map & Coordinates Preview
                    ElevatedActionCard(
                      padding: const EdgeInsets.all(AppTheme.space16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.map_outlined,
                                    size: 16,
                                    color: AppTheme.goldPrimary,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'LOCATION & COORDINATES',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                      color: AppTheme.goldLight,
                                    ),
                                  ),
                                ],
                              ),
                              if (hasCoordinates)
                                Text(
                                  '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontMono,
                                    fontSize: 10.5,
                                    color: AppTheme.textSecondary,
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.space12),
                          if (hasCoordinates) ...[
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMedium),
                              child: SizedBox(
                                height: 176,
                                width: double.infinity,
                                child: Stack(
                                  children: [
                                    FlutterMap(
                                      options: MapOptions(
                                        initialCenter: LatLng(lat, lng),
                                        initialZoom: 15.0,
                                        minZoom: 5.0,
                                        maxZoom: 18.0,
                                        backgroundColor:
                                            AppTheme.voidBackground,
                                        interactionOptions:
                                            const InteractionOptions(
                                          flags: InteractiveFlag.pinchZoom |
                                              InteractiveFlag.drag,
                                        ),
                                      ),
                                      children: [
                                        TileLayer(
                                          urlTemplate: ArmSphereMapConfig
                                              .darkMatterPrimaryUrl,
                                          fallbackUrl: ArmSphereMapConfig
                                              .darkMatterFallbackUrl,
                                          userAgentPackageName:
                                              ArmSphereMapConfig
                                                  .userAgentPackageName,
                                          errorImage: ArmSphereMapConfig
                                              .darkErrorTileImage,
                                          maxNativeZoom: 18,
                                        ),
                                        MarkerLayer(
                                          markers: [
                                            Marker(
                                              point: LatLng(lat, lng),
                                              width: 44,
                                              height: 44,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: AppTheme.goldPrimary
                                                      .withValues(alpha: 0.22),
                                                  border: Border.all(
                                                    color: AppTheme.goldPrimary,
                                                    width: 2.0,
                                                  ),
                                                ),
                                                child: const Icon(
                                                  Icons.location_on_rounded,
                                                  color: AppTheme.goldPrimary,
                                                  size: 22,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Positioned(
                                      right: 10,
                                      bottom: 10,
                                      child: Material(
                                        color: AppTheme.overlayG6Surface,
                                        borderRadius: BorderRadius.circular(8),
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          onTap: () => _openGoogleMapsDirections(
                                            context,
                                            name: name,
                                            addressLine: cleanAddress,
                                            latitude: lat,
                                            longitude: lng,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: AppTheme.goldPrimary
                                                    .withValues(alpha: 0.55),
                                              ),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.open_in_new_rounded,
                                                  size: 13,
                                                  color: AppTheme.goldPrimary,
                                                ),
                                                SizedBox(width: 5),
                                                Text(
                                                  'Open Maps',
                                                  style: TextStyle(
                                                    fontFamily:
                                                        AppTheme.fontDisplay,
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppTheme.textPure,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ] else ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppTheme.space12),
                              decoration: BoxDecoration(
                                color: AppTheme.elevatedSurface,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusSmall,
                                ),
                                border: Border.all(
                                  color: AppTheme.overlayG6Border,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_searching_rounded,
                                    size: 18,
                                    color: AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      cleanAddress.isNotEmpty
                                          ? 'Pin coordinates pending. Tap Directions above to search "$cleanAddress" in Google Maps.'
                                          : 'Exact GPS pin pending verification.',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: AppTheme.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.space16),

                    // 3. Opening / Sparring Notes & Facility Hardware Card
                    ElevatedActionCard(
                      padding: const EdgeInsets.all(AppTheme.space16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 16,
                                color: AppTheme.goldPrimary,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'OPENING, SPARRING & FACILITY NOTES',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                  color: AppTheme.goldLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.space12),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0x22FFFFFF),
                          ),
                          const SizedBox(height: AppTheme.space12),
                          if (openingHours != null &&
                              openingHours.isNotEmpty) ...[
                            Text(
                              openingHours,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPure,
                                height: 1.5,
                              ),
                            ),
                            if (description.isNotEmpty)
                              const SizedBox(height: AppTheme.space8),
                          ],
                          Text(
                            description.isNotEmpty
                                ? description
                                : (openingHours != null &&
                                        openingHours.isNotEmpty
                                    ? ''
                                    : 'Contact the venue organizer below to confirm table availability, open sparring hours, and drop-in rules.'),
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.6,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.space16),

                    // 4. Contact & Coordination Card
                    if (contactInfo.isNotEmpty) ...[
                      ElevatedActionCard(
                        padding: const EdgeInsets.all(AppTheme.space16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.contact_phone_outlined,
                                  size: 16,
                                  color: AppTheme.goldPrimary,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'COORDINATION & CONTACT',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                    color: AppTheme.goldLight,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.space12),
                            const Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0x22FFFFFF),
                            ),
                            const SizedBox(height: AppTheme.space12),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    contactInfo,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.textPrimary,
                                      fontFeatures: [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Copy contact info',
                                  icon: const Icon(
                                    Icons.copy_rounded,
                                    size: 18,
                                    color: AppTheme.goldPrimary,
                                  ),
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: contactInfo),
                                    );
                                    HapticFeedback.selectionClick();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      CrystalSnackBar(
                                        content: const Text(
                                          'Venue contact copied to clipboard.',
                                        ),
                                        backgroundColor: AppTheme.emerald,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.space16),
                    ],

                    // 5. Verification Status Notice (if pending or rejected)
                    if (!isVerified)
                      ElevatedActionCard(
                        padding: const EdgeInsets.all(AppTheme.space16),
                        borderColor: verificationStatus == 'REJECTED'
                            ? AppTheme.error
                            : AppTheme.secondaryAccent,
                        child: Row(
                          children: [
                            Icon(
                              verificationStatus == 'REJECTED'
                                  ? Icons.gpp_bad_outlined
                                  : Icons.hourglass_empty_outlined,
                              size: 24,
                              color: verificationStatus == 'REJECTED'
                                  ? AppTheme.error
                                  : AppTheme.secondaryAccent,
                            ),
                            const SizedBox(width: AppTheme.space12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    verificationStatus == 'REJECTED'
                                        ? 'Certification Declined'
                                        : 'Federation Review Pending',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    verificationStatus == 'REJECTED'
                                        ? 'This facility does not meet official federation table safety standards.'
                                        : 'Referees are auditing table padding, pin lines, and hardware tolerances.',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VenueSpecCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _VenueSpecCell({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.elevatedSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: AppTheme.overlayG6Border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.goldPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontBody,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPure,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
