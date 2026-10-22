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

class MinHeapNode implements Comparable<MinHeapNode> {
  final String nodeId;
  final double distance;

  MinHeapNode(this.nodeId, this.distance);

  @override
  int compareTo(MinHeapNode other) => distance.compareTo(other.distance);
}

class SimplePriorityQueue {
  final List<MinHeapNode> _elements = [];

  bool get isEmpty => _elements.isEmpty;

  void add(String nodeId, double distance) {
    _elements.add(MinHeapNode(nodeId, distance));
    _elements.sort();
  }

  MinHeapNode removeFirst() {
    return _elements.removeAt(0);
  }
}

class CampusDijkstraRouter {
  final Map<String, List<DijkstraEdge>> graph = {};
  final Map<String, LatLng> nodeCoordinates = {};

  CampusDijkstraRouter();

  /// Nạp các đoạn đường từ danh sách đa tuyến (Multi-segment polylines)
  void buildGraphFromPolylines(List<List<LatLng>> polylines) {
    graph.clear();
    nodeCoordinates.clear();

    for (final polyline in polylines) {
      for (int i = 0; i < polyline.length - 1; i++) {
        final p1 = polyline[i];
        final p2 = polyline[i + 1];

        final id1 = _formatCoordKey(p1.latitude, p1.longitude);
        final id2 = _formatCoordKey(p2.latitude, p2.longitude);

        nodeCoordinates[id1] = p1;
        nodeCoordinates[id2] = p2;

        final dist = calculateHaversineDistance(
          p1.latitude,
          p1.longitude,
          p2.latitude,
          p2.longitude,
        );

        graph.putIfAbsent(id1, () => []).add(
          DijkstraEdge(target: id2, weight: dist, coordinate: p2),
        );
        graph.putIfAbsent(id2, () => []).add(
          DijkstraEdge(target: id1, weight: dist, coordinate: p1),
        );
      }
    }

    // Tự động kết nối các nút gần nhau (dưới 25m) để tránh việc các nhánh đường bị đứt gãy
    final nodesList = nodeCoordinates.entries.toList();
    for (int i = 0; i < nodesList.length; i++) {
      for (int j = i + 1; j < nodesList.length; j++) {
        final n1 = nodesList[i];
        final n2 = nodesList[j];
        final d = calculateHaversineDistance(
          n1.value.latitude,
          n1.value.longitude,
          n2.value.latitude,
          n2.value.longitude,
        );
        if (d <= 25.0) {
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

  /// Tìm đỉnh trong đồ thị gần nhất với một tọa độ cho trước
  String? findClosestNode(LatLng target) {
    String? closestId;
    double minDistance = double.infinity;

    for (final entry in nodeCoordinates.entries) {
      final d = calculateHaversineDistance(
        target.latitude,
        target.longitude,
        entry.value.latitude,
        entry.value.longitude,
      );
      if (d < minDistance) {
        minDistance = d;
        closestId = entry.key;
      }
    }

    return closestId;
  }

  /// Thuật toán Dijkstra tìm đường đi bộ ngắn nhất
  DijkstraResult findShortestRoute(LatLng start, LatLng end) {
    if (graph.isEmpty) {
      return DijkstraResult(
        coordinates: [start, end],
        distanceMeters: calculateHaversineDistance(
          start.latitude,
          start.longitude,
          end.latitude,
          end.longitude,
        ),
        estimatedWalkingMinutes: 1,
      );
    }

    final startNodeId = findClosestNode(start);
    final endNodeId = findClosestNode(end);

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
    final pq = SimplePriorityQueue();

    for (final node in nodeCoordinates.keys) {
      distances[node] = double.infinity;
    }

    distances[startNodeId] = 0;
    pq.add(startNodeId, 0);

    while (!pq.isEmpty) {
      final current = pq.removeFirst();
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
          pq.add(edge.target, newDist);
        }
      }
    }

    // Kiểm tra xem có tìm thấy đường đi khả thi tới đích hay không
    final bool hasPath = visited.contains(endNodeId) &&
        distances[endNodeId] != null &&
        !distances[endNodeId]!.isInfinite;

    if (!hasPath) {
      final directDistance = calculateHaversineDistance(
        start.latitude,
        start.longitude,
        end.latitude,
        end.longitude,
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

    // Tái cấu trúc lộ trình đường đi
    final pathCoords = <LatLng>[];
    String? step = endNodeId;

    while (step != null) {
      final coord = nodeCoordinates[step];
      if (coord != null) {
        pathCoords.insert(0, coord);
      }
      step = previous[step];
    }

    // Thêm điểm xuất phát và kết thúc chính xác của người dùng
    if (pathCoords.isEmpty) {
      pathCoords.addAll([start, end]);
    } else {
      pathCoords.insert(0, start);
      pathCoords.add(end);
    }

    final rawMeters = distances[endNodeId] ??
        calculateHaversineDistance(start.latitude, start.longitude, end.latitude, end.longitude);

    final safeMeters = rawMeters.isInfinite || rawMeters.isNaN
        ? calculateHaversineDistance(start.latitude, start.longitude, end.latitude, end.longitude)
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

