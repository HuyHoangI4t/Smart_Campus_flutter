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

  const DijkstraResult({
    required this.coordinates,
    required this.distanceMeters,
    required this.estimatedWalkingMinutes,
  });

  static const empty = DijkstraResult(
    coordinates: [],
    distanceMeters: 0,
    estimatedWalkingMinutes: 0,
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

  /// Nap do thi tu API backend paths (co pre-calculated distances)
  void buildGraphFromApiPaths(List<Map<String, dynamic>> apiPaths) {
    graph.clear();
    nodeCoordinates.clear();

    for (final pathData in apiPaths) {
      final coords = pathData['coordinates'];
      if (coords is! List || coords.length < 2) continue;

      for (int i = 0; i < coords.length - 1; i++) {
        final c1 = coords[i];
        final c2 = coords[i + 1];
        if (c1 is! List || c2 is! List) continue;

        final lat1 = (c1[0] as num?)?.toDouble();
        final lng1 = (c1[1] as num?)?.toDouble();
        final lat2 = (c2[0] as num?)?.toDouble();
        final lng2 = (c2[1] as num?)?.toDouble();

        if (lat1 == null || lng1 == null || lat2 == null || lng2 == null) {
          continue;
        }

        _addEdge(LatLng(lat1, lng1), LatLng(lat2, lng2));
      }
    }

    _autoConnectNearbyNodes(25.0);
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
      return DijkstraResult(
        coordinates: [start, end],
        distanceMeters: 0,
        estimatedWalkingMinutes: 0,
      );
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
      final directDistance = calculateHaversineDistance(
        start.latitude, start.longitude, end.latitude, end.longitude,
      );
      final walkingMinutes = (directDistance / 75.0).ceil().clamp(1, 60);
      final fallbackCoords = <LatLng>[start];
      if (nodeCoordinates[startNodeId] != null) {
        fallbackCoords.add(nodeCoordinates[startNodeId]!);
      }
      if (nodeCoordinates[endNodeId] != null && endNodeId != startNodeId) {
        fallbackCoords.add(nodeCoordinates[endNodeId]!);
      }
      fallbackCoords.add(end);
      return DijkstraResult(
        coordinates: fallbackCoords,
        distanceMeters: directDistance,
        estimatedWalkingMinutes: walkingMinutes,
      );
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

  String _formatCoordKey(double lat, double lng) {
    return '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';
  }
}
