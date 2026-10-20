import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../schedule/models/schedule_model.dart';
import '../../schedule/providers/schedule_provider.dart';
import '../models/news_model.dart';

class NextClassInfo {
  final ScheduleItem? item;
  final bool isOngoing;
  final String statusText;
  final String countdownText;
  final String capsuleLabel;

  const NextClassInfo({
    this.item,
    this.isOngoing = false,
    this.statusText = 'Không có tiết học sắp tới',
    this.countdownText = '--:--',
    this.capsuleLabel = 'NGÀY MAI (THỨ HAI)',
  });

  String get room => item?.room ?? '';
  String get subject => item?.courseName ?? '';
  String get time => item?.timeSlot ?? '';
  String get lecturer => item?.lecturer ?? '';
}

class HomeAlertItem {
  final String id;
  final String type;
  final String variant; // 'warning', 'success', 'info'
  final String icon;
  final String title;
  final String subtitle;
  final String date;
  final String status;
  final String content;
  final String? actionScreen;

  const HomeAlertItem({
    required this.id,
    this.type = 'school_notice',
    this.variant = 'info',
    this.icon = 'info',
    required this.title,
    this.subtitle = '',
    this.date = '',
    this.status = '',
    this.content = '',
    this.actionScreen,
  });

  factory HomeAlertItem.fromJson(Map<String, dynamic> json) {
    return HomeAlertItem(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'school_notice',
      variant: json['variant']?.toString() ?? 'info',
      icon: json['icon']?.toString() ?? 'info',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      actionScreen: json['actionScreen']?.toString(),
    );
  }
}

class HomeState {
  final List<NewsModel> news;
  final List<HomeAlertItem> alerts;
  final bool isLoading;
  final String? error;

  const HomeState({
    this.news = const [],
    this.alerts = const [],
    this.isLoading = false,
    this.error,
  });

  List<NewsModel> get announcements => news;

  HomeState copyWith({
    List<NewsModel>? news,
    List<HomeAlertItem>? alerts,
    bool? isLoading,
    String? error,
  }) {
    return HomeState(
      news: news ?? this.news,
      alerts: alerts ?? this.alerts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class HomeNotifier extends Notifier<HomeState> {
  Dio get _dio => ref.read(dioProvider);

  @override
  HomeState build() {
    Future.microtask(() => fetchDashboard());
    return const HomeState(isLoading: true);
  }

  Future<void> fetchDashboard() async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.wait([
      fetchNews(),
      fetchAlerts(),
    ]);
    state = state.copyWith(isLoading: false);
  }

  Future<void> fetchAlerts() async {
    try {
      final response = await _dio.get(ApiEndpoints.campusDashboard);
      if (response.statusCode == 200 && response.data != null) {
        final List rawAlerts = response.data['alerts'] ?? response.data['notificationAlerts'] ?? [];
        if (rawAlerts.isNotEmpty) {
          final alerts = rawAlerts
              .map((item) => HomeAlertItem.fromJson(item as Map<String, dynamic>))
              .toList();
          state = state.copyWith(alerts: alerts);
          return;
        }
      }
    } catch (_) {}

    _useFallbackAlerts();
  }

  void _useFallbackAlerts() {
    final mockAlerts = [
      const HomeAlertItem(
        id: 'fb-demo',
        type: 'feedback',
        variant: 'warning',
        icon: 'alert-triangle',
        title: 'Phản hồi: [Cơ sở vật chất] ÁDASD (Chờ tiếp nhận)',
        subtitle: '10/10/2026',
        date: '10/10/2026',
        status: 'Chờ tiếp nhận',
        content: 'Phản hồi cơ sở vật chất phòng học.',
        actionScreen: 'feedback',
      ),
      const HomeAlertItem(
        id: 'sos-demo',
        type: 'sos',
        variant: 'success',
        icon: 'check',
        title: 'Tín hiệu SOS: Đã được xử lý an toàn',
        subtitle: '10/10/2026',
        date: '10/10/2026',
        status: 'Đã xử lý an toàn',
        content: 'Tín hiệu SOS đã được đội an ninh hỗ trợ giải quyết.',
        actionScreen: 'sos',
      ),
    ];
    state = state.copyWith(alerts: mockAlerts);
  }

  Future<void> fetchNews() async {
    try {
      final response = await _dio.get(ApiEndpoints.news);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        final news = list.map((item) => NewsModel.fromJson(item)).toList();
        state = state.copyWith(news: news);
      } else {
        _useFallbackNews();
      }
    } catch (_) {
      _useFallbackNews();
    }
  }

  void _useFallbackNews() {
    final mockNews = [
      const NewsModel(
        id: 1,
        title: 'Thông báo đăng ký học phần Học kỳ 2 năm học 2025 - 2026',
        summary: 'Phòng Đào tạo thông báo kế hoạch đăng ký tín chỉ các khóa đào tạo chính quy.',
        category: 'Đào tạo',
        publishedAt: 'Hôm nay',
      ),
      const NewsModel(
        id: 2,
        title: 'Lễ ra quân Chiến dịch Mùa hè xanh & Tình nguyện vì cộng đồng',
        summary: 'Đoàn Thanh niên - Hội Sinh viên trường phát động phong trào tình nguyện hè tại các xã vùng cao.',
        category: 'Đoàn - Hội',
        publishedAt: 'Hôm qua',
      ),
      const NewsModel(
        id: 3,
        title: 'Hội thảo khoa học Công nghệ Thông tin & Trí tuệ Nhân tạo ứng dụng',
        summary: 'Khoa KHTN & Công nghệ tổ chức hội thảo chuyên đề chuyển đổi số trong giáo dục.',
        category: 'Hội thảo',
        publishedAt: '3 ngày trước',
      ),
    ];

    state = state.copyWith(news: mockNews);
  }
}

final homeProvider = NotifierProvider<HomeNotifier, HomeState>(HomeNotifier.new);

/// Provider tính toán lớp học kế tiếp và đếm ngược theo thời gian thực
final nextClassProvider = Provider<NextClassInfo>((ref) {
  final scheduleState = ref.watch(scheduleProvider);
  final allItems = scheduleState.items;

  if (allItems.isEmpty) {
    return const NextClassInfo();
  }

  final now = DateTime.now();
  final currentMinutes = now.hour * 60 + now.minute;
  final todayJsDay = now.weekday == 7 ? 1 : now.weekday + 1; // 1: CN, 2: T2, 3: T3...

  // 1. Kiểm tra xem có lớp nào đang diễn ra hôm nay không
  final todayItems = allItems.where((i) => i.dayNum == todayJsDay).toList();
  for (final item in todayItems) {
    if (currentMinutes >= item.startMinutes && currentMinutes <= item.endMinutes) {
      final remaining = item.endMinutes - currentMinutes;
      final h = remaining ~/ 60;
      final m = remaining % 60;
      final timeStr = h > 0 ? '$h giờ $m phút' : '$m phút';

      return NextClassInfo(
        item: item,
        isOngoing: true,
        statusText: 'Đang diễn ra',
        countdownText: 'Còn $timeStr là tan học',
        capsuleLabel: 'ĐANG TRONG GIỜ HỌC',
      );
    }
  }

  // 2. Tìm lớp học kế tiếp hôm nay
  ScheduleItem? nextTodayItem;
  int minDiff = 99999;
  for (final item in todayItems) {
    if (item.startMinutes > currentMinutes) {
      final diff = item.startMinutes - currentMinutes;
      if (diff < minDiff) {
        minDiff = diff;
        nextTodayItem = item;
      }
    }
  }

  if (nextTodayItem != null) {
    final h = minDiff ~/ 60;
    final m = minDiff % 60;
    final timeStr = h > 0 ? '$h giờ $m phút' : '$m phút';

    return NextClassInfo(
      item: nextTodayItem,
      isOngoing: false,
      statusText: 'Tiết học sắp tới',
      countdownText: 'Bắt đầu sau $timeStr',
      capsuleLabel: 'LỚP HỌC HÔM NAY',
    );
  }

  // 3. Nếu hôm nay không còn lớp, tìm lớp ngày mai hoặc các ngày tiếp theo trong tuần
  for (int offset = 1; offset <= 7; offset++) {
    final targetDayNum = ((todayJsDay - 1 + offset) % 7) + 1;
    final upcomingDayItems = allItems.where((i) => i.dayNum == targetDayNum).toList()
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

    if (upcomingDayItems.isNotEmpty) {
      final firstItem = upcomingDayItems.first;
      final isTomorrow = offset == 1;
      final dayNameUpper = firstItem.cleanDay.toUpperCase();
      final label = isTomorrow ? 'NGÀY MAI ($dayNameUpper)' : dayNameUpper;

      return NextClassInfo(
        item: firstItem,
        isOngoing: false,
        statusText: isTomorrow ? 'Ngày mai ($dayNameUpper)' : 'Lớp học sắp tới ($dayNameUpper)',
        countdownText: '${firstItem.timeSlot} • ${firstItem.room}',
        capsuleLabel: label,
      );
    }
  }

  return const NextClassInfo(
    statusText: 'Không có tiết học sắp tới',
    countdownText: 'Hẹn gặp lại tuần sau!',
    capsuleLabel: 'KHÔNG CÓ LỊCH HỌC',
  );
});

