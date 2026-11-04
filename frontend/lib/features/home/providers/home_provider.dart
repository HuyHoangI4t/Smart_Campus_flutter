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
  final List<NewsModel> announcements;
  final List<HomeAlertItem> alerts;
  final bool isLoading;
  final String? error;

  const HomeState({
    this.news = const [],
    this.announcements = const [],
    this.alerts = const [],
    this.isLoading = false,
    this.error,
  });

  List<NewsModel> get allArticles => [...announcements, ...news];

  HomeState copyWith({
    List<NewsModel>? news,
    List<NewsModel>? announcements,
    List<HomeAlertItem>? alerts,
    bool? isLoading,
    String? error,
  }) {
    return HomeState(
      news: news ?? this.news,
      announcements: announcements ?? this.announcements,
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

  Future<void> fetchDashboard({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.wait([
      fetchNews(forceRefresh: forceRefresh),
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
              .whereType<Map<String, dynamic>>()
              .map((item) => HomeAlertItem.fromJson(item))
              .toList();
          state = state.copyWith(alerts: alerts);
          return;
        }
      }
    } catch (_) {}

    state = state.copyWith(alerts: const []);
  }

  Future<void> fetchNews({bool forceRefresh = false}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.news,
        queryParameters: forceRefresh ? {'refresh': 'true', 'reload': 'true'} : null,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List rawAnnouncements = response.data['announcements'] ??
            response.data['latestAnnouncements'] ??
            [];
        final List rawNews = response.data['news'] ??
            response.data['latestNews'] ??
            [];
        final List rawData = response.data['data'] ?? [];

        List<NewsModel> announcements = rawAnnouncements
            .whereType<Map>()
            .map((item) => NewsModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();

        List<NewsModel> news = rawNews
            .whereType<Map>()
            .map((item) => NewsModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();

        // Fallback: nếu API chưa phân tách announcements và news riêng thì tự động phân loại
        if (announcements.isEmpty || news.isEmpty) {
          final all = rawData
              .whereType<Map>()
              .map((item) => NewsModel.fromJson(Map<String, dynamic>.from(item)))
              .toList();

          if (announcements.isEmpty) {
            announcements = all.where((n) {
              final cat = n.category.toLowerCase();
              return cat.contains('thông báo') ||
                  n.title.toLowerCase().contains('thông báo') ||
                  n.id.startsWith('announcement');
            }).toList();
          }

          if (news.isEmpty) {
            news = all.where((n) {
              final cat = n.category.toLowerCase();
              return cat.contains('tin') ||
                  cat.contains('hoạt động') ||
                  n.id.startsWith('news') ||
                  !announcements.any((a) => a.id == n.id);
            }).toList();
          }
        }

        state = state.copyWith(
          news: news,
          announcements: announcements,
        );
      } else {
        state = state.copyWith(news: const [], announcements: const []);
      }
    } catch (e, stack) {
      // ignore: avoid_print
      print('❌ [fetchNews Error] $e\n$stack');
      state = state.copyWith(news: const [], announcements: const []);
    }
  }
}

final homeProvider = NotifierProvider<HomeNotifier, HomeState>(() {
  return HomeNotifier();
});

int _weekdayToDayNum(int weekday) => weekday == 7 ? 1 : weekday + 1;

/// Provider phát tín hiệu thời gian thực mỗi 30 giây để cập nhật đồng hồ đếm ngược tự động
final currentTimeProvider = StreamProvider.autoDispose<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 30), (_) => DateTime.now());
});

final nextClassProvider = Provider<NextClassInfo>((ref) {
  // Lắng nghe ticker thời gian thực để cập nhật countdown đếm ngược mỗi 30s
  final now = ref.watch(currentTimeProvider).value ?? DateTime.now();
  final scheduleState = ref.watch(scheduleProvider);
  final currentWeekday = now.weekday; // 1 = Thứ 2, 7 = Chủ nhật
  final currentDayNum = _weekdayToDayNum(currentWeekday);
  final currentTimeMinutes = now.hour * 60 + now.minute;

  // 1. ƯU TIÊN SỐ 1: Sử dụng nextClass đã được Backend tính toán chuẩn xác
  // (Đã tự động xử lý Chủ nhật, ngày mai, các ngày tiếp theo, phòng học và chỉ đường)
  if (scheduleState.nextClassItem != null) {
    final item = scheduleState.nextClassItem!;
    final isForToday = item.dayNum == currentDayNum &&
        !scheduleState.nextClassLabel.contains('NGÀY MAI') &&
        !scheduleState.nextClassLabel.contains('TUẦN');

    if (isForToday) {
      if (currentTimeMinutes >= item.startMinutes && currentTimeMinutes < item.endMinutes) {
        final remaining = item.endMinutes - currentTimeMinutes;
        return NextClassInfo(
          item: item,
          isOngoing: true,
          statusText: 'Đang diễn ra',
          countdownText: 'Còn $remaining phút',
          capsuleLabel: 'HÔM NAY',
        );
      } else if (currentTimeMinutes < item.startMinutes) {
        final diff = item.startMinutes - currentTimeMinutes;
        final hours = diff ~/ 60;
        final mins = diff % 60;
        final countdownStr = hours > 0 ? 'Bắt đầu sau ${hours}h ${mins}p' : 'Bắt đầu sau $mins phút';
        return NextClassInfo(
          item: item,
          isOngoing: false,
          statusText: 'Sắp diễn ra',
          countdownText: countdownStr,
          capsuleLabel: 'HÔM NAY',
        );
      }
      // Nếu đã qua giờ học của tiết này (currentTimeMinutes >= item.endMinutes),
      // rơi xuống bước 2 để tìm tiết tiếp theo của hôm nay hoặc các ngày kế tiếp!
    } else {
      return NextClassInfo(
        item: item,
        isOngoing: scheduleState.nextClassIsOngoing,
        statusText: scheduleState.nextClassStatus,
        countdownText: scheduleState.nextClassCountdown,
        capsuleLabel: scheduleState.nextClassLabel,
      );
    }
  }

  // 2. DỰ PHÒNG: Tính toán cục bộ dựa trên danh sách lịch của TUẦN HIỆN TẠI
  // (Đảm bảo không bao giờ bị nhảy sang tuần khác khi người dùng chuyển tuần ở tab Lịch học)
  final items = scheduleState.currentWeekItems.isNotEmpty
      ? scheduleState.currentWeekItems
      : scheduleState.items;

  if (items.isEmpty) {
    return const NextClassInfo();
  }

  // 2.1. Tìm các lớp học trong ngày hôm nay
  final todayClasses = items.where((e) => e.dayNum == currentDayNum).toList();
  todayClasses.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

  for (final cls in todayClasses) {
    if (currentTimeMinutes >= cls.startMinutes && currentTimeMinutes < cls.endMinutes) {
      final remaining = cls.endMinutes - currentTimeMinutes;
      return NextClassInfo(
        item: cls,
        isOngoing: true,
        statusText: 'Đang diễn ra',
        countdownText: 'Còn $remaining phút',
        capsuleLabel: 'HÔM NAY',
      );
    }
    if (currentTimeMinutes < cls.startMinutes) {
      final diff = cls.startMinutes - currentTimeMinutes;
      final hours = diff ~/ 60;
      final mins = diff % 60;
      final countdownStr = hours > 0 ? 'Bắt đầu sau ${hours}h ${mins}p' : 'Bắt đầu sau $mins phút';
      return NextClassInfo(
        item: cls,
        isOngoing: false,
        statusText: 'Sắp diễn ra',
        countdownText: countdownStr,
        capsuleLabel: 'HÔM NAY',
      );
    }
  }

  // 2.2. Nếu hôm nay đã hết hoặc không có lớp, tìm lớp gần nhất trong các ngày CÒN LẠI của tuần
  // Chú ý: CHỈ tìm tịnh tiến về phía trước (không vòng lặp modulo 7 để tránh lấy nhầm lịch quá khứ của tuần này)
  for (int dayOffset = 1; (currentWeekday + dayOffset) <= 7; dayOffset++) {
    int checkWeekday = currentWeekday + dayOffset;
    int checkDayNum = _weekdayToDayNum(checkWeekday);
    final nextDayClasses = items.where((e) => e.dayNum == checkDayNum).toList();
    if (nextDayClasses.isNotEmpty) {
      nextDayClasses.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
      final nextClass = nextDayClasses.first;
      String capsule = dayOffset == 1 ? 'NGÀY MAI' : _weekdayToString(checkWeekday).toUpperCase();
      return NextClassInfo(
        item: nextClass,
        isOngoing: false,
        statusText: 'Lớp học tiếp theo',
        countdownText: '${nextClass.startTime} • ${_weekdayToString(checkWeekday)}',
        capsuleLabel: capsule,
      );
    }
  }

  return const NextClassInfo(
    statusText: 'Tuần này đã hết tiết học',
    capsuleLabel: 'ĐÃ HẾT TIẾT',
  );
});

final nextClassInfoProvider = nextClassProvider;

String _weekdayToString(int day) {
  switch (day) {
    case 1:
      return 'Thứ hai';
    case 2:
      return 'Thứ ba';
    case 3:
      return 'Thứ tư';
    case 4:
      return 'Thứ năm';
    case 5:
      return 'Thứ sáu';
    case 6:
      return 'Thứ bảy';
    case 7:
      return 'Chủ nhật';
    default:
      return 'Hôm nay';
  }
}
