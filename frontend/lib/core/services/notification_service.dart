import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../features/schedule/models/schedule_model.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Notification clicked: ${details.payload}');
        },
      );

      // Yêu cầu quyền thông báo trên Android 13+
      final androidPlatform = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        await androidPlatform.requestNotificationsPermission();
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  /// Gửi thông báo thử nghiệm ngay lập tức để người dùng kiểm tra
  Future<void> sendTestNotification({
    String title = '🔔 Thử nghiệm thông báo lịch học',
    String body = 'Hệ thống thông báo Smart Campus hoạt động tốt! Bạn sẽ nhận thông báo trước giờ học 1 tiếng.',
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'schedule_reminders_channel',
      'Nhắc nhở lịch học',
      channelDescription: 'Thông báo nhắc nhở trước khi buổi học bắt đầu',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: 'test_notification',
    );
  }

  /// Lập lịch thông báo trước khi lịch học bắt đầu 1 tiếng (60 phút)
  Future<void> scheduleClassReminder({
    required ScheduleItem item,
    required DateTime targetDate,
    int minutesBefore = 60,
  }) async {
    await initialize();

    // Tính thời điểm bắt đầu lớp học
    final startMins = item.startMinutes;
    final startHour = startMins ~/ 60;
    final startMinute = startMins % 60;

    final classDateTime = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      startHour,
      startMinute,
    );

    // Thời điểm thông báo trước 1 tiếng
    final reminderTime = classDateTime.subtract(Duration(minutes: minutesBefore));
    final now = DateTime.now();

    // Nếu thời điểm nhắc nhở đã qua thì không lên lịch
    if (reminderTime.isBefore(now)) return;

    final tzReminderTime = tz.TZDateTime.from(reminderTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'schedule_reminders_channel',
      'Nhắc nhở lịch học',
      channelDescription: 'Thông báo nhắc nhở trước khi buổi học bắt đầu 1 tiếng',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    final notificationId = (item.id.hashCode + targetDate.day.hashCode) & 0x7FFFFFFF;

    try {
      await _notificationsPlugin.zonedSchedule(
        id: notificationId,
        title: '🔔 Sắp đến giờ học: ${item.courseName}',
        body: 'Lớp học bắt đầu lúc ${item.timeSlot} tại phòng ${item.room}. Hãy chuẩn bị trước khi vào lớp!',
        scheduledDate: tzReminderTime,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'schedule_${item.id}',
      );
      debugPrint('Đã lên lịch thông báo lúc $reminderTime cho môn: ${item.courseName}');
    } catch (e) {
      debugPrint('Lỗi lên lịch thông báo: $e');
    }
  }

  /// Tự động quét và lên lịch nhắc nhở 1 tiếng cho tất cả môn học trong tuần
  Future<void> syncAllScheduleReminders(List<ScheduleItem> items) async {
    if (items.isEmpty) return;
    await initialize();

    final now = DateTime.now();
    final distToMon = (now.weekday - 1) % 7;
    final mon = now.subtract(Duration(days: distToMon));

    // Lên lịch cho các môn từ Thứ 2 đến Thứ 6 (chỉ các ngày trong tuần)
    for (int dayOffset = 0; dayOffset < 5; dayOffset++) {
      final targetDay = mon.add(Duration(days: dayOffset));
      final dayNum = dayOffset + 2; // Thứ 2 = 2, ..., Thứ 6 = 6

      final dayItems = items.where((i) => i.dayNum == dayNum).toList();
      for (final item in dayItems) {
        await scheduleClassReminder(
          item: item,
          targetDate: targetDay,
          minutesBefore: 60,
        );
      }
    }
  }

  /// Hủy toàn bộ thông báo
  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}

