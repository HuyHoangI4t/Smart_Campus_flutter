import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_campus/core/constants/campus_constants.dart';
import 'package:smart_campus/core/services/external_routing_service.dart';
import 'package:smart_campus/core/utils/dijkstra.dart';

void main() {
  group('LTDDDNT Map Logic Porting & Hybrid Routing Tests', () {
    late CampusDijkstraRouter router;

    setUp(() {
      router = CampusDijkstraRouter();
      router.buildGraphFromPolylines(CampusConstants.defaultWalkways);
    });

    test('buildPerimeterRoadFallback picks Le Duan road when coordinates are on West side', () {
      final start = const LatLng(12.6480, 108.0221); // Le Duan
      final target = const LatLng(12.6515, 108.0238); // Front Gate

      final result = CampusDijkstraRouter.buildPerimeterRoadFallback(start, target);

      // Must follow the perimeter road points, NOT just 2 straight points
      expect(result.coordinates.length, greaterThan(2));
      expect(result.distanceMeters, greaterThan(0));
      expect(result.isHybrid, true);

      // Verify that coordinates contain Le Hospital gate or intermediate road points
      final hasIntermediateRoadPoint = result.coordinates.any(
        (p) => (p.latitude - 108.022990).abs() < 0.0001 || (p.latitude - 12.64936).abs() < 0.0001,
      );
      expect(hasIntermediateRoadPoint, true);
    });

    test('buildPerimeterRoadFallback picks Y Wang road when coordinates are on East side', () {
      final start = const LatLng(12.6465, 108.0265); // Y Wang side
      final target = const LatLng(12.6483, 108.0280); // Back Gate

      final result = CampusDijkstraRouter.buildPerimeterRoadFallback(start, target);

      expect(result.coordinates.length, greaterThan(2));
      expect(result.distanceMeters, greaterThan(0));
      expect(result.isHybrid, true);
    });

    test('stitchPathCoordinates removes consecutive duplicates (< 0.5m)', () {
      final p1 = const LatLng(12.6515, 108.0238);
      final p2 = const LatLng(12.6515, 108.0238); // Exact duplicate
      final p3 = const LatLng(12.6520, 108.0245);

      final stitched = CampusDijkstraRouter.stitchPathCoordinates([
        [p1, p2],
        [p2, p3],
      ]);

      expect(stitched.length, 2);
      expect(stitched.first, p1);
      expect(stitched.last, p3);
    });

    test('Check what getBestGate returns for various locations', () {
      final gates = CampusConstants.gates;

      // 1. User on Le Duan coming from South (e.g. Mai Thi Luu / Le Duan intersection)
      final userLeDuanSouth = const LatLng(12.6460, 108.0210);
      final destNha7 = const LatLng(12.65219714, 108.02494019); // Nha hoc so 7
      final gate1 = CampusDijkstraRouter.getBestGate(
        origin: userLeDuanSouth,
        destination: destNha7,
        isEntering: true,
        availableGates: gates,
      );
      expect(gate1.id, 'front_gate');

      // 2. User on Y Wang
      final userYWang = const LatLng(12.6470, 108.0270);
      final gate2 = CampusDijkstraRouter.getBestGate(
        origin: userYWang,
        destination: destNha7,
        isEntering: true,
        availableGates: gates,
      );
      expect(gate2.id, 'back_gate');

      // 3. User on Le Duan North (e.g. from center of Buon Ma Thuot coming down Le Duan)
      final userLeDuanNorth = const LatLng(12.6550, 108.0260);
      final gate3 = CampusDijkstraRouter.getBestGate(
        origin: userLeDuanNorth,
        destination: destNha7,
        isEntering: true,
        availableGates: gates,
      );
      expect(gate3.id, 'front_gate');

      // 4. User coming from South on Le Duan going to Nha hoc so 2:
      // Since hospital_gate is on Le Duan to the south, it is the optimal entrance gate on Le Duan
      final destNha2 = const LatLng(12.65079877, 108.02465772);
      final gate4 = CampusDijkstraRouter.getBestGate(
        origin: userLeDuanSouth,
        destination: destNha2,
        isEntering: true,
        availableGates: gates,
      );
      expect(gate4.id, 'hospital_gate');

      // 4b. User coming from North on Le Duan going to Nha hoc so 2:
      // front_gate is on Le Duan to the north, so it is the optimal entrance gate from the north
      final gate4b = CampusDijkstraRouter.getBestGate(
        origin: userLeDuanNorth,
        destination: destNha2,
        isEntering: true,
        availableGates: gates,
      );
      expect(gate4b.id, 'front_gate');

      // 5. User coming from North on Le Duan going to Toa Hieu Bo
      final destHieuBo = const LatLng(12.65099693, 108.02452788);
      final gate5 = CampusDijkstraRouter.getBestGate(
        origin: userLeDuanNorth,
        destination: destHieuBo,
        isEntering: true,
        availableGates: gates,
      );
      expect(gate5.id, 'front_gate');

      // 7. Explicit user gate overrides
      final gateExplicitHospital = CampusDijkstraRouter.getBestGate(
        origin: userLeDuanNorth,
        destination: destNha7,
        isEntering: true,
        preferredGateId: 'hospital_gate',
        availableGates: gates,
      );
      expect(gateExplicitHospital.id, 'hospital_gate');

      final gateExplicitBack = CampusDijkstraRouter.getBestGate(
        origin: userLeDuanSouth,
        destination: destNha2,
        isEntering: true,
        preferredGateId: 'back_gate',
        availableGates: gates,
      );
      expect(gateExplicitBack.id, 'back_gate');

      final gateExplicitFront = CampusDijkstraRouter.getBestGate(
        origin: userYWang,
        destination: destNha7,
        isEntering: true,
        preferredGateId: 'front_gate',
        availableGates: gates,
      );
      expect(gateExplicitFront.id, 'front_gate');

      // 8. Destination is Hospital (medical)
      final destHospital = const LatLng(12.65041159, 108.0230479);
      final gateMedical = CampusDijkstraRouter.getBestGate(
        origin: userLeDuanSouth,
        destination: destHospital,
        isEntering: true,
        isMedicalDestination: true,
        availableGates: gates,
      );
      expect(gateMedical.id, 'hospital_gate');
    });

    test('findHybridRoute integrates 3-point transition (outsidePoint, gatePoint, insidePoint)', () {
      final startOutside = const LatLng(12.6490, 108.0225); // On Le Duan outside
      final destination = CampusConstants.campusLocations.first.coordinate; // inside campus

      final hybrid = router.findHybridRoute(
        start: startOutside,
        destination: destination,
        availableGates: CampusConstants.gates,
      );

      expect(hybrid.coordinates.isNotEmpty, true);
      expect(hybrid.isHybrid, true);
      expect(hybrid.viaGateName, contains('Cổng'));
      // Must not be direct 2-point line
      expect(hybrid.coordinates.length, greaterThan(5));
    });

    test('isInsideCampus correctly identifies inside vs outside campus points', () {
      // 1. LTDDDNT default fallback origin (outside Front Gate on Le Duan street)
      final defaultOrigin = const LatLng(12.65138, 108.02360);
      expect(CampusDijkstraRouter.isInsideCampus(defaultOrigin), false);

      // 2. Point on Le Duan outside Hospital gate
      final leDuanPoint = const LatLng(12.6490, 108.0225);
      expect(CampusDijkstraRouter.isInsideCampus(leDuanPoint), false);

      // 3. Point on Y Wang outside Back gate
      final yWangPoint = const LatLng(12.6470, 108.0270);
      expect(CampusDijkstraRouter.isInsideCampus(yWangPoint), false);

      // 4. Inside campus locations
      final toaHieuBo = const LatLng(12.65099693, 108.02452788);
      expect(CampusDijkstraRouter.isInsideCampus(toaHieuBo), true);

      final nhaHocSo2 = const LatLng(12.65079877, 108.02465772);
      expect(CampusDijkstraRouter.isInsideCampus(nhaHocSo2), true);

      final ktx4 = const LatLng(12.64888412, 108.02826763);
      expect(CampusDijkstraRouter.isInsideCampus(ktx4), true);

      // 5. Check all gate outside points (must be outside boundary) & inside points (must be inside)
      for (final gate in CampusConstants.gates) {
        expect(
          CampusDijkstraRouter.isInsideCampus(gate.outsideCoordinate),
          false,
          reason: 'Gate ${gate.id} outsidePoint should be outside campus',
        );
        expect(
          CampusDijkstraRouter.isInsideCampus(gate.insideCoordinate),
          true,
          reason: 'Gate ${gate.id} insidePoint should be inside campus',
        );
      }
    });

    test('ExternalRoadResult.directLine / fromPerimeterFallback follows street curve', () {
      final start = const LatLng(12.6900, 108.0221);
      final end = const LatLng(12.6515, 108.0238);

      final result = ExternalRoadResult.directLine(start, end);
      expect(result.coordinates.length, greaterThan(2));
      expect(result.distanceMeters, greaterThan(0));
    });
  });
}
