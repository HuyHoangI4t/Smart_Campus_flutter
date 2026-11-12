import 'dart:async';
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import '../constants/api_endpoints.dart';
import '../utils/dijkstra.dart';

class ExternalRoadResult {
  final List<LatLng> coordinates;
  final double distanceMeters;
  final int durationSeconds;

  const ExternalRoadResult({
    required this.coordinates,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  /// Dự phòng thông minh theo trục đường bao quanh trường (Lê Duẩn / Y Wang)
  /// Tuyệt đối không vẽ đường chim bay cắt qua nhà dân
  static ExternalRoadResult fromPerimeterFallback(LatLng start, LatLng end) {
    final fb = CampusDijkstraRouter.buildPerimeterRoadFallback(start, end);
    return ExternalRoadResult(
      coordinates: fb.coordinates,
      distanceMeters: fb.distanceMeters,
      durationSeconds: fb.estimatedWalkingMinutes * 60,
    );
  }

  static ExternalRoadResult directLine(LatLng start, LatLng end) {
    return fromPerimeterFallback(start, end);
  }
}

class _CachedRoadEntry {
  final ExternalRoadResult result;
  final DateTime timestamp;
  _CachedRoadEntry(this.result, this.timestamp);
}

class ExternalRoutingService {
  final Dio _dio;
  static final Map<String, _CachedRoadEntry> _roadCache = {};

  ExternalRoutingService(this._dio);

  /// Lấy tuyến đường đi bộ thực tế theo đường phố (Google Maps style)
  /// Đua song song 3 nguồn (Backend Proxy, OSM.de, Project OSRM) để trả về cực nhanh (< 600ms)
  Future<ExternalRoadResult> getWalkingRoadRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    // 0. Cache trong bộ nhớ làm tròn 4 chữ số (~11m) - Trả kết quả tức thì 0ms
    final cacheKey =
        '${start.latitude.toStringAsFixed(4)},${start.longitude.toStringAsFixed(4)}_${end.latitude.toStringAsFixed(4)},${end.longitude.toStringAsFixed(4)}';
    final cached = _roadCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.timestamp).inMinutes < 30) {
      return cached.result;
    }

    final queryList = <Future<ExternalRoadResult>>[];

    // Nguồn 1: Backend proxy (/api/campus/road-route - đua 4 máy chủ OSRM)
    queryList.add(_fetchFromBackendProxy(start, end));

    // Nguồn 2: OpenStreetMap.de Foot Router
    queryList.add(_fetchFromOsmDe(start, end));

    // Nguồn 3: Project OSRM Foot Router
    queryList.add(_fetchFromProjectOsrm(start, end));

    // Nguồn 4: OpenStreetMap.de Driving Router (phủ sóng 100% đường phố Buôn Ma Thuột)
    queryList.add(_fetchFromOsmCar(start, end));

    // Nguồn 5: Project OSRM Driving Router
    queryList.add(_fetchFromProjectOsrmCar(start, end));

    try {
      final fastest = await _raceValidRoute(queryList, timeout: const Duration(milliseconds: 4000));
      if (fastest != null && fastest.coordinates.length >= 2) {
        _roadCache[cacheKey] = _CachedRoadEntry(fastest, DateTime.now());
        return fastest;
      }
    } catch (_) {}

    // Fallback nếu không có kết nối mạng: dùng trục đường Lê Duẩn / Y Wang thay vì chim bay
    return ExternalRoadResult.fromPerimeterFallback(start, end);
  }

  Future<ExternalRoadResult?> _raceValidRoute(
    List<Future<ExternalRoadResult>> futures, {
    required Duration timeout,
  }) {
    final completer = Completer<ExternalRoadResult?>();
    int remaining = futures.length;

    for (final f in futures) {
      f.then((res) {
        if (res.coordinates.length >= 2 && !completer.isCompleted) {
          completer.complete(res);
        } else {
          remaining--;
          if (remaining == 0 && !completer.isCompleted) {
            completer.complete(null);
          }
        }
      }).catchError((_) {
        remaining--;
        if (remaining == 0 && !completer.isCompleted) {
          completer.complete(null);
        }
      });
    }

    return completer.future.timeout(
      timeout,
      onTimeout: () => null,
    );
  }

  Future<ExternalRoadResult> _fetchFromBackendProxy(LatLng start, LatLng end) async {
    final res = await _dio.get(
      ApiEndpoints.campusRoadRoute,
      queryParameters: {
        'startLat': start.latitude,
        'startLng': start.longitude,
        'endLat': end.latitude,
        'endLng': end.longitude,
      },
      options: Options(
        sendTimeout: const Duration(milliseconds: 2500),
        receiveTimeout: const Duration(milliseconds: 2500),
      ),
    );
    if (res.statusCode == 200 && res.data != null) {
      final data = res.data;
      if (data['success'] == true && data['data'] != null) {
        final info = data['data'];
        final distance = (info['distanceMeters'] as num?)?.toDouble() ?? 0.0;
        final duration = (info['durationSeconds'] as num?)?.toInt() ?? 0;
        final rawCoords = info['coordinates'] as List?;
        if (rawCoords != null && rawCoords.isNotEmpty) {
          final coords = <LatLng>[];
          for (final item in rawCoords) {
            if (item is List && item.length >= 2) {
              final lat = (item[0] as num).toDouble();
              final lng = (item[1] as num).toDouble();
              coords.add(LatLng(lat, lng));
            }
          }
          if (coords.length > 2) {
            return ExternalRoadResult(
              coordinates: coords,
              distanceMeters: distance,
              durationSeconds: duration,
            );
          }
        }
      }
    }
    throw Exception('Invalid backend route');
  }

  Future<ExternalRoadResult> _fetchFromOsmDe(LatLng start, LatLng end) async {
    final client = Dio(BaseOptions(
      connectTimeout: const Duration(milliseconds: 2500),
      receiveTimeout: const Duration(milliseconds: 2500),
      headers: {'User-Agent': 'SmartCampus/1.0'},
    ));
    final url =
        'https://routing.openstreetmap.de/routed-foot/route/v1/foot/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';
    final res = await client.get(url);
    return _parseOsrmGeoJson(res.data);
  }

  Future<ExternalRoadResult> _fetchFromProjectOsrm(LatLng start, LatLng end) async {
    final client = Dio(BaseOptions(
      connectTimeout: const Duration(milliseconds: 2500),
      receiveTimeout: const Duration(milliseconds: 2500),
      headers: {'User-Agent': 'SmartCampus/1.0'},
    ));
    final url =
        'https://router.project-osrm.org/route/v1/foot/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';
    final res = await client.get(url);
    return _parseOsrmGeoJson(res.data);
  }

  Future<ExternalRoadResult> _fetchFromOsmCar(LatLng start, LatLng end) async {
    final client = Dio(BaseOptions(
      connectTimeout: const Duration(milliseconds: 2500),
      receiveTimeout: const Duration(milliseconds: 2500),
      headers: {'User-Agent': 'SmartCampus/1.0'},
    ));
    final url =
        'https://routing.openstreetmap.de/routed-car/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';
    final res = await client.get(url);
    return _parseOsrmGeoJson(res.data);
  }

  Future<ExternalRoadResult> _fetchFromProjectOsrmCar(LatLng start, LatLng end) async {
    final client = Dio(BaseOptions(
      connectTimeout: const Duration(milliseconds: 2500),
      receiveTimeout: const Duration(milliseconds: 2500),
      headers: {'User-Agent': 'SmartCampus/1.0'},
    ));
    final url =
        'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';
    final res = await client.get(url);
    return _parseOsrmGeoJson(res.data);
  }

  ExternalRoadResult _parseOsrmGeoJson(dynamic data) {
    if (data is Map<String, dynamic> &&
        data['code'] == 'Ok' &&
        data['routes'] is List &&
        (data['routes'] as List).isNotEmpty) {
      final best = data['routes'][0];
      final distance = (best['distance'] as num?)?.toDouble() ?? 0.0;
      final duration = (best['duration'] as num?)?.toInt() ?? 0;
      final geometry = best['geometry'];

      if (geometry is Map<String, dynamic> && geometry['coordinates'] is List) {
        final rawCoords = geometry['coordinates'] as List;
        final coords = <LatLng>[];

        for (final item in rawCoords) {
          if (item is List && item.length >= 2) {
            final lng = (item[0] as num).toDouble();
            final lat = (item[1] as num).toDouble();
            coords.add(LatLng(lat, lng));
          }
        }

        if (coords.length >= 2) {
          return ExternalRoadResult(
            coordinates: coords,
            distanceMeters: distance,
            durationSeconds: duration,
          );
        }
      }
    }
    throw Exception('Invalid OSRM GeoJSON');
  }
}
