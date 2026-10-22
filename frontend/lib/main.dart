import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/services/home_widget_service.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo dịch vụ thông báo cục bộ và Widget màn hình chính
  await NotificationService.instance.initialize();
  await HomeWidgetService.instance.initialize();

  runApp(
    const ProviderScope(
      child: SmartCampusApp(),
    ),
  );
}
