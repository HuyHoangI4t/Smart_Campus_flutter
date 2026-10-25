import '../constants/campus_constants.dart';
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

  const DijkstraResult({
    required this.coordinates,
    required this.distanceMeters,
    required this.estimatedWalkingMinutes,
    this.isHybrid = false,
    this.viaGateName,
  });

  static const empty = DijkstraResult(
    coordinates: [],
    distanceMeters: 0,
    estimatedWalkingMinutes: 0,
    isHybrid: false,
    viaGateName: null,
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

  /// Kiem tra toa do co nam ben trong khuon vien truong hay khong
  static bool isInsideCampus(LatLng point) {
    final x = point.latitude;
    final y = point.longitude;

    // Buffer 35m xung quanh cac cong truong -> van coi la trong truong
    for (final gate in CampusConstants.gates) {
      final d = calculateHaversineDistance(x, y, gate.lat, gate.lng);
      if (d <= 35.0) return true;
    }

    // Ray-casting point-in-polygon kiem tra da giac ranh gioi
    final b = CampusConstants.campusBoundary;
    if (b.length < 3) return true;

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

  /// Tim cong truong gan nhat voi vi tri nguoi dung
  static CampusGate findNearestGate(LatLng point, List<CampusGate> gates) {
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

  /// Dan duong hybrid: ngoai truong -> cong gan nhat -> loi di bo noi bo
  DijkstraResult findHybridRoute({
    required LatLng start,
    required LatLng destination,
    required List<CampusGate> availableGates,
  }) {
    // Neu vi tri xuat phat nam TRONG truong -> Dijkstra noi bo binh thuong
    if (isInsideCampus(start)) {
      return findShortestRoute(start, destination);
    }

    // Vi tri NGOAI truong -> Dan qua cong gan nhat
    final nearestGate = findNearestGate(start, availableGates);
    final gateCoord = nearestGate.coordinate;

    // Tinh doan di bo noi bo tu cong den dich
    final internalRoute = findShortestRoute(gateCoord, destination);
    if (internalRoute.coordinates.isEmpty) {
      return DijkstraResult.empty;
    }

    // Khoang cach tu vi tri ngoai truong den cong
    final externalDistance = calculateHaversineDistance(
      start.latitude, start.longitude, gateCoord.latitude, gateCoord.longitude,
    );

    // Ghep tuyen: [Vi tri ngoai] -> [Cong truong] -> [Cac moc noi bo...]
    final combinedCoords = <LatLng>[start];
    // Tranh duplicate vi tri cong neu internalRoute da bat dau tu cong
    final firstInternal = internalRoute.coordinates.first;
    final distToFirst = calculateHaversineDistance(
      gateCoord.latitude, gateCoord.longitude,
      firstInternal.latitude, firstInternal.longitude,
    );
    if (distToFirst > 1.0) {
      combinedCoords.add(gateCoord);
    }
    combinedCoords.addAll(internalRoute.coordinates);

    final totalDistance = externalDistance + internalRoute.distanceMeters;
    final totalMinutes = (totalDistance / 75.0).ceil().clamp(1, 120);

    return DijkstraResult(
      coordinates: combinedCoords,
      distanceMeters: totalDistance,
      estimatedWalkingMinutes: totalMinutes,
      isHybrid: true,
      viaGateName: nearestGate.name,
    );
  }

  String _formatCoordKey(double lat, double lng) {
    return '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';
  }
}
