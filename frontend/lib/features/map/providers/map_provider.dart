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
import '../../../core/utils/dijkstra.dart';

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
  });

  List<CampusLocationItem> get filteredLocations {
    return locations.where((loc) {
      final matchesCategory =
          selectedCategory == 'Tat ca' || loc.category == selectedCategory;
      final matchesQuery = searchQuery.isEmpty ||
          loc.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          loc.building.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
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

  /// Cap nhat khoang cach live khi user di chuyen
  void _updateLiveNavigation(LatLng currentPos) {
    final destination = state.selectedLocation;
    if (destination == null) return;

    final route = _router.findShortestRoute(currentPos, destination.coordinate);
    state = state.copyWith(
      activeRoute: route,
    );
  }

  /// Tinh lai route (khi graph thay doi hoac doi cong)
  void _recalculateRoute() {
    final destination = state.selectedLocation;
    if (destination == null) return;

    final start = state.userPosition ?? state.selectedGate.coordinate;
    final route = _router.findShortestRoute(start, destination.coordinate);
    state = state.copyWith(activeRoute: route);
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

  void startNavigationTo(CampusLocationItem destination) {
    final start = state.userPosition ?? state.selectedGate.coordinate;
    final end = destination.coordinate;

    final route = _router.findShortestRoute(start, end);

    state = state.copyWith(
      selectedLocation: destination,
      activeRoute: route,
      isNavigating: true,
    );
  }

  void stopNavigation() {
    state = state.copyWith(
      isNavigating: false,
      activeRoute: null,
    );
  }
}

final mapProvider =
    NotifierProvider<MapNotifier, MapState>(MapNotifier.new);
