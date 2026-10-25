import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

class HomeWidgetService {
  HomeWidgetService._();
  static final HomeWidgetService instance = HomeWidgetService._();

  static const String appGroupId = 'group.com.smartcampus.smartcampus';

  // Widget 1: Lịch học tiếp theo
  static const String scheduleWidgetName = 'ScheduleWidgetProvider';
  static const String qualifiedScheduleWidgetName =
      'com.smartcampus.smart_campus.ScheduleWidgetProvider';

  // Widget 2: Điểm GPA & Tín chỉ tích lũy
  static const String gpaWidgetName = 'GpaWidgetProvider';
  static const String qualifiedGpaWidgetName =
      'com.smartcampus.smart_campus.GpaWidgetProvider';

  Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      await HomeWidget.setAppGroupId(appGroupId);
    } catch (e) {
      debugPrint('HomeWidgetService init error: $e');
    }
  }

  /// Cập nhật dữ liệu cho Widget 1: Lịch học tiếp theo
  Future<void> updateScheduleWidget({
    required String subject,
    required String time,
    required String room,
    required String status,
    required String countdown,
    String? lecturer,
  }) async {
    if (kIsWeb) return;
    try {
      await HomeWidget.saveWidgetData<String>('widget_subject', subject);
      await HomeWidget.saveWidgetData<String>('widget_time', time);
      await HomeWidget.saveWidgetData<String>('widget_room', room);
      await HomeWidget.saveWidgetData<String>('widget_status', status);
      await HomeWidget.saveWidgetData<String>('widget_countdown', countdown);
      if (lecturer != null && lecturer.isNotEmpty) {
        await HomeWidget.saveWidgetData<String>('widget_lecturer', lecturer);
      }

      await HomeWidget.updateWidget(
        name: scheduleWidgetName,
        androidName: scheduleWidgetName,
        qualifiedAndroidName: qualifiedScheduleWidgetName,
      );
      debugPrint('Đã cập nhật Widget Lịch học thành công!');
    } catch (e) {
      debugPrint('Lỗi cập nhật Widget Lịch học: $e');
    }
  }

  /// Cập nhật dữ liệu cho Widget 2: Kết quả học tập GPA
  Future<void> updateGpaWidget({
    required String gpa,
    required String credits,
    required String rank,
    String? gpa10,
    String? progressText,
    String? syncTime,
  }) async {
    if (kIsWeb) return;
    try {
      final doubleVal = double.tryParse(gpa) ?? 0.0;
      final safeRank = (doubleVal <= 0.0 || rank.isEmpty || rank == 'Chưa xếp loại') ? 'Chưa xét' : rank;
      final currentTime = syncTime ?? '✓ Đồng bộ ${DateFormat('HH:mm').format(DateTime.now())}';

      await HomeWidget.saveWidgetData<String>('widget_gpa', gpa);
      await HomeWidget.saveWidgetData<String>('widget_credits', credits.replaceAll(RegExp(r'[^0-9]'), ''));
      await HomeWidget.saveWidgetData<String>('widget_rank', safeRank);
      if (gpa10 != null && gpa10.isNotEmpty) {
        await HomeWidget.saveWidgetData<String>('widget_gpa10', gpa10);
      }
      if (progressText != null && progressText.isNotEmpty) {
        await HomeWidget.saveWidgetData<String>('widget_progress_text', progressText);
      }
      await HomeWidget.saveWidgetData<String>('widget_sync_time', currentTime);

      await HomeWidget.updateWidget(
        name: gpaWidgetName,
        androidName: gpaWidgetName,
        qualifiedAndroidName: qualifiedGpaWidgetName,
      );
      debugPrint('Đã cập nhật Widget GPA thành công!');
    } catch (e) {
      debugPrint('Lỗi cập nhật Widget GPA: $e');
    }
  }

  /// Cập nhật đồng bộ cả 2 widget màn hình chính
  Future<void> updateWidgetData({
    required String subject,
    required String time,
    required String room,
    required String status,
    required String countdown,
    required String gpa,
    required String credits,
    required String rank,
    String? gpa10,
    String? lecturer,
  }) async {
    await updateScheduleWidget(
      subject: subject,
      time: time,
      room: room,
      status: status,
      countdown: countdown,
      lecturer: lecturer,
    );
    await updateGpaWidget(
      gpa: gpa,
      credits: credits,
      rank: rank,
      gpa10: gpa10,
    );
  }
}
