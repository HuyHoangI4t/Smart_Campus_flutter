import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/campus_constants.dart';
import '../../../core/widgets/nav_header.dart';
import '../providers/map_provider.dart';
import '../widgets/map_gate_selector_card.dart';
import '../widgets/map_location_detail_card.dart';
import '../widgets/map_navigation_bar.dart';
import '../widgets/map_top_search_bar.dart';

extension _LatLngToMl on ll.LatLng {
  ml.LatLng toMl() => ml.LatLng(latitude, longitude);
}

extension _LatLngListToMl on List<ll.LatLng> {
  List<ml.LatLng> toMl() => map((c) => c.toMl()).toList();
}

String _colorToHex(Color color) {
  final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
  final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
  final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
  return '#$r$g$b';
}

/// M�n h�nh B?n d? khu�n vi�n tru?ng �?i h?c T�y Nguy�n
/// Vector Map GPU (MapLibre GL), 3D Buildings & Perspective Tilt, Satellite & Vector tile layers.
class CampusMapScreen extends ConsumerStatefulWidget {
  final String? initialBuildingCode;

  const CampusMapScreen({super.key, this.initialBuildingCode});

  @override
  ConsumerState<CampusMapScreen> createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends ConsumerState<CampusMapScreen> {
  ml.MapLibreMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();

  bool _isSatellite = false;
  bool _is3D = true;
  bool _isStyleLoaded = false;
  bool _initialBuildingFocused = false;

  final List<ml.Circle> _locationCircles = [];
  final List<ml.Symbol> _locationSymbols = [];
  final List<ml.Circle> _gateCircles = [];
  final List<ml.Symbol> _gateSymbols = [];

  ml.Fill? _boundaryFill;
  ml.Line? _boundaryLine;
  ml.Line? _routeGlowLine;
  ml.Line? _routeCoreLine;
  ml.Circle? _userRing;
  ml.Circle? _userDot;

  static const String _streetStyle = ml.MapLibreStyles.openfreemapLiberty;

  static const String _satelliteStyle = '''{
  "version": 8,
  "sources": {
    "esri-satellite": {
      "type": "raster",
      "tiles": [
        "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}"
      ],
      "tileSize": 256
    }
  },
  "layers": [
    {
      "id": "esri-satellite-layer",
      "type": "raster",
      "source": "esri-satellite",
      "minzoom": 0,
      "maxzoom": 20
    }
  ]
}''';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialBuildingFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(ml.MapLibreMapController controller) {
    _mapController = controller;

    controller.onCircleTapped.add((circle) {
      _handleAnnotationTapped(circle.data);
    });

    controller.onSymbolTapped.add((symbol) {
      _handleAnnotationTapped(symbol.data);
    });
  }

  void _handleAnnotationTapped(Map<String, dynamic>? data) {
    if (data == null) return;
    final type = data['type'] as String?;
    final rawId = data['id'];

    if (type == 'location' && rawId != null) {
      final locId = rawId is int ? rawId : int.tryParse(rawId.toString());
      if (locId == null) return;
      final locations = ref.read(mapProvider).locations;
      final match = locations.where((l) => l.id == locId);
      if (match.isNotEmpty) {
        final loc = match.first;
        ref.read(mapProvider.notifier).selectLocation(loc);
        _mapController?.animateCamera(
          ml.CameraUpdate.newCameraPosition(
            ml.CameraPosition(
              target: loc.coordinate.toMl(),
              zoom: 17.8,
              tilt: _is3D ? 50.0 : 0.0,
            ),
          ),
        );
      }
    } else if (type == 'gate' && rawId != null) {
      final gateId = rawId.toString();
      final gates = ref.read(mapProvider).gates;
      final match = gates.where((g) => g.id == gateId);
      if (match.isNotEmpty) {
        ref.read(mapProvider.notifier).selectGate(match.first);
      }
    }
  }

  Future<void> _onStyleLoaded() async {
    _isStyleLoaded = true;
    await _drawCampusBoundary();
    await _syncGates();
    await _syncLocations();
    await _syncRoute();
    await _syncUserPosition();
    _checkInitialBuildingFocus();
  }

  void _checkInitialBuildingFocus() {
    if (_initialBuildingFocused || !_isStyleLoaded) return;
    if (widget.initialBuildingCode != null && widget.initialBuildingCode!.isNotEmpty) {
      _initialBuildingFocused = true;
      _focusOnBuilding(widget.initialBuildingCode!);
    }
  }

  void _focusOnBuilding(String buildingCode) {
    final locations = ref.read(mapProvider).locations;
    final match = locations.firstWhere(
      (l) =>
          l.building.toLowerCase().contains(buildingCode.toLowerCase()) ||
          l.name.toLowerCase().contains(buildingCode.toLowerCase()),
      orElse: () => locations.first,
    );

    ref.read(mapProvider.notifier).selectLocation(match);
    _mapController?.animateCamera(
      ml.CameraUpdate.newCameraPosition(
        ml.CameraPosition(
          target: match.coordinate.toMl(),
          zoom: 18.0,
          tilt: _is3D ? 50.0 : 0.0,
        ),
      ),
    );
  }

  Future<void> _drawCampusBoundary() async {
    if (_mapController == null) return;

    if (_boundaryFill != null) {
      await _mapController?.removeFill(_boundaryFill!);
      _boundaryFill = null;
    }
    if (_boundaryLine != null) {
      await _mapController?.removeLine(_boundaryLine!);
      _boundaryLine = null;
    }

    final boundaryCoords = CampusConstants.campusBoundary.toMl();

    _boundaryFill = await _mapController?.addFill(
      ml.FillOptions(
        geometry: [boundaryCoords],
        fillColor: '#0F172A',
        fillOpacity: _isSatellite ? 0.04 : 0.07,
      ),
    );

    _boundaryLine = await _mapController?.addLine(
      ml.LineOptions(
        geometry: boundaryCoords,
        lineColor: '#0F172A',
        lineWidth: 3.2,
        lineOpacity: 0.75,
      ),
    );
  }

  Future<void> _syncGates() async {
    if (_mapController == null || !_isStyleLoaded) return;

    if (_gateCircles.isNotEmpty) {
      await _mapController?.removeCircles(_gateCircles);
      _gateCircles.clear();
    }
    if (_gateSymbols.isNotEmpty) {
      await _mapController?.removeSymbols(_gateSymbols);
      _gateSymbols.clear();
    }

    final mapState = ref.read(mapProvider);
    final gates = mapState.gates;
    final selectedGate = mapState.selectedGate;

    final circleOptionsList = <ml.CircleOptions>[];
    final circleDataList = <Map<String, dynamic>>[];
    final symbolOptionsList = <ml.SymbolOptions>[];
    final symbolDataList = <Map<String, dynamic>>[];

    for (final gate in gates) {
      final isSelected = gate.id == selectedGate.id;
      circleOptionsList.add(
        ml.CircleOptions(
          geometry: gate.coordinate.toMl(),
          circleRadius: isSelected ? 12.0 : 9.5,
          circleColor: '#0F172A',
          circleStrokeWidth: isSelected ? 3.0 : 2.0,
          circleStrokeColor: isSelected ? '#38BDF8' : '#FFFFFF',
        ),
      );
      circleDataList.add({'type': 'gate', 'id': gate.id});

      symbolOptionsList.add(
        ml.SymbolOptions(
          geometry: gate.coordinate.toMl(),
          textField: gate.name,
          textSize: 11.5,
          textColor: '#0F172A',
          textHaloColor: '#FFFFFF',
          textHaloWidth: 2.0,
          textOffset: const Offset(0, 1.4),
        ),
      );
      symbolDataList.add({'type': 'gate', 'id': gate.id});
    }

    final createdCircles = await _mapController?.addCircles(circleOptionsList, circleDataList);
    if (createdCircles != null) _gateCircles.addAll(createdCircles);

    final createdSymbols = await _mapController?.addSymbols(symbolOptionsList, symbolDataList);
    if (createdSymbols != null) _gateSymbols.addAll(createdSymbols);
  }

  Future<void> _syncLocations() async {
    if (_mapController == null || !_isStyleLoaded) return;

    if (_locationCircles.isNotEmpty) {
      await _mapController?.removeCircles(_locationCircles);
      _locationCircles.clear();
    }
    if (_locationSymbols.isNotEmpty) {
      await _mapController?.removeSymbols(_locationSymbols);
      _locationSymbols.clear();
    }

    final mapState = ref.read(mapProvider);
    final locations = mapState.filteredLocations;
    if (locations.isEmpty) return;

    final circleOptionsList = <ml.CircleOptions>[];
    final circleDataList = <Map<String, dynamic>>[];
    final symbolOptionsList = <ml.SymbolOptions>[];
    final symbolDataList = <Map<String, dynamic>>[];

    for (final loc in locations) {
      final isSelected = loc.id == mapState.selectedLocation?.id;
      circleOptionsList.add(
        ml.CircleOptions(
          geometry: loc.coordinate.toMl(),
          circleRadius: isSelected ? 13.0 : 8.5,
          circleColor: _colorToHex(loc.color),
          circleStrokeWidth: isSelected ? 3.5 : 2.0,
          circleStrokeColor: isSelected ? '#FACC15' : '#FFFFFF',
        ),
      );
      circleDataList.add({'type': 'location', 'id': loc.id});

      symbolOptionsList.add(
        ml.SymbolOptions(
          geometry: loc.coordinate.toMl(),
          textField: loc.name,
          textSize: 11.0,
          textColor: '#0F172A',
          textHaloColor: '#FFFFFF',
          textHaloWidth: 1.5,
          textOffset: const Offset(0, 1.3),
        ),
      );
      symbolDataList.add({'type': 'location', 'id': loc.id});
    }

    final createdCircles = await _mapController?.addCircles(circleOptionsList, circleDataList);
    if (createdCircles != null) _locationCircles.addAll(createdCircles);

    final createdSymbols = await _mapController?.addSymbols(symbolOptionsList, symbolDataList);
    if (createdSymbols != null) _locationSymbols.addAll(createdSymbols);
  }

  Future<void> _syncRoute() async {
    if (_mapController == null || !_isStyleLoaded) return;

    if (_routeGlowLine != null) {
      await _mapController?.removeLine(_routeGlowLine!);
      _routeGlowLine = null;
    }
    if (_routeCoreLine != null) {
      await _mapController?.removeLine(_routeCoreLine!);
      _routeCoreLine = null;
    }

    final route = ref.read(mapProvider).activeRoute;
    if (route != null && route.coordinates.isNotEmpty) {
      final coords = route.coordinates.toMl();
      _routeGlowLine = await _mapController?.addLine(
        ml.LineOptions(
          geometry: coords,
          lineColor: '#3B82F6',
          lineWidth: 8.5,
          lineOpacity: 0.35,
          lineJoin: 'round',
        ),
      );
      _routeCoreLine = await _mapController?.addLine(
        ml.LineOptions(
          geometry: coords,
          lineColor: '#2563EB',
          lineWidth: 4.5,
          lineOpacity: 1.0,
          lineJoin: 'round',
        ),
      );
    }
  }

  Future<void> _syncUserPosition() async {
    if (_mapController == null || !_isStyleLoaded) return;

    if (_userRing != null) {
      await _mapController?.removeCircle(_userRing!);
      _userRing = null;
    }
    if (_userDot != null) {
      await _mapController?.removeCircle(_userDot!);
      _userDot = null;
    }

    final pos = ref.read(mapProvider).userPosition;
    if (pos != null) {
      _userRing = await _mapController?.addCircle(
        ml.CircleOptions(
          geometry: pos.toMl(),
          circleRadius: 14.0,
          circleColor: '#3B82F6',
          circleOpacity: 0.25,
        ),
      );
      _userDot = await _mapController?.addCircle(
        ml.CircleOptions(
          geometry: pos.toMl(),
          circleRadius: 7.0,
          circleColor: '#2563EB',
          circleStrokeWidth: 2.5,
          circleStrokeColor: '#FFFFFF',
        ),
      );
    }
  }

  void _toggleSatellite() {
    setState(() => _isSatellite = !_isSatellite);
    _isStyleLoaded = false;
    _mapController?.setStyle(_isSatellite ? _satelliteStyle : _streetStyle);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isSatellite ? 'Đã chuyển sang chế độ ảnh vệ tinh' : 'Đã chuyển sang bản đồ vector 3D'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggle3D() {
    setState(() => _is3D = !_is3D);
    _mapController?.animateCamera(
      ml.CameraUpdate.tiltTo(_is3D ? 50.0 : 0.0),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_is3D ? 'Đã bật chế độ góc nhìn 3D vector (nghiêng 50°)' : 'Đã chuyển về góc nhìn phẳng 2D'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _centerCampus() {
    final userPos = ref.read(mapProvider).userPosition;
    _mapController?.animateCamera(
      ml.CameraUpdate.newCameraPosition(
        ml.CameraPosition(
          target: (userPos ?? CampusConstants.campusCenter).toMl(),
          zoom: 17.2,
          tilt: _is3D ? 50.0 : 0.0,
        ),
      ),
    );
  }

  void _fitBounds() {
    _mapController?.animateCamera(
      ml.CameraUpdate.newCameraPosition(
        ml.CameraPosition(
          target: CampusConstants.campusCenter.toMl(),
          zoom: 16.5,
          tilt: _is3D ? 45.0 : 0.0,
          bearing: 0.0,
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider);

    ref.listen<MapState>(mapProvider, (prev, next) {
      if (next.routingError != null && prev?.routingError != next.routingError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(next.routingError!)),
              ],
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
        ref.read(mapProvider.notifier).clearRoutingError();
      }
      if (!_isStyleLoaded) return;
      if (prev?.activeRoute != next.activeRoute) {
        _syncRoute();
      }
      if (prev?.selectedGate != next.selectedGate || prev?.gates != next.gates) {
        _syncGates();
      }
      if (prev?.selectedLocation != next.selectedLocation ||
          prev?.selectedCategory != next.selectedCategory ||
          prev?.searchQuery != next.searchQuery ||
          prev?.locations != next.locations) {
        _syncLocations();
      }
      if (prev?.userPosition != next.userPosition) {
        _syncUserPosition();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ─── 1. NAVHEADER (Navy #132F73) ───
          const NavHeader(
            title: 'Bản đồ khuôn viên',
            subtitle: 'Đại học Tây Nguyên • Vector 3D & Vệ tinh',
          ),

          // ─── 2. MAP WITH OVERLAYS ───
          Expanded(
            child: Stack(
              children: [
                // 2.1 Core MapLibre Vector Map Engine
                ml.MapLibreMap(
                  initialCameraPosition: ml.CameraPosition(
                    target: CampusConstants.campusCenter.toMl(),
                    zoom: 16.5,
                    tilt: 45.0,
                    bearing: 0.0,
                  ),
                  styleString: _isSatellite ? _satelliteStyle : _streetStyle,
                  onMapCreated: _onMapCreated,
                  onStyleLoadedCallback: _onStyleLoaded,
                  onMapClick: (point, coordinates) {
                    ref.read(mapProvider.notifier).selectLocation(null);
                  },
                  rotateGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                  zoomGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  doubleClickZoomEnabled: true,
                  trackCameraPosition: false,
                  compassEnabled: false,
                  logoEnabled: false,
                  attributionButtonPosition: ml.AttributionButtonPosition.bottomLeft,
                  annotationOrder: const [
                    ml.AnnotationType.fill,
                    ml.AnnotationType.line,
                    ml.AnnotationType.circle,
                    ml.AnnotationType.symbol,
                  ],
                ),

                // 2.2 Top Floating Overlay
                Positioned(
                  top: 10,
                  left: 14,
                  right: 14,
                  child: mapState.isNavigating
                      ? MapGateSelectorCard(
                          selectedGate: mapState.selectedGate,
                          onSelectGate: (gate) {
                            ref.read(mapProvider.notifier).selectGate(gate);
                          },
                        )
                      : MapTopSearchBar(
                          searchController: _searchController,
                          selectedCategory: mapState.selectedCategory,
                          totalCount: mapState.locations.length,
                          onSearchChanged: (val) {
                            ref.read(mapProvider.notifier).updateSearch(val);
                          },
                          onCategorySelected: (cat) {
                            ref.read(mapProvider.notifier).selectCategory(cat);
                          },
                          onClearSearch: () {
                            _searchController.clear();
                            ref.read(mapProvider.notifier).updateSearch('');
                          },
                        ),
                ),

                if (mapState.isLoadingPaths)
                  Positioned(
                    top: 70,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Đang nạp mạng lưới đường đi...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // 2.3 Right Floating Controls (5 nút điều khiển)
                Positioned(
                  right: 14,
                  bottom: (mapState.selectedLocation != null || mapState.isNavigating) ? 170 : 16,
                  child: Column(
                    children: [
                      // Nút chuyển chế độ 3D / 2D
                      _buildMapCircleBtn(
                        icon: Icons.view_in_ar,
                        iconColor: _is3D ? AppColors.accent : AppColors.primary,
                        badgeText: _is3D ? '3D' : '2D',
                        onTap: _toggle3D,
                      ),
                      const SizedBox(height: 8),

                      // Nút đổi lớp Bản đồ (Vệ tinh / Vector)
                      _buildMapCircleBtn(
                        icon: Icons.layers_outlined,
                        iconColor: _isSatellite ? AppColors.accent : AppColors.primary,
                        onTap: _toggleSatellite,
                      ),
                      const SizedBox(height: 8),

                      // Nút xoay hướng Bắc
                      _buildMapCircleBtn(
                        icon: Icons.explore_outlined,
                        iconColor: AppColors.danger,
                        onTap: () => _mapController?.animateCamera(ml.CameraUpdate.bearingTo(0.0)),
                      ),
                      const SizedBox(height: 8),

                      // Nút định vị vị trí hiện tại
                      _buildMapCircleBtn(
                        icon: Icons.my_location,
                        iconColor: AppColors.info,
                        onTap: _centerCampus,
                      ),
                      const SizedBox(height: 8),

                      // Nút phóng to toàn khuôn viên
                      _buildMapCircleBtn(
                        icon: Icons.fullscreen,
                        onTap: _fitBounds,
                      ),
                    ],
                  ),
                ),

                // 2.4 Bottom Overlay: Location Detail Card OR Navigation Bar
                if (mapState.isNavigating && mapState.selectedLocation != null)
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 12,
                    child: MapNavigationBar(
                      destination: mapState.selectedLocation!,
                      currentGate: mapState.selectedGate,
                      distanceMeters: mapState.activeRoute?.distanceMeters ?? 754,
                      walkingMinutes: mapState.activeRoute?.estimatedWalkingMinutes ?? 10,
                      isHybrid: mapState.activeRoute?.isHybrid ?? false,
                      viaGateName: mapState.activeRoute?.viaGateName,
                      onStopNavigation: () {
                        ref.read(mapProvider.notifier).stopNavigation();
                      },
                    ),
                  )
                else if (mapState.selectedLocation != null)
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 12,
                    child: MapLocationDetailCard(
                      location: mapState.selectedLocation!,
                      currentGate: mapState.selectedGate,
                      onClose: () {
                        ref.read(mapProvider.notifier).selectLocation(null);
                      },
                      onStartNavigation: () {
                        final loc = mapState.selectedLocation!;
                        ref.read(mapProvider.notifier).startNavigationTo(loc);
                        final start = mapState.userPosition ?? mapState.selectedGate.coordinate;
                        final end = loc.coordinate;
                        final centerLat = (start.latitude + end.latitude) / 2;
                        final centerLng = (start.longitude + end.longitude) / 2;
                        _mapController?.animateCamera(
                          ml.CameraUpdate.newCameraPosition(
                            ml.CameraPosition(
                              target: ml.LatLng(centerLat, centerLng),
                              zoom: 17.2,
                              tilt: _is3D ? 50.0 : 0.0,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCircleBtn({
    required IconData icon,
    Color iconColor = AppColors.primary,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Center(
          child: badgeText != null
              ? Text(
                  badgeText,
                  style: TextStyle(
                    color: iconColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                )
              : Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }
}


