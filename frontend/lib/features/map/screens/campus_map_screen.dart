import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
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
enum MapZoomTier {
  zoomedOut, // zoom < 15.8: icons thu nhỏ (0.48), ẩn tên công trình phụ để bản đồ gọn gàng
  medium,    // 15.8 <= zoom < 17.0: icons vừa vặn (0.78), chữ gọn gàng (9.5)
  detailed,  // zoom >= 17.0: icons chuẩn (1.05), chữ đầy đủ (11.0)
}

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

  bool _isSatellite = true;
  bool _is3D = false;
  bool _isStyleLoaded = false;
  String? _selectedRoomName;
  String? _pendingFocusBuilding;
  String? _pendingFocusRoom;
  int _lastAnnotationTappedTime = 0;
  ml.CameraPosition? _currentCameraPosition;
  MapZoomTier _currentZoomTier = MapZoomTier.medium;
  int _locationsSyncToken = 0;
  int _gatesSyncToken = 0;

  static MapZoomTier _getZoomTier(double zoom) {
    if (zoom < 15.8) return MapZoomTier.zoomedOut;
    if (zoom < 17.0) return MapZoomTier.medium;
    return MapZoomTier.detailed;
  }

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
  final List<ml.Line> _routeLines = [];
  int _routeSyncToken = 0;
  ml.Circle? _userRing;
  ml.Circle? _userDot;

  Timer? _styleWatchdogTimer;
  String? _fallbackStyle;

  /// Lớp bản đồ 2D đường phố Google Maps đã ẩn toàn bộ tên công trình, địa danh, POI có sẵn
  /// (Tương tự chuẩn LTDDDNT: apistyle=s.t:3|p.v:off|s.t:4|p.v:off)
  static const String _streetStyle = '''{
  "version": 8,
  "name": "Google Maps Clean Road",
  "glyphs": "https://demotiles.maplibre.org/font/{fontstack}/{range}.pbf",
  "sources": {
    "google-road": {
      "type": "raster",
      "tiles": [
        "https://mt0.google.com/vt/lyrs=m&apistyle=s.t:3|p.v:off|s.t:4|p.v:off&hl=vi&x={x}&y={y}&z={z}",
        "https://mt1.google.com/vt/lyrs=m&apistyle=s.t:3|p.v:off|s.t:4|p.v:off&hl=vi&x={x}&y={y}&z={z}",
        "https://mt2.google.com/vt/lyrs=m&apistyle=s.t:3|p.v:off|s.t:4|p.v:off&hl=vi&x={x}&y={y}&z={z}",
        "https://mt3.google.com/vt/lyrs=m&apistyle=s.t:3|p.v:off|s.t:4|p.v:off&hl=vi&x={x}&y={y}&z={z}"
      ],
      "tileSize": 256,
      "maxzoom": 20
    }
  },
  "layers": [
    {
      "id": "road-background",
      "type": "background",
      "paint": {
        "background-color": "#F8FAFC"
      }
    },
    {
      "id": "google-road-layer",
      "type": "raster",
      "source": "google-road",
      "minzoom": 0,
      "maxzoom": 22
    }
  ]
}''';

  String get _effectiveStreetStyle => _streetStyle;

  /// Lớp bản đồ Vệ tinh Google Maps nguyên bản (lyrs=s: ảnh chụp vệ tinh sắc nét, hoàn toàn không có tên công trình / nhãn)
  static const String _satelliteStyle = '''{
  "version": 8,
  "name": "Campus Satellite Clean",
  "glyphs": "https://demotiles.maplibre.org/font/{fontstack}/{range}.pbf",
  "sources": {
    "google-satellite": {
      "type": "raster",
      "tiles": [
        "https://mt0.google.com/vt/lyrs=s&hl=vi&x={x}&y={y}&z={z}",
        "https://mt1.google.com/vt/lyrs=s&hl=vi&x={x}&y={y}&z={z}",
        "https://mt2.google.com/vt/lyrs=s&hl=vi&x={x}&y={y}&z={z}",
        "https://mt3.google.com/vt/lyrs=s&hl=vi&x={x}&y={y}&z={z}"
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
    // Kích hoạt Hybrid Composition để MapLibre GL render ổn định qua TextureView
    ml.MapLibreMap.useHybridComposition = true;
    _selectedRoomName = widget.initialRoomName;
    _startStyleWatchdog();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialBuildingFocus();
    });
  }

  void _startStyleWatchdog() {
    _styleWatchdogTimer?.cancel();
    _styleWatchdogTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted || _isStyleLoaded) return;
      // Sau 1.5 giây nếu style chưa xong, tự động giải phóng loading overlay để người dùng không bao giờ bị kẹt
      setState(() {
        _isStyleLoaded = true;
        if (_fallbackStyle == null && !_isSatellite) {
          _fallbackStyle = ml.MapLibreStyles.openfreemapLiberty;
        }
      });
      _mapController?.moveCamera(ml.CameraUpdate.tiltTo(_is3D ? 45.0 : 0.0));
    });
  }

  @override
  void didUpdateWidget(CampusMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final targetBuilding = widget.initialBuildingCode;
    final targetRoom = widget.initialRoomName;
    if (targetBuilding != null && targetBuilding.isNotEmpty) {
      if (targetBuilding != oldWidget.initialBuildingCode || targetRoom != oldWidget.initialRoomName) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _selectedRoomName = targetRoom;
          });
          _focusOnBuilding(targetBuilding, roomName: targetRoom);
        });
      }
    }
  }

  @override
  void dispose() {
    _styleWatchdogTimer?.cancel();
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

    // Kích hoạt render GPU ngay lập tức trên Android (tránh tình trạng phải xoay hoặc bấm 3D/2D mới render)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController?.moveCamera(ml.CameraUpdate.tiltTo(_is3D ? 45.0 : 0.0));
    });

    controller.onCircleTapped.add((circle) {
      _handleAnnotationTapped(circle.data);
    });

    controller.onSymbolTapped.add((symbol) {
      _handleAnnotationTapped(symbol.data);
    });
  }

  void _onCameraIdle() {
    if (!mounted || _mapController == null || !_isStyleLoaded) return;
    final currentZoom = _mapController?.cameraPosition?.zoom ?? _currentCameraPosition?.zoom ?? 16.5;
    final newTier = _getZoomTier(currentZoom);
    if (newTier != _currentZoomTier) {
      _currentZoomTier = newTier;
      _syncLocations();
      _syncGates();
    }
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
    _styleWatchdogTimer?.cancel();
    if (mounted) {
      setState(() {
        _isStyleLoaded = true;
      });
    }
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
    _routeLines.clear();
    _userRing = null;
    _userDot = null;

    try {
      await _mapController?.setSymbolIconAllowOverlap(true);
      await _mapController?.setSymbolIconIgnorePlacement(true);
      await _mapController?.setSymbolTextAllowOverlap(true);
      await _mapController?.setSymbolTextIgnorePlacement(true);
    } catch (_) {}

    final initialZoom = _mapController?.cameraPosition?.zoom ?? _currentCameraPosition?.zoom ?? 16.5;
    _currentZoomTier = _getZoomTier(initialZoom);

    // Nạp lại góc nghiêng 3D để OpenGL / Vulkan render ngay frame hoàn chỉnh
    _mapController?.moveCamera(ml.CameraUpdate.tiltTo(_is3D ? 45.0 : 0.0));

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
    final currentToken = ++_gatesSyncToken;

    final mapState = ref.read(mapProvider);
    final selectedGate = mapState.selectedGate;
    // Khi đang chỉ đường: nếu GPS ở bên trong trường thì ẩn cổng, nếu xuất phát từ cổng hoặc hybrid thì chỉ hiện cổng được chọn
    final isUsingGpsInside = mapState.userPosition != null &&
        CampusDijkstraRouter.isInsideCampus(mapState.userPosition!);
    final gates = mapState.isNavigating
        ? (isUsingGpsInside ? <CampusGate>[] : [selectedGate])
        : (mapState.gates.isNotEmpty ? mapState.gates : CampusConstants.gates);

    final symbolOptionsList = <ml.SymbolOptions>[];
    final symbolDataList = <Map<String, dynamic>>[];

    await Future.wait(gates.map((gate) {
      final isSelected = gate.id == selectedGate.id;
      final gateKey = 'gate_${gate.id}_${isSelected ? "sel" : "norm"}';
      return _ensureMarkerImage(
        key: gateKey,
        icon: Icons.door_sliding_outlined,
        backgroundColor: const Color(0xFF0F172A),
        iconColor: Colors.white,
        isSelected: isSelected,
      );
    }));

    for (final gate in gates) {
      final isSelected = gate.id == selectedGate.id;
      final gateKey = 'gate_${gate.id}_${isSelected ? "sel" : "norm"}';

      // Tính kích thước biểu tượng cổng dựa trên zoom tier
      final double iconSize;
      final double textSize;
      switch (_currentZoomTier) {
        case MapZoomTier.zoomedOut:
          iconSize = isSelected ? 0.90 : 0.65;
          textSize = 9.0;
          break;
        case MapZoomTier.medium:
          iconSize = isSelected ? 1.10 : 0.85;
          textSize = 10.0;
          break;
        case MapZoomTier.detailed:
          iconSize = isSelected ? 1.25 : 1.05;
          textSize = 11.5;
          break;
      }

      final String gateText = isSelected
          ? gate.name
          : (gate.shortName.isNotEmpty ? gate.shortName : gate.name);

      symbolOptionsList.add(
        _createSafeSymbolOptions(
          geometry: gate.coordinate.toMl(),
          iconImage: gateKey,
          iconSize: iconSize,
          textField: gateText,
          textSize: textSize,
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
    if (currentToken != _gatesSyncToken) {
      if (createdSymbols != null) {
        try { await _mapController?.removeSymbols(createdSymbols); } catch (_) {}
      }
      return;
    }

    final oldGateSymbols = List<ml.Symbol>.from(_gateSymbols);
    if (createdSymbols != null) {
      _gateSymbols.clear();
      _gateSymbols.addAll(createdSymbols);
    }
    if (oldGateSymbols.isNotEmpty) {
      try { await _mapController?.removeSymbols(oldGateSymbols); } catch (_) {}
    }
    if (_gateCircles.isNotEmpty) {
      try { await _mapController?.removeCircles(_gateCircles); } catch (_) {}
      _gateCircles.clear();
    }
  }

  Future<void> _syncLocations() async {
    if (_mapController == null || !_isStyleLoaded) return;
    final currentToken = ++_locationsSyncToken;

    final mapState = ref.read(mapProvider);
    // Khi đang chỉ đường (isNavigating), ẩn toàn bộ các icon địa điểm khác (như Google Maps),
    // chỉ giữ lại duy nhất điểm đích đến để tập trung quan sát tuyến đường.
    // Khi không chỉ đường, giữ nguyên toàn bộ địa điểm và thu nhỏ icon theo mức zoom.
    final locations = mapState.isNavigating
        ? (mapState.selectedLocation != null ? [mapState.selectedLocation!] : <CampusLocationItem>[])
        : mapState.filteredLocations;

    if (locations.isEmpty) {
      if (_locationSymbols.isNotEmpty) {
        try { await _mapController?.removeSymbols(_locationSymbols); } catch (_) {}
        _locationSymbols.clear();
      }
      return;
    }

    final symbolOptionsList = <ml.SymbolOptions>[];
    final symbolDataList = <Map<String, dynamic>>[];

    await Future.wait(locations.map((loc) {
      final isSelected = loc.id == mapState.selectedLocation?.id;
      final isNav = mapState.isNavigating && isSelected;
      final locKey = 'loc_${loc.id}_${isNav ? "nav" : (isSelected ? "sel" : "norm")}';
      return _ensureMarkerImage(
        key: locKey,
        icon: _getDisplayIcon(loc),
        backgroundColor: loc.color,
        iconColor: Colors.white,
        isSelected: isSelected,
        isNavigating: isNav,
      );
    }));

    for (final loc in locations) {
      final isSelected = loc.id == mapState.selectedLocation?.id;
      final isNav = mapState.isNavigating && isSelected;
      final locKey = 'loc_${loc.id}_${isNav ? "nav" : (isSelected ? "sel" : "norm")}';

      final double iconSize;
      final String textField;
      final double textSize;
      final int zIndex;

      if (isNav) {
        switch (_currentZoomTier) {
          case MapZoomTier.zoomedOut:
            iconSize = 1.15;
            textSize = 10.5;
            break;
          case MapZoomTier.medium:
            iconSize = 1.35;
            textSize = 12.0;
            break;
          case MapZoomTier.detailed:
            iconSize = 1.45;
            textSize = 12.5;
            break;
        }
        textField = loc.name;
        zIndex = 25;
      } else if (isSelected) {
        switch (_currentZoomTier) {
          case MapZoomTier.zoomedOut:
            iconSize = 1.00;
            textSize = 10.0;
            break;
          case MapZoomTier.medium:
            iconSize = 1.18;
            textSize = 11.0;
            break;
          case MapZoomTier.detailed:
            iconSize = 1.30;
            textSize = 11.5;
            break;
        }
        textField = loc.name;
        zIndex = 20;
      } else {
        switch (_currentZoomTier) {
          case MapZoomTier.zoomedOut:
            // Khi zoom xa (< 15.8): icon nhỏ gọn (0.48 ~ 14px như LTDDDNT), ẩn tên
            iconSize = 0.48;
            textField = '';
            textSize = 0.0;
            zIndex = 3;
            break;
          case MapZoomTier.medium:
            // Khi zoom trung bình (15.8 - 17.0): icon vừa vặn (0.78), ẩn tên để bản đồ thông thoáng, không bị rối
            iconSize = 0.78;
            textField = '';
            textSize = 0.0;
            zIndex = 5;
            break;
          case MapZoomTier.detailed:
            // Khi zoom gần vào (>= 17.0): icon chuẩn (1.05), hiện tên công trình rõ ràng
            iconSize = 1.05;
            textField = loc.name;
            textSize = 10.5;
            zIndex = 5;
            break;
        }
      }

      symbolOptionsList.add(
        _createSafeSymbolOptions(
          geometry: loc.coordinate.toMl(),
          iconImage: locKey,
          iconSize: iconSize,
          textField: textField,
          textSize: textSize,
          textColor: '#0F172A',
          textHaloColor: '#FFFFFF',
          textHaloWidth: 2.2,
          textMaxWidth: 12.0,
          zIndex: zIndex,
        ),
      );
      symbolDataList.add({'type': 'location', 'id': loc.id});
    }

    final createdSymbols = await _mapController?.addSymbols(symbolOptionsList, symbolDataList);
    if (currentToken != _locationsSyncToken) {
      if (createdSymbols != null) {
        try { await _mapController?.removeSymbols(createdSymbols); } catch (_) {}
      }
      return;
    }

    final oldSymbols = List<ml.Symbol>.from(_locationSymbols);
    if (createdSymbols != null) {
      _locationSymbols.clear();
      _locationSymbols.addAll(createdSymbols);
    }
    if (oldSymbols.isNotEmpty) {
      try { await _mapController?.removeSymbols(oldSymbols); } catch (_) {}
    }
    if (_locationCircles.isNotEmpty) {
      try { await _mapController?.removeCircles(_locationCircles); } catch (_) {}
      _locationCircles.clear();
    }
  }

  /// Xóa triệt để toàn bộ đường dẫn trên map mà không để lại đường rác (ghost polyline)
  Future<void> _clearRouteLines() async {
    if (_mapController == null) return;

    final toRemove = <ml.Line>{
      ..._routeLines,
      ?_routeGlowLine,
      ?_routeCoreLine,
    }.toList();
    _routeLines.clear();
    _routeGlowLine = null;
    _routeCoreLine = null;

    if (toRemove.isNotEmpty) {
      await Future.wait(toRemove.map((l) => _mapController?.removeLine(l) ?? Future.value()));
    }

    // Bảo hiểm: quét toàn bộ lines hiện có trên MapController
    // và xóa bất kỳ line nào không phải đường biên giới khuôn viên (_boundaryLine)
    try {
      final currentLines = _mapController?.lines;
      if (currentLines != null && currentLines.isNotEmpty) {
        final orphaned = currentLines.where((l) => l != _boundaryLine).toList();
        if (orphaned.isNotEmpty) {
          await Future.wait(orphaned.map((l) => _mapController?.removeLine(l) ?? Future.value()));
        }
      }
    } catch (_) {}
  }

  Future<void> _syncRoute() async {
    if (_mapController == null || !_isStyleLoaded) return;
    final currentToken = ++_routeSyncToken;

    await _clearRouteLines();

    final mapState = ref.read(mapProvider);
    // Chỉ vẽ tuyến đường khi đang trong trạng thái điều hướng hợp lệ
    if (!mapState.isNavigating) return;

    final route = mapState.activeRoute;
    if (route != null && route.coordinates.isNotEmpty) {
      final coords = route.coordinates.toMl();
      final addedLines = await Future.wait([
        _mapController?.addLine(
          ml.LineOptions(
            geometry: coords,
            lineColor: '#3B82F6',
            lineWidth: 8.5,
            lineOpacity: 0.35,
            lineJoin: 'round',
          ),
        ) ?? Future.value(null),
        _mapController?.addLine(
          ml.LineOptions(
            geometry: coords,
            lineColor: '#2563EB',
            lineWidth: 4.5,
            lineOpacity: 1.0,
            lineJoin: 'round',
          ),
        ) ?? Future.value(null),
      ]);

      final glowLine = addedLines[0];
      final coreLine = addedLines[1];

      // Nếu trong lúc chờ addLine đã có lệnh dừng hoặc token mới -> lập tức xóa ngay
      if (_routeSyncToken != currentToken || !ref.read(mapProvider).isNavigating) {
        if (glowLine != null) {
          try { await _mapController?.removeLine(glowLine); } catch (_) {}
        }
        if (coreLine != null) {
          try { await _mapController?.removeLine(coreLine); } catch (_) {}
        }
        return;
      }

      _routeGlowLine = glowLine;
      _routeCoreLine = coreLine;
      if (glowLine != null) _routeLines.add(glowLine);
      if (coreLine != null) _routeLines.add(coreLine);
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
      _fallbackStyle = null;
    });
    _startStyleWatchdog();

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

  /// Khung hình camera tập trung vào vị trí người dùng khi bắt đầu lộ trình điều hướng
  void _zoomToUserStart({
    required DijkstraResult? route,
    required CampusLocationItem? destination,
    required CampusGate? gate,
  }) {
    if (_mapController == null || !_isStyleLoaded) return;

    final mapState = ref.read(mapProvider);
    final userPos = mapState.userPosition;

    // Vị trí xuất phát ưu tiên: GPS người dùng -> Cổng đã chọn -> Tọa độ đầu tiên của route -> Điểm đến
    final startCoordinate = userPos ??
        gate?.coordinate ??
        (route != null && route.coordinates.isNotEmpty
            ? route.coordinates.first
            : destination?.coordinate);

    if (startCoordinate == null) return;

    try {
      _mapController?.animateCamera(
        ml.CameraUpdate.newCameraPosition(
          ml.CameraPosition(
            target: startCoordinate.toMl(),
            zoom: 18.2,
            tilt: _is3D ? 50.0 : 0.0,
          ),
        ),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // [PERF - React Native / Flutter Pattern] Fine-grained selectors:
    // Tuyệt đối không watch toàn bộ MapState ở cấp Screen để tránh re-render toàn màn hình
    // khi cảm biến GPS/La bàn/Từ khóa tìm kiếm thay đổi
    final isNavigating = ref.watch(mapProvider.select((s) => s.isNavigating));
    final hasSelectedLocation = ref.watch(mapProvider.select((s) => s.selectedLocation != null));
    final isLoadingPaths = ref.watch(mapProvider.select((s) => s.isLoadingPaths));

    ref.listen<MapState>(mapProvider, (prev, next) {
      if (!next.isMapActive) {
        if (_searchController.text.isNotEmpty) {
          _searchController.clear();
        }
        _selectedRoomName = null;
        return;
      }

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
      } else if (prev?.activeRoute != next.activeRoute) {
        _syncRoute();
      }
      if ((prev?.isNavigating != next.isNavigating && next.isNavigating) ||
          (next.isNavigating && prev?.activeRoute != next.activeRoute && next.activeRoute != null)) {
        _zoomToUserStart(
          route: next.activeRoute,
          destination: next.selectedLocation,
          gate: next.selectedGate,
        );
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
          NavHeader(
            title: 'Bản đồ khuôn viên',
            subtitle: 'Đại học Tây Nguyên • Vector 3D & Vệ tinh',
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.16),
                offset: const Offset(0, 4),
                blurRadius: 10,
              ),
            ],
          ),

          // ─── 2. MAP WITH OVERLAYS ───
          Expanded(
            child: Stack(
              children: [
                // 2.1 Core MapLibre Vector & Satellite Map Engine (GPU Texture Isolated)
                RepaintBoundary(
                  child: ml.MapLibreMap(
                    key: ValueKey<bool>(_isSatellite),
                    initialCameraPosition: _currentCameraPosition ??
                        ml.CameraPosition(
                          target: CampusConstants.campusCenter.toMl(),
                          zoom: 16.5,
                          tilt: _is3D ? 45.0 : 0.0,
                          bearing: 0.0,
                        ),
                    minMaxZoomPreference: const ml.MinMaxZoomPreference(14.0, 20.5),
                    styleString: _isSatellite ? _satelliteStyle : _effectiveStreetStyle,
                    onMapCreated: _onMapCreated,
                    onStyleLoadedCallback: _onStyleLoaded,
                    onMapClick: (point, coordinates) {
                      FocusScope.of(context).unfocus();
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
                    trackCameraPosition: true,
                    onCameraMove: (ml.CameraPosition position) {
                      _currentCameraPosition = position;
                    },
                    onCameraIdle: _onCameraIdle,
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
                ),

                // 2.2 Loading Indicator trong lúc khởi động GPU & nạp Map Style (tránh hiện màn hình đen)
                if (!_isStyleLoaded)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color: _isSatellite ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _isSatellite ? Colors.white : AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Đang tải bản đồ khuôn viên...',
                                style: TextStyle(
                                  color: _isSatellite ? Colors.white70 : AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // 2.3 Top Floating Overlay (Được cô lập bằng Consumer riêng, không làm re-render Native Map)
                Positioned(
                  top: 10,
                  left: 14,
                  right: 14,
                  child: Consumer(
                    builder: (context, ref, _) {
                      final isNav = ref.watch(mapProvider.select((s) => s.isNavigating));
                      if (isNav) {
                        final selectedGate = ref.watch(mapProvider.select((s) => s.selectedGate));
                        return MapGateSelectorCard(
                          selectedGate: selectedGate,
                          onSelectGate: (gate) {
                            ref.read(mapProvider.notifier).selectGate(gate);
                          },
                        );
                      }
                      final selectedCategory = ref.watch(mapProvider.select((s) => s.selectedCategory));
                      final totalCount = ref.watch(mapProvider.select((s) => s.locations.length));
                      final filteredLocations = ref.watch(mapProvider.select((s) => s.filteredLocations));
                      return MapTopSearchBar(
                        searchController: _searchController,
                        selectedCategory: selectedCategory,
                        totalCount: totalCount,
                        filteredLocations: filteredLocations,
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
                      );
                    },
                  ),
                ),

                if (isLoadingPaths)
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
                  bottom: isNavigating
                      ? 110
                      : (hasSelectedLocation ? 212 : 16),
                  child: Column(
                    children: [
                      // Nút chuyển chế độ 3D / 2D
                      _buildMapCircleBtn(
                        icon: Icons.view_in_ar,
                        iconColor: _is3D ? AppColors.accent : AppColors.primary,
                        badgeText: _is3D ? '3D' : '2D',
                        onTap: _toggle3D,
                      ),
                      const SizedBox(height: 6),

                      // Nút đổi lớp Bản đồ (Vệ tinh / Vector)
                      _buildMapCircleBtn(
                        icon: Icons.layers_outlined,
                        iconColor: _isSatellite ? AppColors.accent : AppColors.primary,
                        onTap: _toggleSatellite,
                      ),
                      const SizedBox(height: 6),

                      // Nút xoay hướng Bắc
                      _buildMapCircleBtn(
                        icon: Icons.explore_outlined,
                        iconColor: AppColors.danger,
                        onTap: () => _mapController?.animateCamera(ml.CameraUpdate.bearingTo(0.0)),
                      ),
                      const SizedBox(height: 6),

                      // Nút định vị vị trí hiện tại
                      _buildMapCircleBtn(
                        icon: Icons.my_location,
                        iconColor: AppColors.info,
                        onTap: _centerCampus,
                      ),
                      const SizedBox(height: 6),

                      // Nút phóng to toàn khuôn viên
                      _buildMapCircleBtn(
                        icon: Icons.fullscreen,
                        onTap: _fitBounds,
                      ),
                    ],
                  ),
                ),

                // 2.4 Bottom Overlay: Location Detail Card OR Navigation Bar
                if (isNavigating && hasSelectedLocation)
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 12,
                    child: Consumer(
                      builder: (context, ref, _) {
                        final destination = ref.watch(mapProvider.select((s) => s.selectedLocation));
                        final currentGate = ref.watch(mapProvider.select((s) => s.selectedGate));
                        final activeRoute = ref.watch(mapProvider.select((s) => s.activeRoute));
                        if (destination == null) return const SizedBox.shrink();

                        return MapNavigationBar(
                          destination: destination,
                          currentGate: currentGate,
                          distanceMeters: activeRoute?.distanceMeters ?? 754,
                          walkingMinutes: activeRoute?.estimatedWalkingMinutes ?? 10,
                          isHybrid: activeRoute?.isHybrid ?? false,
                          viaGateName: activeRoute?.viaGateName,
                          onStopNavigation: () async {
                            await _clearRouteLines();
                            ref.read(mapProvider.notifier).stopNavigation();
                            _mapController?.animateCamera(
                              ml.CameraUpdate.newCameraPosition(
                                ml.CameraPosition(
                                  target: destination.coordinate.toMl(),
                                  zoom: 17.5,
                                  tilt: _is3D ? 45.0 : 0.0,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  )
                else if (hasSelectedLocation)
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 12,
                    child: Consumer(
                      builder: (context, ref, _) {
                        final location = ref.watch(mapProvider.select((s) => s.selectedLocation));
                        final currentGate = ref.watch(mapProvider.select((s) => s.selectedGate));
                        final userPos = ref.watch(mapProvider.select((s) => s.userPosition));
                        final isOutside = userPos != null && !CampusDijkstraRouter.isInsideCampus(userPos);
                        if (location == null) return const SizedBox.shrink();

                        return MapLocationDetailCard(
                          location: location,
                          currentGate: currentGate,
                          roomName: _selectedRoomName,
                          isOutsideCampus: isOutside,
                          onClose: () {
                            setState(() => _selectedRoomName = null);
                            ref.read(mapProvider.notifier).selectLocation(null);
                          },
                          onStartNavigation: () {
                            ref.read(mapProvider.notifier).startNavigationTo(location);
                          },
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
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.8)),
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
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
      ),
    );
  }
}
