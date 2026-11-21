import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/painting.dart';
import 'package:geocoding/geocoding.dart' as geo;

/// Zero-billing 2D map tile configuration and geocoding client for ArmSphere.
///
/// Primary tiles use Geoapify Dark Matter with automatic fallback to CARTO
/// Dark Matter and a solid obsidian error tile matching `AppTheme.voidBackground`
/// (`#0B0D12`) so tile loading failures never flash white.
class ArmSphereMapConfig {
  ArmSphereMapConfig._();

  /// Geoapify public tile/geocoding key — overridable via `--dart-define=GEOAPIFY_API_KEY=...`.
  static const String geoapifyApiKey = String.fromEnvironment(
    'GEOAPIFY_API_KEY',
    defaultValue: '1a8a00553de54d9cb23ebd021079ebf1',
  );

  /// User-Agent package identifier for OpenStreetMap / Geoapify tile servers.
  static const String userAgentPackageName = 'com.armsphere.mobile';

  /// Default map center (Lahore, Pakistan) when GPS or initial coords are unavailable.
  static const double defaultLatitude = 31.5204;
  static const double defaultLongitude = 74.3587;
  static const double defaultZoom = 12.0;

  /// Primary dark map tile URL (Geoapify Dark Matter).
  static String get darkMatterPrimaryUrl =>
      'https://maps.geoapify.com/v1/tile/dark-matter-dark-grey/{z}/{x}/{y}.png?apiKey=$geoapifyApiKey';

  /// Secondary fallback dark map tile URL (CARTO Dark Matter, no key required).
  static const String darkMatterFallbackUrl =
      'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';

  /// Satellite imagery tile URL (Esri World Imagery, free attribution layer).
  static const String satelliteUrl =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

  /// Mathematically valid 1x1 solid PNG matching `AppTheme.voidBackground` (#0B0D12)
  /// so failed or offline tiles render seamlessly in smoked obsidian instead of white.
  static final Uint8List darkErrorTileBytes = Uint8List.fromList(<int>[
    137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82,
    0, 0, 0, 1, 0, 0, 0, 1, 8, 2, 0, 0, 0, 144, 119, 83, 222,
    0, 0, 0, 12, 73, 68, 65, 84, 120, 156, 99, 224, 230, 21, 2, 0,
    0, 81, 0, 43, 71, 66, 207, 77, 0, 0, 0, 0, 73, 69, 78, 68,
    174, 66, 96, 130,
  ]);

  static final ImageProvider darkErrorTileImage = MemoryImage(darkErrorTileBytes);

  /// Known Pakistan provinces/territories for normalizing geocoder administrative regions.
  static const List<String> pakistanProvinces = <String>[
    'Punjab',
    'Sindh',
    'Khyber Pakhtunkhwa',
    'Balochistan',
    'Islamabad Capital Territory',
    'Gilgit-Baltistan',
    'Azad Kashmir',
  ];

  /// Maps free-text province/state strings from geocoders onto canonical ArmSphere province names.
  static String normalizeProvince(String rawProvince, {String? fallbackCity}) {
    final normalized = rawProvince.trim().toLowerCase();
    if (normalized.contains('punjab')) return 'Punjab';
    if (normalized.contains('sindh')) return 'Sindh';
    if (normalized.contains('khyber') || normalized.contains('pakhtunkhwa') || normalized == 'kpk' || normalized == 'kp') {
      return 'Khyber Pakhtunkhwa';
    }
    if (normalized.contains('baloch')) return 'Balochistan';
    if (normalized.contains('islamabad') || normalized == 'ict') {
      return 'Islamabad Capital Territory';
    }
    if (normalized.contains('gilgit') || normalized.contains('baltistan') || normalized == 'gb') {
      return 'Gilgit-Baltistan';
    }
    if (normalized.contains('azad') || normalized.contains('kashmir') || normalized == 'ajk') {
      return 'Azad Kashmir';
    }

    final cityLower = (fallbackCity ?? '').trim().toLowerCase();
    if (cityLower.contains('islamabad')) return 'Islamabad Capital Territory';
    if (cityLower.contains('karachi') || cityLower.contains('hyderabad') || cityLower.contains('sukkur')) return 'Sindh';
    if (cityLower.contains('peshawar') || cityLower.contains('abbottabad') || cityLower.contains('mardan')) {
      return 'Khyber Pakhtunkhwa';
    }
    if (cityLower.contains('quetta') || cityLower.contains('gwadar')) return 'Balochistan';
    if (cityLower.contains('gilgit') || cityLower.contains('skardu')) return 'Gilgit-Baltistan';
    if (cityLower.contains('muzaffarabad') || cityLower.contains('mirpur')) return 'Azad Kashmir';

    return rawProvince.trim().isNotEmpty ? rawProvince.trim() : 'Punjab';
  }
}

/// Structured geocoding match returned by [ArmSphereGeocodingService].
class ArmSphereGeocodeResult {
  final double latitude;
  final double longitude;
  final String name;
  final String city;
  final String province;
  final String country;
  final String formattedAddress;

  const ArmSphereGeocodeResult({
    required this.latitude,
    required this.longitude,
    required this.name,
    required this.city,
    required this.province,
    required this.country,
    required this.formattedAddress,
  });
}

/// Forward & reverse geocoding helper using Geoapify primary and Photon / native
/// `geocoding` fallbacks so place search and coordinate resolution stay resilient
/// without billing dependencies.
class ArmSphereGeocodingService {
  ArmSphereGeocodingService._();

  static final Dio _http = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 6),
      headers: const {
        'Accept': 'application/json',
        'User-Agent': 'ArmSphereMobile/1.0',
      },
    ),
  );

  /// Forward search: queries Geoapify Autocomplete first, falling back to Photon OSM.
  static Future<List<ArmSphereGeocodeResult>> searchPlaces(
    String query, {
    int limit = 6,
    CancelToken? cancelToken,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const <ArmSphereGeocodeResult>[];

    // 1. Primary: Geoapify Autocomplete API
    try {
      final response = await _http.get(
        'https://api.geoapify.com/v1/geocode/autocomplete',
        queryParameters: {
          'text': trimmed,
          'limit': limit,
          'format': 'json',
          'apiKey': ArmSphereMapConfig.geoapifyApiKey,
        },
        cancelToken: cancelToken,
      );
      if (response.statusCode == 200 && response.data is Map) {
        final rawResults = (response.data as Map)['results'];
        if (rawResults is List && rawResults.isNotEmpty) {
          return rawResults
              .whereType<Map>()
              .map(_parseGeoapifyResult)
              .whereType<ArmSphereGeocodeResult>()
              .toList();
        }
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) rethrow;
    } catch (_) {
      // Fall through to Photon OSM fallback
    }

    // 2. Fallback: Photon (OpenStreetMap, zero-key)
    try {
      final response = await _http.get(
        'https://photon.komoot.io/api/',
        queryParameters: {
          'q': trimmed,
          'limit': limit,
        },
        cancelToken: cancelToken,
      );
      if (response.statusCode == 200 && response.data is Map) {
        final features = (response.data as Map)['features'];
        if (features is List) {
          return features
              .whereType<Map>()
              .map(_parsePhotonFeature)
              .whereType<ArmSphereGeocodeResult>()
              .toList();
        }
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) rethrow;
    } catch (_) {
      // Fall through cleanly
    }

    return const <ArmSphereGeocodeResult>[];
  }

  /// Reverse geocode coordinates: queries Geoapify Reverse first, falling back to
  /// the native platform `geocoding` plugin.
  static Future<ArmSphereGeocodeResult?> reverseGeocode(
    double latitude,
    double longitude, {
    CancelToken? cancelToken,
  }) async {
    // 1. Primary: Geoapify Reverse Geocoding
    try {
      final response = await _http.get(
        'https://api.geoapify.com/v1/geocode/reverse',
        queryParameters: {
          'lat': latitude,
          'lon': longitude,
          'format': 'json',
          'apiKey': ArmSphereMapConfig.geoapifyApiKey,
        },
        cancelToken: cancelToken,
      );
      if (response.statusCode == 200 && response.data is Map) {
        final rawResults = (response.data as Map)['results'];
        if (rawResults is List && rawResults.isNotEmpty && rawResults.first is Map) {
          final parsed = _parseGeoapifyResult(rawResults.first as Map);
          if (parsed != null) return parsed;
        }
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) rethrow;
    } catch (_) {
      // Fall through to native geocoding plugin
    }

    // 2. Fallback: Native `geocoding` package
    try {
      final placemarks = await geo.placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final city = (p.locality?.trim().isNotEmpty == true
                ? p.locality!
                : (p.subAdministrativeArea?.trim().isNotEmpty == true
                    ? p.subAdministrativeArea!
                    : (p.administrativeArea ?? '')))
            .trim();
        final rawProv = (p.administrativeArea ?? '').trim();
        final province = ArmSphereMapConfig.normalizeProvince(rawProv, fallbackCity: city);
        final country = (p.country ?? '').trim();
        final parts = <String>[
          if (p.street != null && p.street!.trim().isNotEmpty) p.street!.trim(),
          if (p.subLocality != null && p.subLocality!.trim().isNotEmpty) p.subLocality!.trim(),
          if (city.isNotEmpty) city,
          if (province.isNotEmpty && province != city) province,
          if (country.isNotEmpty) country,
        ];
        final formatted = parts.isNotEmpty
            ? parts.join(', ')
            : '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
        return ArmSphereGeocodeResult(
          latitude: latitude,
          longitude: longitude,
          name: (p.name ?? city).trim(),
          city: city,
          province: province,
          country: country,
          formattedAddress: formatted,
        );
      }
    } catch (_) {
      // Return null so caller falls back to coordinate display
    }

    return null;
  }

  static ArmSphereGeocodeResult? _parseGeoapifyResult(Map raw) {
    final lat = (raw['lat'] as num?)?.toDouble();
    final lon = (raw['lon'] as num?)?.toDouble();
    if (lat == null || lon == null) return null;

    final city = (raw['city'] ??
            raw['town'] ??
            raw['village'] ??
            raw['county'] ??
            raw['state_district'] ??
            '')
        .toString()
        .trim();
    final rawState = (raw['state'] ?? raw['region'] ?? '').toString().trim();
    final province = ArmSphereMapConfig.normalizeProvince(rawState, fallbackCity: city);
    final country = (raw['country'] ?? '').toString().trim();
    final name = (raw['name'] ?? raw['address_line1'] ?? city).toString().trim();
    final formatted = (raw['formatted'] ??
            [
              if (name.isNotEmpty) name,
              if (city.isNotEmpty && !name.contains(city)) city,
              if (province.isNotEmpty) province,
              if (country.isNotEmpty) country,
            ].join(', '))
        .toString()
        .trim();

    return ArmSphereGeocodeResult(
      latitude: lat,
      longitude: lon,
      name: name.isNotEmpty ? name : formatted,
      city: city,
      province: province,
      country: country,
      formattedAddress: formatted.isNotEmpty
          ? formatted
          : '${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}',
    );
  }

  static ArmSphereGeocodeResult? _parsePhotonFeature(Map feature) {
    final geometry = feature['geometry'];
    final props = feature['properties'];
    if (geometry is! Map || props is! Map) return null;
    final coords = geometry['coordinates'];
    if (coords is! List || coords.length < 2) return null;

    final lon = (coords[0] as num?)?.toDouble();
    final lat = (coords[1] as num?)?.toDouble();
    if (lat == null || lon == null) return null;

    final name = (props['name'] ?? props['street'] ?? '').toString().trim();
    final city = (props['city'] ?? props['town'] ?? props['county'] ?? '').toString().trim();
    final rawState = (props['state'] ?? '').toString().trim();
    final province = ArmSphereMapConfig.normalizeProvince(rawState, fallbackCity: city);
    final country = (props['country'] ?? '').toString().trim();

    final parts = <String>[
      if (name.isNotEmpty) name,
      if (props['street'] != null &&
          props['street'].toString().trim().isNotEmpty &&
          props['street'].toString().trim() != name)
        props['street'].toString().trim(),
      if (city.isNotEmpty && city != name) city,
      if (province.isNotEmpty && province != city) province,
      if (country.isNotEmpty) country,
    ];
    final formatted = parts.isNotEmpty
        ? parts.join(', ')
        : '${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}';

    return ArmSphereGeocodeResult(
      latitude: lat,
      longitude: lon,
      name: name.isNotEmpty ? name : (city.isNotEmpty ? city : formatted),
      city: city,
      province: province,
      country: country,
      formattedAddress: formatted,
    );
  }
}
