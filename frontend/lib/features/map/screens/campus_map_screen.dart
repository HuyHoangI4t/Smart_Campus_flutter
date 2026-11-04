import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/campus_constants.dart';
import '../../../core/utils/dijkstra.dart';
import '../../../core/utils/haversine.dart';
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


/// M�n h�nh B?n d? khu�n vi�n tru?ng �?i h?c T�y Nguy�n
/// Vector Map GPU (MapLibre GL), 3D Buildings & Perspective Tilt, Satellite & Vector tile layers.
class CampusMapScreen extends ConsumerStatefulWidget {
  final String? initialBuildingCode;
  final String? initialRoomName;

  const CampusMapScreen({
    super.key,
    this.initialBuildingCode,
    this.initialRoomName,
  });

  @override
  ConsumerState<CampusMapScreen> createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends ConsumerState<CampusMapScreen> {
  ml.MapLibreMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();

  bool _isSatellite = false;
  bool _is3D = true;
  bool _isStyleLoaded = false;
  String? _selectedRoomName;
  String? _pendingFocusBuilding;
  String? _pendingFocusRoom;
  int _lastAnnotationTappedTime = 0;
  ml.CameraPosition? _currentCameraPosition;

  /// Tạo SymbolOptions an toàn, truyền đầy đủ tất cả thuộc tính để tránh lỗi null từ MapLibre engine
  static ml.SymbolOptions _createSafeSymbolOptions({
    required ml.LatLng geometry,
    required String iconImage,
    required double iconSize,
    required String textField,
    required double textSize,
    required String textColor,
    required String textHaloColor,
    required double textHaloWidth,
    String iconAnchor = 'center',
    String textAnchor = 'top',
    double textMaxWidth = 10.0,
    int zIndex = 1,
  }) {
    return ml.SymbolOptions(
      geometry: geometry,
      iconImage: iconImage,
      iconSize: iconSize,
      iconAnchor: iconAnchor,
      iconOffset: const Offset(0.0, 0.0),
      iconRotate: 0.0,
      iconOpacity: 1.0,
      iconColor: '#FFFFFF',
      iconHaloColor: '#FFFFFF',
      iconHaloWidth: 0.0,
      iconHaloBlur: 0.0,
      textField: textField,
      textSize: textSize,
      textColor: textColor,
      textHaloColor: textHaloColor,
      textHaloWidth: textHaloWidth,
      textHaloBlur: 0.0,
      textAnchor: textAnchor,
      textOffset: const Offset(0.0, 1.2),
      textRotate: 0.0,
      textOpacity: 1.0,
      textLetterSpacing: 0.0,
      textMaxWidth: textMaxWidth,
      textJustify: 'center',
      textTransform: 'none',
      zIndex: zIndex,
      draggable: false,
    );
  }

  final List<ml.Circle> _locationCircles = [];
  final List<ml.Symbol> _locationSymbols = [];
  final List<ml.Circle> _gateCircles = [];
  final List<ml.Symbol> _gateSymbols = [];

  static final Map<String, Uint8List> _iconBytesCache = {};
  final Set<String> _registeredImages = {};

  ml.Fill? _boundaryFill;
  ml.Line? _boundaryLine;
  ml.Line? _routeGlowLine;
  ml.Line? _routeCoreLine;
  ml.Circle? _userRing;
  ml.Circle? _userDot;

  static const String _streetStyle = ml.MapLibreStyles.openfreemapLiberty;

  static const String _satelliteStyle = '''{
  "version": 8,
  "name": "Campus Satellite Hybrid",
  "glyphs": "https://demotiles.maplibre.org/font/{fontstack}/{range}.pbf",
  "sprite": "https://demotiles.maplibre.org/styles/osm-bright-gl-style/sprite",
  "sources": {
    "google-satellite": {
      "type": "raster",
      "tiles": [
        "https://mt0.google.com/vt/lyrs=y&hl=vi&x={x}&y={y}&z={z}",
        "https://mt1.google.com/vt/lyrs=y&hl=vi&x={x}&y={y}&z={z}",
        "https://mt2.google.com/vt/lyrs=y&hl=vi&x={x}&y={y}&z={z}",
        "https://mt3.google.com/vt/lyrs=y&hl=vi&x={x}&y={y}&z={z}"
      ],
      "tileSize": 256,
      "maxzoom": 20
    }
  },
  "layers": [
    {
      "id": "satellite-background",
      "type": "background",
      "paint": {
        "background-color": "#0F172A"
      }
    },
    {
      "id": "google-satellite-layer",
      "type": "raster",
      "source": "google-satellite",
      "minzoom": 0,
      "maxzoom": 22
    }
  ]
}''';

  @override
  void initState() {
    super.initState();
    _selectedRoomName = widget.initialRoomName;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialBuildingFocus();
    });
  }

  @override
  void didUpdateWidget(CampusMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final targetBuilding = widget.initialBuildingCode;
    final targetRoom = widget.initialRoomName;
    if (targetBuilding != null && targetBuilding.isNotEmpty) {
      if (targetBuilding != oldWidget.initialBuildingCode || targetRoom != oldWidget.initialRoomName) {
        setState(() {
          _selectedRoomName = targetRoom;
        });
        _focusOnBuilding(targetBuilding, roomName: targetRoom);
      }
    }
  }

  @override
  void dispose() {
    final mapState = ref.read(mapProvider);
    if (!mapState.isNavigating) {
      ref.read(mapProvider.notifier).resetExploreState();
    }
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
    _lastAnnotationTappedTime = DateTime.now().millisecondsSinceEpoch;
    // Khi đang trong chế độ dẫn đường chỉ đường (như Google Maps), không cho phép nhấn sang địa điểm khác làm gián đoạn
    if (ref.read(mapProvider).isNavigating) return;

    final type = data['type'] as String?;
    final rawId = data['id'];

    if (type == 'location' && rawId != null) {
      final locId = rawId is int ? rawId : int.tryParse(rawId.toString());
      if (locId == null) return;
      final locations = ref.read(mapProvider).locations;
      final match = locations.where((l) => l.id == locId);
      if (match.isNotEmpty) {
        final loc = match.first;
        setState(() => _selectedRoomName = null);
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

  static IconData _getDisplayIcon(CampusLocationItem loc) {
    final name = loc.name.toLowerCase();
    final cat = loc.category.toLowerCase();

    if (name.contains('wc')) return Icons.wc_rounded;
    if (name.contains('gara') || name.contains('bãi xe') || name.contains('xe')) {
      return Icons.directions_car_rounded;
    }
    if (name.contains('căn tin') || name.contains('canteen') || name.contains('đảo sinh viên') || name.contains('cafe')) {
      return Icons.restaurant_rounded;
    }
    if (name.contains('thư viện')) return Icons.local_library_rounded;
    if (name.contains('bệnh viện') || name.contains('y tế') || name.contains('phòng khám')) {
      return Icons.local_hospital_rounded;
    }
    if (name.contains('hồ bơi')) return Icons.pool_rounded;
    if (name.contains('quần vợt')) return Icons.sports_tennis_rounded;
    if (name.contains('thể thao') || name.contains('thi đấu') || name.contains('sân')) {
      return Icons.fitness_center_rounded;
    }
    if (name.contains('thí nghiệm') || name.contains('công nghệ sinh học')) {
      return Icons.biotech_rounded;
    }
    if (name.contains('ký túc xá') || name.contains('ktx')) return Icons.apartment_rounded;
    if (name.contains('hội trường') || name.contains('400') || name.contains('200')) {
      return Icons.groups_rounded;
    }
    if (name.contains('nhà học') || name.contains('giảng đường') || name.contains('thực hành cao nguyên') || cat.contains('giảng đường')) {
      return Icons.school_rounded;
    }
    if (name.contains('điều hành') || name.contains('hiệu bộ') || name.contains('văn phòng') || cat.contains('hành chính')) {
      return Icons.business_center_rounded;
    }
    return loc.icon;
  }

  static Future<Uint8List> _generateMarkerPng({
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    double size = 96.0,
    bool isSelected = false,
    bool isNavigating = false,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final center = Offset(size / 2, size / 2);
    final radius = (size / 2) - 4.0;

    // 1. Drop shadow
    final shadowPaint = Paint()
      ..color = const Color(0x40000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawCircle(center + const Offset(0, 2.5), radius, shadowPaint);

    // 2. Outer border: Golden if selected/navigating, bright white otherwise
    final isHighlighted = isNavigating || isSelected;
    final borderPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = isHighlighted ? const Color(0xFFFACC15) : Colors.white;
    canvas.drawCircle(center, radius, borderPaint);

    // 3. Inner circle with category background color
    final borderWidth = isHighlighted ? 5.0 : 3.5;
    final innerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = backgroundColor;
    canvas.drawCircle(center, radius - borderWidth, innerPaint);

    // 4. White icon in the center (tăng tỷ lệ icon để nổi bật và dễ nhìn)
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: size * 0.50,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: iconColor,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - (textPainter.width / 2),
        center.dy - (textPainter.height / 2),
      ),
    );

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _ensureMarkerImage({
    required String key,
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    bool isSelected = false,
    bool isNavigating = false,
  }) async {
    if (_mapController == null) return;
    if (_registeredImages.contains(key)) return;

    Uint8List? bytes = _iconBytesCache[key];
    if (bytes == null) {
      bytes = await _generateMarkerPng(
        icon: icon,
        backgroundColor: backgroundColor,
        iconColor: iconColor,
        isSelected: isSelected,
        isNavigating: isNavigating,
      );
      _iconBytesCache[key] = bytes;
    }

    try {
      await _mapController?.addImage(key, bytes);
      _registeredImages.add(key);
    } catch (_) {}
  }

  Future<void> _onStyleLoaded() async {
    _isStyleLoaded = true;
    _registeredImages.clear();

    // 1. Reset tham chiếu annotations Style cũ mà không gọi remove...
    // (Native MapLibre engine đã tự giải phóng toàn bộ annotations khi style thay đổi)
    _locationSymbols.clear();
    _locationCircles.clear();
    _gateSymbols.clear();
    _gateCircles.clear();
    _boundaryFill = null;
    _boundaryLine = null;
    _routeGlowLine = null;
    _routeCoreLine = null;
    _userRing = null;
    _userDot = null;

    try {
      await _mapController?.setSymbolIconAllowOverlap(true);
      await _mapController?.setSymbolTextAllowOverlap(false);
    } catch (_) {}

    try {
      await _drawCampusBoundary();
    } catch (_) {}

    try {
      await _syncGates();
    } catch (_) {}

    try {
      await _syncLocations();
    } catch (_) {}

    try {
      await _syncRoute();
    } catch (_) {}

    try {
      await _syncUserPosition();
    } catch (_) {}

    _checkInitialBuildingFocus();
  }

  void _checkInitialBuildingFocus() {
    if (!_isStyleLoaded) return;
    final targetBuilding = _pendingFocusBuilding ?? widget.initialBuildingCode;
    final targetRoom = _pendingFocusRoom ?? widget.initialRoomName;
    if (targetBuilding != null && targetBuilding.isNotEmpty) {
      _focusOnBuilding(targetBuilding, roomName: targetRoom);
    }
  }

  CampusLocationItem? _findMatchingLocation(String query, List<CampusLocationItem> locations) {
    if (locations.isEmpty) return null;
    final q = query.toLowerCase().trim();

    // 1. Khớp chính xác hoặc chứa trong building / name
    for (final loc in locations) {
      final b = loc.building.toLowerCase();
      final n = loc.name.toLowerCase();
      if (b == q || n == q) return loc;
    }
    for (final loc in locations) {
      final b = loc.building.toLowerCase();
      final n = loc.name.toLowerCase();
      if (b.contains(q) || n.contains(q) || q.contains(b)) return loc;
    }

    // Chuẩn hóa bỏ khoảng trắng quanh dấu chấm/gạch ngang: "7.3. 18" -> "7.3.18"
    final normalizedQ = q.replaceAll(RegExp(r'\s*[\._]\s*'), '.').replaceAll(RegExp(r'\s+'), ' ');

    // 2. Dạng phòng học: [Nhà].[Tầng].[Phòng] hoặc [Nhà].[Phòng] (vd: 7.3.18, 7.3. 18, 2.20, 8.3.4, 9.2.04)
    final roomCodeMatch = RegExp(r'^(\d+)\.(\d+)(?:\.([0-9a-zA-Z_-]+))?').firstMatch(normalizedQ);
    if (roomCodeMatch != null) {
      final bNum = roomCodeMatch.group(1)!;
      for (final loc in locations) {
        final b = loc.building.toLowerCase();
        final n = loc.name.toLowerCase();
        if (b.contains('nhà học số $bNum') ||
            b.contains('nhà $bNum') ||
            n.contains('nhà học số $bNum') ||
            n.contains('nhà $bNum')) {
          return loc;
        }
      }
    }

    // 3. Dạng "Nhà 7", "Nha 7", "Nhà số 7", "Nhà học số 7"
    final nhaMatch = RegExp(r'^(?:nhà\s*học\s*số|nhà\s*học|nhà\s*số|nhà|nha)\s*(\d+)', caseSensitive: false).firstMatch(q);
    if (nhaMatch != null) {
      final bNum = nhaMatch.group(1)!;
      for (final loc in locations) {
        final b = loc.building.toLowerCase();
        final n = loc.name.toLowerCase();
        if (b.contains('nhà học số $bNum') ||
            b.contains('nhà $bNum') ||
            n.contains('nhà học số $bNum') ||
            n.contains('nhà $bNum')) {
          return loc;
        }
      }
    }

    // 4. Các địa danh đặc biệt (Hội trường, Thư viện, GDQP...)
    if (q.contains('400')) {
      final match = locations.where((l) => l.name.contains('400') || l.building.contains('Hội trường lớn') || l.building.contains('400'));
      if (match.isNotEmpty) return match.first;
    }
    if (q.contains('200')) {
      final match = locations.where((l) => l.name.contains('200') || l.building.contains('Hội trường vừa') || l.building.contains('200'));
      if (match.isNotEmpty) return match.first;
    }
    if (q.contains('thư viện') || q.contains('thu vien')) {
      final match = locations.where((l) => l.building.toLowerCase().contains('thư viện'));
      if (match.isNotEmpty) return match.first;
    }
    if (q.contains('gdqp') || q.contains('quốc phòng') || q.contains('quoc phong')) {
      final match = locations.where((l) => l.building.toLowerCase().contains('gdqp'));
      if (match.isNotEmpty) return match.first;
    }

    // 5. Tách số nhà học bất kỳ (vd: "7")
    final numMatch = RegExp(r'(?:nhà\s*học\s*số|nhà\s*học|nhà)?\s*([0-9]+)', caseSensitive: false).firstMatch(q);
    if (numMatch != null) {
      final num = numMatch.group(1);
      for (final loc in locations) {
        final b = loc.building.toLowerCase();
        final n = loc.name.toLowerCase();
        if (b.contains('nhà học số $num') || b.contains('nhà $num') || n.contains('nhà học số $num')) {
          return loc;
        }
      }
    }

    return locations.first;
  }

  void _focusOnBuilding(String buildingCode, {String? roomName}) {
    if (roomName != null && roomName.isNotEmpty) {
      _selectedRoomName = roomName;
    }

    if (_mapController == null || !_isStyleLoaded) {
      _pendingFocusBuilding = buildingCode;
      _pendingFocusRoom = roomName ?? _selectedRoomName;
      return;
    }
    _pendingFocusBuilding = null;
    _pendingFocusRoom = null;

    final locations = ref.read(mapProvider).locations;
    final match = _findMatchingLocation(buildingCode, locations);

    if (match != null) {
      ref.read(mapProvider.notifier).selectLocation(match);
      _mapController?.animateCamera(
        ml.CameraUpdate.newCameraPosition(
          ml.CameraPosition(
            target: match.coordinate.toMl(),
            zoom: 18.2,
            tilt: _is3D ? 45.0 : 0.0,
          ),
        ),
      );
    }
  }

  Future<void> _drawCampusBoundary() async {
    if (_mapController == null) return;

    if (_boundaryFill != null) {
      try { await _mapController?.removeFill(_boundaryFill!); } catch (_) {}
      _boundaryFill = null;
    }
    if (_boundaryLine != null) {
      try { await _mapController?.removeLine(_boundaryLine!); } catch (_) {}
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
      try { await _mapController?.removeCircles(_gateCircles); } catch (_) {}
      _gateCircles.clear();
    }
    if (_gateSymbols.isNotEmpty) {
      try { await _mapController?.removeSymbols(_gateSymbols); } catch (_) {}
      _gateSymbols.clear();
    }

    final mapState = ref.read(mapProvider);
    final selectedGate = mapState.selectedGate;
    // Khi đang dẫn đường: nếu GPS ở bên trong trường thì ẩn cổng, nếu xuất phát từ cổng hoặc hybrid thì hiện cổng
    final isUsingGpsInside = mapState.userPosition != null &&
        CampusDijkstraRouter.isInsideCampus(mapState.userPosition!);
    final gates = mapState.isNavigating
        ? (isUsingGpsInside ? <CampusGate>[] : [selectedGate])
        : mapState.gates;

    final symbolOptionsList = <ml.SymbolOptions>[];
    final symbolDataList = <Map<String, dynamic>>[];

    for (final gate in gates) {
      final isSelected = gate.id == selectedGate.id;
      final gateKey = 'gate_${gate.id}_${isSelected ? "sel" : "norm"}';

      await _ensureMarkerImage(
        key: gateKey,
        icon: Icons.door_sliding_outlined,
        backgroundColor: const Color(0xFF0F172A),
        iconColor: Colors.white,
        isSelected: isSelected,
      );

      symbolOptionsList.add(
        _createSafeSymbolOptions(
          geometry: gate.coordinate.toMl(),
          iconImage: gateKey,
          iconSize: isSelected ? 1.25 : 1.05,
          textField: gate.name,
          textSize: 11.5,
          textColor: '#0F172A',
          textHaloColor: '#FFFFFF',
          textHaloWidth: 2.2,
          textMaxWidth: 10.0,
          zIndex: isSelected ? 10 : 2,
        ),
      );
      symbolDataList.add({'type': 'gate', 'id': gate.id});
    }

    final createdSymbols = await _mapController?.addSymbols(symbolOptionsList, symbolDataList);
    if (createdSymbols != null) _gateSymbols.addAll(createdSymbols);
  }

  Future<void> _syncLocations() async {
    if (_mapController == null || !_isStyleLoaded) return;

    if (_locationCircles.isNotEmpty) {
      try { await _mapController?.removeCircles(_locationCircles); } catch (_) {}
      _locationCircles.clear();
    }
    if (_locationSymbols.isNotEmpty) {
      try { await _mapController?.removeSymbols(_locationSymbols); } catch (_) {}
      _locationSymbols.clear();
    }

    final mapState = ref.read(mapProvider);
    // Khi đang dẫn đường (isNavigating), ẩn toàn bộ các địa điểm khác (như Google Maps),
    // chỉ giữ lại duy nhất 1 điểm đích đến để tập trung quan sát tuyến đường
    final locations = mapState.isNavigating
        ? (mapState.selectedLocation != null ? [mapState.selectedLocation!] : <CampusLocationItem>[])
        : mapState.filteredLocations;

    if (locations.isEmpty) return;

    final symbolOptionsList = <ml.SymbolOptions>[];
    final symbolDataList = <Map<String, dynamic>>[];

    for (final loc in locations) {
      final isSelected = loc.id == mapState.selectedLocation?.id;
      final isNav = mapState.isNavigating;
      final locKey = 'loc_${loc.id}_${isNav ? "nav" : (isSelected ? "sel" : "norm")}';

      await _ensureMarkerImage(
        key: locKey,
        icon: _getDisplayIcon(loc),
        backgroundColor: loc.color,
        iconColor: Colors.white,
        isSelected: isSelected,
        isNavigating: isNav,
      );

      symbolOptionsList.add(
        _createSafeSymbolOptions(
          geometry: loc.coordinate.toMl(),
          iconImage: locKey,
          iconSize: isNav ? 1.45 : (isSelected ? 1.30 : 1.08),
          textField: loc.name,
          textSize: isNav ? 12.5 : 11.0,
          textColor: '#0F172A',
          textHaloColor: '#FFFFFF',
          textHaloWidth: 2.2,
          textMaxWidth: 12.0,
          zIndex: isNav ? 20 : (isSelected ? 15 : 5),
        ),
      );
      symbolDataList.add({'type': 'location', 'id': loc.id});
    }

    final createdSymbols = await _mapController?.addSymbols(symbolOptionsList, symbolDataList);
    if (createdSymbols != null) _locationSymbols.addAll(createdSymbols);
  }

  Future<void> _syncRoute() async {
    if (_mapController == null || !_isStyleLoaded) return;

    if (_routeGlowLine != null) {
      try { await _mapController?.removeLine(_routeGlowLine!); } catch (_) {}
      _routeGlowLine = null;
    }
    if (_routeCoreLine != null) {
      try { await _mapController?.removeLine(_routeCoreLine!); } catch (_) {}
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
      try { await _mapController?.removeCircle(_userRing!); } catch (_) {}
      _userRing = null;
    }
    if (_userDot != null) {
      try { await _mapController?.removeCircle(_userDot!); } catch (_) {}
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
    final nextSatellite = !_isSatellite;

    // Lưu lại vị trí camera hiện tại để không bị nhảy vị trí khi đổi style
    if (_mapController != null) {
      final cam = _mapController!.cameraPosition;
      if (cam != null) {
        _currentCameraPosition = cam;
      }
    }

    // Xóa danh sách ảnh đã đăng ký để nạp lại đầy đủ vào style mới
    _registeredImages.clear();

    setState(() {
      _isSatellite = nextSatellite;
      _isStyleLoaded = false;
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(nextSatellite
            ? 'Đã chuyển sang ảnh vệ tinh Google Hybrid'
            : 'Đã chuyển sang bản đồ vector 3D'),
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

  /// Khung hình camera thông minh khi bắt đầu hoặc đổi lộ trình chỉ đường
  void _zoomToRoute(DijkstraResult? route, CampusLocationItem? destination, CampusGate? gate) {
    if (_mapController == null || !_isStyleLoaded) return;
    if (route == null || route.coordinates.isEmpty) {
      if (destination != null) {
        _mapController?.animateCamera(
          ml.CameraUpdate.newCameraPosition(
            ml.CameraPosition(
              target: destination.coordinate.toMl(),
              zoom: 17.5,
              tilt: _is3D ? 45.0 : 0.0,
            ),
          ),
        );
      }
      return;
    }

    final coords = route.coordinates;
    double minLat = coords.first.latitude;
    double maxLat = coords.first.latitude;
    double minLng = coords.first.longitude;
    double maxLng = coords.first.longitude;

    for (final pt in coords) {
      if (pt.latitude < minLat) minLat = pt.latitude;
      if (pt.latitude > maxLat) maxLat = pt.latitude;
      if (pt.longitude < minLng) minLng = pt.longitude;
      if (pt.longitude > maxLng) maxLng = pt.longitude;
    }

    // Đảm bảo bounding box có kích thước tối thiểu để tránh zoom quá sát
    final latDiff = (maxLat - minLat).abs();
    final lngDiff = (maxLng - minLng).abs();
    if (latDiff < 0.0006) {
      final pad = (0.0006 - latDiff) / 2;
      minLat -= pad;
      maxLat += pad;
    }
    if (lngDiff < 0.0006) {
      final pad = (0.0006 - lngDiff) / 2;
      minLng -= pad;
      maxLng += pad;
    }

    try {
      _mapController?.animateCamera(
        ml.CameraUpdate.newLatLngBounds(
          ml.LatLngBounds(
            southwest: ml.LatLng(minLat, minLng),
            northeast: ml.LatLng(maxLat, maxLng),
          ),
          left: 45,
          top: 115,
          right: 45,
          bottom: 165,
        ),
      );
    } catch (_) {
      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;
      final maxSpan = math.max((maxLat - minLat).abs(), (maxLng - minLng).abs());
      double calcZoom = 17.5;
      if (maxSpan > 0.015) {
        calcZoom = 15.0;
      } else if (maxSpan > 0.008) {
        calcZoom = 15.8;
      } else if (maxSpan > 0.004) {
        calcZoom = 16.5;
      } else if (maxSpan > 0.002) {
        calcZoom = 17.2;
      }

      _mapController?.animateCamera(
        ml.CameraUpdate.newCameraPosition(
          ml.CameraPosition(
            target: ml.LatLng(centerLat, centerLng),
            zoom: calcZoom,
            tilt: _is3D ? 45.0 : 0.0,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider);

    ref.listen<MapState>(mapProvider, (prev, next) {
      if (next.routingNotice != null && prev?.routingNotice != next.routingNotice) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(next.routingNotice!)),
              ],
            ),
            backgroundColor: const Color(0xFF1E40AF),
            duration: const Duration(seconds: 4),
          ),
        );
        ref.read(mapProvider.notifier).clearRoutingNotice();
      }

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
      if (prev?.isNavigating != next.isNavigating) {
        _syncLocations();
        _syncGates();
        _syncRoute();
      }
      if (prev?.activeRoute != next.activeRoute) {
        _syncRoute();
      }
      if ((prev?.isNavigating != next.isNavigating && next.isNavigating) ||
          (next.isNavigating && prev?.activeRoute != next.activeRoute && next.activeRoute != null)) {
        _zoomToRoute(next.activeRoute, next.selectedLocation, next.selectedGate);
      }
      if (prev?.selectedGate != next.selectedGate || prev?.gates != next.gates) {
        _syncGates();
      }
      if (prev?.searchQuery != next.searchQuery) {
        _syncLocations();
        final q = next.searchQuery.trim();
        if (q.isNotEmpty && next.filteredLocations.isNotEmpty) {
          final matched = next.filteredLocations.first;
          setState(() {
            _selectedRoomName = q;
          });
          ref.read(mapProvider.notifier).selectLocation(matched);
          _mapController?.animateCamera(
            ml.CameraUpdate.newCameraPosition(
              ml.CameraPosition(
                target: matched.coordinate.toMl(),
                zoom: 18.2,
                tilt: _is3D ? 45.0 : 0.0,
              ),
            ),
          );
        } else if (q.isEmpty) {
          setState(() {
            _selectedRoomName = null;
          });
          ref.read(mapProvider.notifier).selectLocation(null);
        }
      } else if (prev?.selectedLocation != next.selectedLocation ||
          prev?.selectedCategory != next.selectedCategory ||
          prev?.locations != next.locations) {
        _syncLocations();
      }
      if (next.selectedLocation == null && next.searchQuery.isEmpty) {
        if (_searchController.text.isNotEmpty) {
          _searchController.clear();
        }
        if (_selectedRoomName != null) {
          setState(() {
            _selectedRoomName = null;
          });
        }
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
                // 2.1 Core MapLibre Vector & Satellite Map Engine
                ml.MapLibreMap(
                  key: ValueKey<bool>(_isSatellite),
                  initialCameraPosition: _currentCameraPosition ??
                      ml.CameraPosition(
                        target: CampusConstants.campusCenter.toMl(),
                        zoom: 16.5,
                        tilt: _is3D ? 45.0 : 0.0,
                        bearing: 0.0,
                      ),
                  minMaxZoomPreference: const ml.MinMaxZoomPreference(14.0, 20.5),
                  styleString: _isSatellite ? _satelliteStyle : _streetStyle,
                  onMapCreated: _onMapCreated,
                  onStyleLoadedCallback: _onStyleLoaded,
                  onMapClick: (point, coordinates) {
                    if (ref.read(mapProvider).isNavigating) return;

                    // 1. Chống xung đột sự kiện onSymbolTapped và onMapClick cùng kích hoạt
                    final now = DateTime.now().millisecondsSinceEpoch;
                    if (now - _lastAnnotationTappedTime < 500) return;

                    // 2. Phát hiện click gần địa điểm (Bán kính thông minh 35 mét)
                    // Giúp người dùng click chuột trên Web hoặc chạm ngón tay trên điện thoại không bao giờ bị hụt
                    final clickLat = coordinates.latitude;
                    final clickLng = coordinates.longitude;
                    final locations = ref.read(mapProvider).filteredLocations;

                    CampusLocationItem? nearestLoc;
                    double minDistance = double.infinity;

                    for (final loc in locations) {
                      final dist = calculateHaversineDistance(clickLat, clickLng, loc.lat, loc.lng);
                      if (dist < minDistance) {
                        minDistance = dist;
                        nearestLoc = loc;
                      }
                    }

                    // Nếu click trong bán kính 35 mét tính từ tâm địa điểm -> Chọn địa điểm đó!
                    if (nearestLoc != null && minDistance <= 35.0) {
                      setState(() => _selectedRoomName = null);
                      ref.read(mapProvider.notifier).selectLocation(nearestLoc);
                      _mapController?.animateCamera(
                        ml.CameraUpdate.newCameraPosition(
                          ml.CameraPosition(
                            target: nearestLoc.coordinate.toMl(),
                            zoom: 17.8,
                            tilt: _is3D ? 50.0 : 0.0,
                          ),
                        ),
                      );
                      return;
                    }

                    // Nếu click vào vùng đất trống cách xa các tòa nhà -> Hủy chọn
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
                          filteredLocations: mapState.filteredLocations,
                          onSearchChanged: (val) {
                            ref.read(mapProvider.notifier).updateSearch(val);
                          },
                          onCategorySelected: (cat) {
                            ref.read(mapProvider.notifier).selectCategory(cat);
                          },
                          onLocationSelected: (loc) {
                            setState(() => _selectedRoomName = null);
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
                      roomName: _selectedRoomName,
                      onClose: () {
                        setState(() => _selectedRoomName = null);
                        ref.read(mapProvider.notifier).selectLocation(null);
                      },
                      onStartNavigation: () {
                        final loc = mapState.selectedLocation!;
                        ref.read(mapProvider.notifier).startNavigationTo(loc);
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


