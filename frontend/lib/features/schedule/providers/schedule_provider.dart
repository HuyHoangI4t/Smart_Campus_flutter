import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/schedule_model.dart';

class ScheduleState {
  final List<ScheduleItem> items;
  final String selectedDay;
  final bool isLoading;
  final String? error;

  const ScheduleState({
    this.items = const [],
    this.selectedDay = 'Thứ 2',
    this.isLoading = false,
    this.error,
  });

  List<ScheduleItem> get filteredItems {
    return items.where((item) => item.dayOfWeek == selectedDay).toList();
  }

  ScheduleState copyWith({
    List<ScheduleItem>? items,
    String? selectedDay,
    bool? isLoading,
    String? error,
  }) {
    return ScheduleState(
      items: items ?? this.items,
      selectedDay: selectedDay ?? this.selectedDay,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ScheduleNotifier extends Notifier<ScheduleState> {
  Dio get _dio => ref.read(dioProvider);

  @override
  ScheduleState build() {
    final now = DateTime.now();
    final weekdayMap = {
      1: 'Thứ 2',
      2: 'Thứ 3',
      3: 'Thứ 4',
      4: 'Thứ 5',
      5: 'Thứ 6',
      6: 'Thứ 7',
      7: 'Chủ nhật',
    };
    final initialDay = weekdayMap[now.weekday] ?? 'Thứ 2';

    Future.microtask(() => fetchSchedule());

    return ScheduleState(
      selectedDay: initialDay,
      isLoading: true,
    );
  }

  void selectDay(String day) {
    state = state.copyWith(selectedDay: day);
  }

  Future<void> fetchSchedule() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dio.get(ApiEndpoints.schedule);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        final items = list.map((item) => ScheduleItem.fromJson(item)).toList();
        state = state.copyWith(items: items, isLoading: false);
      } else {
        _useFallbackMockData();
      }
    } catch (_) {
      _useFallbackMockData();
    }
  }

  void _useFallbackMockData() {
    final mockItems = [
      const ScheduleItem(
        id: 1,
        courseName: 'LS Đảng CS VN',
        room: '2.21 (CLC)',
        dayOfWeek: 'Thứ 2',
        timeSlot: 'Tiết 1-4',
        lecturer: 'Đoàn Văn Kỳ',
      ),
      const ScheduleItem(
        id: 2,
        courseName: 'Lập trình thiết bị di động',
        room: '9.2.04',
        dayOfWeek: 'Thứ 2',
        timeSlot: 'Tiết 7-10',
        lecturer: 'TS. Hoàng Minh',
      ),
      const ScheduleItem(
        id: 3,
        courseName: 'Hệ quản trị cơ sở dữ liệu nâng cao',
        room: 'Nhà học số 7.2.1',
        dayOfWeek: 'Thứ 3',
        timeSlot: '07:00 - 09:15',
        lecturer: 'TS. Lê Thị Hồng Vân',
      ),
      const ScheduleItem(
        id: 4,
        courseName: 'Phân tích thiết kế hệ thống thông tin',
        room: 'Nhà học số 8.2.3',
        dayOfWeek: 'Thứ 4',
        timeSlot: '13:00 - 15:15',
        lecturer: 'ThS. Đặng Hữu Phúc',
      ),
      const ScheduleItem(
        id: 5,
        courseName: 'Trí tuệ nhân tạo & Khai phá dữ liệu',
        room: 'Nhà học số 9.3.2',
        dayOfWeek: 'Thứ 5',
        timeSlot: '07:00 - 09:15',
        lecturer: 'PGS.TS. Vũ Đình Khang',
      ),
      const ScheduleItem(
        id: 6,
        courseName: 'Giáo dục thể chất (Bóng đá)',
        room: 'Sân vận động',
        dayOfWeek: 'Thứ 6',
        timeSlot: '06:30 - 08:45',
        lecturer: 'ThS. Phan Quốc Tuấn',
      ),
    ];

    state = state.copyWith(items: mockItems, isLoading: false);
  }

  Future<bool> addCustomSchedule(ScheduleItem item) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.customSchedule,
        data: item.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        state = state.copyWith(items: [...state.items, item]);
        return true;
      }
    } catch (_) {}

    state = state.copyWith(items: [...state.items, item]);
    return true;
  }
}

final scheduleProvider = NotifierProvider<ScheduleNotifier, ScheduleState>(ScheduleNotifier.new);

