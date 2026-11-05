import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/services/home_widget_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/socket_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
