import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import 'app/app.dart';
import 'core/services/home_widget_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/socket_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Kích hoạt Hybrid Composition để MapLibre GL render qua TextureView trên Android,
  // giải quyết triệt để lỗi màn hình đen (black screen) trên các dòng máy vật lý (Samsung, Xiaomi, Oppo...)
  ml.MapLibreMap.useHybridComposition = true;

  // Ẩn thanh trạng thái hệ thống (đồng hồ, pin, sóng) ngay lập tức khi mở ứng dụng
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Khởi tạo dịch vụ thông báo cục bộ, Widget màn hình chính và Socket SOS Realtime
  await NotificationService.instance.initialize();
  await HomeWidgetService.instance.initialize();
  SocketService.instance.initSocket();

  runApp(
    const ProviderScope(
      child: SmartCampusApp(),
    ),
  );
}
