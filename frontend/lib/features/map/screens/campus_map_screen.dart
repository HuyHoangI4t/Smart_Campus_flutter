import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/campus_constants.dart';
import '../../../core/widgets/nav_header.dart';
import '../providers/map_provider.dart';
import '../widgets/map_gate_marker.dart';
import '../widgets/map_gate_selector_card.dart';
import '../widgets/map_location_detail_card.dart';
import '../widgets/map_navigation_bar.dart';
import '../widgets/map_top_search_bar.dart';

/// Màn hình Bản đồ khuôn viên trường Đại học Tây Nguyên
/// (Chuẩn 1:1 theo 09_map_campus_overview.jpg & 10_map_routing_navigation.jpg)
/// Tuân thủ quy chuẩn: Clean Architecture, Modular Widgets (<300 lines), Const constructors,
/// Touch Target >= 44px, Dijkstra Router, Satellite & Street tile layers.
class CampusMapScreen extends ConsumerStatefulWidget {
  final String? initialBuildingCode;

  const CampusMapScreen({super.key, this.initialBuildingCode});

  @override
  ConsumerState<CampusMapScreen> createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends ConsumerState<CampusMapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSatellite = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialBuildingCode != null && widget.initialBuildingCode!.isNotEmpty) {
        _focusOnBuilding(widget.initialBuildingCode!);
      }
    });
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
    _mapController.move(match.coordinate, 18.0);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSatellite() {
    setState(() => _isSatellite = !_isSatellite);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isSatellite ? 'Đã chuyển sang chế độ ảnh vệ tinh' : 'Đã chuyển sang bản đồ đường phố'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _centerCampus() {
    final userPos = ref.read(mapProvider).userPosition;
    _mapController.move(userPos ?? CampusConstants.campusCenter, 16.8);
  }

  void _fitBounds() {
    _mapController.move(CampusConstants.campusCenter, 16.2);
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ─── 1. NAVHEADER (Navy #132F73) ───
          const NavHeader(
            title: 'Bản đồ khuôn viên',
            subtitle: 'Đại học Tây Nguyên • Khuôn viên nội bộ',
          ),

          // ─── 2. MAP WITH OVERLAYS ───
          Expanded(
            child: Stack(
              children: [
                // 2.1 Core Map Layer
                FlutterMap(
                  mapController: _mapController,
                  options: const MapOptions(
                    initialCenter: CampusConstants.campusCenter,
                    initialZoom: 16.5,
                    minZoom: 14.5,
                    maxZoom: 19.0,
                  ),
                  children: [
                    // Lớp gạch nền Bản đồ (OSM hoặc Vệ tinh Esri)
                    TileLayer(
                      urlTemplate: _isSatellite
                          ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                          : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.smartcampus.app',
                    ),

                    // Lớp ranh giới khuôn viên trường ĐH Tây Nguyên (Polygon viền tối)
                    PolygonLayer(
                      polygons: [
                        Polygon(
                          points: CampusConstants.campusBoundary,
                          borderColor: const Color(0xFF0F172A),
                          borderStrokeWidth: 3.5,
                          color: const Color(0x0C0F172A),
                        ),
                      ],
                    ),

                    // Lớp Polyline cho tuyến đường đi bộ Dijkstra (Glow + Core)
                    if (mapState.activeRoute != null && mapState.activeRoute!.coordinates.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: mapState.activeRoute!.coordinates,
                            strokeWidth: 10.0,
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                          ),
                          Polyline(
                            points: mapState.activeRoute!.coordinates,
                            strokeWidth: 5.5,
                            color: const Color(0xFF2563EB),
                          ),
                        ],
                      ),

                    // Lớp Markers
                    MarkerLayer(
                      markers: [
                        // Cổng trường (3 cổng dạng Pill đen viền phát sáng)
                        for (final gate in mapState.gates)
                          Marker(
                            point: gate.coordinate,
                            width: 140,
                            height: 38,
                            alignment: Alignment.center,
                            child: MapGateMarker(
                              gate: gate,
                              isSelected: mapState.selectedGate.id == gate.id,
                              onTap: () {
                                ref.read(mapProvider.notifier).selectGate(gate);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Đã chọn điểm xuất phát: ${gate.name}'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ),

                        // 40 Địa điểm trong trường (Marker tròn màu sắc + icon trắng)
                        for (final loc in mapState.filteredLocations)
                          Marker(
                            point: loc.coordinate,
                            width: 44,
                            height: 44,
                            child: GestureDetector(
                              onTap: () {
                                ref.read(mapProvider.notifier).selectLocation(loc);
                                _mapController.move(loc.coordinate, 18.0);
                              },
                              child: AnimatedScale(
                                duration: const Duration(milliseconds: 200),
                                scale: mapState.selectedLocation?.id == loc.id ? 1.25 : 1.0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: loc.color,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.35),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Icon(loc.icon, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ),

                        // Vị trí người dùng (Chấm xanh phát sáng + Mũi tên la bàn xoay)
                        if (mapState.userPosition != null)
                          Marker(
                            point: mapState.userPosition!,
                            width: 48,
                            height: 48,
                            child: Transform.rotate(
                              angle: (mapState.compassHeading * (pi / 180.0)),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.navigation,
                                    color: AppColors.primary,
                                    size: 26,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                // 2.2 Top Floating Overlay
                Positioned(
                  top: 10,
                  left: 14,
                  right: 14,
                  child: mapState.isNavigating
                      // Khi đang điều hướng (10_map_routing_navigation.jpg)
                      ? MapGateSelectorCard(
                          selectedGate: mapState.selectedGate,
                          onSelectGate: (gate) {
                            ref.read(mapProvider.notifier).selectGate(gate);
                          },
                        )
                      // Khi xem tổng quan (09_map_campus_overview.jpg)
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

                // 2.3 Right Floating Controls (4 nút tròn)
                Positioned(
                  right: 14,
                  bottom: (mapState.selectedLocation != null || mapState.isNavigating) ? 170 : 16,
                  child: Column(
                    children: [
                      // Nút đổi lớp Bản đồ (Vệ tinh / Đường phố)
                      _buildMapCircleBtn(
                        icon: Icons.language,
                        iconColor: _isSatellite ? AppColors.accent : AppColors.primary,
                        onTap: _toggleSatellite,
                      ),
                      const SizedBox(height: 8),

                      // Nút xoay hướng Bắc
                      _buildMapCircleBtn(
                        icon: Icons.explore_outlined,
                        iconColor: AppColors.danger,
                        onTap: () => _mapController.rotate(0.0),
                      ),
                      const SizedBox(height: 8),

                      // Nút định vị vị trí hiện tại
                      _buildMapCircleBtn(
                        icon: Icons.my_location,
                        iconColor: AppColors.info,
                        onTap: _centerCampus,
                      ),
                      const SizedBox(height: 8),

                      // Nút phóng to thu nhỏ toàn khuôn viên
                      _buildMapCircleBtn(
                        icon: Icons.fullscreen,
                        onTap: _fitBounds,
                      ),
                    ],
                  ),
                ),

                // 2.4 Bottom Overlay: Location Detail Card OR Navigation Bar
                if (mapState.isNavigating && mapState.selectedLocation != null)
                  // Đang chỉ đường đi bộ (10_map_routing_navigation.jpg)
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 12,
                    child: MapNavigationBar(
                      destination: mapState.selectedLocation!,
                      currentGate: mapState.selectedGate,
                      distanceMeters: mapState.activeRoute?.distanceMeters ?? 754,
                      walkingMinutes: mapState.activeRoute?.estimatedWalkingMinutes ?? 10,
                      onStopNavigation: () {
                        ref.read(mapProvider.notifier).stopNavigation();
                      },
                    ),
                  )
                else if (mapState.selectedLocation != null)
                  // Xem chi tiết địa điểm đã chọn (09_map_campus_overview.jpg)
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
                        _mapController.move(LatLng(centerLat, centerLng), 17.0);
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
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }
}
