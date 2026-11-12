import '../constants/campus_constants.dart';
import '../services/external_routing_service.dart';
import 'package:latlong2/latlong.dart';
import 'haversine.dart';

class DijkstraEdge {
  final String target;
  final double weight;
  final LatLng coordinate;

  const DijkstraEdge({
    required this.target,
    required this.weight,
    required this.coordinate,
  });
}

class DijkstraResult {
  final List<LatLng> coordinates;
  final double distanceMeters;
  final int estimatedWalkingMinutes;
  final bool isHybrid;
  final String? viaGateName;
  final CampusGate? gate;

  const DijkstraResult({
    required this.coordinates,
    required this.distanceMeters,
    required this.estimatedWalkingMinutes,
    this.isHybrid = false,
    this.viaGateName,
    this.gate,
  });

  static const empty = DijkstraResult(
    coordinates: [],
    distanceMeters: 0,
    estimatedWalkingMinutes: 0,
    isHybrid: false,
    viaGateName: null,
    gate: null,
  );
}

/// Min-heap (binary heap) - O(log n) insert/extract
class _MinHeap {
  final List<_HeapEntry> _data = [];

  bool get isEmpty => _data.isEmpty;

  void insert(String nodeId, double distance) {
    _data.add(_HeapEntry(nodeId, distance));
    _siftUp(_data.length - 1);
  }

  _HeapEntry extractMin() {
    final min = _data[0];
    final last = _data.removeLast();
    if (_data.isNotEmpty) {
      _data[0] = last;
      _siftDown(0);
    }
    return min;
  }

  void _siftUp(int i) {
    while (i > 0) {
      final parent = (i - 1) >> 1;
      if (_data[i].distance < _data[parent].distance) {
        final tmp = _data[i];
        _data[i] = _data[parent];
        _data[parent] = tmp;
        i = parent;
      } else {
        break;
      }
    }
  }

  void _siftDown(int i) {
    final n = _data.length;
    while (true) {
      int smallest = i;
      final left = 2 * i + 1;
      final right = 2 * i + 2;
      if (left < n && _data[left].distance < _data[smallest].distance) {
        smallest = left;
      }
      if (right < n && _data[right].distance < _data[smallest].distance) {
        smallest = right;
      }
      if (smallest == i) break;
      final tmp = _data[i];
      _data[i] = _data[smallest];
      _data[smallest] = tmp;
      i = smallest;
    }
  }
}

class _HeapEntry {
  final String nodeId;
  final double distance;
  _HeapEntry(this.nodeId, this.distance);
}

class CampusDijkstraRouter {
  final Map<String, List<DijkstraEdge>> graph = {};
  final Map<String, LatLng> nodeCoordinates = {};

  CampusDijkstraRouter();

  /// Nap do thi tu danh sach polyline tinh (offline fallback)
  void buildGraphFromPolylines(List<List<LatLng>> polylines) {
    graph.clear();
    nodeCoordinates.clear();

    for (final polyline in polylines) {
      for (int i = 0; i < polyline.length - 1; i++) {
        _addEdge(polyline[i], polyline[i + 1]);
      }
    }

    _autoConnectNearbyNodes(25.0);
  }

  /// Nap do thi tu API backend paths
  /// Backend returns coordinates as List of segments: [[[lat,lng],...], [[lat,lng],...]]
  void buildGraphFromApiPaths(List<Map<String, dynamic>> apiPaths) {
    graph.clear();
    nodeCoordinates.clear();

    for (final pathData in apiPaths) {
      final coords = pathData['coordinates'];
      if (coords is! List) continue;

      // Extract flat segments from coords (handles nested arrays)
      final segments = <List<List<num>>>[];
      _extractSegments(coords, segments);

      // Build edges from each segment
      for (final segment in segments) {
        for (int i = 0; i < segment.length - 1; i++) {
          final c1 = segment[i];
          final c2 = segment[i + 1];
          _addEdge(
            LatLng(c1[0].toDouble(), c1[1].toDouble()),
            LatLng(c2[0].toDouble(), c2[1].toDouble()),
          );
        }
      }
    }

    _autoConnectNearbyNodes(25.0);
  }

  /// Recursively extract flat polyline segments from nested coordinate arrays
  void _extractSegments(List<dynamic> arr, List<List<List<num>>> out) {
    if (arr.isEmpty) return;

    // Case 1: arr[0] is num -> single [lat, lng] point, not a segment
    if (arr[0] is num) return;

    // Case 2: arr[0] is List and arr[0][0] is num -> flat segment of [lat,lng] pairs
    if (arr[0] is List && (arr[0] as List).isNotEmpty && (arr[0] as List)[0] is num) {
      final segment = <List<num>>[];
      for (final pt in arr) {
        if (pt is List && pt.length >= 2 && pt[0] is num && pt[1] is num) {
          segment.add([pt[0] as num, pt[1] as num]);
        }
      }
      if (segment.length >= 2) {
        out.add(segment);
      }
      return;
    }

    // Case 3: deeper nesting -> recurse each sub-array
    for (final sub in arr) {
      if (sub is List) {
        _extractSegments(sub, out);
      }
    }
  }

  void _addEdge(LatLng p1, LatLng p2) {
    final id1 = _formatCoordKey(p1.latitude, p1.longitude);
    final id2 = _formatCoordKey(p2.latitude, p2.longitude);

    nodeCoordinates[id1] = p1;
    nodeCoordinates[id2] = p2;

    final dist = calculateHaversineDistance(
      p1.latitude, p1.longitude, p2.latitude, p2.longitude,
    );

    graph.putIfAbsent(id1, () => []).add(
      DijkstraEdge(target: id2, weight: dist, coordinate: p2),
    );
    graph.putIfAbsent(id2, () => []).add(
      DijkstraEdge(target: id1, weight: dist, coordinate: p1),
    );
  }

  void _autoConnectNearbyNodes(double thresholdMeters) {
    final nodesList = nodeCoordinates.entries.toList();
    for (int i = 0; i < nodesList.length; i++) {
      for (int j = i + 1; j < nodesList.length; j++) {
        final n1 = nodesList[i];
        final n2 = nodesList[j];
        final d = calculateHaversineDistance(
          n1.value.latitude, n1.value.longitude,
          n2.value.latitude, n2.value.longitude,
        );
        if (d <= thresholdMeters) {
          final neighbors1 = graph[n1.key] ?? [];
          if (!neighbors1.any((e) => e.target == n2.key)) {
            graph.putIfAbsent(n1.key, () => []).add(
              DijkstraEdge(target: n2.key, weight: d, coordinate: n2.value),
            );
            graph.putIfAbsent(n2.key, () => []).add(
              DijkstraEdge(target: n1.key, weight: d, coordinate: n1.value),
            );
          }
        }
      }
    }
  }

  String? snapToNearestNode(LatLng point, {double maxSnapMeters = 200.0}) {
    String? bestId;
    double bestDist = double.infinity;

    for (final entry in nodeCoordinates.entries) {
      final d = calculateHaversineDistance(
        point.latitude, point.longitude,
        entry.value.latitude, entry.value.longitude,
      );
      if (d < bestDist && d <= maxSnapMeters) {
        bestDist = d;
        bestId = entry.key;
      }
    }
    return bestId;
  }

  /// Dijkstra shortest path su dung binary heap
  DijkstraResult findShortestRoute(LatLng start, LatLng end) {
    final startNodeId = snapToNearestNode(start);
    final endNodeId = snapToNearestNode(end);

    if (startNodeId == null || endNodeId == null) {
      // Khong snap duoc vao graph -> khong ve duong (tranh chim bay)
      return DijkstraResult.empty;
    }

    final distances = <String, double>{};
    final previous = <String, String?>{};
    final visited = <String>{};
    final pq = _MinHeap();

    for (final node in nodeCoordinates.keys) {
      distances[node] = double.infinity;
    }

    distances[startNodeId] = 0;
    pq.insert(startNodeId, 0);

    while (!pq.isEmpty) {
      final current = pq.extractMin();
      final currNode = current.nodeId;

      if (visited.contains(currNode)) continue;
      visited.add(currNode);

      if (currNode == endNodeId) break;

      final neighbors = graph[currNode] ?? [];
      for (final edge in neighbors) {
        if (visited.contains(edge.target)) continue;

        final newDist = (distances[currNode] ?? 0) + edge.weight;
        if (newDist < (distances[edge.target] ?? double.infinity)) {
          distances[edge.target] = newDist;
          previous[edge.target] = currNode;
          pq.insert(edge.target, newDist);
        }
      }
    }

    final bool hasPath = visited.contains(endNodeId) &&
        distances[endNodeId] != null &&
        !distances[endNodeId]!.isInfinite;

    if (!hasPath) {
      // Khong tim duoc duong di -> tra empty (tranh ve duong chim bay)
      return DijkstraResult.empty;
    }

    final pathCoords = <LatLng>[];
    String? step = endNodeId;
    while (step != null) {
      final coord = nodeCoordinates[step];
      if (coord != null) pathCoords.insert(0, coord);
      step = previous[step];
    }

    if (pathCoords.isEmpty) {
      pathCoords.addAll([start, end]);
    } else {
      pathCoords.insert(0, start);
      pathCoords.add(end);
    }

    final rawMeters = distances[endNodeId] ??
        calculateHaversineDistance(
          start.latitude, start.longitude, end.latitude, end.longitude,
        );
    final safeMeters = rawMeters.isInfinite || rawMeters.isNaN
        ? calculateHaversineDistance(
            start.latitude, start.longitude, end.latitude, end.longitude,
          )
        : rawMeters;
    final walkingMinutes = (safeMeters / 75.0).ceil().clamp(1, 120);

    return DijkstraResult(
      coordinates: pathCoords,
      distanceMeters: safeMeters,
      estimatedWalkingMinutes: walkingMinutes,
    );
  }

  /// Kiểm tra toạ độ có nằm bên trong tường bao khuôn viên trường không
  /// Chuẩn 100% Ray-Casting từ isPointInCampus (E:\LTDDDNT\frontend\src\features\map\leafletHtml.ts dòng 1141-1153)
  static bool isInsideCampus(LatLng point) {
    final b = CampusConstants.campusBoundary;
    if (b.length < 3) return false;

    final x = point.latitude;
    final y = point.longitude;

    bool inside = false;
    for (int i = 0, j = b.length - 1; i < b.length; j = i++) {
      final xi = b[i].latitude, yi = b[i].longitude;
      final xj = b[j].latitude, yj = b[j].longitude;
      final intersect = ((yi > y) != (yj > y)) &&
          (x < (xj - xi) * (y - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  /// Tìm cổng trường tối ưu dựa trên cả quãng đường tiếp cận ngoại vi và đi bộ nội bộ (theo chuẩn LTDDDNT)
  static CampusGate getBestGate({
    required LatLng origin,
    required LatLng destination,
    required bool isEntering,
    String? preferredGateId,
    bool isMedicalDestination = false,
    required List<CampusGate> availableGates,
  }) {
    if (availableGates.isEmpty) return CampusConstants.defaultGate;

    // 1. Nếu người dùng đã chủ động chỉ định cổng (qua nút chọn cổng): tôn trọng 100%
    if (preferredGateId != null) {
      for (final g in availableGates) {
        if (g.id == preferredGateId) return g;
      }
    }

    // 2. Chế độ Tự động: Duyệt toàn bộ các cổng khả dụng
    // Có 2 cổng trên đường Lê Duẩn (Cổng trước & Cổng BV) và 1 cổng trên đường Y Wang (Cổng sau).
    // Chọn cổng có tổng quãng đường (dExt + dInt) ngắn nhất, chuẩn 100% LTDDDNT getBestGate.
    CampusGate bestGate = availableGates.first;
    double minEstDist = double.infinity;

    for (final g in availableGates) {
      final double dExt = isEntering
          ? calculateHaversineDistance(
              origin.latitude, origin.longitude,
              g.outsideCoordinate.latitude, g.outsideCoordinate.longitude,
            )
          : calculateHaversineDistance(
              g.outsideCoordinate.latitude, g.outsideCoordinate.longitude,
              destination.latitude, destination.longitude,
            );

      final double dInt = isEntering
          ? calculateHaversineDistance(
              g.insideCoordinate.latitude, g.insideCoordinate.longitude,
              destination.latitude, destination.longitude,
            )
          : calculateHaversineDistance(
              origin.latitude, origin.longitude,
              g.insideCoordinate.latitude, g.insideCoordinate.longitude,
            );

      final double est = dExt + dInt;
      if (est < minEstDist) {
        minEstDist = est;
        bestGate = g;
      }
    }

    return bestGate;
  }

  /// Tìm cổng trường gần nhất với một toạ độ bất kỳ
  static CampusGate findNearestGate(LatLng point, List<CampusGate> gates) {
    if (gates.isEmpty) return CampusConstants.defaultGate;
    CampusGate bestGate = gates.first;
    double bestDist = double.infinity;
    for (final g in gates) {
      final d = calculateHaversineDistance(
        point.latitude, point.longitude, g.lat, g.lng,
      );
      if (d < bestDist) {
        bestDist = d;
        bestGate = g;
      }
    }
    return bestGate;
  }

  /// Ghép nối các mảng toạ độ liên tiếp và khử các điểm trùng lặp (< 0.5m)
  static List<LatLng> stitchPathCoordinates(List<List<LatLng>> paths) {
    final result = <LatLng>[];
    for (final path in paths) {
      if (path.isEmpty) continue;
      for (final pt in path) {
        if (result.isNotEmpty) {
          final last = result.last;
          if ((last.latitude - pt.latitude).abs() < 0.000005 &&
              (last.longitude - pt.longitude).abs() < 0.000005) {
            continue;
          }
        }
        result.add(pt);
      }
    }
    return result;
  }

  /// Dự phòng ngoại vi thông minh (LTDDDNT):
  /// Nội suy dọc theo trục đường Lê Duẩn hoặc Y Wang thay vì vẽ đường chim bay cắt qua nhà dân
  static DijkstraResult buildPerimeterRoadFallback(LatLng start, LatLng target) {
    final road = (start.longitude <= 108.0255 && target.longitude <= 108.0255)
        ? CampusConstants.perimeterLeDuan
        : CampusConstants.perimeterYWang;

    int sIdx = 0;
    double minSDist = double.infinity;
    int tIdx = 0;
    double minTDist = double.infinity;

    for (int r = 0; r < road.length; r++) {
      final ds = calculateHaversineDistance(
        start.latitude, start.longitude, road[r].latitude, road[r].longitude,
      );
      if (ds < minSDist) {
        minSDist = ds;
        sIdx = r;
      }
      final dt = calculateHaversineDistance(
        target.latitude, target.longitude, road[r].latitude, road[r].longitude,
      );
      if (dt < minTDist) {
        minTDist = dt;
        tIdx = r;
      }
    }

    final coords = <LatLng>[start];
    if (sIdx <= tIdx) {
      for (int i = sIdx; i <= tIdx; i++) {
        coords.add(road[i]);
      }
    } else {
      for (int i = sIdx; i >= tIdx; i--) {
        coords.add(road[i]);
      }
    }
    coords.add(target);

    double totalD = 0;
    for (int c = 0; c < coords.length - 1; c++) {
      totalD += calculateHaversineDistance(
        coords[c].latitude, coords[c].longitude,
        coords[c + 1].latitude, coords[c + 1].longitude,
      );
    }

    final durSec = (totalD / 1.25).round();
    final durMin = (durSec / 60).ceil().clamp(1, 180);

    return DijkstraResult(
      coordinates: coords,
      distanceMeters: totalD,
      estimatedWalkingMinutes: durMin,
      isHybrid: true,
    );
  }

  /// Tuyến đường dự phòng thẳng trực tiếp (LTDDDNT computeFallbackDirectRoute)
  static DijkstraResult computeFallbackDirectRoute(LatLng orig, LatLng dest) {
    final dist = calculateHaversineDistance(orig.latitude, orig.longitude, dest.latitude, dest.longitude);
    final dur = (dist / 80.0).round().clamp(1, 180);
    return DijkstraResult(
      coordinates: [orig, dest],
      distanceMeters: dist,
      estimatedWalkingMinutes: dur,
      isHybrid: false,
    );
  }

  /// Hàm tính toán tuyến đường đa chế độ (nội bộ / đường phố / qua cổng trường)
  /// Port 100% nguyên bản từ calculateRoute trong LTDDDNT (leafletHtml.ts dòng 1734-1830)
  Future<DijkstraResult> calculateRoute({
    required LatLng origin,
    required LatLng destination,
    String? preferredGateId,
    required List<CampusGate> availableGates,
    bool isMedicalDestination = false,
    ExternalRoutingService? externalRoutingService,
  }) async {
    final origIn = isInsideCampus(origin);
    final destIn = isInsideCampus(destination);

    // TRƯỜNG HỢP 1: CẢ 2 ĐỀU Ở TRONG KHUÔN VIÊN TRƯỜNG
    // Đi 100% bằng đường thiết kế nội bộ (Dijkstra)
    if (origIn && destIn) {
      final internalRoute = findShortestRoute(origin, destination);
      if (internalRoute.coordinates.length >= 2) {
        return internalRoute;
      }
      return computeFallbackDirectRoute(origin, destination);
    }

    // TRƯỜNG HỢP 2: CẢ 2 ĐỀU Ở NGOÀI KHUÔN VIÊN TRƯỜNG
    // Đi hoàn toàn trên đường phố công cộng (OSRM)
    if (!origIn && !destIn) {
      if (externalRoutingService != null) {
        try {
          final ext = await externalRoutingService.getWalkingRoadRoute(
            start: origin,
            end: destination,
          );
          if (ext.coordinates.length >= 2) {
            final dur = (ext.durationSeconds / 60).ceil().clamp(1, 180);
            return DijkstraResult(
              coordinates: ext.coordinates,
              distanceMeters: ext.distanceMeters,
              estimatedWalkingMinutes: dur,
              isHybrid: false,
            );
          }
        } catch (_) {}
      }
      return buildPerimeterRoadFallback(origin, destination);
    }

    // TRƯỜNG HỢP 3: TỪ NGOÀI KHU VỰC TRƯỜNG VÀO TRONG KHUÔN VIÊN TRƯỜNG
    if (!origIn && destIn) {
      final gate = getBestGate(
        origin: origin,
        destination: destination,
        isEntering: true,
        preferredGateId: preferredGateId,
        isMedicalDestination: isMedicalDestination,
        availableGates: availableGates,
      );

      final internalRoute = findShortestRoute(gate.insideCoordinate, destination);
      final List<LatLng> intCoords = internalRoute.coordinates.length >= 2
          ? internalRoute.coordinates
          : [gate.insideCoordinate, destination];
      final double intDist = internalRoute.coordinates.length >= 2
          ? internalRoute.distanceMeters
          : calculateHaversineDistance(
              gate.insideCoordinate.latitude, gate.insideCoordinate.longitude,
              destination.latitude, destination.longitude,
            );

      List<LatLng> safeExt = [origin, gate.outsideCoordinate];
      double safeExtDist = calculateHaversineDistance(
        origin.latitude, origin.longitude,
        gate.outsideCoordinate.latitude, gate.outsideCoordinate.longitude,
      );
      int safeExtMinutes = (safeExtDist / 75.0).ceil();

      if (externalRoutingService != null) {
        try {
          final ext = await externalRoutingService.getWalkingRoadRoute(
            start: origin,
            end: gate.outsideCoordinate,
          );
          if (ext.coordinates.length >= 2) {
            safeExt = ext.coordinates;
            safeExtDist = ext.distanceMeters;
            safeExtMinutes = (ext.durationSeconds / 60).ceil();
          }
        } catch (_) {
          final fb = buildPerimeterRoadFallback(origin, gate.outsideCoordinate);
          safeExt = fb.coordinates;
          safeExtDist = fb.distanceMeters;
          safeExtMinutes = fb.estimatedWalkingMinutes;
        }
      } else {
        final fb = buildPerimeterRoadFallback(origin, gate.outsideCoordinate);
        safeExt = fb.coordinates;
        safeExtDist = fb.distanceMeters;
        safeExtMinutes = fb.estimatedWalkingMinutes;
      }

      final gateTransition = [
        gate.outsideCoordinate,
        gate.coordinate,
        gate.insideCoordinate,
      ];
      final combinedCoords = stitchPathCoordinates([
        safeExt,
        gateTransition,
        intCoords,
      ]);

      final gateTransDist = calculateHaversineDistance(
        gate.outsideCoordinate.latitude, gate.outsideCoordinate.longitude,
        gate.insideCoordinate.latitude, gate.insideCoordinate.longitude,
      );
      final totalDist = safeExtDist + gateTransDist + intDist;
      final totalDur = (safeExtMinutes + internalRoute.estimatedWalkingMinutes).clamp(1, 180);

      return DijkstraResult(
        coordinates: combinedCoords,
        distanceMeters: totalDist,
        estimatedWalkingMinutes: totalDur,
        isHybrid: true,
        viaGateName: gate.name,
        gate: gate,
      );
    }

    // TRƯỜNG HỢP 4: TỪ TRONG KHUÔN VIÊN TRƯỜNG ĐI RA NGOÀI ĐƯỜNG
    final gate = getBestGate(
      origin: origin,
      destination: destination,
      isEntering: false,
      preferredGateId: preferredGateId,
      isMedicalDestination: isMedicalDestination,
      availableGates: availableGates,
    );

    final internalRoute = findShortestRoute(origin, gate.insideCoordinate);
    final List<LatLng> intCoords = internalRoute.coordinates.length >= 2
        ? internalRoute.coordinates
        : [origin, gate.insideCoordinate];
    final double intDist = internalRoute.coordinates.length >= 2
        ? internalRoute.distanceMeters
        : calculateHaversineDistance(
            origin.latitude, origin.longitude,
            gate.insideCoordinate.latitude, gate.insideCoordinate.longitude,
          );

    List<LatLng> safeExt = [gate.outsideCoordinate, destination];
    double safeExtDist = calculateHaversineDistance(
      gate.outsideCoordinate.latitude, gate.outsideCoordinate.longitude,
      destination.latitude, destination.longitude,
    );
    int safeExtMinutes = (safeExtDist / 75.0).ceil();

    if (externalRoutingService != null) {
      try {
        final ext = await externalRoutingService.getWalkingRoadRoute(
          start: gate.outsideCoordinate,
          end: destination,
        );
        if (ext.coordinates.length >= 2) {
          safeExt = ext.coordinates;
          safeExtDist = ext.distanceMeters;
          safeExtMinutes = (ext.durationSeconds / 60).ceil();
        }
      } catch (_) {
        final fb = buildPerimeterRoadFallback(gate.outsideCoordinate, destination);
        safeExt = fb.coordinates;
        safeExtDist = fb.distanceMeters;
        safeExtMinutes = fb.estimatedWalkingMinutes;
      }
    } else {
      final fb = buildPerimeterRoadFallback(gate.outsideCoordinate, destination);
      safeExt = fb.coordinates;
      safeExtDist = fb.distanceMeters;
      safeExtMinutes = fb.estimatedWalkingMinutes;
    }

    final gateTransition = [
      gate.insideCoordinate,
      gate.coordinate,
      gate.outsideCoordinate,
    ];
    final combinedCoords = stitchPathCoordinates([
      intCoords,
      gateTransition,
      safeExt,
    ]);

    final gateTransDist = calculateHaversineDistance(
      gate.insideCoordinate.latitude, gate.insideCoordinate.longitude,
      gate.outsideCoordinate.latitude, gate.outsideCoordinate.longitude,
    );
    final totalDist = intDist + gateTransDist + safeExtDist;
    final totalDur = (internalRoute.estimatedWalkingMinutes + safeExtMinutes).clamp(1, 180);

    return DijkstraResult(
      coordinates: combinedCoords,
      distanceMeters: totalDist,
      estimatedWalkingMinutes: totalDur,
      isHybrid: true,
      viaGateName: gate.name,
      gate: gate,
    );
  }

  /// Dẫn đường hybrid đa chế độ (nội bộ / đường phố / chuyển tiếp cổng trường 3 điểm)
  DijkstraResult findHybridRoute({
    required LatLng start,
    required LatLng destination,
    required List<CampusGate> availableGates,
    String? preferredGateId,
    bool isMedicalDestination = false,
    List<LatLng>? externalRoadCoordinates,
    double? externalRoadDistanceMeters,
    int? externalDurationSeconds,
  }) {
    final origIn = isInsideCampus(start);
    final destIn = isInsideCampus(destination);

    // TRƯỜNG HỢP 1: CẢ 2 ĐỀU Ở TRONG KHUÔN VIÊN TRƯỜNG
    // Đi 100% bằng đường thiết kế nội bộ (Dijkstra)
    if (origIn && destIn) {
      return findShortestRoute(start, destination);
    }

    // TRƯỜNG HỢP 2: CẢ 2 ĐỀU Ở NGOÀI KHUÔN VIÊN TRƯỜNG
    // Đi hoàn toàn trên đường phố công cộng
    if (!origIn && !destIn) {
      if (externalRoadCoordinates != null && externalRoadCoordinates.length >= 2) {
        final dist = externalRoadDistanceMeters ??
            calculateHaversineDistance(
              start.latitude, start.longitude,
              destination.latitude, destination.longitude,
            );
        final dur = externalDurationSeconds != null
            ? (externalDurationSeconds / 60).ceil()
            : (dist / 75.0).ceil();
        return DijkstraResult(
          coordinates: externalRoadCoordinates,
          distanceMeters: dist,
          estimatedWalkingMinutes: dur.clamp(1, 180),
          isHybrid: false,
        );
      }
      return buildPerimeterRoadFallback(start, destination);
    }

    // TRƯỜNG HỢP 3: TỪ NGOÀI KHU VỰC TRƯỜNG VÀO TRONG KHUÔN VIÊN TRƯỜNG
    if (!origIn && destIn) {
      final gate = getBestGate(
        origin: start,
        destination: destination,
        isEntering: true,
        preferredGateId: preferredGateId,
        isMedicalDestination: isMedicalDestination,
        availableGates: availableGates,
      );

      // Đi bộ nội bộ từ bên trong cổng đến đích
      final internalRoute = findShortestRoute(gate.insideCoordinate, destination);
      final List<LatLng> intCoords = internalRoute.coordinates.isNotEmpty
          ? internalRoute.coordinates
          : [gate.insideCoordinate, destination];
      final double intDist = internalRoute.coordinates.isNotEmpty
          ? internalRoute.distanceMeters
          : calculateHaversineDistance(
              gate.insideCoordinate.latitude, gate.insideCoordinate.longitude,
              destination.latitude, destination.longitude,
            );

      // Tuyến đường ngoại vi tiếp cận cổng:
      final List<LatLng> safeExt;
      final double safeExtDist;
      final int safeExtMinutes;

      if (externalRoadCoordinates != null && externalRoadCoordinates.length >= 2) {
        safeExt = externalRoadCoordinates;
        safeExtDist = externalRoadDistanceMeters ??
            calculateHaversineDistance(
              start.latitude, start.longitude,
              gate.outsideCoordinate.latitude, gate.outsideCoordinate.longitude,
            );
        final durSec = externalDurationSeconds ?? (safeExtDist / 1.25).round();
        safeExtMinutes = (durSec / 60).ceil();
      } else {
        final perimeterFb = buildPerimeterRoadFallback(start, gate.outsideCoordinate);
        safeExt = perimeterFb.coordinates;
        safeExtDist = perimeterFb.distanceMeters;
        safeExtMinutes = perimeterFb.estimatedWalkingMinutes;
      }

      // Khớp nối chuyển tiếp 3 điểm qua cổng: [outsidePoint -> gatePoint -> insidePoint]
      final gateTransition = [
        gate.outsideCoordinate,
        gate.coordinate,
        gate.insideCoordinate,
      ];
      final combinedCoords = stitchPathCoordinates([
        safeExt,
        gateTransition,
        intCoords,
      ]);

      final gateTransDist = calculateHaversineDistance(
        gate.outsideCoordinate.latitude, gate.outsideCoordinate.longitude,
        gate.insideCoordinate.latitude, gate.insideCoordinate.longitude,
      );
      final totalDist = safeExtDist + gateTransDist + intDist;
      final totalMinutes = (safeExtMinutes + internalRoute.estimatedWalkingMinutes).clamp(1, 180);

      return DijkstraResult(
        coordinates: combinedCoords,
        distanceMeters: totalDist,
        estimatedWalkingMinutes: totalMinutes,
        isHybrid: true,
        viaGateName: gate.name,
        gate: gate,
      );
    }

    // TRƯỜNG HỢP 4: TỪ TRONG KHUÔN VIÊN TRƯỜNG ĐI RA NGOÀI ĐƯỜNG
    final gate = getBestGate(
      origin: start,
      destination: destination,
      isEntering: false,
      preferredGateId: preferredGateId,
      isMedicalDestination: isMedicalDestination,
      availableGates: availableGates,
    );

    final internalRoute = findShortestRoute(start, gate.insideCoordinate);
    final List<LatLng> intCoords = internalRoute.coordinates.isNotEmpty
        ? internalRoute.coordinates
        : [start, gate.insideCoordinate];
    final double intDist = internalRoute.coordinates.isNotEmpty
        ? internalRoute.distanceMeters
        : calculateHaversineDistance(
            start.latitude, start.longitude,
            gate.insideCoordinate.latitude, gate.insideCoordinate.longitude,
          );

    final List<LatLng> safeExt;
    final double safeExtDist;
    final int safeExtMinutes;

    if (externalRoadCoordinates != null && externalRoadCoordinates.length >= 2) {
      safeExt = externalRoadCoordinates;
      safeExtDist = externalRoadDistanceMeters ??
          calculateHaversineDistance(
            gate.outsideCoordinate.latitude, gate.outsideCoordinate.longitude,
            destination.latitude, destination.longitude,
          );
      final durSec = externalDurationSeconds ?? (safeExtDist / 1.25).round();
      safeExtMinutes = (durSec / 60).ceil();
    } else {
      final perimeterFb = buildPerimeterRoadFallback(gate.outsideCoordinate, destination);
      safeExt = perimeterFb.coordinates;
      safeExtDist = perimeterFb.distanceMeters;
      safeExtMinutes = perimeterFb.estimatedWalkingMinutes;
    }

    final gateTransition = [
      gate.insideCoordinate,
      gate.coordinate,
      gate.outsideCoordinate,
    ];
    final combinedCoords = stitchPathCoordinates([
      intCoords,
      gateTransition,
      safeExt,
    ]);

    final gateTransDist = calculateHaversineDistance(
      gate.insideCoordinate.latitude, gate.insideCoordinate.longitude,
      gate.outsideCoordinate.latitude, gate.outsideCoordinate.longitude,
    );
    final totalDist = intDist + gateTransDist + safeExtDist;
    final totalMinutes = (internalRoute.estimatedWalkingMinutes + safeExtMinutes).clamp(1, 180);

    return DijkstraResult(
      coordinates: combinedCoords,
      distanceMeters: totalDist,
      estimatedWalkingMinutes: totalMinutes,
      isHybrid: true,
      viaGateName: gate.name,
      gate: gate,
    );
  }

  String _formatCoordKey(double lat, double lng) {
    return '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';
  }
}
