import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../config/map_config.dart';
import '../theme/app_theme.dart';
import 'crystal_toast.dart';

/// Immutable location payload returned by [ArmSphereLocationPicker.show].
class ArmSpherePickedLocation {
  final double latitude;
  final double longitude;
  final String city;
  final String province;
  final String country;
  final String formattedAddress;

  const ArmSpherePickedLocation({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.province,
    required this.country,
    required this.formattedAddress,
  });

  String get coordinatesLabel =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
}

/// Reusable smoked-obsidian location picker trigger card that sits cleanly above
/// existing text fields in forms without removing or breaking them.
class ArmSphereLocationFieldCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double? latitude;
  final double? longitude;
  final String? resolvedAddress;
  final VoidCallback onPickLocation;
  final VoidCallback? onClear;

  const ArmSphereLocationFieldCard({
    super.key,
    this.title = 'Pin Exact Map Coordinates',
    this.subtitle = 'Drop a 2D map pin to auto-fill address and power Radar discovery',
    this.latitude,
    this.longitude,
    this.resolvedAddress,
    required this.onPickLocation,
    this.onClear,
  });

  bool get _hasCoordinates => latitude != null && longitude != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.smokedGlassDecoration(
        borderRadius: AppTheme.radiusMedium,
        borderColor: _hasCoordinates
            ? AppTheme.goldPrimary.withValues(alpha: 0.65)
            : AppTheme.border,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _hasCoordinates
                      ? AppTheme.goldPrimary.withValues(alpha: 0.16)
                      : AppTheme.elevatedSurface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(
                    color: _hasCoordinates
                        ? AppTheme.goldPrimary.withValues(alpha: 0.5)
                        : AppTheme.border,
                  ),
                ),
                child: Icon(
                  _hasCoordinates ? Icons.location_on_rounded : Icons.map_outlined,
                  size: 18,
                  color: _hasCoordinates ? AppTheme.goldPrimary : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _hasCoordinates
                          ? (resolvedAddress != null && resolvedAddress!.trim().isNotEmpty
                              ? resolvedAddress!
                              : '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}')
                          : subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontBody,
                        fontSize: 11.5,
                        color: _hasCoordinates ? AppTheme.goldLight : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_hasCoordinates && onClear != null)
                IconButton(
                  tooltip: 'Clear pinned coordinates',
                  icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textMuted),
                  onPressed: onClear,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onPickLocation();
                  },
                  icon: Icon(
                    _hasCoordinates ? Icons.edit_location_alt_outlined : Icons.add_location_alt_outlined,
                    size: 16,
                    color: AppTheme.goldPrimary,
                  ),
                  label: Text(
                    _hasCoordinates ? 'Adjust Map Pin' : 'Pick Location on Map',
                    style: const TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: AppTheme.goldPrimary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.goldPrimary.withValues(alpha: 0.55)),
                    backgroundColor: AppTheme.goldPrimary.withValues(alpha: 0.08),
                    padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                ),
              ),
              if (_hasCoordinates) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.voidBackground.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    '${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}',
                    style: const TextStyle(
                      fontFamily: AppTheme.fontMono,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.emerald,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Full-screen modal 2D pure-Flutter location picker styled in ArmSphere's
/// Forged-Crystal Obsidian aesthetic.
///
/// Features:
/// - Geoapify Dark Matter primary tiles with automatic CARTO Dark fallback & obsidian error tile
/// - Satellite imagery toggle (Esri World Imagery)
/// - Pan-to-position & tap-to-drop gold center crosshair pin
/// - Top smoked-glass search bar with 350ms debounced Geoapify/Photon autocomplete
/// - "Use My Location" GPS button via `geolocator` with graceful permission-denied handling
/// - Offline manual coordinates fallback dialog
class ArmSphereLocationPicker extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialLabel;
  final String title;

  const ArmSphereLocationPicker({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialLabel,
    this.title = 'Select Location',
  });

  /// Opens the universal location picker as a full-screen modal route and
  /// resolves with an [ArmSpherePickedLocation] when confirmed, or `null` if cancelled.
  static Future<ArmSpherePickedLocation?> show(
    BuildContext context, {
    double? initialLatitude,
    double? initialLongitude,
    String? initialLabel,
    String title = 'Select Location',
  }) {
    return Navigator.of(context, rootNavigator: true).push<ArmSpherePickedLocation>(
      MaterialPageRoute<ArmSpherePickedLocation>(
        fullscreenDialog: true,
        builder: (_) => ArmSphereLocationPicker(
          initialLatitude: initialLatitude,
          initialLongitude: initialLongitude,
          initialLabel: initialLabel,
          title: title,
        ),
      ),
    );
  }

  @override
  State<ArmSphereLocationPicker> createState() => _ArmSphereLocationPickerState();
}

class _ArmSphereLocationPickerState extends State<ArmSphereLocationPicker> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late LatLng _selectedPoint;
  bool _isSatellite = false;
  bool _isResolvingAddress = false;
  bool _isSearching = false;
  bool _isLocatingGps = false;

  String _resolvedCity = '';
  String _resolvedProvince = 'Punjab';
  String _resolvedCountry = 'Pakistan';
  String _resolvedAddress = '';

  List<ArmSphereGeocodeResult> _searchResults = const <ArmSphereGeocodeResult>[];
  Timer? _searchDebounce;
  Timer? _reverseDebounce;
  CancelToken? _searchCancelToken;
  CancelToken? _reverseCancelToken;

  @override
  void initState() {
    super.initState();
    _selectedPoint = LatLng(
      widget.initialLatitude ?? ArmSphereMapConfig.defaultLatitude,
      widget.initialLongitude ?? ArmSphereMapConfig.defaultLongitude,
    );
    _resolvedAddress = (widget.initialLabel ?? '').trim();
    _scheduleReverseGeocode(_selectedPoint, immediate: true);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _reverseDebounce?.cancel();
    _searchCancelToken?.cancel();
    _reverseCancelToken?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      _searchCancelToken?.cancel();
      setState(() {
        _isSearching = false;
        _searchResults = const <ArmSphereGeocodeResult>[];
      });
      return;
    }

    setState(() => _isSearching = true);
    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      _searchCancelToken?.cancel();
      _searchCancelToken = CancelToken();
      try {
        final results = await ArmSphereGeocodingService.searchPlaces(
          trimmed,
          cancelToken: _searchCancelToken,
        );
        if (!mounted) return;
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => _isSearching = false);
      }
    });
  }

  void _selectSearchResult(ArmSphereGeocodeResult result) {
    HapticFeedback.selectionClick();
    _searchFocusNode.unfocus();
    final target = LatLng(result.latitude, result.longitude);
    setState(() {
      _selectedPoint = target;
      _resolvedCity = result.city;
      _resolvedProvince = result.province;
      _resolvedCountry = result.country;
      _resolvedAddress = result.formattedAddress;
      _searchResults = const <ArmSphereGeocodeResult>[];
      _searchController.text = result.name;
    });
    _mapController.move(target, 15.0);
  }

  void _scheduleReverseGeocode(LatLng point, {bool immediate = false}) {
    _reverseDebounce?.cancel();
    _reverseDebounce = Timer(
      Duration(milliseconds: immediate ? 50 : 450),
      () async {
        _reverseCancelToken?.cancel();
        _reverseCancelToken = CancelToken();
        if (mounted) setState(() => _isResolvingAddress = true);
        try {
          final result = await ArmSphereGeocodingService.reverseGeocode(
            point.latitude,
            point.longitude,
            cancelToken: _reverseCancelToken,
          );
          if (!mounted) return;
          setState(() {
            _isResolvingAddress = false;
            if (result != null) {
              _resolvedCity = result.city;
              _resolvedProvince = result.province;
              _resolvedCountry = result.country;
              _resolvedAddress = result.formattedAddress;
            } else if (_resolvedAddress.isEmpty) {
              _resolvedAddress =
                  '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
            }
          });
        } catch (_) {
          if (!mounted) return;
          setState(() => _isResolvingAddress = false);
        }
      },
    );
  }

  Future<void> _useCurrentLocation() async {
    HapticFeedback.selectionClick();
    if (_isLocatingGps) return;
    setState(() => _isLocatingGps = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showNotice('Location services are disabled. Move the map pin or enter coordinates manually.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showNotice('Location permission denied. You can still search or drag the map pin manually.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!mounted) return;

      final target = LatLng(pos.latitude, pos.longitude);
      setState(() => _selectedPoint = target);
      _mapController.move(target, 15.5);
      _scheduleReverseGeocode(target, immediate: true);
    } catch (_) {
      _showNotice('Unable to lock GPS right now. Drag the map or enter coordinates manually.');
    } finally {
      if (mounted) setState(() => _isLocatingGps = false);
    }
  }

  void _showNotice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      CrystalSnackBar(
        content: Text(message),
        backgroundColor: AppTheme.warning,
      ),
    );
  }

  Future<void> _openManualCoordinatesDialog() async {
    final latCtrl = TextEditingController(text: _selectedPoint.latitude.toStringAsFixed(6));
    final lngCtrl = TextEditingController(text: _selectedPoint.longitude.toStringAsFixed(6));

    final result = await showDialog<LatLng>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          side: const BorderSide(color: AppTheme.border),
        ),
        title: const Text(
          'Manual Coordinates (Offline)',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            fontSize: 16,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter WGS-84 latitude and longitude directly if offline.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: latCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              style: const TextStyle(color: AppTheme.textPrimary, fontFamily: AppTheme.fontMono),
              decoration: const InputDecoration(
                labelText: 'Latitude (-90 to 90)',
                hintText: '31.520400',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: lngCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              style: const TextStyle(color: AppTheme.textPrimary, fontFamily: AppTheme.fontMono),
              decoration: const InputDecoration(
                labelText: 'Longitude (-180 to 180)',
                hintText: '74.358700',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final lat = double.tryParse(latCtrl.text.trim());
              final lng = double.tryParse(lngCtrl.text.trim());
              if (lat == null || lng == null || lat < -90 || lat > 90 || lng < -180 || lng > 180) {
                return;
              }
              Navigator.of(ctx).pop(LatLng(lat, lng));
            },
            child: const Text('Apply Pin'),
          ),
        ],
      ),
    );

    latCtrl.dispose();
    lngCtrl.dispose();

    if (result != null && mounted) {
      setState(() => _selectedPoint = result);
      _mapController.move(result, 15.0);
      _scheduleReverseGeocode(result, immediate: true);
    }
  }

  void _confirmSelection() {
    HapticFeedback.mediumImpact();
    final fallbackAddress = _resolvedAddress.trim().isNotEmpty
        ? _resolvedAddress.trim()
        : '${_selectedPoint.latitude.toStringAsFixed(5)}, ${_selectedPoint.longitude.toStringAsFixed(5)}';

    Navigator.of(context).pop(
      ArmSpherePickedLocation(
        latitude: double.parse(_selectedPoint.latitude.toStringAsFixed(6)),
        longitude: double.parse(_selectedPoint.longitude.toStringAsFixed(6)),
        city: _resolvedCity.trim(),
        province: _resolvedProvince.trim(),
        country: _resolvedCountry.trim(),
        formattedAddress: fallbackAddress,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
      body: Stack(
        children: [
          // 1. Full-screen 2D Pure-Flutter Map
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedPoint,
                initialZoom: widget.initialLatitude != null ? 15.0 : ArmSphereMapConfig.defaultZoom,
                minZoom: 3.0,
                maxZoom: 19.0,
                backgroundColor: AppTheme.voidBackground,
                onTap: (_, point) {
                  _searchFocusNode.unfocus();
                  setState(() {
                    _selectedPoint = point;
                    _searchResults = const <ArmSphereGeocodeResult>[];
                  });
                  _mapController.move(point, _mapController.camera.zoom);
                  _scheduleReverseGeocode(point);
                },
                onPositionChanged: (camera, hasGesture) {
                  if (hasGesture) {
                    setState(() => _selectedPoint = camera.center);
                    _scheduleReverseGeocode(camera.center);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: _isSatellite
                      ? ArmSphereMapConfig.satelliteUrl
                      : ArmSphereMapConfig.darkMatterPrimaryUrl,
                  fallbackUrl: _isSatellite
                      ? null
                      : ArmSphereMapConfig.darkMatterFallbackUrl,
                  userAgentPackageName: ArmSphereMapConfig.userAgentPackageName,
                  errorImage: ArmSphereMapConfig.darkErrorTileImage,
                ),
              ],
            ),
          ),

          // 2. Center Fixed Gold Drop Pin
          IgnorePointer(
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, -18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.voidBackground.withValues(alpha: 0.85),
                        border: Border.all(color: AppTheme.goldPrimary, width: 2.2),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.goldPrimary.withValues(alpha: 0.45),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppTheme.goldPrimary,
                        size: 26,
                      ),
                    ),
                    Container(
                      width: 3,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppTheme.goldPrimary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Container(
                      width: 10,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.goldPrimary.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Top Smoked-Glass Header + Search Bar + Results Dropdown
          Positioned(
            top: topPadding + 10,
            left: 14,
            right: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: AppTheme.smokedGlassDecoration(
                    borderRadius: AppTheme.radiusMedium,
                    borderColor: AppTheme.border,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, color: AppTheme.textPrimary),
                        tooltip: 'Cancel',
                        visualDensity: VisualDensity.compact,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onChanged: _onSearchChanged,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontFamily: AppTheme.fontBody,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search address, gym, venue, or city...',
                            hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13.5),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                            suffixIcon: _isSearching
                                ? const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.goldPrimary,
                                      ),
                                    ),
                                  )
                                : (_searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded,
                                            size: 18, color: AppTheme.textMuted),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchResults = const []);
                                        },
                                      )
                                    : const Icon(Icons.search_rounded,
                                        size: 20, color: AppTheme.goldPrimary)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_searchResults.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 240),
                    decoration: AppTheme.smokedGlassDecoration(
                      borderRadius: AppTheme.radiusMedium,
                      borderColor: AppTheme.goldPrimary.withValues(alpha: 0.35),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: AppTheme.borderSubtle,
                      ),
                      itemBuilder: (context, idx) {
                        final item = _searchResults[idx];
                        return ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.place_outlined,
                            color: AppTheme.goldPrimary,
                            size: 18,
                          ),
                          title: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            item.formattedAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                          onTap: () => _selectSearchResult(item),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 4. Right Floating Controls (Satellite Toggle, GPS, Manual Coordinates)
          Positioned(
            right: 14,
            bottom: bottomPadding + 195,
            child: Column(
              children: [
                _MapControlButton(
                  icon: _isSatellite ? Icons.dark_mode_outlined : Icons.satellite_alt_rounded,
                  tooltip: _isSatellite ? 'Switch to Dark Map' : 'Switch to Satellite',
                  isActive: _isSatellite,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() => _isSatellite = !_isSatellite);
                  },
                ),
                const SizedBox(height: 10),
                _MapControlButton(
                  icon: Icons.my_location_rounded,
                  tooltip: 'Use My Location',
                  isLoading: _isLocatingGps,
                  onPressed: _useCurrentLocation,
                ),
                const SizedBox(height: 10),
                _MapControlButton(
                  icon: Icons.edit_note_rounded,
                  tooltip: 'Enter Coordinates Manually',
                  onPressed: _openManualCoordinatesDialog,
                ),
              ],
            ),
          ),

          // 5. Bottom Smoked-Glass Resolved Address & Confirm Bar
          Positioned(
            left: 14,
            right: 14,
            bottom: bottomPadding + 14,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.smokedGlassDecoration(
                borderRadius: AppTheme.radiusLarge,
                borderColor: AppTheme.goldPrimary.withValues(alpha: 0.45),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.title.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: AppTheme.goldPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_selectedPoint.latitude.toStringAsFixed(5)}, ${_selectedPoint.longitude.toStringAsFixed(5)}',
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
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: AppTheme.goldPrimary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _isResolvingAddress
                            ? const Text(
                                'Resolving address...',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontBody,
                                  fontSize: 13.5,
                                  color: AppTheme.textSecondary,
                                ),
                              )
                            : Text(
                                _resolvedAddress.isNotEmpty
                                    ? _resolvedAddress
                                    : '${_selectedPoint.latitude.toStringAsFixed(5)}, ${_selectedPoint.longitude.toStringAsFixed(5)}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontBody,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                      ),
                    ],
                  ),
                  if (_resolvedCity.isNotEmpty || _resolvedProvince.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 26),
                      child: Text(
                        [
                          if (_resolvedCity.isNotEmpty) _resolvedCity,
                          if (_resolvedProvince.isNotEmpty) _resolvedProvince,
                          if (_resolvedCountry.isNotEmpty) _resolvedCountry,
                        ].join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontBody,
                          fontSize: 11.5,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: _confirmSelection,
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                    label: const Text('CONFIRM LOCATION'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldPrimary,
                      foregroundColor: AppTheme.voidBackground,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isActive;
  final bool isLoading;

  const _MapControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isActive = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Container(
            width: 44,
            height: 44,
            decoration: AppTheme.smokedGlassDecoration(
              borderRadius: AppTheme.radiusMedium,
              borderColor: isActive ? AppTheme.goldPrimary : AppTheme.border,
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
