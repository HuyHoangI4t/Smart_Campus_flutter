import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../schedule/models/schedule_model.dart';
import '../../schedule/providers/schedule_provider.dart';
import '../models/fallback_campus_news.dart';
import '../models/news_model.dart';

enum NextClassState {
  ongoing, // 1. Đang học
  upcoming, // 2. Sắp tới
  nextDay, // 3. Ngày mai hoặc thứ gần nhất
  none, // Chưa có lịch
}

class NextClassInfo {
  final ScheduleItem? item;
  final bool isOngoing;
  final bool isUpcoming;
  final NextClassState stateType;
  final String statusText;
  final String countdownText;
  final String capsuleLabel;

  const NextClassInfo({
    this.item,
    this.isOngoing = false,
    this.isUpcoming = false,
    this.stateType = NextClassState.none,
    this.statusText = 'Không có tiết học sắp tới',
    this.countdownText = '--:--',
    this.capsuleLabel = 'CHƯA CÓ LỊCH HỌC',
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

  String get uniqueId => id.isNotEmpty ? id : '${title}_${date}_$content';

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
    _loadFromCache();
    Future.microtask(() => fetchDashboard());
    return const HomeState(
      news: defaultFallbackNews,
      announcements: defaultFallbackAnnouncements,
      isLoading: false,
    );
  }

  Future<void> _loadFromCache() async {
    try {
      final storage = ref.read(storageServiceProvider);
      final raw = await storage.getCache('home_news_cache');
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final List rawAnn = decoded['announcements'] as List? ?? [];
        final List rawNews = decoded['news'] as List? ?? [];

        final announcements = rawAnn
            .whereType<Map>()
            .where((item) => !_isFallbackItem(Map<String, dynamic>.from(item)))
            .map((item) => NewsModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        final news = rawNews
            .whereType<Map>()
            .where((item) => !_isFallbackItem(Map<String, dynamic>.from(item)))
            .map((item) => NewsModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();

        if (announcements.isNotEmpty || news.isNotEmpty) {
          state = state.copyWith(
            news: news.isNotEmpty ? news : defaultFallbackNews,
            announcements: announcements.isNotEmpty ? announcements : defaultFallbackAnnouncements,
            isLoading: false,
          );
        }
      }
    } catch (_) {}
  }

  Future<void> fetchDashboard({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: state.news.isEmpty && state.announcements.isEmpty, error: null);
    await Future.wait([
      fetchNews(forceRefresh: forceRefresh),
      fetchAlerts(),
    ]);
    state = state.copyWith(isLoading: false);
  }

  static const String _dismissedAlertsKey = 'dismissed_alerts_cache';

  Future<Set<String>> _getDismissedAlertIds() async {
    try {
      final storage = ref.read(storageServiceProvider);
      final raw = await storage.getCache(_dismissedAlertsKey);
      if (raw != null && raw.isNotEmpty) {
        final List list = jsonDecode(raw) as List;
        return list.map((e) => e.toString()).toSet();
      }
    } catch (_) {}
    return <String>{};
  }

  Future<void> _saveDismissedAlertIds(Set<String> ids) async {
    try {
      final storage = ref.read(storageServiceProvider);
      await storage.saveCache(_dismissedAlertsKey, jsonEncode(ids.toList()));
    } catch (_) {}
  }

  Future<void> fetchAlerts() async {
    try {
      final response = await _dio.get(ApiEndpoints.campusDashboard);
      if (response.statusCode == 200 && response.data != null) {
        final dynamic raw = response.data is String ? jsonDecode(response.data) : response.data;
        if (raw is Map) {
          final List rawAlerts = raw['alerts'] ?? raw['notificationAlerts'] ?? [];
          if (rawAlerts.isNotEmpty) {
            final dismissedIds = await _getDismissedAlertIds();
            final alerts = rawAlerts
                .whereType<Map<String, dynamic>>()
                .map((item) => HomeAlertItem.fromJson(item))
                .where((item) => !dismissedIds.contains(item.uniqueId))
                .toList();
            state = state.copyWith(alerts: alerts);
            return;
          }
        }
      }
    } catch (_) {}

    state = state.copyWith(alerts: const []);
  }

  /// Xóa nhanh 1 thông báo/cảnh báo
  Future<void> dismissAlert(String alertId) async {
    final dismissedIds = await _getDismissedAlertIds();
    dismissedIds.add(alertId);
    await _saveDismissedAlertIds(dismissedIds);

    final updated = state.alerts.where((item) => item.uniqueId != alertId).toList();
    state = state.copyWith(alerts: updated);
  }

  /// Xóa nhanh toàn bộ thông báo và cảnh báo
  Future<void> dismissAllAlerts() async {
    final dismissedIds = await _getDismissedAlertIds();
    for (final alert in state.alerts) {
      dismissedIds.add(alert.uniqueId);
    }
    await _saveDismissedAlertIds(dismissedIds);
    state = state.copyWith(alerts: const []);
  }

  /// Hoàn tác xóa thông báo
  Future<void> undoDismissAlert(HomeAlertItem alert, {int? atIndex}) async {
    final dismissedIds = await _getDismissedAlertIds();
    dismissedIds.remove(alert.uniqueId);
    await _saveDismissedAlertIds(dismissedIds);

    final updated = List<HomeAlertItem>.from(state.alerts);
    if (atIndex != null && atIndex >= 0 && atIndex <= updated.length) {
      updated.insert(atIndex, alert);
    } else {
      updated.add(alert);
    }
    state = state.copyWith(alerts: updated);
  }

  /// Khôi phục toàn bộ danh sách thông báo và cảnh báo đã bị ẩn
  Future<void> restoreAllDismissedAlerts() async {
    final storage = ref.read(storageServiceProvider);
    await storage.removeCache(_dismissedAlertsKey);
    await fetchAlerts();
  }

  /// Lọc bỏ bài viết mẫu dự phòng (isFallback / badge "Dữ liệu mẫu" / tiêu đề chứa "[Dữ liệu mẫu]")
  /// Tham khảo logic tương ứng bên LTDDDNT: cleanAnn / cleanNews
  bool _isFallbackItem(Map<String, dynamic> item) {
    if (item['isFallback'] == true) return true;
    final badge = item['badge']?.toString().toLowerCase() ?? '';
    if (badge.contains('mẫu')) return true;
    final title = item['title']?.toString() ?? '';
    if (title.contains('[Dữ liệu mẫu]')) return true;
    final id = item['id']?.toString() ?? '';
    if (id.startsWith('sample-')) return true;
    return false;
  }

  Future<void> fetchNews({bool forceRefresh = false}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.news,
        queryParameters: forceRefresh ? {'refresh': 'true', 'reload': 'true'} : null,
      );

      final dynamic data = response.data is String ? jsonDecode(response.data) : response.data;
      if (response.statusCode == 200 && data is Map && (data['success'] == true || data['announcements'] != null || data['news'] != null)) {
        final List rawAnnouncements = data['announcements'] ??
            data['latestAnnouncements'] ??
            [];
        final List rawNews = data['news'] ??
            data['latestNews'] ??
            [];
        final List rawData = data['data'] ?? [];

        // Lọc bỏ bài viết mẫu/fallback trước khi parse (tham khảo LTDDDNT cleanAnn/cleanNews)
        List<NewsModel> announcements = rawAnnouncements
            .whereType<Map>()
            .where((item) => !_isFallbackItem(Map<String, dynamic>.from(item)))
            .map((item) => NewsModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();

        List<NewsModel> news = rawNews
            .whereType<Map>()
            .where((item) => !_isFallbackItem(Map<String, dynamic>.from(item)))
            .map((item) => NewsModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();

        // Fallback: nếu API chưa phân tách announcements và news riêng thì tự động phân loại
        if (announcements.isEmpty || news.isEmpty) {
          final all = rawData
              .whereType<Map>()
              .where((item) => !_isFallbackItem(Map<String, dynamic>.from(item)))
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

        // Chỉ sử dụng dữ liệu mẫu dự phòng khi API thực sự không trả về bất kỳ dữ liệu thực nào
        if (announcements.isEmpty) {
          announcements = defaultFallbackAnnouncements;
        }
        if (news.isEmpty) {
          news = defaultFallbackNews;
        }

        state = state.copyWith(
          news: news,
          announcements: announcements,
        );

        // Lưu cache offline vào thiết bị
        try {
          final storage = ref.read(storageServiceProvider);
          storage.saveCache('home_news_cache', jsonEncode({
            'announcements': announcements.map((a) => a.toJson()).toList(),
            'news': news.map((n) => n.toJson()).toList(),
          }));
        } catch (_) {}
      }
    } catch (e, stack) {
      // ignore: avoid_print
      print('❌ [fetchNews Error] $e\n$stack');
      // Không bao giờ xóa trắng màn hình khi lỗi mạng - bảo đảm luôn có dữ liệu hiển thị
      if (state.news.isEmpty) {
        state = state.copyWith(news: defaultFallbackNews);
      }
      if (state.announcements.isEmpty) {
        state = state.copyWith(announcements: defaultFallbackAnnouncements);
      }
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
        !scheduleState.nextClassLabel.contains('TUẦN') &&
        !scheduleState.nextClassLabel.startsWith('THỨ');

    if (isForToday) {
      if (currentTimeMinutes >= item.startMinutes && currentTimeMinutes < item.endMinutes) {
        final remaining = item.endMinutes - currentTimeMinutes;
        return NextClassInfo(
          item: item,
          isOngoing: true,
          isUpcoming: false,
          stateType: NextClassState.ongoing,
          statusText: 'Đang diễn ra',
          countdownText: 'Còn $remaining phút',
          capsuleLabel: 'ĐANG HỌC',
        );
      } else if (currentTimeMinutes < item.startMinutes) {
        final diff = item.startMinutes - currentTimeMinutes;
        final hours = diff ~/ 60;
        final mins = diff % 60;
        final countdownStr = hours > 0 ? 'Bắt đầu sau ${hours}h ${mins}p' : 'Bắt đầu sau $mins phút';
        return NextClassInfo(
          item: item,
          isOngoing: false,
          isUpcoming: true,
          stateType: NextClassState.upcoming,
          statusText: 'Sắp diễn ra',
          countdownText: countdownStr,
          capsuleLabel: 'SẮP TỚI',
        );
      }
      // Nếu đã qua giờ học của tiết này (currentTimeMinutes >= item.endMinutes),
      // rơi xuống bước 2 bên dưới để tìm tiết tiếp theo của hôm nay hoặc các ngày kế tiếp!
    } else {
      // Backend đã chỉ định lớp học tiếp theo (NGÀY MAI hoặc THỨ GẦN NHẤT)
      String label = scheduleState.nextClassLabel.trim();
      if (scheduleState.nextClassIsOngoing || label == 'ĐANG HỌC' || label.contains('ĐANG TRONG GIỜ')) {
        label = 'ĐANG HỌC';
      } else if (label == 'SẮP TỚI' || label == 'LỚP HỌC KẾ TIẾP') {
        label = 'SẮP TỚI';
      } else if (label.isEmpty || label == 'HÔM NAY' || label == 'NGÀY MAI' || label.contains('NGÀY MAI')) {
        label = 'NGÀY MAI';
      } else if (label.startsWith('THỨ') || label == 'CN') {
        final parts = label.split(' ');
        label = parts.length > 1 ? '${parts[0]} ${parts[1]}'.toUpperCase() : label.toUpperCase();
      } else {
        label = 'NGÀY MAI';
      }

      final bool isOngoing = label == 'ĐANG HỌC';
      final bool isUpcoming = label == 'SẮP TỚI';
      final NextClassState stateType = isOngoing
          ? NextClassState.ongoing
          : (isUpcoming ? NextClassState.upcoming : NextClassState.nextDay);

      final String countdown = stateType == NextClassState.nextDay
          ? (label == 'NGÀY MAI' ? 'Ngày mai • ${item.startTime}' : '$label • ${item.startTime}')
          : scheduleState.nextClassCountdown;

      return NextClassInfo(
        item: item,
        isOngoing: isOngoing,
        isUpcoming: isUpcoming,
        stateType: stateType,
        statusText: scheduleState.nextClassStatus,
        countdownText: countdown,
        capsuleLabel: label,
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
    // Trạng thái 1: ĐANG HỌC
    if (currentTimeMinutes >= cls.startMinutes && currentTimeMinutes < cls.endMinutes) {
      final remaining = cls.endMinutes - currentTimeMinutes;
      return NextClassInfo(
        item: cls,
        isOngoing: true,
        isUpcoming: false,
        stateType: NextClassState.ongoing,
        statusText: 'Đang diễn ra',
        countdownText: 'Còn $remaining phút',
        capsuleLabel: 'ĐANG HỌC',
      );
    }
    // Trạng thái 2: SẮP TỚI
    if (currentTimeMinutes < cls.startMinutes) {
      final diff = cls.startMinutes - currentTimeMinutes;
      final hours = diff ~/ 60;
      final mins = diff % 60;
      final countdownStr = hours > 0 ? 'Bắt đầu sau ${hours}h ${mins}p' : 'Bắt đầu sau $mins phút';
      return NextClassInfo(
        item: cls,
        isOngoing: false,
        isUpcoming: true,
        stateType: NextClassState.upcoming,
        statusText: 'Sắp diễn ra',
        countdownText: countdownStr,
        capsuleLabel: 'SẮP TỚI',
      );
    }
  }

  // 2.2. Trạng thái 3: NGÀY MAI HOẶC NGÀY/THỨ GẦN NHẤT
  // Nếu hôm nay đã hết hoặc không có lớp, tìm lớp gần nhất trong các ngày tiếp theo
  for (int dayOffset = 1; dayOffset <= 7; dayOffset++) {
    int checkWeekday = ((currentWeekday - 1 + dayOffset) % 7) + 1;
    int checkDayNum = _weekdayToDayNum(checkWeekday);
    final nextDayClasses = items.where((e) => e.dayNum == checkDayNum).toList();
    if (nextDayClasses.isNotEmpty) {
      nextDayClasses.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
      final nextClass = nextDayClasses.first;
      final isTomorrow = dayOffset == 1;
      final String capsule = isTomorrow ? 'NGÀY MAI' : _weekdayToString(checkWeekday).toUpperCase();
      final String countdown = isTomorrow
          ? 'Ngày mai • ${nextClass.startTime}'
          : '${_weekdayToString(checkWeekday)} • ${nextClass.startTime}';
      return NextClassInfo(
        item: nextClass,
        isOngoing: false,
        isUpcoming: false,
        stateType: NextClassState.nextDay,
        statusText: isTomorrow ? 'Lớp học ngày mai' : 'Lớp học ${_weekdayToString(checkWeekday)}',
        countdownText: countdown,
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
