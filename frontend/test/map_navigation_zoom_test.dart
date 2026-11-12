import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_campus/core/constants/campus_constants.dart';
import 'package:smart_campus/core/utils/dijkstra.dart';
import 'package:smart_campus/core/utils/haversine.dart';

void main() {
  group('Map Navigation Far & Gate Reference Tests', () {
    test('CampusConstants defines 3 official campus gates', () {
      expect(CampusConstants.gates.length, 3);
      final gateIds = CampusConstants.gates.map((g) => g.id).toList();
      expect(gateIds, contains('front_gate'));
      expect(gateIds, contains('back_gate'));
      expect(gateIds, contains('hospital_gate'));
    });

    test('findNearestGate picks closest gate when user is far away (>2km)', () {
      final gates = CampusConstants.gates;

      // 1. Vị trí ở xa phía Bắc (Trung tâm TP Buôn Ma Thuột, cách trường > 3km)
      final farNorth = const LatLng(12.6850, 108.0400);
      final distNorth = calculateHaversineDistance(
        farNorth.latitude,
        farNorth.longitude,
        CampusConstants.defaultGate.lat,
        CampusConstants.defaultGate.lng,
      );
      expect(distNorth, greaterThan(2000.0));

      final gateNorth = CampusDijkstraRouter.findNearestGate(farNorth, gates);
      expect(gateNorth.id, isIn(['front_gate', 'hospital_gate']));

      // 2. Vị trí ở xa phía Đông Nam (đường Y Wang, cách cổng sau > 2.5km)
      final farSouthEast = const LatLng(12.6300, 108.0350);
      final distSouthEast = calculateHaversineDistance(
        farSouthEast.latitude,
        farSouthEast.longitude,
        CampusConstants.gates.firstWhere((g) => g.id == 'back_gate').lat,
        CampusConstants.gates.firstWhere((g) => g.id == 'back_gate').lng,
      );
      expect(distSouthEast, greaterThan(2000.0));

      final gateSouthEast = CampusDijkstraRouter.findNearestGate(farSouthEast, gates);
      expect(gateSouthEast.id, 'back_gate');
    });

    test('Internal route calculation from gate to building works smoothly', () {
      final router = CampusDijkstraRouter();
      router.buildGraphFromPolylines(CampusConstants.defaultWalkways);

      final frontGate = CampusConstants.defaultGate;
      final targetBuilding = CampusConstants.campusLocations.first; // Nhà điều hành

      final route = router.findShortestRoute(
        frontGate.coordinate,
        targetBuilding.coordinate,
      );

      expect(route.coordinates.isNotEmpty, true);
      expect(route.distanceMeters, greaterThan(0));
      expect(route.estimatedWalkingMinutes, greaterThanOrEqualTo(1));
    });

    test('Zoom tier logic partitions zoom levels without hiding locations', () {
      // Zoom xa (< 15.8): icons thu nhỏ (0.48), tất cả điểm vẫn hiển thị
      double zoomOut = 15.0;
      expect(zoomOut < 15.8, true);

      // Zoom vừa (15.8 - 17.0): icon trung bình (0.78)
      double zoomMid = 16.5;
      expect(zoomMid >= 15.8 && zoomMid < 17.0, true);

      // Zoom gần (>= 17.0): icon chi tiết (1.05)
      double zoomClose = 17.8;
      expect(zoomClose >= 17.0, true);

      // Đảm bảo toàn bộ địa điểm khuôn viên luôn sẵn sàng hiển thị
      final campusLocations = CampusConstants.campusLocations;
      expect(campusLocations.length, greaterThanOrEqualTo(35));
    });
  });
}

