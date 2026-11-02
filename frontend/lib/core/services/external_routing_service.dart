import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../constants/api_endpoints.dart';
import '../utils/haversine.dart';

class ExternalRoadResult {
  final List<LatLng> coordinates;
  final double distanceMeters;
  final int durationSeconds;

  const ExternalRoadResult({
    required this.coordinates,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  static ExternalRoadResult directLine(LatLng start, LatLng end) {
    final dist = calculateHaversineDistance(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
    final seconds = (dist / 1.25).round(); // ~4.5 km/h walking speed
    return ExternalRoadResult(
      coordinates: [start, end],
      distanceMeters: dist,
      durationSeconds: seconds,
    );
  }
}

class ExternalRoutingService {
  final Dio _dio;

  ExternalRoutingService(this._dio);

  /// Lay tuyen duong di bo thuc te theo duong pho (Google Maps style qua OSRM)
  Future<ExternalRoadResult> getWalkingRoadRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    // 1. Uu tien goi truc tiep OSRM Foot API voi timeout 3.5s
    try {
      final osrmUrl =
          'https://router.project-osrm.org/route/v1/foot/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';

      final response = await _dio.get(
        osrmUrl,
        options: Options(
          sendTimeout: const Duration(milliseconds: 3500),
          receiveTimeout: const Duration(milliseconds: 3500),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic> &&
            data['code'] == 'Ok' &&
            data['routes'] is List &&
            (data['routes'] as List).isNotEmpty) {
          final best = data['routes'][0];
          final distance = (best['distance'] as num?)?.toDouble() ?? 0.0;
          final duration = (best['duration'] as num?)?.toInt() ?? 0;
          final geometry = best['geometry'];

          if (geometry is Map<String, dynamic> &&
              geometry['coordinates'] is List) {
            final rawCoords = geometry['coordinates'] as List;
            final coords = <LatLng>[];

            for (final item in rawCoords) {
              if (item is List && item.length >= 2) {
                final lng = (item[0] as num).toDouble();
                final lat = (item[1] as num).toDouble();
                coords.add(LatLng(lat, lng));
              }
            }

            if (coords.isNotEmpty) {
              return ExternalRoadResult(
                coordinates: coords,
                distanceMeters: distance,
                durationSeconds: duration,
              );
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('OSRM direct route error: $e, falling back to backend proxy...');
      }
    }

    // 2. Fallback sang Backend Proxy (/api/campus/road-route)
    try {
      final proxyResponse = await _dio.get(
        ApiEndpoints.campusRoadRoute,
        queryParameters: {
          'startLat': start.latitude,
          'startLng': start.longitude,
          'endLat': end.latitude,
          'endLng': end.longitude,
        },
        options: Options(
          sendTimeout: const Duration(milliseconds: 3500),
          receiveTimeout: const Duration(milliseconds: 3500),
        ),
      );

      if (proxyResponse.statusCode == 200 && proxyResponse.data != null) {
        final data = proxyResponse.data;
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
            if (coords.isNotEmpty) {
              return ExternalRoadResult(
                coordinates: coords,
                distanceMeters: distance,
                durationSeconds: duration,
              );
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Backend proxy road route error: $e');
      }
    }

    // 3. Fallback cuoi cung: Duong thang ket noi start -> end
    return ExternalRoadResult.directLine(start, end);
  }
}
