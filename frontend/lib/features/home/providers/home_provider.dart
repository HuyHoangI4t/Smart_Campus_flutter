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

  const NextClassInfo({
    this.item,
    this.isOngoing = false,
    this.statusText = 'Không có tiết học sắp tới',
    this.countdownText = '--:--',
  });

  String get room => item?.room ?? '';
  String get subject => item?.courseName ?? '';
  String get time => item?.timeSlot ?? '';
  String get lecturer => item?.lecturer ?? '';
}

class HomeState {
  final List<NewsModel> news;
  final bool isLoading;
  final String? error;

  const HomeState({
    this.news = const [],
    this.isLoading = false,
    this.error,
  });

  List<NewsModel> get announcements => news;

  HomeState copyWith({
    List<NewsModel>? news,
    bool? isLoading,
    String? error,
  }) {
    return HomeState(
      news: news ?? this.news,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class HomeNotifier extends Notifier<HomeState> {
  Dio get _dio => ref.read(dioProvider);

  @override
  HomeState build() {
    Future.microtask(() => fetchNews());
    return const HomeState(isLoading: true);
  }

  Future<void> fetchDashboard() => fetchNews();

  Future<void> fetchNews() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dio.get(ApiEndpoints.news);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        final news = list.map((item) => NewsModel.fromJson(item)).toList();
        state = state.copyWith(news: news, isLoading: false);
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

    state = state.copyWith(news: mockNews, isLoading: false);
  }
}

final homeProvider = NotifierProvider<HomeNotifier, HomeState>(HomeNotifier.new);

/// Provider tính toán lớp học kế tiếp và đếm ngược theo thời gian thực
final nextClassProvider = Provider<NextClassInfo>((ref) {
  final scheduleState = ref.watch(scheduleProvider);
  final items = scheduleState.filteredItems;

  if (items.isEmpty) {
    return const NextClassInfo();
  }

  final now = DateTime.now();
  final currentMinutes = now.hour * 60 + now.minute;

  for (final item in items) {
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
      );
    }
  }

  ScheduleItem? nextItem;
  int minDiff = 99999;

  for (final item in items) {
    if (item.startMinutes > currentMinutes) {
      final diff = item.startMinutes - currentMinutes;
      if (diff < minDiff) {
        minDiff = diff;
        nextItem = item;
      }
    }
  }

  if (nextItem != null) {
    final h = minDiff ~/ 60;
    final m = minDiff % 60;
    final timeStr = h > 0 ? '$h giờ $m phút' : '$m phút';

    return NextClassInfo(
      item: nextItem,
      isOngoing: false,
      statusText: 'Tiết học sắp tới',
      countdownText: 'Bắt đầu sau $timeStr',
    );
  }

  return const NextClassInfo(
    statusText: 'Đã hoàn thành các tiết học trong ngày',
    countdownText: 'Hẹn gặp lại ngày mai!',
  );
});

