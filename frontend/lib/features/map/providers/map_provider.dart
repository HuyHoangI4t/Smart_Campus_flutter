import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/campus_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/dijkstra.dart';

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

  const MapState({
    this.locations = CampusConstants.campusLocations,
    this.gates = CampusConstants.gates,
    this.selectedCategory = 'Tất cả',
    this.searchQuery = '',
    this.selectedLocation,
    this.selectedGate = CampusConstants.defaultGate,
    this.activeRoute,
    this.isNavigating = false,
    this.compassHeading = 0.0,
    this.userPosition,
  });

  List<CampusLocationItem> get filteredLocations {
    return locations.where((loc) {
      final matchesCategory =
          selectedCategory == 'Tất cả' || loc.category == selectedCategory;
      final matchesQuery = searchQuery.isEmpty ||
          loc.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          loc.building.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }

  MapState copyWith({
    List<CampusLocationItem>? locations,
    List<CampusGate>? gates,
    String? selectedCategory,
    String? searchQuery,
    CampusLocationItem? selectedLocation,
    CampusGate? selectedGate,
    DijkstraResult? activeRoute,
    bool? isNavigating,
    double? compassHeading,
    LatLng? userPosition,
  }) {
    return MapState(
      locations: locations ?? this.locations,
      gates: gates ?? this.gates,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      selectedGate: selectedGate ?? this.selectedGate,
      activeRoute: activeRoute ?? this.activeRoute,
      isNavigating: isNavigating ?? this.isNavigating,
      compassHeading: compassHeading ?? this.compassHeading,
      userPosition: userPosition ?? this.userPosition,
    );
  }
}

class MapNotifier extends Notifier<MapState> {
  final CampusDijkstraRouter _router = CampusDijkstraRouter();
  StreamSubscription? _compassSub;
  StreamSubscription? _positionSub;

  @override
  MapState build() {
    _initDijkstraRouter();
    _startCompassListening();
    _startLocationListening();
    fetchLocationsFromBackend();

    ref.onDispose(() {
      _compassSub?.cancel();
      _positionSub?.cancel();
    });

    return const MapState();
  }

  void _initDijkstraRouter() {
    _router.buildGraphFromPolylines(CampusConstants.defaultWalkways);
  }

  void _startCompassListening() {
    try {
      _compassSub = FlutterCompass.events?.listen((event) {
        if (event.heading != null) {
          state = state.copyWith(compassHeading: event.heading!);
        }
      });
    } catch (_) {}
  }

  Future<void> _startLocationListening() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3,
        ),
      ).listen(
        (pos) {
          state = state.copyWith(userPosition: LatLng(pos.latitude, pos.longitude));
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

  Future<void> fetchLocationsFromBackend() async {
    final dio = ref.read(dioProvider);
    try {
      final response = await dio.get(ApiEndpoints.campusLocations);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['locations'] is List) {
          final List<dynamic> list = data['locations'];
          final parsed = list
              .map((item) => CampusLocationItem.fromJson(item as Map<String, dynamic>))
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

  void updateSearch(String query) {
    state = state.copyWith(searchQuery: query);
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

final mapProvider = NotifierProvider<MapNotifier, MapState>(MapNotifier.new);
