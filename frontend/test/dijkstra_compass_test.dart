import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_campus/core/utils/compass_smoother.dart';
import 'package:smart_campus/core/utils/dijkstra.dart';

void main() {
  group('CampusDijkstraRouter Tests', () {
    late CampusDijkstraRouter router;

    setUp(() {
      router = CampusDijkstraRouter();
    });

    test('buildGraphFromPolylines builds connected graph and finds path', () {
      final polylines = [
        [
          const LatLng(10.0, 10.0),
          const LatLng(10.001, 10.001),
          const LatLng(10.002, 10.002),
        ]
      ];

      router.buildGraphFromPolylines(polylines);
      expect(router.nodeCoordinates.length, 3);

      final result = router.findShortestRoute(
        const LatLng(10.0, 10.0),
        const LatLng(10.002, 10.002),
      );

      expect(result.coordinates.isNotEmpty, true);
      expect(result.distanceMeters, greaterThan(0));
    });

    test('buildGraphFromApiPaths parses coordinates and calculates route', () {
      final apiPaths = [
        {
          'id': 1,
          'coordinates': [
            [12.6515, 108.0238],
            [12.6519, 108.0244],
            [12.6525, 108.0250],
          ],
          'node_count': 3,
          'distance_meters': 180.0,
        }
      ];

      router.buildGraphFromApiPaths(apiPaths);
      expect(router.nodeCoordinates.length, 3);

      final result = router.findShortestRoute(
        const LatLng(12.6515, 108.0238),
        const LatLng(12.6525, 108.0250),
      );

      expect(result.coordinates.length, greaterThanOrEqualTo(3));
      expect(result.distanceMeters, greaterThan(0));
      expect(result.estimatedWalkingMinutes, greaterThanOrEqualTo(1));
    });
  });

  group('CompassSmoother Tests', () {
    test('filters heading changes below threshold', () {
      final emitted = <double>[];
      final smoother = CompassSmoother(
        minDegreeChange: 8.0,
        throttleMs: 100,
        onSmoothedHeading: (h) => emitted.add(h),
      );

      smoother.update(5.0); // first update, diff from 0 is 5 < 8 -> ignored
      expect(emitted.isEmpty, true);

      smoother.update(10.0); // diff from 0 is 10 >= 8 -> emitted
      expect(emitted.length, 1);
      expect(emitted.first, 10.0);

      smoother.update(14.0); // diff from 10 is 4 < 8 -> ignored
      expect(emitted.length, 1);

      smoother.dispose();
    });
  });
}
