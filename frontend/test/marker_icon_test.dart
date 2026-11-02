import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus/core/constants/campus_constants.dart';

IconData getDisplayIcon(CampusLocationItem loc) {
  final name = loc.name.toLowerCase();
  if (name.contains('wc')) return Icons.wc_rounded;
  if (name.contains('gara') || name.contains('bãi xe') || name.contains('xe')) {
    return Icons.directions_car_rounded;
  }
  if (name.contains('căn tin') || name.contains('canteen') || name.contains('đảo sinh viên')) {
    return Icons.restaurant_rounded;
  }
  if (name.contains('thư viện')) return Icons.local_library_rounded;
  if (name.contains('bệnh viện') || name.contains('y tế') || name.contains('phòng khám')) {
    return Icons.local_hospital_rounded;
  }
  if (name.contains('hồ bơi')) return Icons.pool_rounded;
  if (name.contains('quần vợt')) return Icons.sports_tennis_rounded;
  if (name.contains('thể thao') || name.contains('thi đấu')) return Icons.fitness_center_rounded;
  if (name.contains('thí nghiệm') || name.contains('công nghệ sinh học')) return Icons.biotech_rounded;
  if (name.contains('ký túc xá') || name.contains('ktx')) return Icons.apartment_rounded;
  if (name.contains('hội trường') || name.contains('400') || name.contains('200')) {
    return Icons.groups_rounded;
  }
  if (name.contains('nhà học') || name.contains('giảng đường') || name.contains('thực hành cao nguyên')) {
    return Icons.school_rounded;
  }
  if (name.contains('điều hành') || name.contains('hiệu bộ') || name.contains('văn phòng')) {
    return Icons.business_center_rounded;
  }
  return loc.icon;
}

Future<Uint8List> generateMarkerPng({
  required IconData icon,
  required Color backgroundColor,
  required Color iconColor,
  double size = 80.0,
  bool isSelected = false,
  bool isNavigating = false,
}) async {
  final pictureRecorder = ui.PictureRecorder();
  final canvas = Canvas(pictureRecorder);
  final center = Offset(size / 2, size / 2);
  final radius = (size / 2) - 4.0;

  // 1. Shadow
  final shadowPaint = Paint()
    ..color = const Color(0x40000000)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
  canvas.drawCircle(center + const Offset(0, 2.5), radius, shadowPaint);

  // 2. Outer border
  final isHighlighted = isNavigating || isSelected;
  final borderPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = isHighlighted ? const Color(0xFFFACC15) : Colors.white;
  canvas.drawCircle(center, radius, borderPaint);

  // 3. Inner circle
  final borderWidth = isHighlighted ? 4.5 : 3.0;
  final innerPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = backgroundColor;
  canvas.drawCircle(center, radius - borderWidth, innerPaint);

  // 4. Icon
  final textPainter = TextPainter(textDirection: TextDirection.ltr);
  textPainter.text = TextSpan(
    text: String.fromCharCode(icon.codePoint),
    style: TextStyle(
      fontSize: size * 0.44,
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

void main() {
  test('generateMarkerPng works for all campus locations and gates', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final loc in CampusConstants.campusLocations) {
      final icon = getDisplayIcon(loc);
      final normalBytes = await generateMarkerPng(
        icon: icon,
        backgroundColor: loc.color,
        iconColor: Colors.white,
      );
      expect(normalBytes.isNotEmpty, isTrue);

      final selBytes = await generateMarkerPng(
        icon: icon,
        backgroundColor: loc.color,
        iconColor: Colors.white,
        isSelected: true,
      );
      expect(selBytes.isNotEmpty, isTrue);
    }

    for (final _ in CampusConstants.gates) {
      final gateBytes = await generateMarkerPng(
        icon: Icons.door_sliding_outlined,
        backgroundColor: const Color(0xFF0F172A),
        iconColor: Colors.white,
      );
      expect(gateBytes.isNotEmpty, isTrue);
    }
  });
}
