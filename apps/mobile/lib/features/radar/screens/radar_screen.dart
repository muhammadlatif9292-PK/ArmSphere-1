import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/config/map_config.dart';
import '../../../core/providers/athlete_provider.dart';
import '../../../core/providers/state_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/armsphere_location_picker.dart';
import '../../../core/widgets/crystal_glass_nav_controls.dart';
import '../../../core/widgets/crystal_toast.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/radar_provider.dart';
import '../widgets/drop_beacon_sheet.dart';
import '../widgets/radar_carousel_card.dart';
import '../widgets/radar_filter_sheet.dart';
import '../widgets/radar_map_markers.dart';

/// Full-screen ArmSphere Tactical Radar Map.
///
/// Features:
/// - Zero-billing 2D `flutter_map` (Geoapify Dark Matter -> CARTO Dark fallback -> obsidian error tile)
/// - Satellite imagery toggle (Esri World Imagery)
/// - Smooth animated camera transitions + GPS "Center on Me" with graceful permission-denied handling
/// - Debounced (~500ms) viewport-based loading from `GET /api/radar/nearby`
/// - Bi-directional Carousel <-> Map sync protected by an explicit anti-loop guard (`_suppressSync`)
/// - Floating Drop Beacon FAB (above carousel) with optimistic offline queue + long-press/button deletion
/// - Offline resilience with cached last-updated banner and offline empty state
class RadarScreen extends ConsumerStatefulWidget {
  final bool personalBeaconsOnly;

  const RadarScreen({
    super.key,
    this.personalBeaconsOnly = false,
  });

  @override
  ConsumerState<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends ConsumerState<RadarScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late final PageController _carouselController;

  bool _isSatellite = false;
  bool _isLocatingGps = false;
  bool _mapReady = false;
  bool _personalScopeOnly = false;
  bool _isUpdatingVisibility = false;
  LatLng? _userGpsLocation;
  LatLng? _savedHomeLocation;
  LatLng _currentCenter = const LatLng(
    ArmSphereMapConfig.defaultLatitude,
    ArmSphereMapConfig.defaultLongitude,
  );

  /// Distance origin is strictly the user's real GPS fix or saved home base —
  /// never the panned map camera center.
  LatLng? get _distanceOrigin => _userGpsLocation ?? _savedHomeLocation;

  // Anti-loop guards preventing infinite Carousel <-> Map feedback loops.
  bool _isAnimatingCamera = false;
  bool _suppressCarouselPageChange = false;
  AnimationController? _cameraAnimController;

  @override
  void initState() {
    super.initState();
    _personalScopeOnly = widget.personalBeaconsOnly;
    _carouselController = PageController(viewportFraction: 0.86);
    _seedInitialCenterFromProfile();
  }

  void _seedInitialCenterFromProfile() {
    final profile = ref.read(athleteProfileProvider).value ??
        ref.read(authProvider).userProfile;
    final lat = (profile?['latitude'] as num?)?.toDouble();
    final lng = (profile?['longitude'] as num?)?.toDouble();
    if (lat != null && lng != null && lat.isFinite && lng.isFinite) {
      final home = LatLng(lat, lng);
      _savedHomeLocation = home;
      _currentCenter = home;
    }
  }

  @override
  void dispose() {
    _cameraAnimController?.dispose();
    _carouselController.dispose();
    super.dispose();
  }

  /// Smooth animated map camera transition that suppresses feedback loops while flying.
  void _animatedMapMove(LatLng destLocation, double destZoom) {
    if (!_mapReady) return;
    _cameraAnimController?.stop();
    _cameraAnimController?.dispose();

    final startCenter = _mapController.camera.center;
    final startZoom = _mapController.camera.zoom;

    final latTween = Tween<double>(
      begin: startCenter.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: startCenter.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(begin: startZoom, end: destZoom);

    final controller = AnimationController(
      duration: const Duration(milliseconds: 420),
      vsync: this,
    );
    _cameraAnimController = controller;

    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutCubic,
    );

    _isAnimatingCamera = true;
    controller.addListener(() {
      if (!mounted) return;
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        _isAnimatingCamera = false;
        _currentCenter = destLocation;
        if (mounted && _mapReady) {
          ref.read(radarProvider.notifier).scheduleViewportFetch(
                _mapController.camera.visibleBounds,
                referenceCenter: _distanceOrigin,
              );
        }
      }
    });

    controller.forward();
  }

  void _onMapReady() {
    _mapReady = true;
    final bounds = _mapController.camera.visibleBounds;
    ref.read(radarProvider.notifier).scheduleViewportFetch(
          bounds,
          referenceCenter: _distanceOrigin,
          immediate: true,
        );
    // Attempt silent GPS lock if permission is already granted (never prompts aggressively on launch).
    _trySilentInitialGps();
  }

  Future<void> _trySilentInitialGps() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      final perm = await Geolocator.checkPermission();
      if (perm != LocationPermission.whileInUse &&
          perm != LocationPermission.always) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 6),
        ),
      );
      if (!mounted) return;
      final gpsLatLng = LatLng(pos.latitude, pos.longitude);
      setState(() => _userGpsLocation = gpsLatLng);
      _animatedMapMove(gpsLatLng, 12.5);
    } catch (_) {
      // Radar works seamlessly without GPS.
    }
  }

  Future<void> _centerOnMe() async {
    if (_isLocatingGps) return;
    HapticFeedback.selectionClick();
    setState(() => _isLocatingGps = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationPermissionToast(
          'Location services are disabled. Enable GPS to center on your position.',
          openLocationSettings: true,
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showLocationPermissionToast(
          'Location permission is needed to center on you. You can still pan and search manually.',
          openLocationSettings: false,
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!mounted) return;
      final gpsLatLng = LatLng(pos.latitude, pos.longitude);
      setState(() => _userGpsLocation = gpsLatLng);
      _animatedMapMove(gpsLatLng, 13.2);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CrystalSnackBar(
            content: const Text(
              'Unable to acquire GPS fix. Pan or search the map manually.',
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocatingGps = false);
    }
  }

  void _showLocationPermissionToast(
    String message, {
    required bool openLocationSettings,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      CrystalSnackBar(
        content: Text(message),
        backgroundColor: AppTheme.titanium,
        action: SnackBarAction(
          label: 'Open Settings',
          textColor: AppTheme.goldPrimary,
          onPressed: () {
            if (openLocationSettings) {
              Geolocator.openLocationSettings();
            } else {
              Geolocator.openAppSettings();
            }
          },
        ),
      ),
    );
  }

  Future<void> _openLocationSearch() async {
    HapticFeedback.selectionClick();
    final picked = await ArmSphereLocationPicker.show(
      context,
      title: 'Fly Radar To Location',
      initialLatitude: _currentCenter.latitude,
      initialLongitude: _currentCenter.longitude,
    );
    if (picked == null || !mounted) return;
    _animatedMapMove(LatLng(picked.latitude, picked.longitude), 13.0);
  }

  Future<void> _openFilters() async {
    HapticFeedback.selectionClick();
    final currentFilter = ref.read(radarProvider).filter;
    final updated = await RadarFilterSheet.show(
      context,
      initialFilter: currentFilter,
    );
    if (updated != null && mounted) {
      ref.read(radarProvider.notifier).updateFilter(updated);
    }
  }

  Future<void> _openDropBeaconSheet() async {
    HapticFeedback.mediumImpact();
    final profile = ref.read(athleteProfileProvider).value ??
        ref.read(authProvider).userProfile;
    final mapCenter = _mapReady ? _mapController.camera.center : _currentCenter;

    final submission = await DropBeaconSheet.show(
      context,
      initialLatitude: mapCenter.latitude,
      initialLongitude: mapCenter.longitude,
      initialWeightClass: profile?['weightClass']?.toString(),
      initialArmPreference: profile?['dominantArm']?.toString(),
    );
    if (submission == null || !mounted) return;

    final result = await ref.read(radarProvider.notifier).dropBeacon(
          beaconType: submission.beaconType,
          title: submission.title,
          latitude: submission.latitude,
          longitude: submission.longitude,
          weightClass: submission.weightClass,
          armPreference: submission.armPreference,
          durationHours: submission.durationHours,
        );

    if (!mounted) return;
    _animatedMapMove(LatLng(result.pin.latitude, result.pin.longitude), 13.2);
    ScaffoldMessenger.of(context).showSnackBar(
      CrystalSnackBar(
        content: Text(
          result.queuedOffline
              ? 'Beacon dropped locally — queued to sync automatically when online.'
              : 'Live Radar Beacon broadcasting now!',
        ),
        backgroundColor: result.queuedOffline ? AppTheme.warning : AppTheme.emerald,
      ),
    );
  }

  Future<void> _confirmDeleteBeacon(RadarPin pin) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0xCC030509),
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          side: BorderSide(color: AppTheme.crimson.withValues(alpha: 0.55)),
        ),
        title: const Text(
          'Delete Active Beacon?',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPure,
          ),
        ),
        content: Text(
          'Remove "${pin.title}" from ArmSphere Radar immediately?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.crimson,
              foregroundColor: AppTheme.textPure,
            ),
            child: const Text('Delete Beacon'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await ref.read(radarProvider.notifier).deleteBeacon(pin.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      CrystalSnackBar(
        content: Text(
          ok ? 'Beacon removed from Radar.' : 'Could not delete beacon.',
        ),
        backgroundColor: ok ? AppTheme.emerald : AppTheme.error,
      ),
    );
  }

  Future<void> _messageBeaconOwner(RadarPin pin) async {
    final targetUserId = pin.userId;
    if (targetUserId == null || targetUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        CrystalSnackBar(
          content: const Text('Unable to open chat for this beacon.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    HapticFeedback.selectionClick();
    try {
      final conv = await ref
          .read(messagingRepositoryProvider)
          .getOrCreateConversation(targetUserId);
      final convId = conv['id']?.toString();
      if (!mounted) return;
      if (convId != null && convId.isNotEmpty) {
        final recipientName = pin.title.trim();
        context.push(
          '/messages/$convId',
          extra: recipientName.isNotEmpty
              ? {'recipientName': recipientName}
              : null,
        );
      } else {
        context.push('/messages');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CrystalSnackBar(
            content: const Text('Could not start conversation right now.'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  /// Map -> Carousel sync (scrolls carousel to tapped pin without triggering map bounce).
  void _onPinTapped(RadarPin pin, List<RadarPin> visiblePins) {
    ref.read(radarProvider.notifier).selectPin(pin.id);
    final idx = visiblePins.indexWhere((p) => p.id == pin.id);
    if (idx >= 0 && _carouselController.hasClients) {
      _suppressCarouselPageChange = true;
      _carouselController
          .animateToPage(
            idx,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          )
          .whenComplete(() {
        _suppressCarouselPageChange = false;
      });
    }
  }

  /// Carousel -> Map sync (centers map on swiped card without triggering carousel loop).
  void _onCarouselPageChanged(int index, List<RadarPin> visiblePins) {
    if (_suppressCarouselPageChange) return;
    if (index < 0 || index >= visiblePins.length) return;
    final pin = visiblePins[index];
    HapticFeedback.selectionClick();
    ref.read(radarProvider.notifier).selectPin(pin.id);
    final targetZoom = _mapReady
        ? _mapController.camera.zoom.clamp(11.5, 15.5)
        : 13.0;
    _animatedMapMove(pin.latLng, targetZoom);
  }

  void _handlePinPrimaryAction(RadarPin pin) {
    HapticFeedback.selectionClick();
    switch (pin.pinType) {
      case RadarPinType.event:
        context.push('/tournament/${pin.id}');
        break;
      case RadarPinType.venue:
        context.push('/venues/${pin.id}');
        break;
      case RadarPinType.club:
        RadarDirectionsHelper.openDirections(
          context,
          latitude: pin.latitude,
          longitude: pin.longitude,
          label: pin.title,
        );
        break;
      case RadarPinType.informalEvent:
        context.push('/informal-events/${pin.id}');
        break;
      case RadarPinType.athlete:
        context.push('/athlete/${pin.id}');
        break;
      case RadarPinType.beacon:
        _messageBeaconOwner(pin);
        break;
    }
  }

  Future<void> _enableAreaVisibilityFromGhostMode() async {
    if (_isUpdatingVisibility) return;
    HapticFeedback.selectionClick();
    setState(() => _isUpdatingVisibility = true);
    try {
      final ok = await ref
          .read(athleteProfileProvider.notifier)
          .updateLocationVisibility('AREA');
      if (!mounted) return;
      if (ok) {
        ref.invalidate(athleteProfileProvider);
        ref.read(radarProvider.notifier).refreshCurrentViewport();
        CrystalToast.show(
          context,
          title: 'Radar Visibility',
          message: 'Radar visibility set to Area (Discoverable).',
          type: CrystalToastType.success,
        );
      } else {
        CrystalToast.show(
          context,
          title: 'Update Failed',
          message: 'Could not update visibility right now.',
          type: CrystalToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingVisibility = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final radarState = ref.watch(radarProvider);
    final authProfile = ref.watch(authProvider).userProfile;
    final athleteProfile = ref.watch(athleteProfileProvider).valueOrNull;
    final currentUserId =
        (authProfile?['id'] ?? authProfile?['userId'])?.toString().trim();

    final locationVisibility = (athleteProfile?['locationVisibility'] ??
            authProfile?['locationVisibility'] ??
            'AREA')
        .toString()
        .trim()
        .toUpperCase();
    final isGhostMode = locationVisibility == 'GHOST';

    final allVisiblePins = radarState.visiblePins;
    final visiblePins = _personalScopeOnly
        ? allVisiblePins
            .where((pin) =>
                pin.pinType == RadarPinType.beacon &&
                pin.isOwnedBy(currentUserId))
            .toList()
        : allVisiblePins;
    final totalCarouselItems = visiblePins.length;

    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.voidBackground,
        extendBodyBehindAppBar: true,
        extendBody: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Full-Screen 2D Tactical FlutterMap (extends edge-to-edge behind status bar)
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentCenter,
                  initialZoom: ArmSphereMapConfig.defaultZoom,
                  minZoom: 3.0,
                  maxZoom: 18.0,
                  backgroundColor: AppTheme.voidBackground,
                  onMapReady: _onMapReady,
                  onPositionChanged: (camera, hasGesture) {
                    _currentCenter = camera.center;
                    // Anti-loop guard: only fetch on genuine user gesture or after animation settles.
                    if (hasGesture && !_isAnimatingCamera) {
                      ref.read(radarProvider.notifier).scheduleViewportFetch(
                            camera.visibleBounds,
                            referenceCenter: _distanceOrigin,
                          );
                    }
                  },
                ),
                children: [
              TileLayer(
                key: ValueKey<bool>(_isSatellite),
                urlTemplate: _isSatellite
                    ? ArmSphereMapConfig.satelliteUrl
                    : ArmSphereMapConfig.darkMatterPrimaryUrl,
                fallbackUrl: _isSatellite
                    ? null
                    : ArmSphereMapConfig.darkMatterFallbackUrl,
                userAgentPackageName: ArmSphereMapConfig.userAgentPackageName,
                errorImage: ArmSphereMapConfig.darkErrorTileImage,
                maxNativeZoom: 18,
              ),
              // Subtle GPS blue/cyan user dot if GPS is active
              if (_userGpsLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userGpsLocation!,
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.cyan.withValues(alpha: 0.25),
                          border: Border.all(color: AppTheme.cyan, width: 2),
                        ),
                        child: Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.cyan,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              // Live Tactical Pin Markers
              MarkerLayer(
                markers: visiblePins.map((pin) {
                  final isSelected = radarState.selectedPinId == pin.id;
                  final isOwned = pin.isOwnedBy(currentUserId);
                  final markerDim = pin.pinType == RadarPinType.beacon ? 58.0 : 46.0;
                  return Marker(
                    point: pin.latLng,
                    width: markerDim,
                    height: markerDim,
                    child: RadarPinMarker(
                      pin: pin,
                      isSelected: isSelected,
                      isOwned: isOwned,
                      onTap: () => _onPinTapped(pin, visiblePins),
                      onLongPress: (pin.pinType == RadarPinType.beacon && isOwned)
                          ? () => _confirmDeleteBeacon(pin)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          ),

          // 1B. Smooth top status-bar gradient fade (eliminates abrupt top spotlight sliver)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topPadding + 28,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.voidBackground.withValues(alpha: 0.72),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Top Tactical Header Bar (Back + Radar Title + Search + Filters)
          Positioned(
            top: topPadding + 10,
            left: 14,
            right: 14,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.overlayG6Surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    border: Border.all(
                      color: AppTheme.goldPrimary.withValues(alpha: 0.4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const CrystalBackButton(fallbackRoute: '/discover'),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _personalScopeOnly
                                      ? Icons.podcasts_rounded
                                      : Icons.radar_rounded,
                                  color: _personalScopeOnly
                                      ? AppTheme.crimson
                                      : AppTheme.goldPrimary,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    _personalScopeOnly
                                        ? 'MY RADAR & BEACONS'
                                        : 'ARMSPHERE RADAR',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                      color: AppTheme.textPure,
                                    ),
                                  ),
                                ),
                                if (radarState.isLoading) ...[
                                  const SizedBox(width: 8),
                                  const SizedBox(
                                    width: 11,
                                    height: 11,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.8,
                                      color: AppTheme.goldPrimary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              _personalScopeOnly
                                  ? '${visiblePins.length} active personal beacon${visiblePins.length == 1 ? '' : 's'}'
                                  : '${visiblePins.length} active signal${visiblePins.length == 1 ? '' : 's'} in sector',
                              style: const TextStyle(
                                fontFamily: AppTheme.fontMono,
                                fontSize: 10.5,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _TopIconAction(
                        icon: Icons.search_rounded,
                        tooltip: 'Search & Fly To Location',
                        onTap: _openLocationSearch,
                      ),
                      const SizedBox(width: 6),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _TopIconAction(
                            icon: Icons.tune_rounded,
                            tooltip: 'Filter Radar Layers',
                            isHighlighted: radarState.filter.hasActiveFilters,
                            onTap: _openFilters,
                          ),
                          if (radarState.filter.hasActiveFilters)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.crimson,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Personal Scope Banner: Ghost Mode notice + quick toggle & Personal/Public scope switch
                if (_personalScopeOnly) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.overlayG6Surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      border: Border.all(
                        color: isGhostMode
                            ? AppTheme.warning.withValues(alpha: 0.7)
                            : AppTheme.goldPrimary.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isGhostMode
                                  ? Icons.visibility_off_rounded
                                  : Icons.podcasts_rounded,
                              size: 16,
                              color: isGhostMode
                                  ? AppTheme.warning
                                  : AppTheme.goldPrimary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isGhostMode
                                    ? 'Ghost Mode is ON — you are hidden from nearby athletes'
                                    : (visiblePins.isEmpty
                                        ? 'No active beacons yet. Tap Drop Beacon to broadcast a session.'
                                        : 'Showing your ${visiblePins.length} active beacon${visiblePins.length == 1 ? '' : 's'}'),
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontBody,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPure,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (isGhostMode) ...[
                              FilledButton.icon(
                                onPressed: _isUpdatingVisibility
                                    ? null
                                    : _enableAreaVisibilityFromGhostMode,
                                style: AppTheme.primaryGoldButtonStyle.copyWith(
                                  padding: const WidgetStatePropertyAll(
                                    EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                  ),
                                  minimumSize: const WidgetStatePropertyAll(
                                    Size(0, 32),
                                  ),
                                ),
                                icon: _isUpdatingVisibility
                                    ? const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.8,
                                          color: AppTheme.voidBackground,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.visibility_rounded,
                                        size: 14,
                                      ),
                                label: const Text(
                                  'Switch to Area Mode',
                                  style: TextStyle(fontSize: 11.5),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            OutlinedButton.icon(
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                setState(() => _personalScopeOnly = false);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.textPure,
                                side: const BorderSide(
                                  color: AppTheme.overlayG6Border,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                minimumSize: const Size(0, 32),
                              ),
                              icon: const Icon(Icons.public_rounded, size: 14),
                              label: const Text(
                                'View Public Radar',
                                style: TextStyle(fontSize: 11.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                // Offline Cache Banner ("Cached — Last updated X minutes ago")
                if (radarState.isFromCache) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.overlayG6Surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      border: Border.all(
                        color: AppTheme.warning.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off_rounded,
                          size: 14,
                          color: AppTheme.warning,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          radarState.cacheAgeLabel,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontMono,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.goldLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 3. Offline No-Cache Centered Banner
          if (radarState.isOfflineNoCache)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 28),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xF00B0F19),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  border: Border.all(
                    color: AppTheme.goldPrimary.withValues(alpha: 0.45),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.wifi_off_rounded,
                      size: 34,
                      color: AppTheme.goldPrimary,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Connect to the internet to load the Radar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPure,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () =>
                          ref.read(radarProvider.notifier).refreshCurrentViewport(),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Retry'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.goldPrimary,
                        side: BorderSide(
                          color: AppTheme.goldPrimary.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 4. Right-Side Tactical Controls (Satellite Toggle + Center on Me + single Drop Beacon FAB)
          Positioned(
            right: 14,
            bottom: totalCarouselItems > 0
                ? bottomPadding + 196
                : bottomPadding + 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _FloatingMapButton(
                  icon: _isSatellite
                      ? Icons.dark_mode_outlined
                      : Icons.satellite_alt_rounded,
                  tooltip: _isSatellite ? 'Dark Tactical Map' : 'Satellite Layer',
                  isActive: _isSatellite,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _isSatellite = !_isSatellite);
                  },
                ),
                const SizedBox(height: 10),
                _FloatingMapButton(
                  icon: Icons.my_location_rounded,
                  tooltip: 'Center on Me',
                  isLoading: _isLocatingGps,
                  onTap: _centerOnMe,
                ),
                const SizedBox(height: 14),
                FloatingActionButton.extended(
                  heroTag: 'radar_drop_beacon_fab',
                  onPressed: _openDropBeaconSheet,
                  backgroundColor: AppTheme.crimson,
                  foregroundColor: AppTheme.textPure,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    side: BorderSide(
                      color: AppTheme.goldLight.withValues(alpha: 0.55),
                      width: 1.0,
                    ),
                  ),
                  icon: const Icon(Icons.podcasts_rounded, size: 19),
                  label: const Text(
                    'Drop Beacon',
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 5. Bottom Horizontally Scrollable Pin Carousel Overlay (active pins only)
          if (totalCarouselItems > 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomPadding + 12,
              child: SizedBox(
                height: 174,
                child: PageView.builder(
                  controller: _carouselController,
                  itemCount: totalCarouselItems,
                  onPageChanged: (index) {
                    if (index < visiblePins.length) {
                      _onCarouselPageChanged(index, visiblePins);
                    }
                  },
                  itemBuilder: (context, index) {
                    final pin = visiblePins[index];
                    final isOwned = pin.isOwnedBy(currentUserId);
                    final isSelected = radarState.selectedPinId == pin.id;
                    return Align(
                      alignment: Alignment.bottomCenter,
                      child: RadarCarouselCard(
                        pin: pin,
                        isSelected: isSelected,
                        isOwned: isOwned,
                        referenceCenter: _distanceOrigin,
                        onTapCard: () {
                          ref.read(radarProvider.notifier).selectPin(pin.id);
                          _animatedMapMove(
                            pin.latLng,
                            _mapReady
                                ? _mapController.camera.zoom.clamp(12.0, 15.5)
                                : 13.0,
                          );
                        },
                        onPrimaryAction: () => _handlePinPrimaryAction(pin),
                        onDirections: () => RadarDirectionsHelper.openDirections(
                          context,
                          latitude: pin.latitude,
                          longitude: pin.longitude,
                          label: pin.title,
                        ),
                        onDeleteBeacon: isOwned
                            ? () => _confirmDeleteBeacon(pin)
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopIconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _TopIconAction({
    required this.icon,
    required this.tooltip,
    this.isHighlighted = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isHighlighted
                ? AppTheme.goldPrimary.withValues(alpha: 0.16)
                : AppTheme.titanium,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isHighlighted ? AppTheme.goldPrimary : AppTheme.border,
            ),
          ),
          child: Icon(
            icon,
            size: 19,
            color: isHighlighted ? AppTheme.goldPrimary : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _FloatingMapButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isActive;
  final bool isLoading;
  final VoidCallback onTap;

  const _FloatingMapButton({
    required this.icon,
    required this.tooltip,
    this.isActive = false,
    this.isLoading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xEB0B0F19),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: isActive ? AppTheme.goldPrimary : AppTheme.border,
                width: isActive ? 1.4 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.goldPrimary,
                      ),
                    )
                  : Icon(
                      icon,
                      size: 20,
                      color: isActive ? AppTheme.goldPrimary : AppTheme.textPrimary,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
