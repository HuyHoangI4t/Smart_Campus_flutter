import 'dart:math';

/// Tính khoảng cách trắc địa giữa hai điểm tọa độ cầu (mét) theo công thức Haversine
double calculateHaversineDistance(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const double earthRadiusMeters = 6371000.0;

  final double dLat = _degToRad(lat2 - lat1);
  final double dLon = _degToRad(lon2 - lon1);

  final double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_degToRad(lat1)) *
          cos(_degToRad(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2);

  final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return earthRadiusMeters * c;
}

double _degToRad(double deg) {
  return deg * (pi / 180.0);
}

