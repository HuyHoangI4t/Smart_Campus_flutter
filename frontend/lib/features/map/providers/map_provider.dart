import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/campus_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/compass_smoother.dart';
import '../../../core/services/external_routing_service.dart';
import '../../../core/utils/dijkstra.dart';
import '../../../core/utils/haversine.dart';

/// Sentinel object de phan biet "khong truyen" vs "truyen null"
class _Sentinel {
  const _Sentinel();
}


class MapState {
  final List<CampusLocationItem> locations;
  final List<CampusGate> gates;
  final String selectedCategory;
  final String searchQuery;
  final CampusLocationItem? selectedLocation;
  final CampusGate selectedGate;
  final DijkstraResult? activeRoute;
  final bool isNavigating;
  final double compassHeading;
  final LatLng? userPosition;
  final bool isLoadingPaths;
  final bool pathsFromApi;
  final String? routingError;

  const MapState({
    this.locations = CampusConstants.campusLocations,
    this.gates = CampusConstants.gates,
    this.selectedCategory = 'Tat ca',
    this.searchQuery = '',
    this.selectedLocation,
    this.selectedGate = CampusConstants.defaultGate,
    this.activeRoute,
    this.isNavigating = false,
    this.compassHeading = 0.0,
    this.userPosition,
    this.isLoadingPaths = false,
    this.pathsFromApi = false,
    this.routingError,
  });

  List<CampusLocationItem> get filteredLocations {
    return locations.where((loc) {
      final matchesCategory = selectedCategory == 'Tat ca' ||
          selectedCategory == 'Tất cả' ||
          loc.category == selectedCategory;
      if (!matchesCategory) return false;
      if (searchQuery.trim().isEmpty) return true;

      return _matchesLocation(loc, searchQuery.trim());
    }).toList();
  }

  static bool _matchesLocation(CampusLocationItem loc, String rawQuery) {
    final q = rawQuery.toLowerCase().trim();
    if (q.isEmpty) return true;

    final name = loc.name.toLowerCase();
    final building = loc.building.toLowerCase();
    final desc = loc.description.toLowerCase();

    // 1. Chứa chuỗi trực tiếp
    if (name.contains(q) || building.contains(q) || desc.contains(q)) {
      return true;
    }

    // Chuẩn hóa bỏ khoảng trắng quanh dấu chấm/gạch ngang: "7.3. 18" -> "7.3.18"
    final normalizedQ = q.replaceAll(RegExp(r'\s*[\._]\s*'), '.').replaceAll(RegExp(r'\s+'), ' ');

    // 2. Dạng phòng học: [Nhà].[Tầng].[Phòng] hoặc [Nhà].[Phòng] (vd: 7.3.18, 7.3. 18, 2.20, 8.3.4, 9.2.04)
    final roomCodeMatch = RegExp(r'^(\d+)\.(\d+)(?:\.([0-9a-zA-Z_-]+))?').firstMatch(normalizedQ);
    if (roomCodeMatch != null) {
      final bNum = roomCodeMatch.group(1)!;
      if (building.contains('nhà học số $bNum') ||
          building.contains('nhà $bNum') ||
          name.contains('nhà học số $bNum') ||
          name.contains('nhà $bNum')) {
        return true;
      }
    }

    // 3. Dạng "Nhà 7", "Nha 7", "Nhà số 7", "Nhà học số 7"
    final nhaMatch = RegExp(r'^(?:nhà\s*học\s*số|nhà\s*học|nhà\s*số|nhà|nha)\s*(\d+)', caseSensitive: false).firstMatch(q);
    if (nhaMatch != null) {
      final bNum = nhaMatch.group(1)!;
      if (building.contains('nhà học số $bNum') ||
          building.contains('nhà $bNum') ||
          name.contains('nhà học số $bNum') ||
          name.contains('nhà $bNum')) {
        return true;
      }
    }

    // 4. Các hội trường lớn & giảng đường chuyên biệt
    if (q.contains('400')) {
      if (name.contains('400') || building.contains('Hội trường lớn') || building.contains('400')) return true;
    }
    if (q.contains('200')) {
      if (name.contains('200') || building.contains('Hội trường vừa') || building.contains('200')) return true;
    }
    if (q.contains('thư viện') || q.contains('thu vien')) {
      if (building.contains('thư viện') || name.contains('thư viện')) return true;
    }
    if (q.contains('gdqp') || q.contains('quốc phòng') || q.contains('quoc phong')) {
      if (building.contains('gdqp') || name.contains('gdqp') || name.contains('quốc phòng')) return true;
    }

    // 5. Nếu gõ đúng 1 chữ số (vd: "7" -> Nhà 7):
    if (RegExp(r'^\d+$').hasMatch(q)) {
      if (building.contains('nhà học số $q') || building == 'nhà $q' || name.contains('nhà học số $q')) {
        return true;
      }
    }

    return false;
  }

  /// Fixed copyWith: su dung sentinel pattern de ho tro set null
  MapState copyWith({
    List<CampusLocationItem>? locations,
    List<CampusGate>? gates,
    String? selectedCategory,
    String? searchQuery,
    Object? selectedLocation = const _Sentinel(),
    CampusGate? selectedGate,
    Object? activeRoute = const _Sentinel(),
    bool? isNavigating,
    double? compassHeading,
    Object? userPosition = const _Sentinel(),
    bool? isLoadingPaths,
    bool? pathsFromApi,
    Object? routingError = const _Sentinel(),
  }) {
    return MapState(
      locations: locations ?? this.locations,
      gates: gates ?? this.gates,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedLocation: selectedLocation is _Sentinel
          ? this.selectedLocation
          : selectedLocation as CampusLocationItem?,
      selectedGate: selectedGate ?? this.selectedGate,
      activeRoute: activeRoute is _Sentinel
          ? this.activeRoute
          : activeRoute as DijkstraResult?,
      isNavigating: isNavigating ?? this.isNavigating,
      compassHeading: compassHeading ?? this.compassHeading,
      userPosition: userPosition is _Sentinel
          ? this.userPosition
          : userPosition as LatLng?,
      isLoadingPaths: isLoadingPaths ?? this.isLoadingPaths,
      pathsFromApi: pathsFromApi ?? this.pathsFromApi,
      routingError: routingError is _Sentinel
          ? this.routingError
          : routingError as String?,
    );
  }
}

class MapNotifier extends Notifier<MapState> {
  final CampusDijkstraRouter _router = CampusDijkstraRouter();
  StreamSubscription? _compassSub;
  StreamSubscription? _positionSub;
  CompassSmoother? _compassSmoother;
  Timer? _searchDebounce;

  @override
  MapState build() {
    _initDijkstraRouter();
    _startCompassListening();
    _startLocationListening();
    fetchLocationsFromBackend();
    _fetchPathsFromBackend();

    ref.onDispose(() {
      _compassSub?.cancel();
      _positionSub?.cancel();
      _compassSmoother?.dispose();
      _searchDebounce?.cancel();
    });

    return const MapState();
  }

  void _initDijkstraRouter() {
    _router.buildGraphFromPolylines(CampusConstants.defaultWalkways);
  }

  /// Fetch duong di tu backend API voi offline fallback
  Future<void> _fetchPathsFromBackend() async {
    state = state.copyWith(isLoadingPaths: true);
    final dio = ref.read(dioProvider);
    try {
      final response = await dio.get(ApiEndpoints.campusPaths);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['paths'] is List) {
          final List<dynamic> rawPaths = data['paths'];
          final apiPaths = rawPaths
              .whereType<Map<String, dynamic>>()
              .toList();
          if (apiPaths.isNotEmpty) {
            _router.buildGraphFromApiPaths(apiPaths);
            state = state.copyWith(
              isLoadingPaths: false,
              pathsFromApi: true,
            );
            // Re-route neu dang navigate
            if (state.isNavigating && state.selectedLocation != null) {
              _recalculateRoute();
            }
            return;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Backend fetch paths fallback to offline constants: $e');
      }
    }
    // Fallback: giu nguyen graph tu offline constants
    state = state.copyWith(isLoadingPaths: false);
  }

  void _startCompassListening() {
    _compassSmoother = CompassSmoother(
      minDegreeChange: 8.0,
      throttleMs: 450,
      onSmoothedHeading: (heading) {
        state = state.copyWith(compassHeading: heading);
      },
    );

    try {
      _compassSub = FlutterCompass.events?.listen((event) {
        if (event.heading != null) {
          _compassSmoother?.update(event.heading!);
        }
      });
    } catch (_) {}
  }

  void _startLocationListening() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        return;
      }

      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3,
        ),
      ).listen(
        (pos) {
          final newPos = LatLng(pos.latitude, pos.longitude);
          state = state.copyWith(userPosition: newPos);
          // Cap nhat khoang cach live khi dang navigate
          if (state.isNavigating && state.selectedLocation != null) {
            _updateLiveNavigation(newPos);
          }
        },
        onError: (e) {
          if (kDebugMode) {
            print('GPS location listen stream error: $e');
          }
        },
        cancelOnError: false,
      );
    } catch (e) {
      if (kDebugMode) {
        print('GPS location listen error: $e');
      }
    }
  }

  /// Tinh toan tuyen duong (noi bo hoac hybrid duong pho OSRM ngoai truong)
  Future<DijkstraResult> _computeRoute({
    required LatLng start,
    required LatLng destination,
    bool isFromGps = false,
  }) async {
    if (!isFromGps || CampusDijkstraRouter.isInsideCampus(start)) {
      return _router.findShortestRoute(start, destination);
    }

    final nearestGate = CampusDijkstraRouter.findNearestGate(start, state.gates);
    final gateCoord = nearestGate.coordinate;

    final directDist = calculateHaversineDistance(
      start.latitude, start.longitude, gateCoord.latitude, gateCoord.longitude,
    );

    if (directDist > 2000.0) {
      final km = (directDist / 1000).toStringAsFixed(1);
      state = state.copyWith(
        routingError:
            'Vị trí hiện tại cách trường ${km}km (vượt quá bán kính hỗ trợ 2km). Vui lòng chọn xuất phát trực tiếp từ Cổng trường.',
        isNavigating: false,
        activeRoute: null,
      );
      return DijkstraResult.empty;
    }

    final externalService = ExternalRoutingService(ref.read(dioProvider));
    final roadResult = await externalService.getWalkingRoadRoute(
      start: start,
      end: gateCoord,
    );

    return _router.findHybridRoute(
      start: start,
      destination: destination,
      availableGates: state.gates,
      externalRoadCoordinates: roadResult.coordinates,
      externalRoadDistanceMeters: roadResult.distanceMeters,
      externalDurationSeconds: roadResult.durationSeconds,
    );
  }

  /// Cap nhat khoang cach live khi user di chuyen
  Future<void> _updateLiveNavigation(LatLng currentPos) async {
    final destination = state.selectedLocation;
    if (destination == null) return;

    if (CampusDijkstraRouter.isInsideCampus(currentPos)) {
      final route = _router.findShortestRoute(currentPos, destination.coordinate);
      if (route.coordinates.isNotEmpty) {
        state = state.copyWith(activeRoute: route);
      }
      return;
    }

    final nearestGate = CampusDijkstraRouter.findNearestGate(currentPos, state.gates);
    final dist = calculateHaversineDistance(
      currentPos.latitude, currentPos.longitude, nearestGate.lat, nearestGate.lng,
    );

    if (dist <= 2000.0) {
      final route = await _computeRoute(
        start: currentPos,
        destination: destination.coordinate,
        isFromGps: true,
      );
      if (route.coordinates.isNotEmpty && state.isNavigating) {
        state = state.copyWith(activeRoute: route);
      }
    }
  }

  /// Tinh lai route (khi graph thay doi hoac doi cong)
  Future<void> _recalculateRoute() async {
    final destination = state.selectedLocation;
    if (destination == null) return;

    final userPos = state.userPosition;
    final DijkstraResult route;
    if (userPos != null) {
      route = await _computeRoute(
        start: userPos,
        destination: destination.coordinate,
        isFromGps: true,
      );
    } else {
      route = await _computeRoute(
        start: state.selectedGate.coordinate,
        destination: destination.coordinate,
        isFromGps: false,
      );
    }
    if (route.coordinates.isNotEmpty) {
      state = state.copyWith(activeRoute: route);
    }
  }

  Future<void> fetchLocationsFromBackend() async {
    final dio = ref.read(dioProvider);
    try {
      final response = await dio.get(ApiEndpoints.campusLocations);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['locations'] is List) {
          final List<dynamic> list = data['locations'];
          final parsed = list
              .map((item) => CampusLocationItem.fromJson(
                  item as Map<String, dynamic>))
              .where((loc) => loc.lat != 0.0 && loc.lng != 0.0)
              .toList();
          if (parsed.isNotEmpty) {
            state = state.copyWith(locations: parsed);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Backend fetch locations fallback to offline constants: $e');
      }
    }

    try {
      final gatesResponse = await dio.get(ApiEndpoints.campusGates);
      if (gatesResponse.statusCode == 200 && gatesResponse.data != null) {
        final gData = gatesResponse.data;
        final rawGates = (gData is Map<String, dynamic>)
            ? (gData['gates'] ?? gData['data'])
            : null;
        if (rawGates is List && rawGates.isNotEmpty) {
          final parsedGates = rawGates
              .map((g) => CampusGate.fromJson(g as Map<String, dynamic>))
              .where((g) => g.lat != 0.0 && g.lng != 0.0)
              .toList();
          if (parsedGates.isNotEmpty) {
            state = state.copyWith(gates: parsedGates);
          }
        }
      }
    } catch (_) {}
  }

  void selectCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  /// Search voi debounce 300ms
  void updateSearch(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      state = state.copyWith(searchQuery: query);
    });
  }

  void selectLocation(CampusLocationItem? location) {
    state = state.copyWith(
      selectedLocation: location,
      isNavigating: false,
      activeRoute: null,
    );
  }

  void selectGate(CampusGate gate) {
    state = state.copyWith(selectedGate: gate);
    if (state.isNavigating && state.selectedLocation != null) {
      startNavigationTo(state.selectedLocation!);
    }
  }

  void clearRoutingError() {
    state = state.copyWith(routingError: null);
  }

  Future<void> startNavigationTo(CampusLocationItem destination) async {
    final userPos = state.userPosition;
    final DijkstraResult route;

    if (userPos != null) {
      route = await _computeRoute(
        start: userPos,
        destination: destination.coordinate,
        isFromGps: true,
      );
    } else {
      route = await _computeRoute(
        start: state.selectedGate.coordinate,
        destination: destination.coordinate,
        isFromGps: false,
      );
    }

    if (route.coordinates.isEmpty) {
      if (state.routingError == null) {
        state = state.copyWith(
          selectedLocation: destination,
          activeRoute: null,
          isNavigating: false,
          routingError: 'Không tìm thấy đường đi bộ đến ${destination.name}',
        );
      }
      return;
    }

    state = state.copyWith(
      selectedLocation: destination,
      activeRoute: route,
      isNavigating: true,
      routingError: null,
    );
  }

  void stopNavigation() {
    state = state.copyWith(
      isNavigating: false,
      activeRoute: null,
    );
  }

  /// Xoá trạng thái tìm kiếm, chọn toà nhà khi rời khỏi map (chỉ thực hiện khi KHÔNG đang dẫn đường)
  void resetExploreState() {
    if (state.isNavigating) return;

    state = state.copyWith(
      selectedLocation: null,
      searchQuery: '',
      selectedCategory: 'Tat ca',
      activeRoute: null,
      routingError: null,
    );
  }
}

final mapProvider =
    NotifierProvider<MapNotifier, MapState>(MapNotifier.new);
