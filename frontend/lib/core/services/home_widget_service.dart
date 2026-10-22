import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

class HomeWidgetService {
  HomeWidgetService._();
  static final HomeWidgetService instance = HomeWidgetService._();

  static const String appGroupId = 'group.com.smartcampus.smartcampus';
  static const String androidWidgetName = 'ScheduleWidgetProvider';

  Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      await HomeWidget.setAppGroupId(appGroupId);
    } catch (e) {
      debugPrint('HomeWidgetService init error: $e');
    }
  }

  /// Cập nhật dữ liệu vào Widget màn hình chính điện thoại
  Future<void> updateWidgetData({
    required String subject,
    required String time,
    required String room,
    required String status,
    required String countdown,
    required String gpa,
    required String credits,
    required String rank,
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>('widget_subject', subject);
      await HomeWidget.saveWidgetData<String>('widget_time', time);
      await HomeWidget.saveWidgetData<String>('widget_room', room);
      await HomeWidget.saveWidgetData<String>('widget_status', status);
      await HomeWidget.saveWidgetData<String>('widget_countdown', countdown);
      await HomeWidget.saveWidgetData<String>('widget_gpa', gpa);
      await HomeWidget.saveWidgetData<String>('widget_credits', credits);
      await HomeWidget.saveWidgetData<String>('widget_rank', rank);

      await HomeWidget.updateWidget(
        name: androidWidgetName,
        androidName: androidWidgetName,
      );
      debugPrint('Đã cập nhật dữ liệu Widget màn hình chính thành công!');
    } catch (e) {
      debugPrint('Lỗi cập nhật Widget data: $e');
    }
  }
}

