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
  final CampusGate? userForcedGate;
  final DijkstraResult? activeRoute;
  final bool isNavigating;
  final double compassHeading;
  final LatLng? userPosition;
  final bool isLoadingPaths;
  final bool pathsFromApi;
  final String? routingError;
  final String? routingNotice;
  final bool isMapActive;

  const MapState({
    this.locations = CampusConstants.campusLocations,
    this.gates = CampusConstants.gates,
    this.selectedCategory = 'Tat ca',
    this.searchQuery = '',
    this.selectedLocation,
    this.selectedGate = CampusConstants.defaultGate,
    this.userForcedGate,
    this.activeRoute,
    this.isNavigating = false,
    this.compassHeading = 0.0,
    this.userPosition,
    this.isLoadingPaths = false,
    this.pathsFromApi = false,
    this.routingError,
    this.routingNotice,
    this.isMapActive = false,
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
    Object? userForcedGate = const _Sentinel(),
    Object? activeRoute = const _Sentinel(),
    bool? isNavigating,
    double? compassHeading,
    Object? userPosition = const _Sentinel(),
    bool? isLoadingPaths,
    bool? pathsFromApi,
    Object? routingError = const _Sentinel(),
    Object? routingNotice = const _Sentinel(),
    bool? isMapActive,
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
      userForcedGate: userForcedGate is _Sentinel
          ? this.userForcedGate
          : userForcedGate as CampusGate?,
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
      routingNotice: routingNotice is _Sentinel
          ? this.routingNotice
          : routingNotice as String?,
      isMapActive: isMapActive ?? this.isMapActive,
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

    ref.onDispose(() {
      _cancelSubscriptions();
    });

    return const MapState();
  }

  void _cancelSubscriptions() {
    _compassSub?.cancel();
    _compassSub = null;
    _positionSub?.cancel();
    _positionSub = null;
    _compassSmoother?.dispose();
    _compassSmoother = null;
    _searchDebounce?.cancel();
    _searchDebounce = null;
  }

  /// Kích hoạt khi người dùng chuyển vào tab Bản đồ:
  /// Khởi động cảm biến la bàn, định vị GPS thực tế và đồng bộ dữ liệu bản đồ
  void activateMap() {
    if (state.isMapActive) return;
    state = state.copyWith(isMapActive: true);
    _startCompassListening();
    _startLocationListening();
    fetchLocationsFromBackend();
    _fetchPathsFromBackend();
  }

  /// Hủy toàn bộ cảm biến, stream và tác vụ nền khi người dùng chuyển sang tab khác:
  /// Dừng cảm biến la bàn (FlutterCompass), dừng GPS watcher (Geolocator), dừng chỉ đường,
  /// giải phóng bộ nhớ và ngăn chặn hao pin ngầm.
  void deactivateMap() {
    _cancelSubscriptions();
    if (!state.isMapActive && !state.isNavigating && state.activeRoute == null && state.selectedLocation == null) {
      return;
    }

    state = state.copyWith(
      isMapActive: false,
      isNavigating: false,
      activeRoute: null,
      userForcedGate: null,
      selectedLocation: null,
      searchQuery: '',
      selectedCategory: 'Tat ca',
      routingError: null,
      routingNotice: null,
    );
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
      if (!ref.mounted) return;
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
    if (ref.mounted) {
      state = state.copyWith(isLoadingPaths: false);
    }
  }

  void _startCompassListening() {
    _compassSmoother = CompassSmoother(
      minDegreeChange: 15.0,
      throttleMs: 800,
      onSmoothedHeading: (heading) {
        // [PERF] Chỉ phát state la bàn khi đang dẫn đường để tránh kích hoạt re-render liên tục
        if (state.isNavigating && (state.compassHeading - heading).abs() > 10.0) {
          state = state.copyWith(compassHeading: heading);
        }
      },
    );

    try {
      _compassSub = FlutterCompass.events?.listen((event) {
        if (event.heading != null && state.isNavigating) {
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

      // 1. Lấy ngay vị trí ban đầu (không cần đợi người dùng di chuyển 5 mét)
      try {
        final initialPos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        ).timeout(const Duration(seconds: 4));
        final initLatLng = LatLng(initialPos.latitude, initialPos.longitude);
        state = state.copyWith(userPosition: initLatLng);
        if (state.isNavigating && state.selectedLocation != null) {
          _updateLiveNavigation(initLatLng);
        }
      } catch (_) {}

      // 2. Lắng nghe vị trí di chuyển liên tục với bộ lọc 5m loại bỏ nhiễu GPS
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
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

  /// Cap nhat khoang cach live khi user di chuyen (bảo toàn nguyên vẹn 100% các khúc cua đường phố ngoài trường)
  void _updateLiveNavigation(LatLng currentPos) {
    if (!state.isNavigating) return;
    final destination = state.selectedLocation;
    if (destination == null) return;

    if (CampusDijkstraRouter.isInsideCampus(currentPos)) {
      final route = _router.findShortestRoute(currentPos, destination.coordinate);
      if (route.coordinates.isNotEmpty) {
        state = state.copyWith(activeRoute: route);
      }
      return;
    }

    final isMedical = destination.category == 'Y tế' ||
        destination.name.toLowerCase().contains('bệnh viện') ||
        destination.building.toLowerCase().contains('bệnh viện') ||
        destination.id == 4;

    final currentGate = state.userForcedGate ??
        CampusDijkstraRouter.getBestGate(
          origin: currentPos,
          destination: destination.coordinate,
          isEntering: true,
          isMedicalDestination: isMedical,
          availableGates: state.gates,
        );
    final dist = calculateHaversineDistance(
      currentPos.latitude, currentPos.longitude, currentGate.lat, currentGate.lng,
    );

    if (dist <= 2000.0) {
      final currentRoute = state.activeRoute;
      if (currentRoute != null && currentRoute.coordinates.length > 2) {
        // Cập nhật vị trí GPS xuất phát mà vẫn bảo toàn 100% các khúc cua đường phố ngoài trường
        final updatedCoords = <LatLng>[currentPos, ...currentRoute.coordinates.skip(1)];
        final totalDist = calculateHaversineDistance(
              currentPos.latitude, currentPos.longitude,
              currentGate.lat, currentGate.lng,
            ) + (currentRoute.distanceMeters - (currentRoute.coordinates.length * 10));
        state = state.copyWith(
          selectedGate: currentGate,
          activeRoute: DijkstraResult(
            coordinates: updatedCoords,
            distanceMeters: totalDist > 0 ? totalDist : currentRoute.distanceMeters,
            estimatedWalkingMinutes: (totalDist / 75.0).ceil().clamp(1, 180),
            isHybrid: true,
            viaGateName: currentGate.name,
          ),
        );
      }
    } else {
      // Khi ở xa > 2km, giữ lộ trình từ cổng đã chọn đến đích
      if (state.activeRoute == null || state.activeRoute!.coordinates.isEmpty) {
        final route = _router.findShortestRoute(currentGate.insideCoordinate, destination.coordinate);
        if (route.coordinates.isNotEmpty && state.isNavigating) {
          state = state.copyWith(selectedGate: currentGate, activeRoute: route);
        }
      }
    }
  }

  /// Tinh lai route (khi graph thay doi hoac doi cong)
  void _recalculateRoute() {
    final destination = state.selectedLocation;
    if (destination == null) return;
    if (state.isNavigating) {
      startNavigationTo(destination);
    }
  }

  Future<void> fetchLocationsFromBackend() async {
    final dio = ref.read(dioProvider);
    try {
      final response = await dio.get(ApiEndpoints.campusLocations);
      if (!ref.mounted) return;
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['locations'] is List) {
          final List<dynamic> list = data['locations'];
          final parsed = list
              .map((item) => CampusLocationItem.fromJson(
                  item as Map<String, dynamic>))
              .where((loc) => loc.lat != 0.0 && loc.lng != 0.0)
              .toList();
          if (parsed.isNotEmpty && ref.mounted) {
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
      if (!ref.mounted) return;
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
          if (parsedGates.isNotEmpty && ref.mounted) {
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
    if (location == null) {
      state = state.copyWith(
        selectedLocation: null,
        isNavigating: false,
        activeRoute: null,
      );
      return;
    }

    final isMedical = location.category == 'Y tế' ||
        location.name.toLowerCase().contains('bệnh viện') ||
        location.building.toLowerCase().contains('bệnh viện') ||
        location.id == 4;

    final orig = state.userPosition ?? const LatLng(12.65138, 108.02360);
    final autoGate = state.userForcedGate ??
        CampusDijkstraRouter.getBestGate(
          origin: orig,
          destination: location.coordinate,
          isEntering: true,
          isMedicalDestination: isMedical,
          availableGates: state.gates,
        );

    state = state.copyWith(
      selectedLocation: location,
      selectedGate: autoGate,
      isNavigating: false,
      activeRoute: null,
    );
  }

  void selectGate(CampusGate gate) {
    state = state.copyWith(
      selectedGate: gate,
      userForcedGate: gate,
    );
    if (state.selectedLocation != null) {
      startNavigationTo(state.selectedLocation!, forcedGate: gate);
    }
  }

  void clearRoutingError() {
    state = state.copyWith(routingError: null);
  }

  void clearRoutingNotice() {
    state = state.copyWith(routingNotice: null);
  }

  Future<void> startNavigationTo(
    CampusLocationItem destination, {
    CampusGate? forcedGate,
  }) async {
    final effectiveForcedGate = forcedGate ?? state.userForcedGate;
    final isMedical = destination.category == 'Y tế' ||
        destination.name.toLowerCase().contains('bệnh viện') ||
        destination.building.toLowerCase().contains('bệnh viện') ||
        destination.id == 4;

    final userPos = state.userPosition;

    // 1. Trường hợp người dùng đang ở trong khuôn viên và KHÔNG chỉ định cổng thủ công:
    // Chạy Dijkstra nội bộ trực tiếp từ vị trí GPS đến đích
    if (userPos != null && CampusDijkstraRouter.isInsideCampus(userPos) && effectiveForcedGate == null) {
      final route = _router.findShortestRoute(
        userPos,
        destination.coordinate,
      );
      if (route.coordinates.isEmpty) {
        state = state.copyWith(
          selectedLocation: destination,
          activeRoute: null,
          isNavigating: false,
          routingError: 'Không tìm thấy đường đi bộ đến ${destination.name}',
        );
        return;
      }
      state = state.copyWith(
        selectedLocation: destination,
        activeRoute: route,
        isNavigating: true,
        routingError: null,
        routingNotice: null,
      );
      return;
    }

    // 2. Điểm xuất phát (Origin):
    // - Nếu có GPS thực tế: dùng userPos (nếu userPos ở trong nhưng người dùng ép cổng: dùng forcedGate.outsideCoordinate)
    // - Nếu chưa có GPS (hoặc userPos ở trong nhưng ép cổng): dùng forcedGate?.outsideCoordinate ?? LatLng(12.65138, 108.02360) (mặc định LTDDDNT)
    final LatLng orig;
    if (effectiveForcedGate != null && userPos != null && CampusDijkstraRouter.isInsideCampus(userPos)) {
      orig = effectiveForcedGate.outsideCoordinate;
    } else {
      orig = userPos ?? (effectiveForcedGate?.outsideCoordinate ?? const LatLng(12.65138, 108.02360));
    }

    // 3. Tính toán toàn bộ tuyến đường đa chế độ bằng calculateRoute (chuẩn 100% LTDDDNT)
    state = state.copyWith(isLoadingPaths: true);
    final externalService = ExternalRoutingService(ref.read(dioProvider));

    final route = await _router.calculateRoute(
      origin: orig,
      destination: destination.coordinate,
      preferredGateId: effectiveForcedGate?.id,
      availableGates: state.gates,
      isMedicalDestination: isMedical,
      externalRoutingService: externalService,
    );

    if (route.coordinates.isEmpty) {
      state = state.copyWith(
        selectedLocation: destination,
        activeRoute: null,
        isNavigating: false,
        isLoadingPaths: false,
        routingError: 'Không tìm thấy đường đi bộ đến ${destination.name}',
      );
      return;
    }

    final chosenGate = route.gate ?? effectiveForcedGate ?? state.selectedGate;
    String? kmNotice;
    if (userPos != null) {
      final directDist = calculateHaversineDistance(
        userPos.latitude, userPos.longitude, chosenGate.lat, chosenGate.lng,
      );
      if (directDist > 2000.0) {
        kmNotice = 'Vị trí hiện tại cách trường ${(directDist / 1000).toStringAsFixed(1)}km (>2km). Lộ trình xuất phát từ ${chosenGate.name}.';
      }
    }

    state = state.copyWith(
      selectedLocation: destination,
      selectedGate: chosenGate,
      activeRoute: route,
      isNavigating: true,
      isLoadingPaths: false,
      routingError: null,
      routingNotice: kmNotice,
    );
  }

  void stopNavigation() {
    state = state.copyWith(
      isNavigating: false,
      activeRoute: null,
      userForcedGate: null,
      routingError: null,
      routingNotice: null,
    );
  }

  /// Xoá trạng thái tìm kiếm, chọn toà nhà khi rời khỏi map (chỉ thực hiện khi KHÔNG đang dẫn đường)
  void resetExploreState() {
    if (state.isNavigating) return;

    state = state.copyWith(
      selectedLocation: null,
      searchQuery: '',
      selectedCategory: 'Tat ca',
      userForcedGate: null,
      activeRoute: null,
      routingError: null,
    );
  }
}

final mapProvider =
    NotifierProvider<MapNotifier, MapState>(MapNotifier.new);
